<div align="center">

# HyperRender

**The only Flutter HTML renderer with CSS float layout.**

[![pub package](https://img.shields.io/pub/v/hyper_render.svg)](https://pub.dev/packages/hyper_render)
[![pub points](https://img.shields.io/pub/points/hyper_render)](https://pub.dev/packages/hyper_render/score)
[![pub likes](https://img.shields.io/pub/likes/hyper_render)](https://pub.dev/packages/hyper_render/score)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-54C5F8.svg)](https://flutter.dev)
[![CI](https://github.com/brewkits/hyper_render/actions/workflows/analyze.yml/badge.svg)](https://github.com/brewkits/hyper_render/actions)

Renders HTML, Markdown, and Quill Delta via a **single custom RenderObject** — not a widget tree.
Drop-in replacement for `flutter_html` and `flutter_widget_from_html`.
60 FPS · 8 MB RAM · CSS float · CJK typography · zero JS.

[**Quick Start**](#-quick-start) · [**Why Switch?**](#-why-switch) · [**API**](#-api-reference) · [**Packages**](#-packages)

</div>

---

## ⚡ Quick Start

```yaml
dependencies:
  hyper_render: ^1.1.2
```

```dart
import 'package:hyper_render/hyper_render.dart';

HyperViewer(
  html: articleHtml,
  onLinkTap: (url) => launchUrl(Uri.parse(url)),
)
```

Zero configuration. XSS sanitization is **on by default**. Works for articles, emails, docs, and CJK content.

---

## 🎬 See It In Action

| CSS Float — Magazine Layout | Ruby / Furigana | Crash-Free Text Selection |
|:---:|:---:|:---:|
| ![CSS Float Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/float_demo.gif) | ![Ruby Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/ruby_demo.gif) | ![Selection Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/selection_demo.gif) |
| Text flows around floated images — no other Flutter HTML library does this | Furigana centered above base glyphs with Kinsoku line-breaking | Select across headings, paragraphs, tables — tested to 100K chars |

| Advanced Tables | vs. flutter_widget_from_html | Virtualized Mode |
|:---:|:---:|:---:|
| ![Table Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/table_demo.gif) | ![Comparison Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/comparison_demo.gif) | ![Performance Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/performance_demo.gif) |
| colspan · rowspan · W3C 2-pass column algorithm | Same HTML rendered side by side | Only visible sections are built — smooth at any length |

---

## 🔀 Why Switch?

Most Flutter HTML libraries map each tag to a widget — a 3,000-word article becomes 500+ nested widgets:

| Feature | flutter_html / FWFH | HyperRender |
|---|:---:|:---:|
| `float: left/right` | ❌ Impossible | ✅ |
| Text selection (large docs) | ❌ Crashes | ✅ Crash-free |
| Ruby / Furigana | ❌ Raw text | ✅ |
| `<details>` / `<summary>` | ❌ | ✅ Interactive |
| CSS Variables `var()` | ❌ | ✅ |
| Flexbox / Grid | ⚠️ Partial | ✅ Full |
| Box shadow · filters | ❌ | ✅ |
| Scroll FPS (25K-char doc) | ~35–45 | **60** |
| RAM usage | 15–28 MB | **~8 MB** |

**Float cannot be bolted onto a widget tree.** Wrapping text around a floated image requires every fragment's coordinates before composing adjacent text — a geometry that only exists when one RenderObject owns the whole layout.

---

## ✨ Features

### CSS Float — Magazine Layouts

```dart
HyperViewer(html: '''
  <article>
    <img src="photo.jpg" style="float:left; width:180px; margin:0 16px 8px 0; border-radius:8px;" />
    <h2>Magazine Layout</h2>
    <p>Text flows around the image — exactly like a browser.</p>
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

One continuous span tree — selection across headings, paragraphs, and table cells. O(log N) binary search hit-testing stays instant on 1,000-line documents.

### Professional CJK Typography

```dart
HyperViewer(html: '''
  <p style="font-size:20px; line-height:2;">
    <ruby>東京<rt>とうきょう</rt></ruby>で
    <ruby>日本語<rt>にほんご</rt></ruby>を学ぶ
  </p>
''')
```

Furigana centered above base characters. Kinsoku shori applied across the full line. Ruby copied to clipboard as `東京(とうきょう)`.

### CSS Variables · Flexbox · Grid

```dart
HyperViewer(html: '''
  <style>:root { --brand: #6750A4; }</style>
  <div style="background:var(--brand); padding:16px; border-radius:12px; color:white;">
    Themed with CSS custom properties
  </div>
''')
```

### Multi-Format Input

```dart
HyperViewer(html: '<h1>Hello</h1><p>World</p>')
HyperViewer.delta(delta: '{"ops":[{"insert":"Hello\\n"}]}')
HyperViewer.markdown(markdown: '# Hello\n\n**Bold** and _italic_.')
```

### XSS Sanitization — Safe by Default

```dart
// ✅ Safe — strips <script>, on* handlers, javascript: URLs
HyperViewer(html: userGeneratedContent)

// ✅ Custom allowlist
HyperViewer(html: userContent, allowedTags: ['p', 'a', 'img', 'strong', 'em'])

// ⚠️ Disable only for trusted internal HTML
HyperViewer(html: trustedCmsHtml, sanitize: false)
```

### Visual Effects

Glassmorphism · Box & text shadows · CSS `filter` · `linear-gradient` · Dashed/dotted borders · High-DPI images

### CSS `@keyframes` Animation

```html
<style>
  @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
  .hero { animation: fadeIn 0.6s ease-out; }
</style>
<div class="hero">Animated content</div>
```

### Hybrid WebView Fallback

```dart
HyperViewer(
  html: maybeComplexHtml,
  fallbackBuilder: (context) => WebViewWidget(controller: _ctrl),
)
```

### Screenshot Export

```dart
final key = GlobalKey();
HyperViewer(html: articleHtml, captureKey: key)
final png = await key.toPngBytes();
```

---

## 📊 Benchmarks

Measured on iPhone 13 + Pixel 6 with a 25,000-character article:

| Metric | flutter_html | flutter_widget_from_html | HyperRender |
|--------|:---:|:---:|:---:|
| Widgets created | ~600 | ~500 | **3–5 chunks** |
| Parse time | 420 ms | 250 ms | **95 ms** |
| RAM | 28 MB | 15 MB | **8 MB** |
| Scroll FPS | ~35 | ~45 | **60** |

---

## 📖 API Reference

### `HyperViewer`

```dart
HyperViewer({
  required String html,
  String? baseUrl,
  String? customCss,
  bool selectable = true,
  bool sanitize = true,
  List<String>? allowedTags,
  HyperRenderMode mode = HyperRenderMode.auto,  // sync | virtualized | auto
  Function(String)? onLinkTap,
  HyperWidgetBuilder? widgetBuilder,
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

ctrl.jumpToAnchor('section-2');
ctrl.scrollToOffset(1200);
```

### Custom Widget Injection

```dart
HyperViewer(
  html: html,
  widgetBuilder: (context, node) {
    if (node is AtomicNode && node.tagName == 'iframe') {
      return YoutubePlayer(url: node.attributes['src'] ?? '');
    }
    return null;
  },
)
```

### `HtmlHeuristics`

```dart
HtmlHeuristics.isComplex(html)
HtmlHeuristics.hasComplexTables(html)
HtmlHeuristics.hasUnsupportedCss(html)
HtmlHeuristics.hasUnsupportedElements(html)
```

---

## 🏗️ Architecture

```
HTML / Delta / Markdown
        │
        ▼
   ADAPTER LAYER      ← HtmlAdapter · DeltaAdapter · MarkdownAdapter
        │
        ▼
UNIFIED DOCUMENT TREE ← BlockNode · InlineNode · AtomicNode · RubyNode
                         TableNode · FlexContainerNode · GridNode
        │
        ▼
  CSS RESOLVER        ← specificity cascade · var() · calc() · inheritance
        │
        ▼
SINGLE RenderObject   ← BFC · IFC · Flexbox · Grid · Table · Float
                         Canvas painting · continuous span tree
                         Kinsoku · O(log N) selection
```

- **Single RenderObject** — float and crash-free selection require one coordinate system
- **O(1) CSS rule lookup** — indexed by tag/class/ID, constant-time regardless of stylesheet size
- **O(log N) text selection** — `_lineStartOffsets[]` precomputed at layout; binary search per touch
- **RepaintBoundary per chunk** — each `ListView.builder` chunk has its own GPU layer
- **Layout regression CI** — 6 fixtures with hard 16 ms (60 FPS) budgets fail the build on regression

---

## ⚠️ When NOT to Use

| Need | Better Choice |
|------|--------------|
| Execute JavaScript | `webview_flutter` |
| Interactive web forms | `webview_flutter` |
| Rich text editing | `super_editor`, `fleather` |
| `position: fixed` / `canvas` | `webview_flutter` via `fallbackBuilder` |
| Max CSS coverage, no float/CJK | `flutter_widget_from_html` |

---

## 📦 Packages

| Package | Purpose |
|---------|---------|
| [`hyper_render`](https://pub.dev/packages/hyper_render) | Convenience wrapper — one dependency for everything |
| [`hyper_render_core`](https://pub.dev/packages/hyper_render_core) | UDT model, CSS resolver, design tokens |
| [`hyper_render_html`](https://pub.dev/packages/hyper_render_html) | HTML adapter |
| [`hyper_render_markdown`](https://pub.dev/packages/hyper_render_markdown) | Markdown adapter |
| [`hyper_render_highlight`](https://pub.dev/packages/hyper_render_highlight) | Syntax highlighting for `<code>` |
| [`hyper_render_clipboard`](https://pub.dev/packages/hyper_render_clipboard) | Image copy / share |
| [`hyper_render_devtools`](https://pub.dev/packages/hyper_render_devtools) | Flutter DevTools extension — UDT inspector, computed style panel, demo mode |

---

## 🤝 Contributing

```bash
git clone https://github.com/brewkits/hyper_render.git
cd hyper_render && flutter pub get
flutter test
dart format --set-exit-if-changed .
flutter analyze --fatal-infos
```

Read the [Architecture Decision Records](doc/adr/) and [Contributing Guide](doc/CONTRIBUTING.md) before submitting a PR.

---

## 📄 License

MIT — see [LICENSE](LICENSE).

---

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=brewkits/hyper_render&type=Date)](https://star-history.com/#brewkits/hyper_render&Date)

[Get Started](#-quick-start) · [Demo App](example/) · [Report a Bug](https://github.com/brewkits/hyper_render/issues) · [pub.dev](https://pub.dev/packages/hyper_render)

</div>
