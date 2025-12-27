# HyperRender Markdown

Markdown parsing plugin for HyperRender.

## Installation

```yaml
dependencies:
  hyper_render_core: ^2.0.0
  hyper_render_markdown: ^2.0.0
```

## Features

- Full Markdown support
- GitHub Flavored Markdown (GFM)
- Code blocks with syntax highlighting
- Tables, task lists, and more

## Usage

```dart
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_markdown/hyper_render_markdown.dart';

HyperViewer(
  content: '''
# Hello World

This is **bold** and *italic* text.

## Features

- Item 1
- Item 2
- Item 3

```dart
void main() {
  print('Hello, HyperRender!');
}
```
  ''',
  contentParser: MarkdownContentParser(),
)
```

## Supported Syntax

- Headers: `#`, `##`, `###`, etc.
- Emphasis: `*italic*`, `**bold**`, `***bold italic***`
- Lists: `-`, `*`, `1.`, `2.`
- Links: `[text](url)`
- Images: `![alt](url)`
- Code: `` `inline` ``, ` ``` `block` ``` `
- Blockquotes: `>`
- Horizontal rules: `---`
- Tables (GFM)
- Task lists (GFM): `- [ ]`, `- [x]`

## Dependencies

- `markdown: ^7.2.2` - Dart team Markdown parser

## License

MIT License
