import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/animation_controller.dart';
import '../core/hyper_render_config.dart';
import '../core/image_provider.dart';
import '../core/render_formula.dart';
import '../core/render_hyper_box.dart';
import '../core/render_media.dart';
import '../core/render_table.dart';
import '../interfaces/code_highlighter.dart';
import '../interfaces/image_clipboard.dart';
import '../interfaces/node_plugin.dart';
import '../model/computed_style.dart';
import '../model/node.dart';
import 'code_block_widget.dart';
import 'error_boundary_widget.dart';
import 'flex_container_widget.dart';
import 'grid_container_widget.dart';
import 'hyper_details_widget.dart';

/// Image action types for context menu
enum ImageAction {
  /// Copy image URL to clipboard
  copyUrl,

  /// Copy image data (requires ImageClipboardHandler)
  copyImage,

  /// Save image to device (requires ImageClipboardHandler)
  saveImage,

  /// Share image (requires ImageClipboardHandler)
  shareImage,
}

/// Callback for custom image action handling
/// Return true if the action was handled, false to use default behavior
typedef ImageActionCallback = Future<bool> Function(
  ImageAction action,
  String imageUrl,
  BuildContext context,
);

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
class HyperRenderWidget extends MultiChildRenderObjectWidget {
  /// The parsed document tree to render
  final DocumentNode document;

  /// Base text style for the content
  final TextStyle baseStyle;

  /// Callback when a link is tapped
  final HyperLinkTapCallback? onLinkTap;

  /// Custom widget builder for embedded content (images, videos, etc.)
  final HyperWidgetBuilder? widgetBuilder;

  /// Custom image loader for loading images
  /// If not provided, uses the default NetworkImage-based loader
  final HyperImageLoader? imageLoader;

  /// Whether text selection is enabled
  final bool selectable;

  /// Text direction for layout
  final TextDirection textDirection;

  /// Color for text selection highlight
  final Color? selectionColor;

  /// Callback when selection changes (e.g., to show context menu)
  final VoidCallback? onSelectionChanged;

  /// Draw debug bounds around each fragment and line row.
  /// See [RenderHyperBox.debugShowBounds].
  final bool debugShowBounds;

  /// When false, `backdrop-filter` and CSS `filter` effects skip
  /// `canvas.saveLayer`. Disable on low-end devices to avoid rasterization
  /// overhead from complex compositing layers.
  /// See [RenderHyperBox.enableComplexFilters].
  final bool enableComplexFilters;

  /// When true, suppresses the top margin of the first block element.
  /// Set to `true` for all virtualized sections except the first so that
  /// CSS margin collapsing works correctly across section boundaries.
  /// See [RenderHyperBox.suppressFirstBlockMarginTop].
  final bool suppressFirstBlockMarginTop;

  /// Called after each layout pass with anchor id→yOffset map and heading list.
  /// Used by [HyperViewerController] to power [scrollToId] and TOC generation.
  final void Function(
    Map<String, double> offsets,
    List<({int level, String text, String? cssId, double yOffset})> headings,
  )? onAnchorLayout;

  /// Called after each layout pass with floats that overhang the section bottom.
  /// Pass the list to the next section's [initialFloats] for cross-chunk float
  /// continuity.  Receives an empty list when no floats dangle.
  final void Function(List<FloatCarryover> carryovers)? onFloatCarryover;

  /// Engine configuration — tunable cache sizes and concurrency.
  /// See [HyperRenderConfig] for all options and defaults.
  final HyperRenderConfig config;

  /// Floats inherited from the previous virtualized section.
  ///
  /// When non-empty, the render object seeds its left/right float lists from
  /// these carryovers before processing fragments, so text wraps correctly
  /// alongside a float element that began in the preceding chunk.
  ///
  /// Obtain the value for section N from [RenderHyperBox.danglingFloats] after
  /// section N-1 has completed layout, and pass it here for section N.
  final List<FloatCarryover> initialFloats;

  /// Custom plugin registry for overriding the rendering of specific HTML tags.
  ///
  /// Plugins are checked **before** any built-in rendering logic, so they can
  /// intercept built-in tags (e.g. replace `<table>` with a custom widget) or
  /// handle custom/unknown tags (e.g. `<math>`, `<figure>`, `<badge>`).
  ///
  /// See [HyperNodePlugin] for the block vs inline distinction.
  final HyperPluginRegistry? pluginRegistry;

