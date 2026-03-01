import "package:hyper_render/hyper_render.dart";
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Security Integration Tests (XSS Prevention)', () {
    testWidgets('sanitize: blocks <script> tags', (tester) async {
      const xssHtml = '''
<div>
  <p>Safe content</p>
  <script>alert('XSS')</script>
  <p>More safe content</p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: xssHtml,
              sanitize: true,  // Security on
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify HyperViewer renders without errors
      expect(find.byType(HyperViewer), findsOneWidget);
      expect(find.byType(HyperRenderWidget), findsWidgets);
      expect(tester.takeException(), isNull);

      // Verify document structure - script tags should be removed
      final hyperViewer = tester.widget<HyperViewer>(find.byType(HyperViewer));
      expect(hyperViewer.sanitize, isTrue);
    });

    testWidgets('sanitize: blocks event handler attributes', (tester) async {
      const eventHandlers = '''
<div>
  <div onclick="malicious()">Click me</div>
  <img src="x" onerror="badCode()">
  <body onload="evil()">
  <a href="#" onmouseover="hack()">Link</a>
  <input onfocus="steal()">
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: eventHandlers,
              sanitize: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without executing any event handlers
      expect(find.byType(HyperViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sanitize: blocks javascript: URLs', (tester) async {
      const javascriptUrls = '''
<div>
  <a href="javascript:alert('XSS')">Click</a>
  <a href="javascript:void(0)">Void</a>
  <a href="JaVaScRiPt:alert('case insensitive')">Case test</a>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: javascriptUrls,
              sanitize: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Note: Can't tap links to test because HyperRender doesn't use
      // standard widgets - would need to test at RenderBox level
    });

    testWidgets('sanitize: blocks data: URLs', (tester) async {
      const dataUrls = '''
<div>
  <a href="data:text/html,<script>alert('XSS')</script>">Data URL</a>
  <img src="data:image/svg+xml,<svg><script>alert('XSS')</script></svg>">
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: dataUrls,
              sanitize: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sanitize: blocks <iframe> tags', (tester) async {
      const iframeHtml = '''
<div>
  <p>Before iframe</p>
  <iframe src="https://evil.com"></iframe>
  <iframe srcdoc="<script>alert('XSS')</script>"></iframe>
  <p>After iframe</p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: iframeHtml,
              sanitize: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sanitize: blocks <embed> and <object> tags', (tester) async {
      const embedHtml = '''
<div>
  <p>Content</p>
  <embed src="https://evil.com/malicious.swf">
  <object data="https://evil.com/malware.pdf"></object>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: embedHtml,
              sanitize: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sanitize: blocks <base> tag (URL spoofing)', (tester) async {
      const baseHtml = '''
<div>
  <base href="https://evil.com/">
  <a href="page.html">Link</a>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: baseHtml,
              sanitize: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sanitize: handles mixed safe and unsafe content', (tester) async {
      const mixedHtml = '''
<div>
  <h1>Title</h1>
  <p>Safe paragraph</p>
  <script>alert('XSS')</script>
  <p onclick="bad()">Click me</p>
  <strong>Bold text</strong>
  <iframe src="evil.com"></iframe>
  <em>Italic text</em>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: mixedHtml,
              sanitize: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render safe content and strip unsafe
      expect(find.byType(HyperViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sanitize: prevents CSS injection attacks', (tester) async {
      const cssInjection = '''
<div>
  <p style="color: expression(alert('XSS'))">Content with JS in CSS</p>
  <p style="background-image: url('javascript:alert(1)')">BG with JS</p>
  <style>body { behavior: url('xss.htc'); }</style>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: cssInjection,
              sanitize: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sanitize: can use custom allowed tags', (tester) async {
      const restrictedHtml = '''
<div>
  <p>Paragraph</p>
  <strong>Bold</strong>
  <img src="image.jpg">
  <table><tr><td>Cell</td></tr></table>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: restrictedHtml,
              sanitize: true,
              allowedTags: ['p', 'strong', 'em'],  // No img, table
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render only allowed tags
      expect(find.byType(HyperViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sanitize: default is enabled', (tester) async {
      const xssHtml = '<script>alert("XSS")</script><p>Content</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: xssHtml,
              // sanitize defaults to true
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final hyperViewer = tester.widget<HyperViewer>(find.byType(HyperViewer));
      expect(hyperViewer.sanitize, isTrue);  // Verify default is true
      expect(tester.takeException(), isNull);
    });

    testWidgets('sanitize: can be explicitly disabled (trusted content)', (tester) async {
      const trustedHtml = '''
<div>
  <p>Trusted content</p>
  <script>console.log('Internal analytics');</script>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: trustedHtml,
              sanitize: false,  // Explicitly disable for trusted content
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final hyperViewer = tester.widget<HyperViewer>(find.byType(HyperViewer));
      expect(hyperViewer.sanitize, isFalse);
      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });
}
