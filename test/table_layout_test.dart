import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

/// Tests for the W3C-inspired 2-pass table layout algorithm.
///
/// The algorithm is implemented in [RenderHyperTable._calculateColumnWidths].
/// Tests here verify the widget-level rendering via [HyperTable] and
/// [SmartTableWrapper] to ensure the table renders correctly with
/// content-driven column widths.
void main() {
  group('HyperTable layout', () {
    // -----------------------------------------------------------------------
    // Smoke tests — table renders without crash
    // -----------------------------------------------------------------------
    testWidgets('renders simple 2-column table', (tester) async {
      final tableNode = _buildSimpleTable([
        ['Column A', 'Column B'],
        ['Short', 'A longer cell value'],
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: HyperTable(tableNode: tableNode),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HyperTable), findsOneWidget);
    });

    testWidgets('renders table with 3 columns of different content widths',
        (tester) async {
      final tableNode = _buildSimpleTable([
        ['A', 'BB', 'CCC'], // short, medium, long header
        ['x', 'yy', 'zzz'],
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 300,
              child: HyperTable(tableNode: tableNode),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HyperTable), findsOneWidget);
    });

    testWidgets('renders single-column table', (tester) async {
      final tableNode = _buildSimpleTable([
        ['Only column'],
        ['row 1'],
        ['row 2'],
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: HyperTable(tableNode: tableNode),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HyperTable), findsOneWidget);
    });

    testWidgets('renders empty table gracefully', (tester) async {
      final emptyTable = TableNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: HyperTable(tableNode: emptyTable),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Empty table should render as SizedBox.shrink — no crash
      expect(find.byType(HyperTable), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // SmartTableWrapper
    // -----------------------------------------------------------------------
    testWidgets('SmartTableWrapper horizontalScroll strategy does not crash',
        (tester) async {
      final tableNode = _buildSimpleTable([
        ['Name', 'Email', 'Phone', 'Address', 'City'],
        [
          'Alice',
          'alice@example.com',
          '+1 555 0100',
          '123 Main St',
          'Springfield'
        ],
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 200,
              child: SmartTableWrapper(
                tableNode: tableNode,
                strategy: TableStrategy.horizontalScroll,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SmartTableWrapper), findsOneWidget);
    });

    testWidgets('SmartTableWrapper autoScale strategy does not crash',
        (tester) async {
      final tableNode = _buildSimpleTable([
        ['Col1', 'Col2', 'Col3'],
        ['a', 'b', 'c'],
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: SmartTableWrapper(
                tableNode: tableNode,
                strategy: TableStrategy.autoScale,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SmartTableWrapper), findsOneWidget);
    });

    testWidgets('SmartTableWrapper fitWidth strategy does not crash',
        (tester) async {
      final tableNode = _buildSimpleTable([
        ['A', 'B'],
        ['1', '2'],
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: SmartTableWrapper(
                tableNode: tableNode,
                strategy: TableStrategy.fitWidth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SmartTableWrapper), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // colspan / rowspan rendering
    // -----------------------------------------------------------------------
    testWidgets('table with colspan=2 renders without crash', (tester) async {
      // Row 1: merged header spanning 2 columns
      // Row 2: two normal cells
      final table = TableNode();
      final headerRow = TableRowNode();
      final mergedCell = TableCellNode(
        isHeader: true,
        attributes: {'colspan': '2'},
      );
      mergedCell.appendChild(TextNode('Merged Header'));
      headerRow.appendChild(mergedCell);
      table.appendChild(headerRow);

      final dataRow = TableRowNode();
      final cell1 = TableCellNode();
      cell1.appendChild(TextNode('Left'));
      final cell2 = TableCellNode();
      cell2.appendChild(TextNode('Right'));
      dataRow.appendChild(cell1);
      dataRow.appendChild(cell2);
      table.appendChild(dataRow);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: HyperTable(tableNode: table),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HyperTable), findsOneWidget);
    });

    testWidgets('table with rowspan=2 renders without crash', (tester) async {
      final table = TableNode();

      // Row 1: cell with rowspan=2, and a normal cell
      final row1 = TableRowNode();
      final spanCell = TableCellNode(attributes: {'rowspan': '2'});
      spanCell.appendChild(TextNode('Tall cell'));
      final normalCell1 = TableCellNode();
      normalCell1.appendChild(TextNode('R1C2'));
      row1.appendChild(spanCell);
      row1.appendChild(normalCell1);
      table.appendChild(row1);

      // Row 2: only one normal cell (the other is covered by rowspan)
      final row2 = TableRowNode();
      final normalCell2 = TableCellNode();
      normalCell2.appendChild(TextNode('R2C2'));
      row2.appendChild(normalCell2);
      table.appendChild(row2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: HyperTable(tableNode: table),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HyperTable), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // HyperViewer integration — table inside full rendering pipeline
    // -----------------------------------------------------------------------
    testWidgets('table inside HyperViewer renders without crash',
        (tester) async {
      const html = '''
<table>
  <thead>
    <tr>
      <th>Library</th>
      <th>Performance</th>
      <th>CSS</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>HyperRender</td>
      <td>Excellent — 60fps even on 800KB documents</td>
      <td>Essential subset</td>
    </tr>
    <tr>
      <td>flutter_widget_from_html</td>
      <td>Acceptable</td>
      <td>Basic</td>
    </tr>
  </tbody>
</table>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                semanticLabel: 'Comparison table',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HyperViewer), findsOneWidget);
      expect(find.bySemanticsLabel('Comparison table'), findsOneWidget);
    });

    testWidgets('HyperViewer table with long content in one column',
        (tester) async {
      // This exercises the 2-pass algorithm: column B has much more content
      // than column A, so it should receive more space.
      const html = '''
<table>
  <tr>
    <td>A</td>
    <td>This is a much longer cell value that should cause column B to be wider than column A in a proper content-driven layout algorithm</td>
  </tr>
  <tr>
    <td>A2</td>
    <td>Also longer B2</td>
  </tr>
</table>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 300,
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                semanticLabel: 'Unequal column table',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // _TableGrid column count (indirectly via estimateColumnCount logic)
  // -------------------------------------------------------------------------
  group('Table node structure', () {
    test('_buildSimpleTable produces correct node structure', () {
      final table = _buildSimpleTable([
        ['A', 'B', 'C'],
        ['1', '2', '3'],
      ]);

      // 2 rows
      expect(table.children.length, equals(2));

      // First row: 3 header cells
      final firstRow = table.children.first as TableRowNode;
      expect(firstRow.children.length, equals(3));
      final firstCell = firstRow.children.first as TableCellNode;
      expect(firstCell.isHeader, isTrue);

      // Second row: 3 data cells
      final secondRow = table.children.last as TableRowNode;
      expect(secondRow.children.length, equals(3));
      final secondCell = secondRow.children.first as TableCellNode;
      expect(secondCell.isHeader, isFalse);
    });

    test('colspan attribute is parsed from attributes map', () {
      final cell = TableCellNode(attributes: {'colspan': '3'});
      expect(cell.colspan, equals(3));
    });

    test('rowspan attribute is parsed from attributes map', () {
      final cell = TableCellNode(attributes: {'rowspan': '4'});
      expect(cell.rowspan, equals(4));
    });

    test('default colspan/rowspan is 1', () {
      final cell = TableCellNode();
      expect(cell.colspan, equals(1));
      expect(cell.rowspan, equals(1));
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a [TableNode] from a 2D list of cell text strings.
/// All cells in the first row are headers; subsequent rows are data cells.
TableNode _buildSimpleTable(List<List<String>> rows) {
  final table = TableNode();
  for (int rowIdx = 0; rowIdx < rows.length; rowIdx++) {
    final row = TableRowNode();
    for (final cellText in rows[rowIdx]) {
      final cell = TableCellNode(isHeader: rowIdx == 0);
      cell.appendChild(TextNode(cellText));
      row.appendChild(cell);
    }
    table.appendChild(row);
  }
  return table;
}
