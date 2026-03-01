import 'package:flutter/painting.dart';

import 'computed_style.dart';

/// ID generator for UDT nodes
///
/// Provides unique IDs for nodes with automatic reset to prevent overflow
/// in long-running applications.
class NodeIdGenerator {
  int _counter = 0;
  static final NodeIdGenerator _instance = NodeIdGenerator._internal();

  NodeIdGenerator._internal();

  /// Get the singleton instance
  factory NodeIdGenerator() => _instance;

  /// Generate next unique ID
  String next() {
    final id = 'node_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

    // Reset counter after 1M to prevent overflow
    if (_counter >= 1000000) {
      _counter = 0;
    }

    return id;
  }

  /// Reset counter (useful for testing)
  void reset() {
    _counter = 0;
  }

  /// Get current counter value (for testing)
  int get counter => _counter;
}

/// Node type in the Unified Document Tree (UDT)
///
/// Reference: doc1.txt - "Mỗi Node trong UDT sẽ có: Type (Block/Inline), Attributes (Styles), và Children"
enum NodeType {
  /// Document root
  document,

  /// Block-level element (div, p, h1-h6, table, etc.)
  block,

  /// Inline element (span, a, strong, em, etc.)
  inline,

  /// Text content
  text,

  /// Atomic/replaced element (img, video, audio, etc.)
  atomic,

  /// Table element
  table,

  /// Table row
  tableRow,

  /// Table cell (td, th)
  tableCell,

  /// Ruby annotation (for Japanese)
  ruby,

  /// Ruby text (rt)
  rubyText,

  /// Line break (br)
  lineBreak,

  /// Interactive details/summary element
  details,

  /// Error boundary for graceful error handling
  errorBoundary,
}

/// Base class for all nodes in the Unified Document Tree (UDT)
///
/// The UDT is the "source of truth" - all input formats (HTML, Delta, Markdown)
/// are converted to UDT before rendering.
///
/// Reference: doc1.txt - "Unified Document Tree (UDT)"
/// Reference: doc3.md - Section 2 "Core Architecture"
abstract class UDTNode {
  /// Node type
  final NodeType type;

  /// Original HTML tag name (if from HTML)
  final String? tagName;

  /// HTML attributes (id, class, etc.)
  final Map<String, String> attributes;

  /// Computed style (resolved from CSS cascade)
  ComputedStyle style;

  /// Parent node (null for root)
  UDTNode? parent;

  /// Child nodes
  final List<UDTNode> children;

  /// Unique identifier for this node (for hit testing, selection)
  ///
  /// Layout information (position, size, baseline) is now stored separately
  /// in [LayoutCache] for better separation of concerns and performance.
  final String id;

  /// ID generator instance
  static final NodeIdGenerator _idGenerator = NodeIdGenerator();

  UDTNode({
    required this.type,
    this.tagName,
    Map<String, String>? attributes,
    ComputedStyle? style,
    List<UDTNode>? children,
    String? id,
  })  : attributes = attributes ?? {},
        style = style ?? ComputedStyle(),
        children = children ?? [],
        id = id ?? _idGenerator.next() {
    for (final child in this.children) {
      child.parent = this;
    }
  }

  /// Add a child node
  void appendChild(UDTNode child) {
    child.parent = this;
    children.add(child);
  }

  /// Remove a child node
  bool removeChild(UDTNode child) {
    final removed = children.remove(child);
    if (removed) {
      child.parent = null;
    }
    return removed;
  }

  /// Get all text content recursively
  String get textContent {
    if (this is TextNode) {
      return (this as TextNode).text;
    }
    return children.map((child) => child.textContent).join();
  }

  /// Check if this node is block-level
  bool get isBlock =>
      type == NodeType.block ||
      type == NodeType.table ||
      type == NodeType.tableRow ||
      style.display == DisplayType.block;

  /// Check if this node is inline
  bool get isInline =>
      type == NodeType.inline ||
      type == NodeType.text ||
      style.display == DisplayType.inline ||
      style.display == DisplayType.inlineBlock;

  /// Traverse the tree (pre-order)
  void traverse(void Function(UDTNode node) visitor) {
    visitor(this);
    for (final child in children) {
      child.traverse(visitor);
    }
  }

  /// Find node by ID
  UDTNode? findById(String targetId) {
    if (id == targetId) return this;
    for (final child in children) {
      final found = child.findById(targetId);
      if (found != null) return found;
    }
    return null;
  }

  /// Get CSS class list
  List<String> get classList {
    final classAttr = attributes['class'];
    if (classAttr == null || classAttr.isEmpty) return [];
    return classAttr.split(RegExp(r'\s+'));
  }

  /// Get CSS ID
  String? get cssId => attributes['id'];

  @override
  String toString() => 'UDTNode($type, tag=$tagName, children=${children.length})';
}

/// Document root node
class DocumentNode extends UDTNode {
  DocumentNode({
    super.children,
  }) : super(
          type: NodeType.document,
          tagName: 'document',
        );
}