  /// Creates a HyperRenderWidget
  ///
  /// The [document] parameter is required and contains the parsed UDT tree.
  /// Use [HtmlAdapter], [DeltaAdapter], or [MarkdownAdapter] to parse content.
  HyperRenderWidget({
    super.key,
    required this.document,
    this.baseStyle = const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
    this.onLinkTap,
    this.widgetBuilder,
    this.imageLoader,
    this.selectable = true,
    this.textDirection = TextDirection.ltr,
    this.selectionColor,
    this.onSelectionChanged,
    this.debugShowBounds = false,
    this.enableComplexFilters = true,
    this.suppressFirstBlockMarginTop = false,
    this.onAnchorLayout,
    this.onFloatCarryover,
    this.config = HyperRenderConfig.defaults,
    this.initialFloats = const [],
    this.pluginRegistry,
  }) : super(
            children: _buildChildren(document, widgetBuilder,
                selectable: selectable,
                onLinkTap: onLinkTap,
                codeHighlighter: config.codeHighlighter,
                keyframeRegistry: config.keyframeRegistry,
                pluginRegistry: pluginRegistry));

  /// Build child widgets for atomic elements (images, tables, etc.)
  static List<Widget> _buildChildren(
    DocumentNode document,
    HyperWidgetBuilder? widgetBuilder, {
    bool selectable = true,
    void Function(String)? onLinkTap,
    CodeHighlighter? codeHighlighter,
    Map<String, HyperKeyframes> keyframeRegistry = const {},
    HyperPluginRegistry? pluginRegistry,
  }) {
    final children = <Widget>[];
    _collectAtomicChildren(document, children, widgetBuilder,
        selectable: selectable,
        onLinkTap: onLinkTap,
        codeHighlighter: codeHighlighter,
        keyframeRegistry: keyframeRegistry,
        pluginRegistry: pluginRegistry);
    return children;
  }

