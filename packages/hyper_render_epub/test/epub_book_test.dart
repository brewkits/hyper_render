import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_epub/hyper_render_epub.dart';

import 'epub_fixtures.dart';

void main() {
  group('EpubBook.open', () {
    test('parses metadata, spine order and body-only chapter html', () async {
      final book = await EpubBook.open(
        buildEpub({
          'mimetype': 'application/epub+zip',
          'META-INF/container.xml': containerXml,
          'OEBPS/content.opf': opfXml(),
          'OEBPS/styles/main.css': 'p { color: red; }',
          'OEBPS/text/chapter1.xhtml': chapterXhtml('<p>First</p>'),
          'OEBPS/text/chapter2.xhtml': chapterXhtml('<p>Second</p>'),
        }),
      );

      expect(book.title, 'Test Book');
      expect(book.author, 'A. Writer');
      expect(book.chapters.map((c) => c.id), ['ch1', 'ch2']);
      expect(book.chapters.first.html, contains('<p>First</p>'));
      // Body content only — no <html>/<head>/<title> wrapper.
      expect(book.chapters.first.html, isNot(contains('<head>')));
      expect(book.chapters.first.html, isNot(contains('<title>')));
    });

    test('collects linked stylesheets into css and drops the <link>', () async {
      final book = await EpubBook.open(
        buildEpub({
          'META-INF/container.xml': containerXml,
          'OEBPS/content.opf': opfXml(),
          'OEBPS/styles/main.css': 'p { color: red; }',
          'OEBPS/text/chapter1.xhtml': chapterXhtml('<p>First</p>'),
          'OEBPS/text/chapter2.xhtml': chapterXhtml('<p>Second</p>'),
        }),
      );

      expect(book.chapters.first.css, contains('p { color: red; }'));
      expect(book.chapters.first.html, isNot(contains('<link')));
    });

    test('collects <head> and <body> <style> blocks in document order',
        () async {
      final book = await EpubBook.open(
        buildEpub({
          'META-INF/container.xml': containerXml,
          'OEBPS/content.opf': opfXml(
            manifest:
                '<item id="ch1" href="text/chapter1.xhtml" media-type="application/xhtml+xml"/>',
            spine: '<itemref idref="ch1"/>',
          ),
          'OEBPS/styles/main.css': 'p { color: red; }',
          'OEBPS/text/chapter1.xhtml': '''
<html>
  <head>
    <style>p { color: blue; }</style>
    <link rel="stylesheet" href="../styles/main.css"/>
  </head>
  <body><p>First</p><style>em { color: green; }</style></body>
</html>''',
        }),
      );

      // A <head> <style> would be lost entirely with the rest of the head, and
      // order matters: a later rule has to keep winning over an earlier one.
      final css = book.chapters.single.css;
      expect(css, contains('p { color: blue; }'));
      expect(css, contains('p { color: red; }'));
      expect(css, contains('em { color: green; }'));
      expect(
        css.indexOf('color: blue'),
        lessThan(css.indexOf('color: red')),
      );
      expect(
        css.indexOf('color: red'),
        lessThan(css.indexOf('color: green')),
      );
      // …and the body-level <style> is moved, not duplicated.
      expect(book.chapters.single.html, isNot(contains('<style')));
    });

    test('inlines <img src> from the archive as a base64 data URI', () async {
      final book = await EpubBook.open(
        buildEpub({
          'META-INF/container.xml': containerXml,
          'OEBPS/content.opf': opfXml(),
          'OEBPS/styles/main.css': 'p { color: red; }',
          'OEBPS/images/pic.png': pngBytes,
          'OEBPS/text/chapter1.xhtml': chapterXhtml(
              '<img src="../images/pic.png" srcset="../images/pic.png 2x"/>'),
          'OEBPS/text/chapter2.xhtml': chapterXhtml('<p>Second</p>'),
        }),
      );

      final html = book.chapters.first.html;
      expect(
        html,
        contains('src="data:image/png;base64,${base64.encode(pngBytes)}"'),
      );
      // A srcset would still point at an unresolvable relative path.
      expect(html, isNot(contains('srcset')));
    });

    test('percent-decodes hrefs before looking them up in the zip', () async {
      final book = await EpubBook.open(
        buildEpub({
          'META-INF/container.xml': containerXml,
          'OEBPS/content.opf': opfXml(
            manifest: '''
    <item id="ch1" href="text/chapter%201.xhtml" media-type="application/xhtml+xml"/>
    <item id="img" href="images/my%20pic.png" media-type="image/png"/>''',
            spine: '<itemref idref="ch1"/>',
          ),
          'OEBPS/images/my pic.png': pngBytes,
          'OEBPS/text/chapter 1.xhtml':
              '<html><body><img src="../images/my%20pic.png"/></body></html>',
        }),
      );

      expect(book.chapters, hasLength(1));
      expect(book.chapters.first.html, contains('data:image/png;base64,'));
    });

    test('splices SVG images inline and leaves remote URLs untouched',
        () async {
      final book = await EpubBook.open(
        buildEpub({
          'META-INF/container.xml': containerXml,
          'OEBPS/content.opf': opfXml(
            manifest: '''
    <item id="ch1" href="text/chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="svg" href="images/logo.svg" media-type="image/svg+xml"/>''',
            spine: '<itemref idref="ch1"/>',
          ),
          'OEBPS/images/logo.svg': '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 50"><rect width="100" height="50"/></svg>''',
          'OEBPS/text/chapter1.xhtml': '<html><body>'
              '<img src="../images/logo.svg" width="40"/>'
              '<img src="https://example.com/remote.png"/>'
              '</body></html>',
        }),
      );

      final html = book.chapters.first.html;
      // A data:image/svg URI would be blocked by UrlSafety; an inline <svg>
      // element is kept by the sanitizer and rendered via flutter_svg.
      expect(html, contains('<svg'));
      expect(html, contains('<rect'));
      expect(html, isNot(contains('src="../images/logo.svg"')));
      // camelCase attributes must survive the parse/serialise round trip, or
      // every spliced SVG scales wrong.
      expect(html, contains('viewBox="0 0 100 50"'));
      // The <img>'s sizing carries over when the SVG doesn't set its own.
      expect(html, contains('width="40"'));
      // The XML declaration and DOCTYPE of the standalone file do not.
      expect(html, isNot(contains('<?xml')));
      expect(html, isNot(contains('DOCTYPE')));
      expect(html, contains('src="https://example.com/remote.png"'));
    });

    test('honours the container rootfile path, not a hardcoded default',
        () async {
      final book = await EpubBook.open(
        buildEpub({
          'META-INF/container.xml': '''
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="book/package.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''',
          'book/package.opf': opfXml(
            manifest:
                '<item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>',
            spine: '<itemref idref="ch1"/>',
          ),
          'book/ch1.xhtml': '<html><body><p>Nested OPF</p></body></html>',
        }),
      );

      expect(book.chapters.single.html, contains('Nested OPF'));
    });

    test('keeps linear="no" spine items', () async {
      final book = await EpubBook.open(
        buildEpub({
          'META-INF/container.xml': containerXml,
          'OEBPS/content.opf': opfXml(
            manifest: '''
    <item id="cover" href="cover.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>''',
            spine: '''
    <itemref idref="cover" linear="no"/>
    <itemref idref="ch1"/>''',
          ),
          'OEBPS/cover.xhtml': '<html><body><p>Cover</p></body></html>',
          'OEBPS/ch1.xhtml': '<html><body><p>One</p></body></html>',
        }),
      );

      expect(book.chapters.map((c) => c.id), ['cover', 'ch1']);
      // …but flags them, so a reader UX can keep them out of the main flow.
      expect(book.chapters.map((c) => c.linear), [false, true]);
    });

    test('skips a spine item whose file is missing instead of throwing',
        () async {
      final book = await EpubBook.open(
        buildEpub({
          'META-INF/container.xml': containerXml,
          'OEBPS/content.opf': opfXml(
            manifest: '''
    <item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ghost" href="ghost.xhtml" media-type="application/xhtml+xml"/>''',
            spine: '''
    <itemref idref="ch1"/>
    <itemref idref="ghost"/>''',
          ),
          'OEBPS/ch1.xhtml': '<html><body><p>One</p></body></html>',
        }),
      );

      expect(book.chapters.map((c) => c.id), ['ch1']);
    });

    test('leaves an <img> whose file is missing pointing at its original src',
        () async {
      final book = await EpubBook.open(
        buildEpub({
          'META-INF/container.xml': containerXml,
          'OEBPS/content.opf': opfXml(
            manifest:
                '<item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>',
            spine: '<itemref idref="ch1"/>',
          ),
          'OEBPS/ch1.xhtml':
              '<html><body><img src="images/gone.png"/></body></html>',
        }),
      );

      expect(book.chapters.single.html, contains('src="images/gone.png"'));
    });

    test('exposes the EPUB3 cover-image bytes', () async {
      final book = await EpubBook.open(
        buildEpub({
          'META-INF/container.xml': containerXml,
          'OEBPS/content.opf': opfXml(
            manifest: '''
    <item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="cover" href="cover.png" media-type="image/png" properties="cover-image"/>''',
            spine: '<itemref idref="ch1"/>',
          ),
          'OEBPS/cover.png': pngBytes,
          'OEBPS/ch1.xhtml': '<html><body><p>One</p></body></html>',
        }),
      );

      expect(book.coverImage, pngBytes);
    });

    test('reports an SVG cover with its media type, rather than dropping it',
        () async {
      final book = await EpubBook.open(
        buildEpub({
          'META-INF/container.xml': containerXml,
          'OEBPS/content.opf': opfXml(
            manifest: '''
    <item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="cover" href="cover.svg" media-type="image/svg+xml" properties="cover-image"/>''',
            spine: '<itemref idref="ch1"/>',
          ),
          'OEBPS/cover.svg': '<svg xmlns="http://www.w3.org/2000/svg"/>',
          'OEBPS/ch1.xhtml': '<html><body><p>One</p></body></html>',
        }),
      );

      // The app picks the renderer (SvgPicture.memory, not Image.memory);
      // silently discarding the book's cover is not ours to do.
      expect(book.coverImage, isNotNull);
      expect(book.coverMediaType, 'image/svg+xml');
    });

    test('falls back to the EPUB2 <meta name="cover"> pointer', () async {
      final book = await EpubBook.open(
        buildEpub({
          'META-INF/container.xml': containerXml,
          'OEBPS/content.opf': opfXml(
            metadata: '''
    <dc:title>Old Book</dc:title>
    <meta name="cover" content="coverimg"/>''',
            manifest: '''
    <item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="coverimg" href="cover.png" media-type="image/png"/>''',
            spine: '<itemref idref="ch1"/>',
          ),
          'OEBPS/cover.png': pngBytes,
          'OEBPS/ch1.xhtml': '<html><body><p>One</p></body></html>',
        }),
      );

      expect(book.title, 'Old Book');
      expect(book.coverImage, pngBytes);
    });

    test('throws EpubFormatException on bytes that are not a zip', () async {
      await expectLater(
        EpubBook.open(Uint8List.fromList(utf8.encode('not an epub'))),
        throwsA(isA<EpubFormatException>()),
      );
    });

    test('throws EpubFormatException when there is no OPF', () async {
      await expectLater(
        EpubBook.open(buildEpub({'readme.txt': 'hello'})),
        throwsA(isA<EpubFormatException>()),
      );
    });

    test('throws EpubFormatException when the OPF has no spine', () async {
      await expectLater(
        EpubBook.open(
          buildEpub({
            'META-INF/container.xml': containerXml,
            'OEBPS/content.opf': opfXml(manifest: '', spine: ''),
          }),
        ),
        throwsA(isA<EpubFormatException>()),
      );
    });
  });

  test('the src open() emits is decodable by epubImageLoader end to end',
      () async {
    final book = await EpubBook.open(
      buildEpub({
        'META-INF/container.xml': containerXml,
        'OEBPS/content.opf': opfXml(
          manifest: '''
    <item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="img" href="pic.png" media-type="image/png"/>''',
          spine: '<itemref idref="ch1"/>',
        ),
        'OEBPS/pic.png': pngBytes,
        'OEBPS/ch1.xhtml': '<html><body><img src="pic.png"/></body></html>',
      }),
    );

    final src = RegExp('src="([^"]+)"')
        .firstMatch(book.chapters.single.html)!
        .group(1)!;
    final loaded = Completer<ui.Image>();
    final failed = Completer<Object>();
    epubImageLoader(src, loaded.complete, failed.complete);

    final image = await loaded.future.timeout(const Duration(seconds: 5));
    expect(image.width, 1);
    expect(image.height, 1);
    expect(failed.isCompleted, isFalse);
  });

  group('table of contents', () {
    test('parses a nested EPUB3 nav document and titles chapters', () async {
      final book = await EpubBook.open(
        buildEpub({
          'META-INF/container.xml': containerXml,
          'OEBPS/content.opf': opfXml(
            manifest: '''
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="ch1" href="text/chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch2" href="text/chapter2.xhtml" media-type="application/xhtml+xml"/>''',
            spine: '''
    <itemref idref="ch1"/>
    <itemref idref="ch2"/>''',
          ),
          'OEBPS/nav.xhtml': '''
<html xmlns:epub="http://www.idpf.org/2007/ops"><body>
  <nav epub:type="landmarks"><ol><li><a href="text/chapter1.xhtml">Start</a></li></ol></nav>
  <nav epub:type="toc">
    <ol>
      <li><a href="text/chapter1.xhtml">Chapter One</a>
        <ol><li><a href="text/chapter1.xhtml#s2">Section Two</a></li></ol>
      </li>
      <li><a href="text/chapter2.xhtml">Chapter Two</a></li>
    </ol>
  </nav>
</body></html>''',
          'OEBPS/text/chapter1.xhtml': '<html><body><p>One</p></body></html>',
          'OEBPS/text/chapter2.xhtml': '<html><body><p>Two</p></body></html>',
        }),
      );

      final toc = book.tableOfContents;
      expect(toc.map((e) => e.title), ['Chapter One', 'Chapter Two']);
      expect(toc.first.level, 0);
      // Hrefs are OPF-relative, fragments preserved.
      expect(toc.first.href, 'text/chapter1.xhtml');
      expect(toc.first.children.single.href, 'text/chapter1.xhtml#s2');
      expect(toc.first.children.single.level, 1);
      // The `landmarks` nav must not be mistaken for the TOC.
      expect(toc.map((e) => e.title), isNot(contains('Start')));
      // Chapter titles come from the TOC; the nested entry does not override
      // the chapter-level title.
      expect(book.chapters.map((c) => c.title), ['Chapter One', 'Chapter Two']);
    });

    test('falls back to toc.ncx when there is no nav document', () async {
      final book = await EpubBook.open(
        buildEpub({
          'META-INF/container.xml': containerXml,
          'OEBPS/content.opf': opfXml(
            manifest: '''
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="ch1" href="text/chapter1.xhtml" media-type="application/xhtml+xml"/>''',
            spine: '<itemref idref="ch1"/>',
            spineAttrs: ' toc="ncx"',
          ),
          'OEBPS/toc.ncx': '''
<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="np1" playOrder="1">
      <navLabel><text>Chapter One</text></navLabel>
      <content src="text/chapter1.xhtml"/>
      <navPoint id="np1a" playOrder="2">
        <navLabel><text>Sub</text></navLabel>
        <content src="text/chapter1.xhtml#sub"/>
      </navPoint>
    </navPoint>
  </navMap>
</ncx>''',
          'OEBPS/text/chapter1.xhtml': '<html><body><p>One</p></body></html>',
        }),
      );

      expect(book.tableOfContents, hasLength(1));
      expect(book.tableOfContents.single.title, 'Chapter One');
      expect(book.tableOfContents.single.children.single.title, 'Sub');
      expect(book.tableOfContents.single.children.single.level, 1);
      expect(book.chapters.single.title, 'Chapter One');
    });

    test('an unparsable TOC yields an empty list, not a failed open', () async {
      final book = await EpubBook.open(
        buildEpub({
          'META-INF/container.xml': containerXml,
          'OEBPS/content.opf': opfXml(
            manifest: '''
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>''',
            spine: '<itemref idref="ch1"/>',
            spineAttrs: ' toc="ncx"',
          ),
          'OEBPS/toc.ncx': '<ncx><navMap><navPoint></ncx>',
          'OEBPS/ch1.xhtml': '<html><body><p>One</p></body></html>',
        }),
      );

      expect(book.tableOfContents, isEmpty);
      expect(book.chapters, hasLength(1));
      expect(book.chapters.single.title, isNull);
    });
  });
}
