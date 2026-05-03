/// HyperRender math plugin — renders `<math>` and `<latex>` tags.
///
/// This plugin uses `flutter_math_fork` for high-performance LaTeX rendering.
///
/// ## Quick start
///
/// ```dart
/// import 'package:hyper_render/hyper_render.dart';
/// import 'package:hyper_render_math/hyper_render_math.dart';
///
/// final registry = HyperPluginRegistry()
///   ..register(const MathNodePlugin());
///
/// HyperViewer(
///   html: 'The quadratic formula: <math>x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}</math>',
///   pluginRegistry: registry,
/// )
/// ```
library;

export 'src/math_node_plugin.dart';
