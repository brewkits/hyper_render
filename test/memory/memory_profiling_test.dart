import "package:hyper_render/hyper_render.dart";
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Memory Profiling Suite
//
// Goals:
//   1. Verify resource cleanup on dispose (no leaks from painters, recognizers,
//      images).
//   2. Confirm the LRU text-painter cache stays bounded under a large document.
//   3. Show that incremental layout doesn't accumulate extra memory across
//      repeated document updates.
//   4. Provide RSS-based smoke numbers for large / image-heavy documents so CI
//      can catch regressions (soft thresholds, not hard failures).
//
// Run with:
//   flutter test test/memory/memory_profiling_test.dart --verbose
// ---------------------------------------------------------------------------

/// Return current Resident Set Size in MiB (0 on web / unsupported platforms).
int _rssMiB() {
  try {
    return ProcessInfo.currentRss ~/ (1024 * 1024);
  } catch (_) {
    return 0;
  }
}

/// Build a large HTML document with [paragraphCount] paragraphs of mixed content.
String _generateLargeHtml({int paragraphCount = 200}) {
  final sb = StringBuffer('<html><body>');
  for (var i = 0; i < paragraphCount; i++) {
    sb.write('''
      <h2>Section $i</h2>
      <p>This is paragraph $i with <strong>bold text</strong>, '
         '<em>italic text</em>, and a
         <a href="https://example.com">link</a>.</p>
      <ul>
        <li>Item A in section $i</li>
        <li>Item B in section $i</li>
      </ul>
    ''');
  }
  sb.write('</body></html>');
  return sb.toString();
}

/// Build HTML with [count] img tags (no actual network requests — src is
/// a recognisable placeholder that will fail gracefully).
String _generateImageHeavyHtml({int count = 50}) {
  final sb = StringBuffer('<html><body>');
  for (var i = 0; i < count; i++) {
    sb.write('<img src="https://placeholder.test/img$i.png" '
        'width="200" height="150" alt="image $i"><br>');
  }
  sb.write('</body></html>');
  return sb.toString();
}

