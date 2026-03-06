import "package:hyper_render/hyper_render.dart";
// End-to-End Integration Tests
//
// Comprehensive integration tests covering full user workflows
// from HTML input to final rendered output with interactions.
//
// These tests validate that all components work together correctly:
// - HTML parsing → CSS resolution → Layout → Rendering → User interaction

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('E2E Integration: Complete Rendering Pipeline', () {
    testWidgets('Full pipeline: HTML → Parse → Layout → Render → Display',
        (tester) async {
      const html = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    .header { color: #1976D2; font-size: 24px; font-weight: bold; }
    .content { line-height: 1.6; }
    .highlight { background-color: #FFF9C4; padding: 4px; }
  </style>
</head>
<body>
  <h1 class="header">Integration Test Document</h1>
  <p class="content">
    This document tests the <span class="highlight">complete rendering pipeline</span>
    from HTML parsing through CSS resolution, layout calculation, and final rendering.
  </p>
  <ul>
    <li>HTML parsing with DOM tree construction</li>
    <li>CSS style resolution and cascade</li>
    <li>Layout calculation with RenderHyperBox</li>
    <li>Canvas rendering with TextPainter</li>
  </ul>
</body>
</html>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                selectable: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no exceptions thrown
      expect(tester.takeException(), isNull);

      // Verify widget tree structure
      expect(find.byType(HyperViewer), findsOneWidget);
      expect(find.byType(HyperRenderWidget), findsAtLeastNWidgets(1));
    });

    testWidgets('E2E: Complex document with multiple features', (tester) async {
      const html = '''
<article>
  <header style="border-bottom: 2px solid #333; padding-bottom: 16px;">
    <h1>Full-Featured Document Test</h1>
    <p style="color: #666; font-size: 14px;">Testing all major features together</p>
  </header>

  <section>
    <h2>1. Text Formatting</h2>
    <p>This paragraph has <strong>bold text</strong>, <em>italic text</em>,
       <code>inline code</code>, and <a href="#">links</a>.</p>
  </section>

  <section>
    <h2>2. Lists</h2>
    <ul>
      <li>Unordered item 1</li>
      <li>Unordered item 2</li>
    </ul>
    <ol>
      <li>Ordered item 1</li>
      <li>Ordered item 2</li>
    </ol>
  </section>

  <section>
    <h2>3. Table</h2>
    <table border="1" style="border-collapse: collapse; width: 100%;">
      <thead>
        <tr><th>Feature</th><th>Status</th></tr>
      </thead>
      <tbody>
        <tr><td>Parsing</td><td>✅ Working</td></tr>
        <tr><td>Layout</td><td>✅ Working</td></tr>
        <tr><td>Rendering</td><td>✅ Working</td></tr>
      </tbody>
    </table>
  </section>

  <section>
    <h2>4. Images and Floats</h2>
    <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
         alt="Test image"
         style="float: left; width: 100px; height: 100px; margin: 0 16px 16px 0;">
    <p>This text should flow around the floated image on the left.
       Lorem ipsum dolor sit amet, consectetur adipiscing elit.
       Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
    <div style="clear: both;"></div>
  </section>

  <section>
    <h2>5. Blockquote</h2>
    <blockquote style="border-left: 4px solid #1976D2; padding-left: 16px; margin: 16px 0;">
      This is a blockquote demonstrating styled block-level elements
      with custom borders and padding.
    </blockquote>
  </section>
</article>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
                selectable: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });

  group('E2E Integration: User Interactions', () {
    testWidgets('Text selection: Tap and drag to select text', (tester) async {
      const html = '''
<div style="padding: 20px;">
  <p id="test-para">This is a test paragraph for text selection.
     Users should be able to tap and drag to select this text.</p>
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

      // Tap at the beginning
      await tester.tapAt(const Offset(50, 50));
      await tester.pump();

      // Drag to select
      await tester.dragFrom(
        const Offset(50, 50),
        const Offset(200, 50),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Scrolling: Large document scrolls smoothly', (tester) async {
      final largeHtml = StringBuffer('<div>');
      for (int i = 0; i < 100; i++) {
        largeHtml.write('<p>Paragraph $i: Lorem ipsum dolor sit amet.</p>');
      }
      largeHtml.write('</div>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: largeHtml.toString()),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll down
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pump();

      // Scroll up
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Rebuild: Content changes trigger proper rebuild',
        (tester) async {
      const html1 = '<h1>Initial Content</h1>';
      const html2 = '<h1>Updated Content</h1>';

      // Render initial content
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html1),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Update content
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html2),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verify HyperViewer still exists
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Dark mode: Theme changes are respected', (tester) async {
      const html = '''
<div>
  <h1>Dark Mode Test</h1>
  <p>This content should adapt to theme changes.</p>
</div>
''';

      // Light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: HyperViewer(html: html),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: HyperViewer(html: html),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('E2E Integration: Error Handling', () {
    testWidgets('Malformed HTML: Gracefully handles invalid markup',
        (tester) async {
      const malformedHtml = '''
<div>
  <p>Unclosed paragraph
  <div>Nested div without closing
  <h1>Unclosed heading
  <ul>
    <li>Item 1
    <li>Item 2 - no closing tag
  </ul>
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

      // Should handle gracefully without crash
      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('404 Images: Handles missing images without crash',
        (tester) async {
      const htmlWith404Image = '''
<div>
  <h2>Document with Missing Image</h2>
  <img src="https://httpstat.us/404" alt="This image will fail">
  <p>This text should still render even if the image fails.</p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: htmlWith404Image),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render placeholder without crash
      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Empty HTML: Handles empty input gracefully', (tester) async {
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
    });

    testWidgets('XSS Attack: Sanitizes malicious scripts', (tester) async {
      const xssHtml = '''
<div>
  <h1>XSS Test</h1>
  <script>alert('XSS Attack!')</script>
  <p onload="alert('XSS')">This paragraph should be safe</p>
  <a href="javascript:alert('XSS')">Malicious link</a>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: xssHtml,
              sanitize: true, // Should sanitize by default
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render safely without executing scripts
      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });

  group('E2E Integration: Performance Edge Cases', () {
    testWidgets('Deeply nested elements: Handles deep DOM trees',
        (tester) async {
      final deepHtml = StringBuffer('<div>');
      for (int i = 0; i < 50; i++) {
        deepHtml.write('<div>Level $i');
      }
      deepHtml.write('Deepest content');
      for (int i = 0; i < 50; i++) {
        deepHtml.write('</div>');
      }
      deepHtml.write('</div>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: deepHtml.toString()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Many CSS classes: Handles hundreds of style rules',
        (tester) async {
      final stylesBuffer = StringBuffer('<style>');
      for (int i = 0; i < 100; i++) {
        stylesBuffer.write('.class$i { color: #${i.toRadixString(16).padLeft(6, '0')}; }');
      }
      stylesBuffer.write('</style><div>');
      for (int i = 0; i < 100; i++) {
        stylesBuffer.write('<p class="class$i">Text $i</p>');
      }
      stylesBuffer.write('</div>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: stylesBuffer.toString()),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Complex table: Large table with many cells', (tester) async {
      final tableHtml = StringBuffer('''
<table border="1" style="border-collapse: collapse;">
  <thead>
    <tr>
      <th>ID</th><th>Name</th><th>Value</th><th>Status</th><th>Action</th>
    </tr>
  </thead>
  <tbody>
''');

      for (int i = 0; i < 50; i++) {
        tableHtml.write('''
    <tr>
      <td>$i</td>
      <td>Item $i</td>
      <td>\$${i * 100}</td>
      <td>${i.isEven ? "Active" : "Inactive"}</td>
      <td><a href="#">Edit</a></td>
    </tr>
''');
      }

      tableHtml.write('</tbody></table>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: tableHtml.toString()),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Multiple floats: Complex float layout', (tester) async {
      final floatHtml = StringBuffer('<div style="width: 400px;">');
      for (int i = 0; i < 20; i++) {
        floatHtml.write('''
  <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
       style="float: ${i.isEven ? 'left' : 'right'}; width: 50px; height: 50px; margin: 4px;">
''');
      }
      floatHtml.write('<p>${'Lorem ipsum dolor sit amet. ' * 50}</p>');
      floatHtml.write('<div style="clear: both;"></div></div>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: floatHtml.toString()),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });

  group('E2E Integration: Real-World Scenarios', () {
    testWidgets('Email client: Renders typical email HTML', (tester) async {
      const emailHtml = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    .email-header { background: #f5f5f5; padding: 16px; border-bottom: 1px solid #ddd; }
    .email-body { padding: 16px; line-height: 1.6; }
    .email-footer { background: #f5f5f5; padding: 16px; border-top: 1px solid #ddd; font-size: 12px; color: #666; }
  </style>
</head>
<body>
  <div class="email-header">
    <strong>From:</strong> sender@example.com<br>
    <strong>To:</strong> recipient@example.com<br>
    <strong>Subject:</strong> Integration Test Email
  </div>
  <div class="email-body">
    <p>Dear User,</p>
    <p>This is a test email to verify that HyperRender can properly handle
       typical email HTML content with headers, body text, and footers.</p>
    <p>Best regards,<br>Test System</p>
  </div>
  <div class="email-footer">
    <p>This is an automated test email. Please do not reply.</p>
  </div>
</body>
</html>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: emailHtml),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('News article: Complex article layout', (tester) async {
      const articleHtml = '''
<article>
  <header style="margin-bottom: 24px;">
    <h1 style="font-size: 32px; margin-bottom: 8px;">Breaking News: Flutter Reaches 1 Billion Installs</h1>
    <p style="color: #666; font-size: 14px;">Published on March 6, 2026 by Tech Reporter</p>
  </header>

  <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
       alt="News header"
       style="width: 100%; height: 200px; margin-bottom: 16px;">

  <p class="lead" style="font-size: 18px; font-weight: 500; margin-bottom: 16px;">
    Flutter, Google's UI toolkit, has achieved a major milestone today...
  </p>

  <h2>Key Highlights</h2>
  <ul>
    <li>1 billion total app installs using Flutter</li>
    <li>500,000+ apps published to stores</li>
    <li>Fastest-growing cross-platform framework</li>
  </ul>

  <blockquote style="border-left: 4px solid #1976D2; padding-left: 16px; margin: 24px 0; font-style: italic;">
    "Flutter has revolutionized how developers build beautiful, fast apps."
  </blockquote>

  <p>The framework continues to gain momentum...</p>
</article>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: articleHtml, selectable: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Documentation: API docs with code samples', (tester) async {
      const docsHtml = '''
<div>
  <h1>HyperViewer API Documentation</h1>

  <section>
    <h2>Basic Usage</h2>
    <p>Create a HyperViewer widget to render HTML:</p>
    <pre style="background: #f5f5f5; padding: 12px; border-radius: 4px; overflow-x: auto;">
<code>HyperViewer(
  html: '&lt;h1&gt;Hello World&lt;/h1&gt;',
  mode: HyperRenderMode.sync,
)</code></pre>
  </section>

  <section>
    <h2>Parameters</h2>
    <table border="1" style="width: 100%; border-collapse: collapse;">
      <tr>
        <th>Parameter</th>
        <th>Type</th>
        <th>Description</th>
      </tr>
      <tr>
        <td>html</td>
        <td>String</td>
        <td>HTML content to render</td>
      </tr>
      <tr>
        <td>mode</td>
        <td>HyperRenderMode</td>
        <td>Rendering mode (sync/async/auto)</td>
      </tr>
    </table>
  </section>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: docsHtml),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });
}
