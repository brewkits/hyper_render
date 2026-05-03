import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('HyperRender Memory & Lifecycle Stability', () {
    testWidgets('Stays stable under 100 fast navigation cycles',
        (tester) async {
      const html =
          '<h1>Navigation Test</h1><p>Content that should be disposed correctly.</p>';

      for (int i = 0; i < 100; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperViewer(html: html, key: ValueKey('viewer-$i')),
            ),
          ),
        );
        // We only pump one frame to simulate very fast navigation
        await tester.pump();

        // Navigate away
        await tester
            .pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('Handles disposal during active async parse', (tester) async {
      final veryLargeHtml = '<div>${"Large content " * 5000}</div>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: veryLargeHtml, mode: HyperRenderMode.auto),
          ),
        ),
      );

      // Active parse is happening in isolate...
      await tester.pump();

      // Immediately dispose
      await tester
          .pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

      // Wait to see if any late setState calls or isolate callbacks cause errors
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Resource cleanup: images and controllers', (tester) async {
      // Test that large documents with many images don't leak memory
      // by ensuring they can be rebuilt many times.
      final html =
          '<div>${List.generate(20, (i) => '<img src="img$i.png">').join()}</div>';

      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperViewer(html: html, key: ValueKey('img-test-$i')),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    });
  });
}
