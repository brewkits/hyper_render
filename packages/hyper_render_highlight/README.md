# hyper_render_highlight

Syntax highlighting plugin for [HyperRender](https://pub.dev/packages/hyper_render). Powered by [flutter_highlight](https://pub.dev/packages/flutter_highlight) — 180+ languages, 10 built-in themes.

---

## Installation

```yaml
dependencies:
  hyper_render_core: ^1.3.2
  hyper_render_highlight: ^1.3.2
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

## HyperRender Ecosystem

| Package | Description |
|---------|-------------|
| [hyper_render](https://pub.dev/packages/hyper_render) | Main package — `HyperViewer` widget, HTML + Markdown rendering |
| [hyper_render_core](https://pub.dev/packages/hyper_render_core) | Core engine: UDT model, `RenderHyperBox`, plugin API |
| [hyper_render_html](https://pub.dev/packages/hyper_render_html) | HTML + CSS → UDT parser |
| [hyper_render_markdown](https://pub.dev/packages/hyper_render_markdown) | Markdown (GFM) → UDT parser |
| **[hyper_render_highlight](https://pub.dev/packages/hyper_render_highlight)** | **Syntax highlighting for `<code>` / `<pre>` blocks** ← you are here |
| [hyper_render_clipboard](https://pub.dev/packages/hyper_render_clipboard) | Image copy / save / share *(opt-in)* |
| [hyper_render_math](https://pub.dev/packages/hyper_render_math) | LaTeX / MathML rendering *(opt-in)* |
| [hyper_render_devtools](https://pub.dev/packages/hyper_render_devtools) | Flutter DevTools inspector |

[Source](https://github.com/brewkits/hyper_render/tree/main/packages/hyper_render_highlight) · [Issues](https://github.com/brewkits/hyper_render/issues) · [Changelog](CHANGELOG.md)

---

## License

MIT — see [LICENSE](LICENSE).
