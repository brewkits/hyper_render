/// HyperRender Markdown Plugin Example
///
/// This example shows how to render Markdown content.
library;

import 'package:flutter/material.dart';
// In a real app:
// import 'package:hyper_render_core/hyper_render_core.dart';
// import 'package:hyper_render_markdown/hyper_render_markdown.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperRender Markdown Example',
      home: const MarkdownExamplePage(),
    );
  }
}

class MarkdownExamplePage extends StatelessWidget {
  const MarkdownExamplePage({super.key});

  static const String markdownContent = '''
# Hello HyperRender!

This is a paragraph with **bold** and *italic* text.

## Features

- Full Markdown support
- GitHub Flavored Markdown (GFM)
- Code blocks with syntax highlighting
- Tables

## Code Example

```dart
void main() {
  print('Hello, HyperRender!');
}
```

## Table

| Feature | Status |
|---------|--------|
| Headers | Done |
| Lists | Done |
| Code | Done |

## Links

Visit [Flutter](https://flutter.dev) for more info.

## Blockquote

> This is a blockquote.
> It can span multiple lines.

## Horizontal Rule

---

That's it!
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Markdown Example')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'See code comments for usage example.\n\n'
          'To use:\n'
          '1. Add hyper_render_core and hyper_render_markdown to pubspec.yaml\n'
          '2. Import both packages\n'
          '3. Use HyperViewer with MarkdownContentParser()',
        ),
      ),
      // In a real app:
      // body: HyperViewer(
      //   content: markdownContent,
      //   contentParser: MarkdownContentParser(),
      //   onLinkTap: (url) => launchUrl(Uri.parse(url)),
      // ),
    );
  }
}

/// Usage example:
///
/// ```dart
/// import 'package:hyper_render_core/hyper_render_core.dart';
/// import 'package:hyper_render_markdown/hyper_render_markdown.dart';
///
/// class MyPage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return HyperViewer(
///       content: '# Hello World\n\nThis is **Markdown**.',
///       contentParser: MarkdownContentParser(),
///     );
///   }
/// }
/// ```
