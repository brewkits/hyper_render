import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

/// Regression tests for the v1.3.2 table review:
///   Bug 1 — when no `cellContentBuilder` is supplied, a cell containing
///           a `<div>` (BlockNode) must NOT silently disappear.
///   Issue 3 — a table whose `rowCount * columnCount` exceeds the
///             100 000-cell cap must render a "too large" placeholder
///             instead of allocating millions of `null` refs on the UI
///             thread.
void main() {
  group('Bug 1 — cell block-content fallback', () {
    testWidgets('cell with <div> renders the inner text when builder is null',
        (tester) async {
      // Build a table with a single cell whose child is a BlockNode wrapping
      // a TextNode. Before the fix this rendered an empty cell.
      final table = TableNode(children: [
        TableRowNode(children: [
          TableCellNode(children: [
            BlockNode.div(children: [TextNode('block content here')]),
          ]),
        ]),
      ]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperTable(tableNode: table), // no cellContentBuilder
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('block content here'), findsOneWidget,
          reason: 'block content must surface via default fallback');
    });

    testWidgets('cell with inline + block renders both', (tester) async {
      final table = TableNode(children: [
        TableRowNode(children: [
          TableCellNode(children: [
            TextNode('inline first'),
            BlockNode.div(children: [TextNode('then block')]),
          ]),
        ]),
      ]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: HyperTable(tableNode: table)),
      ));
      await tester.pumpAndSettle();

      // Inline part is in a Text.rich (combined with block-fallback Text).
      // We assert both visible strings appear somewhere in the tree.
      final allText = find
          .byType(Text)
          .evaluate()
          .map((e) {
            final w = e.widget as Text;
            if (w.data != null) return w.data!;
            return w.textSpan?.toPlainText() ?? '';
          })
          .join('|');
      expect(allText, contains('inline first'));
      expect(allText, contains('then block'));
    });

    testWidgets('supplied cellContentBuilder still wins over fallback',
        (tester) async {
      final table = TableNode(children: [
        TableRowNode(children: [
          TableCellNode(children: [
            BlockNode.div(children: [TextNode('original')]),
          ]),
        ]),
      ]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperTable(
            tableNode: table,
            cellContentBuilder: (cellNode) => const Text('replaced by builder'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('replaced by builder'), findsOneWidget);
      expect(find.text('original'), findsNothing);
    });
  });

  group('Issue 3 — total-cell cap', () {
    testWidgets('huge table is replaced with a "too large" placeholder',
        (tester) async {
      // Construct a table whose grid would be 400 × 400 = 160 000 cells —
      // above the 100 000 cap. With per-cell colspan limited to 1000, this
      // simulates a malicious / generated document.
      const rows = 400;
      const cols = 400;
      final table = TableNode(children: [
        for (int r = 0; r < rows; r++)
          TableRowNode(children: [
            for (int c = 0; c < cols; c++)
              TableCellNode(children: [TextNode('$r,$c')]),
          ]),
      ]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: SingleChildScrollView(
              child: HyperTable(tableNode: table),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Table too large'), findsOneWidget,
          reason: 'cap must surface a visible placeholder');
      // And the actual cell content must NOT have been rendered.
      expect(find.text('0,0'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('table just under the cap still renders cells', (tester) async {
      // 50 × 50 = 2500 cells — well under the cap.
      const rows = 50;
      const cols = 50;
      final table = TableNode(children: [
        for (int r = 0; r < rows; r++)
          TableRowNode(children: [
            for (int c = 0; c < cols; c++)
              TableCellNode(children: [TextNode('$r-$c')]),
          ]),
      ]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1600,
            height: 1600,
            child: SingleChildScrollView(
              child: HyperTable(tableNode: table),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // First cell visible somewhere in the scroll view.
      expect(find.text('0-0'), findsOneWidget);
      expect(find.textContaining('Table too large'), findsNothing);
    });
  });
}
