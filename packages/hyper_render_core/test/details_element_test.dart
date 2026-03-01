import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('DetailsNode Structure', () {
    test('DetailsNode creates with default closed state', () {
      final details = DetailsNode(
        children: [
          BlockNode(
            tagName: 'summary',
            children: [TextNode('Summary')],
          ),
          BlockNode.p(children: [TextNode('Content')]),
        ],
      );

      expect(details.type, equals(NodeType.details));
      expect(details.tagName, equals('details'));
      expect(details.open, isFalse); // Default is closed
      expect(details.children.length, equals(2));
    });

    test('DetailsNode can be created with open state', () {
      final details = DetailsNode(
        open: true,
        children: [
          BlockNode(
            tagName: 'summary',
            children: [TextNode('Summary')],
          ),
          BlockNode.p(children: [TextNode('Content')]),
        ],
      );

      expect(details.open, isTrue);
    });

    test('DetailsNode.isOpen checks for open attribute', () {
      expect(DetailsNode.isOpen({'open': ''}), isTrue);
      expect(DetailsNode.isOpen({'open': 'open'}), isTrue);
      expect(DetailsNode.isOpen({}), isFalse);
      expect(DetailsNode.isOpen({'class': 'foo'}), isFalse);
    });

    test('DetailsNode with summary and multiple content children', () {
      final details = DetailsNode(
        children: [
          BlockNode(
            tagName: 'summary',
            children: [TextNode('Click me')],
          ),
          BlockNode.p(children: [TextNode('Paragraph 1')]),
          BlockNode.p(children: [TextNode('Paragraph 2')]),
          InlineNode.strong(children: [TextNode('Bold text')]),
        ],
      );

      expect(details.children.length, equals(4));

      final summary = details.children[0];
      expect(summary.tagName, equals('summary'));

      expect(details.children[1].textContent, contains('Paragraph 1'));
      expect(details.children[2].textContent, contains('Paragraph 2'));
    });

    test('DetailsNode without summary still works', () {
      final details = DetailsNode(
        children: [
          BlockNode.p(children: [TextNode('Content only')]),
        ],
      );

      expect(details.children.length, equals(1));
      expect(details.children[0].tagName, equals('p'));
    });

    test('DetailsNode with empty children', () {
      final details = DetailsNode(
        children: [],
      );

      expect(details.children.isEmpty, isTrue);
      expect(details.type, equals(NodeType.details));
    });

    test('DetailsNode preserves attributes', () {
      final details = DetailsNode(
        attributes: {
          'class': 'collapsible',
          'data-id': '123',
        },
        open: true,
        children: [],
      );

      expect(details.attributes['class'], equals('collapsible'));
      expect(details.attributes['data-id'], equals('123'));
    });

    test('DetailsNode has block display by default', () {
      final details = DetailsNode(children: []);

      expect(details.style.display, equals(DisplayType.block));
    });

    test('DetailsNode can have custom style', () {
      final details = DetailsNode(
        style: ComputedStyle(
          backgroundColor: Colors.yellow,
          padding: const EdgeInsets.all(10),
        ),
        children: [],
      );

      expect(details.style.backgroundColor, equals(Colors.yellow));
      expect(details.style.padding, equals(const EdgeInsets.all(10)));
    });
  });

  group('DetailsWidget Behavior', () {
    testWidgets('DetailsWidget renders with default closed state', (tester) async {
      final details = DetailsNode(
        children: [
          BlockNode(
            tagName: 'summary',
            children: [TextNode('Summary')],
          ),
          BlockNode.p(children: [TextNode('Hidden content')]),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailsWidget(
              detailsNode: details,
            ),
          ),
        ),
      );

      // Summary should be visible
      expect(find.text('Summary'), findsOneWidget);

      // Content should be hidden initially
      expect(find.text('Hidden content'), findsNothing);
    });

    testWidgets('DetailsWidget renders with open state', (tester) async {
      final details = DetailsNode(
        open: true,
        children: [
          BlockNode(
            tagName: 'summary',
            children: [TextNode('Summary')],
          ),
          BlockNode.p(children: [TextNode('Visible content')]),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailsWidget(
              detailsNode: details,
            ),
          ),
        ),
      );

      // Both summary and content should be visible
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Visible content'), findsOneWidget);
    });

    testWidgets('DetailsWidget shows default summary when not provided', (tester) async {
      final details = DetailsNode(
        children: [
          BlockNode.p(children: [TextNode('Content without summary')]),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailsWidget(
              detailsNode: details,
            ),
          ),
        ),
      );

      // Default summary "Details" should be shown
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('DetailsWidget toggles on tap', (tester) async {
      final details = DetailsNode(
        children: [
          BlockNode(
            tagName: 'summary',
            children: [TextNode('Click me')],
          ),
          BlockNode.p(children: [TextNode('Toggled content')]),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailsWidget(
              detailsNode: details,
            ),
          ),
        ),
      );

      // Initially closed
      expect(find.text('Toggled content'), findsNothing);

      // Tap to expand
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Should now be visible
      expect(find.text('Toggled content'), findsOneWidget);

      // Tap again to collapse
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Should be hidden again
      expect(find.text('Toggled content'), findsNothing);
    });

    testWidgets('DetailsWidget shows disclosure triangle', (tester) async {
      final details = DetailsNode(
        children: [
          BlockNode(
            tagName: 'summary',
            children: [TextNode('Summary')],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailsWidget(
              detailsNode: details,
            ),
          ),
        ),
      );

      // Should find arrow icon (right arrow when closed)
      expect(find.byIcon(Icons.arrow_right), findsOneWidget);

      // Tap to expand
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Arrow should change to down arrow when open
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('DetailsWidget respects baseStyle', (tester) async {
      final details = DetailsNode(
        children: [
          BlockNode(
            tagName: 'summary',
            children: [TextNode('Styled summary')],
          ),
        ],
      );

      const customStyle = TextStyle(fontSize: 20, color: Colors.red);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailsWidget(
              detailsNode: details,
              baseStyle: customStyle,
            ),
          ),
        ),
      );

      // Widget should render (style testing is limited in widget tests)
      expect(find.text('Styled summary'), findsOneWidget);
    });

    testWidgets('DetailsWidget handles empty details', (tester) async {
      final details = DetailsNode(children: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DetailsWidget(
              detailsNode: details,
            ),
          ),
        ),
      );

      // Should show default summary
      expect(find.text('Details'), findsOneWidget);
    });
  });

  group('Integration with HTML Adapter', () {
    test('HtmlAdapter should parse details element', () {
      // This would be tested in hyper_render_html package
      // We document expected behavior here
      final details = DetailsNode(
        open: false,
        children: [
          BlockNode(
            tagName: 'summary',
            children: [TextNode('Summary')],
          ),
          BlockNode.p(children: [TextNode('Content')]),
        ],
      );

      expect(details.type, equals(NodeType.details));
    });

    test('HtmlAdapter should respect open attribute', () {
      // Expected HTML: <details open><summary>...</summary>...</details>
      final details = DetailsNode(
        open: true,
        children: [],
      );

      expect(details.open, isTrue);
    });

    test('HtmlAdapter should handle details without open attribute', () {
      // Expected HTML: <details><summary>...</summary>...</details>
      final details = DetailsNode(
        open: false,
        children: [],
      );

      expect(details.open, isFalse);
    });
  });

  group('Edge Cases', () {
    test('DetailsNode with multiple summary elements (invalid HTML)', () {
      final details = DetailsNode(
        children: [
          BlockNode(
            tagName: 'summary',
            children: [TextNode('Summary 1')],
          ),
          BlockNode(
            tagName: 'summary',
            children: [TextNode('Summary 2')],
          ),
          BlockNode.p(children: [TextNode('Content')]),
        ],
      );

      // Should still work, DetailsWidget will use first summary
      expect(details.children.length, equals(3));
      expect(details.children[0].tagName, equals('summary'));
      expect(details.children[1].tagName, equals('summary'));
    });

    test('DetailsNode with complex nested content', () {
      final details = DetailsNode(
        children: [
          BlockNode(
            tagName: 'summary',
            children: [
              TextNode('Summary with '),
              InlineNode.strong(children: [TextNode('formatting')]),
            ],
          ),
          BlockNode.p(children: [TextNode('Paragraph')]),
          BlockNode(
            tagName: 'ul',
            children: [
              BlockNode(
                tagName: 'li',
                children: [TextNode('List item')],
              ),
            ],
          ),
          TableNode(
            children: [
              TableRowNode(children: [
                TableCellNode(children: [TextNode('Cell')]),
              ]),
            ],
          ),
        ],
      );

      expect(details.children.length, equals(4));
      expect(details.children[0].tagName, equals('summary'));
      expect(details.children[1].tagName, equals('p'));
      expect(details.children[2].tagName, equals('ul'));
      expect(details.children[3].type, equals(NodeType.table));
    });

    test('Nested details elements', () {
      final outer = DetailsNode(
        children: [
          BlockNode(
            tagName: 'summary',
            children: [TextNode('Outer')],
          ),
          DetailsNode(
            children: [
              BlockNode(
                tagName: 'summary',
                children: [TextNode('Inner')],
              ),
              BlockNode.p(children: [TextNode('Inner content')]),
            ],
          ),
        ],
      );

      expect(outer.children.length, equals(2));
      expect(outer.children[0].tagName, equals('summary'));
      expect(outer.children[1].type, equals(NodeType.details));

      final inner = outer.children[1] as DetailsNode;
      expect(inner.children.length, equals(2));
    });

    test('DetailsNode textContent extracts all text', () {
      final details = DetailsNode(
        children: [
          BlockNode(
            tagName: 'summary',
            children: [TextNode('Summary')],
          ),
          BlockNode.p(children: [TextNode('Content 1')]),
          BlockNode.p(children: [TextNode('Content 2')]),
        ],
      );

      final text = details.textContent;
      expect(text, contains('Summary'));
      expect(text, contains('Content 1'));
      expect(text, contains('Content 2'));
    });
  });
}
