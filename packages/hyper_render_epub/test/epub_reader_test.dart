import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:hyper_render_epub/hyper_render_epub.dart';

import 'epub_fixtures.dart';

/// A two-chapter book whose first chapter links to the second.
Uint8List _twoChapterEpub() => buildEpub({
      'META-INF/container.xml': containerXml,
      'OEBPS/content.opf': opfXml(
        manifest: '''
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="ch1" href="text/chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch2" href="text/chapter2.xhtml" media-type="application/xhtml+xml"/>''',
      ),
      'OEBPS/nav.xhtml': '''
<html xmlns:epub="http://www.idpf.org/2007/ops"><body>
  <nav epub:type="toc"><ol>
    <li><a href="text/chapter1.xhtml">Chapter One</a></li>
    <li><a href="text/chapter2.xhtml#top">Chapter Two</a></li>
  </ol></nav>
</body></html>''',
      'OEBPS/styles/main.css': 'p { color: red; }',
      'OEBPS/text/chapter1.xhtml': chapterXhtml(
        '<p>First</p><a href="chapter2.xhtml">Onward</a>'
        '<a href="https://example.com/away">Away</a>',
      ),
      'OEBPS/text/chapter2.xhtml': chapterXhtml('<p>Second</p>'),
    });

/// The `HyperViewer` `EpubReader` currently has mounted.
HyperViewer _viewer(WidgetTester tester) =>
    tester.widget<HyperViewer>(find.byType(HyperViewer));

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  // LazyImageQueue dedupes in-flight loads by URL process-wide, and every
  // chapter here inlines the *same* fixture PNG — so an unresolved load left
  // by one test would silently swallow the next test's registration.
  setUp(() => LazyImageQueue.instance.resetForTesting());
  tearDown(() => LazyImageQueue.instance.resetForTesting());

  group('EpubReaderController', () {
    test('clamps an out-of-range initial chapter', () async {
      final book = await EpubBook.open(_twoChapterEpub());

      expect(
          EpubReaderController(book: book, initialChapter: 99).chapterIndex, 1);
      expect(
          EpubReaderController(book: book, initialChapter: -5).chapterIndex, 0);
    });

    test('next/previous stop at the ends and notify only on a real move',
        () async {
      final book = await EpubBook.open(_twoChapterEpub());
      final controller = EpubReaderController(book: book);
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.previous(); // already at 0
      expect(controller.chapterIndex, 0);
      expect(controller.hasPrevious, isFalse);
      expect(notifications, 0);

      controller.next();
      expect(controller.chapterIndex, 1);
      expect(notifications, 1);

      controller.next(); // already at the last chapter
      expect(controller.chapterIndex, 1);
      expect(controller.hasNext, isFalse);
      expect(notifications, 1);
    });

    test('resolves a TOC href — fragment and all — to a chapter index',
        () async {
      final book = await EpubBook.open(_twoChapterEpub());
      final controller = EpubReaderController(book: book);
      addTearDown(controller.dispose);

      // Straight from EpubBook.tableOfContents, which carries a #fragment.
      expect(book.tableOfContents[1].href, 'text/chapter2.xhtml#top');
      expect(
        controller.chapterIndexForHref(book.tableOfContents[1].href),
        1,
      );
      expect(controller.chapterIndexForHref('text/chapter1.xhtml'), 0);
    });

    test('resolves a link relative to the chapter that contains it', () async {
      final book = await EpubBook.open(_twoChapterEpub());
      final controller = EpubReaderController(book: book);
      addTearDown(controller.dispose);

      // "chapter2.xhtml" is a sibling of chapter1, not of the OPF — resolving
      // it against the wrong base is the classic broken-link bug.
      expect(controller.chapterIndexForHref('text/chapter2.xhtml'), 1);
      expect(
        controller.chapterIndexForHref(
          'chapter2.xhtml',
          relativeTo: 'text/chapter1.xhtml',
        ),
        1,
      );
      expect(controller.chapterIndexForHref('chapter2.xhtml'), isNull);
    });

    test('openHref moves for in-book links and reports external ones',
        () async {
      final book = await EpubBook.open(_twoChapterEpub());
      final controller = EpubReaderController(book: book);
      addTearDown(controller.dispose);

      expect(controller.openHref('chapter2.xhtml'), isTrue);
      expect(controller.chapterIndex, 1);
      expect(controller.openHref('https://example.com/away'), isFalse);
      expect(controller.chapterIndex, 1);
      expect(controller.openHref('#same-document'), isFalse);
    });
  });

  group('EpubReader', () {
    testWidgets('renders the current chapter and follows the controller',
        (tester) async {
      final book = await EpubBook.open(_twoChapterEpub());
      final controller = EpubReaderController(book: book);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_host(EpubReader(controller: controller)));
      // pump(), never pumpAndSettle(): an unresolved image keeps
      // RenderHyperBox's shimmer frame-callback loop alive forever.
      await tester.pump();

      expect(_viewer(tester).content, contains('First'));

      controller.next();
      await tester.pump();

      expect(_viewer(tester).content, contains('Second'));
      expect(_viewer(tester).content, isNot(contains('First')));
    });

    testWidgets('keys the viewer by position, not by chapter id',
        (tester) async {
      // A spine may list the same manifest item twice. Keyed by id, the two
      // positions would collide, Flutter would reuse the element, and paged
      // mode would not reset to page 0 — the very thing the key is for.
      final book = await EpubBook.open(buildEpub({
        'META-INF/container.xml': containerXml,
        'OEBPS/content.opf': opfXml(
          manifest:
              '<item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>',
          spine: '<itemref idref="ch1"/><itemref idref="ch1"/>',
        ),
        'OEBPS/ch1.xhtml': '<html><body><p>Repeated</p></body></html>',
      }));
      expect(book.chapters.map((c) => c.id), ['ch1', 'ch1']);

      final controller = EpubReaderController(book: book);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_host(EpubReader(controller: controller)));
      await tester.pump();
      final firstKey = _viewer(tester).key;

      controller.next();
      await tester.pump();

      expect(_viewer(tester).key, isNot(firstKey));
    });

    testWidgets('passes the chapter stylesheet, ahead of the reader\'s own CSS',
        (tester) async {
      final book = await EpubBook.open(_twoChapterEpub());
      final controller = EpubReaderController(book: book);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_host(EpubReader(
        controller: controller,
        customCss: 'p { font-size: 20px; }',
      )));
      await tester.pump();

      final css = _viewer(tester).customCss!;
      expect(css, contains('p { color: red; }'));
      expect(css, contains('p { font-size: 20px; }'));
      // The reader's own preferences must come last so they win.
      expect(
        css.indexOf('color: red'),
        lessThan(css.indexOf('font-size: 20px')),
      );
    });

    testWidgets('uses epubImageLoader, which is what decodes data: URIs',
        (tester) async {
      final book = await EpubBook.open(_twoChapterEpub());
      final controller = EpubReaderController(book: book);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_host(EpubReader(controller: controller)));
      await tester.pump();

      // Identity matters: a closure rebuilt per frame would make
      // RenderHyperBox dispose and reload every image on every rebuild.
      expect(_viewer(tester).imageLoader, same(epubImageLoader));
    });

    testWidgets('an in-book link tap navigates; an external one is reported',
        (tester) async {
      final book = await EpubBook.open(_twoChapterEpub());
      final controller = EpubReaderController(book: book);
      addTearDown(controller.dispose);
      final external = <String>[];

      await tester.pumpWidget(_host(EpubReader(
        controller: controller,
        onExternalLinkTap: external.add,
      )));
      await tester.pump();

      // Invoking the wired callback rather than hit-testing canvas-painted
      // text: this asserts EpubReader's own wiring, not HyperRender's tap
      // geometry, which has its own tests.
      _viewer(tester).onLinkTap!('chapter2.xhtml');
      await tester.pump();

      expect(controller.chapterIndex, 1);
      expect(external, isEmpty);

      _viewer(tester).onLinkTap!('https://example.com/away');
      await tester.pump();

      expect(controller.chapterIndex, 1);
      expect(external, ['https://example.com/away']);
    });

    testWidgets('renders a spliced SVG image through flutter_svg',
        (tester) async {
      final book = await EpubBook.open(buildEpub({
        'META-INF/container.xml': containerXml,
        'OEBPS/content.opf': opfXml(
          manifest: '''
    <item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="logo" href="logo.svg" media-type="image/svg+xml"/>''',
          spine: '<itemref idref="ch1"/>',
        ),
        'OEBPS/logo.svg':
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">'
                '<rect width="10" height="10"/></svg>',
        'OEBPS/ch1.xhtml':
            '<html><body><p>Art</p><img src="logo.svg"/></body></html>',
      }));
      final controller = EpubReaderController(book: book);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_host(EpubReader(
        controller: controller,
        // sync mode parses on the spot; paged/virtualized defer through a
        // microtask that this assertion would race.
        mode: HyperRenderMode.sync,
      )));
      await tester.pump();

      // The whole point of splicing markup instead of emitting a
      // data:image/svg URI (which UrlSafety blocks): it actually renders.
      expect(find.byType(SvgPicture), findsOneWidget);
      // …and it renders from the *markup*. An un-spliced <img src="logo.svg">
      // would also produce an SvgPicture — a network one, pointed at a
      // relative path nothing can fetch — so the loader type is what
      // distinguishes a working image from a broken one.
      expect(
        tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader,
        isA<SvgStringLoader>(),
      );
    });

    testWidgets('falls back to emptyBuilder for a book with no chapters',
        (tester) async {
      // Every spine item's file is missing from the archive, so all of them
      // are skipped — the book opens, with nothing to read.
      final book = await EpubBook.open(buildEpub({
        'META-INF/container.xml': containerXml,
        'OEBPS/content.opf': opfXml(
          manifest:
              '<item id="ghost" href="ghost.xhtml" media-type="application/xhtml+xml"/>',
          spine: '<itemref idref="ghost"/>',
        ),
      }));
      expect(book.chapters, isEmpty);

      final controller = EpubReaderController(book: book);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_host(EpubReader(
        controller: controller,
        emptyBuilder: (_) => const Text('Nothing to read'),
      )));
      await tester.pump();

      expect(find.text('Nothing to read'), findsOneWidget);
      expect(find.byType(HyperViewer), findsNothing);
      expect(() => controller.chapter, throwsStateError);
    });
  });
}
