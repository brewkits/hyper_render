# hyper_render_math

A **template plugin** for [HyperRender](../../README.md) that renders mathematical
expressions (`<math>` / `<latex>` tags) as Flutter widgets.

> **This is a skeleton.** It ships a visible placeholder so you can verify
> the plugin wiring before adding a rendering backend. Replace the
> `_Placeholder` widget in `lib/src/math_node_plugin.dart` with
> `flutter_math_fork` (or another library) to complete the implementation.

---

## Usage

```dart
import 'package:hyper_render/hyper_render.dart';
import 'package:hyper_render_math/hyper_render_math.dart';

final registry = HyperPluginRegistry()
  ..register(const MathNodePlugin())    // handles <math>
  ..register(const LatexNodePlugin());  // handles <latex>

HyperViewer(
  html: 'The quadratic formula: '
        '<math>x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}</math>',
  pluginRegistry: registry,
)
```

## Completing the implementation

1. Uncomment a backend in `pubspec.yaml`:

   ```yaml
   # KaTeX-based (fast, offline — recommended):
   flutter_math_fork: ^0.7.2
   ```

2. In `lib/src/math_node_plugin.dart`, replace `_Placeholder` with:

   ```dart
   import 'package:flutter_math_fork/flutter_math.dart';

   // inside MathNodePlugin.build():
   return Math.tex(
     src,
     textStyle: TextStyle(fontSize: ctx.style?.fontSize ?? 16),
     onErrorFallback: (err) => SelectableText(src),
   );
   ```

3. Add tests, update CHANGELOG, and publish on pub.dev.

## Inline math

To flow equations inside text paragraphs, switch to inline tier:

```dart
class InlineMathPlugin extends MathNodePlugin {
  @override bool get isInline => true;
}
```

## Contributing

See [PLUGIN_DEVELOPMENT.md](../../doc/PLUGIN_DEVELOPMENT.md) for the full
guide on building, testing, and submitting plugins.
