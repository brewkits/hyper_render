# Changelog — hyper_render_epub

## 0.1.2

- Updated dependencies on `hyper_render` and `hyper_render_core` to `^1.8.0` for v1.8.0 monorepo alignment and AI streaming architecture compatibility.

## 0.1.1

- Added standalone `example/example.dart` demonstrating `EpubBook.open` and `EpubReader`.
- Added doc comments to `EpubChapter` and `EpubTocEntry` constructors for 100% dartdoc coverage.
- Tightened `hyper_render` and `hyper_render_core` dependency constraints to `^1.7.0` to ensure downgrade test lower bound compatibility on pub.dev.

## 0.1.0

Initial release — **not publishable yet**: it depends on `hyper_render: ^1.7.0`, which is
not on pub.dev. `EpubReader` needs `HyperViewer.imageLoader` (unreleased, on `main`) to
decode the inline `data:` URIs chapters carry, so this package ships once `hyper_render`
1.7.0 does. Monorepo development is unaffected.

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
- `EpubReaderController` (a `ChangeNotifier`: position, `next`/`previous`/`goTo`,
  `chapterIndexForHref`, `openHref`) and `EpubReader`, which renders the current chapter
  through `HyperViewer` and resolves link taps — in-book links move the controller,
  everything else goes to `onExternalLinkTap`. No `Scaffold`/app bar/TOC drawer: chrome is
  the app's, and it has the controller to drive it.
- `EpubChapter.href` (OPF-relative, matching `EpubTocEntry.href`) so TOC entries and
  cross-chapter links can be resolved to a chapter. Links inside a chapter resolve against
  *that chapter's* directory — pass `relativeTo`, which `EpubReader` does for you.
- `EpubFormatException` for structural damage (not a zip, no OPF, no spine). Partial damage
  degrades instead of throwing: a missing chapter file is skipped, an unparsable TOC yields
  an empty list, an `<img>` with no matching entry keeps its original `src`.

- SVG handling: `<img src="*.svg">` is replaced by the SVG markup inline (a
  `data:image/svg` URI would be blocked by `UrlSafety`; an inline `<svg>` is preserved by
  the sanitizer and rendered through `flutter_svg` — note that renderer is chained in by
  `HyperViewer`, not by core's `HyperRenderWidget`). `EpubBook.coverMediaType` accompanies
  `coverImage` so an SVG cover can be routed to `SvgPicture.memory`.

### 📌 Deliberate limits

- Cross-chapter `<a href>` links are left as authored in `EpubChapter.html`; `EpubReader`
  resolves them at tap time.
- Embedded fonts (`@font-face`) and `background-image` are engine-level gaps, not worked
  around here. See the README.
