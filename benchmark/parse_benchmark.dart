// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

/// Benchmark for HTML parsing performance
///
/// Measures the time to parse HTML documents of various sizes
void main() {
  testWidgets('Benchmark: Parse 1KB HTML', (tester) async {
    final html = _generateHtml(size: 1024); // 1KB
    final stopwatch = Stopwatch();

    // Warm-up
    await _runBenchmark(tester, html);

    // Run benchmark 10 times
    final times = <int>[];
    for (int i = 0; i < 10; i++) {
      stopwatch.reset();
      stopwatch.start();
      await _runBenchmark(tester, html);
      stopwatch.stop();
      times.add(stopwatch.elapsedMilliseconds);
    }

    _printResults('Parse 1KB HTML', times);
  });

  testWidgets('Benchmark: Parse 10KB HTML', (tester) async {
    final html = _generateHtml(size: 10 * 1024); // 10KB
    final times = <int>[];

    // Warm-up
    await _runBenchmark(tester, html);

    for (int i = 0; i < 10; i++) {
      final stopwatch = Stopwatch()..start();
      await _runBenchmark(tester, html);
      stopwatch.stop();
      times.add(stopwatch.elapsedMilliseconds);
    }

    _printResults('Parse 10KB HTML', times);
  });

  testWidgets('Benchmark: Parse 50KB HTML', (tester) async {
    final html = _generateHtml(size: 50 * 1024); // 50KB
    final times = <int>[];

    // Warm-up
    await _runBenchmark(tester, html);

    for (int i = 0; i < 10; i++) {
      final stopwatch = Stopwatch()..start();
      await _runBenchmark(tester, html);
      stopwatch.stop();
      times.add(stopwatch.elapsedMilliseconds);
    }

    _printResults('Parse 50KB HTML', times);
  });

  testWidgets('Benchmark: Parse 100KB HTML', (tester) async {
    final html = _generateHtml(size: 100 * 1024); // 100KB
    final times = <int>[];

    // Warm-up
    await _runBenchmark(tester, html);

    for (int i = 0; i < 5; i++) {
      final stopwatch = Stopwatch()..start();
      await _runBenchmark(tester, html);
      stopwatch.stop();
      times.add(stopwatch.elapsedMilliseconds);
    }

    _printResults('Parse 100KB HTML', times);
  });

  testWidgets('Benchmark: Parse Complex HTML', (tester) async {
    final html = _generateComplexHtml();
    final times = <int>[];

    // Warm-up
    await _runBenchmark(tester, html);

    for (int i = 0; i < 10; i++) {
      final stopwatch = Stopwatch()..start();
      await _runBenchmark(tester, html);
      stopwatch.stop();
      times.add(stopwatch.elapsedMilliseconds);
    }

    _printResults('Parse Complex HTML (with tables, lists, styles)', times);
  });
}

Future<void> _runBenchmark(WidgetTester tester, String html) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HyperViewer(
          html: html,
          mode: HyperRenderMode.sync,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.pumpWidget(Container());
}

void _printResults(String testName, List<int> times) {
  times.sort();
  final min = times.first;
  final max = times.last;
  final avg = times.reduce((a, b) => a + b) / times.length;
  final median = times[times.length ~/ 2];
  final p95 = times[(times.length * 0.95).floor()];

  print('\n${'=' * 60}');
  print('$testName Results:');
  print('  Runs: ${times.length}');
  print('  Min:    ${min.toString().padLeft(4)}ms');
  print('  Median: ${median.toString().padLeft(4)}ms');
  print('  Avg:    ${avg.toStringAsFixed(1).padLeft(6)}ms');
  print('  P95:    ${p95.toString().padLeft(4)}ms');
  print('  Max:    ${max.toString().padLeft(4)}ms');
  print('=' * 60);
}

String _generateHtml({required int size}) {
  final buffer = StringBuffer('<div>');

  // Generate paragraphs until we reach target size
  int currentSize = buffer.length;
  int counter = 1;

  while (currentSize < size) {
    final paragraph =
        '<p>Paragraph $counter: Lorem ipsum dolor sit amet, consectetur '
        'adipiscing elit. Sed do eiusmod tempor incididunt ut labore et '
        'dolore magna aliqua.</p>\n';

    buffer.write(paragraph);
    currentSize += paragraph.length;
    counter++;
  }

  buffer.write('</div>');
  return buffer.toString();
}

String _generateComplexHtml() {
  return '''
<article>
  <h1>Complex HTML Document</h1>

  <section>
    <h2>Section with Table</h2>
    <table border="1" style="width: 100%; border-collapse: collapse;">
      <thead>
        <tr>
          <th>Column 1</th>
          <th>Column 2</th>
          <th>Column 3</th>
        </tr>
      </thead>
      <tbody>
        ${List.generate(20, (i) => '''
        <tr>
          <td>Data ${i + 1}-1</td>
          <td>Data ${i + 1}-2</td>
          <td>Data ${i + 1}-3</td>
        </tr>
        ''').join()}
      </tbody>
    </table>
  </section>

  <section>
    <h2>Section with Lists</h2>
    <ul>
      ${List.generate(50, (i) => '<li>List item ${i + 1}</li>').join('\n')}
    </ul>
  </section>

  <section>
    <h2>Section with Styled Content</h2>
    ${List.generate(30, (i) => '''
    <p style="color: #333; font-size: 16px; line-height: 1.5;">
      Paragraph ${i + 1} with <strong>bold text</strong>, <em>italic text</em>,
      and <a href="https://example.com">links</a>.
    </p>
    ''').join('\n')}
  </section>

  <section>
    <h2>Section with Nested Divs</h2>
    <div style="padding: 10px; background: #f0f0f0;">
      <div style="padding: 10px; background: #e0e0e0;">
        <div style="padding: 10px; background: #d0d0d0;">
          <div style="padding: 10px; background: #c0c0c0;">
            <p>Deeply nested content</p>
          </div>
        </div>
      </div>
    </div>
  </section>
</article>
''';
}
