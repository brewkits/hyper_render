import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../model/node.dart';
import '../model/computed_style.dart';
import 'render_formula.dart';
import 'render_media.dart';
import 'render_ruby.dart';
import 'render_table.dart';
import '../widgets/details_widget.dart';

/// Callback for handling link taps
typedef LinkTapCallback = void Function(String url);

/// Callback for handling image loading
typedef ImageBuilder = Widget Function(String src, String? alt, double? width, double? height);

/// HtmlToSpanConverter - Core Engine
///
/// Converts UDT (Unified Document Tree) to InlineSpan tree.
/// This is the paradigm shift from "1 tag → 1 Widget" to
/// "Entire HTML → Single InlineSpan tree".
///
/// Benefits:
/// - SelectionArea only manages 1 RenderParagraph
/// - Simple layout, high performance
/// - Smooth text selection without interruption
/// - Perfect compatibility with Flutter text engine
///
/// Reference: doc3.md - "2.1 Paradigm Shift: Single InlineSpan Tree"
class HtmlToSpanConverter {
  /// Base text style
  final TextStyle baseStyle;

  /// Link tap callback
  final LinkTapCallback? onLinkTap;

  /// Custom image builder
  final ImageBuilder? imageBuilder;

  /// Custom media widget builder for audio/video
  final MediaWidgetBuilder? mediaBuilder;

  /// Callback when media element is tapped (used when no custom mediaBuilder)
  final void Function(MediaInfo)? onMediaTap;

  /// Whether to preserve whitespace
  final bool preserveWhitespace;

  /// Gesture recognizers to dispose later
  final List<GestureRecognizer> _recognizers = [];

  HtmlToSpanConverter({
    TextStyle? baseStyle,
    this.onLinkTap,
    this.imageBuilder,
    this.mediaBuilder,
    this.onMediaTap,
    this.preserveWhitespace = false,
  }) : baseStyle = baseStyle ?? const TextStyle(fontSize: 16, color: Colors.black);

  /// Convert a document node to InlineSpan
  ///
  /// Returns a TextSpan containing the entire document as a single tree
  InlineSpan convert(DocumentNode document) {
    final children = <InlineSpan>[];

    for (final child in document.children) {
      final span = _convertNode(child);
      if (span != null) {
        children.add(span);
      }
    }

    return TextSpan(
      style: baseStyle,
      children: children,
    );
  }

  /// Convert a single UDT node to InlineSpan
  InlineSpan? _convertNode(UDTNode node) {
    // Skip hidden elements
    if (node.style.display == DisplayType.none) {
      return null;
    }

    switch (node.type) {
      case NodeType.text:
        return _convertText(node as TextNode);

      case NodeType.inline:
        return _convertInline(node);

      case NodeType.block:
        return _convertBlock(node);

      case NodeType.lineBreak:
        return const TextSpan(text: '\n');

      case NodeType.atomic:
        return _convertAtomic(node as AtomicNode);

      case NodeType.ruby:
        return _convertRuby(node as RubyNode);

      case NodeType.table:
        return _convertTable(node as TableNode);

      case NodeType.tableRow:
      case NodeType.tableCell:
        // These are handled by table converter
        return null;

      case NodeType.details:
        return _convertDetails(node as DetailsNode);

      case NodeType.errorBoundary:
        // Error boundaries are handled by ErrorBoundaryWidget, not inline spans
        return null;

      case NodeType.document:
      case NodeType.rubyText:
        return null;
    }
  }

  /// Convert text node
  TextSpan _convertText(TextNode node) {
    String text = node.text;

    // Normalize whitespace unless preserving
    if (!preserveWhitespace) {
      text = _normalizeWhitespace(text);
    }

    return TextSpan(
      text: text,
      style: node.style.toTextStyle(),
    );
  }

  /// Convert inline element (span, a, strong, em, etc.)
  InlineSpan _convertInline(UDTNode node) {
    final children = <InlineSpan>[];

    for (final child in node.children) {
      final span = _convertNode(child);
      if (span != null) {
        children.add(span);
      }
    }

    // Handle links
    if (node.tagName == 'a') {
      final href = node.attributes['href'];
      TapGestureRecognizer? recognizer;

      if (href != null && onLinkTap != null) {
        recognizer = TapGestureRecognizer()
          ..onTap = () => onLinkTap!(href);
        _recognizers.add(recognizer);
      }

      return TextSpan(
        children: children,
        style: node.style.toTextStyle(),
        recognizer: recognizer,
      );
    }

    return TextSpan(
      children: children,
      style: node.style.toTextStyle(),
    );
  }

  /// Convert block element (p, div, h1-h6, etc.)
  ///
  /// Block elements are converted to TextSpan with newlines
  InlineSpan _convertBlock(UDTNode node) {
    final children = <InlineSpan>[];

    // Add block-level margin/padding as space
    // (In full implementation, this would use custom paragraph styles)

    for (final child in node.children) {
      final span = _convertNode(child);
      if (span != null) {
        children.add(span);
      }
    }

    // Add newline after block elements
    children.add(const TextSpan(text: '\n'));

    // For headings and paragraphs, add extra spacing
    if (_isBlockWithMargin(node.tagName)) {
      children.add(const TextSpan(text: '\n'));
    }

    return TextSpan(
      children: children,
      style: node.style.toTextStyle(),
    );
  }

