# HyperRender Limitations

This document describes the known limitations of hyper_render and provides
workarounds where available.

---

## CSS Coverage Gaps

hyper_render implements the **essential** CSS subset needed for typical
article/document rendering (~50 properties). Properties outside that subset
are silently ignored.

### Not supported

| Property / Feature | Impact | Workaround |
|--------------------|--------|------------|
| `position: absolute` / `fixed` | Elements won't be positioned outside normal flow | Use `pluginRegistry` to inject a custom Flutter overlay |
| `z-index` | Stacking order not respected | Structure HTML so elements appear in the desired paint order |
| `clip-path` | Non-rectangular masks not applied | Pre-clip images server-side |
| `@media` queries | Responsive breakpoints ignored | Serve device-appropriate HTML, or use `customCss` for overrides |
| `background-position` | Not parsed | Use inline `<img>` instead of CSS backgrounds |
| `background-repeat` | Not parsed | N/A |
| `columns` / `column-count` | Multi-column layout not rendered | Use a CSS Grid layout (supported) |

### Supported in v1.2.0

| Property | Status |
|----------|--------|
| `box-shadow` | ✅ Multiple shadows, blur, spread supported |
| `text-shadow` | ✅ Multiple shadows, blur supported |
| `filter` / `backdrop-filter` | ✅ blur, brightness, contrast supported |
| `@keyframes` | ✅ Parsed from `<style>` tags automatically |
| `background-image` | ✅ url() and `linear-gradient()` supported |
| `background-size` | ✅ cover, contain, fill supported |
| `display: grid` | ✅ full auto-placement, fr-units, and gap support |

### Partial support

| Property | Limitation |
|----------|------------|
| `opacity` | Applied per-element; stacking context opacity not propagated |
| `position: relative` | Supported but child `absolute` positioning is not |
| `calc()` | Arithmetic on px/em/rem only; `%` in calc not resolved |
| `sub` / `sup` | Basic font-size reduction; vertical-align positioning is approximate |

---

## Table Layout Accuracy

hyper_render implements a **2-pass W3C-inspired** column width algorithm:

1. **Pass 1**: Compute per-column min-content and max-content widths using
   Flutter's `getMinIntrinsicWidth` / `getMaxIntrinsicWidth` on each cell.
2. **Pass 2**: Distribute available width proportionally, respecting
   min-content floors.

**Known gaps vs. full W3C auto-layout**:

- `colspan` > 2 distributes min-width equally; W3C allows cells to "claim"
  more from unconstrained neighbours — complex tables with large spans may
  have slightly different column ratios than a browser.
- `table-layout: fixed` is not implemented.
- Percentage widths on cells (`width: 40%`) are not currently propagated.
- Nested tables are supported but may accumulate layout inaccuracies.

---

## Security Model

hyper_render is a **read-only renderer, not a browser**.

- **No JavaScript execution** — `<script>` tags are stripped by the sanitizer.
- **No network access from CSS** — external stylesheets and `@import` are
  not loaded.
- **CSS `expression()`** — IE-era attack blocked by the sanitizer.
- **`vbscript:` URLs** — blocked alongside `javascript:`.
- **`data:image/svg+xml` URLs** — blocked (SVG can embed `<script>`).
- **Event handlers** (`onclick`, `onload`, …) — always stripped.

### What is NOT protected against

- **CSS injection via `customCss`**: content passed to `customCss` is not
  sanitized — only use trusted CSS here.
- **Server-side injection**: sanitize content on the server before it reaches
  the client; `HtmlSanitizer` is a defence-in-depth measure, not a primary
  security boundary.
- **Phishing via links**: `onLinkTap` is called for all `<a>` tags; validate
  URLs in your callback before opening them.

---

## When to Use `fallbackBuilder` / WebView Hybrid

Use `fallbackBuilder` when the content requires features hyper_render cannot
provide:

```dart
HyperViewer(
  html: html,
  fallbackBuilder: HtmlHeuristics.isComplex(html)
      ? (ctx) => WebViewWidget(controller: _wvc)
      : null,
)
```

`HtmlHeuristics.isComplex(html)` returns `true` when the HTML contains:

- Tables with `colspan` / `rowspan` ≥ 3
- `position: absolute` / `fixed`, `z-index`, `clip-path`, multi-column CSS
- `<canvas>`, `<form>`, `<input>`, `<select>`, `<textarea>`, `<script>`
- Streaming media URLs (HLS `.m3u8`, `rtsp:`, `rtmp:`)

---

## Performance

| Scenario | Behaviour |
|----------|-----------|
| Content ≤ 10 KB | Synchronous parse + render on main thread |
| Content > 10 KB | Async parse in `compute()` isolate + `ListView.builder` virtualisation |
| Very large tables (100+ rows) | Linear layout time; prefer server-side pagination |
| `display: none` subtrees | Skipped during layout but still parsed |

---

## Interactive Elements

hyper_render is a **viewer**, not an editor. However, you can use the
**Plugin API (v1.2.0)** to render interactive Flutter widgets for custom tags:

```dart
final registry = HyperPluginRegistry()
  ..register(MyInteractivePlugin()); // Renders <my-form> as a Flutter Form
```

---

## Platform-Specific Notes

- **Web (HTML renderer)**: `SelectionArea` may behave differently from
  native due to Flutter's DOM-based text rendering.
- **iOS 15 and below**: `InteractiveViewer` (zoom mode) may conflict with
  scrolling in some edge cases; test with your target iOS version.
- **Android foldables**: layout updates on fold/unfold correctly via
  Flutter's `LayoutBuilder`.

---

*Last updated: April 29, 2026 — HyperRender v1.2.3*
