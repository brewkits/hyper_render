import "package:hyper_render/hyper_render.dart";
// Large document integration tests.
//
// HyperRender renders text via Canvas — find.text() / find.textContaining()
// don't work on its output.  Widget-level assertions use structural finders;
// content correctness is verified at the parser level.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Large Document Integration Tests', () {
    testWidgets('renders 50KB HTML document smoothly', (tester) async {
      final largeHtml = _generateLargeHtml(paragraphs: 100, wordsPerParagraph: 50);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: largeHtml, mode: HyperRenderMode.auto),
          ),
        ),
      );

      await tester.pump(); // show initial frame / loading indicator
      // Wait for compute() isolate in real time — pumpAndSettle can't settle
      // while CircularProgressIndicator (infinite animation) is visible.
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 5)));
      await tester.pump(); // process setState from compute().then()
      // Advance 500ms fake-time to let AnimatedSwitcher (300ms) finish.
      // Avoid pumpAndSettle — BouncingScrollPhysics can create infinite frames.
      await tester.pump(const Duration(milliseconds: 500));
      stopwatch.stop();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
      expect(stopwatch.elapsedMilliseconds, lessThan(10000),
          reason: 'Should render 50KB HTML in < 10s (debug mode)');
    });

    testWidgets('virtualizes 100KB+ HTML document', (tester) async {
      final veryLargeHtml =
          _generateLargeHtml(paragraphs: 300, wordsPerParagraph: 100);

      expect(veryLargeHtml.length, greaterThan(100000),
          reason: 'Document should be > 100KB');

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: veryLargeHtml,
              mode: HyperRenderMode.virtualized,
              placeholderBuilder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 5)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      stopwatch.stop();

      expect(tester.takeException(), isNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(10000),
          reason: 'Should load 100KB+ HTML in < 10s (debug mode)');

      // Virtualized mode uses ListView
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('scrolls smoothly through large document', (tester) async {
      // Use sync mode so the viewer renders immediately (no isolate/spinner).
      // This allows pumpAndSettle to work and scroll finders to locate widgets.
      final largeHtml = _generateLargeHtml(paragraphs: 100, wordsPerParagraph: 50);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: largeHtml, mode: HyperRenderMode.sync),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Drag down — should not throw
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -500),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -5000),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    testWidgets('handles 1000+ elements efficiently', (tester) async {
      final buffer = StringBuffer('<ul>');
      for (int i = 1; i <= 1000; i++) {
        buffer.write('<li>Item $i with some content</li>');
      }
      buffer.write('</ul>');

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: buffer.toString(),
              mode: HyperRenderMode.virtualized,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 5)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      stopwatch.stop();

      expect(tester.takeException(), isNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(10000),
          reason: 'Should handle 1000+ elements in < 10s (debug mode)');
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('handles deeply nested HTML', (tester) async {
      final buffer = StringBuffer();
      for (int i = 1; i <= 20; i++) {
        buffer.write('<div style="padding-left:10px;">Level $i ');
      }
      buffer.write('<p>Deeply nested content</p>');
      for (int i = 0; i < 20; i++) {
        buffer.write('</div>');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: buffer.toString()),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);

      // Verify parser captures all 20 levels
      final doc = HtmlAdapter().parse(buffer.toString());
      final text = doc.textContent;
      expect(text, contains('Level 1'));
      expect(text, contains('Level 20'));
      expect(text, contains('Deeply nested content'));
    });

    testWidgets('handles mixed large content (text + images + tables)',
        (tester) async {
      final buf = StringBuffer('<article><h1>Large Mixed Content Test</h1>');
      // 70 sections × ~460 chars ≈ 32KB > 30KB threshold.
      for (int i = 1; i <= 70; i++) {
        buf.write('''
  <section>
    <h2>Section $i</h2>
    <p>This is paragraph $i with some long text content that wraps to multiple lines.</p>
    <img src="data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs="
         style="width:100%;max-width:400px;">
    <table border="1" style="width:100%;border-collapse:collapse;">
      <tr><th>Col 1</th><th>Col 2</th><th>Col 3</th></tr>
      <tr><td>Data $i-A</td><td>Data $i-B</td><td>Data $i-C</td></tr>
    </table>
  </section>
''');
      }
      buf.write('</article>');
      final html = buf.toString();

      expect(html.length, greaterThan(30000),
          reason: 'Mixed content should be > 30KB');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, mode: HyperRenderMode.virtualized),
          ),
        ),
      );

      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 5)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);

      // Parser-level content check
      final doc = HtmlAdapter().parse(html);
      final text = doc.textContent;
      expect(text, contains('Large Mixed Content Test'));
      expect(text, contains('Section 1'));
    });
  });

  // ─── Parser-level size/structure tests ────────────────────────────────────

  group('Large Document — Parser correctness', () {
    test('50-para document parsed without error', () {
      final html = _generateLargeHtml(paragraphs: 50, wordsPerParagraph: 30);
      final doc = HtmlAdapter().parse(html);
      expect(doc.children, isNotEmpty);
      expect(doc.textContent, contains('Paragraph 1'));
      expect(doc.textContent, contains('Paragraph 50'));
    });

    test('document with 1000 list items parsed correctly', () {
      final buf = StringBuffer('<ul>');
      for (int i = 1; i <= 1000; i++) {
        buf.write('<li>Item $i</li>');
      }
      buf.write('</ul>');
      final doc = HtmlAdapter().parse(buf.toString());
      expect(doc.children, isNotEmpty);
      expect(doc.textContent, contains('Item 1'));
      expect(doc.textContent, contains('Item 1000'));
    });

    test('deeply nested HTML: textContent captures all levels', () {
      final buf = StringBuffer();
      for (int i = 1; i <= 10; i++) {
        buf.write('<div>Level $i ');
      }
      buf.write('<p>Leaf</p>');
      for (int i = 0; i < 10; i++) {
        buf.write('</div>');
      }
      final doc = HtmlAdapter().parse(buf.toString());
      final t = doc.textContent;
      for (int i = 1; i <= 10; i++) {
        expect(t, contains('Level $i'));
      }
      expect(t, contains('Leaf'));
    });
  });
}

String _generateLargeHtml({
  required int paragraphs,
  required int wordsPerParagraph,
}) {
  const words = [
    'lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing',
    'elit', 'sed', 'do', 'eiusmod', 'tempor', 'incididunt', 'ut', 'labore',
    'et', 'dolore', 'magna', 'aliqua', 'enim', 'ad', 'minim', 'veniam',
    'quis', 'nostrud', 'exercitation', 'ullamco', 'laboris',
  ];

  final buffer = StringBuffer('<article><h1>Large Document Test</h1>');

  for (int p = 1; p <= paragraphs; p++) {
    buffer.write('\n<h2>Paragraph $p</h2>\n<p>');
    for (int w = 0; w < wordsPerParagraph; w++) {
      buffer.write(words[w % words.length]);
      if (w < wordsPerParagraph - 1) buffer.write(' ');
    }
    buffer.write('</p>');
    if (p % 10 == 0) {
      buffer.write(
          '<ul><li>List item 1</li><li>List item 2</li><li>List item 3</li></ul>');
    }
  }

  buffer.write('</article>');
  return buffer.toString();
}
