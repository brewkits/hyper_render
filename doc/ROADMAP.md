# HyperRender — Product Roadmap

**Last Updated**: 2026-03-25
**Current Stable**: v1.1.4
**Repository**: [github.com/brewkits/hyper_render](https://github.com/brewkits/hyper_render)

This document tracks the long-term direction of the HyperRender ecosystem.
For detailed CSS property tracking, see [`internal/CSS_SUPPORT_ROADMAP.md`](internal/CSS_SUPPORT_ROADMAP.md).

---

## Completed — v1.0 → v1.1.2

- Single `RenderObject` pipeline (Parse → Style → Layout → Paint)
- Float layout algorithm (`float: left/right`, `clear`) — unique advantage over FWFH
- Isolate-based HTML parsing (non-blocking UI thread)
- `ListView.builder` virtualization (low RAM on large documents)
- Full Flexbox support (90% coverage: direction, wrap, gap, align, grow/shrink/basis)
- CSS Variables `var()`, `transition`, `animation-*` parsing
- Ruby / Furigana, Kinsoku line-breaking (CJK typography)
- Crash-free text selection across the entire document
- **O(log N) binary-search hit-testing** — `_lineStartOffsets[]` precomputed at layout; selection instant on 1,000-line documents
- **Ruby clipboard format** — fully-selected ruby fragment copied as `base(ふりがな)`; partial selection copies base text only
- Interactive `<details>` / `<summary>`
- Multimedia error boundaries via `_safeWidgetBuilder`
- CSS Box Shadow, linear-gradient, retina image rendering
- Adaptive text selection colors (iOS / Material)
- CSS Grid layout (`display:grid` — full row/column track sizing, `gap`, span)
- RTL / bidirectional text (Arabic, Hebrew, Persian via `direction: rtl`)
- **CSS `@keyframes` execution** (v1.1.2) — `opacity`, `transform` (translate, scale, rotate); `from`/`to` and percentage selectors; vendor prefixes
- Modular package architecture: `hyper_render_core`, `hyper_render_html`,
  `hyper_render_markdown`, `hyper_render_highlight`, `hyper_render_clipboard`
- **`hyper_render_devtools` v1.0.0** — UDT Tree inspector, Computed Style panel, Float region visualizer, demo mode (no live app required); published to pub.dev
- **Golden test coverage** — Float layout, RTL/BiDi, CJK + Ruby suites pinned to ubuntu-22.04 + Flutter 3.29.2 + Noto fonts for pixel-stable CI
- **Layout regression CI guard** — 6 fixtures (simple paragraph → 100-paragraph article) with hard 16 ms (60 FPS) thresholds; any regression fails the PR build
- **3-pipeline CI architecture** — Pre-flight (format + analyze, < 2 min) · Core Validation (per-package selective tests on PR, full 3-OS × 2-channel matrix on push) · Visual/Performance gates (golden + benchmark)

---

## v1.2 — Stability & CSS Polish (updated 2026-03-24)

### Cross-Chunk Float Carryover

**Source**: Reviewer feedback — float layout correctness in virtualized mode
**Priority**: Medium — affects layout density for tall floated images in long documents

**Current behaviour**: When `parseToSections()` splits a document into chunks, each
chunk gets its own `RenderHyperBox` with an independent float list. If a block in
Chunk N contains a tall floated image (taller than the accompanying text), the engine
correctly renders the full image by extending Chunk N's height to `float.rect.bottom`
(see `render_hyper_box.dart` lines 963-967). The image is never visually truncated.

However, the empty space to the right of the float's lower portion is wasted: text
from Chunk N+1 starts below the float at full width instead of filling that space.

**Mitigation shipped (v1.1)**: `HtmlAdapter._containsFloatChild` parse-time guard —
sections are never split immediately after a float-bearing block, keeping the float
and its immediately following text in the same chunk.  This eliminates the wasted-space
problem for the most common case (short paragraphs after a float).

**Remaining gap**: If accumulated text before the float exceeds the chunk threshold,
or the document has a float very close to the chunk boundary, the guard can be
insufficient and wasted space still occurs.

**Full fix** requires:
1. Computing `naturalTextHeight` (height without float extension) in `performLayout`.
2. If `float.rect.bottom > naturalTextHeight`, emit a `FloatCarryover` record
   (`direction`, `width`, `remainingHeight`, `imagePixelOffset`).
3. Reduce Chunk N's `size.height` to `naturalTextHeight` (float is clipped at the
   chunk boundary — this is the trade-off).
