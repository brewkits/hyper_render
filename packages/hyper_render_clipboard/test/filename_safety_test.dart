import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_clipboard/src/super_clipboard_handler.dart';

/// Path-traversal regression test for the image save / share flow.
///
/// `Uri.pathSegments.last` URL-decodes `%2F`/`%5C` into literal slashes,
/// which would let `File('${dir.path}/$name')` write outside `dir`. The
/// filename helper must neutralise both separators.
void main() {
  final handler = SuperClipboardHandler();

  group('SuperClipboardHandler._getFilenameFromUrl — path traversal', () {
    test('URL-encoded forward-slash is sanitised', () {
      final name = handler.getFilenameFromUrlForTest(
        'https://evil.com/foo/..%2f..%2fetc%2fpasswd.png',
      );
      expect(name.contains('/'), isFalse,
          reason: 'literal slash must not survive: "$name"');
      expect(name.contains('..'), isTrue,
          reason: 'rest of segment is preserved, only separators replaced');
    });

    test('URL-encoded back-slash is sanitised', () {
      final name = handler.getFilenameFromUrlForTest(
        r'https://evil.com/img%5C..%5Cdata%5Cprefs.png',
      );
      expect(name.contains(r'\'), isFalse,
          reason: 'literal backslash must not survive: "$name"');
    });

    test('plain filename passes through unchanged', () {
      final name = handler.getFilenameFromUrlForTest(
        'https://example.com/images/cat.png',
      );
      expect(name, equals('cat.png'));
    });

    test('extensionless segments fall back to default name', () {
      final name = handler.getFilenameFromUrlForTest('https://example.com/abc');
      expect(name.startsWith('image_'), isTrue);
      expect(name.endsWith('.png'), isTrue);
    });
  });

  group('SuperClipboardHandler._sanitiseFilename — caller-supplied names', () {
    // saveImageBytes / shareImageBytes accept a `filename` argument from the
    // caller. Before W1 that string was concatenated raw into the file path;
    // a malicious app dev passing user-supplied input would have opened the
    // same traversal hole that _getFilenameFromUrl was already plugging.
    test('literal forward-slash is replaced', () {
      // `.` is intentionally preserved (extensions); only separators replaced.
      expect(handler.sanitiseFilenameForTest('../../etc/passwd.png'),
          equals('.._.._etc_passwd.png'));
    });

    test('literal backslash is replaced', () {
      expect(handler.sanitiseFilenameForTest(r'..\..\windows\system.dll'),
          equals('.._.._windows_system.dll'));
    });

    test('safe filename passes through unchanged', () {
      expect(handler.sanitiseFilenameForTest('photo_2026_05_18.jpg'),
          equals('photo_2026_05_18.jpg'));
    });

    test('mixed separators are all replaced', () {
      final s = handler.sanitiseFilenameForTest(r'a/b\c/d.png');
      expect(s.contains('/'), isFalse);
      expect(s.contains(r'\'), isFalse);
    });
  });
}
