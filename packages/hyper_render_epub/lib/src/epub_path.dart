/// Path helpers for EPUB zip entries.
///
/// EPUB hrefs live in two different coordinate systems and mixing them is the
/// classic source of "image not found" bugs:
///
/// * manifest / spine hrefs resolve against the **OPF file's directory**;
/// * hrefs *inside* a chapter (`<img src>`, `<link href>`) resolve against
///   **that chapter's own directory**.
///
/// Zip entry names are literal UTF-8 strings, while hrefs are percent-encoded
/// URI references, so every lookup has to decode before comparing.
library;

/// Returns the directory part of a zip entry name, with a trailing `/`
/// (empty string when the entry sits at the archive root).
String epubDirOf(String path) {
  final i = path.lastIndexOf('/');
  return i == -1 ? '' : path.substring(0, i + 1);
}

/// Collapses `.`/`..` segments and leading slashes into the canonical zip
/// entry form (no leading `/`, no empty segments).
String epubNormalize(String path) {
  final out = <String>[];
  for (final segment in path.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (out.isNotEmpty) out.removeLast();
      continue;
    }
    out.add(segment);
  }
  return out.join('/');
}

/// Resolves [href] — as written inside an EPUB document — against [baseDir]
/// (a directory path ending in `/`, or `''` for the archive root) and returns
/// the zip entry name it points at.
///
/// Strips any `#fragment`, percent-decodes (zip names are literal, hrefs are
/// not), and normalises `../`. Returns `null` for absolute URLs
/// (`http:`, `data:`, …) — those are not archive entries and must be left
/// alone by callers.
String? epubResolve(String baseDir, String href) {
  final trimmed = href.trim();
  if (trimmed.isEmpty) return null;
  if (_absoluteUrl.hasMatch(trimmed)) return null;

  var path = trimmed;
  final hash = path.indexOf('#');
  if (hash != -1) path = path.substring(0, hash);
  if (path.isEmpty) return null; // same-document link, e.g. href="#top"

  path = epubDecode(path);
  // A leading `/` means archive root, not "relative to baseDir".
  final joined = path.startsWith('/') ? path : '$baseDir$path';
  final normalised = epubNormalize(joined);
  return normalised.isEmpty ? null : normalised;
}

/// Percent-decodes an href, tolerating the malformed `%` sequences real books
/// contain (in which case the raw string is used as-is).
///
/// Catches broadly on purpose: `Uri.decodeFull` signals a bad escape with an
/// [ArgumentError] (an `Error`, not an `Exception`), so an `on FormatException`
/// clause would let a filename like `100%.png` crash the whole open.
String epubDecode(String value) {
  try {
    return Uri.decodeFull(value);
  } catch (_) {
    return value;
  }
}

/// Expresses the zip entry [path] the way public hrefs are documented: relative
/// to the OPF's directory, or rooted at `/` for the rare entry that lives
/// outside it.
///
/// The inverse of [epubResolve] against the OPF directory, and the shared
/// coordinate system that lets a TOC href be matched against a chapter.
String epubHrefFromOpf(String path, String opfDir) =>
    path.startsWith(opfDir) ? path.substring(opfDir.length) : '/$path';

/// The `#fragment` of [href] including the `#`, or `''` when there is none.
String epubFragment(String href) {
  final hash = href.indexOf('#');
  return hash == -1 ? '' : href.substring(hash);
}

final RegExp _absoluteUrl = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:');
