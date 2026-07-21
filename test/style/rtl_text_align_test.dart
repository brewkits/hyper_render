// Parse⇒render tests for explicit `text-align` on a box-level RTL tree
// (`HyperRenderWidget(textDirection: TextDirection.rtl)`).
//
// RTL defaults to `start` = right-packed. Previously an explicit `text-align`
// on an RTL paragraph was ignored (everything right-packed). Now an explicit
// value overrides — but an UNSET RTL paragraph still right-packs, so the
// common RTL case is unchanged. The explicit flag is read from the block
// ancestor, since the line's text fragment merely inherited the value.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

Future<RenderHyperBox> _rtlBox(WidgetTester tester, String html,
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
          textDirection: TextDirection.rtl,
          selectable: true,
          onRenderBoxReady: (b) => box = b,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return box!;
}

double _firstTextX(RenderHyperBox box) {
  final tf = box.debugFragments().firstWhere(
        (f) =>
            f['type'] == 'text' &&
            (f['text'] as String?)?.trim().isNotEmpty == true,
        orElse: () => <String, dynamic>{},
      );
  return (tf['offsetX'] as double?) ?? -1;
}

double _rightEdge(RenderHyperBox box) {
  box.selectAll();
  var maxR = 0.0;
  for (final r in box.getSelectionRects()) {
    if (r.right > maxR) maxR = r.right;
  }
  return maxR;
}

void main() {
  group('box-level RTL text-align', () {
    testWidgets('unset RTL paragraph right-packs (default = start)',
        (tester) async {
      final box = await _rtlBox(tester, '<p>short</p>');
      expect(_rightEdge(box), greaterThan(380));
    });

    testWidgets('explicit text-align:left left-packs on RTL', (tester) async {
      final box =
          await _rtlBox(tester, '<p style="text-align:left;">short</p>');
      expect(_firstTextX(box), closeTo(0, 2));
    });

    testWidgets('explicit text-align:center centers on RTL', (tester) async {
      final box =
          await _rtlBox(tester, '<p style="text-align:center;">short</p>');
      final x = _firstTextX(box);
      expect(x, greaterThan(50));
      // not flush to either edge
      expect(x, lessThan(350));
    });

    testWidgets('explicit text-align:right keeps the RTL start edge',
        (tester) async {
      final box =
          await _rtlBox(tester, '<p style="text-align:right;">short</p>');
      expect(_rightEdge(box), greaterThan(380));
    });

    testWidgets('text-align set on a wrapping div also overrides',
        (tester) async {
      final box = await _rtlBox(
          tester, '<div style="text-align:left;"><p>short</p></div>');
      expect(_firstTextX(box), closeTo(0, 2));
    });
  });
}
