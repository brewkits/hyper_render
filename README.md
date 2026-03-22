<div align="center">

# HyperRender

**The only Flutter HTML renderer with CSS float layout.**

[![pub package](https://img.shields.io/pub/v/hyper_render.svg)](https://pub.dev/packages/hyper_render)
[![pub points](https://img.shields.io/pub/points/hyper_render)](https://pub.dev/packages/hyper_render/score)
[![pub likes](https://img.shields.io/pub/likes/hyper_render)](https://pub.dev/packages/hyper_render/score)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-54C5F8.svg)](https://flutter.dev)

Renders HTML, Markdown, and Quill Delta using a **single custom RenderObject** — not a widget tree.
Drop-in replacement for `flutter_html` and `flutter_widget_from_html`. Ships with CSS float, Flexbox, Grid, CJK typography, crash-free text selection, and zero JS dependencies.

[**Quick Start**](#-quick-start) · [**Why Switch?**](#-why-switch-from-fwfh--flutter_html) · [**Features**](#-features) · [**API**](#-api-reference) · [**Benchmarks**](#-benchmarks)

</div>

---

## ⚡ Quick Start

```yaml
dependencies:
  hyper_render: ^1.1.0
```

```dart
import 'package:hyper_render/hyper_render.dart';

// Works. Sanitization is ON by default — safe for user content.
HyperViewer(
  html: articleHtml,
  onLinkTap: (url) => launchUrl(Uri.parse(url)),
)
```

That's it. No configuration required. Works for news articles, emails, documentation, and CJK content out of the box.

---

## 🎬 See It In Action

| CSS Float — Magazine Layout | Ruby / Furigana | Crash-Free Text Selection |
|:---:|:---:|:---:|
| ![CSS Float Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/float_demo.gif) | ![Ruby Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/ruby_demo.gif) | ![Selection Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/selection_demo.gif) |
| Text flows around floated images — no other Flutter HTML library can do this | Furigana centered above base glyphs with full Kinsoku line-breaking | Select across headings, paragraphs, and table cells — tested to 100K chars |

| Advanced Tables | vs. flutter_widget_from_html | Virtualized Mode |
|:---:|:---:|:---:|
| ![Table Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/table_demo.gif) | ![Comparison Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/comparison_demo.gif) | ![Performance Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/performance_demo.gif) |
| colspan, rowspan, auto-scaling, W3C 2-pass column algorithm | Same HTML — side by side | Only visible sections are built and painted — smooth at any document length |

---

## 🔀 Why Switch from FWFH / flutter_html?

Most Flutter HTML libraries map each tag to a Flutter widget — `Column`, `Row`, `Padding`, `Wrap`, `RichText`. A 3,000-word article becomes 500+ deeply nested widgets, and then:

| What you need | flutter_html / FWFH | HyperRender |
|---|:---:|:---:|
| `float: left/right` | ❌ Impossible | ✅ |
| Text selection (large docs) | ❌ Crashes | ✅ Crash-free |
| Ruby / Furigana | ❌ Shows raw text | ✅ |
| `<details>/<summary>` | ❌ | ✅ Interactive |
| CSS Variables `var()` | ❌ | ✅ |
| Flexbox / Grid | ⚠️ Partial | ✅ Full |
| Box shadow & filters | ❌ | ✅ |
| Scroll FPS (25K-char article) | ~35–45 fps | **60 fps** |
| RAM usage | 15–28 MB | **~8 MB** |

**Float is not a missing feature you can add.** To wrap text around a floated image, the layout engine needs every fragment's coordinates before composing the adjacent text. A widget tree where each `Column` owns its own layout simply cannot share that geometry — there is no algorithm that fixes this without replacing the widget tree entirely.

That is exactly what HyperRender does: **one RenderObject, one coordinate system, one layout pass.**

---

## ✨ Features

### 🌟 CSS Float — Magazine Layouts

```dart
HyperViewer(
  html: '''
    <article>
      <img src="photo.jpg"
           style="float: left; width: 180px; margin: 0 16px 8px 0; border-radius: 8px;" />
      <h2>Magazine Layout</h2>
      <p>This text flows around the floated image — exactly like a real browser.
         No other Flutter library can render this correctly.</p>
    </article>
  ''',
)
```

---

### ✅ Crash-Free Text Selection

```dart
HyperViewer(
  html: longArticleHtml,
  selectable: true,              // default
  showSelectionMenu: true,       // Copy / Select All
  selectionHandleColor: Colors.blue,
)
```

One continuous span tree = selection across headings, paragraphs, and table cells.
Tested to **100,000-character documents** in CI without crashes.

---

### 🈶 Professional CJK Typography

```dart
HyperViewer(
  html: '''
    <p style="font-size: 20px; line-height: 2;">
      <ruby>東京<rt>とうきょう</rt></ruby>で
      <ruby>日本語<rt>にほんご</rt></ruby>を学ぶ
    </p>
  ''',
)
```

Furigana renders **centered above** base characters. Kinsoku shori (line-breaking rules)
applied across the full line — not truncated at widget boundaries like every other library.

---

### 🎨 CSS Variables, Flexbox, Grid

```dart
// CSS custom properties
HyperViewer(html: '''
  <style>
    :root { --brand: #6750A4; --gap: 16px; }
    .card { background: var(--brand); padding: calc(var(--gap) * 1.5);
            border-radius: 12px; color: white; }
  </style>
  <div class="card">Themed with CSS custom properties</div>
''')

// Flexbox navigation bar
HyperViewer(html: '''
  <div style="display: flex; justify-content: space-between;
              align-items: center; gap: 16px; background: #1976D2;
              padding: 12px; border-radius: 8px; color: white;">
    <strong>MyApp</strong>
    <div style="display: flex; gap: 20px;">
      <span>Home</span><span>Blog</span><span>About</span>
    </div>
  </div>
''')

// CSS Grid
HyperViewer(html: '''
  <div style="display: grid; grid-template-columns: 1fr 2fr 1fr; gap: 12px;">
    <div style="background: #E3F2FD; padding: 16px;">Sidebar</div>
    <div style="background: #F3E5F5; padding: 16px;">Main</div>
    <div style="background: #E8F5E9; padding: 16px;">Aside</div>
  </div>
''')
```

---

### 📊 Multi-Format Input

```dart
// HTML
HyperViewer(html: '<h1>Hello</h1><p>World</p>')

// Quill Delta JSON
HyperViewer.delta(delta: '{"ops":[{"insert":"Hello\\n"}]}')

// Markdown (CommonMark)
HyperViewer.markdown(markdown: '# Hello\n\n**Bold** and _italic_.')

// Custom CSS injection
HyperViewer(
  html: articleHtml,
  customCss: 'body { font-size: 18px; line-height: 1.8; } a { color: #6750A4; }',
)
```

---

### 🛡️ Sanitization — Safe for User Content

XSS protection is **on by default**. You opt out, not in.

```dart
// ✅ Safe by default — strips <script>, on* handlers, javascript: URLs
HyperViewer(html: userGeneratedContent)

// ✅ Custom allowlist
HyperViewer(
  html: userContent,
  allowedTags: ['p', 'a', 'img', 'strong', 'em', 'ul', 'li'],
)

// ⚠️ Disable only for trusted internal HTML
HyperViewer(html: trustedCmsHtml, sanitize: false)
```

Blocked by default: `<script>` · `<iframe>` · `on*` event handlers · `javascript:` URLs · `vbscript:` · `data:image/svg+xml` · CSS `expression()`

---

### 🔭 Hybrid WebView Fallback

```dart
// Automatic — HtmlHeuristics detects complex HTML and routes it to WebView
HyperViewer(
  html: maybeComplexHtml,
  fallbackBuilder: (context) => WebViewWidget(controller: _webViewController),
)

// Manual check
if (HtmlHeuristics.isComplex(html)) {
  // Use WebView
}
```

---

### 🖼️ Visual Effects

Because HyperRender controls the paint cycle directly, it supports effects that
standard Flutter widgets make difficult:

- **Glassmorphism**: `backdrop-filter: blur(10px)`
- **Box & text shadows**: multi-layer, with spread and blur
- **CSS filters**: `filter: blur(4px) brightness(1.2) contrast(0.8)`
- **Gradients**: `background: linear-gradient(to right, #6a11cb, #2575fc)`
- **Dashed / dotted borders**: `border-style: dashed | dotted`
- **High-DPI images**: automatic `FilterQuality.medium`

---

### 🧮 Formula / LaTeX

```dart
// Built-in Unicode renderer (zero deps)
FormulaWidget(formula: r'E = mc^2')
FormulaWidget(formula: r'\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}')

// Plug in flutter_math_fork for full LaTeX
FormulaWidget(
  formula: r'\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}',
  customBuilder: (context, formula) => Math.tex(formula),
)
```

Also works as a Quill Delta embed: `{"insert": {"formula": "E = mc^2"}}`.

---

### 📸 Screenshot Export

```dart
final captureKey = GlobalKey();

HyperViewer(html: articleHtml, captureKey: captureKey)

final pngBytes = await captureKey.toPngBytes();
final image   = await captureKey.toImage();
```

---

### 📖 Interactive `<details>` / `<summary>`

```html
<details>
  <summary>Click to expand</summary>
  <p>HyperRender is the only Flutter HTML library that supports this interactively.</p>
</details>
```

---

### 🌐 RTL / BiDi

```html
<p dir="rtl">هذا نص عربي من اليمين إلى اليسار</p>
<p dir="ltr">Back to left-to-right text.</p>
```

---

## 📊 Benchmarks

Measured on iPhone 13 (iOS 17) + Pixel 6 (Android 13) with a 25,000-character article.
Run `flutter run --release benchmark/performance_test.dart` to reproduce.

| Metric | flutter_html | flutter_widget_from_html | HyperRender |
|--------|:---:|:---:|:---:|
| Flutter widgets created | ~600 | ~500 | **3–5 chunks** |
| Parse time | 420 ms | 250 ms | **95 ms** |
| RAM usage | 28 MB | 15 MB | **8 MB** |
| Scroll FPS | ~35 | ~45 | **60** |
| `float: left/right` | ❌ | ❌ | ✅ |
| Selection on large docs | ⚠️ Limited | ❌ Crashes | ✅ |
| Ruby / Furigana | ❌ | ❌ | ✅ |
| CSS Variables | ❌ | ❌ | ✅ |
| Glassmorphism / Filters | ❌ | ❌ | ✅ |

> **"Widgets created"**: flutter_html / FWFH produce one Flutter widget per HTML tag.
> HyperRender splits the document into ~3–5 `RenderHyperBox` chunks and paints each
> directly to Canvas — the tag count never maps to widget count.

---

## 📖 API Reference

### `HyperViewer`

```dart
HyperViewer({
  required String html,
  String? baseUrl,                          // Resolve relative URLs
  String? customCss,                        // Inject extra CSS
  bool selectable = true,                   // Enable text selection
  bool sanitize = true,                     // XSS protection (default: ON)
  List<String>? allowedTags,               // Custom sanitizer allowlist
  HyperRenderMode mode = HyperRenderMode.auto, // sync | virtualized | auto
  Function(String)? onLinkTap,
  HyperWidgetBuilder? widgetBuilder,        // Inject Flutter widgets by tag
  WidgetBuilder? fallbackBuilder,           // Shown when HtmlHeuristics.isComplex()
  WidgetBuilder? placeholderBuilder,        // Async loading state
  GlobalKey? captureKey,                    // Screenshot export
  bool enableZoom = false,
  bool showSelectionMenu = true,
  String? semanticLabel,
  HyperViewerController? controller,        // Programmatic scroll + anchor jump
  void Function(Object, StackTrace)? onError,
})

HyperViewer.delta(delta: jsonString, ...)
HyperViewer.markdown(markdown: markdownString, ...)
```

### Custom Widget Injection

```dart
HyperViewer(
  html: htmlContent,
  widgetBuilder: (context, node) {
    if (node is AtomicNode && node.tagName == 'iframe') {
      final src = node.attributes['src'] ?? '';
      if (src.contains('youtube.com')) return YoutubePlayer(url: src);
    }
    return null; // fall through to default rendering
  },
)
```

### `HyperViewerController` — Anchor Navigation

```dart
final _ctrl = HyperViewerController();

HyperViewer(html: articleHtml, controller: _ctrl)

// Jump to any #anchor in the document
_ctrl.jumpToAnchor('section-2');
_ctrl.scrollToOffset(1200);
```

### `HtmlHeuristics`

```dart
HtmlHeuristics.isComplex(html)              // any of the below
HtmlHeuristics.hasComplexTables(html)       // colspan > 3 or deeply nested tables
HtmlHeuristics.hasUnsupportedCss(html)      // position:fixed, clip-path
HtmlHeuristics.hasUnsupportedElements(html) // canvas, form, select, input
```

### `SmartTableWrapper`

```dart
SmartTableWrapper(
  tableNode: myTableNode,
  strategy: TableStrategy.horizontalScroll, // fitWidth | autoScale | horizontalScroll
  minScaleFactor: 0.6,
)
```

### `FormulaWidget`

```dart
FormulaWidget(
  formula: r'\frac{-b \pm \sqrt{b^2-4ac}}{2a}',
  style: TextStyle(fontSize: 18),
  customBuilder: (context, f) => Math.tex(f), // optional flutter_math_fork hook
)
```

---

## 🏗️ Architecture

```
HTML / Delta / Markdown
        │
        ▼
   ADAPTER LAYER          ← HtmlAdapter · DeltaAdapter · MarkdownAdapter
        │
        ▼
UNIFIED DOCUMENT TREE     ← BlockNode · InlineNode · AtomicNode · RubyNode
                               TableNode · FlexContainerNode · GridNode
        │
        ▼
  CSS RESOLVER            ← specificity cascade · var() · calc() · inheritance
        │
        ▼
SINGLE RenderObject       ← BFC · IFC · Flexbox · Grid · Table · Float
                               Canvas painting · continuous span tree
                               Kinsoku · perfect text selection
```

**Key design choices:**
- **Single RenderObject** — the whole document is one `RenderBox`; float layout and crash-free selection are only possible because every fragment's coordinates live in one coordinate system
- **O(1) CSS rule lookup** — rules are indexed by tag/class/ID; lookup is constant-time regardless of stylesheet size
- **RepaintBoundary per chunk** — `ListView.builder` splits large documents into chunks, each with its own GPU layer; cross-chunk repaints never trigger
- **One-shot image listeners** — `ImageStreamListener` self-removes on success and error; no listener leaks

---

## ⚠️ When NOT to Use HyperRender

HyperRender is a content renderer, not a browser. Use something else for:

| Need | Better Choice |
|------|--------------|
| Execute JavaScript | `webview_flutter` |
| Interactive web forms | `webview_flutter` |
| Rich text editing | `super_editor`, `fleather` |
| `position: fixed`, `canvas` elements | `webview_flutter` (via `fallbackBuilder`) |
| Maximum CSS property count, no float/CJK need | `flutter_widget_from_html` |

---

## 📦 Extension Packages

| Package | Purpose | Status |
|---------|---------|:------:|
| [`hyper_render_core`](https://pub.dev/packages/hyper_render_core) | UDT model, CSS resolver, design tokens | ✅ Stable |
| [`hyper_render_html`](https://pub.dev/packages/hyper_render_html) | HTML adapter | ✅ Stable |
| [`hyper_render_markdown`](https://pub.dev/packages/hyper_render_markdown) | Markdown adapter | ✅ Stable |
| [`hyper_render_highlight`](https://pub.dev/packages/hyper_render_highlight) | Syntax highlighting for `<code>` | ✅ Stable |
| [`hyper_render_clipboard`](https://pub.dev/packages/hyper_render_clipboard) | Image copy / share | ✅ Stable |

Use the convenience `hyper_render` package (this one) to get all of the above in one dependency.

---

## 🗺️ Roadmap

### ✅ Shipped (v1.0 → v1.1)

CSS float · Flexbox · Grid · CSS Variables · `calc()` · Kinsoku + Ruby · `<details>` · RTL/BiDi · Quill Delta · Markdown · XSS sanitization · Screenshot export · `HtmlHeuristics` fallback · View virtualization · Design tokens · Dark mode · Performance monitoring

### 🔜 v1.2 — Stability & CSS polish

- Memory-pressure handling (`WidgetsBindingObserver` — auto-evict caches on low-memory signal)
- Full SVG renderer (currently shows placeholder)
- `video_player` / `audio` integration

### 🔮 v2.0+ — Plugin ecosystem & animation

- `hyper_render_media` package — extract media layer so core stays zero-dep
- CSS `@keyframes` / `transition` execution (currently parsed but not animated)
- `hyper_render_devtools` first working release (UDT inspector, computed-style panel)
- `hyper_render_export` — full-document PDF and high-res image export

Full details → [`doc/ROADMAP.md`](doc/ROADMAP.md)

---

## 🤝 Contributing

```bash
git clone https://github.com/brewkits/hyper_render.git
cd hyper_render && flutter pub get
flutter test                    # all tests must pass
cd example && flutter run       # run the demo app
```

Read the [Architecture Decision Records](doc/adr/) and [Contributing Guide](doc/CONTRIBUTING.md) before submitting PRs.

---

## 📄 License

MIT — see [LICENSE](LICENSE).

---

## ⭐ Star History

If HyperRender saves you from WebView overhead, a star goes a long way:

[![Star History Chart](https://api.star-history.com/svg?repos=brewkits/hyper_render&type=Date)](https://star-history.com/#brewkits/hyper_render&Date)

---

## 👤 Author & Maintainer

**HyperRender** is designed and maintained by [**brewkits**](https://github.com/brewkits).

Built to solve a real problem: Flutter's rich-text ecosystem either uses WebView (heavy) or flutter_widget_from_html (no float, no CJK). HyperRender is the third option — a native single-`RenderObject` engine that runs at 60 FPS and handles real-world editorial HTML.

If this library helps your product ship faster, consider [sponsoring development](https://github.com/sponsors/brewkits) or leaving a ⭐ on GitHub.

---

<div align="center">

**Built with care for Flutter developers who push the platform.**

[Get Started](#-quick-start) · [Demo App](example/) · [Report a Bug](https://github.com/brewkits/hyper_render/issues) · [pub.dev](https://pub.dev/packages/hyper_render)

</div>
