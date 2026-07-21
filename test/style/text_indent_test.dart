// Tests that CSS `text-indent` executes — it previously had zero code
// references despite CSS_PROPERTIES_MATRIX.md claiming ✅ support. Found while
// auditing flutter_html for feature parity.
//
// text-indent shifts the FIRST line of a block only; it inherits per CSS.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

Future<RenderHyperBox> _render(WidgetTester tester, String html,
    {double width = 400}) async {
  final doc = HtmlAdapter().parse(html);
  StyleResolver().resolveStyles(doc);
  RenderHyperBox? box;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: HyperRenderWidget(
          document: doc,
          selectable: true,
          onRenderBoxReady: (b) => box = b,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return box!;
}

double? _firstTextX(RenderHyperBox box) {
  final tf = box.debugFragments().firstWhere(
        (f) =>
            f['type'] == 'text' &&
            (f['text'] as String?)?.trim().isNotEmpty == true,
        orElse: () => <String, dynamic>{},
      );
  return tf['offsetX'] as double?;
}

/// First (leftmost) x of each visual line, derived from selection rects so it
/// works even when text wraps (debugFragments exposes only un-split fragments).
List<double> _perLineFirstX(RenderHyperBox box) {
  box.selectAll();
  final byLine = <double, double>{};
  for (final r in box.getSelectionRects()) {
    if (!byLine.containsKey(r.top) || r.left < byLine[r.top]!) {
      byLine[r.top] = r.left;
    }
  }
  final entries = byLine.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((e) => e.value).toList();
}

void main() {
  group('text-indent executes', () {
    testWidgets('px indent shifts the first line', (tester) async {
      final none = _firstTextX(await _render(tester, '<p>hi</p>'));
      final indented = _firstTextX(
          await _render(tester, '<p style="text-indent: 40px;">hi</p>'));
      expect(none, 0.0);
      expect(indented, 40.0);
    });

    testWidgets('em indent resolves against root font-size', (tester) async {
      final indented = _firstTextX(
          await _render(tester, '<p style="text-indent: 2em;">hi</p>'));
      expect(indented, 32.0); // 2em × 16px root
    });

    testWidgets('only the first line is indented, wrapped lines are not',
        (tester) async {
      final box = await _render(
        tester,
        '<p style="text-indent: 30px;">word1 word2 word3 word4 word5 word6</p>',
        width: 150,
      );
      final xs = _perLineFirstX(box);
      expect(xs.length, greaterThan(1), reason: 'text should wrap');
      expect(xs.first, closeTo(30, 2));
      expect(xs[1], closeTo(0, 2));
    });

    testWidgets('text-indent inherits to inline children', (tester) async {
      final indented = _firstTextX(await _render(
          tester, '<p style="text-indent: 25px;"><b>bold</b> start</p>'));
      expect(indented, 25.0);
    });

    testWidgets('no text-indent leaves the first line flush', (tester) async {
      final x = _firstTextX(await _render(tester, '<p>plain</p>'));
      expect(x, 0.0);
    });

    testWidgets('each block gets its own first-line indent', (tester) async {
      final box = await _render(
        tester,
        '<p style="text-indent: 20px;">first</p>'
        '<p style="text-indent: 20px;">second</p>',
      );
      // Both paragraphs' single lines should be indented (independent blocks).
      final xs = _perLineFirstX(box);
      expect(xs.length, 2);
      expect(xs[0], closeTo(20, 2));
      expect(xs[1], closeTo(20, 2));
    });
  });
}
