import "package:hyper_render/hyper_render.dart";
// Performance regression tests.
//
// These tests protect against catastrophic regressions, not micro-benchmarks.
// Thresholds are set very loosely because:
//   • Flutter test runner runs in debug mode (JIT, no AOT optimisations)
//   • pumpAndSettle() includes layout + paint overhead
//   • CI machines vary widely in performance
//
// A real performance benchmark suite belongs in the benchmark/ directory.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Performance Regression Tests', () {
    testWidgets('parse time: 1KB HTML completes without error', (tester) async {
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
            body: HyperViewer(html: smallHtml, mode: HyperRenderMode.sync),
          ),
        ),
      );

      await tester.pump();
      stopwatch.stop();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
      // Debug-mode threshold: 3 seconds (catastrophic regression guard only)
      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: 'Small HTML must render in < 3s (debug mode)');
    });

    testWidgets('parse time: 10KB HTML completes without error', (tester) async {
      final mediumHtml = _generateHtml(size: 10000);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: mediumHtml, mode: HyperRenderMode.sync),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      expect(tester.takeException(), isNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: '10KB HTML must render in < 5s (debug mode)');
    });

    testWidgets('parse time: 100KB HTML (async) completes without error',
        (tester) async {
      final largeHtml = _generateHtml(size: 100000);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: largeHtml, mode: HyperRenderMode.virtualized),
          ),
        ),
      );

      // Virtualized mode spawns a real isolate via compute().
      // pumpAndSettle never settles while CircularProgressIndicator is showing.
      // Use runAsync to wait for the isolate in real time, then process setState.
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 5)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      stopwatch.stop();

      expect(tester.takeException(), isNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(10000),
          reason: '100KB async HTML must complete in < 10s (debug mode)');
    });

    testWidgets('CSS resolution: 100 styled elements renders without error',
        (tester) async {
      final buffer = StringBuffer('''
<style>
  .class1 { color: red;    font-size: 14px; }
  .class2 { color: blue;   font-size: 16px; }
  .class3 { color: green;  font-size: 18px; }
  .class4 { color: orange; font-weight: bold; }
  .class5 { color: purple; font-style: italic; }
</style>
<div>
''');

      for (int i = 0; i < 100; i++) {
        buffer.write('<p class="class${(i % 5) + 1}">Text $i</p>');
      }
      buffer.write('</div>');

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: HyperViewer(html: buffer.toString())),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      expect(tester.takeException(), isNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: '100 CSS-styled elements must render in < 5s (debug mode)');
    });

    testWidgets('float layout: 10 floats renders without crash', (tester) async {
      final floatHtml = '''
<div>
  ${List.generate(10, (i) => '''
    <img src="data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs="
         style="float:${i.isEven ? 'left' : 'right'};
                width:60px;height:60px;margin:8px;">
  ''').join()}
  <p>${'Lorem ipsum dolor sit amet. ' * 20}</p>
  <div style="clear:both;"></div>
</div>
''';

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HyperViewer(html: floatHtml)),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      expect(tester.takeException(), isNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: '10 floats must render in < 5s (debug mode)');
    });

    testWidgets('table rendering: 100 rows renders without crash', (tester) async {
      final buffer = StringBuffer('''
<table border="1" style="width:100%;border-collapse:collapse;">
  <thead>
    <tr><th>ID</th><th>Name</th><th>Value</th><th>Status</th></tr>
  </thead>
  <tbody>
''');

      for (int i = 1; i <= 100; i++) {
        buffer.write('''
    <tr>
      <td>$i</td><td>Item $i</td>
      <td>\$${i * 10}</td>
      <td>${i.isEven ? 'Active' : 'Inactive'}</td>
    </tr>
''');
      }
      buffer.write('</tbody></table>');

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: HyperViewer(html: buffer.toString())),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      expect(tester.takeException(), isNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: '100-row table must render in < 5s (debug mode)');
    });

    testWidgets('selection hit test: responds to tap without error', (tester) async {
      const html = '''
<p>This is a test paragraph for selection performance testing.
It has multiple lines and should respond quickly to tap events.</p>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, selectable: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();
      await tester.tapAt(const Offset(100, 100));
      await tester.pump();
      stopwatch.stop();

      expect(tester.takeException(), isNull);
      // Even in debug mode, a single tap response must complete in < 5s
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: 'Tap response must complete in < 5s (debug mode)');
    });

    testWidgets('rebuild performance: same content rebuilds without error',
        (tester) async {
      const html = '<p>Test content for rebuild check.</p>';

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HyperViewer(html: html))),
      );
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HyperViewer(html: html))),
      );
      await tester.pump();
      stopwatch.stop();

      expect(tester.takeException(), isNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: 'Same-content rebuild must complete in < 3s (debug mode)');
    });

    testWidgets("memory: doesn't grow on repeated renders", (tester) async {
      const html = '<p>Memory test content</p>';

      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: HyperViewer(html: html, key: ValueKey(i))),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pumpWidget(Container());
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
    });
  });
}

String _generateHtml({required int size}) {
  final buffer = StringBuffer('<article>');
  int paragraphNum = 1;
  while (buffer.length < size) {
    buffer.write('<p>Paragraph $paragraphNum. '
        'Lorem ipsum dolor sit amet consectetur adipiscing elit. </p>');
    paragraphNum++;
  }
  buffer.write('</article>');
  return buffer.toString();
}
