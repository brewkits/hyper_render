# Changelog

All notable changes to HyperRender are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-03-01

First stable release. Core features, plugin architecture, and cross-platform support are production-ready.

### Pre-publish fixes (2026-03-01)

- **`docs/` → `doc/`** — renamed documentation directory to follow pub.dev layout convention
- **`HyperViewer`** — removed `implementation_imports` lint violations; added `onError` callback; parsing is now async via `Future.microtask` (non-blocking UI); `HyperRenderMode.virtualized` now renders each top-level block as an independent `HyperRenderWidget` inside `ListView.builder`; `enableZoom` now correctly wraps content in `InteractiveViewer`; `_isComplexHtml` cached instead of recomputed on every `build()`
- **`HyperRenderWidget`** — removed null-guard around `childWidget`; removed unused import
- **`DefaultCssParser`** — fixed redundant `?.` null-check on non-nullable `String.trim()`
- **Sub-packages** — SDK constraint `>=3.5.0 <4.0.0`; `vector_math: ^2.2.0`; `share_plus: ^10.0.0`; `topics` added to all sub-package pubspecs

### Bug Fixes

- **`CssRuleIndex` ancestor-class misindex (CRITICAL)** — `_analyzeSelector()` previously checked for `.` and `#` *before* checking for combinator characters, so a rule like `nav.main-nav li` or `.sidebar .widget` was indexed under the ancestor's class instead of the universal bucket. Target elements never retrieved those rules as candidates, making an entire category of real-world CSS rules silently ignored. Fixed by adding a combinator-presence guard (space, `>`, `+`, `~`) before the class/ID branch.

- **Image layout division-by-zero (MAJOR)** — When a `ui.Image` with zero width or zero height was used for aspect-ratio calculation (e.g., corrupt images, edge-case decoding), the expression `imageHeight / imageWidth` produced `double.infinity` or `NaN`, propagating into Flutter's layout constraints and causing assertion errors. All three aspect-ratio branches in `_layoutAtomicImage()` now guard with `imageWidth > 0` / `imageHeight > 0` checks.

- **Ruby `<rt>` text null dereference (MINOR)** — `HtmlAdapter._buildRubyNode()` accessed `child.text` without `?? ''` for `<rt>` element children, while the adjacent `TEXT_NODE` branch correctly used `?? ''`. Fixed by adding `?? ''`.

- **`HtmlSanitizer` strips ARIA/accessibility attributes (MEDIUM)** — `aria-label`, `aria-hidden`, `aria-expanded`, `role`, and all `aria-*` attributes were silently removed by the default sanitizer allowlist, making the documented ARIA/accessibility features non-functional when `sanitize: true` (the default). Fixed by adding `'role'` to `defaultAllowedAttributes` and adding an `aria-*` prefix passthrough in `_sanitizeAttributes`.

- **`@import` blocked in CSS** — `@import` directives are now stripped from `<style>` tag CSS (via `HtmlAdapter.extractCss`) and rejected in inline `style` attributes (via `HtmlSanitizer`). `HtmlSanitizer.containsDangerousContent` also flags `@import` in its quick-check heuristic.

- **`!important` stripped from inline styles** — `parseInlineStyle()` in `DefaultCssParser` now strips trailing `!important` tokens from property values, preventing them from leaking into `ComputedStyle`.

### Security

- **`customCss` security note** — dartdoc for `HyperViewer.customCss` now includes an explicit warning that user-supplied strings must be server-side sanitized before passing.

### New Features

- **`onImageTap` callback** — `HyperViewer` and `HyperRenderWidget` now accept `onImageTap: (url) {}` to handle image tap events.
- **`allowedAttributes` parameter** — `HyperViewer` now exposes `allowedAttributes` (all 3 constructors) to override the sanitizer's default attribute allowlist.
- **`HyperRenderConfig`** — new static-field class for configuring global rendering defaults before app startup:
  - `HyperRenderConfig.imageCacheMaxMb` (default: 50 MB)
  - `HyperRenderConfig.textPainterCacheMaxEntries` (default: 5000)
  - `HyperRenderConfig.configure({imageCacheMaxMb, textPainterCacheMaxEntries})`
- **`hyper_render_clipboard` re-enabled** — the clipboard sub-package is now included in `pubspec.yaml` and exported from `lib/hyper_render.dart`.

### Rendering Engine