  /// Convert atomic element (img, video, audio, formula, etc.)
  InlineSpan _convertAtomic(AtomicNode node) {
    if (node.tagName == 'img') {
      return _convertImage(node);
    }

    // Handle audio and video elements
    if (node.tagName == 'audio' || node.tagName == 'video') {
      return _convertMedia(node);
    }

    // Handle LaTeX formula
    if (node.tagName == 'formula') {
      return _convertFormula(node);
    }

    // Placeholder for other atomic elements (iframe, etc.)
    return WidgetSpan(
      child: Container(
        width: node.intrinsicWidth ?? 200,
        height: node.intrinsicHeight ?? 100,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.widgets_outlined, size: 48),
        ),
      ),
      alignment: PlaceholderAlignment.middle,
    );
  }

  /// Convert formula element (LaTeX)
  InlineSpan _convertFormula(AtomicNode node) {
    final formula = node.attributes['formula'] ?? node.src ?? '';

    return WidgetSpan(
      child: FormulaWidget(
        formula: formula,
        style: node.style.toTextStyle(),
      ),
      alignment: PlaceholderAlignment.middle,
    );
  }

  /// Convert media element (audio/video)
  InlineSpan _convertMedia(AtomicNode node) {
    final mediaInfo = MediaInfo.fromNode(node);

    // Use custom media builder if provided
    if (mediaBuilder != null) {
      return WidgetSpan(
        child: Builder(
          builder: (context) => mediaBuilder!(context, mediaInfo),
        ),
        alignment: PlaceholderAlignment.middle,
      );
    }

    // Use default media widget with optional tap callback
    // IMPORTANT: Use onMediaTap if available, otherwise try onLinkTap for video URLs
    return WidgetSpan(
      child: DefaultMediaWidget(
        mediaInfo: mediaInfo,
        onTap: onMediaTap != null
            ? () => onMediaTap!(mediaInfo)
            : (onLinkTap != null && mediaInfo.src.isNotEmpty
                ? () => onLinkTap!(mediaInfo.src)
                : null),
      ),
      alignment: PlaceholderAlignment.middle,
    );
  }

  /// Convert image element
  InlineSpan _convertImage(AtomicNode node) {
    final src = node.src ?? '';
    final alt = node.alt;
    final width = node.intrinsicWidth;
    final height = node.intrinsicHeight;

    // Use custom image builder if provided
    if (imageBuilder != null) {
      return WidgetSpan(
        child: imageBuilder!(src, alt, width, height),
        alignment: PlaceholderAlignment.middle,
      );
    }

    // Default image widget
    Widget imageWidget;
    if (src.startsWith('http://') || src.startsWith('https://')) {
      imageWidget = Image.network(
        src,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageError(alt, width, height);
        },
      );
    } else {
      imageWidget = _buildImageError(alt, width, height);
    }

    return WidgetSpan(
      child: imageWidget,
      alignment: PlaceholderAlignment.middle,
    );
  }

  Widget _buildImageError(String? alt, double? width, double? height) {
    return Container(
      width: width ?? 100,
      height: height ?? 100,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, size: 32),
          if (alt != null)
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                alt,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  /// Convert ruby annotation
  ///
  /// Uses custom RubySpan for perfect furigana rendering
  InlineSpan _convertRuby(RubyNode node) {
    return RubySpan(
      baseText: node.baseText,
      rubyText: node.rubyText,
      baseStyle: node.style.toTextStyle(),
    );
  }

  /// Convert table element
  ///
  /// Tables are rendered as WidgetSpan with SmartTableWrapper
  InlineSpan _convertTable(TableNode node) {
    return WidgetSpan(
      child: SmartTableWrapper(
        tableNode: node,
        baseStyle: baseStyle,
        onLinkTap: onLinkTap,
      ),
      alignment: PlaceholderAlignment.middle,
    );
  }

  /// Convert details element (`<details>`/`<summary>`)
  ///
  /// Details elements are rendered as WidgetSpan with DetailsWidget
  InlineSpan _convertDetails(DetailsNode node) {
    return WidgetSpan(
      child: DetailsWidget(
        detailsNode: node,
        baseStyle: baseStyle,
        onLinkTap: onLinkTap,
      ),
      alignment: PlaceholderAlignment.middle,
    );
  }

  /// Check if block element should have margin
  bool _isBlockWithMargin(String? tagName) {
    return tagName == 'p' ||
        tagName == 'h1' ||
        tagName == 'h2' ||
        tagName == 'h3' ||
        tagName == 'h4' ||
        tagName == 'h5' ||
        tagName == 'h6' ||
        tagName == 'blockquote';
  }

  /// Normalize whitespace (collapse multiple spaces, trim)
  String _normalizeWhitespace(String text) {
    // Collapse multiple whitespace to single space
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Dispose gesture recognizers
  ///
  /// Call this when the widget is disposed
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }
}

/// Extension to build widgets from converter
extension HtmlToSpanConverterWidgets on HtmlToSpanConverter {
  /// Build a RichText widget from document
  Widget buildRichText(DocumentNode document) {
    final span = convert(document);

    return RichText(
      text: span as TextSpan,
      softWrap: true,
    );
  }

  /// Build a SelectableText widget from document
  Widget buildSelectableText(DocumentNode document) {
    final span = convert(document);

    return SelectableText.rich(
      span as TextSpan,
    );
  }

  /// Build with SelectionArea wrapper (recommended)
  Widget buildWithSelectionArea(DocumentNode document) {
    final span = convert(document);

    return SelectionArea(
      child: RichText(
        text: span as TextSpan,
        softWrap: true,
      ),
    );
  }
}
