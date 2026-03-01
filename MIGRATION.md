# Migration Guide — Coming from flutter_html or flutter_widget_from_html?

This guide helps you migrate from `flutter_html` (v3.x) and `flutter_widget_from_html`
(FWFH, v0.17.x) to HyperRender.

---

## Why migrate?

| Pain point | flutter_html | flutter_widget_from_html | HyperRender |
|-----------|:---:|:---:|:---:|
| HTML widgets per document | ~600 | ~500 | **~3–5 render chunks** |
| CSS `float: left/right` | ❌ Impossible | ❌ Impossible | ✅ |
| Text selection on large docs | ⚠️ Slow | ❌ Crashes (v0.17) | ✅ Crash-free |
| `<ruby>/<rt>` Furigana | ❌ Raw text | ❌ Not supported | ✅ |
| `<details>/<summary>` | ❌ | ❌ | ✅ Interactive |
| CSS Variables + `calc()` | ❌ | ❌ | ✅ |

If you need `float`, CJK typography, or crash-free selection — this migration
pays for itself immediately. If you need maximum CSS decoration coverage
and don't need those features, FWFH may still be appropriate.

---

## Drop-in replacement (5 minutes)

### From `flutter_html`

```dart
// Before (flutter_html)
Html(data: htmlString)

// After (HyperRender)
HyperViewer(html: htmlString)
```

### From `flutter_widget_from_html` (HtmlWidget)

```dart
// Before (FWFH)
HtmlWidget(htmlString)

// After (HyperRender)
HyperViewer(html: htmlString)
```

Both libraries use positional `String` as their first argument. HyperRender
requires a named `html:` parameter — that is the only mandatory change.

---

## Common parameter mappings

### Link tap handler

```dart
// flutter_html
Html(
  data: html,
  onLinkTap: (url, _, __) => launchUrl(Uri.parse(url!)),
)

// FWFH
HtmlWidget(html, onTapUrl: (url) => launchUrl(Uri.parse(url)))

// HyperRender
HyperViewer(
  html: html,
  onLinkTap: (url) => launchUrl(Uri.parse(url)),
)
```

### Custom widget for specific tags

```dart
// flutter_html
Html(
  data: html,
  extensions: [TagExtension(tagsToExtend: {'iframe'}, builder: (ctx) => ...)],
)

// FWFH
HtmlWidget(
  html,
  customWidgetBuilder: (element) {
    if (element.localName == 'iframe') return MyWidget();
    return null;
  },
)

// HyperRender
HyperViewer(
  html: html,
  widgetBuilder: (node) {
    if (node is AtomicNode && node.tagName == 'iframe') return MyWidget();
    return null;  // fall through to default rendering
  },
)
```

### Text styles / CSS injection

```dart
// flutter_html — custom style map
Html(
  data: html,
  style: {
    'p': Style(fontSize: FontSize(16)),
    'h1': Style(color: Colors.indigo),
  },
)

// FWFH — custom stylesheet
HtmlWidget(html, customStylesBuilder: (element) {
  if (element.localName == 'p') return 'font-size: 16px';
  return null;
})

// HyperRender — inject a CSS string (full cascade, specificity respected)
HyperViewer(
  html: html,
  customCss: '''
    p  { font-size: 16px; line-height: 1.7; }
    h1 { color: #3F51B5; }
    a  { color: #6750A4; }
  ''',
)
```

---

## Feature-specific migration

### Float layout (NEW — not possible in flutter_html/FWFH)

```dart
// This just works in HyperRender. No migration needed — it was never possible before.
HyperViewer(
  html: '''
    <img src="photo.jpg" style="float: left; width: 200px; margin: 0 16px 8px 0;" />
    <p>Text wraps naturally around the image — magazine style.</p>
  ''',
)
```

### Text selection

```dart
// flutter_html — limited, no copy menu
Html(data: html, selectable: true)

// FWFH v0.17 — no built-in selection; wrapping in SelectionArea crashes on
// large documents because selection spans multiple independent RichText nodes
HtmlWidget(html, enableCaching: true) // no selection support

// HyperRender — crash-free, copy menu included
HyperViewer(
  html: html,
  selectable: true,           // default: true
  selectionHandleColor: Colors.blue,
  // Customise context-menu actions:
  selectionMenuActionsBuilder: (controller) => [
    SelectionMenuAction(label: 'Copy', onPressed: controller.copySelection),
  ],
)
```

