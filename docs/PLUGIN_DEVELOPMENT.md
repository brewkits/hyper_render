# Plugin Development Guide

This guide explains how to create custom plugins for HyperRender using the interface system.

## Available Plugin Interfaces

HyperRender provides several interfaces for extending functionality:

| Interface | Purpose | Example Plugin |
|-----------|---------|----------------|
| `ContentParser` | Parse content formats | HTML, Markdown, Delta |
| `CodeHighlighter` | Syntax highlighting | flutter_highlight, Prism |
| `CssParserInterface` | CSS parsing | csslib, custom parser |
| `ImageClipboardHandler` | Image clipboard operations | super_clipboard |

## Creating a Content Parser Plugin

### Step 1: Implement the Interface

```dart
import 'package:hyper_render/hyper_render.dart';

class MyCustomParser implements ContentParser {
  @override
  ContentType get contentType => ContentType.custom;

  @override
  DocumentNode parse(String content) {
    // Parse your content format into DocumentNode
    final root = DocumentNode();

    // Example: Simple text parser
    final lines = content.split('\n');
    for (final line in lines) {
      final block = BlockNode(tagName: 'p');
      block.children.add(TextNode(text: line));
      root.children.add(block);
    }

    return root;
  }

  @override
  DocumentNode parseWithOptions(
    String content, {
    String? baseUrl,
    String? customCss,
  }) {
    // Handle additional options
    return parse(content);
  }

  @override
  List<DocumentNode> parseToSections(String content, {int chunkSize = 3000}) {
    // For large content, split into sections for virtualization
    return [parse(content)];
  }
}
```

### Step 2: Use Your Parser

```dart
HyperViewer(
  content: myContent,
  contentParser: MyCustomParser(),
)
```

## Creating a Code Highlighter Plugin

### Step 1: Implement the Interface

```dart
import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

class PrismHighlighter implements CodeHighlighter {
  @override
  List<TextSpan> highlight(String code, String language) {
    // Use your highlighting library
    return [
      TextSpan(
        text: code,
        style: TextStyle(
          fontFamily: 'monospace',
          color: Colors.white,
        ),
      ),
    ];
  }

  @override
  Set<String> get supportedLanguages => {
    'javascript', 'typescript', 'dart', 'python', 'rust', 'go',
  };

  @override
  bool isLanguageSupported(String language) {
    return supportedLanguages.contains(language.toLowerCase());
  }

  @override
  TextStyle get defaultStyle => TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 14,
  );

  @override
  Color get backgroundColor => Color(0xFF1E1E1E);
}
```

### Step 2: Use Your Highlighter

```dart
HyperViewer(
  content: htmlWithCodeBlocks,
  contentParser: HtmlContentParser(),
  codeHighlighter: PrismHighlighter(),
)
```

## Creating an Image Clipboard Plugin

This is a real-world example from `hyper_render_clipboard`:

### Step 1: Implement the Interface

```dart
import 'dart:typed_data';
import 'package:hyper_render/hyper_render.dart';
import 'package:super_clipboard/super_clipboard.dart' show DataWriterItem, Formats, SystemClipboard;

class SuperClipboardHandler implements ImageClipboardHandler {
  @override
  Future<bool> copyImageFromUrl(String imageUrl) async {
    // Download and copy to clipboard
    final response = await http.get(Uri.parse(imageUrl));
    return copyImageBytes(response.bodyBytes);
  }

  @override
  Future<bool> copyImageBytes(Uint8List bytes, {String? mimeType}) async {
    // Use super_clipboard to copy
    final clipboard = SystemClipboard.instance;
    final item = DataWriterItem();
    item.add(Formats.png(bytes));
    await clipboard?.write([item]);
    return true;
  }

  @override
  Future<String?> saveImageFromUrl(String imageUrl, {String? filename}) async {
    // Download and save to device
    // ...
  }

  @override
  Future<String?> saveImageBytes(Uint8List bytes, {String? filename}) async {
    // Save bytes to device storage
    // ...
  }

  @override
  Future<bool> shareImageFromUrl(String imageUrl, {String? text}) async {
    // Share via system dialog
    // ...
  }

  @override
  Future<bool> shareImageBytes(Uint8List bytes, {String? text, String? filename}) async {
    // Share bytes via system dialog
    // ...
  }

  @override
  bool get isImageCopySupported => true;

  @override
  bool get isSaveSupported => true;

  @override
  bool get isShareSupported => true;

  @override
  List<String> get supportedFormats => ['image/png', 'image/jpeg', 'image/gif'];
}
```

