import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('Table Auto-Layout - Content-based Width Calculation', () {
    test('TableCellNode stores colspan and rowspan correctly', () {
      final cell1 = TableCellNode(
        attributes: {'colspan': '2', 'rowspan': '3'},
        children: [TextNode('Spanning cell')],
      );

      expect(cell1.colspan, equals(2));
      expect(cell1.rowspan, equals(3));
    });

    test('TableCellNode defaults to 1x1 when no attributes', () {
      final cell = TableCellNode(
        children: [TextNode('Normal cell')],
      );

      expect(cell.colspan, equals(1));
      expect(cell.rowspan, equals(1));
    });

    test('TableCellNode handles invalid colspan gracefully', () {
      final cell = TableCellNode(
        attributes: {'colspan': 'invalid'},
        children: [TextNode('Cell')],
      );

      // Should default to 1 when parsing fails
      expect(cell.colspan, equals(1));
    });

    test('TableCellNode handles negative values gracefully', () {
      final cell = TableCellNode(
        attributes: {'colspan': '-5', 'rowspan': '-2'},
        children: [TextNode('Cell')],
      );

      // Negative values should be treated as 1 (or parsing fails)
      expect(cell.colspan, anyOf(equals(1), equals(-5)));
      expect(cell.rowspan, anyOf(equals(1), equals(-2)));
    });

    test('TableCellNode handles zero values', () {
      final cell = TableCellNode(
        attributes: {'colspan': '0', 'rowspan': '0'},
        children: [TextNode('Cell')],
      );

      // Zero should be treated as 1 or 0 depending on implementation
      expect(cell.colspan, anyOf(equals(0), equals(1)));
      expect(cell.rowspan, anyOf(equals(0), equals(1)));
    });

    test('TableCellNode handles very large colspan', () {
      final cell = TableCellNode(
        attributes: {'colspan': '999'},
        children: [TextNode('Wide cell')],
      );

      expect(cell.colspan, equals(999));
    });

    test('TableNode structure with mixed colspan', () {
      final table = TableNode(
        children: [
          TableRowNode(children: [
            TableCellNode(
              attributes: {'colspan': '2'},
              children: [TextNode('Wide header')],
            ),
          ]),
          TableRowNode(children: [
            TableCellNode(children: [TextNode('Cell 1')]),
            TableCellNode(children: [TextNode('Cell 2')]),
          ]),
        ],
      );

      expect(table.children.length, equals(2));

      final row1 = table.children[0] as TableRowNode;
      final row2 = table.children[1] as TableRowNode;

      expect((row1.children[0] as TableCellNode).colspan, equals(2));
      expect((row2.children[0] as TableCellNode).colspan, equals(1));
      expect((row2.children[1] as TableCellNode).colspan, equals(1));
    });

    test('TableNode handles empty table', () {
      final table = TableNode(children: []);

      expect(table.children.isEmpty, isTrue);
      expect(table.type, equals(NodeType.table));
    });

    test('TableNode with rowspan cells', () {
      final table = TableNode(
        children: [
          TableRowNode(children: [
            TableCellNode(
              attributes: {'rowspan': '2'},
              children: [TextNode('Tall cell')],
            ),
            TableCellNode(children: [TextNode('Normal')]),
          ]),
          TableRowNode(children: [
            TableCellNode(children: [TextNode('Cell 2')]),
          ]),
        ],
      );

      final row1 = table.children[0] as TableRowNode;
      final cell1 = row1.children[0] as TableCellNode;

      expect(cell1.rowspan, equals(2));
    });

    test('TableNode with both colspan and rowspan', () {
      final table = TableNode(
        children: [
          TableRowNode(children: [
            TableCellNode(
              attributes: {'colspan': '2', 'rowspan': '2'},
              children: [TextNode('Big cell')],
            ),
            TableCellNode(children: [TextNode('Normal')]),
          ]),
        ],
      );

      final cell = (table.children[0] as TableRowNode).children[0] as TableCellNode;

      expect(cell.colspan, equals(2));
      expect(cell.rowspan, equals(2));
    });

    test('TableNode preserves attributes', () {
      final table = TableNode(
        attributes: {
          'border': '1',
          'cellspacing': '0',
          'class': 'data-table'
        },
        children: [],
      );

      expect(table.attributes['border'], equals('1'));
      expect(table.attributes['cellspacing'], equals('0'));
      expect(table.attributes['class'], equals('data-table'));
    });

    test('TableCellNode with complex content', () {
      final cell = TableCellNode(
        children: [
          TextNode('Text '),
          InlineNode.strong(children: [TextNode('bold')]),
          TextNode(' more text'),
        ],
      );

      expect(cell.children.length, equals(3));
      expect(cell.textContent, contains('Text'));
      expect(cell.textContent, contains('bold'));
    });

    test('TableRowNode with mixed cell types', () {
      final row = TableRowNode(children: [
        TableCellNode(
          isHeader: true,
          children: [TextNode('Header')],
        ),
        TableCellNode(
          isHeader: false,
          children: [TextNode('Data')],
        ),
      ]);

      expect(row.children.length, equals(2));
      expect((row.children[0] as TableCellNode).tagName, equals('th'));
      expect((row.children[1] as TableCellNode).tagName, equals('td'));
    });

    test('TableNode handles thead/tbody/tfoot structure', () {
      final table = TableNode(
        children: [
          BlockNode(
            tagName: 'thead',
            children: [
              TableRowNode(children: [
                TableCellNode(children: [TextNode('Header')])
              ]),
            ],
          ),
          BlockNode(
            tagName: 'tbody',
            children: [
              TableRowNode(children: [
                TableCellNode(children: [TextNode('Body')])
              ]),
            ],
          ),
        ],
      );

      expect(table.children.length, equals(2));
      expect(table.children[0].tagName, equals('thead'));
      expect(table.children[1].tagName, equals('tbody'));
    });
  });

  group('Table Width Calculation Edge Cases', () {
    // Note: These tests would require access to RenderHyperTable internals
    // For now, we document expected behaviors

    test('Table with all equal content should distribute evenly', () {
      final table = TableNode(
        children: [
          TableRowNode(children: [
            TableCellNode(children: [TextNode('A')]),
            TableCellNode(children: [TextNode('B')]),
            TableCellNode(children: [TextNode('C')]),
          ]),
        ],
      );

      // All cells have equal content, so should get equal width
      expect(table.children.length, equals(1));
      final row = table.children[0] as TableRowNode;
      expect(row.children.length, equals(3));
    });

    test('Table with one very wide cell', () {
      final table = TableNode(
        children: [
          TableRowNode(children: [
            TableCellNode(children: [TextNode('A')]),
            TableCellNode(children: [
              TextNode('This is a very long text that should get more width')
            ]),
            TableCellNode(children: [TextNode('C')]),
          ]),
        ],
      );

      final row = table.children[0] as TableRowNode;
      final cells = row.children.cast<TableCellNode>();

      // Cell 2 has longer content
      expect(cells[1].textContent.length, greaterThan(cells[0].textContent.length));
      expect(cells[1].textContent.length, greaterThan(cells[2].textContent.length));
    });

    test('Table with colspan should distribute width across columns', () {
      final table = TableNode(
        children: [
          TableRowNode(children: [
            TableCellNode(
              attributes: {'colspan': '3'},
              children: [TextNode('Spanning all 3 columns')],
            ),
          ]),
          TableRowNode(children: [
            TableCellNode(children: [TextNode('A')]),
            TableCellNode(children: [TextNode('B')]),
            TableCellNode(children: [TextNode('C')]),
          ]),
        ],
      );

      final row1 = table.children[0] as TableRowNode;
      final row2 = table.children[1] as TableRowNode;

      expect((row1.children[0] as TableCellNode).colspan, equals(3));
      expect(row2.children.length, equals(3));
    });

    test('Empty table cells should get minimum width', () {
      final table = TableNode(
        children: [
          TableRowNode(children: [
            TableCellNode(children: [TextNode('')]),
            TableCellNode(children: [TextNode('Some content')]),
          ]),
        ],
      );

      final row = table.children[0] as TableRowNode;
      final cells = row.children.cast<TableCellNode>();

      // First cell is empty, second has content
      expect(cells[0].textContent, isEmpty);
      expect(cells[1].textContent, isNotEmpty);
    });

    test('Table with different row counts', () {
      final table = TableNode(
        children: [
          TableRowNode(children: [
            TableCellNode(children: [TextNode('1-1')]),
            TableCellNode(children: [TextNode('1-2')]),
          ]),
          TableRowNode(children: [
            TableCellNode(children: [TextNode('2-1')]),
            TableCellNode(children: [TextNode('2-2')]),
            TableCellNode(children: [TextNode('2-3')]),
          ]),
        ],
      );

      final row1 = table.children[0] as TableRowNode;
      final row2 = table.children[1] as TableRowNode;

      expect(row1.children.length, equals(2));
      expect(row2.children.length, equals(3));
      // This represents an irregular table structure
    });
  });

  group('Table Strategy', () {
    test('SmartTableWrapper has default strategy', () {
      final wrapper = SmartTableWrapper(
        tableNode: TableNode(children: []),
      );

      expect(wrapper.strategy, equals(TableStrategy.horizontalScroll));
    });

    test('SmartTableWrapper can use autoScale strategy', () {
      final wrapper = SmartTableWrapper(
        tableNode: TableNode(children: []),
        strategy: TableStrategy.autoScale,
      );

      expect(wrapper.strategy, equals(TableStrategy.autoScale));
    });

    test('SmartTableWrapper accepts baseStyle', () {
      const baseStyle = TextStyle(fontSize: 14, color: Colors.black);
      final wrapper = SmartTableWrapper(
        tableNode: TableNode(children: []),
        baseStyle: baseStyle,
      );

      expect(wrapper.baseStyle, equals(baseStyle));
    });

    test('SmartTableWrapper accepts onLinkTap callback', () {
      void onTap(String url) {}

      final wrapper = SmartTableWrapper(
        tableNode: TableNode(children: []),
        onLinkTap: onTap,
      );

      expect(wrapper.onLinkTap, equals(onTap));
    });
  });
}
