// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Layout-time regression guard
//
// Each test measures the median single-layout-pass time for a fixed HTML
// fixture and fails if it exceeds the 60 FPS budget (16 ms).
//
// CI usage:
//   flutter test benchmark/layout_regression.dart --reporter json \
//       > benchmark/results/layout_$(date +%Y%m%d_%H%M%S).json
//
// The benchmark.yml workflow compares the median against THRESHOLDS and
// posts a PR comment when any budget is exceeded.
// ─────────────────────────────────────────────────────────────────────────────

/// Hard layout-time budgets per fixture (milliseconds, median over N runs).
/// Raise a budget only with a documented justification in the PR description.
const _kThresholds = {
  'simple_paragraph': 8,    // trivial — must stay well under budget
  'mixed_inline': 10,       // bold/italic/code/links inline mix
  'float_layout': 12,       // float + text-wrap — the heaviest inline case
  'table_20_rows': 14,      // 3-column table, 20 rows with col/row spans
  'cjk_ruby': 14,           // CJK kinsoku + ruby annotation measurement
  'large_article': 16,      // 100-paragraph realistic article — worst case
};

const _kWarmupRuns = 3;
const _kMeasureRuns = 10;

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _kSimpleParagraph = '''
<p>A single paragraph of plain text used as the baseline measurement.
It contains no special formatting, floats, or CJK characters.
The layout should complete in well under half the frame budget.</p>
''';

const _kMixedInline = '''
<p>This paragraph contains <strong>bold</strong>, <em>italic</em>,
<code>inline code</code>, <a href="#">a link</a>, <mark>highlighted</mark>,
<u>underline</u>, <s>strikethrough</s>, super<sup>script</sup>,
and sub<sub>script</sub> all on the same line so the fragment-merge
and baseline-alignment passes are exercised.</p>
<p><strong><em>Nested bold italic</em></strong> and
back to <em>italic with <strong>bold</strong> nested</em>.</p>
''';

const _kFloatLayout = '''
<div style="overflow:hidden">
  <img src="https://invalid.example.test/cover.jpg"
       style="float:left; width:120px; height:160px; margin-right:12px"
       alt="float left">
  <p>Paragraph text that must flow around the left-floated image.
  The line-layout algorithm reserves the float inset for every line
  that overlaps the image vertically.  This fixture exercises the
  float-clearance and inset-reservation paths in _performLineLayout.</p>
  <p>A second paragraph continues below the first.  Once the accumulated
  line height exceeds the float height, subsequent lines use the full
  available width — testing the float-expiry logic.</p>
</div>
''';

// Not const — uses _repeat() which is a runtime function call.
final _kTable20Rows = '''
<table>
  <thead>
    <tr><th>Name</th><th colspan="2">Scores</th></tr>
  </thead>
  <tbody>
    ${_repeat('<tr><td>Row</td><td>A</td><td>B</td></tr>', 20)}
  </tbody>
</table>
''';

const _kCjkRuby = '''
<p>
  <ruby>東京<rt>とうきょう</rt></ruby>は
  <ruby>日本<rt>にほん</rt></ruby>の首都です。
  <ruby>漢字<rt>かんじ</rt></ruby>の上に
  <ruby>振り仮名<rt>ふりがな</rt></ruby>が付きます。
  句読点（。、）は行頭に来てはならず、
  括弧の開き（「）は行末に来てはなりません。
</p>
<p>
  中文文本也应该在正确的位置换行，标点符号不应该出现在行首。
  한국어 텍스트도 올바른 위치에서 줄 바꿈이 되어야 합니다.
</p>
''';

String _kLargeArticle = () {
  final sb = StringBuffer('<article><h1>Performance Test Article</h1>');
  for (int i = 1; i <= 100; i++) {
    sb.write('''
<h2>Section $i</h2>
<p>Paragraph $i — Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
<strong>Bold word</strong> and <em>italic word</em> in every paragraph
so the inline fragment pipeline is exercised throughout.</p>
''');
  }
  sb.write('</article>');
  return sb.toString();
}();

String _repeat(String s, int n) => List.filled(n, s).join('\n');

// ── Measurement helpers ───────────────────────────────────────────────────────

/// Pumps [html] once and returns the elapsed wall-clock milliseconds.
Future<int> _measureOne(WidgetTester tester, String html) async {
  final sw = Stopwatch()..start();
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        size: Size(400, 800),
        devicePixelRatio: 1.0,
        textScaler: TextScaler.noScaling,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SizedBox(
            width: 368,
            child: HyperViewer(html: html, mode: HyperRenderMode.sync),
          ),
        ),
      ),
    ),
  );
  await tester.pump();       // layout pass
  sw.stop();
  await tester.pumpWidget(const SizedBox()); // reset between runs
  return sw.elapsedMilliseconds;
}

