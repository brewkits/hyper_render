import 'package:xml/xml.dart';

import 'epub_archive.dart';
import 'epub_exception.dart';
import 'epub_path.dart';

/// One `<item>` of the OPF `<manifest>`.
class OpfItem {
  /// Manifest `id`, the key spine `<itemref idref>` points at.
  final String id;

  /// Zip entry name this item resolves to (OPF-directory-relative `href`
  /// already resolved), or `null` for a remote/absolute href.
  final String? path;

  /// Declared `media-type`, e.g. `application/xhtml+xml`, `image/jpeg`.
  final String mediaType;

  /// EPUB3 `properties` tokens, e.g. `nav`, `cover-image`.
  final Set<String> properties;

  const OpfItem({
    required this.id,
    required this.path,
    required this.mediaType,
    required this.properties,
  });
}

/// The parsed OPF package document: metadata, manifest and spine.
class OpfPackage {
  /// Zip entry name of the OPF file itself.
  final String path;

  /// Directory the OPF lives in (with trailing `/`) — the base every manifest
  /// href resolves against.
  final String dir;

  /// Manifest items by `id`.
  final Map<String, OpfItem> manifest;

  /// Manifest items by resolved zip entry name.
  final Map<String, OpfItem> byPath;

  /// Spine `idref`s, in reading order.
  final List<String> spine;

  /// Spine ids marked `linear="no"` (front/back matter a reader may skip).
  final Set<String> nonLinear;

  /// `<spine toc="...">` — the EPUB2 `toc.ncx` manifest id, when present.
  final String? ncxId;

  /// `<meta name="cover" content="...">` — the EPUB2 cover manifest id.
  final String? coverMetaId;

  /// `dc:title`.
  final String? title;

  /// `dc:creator`.
  final String? author;

  const OpfPackage({
    required this.path,
    required this.dir,
    required this.manifest,
    required this.byPath,
    required this.spine,
    required this.nonLinear,
    required this.ncxId,
    required this.coverMetaId,
    required this.title,
    required this.author,
  });

  /// The EPUB3 navigation document (`properties="nav"`), if the book has one.
  OpfItem? get navItem {
    for (final item in manifest.values) {
      if (item.properties.contains('nav')) return item;
    }
    return null;
  }

  /// The cover image item — EPUB3 `properties="cover-image"` first, then the
  /// EPUB2 `<meta name="cover">` pointer.
  ///
  /// Both paths require an *image*: a `<meta name="cover">` pointing at the
  /// cover *page* (a common EPUB2 mistake) is not a cover image. SVG counts —
  /// the caller is told the media type and can pick its own renderer.
  OpfItem? get coverItem {
    for (final item in manifest.values) {
      if (item.properties.contains('cover-image') && _isImage(item)) {
        return item;
      }
    }
    final byMeta = coverMetaId == null ? null : manifest[coverMetaId];
    if (byMeta != null && _isImage(byMeta)) return byMeta;
    return null;
  }

  static bool _isImage(OpfItem item) {
    final type = item.mediaType.toLowerCase();
    if (type.isNotEmpty) return type.startsWith('image/');
    // Undeclared media-type: fall back to the extension.
    final path = item.path?.toLowerCase();
    if (path == null) return false;
    return const ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.svg']
        .any(path.endsWith);
  }
}

/// Locates the OPF package document via `META-INF/container.xml`.
///
/// Falls back to the first `.opf` entry in the archive when the container is
/// missing or unparsable — some real books ship a broken container but are
/// otherwise readable.
String findOpfPath(EpubArchive archive) {
  final containerXml = archive.readText('META-INF/container.xml');
  if (containerXml != null) {
    try {
      final doc = XmlDocument.parse(containerXml);
      for (final rootfile
          in doc.findAllElements('rootfile', namespaceUri: '*')) {
        final fullPath = rootfile.getAttribute('full-path');
        if (fullPath == null || fullPath.trim().isEmpty) continue;
        final resolved = epubResolve('', fullPath);
        if (resolved != null && archive.read(resolved) != null) return resolved;
      }
    } on XmlException {
      // Fall through to the scan below.
    }
  }

  for (final name in archive.names) {
    if (name.toLowerCase().endsWith('.opf')) return name;
  }
  throw const EpubFormatException(
    'No OPF package document found (META-INF/container.xml missing or '
    'pointing nowhere, and no *.opf entry in the archive).',
  );
}

/// Parses the OPF package document at [opfPath].
OpfPackage parseOpf(EpubArchive archive, String opfPath) {
  final xml = archive.readText(opfPath);
  if (xml == null) {
    throw EpubFormatException('OPF package document missing: $opfPath');
  }

  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xml);
  } on XmlException catch (e) {
    throw EpubFormatException('OPF package document is not valid XML: $e');
  }

  final dir = epubDirOf(opfPath);

  final manifest = <String, OpfItem>{};
  final byPath = <String, OpfItem>{};
  for (final element in doc.findAllElements('item', namespaceUri: '*')) {
    final id = element.getAttribute('id');
    final href = element.getAttribute('href');
    if (id == null || href == null) continue;
    final item = OpfItem(
      id: id,
      path: epubResolve(dir, href),
      mediaType: element.getAttribute('media-type')?.trim() ?? '',
      properties: _tokens(element.getAttribute('properties')),
    );
    manifest[id] = item;
    if (item.path != null) byPath[item.path!] = item;
  }

  final spine = <String>[];
  final nonLinear = <String>{};
  String? ncxId;
  final spineElement =
      doc.findAllElements('spine', namespaceUri: '*').firstOrNull;
  if (spineElement != null) {
    ncxId = spineElement.getAttribute('toc');
    for (final ref
        in spineElement.findAllElements('itemref', namespaceUri: '*')) {
      final idref = ref.getAttribute('idref');
      if (idref == null) continue;
      spine.add(idref);
      if (ref.getAttribute('linear')?.trim().toLowerCase() == 'no') {
        nonLinear.add(idref);
      }
    }
  }
  if (spine.isEmpty) {
    throw const EpubFormatException(
      'OPF package document declares no spine items — nothing to read.',
    );
  }

  // Scoped to <metadata> so a `<title>` elsewhere in the package document
  // (or inside an embedded SVG fallback) can't shadow `dc:title`.
  final XmlNode metadata =
      doc.findAllElements('metadata', namespaceUri: '*').firstOrNull ?? doc;

  String? coverMetaId;
  for (final meta in doc.findAllElements('meta', namespaceUri: '*')) {
    if (meta.getAttribute('name')?.trim().toLowerCase() == 'cover') {
      coverMetaId = meta.getAttribute('content')?.trim();
      if (coverMetaId != null && coverMetaId.isNotEmpty) break;
    }
  }

  return OpfPackage(
    path: opfPath,
    dir: dir,
    manifest: manifest,
    byPath: byPath,
    spine: spine,
    nonLinear: nonLinear,
    ncxId: ncxId,
    coverMetaId: coverMetaId,
    title: _dcText(metadata, 'title'),
    author: _dcText(metadata, 'creator'),
  );
}

Set<String> _tokens(String? value) {
  if (value == null) return const {};
  return value
      .split(RegExp(r'\s+'))
      .map((t) => t.trim().toLowerCase())
      .where((t) => t.isNotEmpty)
      .toSet();
}

/// Reads a Dublin Core element's text, namespace-agnostically — real books
/// use `dc:`, `DC:`, or no prefix at all.
String? _dcText(XmlNode scope, String name) {
  for (final element in scope.findAllElements(name, namespaceUri: '*')) {
    final text = element.innerText.trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
