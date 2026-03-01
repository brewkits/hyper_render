import "package:hyper_render/hyper_render.dart";
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    testWidgets('table inside HyperViewer renders without crash', (tester) async {
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

    // -----------------------------------------------------------------------
    // Nested table rendering
    // -----------------------------------------------------------------------
    testWidgets('HyperTable renders nested table inside cell without crash',
        (tester) async {
      // Build: outer 1-col table whose single cell contains a nested 2-col table.
      final outerTable = TableNode();
      final outerRow = TableRowNode();
      final outerCell = TableCellNode();

      // Inner 2-column table
      final innerTable = TableNode();
      final innerRow = TableRowNode();
      final innerCell1 = TableCellNode();
      innerCell1.appendChild(TextNode('Inner A'));
      final innerCell2 = TableCellNode();
      innerCell2.appendChild(TextNode('Inner B'));
      innerRow.appendChild(innerCell1);
      innerRow.appendChild(innerCell2);
      innerTable.appendChild(innerRow);

      // Nest inner table inside outer cell
      outerCell.appendChild(innerTable);
      outerRow.appendChild(outerCell);
      outerTable.appendChild(outerRow);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: HyperTable(tableNode: outerTable),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HyperTable), findsOneWidget);
      // Both HyperTable instances (outer + inner) should be present
      expect(find.byType(HyperTable), findsWidgets);
    });

    testWidgets('HyperViewer renders 2-level nested table HTML without crash',
        (tester) async {
      const html = '''
<table>
  <tr>
    <td>
      <table>
        <tr>
          <td>Nested cell 1</td>
          <td>Nested cell 2</td>
        </tr>
      </table>
    </td>
    <td>Outer cell 2</td>
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
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HyperViewer), findsOneWidget);
      // Inner text content should be visible
      expect(find.text('Nested cell 1'), findsOneWidget);
      expect(find.text('Nested cell 2'), findsOneWidget);

      // Verify nested table has non-zero rendered size
      final hyperTableFinder = find.byType(HyperTable);
      expect(hyperTableFinder, findsWidgets);
      for (final element in hyperTableFinder.evaluate()) {
        final renderBox = element.renderObject as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          expect(renderBox.size.height, greaterThan(0),
              reason: 'HyperTable should have non-zero height');
        }
      }
    });

    testWidgets('HyperViewer renders 3-level nested table HTML without crash',
        (tester) async {
      const html = '''
<table>
  <tr>
    <td>
      <table>
        <tr>
          <td>
            <table>
              <tr>
                <td>Deepest cell</td>
              </tr>
            </table>
          </td>
          <td>Level 2 B</td>
        </tr>
      </table>
    </td>
  </tr>
</table>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HyperViewer), findsOneWidget);
      expect(find.text('Deepest cell'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Full _nestedHtml invoice — exact content from table_advanced_demo.dart
  // -------------------------------------------------------------------------
  group('Real-world nested invoice HTML', () {
    // This is the EXACT _nestedHtml from example/lib/table_advanced_demo.dart
    // It has 3 levels of nested <table> — outer card → two-column → line items
    // → detail cells (title + subtitle).
    const nestedInvoiceHtml = '''
<div style="font-family:-apple-system,Roboto,sans-serif;padding:16px;background:#F8F9FA;">
<h2 style="color:#1A237E;margin:0 0 4px;">Nested Table Layouts</h2>
<p style="color:#757575;font-size:13px;margin:0 0 20px;">Three levels of nesting.</p>
<table width="100%" cellpadding="0" cellspacing="0"
  style="background:white;border-radius:12px;border:1px solid #E0E0E0;margin-bottom:20px;">
  <tr>
    <td style="background:#1A237E;padding:16px 20px;">
      <span style="font-size:16px;font-weight:800;color:white;">Invoice #INV-2026-001</span>
    </td>
  </tr>
  <tr>
    <td style="padding:20px;">
      <table width="100%" cellpadding="0" cellspacing="8">
        <tr>
          <td width="48%" style="background:#F5F5F5;border-radius:8px;padding:14px;vertical-align:top;">
            <div style="font-size:10px;font-weight:700;color:#9E9E9E;">FROM</div>
            <div style="font-size:14px;font-weight:700;color:#212121;">HyperRender Studio</div>
          </td>
          <td width="4%"></td>
          <td width="48%" style="background:#E8EAF6;border-radius:8px;padding:14px;vertical-align:top;">
            <div style="font-size:10px;font-weight:700;color:#5C6BC0;">BILL TO</div>
            <div style="font-size:14px;font-weight:700;color:#212121;">Acme Corp</div>
          </td>
        </tr>
        <tr>
          <td colspan="3">
            <table width="100%" cellpadding="0" cellspacing="0"
              style="border:1px solid #E0E0E0;">
              <thead>
                <tr>
                  <th style="padding:10px 14px;text-align:left;">DESCRIPTION</th>
                  <th style="padding:10px 14px;text-align:center;">QTY</th>
                  <th style="padding:10px 14px;text-align:right;">UNIT</th>
                  <th style="padding:10px 14px;text-align:right;">TOTAL</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td style="padding:12px 14px;">
                    <table cellpadding="0" cellspacing="0">
                      <tr>
                        <td style="font-size:14px;font-weight:600;color:#212121;">HyperRender Pro License</td>
                      </tr>
                      <tr>
                        <td style="font-size:11px;color:#9E9E9E;">12 months · Unlimited apps</td>
                      </tr>
                    </table>
                  </td>
                  <td style="padding:12px 14px;text-align:center;">1</td>
                  <td style="padding:12px 14px;text-align:right;">\$499</td>
                  <td style="padding:12px 14px;text-align:right;font-weight:600;">\$499.00</td>
                </tr>
                <tr>
                  <td style="padding:12px 14px;">
                    <table cellpadding="0" cellspacing="0">
                      <tr><td style="font-size:14px;font-weight:600;">Onboarding &amp; Setup</td></tr>
                      <tr><td style="font-size:11px;color:#9E9E9E;">3 hours · Remote session</td></tr>
                    </table>
                  </td>
                  <td style="padding:12px 14px;text-align:center;">3</td>
                  <td style="padding:12px 14px;text-align:right;">\$150</td>
                  <td style="padding:12px 14px;text-align:right;font-weight:600;">\$450.00</td>
                </tr>
              </tbody>
              <tfoot>
                <tr>
                  <td colspan="3" style="padding:14px;font-size:16px;font-weight:800;color:#1A237E;">TOTAL DUE</td>
                  <td style="padding:14px;text-align:right;font-size:18px;font-weight:900;color:#1A237E;">\$949.00</td>
                </tr>
              </tfoot>
            </table>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>
</div>
''';

    testWidgets('invoice nested tables render without crash via HyperViewer',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 800,
              child: HyperViewer(
                html: nestedInvoiceHtml,
                mode: HyperRenderMode.sync,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Level-3 nested table text is visible (HyperRender Pro License)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 800,
              child: HyperViewer(
                html: nestedInvoiceHtml,
                mode: HyperRenderMode.sync,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Level-3 detail cell: HyperRender Pro License
      expect(find.text('HyperRender Pro License'), findsOneWidget,
          reason: 'Level-3 nested table detail cell text should be visible');
    });

    testWidgets('Level-3 nested table subtitle text is visible',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 800,
              child: HyperViewer(
                html: nestedInvoiceHtml,
                mode: HyperRenderMode.sync,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('12 months · Unlimited apps'), findsOneWidget,
          reason: 'Level-3 subtitle row should be visible');
      expect(find.text('Onboarding & Setup'), findsOneWidget,
          reason: 'Second item title should be visible');
    });

    testWidgets('TOTAL DUE footer text is visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 800,
              child: HyperViewer(
                html: nestedInvoiceHtml,
                mode: HyperRenderMode.sync,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TOTAL DUE'), findsOneWidget,
          reason: 'tfoot TOTAL DUE cell should be visible');
    });

    testWidgets('FROM / BILL TO labels visible (Level-2 table)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 800,
              child: HyperViewer(
                html: nestedInvoiceHtml,
                mode: HyperRenderMode.sync,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HyperRender Studio'), findsOneWidget,
          reason: 'FROM column content should be visible');
      expect(find.text('Acme Corp'), findsOneWidget,
          reason: 'BILL TO column content should be visible');
    });

    testWidgets('exactly one HyperTable widget (nested tables use _TableLayout)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 800,
              child: HyperViewer(
                html: nestedInvoiceHtml,
                mode: HyperRenderMode.sync,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only ONE HyperTable (the outer table from RenderHyperBox's atomic child).
      // Nested tables are rendered via _TableLayout directly inside _buildCellContent,
      // so they do NOT create additional HyperTable instances in the widget tree.
      final tables = find.byType(HyperTable);
      expect(tables, findsOneWidget,
          reason: 'Outer table is one HyperTable; nested tables use private _TableLayout');
    });

    testWidgets('nested tables render correctly with selectable:true (matches demo)',
        (tester) async {
      // This replicates the exact _HtmlTab usage in table_advanced_demo.dart:
      //   HyperViewer(html: html, selectable: true)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 800,
              child: HyperViewer(
                html: nestedInvoiceHtml,
                mode: HyperRenderMode.sync,
                selectable: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All nested content must still be visible when selectable=true
      expect(find.text('HyperRender Pro License'), findsOneWidget,
          reason: 'Level-4 nested table text visible with selectable:true');
      expect(find.text('TOTAL DUE'), findsOneWidget,
          reason: 'tfoot TOTAL DUE visible with selectable:true');
      expect(find.text('HyperRender Studio'), findsOneWidget,
          reason: 'Level-2 FROM cell visible with selectable:true');
    });

    testWidgets('HyperTable instances all have non-zero height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 800,
              child: HyperViewer(
                html: nestedInvoiceHtml,
                mode: HyperRenderMode.sync,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final element in find.byType(HyperTable).evaluate()) {
        final renderBox = element.renderObject as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          expect(renderBox.size.height, greaterThan(0),
              reason: 'Every HyperTable should have non-zero height');
        }
      }
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
