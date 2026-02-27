<div align="center">

# ⚡ HyperRender

### *"Render HTML like native text — not like a web browser."*

HyperRender is a **high-performance, native-feeling content rendering engine** for Flutter.
Designed for content-heavy apps (News, Blogs, E-books, RSS Readers), it bypasses the
**Widget Tree Hell** of traditional HTML parsers by rendering entire documents inside a
**Single Custom RenderObject**.

Forget OOM crashes. Forget scroll jank. Welcome to **60 FPS**.

[![pub package](https://img.shields.io/pub/v/hyper_render.svg)](https://pub.dev/packages/hyper_render)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![Performance](https://img.shields.io/badge/Parse_Speed-4.4x_faster-green.svg)](#benchmarks)
[![CSS](https://img.shields.io/badge/CSS_Coverage-68%25-orange.svg)](#css-support)

[Quick Start](#quick-start) · [Features](#features) · [Benchmarks](#benchmarks) · [API Reference](#api-reference) · [When NOT to use](#when-not-to-use)

</div>

---

## 🚨 The Problem with Traditional HTML Renderers

Most Flutter HTML libraries (`flutter_widget_from_html`, `flutter_html`) parse HTML and
map each tag **1:1 to Flutter widgets** — `Column`, `Row`, `Padding`, `Wrap`, `RichText`.

Load a 5,000-word article with a table and a floated image?
The result is **thousands of deeply nested widgets**. And then:

| Symptom | Root Cause |
|---------|-----------|
| ❌ Main thread jank on scroll | Widget tree rebuild on every frame |
| ❌ OOM crashes on large documents | Each widget holds its own memory |
| ❌ `float: left/right` impossible | Geometry across widget boundaries can't be calculated |
| ❌ Text selection crashes | Selection spans multiple independent `RichText` nodes |
| ❌ Broken CJK typography | No cross-widget line-breaking algorithm |

This is **Widget Tree Hell**. It is an architectural limitation, not a fixable bug.

---

## 💎 The HyperRender Solution

HyperRender acts like a **mini browser engine**.

Instead of building a widget tree, it parses HTML/CSS into a **Unified Document Tree (UDT)**
and paints everything directly onto the `Canvas` using a **single `RenderObject`** and a
continuous `InlineSpan` tree.

```
HTML Input  ──►  Adapter  ──►  UDT  ──►  CSS Resolver  ──►  Single RenderObject  ──►  Canvas
```

One RenderObject means:
- ✅ **Float layout works** — we control every pixel's coordinates
- ✅ **Selection never crashes** — the entire document is one continuous span tree
- ✅ **True Kinsoku line-breaking** — no widget boundary interrupts CJK rules
- ✅ **O(1) CSS rule lookup** — tag/class/ID index, not O(n×m) scan
- ✅ **View virtualization** — `ListView.builder` + `RepaintBoundary` per chunk

---

## 📊 Benchmarks

> Measured on iPhone 13 (iOS 17) and Pixel 6 (Android 13) with a 25,000-character article.

| Metric | flutter_html | flutter_widget_from_html | ⚡ HyperRender |
|--------|:---:|:---:|:---:|
| **Parse time** | 420ms ❌ | 250ms ⚠️ | **95ms ✅** — 4.4× faster |
| **RAM usage** | 28 MB ❌ | 15 MB ⚠️ | **8 MB ✅** — 3.5× lighter |
| **Scroll FPS** | ~35 fps ❌ | ~45 fps ⚠️ | **60 fps ✅** |
| **CSS `float`** | ❌ Not possible | ❌ Not possible | **✅ Perfect** |
| **Text selection** | ⚠️ Slow, limited | ❌ Crashes on large docs | **✅ Crash-free** |
| **Ruby / Furigana** | ❌ Raw text | ❌ Not supported | **✅ Professional** |
| **`<details>/<summary>`** | ❌ | ❌ | **✅ Interactive** |
| **CSS Variables `var()`** | ❌ | ❌ | **✅** |
| **Flexbox** | ❌ | ⚠️ Partial | **✅ 90%** |

---

## 📦 Quick Start

```yaml
# pubspec.yaml
dependencies:
  hyper_render: ^2.1.0
```

```dart
import 'package:hyper_render/hyper_render.dart';

// That's all. Sanitization is ON by default.
HyperViewer(
  html: articleHtml,
  onLinkTap: (url) => launchUrl(Uri.parse(url)),
)
```

---

## ✨ Features

### 🌟 CSS Float — The Feature No One Else Has

Text wrapping around floated images is an **architectural impossibility** for widget-tree
renderers. HyperRender is the **only Flutter HTML library** that supports it natively.

```dart
HyperViewer(
  html: '''
    <article>
      <img src="https://example.com/photo.jpg"
           style="float: left; width: 200px; margin: 0 16px 8px 0; border-radius: 8px;" />
      <h2>Magazine-style Layout</h2>
      <p>This text flows naturally around the floated image, just like a browser.
         No other Flutter HTML library can do this. Try it and see.</p>
      <p>Additional paragraphs continue to respect the float clearance
         until the image is fully cleared.</p>
    </article>
  ''',
)
```

---

### ✨ Crash-Free Text Selection

Because the entire document lives inside **one continuous span tree**, selection works
perfectly across paragraphs, headings, and table cells — with no crashes, even on
100,000-character documents.

```dart
HyperViewer(
  html: longArticleHtml,
  selectable: true,           // default: true
  showSelectionMenu: true,    // Copy / Select All menu
  selectionHandleColor: Colors.blue,
)
```

---

### 🀄 Professional CJK Typography

```dart
HyperViewer(
  html: '''
    <p style="font-size: 20px; line-height: 2;">
      <ruby>東京<rt>とうきょう</rt></ruby>で
      <ruby>日本語<rt>にほんご</rt></ruby>を
      <ruby>勉強<rt>べんきょう</rt></ruby>しています。
    </p>
  ''',
)
```

Furigana renders **above** the base characters with perfect alignment —
not inline as raw text like every other library.

---

### 🎨 CSS Variables & `calc()`  *(Sprint 3)*

```dart
HyperViewer(
  html: '''
    <style>
      :root {
        --brand: #6750A4;
        --gap: 16px;
      }
      .card {
        background: var(--brand);
        padding: calc(var(--gap) * 1.5);
        border-radius: 12px;
        color: white;
      }
    </style>
    <div class="card">Themed with CSS custom properties</div>
  ''',
)
```

---

### 🔲 CSS Grid  *(Sprint 3)*

```dart
HyperViewer(
  html: '''
    <div style="display: grid; grid-template-columns: 1fr 2fr 1fr; gap: 12px;">
      <div style="background: #E3F2FD; padding: 16px; border-radius: 8px;">Sidebar</div>
      <div style="background: #F3E5F5; padding: 16px; border-radius: 8px;">Main Content</div>
      <div style="background: #E8F5E9; padding: 16px; border-radius: 8px;">Aside</div>
    </div>
  ''',
)
```

---

### 📐 Flexbox (90% Coverage)

```dart
HyperViewer(
  html: '''
    <div style="display: flex; justify-content: space-between;
                align-items: center; gap: 16px; padding: 12px;
                background: #1976D2; border-radius: 8px; color: white;">
      <strong>MyApp</strong>
      <div style="display: flex; gap: 20px;">
        <span>Home</span><span>Blog</span><span>About</span>
      </div>
    </div>
  ''',
)
```

Supported: `flex-direction`, `justify-content`, `align-items`, `align-self`,
`flex-wrap`, `flex-grow`, `flex-shrink`, `flex-basis`, `gap`, `row-gap`, `column-gap`.

---

### 📊 Smart Table Layout

Tables use **W3C 2-pass column width algorithm** (min-content → distribute surplus),
with three overflow strategies via `SmartTableWrapper`:

```dart
// Strategy auto-selected based on table width attribute:
// width:100% → fitWidth, otherwise → autoScale (min 60%)
HyperViewer(html: htmlWithTable)

// Or control manually:
SmartTableWrapper(
  tableNode: myTableNode,
  strategy: TableStrategy.horizontalScroll, // fitWidth | autoScale | horizontalScroll
)

// Build tables programmatically:
final table = TableNode();
final row = TableRowNode();
final cell = TableCellNode(isHeader: true, attributes: {'colspan': '2'});
cell.appendChild(TextNode('Merged Header'));
row.appendChild(cell);
table.appendChild(row);
HyperTable(tableNode: table)
```

---

### 🧮 Formula / LaTeX Rendering

Built-in Unicode renderer for math expressions. Plug in `flutter_math_fork` for full LaTeX.

```dart
// Built-in Unicode rendering (zero dependencies)
FormulaWidget(formula: r'E = mc^2')
FormulaWidget(formula: r'\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}')
FormulaWidget(formula: r'\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}')

// Swap to flutter_math_fork for full LaTeX:
FormulaWidget(
  formula: r'\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}',
  customBuilder: (context, formula) => Math.tex(formula),
)
```

Works in Quill Delta embeds:
```json
{ "ops": [
  { "insert": "The energy formula " },
  { "insert": { "formula": "E = mc^2" } },
  { "insert": " was derived by Einstein.\n" }
]}
```

---

### 🔀 Multi-Format Input

```dart
// HTML
HyperViewer(html: '<h1>Hello</h1><p>World</p>')

// Quill Delta JSON
HyperViewer.delta(delta: '{"ops":[{"insert":"Hello\\n"}]}')

// Markdown
HyperViewer.markdown(markdown: '# Hello\n\n**Bold** and _italic_.')

// Custom CSS injected on top of document styles
HyperViewer(
  html: articleHtml,
  customCss: 'body { font-size: 18px; line-height: 1.8; } a { color: #6750A4; }',
)
```

---

### 🔭 Hybrid WebView — `HtmlHeuristics` + `fallbackBuilder`

Not every HTML document is content. For interactive or JavaScript-heavy HTML,
use the built-in heuristics to detect complexity and fall back to a WebView:

```dart
// Automatic fallback — no manual detection needed
HyperViewer(
  html: maybeComplexHtml,
  fallbackBuilder: (context) => WebViewWidget(controller: _webViewController),
)

// Manual detection
if (HtmlHeuristics.isComplex(html)) {
  // Use WebView
} else {
  // HyperViewer renders it perfectly
}

// Fine-grained checks:
HtmlHeuristics.hasComplexTables(html)      // colspan > 3, nested tables
HtmlHeuristics.hasUnsupportedCss(html)     // position:fixed, clip-path
HtmlHeuristics.hasUnsupportedElements(html) // <canvas>, <form>, <select>
```

---

### 📸 Screenshot Export  *(Sprint 3)*

```dart
final captureKey = GlobalKey();

HyperViewer(
  html: articleHtml,
  captureKey: captureKey,
)

// Capture anytime:
final pngBytes = await captureKey.toPngBytes();  // PNG
final image = await captureKey.toImage();         // ui.Image
```

---

### 📖 `<details>` / `<summary>` — Collapsible Sections

```html
<details>
  <summary>Click to expand</summary>
  <p>Hidden content revealed on tap. HyperRender is the only Flutter HTML
     library that supports this element interactively.</p>
</details>

<details open>
  <summary>Open by default</summary>
  <p>This section starts expanded.</p>
</details>
```

---

### 🌐 RTL / BiDi  *(Sprint 3)*

```html
<p dir="rtl">هذا نص عربي من اليمين إلى اليسار</p>
<p dir="ltr">Back to left-to-right text.</p>
```

---

## 🔒 Security

**Sanitization is ON by default.** `HyperViewer` strips `<script>`, event handlers,
`javascript:` URLs, `vbscript:`, SVG data URIs, and CSS `expression()` out of the box.

```dart
// ✅ Safe by default — sanitize: true is the default
HyperViewer(html: userGeneratedContent)

// ✅ Custom tag allowlist
HyperViewer(
  html: userContent,
  sanitize: true,
  allowedTags: ['p', 'a', 'img', 'strong', 'em', 'ul', 'ol', 'li'],
)

// ⚠️ Opt-out only for fully trusted backend HTML
HyperViewer(html: trustedCmsHtml, sanitize: false)
```

**What gets removed:**
- Tags: `<script>`, `<iframe>`, `<object>`, `<embed>`, `<form>`, `<input>`
- Attributes: `onclick`, `onerror`, `onload` and all `on*` handlers
- URLs: `javascript:`, `vbscript:`, `data:image/svg+xml` (SVG can embed scripts)
- CSS: `expression(...)` (IE injection vector)

---

## 🏗️ Architecture

HyperRender uses a **4-layer browser-inspired pipeline**:

```
┌─────────────────────────────────────────────────────┐
│        Input  (HTML / Quill Delta / Markdown)       │
└───────────────────────┬─────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────┐
│           ADAPTER LAYER  (Input Parsers)            │
│    HtmlAdapter · DeltaAdapter · MarkdownAdapter     │
└───────────────────────┬─────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────┐
│         UNIFIED DOCUMENT TREE  (UDT)                │
│  BlockNode · InlineNode · AtomicNode · RubyNode     │
│  TableNode · FlexContainerNode · GridNode           │
└───────────────────────┬─────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────┐
│           CSS STYLE RESOLVER                        │
│  User-Agent → <style> rules → Inline → Inheritance │
│  Specificity cascade · CSS Variables · calc()       │
└───────────────────────┬─────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────┐
│        SINGLE CUSTOM RenderObject                   │
│  BFC · IFC · Flexbox · Grid · Table · Float         │
│  Direct Canvas painting · Continuous span tree      │
│  Kinsoku line-breaking · Perfect text selection     │
└─────────────────────────────────────────────────────┘
```

**Key innovations:**
- **Single RenderObject** — entire document painted in one `RenderBox`; enables float layout and crash-free selection
- **O(1) CSS rule indexing** — rules indexed by tag/class/ID; lookup is constant-time regardless of stylesheet size
- **Flat coordinate system** — all fragment positions computed in one layout pass; no widget-boundary offset errors
- **RepaintBoundary per chunk** — `ListView.builder` chunks each with its own GPU layer; cross-chunk repaint never triggers
- **One-shot `ImageStreamListener`** — self-removing on both success and error; no listener leak

---

## 📖 API Reference

### `HyperViewer`

```dart
// HTML (default constructor)
HyperViewer({
  required String html,
  String? baseUrl,             // Resolve relative URLs
  String? customCss,           // Inject extra CSS (lower priority than document styles)
  bool selectable = true,      // Enable text selection
  bool sanitize = true,        // Strip dangerous tags/attributes (default: ON)
  List<String>? allowedTags,   // Custom allowlist for sanitize: true
  HyperRenderMode mode = HyperRenderMode.auto, // sync | async | auto
  Function(String)? onLinkTap,
  HyperWidgetBuilder? widgetBuilder, // Inject native Flutter widgets by tag/node
  WidgetBuilder? fallbackBuilder,    // Shown when HtmlHeuristics.isComplex()
  GlobalKey? captureKey,       // Screenshot export
  bool enableZoom = false,
  bool showSelectionMenu = true,
  WidgetBuilder? placeholderBuilder, // Async loading state
  String? semanticLabel,
  bool debugShowHyperRenderBounds = false,
})

// Named constructors
HyperViewer.delta(delta: jsonString, ...)
HyperViewer.markdown(markdown: markdownString, ...)
```

### `HyperWidgetBuilder` — Custom Widget Injection

```dart
HyperViewer(
  html: htmlContent,
  widgetBuilder: (context, node) {
    // Intercept any node by tag or attributes
    if (node is AtomicNode && node.tagName == 'iframe') {
      final src = node.attributes['src'] ?? '';
      if (src.contains('youtube.com')) {
        return YoutubePlayerWidget(url: src);
      }
    }
    return null; // Fall through to default rendering
  },
)
```

### `HtmlHeuristics`

```dart
HtmlHeuristics.isComplex(html)           // any of the below
HtmlHeuristics.hasComplexTables(html)    // colspan > 3 or deeply nested
HtmlHeuristics.hasUnsupportedCss(html)   // position:fixed, clip-path, columns
HtmlHeuristics.hasUnsupportedElements(html) // canvas, form, select, input
```

### `SmartTableWrapper`

```dart
SmartTableWrapper(
  tableNode: myTableNode,
  strategy: TableStrategy.fitWidth,        // Shrink columns proportionally
  // strategy: TableStrategy.horizontalScroll, // Preserve widths, scroll
  // strategy: TableStrategy.autoScale,    // FittedBox scale-down
  minScaleFactor: 0.6,                     // Min scale for autoScale
)
```

### `FormulaWidget`

```dart
FormulaWidget(
  formula: r'\frac{-b \pm \sqrt{b^2-4ac}}{2a}',
  style: TextStyle(fontSize: 18),
  customBuilder: (context, formula) => Math.tex(formula), // optional
)
```

### `HyperCaptureExtension`

```dart
final key = GlobalKey();
// ... HyperViewer(captureKey: key)

final bytes = await key.toPngBytes();    // Uint8List PNG
final image = await key.toImage();       // ui.Image
```

### `DesignTokens`

```dart
// Material Design 3 compliant, auto dark-mode
DesignTokens.headingStyle(1)           // H1 TextStyle
DesignTokens.bodyFontSize              // 14.0
DesignTokens.space2                    // 16.0
DesignTokens.spacing(2)                // EdgeInsets.all(16)
DesignTokens.getTextPrimary(context)   // Color (adapts to theme)
DesignTokens.getBackgroundColor(context)
```

---

## ⚠️ When NOT to Use HyperRender

HyperRender is a **specialized content engine**, not a full browser. Choose the right tool:

| Need | Use Instead |
|------|------------|
| Execute JavaScript | `webview_flutter` |
| Interactive web forms | `webview_flutter` |
| Rich text editor | `super_editor`, `fleather` |
| Complex HTML with `position:fixed`, `canvas` | `webview_flutter` (via `fallbackBuilder`) |

**✅ DO USE** for: News apps, Medium-clones, documentation viewers, RSS readers,
e-book readers, email clients, CJK content apps — anywhere you need to render
large amounts of beautifully formatted content without dropping frames.

---

## 🗺️ Roadmap

### ✅ v1–v3 Complete

- [x] HTML parser → Unified Document Tree (UDT)
- [x] Full CSS cascade — specificity, inheritance, `!important`
- [x] **CSS Float layout** — text wrapping around images/video (unique)
- [x] Perfect text selection + copy menu (crash-free)
- [x] W3C 2-pass table layout (colspan, rowspan, `SmartTableWrapper`)
- [x] Flexbox layout (90% coverage)
- [x] CJK Kinsoku line-breaking + Ruby / Furigana (unique)
- [x] `<details>` / `<summary>` collapsible (unique)
- [x] CSS Variables (`--custom-props`, `var()`)
- [x] CSS Grid (`display: grid`, fr units)
- [x] **Paren-aware inline style tokenizer** — `url()`, `calc()`, `rgb()` never truncated
- [x] CSS `calc()` (px, em, rem arithmetic)
- [x] SVG inline rendering (placeholder)
- [x] RTL / BiDi (`dir` attribute)
- [x] Screenshot export (`captureKey` + `HyperCaptureExtension`)
- [x] `HtmlHeuristics` + `fallbackBuilder` — hybrid WebView pattern
- [x] `FormulaWidget` — Unicode LaTeX + `flutter_math_fork` hook
- [x] Quill Delta adapter + formula embeds
- [x] Markdown adapter
- [x] HTML sanitization (XSS, `vbscript:`, SVG data:, CSS `expression()`)
- [x] Base URL resolution
- [x] Error boundaries + loading skeletons
- [x] View virtualization + `RepaintBoundary` per chunk
- [x] Design Tokens (Material 3) + dark mode
- [x] CSS Plugin Architecture (`CssParserInterface` — swappable parser)
- [x] Performance monitoring (`PerformanceMonitor` in `hyper_render_core`)

### 🚧 In Progress

- [ ] Full SVG renderer (not just placeholder)
- [ ] Video/audio player integration (`video_player` plugin)
- [ ] CSS `@keyframes` animation (currently via `HyperAnimatedWidget`)

### 🔮 v4.0 — Browser Engine Tier

> These are ambitious, multi-sprint features that push HyperRender into browser-engine territory.

#### 🟡 Vanilla JS Execution via QuickJS

Embed [QuickJS](https://bellard.org/quickjs/) — the lightweight JS engine by Fabrice Bellard
(~300 KB, no JIT, perfect for sandboxed execution) via Dart FFI.

Architecture plan:
1. **QuickJS via FFI** — run the C library directly inside the Flutter process
2. **Synthetic DOM bridge** — Dart methods exposed to JS: `document.getElementById()`,
   `element.style.display = 'none'`, `element.textContent`
3. **Scope**: Vanilla JS only — form validation, show/hide (accordion), quiz logic.
   No React/Vue/Angular. No `fetch()`. No `setTimeout()` with DOM mutations.
4. For JavaScript-heavy pages: use `fallbackBuilder` → `webview_flutter`

```dart
// Future API (v4.0)
HyperViewer(
  html: htmlWithInlineScript,
  enableVanillaJs: true,   // opt-in — off by default for security
  jsWhitelist: ['document', 'console'],
)
```

#### 🟡 `position: absolute/fixed` Layout

Enable positioned elements inside a `PositioningContext`. Required for
tooltips, dropdowns, and overlay-style HTML fragments.

#### 🟡 `clip-path` Support

Polygon and circle clip masks via Flutter's `ClipPath` widget.

#### 🟢 Print / PDF Export

`HyperViewer` → paginated `pdf` output via `printing` package.

### 🎯 CSS Strategy

HyperRender follows **Graceful Degradation** — unknown CSS properties are silently
ignored, never crash the renderer. Layout and typography are always correct.
Decorative unsupported properties (e.g. `mix-blend-mode`, `backdrop-filter`) result
in a slightly simpler visual — the content remains perfectly readable at 60 FPS.

The CSS parser backend is **swappable** via `CssParserInterface`:

```dart
// Default: uses Google's csslib AST parser (handles @media, @keyframes, etc.)
// Zero config — automatic.

// Custom parser (e.g. for a restricted environment):
class MyMinimalParser implements CssParserInterface {
  @override
  List<ParsedCssRule> parseStylesheet(String css) { ... }

  @override
  Map<String, String> parseInlineStyle(String style) { ... }
}
```

This means **community-contributed CSS plugins** can extend coverage without
touching the core — the same model used by browser engine plugin architectures.

---

## 📦 Extension Packages

| Package | Description | Status |
|---------|-------------|:------:|
| `hyper_render_core` | Core UDT, CSS resolver, design tokens | ✅ Stable |
| `hyper_render_html` | HTML adapter | ✅ Stable |
| `hyper_render_markdown` | Markdown adapter | ⚠️ Alpha |
| `hyper_render_highlight` | Syntax highlighting for `<code>` | ✅ Stable |
| `hyper_render_devtools` | Flutter DevTools extension (UDT inspector) | 🧪 Beta |

---

## 🤝 Contributing

```bash
git clone https://github.com/yourusername/hyper_render.git
cd hyper_render
flutter pub get
flutter test           # All tests must pass
cd example && flutter run  # Run the demo app
```

Read our [Architecture Guide](docs/ARCHITECTURE.md) and
[Contributing Guidelines](docs/CONTRIBUTING.md) before submitting PRs.

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

## 🔗 More

- 📋 [Comparison Matrix](docs/COMPARISON_MATRIX.md) — Full feature comparison
- 🎨 [CSS Properties Matrix](docs/CSS_PROPERTIES_MATRIX.md) — Complete CSS support status
- 📐 [Supported HTML Elements](docs/SUPPORTED_HTML.md) — Tags and attributes
- ⚠️ [Known Limitations](docs/LIMITATIONS.md) — Honest list of what we don't support yet
- 📦 [Migration Guide](MIGRATION.md) — Coming from flutter_html or FWFH?

---

<div align="center">

**Built with ❤️ by the Flutter community**

[Get Started](#quick-start) · [View Demo](example/) · [Report Bug](https://github.com/yourusername/hyper_render/issues) · [Request Feature](https://github.com/yourusername/hyper_render/issues)

</div>
