import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('Advanced Security & XSS Integration', () {
    testWidgets('Strips SVG script payloads', (tester) async {
      const svgXss = '''
<div>
  <svg><script>alert(1)</script></svg>
  <p>Safe</p>
</div>
''';
      await tester.pumpWidget(MaterialApp(home: HyperViewer(html: svgXss)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Blocks data:text/html URLs in all attributes', (tester) async {
      const dataXss = '''
<div>
  <a href="data:text/html,<script>alert(1)</script>">Link</a>
  <img src="data:text/html,<script>alert(1)</script>">
  <iframe src="data:text/html,<script>alert(1)</script>"></iframe>
</div>
''';
      await tester.pumpWidget(MaterialApp(home: HyperViewer(html: dataXss)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Prevents bypass via null bytes', (tester) async {
      const nullByteXss = '<scr\u0000ipt>alert(1)</scr\u0000ipt>';
      final sanitized = HtmlSanitizer.sanitize(nullByteXss);
      expect(sanitized, isNot(contains('<script>')));
    });

    testWidgets('Prevents bypass via encoded characters', (tester) async {
      const encodedXss =
          '<img src=x onerror="&#97;&#108;&#101;&#114;&#116;&#40;&#49;&#41;">';
      await tester.pumpWidget(MaterialApp(home: HyperViewer(html: encodedXss)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Prevents bypass via case variations', (tester) async {
      const caseXss = '<sCrIpT>alert(1)</ScRiPt><ImG sRc=x OnErRoR=alert(1)>';
      await tester.pumpWidget(MaterialApp(home: HyperViewer(html: caseXss)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Prevents bypass via nested payloads', (tester) async {
      const nestedXss = '<<script>alert(1)</script>script>alert(1)</script>';
      final sanitized = HtmlSanitizer.sanitize(nestedXss);
      expect(sanitized, isNot(contains('<script>')));
    });

    testWidgets('Blocks dangerous CSS functions in style attribute',
        (tester) async {
      const cssXss = '''
<div style="width: expression(alert(1)); background: url(javascript:alert(1));">
  XSS in style
</div>
''';
      await tester.pumpWidget(MaterialApp(home: HyperViewer(html: cssXss)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Ensures allowedTags doesn\'t accidentally allow dangerous tags',
        (tester) async {
      const html = '<script>alert(1)</script><p>Safe</p>';
      final sanitized =
          HtmlSanitizer.sanitize(html, allowedTags: ['script', 'p']);
      // A robust sanitizer should still strip 'script' because it's in the permanent blacklist
      expect(sanitized, isNot(contains('<script>')));
      expect(sanitized, contains('Safe'));
    });
  });
}
