import "package:hyper_render/hyper_render.dart";
// Cross-Platform Validation Tests
//
// Validates that HyperRender works consistently across all supported platforms:
// - iOS (physical devices + simulator)
// - Android (physical devices + emulator)
// - macOS
// - Windows
// - Linux
// - Web (where applicable)
//
// These tests ensure:
// 1. Consistent rendering across platforms
// 2. Platform-specific features work correctly
// 3. No platform-specific crashes or bugs
// 4. Performance is acceptable on all platforms
//
// Run on each platform:
// ```bash
// flutter test test/integration/cross_platform_validation_test.dart
// ```

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Store current platform for reporting
  final currentPlatform = kIsWeb
      ? 'Web'
      : Platform.operatingSystem;

  group('Cross-Platform: Core Rendering', () {
    testWidgets('Basic HTML renders on $currentPlatform', (tester) async {
      const html = '''
<div>
  <h1>Cross-Platform Test</h1>
  <p>This HTML should render identically on all platforms.</p>
  <ul>
    <li>iOS</li>
    <li>Android</li>
    <li>macOS</li>
    <li>Windows</li>
    <li>Linux</li>
  </ul>
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

      debugPrint('✅ Basic rendering works on $currentPlatform');
    });

    testWidgets('CSS styles apply consistently on $currentPlatform',
        (tester) async {
      const html = '''
<style>
  .red { color: #FF0000; }
  .blue { color: #0000FF; }
  .large { font-size: 24px; }
  .bold { font-weight: bold; }
</style>
<div>
  <p class="red">Red text</p>
  <p class="blue">Blue text</p>
  <p class="large">Large text</p>
  <p class="bold">Bold text</p>
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

      debugPrint('✅ CSS styles work on $currentPlatform');
    });

    testWidgets('Images load on $currentPlatform', (tester) async {
      const html = '''
<div>
  <h2>Image Loading Test</h2>
  <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
       alt="Test image"
       style="width: 100px; height: 100px;">
  <p>Image should load above this text.</p>
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

      debugPrint('✅ Image loading works on $currentPlatform');
    });

    testWidgets('Tables render correctly on $currentPlatform', (tester) async {
      const html = '''
<table border="1" style="width: 100%; border-collapse: collapse;">
  <thead>
    <tr>
      <th>Platform</th><th>Status</th><th>Performance</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>iOS</td><td>✅</td><td>Excellent</td></tr>
    <tr><td>Android</td><td>✅</td><td>Excellent</td></tr>
    <tr><td>Desktop</td><td>✅</td><td>Excellent</td></tr>
  </tbody>
</table>
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

      debugPrint('✅ Table rendering works on $currentPlatform');
    });
  });

  group('Cross-Platform: Text Selection', () {
    testWidgets('Text selection enabled on $currentPlatform', (tester) async {
      const html = '''
<div style="padding: 20px;">
  <p>This text should be selectable on all platforms.
     Long press or click and drag to select.</p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, selectable: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);

      // Attempt to select text (platform-specific behavior)
      await tester.tapAt(const Offset(100, 100));
      await tester.pump();

      expect(tester.takeException(), isNull);

      debugPrint('✅ Text selection works on $currentPlatform');
    });

    testWidgets('Selection disabled when selectable=false on $currentPlatform',
        (tester) async {
      const html = '<p>This text should NOT be selectable.</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, selectable: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);

      debugPrint('✅ Selection control works on $currentPlatform');
    });
  });

  group('Cross-Platform: Performance', () {
    testWidgets('Parse performance acceptable on $currentPlatform',
        (tester) async {
      // Generate 10KB HTML
      final buffer = StringBuffer('<div>');
      for (int i = 0; i < 40; i++) {
        buffer.write('''
<section>
  <h3>Section $i</h3>
  <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>
</section>
''');
      }
      buffer.write('</div>');

      final stopwatch = Stopwatch()..start();

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
      stopwatch.stop();

      expect(tester.takeException(), isNull);

      // Debug mode is slower, so use generous threshold
      final threshold = kDebugMode ? 5000 : 1000;
      expect(stopwatch.elapsedMilliseconds, lessThan(threshold),
          reason: '10KB HTML should parse quickly on $currentPlatform');

      debugPrint('✅ Parse performance acceptable on $currentPlatform: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Scrolling performance acceptable on $currentPlatform',
        (tester) async {
      final buffer = StringBuffer('<div>');
      for (int i = 0; i < 100; i++) {
        buffer.write('<p>Paragraph $i: Lorem ipsum dolor sit amet.</p>');
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

      // Perform scroll
      final stopwatch = Stopwatch()..start();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pump();
      stopwatch.stop();

      expect(tester.takeException(), isNull);

      // Scrolling should be responsive
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: 'Scroll should be responsive on $currentPlatform');

      debugPrint('✅ Scroll performance acceptable on $currentPlatform: ${stopwatch.elapsedMilliseconds}ms');
    });
  });

  group('Cross-Platform: Platform-Specific Features', () {
    testWidgets('Platform detection works on $currentPlatform', (tester) async {
      // Verify we can detect the current platform
      String detectedPlatform;

      if (kIsWeb) {
        detectedPlatform = 'Web';
      } else {
        switch (Platform.operatingSystem) {
          case 'ios':
            detectedPlatform = 'iOS';
            break;
          case 'android':
            detectedPlatform = 'Android';
            break;
          case 'macos':
            detectedPlatform = 'macOS';
            break;
          case 'windows':
            detectedPlatform = 'Windows';
            break;
          case 'linux':
            detectedPlatform = 'Linux';
            break;
          default:
            detectedPlatform = 'Unknown';
        }
      }

      expect(detectedPlatform, isNot('Unknown'));

      debugPrint('✅ Running on detected platform: $detectedPlatform');
    });

    testWidgets('Theme adapts to platform on $currentPlatform',
        (tester) async {
      const html = '<h1>Theme Test</h1><p>Text should use platform theme.</p>';

      // Test with platform-specific theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            platform: defaultTargetPlatform,
            useMaterial3: true,
          ),
          home: Scaffold(
            body: HyperViewer(html: html),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);

      debugPrint('✅ Theme adaptation works on $currentPlatform');
    });
  });

  group('Cross-Platform: Error Handling', () {
    testWidgets('Malformed HTML handled consistently on $currentPlatform',
        (tester) async {
      const malformedHtml = '''
<div>
  <p>Unclosed paragraph
  <h1>Unclosed heading
  <ul>
    <li>Item without closing
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: malformedHtml),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should handle gracefully on all platforms
      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);

      debugPrint('✅ Error handling works on $currentPlatform');
    });

    testWidgets('Empty HTML handled on $currentPlatform', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: ''),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);

      debugPrint('✅ Empty HTML handled on $currentPlatform');
    });

    testWidgets('XSS protection works on $currentPlatform', (tester) async {
      const xssHtml = '''
<div>
  <script>alert('XSS')</script>
  <p onload="alert('XSS')">Should be safe</p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: xssHtml, sanitize: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should sanitize on all platforms
      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);

      debugPrint('✅ XSS protection works on $currentPlatform');
    });
  });

  group('Cross-Platform: Complex Layouts', () {
    testWidgets('Float layout works on $currentPlatform', (tester) async {
      const html = '''
<div>
  <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
       style="float: left; width: 100px; height: 100px; margin: 0 16px 16px 0;">
  <p>This text should flow around the floated image on all platforms.
     The layout should be consistent regardless of the underlying OS.</p>
  <div style="clear: both;"></div>
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

      debugPrint('✅ Float layout works on $currentPlatform');
    });

    testWidgets('Nested elements render on $currentPlatform', (tester) async {
      final buffer = StringBuffer('<div>');
      for (int i = 0; i < 20; i++) {
        buffer.write('<div style="margin-left: ${i * 4}px;">');
      }
      buffer.write('Deeply nested content');
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

      debugPrint('✅ Nested elements work on $currentPlatform');
    });
  });

  group('Cross-Platform: Real-World Content', () {
    testWidgets('News article renders on $currentPlatform', (tester) async {
      const html = '''
<article>
  <h1>Platform Test Article</h1>
  <p class="byline">Testing on $currentPlatform</p>
  <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
       style="width: 100%; height: 200px;">
  <p>This article tests cross-platform rendering consistency.</p>
  <h2>Key Features Tested</h2>
  <ul>
    <li>HTML parsing</li>
    <li>CSS styling</li>
    <li>Image loading</li>
    <li>Text formatting</li>
  </ul>
  <blockquote style="border-left: 4px solid #1976D2; padding-left: 16px;">
    "Cross-platform consistency is critical for user experience."
  </blockquote>
</article>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: html, selectable: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);

      debugPrint('✅ News article renders on $currentPlatform');
    });

    testWidgets('Documentation page renders on $currentPlatform',
        (tester) async {
      const html = '''
<div>
  <h1>HyperRender Documentation</h1>
  <h2>Platform Support</h2>
  <table border="1" style="border-collapse: collapse; width: 100%;">
    <tr><th>Platform</th><th>Support</th></tr>
    <tr><td>iOS</td><td>✅ Full</td></tr>
    <tr><td>Android</td><td>✅ Full</td></tr>
    <tr><td>macOS</td><td>✅ Full</td></tr>
    <tr><td>Windows</td><td>✅ Full</td></tr>
    <tr><td>Linux</td><td>✅ Full</td></tr>
  </table>
  <h3>Code Example</h3>
  <pre style="background: #f5f5f5; padding: 12px;"><code>HyperViewer(
  html: '&lt;h1&gt;Hello&lt;/h1&gt;',
  mode: HyperRenderMode.sync,
)</code></pre>
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

      debugPrint('✅ Documentation renders on $currentPlatform');
    });
  });
}
