# hyper_render_core

Core rendering engine for [HyperRender](https://pub.dev/packages/hyper_render) — the single `RenderObject` that drives CSS float layout, crash-free text selection, and CJK/Furigana typography in Flutter.

Most apps should depend on [`hyper_render`](https://pub.dev/packages/hyper_render) instead, which bundles everything. Use this package directly if you need the engine without the HTML/Markdown parsers, or if you are building a parser plugin.

---

## Installation

```yaml
dependencies:
  hyper_render_core: ^1.2.0
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
  @override String get tagName => 'my-card';
  @override bool get isInline => false; // true = flows with text

  @override
  Widget? build(HyperPluginBuildContext ctx) {
    return Card(child: Text(ctx.node.textContent));
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

## License

MIT — see [LICENSE](LICENSE).
