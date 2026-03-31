# hyper_render_highlight

Syntax highlighting plugin for [HyperRender](https://pub.dev/packages/hyper_render). Powered by [flutter_highlight](https://pub.dev/packages/flutter_highlight) — 180+ languages, 10 built-in themes.

---

## Installation

```yaml
dependencies:
  hyper_render_core: ^1.2.0
  hyper_render_highlight: ^1.2.0
```

---

## Usage

### With HTML

```dart
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_html/hyper_render_html.dart';
import 'package:hyper_render_highlight/hyper_render_highlight.dart';

final document = HtmlContentParser().parse('''
  <pre><code class="language-dart">
  void main() {
    print('Hello, World!');
  }
  </code></pre>
''');

HyperRenderWidget(
  document: document,
  codeHighlighter: FlutterHighlightCodeHighlighter(),
)
```

### Custom theme

```dart
final highlighter = FlutterHighlightCodeHighlighter(
  theme: HighlightTheme.dracula,
);
```

---

## Available themes

| Theme | Style |
|-------|-------|
| `HighlightTheme.vs2015` | Visual Studio 2015 dark (default) |
| `HighlightTheme.atomOneDark` | Atom One Dark |
| `HighlightTheme.atomOneLight` | Atom One Light |
| `HighlightTheme.github` | GitHub light |
| `HighlightTheme.githubDark` | GitHub dark |
| `HighlightTheme.monokaiSublime` | Monokai Sublime |
| `HighlightTheme.dracula` | Dracula |
| `HighlightTheme.nord` | Nord |
| `HighlightTheme.solarizedDark` | Solarized Dark |
| `HighlightTheme.solarizedLight` | Solarized Light |

---

## Supported languages

180+ languages. Query at runtime:

```dart
print(FlutterHighlightCodeHighlighter().supportedLanguages);
// {dart, javascript, typescript, python, go, rust, swift, kotlin, ...}
```

---

## License

MIT — see [LICENSE](LICENSE).