  static void _collectAtomicChildren(
    UDTNode node,
    List<Widget> children,
    HyperWidgetBuilder? widgetBuilder, {
    bool selectable = true,
    void Function(String)? onLinkTap,
    CodeHighlighter? codeHighlighter,
    Map<String, HyperKeyframes> keyframeRegistry = const {},
    HyperPluginRegistry? pluginRegistry,
  }) {
    Widget? childWidget;

    // Plugin registry check: highest priority, fires before all built-in logic.
    // Covers both block-tier (full-width) and inline-tier (flows with text) plugins.
    if (pluginRegistry != null && pluginRegistry.hasPlugin(node.tagName)) {
      final plugin = pluginRegistry.pluginFor(node.tagName)!;
      const baseStyle = TextStyle(fontSize: 16, color: Color(0xFF1F2937));
      const ctx = HyperPluginBuildContext(baseStyle: baseStyle);
      childWidget = plugin.buildWidget(node, ctx);
      if (childWidget != null) {
        children.add(_HyperChildWidget(
            node: node,
            child: _maybeAnimate(node, childWidget, keyframeRegistry)));
        return; // Plugin owns this node — do not recurse into children.
      }
      // Plugin returned null → fall through to built-in rendering.
    }

    // Is it a flex container?
    if (node.style.display == DisplayType.flex) {
      childWidget = widgetBuilder?.call(node);
      childWidget ??= _buildFlexContainerWidget(node, widgetBuilder,
          selectable: selectable);
      if (childWidget != null) {
        children.add(_HyperChildWidget(
            node: node,
            child: _maybeAnimate(node, childWidget, keyframeRegistry)));
      }
      // Don't recurse into flex children - they're handled by flex container
      return;
    }
    // Is it a grid container?
    if (node.style.display == DisplayType.grid) {
      childWidget = widgetBuilder?.call(node);
      childWidget ??= _buildGridContainerWidget(node, widgetBuilder,
          selectable: selectable);
      if (childWidget != null) {
        children.add(_HyperChildWidget(
            node: node,
            child: _maybeAnimate(node, childWidget, keyframeRegistry)));
      }
      // Don't recurse into grid children - they're handled by grid container
      return;
    }
    // Is it a float?
    else if (node.style.float != HyperFloat.none) {
      childWidget = widgetBuilder?.call(node);
      // Fall back to default atomic widget for any unhandled atomic node
      if (childWidget == null && node is AtomicNode) {
        childWidget = _buildDefaultAtomicWidget(node);
      } else if (childWidget == null) {
        childWidget = HyperRenderWidget(
          document: DocumentNode(children: node.children),
          selectable: selectable,
          onLinkTap: onLinkTap,
          // Propagate builder options:
          widgetBuilder: widgetBuilder,
          config: HyperRenderConfig(
            codeHighlighter: codeHighlighter,
            keyframeRegistry: keyframeRegistry,
          ),
          pluginRegistry: pluginRegistry,
        );
      }

      if (childWidget != null) {
        children.add(_HyperFloatChildWidget(
          node: node,
          floatDirection: node.style.float,
          child: _maybeAnimate(node, childWidget, keyframeRegistry),
        ));
      }
      return;
    }
    // Is it an error boundary?
    else if (node.type == NodeType.errorBoundary) {
      childWidget = widgetBuilder?.call(node);
      childWidget ??= ErrorBoundaryWidget(errorNode: node as ErrorBoundaryNode);
      // Error boundaries are never animated.
      children.add(_HyperChildWidget(node: node, child: childWidget));
      return;
    }
    // Is it a <details> element?
    else if (node.tagName?.toLowerCase() == 'details') {
      childWidget = widgetBuilder?.call(node);
      childWidget ??= HyperDetailsWidget(
        detailsNode: node,
        widgetBuilder: widgetBuilder,
      );
      children.add(_HyperChildWidget(
          node: node,
          child: _maybeAnimate(node, childWidget, keyframeRegistry)));
      return; // children handled internally by HyperDetailsWidget
    }
    // Is it a code block (<pre> with optional <code> child)?
    else if (_isCodeBlock(node)) {
      childWidget = widgetBuilder?.call(node);
      childWidget ??= _buildCodeBlockWidget(node, codeHighlighter);
      if (childWidget != null) {
        children.add(_HyperChildWidget(
            node: node,
            child: _maybeAnimate(node, childWidget, keyframeRegistry)));
      }
    }
    // Is it a non-floating atomic element or table?
    else if (node.type == NodeType.atomic) {
      final atomicNode = node as AtomicNode;
      childWidget = widgetBuilder?.call(atomicNode);
      childWidget ??= _buildDefaultAtomicWidget(atomicNode);
      if (childWidget != null) {
        children.add(_HyperChildWidget(
            node: node,
            child: _maybeAnimate(node, childWidget, keyframeRegistry)));
      }
    } else if (node.type == NodeType.table) {
      final tableNode = node as TableNode;
      childWidget = widgetBuilder?.call(tableNode);
      childWidget ??= _buildDefaultTableWidget(tableNode,
          selectable: selectable, onLinkTap: onLinkTap);
      if (childWidget != null) {
        children.add(_HyperChildWidget(
            node: node,
            child: _maybeAnimate(node, childWidget, keyframeRegistry)));
      }
    }

    // Recurse into children, but ONLY if the current node isn't a child-widget itself
    // (because its children are not part of the main render tree)
    if (childWidget == null) {
      for (final child in node.children) {
        _collectAtomicChildren(child, children, widgetBuilder,
            selectable: selectable,
            onLinkTap: onLinkTap,
            codeHighlighter: codeHighlighter,
            keyframeRegistry: keyframeRegistry,
            pluginRegistry: pluginRegistry);
      }
    }
  }

  /// Wraps [child] with [HyperAnimatedWidget] when [node] carries a CSS
  /// `animation-name` property and the keyframes are known.  Returns [child]
  /// unchanged if no animation should be applied.
  static Widget _maybeAnimate(
    UDTNode node,
    Widget child,
    Map<String, HyperKeyframes> keyframeRegistry,
  ) {
    final animName = node.style.animationName;
    if (animName == null || animName.isEmpty) return child;

    // Require that the keyframe definition is resolvable.
    final known = keyframeRegistry.containsKey(animName) ||
        HyperAnimations.byName(animName) != null;
    if (!known) return child;

    return HyperAnimatedWidget.fromStyle(
      style: node.style,
      keyframesLookup: keyframeRegistry.isNotEmpty ? keyframeRegistry : null,
      child: child,
    );
  }

