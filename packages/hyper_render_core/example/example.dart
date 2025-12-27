/// HyperRender Core Example
///
/// This example shows how to use the core package with custom plugins.
library;

import 'package:flutter/material.dart';
// In a real app:
// import 'package:hyper_render_core/hyper_render_core.dart';
// import 'package:hyper_render_html/hyper_render_html.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperRender Core Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('HyperRender Core')),
        body: const Center(
          child: Text('See documentation for usage'),
          // In a real app:
          // HyperViewer(
          //   content: '<p>Hello World</p>',
          //   contentParser: HtmlContentParser(),
          // )
        ),
      ),
    );
  }
}

/// Example: Creating a custom content parser
///
/// ```dart
/// class PlainTextParser implements ContentParser {
///   @override
///   ContentType get contentType => ContentType.plainText;
///
///   @override
///   DocumentNode parse(String content) {
///     final root = DocumentNode();
///     for (final line in content.split('\n')) {
///       final block = BlockNode(tagName: 'p');
///       block.children.add(TextNode(text: line));
///       root.children.add(block);
///     }
///     return root;
///   }
///
///   @override
///   DocumentNode parseWithOptions(String content, {String? baseUrl, String? customCss}) {
///     return parse(content);
///   }
///
///   @override
///   List<DocumentNode> parseToSections(String content, {int chunkSize = 3000}) {
///     return [parse(content)];
///   }
/// }
/// ```

/// Example: Creating a custom code highlighter
///
/// ```dart
/// class SimpleHighlighter implements CodeHighlighter {
///   @override
///   List<TextSpan> highlight(String code, String language) {
///     return [TextSpan(text: code, style: TextStyle(fontFamily: 'monospace'))];
///   }
///
///   @override
///   Set<String> get supportedLanguages => {'dart', 'javascript'};
///
///   @override
///   bool isLanguageSupported(String language) => supportedLanguages.contains(language);
///
///   @override
///   TextStyle get defaultStyle => TextStyle(fontFamily: 'monospace');
///
///   @override
///   Color get backgroundColor => Colors.grey[900]!;
/// }
/// ```