- Custom `RenderObject`-based layout engine (`RenderHyperBox`) — no widget tree overhead per text node
- Unified Document Tree (UDT) model: `BlockNode`, `InlineNode`, `AtomicNode`, `TextNode`, `RubyNode`, `TableNode`
- Full CSS cascade: UA defaults → author `<style>` rules → inline `style=""` → inheritance
- CSS specificity calculated correctly (ID > class > element); stable sort by source index for equal specificity
- `CssRuleIndex`: O(1) HashMap-backed CSS rule lookup — 3–16µs median regardless of stylesheet size (measured at 100–5,000 rules)

### Layout

- Block and inline layout with correct margin collapsing
- Flexbox (`display: flex`) with direction, wrap, align-items, justify-content, gap
- CSS Grid (`display: grid`) with template columns/rows and span support
- Float layout (`float: left/right`) with full text reflow — wrapping text around floated images works as expected
- Table layout with content-based column widths, colspan/rowspan, nested tables
- `display: none` fully respected

### CSS Properties

- Typography: `font-size` (px, em, rem), `font-weight`, `font-style`, `font-family`, `line-height`, `letter-spacing`, `word-spacing`, `text-align`, `text-decoration`, `text-transform`, `white-space`, `vertical-align`
- Box model: `width`/`height`, `min-`/`max-` variants, `margin`, `padding`, `border`, `border-radius`
- Color: named colors (full CSS4 palette of 147 names), `#RGB`, `#RRGGBB`, `#RGBA`, `#RRGGBBAA`, `rgb()`, `rgba()`, `hsl()`, `hsla()`
- Backgrounds: `background-color`, `background-image` (basic)
- Layout: `display`, `float`, `clear`, `overflow`, `position: static/relative`, `opacity`
- Flexbox: `flex-direction`, `flex-wrap`, `justify-content`, `align-items`, `align-content`, `align-self`, `flex-grow`, `flex-shrink`, `flex-basis`, `order`, `gap`
- Grid: `grid-template-columns`, `grid-template-rows`, `grid-auto-flow`, `grid-column`, `grid-row`
- CSS custom properties (`--var-name`) and `var()` resolution with nested references
- `calc()` expressions with px/em/rem arithmetic, including negative numbers
- `transition` and `animation` parsed into `ComputedStyle` (visual playback via `HyperAnimatedWidget`)
- `transform` via `Matrix4` (translation, rotation, scale)
- Inline style tokenizer is bracket-aware — `calc(50% - 8px)` inside `style=""` parses correctly

### HTML Tags

- Text: `<p>`, `<div>`, `<span>`, `<br>`, `<hr>`
- Headings: `<h1>`–`<h6>`
- Formatting: `<strong>`/`<b>`, `<em>`/`<i>`, `<u>`, `<s>`/`<del>`, `<mark>`, `<code>`, `<pre>`, `<sub>`, `<sup>`, `<abbr>`, `<cite>`, `<q>`, `<kbd>`, `<samp>`
- Lists: `<ul>`, `<ol>`, `<li>` with 9 list-style-type variants (disc, circle, square, decimal, lower/upper-roman, lower/upper-alpha, none)
- Tables: `<table>`, `<thead>`, `<tbody>`, `<tfoot>`, `<tr>`, `<th>`, `<td>` with full colspan/rowspan
- Links: `<a>` with `href`, `target`, `aria-label`
- Media: `<img>` (network + asset), `<video>` / `<audio>` (styled placeholder via `DefaultMediaWidget`)
- Semantic: `<article>`, `<section>`, `<aside>`, `<nav>`, `<main>`, `<header>`, `<footer>`, `<blockquote>`, `<figure>`, `<figcaption>`
- Interactive: `<details>` / `<summary>` (tap to expand/collapse)
- CJK: `<ruby>` / `<rt>` (furigana rendering above base text), kinsoku shori line-breaking rules
- Metadata: `<style>` (full CSS injection), `<link>` (external stylesheet — href captured, not fetched)
- SVG: `<svg>` inline (placeholder; full renderer in progress)
- Unsupported: `<canvas>`, `<form>`, `<input>`, `<select>`, `<iframe>` — use `widgetBuilder` to inject native Flutter widgets for these

### Content Formats

- HTML5 (default)
- CommonMark Markdown with GFM extensions (tables, strikethrough, task lists) via `HyperViewer.markdown()`
- Quill Delta JSON via `HyperViewer.delta()`

