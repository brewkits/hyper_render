// Tests for debug-mode memory pressure metrics (v1.5.0).
//
// Verifies that HyperViewer records a HyperMemoryMetrics snapshot to
// HyperMemoryDebug when the platform signals memory pressure.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  setUp(HyperMemoryDebug.reset);
  tearDown(HyperMemoryDebug.reset);

  testWidgets('memory pressure records a metrics snapshot', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HyperViewer(
            html: '<p>Hello <strong>world</strong></p>',
            mode: HyperRenderMode.sync,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(HyperMemoryDebug.lastMetrics, isNull);

    // Simulate an OS memory-pressure signal.
    tester.binding.handleMemoryPressure();
    await tester.pump();

    final metrics = HyperMemoryDebug.lastMetrics;
    expect(metrics, isNotNull);
    // At least one RenderHyperBox exists in a synced document, so it is cleared.
    expect(metrics!.renderBoxesCleared, greaterThanOrEqualTo(1));
    // Non-negative deltas.
    expect(metrics.imageCacheBytesFreed, greaterThanOrEqualTo(0));
    expect(metrics.imageCacheImagesEvicted, greaterThanOrEqualTo(0));
    expect(metrics.pendingImageLoadsDropped, greaterThanOrEqualTo(0));
  });

  testWidgets('onMemoryPressure callback still fires alongside metrics',
      (tester) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HyperViewer(
            html: '<p>x</p>',
            mode: HyperRenderMode.sync,
            onMemoryPressure: () => called = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.binding.handleMemoryPressure();
    await tester.pump();

    expect(called, isTrue);
    expect(HyperMemoryDebug.lastMetrics, isNotNull);
  });
}
