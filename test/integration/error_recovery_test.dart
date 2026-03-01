import "package:hyper_render/hyper_render.dart";
// ignore_for_file: text_direction_code_point_in_literal
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Error Recovery Integration Tests', () {
    testWidgets('handles malformed HTML gracefully', (tester) async {
      const malformedHtml = '''
<div>
  <p>Unclosed paragraph
  <div>Mismatched tags</p>
  <img src="image.jpg" <!-- Missing closing bracket
  <a href="link">Unclosed link
  <ul>
    <li>Item 1
    <li>Item 2 <!-- Missing closing tags
  </div> <!-- Extra closing tag
</span> <!-- Never opened
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: malformedHtml,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not crash despite malformed HTML
      expect(tester.takeException(), isNull);

      // Should render something (parser recovers)
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('handles empty HTML', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: ''),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not crash on empty HTML
      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('handles whitespace-only HTML', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: '   \n\n\t\t   '),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('handles HTML with only comments', (tester) async {
      const commentsOnly = '''
<!-- This is a comment -->
<!-- Another comment -->
<!-- <div>Commented out HTML</div> -->
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: commentsOnly),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('handles invalid CSS gracefully', (tester) async {
      const invalidCss = '''
<style>
  .class { color: not-a-color; }
  .other { font-size: invalid; }
  .broken { margin: ; }
  syntax error here
</style>
<p class="class">This should still render</p>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: invalidCss),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('handles broken image URLs', (tester) async {
      const brokenImages = '''
<div>
  <img src="">
  <img src="not-a-url">
  <img src="http://definitely-doesnt-exist-12345.com/image.jpg">
  <img>
  <p>Text content should still work</p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: brokenImages),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('handles circular CSS references', (tester) async {
      const circularCss = '''
<style>
  .a { color: inherit; }
  .b { font-size: inherit; }
</style>
<div class="a">
  <div class="b">
    <p>Content with circular inheritance</p>
  </div>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: circularCss),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('handles extremely deep nesting', (tester) async {
      // 100 levels of nesting
      final buffer = StringBuffer();

      for (int i = 0; i < 100; i++) {
        buffer.write('<div>');
      }

      buffer.write('Deep content');

      for (int i = 0; i < 100; i++) {
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
    });

    testWidgets('handles unicode edge cases', (tester) async {
      const unicodeEdgeCases = '''
<div>
  <p>Zero-width characters: ​‌‍</p>
  <p>RTL override: ‮This text is reversed‬</p>
  <p>Combining characters: e̊a̧b̧c̊</p>
  <p>Emoji sequences: 👨‍👩‍👧‍👦 👩‍💻 🏳️‍🌈</p>
  <p>Mathematical: ∫∑∏√∞≠≈±</p>
  <p>Unusual spaces:      </p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: unicodeEdgeCases),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('handles invalid JSON in Delta mode', (tester) async {
      const invalidDeltas = [
        '',                    // Empty
        '{',                   // Incomplete JSON
        '{"ops":',            // Incomplete
        '{"ops": [}',         // Malformed array
        'not json at all',    // Not JSON
      ];

      for (final delta in invalidDeltas) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperViewer.delta(delta: delta),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not crash, should handle gracefully
        expect(tester.takeException(), isNull,
            reason: 'Should handle invalid Delta: $delta');

        // Clear widget
        await tester.pumpWidget(Container());
        await tester.pump();
      }
    });

    testWidgets('handles extremely long lines without crash', (tester) async {
      // Single paragraph with 10,000 words (very long line)
      final longLine = '<p>${'word ' * 10000}</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: longLine),
            ),
          ),
        ),
      );

      // Use pump() instead of pumpAndSettle() to avoid timeout with large content
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('handles many floats without performance degradation', (tester) async {
      // 50 floats (stress test)
      final manyFloats = StringBuffer('<div style="width: 600px;">');

      for (int i = 0; i < 50; i++) {
        manyFloats.write('''
  <img src="https://picsum.photos/50/50?random=$i"
       style="float: ${i % 2 == 0 ? 'left' : 'right'}; width: 50px; height: 50px;">
''');
      }

      manyFloats.write('<p>${'Text content ' * 100}</p></div>');

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: manyFloats.toString()),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      expect(tester.takeException(), isNull);

      // Should still be reasonably fast (< 1 second even with 50 floats)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: '50 floats should render in < 1s');
    });

    testWidgets('recovers from layout errors with error boundaries', (tester) async {
      // This HTML might cause layout issues but should be caught by error boundaries
      const problematicHtml = '''
<div style="width: -100px;">Negative width</div>
<div style="height: 99999999px;">Huge height</div>
<table><tr><td colspan="999999">Too many columns</td></tr></table>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: problematicHtml),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Error boundaries should prevent crash
      expect(tester.takeException(), isNull,
          reason: 'Error boundaries should catch layout errors');
    });

    testWidgets('handles rapid content changes', (tester) async {
      // Rapidly change HTML content
      for (int i = 0; i < 20; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperViewer(
                html: '<p>Content change $i</p>',
                key: ValueKey(i),
              ),
            ),
          ),
        );

        await tester.pump();
      }

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('handles concurrent mode switches', (tester) async {
      const html = '<p>Test content</p>';

      // Switch modes rapidly
      for (final mode in [
        HyperRenderMode.sync,
        HyperRenderMode.virtualized,
        HyperRenderMode.auto,
        HyperRenderMode.sync,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperViewer(
                html: html,
                mode: mode,
                key: ValueKey(mode),
              ),
            ),
          ),
        );

        await tester.pump();
      }

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });
}
