import 'dart:typed_data';

/// A single chapter (spine item) of an [EpubBook], already resolved to
/// content `HyperViewer` can render directly.
///
/// ```dart
/// HyperViewer(
///   html: chapter.html,
///   customCss: chapter.css,
///   imageLoader: epubImageLoader,
///   mode: HyperRenderMode.paged,
/// )
/// ```
class EpubChapter {
  /// The manifest id of this chapter, from the OPF `<spine>`.
  final String id;

  /// Chapter title, if one could be resolved from the EPUB3 `nav.xhtml` or
  /// EPUB2 `toc.ncx` table of contents. `null` when the TOC doesn't map a
  /// title onto this exact spine item.
  final String? title;

  /// XHTML body content, ready for `HyperViewer(html: ...)`.
  ///
  /// `<img src>` has already been rewritten to inline `data:` URIs (the
  /// image bytes live inside the EPUB zip, not at a fetchable `http(s)://`
  /// URL) and `<link rel="stylesheet">` tags have been removed — their
  /// content is concatenated into [css] instead.
  final String html;

  /// CSS text collected from every `<link rel="stylesheet">` this chapter
  /// referenced, in document order. Pass this to `HyperViewer.customCss` —
  /// HyperRender does not fetch external stylesheets on its own, only
  /// inline `<style>` tags.
  final String css;

  const EpubChapter({
    required this.id,
    required this.html,
    required this.css,
    this.title,
  });
}

/// A table-of-contents entry, from EPUB3 `nav.xhtml` or EPUB2 `toc.ncx`.
class EpubTocEntry {
  /// Display title.
  final String title;

  /// Href, relative to the OPF's directory (matches an [EpubChapter.id]'s
  /// source path, not necessarily the chapter id itself — hrefs may include
  /// a `#fragment` for mid-chapter anchors).
  final String href;

  /// Nesting depth, 0 = top-level.
  final int level;

  /// Nested entries (sub-chapters/sections).
  final List<EpubTocEntry> children;

  const EpubTocEntry({
    required this.title,
    required this.href,
    this.level = 0,
    this.children = const [],
  });
}

/// A parsed EPUB book: container → OPF manifest/spine → per-chapter content.
///
/// ```dart
/// final bytes = await File('book.epub').readAsBytes();
/// final book = EpubBook.open(bytes);
/// HyperViewer(
///   html: book.chapters.first.html,
///   customCss: book.chapters.first.css,
///   imageLoader: epubImageLoader,
///   mode: HyperRenderMode.paged,
/// )
/// ```
class EpubBook {
  /// From OPF `dc:title`, if present.
  final String? title;

  /// From OPF `dc:creator`, if present.
  final String? author;

  /// Cover image bytes, if the OPF manifest declares one (`properties`
  /// `"cover-image"` in EPUB3, or a `<meta name="cover">` in EPUB2).
  final Uint8List? coverImage;

  /// Chapters in spine (reading) order.
  final List<EpubChapter> chapters;

  /// Table of contents, top-level entries (each may have [EpubTocEntry.children]).
  final List<EpubTocEntry> tableOfContents;

  // title/author/coverImage have no call site yet — the container/OPF/TOC
  // parser (next change) is the only intended caller, and EpubBook.open()
  // below is still a scaffolding stub. Expected for this commit; the
  // `ignore:` comments below should come out once the parser lands and
  // actually passes these.
  const EpubBook._({
    required this.chapters,
    required this.tableOfContents,
    this.title, // ignore: unused_element_parameter
    this.author, // ignore: unused_element_parameter
    this.coverImage, // ignore: unused_element_parameter
  });

  /// Parses [bytes] — the raw contents of an `.epub` file — into an
  /// [EpubBook].
  ///
  /// `async` on purpose even though today's stub doesn't await anything:
  /// the real implementation does `ZipDecoder` + per-chapter base64 encoding
  /// over a whole book, which is real main-thread work for a large,
  /// illustrated EPUB. Fixing the signature now (while nothing depends on
  /// it yet) is cheaper than changing a published API later.
  ///
  /// **Not implemented yet.** This is a scaffolding commit: the public shape
  /// above (`EpubChapter`/`EpubTocEntry`/`EpubBook`) is what the container/
  /// OPF/TOC parser (next change) and its callers will be written against.
  /// Calling this now throws [UnimplementedError].
  static Future<EpubBook> open(Uint8List bytes) async {
    throw UnimplementedError(
      'EpubBook.open is not implemented yet — hyper_render_epub is still '
      'scaffolding container/OPF/TOC parsing. See CHANGELOG.md.',
    );
  }
}
