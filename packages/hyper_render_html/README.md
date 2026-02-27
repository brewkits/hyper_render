# HyperRender HTML

HTML parsing plugin for HyperRender with full CSS support.

## Features

- **Full HTML Parsing** - Complete DOM parsing via `html` package
- **CSS Stylesheet Parsing** - Full CSS cascade via `csslib` package
- **Inline Style Support** - Parse style attributes
- **CSS Specificity** - Proper cascade resolution
- **Custom CSS** - Add your own stylesheets
- **Base URL Support** - Resolve relative URLs

## Installation

```yaml
dependencies:
  hyper_render_core: ^1.0.0
  hyper_render_html: ^1.0.0
```

## Usage

### Basic HTML Parsing

```dart
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_html/hyper_render_html.dart';

// Create parser
final parser = HtmlContentParser();

// Parse HTML to UDT
final document = parser.parse('''
  <h1>Welcome</h1>
  <p>This is <strong>bold</strong> and <em>italic</em> text.</p>
  <ul>
    <li>Item 1</li>
    <li>Item 2</li>
  </ul>
''');

// Render
HyperRenderWidget(document: document)
```

### With Custom CSS

```dart
final document = parser.parseWithOptions(
  '<div class="card"><h2>Title</h2><p>Content</p></div>',
  customCss: '''
    .card {
      background: #f5f5f5;
      padding: 16px;
      border-radius: 8px;
    }
    .card h2 {
      color: #333;
      margin-bottom: 8px;
    }
  ''',
);
```

### With Base URL

```dart
final document = parser.parseWithOptions(
  '<img src="/images/photo.jpg">',
  baseUrl: 'https://example.com',
);
// Image src resolves to: https://example.com/images/photo.jpg
```

### CSS Parser Standalone

```dart
import 'package:hyper_render_html/hyper_render_html.dart';

final cssParser = CsslibCssParser();

// Parse stylesheet
final rules = cssParser.parseStylesheet('''
  body { font-size: 16px; }
  .highlight { background: yellow; }
  #header { font-weight: bold; }
''');

// Parse inline style
final props = cssParser.parseInlineStyle('color: red; margin: 10px');
// {'color': 'red', 'margin': '10px'}
```

## Supported HTML Elements

### Block Elements
- Headings: `h1`, `h2`, `h3`, `h4`, `h5`, `h6`
- Paragraphs: `p`, `div`, `article`, `section`
- Lists: `ul`, `ol`, `li`
- Blockquote: `blockquote`
- Pre/Code: `pre`, `code`
- Tables: `table`, `tr`, `td`, `th`, `thead`, `tbody`

### Inline Elements
- Text formatting: `strong`, `b`, `em`, `i`, `u`, `s`, `del`, `ins`
- Links: `a`
- Code: `code`, `kbd`, `samp`
- Ruby: `ruby`, `rt`, `rp`
- Misc: `span`, `br`, `sup`, `sub`

### Media Elements
- Images: `img`
- Video: `video` (placeholder)
- Audio: `audio` (placeholder)

## Supported CSS Properties

### Box Model
- `width`, `height`, `min-width`, `max-width`, `min-height`, `max-height`
- `margin`, `margin-top`, `margin-right`, `margin-bottom`, `margin-left`
- `padding`, `padding-top`, `padding-right`, `padding-bottom`, `padding-left`
- `border`, `border-width`, `border-color`, `border-radius`

### Typography
- `color`, `font-size`, `font-weight`, `font-style`, `font-family`
- `line-height`, `letter-spacing`, `word-spacing`
- `text-align`, `text-decoration`, `text-transform`
- `white-space`, `vertical-align`

### Layout
- `display` (block, inline, inline-block, flex, none)
- `float`, `clear`
- `overflow`, `overflow-x`, `overflow-y`
- `position` (static, relative)

### Visual
- `background-color`, `background-image`
- `opacity`
- `transform`

## License

MIT License - see LICENSE file for details.