## Creating a CSS Parser Plugin

```dart
import 'package:hyper_render/hyper_render.dart';

class CustomCssParser implements CssParserInterface {
  @override
  List<ParsedCssRule> parseStylesheet(String css) {
    // Parse CSS stylesheet
    final rules = <ParsedCssRule>[];

    // Your parsing logic here
    // ...

    return rules;
  }

  @override
  Map<String, String> parseInlineStyle(String style) {
    // Parse inline style attribute
    final properties = <String, String>{};

    // Example: "color: red; font-size: 16px"
    for (final declaration in style.split(';')) {
      final parts = declaration.split(':');
      if (parts.length == 2) {
        properties[parts[0].trim()] = parts[1].trim();
      }
    }

    return properties;
  }
}
```

## Publishing Your Plugin

### Package Structure

```
my_hyper_render_plugin/
├── lib/
│   ├── my_hyper_render_plugin.dart  # Public exports
│   └── src/
│       └── my_plugin_impl.dart       # Implementation
├── example/
│   └── main.dart
├── test/
│   └── my_plugin_test.dart
├── pubspec.yaml
├── README.md
└── CHANGELOG.md
```

### pubspec.yaml

```yaml
name: my_hyper_render_plugin
description: Custom plugin for HyperRender
version: 1.0.0

environment:
  sdk: '>=3.5.0 <4.0.0'
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  hyper_render_core: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

### Export Your Plugin

```dart
// lib/my_hyper_render_plugin.dart
library my_hyper_render_plugin;

export 'src/my_plugin_impl.dart';
```

## Best Practices

### 1. Handle Errors Gracefully

```dart
@override
DocumentNode parse(String content) {
  try {
    return _parseInternal(content);
  } catch (e) {
    debugPrint('Parse error: $e');
    // Return fallback content
    return DocumentNode()
      ..children.add(BlockNode(tagName: 'p')
        ..children.add(TextNode(text: content)));
  }
}
```

### 2. Support Async Parsing for Large Content

```dart
@override
List<DocumentNode> parseToSections(String content, {int chunkSize = 3000}) {
  if (content.length < chunkSize) {
    return [parse(content)];
  }

  // Split into chunks for virtualization
  final sections = <DocumentNode>[];
  // ...chunking logic
  return sections;
}
```

### 3. Make Dependencies Optional

```dart
class MyHighlighter implements CodeHighlighter {
  final bool _useAdvancedFeatures;

  MyHighlighter({bool advancedFeatures = false})
      : _useAdvancedFeatures = advancedFeatures;
}
```

### 4. Document Your Plugin

```dart
/// Custom highlighter using XYZ library
///
/// ## Features
/// - Supports 50+ languages
/// - Custom themes
/// - Line numbers
///
/// ## Usage
/// ```dart
/// HyperViewer(
///   content: code,
///   codeHighlighter: MyHighlighter(theme: 'monokai'),
/// )
/// ```
class MyHighlighter implements CodeHighlighter {
  // ...
}
```

## Testing Your Plugin

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_hyper_render_plugin/my_hyper_render_plugin.dart';

void main() {
  group('MyCustomParser', () {
    late MyCustomParser parser;

    setUp(() {
      parser = MyCustomParser();
    });

    test('parses simple content', () {
      final doc = parser.parse('Hello World');
      expect(doc.children.length, 1);
    });

    test('handles empty content', () {
      final doc = parser.parse('');
      expect(doc.children, isEmpty);
    });

    test('handles malformed content gracefully', () {
      expect(() => parser.parse('{{invalid}}'), returnsNormally);
    });
  });
}
```

## Example Plugins

- [hyper_render_clipboard](../packages/hyper_render_clipboard) - Image clipboard using super_clipboard
- [hyper_render_html](../packages/hyper_render_html) - HTML parsing (stub)
- [hyper_render_highlight](../packages/hyper_render_highlight) - Syntax highlighting (stub)
