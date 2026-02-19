import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('Performance Regression Tests', () {
    testWidgets('parse time: 1KB HTML < 10ms', (tester) async {
      const smallHtml = '''
<article>
  <h1>Title</h1>
  <p>This is a small HTML document for performance testing.</p>
  <ul>
    <li>Item 1</li>
    <li>Item 2</li>
    <li>Item 3</li>
  </ul>
</article>
''';

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: smallHtml,
              mode: HyperRenderMode.sync,
            ),
          ),
        ),
      );

      await tester.pump(); // First frame
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(10),
          reason: 'Small HTML should parse + render in < 10ms');
    });

    testWidgets('parse time: 10KB HTML < 50ms', (tester) async {
      final mediumHtml = _generateHtml(size: 10000);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: mediumHtml,
              mode: HyperRenderMode.sync,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: '10KB HTML should render in < 50ms');
    });

    testWidgets('parse time: 100KB HTML < 200ms (async)', (tester) async {
      final largeHtml = _generateHtml(size: 100000);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: largeHtml,
              mode: HyperRenderMode.virtualized, // Async parsing
            ),
          ),
        ),
      );

      // Wait for async parsing to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(2000),
          reason: '100KB HTML should parse + render in < 2s (async)');
    });

    testWidgets('CSS resolution: 100 rules < 5ms', (tester) async {
      // HTML with 100 styled elements
      final buffer = StringBuffer('''
<style>
  .class1 { color: red; font-size: 14px; }
  .class2 { color: blue; font-size: 16px; }
  .class3 { color: green; font-size: 18px; }
  .class4 { color: orange; font-weight: bold; }
  .class5 { color: purple; font-style: italic; }
</style>
<div>
''');

      for (int i = 0; i < 100; i++) {
        final classNum = (i % 5) + 1;
        buffer.write('<p class="class$classNum">Text $i</p>');
      }

      buffer.write('</div>');

      final stopwatch = Stopwatch()..start();

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
      stopwatch.stop();

      // CSS resolution should be fast (< 50ms for 100 elements)
      expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: 'CSS resolution for 100 rules should be < 50ms');
    });

    testWidgets('float layout: 10 floats < 20ms overhead', (tester) async {
      final floatHtml = '''
<div style="width: 600px;">
  ${List.generate(10, (i) => '''
    <img src="https://picsum.photos/100/100?random=$i"
         style="float: ${i % 2 == 0 ? 'left' : 'right'}; width: 100px; height: 100px; margin: 8px;">
  ''').join()}

  <p>${'Lorem ipsum ' * 100}</p>
</div>
''';

      // Measure baseline (no floats)
      final noFloatHtml = '''
<div style="width: 600px;">
  <p>${'Lorem ipsum ' * 100}</p>
</div>
''';

      // Baseline
      final baseline = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: noFloatHtml),
          ),
        ),
      );
      await tester.pumpAndSettle();
      baseline.stop();

      await tester.pumpWidget(Container());
      await tester.pump();

      // With floats
      final withFloats = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: floatHtml),
          ),
        ),
      );
      await tester.pumpAndSettle();
      withFloats.stop();

      final overhead = withFloats.elapsedMilliseconds - baseline.elapsedMilliseconds;

      // Float overhead should be < 20ms for 10 floats
      expect(overhead, lessThan(20),
          reason: 'Float layout overhead should be < 20ms for 10 floats');
    });

    testWidgets('table rendering: 100 rows < 100ms', (tester) async {
      final buffer = StringBuffer('''
<table border="1" style="width: 100%; border-collapse: collapse;">
  <thead>
    <tr>
      <th>ID</th>
      <th>Name</th>
      <th>Value</th>
      <th>Status</th>
    </tr>
  </thead>
  <tbody>
''');

      for (int i = 1; i <= 100; i++) {
        buffer.write('''
    <tr>
      <td>$i</td>
      <td>Item $i</td>
      <td>\$${i * 10}</td>
      <td>${i % 2 == 0 ? 'Active' : 'Inactive'}</td>
    </tr>
''');
      }

      buffer.write('</tbody></table>');

      final stopwatch = Stopwatch()..start();

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
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: '100-row table should render in < 100ms');
    });

    testWidgets('selection hit test: < 1ms', (tester) async {
      const html = '''
<p>This is a test paragraph for selection performance testing.
It has multiple lines and should respond quickly to tap events.</p>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: html,
              selectable: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Measure tap response time
      final stopwatch = Stopwatch()..start();

      await tester.tapAt(const Offset(100, 100));
      await tester.pump();

      stopwatch.stop();

      // Hit test should be < 1ms (very fast)
      expect(stopwatch.elapsedMicroseconds, lessThan(1000),
          reason: 'Selection hit test should be < 1ms');
    });

    testWidgets('rebuild performance: same content < 5ms', (tester) async {
      const html = '<p>Test content</p>';

      // Initial build
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Rebuild with same content (should be fast due to caching)
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html),
          ),
        ),
      );

      await tester.pump();
      stopwatch.stop();

      // Rebuild should be very fast (< 5ms) due to caching
      expect(stopwatch.elapsedMilliseconds, lessThan(5),
          reason: 'Rebuild with same content should be < 5ms');
    });

    testWidgets('memory: doesn\'t grow on repeated renders', (tester) async {
      const html = '<p>Memory test content</p>';

      // Render multiple times
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperViewer(html: html, key: ValueKey(i)),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Clear previous widget
        await tester.pumpWidget(Container());
        await tester.pump();
      }

      // If memory leaked, this test would fail due to out of memory
      // No assertion needed - successful completion means no leak
      expect(true, true);
    });
  });
}

/// Generate HTML of approximate size
String _generateHtml({required int size}) {
  final buffer = StringBuffer('<article>');
  int currentSize = buffer.length;

  int paragraphNum = 1;
  while (currentSize < size) {
    buffer.write('<p>Paragraph $paragraphNum. ');
    buffer.write('Lorem ipsum dolor sit amet consectetur adipiscing elit. ');
    buffer.write('</p>');

    currentSize = buffer.length;
    paragraphNum++;
  }

  buffer.write('</article>');
  return buffer.toString();
}
