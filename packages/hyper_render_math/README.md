# hyper_render_math

Mathematical formula rendering plugin for [HyperRender](https://pub.dev/packages/hyper_render).
Renders `<math>` and `<latex>` tags using [flutter_math_fork](https://pub.dev/packages/flutter_math_fork) for high-performance LaTeX typesetting.

---

## Installation

```yaml
dependencies:
  hyper_render_core: ^1.3.0
  hyper_render_math: ^1.3.0
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

## Contributing

See [PLUGIN_DEVELOPMENT.md](../../doc/PLUGIN_DEVELOPMENT.md) for the full guide
on building, testing, and submitting plugins.
