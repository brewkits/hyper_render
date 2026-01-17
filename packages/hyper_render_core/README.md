# HyperRender Core

Zero-dependency core rendering engine for HyperRender.

## Features

- **Universal Document Tree (UDT)** - Unified data model for all content types
- **Custom RenderObject Layout Engine** - High-performance rendering
- **Fragment-based Inline Layout** - Advanced text layout with float support
- **CJK Line-breaking (Kinsoku)** - Proper Japanese/Chinese/Korean typography
- **Ruby/Furigana Support** - Japanese reading annotations
- **Text Selection** - Native-feeling selection with handles
- **CSS Cascade Resolution** - Full CSS specificity and inheritance

## Installation

```yaml
dependencies:
  hyper_render_core: ^2.0.0
```

## Zero External Dependencies

This package only depends on Flutter SDK. Parsing (HTML, Markdown, CSS) and syntax highlighting are provided by separate plugin packages:

- `hyper_render_html` - HTML parsing with CSS support
- `hyper_render_markdown` - Markdown parsing (GFM)
- `hyper_render_highlight` - Syntax highlighting for code blocks
- `hyper_render_clipboard` - Advanced image clipboard operations

## Usage

### Direct Document Creation

```dart
import 'package:hyper_render_core/hyper_render_core.dart';

// Create document manually
final document = DocumentNode(children: [
  BlockNode(tagName: 'h1', children: [TextNode(text: 'Hello World')]),
  BlockNode(tagName: 'p', children: [
    TextNode(text: 'Welcome to '),
    InlineNode(tagName: 'strong', children: [TextNode(text: 'HyperRender')]),
    TextNode(text: '!'),
  ]),
]);

// Render with HyperRenderWidget
HyperRenderWidget(document: document)
```

### With Content Parser Plugin

```dart
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_html/hyper_render_html.dart';

// Parse HTML to UDT
final parser = HtmlContentParser();
final document = parser.parse('<h1>Hello</h1><p>World</p>');

// Render
HyperRenderWidget(document: document)
```

## Plugin Interfaces

HyperRender Core provides interfaces for extending functionality:

### ContentParser

For content parsing (HTML, Markdown, Delta):

```dart
abstract class ContentParser {
  ContentType get contentType;
  DocumentNode parse(String content);
  DocumentNode parseWithOptions(String content, {String? baseUrl, String? customCss});
  List<DocumentNode> parseToSections(String content, {int chunkSize = 3000});
}
```

### CodeHighlighter

For code syntax highlighting:

```dart
abstract class CodeHighlighter {
  List<TextSpan> highlight(String code, String language);
  Set<String> get supportedLanguages;
  bool isLanguageSupported(String language);
  TextStyle get defaultStyle;
  Color get backgroundColor;
}
```

### CssParserInterface

For CSS stylesheet parsing:

```dart
abstract class CssParserInterface {
  List<ParsedCssRule> parseStylesheet(String css);
  Map<String, String> parseInlineStyle(String style);
}
```

### ImageClipboardHandler

For image clipboard operations:

```dart
abstract class ImageClipboardHandler {
  Future<bool> copyImageFromUrl(String imageUrl);
  Future<bool> copyImageBytes(Uint8List bytes, {String? mimeType});
  Future<String?> saveImageFromUrl(String imageUrl, {String? filename});
  // ... more methods
}
```

## UDT Node Types

| Node Type | Description | Example Tags |
|-----------|-------------|--------------|
| `DocumentNode` | Root container | - |
| `BlockNode` | Block-level element | div, p, h1-h6, ul, ol |
| `InlineNode` | Inline element | span, a, strong, em |
| `TextNode` | Text content | - |
| `LineBreakNode` | Line break | br |
| `AtomicNode` | Non-text inline | img, video |
| `RubyNode` | Ruby annotation | ruby |
| `TableNode` | Table structure | table |
| `TableRowNode` | Table row | tr |
| `TableCellNode` | Table cell | td, th |

## ComputedStyle

All CSS properties are resolved into `ComputedStyle`:

```dart
final style = ComputedStyle(
  fontSize: 16.0,
  fontWeight: FontWeight.bold,
  color: Color(0xFF333333),
  margin: EdgeInsets.all(8),
  padding: EdgeInsets.symmetric(horizontal: 16),
  display: DisplayType.block,
);
```

## License

MIT License - see LICENSE file for details.
