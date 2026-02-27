import 'package:flutter/material.dart';
import '../model/node.dart';
import '../style/design_tokens.dart';

/// Interactive widget for `<details>`/`<summary>` HTML elements
///
/// Provides expand/collapse functionality similar to native HTML `<details>` element.
/// The `<summary>` element acts as the clickable header, while the rest of the
/// content is shown/hidden based on the expanded state.
class DetailsWidget extends StatefulWidget {
  /// The details node containing summary and content
  final DetailsNode detailsNode;

  /// Base text style
  final TextStyle? baseStyle;

  /// Callback when a link is tapped
  final void Function(String url)? onLinkTap;

  const DetailsWidget({
    super.key,
    required this.detailsNode,
    this.baseStyle,
    this.onLinkTap,
  });

  @override
  State<DetailsWidget> createState() => _DetailsWidgetState();
}

class _DetailsWidgetState extends State<DetailsWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    // Use the 'open' attribute from DetailsNode as initial state
    _isExpanded = widget.detailsNode.open;
  }

  @override
  Widget build(BuildContext context) {
    // Extract summary and content children
    Widget? summaryWidget;
    final List<Widget> contentWidgets = [];

    for (final child in widget.detailsNode.children) {
      if (child.tagName?.toLowerCase() == 'summary') {
        // Build summary widget
        summaryWidget = _buildSummary(child);
      } else {
        // All other children are content (collected regardless of expansion state)
        contentWidgets.add(_buildContent(child));
      }
    }

    // Default summary if not provided
    summaryWidget ??= _buildDefaultSummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated disclosure triangle with smooth rotation
                AnimatedRotation(
                  turns: _isExpanded ? 0.25 : 0.0, // 90 degrees when expanded
                  duration: DesignTokens.durationMedium,
                  curve: DesignTokens.curveStandard,
                  child: const Icon(
                    Icons.arrow_right,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(child: summaryWidget),
              ],
            ),
          ),
        ),
        // Smooth expand/collapse animation
        AnimatedSize(
          duration: DesignTokens.durationMedium,
          curve: DesignTokens.curveStandard,
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: contentWidgets,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSummary(UDTNode summaryNode) {
    // Extract text from summary node
    final text = _extractText(summaryNode);

    return Text(
      text,
      style: widget.baseStyle?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDefaultSummary() {
    return Text(
      'Details',
      style: widget.baseStyle?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildContent(UDTNode node) {
    // Simple text extraction for content
    final text = _extractText(node);

    return Padding(
      padding: const EdgeInsets.only(left: 24.0, top: 4.0, bottom: 4.0),
      child: Text(
        text,
        style: widget.baseStyle,
      ),
    );
  }

  /// Recursively extract text from node and its children
  String _extractText(UDTNode node) {
    if (node is TextNode) {
      return node.text;
    }

    final buffer = StringBuffer();
    for (final child in node.children) {
      buffer.write(_extractText(child));
    }

    return buffer.toString();
  }
}
