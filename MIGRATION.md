# Migration Guide

HyperRender **v1.0.0** is the initial stable release. There are no prior public
versions to migrate from.

This document describes the stable public API, notes any patterns from
pre-release builds, and outlines what future versions may change.

---

## v1.0.0 — Stable API

### HyperViewer constructors

```dart
// HTML content
HyperViewer(
  html: '<p>Hello World</p>',
  baseUrl: 'https://example.com',   // optional — resolves relative URLs
  customCss: 'p { color: #333; }',  // optional — injected stylesheet
  sanitize: true,                    // default — DOM-based XSS sanitization
  selectable: true,                  // default — text selection enabled
  debugShowHyperRenderBounds: false, // optional — layout debug overlay
  captureKey: GlobalKey(),           // optional — enables toPngBytes()
)

// Markdown content
HyperViewer.fromMarkdown(
  markdown: '# Hello\n\nWorld',
  captureKey: GlobalKey(),
)

// Quill Delta content
HyperViewer.fromDelta(
  delta: jsonString,
)
```

### Screenshot export

```dart
final key = GlobalKey();

HyperViewer(html: '...', captureKey: key);

// Capture as PNG bytes (e.g. 2× for high-DPI)
final bytes = await key.toPngBytes(pixelRatio: 2.0);

// Or as dart:ui Image
final image = await key.toImage(pixelRatio: 3.0);
```

`HyperCaptureExtension` is exported from `package:hyper_render/hyper_render.dart`.

### CSS features

All features below are supported in v1.0.0:

| Feature | Example |
|---------|---------|
| CSS custom properties | `--brand: #e53935; color: var(--brand)` |
| `var()` with fallback | `color: var(--undefined, #333)` |
| `calc()` arithmetic | `font-size: calc(1rem + 4px)` |
| CSS Grid | `display: grid; grid-template-columns: 1fr 2fr` |
| `repeat()` | `grid-template-columns: repeat(3, 1fr)` |
| `grid-column: span N` | `grid-column: span 2` |
| RTL / BiDi | `direction: rtl` or `dir="rtl"` attribute |
| CSS `!important` | `color: red !important` |
| Inline SVG | `<svg>` elements in HTML content |
| `baseUrl` URL resolution | Relative `href`/`src` resolved against base |
| `customCss` injection | Extra stylesheet applied after document CSS |
| `debugShowHyperRenderBounds` | Blue/orange outlines for layout debugging |

### Sanitization

HTML sanitization is **on by default** (`sanitize: true`). The sanitizer uses
a DOM parser — safer than regex-based approaches.

```dart
// Safe (default) — sanitizes user-provided HTML
HyperViewer(html: userContent)

// Skip sanitization only for HTML you fully control
HyperViewer(html: trustedMarkup, sanitize: false)
```

### CSS rule specificity

The full CSS cascade is applied: user-agent defaults → class/ID rules →
inline styles → `!important` declarations. Custom properties (`--var`) are
inherited along the parent chain.

---

## Pre-release builds

If you used a pre-release (unreleased) build of HyperRender, note these
API stabilizations made before v1.0.0:

- **`HyperViewer` parameter**: Uses `html:` (NOT `content:`). `content` is
  an internal field — do not reference it directly.
- **`HyperAnimatedWidget`**: Uses `animationName:` (String) — not `keyframes:`.
- **`PerformanceMonitor` / `PerformanceReport`**: Only exported from
  `hyper_render_core`, not from the main `hyper_render` package.
- **`RenderHyperBoxSelection`** extension: Selection methods (`getSelectedText`,
  `clearSelection`, etc.) are on this public extension — import
  `package:hyper_render/hyper_render.dart` as usual.

---

## Future versions

The following changes are **planned** for future releases. Nothing is removed
in v1.0.0.

| Area | Planned change |
|------|----------------|
| Background images | `background-image`, `background-size`, `background-position` |
| Pseudo-elements | `::before`, `::after` |
| CSS filters | `filter`, `backdrop-filter` |
| Viewport units | `vh`, `vw` |

---

*Last updated: February 2026 — HyperRender v1.0.0*
