# Changelog — hyper_render_epub

## 0.1.0

Initial release — not published to pub.dev yet.

### ✨ New

- `EpubBook.open(Uint8List)`: unzips an `.epub`, locates the OPF package document through
  `META-INF/container.xml` (never a hardcoded path), and parses `dc:title` / `dc:creator`,
  the manifest, the spine and the cover image. Returns `Future<EpubBook>` — a large,
  illustrated book is real main-thread work (zip inflate + base64 per image).
- Table of contents: EPUB3 `nav.xhtml` (`properties="nav"`, `epub:type="toc"`), falling
  back to the EPUB2 `toc.ncx` navMap. Nesting and `#fragment`s are preserved, and TOC
  titles are matched onto chapters by resolved path, so `EpubChapter.title` is populated.
- Per-chapter transform: `<img src>` pointing into the archive is rewritten to an inline
  base64 `data:` URI; `<link rel="stylesheet">` and `<style>` elements are removed and
  their text concatenated into `EpubChapter.css` in document order (for
  `HyperViewer.customCss`); `<body>` content is extracted. Parsed with the HTML5 parser,
  not a strict XHTML one — real books are full of undeclared entities and unclosed tags.
- `EpubChapter.linear` mirrors the spine's `linear="no"`: such items are kept in
  `chapters` (dropping content silently is worse) but flagged so a reader can present
  them out of the main flow.
- `epubImageLoader`: a `HyperImageLoader` that decodes those `data:` URIs (falls back to
  the normal network loader for any other scheme).
- `EpubFormatException` for structural damage (not a zip, no OPF, no spine). Partial damage
  degrades instead of throwing: a missing chapter file is skipped, an unparsable TOC yields
  an empty list, an `<img>` with no matching entry keeps its original `src`.

### 📌 Deliberate limits

- SVG images are left un-inlined — `UrlSafety` blocks `data:image/svg` and the canvas
  painter cannot rasterise SVG. For the same reason an SVG cover is reported as
  `coverImage: null` rather than as bytes nothing can decode.
- Cross-chapter `<a href>` links are left as authored; resolving them is the app's job.
- Embedded fonts (`@font-face`) and `background-image` are engine-level gaps, not worked
  around here. See the README.
