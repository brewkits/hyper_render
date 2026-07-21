// Parse⇒render tests for CSS `text-align: justify`. Justify distributes free
// space across a line's inter-word gaps (by widening each space) so every
// line except the last reaches the right edge. The trailing space left over
// from wrapping is excluded, so the last visible glyph lands exactly at the
// edge — matching browsers.
//
// The critical correctness concern is that paint, selection, and hit-testing
// all use the SAME justified word-spacing as the position pass (via
// `_effectiveFragmentStyle`). The selection test below guards that.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

Future<RenderHyperBox> _box(WidgetTester tester, String html,
    {double width = 250}) async {
  final doc = HtmlAdapter().parse(html);
  StyleResolver().resolveStyles(doc);
  RenderHyperBox? box;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: HyperRenderWidget(
            document: doc,
            selectable: true,
            onRenderBoxReady: (b) => box = b,
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return box!;
}

/// Rightmost selection-rect edge for each visual line (keyed by line top).
List<MapEntry<double, double>> _lineRightEdges(RenderHyperBox box) {
  box.selectAll();
  final m = <double, double>{};
  for (final r in box.getSelectionRects()) {
    if (!m.containsKey(r.top) || r.right > m[r.top]!) m[r.top] = r.right;
  }
  final entries = m.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return entries;
}

const _text =
    'The quick brown fox jumps over the lazy dog and then keeps running '
    'along the road past the old house';

void main() {
  group('text-align: justify executes', () {
    testWidgets('every line but the last reaches the right edge',
        (tester) async {
      final box =
          await _box(tester, '<p style="text-align: justify;">$_text</p>');
      final edges = _lineRightEdges(box);
      expect(edges.length, greaterThan(1), reason: 'text should wrap');

      // Discover the justified target from the widest line (the container's
      // effective content width), then assert every non-last line hits it.
      final target = edges.map((e) => e.value).reduce((a, b) => a > b ? a : b);
      for (var i = 0; i < edges.length - 1; i++) {
        expect(edges[i].value, closeTo(target, 1.0),
            reason: 'line $i must be justified to the edge');
      }
      // The last line is left at natural width (not stretched to the edge).
      expect(edges.last.value, lessThan(target - 5));
    });

    testWidgets('left-aligned control is ragged-right (not justified)',
        (tester) async {
      final box = await _box(tester, '<p style="text-align: left;">$_text</p>');
      final edges = _lineRightEdges(box);
      final target = edges.map((e) => e.value).reduce((a, b) => a > b ? a : b);
      // At least one non-last line falls short of the widest — a ragged edge.
      final anyRagged = [
        for (var i = 0; i < edges.length - 1; i++) edges[i].value
      ].any((e) => e < target - 5);
      expect(anyRagged, isTrue);
    });

    testWidgets('single unbroken word is not justified and does not crash',
        (tester) async {
      final box = await _box(
          tester, '<p style="text-align: justify;">Supercalifragilistic</p>');
      expect(box.getSelectionRects, returnsNormally);
    });

    testWidgets('a one-line justify paragraph is left at natural width',
        (tester) async {
      // A paragraph that fits on one line is its own last line → not stretched.
      final box = await _box(
          tester, '<p style="text-align: justify;">short</p>',
          width: 400);
      final edges = _lineRightEdges(box);
      expect(edges.length, 1);
      expect(edges.first.value, lessThan(100));
    });
  });

  group('justify stays consistent with selection', () {
    testWidgets('selectAll reads back the full text on justified lines',
        (tester) async {
      final box =
          await _box(tester, '<p style="text-align: justify;">$_text</p>');
      box.selectAll();
      final selected = box.getSelectedText() ?? '';
      expect(selected.replaceAll(RegExp(r'\s+'), ' ').trim(), _text);
    });
  });
}
