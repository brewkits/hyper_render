# HyperRender Core

The core rendering engine for HyperRender with **zero external dependencies**.

## Installation

```yaml
dependencies:
  hyper_render_core: ^2.0.0
  hyper_render_html: ^2.0.0  # Choose your parser
```

## Features

- Plugin interfaces for extensibility
- Core models (DocumentNode, ComputedStyle, etc.)
- Base rendering logic
- Zero external dependencies (Flutter only)

## Usage

```dart
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_html/hyper_render_html.dart';

HyperViewer(
  content: '<p>Hello <strong>World</strong></p>',
  contentParser: HtmlContentParser(),
)
```

## Plugin System

HyperRender Core provides interfaces for creating plugins:

| Interface | Purpose |
|-----------|---------|
| `ContentParser` | Parse content (HTML, Markdown, Delta) |
| `CodeHighlighter` | Syntax highlighting |
| `CssParserInterface` | CSS parsing |
| `ImageClipboardHandler` | Image clipboard operations |

## Creating Custom Plugins

See [Plugin Development Guide](../../docs/PLUGIN_DEVELOPMENT.md) for details.

## Available Plugins

| Package | Description | Status |
|---------|-------------|--------|
| `hyper_render_html` | HTML parsing | Free |
| `hyper_render_markdown` | Markdown parsing | Free |
| `hyper_render_highlight` | Syntax highlighting | Paid |
| `hyper_render_clipboard` | Image clipboard | Free |

## License

MIT License
