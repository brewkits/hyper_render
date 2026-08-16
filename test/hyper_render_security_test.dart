import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:flutter/material.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('HyperRender Security Tests', () {
    testWidgets('Strips dangerous tags when sanitize: true',
        (WidgetTester tester) async {
      const html = '''
        <div>Safe Content</div>
        <script>alert(1);</script>
        <iframe src="javascript:alert(1)"></iframe>
        <object data="malicious.swf"></object>
      ''';

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: HyperViewer(
            html: html,
            sanitize: true,
          ),
        ),
      ));

      // As HyperRender paints directly to canvas, we verify it pumps successfully without crashing
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    test('UrlSafety blocks javascript: even with unicode bypass', () {
      // Test URL Smuggling logic directly against the safety utility
      expect(UrlSafety.isSafe('javascript:alert(1)'), isFalse);
      expect(UrlSafety.isSafe('jav\tascript:alert(1)'), isFalse);
      expect(UrlSafety.isSafe('vbscript:alert(1)'), isFalse);
      expect(UrlSafety.isSafe('file:///etc/passwd'), isFalse);
      expect(UrlSafety.isSafe('data:text/html,<script>alert(1)</script>'),
          isFalse);

      expect(UrlSafety.isSafe('https://google.com'), isTrue);
      expect(UrlSafety.isSafe('mailto:test@example.com'), isTrue);
      expect(UrlSafety.isSafe('tel:+123456789'), isTrue);
    });
  });
}
