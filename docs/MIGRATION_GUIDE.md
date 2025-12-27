# Migration Guide: HyperRender 1.x to 2.0

This guide explains the architectural changes in HyperRender 2.0 and how to migrate your code.

## Overview of Changes

### HyperRender 1.x (Current - Bundled Approach)
- Single package with all dependencies bundled
- Simple installation: just add `hyper_render: ^1.0.0`
- All parsers (HTML, Markdown, Delta) included
- All features (syntax highlighting, etc.) included

### HyperRender 2.0 (Modular Approach)
- Zero-dependency core package
- Pick only the plugins you need
- Better tree-shaking and smaller bundle sizes
- Plugin system for extensibility

## Package Structure in 2.0

```yaml
# Minimal setup (choose your parser)
dependencies:
  hyper_render_core: ^2.0.0       # Core engine (zero deps)
  hyper_render_html: ^2.0.0       # HTML parsing plugin

# Full setup
dependencies:
  hyper_render_core: ^2.0.0
  hyper_render_html: ^2.0.0       # HTML parsing
  hyper_render_markdown: ^2.0.0   # Markdown parsing
  hyper_render_highlight: ^2.0.0  # Syntax highlighting (paid)
  hyper_render_clipboard: ^2.0.0  # Image clipboard support
```

## Migration Steps

### Step 1: Update Dependencies

**Before (1.x):**
```yaml
dependencies:
  hyper_render: ^1.0.0
```

**After (2.0):**
```yaml
dependencies:
  hyper_render_core: ^2.0.0
  hyper_render_html: ^2.0.0  # If using HTML
  # Add other plugins as needed
```

### Step 2: Update Imports

**Before (1.x):**
```dart
import 'package:hyper_render/hyper_render.dart';
```

**After (2.0):**
```dart
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_html/hyper_render_html.dart';
```

### Step 3: Update Widget Usage

**Before (1.x) - Automatic parser selection:**
```dart
HyperViewer(
  html: '<p>Hello World</p>',
)
```

**After (2.0) - Explicit parser:**
```dart
HyperViewer(
  content: '<p>Hello World</p>',
  contentParser: HtmlContentParser(),
)
```

### Step 4: Custom Plugins (Optional)

If you were using custom implementations, update to use the new interfaces:

**Before (1.x):**
```dart
// Custom code highlighter (limited options)
HyperViewer(
  html: content,
  // No custom highlighter option
)
```

**After (2.0):**
```dart
// Implement CodeHighlighter interface
class MyCustomHighlighter implements CodeHighlighter {
  @override
  List<TextSpan> highlight(String code, String language) {
    // Your implementation
  }

  @override
  Set<String> get supportedLanguages => {'dart', 'python'};
}

HyperViewer(
  content: content,
  contentParser: HtmlContentParser(),
  codeHighlighter: MyCustomHighlighter(),
)
```

## Feature Comparison

| Feature | 1.x Location | 2.0 Location |
|---------|-------------|--------------|
| HTML Parsing | Built-in | `hyper_render_html` |
| Markdown Parsing | Built-in | `hyper_render_markdown` |
| Delta Parsing | Built-in | `hyper_render_delta` |
| Syntax Highlighting | Built-in | `hyper_render_highlight` |
| Image Clipboard | Built-in (basic) | `hyper_render_clipboard` |
| Core Rendering | Built-in | `hyper_render_core` |

## Interface Reference

### ContentParser (for custom parsers)

```dart
abstract class ContentParser {
  /// The type of content this parser handles
  ContentType get contentType;

  /// Parse content string into DocumentNode
  DocumentNode parse(String content);

  /// Parse with additional options
  DocumentNode parseWithOptions(
    String content, {
    String? baseUrl,
    String? customCss,
  });

  /// Parse into sections for virtualization
  List<DocumentNode> parseToSections(String content, {int chunkSize = 3000});
}
```

### CodeHighlighter (for syntax highlighting)

```dart
abstract class CodeHighlighter {
  /// Highlight code and return TextSpans
  List<TextSpan> highlight(String code, String language);

  /// Set of supported language identifiers
  Set<String> get supportedLanguages;

  /// Check if a language is supported
  bool isLanguageSupported(String language);
}
```

### ImageClipboardHandler (for image operations)

```dart
abstract class ImageClipboardHandler {
  Future<bool> copyImageFromUrl(String imageUrl);
  Future<bool> copyImageBytes(Uint8List bytes, {String? mimeType});
  Future<String?> saveImageFromUrl(String imageUrl, {String? filename});
  Future<String?> saveImageBytes(Uint8List bytes, {String? filename});
  Future<bool> shareImageFromUrl(String imageUrl, {String? text});
  Future<bool> shareImageBytes(Uint8List bytes, {String? text, String? filename});

  bool get isImageCopySupported;
  bool get isSaveSupported;
  bool get isShareSupported;
  List<String> get supportedFormats;
}
```

## Staying on 1.x

If you prefer the bundled approach, you can continue using version 1.x:

```yaml
dependencies:
  hyper_render: ^1.0.0  # Stays on bundled version
```

The 1.x branch will receive bug fixes but new features will be added to 2.0.

## Benefits of 2.0

1. **Smaller Bundle Size** - Only include what you use
2. **No Dependency Conflicts** - Choose your own versions of parsing libraries
3. **Extensibility** - Create custom plugins
4. **Better Testing** - Mock interfaces easily
5. **Community Plugins** - Third-party plugins possible

## Need Help?

- [GitHub Issues](https://github.com/user/hyper_render/issues)
- [Documentation](https://github.com/user/hyper_render/docs)
- [Examples](https://github.com/user/hyper_render/example)
