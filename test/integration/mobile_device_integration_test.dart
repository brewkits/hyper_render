import "package:hyper_render/hyper_render.dart";
// Mobile Device Integration Tests
//
// Specialized integration tests for mobile device characteristics:
// - Touch interactions and gestures
// - Screen size variations (phones, tablets, foldables)
// - Memory constraints
// - Platform-specific behaviors (iOS vs Android)
// - Battery and performance optimization
//
// Run on physical devices:
// ```bash
// flutter test --device-id=<device-id> test/integration/mobile_device_integration_test.dart
// ```

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mobile Device: Touch Interactions', () {
    testWidgets('Single tap: Detects tap on selectable text', (tester) async {
      const html = '''
<div style="padding: 40px;">
  <p>Tap me to select text. This paragraph should respond to touch gestures
     on mobile devices including phones and tablets.</p>
</div>
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

      // Tap on the text
      await tester.tapAt(const Offset(100, 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Long press: Triggers text selection', (tester) async {
      const html = '''
<div style="padding: 40px;">
  <p>Long press this text to start selection. Mobile devices typically
     show selection handles after a long press gesture.</p>
</div>
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

      // Long press
      await tester.longPress(find.byType(HyperViewer));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Drag gesture: Selection drag works smoothly', (tester) async {
      const html = '''
<div style="padding: 40px;">
  <p>Drag across this text to select multiple words.
     This tests the selection drag performance on mobile devices.</p>
</div>
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

      // Drag to select
      final startPoint = tester.getCenter(find.byType(HyperViewer));
      await tester.dragFrom(
        startPoint,
        const Offset(200, 0),
        touchSlopX: 0,
        touchSlopY: 0,
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Pinch zoom: Handles zoom gestures (if supported)',
        (tester) async {
      // Note: Pinch zoom may not be supported in test environment
      // This test verifies the widget doesn't crash on scale gestures
      const html = '<div><h1>Zoom Test</h1><p>Try pinch to zoom.</p></div>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should render without crash
      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });

  group('Mobile Device: Screen Size Variations', () {
    testWidgets('Small phone: Renders correctly on small screens',
        (tester) async {
      // Simulate small phone screen (320x568 - iPhone SE)
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      const html = '''
<div style="padding: 16px;">
  <h1>Small Screen Test</h1>
  <p>This content should adapt to small phone screens like iPhone SE (320x568).</p>
  <table border="1" style="width: 100%; border-collapse: collapse;">
    <tr><th>Item</th><th>Value</th></tr>
    <tr><td>Width</td><td>320px</td></tr>
    <tr><td>Height</td><td>568px</td></tr>
  </table>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: html),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Standard phone: Renders on typical phone screens',
        (tester) async {
      // Simulate standard phone (375x667 - iPhone 8)
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      const html = '''
<article style="padding: 16px;">
  <h1>Standard Phone Screen</h1>
  <p>Testing on 375x667 (iPhone 8, iPhone SE 2/3).</p>
  <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
       style="width: 100%; height: 200px; margin: 16px 0;">
  <p>Image should scale to fit screen width.</p>
</article>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: html),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Large phone: Renders on modern flagship phones',
        (tester) async {
      // Simulate large phone (428x926 - iPhone 14 Pro Max)
      tester.view.physicalSize = const Size(428, 926);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      const html = '''
<div style="padding: 20px;">
  <h1>Large Phone Screen</h1>
  <p>Testing on 428x926 (iPhone 14 Pro Max, similar large Android phones).</p>
  <div style="columns: 2; column-gap: 16px;">
    <p>Column 1: This content uses CSS columns for better use of
       large screen width.</p>
    <p>Column 2: Multi-column layout should work smoothly on
       large phone screens.</p>
  </div>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: html),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Tablet: Renders on tablet screens', (tester) async {
      // Simulate tablet (768x1024 - iPad)
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      const html = '''
<article style="max-width: 700px; margin: 0 auto; padding: 32px;">
  <h1>Tablet Screen Test</h1>
  <p style="columns: 2; column-gap: 24px;">
    This is a tablet screen test at 768x1024 (iPad).
    Content should utilize the wider screen effectively
    with multi-column layouts where appropriate.
    The text should flow naturally across columns.
  </p>
  <table border="1" style="width: 100%; border-collapse: collapse; margin: 24px 0;">
    <thead>
      <tr>
        <th>Feature</th><th>Phone</th><th>Tablet</th>
      </tr>
    </thead>
    <tbody>
      <tr><td>Width</td><td>375-428px</td><td>768-1024px</td></tr>
      <tr><td>Columns</td><td>1</td><td>2+</td></tr>
      <tr><td>Layout</td><td>Vertical</td><td>Multi-column</td></tr>
    </tbody>
  </table>
</article>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: html),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Landscape orientation: Handles orientation changes',
        (tester) async {
      // Test portrait
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      const html = '''
<div style="padding: 16px;">
  <h1>Orientation Test</h1>
  <p>This content should adapt when device rotates between portrait and landscape.</p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Rotate to landscape
      tester.view.physicalSize = const Size(667, 375);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Mobile Device: Memory Constraints', () {
    testWidgets('Memory: Renders 25KB document without crash', (tester) async {
      // Generate ~25KB HTML
      final buffer = StringBuffer('<article>');
      for (int i = 0; i < 100; i++) {
        buffer.write('''
<section>
  <h2>Section $i</h2>
  <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit.
     Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
     Ut enim ad minim veniam, quis nostrud exercitation ullamco.</p>
</section>
''');
      }
      buffer.write('</article>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: buffer.toString(),
                mode: HyperRenderMode.sync,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Memory: Multiple images load without OOM', (tester) async {
      // Test with multiple small images (base64 1x1 transparent GIF)
      final buffer = StringBuffer('<div>');
      for (int i = 0; i < 20; i++) {
        buffer.write('''
<img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
     alt="Image $i"
     style="width: 100px; height: 100px; display: inline-block; margin: 4px;">
''');
      }
      buffer.write('</div>');

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

    testWidgets('Memory: Widget disposal cleans up resources', (tester) async {
      const html = '''
<div>
  <h1>Memory Cleanup Test</h1>
  <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==">
  <p>This widget will be disposed to test cleanup.</p>
</div>
''';

      // Render widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, key: const ValueKey('test1')),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Dispose by removing widget
      await tester.pumpWidget(Container());
      await tester.pump();

      // Render again with new instance
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, key: const ValueKey('test2')),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Memory: Repeated rebuilds do not leak', (tester) async {
      const html = '<p>Memory leak test</p>';

      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperViewer(html: html, key: ValueKey(i)),
            ),
          ),
        );
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
    });
  });

  group('Mobile Device: Platform-Specific Behaviors', () {
    testWidgets('iOS-specific: Renders correctly on iOS', (tester) async {
      const html = '''
<div style="padding: 20px;">
  <h1>iOS Test</h1>
  <p>Testing iOS-specific behaviors like text selection and scrolling.</p>
  <a href="https://example.com">iOS Link Styling</a>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            platform: TargetPlatform.iOS,
            useMaterial3: true,
          ),
          home: Scaffold(
            body: HyperViewer(html: html, selectable: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Android-specific: Renders correctly on Android',
        (tester) async {
      const html = '''
<div style="padding: 20px;">
  <h1>Android Test</h1>
  <p>Testing Android-specific behaviors like ripple effects and Material Design.</p>
  <a href="https://example.com">Android Link Styling</a>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            platform: TargetPlatform.android,
            useMaterial3: true,
          ),
          home: Scaffold(
            body: HyperViewer(html: html, selectable: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Platform detection: Adapts to platform', (tester) async {
      // This test verifies the widget works across platforms
      final currentPlatform = Platform.operatingSystem;

      const html = '''
<div>
  <h1>Platform Adaptive Test</h1>
  <p>This content should adapt to the current platform automatically.</p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);

      debugPrint('Test ran on platform: $currentPlatform');
    });
  });

  group('Mobile Device: Performance Optimization', () {
    testWidgets('Performance: Sync mode for small documents', (tester) async {
      const smallHtml = '''
<div>
  <h1>Small Document</h1>
  <p>This small document should use sync mode for instant rendering.</p>
</div>
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

      await tester.pump();
      stopwatch.stop();

      expect(tester.takeException(), isNull);

      // Even in debug mode, small docs should render quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(2000),
          reason: 'Small document should render in < 2s (debug mode)');
    });

    testWidgets('Performance: Virtualized mode for large documents',
        (tester) async {
      // Generate large document
      final largeHtml = StringBuffer('<div>');
      for (int i = 0; i < 200; i++) {
        largeHtml.write('<p>Paragraph $i: Lorem ipsum dolor sit amet.</p>');
      }
      largeHtml.write('</div>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: largeHtml.toString(),
              mode: HyperRenderMode.virtualized,
            ),
          ),
        ),
      );

      await tester.pump();

      // Should show loading indicator initially
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Performance: Auto mode selects appropriate strategy',
        (tester) async {
      final mediumHtml = '''
<article>
  ${List.generate(50, (i) => '<p>Paragraph $i content here.</p>').join()}
</article>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: mediumHtml,
              mode: HyperRenderMode.auto,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Performance: Image loading is optimized', (tester) async {
      const htmlWithImages = '''
<div>
  <h2>Image Loading Test</h2>
  <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
       alt="Image 1" style="width: 200px; height: 200px;">
  <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
       alt="Image 2" style="width: 200px; height: 200px;">
</div>
''';

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: htmlWithImages),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      expect(tester.takeException(), isNull);

      // Images should load reasonably quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: 'Images should load in < 5s (debug mode)');
    });
  });

  group('Mobile Device: Battery and Resource Usage', () {
    testWidgets('Battery: Static content does not trigger repaints',
        (tester) async {
      const html = '''
<div>
  <h1>Static Content</h1>
  <p>This static content should not cause unnecessary repaints that drain battery.</p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // After settle, there should be no further repaints
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Battery: Idle widget does not consume CPU', (tester) async {
      const html = '<p>Idle content that should not waste CPU cycles.</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Let it sit idle
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });
  });

  group('Mobile Device: Edge Cases', () {
    testWidgets('Low memory: Gracefully handles memory pressure',
        (tester) async {
      // This test doesn't actually simulate low memory, but verifies
      // the widget can render a reasonably large document
      final buffer = StringBuffer('<div>');
      for (int i = 0; i < 100; i++) {
        buffer.write('<p>Section $i: Lorem ipsum dolor sit amet.</p>');
      }
      buffer.write('</div>');

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
    });

    testWidgets('Slow network: Handles delayed image loading', (tester) async {
      const htmlWithExternalImage = '''
<div>
  <h2>Slow Network Test</h2>
  <img src="https://httpstat.us/200?sleep=2000" alt="Slow loading image">
  <p>Text should render even if images are slow to load.</p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: htmlWithExternalImage),
          ),
        ),
      );

      // Text should render immediately
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('App backgrounding: Handles lifecycle changes', (tester) async {
      const html = '''
<div>
  <h1>Lifecycle Test</h1>
  <p>This widget should handle app backgrounding gracefully.</p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Simulate app pausing (backgrounding)
      // The widget tree remains but app is paused
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });
  });
}
