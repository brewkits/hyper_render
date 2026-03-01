import "package:hyper_render/hyper_render.dart";
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Integration Tests - HTML to Custom Render', () {
    group('Full pipeline: HTML -> UDT -> RenderHyperBox', () {
      testWidgets('renders simple HTML paragraph', (WidgetTester tester) async {
        const html = '<p>Hello World</p>';
        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: document,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders HTML with inline styles',
          (WidgetTester tester) async {
        const html = '''
          <p style="color: red; font-size: 24px;">
            Styled text
          </p>
        ''';
        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        final resolver = StyleResolver();
        resolver.resolveStyles(document);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: document,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders HTML with nested formatting',
          (WidgetTester tester) async {
        const html = '''
          <p>
            Normal text
            <strong>bold <em>bold-italic</em></strong>
            <u>underlined</u>
          </p>
        ''';
        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: document,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders HTML with links', (WidgetTester tester) async {
        const html = '<p><a href="https://example.com">Click here</a></p>';
        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: document,
                onLinkTap: (url) {
                  // TODO: Add assertion for url
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
        // In a real test, we would simulate a tap and check clickedUrl.
      });

      testWidgets('renders HTML with images', (WidgetTester tester) async {
        const html = '<img src="https://example.com/image.png" width="100" height="100">';
        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: document,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders HTML with tables', (WidgetTester tester) async {
        const html = '''
          <table>
            <tr><th>Header 1</th><th>Header 2</th></tr>
            <tr><td>Cell 1</td><td>Cell 2</td></tr>
          </table>
        ''';
        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        expect(document.children, isNotEmpty);

        bool hasTable = false;
        document.traverse((node) {
          if (node is TableNode) hasTable = true;
        });
        expect(hasTable, isTrue);
      });

      testWidgets('renders HTML with ruby annotations',
          (WidgetTester tester) async {
        const html = '<ruby>漢字<rt>かんじ</rt></ruby>';
        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: document,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });

      testWidgets('renders HTML with line breaks', (WidgetTester tester) async {
        const html = '<p>Line 1<br>Line 2<br>Line 3</p>';
        final adapter = HtmlAdapter();
        final document = adapter.parse(html);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: document,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });
    });

    // NOTE: Markdown and Delta pipeline tests are simplified as the adapters still exist
    // but are not the main focus of the current refactoring.
    group('Full pipeline: Markdown -> UDT -> RenderHyperBox', () {
      testWidgets('renders Markdown heading', (WidgetTester tester) async {
        const markdown = '# Hello World';
        final adapter = MarkdownAdapter();
        final result = adapter.parse(markdown);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: result,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });
    });

    group('Full pipeline: Delta -> UDT -> RenderHyperBox', () {
      testWidgets('renders Quill Delta text', (WidgetTester tester) async {
        const delta = '{"ops":[{"insert":"Hello World\\n"}]}';
        final adapter = DeltaAdapter();
        final result = adapter.parse(delta);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperRenderWidget(
                document: result,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperRenderWidget), findsOneWidget);
      });
    });

    group('HyperViewer integration', () {
      testWidgets('renders with sync mode', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperViewer(
                html: '<p>Hello World</p>',
                mode: HyperRenderMode.sync,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperViewer), findsOneWidget);
      });

      testWidgets('renders with auto mode (defaults to sync for small content)',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperViewer(
                html: '<p>Hello World</p>',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HyperViewer), findsOneWidget);
      });

      // TODO: Add tests for virtualized mode with long content
    });
  });
}
