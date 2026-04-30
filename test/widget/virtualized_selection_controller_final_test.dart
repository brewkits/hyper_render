import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/src/widgets/virtualized_selection_controller.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('VirtualizedSelectionController Comprehensive Final', () {
    late VirtualizedSelectionController controller;
    late List<DocumentNode> sections;

    setUp(() {
      sections = [
        DocumentNode(children: [
          BlockNode.p(children: [TextNode('Chunk 0')])
        ]),
        DocumentNode(children: [
          BlockNode.p(children: [TextNode('Chunk 1')])
        ]),
      ];
      controller = VirtualizedSelectionController(
        sectionsGetter: () => sections,
        listViewKey: GlobalKey(),
      );
    });

    test('getters return null when no selection', () {
      expect(controller.startHandleRectInStack, isNull);
      expect(controller.endHandleRectInStack, isNull);
      expect(controller.topmostSelectionRectInStack, isNull);
    });

    test('selectAll and getters', () {
      controller.selectAll();
      // Even without RenderBoxes, the getters should not crash
      controller.startHandleRectInStack;
      controller.endHandleRectInStack;
      controller.topmostSelectionRectInStack;
      expect(controller.hasSelection, isTrue);
    });

    test('notifyHandleRectsChanged triggers listeners', () {
      int count = 0;
      controller.addListener(() => count++);
      controller.notifyHandleRectsChanged();
      expect(count, 1);
    });

    test('updateSelectionFromHandle returns early if no selection', () {
      controller.updateSelectionFromHandle(true, Offset.zero);
      expect(controller.hasSelection, isFalse);
    });

    test('getSelectedText with off-screen chunks', () {
      controller.selectAll();
      final text = controller.getSelectedText();
      expect(text, contains('Chunk 0'));
      expect(text, contains('Chunk 1'));
    });
  });
}
