import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_epub/src/epub_path.dart';

void main() {
  group('epubDirOf', () {
    test('returns the directory with a trailing slash', () {
      expect(epubDirOf('OEBPS/text/ch1.xhtml'), 'OEBPS/text/');
    });

    test('returns an empty string at the archive root', () {
      expect(epubDirOf('content.opf'), '');
    });
  });

  group('epubNormalize', () {
    test('collapses . and .. segments', () {
      expect(epubNormalize('OEBPS/text/../images/pic.png'),
          'OEBPS/images/pic.png');
      expect(epubNormalize('./OEBPS//ch1.xhtml'), 'OEBPS/ch1.xhtml');
    });

    test('drops a leading slash', () {
      expect(epubNormalize('/OEBPS/ch1.xhtml'), 'OEBPS/ch1.xhtml');
    });

    test('does not walk above the archive root', () {
      expect(epubNormalize('../../etc/passwd'), 'etc/passwd');
    });
  });

  group('epubResolve', () {
    test('resolves against the containing directory', () {
      expect(
        epubResolve('OEBPS/text/', '../images/pic.png'),
        'OEBPS/images/pic.png',
      );
    });

    test('treats a leading slash as archive-root, not base-relative', () {
      expect(epubResolve('OEBPS/text/', '/OEBPS/ch1.xhtml'), 'OEBPS/ch1.xhtml');
    });

    test('strips the fragment', () {
      expect(epubResolve('OEBPS/', 'ch1.xhtml#part2'), 'OEBPS/ch1.xhtml');
    });

    test('percent-decodes, because zip entry names are literal', () {
      expect(epubResolve('OEBPS/', 'my%20pic.png'), 'OEBPS/my pic.png');
    });

    test('tolerates a malformed percent escape', () {
      expect(epubResolve('OEBPS/', '100%.png'), 'OEBPS/100%.png');
    });

    test('returns null for absolute URLs and same-document links', () {
      expect(epubResolve('OEBPS/', 'https://example.com/a.png'), isNull);
      expect(epubResolve('OEBPS/', 'data:image/png;base64,AAAA'), isNull);
      expect(epubResolve('OEBPS/', '#top'), isNull);
      expect(epubResolve('OEBPS/', '   '), isNull);
    });
  });

  group('epubFragment', () {
    test('keeps the # and returns empty when absent', () {
      expect(epubFragment('ch1.xhtml#s2'), '#s2');
      expect(epubFragment('ch1.xhtml'), '');
    });
  });
}
