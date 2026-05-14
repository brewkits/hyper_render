# hyper_render_core

Core rendering engine for [HyperRender](https://pub.dev/packages/hyper_render) — the single `RenderObject` that drives CSS float layout, crash-free text selection, and CJK/Furigana typography in Flutter.

Most apps should depend on [`hyper_render`](https://pub.dev/packages/hyper_render) instead, which bundles everything. Use this package directly if you need the engine without the HTML/Markdown parsers, or if you are building a parser plugin.

---

## Installation

```yaml
dependencies:
  hyper_render_core: ^1.3.1
```

---

## Usage

### Build a document and render it

```dart
import 'package:hyper_render_core/hyper_render_core.dart';

final document = DocumentNode(children: [
  BlockNode(tagName: 'h1', children: [TextNode(text: 'Hello World')]),
  BlockNode(tagName: 'p', children: [
    TextNode(text: 'Welcome to '),
    InlineNode(tagName: 'strong', children: [TextNode(text: 'HyperRender')]),
    TextNode(text: '!'),
  ]),
]);

HyperRenderWidget(document: document)
```

### Plug in an HTML parser

```dart
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_html/hyper_render_html.dart';

final document = HtmlContentParser().parse('<h1>Hello</h1><p>World</p>');

HyperRenderWidget(document: document)
```

### Custom tag plugins

Register a `HyperNodePlugin` to render arbitrary HTML tags as Flutter widgets:

```dart
class MyCardPlugin implements HyperNodePlugin {
  @override List<String> get tagNames => ['my-card'];
  @override bool get isInline => false; // true = flows with text

  @override
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) {
    return Card(child: Text(node.textContent));
  }
}

HyperRenderWidget(
  document: document,
  pluginRegistry: HyperPluginRegistry()..register(MyCardPlugin()),
)
```

---

## UDT Node Types

| Type | Description |
|------|-------------|
| `DocumentNode` | Root container |
| `BlockNode` | Block-level element (`div`, `p`, `h1`–`h6`, `ul`, `ol`, …) |
| `InlineNode` | Inline element (`span`, `a`, `strong`, `em`, …) |
| `TextNode` | Text content |
| `AtomicNode` | Non-text inline (`img`, `video`) |
| `RubyNode` | Ruby / Furigana annotation |
| `TableNode` / `TableRowNode` / `TableCellNode` | Table structure |
| `DetailsNode` | Interactive `<details>`/`<summary>` |
| `LineBreakNode` | `<br>` |

---

## Plugin Interfaces

Implement these to extend the engine:

| Interface | Purpose |
|-----------|---------|
| `ContentParser` | HTML, Markdown, or Delta parsing |
| `CodeHighlighter` | Syntax highlighting for `<code>` / `<pre>` |
| `CssParserInterface` | CSS stylesheet parsing |
| `ImageClipboardHandler` | Image copy / share |

---

## HyperRender Ecosystem

| Package | Description |
|---------|-------------|
| [hyper_render](https://pub.dev/packages/hyper_render) | Main package — `HyperViewer` widget, HTML + Markdown rendering |
| **[hyper_render_core](https://pub.dev/packages/hyper_render_core)** | **Core engine: UDT model, `RenderHyperBox`, plugin API** ← you are here |
| [hyper_render_html](https://pub.dev/packages/hyper_render_html) | HTML + CSS → UDT parser |
| [hyper_render_markdown](https://pub.dev/packages/hyper_render_markdown) | Markdown (GFM) → UDT parser |
| [hyper_render_highlight](https://pub.dev/packages/hyper_render_highlight) | Syntax highlighting for `<code>` / `<pre>` blocks |
| [hyper_render_clipboard](https://pub.dev/packages/hyper_render_clipboard) | Image copy / save / share *(opt-in)* |
| [hyper_render_math](https://pub.dev/packages/hyper_render_math) | LaTeX / MathML rendering *(opt-in)* |
| [hyper_render_devtools](https://pub.dev/packages/hyper_render_devtools) | Flutter DevTools inspector |

[Source](https://github.com/brewkits/hyper_render/tree/main/packages/hyper_render_core) · [Issues](https://github.com/brewkits/hyper_render/issues) · [Changelog](CHANGELOG.md)

---

## License

MIT — see [LICENSE](LICENSE).
