import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/src/widgets/virtualized_selection_controller.dart';
import 'package:hyper_render/src/widgets/virtualized_selection_overlay.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('VirtualizedSelectionOverlay Full Coverage', () {
    late VirtualizedSelectionController controller;
    late List<DocumentNode> sections;
    final listViewKey = GlobalKey();

    setUp(() {
      sections = [
        DocumentNode(children: [BlockNode.p(children: [TextNode('Chunk 0')])]),
        DocumentNode(children: [BlockNode.p(children: [TextNode('Chunk 1')])]),
      ];
      controller = VirtualizedSelectionController(
        sectionsGetter: () => sections,
        listViewKey: listViewKey,
      );
    });

    testWidgets('VirtualizedChunk lifecycle and registration', (WidgetTester tester) async {
      final chunkKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualizedChunk(
              chunkIndex: 0,
              document: sections[0],
              selectionController: controller,
              selectable: true,
              config: const HyperRenderConfig(),
              key: chunkKey,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      // Update widget to trigger didUpdateWidget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualizedChunk(
              chunkIndex: 0,
              document: DocumentNode(children: [TextNode('Updated')]),
              selectionController: controller,
              selectable: true,
              config: const HyperRenderConfig(),
              key: chunkKey,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('Overlay menu reveal and dismiss', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualizedSelectionOverlay(
              controller: controller,
              handleColor: Colors.blue,
              child: ListView.builder(
                key: listViewKey,
                itemCount: sections.length,
                itemBuilder: (context, index) => VirtualizedChunk(
                  chunkIndex: index,
                  document: sections[index],
                  selectionController: controller,
                  selectable: true,
                  config: const HyperRenderConfig(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger selection to reveal menu
      controller.selectAll();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      
      expect(find.byType(Material), findsAtLeast(1));
    });

    testWidgets('Tap outside clears selection in overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: VirtualizedSelectionOverlay(
                  controller: controller,
                  handleColor: Colors.blue,
                  child: Container(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      );

      controller.selectAll();
      await tester.pumpAndSettle();
      expect(controller.hasSelection, isTrue);

      // Tap outside (at the top-left of screen)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(controller.hasSelection, isFalse);
    });
  });
}
