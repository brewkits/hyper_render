import 'package:flutter/material.dart';
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_highlight/hyper_render_highlight.dart';

/// Example demonstrating syntax highlighting with hyper_render_highlight
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperRender Highlight Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const HighlightExamplePage(),
    );
  }
}

class HighlightExamplePage extends StatefulWidget {
  const HighlightExamplePage({super.key});

  @override
  State<HighlightExamplePage> createState() => _HighlightExamplePageState();
}

class _HighlightExamplePageState extends State<HighlightExamplePage> {
  HighlightTheme _selectedTheme = HighlightTheme.dracula;

  @override
  Widget build(BuildContext context) {
    // Create highlighter with selected theme
    final highlighter = FlutterHighlightCodeHighlighter(
      theme: _selectedTheme,
    );

    // Create a simple document with code blocks
    final document = _createCodeDocument();

    return Scaffold(
      appBar: AppBar(
        title: const Text('HyperRender Highlight Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Theme selector
          PopupMenuButton<HighlightTheme>(
            icon: const Icon(Icons.palette),
            tooltip: 'Select Theme',
            onSelected: (theme) {
              setState(() {
                _selectedTheme = theme;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: HighlightTheme.dracula,
                child: Text('Dracula'),
              ),
              const PopupMenuItem(
                value: HighlightTheme.atomOneDark,
                child: Text('Atom One Dark'),
              ),
              const PopupMenuItem(
                value: HighlightTheme.atomOneLight,
                child: Text('Atom One Light'),
              ),
              const PopupMenuItem(
                value: HighlightTheme.github,
                child: Text('GitHub'),
              ),
              const PopupMenuItem(
                value: HighlightTheme.vs2015,
                child: Text('VS2015'),
              ),
              const PopupMenuItem(
                value: HighlightTheme.monokaiSublime,
                child: Text('Monokai Sublime'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Theme: ${_selectedTheme.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            HyperRenderWidget(
              document: document,
              codeHighlighter: highlighter,
            ),
          ],
        ),
      ),
    );
  }

  /// Create a document with various code blocks
  DocumentNode _createCodeDocument() {
    return DocumentNode(
      children: [
        BlockNode(
          tagName: 'h1',
          children: [TextNode('Syntax Highlighting Examples')],
        ),

        // Dart code
        BlockNode(
          tagName: 'h2',
          children: [TextNode('Dart')],
        ),
        _createCodeBlock('dart', _dartCode),

        // JavaScript code
        BlockNode(
          tagName: 'h2',
          children: [TextNode('JavaScript')],
        ),
        _createCodeBlock('javascript', _jsCode),

        // Python code
        BlockNode(
          tagName: 'h2',
          children: [TextNode('Python')],
        ),
        _createCodeBlock('python', _pythonCode),

        // JSON
        BlockNode(
          tagName: 'h2',
          children: [TextNode('JSON')],
        ),
        _createCodeBlock('json', _jsonCode),

        // SQL
        BlockNode(
          tagName: 'h2',
          children: [TextNode('SQL')],
        ),
        _createCodeBlock('sql', _sqlCode),
      ],
    );
  }

  /// Helper to create a code block node
  BlockNode _createCodeBlock(String language, String code) {
    final codeNode = BlockNode(tagName: 'code', children: [
      TextNode(code),
    ]);
    codeNode.attributes['class'] = 'language-$language';

    return BlockNode(tagName: 'pre', children: [codeNode]);
  }
}

// Sample code snippets

const _dartCode = '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomePage(),
    );
  }
}
''';

const _jsCode = '''
// Async function example
async function fetchData(url) {
  try {
    const response = await fetch(url);
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error fetching data:', error);
    throw error;
  }
}

// Arrow function with destructuring
const processUser = ({ name, age, email }) => {
  return {
    displayName: name.toUpperCase(),
    isAdult: age >= 18,
    contact: email,
  };
};
''';

const _pythonCode = '''
from dataclasses import dataclass
from typing import List, Optional

@dataclass
class User:
    name: str
    age: int
    email: Optional[str] = None

def process_users(users: List[User]) -> List[dict]:
    """Process a list of users and return summary."""
    return [
        {
            "name": user.name,
            "is_adult": user.age >= 18,
            "has_email": user.email is not None,
        }
        for user in users
    ]

if __name__ == "__main__":
    users = [User("Alice", 30, "alice@example.com")]
    print(process_users(users))
''';

const _jsonCode = '''
{
  "name": "hyper_render",
  "version": "2.0.0",
  "description": "Universal Content Engine for Flutter",
  "features": [
    "HTML rendering",
    "Markdown support",
    "Syntax highlighting",
    "Text selection"
  ],
  "author": {
    "name": "HyperRender Team",
    "email": "contact@hyperrender.dev"
  },
  "dependencies": {
    "flutter": ">=3.10.0"
  }
}
''';

const _sqlCode = '''
-- Create users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Query with JOIN
SELECT
    u.username,
    COUNT(p.id) as post_count
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
WHERE u.created_at > '2024-01-01'
GROUP BY u.id, u.username
HAVING COUNT(p.id) > 5
ORDER BY post_count DESC
LIMIT 10;
''';

/// Example: Using highlighter standalone
void standaloneHighlighterExample() {
  const highlighter = FlutterHighlightCodeHighlighter(
    theme: HighlightTheme.atomOneDark,
  );

  // Check if language is supported
  // ignore: avoid_print
  print('Dart supported: ${highlighter.isLanguageSupported('dart')}');
  // ignore: avoid_print
  print('Supported languages: ${highlighter.supportedLanguages.length}');

  // Get highlighted spans
  final spans = highlighter.highlight(
    'void main() { print("Hello"); }',
    'dart',
  );

  // ignore: avoid_print
  print('Generated ${spans.length} text spans');
}

/// Example: Custom highlighter implementation
class MinimalHighlighter implements CodeHighlighter {
  @override
  List<TextSpan> highlight(String code, String? language) {
    // Simple keyword highlighting for demo
    final keywords = ['void', 'main', 'print', 'return', 'if', 'else'];
    final pattern = RegExp(keywords.join('|'));

    final spans = <TextSpan>[];
    var lastEnd = 0;

    for (final match in pattern.allMatches(code)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: code.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < code.length) {
      spans.add(TextSpan(text: code.substring(lastEnd)));
    }

    return spans;
  }

  @override
  Set<String> get supportedLanguages => {'dart'};

  @override
  bool isLanguageSupported(String language) => language == 'dart';

  @override
  String get themeName => 'minimal';
}
