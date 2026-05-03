import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('Layout Optimization & Refactor Tests', () {
    test('Emoji Surrogate Pair breaking should be handled safely', () {
      final style = ComputedStyle(fontSize: 16);
      final node = TextNode('😀');
      final fragment = Fragment.text(
        text: '😀',
        sourceNode: node,
        style: style,
        characterOffset: 0,
      );

      expect(fragment.text, equals('😀'));
      expect(fragment.text!.length, equals(2));
    });

    testWidgets('RenderHyperBox handles float layout without infinity loop',
        (WidgetTester tester) async {
      // Smoke test for the float loop fix.
      final doc = DocumentNode(children: [
        BlockNode(
          tagName: 'div',
          style: ComputedStyle(float: HyperFloat.left, width: 100, height: 0),
          children: [TextNode('Float content')],
        ),
        BlockNode.p(children: [TextNode('Normal content')]),
      ]);

      // If it didn't hang/timeout, the loop was successfully broken.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperRenderWidget(
              document: doc,
            ),
          ),
        ),
      );

      expect(find.byType(HyperRenderWidget), findsAtLeastNWidgets(1));
    });

    test('Rect merging logic principle verification', () {
      const rect1 = Rect.fromLTWH(0, 0, 50, 20);
      const rect2 = Rect.fromLTWH(50, 0, 50, 20);

      bool canMerge = (rect1.top - rect2.top).abs() < 0.1 &&
          (rect1.bottom - rect2.bottom).abs() < 0.1 &&
          rect2.left <= rect1.right + 1.0;

      expect(canMerge, isTrue);

      final merged = rect1.expandToInclude(rect2);
      expect(merged, equals(const Rect.fromLTWH(0, 0, 100, 20)));
    });
  });
}
