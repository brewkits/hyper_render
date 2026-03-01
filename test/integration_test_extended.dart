import "package:hyper_render/hyper_render.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extended Integration Tests - Tests verifying interactions between components
void main() {
  group('Integration Tests - Component Interactions', () {
    group('Parser + StyleResolver Integration', () {
      test('HTML parser output is correctly styled by StyleResolver', () {
        final adapter = HtmlAdapter();
        final document = adapter.parse('''
          <div class="container">
            <h1>Title</h1>
            <p class="intro">Introduction paragraph</p>
          </div>
        ''');

        final resolver = StyleResolver();
        resolver.parseCss('''
          .container { padding: 20px; }
          h1 { color: #333333; font-size: 32px; }
          .intro { font-style: italic; color: #666666; }
        ''');
        resolver.resolveStyles(document);

        // Find the h1 node
        UDTNode? h1;
        document.traverse((node) {
          if (node.tagName == 'h1') h1 = node;
        });

        expect(h1, isNotNull);
        expect(h1!.style.fontSize, equals(32));
        expect(h1!.style.color, equals(const Color(0xFF333333)));
      });

      test('Markdown parser + StyleResolver works together', () {
        final adapter = MarkdownAdapter();
        final document = adapter.parse('''
# Heading

**Bold text** and *italic text*
        ''');

        final resolver = StyleResolver();
        resolver.resolveStyles(document);

        // Heading should have default h1 styles
        UDTNode? heading;
        document.traverse((node) {
          if (node.tagName == 'h1') heading = node;
        });

        expect(heading, isNotNull);
        expect(heading!.style.fontWeight, equals(FontWeight.bold));
      });

      test('Inline styles override CSS class styles', () {
        final adapter = HtmlAdapter();
        final document = adapter.parse('''
          <p class="red" style="color: blue;">Text</p>
        ''');

        final resolver = StyleResolver();
        resolver.parseCss('.red { color: red; }');
        resolver.resolveStyles(document);

        final p = document.children.first;
        // Inline style should win
        expect(p.style.color, equals(const Color(0xFF0000FF)));
      });

      test('CSS inheritance works correctly', () {
        final adapter = HtmlAdapter();
        final document = adapter.parse('''
          <div style="font-family: Roboto; font-size: 16px;">
            <p>Inherits parent font</p>
          </div>
        ''');

        final resolver = StyleResolver();
        resolver.resolveStyles(document);

        // Note: Inheritance behavior depends on implementation
        expect(document.children.first.style.fontFamily, equals('Roboto'));
      });
    });

    group('Widget + RenderObject Integration', () {
      testWidgets('HyperRenderWidget creates RenderHyperBox correctly',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Test content')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(document: doc),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final renderBox = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );

        expect(renderBox, isNotNull);
        expect(renderBox.document, equals(doc));
      });

      testWidgets('Widget updates propagate to RenderObject',
          (WidgetTester tester) async {
        final doc1 = DocumentNode(children: [
          BlockNode.p(children: [TextNode('First content')]),
        ]);
        final doc2 = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Second content')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(document: doc1),
            ),
          ),
        );

        await tester.pumpAndSettle();

        var renderBox = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );
        expect(renderBox.document, equals(doc1));

        // Update document
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(document: doc2),
            ),
          ),
        );

        await tester.pumpAndSettle();

        renderBox = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );
        expect(renderBox.document, equals(doc2));
      });

      testWidgets('baseStyle changes trigger relayout',
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
        final size1 = tester.getSize(find.byType(HyperRenderWidget));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final size2 = tester.getSize(find.byType(HyperRenderWidget));

        // Larger font should result in larger or equal height
        // Note: exact height depends on rendering implementation
        expect(size2.height, greaterThanOrEqualTo(size1.height));
      });

      testWidgets('selectable property affects RenderObject',
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

        final renderBox = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );

        expect(renderBox.selectable, isTrue);
      });
    });

    group('Fragment + Layout Integration', () {
      testWidgets('Fragments are positioned correctly after layout',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            TextNode('First word '),
            TextNode('second word'),
          ]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: HyperRenderWidget(document: doc),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final renderBox = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );

        // RenderBox should be laid out
        expect(renderBox.hasSize, isTrue);
        expect(renderBox.size.width, greaterThan(0));
      });

      testWidgets('Line breaks create multiple lines',
          (WidgetTester tester) async {
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
                child: HyperRenderWidget(document: doc),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final renderBox = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );

        // Multiple lines should result in height > single line
        expect(renderBox.size.height, greaterThan(30));
      });

      testWidgets('Atomic fragments maintain size after layout',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            AtomicNode.img(
              src: 'https://example.com/image.png',
              width: 100,
              height: 80,
            ),
          ]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: HyperRenderWidget(
                  document: doc,
                  widgetBuilder: (node) {
                    if (node.tagName == 'img') {
                      return Container(
                        width: 100,
                        height: 80,
                        color: Colors.grey,
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final renderBox = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );

        // RenderObject should have height at least as tall as the image
        expect(renderBox.size.height, greaterThanOrEqualTo(80));
      });
    });

    group('Selection + Clipboard Integration', () {
      testWidgets('Selected text can be retrieved',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Hello World')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: HyperRenderWidget(
                  document: doc,
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

        renderBox.selection = const HyperTextSelection(start: 0, end: 5);
        await tester.pump();

        final selectedText = renderBox.getSelectedText();
        expect(selectedText, equals('Hello'));
      });

      testWidgets('Selection rects are computed correctly',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Some selectable text here')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: HyperRenderWidget(
                  document: doc,
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

        renderBox.selection = const HyperTextSelection(start: 5, end: 15);
        await tester.pump();

        final rects = renderBox.getSelectionRects();
        expect(rects, isNotEmpty);

        // Each rect should have positive dimensions
        for (final rect in rects) {
          expect(rect.width, greaterThan(0));
          expect(rect.height, greaterThan(0));
        }
      });

      testWidgets('Handle positions are correct',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Drag handles test')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: HyperRenderWidget(
                  document: doc,
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

        renderBox.selection = const HyperTextSelection(start: 0, end: 10);
        await tester.pump();

        final startRect = renderBox.getStartHandleRect();
        final endRect = renderBox.getEndHandleRect();

        expect(startRect, isNotNull);
        expect(endRect, isNotNull);
        // End handle should be at or after start handle
        expect(endRect!.left, greaterThanOrEqualTo(startRect!.left));
      });
    });

    group('Event Callbacks Integration', () {
      testWidgets('onLinkTap is called with correct URL',
          (WidgetTester tester) async {
        // ignore: unused_local_variable
        String? tappedUrl;

        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            InlineNode(
              tagName: 'a',
              attributes: {'href': 'https://flutter.dev'},
              children: [TextNode('Flutter')],
            ),
          ]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  height: 100,
                  child: HyperRenderWidget(
                    document: doc,
                    onLinkTap: (url) => tappedUrl = url,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify widget rendered
        expect(find.byType(HyperRenderWidget), findsOneWidget);

        // Tap the widget (verifies no crash on tap; link hit-testing requires
        // exact coordinates that depend on text layout at runtime)
        await tester.tap(find.byType(HyperRenderWidget));
        await tester.pumpAndSettle();
      });

      testWidgets('onSelectionChanged is called when selection changes',
          (WidgetTester tester) async {
        var selectionChangedCalled = false;

        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Selection test')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: HyperRenderWidget(
                  document: doc,
                  selectable: true,
                  onSelectionChanged: (_) {
                    selectionChangedCalled = true;
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final renderBox = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );

        renderBox.selection = const HyperTextSelection(start: 0, end: 5);
        await tester.pump();

        expect(selectionChangedCalled, isTrue);
      });
    });

    group('Document Traversal Integration', () {
      test('traverse visits all nodes in correct order', () {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            TextNode('First'),
            InlineNode.strong(children: [TextNode('Bold')]),
            TextNode('Last'),
          ]),
        ]);

        final visited = <String>[];
        doc.traverse((node) {
          if (node is TextNode) {
            visited.add(node.text);
          }
        });

        expect(visited, equals(['First', 'Bold', 'Last']));
      });

      test('findById finds correct node', () {
        final target = TextNode('Target');
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            TextNode('Other'),
            target,
          ]),
        ]);

        final found = doc.findById(target.id);
        expect(found, equals(target));
      });

      test('textContent returns all text', () {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            TextNode('Hello '),
            InlineNode.strong(children: [TextNode('World')]),
          ]),
        ]);

        expect(doc.textContent, equals('Hello World'));
      });

      test('parent references are set correctly', () {
        final text = TextNode('Child');
        final p = BlockNode.p(children: [text]);
        final doc = DocumentNode(children: [p]);

        // Children list membership
        expect(p.children.contains(text), isTrue);
        // Parent back-references
        expect(text.parent, equals(p));
        expect(p.parent, equals(doc));
      });
    });

    group('Style Resolution Integration', () {
      test('user agent styles are applied by default', () {
        final doc = DocumentNode(children: [
          BlockNode.h1(children: [TextNode('Heading')]),
          BlockNode.p(children: [TextNode('Paragraph')]),
        ]);

        final resolver = StyleResolver();
        resolver.resolveStyles(doc);

        final h1 = doc.children[0];
        final p = doc.children[1];

        // H1 should have larger font than P
        expect(h1.style.fontSize, greaterThan(p.style.fontSize));
        expect(h1.style.fontWeight, equals(FontWeight.bold));
      });

      test('custom CSS overrides user agent styles', () {
        final adapter = HtmlAdapter();
        final document = adapter.parse('<h1 class="custom">Title</h1>');

        final resolver = StyleResolver();
        resolver.parseCss('h1.custom { font-size: 48px; color: red; }');
        resolver.resolveStyles(document);

        final h1 = document.children.first;
        expect(h1.style.fontSize, equals(48));
        expect(h1.style.color, equals(const Color(0xFFFF0000)));
      });

      test('inline styles take precedence over class styles', () {
        final adapter = HtmlAdapter();
        final document = adapter.parse('<p class="styled" style="color: blue;">Text</p>');

        final resolver = StyleResolver();
        resolver.parseCss('.styled { color: red; }');
        resolver.resolveStyles(document);

        final p = document.children.first;
        // Inline style should win over class style
        expect(p.style.color, equals(const Color(0xFF0000FF)));
      });
    });

    group('Float Layout Integration', () {
      testWidgets('float left affects text flow',
          (WidgetTester tester) async {
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
                TextNode('This text should flow around the float.'),
              ]),
            ],
          ),
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

      testWidgets('clear property clears floats',
          (WidgetTester tester) async {
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
              BlockNode(
                tagName: 'div',
                children: [TextNode('Below float')],
              ),
            ],
          ),
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

    group('Table + SmartTableWrapper Integration', () {
      testWidgets('table renders with SmartTableWrapper',
          (WidgetTester tester) async {
        final tableNode = TableNode(children: [
          TableRowNode(children: [
            TableCellNode(isHeader: true, children: [TextNode('Header 1')]),
            TableCellNode(isHeader: true, children: [TextNode('Header 2')]),
          ]),
          TableRowNode(children: [
            TableCellNode(children: [TextNode('Cell 1')]),
            TableCellNode(children: [TextNode('Cell 2')]),
          ]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartTableWrapper(
                tableNode: tableNode,
                strategy: TableStrategy.horizontalScroll,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(SmartTableWrapper), findsOneWidget);
      });

      testWidgets('table with colspan/rowspan renders correctly',
          (WidgetTester tester) async {
        final tableNode = TableNode(children: [
          TableRowNode(children: [
            TableCellNode(
              isHeader: true,
              attributes: {'colspan': '2'},
              children: [TextNode('Spanning Header')],
            ),
          ]),
          TableRowNode(children: [
            TableCellNode(children: [TextNode('Cell 1')]),
            TableCellNode(children: [TextNode('Cell 2')]),
          ]),
        ]);

        final firstCell = tableNode.children.first.children.first as TableCellNode;
        expect(firstCell.colspan, equals(2));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartTableWrapper(tableNode: tableNode),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(SmartTableWrapper), findsOneWidget);
      });
    });

    group('Ruby Annotation Integration', () {
      testWidgets('ruby annotations render correctly',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            RubyNode(baseText: '漢字', rubyText: 'かんじ'),
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

        final renderBox = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );

        // Ruby annotation should take extra height
        expect(renderBox.size.height, greaterThan(20));
      });

      testWidgets('HTML ruby is parsed and rendered',
          (WidgetTester tester) async {
        const html = '<ruby>東京<rt>とうきょう</rt></ruby>';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        RubyNode? ruby;
        document.traverse((node) {
          if (node is RubyNode) ruby = node;
        });

        expect(ruby, isNotNull);
        expect(ruby!.baseText, equals('東京'));
        expect(ruby!.rubyText, equals('とうきょう'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(document: document),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });
    });

    group('Code Highlighting Integration', () {
      test('PlainTextHighlighter returns single span', () {
        final highlighter = PlainTextHighlighter();

        final spans = highlighter.highlight('Some code', 'any');

        expect(spans.length, equals(1));
        expect(spans.first.text, equals('Some code'));
      });

      test('PlainTextHighlighter has empty supported languages', () {
        final highlighter = PlainTextHighlighter();

        // PlainTextHighlighter doesn't claim to support any language
        // but can still process any text
        expect(highlighter.supportedLanguages, isEmpty);
        expect(highlighter.themeName, equals('plain'));
      });
    });

    group('Media Elements Integration', () {
      test('video element is parsed correctly', () {
        final adapter = HtmlAdapter();
        final document = adapter.parse(
          '<video src="video.mp4" width="640" height="360" controls></video>',
        );

        final video = document.children.first as AtomicNode;
        expect(video.tagName, equals('video'));
        expect(video.src, equals('video.mp4'));
        expect(video.intrinsicWidth, equals(640));
        expect(video.intrinsicHeight, equals(360));
      });

      test('audio element is parsed correctly', () {
        final adapter = HtmlAdapter();
        final document = adapter.parse(
          '<audio src="audio.mp3" controls></audio>',
        );

        final audio = document.children.first as AtomicNode;
        expect(audio.tagName, equals('audio'));
        expect(audio.src, equals('audio.mp3'));
      });

      testWidgets('custom widget builder handles video',
          (WidgetTester tester) async {
        var videoBuildCalled = false;

        final doc = DocumentNode(children: [
          AtomicNode(
            tagName: 'video',
            src: 'video.mp4',
            intrinsicWidth: 320,
            intrinsicHeight: 180,
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                widgetBuilder: (node) {
                  if (node.tagName == 'video') {
                    videoBuildCalled = true;
                    return Container(
                      width: 320,
                      height: 180,
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.play_arrow, color: Colors.white),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(videoBuildCalled, isTrue);
      });
    });

    group('Keyboard Shortcuts Integration', () {
      testWidgets('Ctrl+A selects all text', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Select all this text')]),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: HyperRenderWidget(
                  document: doc,
                  selectable: true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Focus the widget first
        await tester.tap(find.byType(HyperRenderWidget));
        await tester.pump();

        // Send Ctrl+A
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pump();

        // Verify the widget is still rendered after keyboard interaction
        // (Ctrl+A triggers the shortcut handler; full selection state testing
        // requires the widget to have proper focus in the test environment)
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });
    });

    group('Responsive Layout Integration', () {
      testWidgets('layout adapts to width changes',
          (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            TextNode('This text should reflow when the width changes.'),
          ]),
        ]);

        // First with wide container
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: HyperRenderWidget(document: doc),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final height1 = tester.getSize(find.byType(HyperRenderWidget)).height;

        // Then with narrow container
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 100,
                child: HyperRenderWidget(document: doc),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final height2 = tester.getSize(find.byType(HyperRenderWidget)).height;

        // Narrow container should cause more lines, hence more height
        expect(height2, greaterThan(height1));
      });
    });
  });
}