  /// Check if node is a code block (<pre> element)
  static bool _isCodeBlock(UDTNode node) {
    final tagName = node.tagName?.toLowerCase();
    return tagName == 'pre' && node.type == NodeType.block;
  }

  /// Build CodeBlockWidget for <pre> elements with syntax highlighting
  static Widget? _buildCodeBlockWidget(
      UDTNode node, CodeHighlighter? highlighter) {
    // Extract code content and language
    String codeContent = '';
    String? language;

    // Check if pre has a <code> child
    for (final child in node.children) {
      if (child.tagName?.toLowerCase() == 'code') {
        // Get language from class attribute
        final classAttr = child.attributes['class'];
        language = detectLanguageFromClass(classAttr);

        // Extract text content from code element
        codeContent = _extractTextContent(child);
        break;
      }
    }

    // If no <code> child, extract text directly from <pre>
    if (codeContent.isEmpty) {
      codeContent = _extractTextContent(node);
      // Try to get language from pre's class
      final classAttr = node.attributes['class'];
      language ??= detectLanguageFromClass(classAttr);
    }

    if (codeContent.isEmpty) return null;

    return CodeBlockWidget(
      code: codeContent,
      language: language,
      theme: CodeTheme.vs2015,
      showCopyButton: true,
      showLineNumbers: false,
      highlighter: highlighter,
    );
  }

  /// Extract text content from a node tree
  static String _extractTextContent(UDTNode node) {
    final buffer = StringBuffer();
    _collectText(node, buffer);
    return buffer.toString();
  }

  static void _collectText(UDTNode node, StringBuffer buffer) {
    if (node is TextNode) {
      buffer.write(node.text);
    } else {
      for (final child in node.children) {
        _collectText(child, buffer);
      }
    }
  }

  /// Build GridContainerWidget for display:grid elements
  static Widget? _buildGridContainerWidget(
    UDTNode node,
    HyperWidgetBuilder? widgetBuilder, {
    bool selectable = false,
  }) {
    final items = <GridItem>[];
    for (final child in node.children) {
      final childWidget = _buildFlexChild(child, widgetBuilder);
      if (childWidget != null) {
        items.add(GridItem(
          child: childWidget,
          span: gridItemSpan(child),
        ));
      }
    }
    if (items.isEmpty) return null;
    return GridContainerWidget(
        node: node, items: items, selectable: selectable);
  }

