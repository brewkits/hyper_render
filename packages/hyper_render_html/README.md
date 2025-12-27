# HyperRender HTML

HTML parsing plugin for HyperRender.

## Installation

```yaml
dependencies:
  hyper_render_core: ^2.0.0
  hyper_render_html: ^2.0.0
```

## Features

- Full HTML parsing with proper DOM tree
- CSS parsing and style resolution
- Support for inline styles and `<style>` tags
- Handles nested elements and complex markup

## Usage

```dart
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_html/hyper_render_html.dart';

HyperViewer(
  content: '''
    <html>
    <head>
      <style>
        h1 { color: blue; }
        .highlight { background: yellow; }
      </style>
    </head>
    <body>
      <h1>Hello World</h1>
      <p class="highlight">This is highlighted text.</p>
    </body>
    </html>
  ''',
  contentParser: HtmlContentParser(),
  onLinkTap: (url) => launchUrl(Uri.parse(url)),
)
```

## Supported HTML Elements

- Text: `p`, `span`, `div`, `h1`-`h6`
- Formatting: `strong`, `b`, `em`, `i`, `u`, `s`, `del`, `ins`
- Lists: `ul`, `ol`, `li`
- Tables: `table`, `tr`, `td`, `th` (with colspan/rowspan)
- Links: `a`
- Images: `img`
- Code: `pre`, `code`
- Ruby: `ruby`, `rt`, `rp`
- And more...

## CSS Support

- Selectors: element, class, id, attribute
- Box model: margin, padding, border
- Typography: font-family, font-size, color, etc.
- Layout: display, float, clear
- See full list in documentation

## Dependencies

- `html: ^0.15.6` - Dart team HTML parser
- `csslib: ^1.0.0` - Dart team CSS parser

## License

MIT License
