import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('UrlSafety.isSafe — scheme blocklist', () {
    test('allows ordinary web schemes', () {
      expect(UrlSafety.isSafe('https://example.com'), isTrue);
      expect(UrlSafety.isSafe('http://example.com/path?q=1'), isTrue);
      expect(UrlSafety.isSafe('mailto:user@example.com'), isTrue);
      expect(UrlSafety.isSafe('tel:+84123456789'), isTrue);
      expect(UrlSafety.isSafe('/relative/path'), isTrue);
      expect(UrlSafety.isSafe('#anchor'), isTrue);
      expect(UrlSafety.isSafe(''), isTrue);
    });

    test('blocks javascript: and vbscript:', () {
      expect(UrlSafety.isSafe('javascript:alert(1)'), isFalse);
      expect(UrlSafety.isSafe('vbscript:msgbox(1)'), isFalse);
    });

    test('case-insensitive scheme match', () {
      expect(UrlSafety.isSafe('JavaScript:alert(1)'), isFalse);
      expect(UrlSafety.isSafe('JAVASCRIPT:alert(1)'), isFalse);
      expect(UrlSafety.isSafe('FiLe:///etc/passwd'), isFalse);
    });

    test('control-char smuggling neutralised', () {
      // "jav\tascript:" historically slipped past naive startsWith.
      expect(UrlSafety.isSafe('jav\tascript:alert(1)'), isFalse);
      expect(UrlSafety.isSafe('jav\nascript:alert(1)'), isFalse);
      expect(UrlSafety.isSafe('  javascript:alert(1)'), isFalse);
    });

    test('blocks data: except for images', () {
      expect(UrlSafety.isSafe('data:image/png;base64,iVBOR...'), isTrue);
      expect(UrlSafety.isSafe('data:image/jpeg;base64,/9j/...'), isTrue);
      expect(UrlSafety.isSafe('data:text/html,<script>alert(1)</script>'),
          isFalse);
      // SVG data URLs can carry <script> inside the SVG.
      expect(UrlSafety.isSafe('data:image/svg+xml,<svg>...</svg>'), isFalse);
    });

    test('blocks mobile-dangerous schemes', () {
      expect(UrlSafety.isSafe('file:///etc/passwd'), isFalse);
      expect(UrlSafety.isSafe('file:///data/data/app/db.sqlite'), isFalse);
      expect(UrlSafety.isSafe('mhtml://attacker.com/archive'), isFalse);
      expect(UrlSafety.isSafe('about:blank'), isFalse);
    });
  });
}
