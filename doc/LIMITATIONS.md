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
| `columns` / `column-count` | Multi-column layout not rendered | Use a CSS Grid layout (supported) |

### Supported in v1.2.0 - v1.4.0

| Property | Status |
|----------|--------|
| `box-shadow` | ✅ Multiple shadows, blur, spread supported |
| `text-shadow` | ✅ Multiple shadows, blur supported |
| `filter` / `backdrop-filter` | ✅ blur, brightness, contrast supported |
| `@keyframes` | ✅ Parsed from `<style>` tags automatically |
| `background-image` | ✅ url() and `linear-gradient()` supported |
| `background-size` | ✅ cover, contain, fill supported |
| `background-position` | ✅ Supported since v1.3.1 |
| `background-repeat` | ✅ repeat/repeat-x/repeat-y/no-repeat/space/round supported since v1.3.1 |
| `display: grid` | ✅ full auto-placement, fr-units, and gap support |
| `object-fit` | ✅ cover, contain, fill, none, scale-down supported |
| `list-style-type` / `list-style-position` / `list-style` | ✅ All 11 marker types, shorthand, supported since v1.3.1 |
| `aspect-ratio` | ✅ `W/H` and bare-number syntax, applied to `<img>`/`<video>` sizing (v1.4.0) |
| `transition` | ✅ Animates opacity/transform/color/background-color on style changes via `HyperTransitionWidget` (color added v1.5.0) |
| `animation-iteration-count: infinite` | ✅ Loops via `AnimationController.repeat()`, including `alternate` direction (v1.4.0) |
| `cubic-bezier()` / `steps()` timing functions | ✅ `transition` + `animation` accept `cubic-bezier(x1,y1,x2,y2)`, `steps(n, start\|end)`, `step-start`, `step-end` (v1.5.0) |

### Partial support

| Property | Limitation |
|----------|------------|
| `opacity` | Applied per-element; stacking context opacity not propagated |
| `position: relative` | Supported but child `absolute` positioning is not |
| `calc()` | Arithmetic on px/em/rem only; `%` in calc not resolved |
| `text-align` | LTR center/right on canvas paragraphs; `justify` falls back to left; per-element `direction:rtl` paragraphs keep their default right-alignment |
| `height: %` | Percentage height is not resolved — the single-pass top-down flow doesn't know a parent's resolved height while laying out its children. Use absolute px, or `aspect-ratio`. (`width`/`max-width`/`min-width`/`text-indent` with `%` ARE supported.) |
| `border-spacing` | Not implemented |
| `sub` / `sup` | Basic font-size reduction; vertical-align positioning is approximate |
| Animated `color` / `background-color` | `@keyframes` (`animation-name`) animates both the widget-tier render path AND block-level text painted directly on the `RenderHyperBox` canvas (unreleased). `transition`-driven color changes still only apply on the widget tier — canvas-painted text does not re-tint on a `transition` style change |
| Canvas block-level `animation-name` (`RenderHyperBox`) | Only a block's own decoration + its directly-owned text/ruby fragments participate; list markers, floated images, and a *nested* animated descendant's own animation do not compose with an animating ancestor's opacity/transform (unreleased). **Avoid combining** with an inline `<span style="background:...">` inside the animated block — inline decorations paint after this pass and will visibly cover the animated text, not just fail to animate |

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
| Content > 10 KB | Async parse via `Future.microtask` + `ListView.builder` virtualisation |
| Very large tables (100+ rows) | Linear layout time; prefer server-side pagination |
| `display: none` subtrees | Skipped during layout but still parsed |

### Writing widget tests against large content

`await tester.pumpAndSettle()` **times out** when the content is over the
~10 KB virtualisation threshold and the mode is `auto` (the default). This is
not a rendering failure — it is a consequence of the async parse: the work runs
in a `Future.microtask`, which `pumpAndSettle` does not drive to completion.
The content renders correctly at runtime.

In tests, do one of the following:

```dart
// 1. Let the async parse actually run, then pump.
await tester.pumpWidget(MyWidget());
await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
await tester.pump();

// 2. Or force the synchronous path when the document is small enough to
//    render in one pass and you just want a settled tree.
HyperViewer(html: html, mode: HyperRenderMode.sync)
```

Prefer explicit `pump(duration)` calls over `pumpAndSettle()` for any test that
exercises virtualised or paged mode.

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

*Last updated: June 24, 2026 — HyperRender v1.4.0*