/// Block-level element node (div, p, h1-h6, blockquote, etc.)
///
/// Reference: doc1.txt - "Block Formatting Context (BFC)"
class BlockNode extends UDTNode {
  BlockNode({
    required String super.tagName,
    super.attributes,
    ComputedStyle? style,
    super.children,
  }) : super(
          type: NodeType.block,
          style: style ?? ComputedStyle(display: DisplayType.block),
        );

  /// Factory for common block elements with default styles
  factory BlockNode.h1({List<UDTNode>? children}) => BlockNode(
        tagName: 'h1',
        style: ComputedStyle(
          display: DisplayType.block,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          margin: const EdgeInsets.symmetric(vertical: 21.44),
        ),
        children: children,
      );

  factory BlockNode.h2({List<UDTNode>? children}) => BlockNode(
        tagName: 'h2',
        style: ComputedStyle(
          display: DisplayType.block,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          margin: const EdgeInsets.symmetric(vertical: 19.92),
        ),
        children: children,
      );

  factory BlockNode.p({List<UDTNode>? children}) => BlockNode(
        tagName: 'p',
        style: ComputedStyle(
          display: DisplayType.block,
          margin: const EdgeInsets.symmetric(vertical: 16),
        ),
        children: children,
      );

  factory BlockNode.div({List<UDTNode>? children}) => BlockNode(
        tagName: 'div',
        children: children,
      );

  factory BlockNode.blockquote({List<UDTNode>? children}) => BlockNode(
        tagName: 'blockquote',
        style: ComputedStyle(
          display: DisplayType.block,
          margin: const EdgeInsets.fromLTRB(40, 16, 40, 16),
        ),
        children: children,
      );
}

/// Inline element node (span, a, strong, em, etc.)
///
/// Reference: doc1.txt - "Inline Formatting Context (IFC)"
class InlineNode extends UDTNode {
  InlineNode({
    required String super.tagName,
    super.attributes,
    ComputedStyle? style,
    super.children,
  }) : super(
          type: NodeType.inline,
          style: style ?? ComputedStyle(display: DisplayType.inline),
        );

  /// Factory for common inline elements with default styles
  factory InlineNode.span({List<UDTNode>? children}) => InlineNode(
        tagName: 'span',
        children: children,
      );

  factory InlineNode.strong({List<UDTNode>? children}) => InlineNode(
        tagName: 'strong',
        style: ComputedStyle(fontWeight: FontWeight.bold),
        children: children,
      );

  factory InlineNode.em({List<UDTNode>? children}) => InlineNode(
        tagName: 'em',
        style: ComputedStyle(fontStyle: FontStyle.italic),
        children: children,
      );

  factory InlineNode.a({
    required String href,
    List<UDTNode>? children,
  }) =>
      InlineNode(
        tagName: 'a',
        attributes: {'href': href},
        style: ComputedStyle(
          color: const Color(0xFF0000EE),
          textDecoration: TextDecoration.underline,
        ),
        children: children,
      );

  factory InlineNode.code({List<UDTNode>? children}) => InlineNode(
        tagName: 'code',
        style: ComputedStyle(fontFamily: 'monospace'),
        children: children,
      );

  factory InlineNode.u({List<UDTNode>? children}) => InlineNode(
        tagName: 'u',
        style: ComputedStyle(textDecoration: TextDecoration.underline),
        children: children,
      );

  factory InlineNode.s({List<UDTNode>? children}) => InlineNode(
        tagName: 's',
        style: ComputedStyle(textDecoration: TextDecoration.lineThrough),
        children: children,
      );
}

/// Text content node
///
/// Represents raw text content without any HTML tags
class TextNode extends UDTNode {
  /// The text content
  final String text;

  TextNode(this.text, {super.style, super.id})
      : super(
          type: NodeType.text,
          tagName: '#text',
        );

  @override
  String get textContent => text;

  @override
  String toString() => 'TextNode("${text.length > 20 ? '${text.substring(0, 20)}...' : text}")';
}

/// Line break node (br)
class LineBreakNode extends UDTNode {
  LineBreakNode()
      : super(
          type: NodeType.lineBreak,
          tagName: 'br',
        );
}

/// Atomic/replaced element node (img, video, audio, iframe)
///
/// These elements have intrinsic dimensions and are treated as
/// single units during layout (like a large character)
///
/// Reference: doc1.txt - "Atomic Fragment"
class AtomicNode extends UDTNode {
  /// Source URL for media elements
  final String? src;

  /// Alt text for images
  final String? alt;

  /// Intrinsic width (from attribute or natural size)
  final double? intrinsicWidth;

  /// Intrinsic height (from attribute or natural size)
  final double? intrinsicHeight;

  AtomicNode({
    required String super.tagName,
    this.src,
    this.alt,
    this.intrinsicWidth,
    this.intrinsicHeight,
    super.attributes,
    ComputedStyle? style,
  }) : super(
          type: NodeType.atomic,
          style: style ?? ComputedStyle(display: DisplayType.inlineBlock),
        );

