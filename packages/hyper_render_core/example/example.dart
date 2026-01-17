// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

/// Example demonstrating direct usage of hyper_render_core
/// without any parsing plugins.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperRender Core Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CoreExamplePage(),
    );
  }
}

class CoreExamplePage extends StatelessWidget {
  const CoreExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Create document manually using UDT nodes
    final document = _createDocument();

    return Scaffold(
      appBar: AppBar(
        title: const Text('HyperRender Core Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: HyperRenderWidget(document: document),
      ),
    );
  }

  /// Create a document manually using UDT nodes
  DocumentNode _createDocument() {
    return DocumentNode(
      children: [
        // Heading
        BlockNode(
          tagName: 'h1',
          children: [TextNode('Welcome to HyperRender Core')],
        ),

        // Paragraph with mixed styles
        BlockNode(
          tagName: 'p',
          children: [
            TextNode('This example demonstrates '),
            InlineNode(
              tagName: 'strong',
              children: [TextNode('direct document creation')],
            ),
            TextNode(' without using any parsing plugins.'),
          ],
        ),

        // Another paragraph
        BlockNode(
          tagName: 'p',
          children: [
            TextNode('You can create '),
            InlineNode(
              tagName: 'em',
              children: [TextNode('italic')],
            ),
            TextNode(', '),
            InlineNode(
              tagName: 'strong',
              children: [TextNode('bold')],
            ),
            TextNode(', and '),
            InlineNode(
              tagName: 'code',
              children: [TextNode('inline code')],
            ),
            TextNode(' styles.'),
          ],
        ),

        // Subheading
        BlockNode(
          tagName: 'h2',
          children: [TextNode('Features')],
        ),

        // Unordered list
        BlockNode(
          tagName: 'ul',
          children: [
            BlockNode(
              tagName: 'li',
              children: [TextNode('Zero external dependencies')],
            ),
            BlockNode(
              tagName: 'li',
              children: [TextNode('Universal Document Tree (UDT)')],
            ),
            BlockNode(
              tagName: 'li',
              children: [TextNode('Plugin architecture')],
            ),
            BlockNode(
              tagName: 'li',
              children: [TextNode('CJK typography support')],
            ),
          ],
        ),

        // Code block
        BlockNode(
          tagName: 'pre',
          children: [
            BlockNode(
              tagName: 'code',
              children: [
                TextNode('''void main() {
  final doc = DocumentNode(children: [
    BlockNode(tagName: 'p', children: [
      TextNode('Hello World'),
    ]),
  ]);
  print(doc);
}'''),
              ],
            ),
          ],
        ),

        // Blockquote
        BlockNode(
          tagName: 'blockquote',
          children: [
            BlockNode(
              tagName: 'p',
              children: [
                TextNode(
                    'HyperRender Core provides the foundation for all content rendering.'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Example: Creating styled nodes with ComputedStyle
void computedStyleExample() {
  // Create a style
  final style = ComputedStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF333333),
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    backgroundColor: const Color(0xFFF5F5F5),
    borderRadius: BorderRadius.circular(8),
  );

  // Apply to a node (style is set via constructor)
  final node = BlockNode(tagName: 'div', style: style);

  print('Node style: fontSize=${node.style.fontSize}');
}

/// Example: Using interfaces for custom implementations
void interfaceExample() {
  // PlainTextHighlighter is a built-in no-op highlighter
  const highlighter = PlainTextHighlighter();

  // Check supported languages
  print('Supported: ${highlighter.supportedLanguages}');

  // Highlight code (returns plain text spans)
  final spans = highlighter.highlight('print("hello")', 'dart');
  print('Spans: ${spans.length}');
}
