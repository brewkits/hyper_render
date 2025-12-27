/// HyperRender HTML Plugin Example
///
/// This example shows how to render HTML content.
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
      title: 'HyperRender HTML Example',
      home: const HtmlExamplePage(),
    );
  }
}

class HtmlExamplePage extends StatelessWidget {
  const HtmlExamplePage({super.key});

  static const String htmlContent = '''
<html>
<head>
  <style>
    body { font-family: sans-serif; padding: 16px; }
    h1 { color: #1976D2; }
    .highlight { background-color: #FFF9C4; padding: 4px 8px; }
    code { background: #F5F5F5; padding: 2px 6px; border-radius: 4px; }
  </style>
</head>
<body>
  <h1>Hello HyperRender!</h1>
  <p>This is a <strong>bold</strong> and <em>italic</em> text.</p>
  <p class="highlight">This paragraph has a highlight class.</p>
  <p>Inline code: <code>print("Hello World")</code></p>

  <h2>Features</h2>
  <ul>
    <li>Full CSS support</li>
    <li>Nested elements</li>
    <li>Tables with colspan/rowspan</li>
  </ul>

  <h2>Links</h2>
  <p>Visit <a href="https://flutter.dev">Flutter</a> for more info.</p>

  <h2>Code Block</h2>
  <pre><code class="language-dart">
void main() {
  print('Hello, HyperRender!');
}
  </code></pre>
</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HTML Example')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'See code comments for usage example.\n\n'
          'To use:\n'
          '1. Add hyper_render_core and hyper_render_html to pubspec.yaml\n'
          '2. Import both packages\n'
          '3. Use HyperViewer with HtmlContentParser()',
        ),
      ),
      // In a real app:
      // body: HyperViewer(
      //   content: htmlContent,
      //   contentParser: HtmlContentParser(),
      //   onLinkTap: (url) => launchUrl(Uri.parse(url)),
      // ),
    );
  }
}

/// Usage example:
///
/// ```dart
/// import 'package:hyper_render_core/hyper_render_core.dart';
/// import 'package:hyper_render_html/hyper_render_html.dart';
///
/// class MyPage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return HyperViewer(
///       content: '<p>Hello <strong>World</strong></p>',
///       contentParser: HtmlContentParser(),
///       onLinkTap: (url) {
///         print('Link tapped: $url');
///       },
///     );
///   }
/// }
/// ```