  /// Factory for image element
  factory AtomicNode.img({
    required String src,
    String? alt,
    double? width,
    double? height,
  }) =>
      AtomicNode(
        tagName: 'img',
        src: src,
        alt: alt,
        intrinsicWidth: width,
        intrinsicHeight: height,
        attributes: {
          'src': src,
          if (alt != null) 'alt': alt,
        },
      );

  /// Factory for video element
  factory AtomicNode.video({
    required String src,
    double? width,
    double? height,
  }) =>
      AtomicNode(
        tagName: 'video',
        src: src,
        intrinsicWidth: width,
        intrinsicHeight: height,
        attributes: {'src': src},
      );
}

/// Ruby annotation node (for Japanese Furigana)
///
/// Reference: doc3.md - Section "Requirement 4: Japanese Ruby/Furigana Support"
class RubyNode extends UDTNode {
  /// Base text (Kanji)
  final String baseText;

  /// Ruby text (Furigana)
  final String rubyText;

  RubyNode({
    required this.baseText,
    required this.rubyText,
    super.style,
  }) : super(
          type: NodeType.ruby,
          tagName: 'ruby',
        );

  @override
  String get textContent => baseText;
}

/// Table node
///
/// Reference: doc3.md - Section "Requirement 2: Table Horizontal Scroll"
class TableNode extends UDTNode {
  TableNode({
    super.attributes,
    ComputedStyle? style,
    super.children,
  }) : super(
          type: NodeType.table,
          tagName: 'table',
          style: style ?? ComputedStyle(display: DisplayType.table),
        );
}

/// Table row node
class TableRowNode extends UDTNode {
  TableRowNode({
    super.attributes,
    ComputedStyle? style,
    super.children,
  }) : super(
          type: NodeType.tableRow,
          tagName: 'tr',
          style: style ?? ComputedStyle(display: DisplayType.tableRow),
        );
}

/// Table cell node (td or th)
class TableCellNode extends UDTNode {
  /// Whether this is a header cell (th)
  final bool isHeader;

  TableCellNode({
    this.isHeader = false,
    super.attributes,
    ComputedStyle? style,
    super.children,
  }) : super(
          type: NodeType.tableCell,
          tagName: isHeader ? 'th' : 'td',
          style: style ??
              ComputedStyle(
                display: DisplayType.tableCell,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              ),
        );

  /// Get colspan value
  int get colspan => int.tryParse(attributes['colspan'] ?? '1') ?? 1;

  /// Get rowspan value
  int get rowspan => int.tryParse(attributes['rowspan'] ?? '1') ?? 1;
}

/// Details node for interactive disclosure widget (`<details>`/`<summary>`)
///
/// Represents the HTML `<details>` element which provides an interactive
/// disclosure widget that can be toggled open/closed by the user.
class DetailsNode extends UDTNode {
  /// Whether the details should be initially open
  final bool open;

  DetailsNode({
    super.attributes,
    ComputedStyle? style,
    super.children,
    this.open = false,
  }) : super(
          type: NodeType.details,
          tagName: 'details',
          style: style ?? ComputedStyle(display: DisplayType.block),
        );

  /// Check if the 'open' attribute is present in HTML
  static bool isOpen(Map<String, String> attributes) {
    return attributes.containsKey('open');
  }
}

/// Error boundary node for graceful error handling
///
/// Represents an error that occurred during parsing or rendering.
/// Instead of crashing the entire app, errors are captured and displayed
/// in a user-friendly way.
///
/// Example usage:
/// ```dart
/// try {
///   return parseHTML(html);
/// } catch (e, stack) {
///   return DocumentNode(children: [
///     ErrorBoundaryNode(
///       error: e,
///       stackTrace: stack,
///       friendlyMessage: 'Failed to parse HTML',
///     ),
///   ]);
/// }
/// ```
class ErrorBoundaryNode extends UDTNode {
  /// The error that was caught
  final dynamic error;

  /// Stack trace of the error
  final StackTrace stackTrace;

  /// User-friendly error message
  final String? friendlyMessage;

  /// Original content that failed to parse (for debugging)
  final String? originalContent;

  ErrorBoundaryNode({
    required this.error,
    required this.stackTrace,
    this.friendlyMessage,
    this.originalContent,
    super.attributes,
  }) : super(
          type: NodeType.errorBoundary,
          tagName: 'error-boundary',
          style: ComputedStyle(display: DisplayType.block),
        );

  /// Get error message as string
  String get errorMessage => error?.toString() ?? 'Unknown error';

  /// Get abbreviated stack trace (first 5 lines)
  String get shortStackTrace {
    final lines = stackTrace.toString().split('\n');
    final abbreviated = lines.take(5).join('\n');
    if (lines.length > 5) {
      return '$abbreviated\n... (${lines.length - 5} more lines)';
    }
    return abbreviated;
  }

  @override
  String toString() =>
      'ErrorBoundaryNode(error: $errorMessage, message: $friendlyMessage)';
}
