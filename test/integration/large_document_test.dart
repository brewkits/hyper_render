import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('Large Document Integration Tests', () {
    testWidgets('renders 50KB HTML document smoothly', (tester) async {
      // Generate large HTML document (~50KB)
      final largeHtml = _generateLargeHtml(
        paragraphs: 100,
        wordsPerParagraph: 50,
      );

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: largeHtml,
              mode: HyperRenderMode.auto, // Should choose sync
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Verify render time is reasonable (< 500ms for 50KB)
      expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: 'Should render 50KB HTML in < 500ms');

      // Verify first paragraph is visible
      expect(find.textContaining('Paragraph 1'), findsOneWidget);
    });

    testWidgets('virtualizes 100KB+ HTML document', (tester) async {
      // Generate very large HTML document (~100KB+)
      final veryLargeHtml = _generateLargeHtml(
        paragraphs: 300,
        wordsPerParagraph: 100,
      );

      expect(veryLargeHtml.length, greaterThan(100000),
          reason: 'Document should be > 100KB');

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: veryLargeHtml,
              mode: HyperRenderMode.virtualized,
              placeholderBuilder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );

      // Wait for loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));

      // Wait for content to load (async parsing in isolate)
      await tester.pumpAndSettle(const Duration(seconds: 5));
      stopwatch.stop();

      // Verify loading completed (< 5 seconds for 100KB)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: 'Should load 100KB+ HTML in < 5 seconds');

      // Verify first paragraph is visible
      expect(find.textContaining('Paragraph 1'), findsOneWidget);

      // Verify ListView is used (virtualized mode)
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('scrolls smoothly through large document', (tester) async {
      final largeHtml = _generateLargeHtml(
        paragraphs: 100,
        wordsPerParagraph: 50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: largeHtml,
              mode: HyperRenderMode.auto,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll down
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -500),
      );
      await tester.pump();

      // Scroll should work without errors
      expect(tester.takeException(), isNull);

      // Scroll to bottom
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -5000),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('handles 1000+ elements efficiently', (tester) async {
      // Generate HTML with many small elements
      final buffer = StringBuffer('<div>');

      // 1000 list items
      buffer.write('<ul>');
      for (int i = 1; i <= 1000; i++) {
        buffer.write('<li>Item $i with some content</li>');
      }
      buffer.write('</ul>');

      buffer.write('</div>');

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

      await tester.pumpAndSettle(const Duration(seconds: 5));
      stopwatch.stop();

      // Should handle 1000+ elements (< 3 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: 'Should handle 1000+ elements in < 3s');

      // Verify first item visible
      expect(find.textContaining('Item 1'), findsOneWidget);
    });

    testWidgets('handles deeply nested HTML', (tester) async {
      // Generate deeply nested HTML (20 levels)
      final buffer = StringBuffer();

      // Open 20 divs
      for (int i = 1; i <= 20; i++) {
        buffer.write('<div style="padding-left: 10px;">Level $i');
      }

      buffer.write('<p>Deeply nested content</p>');

      // Close 20 divs
      for (int i = 1; i <= 20; i++) {
        buffer.write('</div>');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: buffer.toString(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify deeply nested content renders
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Level 20'), findsOneWidget);
      expect(find.text('Deeply nested content'), findsOneWidget);
    });

    testWidgets('handles mixed large content (text + images + tables)', (tester) async {
      final buffer = StringBuffer('''
<article>
  <h1>Large Mixed Content Test</h1>
''');

      // Add 50 sections with text + image + table
      for (int i = 1; i <= 50; i++) {
        buffer.write('''
  <section>
    <h2>Section $i</h2>
    <p>This is paragraph $i with some long text content that wraps to multiple lines. It contains enough text to make the document large.</p>

    <img src="https://picsum.photos/400/300?random=$i" style="width: 100%; height: auto; max-width: 400px;">

    <table border="1" style="width: 100%; border-collapse: collapse;">
      <tr>
        <th>Column 1</th>
        <th>Column 2</th>
        <th>Column 3</th>
      </tr>
      <tr>
        <td>Data $i-1</td>
        <td>Data $i-2</td>
        <td>Data $i-3</td>
      </tr>
    </table>
  </section>
''');
      }

      buffer.write('</article>');

      final html = buffer.toString();
      expect(html.length, greaterThan(30000),
          reason: 'Mixed content should be > 30KB');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: html,
              mode: HyperRenderMode.virtualized,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify renders without crashing
      expect(tester.takeException(), isNull);
      expect(find.text('Large Mixed Content Test'), findsOneWidget);
      expect(find.text('Section 1'), findsOneWidget);
    });
  });
}

/// Generate large HTML document for testing
String _generateLargeHtml({
  required int paragraphs,
  required int wordsPerParagraph,
}) {
  final buffer = StringBuffer('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Large Document Test</title>
</head>
<body>
  <article>
    <h1>Large Document Test</h1>
    <p>This is a generated document with $paragraphs paragraphs, each with approximately $wordsPerParagraph words.</p>
''');

  final loremWords = [
    'lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing',
    'elit', 'sed', 'do', 'eiusmod', 'tempor', 'incididunt', 'ut', 'labore',
    'et', 'dolore', 'magna', 'aliqua', 'enim', 'ad', 'minim', 'veniam',
    'quis', 'nostrud', 'exercitation', 'ullamco', 'laboris', 'nisi', 'aliquip',
    'ex', 'ea', 'commodo', 'consequat', 'duis', 'aute', 'irure', 'in',
    'reprehenderit', 'voluptate', 'velit', 'esse', 'cillum', 'fugiat', 'nulla',
    'pariatur', 'excepteur', 'sint', 'occaecat', 'cupidatat', 'non', 'proident',
  ];

  for (int p = 1; p <= paragraphs; p++) {
    buffer.write('\n    <h2>Paragraph $p</h2>\n    <p>');

    for (int w = 0; w < wordsPerParagraph; w++) {
      buffer.write(loremWords[w % loremWords.length]);
      if (w < wordsPerParagraph - 1) buffer.write(' ');
    }

    buffer.write('</p>');

    // Add some variety every 10 paragraphs
    if (p % 10 == 0) {
      buffer.write('''
    <ul>
      <li>List item 1</li>
      <li>List item 2</li>
      <li>List item 3</li>
    </ul>
''');
    }
  }

  buffer.write('''
  </article>
</body>
</html>
''');

  return buffer.toString();
}
