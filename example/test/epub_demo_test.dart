// Functional test for the EPUB demo.
//
// The smoke net only proves the screen opens; it can't get past the loading
// spinner, because zipping the sample book encodes real PNGs through
// `Picture.toImage()`, which needs a genuine async gap (`tester.runAsync`).
// These tests do the real thing: parse the very bytes the screen parses, and
// drive chapter navigation on the mounted widget.

import 'package:example/epub_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:hyper_render_epub/hyper_render_epub.dart';

void main() {
  // LazyImageQueue is a process-wide singleton that dedupes in-flight loads by
  // URL; the sample book's images repeat across tests.
  setUp(() => LazyImageQueue.instance.resetForTesting());
  tearDown(() => LazyImageQueue.instance.resetForTesting());

  testWidgets('the sample bytes really are an EPUB container', (tester) async {
    late final EpubBook book;
    await tester.runAsync(() async {
      book = await EpubBook.open(await buildSampleEpub());
    });

    expect(book.title, 'Anatomy of an EPUB');
    expect(book.author, 'HyperRender');
    expect(book.chapters, hasLength(3));
    expect(book.tableOfContents, hasLength(3));
    expect(book.coverMediaType, 'image/png');
    expect(book.coverImage, isNotNull);

    // The stylesheet is <link>ed, not inline — the package must have pulled it
    // out of the zip and handed it over separately.
    expect(book.chapters.first.css, contains('.plate { float: left'));
    expect(book.chapters.first.html, isNot(contains('<link')));

    // Chapter 2's raster image became an inline data: URI…
    expect(book.chapters[1].html, contains('src="data:image/png;base64,'));
    // …while chapter 1's SVG was spliced as markup (a data:image/svg URI would
    // be blocked by UrlSafety).
    expect(book.chapters.first.html, contains('<svg'));
    // `src=` qualified: the chapter's prose mentions "data:image/svg" as text.
    expect(book.chapters.first.html, isNot(contains('src="data:image/svg')));
    expect(book.chapters.first.html, isNot(contains('src="../images/')));
  });

  testWidgets('navigates chapters and resolves a TOC jump', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: EpubDemo()));
      // Let the zip + PNG encoding finish; the screen shows a spinner until it
      // does. pumpAndSettle() is not an option — an unresolved chapter image
      // keeps RenderHyperBox's shimmer frame loop alive indefinitely.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pump();
    });
    await tester.pump();

    // Metadata straight off the OPF.
    expect(find.text('Anatomy of an EPUB'), findsOneWidget);
    expect(find.textContaining('3 spine items'), findsOneWidget);
    expect(find.text('1 — The container'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(find.text('2 — Images inside the zip'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    expect(find.text('1 — The container'), findsOneWidget);

    // A TOC entry's href is OPF-relative; the controller resolves it to a
    // chapter rather than the app matching strings.
    await tester.tap(find.byIcon(Icons.list));
    await tester.pump();
    // The sheet slides in; tapping mid-animation lands outside its bounds.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('3 — Links and typography').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // sheet dismissal

    expect(find.text('3 — Links and typography'), findsOneWidget);
  });
}
