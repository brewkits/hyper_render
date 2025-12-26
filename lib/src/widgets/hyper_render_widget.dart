import 'package:flutter/material.dart';

import '../core/render_hyper_box.dart';
import '../core/render_table.dart';
import '../model/computed_style.dart';
import '../model/node.dart';

/// HyperRenderWidget - MultiChildRenderObjectWidget for custom HTML rendering
///
/// This widget uses the custom RenderHyperBox for layout and painting,
/// enabling advanced features like:
/// - Float layout (text wrap around images)
/// - Margin collapsing
/// - Custom inline background/border
/// - CJK line-breaking (Kinsoku)
/// - Text selection with drag support
/// - Async image loading
///
/// ## Basic Usage
/// ```dart
/// HyperRenderWidget(
///   document: documentNode,
///   baseStyle: TextStyle(fontSize: 16),
///   onLinkTap: (url) => launchUrl(Uri.parse(url)),
/// )
/// ```
///
/// ## With Selection
/// ```dart
/// HyperRenderWidget(
///   document: documentNode,
///   selectable: true, // Enable text selection
/// )
/// ```
///
/// Reference: doc3.md - "RenderObject-centric Architecture"
class HyperRenderWidget extends MultiChildRenderObjectWidget {
  /// The parsed document tree to render
  final DocumentNode document;

  /// Base text style for the content
  final TextStyle baseStyle;

  /// Callback when a link is tapped
  final HyperLinkTapCallback? onLinkTap;

  /// Custom widget builder for embedded content (images, videos, etc.)
  final HyperWidgetBuilder? widgetBuilder;

  /// Whether text selection is enabled
  final bool selectable;

  /// Creates a HyperRenderWidget
  ///
  /// The [document] parameter is required and contains the parsed UDT tree.
  /// Use [HtmlAdapter], [DeltaAdapter], or [MarkdownAdapter] to parse content.
  HyperRenderWidget({
    super.key,
    required this.document,
    this.baseStyle = const TextStyle(fontSize: 16, color: Color(0xFF000000)),
    this.onLinkTap,
    this.widgetBuilder,
    this.selectable = true,
  }) : super(children: _buildChildren(document, widgetBuilder));

  /// Build child widgets for atomic elements (images, tables, etc.)
  static List<Widget> _buildChildren(
    DocumentNode document,
    HyperWidgetBuilder? widgetBuilder,
  ) {
    final children = <Widget>[];
    _collectAtomicChildren(document, children, widgetBuilder);
    return children;
  }

  static void _collectAtomicChildren(
    UDTNode node,
    List<Widget> children,
    HyperWidgetBuilder? widgetBuilder,
  ) {
    Widget? childWidget;

    // Is it a float?
    if (node.style.float != HyperFloat.none) {
      childWidget = widgetBuilder?.call(node);
      // If it's an image, build the default image widget
      if (childWidget == null && node is AtomicNode && node.tagName == 'img') {
        childWidget = _buildDefaultAtomicWidget(node);
      }
      
      if (childWidget != null) {
        children.add(_HyperFloatChildWidget(
          node: node,
          floatDirection: node.style.float,
          child: childWidget,
        ));
      }
    } 
    // Is it a non-floating atomic element or table?
    else if (node.type == NodeType.atomic) {
      final atomicNode = node as AtomicNode;
      childWidget = widgetBuilder?.call(atomicNode);
      childWidget ??= _buildDefaultAtomicWidget(atomicNode);
      if (childWidget != null) {
        children.add(_HyperChildWidget(node: node, child: childWidget));
      }
    } else if (node.type == NodeType.table) {
      final tableNode = node as TableNode;
      childWidget = widgetBuilder?.call(tableNode);
      childWidget ??= _buildDefaultTableWidget(tableNode);
      if (childWidget != null) {
        children.add(_HyperChildWidget(node: node, child: childWidget));
      }
    }

    // Recurse into children, but ONLY if the current node isn't a child-widget itself
    // (because its children are not part of the main render tree)
    if (childWidget == null) {
      for (final child in node.children) {
        _collectAtomicChildren(child, children, widgetBuilder);
      }
    }
  }

  static Widget? _buildDefaultAtomicWidget(AtomicNode node) {
    if (node.tagName == 'img') {
      final src = node.src;
      if (src == null || src.isEmpty) return null;

      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          src,
          width: node.intrinsicWidth,
          height: node.intrinsicHeight,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: node.intrinsicWidth ?? 100,
              height: node.intrinsicHeight ?? 100,
              color: const Color(0xFFE0E0E0),
              child: const Center(
                child: Icon(Icons.broken_image, size: 32),
              ),
            );
          },
        ),
      );
    }

    if (node.tagName == 'video') {
      // Placeholder for video - actual implementation would use video_player
      return Container(
        width: node.intrinsicWidth ?? 320,
        height: node.intrinsicHeight ?? 180,
        color: const Color(0xFF000000),
        child: const Center(
          child: Icon(
            Icons.play_circle_outline,
            size: 64,
            color: Color(0xFFFFFFFF),
          ),
        ),
      );
    }

    return null;
  }

  static Widget? _buildDefaultTableWidget(TableNode node) {
    // Use the SmartTableWrapper for intelligent table rendering
    return SmartTableWrapper(
      tableNode: node,
      strategy: TableStrategy.horizontalScroll,
      minScaleFactor: 0.6,
    );
  }

  @override
  RenderHyperBox createRenderObject(BuildContext context) {
    return RenderHyperBox(
      document: document,
      baseStyle: baseStyle,
      onLinkTap: onLinkTap,
      selectable: selectable,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderHyperBox renderObject) {
    if (renderObject.document != document) {
      renderObject.document = document;
    }
    if (renderObject.baseStyle != baseStyle) {
      renderObject.baseStyle = baseStyle;
    }
    if (renderObject.onLinkTap != onLinkTap) {
      renderObject.onLinkTap = onLinkTap;
    }
    if (renderObject.selectable != selectable) {
      renderObject.selectable = selectable;
    }
  }
}

/// Internal widget to wrap atomic children
class _HyperChildWidget extends ParentDataWidget<HyperBoxParentData> {
  final UDTNode node;

  const _HyperChildWidget({
    required this.node,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData as HyperBoxParentData;
    parentData.sourceNode = node;
    parentData.isFloat = false;
  }

  @override
  Type get debugTypicalAncestorWidgetClass => HyperRenderWidget;
}

/// Internal widget to wrap float children
class _HyperFloatChildWidget extends ParentDataWidget<HyperBoxParentData> {
  final UDTNode node;
  final HyperFloat floatDirection;

  const _HyperFloatChildWidget({
    required this.node,
    required this.floatDirection,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData as HyperBoxParentData;
    parentData.sourceNode = node;
    parentData.isFloat = true;
    parentData.floatDirection = floatDirection;
  }

  @override
  Type get debugTypicalAncestorWidgetClass => HyperRenderWidget;
}
