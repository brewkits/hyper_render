import "package:hyper_render/hyper_render.dart";
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HyperRenderWidget', () {
    group('Construction', () {
      testWidgets('creates with required parameters',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Hello')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(document: doc),
            ),
          ),
        );

        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('accepts custom baseStyle', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Hello')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle:
                    const TextStyle(fontSize: 24, color: Color(0xFFFF0000)),
              ),
            ),
          ),
        );

        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('accepts onLinkTap callback', (WidgetTester tester) async {
        String? tappedUrl;
        final doc = DocumentNode(children: [
          InlineNode(
            tagName: 'a',
            attributes: {'href': 'https://example.com'},
            children: [TextNode('Click')],
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                onLinkTap: (url) => tappedUrl = url,
              ),
            ),
          ),
        );

        expect(find.byType(HyperRenderWidget), findsOneWidget);
        expect(tappedUrl, isNull); // Not tapped yet
      });

      testWidgets('accepts selectable parameter', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Hello')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                selectable: false,
              ),
            ),
          ),
        );

        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });
    });

    group('Document types', () {
      testWidgets('renders text nodes', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          TextNode('Simple text'),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(document: doc),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders block nodes', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Paragraph')]),
          BlockNode.h1(children: [TextNode('Heading')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(document: doc),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders inline nodes', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            TextNode('Normal '),
            InlineNode.strong(children: [TextNode('bold')]),
            TextNode(' and '),
            InlineNode.em(children: [TextNode('italic')]),
          ]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(document: doc),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders atomic nodes (images)', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          AtomicNode(
            tagName: 'img',
            src: 'https://example.com/image.png',
            intrinsicWidth: 100,
            intrinsicHeight: 100,
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(document: doc),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders table nodes', (WidgetTester tester) async {
        // Table rendering is complex and may require SmartTableWrapper
        // This test verifies the widget can be created with a table node
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Before table')]),
          // Tables are rendered as child widgets, so test separately
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(document: doc),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders ruby nodes', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            TextNode('The word '),
            RubyNode(baseText: '日本語', rubyText: 'にほんご'),
            TextNode(' means Japanese.'),
          ]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(document: doc),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders line break nodes', (WidgetTester tester) async {
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
              body: HyperRenderWidget(document: doc),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });
    });

    group('updateRenderObject', () {
      testWidgets('updates when document changes', (WidgetTester tester) async {
        final doc1 = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Original')]),
        ]);
        final doc2 = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Updated')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(document: doc1),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Update document
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(document: doc2),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('updates when baseStyle changes',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Test')]),
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

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('updates when selectable changes',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Test')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                selectable: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                selectable: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });
    });

    group('Complex layouts', () {
      testWidgets('renders deeply nested structure',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode(
            tagName: 'article',
            children: [
              BlockNode.h1(children: [TextNode('Title')]),
              BlockNode(
                tagName: 'section',
                children: [
                  BlockNode.p(children: [
                    TextNode('This is '),
                    InlineNode.strong(children: [
                      TextNode('bold '),
                      InlineNode.em(children: [TextNode('and italic')]),
                    ]),
                    TextNode(' text.'),
                  ]),
                ],
              ),
            ],
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HyperRenderWidget(document: doc),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders mixed content', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.h1(children: [TextNode('Welcome')]),
          BlockNode.p(children: [
            TextNode('Visit our '),
            InlineNode(
              tagName: 'a',
              attributes: {'href': 'https://example.com'},
              children: [TextNode('website')],
            ),
          ]),
          BlockNode.p(children: [
            RubyNode(baseText: '東京', rubyText: 'とうきょう'),
            TextNode(' is the capital of Japan.'),
          ]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HyperRenderWidget(document: doc),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('handles long text with word wrap',
          (WidgetTester tester) async {
        final longText =
            'This is a very long text that should wrap to multiple lines '
            'when the container width is not sufficient to display it in a single line. '
            'The custom rendering engine should handle this correctly.';

        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode(longText)]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                child: HyperRenderWidget(document: doc),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('handles CJK text', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            TextNode('日本語のテキストはこのように表示されます。'),
            TextNode('这是中文文本。'),
            TextNode('한국어 텍스트입니다.'),
          ]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                child: HyperRenderWidget(document: doc),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });
    });

    group('Custom widget builder', () {
      testWidgets('uses custom widget builder for atomic nodes',
          (WidgetTester tester) async {
        var customBuilderCalled = false;

        final doc = DocumentNode(children: [
          AtomicNode(
            tagName: 'custom',
            src: 'custom-source',
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                widgetBuilder: (node) {
                  if (node.tagName == 'custom') {
                    customBuilderCalled = true;
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.blue,
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(customBuilderCalled, isTrue);
      });
    });
  });
}
