/// Tests for URL protocol blocking in html_adapter._resolveUrl()
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('URL Protocol Security', () {
    HyperViewer viewer(String html) => HyperViewer(html: html);

    test('javascript: URL in href is dropped', () {
      // The adapter should strip javascript: hrefs and not crash
      final html = '<a href="javascript:alert(1)">click</a>';
      expect(() => viewer(html), returnsNormally);
    });

    test('javascript: with mixed case is dropped', () {
      final html = '<a href="JaVaScRiPt:alert(1)">click</a>';
      expect(() => viewer(html), returnsNormally);
    });

    test('javascript: with leading whitespace is dropped', () {
      final html = '<a href="  javascript:alert(1)">click</a>';
      expect(() => viewer(html), returnsNormally);
    });

    test('vbscript: URL in href is dropped', () {
      final html = '<a href="vbscript:MsgBox(1)">click</a>';
      expect(() => viewer(html), returnsNormally);
    });

    test('data:text URL in img src is dropped', () {
      final html = '<img src="data:text/html,<script>alert(1)</script>">';
      expect(() => viewer(html), returnsNormally);
    });

    test('data:application URL in img src is dropped', () {
      final html = '<img src="data:application/javascript,alert(1)">';
      expect(() => viewer(html), returnsNormally);
    });

    test('data:image URL in img src is allowed (safe)', () {
      // data:image/... is safe for images
      final html = '<img src="data:image/png;base64,abc123">';
      expect(() => viewer(html), returnsNormally);
    });

    test('https: URL passes through normally', () {
      final html = '<a href="https://example.com">link</a>';
      expect(() => viewer(html), returnsNormally);
    });

    test('relative URL passes through normally', () {
      final html = '<a href="/path/to/page">link</a>';
      expect(() => viewer(html), returnsNormally);
    });

    test('empty href is handled gracefully', () {
      final html = '<a href="">link</a>';
      expect(() => viewer(html), returnsNormally);
    });
  });
}
