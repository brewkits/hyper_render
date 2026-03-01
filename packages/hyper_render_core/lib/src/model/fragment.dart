import 'dart:ui';

import 'computed_style.dart';
import 'node.dart';

/// Fragment type for inline layout
///
/// Reference: doc1.txt - "Chiến lược Chunking & Line Building"
/// Content is divided into Fragments (Mảnh):
/// - Text Fragment: A phrase with the same style
/// - Atomic Fragment: An icon, image, or media (treated as a special character)
enum FragmentType {
  /// Text content fragment
  text,

  /// Atomic/replaced element (img, video, etc.)
  atomic,

  /// Line break (forced)
  lineBreak,

  /// Ruby annotation (Japanese)
  ruby,
}

/// A Fragment represents a unit of content for inline layout
///
/// During layout, the content is broken into Fragments, each measured
/// independently, then arranged into lines.
///
/// Reference: doc1.txt - "Quy trình 4 bước của thuật toán"
/// Step 1: Tokenization - Break into Fragments
/// Step 2: Measuring - Measure each Fragment
/// Step 3: Line Breaking - Arrange into lines
/// Step 4: Baseline Alignment
class Fragment {
  /// Fragment type
  final FragmentType type;

  /// Text content (for text fragments)
  final String? text;

  /// Source UDT node
  final UDTNode sourceNode;

  /// Computed style
  final ComputedStyle style;

  /// Measured size (set after measuring)
  Size? measuredSize;

  /// Position offset within the line (set after layout)
  Offset? offset;

  /// Character offset in the full text (for selection)
  int characterOffset;

  /// For ruby fragments
  final String? rubyText;

  /// Ruby annotation height (for proper layout)
  double? rubyHeight;

  Fragment({
    required this.type,
    this.text,
    required this.sourceNode,
    required this.style,
    this.characterOffset = 0,
    this.rubyText,
  });

  /// Create a text fragment
  factory Fragment.text({
    required String text,
    required UDTNode sourceNode,
    required ComputedStyle style,
    int characterOffset = 0,
  }) {
    return Fragment(
      type: FragmentType.text,
      text: text,
      sourceNode: sourceNode,
      style: style,
      characterOffset: characterOffset,
    );
  }

  /// Create an atomic fragment (image, video, etc.)
  factory Fragment.atomic({
    required UDTNode sourceNode,
    required ComputedStyle style,
    required Size size,
  }) {
    return Fragment(
      type: FragmentType.atomic,
      sourceNode: sourceNode,
      style: style,
    )..measuredSize = size;
  }

  /// Create a line break fragment
  factory Fragment.lineBreak({
    required UDTNode sourceNode,
    required ComputedStyle style,
  }) {
    return Fragment(
      type: FragmentType.lineBreak,
      sourceNode: sourceNode,
      style: style,
    )..measuredSize = Size.zero;
  }

  /// Create a ruby fragment
  factory Fragment.ruby({
    required String baseText,
    required String rubyText,
    required UDTNode sourceNode,
    required ComputedStyle style,
  }) {
    return Fragment(
      type: FragmentType.ruby,
      text: baseText,
      rubyText: rubyText,
      sourceNode: sourceNode,
      style: style,
    );
  }

  /// Width of the fragment (after measuring)
  double get width => measuredSize?.width ?? 0;

  /// Height of the fragment (after measuring)
  double get height => measuredSize?.height ?? 0;

  /// Get the bounding rect (after layout)
  Rect? get rect {
    if (offset == null || measuredSize == null) return null;
    return Rect.fromLTWH(
      offset!.dx,
      offset!.dy,
      measuredSize!.width,
      measuredSize!.height,
    );
  }

  /// Check if this fragment can be broken (for line wrapping)
  bool get canBreak => type == FragmentType.text && text != null && text!.contains(' ');

  /// Check if this is a whitespace-only fragment
  bool get isWhitespace =>
      type == FragmentType.text && text != null && text!.trim().isEmpty;

  @override
  String toString() {
    switch (type) {
      case FragmentType.text:
        final displayText =
            text!.length > 20 ? '${text!.substring(0, 20)}...' : text!;
        return 'Fragment.text("$displayText")';
      case FragmentType.atomic:
        return 'Fragment.atomic(${sourceNode.tagName})';
      case FragmentType.lineBreak:
        return 'Fragment.lineBreak';
      case FragmentType.ruby:
        return 'Fragment.ruby($text|$rubyText)';
    }
  }
}

/// A line of fragments after layout
///
/// Reference: doc1.txt - "Bước 3: Xây dựng dòng (Line Breaking)"
class LineInfo {
  /// Fragments in this line
  final List<Fragment> fragments = [];

  /// Line bounds (set after layout)
  Rect? bounds;

  /// Top position of the line (y coordinate)
  double top = 0;

  /// Baseline position relative to line top
  double baseline = 0;

  /// Left inset for float elements
  double leftInset = 0;

  /// Right inset for float elements
  double rightInset = 0;

  /// Constructor with optional initial values
  LineInfo({
    this.top = 0,
    this.baseline = 0,
    this.leftInset = 0,
    this.rightInset = 0,
  });

  /// Add a fragment to this line
  void add(Fragment fragment) {
    fragments.add(fragment);
  }

  /// Total width of all fragments
  double get width {
    if (fragments.isEmpty) return 0;
    double total = 0;
    for (final frag in fragments) {
      total += frag.width;
    }
    return total;
  }

  /// Maximum height of all fragments
  double get height {
    if (fragments.isEmpty) return 0;
    double maxHeight = 0;
    for (final frag in fragments) {
      if (frag.height > maxHeight) {
        maxHeight = frag.height;
      }
    }
    return maxHeight;
  }

  /// Number of characters in this line
  int get characterCount {
    int count = 0;
    for (final frag in fragments) {
      if (frag.type == FragmentType.text && frag.text != null) {
        count += frag.text!.length;
      } else if (frag.type == FragmentType.lineBreak) {
        count += 1; // Line break counts as 1 character
      }
    }
    return count;
  }

  /// Check if line is empty
  bool get isEmpty => fragments.isEmpty;

  /// Check if line is not empty
  bool get isNotEmpty => fragments.isNotEmpty;

  @override
  String toString() =>
      'LineInfo(fragments=${fragments.length}, width=$width, height=$height)';
}
