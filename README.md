<div align="center">

<img src="https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/logo.png" width="96" alt="HyperRender logo" />

# HyperRender

### The Flutter HTML renderer that actually works.

[![pub.dev](https://img.shields.io/pub/v/hyper_render.svg?label=pub.dev&color=0175C2)](https://pub.dev/packages/hyper_render)
[![pub points](https://img.shields.io/pub/points/hyper_render?label=pub%20points&color=00b4ab)](https://pub.dev/packages/hyper_render/score)
[![likes](https://img.shields.io/pub/likes/hyper_render?color=FF6B6B)](https://pub.dev/packages/hyper_render/score)
[![CI](https://github.com/brewkits/hyper_render/actions/workflows/analyze.yml/badge.svg)](https://github.com/brewkits/hyper_render/actions)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-54C5F8.svg?logo=flutter)](https://flutter.dev)

**60 FPS · 8 MB RAM · CSS float · Ruby typography · XSS-safe by default**

CSS float layout · crash-free text selection · CJK/Furigana · `@keyframes` · Flexbox/Grid<br>
Drop-in replacement for `flutter_html` and `flutter_widget_from_html`.

[**Quick Start**](#-quick-start) · [**Why Switch?**](#-why-switch-the-architecture-argument) · [**API**](#-api-reference) · [**Packages**](#-packages)

</div>

---

## Demos

| CSS Float Layout | Ruby / Furigana | Crash-Free Selection |
|:---:|:---:|:---:|
| ![CSS Float Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/float_demo.gif) | ![Ruby Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/ruby_demo.gif) | ![Selection Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/selection_demo.gif) |
| Text wraps around floated images — no other Flutter HTML renderer does this | Furigana centered above base glyphs, full Kinsoku line-breaking | Select across headings, paragraphs, tables — tested to 100 000 chars |

| Advanced Tables | Head-to-Head | Virtualized Mode |
|:---:|:---:|:---:|
| ![Table Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/table_demo.gif) | ![Comparison Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/comparison_demo.gif) | ![Performance Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/performance_demo.gif) |
| `colspan` · `rowspan` · W3C 2-pass column algorithm | Same HTML in HyperRender vs flutter_widget_from_html | Virtualized rendering — 60 FPS on documents of any length |

---

## Quick Start

```yaml
dependencies:
  hyper_render: ^1.1.3
```

```dart
import 'package:hyper_render/hyper_render.dart';

HyperViewer(
  html: articleHtml,
  onLinkTap: (url) => launchUrl(Uri.parse(url)),
)
```

Zero configuration. XSS sanitization is **on by default**.
Works for articles, emails, docs, newsletters, and CJK content.

---

## Why Switch? The Architecture Argument

Most Flutter HTML libraries map each HTML tag to a Flutter widget. A 3 000-word article becomes **500+ nested widgets** — and some layout primitives simply cannot be expressed that way:

> **CSS `float` is not possible in a widget tree.**
> Wrapping text around a floated image requires every fragment's coordinates before adjacent text can be composed. That geometry only exists when a single `RenderObject` owns the entire layout.

HyperRender renders the whole document inside **one custom `RenderObject`**. Float, crash-free selection, and sub-millisecond binary-search hit-testing all follow from that single design decision.

### Feature Matrix

| Feature | `flutter_html` | `flutter_widget_from_html` | **HyperRender** |
|---|:---:|:---:|:---:|
| `float: left / right` | ❌ | ❌ | ✅ |
| Text selection — large docs | ❌ Crashes | ❌ Crashes | ✅ Crash-free |
| Ruby / Furigana | ❌ Raw text | ❌ Raw text | ✅ |
| `<details>` / `<summary>` | ❌ | ❌ | ✅ Interactive |
| CSS Variables `var()` | ❌ | ❌ | ✅ |
| CSS `@keyframes` | ❌ | ❌ | ✅ |
| Flexbox / Grid | ⚠️ Partial | ⚠️ Partial | ✅ Full |
| Box shadow · `filter` | ❌ | ❌ | ✅ |
| SVG `<img src="*.svg">` | ⚠️ | ⚠️ | ✅ |
| Scroll FPS (25 K-char doc) | ~35 | ~45 | **60** |
| RAM (same doc) | 28 MB | 15 MB | **8 MB** |

### Benchmarks

Measured on iPhone 13 + Pixel 6 with a 25 000-character article:

| Metric | `flutter_html` | `flutter_widget_from_html` | **HyperRender** |
|---|:---:|:---:|:---:|
| Widgets created | ~600 | ~500 | **3–5 chunks** |
| First parse | 420 ms | 250 ms | **95 ms** |
| Peak RAM | 28 MB | 15 MB | **8 MB** |
| Scroll FPS | ~35 | ~45 | **60** |

---

## Features

### CSS Float — Magazine Layouts

```dart
HyperViewer(html: '''
  <article>
    <img src="photo.jpg" style="float:left; width:180px; margin:0 16px 8px 0; border-radius:8px;" />
    <h2>The Art of Layout</h2>
    <p>Text wraps around the image exactly like a browser — because HyperRender
    uses the same block formatting context algorithm.</p>
  </article>
''')
```

### Crash-Free Text Selection

```dart
HyperViewer(
  html: longArticleHtml,
  selectable: true,
  showSelectionMenu: true,
  selectionHandleColor: Colors.blue,
)
```

One continuous span tree. Selection crosses headings, paragraphs, and table cells.
O(log N) binary-search hit-testing stays instant on 1 000-line documents.

### CJK Typography — Ruby / Furigana

```dart
HyperViewer(html: '''
  <p style="font-size:20px; line-height:2;">
    <ruby>東京<rt>とうきょう</rt></ruby>で
    <ruby>日本語<rt>にほんご</rt></ruby>を学ぶ
  </p>
''')
```

Furigana centered above base characters. Kinsoku shori applied across the full line.
Ruby copied to clipboard as `東京(とうきょう)`.

### CSS Variables · Flexbox · Grid

```dart
HyperViewer(html: '''
  <style>
    :root { --brand: #6750A4; --surface: #F3EFF4; }
  </style>
  <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
    <div style="background:var(--brand); color:white; padding:16px; border-radius:12px;">
      Column one — themed with CSS custom properties
    </div>
    <div style="background:var(--surface); padding:16px; border-radius:12px;">
      Column two — same token system
    </div>
  </div>
''')
```

### CSS `@keyframes` Animation

```html
<style>
  @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
  @keyframes slideUp { from { transform: translateY(24px); opacity: 0; }
                       to   { transform: translateY(0);    opacity: 1; } }
  .hero { animation: fadeIn 0.6s ease-out; }
  .card { animation: slideUp 0.4s ease-out; }
</style>
<div class="hero"><h1>Welcome</h1></div>
<div class="card"><p>Animated without any Dart code.</p></div>
```

Parsed from `<style>` tags automatically — supports `opacity`, `transform`, vendor-prefixed variants,
and percentage selectors.

### XSS Sanitization — Safe by Default

```dart
// Safe — strips <script>, on* handlers, javascript: URLs
HyperViewer(html: userGeneratedContent)

// Custom allowlist for stricter sandboxing
HyperViewer(html: userContent, allowedTags: ['p', 'a', 'img', 'strong', 'em'])

// Disable only for fully trusted, internal HTML
HyperViewer(html: trustedCmsHtml, sanitize: false)
```

### Multi-Format Input

```dart
HyperViewer(html: '<h1>Hello</h1><p>World</p>')
HyperViewer.delta(delta: '{"ops":[{"insert":"Hello\\n"}]}')
HyperViewer.markdown(markdown: '# Hello\n\n**Bold** and _italic_.')
```

### Screenshot Export

```dart
final captureKey = GlobalKey();
HyperViewer(html: articleHtml, captureKey: captureKey)

// Export to PNG bytes
final png = await captureKey.toPngBytes();

// Export with custom pixel ratio
final hd = await captureKey.toPngBytes(pixelRatio: 3.0);
```

### Hybrid WebView Fallback

```dart
HyperViewer(
  html: maybeComplexHtml,
  fallbackBuilder: (context) => WebViewWidget(controller: _webViewController),
)
```

---

## API Reference

### `HyperViewer`

```dart
HyperViewer({
  required String html,
  String? baseUrl,           // resolves relative <img src> and <a href>
  String? customCss,         // injected after the document's own <style> tags
  bool selectable = true,
  bool sanitize = true,
  List<String>? allowedTags,
  HyperRenderMode mode = HyperRenderMode.auto, // sync | virtualized | auto
  void Function(String)? onLinkTap,
  HyperWidgetBuilder? widgetBuilder,           // custom widget injection
  WidgetBuilder? fallbackBuilder,
  WidgetBuilder? placeholderBuilder,
  GlobalKey? captureKey,
  bool showSelectionMenu = true,
  String? semanticLabel,
  HyperViewerController? controller,
  void Function(Object, StackTrace)? onError,
})

HyperViewer.delta(delta: jsonString, ...)
HyperViewer.markdown(markdown: markdownString, ...)
```

### `HyperViewerController`

```dart
final ctrl = HyperViewerController();
HyperViewer(html: html, controller: ctrl)

ctrl.jumpToAnchor('section-2');   // scroll to <a name="section-2">
ctrl.scrollToOffset(1200);        // absolute pixel offset
```

### Custom Widget Injection

Replace any HTML element with an arbitrary Flutter widget:

```dart
HyperViewer(
  html: html,
  widgetBuilder: (context, node) {
    if (node is AtomicNode && node.tagName == 'iframe') {
      return YoutubePlayer(url: node.attributes['src'] ?? '');
    }
    return null; // fall back to default rendering
  },
)
```

### `HtmlHeuristics` — Introspect Before Rendering

```dart
if (HtmlHeuristics.isComplex(html)) {
  // use HyperRenderMode.virtualized for long documents
}
HtmlHeuristics.hasComplexTables(html)
HtmlHeuristics.hasUnsupportedCss(html)
HtmlHeuristics.hasUnsupportedElements(html)
```

---

## Architecture

```
HTML / Markdown / Quill Delta
          │
          ▼
   ADAPTER LAYER         HtmlAdapter · MarkdownAdapter · DeltaAdapter
          │
          ▼
  UNIFIED DOCUMENT TREE  BlockNode · InlineNode · AtomicNode
                         RubyNode · TableNode · FlexContainerNode · GridNode
          │
          ▼
    CSS RESOLVER          specificity cascade · var() · calc() · inheritance
          │
          ▼
  SINGLE RenderObject     BFC · IFC · Float · Flexbox · Grid · Table
                          Canvas painting · continuous span tree
                          Kinsoku · O(log N) binary-search selection
```

Key engineering decisions:

- **Single RenderObject** — float layout and crash-free selection require one shared coordinate system; no widget-tree library can provide this
- **O(1) CSS rule lookup** — rules are indexed by tag / class / ID; constant time regardless of stylesheet size
- **O(log N) hit-testing** — `_lineStartOffsets[]` precomputed at layout time; each touch is a binary search, not a linear scan
- **RepaintBoundary per chunk** — each `ListView.builder` chunk gets its own GPU layer; unmodified chunks are composited, not repainted

---

## When NOT to Use

| Need | Better choice |
|------|--------------|
| Execute JavaScript | `webview_flutter` |
| Interactive web forms / input | `webview_flutter` |
| Rich text editing | `super_editor`, `fleather` |
| `position: fixed`, `<canvas>`, media queries | `webview_flutter` (use `fallbackBuilder`) |
| Maximum CSS coverage, float/CJK not required | `flutter_widget_from_html` |

---

## Packages

| Package | pub.dev | Description |
|---------|---------|-------------|
| [`hyper_render`](https://pub.dev/packages/hyper_render) | [![pub](https://img.shields.io/pub/v/hyper_render.svg)](https://pub.dev/packages/hyper_render) | Convenience wrapper — one dependency, everything included |
| [`hyper_render_core`](https://pub.dev/packages/hyper_render_core) | [![pub](https://img.shields.io/pub/v/hyper_render_core.svg)](https://pub.dev/packages/hyper_render_core) | Core engine — UDT model, CSS resolver, RenderObject, design tokens |
| [`hyper_render_html`](https://pub.dev/packages/hyper_render_html) | [![pub](https://img.shields.io/pub/v/hyper_render_html.svg)](https://pub.dev/packages/hyper_render_html) | HTML + CSS parser |
| [`hyper_render_markdown`](https://pub.dev/packages/hyper_render_markdown) | [![pub](https://img.shields.io/pub/v/hyper_render_markdown.svg)](https://pub.dev/packages/hyper_render_markdown) | Markdown adapter |
| [`hyper_render_highlight`](https://pub.dev/packages/hyper_render_highlight) | [![pub](https://img.shields.io/pub/v/hyper_render_highlight.svg)](https://pub.dev/packages/hyper_render_highlight) | Syntax highlighting for `<code>` / `<pre>` blocks |
| [`hyper_render_clipboard`](https://pub.dev/packages/hyper_render_clipboard) | [![pub](https://img.shields.io/pub/v/hyper_render_clipboard.svg)](https://pub.dev/packages/hyper_render_clipboard) | Image copy / share via `super_clipboard` |
| [`hyper_render_devtools`](https://pub.dev/packages/hyper_render_devtools) | [![pub](https://img.shields.io/pub/v/hyper_render_devtools.svg)](https://pub.dev/packages/hyper_render_devtools) | Flutter DevTools extension — UDT inspector, computed styles, demo mode |

---

## Contributing

```bash
git clone https://github.com/brewkits/hyper_render.git
cd hyper_render
flutter pub get
flutter test
dart format --set-exit-if-changed .
flutter analyze --fatal-infos
```

Read the [Architecture Decision Records](doc/adr/) and [Contributing Guide](doc/CONTRIBUTING.md) before submitting a PR.

---

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">

[Get Started](#-quick-start) · [Example App](example/) · [Report a Bug](https://github.com/brewkits/hyper_render/issues) · [pub.dev](https://pub.dev/packages/hyper_render)

</div>
