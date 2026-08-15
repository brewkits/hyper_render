import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';

import 'epub_book.dart';
import 'epub_path.dart';

/// A table-of-contents entry paired with the zip entry its href points at, so
/// chapter titles can be matched by resolved path rather than by raw href.
class ResolvedTocEntry {
  /// The public entry handed to callers.
  final EpubTocEntry entry;

  /// Zip entry name [entry]'s href resolves to (`null` for external links).
  final String? path;

  /// Flattened children, depth-first.
  final List<ResolvedTocEntry> children;

  const ResolvedTocEntry(this.entry, this.path, this.children);
}

/// Parses an EPUB3 navigation document (`nav.xhtml`).
///
/// [navPath] is the nav document's own zip entry name (hrefs inside it are
/// relative to *its* directory, not the OPF's); [opfDir] is what the returned
/// [EpubTocEntry.href]s are made relative to.
List<ResolvedTocEntry> parseNavDocument(
  String source,
  String navPath,
  String opfDir,
) {
  final dom.Document document;
  try {
    document = html_parser.parse(source);
  } catch (_) {
    return const [];
  }
  final baseDir = epubDirOf(navPath);

  // Prefer the `toc` nav; a nav document may also carry `landmarks`,
  // `page-list`, `loi`, … which are not a table of contents.
  dom.Element? nav;
  for (final candidate in document.querySelectorAll('nav')) {
    final type =
        candidate.attributes['epub:type'] ?? candidate.attributes['type'] ?? '';
    if (type.split(RegExp(r'\s+')).contains('toc')) {
      nav = candidate;
      break;
    }
  }
  nav ??= document.querySelector('nav');
  if (nav == null) return const [];

  final list = nav.children
      .where((e) => e.localName == 'ol' || e.localName == 'ul')
      .firstOrNull;
  if (list == null) return const [];
  return _navList(list, baseDir, opfDir, 0);
}

List<ResolvedTocEntry> _navList(
  dom.Element list,
  String baseDir,
  String opfDir,
  int level,
) {
  final entries = <ResolvedTocEntry>[];
  for (final li in list.children.where((e) => e.localName == 'li')) {
    final anchor = li.children
        .where((e) => e.localName == 'a' || e.localName == 'span')
        .firstOrNull;
    final nested = li.children
        .where((e) => e.localName == 'ol' || e.localName == 'ul')
        .firstOrNull;
    final children = nested == null
        ? const <ResolvedTocEntry>[]
        : _navList(nested, baseDir, opfDir, level + 1);

    final rawHref = anchor?.attributes['href'] ?? '';
    final title = _collapse(anchor?.text ?? '');
    if (title.isEmpty && rawHref.isEmpty && children.isEmpty) continue;

    entries.add(
      _entry(
        title: title,
        rawHref: rawHref,
        baseDir: baseDir,
        opfDir: opfDir,
        level: level,
        children: children,
      ),
    );
  }
  return entries;
}

/// Parses an EPUB2 `toc.ncx` navMap.
///
/// [ncxPath] is the NCX's own zip entry name (its `content src`s are relative
/// to that directory); [opfDir] is what the returned hrefs are relative to.
List<ResolvedTocEntry> parseNcx(String source, String ncxPath, String opfDir) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(source);
  } on XmlException {
    return const [];
  }
  final navMap = doc.findAllElements('navMap', namespaceUri: '*').firstOrNull;
  if (navMap == null) return const [];
  return _navPoints(navMap, epubDirOf(ncxPath), opfDir, 0);
}

List<ResolvedTocEntry> _navPoints(
  XmlElement parent,
  String baseDir,
  String opfDir,
  int level,
) {
  final entries = <ResolvedTocEntry>[];
  // Direct children only — `findAllElements` would flatten the nesting that
  // carries the TOC's depth.
  for (final point in parent.childElements) {
    if (point.localName != 'navPoint') continue;
    final label = point
        .findElements('navLabel', namespaceUri: '*')
        .expand((e) => e.findElements('text', namespaceUri: '*'))
        .firstOrNull;
    final content =
        point.findElements('content', namespaceUri: '*').firstOrNull;
    entries.add(
      _entry(
        title: _collapse(label?.innerText ?? ''),
        rawHref: content?.getAttribute('src') ?? '',
        baseDir: baseDir,
        opfDir: opfDir,
        level: level,
        children: _navPoints(point, baseDir, opfDir, level + 1),
      ),
    );
  }
  return entries;
}

ResolvedTocEntry _entry({
  required String title,
  required String rawHref,
  required String baseDir,
  required String opfDir,
  required int level,
  required List<ResolvedTocEntry> children,
}) {
  final path = epubResolve(baseDir, rawHref);
  // The public href is documented as OPF-relative, so strip the OPF directory
  // back off the resolved zip key and re-attach any `#fragment`.
  final String href;
  if (path == null) {
    href = rawHref;
  } else {
    final relative =
        path.startsWith(opfDir) ? path.substring(opfDir.length) : '/$path';
    href = '$relative${epubFragment(rawHref)}';
  }
  return ResolvedTocEntry(
    EpubTocEntry(
      title: title,
      href: href,
      level: level,
      children: [for (final c in children) c.entry],
    ),
    path,
    children,
  );
}

/// First title for each zip entry a TOC points at, depth-first (an entry
/// deeper in the tree never overrides the chapter-level title above it).
Map<String, String> tocTitlesByPath(List<ResolvedTocEntry> entries) {
  final titles = <String, String>{};
  void walk(List<ResolvedTocEntry> list) {
    for (final entry in list) {
      final path = entry.path;
      if (path != null &&
          entry.entry.title.isNotEmpty &&
          !titles.containsKey(path)) {
        titles[path] = entry.entry.title;
      }
      walk(entry.children);
    }
  }

  walk(entries);
  return titles;
}

String _collapse(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
