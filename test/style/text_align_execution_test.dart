// Tests that CSS `text-align` actually EXECUTES for paragraph text painted on
// the RenderHyperBox canvas — previously it only applied to widget-tier
// content (table cells / flex), so <p style="text-align:center"> rendered
// left-aligned. Found while auditing flutter_html for feature parity.
//
// The critical correctness concern (per review): shifting fragment.offset for
// alignment must keep selection/hit-testing correct, since those read
// fragment.offset directly. The selection-rect test below asserts that.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

Future<RenderHyperBox> _render(WidgetTester tester, String html,
    {double width = 400}) async {
  final adapter = HtmlAdapter();
  final doc = adapter.parse(html);
  final resolver = StyleResolver();
  final css = adapter.extractCss(html);
  if (css.isNotEmpty) resolver.parseCss(css);
  resolver.resolveStyles(doc);
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

void main() {
  group('text-align executes on the canvas paragraph path', () {
    testWidgets('left < center < right shift the first fragment',
        (tester) async {
      final leftX = _firstTextX(
          await _render(tester, '<p style="text-align: left;">short text</p>'));
      final centerX = _firstTextX(await _render(
          tester, '<p style="text-align: center;">short text</p>'));
      final rightX = _firstTextX(await _render(
          tester, '<p style="text-align: right;">short text</p>'));

      expect(leftX, 0.0);
      expect(centerX!, greaterThan(leftX!));
      expect(rightX!, greaterThan(centerX));
    });

    testWidgets('right-aligned text ends near the right edge', (tester) async {
      final box =
          await _render(tester, '<p style="text-align: right;">abc</p>');
      final tf = box.debugFragments().firstWhere(
            (f) =>
                f['type'] == 'text' &&
                (f['text'] as String?)?.trim().isNotEmpty == true,
          );
      final rightEdge = (tf['offsetX'] as double) + (tf['width'] as double);
      // Should sit within a few px of the 400px container's right edge.
      expect(rightEdge, greaterThan(390));
      expect(rightEdge, lessThanOrEqualTo(400));
    });

    testWidgets('no text-align stays left-aligned', (tester) async {
      final x = _firstTextX(await _render(tester, '<p>default</p>'));
      expect(x, 0.0);
    });

    testWidgets('text-align inherits to inline children', (tester) async {
      final x = _firstTextX(await _render(
          tester, '<p style="text-align: center;">a <b>bold</b> c</p>'));
      expect(x!, greaterThan(0));
    });

    testWidgets('text-align via stylesheet rule', (tester) async {
      final x = _firstTextX(await _render(
          tester, '<style>p { text-align: center; }</style><p>centered</p>'));
      expect(x!, greaterThan(0));
    });
  });

  group('alignment stays consistent with selection/hit-testing', () {
    testWidgets(
        'selectAll on a centered paragraph yields rects in the centered region',
        (tester) async {
      // getSelectionRects() reads fragment.offset, the same field paint and
      // hit-testing read. If alignment shifted the paint but selection still
      // assumed left-packed, this rect would start at x≈0. It must instead
      // start where the centered glyphs actually are (x > 0).
      final box = await _render(
          tester, '<p style="text-align: center;">ABCDEFGHIJ</p>');
      box.selectAll();
      final rects = box.getSelectionRects();
      expect(rects, isNotEmpty);
      expect(rects.first.left, greaterThan(0),
          reason: 'selection rect must follow the centered text, not '
              'left-packed layout — proves hit-testing stays correct');
    });

    testWidgets('left-aligned selection still starts at x≈0', (tester) async {
      final box = await _render(tester, '<p>ABCDEFGHIJ</p>');
      box.selectAll();
      final rects = box.getSelectionRects();
      expect(rects, isNotEmpty);
      expect(rects.first.left, lessThan(2));
    });
  });
}
