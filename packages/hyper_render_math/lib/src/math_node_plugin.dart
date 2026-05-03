import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

/// Renders `<math>` and `<latex>` tags as mathematical expressions.
///
/// This plugin uses `flutter_math_fork` for high-performance LaTeX rendering.
///
/// ## Usage:
/// ```dart
/// final registry = HyperPluginRegistry()
///   ..register(const MathNodePlugin());
///
/// HyperViewer(
///   html: '<math src="x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"></math>',
///   pluginRegistry: registry,
/// );
/// ```
class MathNodePlugin implements HyperNodePlugin {
  const MathNodePlugin();

  @override
  List<String> get tagNames => ['math', 'latex'];

  /// Inline math if it's a `<latex>` tag or has `display="inline"`.
  @override
  bool get isInline => false;

  @override
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) {
    final src = node.attributes['src']?.trim() ?? _getTextContent(node).trim();
    if (src.isEmpty) return null;

    final isDisplayMode = node.attributes['display'] != 'inline' &&
        node.attributes['mode'] != 'inline';

    return Math.tex(
      src,
      mathStyle: isDisplayMode ? MathStyle.display : MathStyle.text,
      textStyle: ctx.baseStyle,
      onErrorFallback: (err) => SelectableText(
        src,
        style: ctx.baseStyle.copyWith(
          color: Colors.red,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  String _getTextContent(UDTNode node) {
    final buffer = StringBuffer();
    void traverse(UDTNode n) {
      if (n is TextNode) {
        buffer.write(n.text);
      }
      for (final child in n.children) {
        traverse(child);
      }
    }

    traverse(node);
    return buffer.toString();
  }
}
