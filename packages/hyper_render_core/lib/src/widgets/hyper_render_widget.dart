import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_core/src/interfaces/selection_types.dart';
import '../core/render_table.dart';

/// Selection changed callback
typedef SelectionChangedCallback = void Function(HyperTextSelection? selection);

/// HyperRenderWidget - The main widget for rendering UDT content
class HyperRenderWidget extends MultiChildRenderObjectWidget {
  /// The document tree to render
  final DocumentNode document;

  /// Base text style
  final TextStyle baseStyle;

  /// Link tap callback
  final HyperLinkTapCallback? onLinkTap;

  /// Custom widget builder for atomic elements
  final HyperWidgetBuilder? widgetBuilder;

  /// Custom image loader
  final HyperImageLoader? imageLoader;

  /// Whether text selection is enabled
  final bool selectable;

  /// Callback for selection change
  final SelectionChangedCallback? onSelectionChanged;

  /// Custom selection menu actions builder
  final List<SelectionMenuAction> Function(SelectionOverlayController)? selectionMenuActionsBuilder;

  /// Custom color for selection handles
  final Color? selectionHandleColor;

  /// Custom color for selected text background
  final Color? selectionColor;

  /// Whether to show layout boundaries for debugging
  final bool debugShowHyperRenderBounds;

  /// Syntax highlighter for code blocks
  final CodeHighlighter? codeHighlighter;

  HyperRenderWidget({
    super.key,
    required this.document,
    this.baseStyle = const TextStyle(fontSize: 16, color: Color(0xFF000000)),
    this.onLinkTap,
    this.widgetBuilder,
    this.imageLoader,
    this.selectable = true,
    this.onSelectionChanged,
    this.selectionMenuActionsBuilder,
    this.selectionHandleColor,
    this.selectionColor,
    this.codeHighlighter,
    this.debugShowHyperRenderBounds = false,
  }) : super(children: _buildChildren(document, widgetBuilder, codeHighlighter, onLinkTap, selectable));

  /// Build child widgets for atomic elements (images, tables, etc.)
  static List<Widget> _buildChildren(
    DocumentNode document,
    HyperWidgetBuilder? widgetBuilder,
    CodeHighlighter? codeHighlighter,
    HyperLinkTapCallback? onLinkTap,
    bool selectable,
  ) {
    final children = <Widget>[];
    _collectAtomicChildren(document, children, widgetBuilder, codeHighlighter, onLinkTap, selectable);
    return children;
  }

  static void _collectAtomicChildren(
    UDTNode node,
    List<Widget> children,
    HyperWidgetBuilder? widgetBuilder,
    CodeHighlighter? codeHighlighter,
    HyperLinkTapCallback? onLinkTap,
    bool selectable,
  ) {
    Widget? childWidget;

    // Is it a float?
    if (node.style.float != HyperFloat.none) {
      childWidget = widgetBuilder?.call(node);
      
      if (childWidget == null) {
        if (node is AtomicNode) {
          childWidget = _buildDefaultAtomicWidget(node, onLinkTap: onLinkTap);
        } else {
          final nestedChildren = <Widget>[];
          for (final child in node.children) {
            _collectAtomicChildren(child, nestedChildren, widgetBuilder, codeHighlighter, onLinkTap, selectable);
          }
          childWidget = Container(
            width: node.style.width,
            height: node.style.height,
            padding: node.style.padding,
            decoration: BoxDecoration(
              color: node.style.backgroundColor,
              border: node.style.borderWidth != EdgeInsets.zero
                  ? Border.all(color: node.style.borderColor ?? Colors.transparent, width: node.style.borderWidth.top)
                  : null,
              borderRadius: node.style.borderRadius,
            ),
            child: nestedChildren.length == 1 ? nestedChildren.first : Column(children: nestedChildren),
          );
        }
      }

      children.add(_HyperChildWidget(node: node, child: childWidget));
      return;
    }

    // Is it a table element?
    if (node.type == NodeType.table) {
      final tableNode = node as TableNode;
      final tableWidget = widgetBuilder?.call(tableNode) ??
          HyperTable(
            tableNode: tableNode,
            onLinkTap: onLinkTap,
            // Do not wrap in SelectionArea here — HyperRenderWidget manages selection.
            selectable: false,
          );
      children.add(_HyperChildWidget(node: node, child: tableWidget));
      return;
    }

    // Is it an atomic element?
    if (node.type == NodeType.atomic) {
      final atomicNode = node as AtomicNode;
      childWidget = widgetBuilder?.call(atomicNode);
      childWidget ??= _buildDefaultAtomicWidget(atomicNode, onLinkTap: onLinkTap);
      children.add(_HyperChildWidget(node: node, child: childWidget));
    } else {
      for (final child in node.children) {
        _collectAtomicChildren(child, children, widgetBuilder, codeHighlighter, onLinkTap, selectable);
      }
    }
  }

  static Widget _buildDefaultAtomicWidget(AtomicNode node, {HyperLinkTapCallback? onLinkTap}) {
    if (node.tagName == 'img' && node.src != null && node.src!.isNotEmpty) {
      final src = node.src!;
      if (src.startsWith('data:')) {
        // Decode base64 data URL inline (e.g. data:image/png;base64,...)
        try {
          final commaIndex = src.indexOf(',');
          if (commaIndex > 0) {
            final bytes = base64Decode(src.substring(commaIndex + 1));
            return Image.memory(
              bytes,
              semanticLabel: node.alt,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            );
          }
        } catch (_) {
          // Fall through to empty widget
        }
        return const SizedBox.shrink();
      }
      return Image.network(
        src,
        semanticLabel: node.alt,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  RenderHyperBox createRenderObject(BuildContext context) {
    return RenderHyperBox(
      document: document,
      baseStyle: baseStyle,
      onLinkTap: onLinkTap,
      imageLoader: imageLoader,
      selectable: selectable,
      onSelectionChanged: onSelectionChanged,
      selectionMenuActionsBuilder: selectionMenuActionsBuilder,
      selectionHandleColor: selectionHandleColor,
      selectionColor: selectionColor,
      debugShowHyperRenderBounds: debugShowHyperRenderBounds,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderHyperBox renderObject) {
    renderObject
      ..document = document
      ..baseStyle = baseStyle
      ..onLinkTap = onLinkTap
      ..imageLoader = imageLoader
      ..selectable = selectable
      ..onSelectionChanged = onSelectionChanged
      ..selectionMenuActionsBuilder = selectionMenuActionsBuilder
      ..selectionHandleColor = selectionHandleColor
      ..selectionColor = selectionColor
      ..debugShowHyperRenderBounds = debugShowHyperRenderBounds;
  }
}

class _HyperChildWidget extends ParentDataWidget<HyperBoxParentData> {
  final UDTNode node;
  const _HyperChildWidget({required this.node, required super.child});

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData as HyperBoxParentData;
    if (parentData.sourceNode != node) {
      parentData.sourceNode = node;
      parentData.isFloat = node.style.float != HyperFloat.none;
      parentData.floatDirection = node.style.float;
      final targetParent = renderObject.parent;
      if (targetParent is RenderHyperBox) {
        targetParent.markNeedsLayout();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => HyperRenderWidget;
}
