# HyperRender Highlight

Syntax highlighting plugin for HyperRender using flutter_highlight.

## Features

- **180+ Languages** - Comprehensive language support via highlight.js
- **Multiple Themes** - VS2015, Atom One Dark, GitHub, Dracula, and more
- **Auto-detection** - Automatic language detection when not specified
- **Seamless Integration** - Works with HyperRender's code block rendering

## Installation

```yaml
dependencies:
  hyper_render_core: ^1.0.0
  hyper_render_highlight: ^1.0.0
```

## Usage

### Basic Usage

```dart
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_html/hyper_render_html.dart';
import 'package:hyper_render_highlight/hyper_render_highlight.dart';

// Create highlighter
final highlighter = FlutterHighlightCodeHighlighter();

// Parse HTML with code blocks
final parser = HtmlContentParser();
final document = parser.parse('''
  <pre><code class="language-dart">
  void main() {
    print('Hello, World!');
  }
  </code></pre>
''');

// Render with syntax highlighting
HyperRenderWidget(
  document: document,
  codeHighlighter: highlighter,
)
```

### Custom Theme

```dart
final highlighter = FlutterHighlightCodeHighlighter(
  theme: HighlightTheme.dracula,
);
```

### Available Themes

| Theme | Description |
|-------|-------------|
| `HighlightTheme.vs2015` | Visual Studio 2015 dark (default) |
| `HighlightTheme.atomOneDark` | Atom One Dark |
| `HighlightTheme.atomOneLight` | Atom One Light |
| `HighlightTheme.github` | GitHub light theme |
| `HighlightTheme.githubDark` | GitHub dark theme |
| `HighlightTheme.monokaiSublime` | Monokai Sublime |
| `HighlightTheme.dracula` | Dracula dark theme |
| `HighlightTheme.nord` | Nord theme |
| `HighlightTheme.solarizedDark` | Solarized Dark |
| `HighlightTheme.solarizedLight` | Solarized Light |

### With Markdown

```dart
import 'package:hyper_render_markdown/hyper_render_markdown.dart';
import 'package:hyper_render_highlight/hyper_render_highlight.dart';

final parser = MarkdownContentParser();
final highlighter = FlutterHighlightCodeHighlighter(
  theme: HighlightTheme.atomOneDark,
);

final document = parser.parse('''
# Code Example

```python
def hello():
    print("Hello, World!")

hello()
```
''');

HyperRenderWidget(
  document: document,
  codeHighlighter: highlighter,
)
```

## Supported Languages

The plugin supports 180+ programming languages including:

### Popular Languages
- **Web**: JavaScript, TypeScript, HTML, CSS, JSON
- **Mobile**: Dart, Swift, Kotlin, Java, Objective-C
- **Backend**: Python, Ruby, PHP, Go, Rust, C#
- **Systems**: C, C++, Rust, Assembly
- **Data**: SQL, R, Julia, MATLAB
- **Shell**: Bash, PowerShell, Zsh
- **Config**: YAML, TOML, INI, XML

### Full List

Check `highlighter.supportedLanguages` for the complete list:

```dart
final highlighter = FlutterHighlightCodeHighlighter();
print(highlighter.supportedLanguages);
// {dart, javascript, python, ruby, go, rust, ...}
```

## Custom Highlighter

You can implement your own highlighter using the `CodeHighlighter` interface:

```dart
import 'package:hyper_render_core/hyper_render_core.dart';

class MyCustomHighlighter implements CodeHighlighter {
  @override
  List<TextSpan> highlight(String code, String language) {
    // Your custom highlighting logic
    return [TextSpan(text: code)];
  }

  @override
  Set<String> get supportedLanguages => {'dart', 'python'};

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

## License

MIT License - see LICENSE file for details.