4. Chunk N+1 receives the `FloatCarryover` via `HyperRenderWidget.initialFloats`
   and seeds `_leftFloats`/`_rightFloats` in `_performLineLayout` so text wraps.
5. The float image in Chunk N+1 must be painted from `imagePixelOffset` to render
   only the "remaining" portion without repeating the already-visible top.

**Trade-off**: Step 3 clips the float image at the chunk boundary, which may look
jarring for large images. A workaround is to increase `chunkSize` so fewer splits
occur near floats.

Scope:
- [ ] Add `FloatCarryover` data class to `render_hyper_box_types.dart`
- [ ] Add `danglingFloats` getter to `RenderHyperBox`
- [ ] Add `initialFloats` parameter to `RenderHyperBox` / `HyperRenderWidget`
- [ ] Seed initial floats in `_performLineLayout`
- [ ] Wire `FloatCarryover` callbacks through `VirtualizedChunk` → `HyperViewer`
- [ ] Add offset rendering support in `_paintFloatImages` for image floats
- [ ] Integration test: tall float at chunk boundary shows no wasted space

---

## v1.2 — Stability & CSS Polish

**Theme**: Close remaining CSS gaps; improve runtime safety on low-memory devices.

### Memory Pressure Handling

**Source**: Expert review recommendation
**Priority**: High — directly impacts stability on low-end devices (2 GB RAM)

The image cache is currently tuned manually. `WidgetsBindingObserver` should be
integrated so HyperRender automatically evicts caches when the OS signals memory pressure.

```dart
class HyperRenderController with WidgetsBindingObserver {
  @override
  void didHaveMemoryPressure() {
    imageCache.evictAll();        // Flutter image cache
    _internalSpanCache.clear();   // HyperRender internal span cache
    super.didHaveMemoryPressure();
  }
}
```

Scope:
- [ ] Implement `WidgetsBindingObserver` in `HyperRenderController`
- [ ] Expose `onMemoryPressure` callback for host-app customization
- [ ] Debug-mode metrics: eviction count, bytes freed
- [ ] Smoke test on a 2 GB RAM device

### CSS Phase 3 — Visual Polish

Properties deferred from Phase 3 in [`internal/CSS_SUPPORT_ROADMAP.md`](internal/CSS_SUPPORT_ROADMAP.md):

- [ ] `text-shadow` — high visual impact, 1-day effort
- [ ] `text-overflow: ellipsis` — extremely common, 4-hour effort
- [ ] `box-shadow` — design system compatibility
- [ ] `list-style-type`, `list-style-position` — better `<ul>` / `<ol>` rendering
- [ ] `word-break`, `overflow-wrap` — CJK and long-URL handling
- [ ] `background-repeat`, `background-position`, `background-size`

---

## v2.0 — Plugin Ecosystem

**Theme**: Extract multimedia into a standalone plugin; ship the first working
DevTools panels; begin true CSS animation execution.

### hyper_render_media — Standalone Package

**Source**: Expert review + internal v3.0 plan (promoted to v2.0)
**Priority**: High — keeps core lean; enables independent versioning of media layer

The core library currently bundles multimedia support (`video_player`, `webview`
via `WidgetBuilder`). Splitting this into `hyper_render_media` means teams that only
need HTML/Markdown do not pull in heavy media dependencies.

Target package structure:

```
packages/
  hyper_render_core/       # UDT model, CSS engine, layout — zero external deps
  hyper_render_html/       # HTML adapter
  hyper_render_markdown/   # Markdown adapter
  hyper_render_clipboard/  # Selection & clipboard
  hyper_render_highlight/  # Syntax highlighting
  hyper_render_media/      # NEW: video, audio, iframe, custom widget injection
  hyper_render_devtools/   # DevTools extension (existing, being completed)
```

