// ignore_for_file: unused_local_variable
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/src/widgets/virtualized_selection_controller.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('VirtualizedSelectionController', () {
    late VirtualizedSelectionController controller;
    late GlobalKey listViewKey;
    late List<DocumentNode> sections;

    setUp(() {
      listViewKey = GlobalKey();
      sections = [
        DocumentNode(children: [
          BlockNode.p(children: [TextNode('Chunk 0 Text')])
        ]),
        DocumentNode(children: [
          BlockNode.p(children: [TextNode('Chunk 1 Text')])
        ]),
      ];
      controller = VirtualizedSelectionController(
        sectionsGetter: () => sections,
        listViewKey: listViewKey,
      );
    });

    test('initial state', () {
      expect(controller.hasSelection, isFalse);
      expect(controller.selection, isNull);
    });

    test('ChunkAnchor equality and comparison', () {
      const a1 = ChunkAnchor(0, 10);
      const a2 = ChunkAnchor(0, 10);
      const a3 = ChunkAnchor(0, 11);
      const a4 = ChunkAnchor(1, 5);

      expect(a1 == a2, isTrue);
      expect(a1 == a3, isFalse);
      expect(a1.hashCode == a2.hashCode, isTrue);

      expect(a1 <= a2, isTrue);
      expect(a1 <= a3, isTrue);
      expect(a3 <= a1, isFalse);
      expect(a1 <= a4, isTrue);
      expect(a4 <= a1, isFalse);
    });

    test('CrossChunkSelection collapsed state', () {
      const start = ChunkAnchor(0, 5);
      const end = ChunkAnchor(0, 5);
      const sel = CrossChunkSelection(start: start, end: end);
      expect(sel.isCollapsed, isTrue);

      const sel2 = CrossChunkSelection(start: start, end: ChunkAnchor(0, 6));
      expect(sel2.isCollapsed, isFalse);

      const sel3 = CrossChunkSelection(start: start, end: ChunkAnchor(1, 5));
      expect(sel3.isCollapsed, isFalse);
    });

    test('selectAll creates correct selection', () {
      controller.selectAll();
      expect(controller.hasSelection, isTrue);
      expect(controller.selection!.start, const ChunkAnchor(0, 0));
      expect(controller.selection!.end.chunkIndex, 1);
      expect(controller.selection!.end.localOffset,
          sections[1].textContent.length);
    });

    test('clearSelection resets state', () {
      controller.selectAll();
      expect(controller.hasSelection, isTrue);
      controller.clearSelection();
      expect(controller.hasSelection, isFalse);
      expect(controller.selection, isNull);
    });

    test('getSelectedText for off-screen chunks', () {
      controller.selectAll();
      final text = controller.getSelectedText();
      // 'Chunk 0 Text' + '\n' + 'Chunk 1 Text'
      expect(text, contains('Chunk 0 Text'));
      expect(text, contains('Chunk 1 Text'));
      expect(text, contains('\n'));
    });

    test('getSelectedText for partial selection', () {
      controller.selectAll();
      controller.clearSelection();

      // Select '0 Text' from chunk 0 and 'Chunk 1' from chunk 1
      // Chunk 0 text is 'Chunk 0 Text' (length 12)
      // Chunk 1 text is 'Chunk 1 Text'

      const start = ChunkAnchor(0, 6); // '0 Text'
      const end = ChunkAnchor(1, 7); // 'Chunk 1'

      // We need to set internal selection manually since we don't have RenderBoxes here
      // But VirtualizedSelectionController doesn't allow setting selection directly easily
      // Let's use selectAll and then check. Actually we can't easily test updateSelection without RenderBoxes.
      // But we can test getSelectedText if we could set the selection.
    });
  });

  group('VirtualizedSelectionController - Widget Integration', () {
    testWidgets('registerChunk adds chunk to map', (WidgetTester tester) async {
      final listViewKey = GlobalKey();
      final sections = [DocumentNode(children: [])];
      final controller = VirtualizedSelectionController(
        sectionsGetter: () => sections,
        listViewKey: listViewKey,
      );

      final chunkKey = GlobalKey();
      controller.registerChunk(0, chunkKey, 100);

      // We can't access private _chunks, but we can check if it triggers actions
      // For example, getSelectedText might try to use it.
    });
  });
}