/// Runs [_kWarmupRuns] throw-away passes, then [_kMeasureRuns] measured ones.
/// Returns sorted times.
Future<List<int>> _bench(WidgetTester tester, String html) async {
  for (int i = 0; i < _kWarmupRuns; i++) {
    await _measureOne(tester, html);
  }
  final times = <int>[];
  for (int i = 0; i < _kMeasureRuns; i++) {
    times.add(await _measureOne(tester, html));
  }
  times.sort();
  return times;
}

int _median(List<int> sorted) => sorted[sorted.length ~/ 2];
int _p95(List<int> sorted) => sorted[(sorted.length * 0.95).floor()];

// ── Result serialisation ──────────────────────────────────────────────────────

final _results = <Map<String, dynamic>>[];

void _record(
  String name,
  List<int> times, {
  required int thresholdMs,
}) {
  final med = _median(times);
  final p95 = _p95(times);
  final passed = med <= thresholdMs;

  _results.add({
    'fixture': name,
    'threshold_ms': thresholdMs,
    'median_ms': med,
    'p95_ms': p95,
    'min_ms': times.first,
    'max_ms': times.last,
    'runs': times.length,
    'passed': passed,
  });

  final icon = passed ? '✓' : '✗';
  final status = passed
      ? 'PASS  (median ${med}ms ≤ ${thresholdMs}ms)'
      : 'FAIL  (median ${med}ms > ${thresholdMs}ms — budget exceeded!)';

  print('  $icon  ${name.padRight(22)} $status   p95=${p95}ms');
}

void _writeResults() {
  final dir = Directory('benchmark/results');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final ts = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
  final file = File('benchmark/results/layout_$ts.json');
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'generated_at': ts,
      'flutter_version': Platform.environment['FLUTTER_VERSION'] ?? 'unknown',
      'results': _results,
    }),
  );
  print('\n  Results saved → ${file.path}');
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  print('\n${'═' * 64}');
  print('  HyperRender Layout Regression Benchmark');
  print('  Budget: 16 ms per layout pass (60 FPS)');
  print('${'═' * 64}');

  tearDownAll(_writeResults);

  group('Layout regression — 60 FPS budget', () {
    testWidgets('simple_paragraph', (tester) async {
      final times = await _bench(tester, _kSimpleParagraph);
      _record('simple_paragraph', times,
          thresholdMs: _kThresholds['simple_paragraph']!);
      expect(
        _median(times),
        lessThanOrEqualTo(_kThresholds['simple_paragraph']!),
        reason: 'simple_paragraph layout median exceeded '
            '${_kThresholds["simple_paragraph"]}ms budget',
      );
    });

    testWidgets('mixed_inline', (tester) async {
      final times = await _bench(tester, _kMixedInline);
      _record('mixed_inline', times,
          thresholdMs: _kThresholds['mixed_inline']!);
      expect(
        _median(times),
        lessThanOrEqualTo(_kThresholds['mixed_inline']!),
        reason: 'mixed_inline layout median exceeded '
            '${_kThresholds["mixed_inline"]}ms budget',
      );
    });

    testWidgets('float_layout', (tester) async {
      final times = await _bench(tester, _kFloatLayout);
      _record('float_layout', times,
          thresholdMs: _kThresholds['float_layout']!);
      expect(
        _median(times),
        lessThanOrEqualTo(_kThresholds['float_layout']!),
        reason: 'float_layout layout median exceeded '
            '${_kThresholds["float_layout"]}ms budget',
      );
    });

    testWidgets('table_20_rows', (tester) async {
      final times = await _bench(tester, _kTable20Rows);
      _record('table_20_rows', times,
          thresholdMs: _kThresholds['table_20_rows']!);
      expect(
        _median(times),
        lessThanOrEqualTo(_kThresholds['table_20_rows']!),
        reason: 'table_20_rows layout median exceeded '
            '${_kThresholds["table_20_rows"]}ms budget',
      );
    });

    testWidgets('cjk_ruby', (tester) async {
      final times = await _bench(tester, _kCjkRuby);
      _record('cjk_ruby', times, thresholdMs: _kThresholds['cjk_ruby']!);
      expect(
        _median(times),
        lessThanOrEqualTo(_kThresholds['cjk_ruby']!),
        reason: 'cjk_ruby layout median exceeded '
            '${_kThresholds["cjk_ruby"]}ms budget',
      );
    });

    testWidgets('large_article', (tester) async {
      final times = await _bench(tester, _kLargeArticle);
      _record('large_article', times,
          thresholdMs: _kThresholds['large_article']!);
      expect(
        _median(times),
        lessThanOrEqualTo(_kThresholds['large_article']!),
        reason: 'large_article layout median exceeded '
            '${_kThresholds["large_article"]}ms budget — '
            'check _performLineLayout for O(N²) regressions',
      );
    });
  });
}
