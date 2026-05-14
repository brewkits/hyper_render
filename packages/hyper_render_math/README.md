# hyper_render_math

Mathematical formula rendering plugin for [HyperRender](https://pub.dev/packages/hyper_render).
Renders `<math>` and `<latex>` tags using [flutter_math_fork](https://pub.dev/packages/flutter_math_fork) for high-performance LaTeX typesetting.

---

## Installation

```yaml
dependencies:
  hyper_render_math: ^1.3.1
```

---

## Usage

Register `MathNodePlugin` — it handles both `<math>` and `<latex>` tags:

```dart
import 'package:hyper_render/hyper_render.dart';
import 'package:hyper_render_math/hyper_render_math.dart';

final registry = HyperPluginRegistry()
  ..register(const MathNodePlugin());

HyperViewer(
  html: 'The quadratic formula: '
        '<math>x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}</math>',
  pluginRegistry: registry,
)
```

### Display vs inline mode

By default `<math>` renders in display mode (centered, larger). To render inline:

```html
<p>Energy: <math display="inline">E = mc^2</math> in action.</p>
```

Or use the `<latex>` tag with the `mode="inline"` attribute:

```html
<p>Euler's identity: <latex mode="inline">e^{i\pi} + 1 = 0</latex></p>
```

### Inline-tier plugin

To flow equations inside text lines (without the block break), subclass and flip `isInline`:

```dart
class InlineMathPlugin extends MathNodePlugin {
  @override bool get isInline => true;
}
```

### Error fallback

If a LaTeX expression cannot be parsed, the raw source is displayed in red monospace
so you can identify and fix the malformed formula.

---

## HyperRender Ecosystem

| Package | Description |
|---------|-------------|
| [hyper_render](https://pub.dev/packages/hyper_render) | Main package — `HyperViewer` widget, HTML + Markdown rendering |
| [hyper_render_core](https://pub.dev/packages/hyper_render_core) | Core engine: UDT model, `RenderHyperBox`, plugin API |
| [hyper_render_html](https://pub.dev/packages/hyper_render_html) | HTML + CSS → UDT parser |
| [hyper_render_markdown](https://pub.dev/packages/hyper_render_markdown) | Markdown (GFM) → UDT parser |
| [hyper_render_highlight](https://pub.dev/packages/hyper_render_highlight) | Syntax highlighting for `<code>` / `<pre>` blocks |
| [hyper_render_clipboard](https://pub.dev/packages/hyper_render_clipboard) | Image copy / save / share *(opt-in)* |
| **[hyper_render_math](https://pub.dev/packages/hyper_render_math)** | **LaTeX / MathML rendering** ← you are here |
| [hyper_render_devtools](https://pub.dev/packages/hyper_render_devtools) | Flutter DevTools inspector |

[Source](https://github.com/brewkits/hyper_render/tree/main/packages/hyper_render_math) · [Issues](https://github.com/brewkits/hyper_render/issues) · [Changelog](CHANGELOG.md) · [Plugin Development Guide](https://github.com/brewkits/hyper_render/blob/main/doc/PLUGIN_DEVELOPMENT.md)

---

## License

MIT — see [LICENSE](LICENSE).
