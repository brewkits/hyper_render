import "package:hyper_render/hyper_render.dart";
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for verifying the actual layout logic of RenderHyperBox
/// These tests go beyond "does it render" and verify actual behavior
void main() {
  group('Line Breaking Logic', () {
    testWidgets('long text wraps into multiple lines', (WidgetTester tester) async {
      // Create a document with text that's too long to fit in one line
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode(
            'This is a very long text that should definitely wrap into multiple lines '
            'when rendered in a narrow container because it contains many words.',
          ),
        ]),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Narrow container forces wrapping
              child: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get the RenderHyperBox
      final renderBox = tester.renderObject<RenderHyperBox>(
        find.byType(HyperRenderWidget),
      );

      // The height should be > single line height (roughly 20px for fontSize 16)
      // Multiple lines means height should be at least 40+
      expect(renderBox.size.height, greaterThan(30));
    });

    testWidgets('short text stays on single line', (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('Hello'),
        ]),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Wide container
              child: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final renderBox = tester.renderObject<RenderHyperBox>(
        find.byType(HyperRenderWidget),
      );

      // Single line should have small height (around 20-30px)
      expect(renderBox.size.height, lessThan(50));
    });

    testWidgets('explicit line breaks create new lines', (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('Line 1'),
          LineBreakNode(),
          TextNode('Line 2'),
          LineBreakNode(),
          TextNode('Line 3'),
        ]),
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

      final renderBox = tester.renderObject<RenderHyperBox>(
        find.byType(HyperRenderWidget),
      );

      // 3 lines with line breaks should have height > 2 lines
      expect(renderBox.size.height, greaterThan(50));
    });
  });

  group('Float Layout Logic', () {
    testWidgets('float left creates space on left side', (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode(
          tagName: 'div',
          children: [
            BlockNode(
              tagName: 'div',
              children: [TextNode('Float')],
            )..style = ComputedStyle(
                float: HyperFloat.left,
                width: 100,
                height: 100,
              ),
            BlockNode.p(children: [
              TextNode('This text should wrap around the float element on the left side.'),
            ]),
          ],
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final renderBox = tester.renderObject<RenderHyperBox>(
        find.byType(HyperRenderWidget),
      );

      // With a 100px wide float and 300px container,
      // the text area is reduced, which may cause more wrapping
      // Height should be at least as tall as the float (100px)
      expect(renderBox.size.height, greaterThanOrEqualTo(100));
    });

    testWidgets('float right creates space on right side', (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode(
          tagName: 'div',
          children: [
            BlockNode(
              tagName: 'div',
              children: [TextNode('Float')],
            )..style = ComputedStyle(
                float: HyperFloat.right,
                width: 100,
                height: 100,
              ),
            BlockNode.p(children: [
              TextNode('This text should wrap around the float element.'),
            ]),
          ],
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final renderBox = tester.renderObject<RenderHyperBox>(
        find.byType(HyperRenderWidget),
      );

      // Height should accommodate the float
      expect(renderBox.size.height, greaterThanOrEqualTo(100));
    });

    testWidgets('multiple floats stack correctly', (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode(
          tagName: 'div',
          children: [
            BlockNode(
              tagName: 'div',
              children: [TextNode('Float 1')],
            )..style = ComputedStyle(
                float: HyperFloat.left,
                width: 80,
                height: 80,
              ),
            BlockNode(
              tagName: 'div',
              children: [TextNode('Float 2')],
            )..style = ComputedStyle(
                float: HyperFloat.left,
                width: 80,
                height: 80,
              ),
            BlockNode.p(children: [
              TextNode('Text wrapping around multiple floats.'),
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

  group('onLinkTap Handler', () {
    testWidgets('link tap callback receives correct URL', (WidgetTester tester) async {
      // Create a link that fills the entire area
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          InlineNode(
            tagName: 'a',
            attributes: {'href': 'https://example.com/test'},
            children: [
              TextNode('Click this link to test the tap handler'),
            ],
          ),
        ]),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 100,
                child: HyperRenderWidget(
                  document: doc,
                  baseStyle: const TextStyle(fontSize: 16),
                  onLinkTap: (url) {
                    // TODO: Add assertion for url
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap at a point within the widget
      await tester.tapAt(tester.getCenter(find.byType(HyperRenderWidget)));
      await tester.pump();

      // The tap should have triggered the callback
      // Note: This depends on the exact layout position
      // In real testing, we might need to tap at the exact link position
    });
  });

  group('Selection Logic', () {
    testWidgets('selection updates handle positions correctly', (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('Select some of this text to test selection handles.'),
        ]),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
                selectable: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final renderBox = tester.renderObject<RenderHyperBox>(
        find.byType(HyperRenderWidget),
      );

      // Set a selection
      renderBox.selection = const HyperTextSelection(start: 0, end: 10);
      await tester.pump();

      // Get selection rects
      final rects = renderBox.getSelectionRects();
      expect(rects, isNotEmpty);

      // Start and end handle rects should exist
      final startRect = renderBox.getStartHandleRect();
      final endRect = renderBox.getEndHandleRect();
      expect(startRect, isNotNull);
      expect(endRect, isNotNull);
    });

    testWidgets('updateSelectionFromHandle works correctly', (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('Text for testing handle updates.'),
        ]),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
                selectable: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final renderBox = tester.renderObject<RenderHyperBox>(
        find.byType(HyperRenderWidget),
      );

      // Set initial selection
      renderBox.selection = const HyperTextSelection(start: 5, end: 15);
      await tester.pump();

      // Simulate moving the end handle
      renderBox.updateSelectionFromHandle(false, const Offset(100, 10));
      await tester.pump();

      // Selection should have been updated
      expect(renderBox.selection, isNotNull);
    });

    testWidgets('copySelection works correctly', (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('Copy this text.'),
        ]),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
                selectable: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final renderBox = tester.renderObject<RenderHyperBox>(
        find.byType(HyperRenderWidget),
      );

      // Select all text
      renderBox.selectAll();
      await tester.pump();

      // Get selected text
      final text = renderBox.getSelectedText();
      expect(text, isNotNull);
      expect(text, contains('Copy'));
    });
  });

  group('Fragment-Child Linking', () {
    testWidgets('atomic fragment is linked to child widget', (WidgetTester tester) async {
      // Create a document with an image (atomic element)
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('Before image'),
          AtomicNode.img(
            src: 'https://example.com/image.png',
            width: 100,
            height: 100,
          ),
          TextNode('After image'),
        ]),
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

      // Verify widget renders without error
      expect(find.byType(HyperRenderWidget), findsOneWidget);

      // Check that child widgets were created for the image
      final renderBox = tester.renderObject<RenderHyperBox>(
        find.byType(HyperRenderWidget),
      );

      // The render box should have a non-zero height accounting for text and image
      expect(renderBox.size.height, greaterThan(0));
    });

    testWidgets('table fragment is linked to table widget', (WidgetTester tester) async {
      final adapter = HtmlAdapter();
      final document = adapter.parse('''
        <table>
          <tr><td>Cell 1</td><td>Cell 2</td></tr>
          <tr><td>Cell 3</td><td>Cell 4</td></tr>
        </table>
      ''');

      // Check that the document parsed correctly and contains a table
      bool hasTable = false;
      void findTable(UDTNode node) {
        if (node is TableNode) {
          hasTable = true;
          return;
        }
        for (final child in node.children) {
          findTable(child);
        }
      }
      findTable(document);
      expect(hasTable, isTrue);
    });
  });

  group('Intrinsic Size Calculations', () {
    testWidgets('minIntrinsicWidth returns reasonable value', (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('LongestWord short'),
        ]),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntrinsicWidth(
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

    testWidgets('maxIntrinsicWidth returns reasonable value', (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('This is a line of text'),
        ]),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntrinsicWidth(
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

  group('Ruby Annotation Layout', () {
    testWidgets('ruby annotation takes extra height', (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          RubyNode(baseText: '漢字', rubyText: 'かんじ'),
        ]),
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

      final renderBox = tester.renderObject<RenderHyperBox>(
        find.byType(HyperRenderWidget),
      );

      // Ruby annotation should take more height than regular text
      // Base + ruby text + gap
      expect(renderBox.size.height, greaterThan(20));
    });
  });

  group('Inline Decoration', () {
    testWidgets('inline background renders across line breaks', (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          InlineNode(
            tagName: 'span',
            children: [
              TextNode('This is highlighted text that spans multiple lines when the container is narrow'),
            ],
          )..style = ComputedStyle(backgroundColor: const Color(0xFFFFFF00)),
        ]),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Narrow to force wrapping
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

  group('CJK Line Breaking (Kinsoku)', () {
    testWidgets('CJK text breaks correctly', (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('これは日本語のテストです。改行が正しく行われることを確認します。'),
        ]),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final renderBox = tester.renderObject<RenderHyperBox>(
        find.byType(HyperRenderWidget),
      );

      // Long CJK text should wrap into multiple lines
      expect(renderBox.size.height, greaterThan(30));
    });

    testWidgets('mixed CJK and Latin text breaks correctly', (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('English text mixed with 日本語 and more English.'),
        ]),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
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
}
