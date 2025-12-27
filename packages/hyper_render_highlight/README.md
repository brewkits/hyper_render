# HyperRender Highlight

Syntax highlighting plugin for HyperRender.

> **Note**: This is a **PAID** plugin. Contact sales@hyperrender.dev for licensing.

## Installation

```yaml
dependencies:
  hyper_render_core: ^2.0.0
  hyper_render_html: ^2.0.0  # or hyper_render_markdown
  hyper_render_highlight: ^2.0.0
```

## Features

- 180+ programming languages
- Multiple color themes
- Line numbers (optional)
- Copy button (optional)
- Custom theme support

## Usage

```dart
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_html/hyper_render_html.dart';
import 'package:hyper_render_highlight/hyper_render_highlight.dart';

HyperViewer(
  content: '''
    <pre><code class="language-dart">
    void main() {
      print('Hello, World!');
    }
    </code></pre>
  ''',
  contentParser: HtmlContentParser(),
  codeHighlighter: FlutterHighlighter(
    theme: 'monokai',
    showLineNumbers: true,
  ),
)
```

## Available Themes

- `monokai` (default)
- `dracula`
- `github`
- `github-dark`
- `vs`
- `vs-dark`
- `atom-one-dark`
- `atom-one-light`
- `solarized-dark`
- `solarized-light`
- And many more...

## Supported Languages

Dart, JavaScript, TypeScript, Python, Java, Kotlin, Swift, Go, Rust, C, C++, C#, PHP, Ruby, Scala, HTML, CSS, JSON, YAML, SQL, Shell, and 160+ more.

## Configuration

```dart
FlutterHighlighter(
  // Theme name
  theme: 'monokai',

  // Show line numbers
  showLineNumbers: true,

  // Custom font family
  fontFamily: 'JetBrains Mono',

  // Custom font size
  fontSize: 14.0,

  // Enable copy button
  showCopyButton: true,
)
```

## Dependencies

- `flutter_highlight: ^0.7.0`
- `highlight: ^0.7.0`

## License

Commercial License - Contact sales@hyperrender.dev