Scope:
- [ ] Define `MultimediaWidgetBuilder` protocol interface in `hyper_render_core`
- [ ] Move `_safeWidgetBuilder` and media error boundaries to `hyper_render_media`
- [ ] Publish `hyper_render_media` to pub.dev
- [ ] Update example app to use the new package
- [ ] Write migration guide for existing users

### CSS Animation Execution (Stateful HTML)

**Source**: Expert review — "make content feel alive"
**Priority**: Medium

**v1.1.2**: `@keyframes` fully parsed and **executed** — `opacity`, `transform` (translate, scale, rotate), `from`/`to` and `%` selectors, vendor prefixes, `HyperAnimatedWidget.keyframesLookup`.

Remaining v2.0 scope:
- [ ] Wire `AnimationController` into the render cycle for `transition` (parsed but not yet executed)
- [ ] Animatable properties beyond `opacity`/`transform`: `color`, `background-color`
- [ ] Timing functions: `ease`, `linear`, `ease-in-out`, `cubic-bezier()`
- [ ] Repaint only the animated region — do not rebuild the full span tree
- [ ] Trigger mechanism: class toggle via public API (hover on web/desktop)
- [ ] Out of scope for v2.0: layout animations (`width`, `height`), `clip-path` animation

### hyper_render_devtools — v2.x Improvements

**Status**: ✅ v1.0.0 shipped — UDT Tree inspector, Computed Style panel, Float region visualizer, demo mode

Remaining v2.x scope:
- [ ] Performance timeline overlay (layout + paint timing per chunk)
- [ ] Live CSS variable inspector (edit `--var` values and see instant re-render)
- [ ] Selection debug panel (show fragment boundaries, ruby offsets)
- [ ] Export UDT snapshot to JSON for offline analysis

---

## v2.x — Export Engine

**Theme**: Allow rendered content to be captured as PDF or high-resolution images.

### hyper_render_export — New Package

**Source**: Expert review — "Screencapture engine"
**Priority**: Medium — high business value for e-reader and documentation apps

```dart
final exporter = HyperRenderExporter(controller);

// Export to PDF
final pdfBytes = await exporter.toPdf(
  pageSize: PdfPageFormat.a4,
  includeLinks: true,
);

// Export to image
final imageBytes = await exporter.toImage(
  pixelRatio: 3.0,
  format: ImageFormat.png,
);
```

Scope:
- [ ] New package `hyper_render_export` (separate to avoid bloating core)
- [ ] Full-document image capture (scroll + stitch multiple frames)
- [ ] PDF pagination with CSS `page-break` hints
- [ ] Hyperlink preservation in PDF output
- [ ] Progress callback for long documents
- [ ] Dependencies: `pdf` (dart-pdf), Flutter `RenderObject.toImage()`

---

## Backlog

Items under consideration, not yet scheduled:

| Item | Notes |
|------|-------|
| `position: absolute / fixed / sticky` | Complex with single-RenderObject model |
| `clip-path`, `filter` | Advanced visual effects |
| `object-fit` for `<img>` | Requires changes to image layout pass |
| `aspect-ratio` | Responsive media sizing |
| Server-side UDT snapshot | Pre-render on server, hydrate on client |

---

## Guiding Principles

1. **Stability first** — bug fixes and memory safety before new features.
2. **Core stays lean** — substantial features ship as separate packages.
3. **No performance regression** — all benchmarks must pass before each release.
4. **Test coverage** — every new feature requires unit tests and an `example/` demo.
5. **Backward compatibility** — breaking changes only at major version bumps.

---

## Related Documents

- [CSS Support Roadmap](internal/CSS_SUPPORT_ROADMAP.md) *(internal)*
- [Architecture Decision Records](adr/)
- [Plugin Development Guide](PLUGIN_DEVELOPMENT.md)
- [Contributing Guide](CONTRIBUTING.md)
- [Changelog](../CHANGELOG.md)
