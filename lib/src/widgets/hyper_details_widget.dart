import 'package:flutter/material.dart';

import '../core/render_hyper_box.dart';
import '../model/node.dart';
import 'hyper_render_widget.dart';

/// Renders an HTML `<details>/<summary>` element as an interactive
/// expand/collapse panel.
///
/// - `<summary>` → always-visible clickable header with a disclosure arrow.
/// - Remaining content → collapsible body.
/// - The `open` HTML attribute controls the initial state.
///
/// Example HTML:
/// ```html
/// <details open>
///   <summary>Click to collapse</summary>
///   <p>Hidden content revealed on click.</p>
/// </details>
/// ```
class HyperDetailsWidget extends StatefulWidget {
  /// The `<details>` node from the parsed document.
  final UDTNode detailsNode;

  /// Widget builder forwarded from the parent [HyperRenderWidget].
  final HyperWidgetBuilder? widgetBuilder;

  const HyperDetailsWidget({
    super.key,
    required this.detailsNode,
    this.widgetBuilder,
  });

  @override
  State<HyperDetailsWidget> createState() => _HyperDetailsWidgetState();
}

class _HyperDetailsWidgetState extends State<HyperDetailsWidget>
    with SingleTickerProviderStateMixin {
  late bool _isOpen;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    // Honour the HTML `open` attribute for initial state.
    _isOpen = widget.detailsNode.attributes.containsKey('open');

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: _isOpen ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryNode = _findSummary();
    final bodyNodes = _bodyNodes();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Summary header ──────────────────────────────────────────────────
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                // Disclosure triangle
                AnimatedRotation(
                  turns: _isOpen ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.arrow_right,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: summaryNode != null
                      ? _SummaryContent(
                          node: summaryNode,
                          widgetBuilder: widget.widgetBuilder,
                        )
                      : const Text(
                          'Details',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                ),
              ],
            ),
          ),
        ),

        // ── Collapsible body ─────────────────────────────────────────────────
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1,
          child: Padding(
            padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: bodyNodes.map((node) {
                return HyperRenderWidget(
                  document: DocumentNode(children: [node]),
                  widgetBuilder: widget.widgetBuilder,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  UDTNode? _findSummary() {
    for (final child in widget.detailsNode.children) {
      if (child.tagName?.toLowerCase() == 'summary') return child;
    }
    return null;
  }

  List<UDTNode> _bodyNodes() {
    return widget.detailsNode.children
        .where((c) => c.tagName?.toLowerCase() != 'summary')
        .toList();
  }
}

/// Renders the text/inline content of a `<summary>` node.
class _SummaryContent extends StatelessWidget {
  final UDTNode node;
  final HyperWidgetBuilder? widgetBuilder;

  const _SummaryContent({required this.node, this.widgetBuilder});

  @override
  Widget build(BuildContext context) {
    // Wrap summary children in a document so HyperRenderWidget can render them.
    final doc = DocumentNode(children: node.children.isNotEmpty
        ? node.children
        : [TextNode(node.textContent)]);

    return HyperRenderWidget(
      document: doc,
      widgetBuilder: widgetBuilder,
      baseStyle: const TextStyle(fontWeight: FontWeight.w500),
    );
  }
}
