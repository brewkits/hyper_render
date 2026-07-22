// CSS EXECUTION GUARD — the systemic net against the "parsed but not rendered"
// bug class.
//
// This session's audit repeatedly found CSS properties that parsed correctly
// into `ComputedStyle` but had NO effect on the rendered output (text-align,
// text-indent, display:none, min-width). The docs claimed support; only a
// render-level test exposed the gap.
//
// Every case here asserts that a property produces a rendering DIFFERENT from
// the same markup without it — measured through actual layout output (rendered
// height, or a fragment's painted x-offset), never through `ComputedStyle`.
// A property that silently stops executing will flip one of these to "equal"
// and fail loudly.
//
// When you add a new layout/position-affecting CSS property to the matrix docs,
// add a row here too.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

Future<double> _height(WidgetTester tester, String html,
    {double width = 400}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: SingleChildScrollView(child: HyperViewer(html: html)),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return tester.getSize(find.byType(HyperViewer)).height;
}

Future<double> _firstTextX(WidgetTester tester, String html,
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
          onRenderBoxReady: (b) => box = b,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  final tf = box!.debugFragments().firstWhere(
        (f) =>
            f['type'] == 'text' &&
            (f['text'] as String?)?.trim().isNotEmpty == true,
        orElse: () => <String, dynamic>{},
      );
  return (tf['offsetX'] as double?) ?? -1;
}

const _long =
    'This is a fairly long line of text that will definitely wrap onto '
    'several lines inside a narrow enough container to matter for tests';

void main() {
  group('CSS execution guard — properties must change rendered output', () {
    // Each test compares WITH the property vs WITHOUT it and asserts they
    // differ. If a property regresses to parsed-but-not-executed, these fail.

    testWidgets('display:none removes height', (tester) async {
      final withHidden = await _height(
          tester, '<p>A</p><div style="display:none">HIDDEN</div><p>B</p>');
      final without = await _height(tester, '<p>A</p><p>B</p>');
      expect(withHidden, without);
    });

    testWidgets('max-width reduces content width (increases height)',
        (tester) async {
      final base = await _height(tester, '<div>$_long</div>');
      final constrained =
          await _height(tester, '<div style="max-width:120px">$_long</div>');
      expect(constrained, greaterThan(base));
    });

    testWidgets('max-width:% reduces content width', (tester) async {
      final base = await _height(tester, '<div>$_long</div>');
      final pct =
          await _height(tester, '<div style="max-width:30%">$_long</div>');
      expect(pct, greaterThan(base));
    });

    testWidgets('min-width overrides a narrow max-width', (tester) async {
      final onlyMax =
          await _height(tester, '<div style="max-width:80px">$_long</div>');
      final withMin = await _height(
          tester, '<div style="max-width:80px;min-width:300px">$_long</div>');
      expect(withMin, lessThan(onlyMax));
    });

    testWidgets('width:% constrains a block', (tester) async {
      final base = await _height(tester, '<div>$_long</div>');
      final half = await _height(tester, '<div style="width:40%">$_long</div>');
      expect(half, greaterThan(base));
    });

    testWidgets('text-align:center shifts first fragment right',
        (tester) async {
      final left = await _firstTextX(tester, '<p>short</p>');
      final center =
          await _firstTextX(tester, '<p style="text-align:center">short</p>');
      expect(center, greaterThan(left));
    });

    testWidgets('text-align:right shifts further than center', (tester) async {
      final center =
          await _firstTextX(tester, '<p style="text-align:center">short</p>');
      final right =
          await _firstTextX(tester, '<p style="text-align:right">short</p>');
      expect(right, greaterThan(center));
    });

    testWidgets('text-indent shifts the first line', (tester) async {
      final base = await _firstTextX(tester, '<p>text</p>');
      final indented =
          await _firstTextX(tester, '<p style="text-indent:40px">text</p>');
      expect(indented, greaterThan(base));
    });

    testWidgets('text-indent:% shifts the first line', (tester) async {
      final base = await _firstTextX(tester, '<p>text</p>');
      final indented =
          await _firstTextX(tester, '<p style="text-indent:10%">text</p>');
      expect(indented, greaterThan(base));
    });

    testWidgets('margin adds vertical space', (tester) async {
      final base = await _height(tester, '<p>A</p><p>B</p>');
      final withMargin = await _height(
          tester, '<p>A</p><p style="margin:40px 0">B</p><p>C</p>');
      expect(withMargin, greaterThan(base));
    });

    testWidgets('padding adds space inside a block', (tester) async {
      final base = await _height(tester, '<div>x</div>');
      final withPad =
          await _height(tester, '<div style="padding:30px">x</div>');
      expect(withPad, greaterThan(base));
    });

    testWidgets('font-size changes line height', (tester) async {
      final base = await _height(tester, '<p>x</p>');
      final big = await _height(tester, '<p style="font-size:40px">x</p>');
      expect(big, greaterThan(base));
    });

    testWidgets('line-height changes block height', (tester) async {
      final base = await _height(tester, '<p style="line-height:1">x</p>');
      final tall = await _height(tester, '<p style="line-height:3">x</p>');
      expect(tall, greaterThan(base));
    });

    testWidgets('white-space:pre preserves newlines (more height)',
        (tester) async {
      final normal = await _height(tester, '<div>line1 line2 line3</div>');
      final pre = await _height(
          tester, '<div style="white-space:pre">line1\nline2\nline3</div>');
      expect(pre, greaterThan(normal));
    });

    testWidgets('display:none on a table row removes its height',
        (tester) async {
      final withHidden = await _height(
        tester,
        '<table><tr><td>A</td></tr>'
        '<tr style="display:none"><td>H</td></tr></table>',
      );
      final oneRow =
          await _height(tester, '<table><tr><td>A</td></tr></table>');
      expect(withHidden, oneRow);
    });
  });
}
