import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

/// Helper: build a `<details>` node with a `<summary>` and body children.
UDTNode buildDetailsNode({
  bool open = false,
  String summaryText = 'Summary',
  List<UDTNode>? body,
}) {
  return BlockNode(
    tagName: 'details',
    attributes: open ? {'open': ''} : {},
    children: [
      BlockNode(
        tagName: 'summary',
        children: [TextNode(summaryText)],
      ),
      ...?body,
    ],
  );
}

void main() {
  group('Details node — model', () {
    test('details node without open attribute is closed by default', () {
      final details = buildDetailsNode(open: false);
      expect(details.attributes.containsKey('open'), isFalse);
    });

    test('details node with open attribute is open', () {
      final details = buildDetailsNode(open: true);
      expect(details.attributes.containsKey('open'), isTrue);
    });

    test('details node has tagName "details"', () {
      final details = buildDetailsNode();
      expect(details.tagName, equals('details'));
    });

    test('summary child has tagName "summary"', () {
      final details = buildDetailsNode(summaryText: 'Click me');
      final summary = details.children
          .firstWhere((c) => c.tagName?.toLowerCase() == 'summary');
      expect(summary.tagName, equals('summary'));
    });

    test('summary text content is correct', () {
      final details = buildDetailsNode(summaryText: 'My Section');
      final summary = details.children
          .firstWhere((c) => c.tagName?.toLowerCase() == 'summary');
      expect(summary.textContent, equals('My Section'));
    });

    test('details without summary child', () {
      final details = BlockNode(
        tagName: 'details',
        children: [TextNode('content without summary')],
      );
      final summaries = details.children
          .where((c) => c.tagName?.toLowerCase() == 'summary')
          .toList();
      expect(summaries, isEmpty);
    });

    test('details body nodes exclude summary', () {
      final details = buildDetailsNode(
        body: [
          BlockNode.p(children: [TextNode('Body paragraph 1')]),
          BlockNode.p(children: [TextNode('Body paragraph 2')]),
        ],
      );
      final bodyNodes = details.children
          .where((c) => c.tagName?.toLowerCase() != 'summary')
          .toList();
      expect(bodyNodes.length, equals(2));
    });

    test('details body textContent', () {
      final details = buildDetailsNode(
        body: [
          BlockNode.p(children: [TextNode('Hidden content')]),
        ],
      );
      // Full text includes summary + body
      expect(details.textContent, contains('Summary'));
      expect(details.textContent, contains('Hidden content'));
    });

    test('nested details inside details', () {
      final inner = buildDetailsNode(
        summaryText: 'Inner',
        body: [
          BlockNode.p(children: [TextNode('Nested body')])
        ],
      );
      final outer = buildDetailsNode(
        summaryText: 'Outer',
        body: [inner],
      );
      // outer has summary + inner details
      final outerBody = outer.children
          .where((c) => c.tagName?.toLowerCase() != 'summary')
          .toList();
      expect(outerBody.length, equals(1));
      expect(outerBody.first.tagName, equals('details'));
    });

    test('multiple summary elements — first one wins (model)', () {
      final details = BlockNode(
        tagName: 'details',
        children: [
          BlockNode(tagName: 'summary', children: [TextNode('First')]),
          BlockNode(tagName: 'summary', children: [TextNode('Second')]),
          BlockNode.p(children: [TextNode('Body')]),
        ],
      );
      final summaries = details.children
          .where((c) => c.tagName?.toLowerCase() == 'summary')
          .toList();
      expect(summaries.length, equals(2));
      // Widget logic uses the first — model just stores both
      expect(summaries.first.textContent, equals('First'));
    });

    test('details with inline summary content', () {
      final details = BlockNode(
        tagName: 'details',
        children: [
          BlockNode(
            tagName: 'summary',
            children: [
              TextNode('Click '),
              InlineNode.strong(children: [TextNode('here')]),
              TextNode(' for more'),
            ],
          ),
          BlockNode.p(children: [TextNode('Content')]),
        ],
      );
      final summary = details.children.first;
      expect(summary.textContent, equals('Click here for more'));
    });

    test('details parent is set on children', () {
      final details = buildDetailsNode(
        body: [
          BlockNode.p(children: [TextNode('Body')])
        ],
      );
      for (final child in details.children) {
        expect(child.parent, same(details));
      }
    });
  });

  group('HyperDetailsWidget — open/close state', () {
    testWidgets('renders closed by default (no open attribute)',
        (tester) async {
      final details = buildDetailsNode(
        open: false,
        summaryText: 'My Summary',
        body: [
          BlockNode.p(children: [TextNode('Hidden')])
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperDetailsWidget(detailsNode: details),
          ),
        ),
      );

      // Widget should render without exceptions
      expect(find.byType(HyperDetailsWidget), findsOneWidget);
      // Disclosure arrow should be present
      expect(find.byIcon(Icons.arrow_right), findsOneWidget);
    });

    testWidgets('renders open when open attribute is present', (tester) async {
      final details = buildDetailsNode(
        open: true,
        summaryText: 'Open Section',
        body: [
          BlockNode.p(children: [TextNode('Visible body')])
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperDetailsWidget(detailsNode: details),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Widget renders without exceptions
      expect(find.byType(HyperDetailsWidget), findsOneWidget);
      expect(find.byIcon(Icons.arrow_right), findsOneWidget);
    });

    testWidgets('tapping InkWell toggles state without crashing',
        (tester) async {
      final details = buildDetailsNode(
        open: false,
        summaryText: 'Toggle Me',
        body: [
          BlockNode.p(children: [TextNode('Body text')])
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperDetailsWidget(detailsNode: details),
          ),
        ),
      );

      // Tap the InkWell header area to toggle
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Still renders, no crash
      expect(find.byType(HyperDetailsWidget), findsOneWidget);
    });

    testWidgets('fallback text "Details" shown when no summary child',
        (tester) async {
      final details = BlockNode(
        tagName: 'details',
        children: [
          BlockNode.p(children: [TextNode('Body only')])
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperDetailsWidget(detailsNode: details),
          ),
        ),
      );

      // The fallback is a real Text widget (not a HyperRenderWidget)
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('disclosure icon is present', (tester) async {
      final details = buildDetailsNode(summaryText: 'Section');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperDetailsWidget(detailsNode: details),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_right), findsOneWidget);
    });

    testWidgets('dispose does not throw', (tester) async {
      final details = buildDetailsNode(summaryText: 'Section');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperDetailsWidget(detailsNode: details),
          ),
        ),
      );

      // Replace with a different widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(home: SizedBox.shrink()),
      );

      // No exceptions thrown
    });
  });

  group('Details in DocumentNode tree', () {
    test('document with details node traversal', () {
      final details = buildDetailsNode(
        summaryText: 'FAQ',
        body: [
          BlockNode.p(children: [TextNode('Answer')])
        ],
      );
      final doc = DocumentNode(children: [details]);

      int blockCount = 0;
      doc.traverse((n) {
        if (n.type == NodeType.block) blockCount++;
      });

      // details(block) + summary(block) + p(block) = 3 block nodes
      expect(blockCount, greaterThanOrEqualTo(3));
    });

    test('findById works for details node', () {
      final details = buildDetailsNode(summaryText: 'Section');
      final doc = DocumentNode(children: [details]);
      expect(doc.findById(details.id), same(details));
    });
  });
}
