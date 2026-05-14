# hyper_render_html

HTML parsing plugin for [HyperRender](https://pub.dev/packages/hyper_render). Converts HTML + CSS into the Universal Document Tree consumed by `hyper_render_core`.

---

## Installation

```yaml
dependencies:
  hyper_render_core: ^1.3.1
  hyper_render_html: ^1.3.1
```

---

## Usage

### Parse HTML

```dart
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_html/hyper_render_html.dart';

final document = HtmlContentParser().parse('''
  <h1>Welcome</h1>
  <p>This is <strong>bold</strong> and <em>italic</em> text.</p>
  <ul>
    <li>Item 1</li>
    <li>Item 2</li>
  </ul>
''');

HyperRenderWidget(document: document)
```

### Custom CSS

```dart
final document = HtmlContentParser().parseWithOptions(
  '<div class="card"><h2>Title</h2><p>Content</p></div>',
  customCss: '''
    .card { background: #f5f5f5; padding: 16px; border-radius: 8px; }
    .card h2 { color: #333; margin-bottom: 8px; }
  ''',
);
```

### Base URL (resolves relative paths)

```dart
final document = HtmlContentParser().parseWithOptions(
  '<img src="/images/photo.jpg">',
  baseUrl: 'https://example.com',
);
// <img> src resolved to: https://example.com/images/photo.jpg
```

---

## Supported HTML

**Block**: `h1`–`h6`, `p`, `div`, `article`, `section`, `blockquote`, `pre`, `ul`, `ol`, `li`, `table`, `tr`, `td`, `th`, `details`, `summary`, `hr`, `dl`, `dt`, `dd`

**Inline**: `a`, `strong`, `b`, `em`, `i`, `u`, `s`, `del`, `ins`, `code`, `kbd`, `sup`, `sub`, `ruby`, `rt`, `span`, `br`

**Media**: `img`, `video` (poster placeholder), `audio` (placeholder)

---

## Supported CSS

**Box model**: `width`, `height`, `min/max-width`, `min/max-height`, `margin`, `padding`, `border`, `border-radius`, `box-shadow`

**Typography**: `color`, `font-size`, `font-weight`, `font-style`, `font-family`, `line-height`, `letter-spacing`, `text-align`, `text-decoration`, `text-transform`, `vertical-align`

**Layout**: `display` (block, inline, inline-block, flex, grid, none), `float`, `clear`, `overflow`, `position` (static, relative)

**List**: `list-style-type` (disc/circle/square/decimal/lower|upper-alpha|latin|roman/none), `list-style-position`, `list-style` shorthand

**Visual**: `background-color`, `background-image`, `background-repeat`, `background-position`, `opacity`, `transform`, `filter`, `backdrop-filter`

**CSS features**: custom properties (`var()`), `calc()`, `@keyframes`, specificity cascade, inheritance

---

## HyperRender Ecosystem

| Package | Description |
|---------|-------------|
| [hyper_render](https://pub.dev/packages/hyper_render) | Main package — `HyperViewer` widget, HTML + Markdown rendering |
| [hyper_render_core](https://pub.dev/packages/hyper_render_core) | Core engine: UDT model, `RenderHyperBox`, plugin API |
| **[hyper_render_html](https://pub.dev/packages/hyper_render_html)** | **HTML + CSS → UDT parser** ← you are here |
| [hyper_render_markdown](https://pub.dev/packages/hyper_render_markdown) | Markdown (GFM) → UDT parser |
| [hyper_render_highlight](https://pub.dev/packages/hyper_render_highlight) | Syntax highlighting for `<code>` / `<pre>` blocks |
| [hyper_render_clipboard](https://pub.dev/packages/hyper_render_clipboard) | Image copy / save / share *(opt-in)* |
| [hyper_render_math](https://pub.dev/packages/hyper_render_math) | LaTeX / MathML rendering *(opt-in)* |
| [hyper_render_devtools](https://pub.dev/packages/hyper_render_devtools) | Flutter DevTools inspector |

[Source](https://github.com/brewkits/hyper_render/tree/main/packages/hyper_render_html) · [Issues](https://github.com/brewkits/hyper_render/issues) · [Changelog](CHANGELOG.md)

---

## License

MIT — see [LICENSE](LICENSE).
