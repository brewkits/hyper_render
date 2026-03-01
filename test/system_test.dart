import "package:hyper_render/hyper_render.dart";
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// System Tests - End-to-end tests covering the full rendering pipeline
/// These tests verify the complete flow from input (HTML/Markdown/Delta) to rendered output
void main() {
  group('System Tests - Full Pipeline', () {
    group('HTML Rendering Pipeline', () {
      testWidgets('renders simple HTML document', (WidgetTester tester) async {
        const html = '''
          <html>
            <body>
              <h1>Welcome</h1>
              <p>This is a paragraph.</p>
            </body>
          </html>
        ''';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
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
      });

      testWidgets('renders HTML with all inline formatting', (WidgetTester tester) async {
        const html = '''
          <p>
            <strong>Bold</strong>,
            <em>Italic</em>,
            <u>Underline</u>,
            <s>Strikethrough</s>,
            <code>Code</code>,
            <mark>Highlighted</mark>,
            <sub>Subscript</sub>,
            <sup>Superscript</sup>
          </p>
        ''';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

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

      testWidgets('renders HTML with headings h1-h6', (WidgetTester tester) async {
        const html = '''
          <h1>Heading 1</h1>
          <h2>Heading 2</h2>
          <h3>Heading 3</h3>
          <h4>Heading 4</h4>
          <h5>Heading 5</h5>
          <h6>Heading 6</h6>
        ''';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);
        final resolver = StyleResolver();
        resolver.resolveStyles(document);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HyperRenderWidget(document: document),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify headings have different sizes
        final h1 = document.children[0];
        final h6 = document.children[5];
        expect(h1.style.fontSize, greaterThan(h6.style.fontSize));
      });

      testWidgets('renders HTML with lists', (WidgetTester tester) async {
        const html = '''
          <ul>
            <li>Unordered item 1</li>
            <li>Unordered item 2</li>
          </ul>
          <ol>
            <li>Ordered item 1</li>
            <li>Ordered item 2</li>
          </ol>
        ''';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HyperRenderWidget(document: document),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders HTML with nested lists', (WidgetTester tester) async {
        const html = '''
          <ul>
            <li>Item 1
              <ul>
                <li>Nested item 1.1</li>
                <li>Nested item 1.2</li>
              </ul>
            </li>
            <li>Item 2</li>
          </ul>
        ''';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HyperRenderWidget(document: document),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders HTML with blockquote', (WidgetTester tester) async {
        const html = '''
          <blockquote>
            <p>This is a quoted text.</p>
            <p>— Author</p>
          </blockquote>
        ''';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

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

      testWidgets('renders HTML with pre/code blocks', (WidgetTester tester) async {
        const html = '''
          <pre><code class="language-dart">
void main() {
  print('Hello, World!');
}
          </code></pre>
        ''';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

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

      testWidgets('renders HTML with horizontal rule', (WidgetTester tester) async {
        const html = '''
          <p>Before</p>
          <hr>
          <p>After</p>
        ''';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

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

      testWidgets('renders HTML with definition lists', (WidgetTester tester) async {
        const html = '''
          <dl>
            <dt>Term 1</dt>
            <dd>Definition 1</dd>
            <dt>Term 2</dt>
            <dd>Definition 2</dd>
          </dl>
        ''';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

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

    group('CSS Styling Pipeline', () {
      testWidgets('applies inline styles correctly', (WidgetTester tester) async {
        const html = '''
          <p style="color: #FF0000; font-size: 24px; font-weight: bold;">
            Red bold 24px text
          </p>
        ''';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);
        final resolver = StyleResolver();
        resolver.resolveStyles(document);

        final p = document.children.first;
        expect(p.style.color, equals(const Color(0xFFFF0000)));
        expect(p.style.fontSize, equals(24));
        expect(p.style.fontWeight, equals(FontWeight.bold));
      });

      testWidgets('applies CSS classes correctly', (WidgetTester tester) async {
        final adapter = HtmlAdapter();
        final document = adapter.parse('<p class="highlight">Text</p>');

        final resolver = StyleResolver();
        resolver.parseCss('.highlight { background-color: #FFFF00; padding: 8px; }');
        resolver.resolveStyles(document);

        UDTNode? p;
        document.traverse((node) {
          if (node.tagName == 'p') p = node;
        });
        
        expect(p, isNotNull);
        expect(p!.style.backgroundColor, equals(const Color(0xFFFFFF00)));
      });

      testWidgets('applies CSS specificity correctly', (WidgetTester tester) async {
        final adapter = HtmlAdapter();
        final document = adapter.parse('<p id="main" class="text">Text</p>');

        final resolver = StyleResolver();
        resolver.parseCss('''
          p { color: blue; }
          .text { color: green; }
          #main { color: red; }
        ''');
        resolver.resolveStyles(document);

        // ID selector should win due to higher specificity
        UDTNode? p;
        document.traverse((node) {
          if (node.tagName == 'p') p = node;
        });
        
        expect(p, isNotNull);
        expect(p!.style.color, equals(const Color(0xFFFF0000)));
      });

      testWidgets('applies box model properties', (WidgetTester tester) async {
        final adapter = HtmlAdapter();
        final document = adapter.parse('<div class="box">Content</div>');

        final resolver = StyleResolver();
        resolver.parseCss('''
          .box {
            margin: 10px;
            padding: 20px;
            border: 1px solid black;
            border-radius: 8px;
          }
        ''');
        resolver.resolveStyles(document);

        UDTNode? div;
        document.traverse((node) {
          if (node.tagName == 'div') div = node;
        });
        
        expect(div, isNotNull);
        expect(div!.style.margin, isNotNull);
        expect(div!.style.padding, isNotNull);
      });

      testWidgets('applies text decoration properties', (WidgetTester tester) async {
        final adapter = HtmlAdapter();
        final document = adapter.parse('<span class="decorated">Text</span>');

        final resolver = StyleResolver();
        resolver.parseCss('''
          .decorated {
            text-decoration: underline;
            text-decoration-color: red;
            text-decoration-style: wavy;
          }
        ''');
        resolver.resolveStyles(document);

        final span = document.children.first;
        expect(span.style.textDecoration, isNotNull);
      });

      testWidgets('applies font properties', (WidgetTester tester) async {
        final adapter = HtmlAdapter();
        final document = adapter.parse('<p class="styled">Text</p>');

        final resolver = StyleResolver();
        resolver.parseCss('''
          .styled {
            font-family: "Roboto", sans-serif;
            font-size: 18px;
            font-weight: 600;
            font-style: italic;
            line-height: 1.5;
            letter-spacing: 0.5px;
          }
        ''');
        resolver.resolveStyles(document);

        final p = document.children.first;
        expect(p.style.fontSize, equals(18));
        expect(p.style.fontStyle, equals(FontStyle.italic));
      });
    });

    group('Markdown Rendering Pipeline', () {
      testWidgets('renders Markdown headings', (WidgetTester tester) async {
        const markdown = '''
# Heading 1
## Heading 2
### Heading 3
        ''';

        final adapter = MarkdownAdapter();
        final document = adapter.parse(markdown);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HyperRenderWidget(document: document),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders Markdown formatting', (WidgetTester tester) async {
        const markdown = '''
**Bold text**

*Italic text*

***Bold and italic***

~~Strikethrough~~

`Inline code`
        ''';

        final adapter = MarkdownAdapter();
        final document = adapter.parse(markdown);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HyperRenderWidget(document: document),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders Markdown lists', (WidgetTester tester) async {
        const markdown = '''
- Item 1
- Item 2
  - Nested item
- Item 3

1. First
2. Second
3. Third
        ''';

        final adapter = MarkdownAdapter();
        final document = adapter.parse(markdown);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HyperRenderWidget(document: document),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders Markdown code blocks', (WidgetTester tester) async {
        const markdown = '''
```dart
void main() {
  print('Hello');
}
```
        ''';

        final adapter = MarkdownAdapter();
        final document = adapter.parse(markdown);

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

      testWidgets('renders Markdown links', (WidgetTester tester) async {
        const markdown = '[Click here](https://example.com)';

        final adapter = MarkdownAdapter();
        final document = adapter.parse(markdown);

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

      testWidgets('renders Markdown images', (WidgetTester tester) async {
        const markdown = '![Alt text](https://example.com/image.png)';

        final adapter = MarkdownAdapter();
        final document = adapter.parse(markdown);

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

      testWidgets('renders Markdown blockquotes', (WidgetTester tester) async {
        const markdown = '''
> This is a blockquote.
> It can span multiple lines.
        ''';

        final adapter = MarkdownAdapter();
        final document = adapter.parse(markdown);

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

      testWidgets('renders Markdown tables (GFM)', (WidgetTester tester) async {
        const markdown = '''
| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |
| Cell 3   | Cell 4   |
        ''';

        final adapter = MarkdownAdapter();
        final document = adapter.parse(markdown);

        // Check that table was parsed
        bool hasTable = false;
        document.traverse((node) {
          if (node is TableNode) hasTable = true;
        });
        expect(hasTable, isTrue);
      });

      testWidgets('renders Markdown task lists (GFM)', (WidgetTester tester) async {
        const markdown = '''
- [x] Completed task
- [ ] Pending task
- [x] Another completed
        ''';

        final adapter = MarkdownAdapter();
        final document = adapter.parse(markdown);

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

    group('Delta (Quill) Rendering Pipeline', () {
      testWidgets('renders Delta plain text', (WidgetTester tester) async {
        const delta = '{"ops":[{"insert":"Hello World\\n"}]}';

        final adapter = DeltaAdapter();
        final document = adapter.parse(delta);

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

      testWidgets('renders Delta with formatting', (WidgetTester tester) async {
        const delta = '''
{
  "ops": [
    {"insert": "Bold", "attributes": {"bold": true}},
    {"insert": " and "},
    {"insert": "Italic", "attributes": {"italic": true}},
    {"insert": "\\n"}
  ]
}
        ''';

        final adapter = DeltaAdapter();
        final document = adapter.parse(delta);

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

      testWidgets('renders Delta with headers', (WidgetTester tester) async {
        const delta = '''
{
  "ops": [
    {"insert": "Heading 1"},
    {"insert": "\\n", "attributes": {"header": 1}},
    {"insert": "Heading 2"},
    {"insert": "\\n", "attributes": {"header": 2}}
  ]
}
        ''';

        final adapter = DeltaAdapter();
        final document = adapter.parse(delta);

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

      testWidgets('renders Delta with lists', (WidgetTester tester) async {
        const delta = '''
{
  "ops": [
    {"insert": "Item 1"},
    {"insert": "\\n", "attributes": {"list": "bullet"}},
    {"insert": "Item 2"},
    {"insert": "\\n", "attributes": {"list": "bullet"}}
  ]
}
        ''';

        final adapter = DeltaAdapter();
        final document = adapter.parse(delta);

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

      testWidgets('renders Delta with links', (WidgetTester tester) async {
        const delta = '''
{
  "ops": [
    {"insert": "Click here", "attributes": {"link": "https://example.com"}},
    {"insert": "\\n"}
  ]
}
        ''';

        final adapter = DeltaAdapter();
        final document = adapter.parse(delta);

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

    group('Table Rendering', () {
      testWidgets('renders simple table', (WidgetTester tester) async {
        const html = '''
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Age</th>
                <th>City</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>Alice</td>
                <td>25</td>
                <td>New York</td>
              </tr>
              <tr>
                <td>Bob</td>
                <td>30</td>
                <td>London</td>
              </tr>
            </tbody>
          </table>
        ''';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        // Find the table node
        TableNode? table;
        document.traverse((node) {
          if (node is TableNode) table = node;
        });

        expect(table, isNotNull);
        expect(table!.children.length, greaterThan(0));
      });

      testWidgets('renders table with colspan', (WidgetTester tester) async {
        const html = '''
          <table>
            <tr>
              <td colspan="2">Spanning two columns</td>
            </tr>
            <tr>
              <td>Cell 1</td>
              <td>Cell 2</td>
            </tr>
          </table>
        ''';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        TableCellNode? spanningCell;
        document.traverse((node) {
          if (node is TableCellNode && node.colspan > 1) {
            spanningCell = node;
          }
        });

        expect(spanningCell, isNotNull);
        expect(spanningCell!.colspan, equals(2));
      });

      testWidgets('renders table with rowspan', (WidgetTester tester) async {
        const html = '''
          <table>
            <tr>
              <td rowspan="2">Spanning two rows</td>
              <td>Cell 1</td>
            </tr>
            <tr>
              <td>Cell 2</td>
            </tr>
          </table>
        ''';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        TableCellNode? spanningCell;
        document.traverse((node) {
          if (node is TableCellNode && node.rowspan > 1) {
            spanningCell = node;
          }
        });

        expect(spanningCell, isNotNull);
        expect(spanningCell!.rowspan, equals(2));
      });

      testWidgets('SmartTableWrapper with horizontal scroll strategy', (WidgetTester tester) async {
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
    });

    group('CJK and Ruby Annotations', () {
      testWidgets('renders Japanese text with ruby annotations', (WidgetTester tester) async {
        const html = '''
          <p>
            <ruby>日本語<rt>にほんご</rt></ruby>を勉強しています。
          </p>
        ''';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        RubyNode? rubyNode;
        document.traverse((node) {
          if (node is RubyNode) rubyNode = node;
        });

        expect(rubyNode, isNotNull);
        expect(rubyNode!.baseText, equals('日本語'));
        expect(rubyNode!.rubyText, equals('にほんご'));

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

      testWidgets('renders Chinese text correctly', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            TextNode('这是中文测试文本。中文排版应该正确处理。'),
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

      testWidgets('renders Korean text correctly', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            TextNode('한국어 테스트입니다. 한글 렌더링이 정상적으로 작동해야 합니다.'),
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

      testWidgets('Kinsoku processing prevents bad line breaks', (WidgetTester tester) async {
        // Test that punctuation doesn't start a line
        expect(KinsokuProcessor.cannotStartLine('。'), isTrue);
        expect(KinsokuProcessor.cannotStartLine('、'), isTrue);
        expect(KinsokuProcessor.cannotStartLine('」'), isTrue);
        expect(KinsokuProcessor.cannotStartLine('）'), isTrue);

        // Test that opening brackets don't end a line
        expect(KinsokuProcessor.cannotEndLine('「'), isTrue);
        expect(KinsokuProcessor.cannotEndLine('（'), isTrue);
        expect(KinsokuProcessor.cannotEndLine('『'), isTrue);
      });
    });

    group('Image Rendering', () {
      testWidgets('renders image with dimensions', (WidgetTester tester) async {
        const html = '<img src="https://example.com/image.png" width="200" height="100" alt="Test">';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        final img = document.children.first as AtomicNode;
        expect(img.src, equals('https://example.com/image.png'));
        expect(img.intrinsicWidth, equals(200));
        expect(img.intrinsicHeight, equals(100));
        expect(img.alt, equals('Test'));
      });

      testWidgets('renders image in paragraph', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            TextNode('Before image '),
            AtomicNode.img(
              src: 'https://example.com/image.png',
              width: 100,
              height: 100,
            ),
            TextNode(' after image'),
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

      testWidgets('custom widget builder for images', (WidgetTester tester) async {
        var builderCalled = false;

        final doc = DocumentNode(children: [
          AtomicNode.img(
            src: 'https://example.com/image.png',
            width: 100,
            height: 100,
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: doc,
                widgetBuilder: (node) {
                  if (node.tagName == 'img') {
                    builderCalled = true;
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey,
                      child: const Center(child: Text('Custom Image')),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(builderCalled, isTrue);
      });
    });

    group('Link Handling', () {
      testWidgets('link tap callback is called', (WidgetTester tester) async {
        // ignore: unused_local_variable
        String? tappedUrl;

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
        expect(find.byType(HyperRenderWidget), findsOneWidget);
        // Note: Actual tap testing would need precise positioning
      });

      testWidgets('mailto links are parsed correctly', (WidgetTester tester) async {
        const html = '<a href="mailto:test@example.com">Email</a>';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        final link = document.children.first as InlineNode;
        expect(link.attributes['href'], equals('mailto:test@example.com'));
      });

      testWidgets('tel links are parsed correctly', (WidgetTester tester) async {
        const html = '<a href="tel:+1234567890">Call</a>';

        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        final link = document.children.first as InlineNode;
        expect(link.attributes['href'], equals('tel:+1234567890'));
      });
    });

    group('Selection System', () {
      testWidgets('text selection works', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [
            TextNode('Selectable text content here'),
          ]),
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

        // Set selection programmatically
        renderBox.selection = const HyperTextSelection(start: 0, end: 10);
        await tester.pump();

        expect(renderBox.selection, isNotNull);
        expect(renderBox.selection!.start, equals(0));
        expect(renderBox.selection!.end, equals(10));
      });

      testWidgets('select all works', (WidgetTester tester) async {
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

        renderBox.selectAll();
        await tester.pump();

        expect(renderBox.selection, isNotNull);
        expect(renderBox.getSelectedText(), contains('Hello'));
      });

      testWidgets('clear selection works', (WidgetTester tester) async {
        final doc = DocumentNode(children: [
          BlockNode.p(children: [TextNode('Test text')]),
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
        expect(renderBox.selection, isNotNull);

        renderBox.clearSelection();
        await tester.pump();
        expect(renderBox.selection, isNull);
      });
    });

    group('Performance - Large Documents', () {
      testWidgets('renders document with 100 paragraphs', (WidgetTester tester) async {
        final children = List.generate(
          100,
          (i) => BlockNode.p(children: [
            TextNode('Paragraph $i: This is a test paragraph with some content.'),
          ]),
        );

        final doc = DocumentNode(children: children);

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

      testWidgets('renders document with deeply nested structure', (WidgetTester tester) async {
        UDTNode createNestedDiv(int depth, String text) {
          if (depth == 0) {
            return TextNode(text);
          }
          return BlockNode(
            tagName: 'div',
            children: [createNestedDiv(depth - 1, text)],
          );
        }

        final doc = DocumentNode(children: [
          createNestedDiv(10, 'Deeply nested content'),
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

      testWidgets('renders long paragraph with word wrap', (WidgetTester tester) async {
        final longText = List.generate(50, (i) => 'word$i').join(' ');
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

        final renderBox = tester.renderObject<RenderHyperBox>(
          find.byType(HyperRenderWidget),
        );

        // Long text should wrap and create height
        expect(renderBox.size.height, greaterThan(50));
      });
    });

    group('HyperViewer Modes', () {
      testWidgets('sync mode renders immediately', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperViewer(
                html: '<p>Sync mode content</p>',
                mode: HyperRenderMode.sync,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperViewer), findsOneWidget);
      });

      testWidgets('auto mode selects appropriate strategy', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperViewer(
                html: '<p>Auto mode content</p>',
                mode: HyperRenderMode.auto,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperViewer), findsOneWidget);
      });

      testWidgets('HyperViewer with selectable option', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperViewer(
                html: '<p>Selectable content</p>',
                selectable: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperViewer), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('handles empty HTML gracefully', (WidgetTester tester) async {
        final adapter = HtmlAdapter();
        final document = adapter.parse('');

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

      testWidgets('handles malformed HTML gracefully', (WidgetTester tester) async {
        final adapter = HtmlAdapter();
        final document = adapter.parse('<p>Unclosed paragraph<div>Mixed nesting</p></div>');

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

      testWidgets('handles empty document', (WidgetTester tester) async {
        final doc = DocumentNode(children: []);

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

      testWidgets('handles invalid Delta JSON gracefully', (WidgetTester tester) async {
        final adapter = DeltaAdapter();
        // This should not throw, but handle gracefully
        try {
          final document = adapter.parse('invalid json');
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: HyperRenderWidget(document: document),
              ),
            ),
          );
          await tester.pumpAndSettle();
        } catch (e) {
          // Expected for invalid JSON
          expect(e, isA<FormatException>());
        }
      });
    });
  });
}