  static Widget? _buildDefaultAtomicWidget(AtomicNode node) {
    // SVG inline rendering
    if (node.tagName == 'svg') {
      final svgData = node.svgData;
      final width = node.intrinsicWidth ?? node.style.width ?? 200;
      final height = node.intrinsicHeight ?? node.style.height ?? 200;
      if (svgData != null && svgData.isNotEmpty) {
        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _SvgPlaceholderPainter(svgData),
            size: Size(width, height),
          ),
        );
      }
      // SVG from src (e.g. <img src="*.svg">)
      final src = node.src;
      if (src != null && src.isNotEmpty) {
        return SizedBox(
          width: width,
          height: height,
          child: Image.network(
            src,
            width: width,
            height: height,
            errorBuilder: (_, __, ___) => SizedBox(
              width: width,
              height: height,
              child: const Icon(Icons.image_not_supported),
            ),
          ),
        );
      }
      return null;
    }

    if (node.tagName == 'img') {
      final src = node.src;
      if (src == null || src.isEmpty) return null;

      // Float images are painted on canvas by RenderHyperBox._paintFloatImages.
      // Creating a HyperImage widget here would cause a duplicate HTTP load
      // (Image.network + _loadImage via LazyImageQueue) and sizing conflicts.
      if (node.style.float != HyperFloat.none) return null;

      // Use intrinsic dimensions if available, otherwise fallback to CSS style dimensions
      final width = node.intrinsicWidth ?? node.style.width;
      final height = node.intrinsicHeight ?? node.style.height;

      // Use HyperImage with context menu for copy/save/share
      return HyperImage(
        src: src,
        width: width,
        height: height,
        borderRadius: 8.0,
        enableContextMenu: true,
      );
    }

    if (node.tagName == 'video' || node.tagName == 'audio') {
      return DefaultMediaWidget(mediaInfo: MediaInfo.fromNode(node));
    }

    if (node.tagName == 'formula') {
      final formula = node.attributes['formula'] ?? node.src ?? '';
      if (formula.isEmpty) return null;
      return FormulaWidget(formula: formula);
    }

    return null;
  }

  static Widget? _buildDefaultTableWidget(TableNode node,
      {bool selectable = true, void Function(String)? onLinkTap}) {
    // Use horizontalScroll by default — it works correctly inside IntrinsicHeight
    // rows (LayoutBuilder blocks intrinsic dimension queries, so autoScale/fitWidth
    // can only be used for top-level tables that are never measured intrinsically).
    // fitWidth is still used for tables explicitly marked with a percentage width.
    TableStrategy strategy = TableStrategy.horizontalScroll;

    // Check if table has width: 100% in inline style or width attribute
    final styleAttr = node.attributes['style'];
    final widthAttr = node.attributes['width'];

    final hasPercentWidth =
        (styleAttr?.contains('width') == true && styleAttr!.contains('%')) ||
            (widthAttr?.contains('%') ?? false);

    if (hasPercentWidth) {
      // Use fitWidth for percentage widths (wraps to device width)
      strategy = TableStrategy.fitWidth;
    }

    return SmartTableWrapper(
      tableNode: node,
      strategy: strategy,
      minScaleFactor: 0.6,
      selectable: selectable,
      onLinkTap: onLinkTap,
      // Supply a cell builder so that cells containing block-level content
      // (nested tables, paragraphs, images, …) are rendered via
      // HyperRenderWidget instead of being silently dropped.
      // selectable:false prevents a nested SelectionArea inside the outer one.
      cellContentBuilder: (cellNode) => HyperRenderWidget(
        document: DocumentNode(children: cellNode.children),
        selectable: false,
        onLinkTap: onLinkTap,
      ),
    );
  }

  /// Build FlexContainer widget for display:flex elements
  static Widget? _buildFlexContainerWidget(
    UDTNode node,
    HyperWidgetBuilder? widgetBuilder, {
    bool selectable = false,
  }) {
    // Recursively build children of flex container
    final flexChildren = <Widget>[];
    for (final child in node.children) {
      final childWidget = _buildFlexChild(child, widgetBuilder);
      if (childWidget != null) {
        // Wrap child with FlexItemWidget if it has flex properties
        if (child.style.flexGrow != null ||
            child.style.flexShrink != null ||
            child.style.flexBasis != null ||
            child.style.alignSelf != null) {
          flexChildren.add(FlexItemWidget(
            style: child.style,
            child: childWidget,
          ));
        } else {
          flexChildren.add(childWidget);
        }
      }
    }

    return FlexContainerWidget(
      node: node,
      selectable: selectable,
      children: flexChildren,
    );
  }

  /// Build a single flex child
  static TextAlign _toTextAlign(HyperTextAlign align) {
    switch (align) {
      case HyperTextAlign.center:
        return TextAlign.center;
      case HyperTextAlign.right:
        return TextAlign.right;
      case HyperTextAlign.justify:
        return TextAlign.justify;
      case HyperTextAlign.left:
        return TextAlign.left;
    }
  }

  static CrossAxisAlignment _toColumnCrossAxis(HyperTextAlign align) {
    switch (align) {
      case HyperTextAlign.center:
        return CrossAxisAlignment.center;
      case HyperTextAlign.right:
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.start;
    }
  }

  static Widget? _buildFlexChild(
      UDTNode node, HyperWidgetBuilder? widgetBuilder) {
    // If it's text content, convert to Text widget
    if (node.type == NodeType.text) {
      final textNode = node as TextNode;
      final text = textNode.text.trim();
      if (text.isEmpty) return null;

      return Text(
        text,
        textAlign: _toTextAlign(node.style.textAlign),
        style: node.style.toTextStyle(),
      );
    }

    // If it's an inline node with text children, convert to RichText
    if (node.type == NodeType.inline) {
      final spans = _buildTextSpans(node);
      if (spans.isNotEmpty) {
        return Text.rich(
          TextSpan(children: spans),
          textAlign: _toTextAlign(node.style.textAlign),
        );
      }
    }

    // If it's a nested flex container, recursively build it
    if (node.type == NodeType.block && node.style.display == DisplayType.flex) {
      return _buildFlexContainerWidget(node, widgetBuilder);
    }

    // If it's a block, create a container
    if (node.type == NodeType.block) {
      final blockChildren = <Widget>[];
      for (final child in node.children) {
        final childWidget = _buildFlexChild(child, widgetBuilder);
        if (childWidget != null) {
          blockChildren.add(childWidget);
        }
      }

      if (blockChildren.isEmpty) return null;

      // Only apply solid border via BoxDecoration — dashed/dotted/double
      // require custom painting (not supported here, skipped for now).
      final hasSolidBorder = node.style.borderWidth != EdgeInsets.zero &&
          node.style.borderStyle == HyperBorderStyle.solid;
      return Container(
        margin: node.style.margin,
        padding: node.style.padding,
        width: node.style.width,
        height: node.style.height,
        decoration: BoxDecoration(
          // Use gradient over flat color when available.
          gradient: node.style.backgroundGradient,
          color: node.style.backgroundGradient == null
              ? node.style.backgroundColor
              : null,
          border: hasSolidBorder
              ? Border(
                  top: BorderSide(
                    color: node.style.borderColor ?? Colors.transparent,
                    width: node.style.borderWidth.top,
                  ),
                  right: BorderSide(
                    color: node.style.borderColor ?? Colors.transparent,
                    width: node.style.borderWidth.right,
                  ),
                  bottom: BorderSide(
                    color: node.style.borderColor ?? Colors.transparent,
                    width: node.style.borderWidth.bottom,
                  ),
                  left: BorderSide(
                    color: node.style.borderColor ?? Colors.transparent,
                    width: node.style.borderWidth.left,
                  ),
                )
              : null,
          borderRadius: node.style.borderRadius,
          boxShadow: node.style.boxShadow,
        ),
        child: blockChildren.length == 1
            ? blockChildren.first
            : Column(
                crossAxisAlignment: _toColumnCrossAxis(node.style.textAlign),
                mainAxisSize: MainAxisSize.min,
                children: blockChildren,
              ),
      );
    }

    // If it's atomic (img, video), use existing logic
    if (node.type == NodeType.atomic) {
      return _buildDefaultAtomicWidget(node as AtomicNode);
    }

    return null;
  }

  /// Build TextSpans from node tree (for inline content)
  static List<InlineSpan> _buildTextSpans(UDTNode node) {
    final spans = <InlineSpan>[];

    for (final child in node.children) {
      if (child.type == NodeType.text) {
        final text = (child as TextNode).text;
        if (text.isNotEmpty) {
          spans.add(TextSpan(
            text: text,
            style: child.style.toTextStyle(),
          ));
        }
      } else if (child.type == NodeType.inline) {
        spans.addAll(_buildTextSpans(child));
      }
    }

    return spans;
  }

  @override
  RenderHyperBox createRenderObject(BuildContext context) {
    return RenderHyperBox(
      document: document,
      baseStyle: baseStyle,
      onLinkTap: onLinkTap,
      imageLoader: imageLoader,
      selectable: selectable,
      textDirection: textDirection,
      selectionColor: selectionColor,
      onSelectionChanged: onSelectionChanged,
      config: config,
    )
      ..debugShowBounds = debugShowBounds
      ..enableComplexFilters = enableComplexFilters
      ..suppressFirstBlockMarginTop = suppressFirstBlockMarginTop
      ..onAnchorLayout = onAnchorLayout
      ..initialFloats = initialFloats
      ..onFloatCarryover = onFloatCarryover
      ..blockPluginTags = pluginRegistry?.blockPluginTags ?? const {}
      ..inlinePluginTags = pluginRegistry?.inlinePluginTags ?? const {};
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
    if (renderObject.imageLoader != imageLoader) {
      renderObject.imageLoader = imageLoader;
    }
    if (renderObject.selectable != selectable) {
      renderObject.selectable = selectable;
    }
    if (renderObject.textDirection != textDirection) {
      renderObject.textDirection = textDirection;
    }
    if (renderObject.selectionColor != selectionColor) {
      renderObject.selectionColor = selectionColor;
    }
    if (renderObject.onSelectionChanged != onSelectionChanged) {
      renderObject.onSelectionChanged = onSelectionChanged;
    }
    if (renderObject.debugShowBounds != debugShowBounds) {
      renderObject.debugShowBounds = debugShowBounds;
      renderObject.markNeedsPaint();
    }
    if (renderObject.enableComplexFilters != enableComplexFilters) {
      renderObject.enableComplexFilters = enableComplexFilters;
      renderObject.markNeedsPaint();
    }
    if (renderObject.suppressFirstBlockMarginTop !=
        suppressFirstBlockMarginTop) {
      renderObject.suppressFirstBlockMarginTop = suppressFirstBlockMarginTop;
      renderObject.markNeedsLayout();
    }
    renderObject.onAnchorLayout = onAnchorLayout;
    if (renderObject.config != config) {
      renderObject.config = config;
    }
    renderObject.initialFloats = initialFloats;
    renderObject.onFloatCarryover = onFloatCarryover;

    // Plugin registry — update tag sets when the registry changes.
    final newBlockTags = pluginRegistry?.blockPluginTags ?? const <String>{};
    final newInlineTags = pluginRegistry?.inlinePluginTags ?? const <String>{};
    if (!_setEquals(renderObject.blockPluginTags, newBlockTags)) {
      renderObject.blockPluginTags = newBlockTags;
    }
    if (!_setEquals(renderObject.inlinePluginTags, newInlineTags)) {
      renderObject.inlinePluginTags = newInlineTags;
    }
  }
}

bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  return a.containsAll(b);
}

/// Internal widget to wrap atomic children
///
/// Uses a [ValueKey] based on [UDTNode.id] to ensure Flutter correctly matches
/// widgets to their corresponding elements during rebuilds. This prevents
/// mismatching issues when the widget tree and fragment list update asynchronously.
class _HyperChildWidget extends ParentDataWidget<HyperBoxParentData> {
  final UDTNode node;

  _HyperChildWidget({
    required this.node,
    required super.child,
  }) : super(key: ValueKey('hyper_child_${node.id}'));

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
///
/// Uses a [ValueKey] based on [UDTNode.id] to ensure Flutter correctly matches
/// float widgets to their corresponding elements during rebuilds.
class _HyperFloatChildWidget extends ParentDataWidget<HyperBoxParentData> {
  final UDTNode node;
  final HyperFloat floatDirection;

  _HyperFloatChildWidget({
    required this.node,
    required this.floatDirection,
    required super.child,
  }) : super(key: ValueKey('hyper_float_${node.id}'));

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

/// HyperImage - Image widget with context menu for copy/save/share
///
/// Features:
/// - Long-press to show context menu
/// - Copy image URL to clipboard (default)
/// - Full image copy/save/share with custom [ImageClipboardHandler]
/// - Loading and error states
///
/// ## Basic Usage
/// ```dart
/// HyperImage(src: 'https://example.com/image.jpg')
/// ```
///
/// ## With Full Clipboard Support
/// ```dart
/// HyperImage(
///   src: 'https://example.com/image.jpg',
///   clipboardHandler: SuperClipboardHandler(), // from hyper_render_clipboard
/// )
/// ```
class HyperImage extends StatelessWidget {
  /// Image source URL
  final String src;

