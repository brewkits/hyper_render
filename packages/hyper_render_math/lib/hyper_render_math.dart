/// HyperRender math plugin — renders `<math>` and `<latex>` tags.
///
/// This is a **skeleton / template** plugin. Wire up `flutter_math_fork`
/// (or another backend) in `lib/src/math_node_plugin.dart` to complete it.
///
/// ## Quick start
///
/// ```dart
/// import 'package:hyper_render/hyper_render.dart';
/// import 'package:hyper_render_math/hyper_render_math.dart';
///
/// final registry = HyperPluginRegistry()
///   ..register(const MathNodePlugin())    // handles <math>
///   ..register(const LatexNodePlugin());  // handles <latex>
///
/// HyperViewer(
///   html: 'The quadratic formula: <math>x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}</math>',
///   pluginRegistry: registry,
/// )
/// ```
library;

export 'src/math_node_plugin.dart';
