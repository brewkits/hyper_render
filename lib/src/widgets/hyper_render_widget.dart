import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/image_provider.dart';
import '../core/render_hyper_box.dart';
import '../core/render_table.dart';
import '../interfaces/image_clipboard.dart';
import '../model/computed_style.dart';
import '../model/node.dart';
import 'code_block_widget.dart';
import 'flex_container_widget.dart';

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

  /// Custom image loader for loading images
  /// If not provided, uses the default NetworkImage-based loader
  final HyperImageLoader? imageLoader;

  /// Whether text selection is enabled
  final bool selectable;

  /// Callback when selection changes (e.g., to show context menu)
  final VoidCallback? onSelectionChanged;

  /// Draw debug bounds around each fragment and line row.
  /// See [RenderHyperBox.debugShowBounds].
  final bool debugShowBounds;

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
    this.imageLoader,
    this.selectable = true,
    this.onSelectionChanged,
    this.debugShowBounds = false,
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

    // Is it a flex container?
    if (node.style.display == DisplayType.flex) {
      childWidget = widgetBuilder?.call(node);
      childWidget ??= _buildFlexContainerWidget(node, widgetBuilder);
      if (childWidget != null) {
        children.add(_HyperChildWidget(node: node, child: childWidget));
      }
      // Don't recurse into flex children - they're handled by flex container
      return;
    }
    // Is it a float?
    else if (node.style.float != HyperFloat.none) {
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
    // Is it a code block (<pre> with optional <code> child)?
    else if (_isCodeBlock(node)) {
      childWidget = widgetBuilder?.call(node);
      childWidget ??= _buildCodeBlockWidget(node);
      if (childWidget != null) {
        children.add(_HyperChildWidget(node: node, child: childWidget));
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

  /// Check if node is a code block (<pre> element)
  static bool _isCodeBlock(UDTNode node) {
    final tagName = node.tagName?.toLowerCase();
    return tagName == 'pre' && node.type == NodeType.block;
  }

  /// Build CodeBlockWidget for <pre> elements with syntax highlighting
  static Widget? _buildCodeBlockWidget(UDTNode node) {
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

  static Widget? _buildDefaultAtomicWidget(AtomicNode node) {
    if (node.tagName == 'img') {
      final src = node.src;
      if (src == null || src.isEmpty) return null;

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
    // Auto-detect strategy based on CSS width:
    // - If width is 100%, use fitWidth (table wraps to screen like fwfh)
    // - Otherwise, use autoScale (table scales down if too wide)
    TableStrategy strategy = TableStrategy.autoScale;

    // Check if table has width: 100% in inline style or width attribute
    final styleAttr = node.attributes['style'];
    final widthAttr = node.attributes['width'];

    final hasPercentWidth = (styleAttr?.contains('width') == true &&
                            styleAttr!.contains('%')) ||
                            (widthAttr?.contains('%') ?? false);

    if (hasPercentWidth) {
      // Use fitWidth for percentage widths (wraps to device width)
      strategy = TableStrategy.fitWidth;
    }

    return SmartTableWrapper(
      tableNode: node,
      strategy: strategy,
      minScaleFactor: 0.6,
    );
  }

  /// Build FlexContainer widget for display:flex elements
  static Widget? _buildFlexContainerWidget(
    UDTNode node,
    HyperWidgetBuilder? widgetBuilder,
  ) {
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
      children: flexChildren,
    );
  }

  /// Build a single flex child
  static Widget? _buildFlexChild(UDTNode node, HyperWidgetBuilder? widgetBuilder) {
    // If it's text content, convert to Text widget
    if (node.type == NodeType.text) {
      final textNode = node as TextNode;
      final text = textNode.text.trim();
      if (text.isEmpty) return null;

      return Text(
        text,
        style: node.style.toTextStyle(),
      );
    }

    // If it's an inline node with text children, convert to RichText
    if (node.type == NodeType.inline) {
      final spans = _buildTextSpans(node);
      if (spans.isNotEmpty) {
        return Text.rich(
          TextSpan(children: spans),
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

      return Container(
        margin: node.style.margin,
        padding: node.style.padding,
        width: node.style.width,
        height: node.style.height,
        decoration: BoxDecoration(
          color: node.style.backgroundColor,
          border: node.style.borderWidth != EdgeInsets.zero
              ? Border.all(
                  color: node.style.borderColor ?? Colors.transparent,
                  width: node.style.borderWidth.top,
                )
              : null,
          borderRadius: node.style.borderRadius,
        ),
        child: blockChildren.length == 1
            ? blockChildren.first
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
      onSelectionChanged: onSelectionChanged,
    )..debugShowBounds = debugShowBounds;
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
    if (renderObject.onSelectionChanged != onSelectionChanged) {
      renderObject.onSelectionChanged = onSelectionChanged;
    }
    if (renderObject.debugShowBounds != debugShowBounds) {
      renderObject.debugShowBounds = debugShowBounds;
      renderObject.markNeedsPaint();
    }
  }
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
        fit: BoxFit.cover,
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
            width: width ?? 100,
            height: height ?? 100,
            color: const Color(0xFFE0E0E0),
            child: const Center(
              child: Icon(Icons.broken_image, size: 32, color: Color(0xFF9E9E9E)),
            ),
          );
        },
      ),
    );

    if (!enableContextMenu) {
      return imageWidget;
    }

    return GestureDetector(
      onLongPressStart: (details) => _showContextMenu(context, details.globalPosition),
      onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
      child: imageWidget,
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final handler = clipboardHandler ?? const DefaultImageClipboardHandler();
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

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
          message = success ? 'Image copied to clipboard' : 'Failed to copy image';
          break;

        case ImageAction.saveImage:
          final path = await handler.saveImageFromUrl(src);
          success = path != null;
          message = success ? 'Image saved' : 'Failed to save image';
          break;

        case ImageAction.shareImage:
          success = await handler.shareImageFromUrl(src);
          message = success ? '' : 'Failed to share image'; // No message on share success
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
