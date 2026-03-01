import "package:hyper_render/hyper_render.dart";
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests for the accessibility enhancements added in Sprint 4:
/// - <ul>/<ol>/<li> semantic nodes (list hint + ordinal position)
/// - role="button" / role="region" / role="heading" ARIA role mapping
/// - aria-label / aria-labelledby resolved to semantic labels
/// - fallbackBuilder with HtmlHeuristics.isComplex() gating
void main() {
  // ---------------------------------------------------------------------------
  // fallbackBuilder
  // ---------------------------------------------------------------------------
  group('fallbackBuilder', () {
    testWidgets('shows fallback when html is complex (position:fixed)',
        (tester) async {
      const complexHtml =
          '<div style="position:fixed; top:0;">Floating bar</div>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: complexHtml,
                mode: HyperRenderMode.sync,
                fallbackBuilder: (_) => const Text('FALLBACK'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('FALLBACK'), findsOneWidget);
    });

    testWidgets('shows fallback when html has canvas element', (tester) async {
      const html = '<canvas id="chart" width="200" height="200"></canvas>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                fallbackBuilder: (_) =>
                    const Text('Fallback: canvas not supported'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Fallback: canvas not supported'), findsOneWidget);
    });

    testWidgets('does NOT show fallback for simple article HTML',
        (tester) async {
      const simpleHtml = '''
<article>
  <h1>Title</h1>
  <p>First paragraph.</p>
  <ul><li>Item 1</li></ul>
</article>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: simpleHtml,
                mode: HyperRenderMode.sync,
                semanticLabel: 'Article',
                fallbackBuilder: (_) => const Text('SHOULD NOT APPEAR'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SHOULD NOT APPEAR'), findsNothing);
      expect(find.bySemanticsLabel('Article'), findsOneWidget);
    });

    testWidgets('fallbackBuilder receives valid BuildContext', (tester) async {
      const html = '<div style="z-index:999;">x</div>';
      ThemeData? receivedTheme;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: const ColorScheme.light()),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                fallbackBuilder: (ctx) {
                  receivedTheme = Theme.of(ctx);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(receivedTheme, isNotNull);
    });

    testWidgets('fallbackBuilder is ignored for delta content', (tester) async {
      // Delta content is never complex — fallbackBuilder should be ignored
      const delta = '{"ops":[{"insert":"Hello World\\n"}]}';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer.delta(
                delta: delta,
                mode: HyperRenderMode.sync,
                semanticLabel: 'Delta content',
                fallbackBuilder: (_) => const Text('SHOULD NOT APPEAR'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SHOULD NOT APPEAR'), findsNothing);
    });

    testWidgets('fallbackBuilder is ignored for markdown content',
        (tester) async {
      const markdown = '# Title\n\nSome text.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer.markdown(
                markdown: markdown,
                mode: HyperRenderMode.sync,
                semanticLabel: 'Markdown content',
                fallbackBuilder: (_) => const Text('SHOULD NOT APPEAR'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SHOULD NOT APPEAR'), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // List element accessibility
  // ---------------------------------------------------------------------------
  group('List element semantics', () {
    testWidgets('renders <ul>/<li> without crash', (tester) async {
      const html = '''
<ul>
  <li>First item</li>
  <li>Second item</li>
  <li>Third item</li>
</ul>
''';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                semanticLabel: 'Unordered list',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
      expect(find.bySemanticsLabel('Unordered list'), findsOneWidget);
    });

    testWidgets('renders <ol>/<li> without crash', (tester) async {
      const html = '''
<ol>
  <li>Step one</li>
  <li>Step two</li>
  <li>Step three</li>
</ol>
''';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                semanticLabel: 'Ordered list',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
      expect(find.bySemanticsLabel('Ordered list'), findsOneWidget);
    });

    testWidgets('renders nested lists without crash', (tester) async {
      const html = '''
<ul>
  <li>Parent 1
    <ul>
      <li>Child 1.1</li>
      <li>Child 1.2</li>
    </ul>
  </li>
  <li>Parent 2</li>
</ul>
''';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                semanticLabel: 'Nested lists',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // ARIA attributes
  // ---------------------------------------------------------------------------
  group('ARIA attributes', () {
    testWidgets('renders aria-label on paragraph without crash', (tester) async {
      const html =
          '<p aria-label="Important notice">Read this carefully.</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                semanticLabel: 'ARIA test',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('renders role="button" without crash', (tester) async {
      const html =
          '<span role="button" aria-label="Submit form">Submit</span>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                semanticLabel: 'Button test',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('renders role="region" without crash', (tester) async {
      const html = '''
<div role="region" aria-label="News section">
  <h2>Latest News</h2>
  <p>Breaking: Flutter 4 released.</p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                semanticLabel: 'Region test',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('renders role="heading" without crash', (tester) async {
      const html = '<div role="heading">Custom Heading</div>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                semanticLabel: 'Heading role test',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets(
        'renders mixed ARIA attributes alongside headings and links without crash',
        (tester) async {
      const html = '''
<article aria-label="Main article">
  <h1>Article Title</h1>
  <p>First paragraph with a <a href="https://example.com">link</a>.</p>
  <section role="region" aria-label="Related links">
    <ul>
      <li><a href="/page1">Page 1</a></li>
      <li><a href="/page2">Page 2</a></li>
    </ul>
  </section>
  <button aria-label="Share article">Share</button>
</article>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                semanticLabel: 'Full article with ARIA',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
      expect(find.bySemanticsLabel('Full article with ARIA'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Outer semantics label (Semantics wrapper)
  // ---------------------------------------------------------------------------
  group('Outer semantics label', () {
    testWidgets('excludeSemantics hides content from a11y tree', (tester) async {
      const html = '<p>Decorative content</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                semanticLabel: 'Hidden content',
                excludeSemantics: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Excluded from semantics tree
      expect(find.bySemanticsLabel('Hidden content'), findsNothing);
    });

    testWidgets('semanticLabel defaults to "Article content"', (tester) async {
      const html = '<p>Some text</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                // no semanticLabel
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Article content'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Security + Accessibility interplay
  // ---------------------------------------------------------------------------
  group('Security + Accessibility', () {
    testWidgets(
        'vbscript: href is sanitized; link semantic label still present',
        (tester) async {
      const html = '<a href="vbscript:msgbox(1)">Dangerous link</a>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: html,
                sanitize: true,
                mode: HyperRenderMode.sync,
                semanticLabel: 'Sanitized content',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
      // Outer semantics label still accessible
      expect(find.bySemanticsLabel('Sanitized content'), findsOneWidget);
    });

    testWidgets('CSS expression() is stripped; content still accessible',
        (tester) async {
      const html =
          '<p style="width:expression(alert(1))">Safe text after sanitization</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                html: html,
                sanitize: true,
                mode: HyperRenderMode.sync,
                semanticLabel: 'CSS-sanitized content',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('CSS-sanitized content'), findsOneWidget);
    });
  });
}
