import 'package:flutter/material.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

/// Renders `<math>` and `<latex>` tags as mathematical expressions.
///
/// This is a **skeleton implementation** — it shows the correct plugin
/// structure but renders a placeholder until you wire up a rendering backend.
///
/// ## To complete this plugin:
///
/// 1. Add a rendering dependency to pubspec.yaml, e.g.:
///    ```yaml
///    flutter_math_fork: ^0.7.2
///    ```
///
/// 2. Replace the [_Placeholder] widget below with actual rendering:
///    ```dart
///    import 'package:flutter_math_fork/flutter_math.dart';
///
///    return Math.tex(
///      src,
///      textStyle: TextStyle(fontSize: style.fontSize ?? 16),
///      onErrorFallback: (err) => Text(src),
///    );
///    ```
///
/// 3. Publish as `hyper_render_math` on pub.dev following the guide in
///    `doc/PLUGIN_DEVELOPMENT.md`.
class MathNodePlugin implements HyperNodePlugin {
  const MathNodePlugin();

  @override
  List<String> get tagNames => ['math'];

  /// Block-level by default. Set to `true` if you want inline math (e.g.
  /// equations flowing inside a paragraph).
  @override
  bool get isInline => false;

  @override
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) {
    // The LaTeX/MathML source comes either from the `src` attribute or the
    // element's text content.
    final src = node.attributes['src']?.trim() ??
        _getTextContent(node).trim();
    if (src.isEmpty) return null;

    // TODO: replace _Placeholder with a real math renderer (see class docs).
    return _Placeholder(src: src);
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

/// Renders `<latex>` as an alias for `<math>`.
///
/// Register both if your content uses either tag:
/// ```dart
/// final registry = HyperPluginRegistry()
///   ..register(const MathNodePlugin())
///   ..register(const LatexNodePlugin());
/// ```
class LatexNodePlugin extends MathNodePlugin {
  const LatexNodePlugin();

  @override
  List<String> get tagNames => ['latex'];
}

// ── Placeholder — replace this with a real rendering widget ──────────────────

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.src});

  final String src;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(4),
        color: Colors.orange.shade50,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.functions, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              src,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
