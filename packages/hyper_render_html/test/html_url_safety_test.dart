import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_html/hyper_render_html.dart';

/// Defense-in-depth: HtmlAdapter must apply [UrlSafety.isSafe] to `href` /
/// `src` even when the upstream HtmlSanitizer is bypassed (callers that
/// invoke `HtmlAdapter().parse(...)` directly, or run HyperViewer with
/// `sanitize: false` over trusted content that turns out not to be trusted).
///
/// Mirrors `markdown_url_safety_test.dart` in the Markdown sub-package so
/// every parser enforces the same blocklist.
void main() {
  final adapter = HtmlAdapter();

  String? firstHref(DocumentNode doc) {
    String? found;
    void walk(UDTNode n) {
      if (found != null) return;
      if (n.tagName == 'a') {
        found = n.attributes['href'];
        return;
      }
      for (final c in n.children) {
        walk(c);
        if (found != null) return;
      }
    }

    walk(doc);
    return found;
  }

  String? firstImgSrc(DocumentNode doc) {
    String? found;
    void walk(UDTNode n) {
      if (found != null) return;
      if (n is AtomicNode && n.tagName == 'img') {
        found = n.src;
        return;
      }
      for (final c in n.children) {
        walk(c);
        if (found != null) return;
      }
    }

    walk(doc);
    return found;
  }

  group('HtmlAdapter — dangerous <a href> schemes', () {
    test('javascript: link collapses to #', () {
      final doc = adapter.parse('<a href="javascript:alert(1)">x</a>');
      expect(firstHref(doc), equals('#'));
    });

    test('file: link collapses to #', () {
      final doc = adapter.parse(
        '<a href="file:///data/data/com.app/secret.db">x</a>',
      );
      expect(firstHref(doc), equals('#'));
    });

    test('mhtml: link collapses to #', () {
      final doc = adapter.parse('<a href="mhtml://attacker.com/x">x</a>');
      expect(firstHref(doc), equals('#'));
    });

    test('about: link collapses to #', () {
      final doc = adapter.parse('<a href="about:blank">x</a>');
      expect(firstHref(doc), equals('#'));
    });

    test('control-char smuggling neutralised', () {
      // "jav\tascript:" used to slip past naive startsWith.
      final doc = adapter.parse('<a href="jav&#x09;ascript:alert(1)">x</a>');
      expect(firstHref(doc), equals('#'));
    });

    test('safe https link preserved', () {
      final doc = adapter.parse('<a href="https://example.com">x</a>');
      expect(firstHref(doc), equals('https://example.com'));
    });
  });

  group('HtmlAdapter — dangerous <img src> schemes', () {
    test('javascript: image src is blanked', () {
      final doc = adapter.parse('<img src="javascript:alert(1)">');
      expect(firstImgSrc(doc), equals(''));
    });

    test('file: image src is blanked', () {
      final doc = adapter.parse('<img src="file:///etc/passwd">');
      expect(firstImgSrc(doc), equals(''));
    });

    test('data:image/svg image src is blanked (SVG can carry script)', () {
      final doc = adapter.parse(
        '<img src="data:image/svg+xml,%3Csvg%3E%3C/svg%3E">',
      );
      expect(firstImgSrc(doc), equals(''));
    });

    test('safe https image src preserved', () {
      final doc = adapter.parse('<img src="https://example.com/cat.png">');
      expect(firstImgSrc(doc), equals('https://example.com/cat.png'));
    });

    test('data:image/png is allowed (legitimate inline image)', () {
      final doc = adapter.parse(
        '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==">',
      );
      expect(firstImgSrc(doc), startsWith('data:image/png'));
    });
  });
}
