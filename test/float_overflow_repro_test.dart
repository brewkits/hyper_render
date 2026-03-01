import "package:hyper_render/hyper_render.dart";
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Float should drop down when horizontal space is insufficient', (WidgetTester tester) async {
    // Scenario: Two left floats that combined are wider than the container.
    // The second float should drop below the first one.
    
    const double containerWidth = 300.0;
    const String html = '''
      <div style="width: 300px;">
        <div style="float: left; width: 200px; height: 50px; background: red;">F1</div>
        <div style="float: left; width: 150px; height: 50px; background: blue;">F2</div>
      </div>
    ''';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: containerWidth,
              child: HyperViewer(html: html),
            ),
          ),
        ),
      ),
    );

    // Wait for everything to settle
    await tester.pumpAndSettle();

    // Find the RenderHyperBox
    final renderBox = tester.renderObject<RenderHyperBox>(find.byType(HyperRenderWidget));
    
    // In a correct CSS engine:
    // F1: top=0, left=0, width=200
    // F2: should be at top=50, left=0, width=150 (because 200+150 > 300)
    
    // The fragments are private, but we can check the children positions.
    // HyperRenderWidget has child RenderBoxes for each atomic element/float.
    
    final List<RenderBox> children = [];
    renderBox.visitChildren((child) {
      if (child is RenderBox) children.add(child);
    });

    expect(children.length, equals(2), reason: 'Should have 2 float children');
    
    final f1Pos = (children[0].parentData as HyperBoxParentData).offset;
    final f2Pos = (children[1].parentData as HyperBoxParentData).offset;

    print('F1 position: $f1Pos');
    print('F2 position: $f2Pos');

    // F1 should be at (0, 0)
    expect(f1Pos, equals(Offset.zero));
    
    // F2 should NOT be at (200, 0) because that overflows 300px.
    // It should be at (0, 50) - dropping down.
    expect(f2Pos.dx, lessThanOrEqualTo(10.0), reason: 'F2 should drop to the left side of the next line');
    expect(f2Pos.dy, greaterThanOrEqualTo(50.0), reason: 'F2 should drop below F1');
  });
}
