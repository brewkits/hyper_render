// The root package's HtmlAdapter (lib/src/parser/html/html_adapter.dart — the
// one HyperViewer actually uses) previously lacked the URL-safety gate that
// the hyper_render_html, Markdown, and Delta adapters all apply. A caller
// using HtmlAdapter directly, or with sanitize:false, could let dangerous
// schemes reach image-loading and link-tap. This locks the gate in place.

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

AtomicNode? _img(String html) {
  final doc = HtmlAdapter().parse(html);
  AtomicNode? r;
  void walk(UDTNode n) {
    if (n is AtomicNode && n.tagName == 'img') r = n;
    for (final c in n.children) {
      walk(c);
    }
  }

  walk(doc);
  return r;
}

UDTNode? _anchor(String html) {
  final doc = HtmlAdapter().parse(html);
  UDTNode? r;
  void walk(UDTNode n) {
    if (n.tagName == 'a') r = n;
    for (final c in n.children) {
      walk(c);
    }
  }

  walk(doc);
  return r;
}

void main() {
  group('root HtmlAdapter URL-safety gate', () {
    test('blocks javascript: / vbscript: / file: hrefs (→ #)', () {
      expect(_anchor('<a href="javascript:alert(1)">x</a>')?.attributes['href'],
          '#');
      expect(_anchor('<a href="vbscript:msgbox(1)">x</a>')?.attributes['href'],
          '#');
      expect(_anchor('<a href="file:///etc/passwd">x</a>')?.attributes['href'],
          '#');
    });

    test('blocks dangerous img src (→ empty)', () {
      expect(_img('<img src="file:///etc/passwd">')?.src, '');
      expect(_img('<img src="javascript:alert(1)">')?.src, '');
    });

    test('allows https / http / mailto / tel', () {
      expect(_anchor('<a href="https://example.com">x</a>')?.attributes['href'],
          'https://example.com');
      expect(_anchor('<a href="mailto:a@b.com">x</a>')?.attributes['href'],
          'mailto:a@b.com');
      expect(_img('<img src="https://example.com/a.png">')?.src,
          'https://example.com/a.png');
    });

    test('allows relative paths and anchors', () {
      expect(_anchor('<a href="/path">x</a>')?.attributes['href'], '/path');
      expect(_anchor('<a href="#sec">x</a>')?.attributes['href'], '#sec');
    });
  });
}