  /// Image width
  final double? width;

  /// Image height
  final double? height;

  /// Border radius
  final double borderRadius;

  /// Handler for clipboard operations (copy, save, share)
  /// If not provided, uses [DefaultImageClipboardHandler] which only copies URLs.
  final ImageClipboardHandler? clipboardHandler;

  /// Callback for custom image actions (legacy, prefer clipboardHandler)
  /// If not provided, uses clipboardHandler behavior
  final ImageActionCallback? onImageAction;

  /// Whether to show context menu on long press
  final bool enableContextMenu;

  const HyperImage({
    super.key,
    required this.src,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.clipboardHandler,
    this.onImageAction,
    this.enableContextMenu = true,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        src,
        width: width,
        height: height,
        // cover crops to fill exact bounds; contain scales to fit without crop.
        // When only one dimension (or neither) is specified, contain avoids
        // unexpected cropping inside flex / intrinsic-size contexts.
        fit: (width != null && height != null) ? BoxFit.cover : BoxFit.contain,
        cacheWidth: width != null ? (width! * 2).toInt() : null,
        cacheHeight: height != null ? (height! * 2).toInt() : null,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width ?? 100,
            height: height ?? 100,
            color: const Color(0xFFF5F5F5),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          // When frame == null the image is still downloading; loadingBuilder
          // already provides the placeholder, so return child unchanged to
          // avoid hiding it behind opacity:0.  Once the first frame arrives,
          // animate in from transparent to fully opaque.
          if (wasSynchronouslyLoaded || frame == null) return child;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (_, value, child) => Opacity(opacity: value, child: child),
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width ?? 100,
            height: height ?? 100,
            color: const Color(0xFFE0E0E0),
            child: const Center(
              child:
                  Icon(Icons.broken_image, size: 32, color: Color(0xFF9E9E9E)),
            ),
          );
        },
      ),
    );

