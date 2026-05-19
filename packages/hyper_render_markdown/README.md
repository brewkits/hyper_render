# hyper_render_markdown

Markdown parsing plugin for [HyperRender](https://pub.dev/packages/hyper_render) with GitHub Flavored Markdown (GFM) support.

---

## Installation

```yaml
dependencies:
  hyper_render_core: ^1.3.2
  hyper_render_markdown: ^1.3.2
```

---

## Usage

```dart
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_markdown/hyper_render_markdown.dart';

final document = MarkdownContentParser().parse('''
# Hello

This is **bold** and *italic* text.

- Item 1
- Item 2

```dart
void main() => print('Hello');
```
''');

HyperRenderWidget(document: document)
```

### GFM options

```dart
final parser = MarkdownContentParser(
  enableGfm: true,        // GitHub Flavored Markdown (default: true)
  enableInlineHtml: true, // allow inline HTML
);
```

### With syntax highlighting

```dart
import 'package:hyper_render_highlight/hyper_render_highlight.dart';

HyperRenderWidget(
  document: MarkdownContentParser().parse(markdownWithCode),
  codeHighlighter: FlutterHighlightCodeHighlighter(
    theme: HighlightTheme.atomOneDark,
  ),
)
```

---

## Supported GFM features

| Feature | Syntax |
|---------|--------|
| Tables | `\| col \| col \|` |
| Task lists | `- [x]` / `- [ ]` |
| Strikethrough | `~~text~~` |
| Fenced code blocks | ` ```lang ``` ` |
| Autolinks | `https://...` |

---

## HyperRender Ecosystem

| Package | Description |
|---------|-------------|
| [hyper_render](https://pub.dev/packages/hyper_render) | Main package — `HyperViewer` widget, HTML + Markdown rendering |
| [hyper_render_core](https://pub.dev/packages/hyper_render_core) | Core engine: UDT model, `RenderHyperBox`, plugin API |
| [hyper_render_html](https://pub.dev/packages/hyper_render_html) | HTML + CSS → UDT parser |
| **[hyper_render_markdown](https://pub.dev/packages/hyper_render_markdown)** | **Markdown (GFM) → UDT parser** ← you are here |
| [hyper_render_highlight](https://pub.dev/packages/hyper_render_highlight) | Syntax highlighting for `<code>` / `<pre>` blocks |
| [hyper_render_clipboard](https://pub.dev/packages/hyper_render_clipboard) | Image copy / save / share *(opt-in)* |
| [hyper_render_math](https://pub.dev/packages/hyper_render_math) | LaTeX / MathML rendering *(opt-in)* |
| [hyper_render_devtools](https://pub.dev/packages/hyper_render_devtools) | Flutter DevTools inspector |

[Source](https://github.com/brewkits/hyper_render/tree/main/packages/hyper_render_markdown) · [Issues](https://github.com/brewkits/hyper_render/issues) · [Changelog](CHANGELOG.md)

---

## License

MIT — see [LICENSE](LICENSE).
