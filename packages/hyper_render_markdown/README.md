# hyper_render_markdown

Markdown parsing plugin for [HyperRender](https://pub.dev/packages/hyper_render) with GitHub Flavored Markdown (GFM) support.

---

## Installation

```yaml
dependencies:
  hyper_render_core: ^1.2.0
  hyper_render_markdown: ^1.2.0
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

## License

MIT — see [LICENSE](LICENSE).
