<div align="center">

<img src="https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/logo.svg" width="96" alt="HyperRender logo" />

# HyperRender

### The only Flutter HTML renderer with CSS float layout.

[![pub.dev](https://img.shields.io/pub/v/hyper_render.svg?label=pub.dev&color=0175C2)](https://pub.dev/packages/hyper_render)
[![pub points](https://img.shields.io/pub/points/hyper_render?label=pub%20points&color=00b4ab)](https://pub.dev/packages/hyper_render/score)
[![likes](https://img.shields.io/pub/likes/hyper_render?color=FF6B6B)](https://pub.dev/packages/hyper_render/score)
[![CI](https://github.com/brewkits/hyper_render/actions/workflows/analyze.yml/badge.svg)](https://github.com/brewkits/hyper_render/actions)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-54C5F8.svg?logo=flutter)](https://flutter.dev)

**CSS float · crash-free selection · CJK/Furigana · `@keyframes` · 1 646 tests · XSS-safe · Zero Gradle config**

[**Quick Start**](#-quick-start) · [**Why Switch?**](#️-why-switch-the-architecture-argument) · [**API**](#-api-reference) · [**Packages**](#-packages)

</div>

---

## Demos

| CSS Float Layout | Ruby / Furigana | Crash-Free Selection |
|:---:|:---:|:---:|
| ![CSS Float Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/float_demo.gif) | ![Ruby Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/ruby_demo.gif) | ![Selection Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/selection_demo.gif) |
| Text wraps around floated images — **no other Flutter HTML renderer does this** | Furigana centered above base glyphs, full Kinsoku line-breaking | Select across headings, paragraphs, tables — tested to 100 000 chars |

| Advanced Tables | Head-to-Head | Virtualized Mode |
|:---:|:---:|:---:|
| ![Table Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/table_demo.gif) | ![Comparison Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/comparison_demo.gif) | ![Performance Demo](https://raw.githubusercontent.com/brewkits/hyper_render/main/assets/performance_demo.gif) |
| `colspan` · `rowspan` · W3C 2-pass column algorithm | Same HTML in HyperRender vs flutter_widget_from_html | Virtualized rendering — 60 FPS on documents of any length |

---

## 🚀 Quick Start

```yaml
dependencies:
  hyper_render: ^1.3.2
```

```dart
import 'package:hyper_render/hyper_render.dart';

HyperViewer(
  html: articleHtml,
  onLinkTap: (url) => launchUrl(Uri.parse(url)),
)
```

Zero configuration. XSS sanitization is **on by default**. No Gradle setup required.

---

## 🏗️ Why Switch? The Architecture Argument

Most Flutter HTML libraries map each HTML tag to a Flutter widget. A 3 000-word article becomes **500+ nested widgets** — and some layout primitives simply cannot be expressed that way:

> **CSS `float` is architecturally impossible in a widget tree.**
> Wrapping text around a floated image requires every fragment's coordinates before adjacent text can be composed. That geometry only exists when a single `RenderObject` owns the entire layout pass.

HyperRender renders the whole document inside **one custom `RenderObject`**. CSS float, crash-free selection, O(log N) binary-search hit-testing, and `@keyframes` animations all follow directly from that single architectural decision.

### Feature Matrix

| Feature | `flutter_html` | `flutter_widget_from_html` | **HyperRender** |
|---|:---:|:---:|:---:|
| `float: left / right` | ❌ | ❌ | ✅ |
| Text selection — large docs | ❌ Crashes | ❌ Crashes | ✅ Crash-free |
| Ruby / Furigana + Kinsoku | ❌ Raw text | ❌ Raw text | ✅ |
| RTL / BiDi (Arabic, Hebrew) | ⚠️ | ⚠️ | ✅ |
| CSS Variables `var()` | ❌ | ❌ | ✅ |
| CSS `@keyframes` animation | ❌ | ❌ | ✅ |
| Flexbox / Grid | ⚠️ Partial | ⚠️ Partial | ✅ Full |
| `box-shadow` · `filter` | ❌ | ❌ | ✅ |
| `list-style-type` (all 11 values) | ⚠️ disc only | ⚠️ disc only | ✅ |
| `<details>` / `<summary>` | ❌ | ❌ | ✅ Interactive |
| Quill Delta input | ❌ | ❌ | ✅ |
| Markdown input | ❌ | ❌ | ✅ GFM |
| Modular packages | ❌ monolith | ❌ monolith | ✅ opt-in add-ons |
| Zero Gradle config | ✅ | ✅ | ✅ |

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

> **Inline SVG note**: `<svg>` and `<math>` are stripped by default because inline SVG can embed `<script>` payloads. External SVG via `<img src="*.svg">` is fully supported. Add `'svg'` to `allowedTags` only for content you fully control.

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
final hd  = await captureKey.toPngBytes(pixelRatio: 3.0);
```

### Hybrid WebView Fallback

```dart
HyperViewer(
  html: maybeComplexHtml,
  fallbackBuilder: (context) => WebViewWidget(controller: _webViewController),
)
```

---

## 📖 API Reference

### `HyperViewer`

```dart
HyperViewer({
  required String html,
  String? baseUrl,           // resolves relative <img src> and <a href>
  String? customCss,         // injected after the document's own <style> tags
  bool selectable = true,
  bool sanitize = true,
  List<String>? allowedTags,
  HyperRenderMode mode = HyperRenderMode.auto, // sync | virtualized | paged | auto
  bool enableZoom = false,
  void Function(String)? onLinkTap,
  HyperWidgetBuilder? widgetBuilder,           // custom widget injection
  WidgetBuilder? fallbackBuilder,
  WidgetBuilder? placeholderBuilder,
  GlobalKey? captureKey,
  bool showSelectionMenu = true,
  String? semanticLabel,
  HyperViewerController? controller,
  HyperPageController? pageController,         // paged mode only
  HyperPluginRegistry? pluginRegistry,         // custom tag plugins
  void Function(Object, StackTrace)? onError,
})

HyperViewer.delta(delta: jsonString, ...)
HyperViewer.markdown(markdown: markdownString, ...)
```

### `HyperRenderMode`

| Value | Behaviour |
|---|---|
| `auto` | Sync for ≤ 10 000 chars, async virtualized otherwise |
| `sync` | Always render synchronously in a single scroll view |
| `virtualized` | `ListView.builder` — only visible sections built/painted |
| `paged` | `PageView.builder` — one section per page (e-book / reader UI) |

### `HyperPageController` (paged mode)

```dart
final ctrl = HyperPageController();

HyperViewer(html: html, mode: HyperRenderMode.paged, pageController: ctrl)

ctrl.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
ctrl.animateToPage(2, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
ctrl.jumpToPage(0);

// Reactive page indicator:
ValueListenableBuilder<int>(
  valueListenable: ctrl.currentPage,
  builder: (_, page, __) => Text('Page ${page + 1} of ${ctrl.pageCount}'),
)
```

### Plugin API — Custom HTML Tags

Register custom tag renderers via `HyperPluginRegistry`. Two tiers:

- **Block** (`isInline == false`): full-width widget with CSS margins
- **Inline** (`isInline == true`): flows with text; intrinsic size measured automatically

```dart
class MyCardPlugin implements HyperNodePlugin {
  @override String get tagName => 'my-card';
  @override bool get isInline => false;

  @override
  Widget? build(HyperPluginBuildContext ctx) {
    return Card(child: Text(ctx.node.textContent));
    // Return null to fall through to default rendering.
  }
}

final registry = HyperPluginRegistry()..register(MyCardPlugin());
HyperViewer(html: '<my-card>Hello</my-card>', pluginRegistry: registry)
```

### `HyperViewerController`

```dart
final ctrl = HyperViewerController();
HyperViewer(html: html, controller: ctrl)

ctrl.scrollToId('section-2');   // scroll to <id="section-2">
ctrl.scrollToOffset(1200);        // absolute pixel offset
```

### Custom Widget Injection

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

- **Single RenderObject** — float layout and crash-free selection require one shared coordinate system; a widget tree cannot provide this
- **O(1) CSS rule lookup** — rules indexed by tag / class / ID; constant time regardless of stylesheet size
- **O(log N) hit-testing** — `_lineStartOffsets[]` precomputed at layout time; each touch is a binary search, not a linear scan
- **RepaintBoundary per chunk** — unmodified chunks are composited, not repainted; incremental layout caches unchanged sections by content hash
- **1 646 passing tests** — unit, widget, integration, fuzz (43 cases), and golden pixel tests across 3 OS platforms

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

## ♿ Accessibility (WCAG 2.1 AA)

- **Image alt text** (WCAG 1.1.1): `<img alt="…">` elements produce a discrete `SemanticsNode` at the image's layout rect — screen-reader users can navigate to images element-by-element.
- **`aria-label` on links** (WCAG 4.1.2): `<a aria-label="…">` uses the attribute value as the accessible label instead of text content.

```html
<img src="chart.png" alt="Q3 revenue chart — $2.4M, up 18% YoY">
<a href="/privacy" aria-label="Privacy policy (opens in new tab)">Privacy</a>
```

---

## 📦 Packages

| Package | pub.dev | Description |
|---------|---------|-------------|
| [`hyper_render`](https://pub.dev/packages/hyper_render) | [![pub](https://img.shields.io/pub/v/hyper_render.svg)](https://pub.dev/packages/hyper_render) | Convenience wrapper — HTML, Markdown, Delta, syntax highlight |
| [`hyper_render_core`](https://pub.dev/packages/hyper_render_core) | [![pub](https://img.shields.io/pub/v/hyper_render_core.svg)](https://pub.dev/packages/hyper_render_core) | Core engine — UDT model, CSS resolver, RenderObject; zero native deps |
| [`hyper_render_html`](https://pub.dev/packages/hyper_render_html) | [![pub](https://img.shields.io/pub/v/hyper_render_html.svg)](https://pub.dev/packages/hyper_render_html) | HTML + CSS parser |
| [`hyper_render_markdown`](https://pub.dev/packages/hyper_render_markdown) | [![pub](https://img.shields.io/pub/v/hyper_render_markdown.svg)](https://pub.dev/packages/hyper_render_markdown) | Markdown adapter (GFM) |
| [`hyper_render_highlight`](https://pub.dev/packages/hyper_render_highlight) | [![pub](https://img.shields.io/pub/v/hyper_render_highlight.svg)](https://pub.dev/packages/hyper_render_highlight) | Syntax highlighting for `<code>` / `<pre>` blocks |
| [`hyper_render_devtools`](https://pub.dev/packages/hyper_render_devtools) | [![pub](https://img.shields.io/pub/v/hyper_render_devtools.svg)](https://pub.dev/packages/hyper_render_devtools) | Flutter DevTools extension — UDT inspector, computed styles, float visualizer |

### Optional add-ons

These packages bring native dependencies and are **not bundled** by default. Install only what you need.

| Package | pub.dev | Description |
|---------|---------|-------------|
| [`hyper_render_clipboard`](https://pub.dev/packages/hyper_render_clipboard) | [![pub](https://img.shields.io/pub/v/hyper_render_clipboard.svg)](https://pub.dev/packages/hyper_render_clipboard) | Native image copy / share via `super_clipboard` |
| [`hyper_render_math`](https://pub.dev/packages/hyper_render_math) | [![pub](https://img.shields.io/pub/v/hyper_render_math.svg)](https://pub.dev/packages/hyper_render_math) | LaTeX / MathML via `flutter_math_fork` |

#### `hyper_render_clipboard` — Native image copy / share

```yaml
dependencies:
  hyper_render_clipboard: ^1.3.2
```

```dart
import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';

HyperViewer(
  html: html,
  imageClipboardHandler: SuperClipboardHandler(),
)
```

> **Android setup required:** `super_clipboard` transitively pulls in `irondash_engine_context`, which requires `compileSdk ≥ 34`. Add this to `android/build.gradle.kts` (root file, not `app/`):
>
> ```kotlin
> subprojects {
>     afterEvaluate {
>         extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
>             compileSdk = 35
>         }
>     }
> }
> ```
>
> Tracked in [#5](https://github.com/brewkits/hyper_render/issues/5).

#### `hyper_render_math` — LaTeX / MathML rendering

```yaml
dependencies:
  hyper_render_math: ^1.3.2
```

```dart
import 'package:hyper_render_math/hyper_render_math.dart';

final registry = HyperPluginRegistry()..register(const MathPlugin());
HyperViewer(html: html, pluginRegistry: registry)
```

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

See [Architecture Decision Records](doc/adr/) and [Contributing Guide](doc/CONTRIBUTING.md) before submitting a PR.

---

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">

[![GitHub stars](https://img.shields.io/github/stars/brewkits/hyper_render?style=social)](https://github.com/brewkits/hyper_render)

[pub.dev](https://pub.dev/packages/hyper_render) · [API docs](https://pub.dev/documentation/hyper_render/latest/) · [Changelog](CHANGELOG.md) · [Roadmap](doc/ROADMAP.md)

</div>
