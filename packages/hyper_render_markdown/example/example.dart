import 'package:flutter/material.dart';
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_markdown/hyper_render_markdown.dart';

/// Example demonstrating Markdown parsing with hyper_render_markdown
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperRender Markdown Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MarkdownExamplePage(),
    );
  }
}

class MarkdownExamplePage extends StatelessWidget {
  const MarkdownExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Parse Markdown to UDT
    const parser = MarkdownContentParser(
      enableGfm: true,
      enableInlineHtml: true,
    );
    final document = parser.parse(_sampleMarkdown);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HyperRender Markdown Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: HyperRenderWidget(document: document),
      ),
    );
  }
}

/// Sample Markdown content
const _sampleMarkdown = '''
# Welcome to HyperRender Markdown

This example demonstrates **Markdown parsing** with *GitHub Flavored Markdown* support.

## Text Formatting

You can use various text styles:

- **Bold text** with `**text**` or `__text__`
- *Italic text* with `*text*` or `_text_`
- ~~Strikethrough~~ with `~~text~~` (GFM)
- `Inline code` with backticks

## Links and Images

Links are easy: [Visit Flutter](https://flutter.dev)

Images too: ![Flutter Logo](https://flutter.dev/assets/images/shared/brand/flutter/logo/flutter-lockup.png)

## Lists

### Unordered List
- Item 1
- Item 2
  - Nested item 2.1
  - Nested item 2.2
- Item 3

### Ordered List
1. First item
2. Second item
3. Third item

### Task List (GFM)
- [x] Task completed
- [x] Another done task
- [ ] Task pending
- [ ] Another pending task

## Blockquotes

> HyperRender provides a high-performance rendering engine for Flutter.
>
> It supports perfect text selection and advanced CSS.

## Code Blocks

Inline code: `const x = 42;`

Fenced code block:

```dart
void main() {
  final parser = MarkdownContentParser();
  final document = parser.parse('# Hello World');

  runApp(MaterialApp(
    home: HyperRenderWidget(document: document),
  ));
}
```

## Tables (GFM)

| Feature | Status | Notes |
|---------|--------|-------|
| Headings | ✓ | H1-H6 supported |
| Bold/Italic | ✓ | Standard syntax |
| Lists | ✓ | Nested supported |
| Tables | ✓ | GFM tables |
| Code | ✓ | Fenced blocks |

## Horizontal Rule

---

## Nested Formatting

You can **combine _different_ formatting** styles together.

Even `code with **bold** inside` (though bold won't render in code).

## HTML in Markdown

When `enableInlineHtml` is true:

<div style="background: #f0f0f0; padding: 10px; border-radius: 4px;">
  <strong>This is HTML inside Markdown!</strong>
</div>

---

*That's all for this example!*
''';

/// Example: Quick parsing with convenience function
void quickParseExample() {
  // Use the convenience function
  final document = parseMarkdown('# Hello World\n\nThis is **bold** text.');

  // ignore: avoid_print
  print('Document has ${document.children.length} children');
}

/// Example: Parsing without GFM
void noGfmExample() {
  const parser = MarkdownContentParser(
    enableGfm: false, // Disable GFM extensions
    enableInlineHtml: false, // Disable inline HTML
  );

  // ignore: unused_local_variable
  final document = parser.parse('''
# Standard Markdown

This is standard Markdown without GFM extensions.

~~This won't be strikethrough~~

| Tables | Won't | Work |
''');

  // ignore: avoid_print
  print('Parsed without GFM');
}

/// Example: Using MarkdownAdapter directly
void adapterExample() {
  final adapter = MarkdownAdapter(
    enableGfm: true,
    enableInlineHtml: true,
  );

  final document = adapter.parse('''
# Direct Adapter Usage

Using `MarkdownAdapter` directly gives you the same result.
''');

  // ignore: avoid_print
  print('Document type: ${document.runtimeType}');
}

/// Example: Parsing to sections for virtualization
void sectionsExample() {
  const parser = MarkdownContentParser();

  // For very long content, parse to sections
  final sections = parser.parseToSections(
    _sampleMarkdown,
    chunkSize: 1000, // Characters per chunk
  );

  // ignore: avoid_print
  print('Parsed into ${sections.length} sections');

  // Use with ListView.builder for virtualization
  // ListView.builder(
  //   itemCount: sections.length,
  //   itemBuilder: (context, index) {
  //     return HyperRenderWidget(document: sections[index]);
  //   },
  // );
}
