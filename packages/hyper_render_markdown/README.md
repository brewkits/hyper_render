# HyperRender Markdown

Markdown parsing plugin for HyperRender with GitHub Flavored Markdown support.

## Features

- **GitHub Flavored Markdown (GFM)** - Tables, strikethrough, task lists, autolinks
- **Code Blocks** - Fenced code blocks with language hints
- **Tables** - Full GFM table support
- **Task Lists** - Checkbox lists
- **Inline HTML** - Optional HTML within Markdown
- **Images & Links** - Full support with titles

## Installation

```yaml
dependencies:
  hyper_render_core: ^1.0.0
  hyper_render_markdown: ^1.0.0
```

## Usage

### Basic Markdown Parsing

```dart
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_markdown/hyper_render_markdown.dart';

// Create parser
final parser = MarkdownContentParser();

// Parse Markdown to UDT
final document = parser.parse('''
# Welcome to HyperRender

This is **bold** and *italic* text.

## Features

- Item 1
- Item 2
- Item 3

```dart
void main() {
  print('Hello, World!');
}
```
''');

// Render
HyperRenderWidget(document: document)
```

### With Options

```dart
final parser = MarkdownContentParser(
  enableGfm: true,        // GitHub Flavored Markdown
  enableInlineHtml: true, // Allow inline HTML
);

final document = parser.parse(markdownContent);
```

### Convenience Function

```dart
import 'package:hyper_render_markdown/hyper_render_markdown.dart';

// Quick parsing
final document = parseMarkdown('# Hello World');
```

### Using MarkdownAdapter Directly

```dart
final adapter = MarkdownAdapter(
  enableGfm: true,
  enableInlineHtml: false,
);

final document = adapter.parse(markdownContent);
```

## Supported Markdown Syntax

### Headings
```markdown
# H1
## H2
### H3
#### H4
##### H5
###### H6
```

### Text Formatting
```markdown
**bold** or __bold__
*italic* or _italic_
~~strikethrough~~ (GFM)
`inline code`
```

### Links & Images
```markdown
[Link text](https://example.com)
[Link with title](https://example.com "Title")
![Alt text](image.jpg)
![Alt text](image.jpg "Image title")
```

### Lists
```markdown
- Unordered item
- Another item
  - Nested item

1. Ordered item
2. Another item
   1. Nested item

- [x] Task completed (GFM)
- [ ] Task pending (GFM)
```

### Blockquotes
```markdown
> This is a blockquote
>
> Multiple paragraphs
```

### Code Blocks
````markdown
```dart
void main() {
  print('Hello');
}
```
````

### Tables (GFM)
```markdown
| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |
| Cell 3   | Cell 4   |
```

### Horizontal Rule
```markdown
---
***
___
```

## Integration with Syntax Highlighting

```dart
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_markdown/hyper_render_markdown.dart';
import 'package:hyper_render_highlight/hyper_render_highlight.dart';

final parser = MarkdownContentParser();
final highlighter = FlutterHighlightCodeHighlighter(
  theme: HighlightTheme.dracula,
);

final document = parser.parse(markdownWithCode);

HyperRenderWidget(
  document: document,
  codeHighlighter: highlighter,
)
```

## License

MIT License - see LICENSE file for details.