    if (!enableContextMenu) {
      return imageWidget;
    }

    return GestureDetector(
      onLongPressStart: (details) =>
          _showContextMenu(context, details.globalPosition),
      onSecondaryTapDown: (details) =>
          _showContextMenu(context, details.globalPosition),
      child: imageWidget,
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final handler = clipboardHandler ?? const DefaultImageClipboardHandler();
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // Build menu items based on handler capabilities
    final menuItems = <PopupMenuEntry<ImageAction>>[
      const PopupMenuItem(
        value: ImageAction.copyUrl,
        child: Row(
          children: [
            Icon(Icons.link, size: 20),
            SizedBox(width: 12),
            Text('Copy URL'),
          ],
        ),
      ),
    ];

    // Add "Copy Image" if supported
    if (handler.isImageCopySupported) {
      menuItems.add(const PopupMenuItem(
        value: ImageAction.copyImage,
        child: Row(
          children: [
            Icon(Icons.copy, size: 20),
            SizedBox(width: 12),
            Text('Copy Image'),
          ],
        ),
      ));
    }

    // Add "Save Image" if supported
    if (handler.isSaveSupported) {
      menuItems.add(const PopupMenuItem(
        value: ImageAction.saveImage,
        child: Row(
          children: [
            Icon(Icons.download, size: 20),
            SizedBox(width: 12),
            Text('Save Image'),
          ],
        ),
      ));
    }

    // Add "Share" if supported
    if (handler.isShareSupported) {
      menuItems.add(const PopupMenuItem(
        value: ImageAction.shareImage,
        child: Row(
          children: [
            Icon(Icons.share, size: 20),
            SizedBox(width: 12),
            Text('Share'),
          ],
        ),
      ));
    }

    showMenu<ImageAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: menuItems,
    ).then((action) async {
      if (action == null) return;
      if (!context.mounted) return;

      // Try custom callback first (legacy support)
      if (onImageAction != null) {
        final handled = await onImageAction!(action, src, context);
        if (handled) return;
        if (!context.mounted) return;
      }

      // Use handler for actions
      bool success = false;
      String message = '';

      switch (action) {
        case ImageAction.copyUrl:
          await Clipboard.setData(ClipboardData(text: src));
          success = true;
          message = 'Image URL copied to clipboard';
          break;

        case ImageAction.copyImage:
          success = await handler.copyImageFromUrl(src);
          message =
              success ? 'Image copied to clipboard' : 'Failed to copy image';
          break;

        case ImageAction.saveImage:
          final path = await handler.saveImageFromUrl(src);
          success = path != null;
          message = success ? 'Image saved' : 'Failed to save image';
          break;

        case ImageAction.shareImage:
          success = await handler.shareImageFromUrl(src);
          message = success
              ? ''
              : 'Failed to share image'; // No message on share success
          break;
      }

      if (context.mounted && message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            backgroundColor: success ? null : Colors.red,
          ),
        );
      }
    });
  }
}

/// Placeholder painter for inline SVG data.
/// Renders a simple bounding box with SVG icon when flutter_svg is not available.
class _SvgPlaceholderPainter extends CustomPainter {
  final String svgData;
  const _SvgPlaceholderPainter(this.svgData);

  @override
  void paint(Canvas canvas, Size size) {
    // Fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFE0E0E0),
    );
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
        const Radius.circular(4),
      ),
      Paint()
        ..color = const Color(0xFFBDBDBD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // Draw diagonal SVG placeholder lines
    final linePaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, size.height),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_SvgPlaceholderPainter old) => old.svgData != svgData;
}
