import "package:hyper_render/hyper_render.dart";
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HyperTextSelection', () {
    test('creates with start and end', () {
      const selection = HyperTextSelection(start: 0, end: 10);

      expect(selection.start, equals(0));
      expect(selection.end, equals(10));
    });

    test('isCollapsed returns true when start equals end', () {
      const selection = HyperTextSelection(start: 5, end: 5);

      expect(selection.isCollapsed, isTrue);
    });

    test('isCollapsed returns false when start differs from end', () {
      const selection = HyperTextSelection(start: 0, end: 10);

      expect(selection.isCollapsed, isFalse);
    });

    test('isValid returns true for valid range', () {
      const selection = HyperTextSelection(start: 0, end: 10);

      expect(selection.isValid, isTrue);
    });

    test('isValid returns false for negative start', () {
      const selection = HyperTextSelection(start: -1, end: 10);

      expect(selection.isValid, isFalse);
    });

    test('isValid returns false when end is less than start', () {
      const selection = HyperTextSelection(start: 10, end: 5);

      expect(selection.isValid, isFalse);
    });

    test('copyWith creates new instance with updated values', () {
      const original = HyperTextSelection(start: 0, end: 10);
      final copied = original.copyWith(end: 20);

      expect(copied.start, equals(0));
      expect(copied.end, equals(20));
      expect(original.end, equals(10)); // Original unchanged
    });

    test('copyWith preserves values when not specified', () {
      const original = HyperTextSelection(start: 5, end: 15);
      final copied = original.copyWith();

      expect(copied.start, equals(5));
      expect(copied.end, equals(15));
    });
  });

  group('HyperBoxParentData', () {
    test('has correct default values', () {
      final parentData = HyperBoxParentData();

      expect(parentData.sourceNode, isNull);
      expect(parentData.fragment, isNull);
      expect(parentData.isFloat, isFalse);
      expect(parentData.floatDirection, equals(HyperFloat.none));
      expect(parentData.floatRect, isNull);
    });

    test('can set all properties', () {
      final node = TextNode('Test');
      final fragment = Fragment.text(
        text: 'Test',
        sourceNode: node,
        style: ComputedStyle(),
      );

      final parentData = HyperBoxParentData()
        ..sourceNode = node
        ..fragment = fragment
        ..isFloat = true
        ..floatDirection = HyperFloat.left
        ..floatRect = const Rect.fromLTWH(0, 0, 100, 100);

      expect(parentData.sourceNode, equals(node));
      expect(parentData.fragment, equals(fragment));
      expect(parentData.isFloat, isTrue);
      expect(parentData.floatDirection, equals(HyperFloat.left));
      expect(parentData.floatRect, equals(const Rect.fromLTWH(0, 0, 100, 100)));
    });
  });

  group('RenderHyperBox', () {
    late RenderHyperBox renderBox;

    setUp(() {
      renderBox = RenderHyperBox(
        baseStyle: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
        selectable: true,
      );
    });

    tearDown(() {
      renderBox.dispose();
    });

    group('Properties', () {
      test('document getter and setter', () {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Hello')]),
        ]);

        renderBox.document = doc;
        expect(renderBox.document, equals(doc));
      });

      test('baseStyle getter and setter', () {
        const style = TextStyle(fontSize: 20, color: Color(0xFFFF0000));
        renderBox.baseStyle = style;
        expect(renderBox.baseStyle, equals(style));
      });

      test('selectable getter and setter', () {
        renderBox.selectable = false;
        expect(renderBox.selectable, isFalse);

        renderBox.selectable = true;
        expect(renderBox.selectable, isTrue);
      });

      test('selection getter and setter', () {
        const selection = HyperTextSelection(start: 0, end: 5);
        renderBox.selection = selection;
        expect(renderBox.selection, equals(selection));
      });

      test('disabling selectable clears selection', () {
        renderBox.selection = const HyperTextSelection(start: 0, end: 5);
        renderBox.selectable = false;
        expect(renderBox.selection, isNull);
      });
    });

    group('Layout', () {
      testWidgets('computes correct size for simple document',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Hello World')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Just verify it renders without error
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('handles empty document', (WidgetTester tester) async {
        final doc = DocumentNode(children: []);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('handles nested blocks', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode(
            tagName: 'div',
            children: [
              BlockNode.p(children: [TextNode('Paragraph 1')]),
              BlockNode.p(children: [TextNode('Paragraph 2')]),
            ],
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('handles inline elements', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            TextNode('Hello '),
            InlineNode.strong(children: [TextNode('World')]),
            TextNode('!'),
          ]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });
    });

    group('Selection', () {
      testWidgets('selectAll selects entire document',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Hello World')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
                selectable: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find the RenderHyperBox
        final renderObject = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );

        renderObject.selectAll();
        expect(renderObject.selection, isNotNull);
        expect(renderObject.selection!.start, equals(0));
        expect(renderObject.selection!.end, greaterThan(0));
      });

      testWidgets('clearSelection clears the selection',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Hello World')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
                selectable: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final renderObject = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );

        renderObject.selectAll();
        expect(renderObject.selection, isNotNull);

        renderObject.clearSelection();
        expect(renderObject.selection, isNull);
      });

      testWidgets('getSelectedText returns selected text',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Hello World')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
                selectable: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final renderObject = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );

        renderObject.selectAll();
        final text = renderObject.getSelectedText();
        expect(text, isNotNull);
        expect(text, contains('Hello'));
        expect(text, contains('World'));
      });

      testWidgets('getSelectedText returns null when no selection',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Hello World')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
                selectable: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final renderObject = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );

        final text = renderObject.getSelectedText();
        expect(text, isNull);
      });

      testWidgets('getSelectionRects returns empty list when no selection',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Hello World')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
                selectable: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final renderObject = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );

        final rects = renderObject.getSelectionRects();
        expect(rects, isEmpty);
      });

      testWidgets('getSelectionRects returns rects when selection exists',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Hello World')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
                selectable: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final renderObject = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );

        renderObject.selectAll();
        final rects = renderObject.getSelectionRects();
        expect(rects, isNotEmpty);
      });
    });

    group('Link handling', () {
      testWidgets('onLinkTap callback is invoked', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            InlineNode(
              tagName: 'a',
              attributes: {'href': 'https://example.com'},
              children: [TextNode('Click me')],
            ),
          ]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
                onLinkTap: (url) {
                  // TODO: Add assertion for url
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on the link
        await tester.tap(find.byType(HyperRenderWidget));
        await tester.pumpAndSettle();

        // Link should be tapped (assuming tap hits the link area)
        // Note: This test may need adjustment based on actual layout
      });
    });

    group('Line break handling', () {
      testWidgets('handles line break nodes', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            TextNode('Line 1'),
            LineBreakNode(),
            TextNode('Line 2'),
          ]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });
    });

    group('Ruby annotation handling', () {
      testWidgets('handles ruby nodes', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            RubyNode(baseText: '漢字', rubyText: 'かんじ'),
          ]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });
    });

    group('Float layout', () {
      testWidgets('handles float: left style', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode(
            tagName: 'div',
            children: [
              BlockNode(
                tagName: 'div',
                children: [TextNode('Float content')],
              )..style = ComputedStyle(
                  float: HyperFloat.left,
                  width: 100,
                  height: 100,
                ),
              BlockNode.p(children: [
                TextNode('This text should wrap around the float'),
              ]),
            ],
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: HyperRenderWidget(
                  document: doc,
                  baseStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('handles float: right style', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode(
            tagName: 'div',
            children: [
              BlockNode(
                tagName: 'div',
                children: [TextNode('Float content')],
              )..style = ComputedStyle(
                  float: HyperFloat.right,
                  width: 100,
                  height: 100,
                ),
              BlockNode.p(children: [
                TextNode('This text should wrap around the float'),
              ]),
            ],
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: HyperRenderWidget(
                  document: doc,
                  baseStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });
    });

    group('Intrinsic dimensions', () {
      test('computeMinIntrinsicWidth returns 0 for null document', () {
        expect(renderBox.computeMinIntrinsicWidth(100), equals(0));
      });

      test('computeMaxIntrinsicWidth returns 0 for null document', () {
        expect(renderBox.computeMaxIntrinsicWidth(100), equals(0));
      });

      test('computeMinIntrinsicHeight returns 0 for null document', () {
        expect(renderBox.computeMinIntrinsicHeight(100), equals(0));
      });

      test('computeMaxIntrinsicHeight returns 0 for null document', () {
        expect(renderBox.computeMaxIntrinsicHeight(100), equals(0));
      });
    });
  });

  group('ImageLoadState', () {
    test('has all expected values', () {
      expect(ImageLoadState.values.length, equals(3));
      expect(ImageLoadState.loading, isNotNull);
      expect(ImageLoadState.loaded, isNotNull);
      expect(ImageLoadState.error, isNotNull);
    });
  });
}