### Text Selection

- Cross-fragment text selection rendered as a single continuous highlight
- Selection drag handles on mobile
- Context menu (Copy, Select All) — customisable via `selectionMenuActionsBuilder`
- `getSelectedText()`, `selectAll()`, `clearSelection()` on `RenderHyperBox`
- `onSelectionChanged` callback for external state updates

### Security

- `HtmlSanitizer` with allowlist-based tag and attribute filtering — enabled by default for HTML content
- `javascript:`, `vbscript:`, `data:text`, `data:application` URL schemes blocked in `href`/`src` attributes
- CSS `expression()` stripped from inline styles
- Null-byte injection in tag names blocked (strips `\x00` before parsing)
- `allowedTags` parameter to extend the default allowlist
- `sanitize: false` opt-out for trusted, backend-controlled HTML

### Accessibility

- `Semantics` wrapper on `HyperViewer` with configurable `semanticLabel` (default: `'Article content'`)
- `excludeSemantics: true` for decorative content
- Per-element semantic nodes: `isHeader` for `<h1>`–`<h6>`, `isLink` for `<a>`, `isImage` for `<img>`, `isButton` for `<button>`
- List ordinal hints: "Item 2 of 5" for `<li>` within `<ul>`/`<ol>`
- ARIA attribute support: `aria-label` overrides semantic label on any element; `role` maps to Flutter semantic flags (button, heading, region)
- Landmark elements (`<nav>`, `<main>`, `<header>`, `<footer>`) emit labeled `SemanticsNode` entries
- `<pre>` announced as "Code block: [content]" for screen readers
- Text direction: `dir="rtl"` / `dir="ltr"` per-element, inherited

### Performance

- Image LRU cache: `LinkedHashMap`-backed with 50 MB byte-budget; oldest loaded `ui.Image` objects are evicted and disposed when limit is exceeded
- Viewport culling: off-screen fragments skipped during paint (disabled in test/golden environment where no clip layer is present)
- Selection highlight uses `computeLineMetrics()` ascent+descent for tight glyph bounds — avoids CSS line-height inflating the highlight rect
- `HyperRenderMode.auto`: sync rendering below ~30 KB; switches to virtualized `ListView` for larger documents

Measured on macOS (Darwin 25.2.0, Flutter Desktop, release mode):

| Document size | Median parse time |
|---------------|-------------------|
| 1 KB          | 27 ms             |
| 10 KB         | 69 ms             |
| 50 KB         | 276 ms            |
| 100 KB        | 575 ms            |

CSS lookup: 3–16 µs median (100–5,000 rules). Source: `benchmark/RESULTS.md`.

### Plugin Interfaces

- `ContentParser` — custom content format (implement `parseWithOptions`)
- `CodeHighlighter` — syntax highlighting (return `InlineSpan` tree)
- `CssParserInterface` — custom CSS parsing
- `ImageClipboardHandler` — copy/save image data from `<img>` nodes
- `HyperWidgetBuilder = Widget? Function(UDTNode node)` — replace any atomic node with a native Flutter widget; return `null` to use default rendering

### Developer Tools

- `captureKey: GlobalKey` on `HyperViewer` + `HyperCaptureExtension` to export rendered content as PNG
- `debugShowHyperRenderBounds: true` draws debug outlines around each render box
- `packages/hyper_render_devtools/` — Flutter DevTools extension for inspecting the UDT and fragment layout
- `HtmlHeuristics.isComplex()` — detects documents with `position:fixed`, `<canvas>`, `z-index`, etc.; use with `fallbackBuilder` to show a WebView instead

### Packages

- `hyper_render` — top-level package, re-exports everything; depends on `hyper_render_core`, `hyper_render_html`, `hyper_render_markdown`
- `hyper_render_core` — rendering engine with no external dependencies (except Flutter SDK)
- `hyper_render_html` — HTML parser, CSS parser, HTML sanitizer
- `hyper_render_markdown` — CommonMark + GFM parser (wraps `markdown` package)
- `hyper_render_clipboard` — image copy/save via `super_clipboard`

### Tests

164 unit and integration tests passing (style, layout, accessibility, security, performance, widget capture).

---

[1.0.0]: https://github.com/brewkits/hyper_render/releases/tag/v1.0.0