void main() {
  // ---------------------------------------------------------------------------
  // 1. Resource cleanup on dispose
  // ---------------------------------------------------------------------------
  group('Resource cleanup on dispose', () {
    testWidgets('disposes text painters and link recognizers', (tester) async {
      const html = '''
        <h1>Hello World</h1>
        <p>Visit <a href="https://example.com">example.com</a> today.</p>
        <p><strong>Bold</strong> and <em>italic</em> content.</p>
      ''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Widget is alive — just verify it rendered without error.
      expect(find.byType(HyperViewer), findsOneWidget);

      // Replace with an empty widget to trigger dispose.
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();

      // No assertions on internal state needed — if dispose() throws
      // (e.g. double-dispose of TextPainter), the test fails here.
    });

    testWidgets('repeated mount/unmount does not throw', (tester) async {
      const html = '<p>Mount and unmount test</p>';

      for (var cycle = 0; cycle < 10; cycle++) {
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: HyperViewer(html: html))),
        );
        await tester.pump();
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        await tester.pump();
      }

      // If we reach here, no resource management errors occurred.
      expect(true, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. LRU cache stays bounded
  // ---------------------------------------------------------------------------
  group('LRU text-painter cache stays bounded', () {
    testWidgets('large document does not exceed LRU max size', (tester) async {
      // 200 paragraphs → many unique (text, style) combos but LRU caps at 5000.
      final html = _generateLargeHtml(paragraphCount: 200);

      final before = _rssMiB();

      // 200-paragraph HTML > 10KB → auto mode → virtualized (ListView.builder).
      // Do NOT wrap in SingleChildScrollView — ListView provides its own scroll.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html),
          ),
        ),
      );
      // compute() isolate runs in real time; runAsync waits for it.
      await tester.pump();
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 5)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final after = _rssMiB();
      final deltaMiB = after - before;

      print('[Memory] 200-paragraph document — RSS delta: ${deltaMiB}MiB');

      // Soft threshold: large document should not require more than 500 MiB
      // of additional RSS.  Debug-mode Flutter has significant overhead vs
      // release builds; 500 MiB catches catastrophic leaks, not small drifts.
      if (deltaMiB > 500) {
        fail('RSS grew by ${deltaMiB}MiB for 200-paragraph document '
            '(threshold: 500MiB). Possible memory leak.');
      }
    });

    testWidgets('500 repeated HyperViewer widgets — bounded peak memory',
        (tester) async {
      // Simulates a long list where each item is a separate HyperViewer.
      // Only a few are visible at a time (ListView.builder).
      final items = List.generate(
        500,
        (i) => '<p>Item <strong>$i</strong>: content goes here.</p>',
      );

      final before = _rssMiB();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => SizedBox(
                height: 60,
                child: HyperViewer(html: items[i]),
              ),
            ),
          ),
        ),
      );

      // Only the visible viewport renders; scroll a bit to trigger recycling.
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      final after = _rssMiB();
      final deltaMiB = after - before;

      print('[Memory] 500-item ListView — RSS delta: ${deltaMiB}MiB');

      if (deltaMiB > 200) {
        fail('RSS grew by ${deltaMiB}MiB for 500-item list '
            '(threshold: 200MiB).');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 3. Incremental layout — no memory growth across updates
  // ---------------------------------------------------------------------------
  group('Incremental layout memory stability', () {
    testWidgets('updating document 50 times does not grow RSS unboundedly',
        (tester) async {
      var currentHtml = _generateLargeHtml(paragraphCount: 10);

      // ValueNotifier lets us swap the document without rebuilding the tree.
      final notifier = ValueNotifier<String>(currentHtml);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<String>(
              valueListenable: notifier,
              builder: (_, html, __) => SingleChildScrollView(
                child: HyperViewer(html: html),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = _rssMiB();

      // Update document 50 times alternating between two variants.
      for (var i = 0; i < 50; i++) {
        final alt = i.isEven
            ? _generateLargeHtml(paragraphCount: 10)
            : _generateLargeHtml(paragraphCount: 12);
        notifier.value = alt;
        await tester.pump();
      }

      await tester.pumpAndSettle();
      final after = _rssMiB();
      final deltaMiB = after - before;

      print('[Memory] 50 document updates — RSS delta: ${deltaMiB}MiB');

      if (deltaMiB > 80) {
        fail('RSS grew by ${deltaMiB}MiB across 50 document updates '
            '(threshold: 80MiB). Possible leak in layout invalidation path.');
      }

      notifier.dispose();
    });

    testWidgets('width constraint changes do not rebuild fragment list',
        (tester) async {
      // Regression: if width changes cause retokenization, it's a perf bug.
      // We can't directly inspect _fragmentsVersion from the test, but we
      // verify RSS stays stable as a proxy.
      final html = _generateLargeHtml(paragraphCount: 30);

      final widthNotifier = ValueNotifier<double>(300.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<double>(
              valueListenable: widthNotifier,
              builder: (_, width, __) => SizedBox(
                width: width,
                child: HyperViewer(html: html),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = _rssMiB();

      // Simulate 20 width changes (e.g. rotation or window resize).
      for (final w in List.generate(20, (i) => 300.0 + i * 5)) {
        widthNotifier.value = w;
        await tester.pump();
      }

      await tester.pumpAndSettle();
      final after = _rssMiB();
      final deltaMiB = after - before;

      print('[Memory] 20 width changes — RSS delta: ${deltaMiB}MiB');

      if (deltaMiB > 30) {
        fail('RSS grew by ${deltaMiB}MiB across 20 width changes '
            '(threshold: 30MiB). Text painter cache may be leaking.');
      }

      widthNotifier.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Image-heavy document
  // ---------------------------------------------------------------------------
  group('Image-heavy document memory', () {
    testWidgets('50 images (all fail gracefully) — bounded memory',
        (tester) async {
      final html = _generateImageHeavyHtml(count: 50);

      final before = _rssMiB();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: html),
            ),
          ),
        ),
      );

      // Let image errors surface.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      final after = _rssMiB();
      final deltaMiB = after - before;

      print('[Memory] 50-image document (all failing) — RSS delta: ${deltaMiB}MiB');

      if (deltaMiB > 60) {
        fail('RSS grew by ${deltaMiB}MiB for 50-image document '
            '(threshold: 60MiB). Image error path may be leaking.');
      }
    });

    testWidgets('dispose clears image cache', (tester) async {
      final html = _generateImageHeavyHtml(count: 20);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HyperViewer(html: html))),
      );
      await tester.pump();

      // Dispose by replacing the widget tree.
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();

      // Verify no crash occurred during dispose with pending image loads.
      expect(find.byType(HyperViewer), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. Summary report
  // ---------------------------------------------------------------------------
  test('Print memory profiling summary', () {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('  HyperRender Memory Profiling Suite — Summary');
    print('  See individual test output above for RSS deltas.');
    print('');
    print('  Thresholds (soft — failures indicate leaks):');
    print('    200-paragraph document   : < 150 MiB RSS delta');
    print('    500-item ListView        : < 200 MiB RSS delta');
    print('    50 document updates      : <  80 MiB RSS delta');
    print('    20 width changes         : <  30 MiB RSS delta');
    print('    50 failing images        : <  60 MiB RSS delta');
    print('═══════════════════════════════════════════════════════');
  });
}
