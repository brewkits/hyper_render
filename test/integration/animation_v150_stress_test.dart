// Stress tests for v1.5.0 animation features.
//
// Covers a large count of concurrently animated elements and rapid style
// churn (the didUpdateWidget path in HyperAnimatedWidget / HyperTransitionWidget
// that disposes and recreates AnimationControllers).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('v1.5.0 animation stress', () {
    testWidgets('300 concurrently animated color boxes stay stable',
        (tester) async {
      final html = StringBuffer('''
<style>
  @keyframes glow { from { background-color: #6366f1; } to { background-color: #ec4899; } }
  .b { width: 20px; height: 20px; display: inline-block; margin: 2px; }
</style>
''');
      for (var i = 0; i < 300; i++) {
        html.write(
            '<div class="b" style="animation: glow ${1 + i % 3}s steps(${(i % 6) + 1}, end) infinite alternate;"></div>');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                  html: html.toString(), mode: HyperRenderMode.sync),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('rapid timing-function swaps do not leak or crash',
        (tester) async {
      const timings = [
        'cubic-bezier(0.4, 0, 0.2, 1)',
        'steps(4, end)',
        'linear',
        'step-start',
        'ease-in-out',
      ];

      for (var i = 0; i < 20; i++) {
        final fn = timings[i % timings.length];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperViewer(
                html:
                    '<div style="opacity:0.5; background-color:#eef; transition: all 0.3s $fn">churn $i</div>',
                mode: HyperRenderMode.sync,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });
  });
}
