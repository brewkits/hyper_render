import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_markdown/hyper_render_markdown.dart';

/// Regression tests for the URL scheme blocklist in the standalone markdown
/// sub-package. Previously this adapter shipped its own `_isSafeUrl` and
/// drifted out of sync with the root `HtmlSanitizer.isSafeUrl` (missed
/// `file:`/`mhtml:`/`about:`); now both delegate to [UrlSafety.isSafe].
///
/// We assert behaviour by checking that dangerous-href links resolve to the
/// neutral placeholder `#` instead of the attacker URL.
void main() {
  final adapter = MarkdownAdapter();

  String? extractFirstHref(DocumentNode doc) {
    String? found;
    void walk(UDTNode n) {
      if (found != null) return;
      if (n.tagName == 'a') {
        final href = n.attributes['href'];
        if (href != null) {
          found = href;
          return;
        }
      }
      for (final c in n.children) {
        walk(c);
        if (found != null) return;
      }
    }

    walk(doc);
    return found;
  }

  String? extractFirstImgSrc(DocumentNode doc) {
    String? found;
    void walk(UDTNode n) {
      if (found != null) return;
      if (n.tagName == 'img') {
        found = n.attributes['src'];
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

  group('MarkdownAdapter — dangerous link schemes', () {
    test('javascript: link is replaced with #', () {
      final doc = adapter.parse('[click](javascript:alert(1))');
      expect(extractFirstHref(doc), equals('#'));
    });

    test('file: link is replaced with #', () {
      final doc = adapter.parse(
        '[steal](file:///data/data/com.app/databases/secret.db)',
      );
      expect(extractFirstHref(doc), equals('#'));
    });

    test('mhtml: link is replaced with #', () {
      final doc = adapter.parse('[arch](mhtml://attacker.com/archive)');
      expect(extractFirstHref(doc), equals('#'));
    });

    test('about: link is replaced with #', () {
      final doc = adapter.parse('[blank](about:blank)');
      expect(extractFirstHref(doc), equals('#'));
    });

    test('safe https link is preserved', () {
      final doc = adapter.parse('[ok](https://example.com)');
      expect(extractFirstHref(doc), equals('https://example.com'));
    });
  });

  group('MarkdownAdapter — dangerous image schemes', () {
    test('javascript: image src is blanked', () {
      final doc = adapter.parse('![x](javascript:alert(1))');
      expect(extractFirstImgSrc(doc), equals(''));
    });

    test('file: image src is blanked', () {
      final doc = adapter.parse('![x](file:///etc/passwd.png)');
      expect(extractFirstImgSrc(doc), equals(''));
    });

    test('data:image/svg image src is blanked (svg can carry script)', () {
      final doc = adapter.parse('![x](data:image/svg+xml,<svg></svg>)');
      expect(extractFirstImgSrc(doc), equals(''));
    });

    test('https image src is preserved', () {
      final doc = adapter.parse('![ok](https://example.com/cat.png)');
      expect(extractFirstImgSrc(doc), equals('https://example.com/cat.png'));
    });
  });
}
