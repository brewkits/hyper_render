import 'dart:typed_data';

import 'epub_archive.dart';
import 'epub_chapter_transform.dart';
import 'epub_exception.dart';
import 'epub_opf.dart';
import 'epub_toc.dart';

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

  /// CSS text collected from every `<link rel="stylesheet">` and `<style>`
  /// this chapter carried, in document order. Pass this to
  /// `HyperViewer.customCss` — HyperRender does not fetch external stylesheets
  /// on its own, and a `<head>` `<style>` would otherwise be lost with the
  /// rest of the head.
  final String css;

  /// False when the spine marks this item `linear="no"` — front/back matter
  /// (cover pages, colophons, note collections) that a reader may present out
  /// of the main flow, or skip. Such items are still in [EpubBook.chapters];
  /// this flag is what lets a reader UX decide.
  final bool linear;

  const EpubChapter({
    required this.id,
    required this.html,
    required this.css,
    this.title,
    this.linear = true,
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
/// final book = await EpubBook.open(bytes);
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
  ///
  /// Includes items the spine marks `linear="no"` (covers, notes, colophons):
  /// they are part of the book, and dropping content silently is worse than
  /// showing a page a reader can skip — see [EpubChapter.linear] to tell them
  /// apart. A spine item whose file is missing from the archive *is* dropped,
  /// so this can be shorter than the spine.
  final List<EpubChapter> chapters;

  /// Table of contents, top-level entries (each may have [EpubTocEntry.children]).
  ///
  /// Empty when the book ships no navigation document / `toc.ncx`, or when the
  /// one it ships cannot be parsed — a broken TOC never fails the open.
  final List<EpubTocEntry> tableOfContents;

  const EpubBook._({
    required this.chapters,
    required this.tableOfContents,
    this.title,
    this.author,
    this.coverImage,
  });

  /// Parses [bytes] — the raw contents of an `.epub` file — into an
  /// [EpubBook].
  ///
  /// Unzips the archive, locates the OPF package document through
  /// `META-INF/container.xml`, then resolves every spine item into an
  /// [EpubChapter] whose images are inlined as `data:` URIs and whose linked
  /// stylesheets are collected into [EpubChapter.css].
  ///
  /// `async` because this is real main-thread work for a large, illustrated
  /// book (zip inflate + base64 over every image); the returned future
  /// completes on the same frame for small books.
  ///
  /// Throws [EpubFormatException] when the bytes are not a usable EPUB — not a
  /// zip, no OPF, or an OPF with no spine. Partial damage (a missing chapter
  /// file, an unparsable TOC, an image whose entry is absent) degrades
  /// gracefully instead of throwing; see [EpubFormatException].
  static Future<EpubBook> open(Uint8List bytes) async {
    final archive = EpubArchive.decode(bytes);
    final opf = parseOpf(archive, findOpfPath(archive));

    final toc = _readToc(archive, opf);
    final titles = tocTitlesByPath(toc);

    final chapters = <EpubChapter>[];
    for (final idref in opf.spine) {
      final item = opf.manifest[idref];
      final source = archive.readText(item?.path);
      if (item == null || source == null) continue;
      final content = transformChapter(
        source: source,
        chapterPath: item.path!,
        archive: archive,
        opf: opf,
      );
      chapters.add(
        EpubChapter(
          id: item.id,
          title: titles[item.path],
          html: content.html,
          css: content.css,
          linear: !opf.nonLinear.contains(idref),
        ),
      );
    }

    return EpubBook._(
      chapters: chapters,
      tableOfContents: [for (final entry in toc) entry.entry],
      title: opf.title,
      author: opf.author,
      coverImage: archive.read(opf.coverItem?.path),
    );
  }

  /// EPUB3 navigation document first, EPUB2 `toc.ncx` as fallback — a book may
  /// legally ship both (for reader compatibility), and the nav document is the
  /// authoritative one when it does.
  static List<ResolvedTocEntry> _readToc(
    EpubArchive archive,
    OpfPackage opf,
  ) {
    final nav = opf.navItem;
    if (nav?.path != null) {
      final source = archive.readText(nav!.path);
      if (source != null) {
        final entries = parseNavDocument(source, nav.path!, opf.dir);
        if (entries.isNotEmpty) return entries;
      }
    }

    final ncx = opf.ncxId == null ? null : opf.manifest[opf.ncxId];
    final ncxPath = ncx?.path ??
        opf.byPath.keys
            .where((p) => p.toLowerCase().endsWith('.ncx'))
            .firstOrNull;
    if (ncxPath != null) {
      final source = archive.readText(ncxPath);
      if (source != null) return parseNcx(source, ncxPath, opf.dir);
    }
    return const [];
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