### Sanitization

```dart
// flutter_html — no built-in sanitization
Html(data: userContent)  // XSS risk

// FWFH — no built-in sanitization
HtmlWidget(userContent)  // XSS risk

// HyperRender — sanitized by default
HyperViewer(html: userContent)  // ✅ safe: sanitize: true is the default

// Opt-out only for fully trusted, backend-controlled HTML:
HyperViewer(html: trustedCmsHtml, sanitize: false)
```

### Markdown / Delta input

```dart
// HyperRender supports multiple formats — no separate package needed
HyperViewer.markdown(markdown: '# Hello\n\n**Bold** _italic_.')
HyperViewer.delta(delta: '{"ops":[{"insert":"Hello\\n"}]}')
```

---

## What HyperRender does NOT support (yet)

Be aware of these before migrating critical features:

| Feature | Status | Workaround |
|---------|:------:|-----------|
| `position: absolute/fixed` | 🚧 Planned | `fallbackBuilder` → WebView |
| `z-index` stacking | 🚧 Planned | n/a |
| `clip-path` | 🚧 Planned | n/a |
| `<canvas>` | ❌ Never (not a browser) | `widgetBuilder` injection |
| `<form>`, `<input>` | ❌ | `widgetBuilder` injection |
| JavaScript execution | 🔮 Planned (QuickJS, vanilla JS only) | `fallbackBuilder` → WebView |

For complex HTML that uses these, use `HtmlHeuristics` to detect and
fall back to a WebView automatically:

```dart
HyperViewer(
  html: maybeComplexHtml,
  fallbackBuilder: (context) => WebViewWidget(controller: _webViewController),
)
```

---

## HyperViewer v1.0.0 stable API

```dart
HyperViewer({
  required String html,
  String? baseUrl,             // Resolve relative URLs
  String? customCss,           // Injected stylesheet (after document styles)
  bool selectable = true,
  bool sanitize = true,
  List<String>? allowedTags,   // Custom allowlist for sanitize: true
  bool allowDataAttributes = false,
  HyperRenderMode mode = HyperRenderMode.auto,
  Function(String)? onLinkTap,
  HyperWidgetBuilder? widgetBuilder,         // Widget? Function(UDTNode node)
  WidgetBuilder? fallbackBuilder,            // Called when HtmlHeuristics.isComplex()
  GlobalKey? captureKey,                     // Screenshot export via HyperCaptureExtension
  bool enableZoom = false,
  double minScale = 0.5,
  double maxScale = 4.0,
  List<SelectionMenuAction> Function(SelectionOverlayController)? selectionMenuActionsBuilder,
  Color? selectionHandleColor,
  Color? selectionColor,
  WidgetBuilder? placeholderBuilder,
  String? semanticLabel,
  bool excludeSemantics = false,
  bool debugShowHyperRenderBounds = false,
})

HyperViewer.markdown(markdown: '# Hello', ...)
HyperViewer.delta(delta: jsonString, ...)
```

> **Note:** Named constructors are `.markdown()` and `.delta()` — NOT `.fromMarkdown()` /
> `.fromDelta()` (those never existed in stable).

---

## Pre-release → v1.0.0 API stabilizations

If you used an unreleased/dev build, note these changes:

| Old (pre-release) | Stable (v1.0.0) |
|-------------------|-----------------|
| `HyperViewer(content: ...)` | `HyperViewer(html: ...)` |
| `HyperAnimatedWidget(keyframes: ...)` | `HyperAnimatedWidget(animationName: ...)` |
| `HyperViewer.fromMarkdown(...)` | `HyperViewer.markdown(...)` |
| `HyperViewer.fromDelta(...)` | `HyperViewer.delta(...)` |
| `PerformanceMonitor` from main pkg | Only in `hyper_render_core` |

---

## Planned future versions

| Area | Planned change |
|------|----------------|
| `position: absolute/fixed` | Planned — positioning context |
| Vanilla JS (show/hide, form validation) | Planned — QuickJS via Dart FFI |
| `clip-path` polygon / circle | Planned |
| `::before` / `::after` pseudo-elements | Planned |
| `filter` / `backdrop-filter` | Planned |
| `vh` / `vw` viewport units | Planned |
| Full SVG renderer | In progress |

---

*Last updated: February 2026 — HyperRender v1.0.0*
