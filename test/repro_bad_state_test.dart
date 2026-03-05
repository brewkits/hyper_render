import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  testWidgets('Reproduction: Bad state: No element in LineBreakingEngine', (WidgetTester tester) async {
    // A document where the first block has 0 top margin.
    final document = DocumentNode(children: [
      BlockNode(
        tagName: 'div',
        style: ComputedStyle(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(10),
        ),
        children: [
          TextNode('Hello World'),
        ],
      ),
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

    // Verify that layout succeeded without crash
    expect(tester.takeException(), isNull);
  });
}
