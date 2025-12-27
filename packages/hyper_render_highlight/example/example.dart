/// HyperRender Highlight Plugin Example
///
/// This example shows how to add syntax highlighting to code blocks.
library;

import 'package:flutter/material.dart';
// In a real app:
// import 'package:hyper_render_core/hyper_render_core.dart';
// import 'package:hyper_render_html/hyper_render_html.dart';
// import 'package:hyper_render_highlight/hyper_render_highlight.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperRender Highlight Example',
      theme: ThemeData.dark(),
      home: const HighlightExamplePage(),
    );
  }
}

class HighlightExamplePage extends StatelessWidget {
  const HighlightExamplePage({super.key});

  static const String htmlWithCode = '''
<html>
<body>
  <h1>Code Highlighting Demo</h1>

  <h2>Dart</h2>
  <pre><code class="language-dart">
void main() {
  final greeting = 'Hello, World!';
  print(greeting);

  final numbers = [1, 2, 3, 4, 5];
  final doubled = numbers.map((n) => n * 2);
  print(doubled.toList());
}

class Person {
  final String name;
  final int age;

  Person(this.name, this.age);

  @override
  String toString() => 'Person(name: \$name, age: \$age)';
}
  </code></pre>

  <h2>JavaScript</h2>
  <pre><code class="language-javascript">
async function fetchData() {
  const response = await fetch('/api/data');
  const data = await response.json();
  return data;
}

const users = [
  { name: 'Alice', age: 30 },
  { name: 'Bob', age: 25 },
];

users.forEach(user => console.log(user.name));
  </code></pre>

  <h2>Python</h2>
  <pre><code class="language-python">
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

# Generate first 10 Fibonacci numbers
for i in range(10):
    print(f"F({i}) = {fibonacci(i)}")

class Calculator:
    def __init__(self):
        self.result = 0

    def add(self, value):
        self.result += value
        return self
  </code></pre>
</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Syntax Highlighting')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'Syntax Highlighting Plugin (PAID)\n\n'
          'Features:\n'
          '- 180+ languages supported\n'
          '- Multiple themes (Monokai, Dracula, etc.)\n'
          '- Line numbers\n'
          '- Copy button\n\n'
          'To use:\n'
          '1. Purchase license at sales@hyperrender.dev\n'
          '2. Add hyper_render_highlight to pubspec.yaml\n'
          '3. Use FlutterHighlighter() with HyperViewer',
        ),
      ),
      // In a real app:
      // body: HyperViewer(
      //   content: htmlWithCode,
      //   contentParser: HtmlContentParser(),
      //   codeHighlighter: FlutterHighlighter(theme: 'monokai'),
      // ),
    );
  }
}

/// Usage example:
///
/// ```dart
/// import 'package:hyper_render_core/hyper_render_core.dart';
/// import 'package:hyper_render_html/hyper_render_html.dart';
/// import 'package:hyper_render_highlight/hyper_render_highlight.dart';
///
/// class MyPage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return HyperViewer(
///       content: '<pre><code class="language-dart">void main() {}</code></pre>',
///       contentParser: HtmlContentParser(),
///       codeHighlighter: FlutterHighlighter(
///         theme: 'monokai',
///         showLineNumbers: true,
///       ),
///     );
///   }
/// }
/// ```
///
/// Available themes:
/// - 'monokai' (default)
/// - 'dracula'
/// - 'github'
/// - 'vs-dark'
/// - 'atom-one-dark'
/// - And many more...
