import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  testWidgets('Complex float should render internal text', (WidgetTester tester) async {
    final document = DocumentNode(children: [
      BlockNode(
        tagName: 'div',
        style: ComputedStyle(
          float: HyperFloat.left,
          width: 200,
        ),
        children: [
          TextNode('Float Content'),
        ],
      ),
      TextNode('Main Flow'),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HyperRenderWidget(
            document: document,
          ),
        ),
      ),
    );

    // Previously, 'Float Content' would be lost because it was inside a float div
    // and _collectAtomicChildren didn't handle text nodes.
    // Now it should be rendered via a nested HyperRenderWidget.
    expect(find.byType(HyperRenderWidget), findsNWidgets(2)); // Outer + Inner
  });
}
