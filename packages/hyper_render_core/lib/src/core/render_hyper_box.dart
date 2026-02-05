import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../model/computed_style.dart';
import '../model/fragment.dart';
import '../model/node.dart';
import 'image_provider.dart';
import 'kinsoku_processor.dart';

/// Callback for handling link taps
typedef HyperLinkTapCallback = void Function(String url);

/// Callback for building custom widgets for embedded content
typedef HyperWidgetBuilder = Widget? Function(UDTNode node);

/// Callback when image loading state changes
typedef ImageLoadCallback = void Function(String src, ImageLoadState state);

/// Parent data for children of RenderHyperBox
class HyperBoxParentData extends ContainerBoxParentData<RenderBox> {
  /// The source UDT node this child corresponds to
  UDTNode? sourceNode;

  /// The fragment this child corresponds to (for atomic elements)
  Fragment? fragment;

  /// Whether this child is a float element
  bool isFloat = false;

  /// Float direction (left or right)
  HyperFloat floatDirection = HyperFloat.none;

  /// The computed rect after float layout
  Rect? floatRect;
}

/// Float area that text must flow around
class _FloatArea {
  final Rect rect;
  final HyperFloat direction;

  _FloatArea({required this.rect, required this.direction});
}

/// Inline decoration info for painting background/border across line breaks
class _InlineDecoration {
  final UDTNode node;
  final List<Rect> rects;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;

  _InlineDecoration({
    required this.node,
    required this.rects,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.borderRadius,
  });
}

/// Block decoration info for painting border-left, background on block elements
class _BlockDecoration {
  final UDTNode node;
  final Rect rect;
  final Color? backgroundColor;
  final Color? borderLeftColor;
  final double borderLeftWidth;
  final BorderRadius? borderRadius;

  _BlockDecoration({
    required this.node,
    required this.rect,
    this.backgroundColor,
    this.borderLeftColor,
    this.borderLeftWidth = 0,
    this.borderRadius,
  });
}


/// LRU Cache for TextPainter to prevent memory leak
///
/// Uses LinkedHashMap with access-order to automatically track LRU entries.
/// When capacity is exceeded, the least recently used entry is evicted.
class _LruCache<K, V> {
  final int _maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();
  final void Function(V)? _onEvict;

  _LruCache({required int maxSize, void Function(V)? onEvict})
      : _maxSize = maxSize,
        _onEvict = onEvict;

  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      // Re-insert to move to end (most recently used)
      _cache[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    // Remove existing to update access order
    final existing = _cache.remove(key);
    if (existing != null) {
      _onEvict?.call(existing);
    }

    // Evict if at capacity
    while (_cache.length >= _maxSize) {
      final eldest = _cache.keys.first;
      final evicted = _cache.remove(eldest);
      if (evicted != null) {
        _onEvict?.call(evicted);
      }
    }

    _cache[key] = value;
  }

  bool containsKey(K key) => _cache.containsKey(key);

  void clear() {
    final onEvict = _onEvict;
    if (onEvict != null) {
      for (final value in _cache.values) {
        onEvict(value);
      }
    }
    _cache.clear();
  }

  int get length => _cache.length;

  Iterable<V> get values => _cache.values;
}

/// Selection range for text
class HyperTextSelection {
  final int start;
  final int end;

  const HyperTextSelection({required this.start, required this.end});

  bool get isCollapsed => start == end;
  bool get isValid => start >= 0 && end >= start;

  HyperTextSelection copyWith({int? start, int? end}) {
    return HyperTextSelection(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}

/// RenderHyperBox - The core custom rendering engine
///
/// This RenderObject implements:
/// - Fragment-based inline layout (IFC - Inline Formatting Context)
/// - Float layout (CSS float: left/right)
/// - Margin collapsing
/// - CJK line-breaking (Kinsoku)
/// - Text selection support
/// - Inline background/border for wrapped text
/// - Async image loading
///
/// Reference: doc1.txt - "Quy trình 4 bước của thuật toán"
/// Reference: doc3.md - "RenderObject-centric Architecture"
class RenderHyperBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, HyperBoxParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, HyperBoxParentData> {
  /// The document tree to render
  DocumentNode? _document;

  /// Base text style
  TextStyle _baseStyle;

  /// Link tap callback
  HyperLinkTapCallback? _onLinkTap;

  /// Custom image loader (defaults to defaultImageLoader if not provided)
  HyperImageLoader? _imageLoader;

  /// Whether text selection is enabled
  bool _selectable;

  /// Max width constraint (for line wrapping)
  double _maxWidth = double.infinity;

  /// Cached fragments after tokenization
  List<Fragment> _fragments = [];

  /// Cached lines after layout
  final List<LineInfo> _lines = [];

  /// Active float areas
  final List<_FloatArea> _leftFloats = [];
  final List<_FloatArea> _rightFloats = [];

  /// Text painters cache (for measuring and painting text)
  /// Uses LRU cache with max 5000 entries for large documents (e.g., novel reading apps)
  /// The LRU eviction ensures memory stays bounded while keeping frequently used painters
  /// Larger cache = better performance for stress tests with 500+ pages
  /// 5000 entries ≈ ~20MB memory for typical text styles
  late final _LruCache<int, TextPainter> _textPainters = _LruCache(
    maxSize: 5000,
    onEvict: (painter) => painter.dispose(),
  );

  /// Gesture recognizers for links
  final Map<String, TapGestureRecognizer> _linkRecognizers = {};

  /// Last collapsed margin (for margin collapsing between blocks)
  double _lastBlockMarginBottom = 0;

  /// Inline decorations for painting backgrounds/borders
  final List<_InlineDecoration> _inlineDecorations = [];

  /// Block decorations for painting border-left, backgrounds
  final List<_BlockDecoration> _blockDecorations = [];

  /// Image cache
  final Map<String, CachedImage> _imageCache = {};

  /// Current text selection
  HyperTextSelection? _selection;

  /// Selection start position (for drag selection)
  int? _selectionStartPosition;

  /// Total character count in document
  int _totalCharacterCount = 0;

  /// Cached intrinsic widths (invalidated on layout change)
  double? _cachedMinIntrinsicWidth;
  double? _cachedMaxIntrinsicWidth;

  /// Character offset to fragment mapping
  final Map<int, Fragment> _characterToFragment = {};

  /// Callback when selection changes
  VoidCallback? onSelectionChanged;

  RenderHyperBox({
    DocumentNode? document,
    TextStyle baseStyle =
        const TextStyle(fontSize: 16, color: Color(0xFF000000)),
    HyperLinkTapCallback? onLinkTap,
    HyperImageLoader? imageLoader,
    bool selectable = true,
    this.onSelectionChanged,
  })  : _document = document,
        _baseStyle = baseStyle,
        _onLinkTap = onLinkTap,
        _imageLoader = imageLoader,
        _selectable = selectable;

  // ============================================
  // Properties
  // ============================================

  DocumentNode? get document => _document;
  set document(DocumentNode? value) {
    if (_document == value) return;
    _document = value;
    _invalidateLayout();
    markNeedsLayout();
  }

  TextStyle get baseStyle => _baseStyle;
  set baseStyle(TextStyle value) {
    if (_baseStyle == value) return;
    _baseStyle = value;
    _invalidateLayout();
    markNeedsLayout();
  }

  HyperLinkTapCallback? get onLinkTap => _onLinkTap;
  set onLinkTap(HyperLinkTapCallback? value) {
    _onLinkTap = value;
  }

  bool get selectable => _selectable;
  set selectable(bool value) {
    if (_selectable == value) return;
    _selectable = value;
    if (!value) {
      _selection = null;
    }
    markNeedsPaint();
  }

  HyperImageLoader? get imageLoader => _imageLoader;
  set imageLoader(HyperImageLoader? value) {
    if (_imageLoader == value) return;
    _imageLoader = value;
    // Clear image cache and reload with new loader
    _imageCache.clear();
    if (attached) {
      _loadImages();
    }
  }

  HyperTextSelection? get selection => _selection;
  set selection(HyperTextSelection? value) {
    if (_selection == value) return;
    _selection = value;
    markNeedsPaint();
    onSelectionChanged?.call();
  }

  /// Notify selection changed (call after modifying _selection directly)
  void _notifySelectionChanged() {
    onSelectionChanged?.call();
  }

  // ============================================
  // RenderBox Setup
  // ============================================

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! HyperBoxParentData) {
      child.parentData = HyperBoxParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    // Load images when attached
    _loadImages();
  }

  @override
  void dispose() {
    _disposeTextPainters();
    _disposeLinkRecognizers();
    _disposeImages();
    super.dispose();
  }

  void _disposeTextPainters() {
    // LRU cache will call dispose on each painter via onEvict callback
    _textPainters.clear();
  }

  void _disposeLinkRecognizers() {
    for (final recognizer in _linkRecognizers.values) {
      recognizer.dispose();
    }
    _linkRecognizers.clear();
  }

  void _disposeImages() {
    _imageCache.clear();
  }

  void _invalidateLayout() {
    _fragments.clear();
    _lines.clear();
    _leftFloats.clear();
    _rightFloats.clear();
    _inlineDecorations.clear();
    _blockDecorations.clear();
    _characterToFragment.clear();
    _fragmentRanges.clear();
    _totalCharacterCount = 0;
    _cachedMinIntrinsicWidth = null;
    _cachedMaxIntrinsicWidth = null;
    _disposeTextPainters();
  }

  // ============================================
  // Image Loading
  // ============================================

  void _loadImages() {
    if (_document == null) return;

    _document!.traverse((node) {
      if (node is AtomicNode && node.tagName == 'img') {
        final src = node.src;
        if (src != null && src.isNotEmpty && !_imageCache.containsKey(src)) {
          _loadImage(src);
        }
      }
    });
  }

  void _loadImage(String src) {
    _imageCache[src] = const CachedImage(state: ImageLoadState.loading);

    // Use the provided loader or fall back to default
    final loader = _imageLoader ?? defaultImageLoader;

    loader(
      src,
      (ui.Image image) {
        // On successful load
        if (!attached) return;
        _imageCache[src] = CachedImage(
          image: image,
          state: ImageLoadState.loaded,
        );
        markNeedsLayout();
        markNeedsPaint();
      },
      (Object error) {
        // On error
        if (!attached) return;
        _imageCache[src] = CachedImage(
          state: ImageLoadState.error,
          error: error.toString(),
        );
        markNeedsPaint();
      },
    );
  }

  // ============================================
  // Intrinsic Dimensions
  // ============================================

  @override
  double computeMinIntrinsicWidth(double height) {
    if (_document == null) return 0;

    // Use cached value if available
    if (_cachedMinIntrinsicWidth != null) {
      return _cachedMinIntrinsicWidth!;
    }

    _ensureFragments();
    // This is expensive but correct. It finds the longest unbreakable word.
    double maxWidth = 0;

    for (final fragment in _fragments) {
      if (fragment.type == FragmentType.text && fragment.text != null) {
        final text = fragment.text!;
        final words = text.split(RegExp(r'\s+'));
        for (final word in words) {
          if (word.isEmpty) continue;
          final painter = _getTextPainter(word, fragment.style);
          if (painter.width > maxWidth) {
            maxWidth = painter.width;
          }
        }
      } else if (fragment.type == FragmentType.atomic || fragment.type == FragmentType.ruby) {
        // Ensure fragment is measured if it hasn't been already
        if (fragment.measuredSize == null) _measureFragment(fragment);
        if (fragment.width > maxWidth) {
          maxWidth = fragment.width;
        }
      }
    }

    _cachedMinIntrinsicWidth = maxWidth;
    return maxWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (_document == null) return 0;

    // Use cached value if available
    if (_cachedMaxIntrinsicWidth != null) {
      return _cachedMaxIntrinsicWidth!;
    }

    _ensureFragments();
    _measureFragments(); // Ensures all fragments have a measured size.

    double totalWidth = 0;
    for (final fragment in _fragments) {
      // Sum up widths of inline-level elements that would form a single long line.
      if (fragment.type == FragmentType.text ||
          fragment.type == FragmentType.atomic ||
          fragment.type == FragmentType.ruby) {
        totalWidth += fragment.width;
      }
    }

    _cachedMaxIntrinsicWidth = totalWidth;
    return totalWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _computeHeightForWidth(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _computeHeightForWidth(width);
  }

  double _computeHeightForWidth(double width) {
    if (_document == null) return 0;

    _maxWidth = width;
    _ensureFragments();
    _performLineLayout();

    if (_lines.isEmpty) return 0;

    final lastLine = _lines.last;
    return lastLine.top + lastLine.height;
  }

  // ============================================
  // Layout
  // ============================================

  @override
  void performLayout() {
    if (_document == null) {
      size = constraints.smallest;
      return;
    }

    _maxWidth = constraints.maxWidth;

    // Step 1: Tokenization - Break UDT into Fragments
    _ensureFragments();

    // Step 1.5: Link children to fragments (CRITICAL - must be done right after fragments are created)
    // This uses order-based matching since fragments and children are created in same traversal order
    _linkFragmentsToChildrenByOrder();

    // Step 2: Measure all fragments
    _measureFragments();

    // Step 3: Line Breaking with Float Support
    _performLineLayout();

    // Step 4: Position fragments within lines (baseline alignment)
    _positionFragments();

    // Step 5: Build inline decorations
    _buildInlineDecorations();

    // Step 6: Build character mapping for selection
    _buildCharacterMapping();

    // Step 7: Layout child RenderBoxes (for atomic elements)
    _layoutChildren();

    // Calculate final size
    double height = 0;
    if (_lines.isNotEmpty) {
      final lastLine = _lines.last;
      height = lastLine.top + lastLine.height;
    }

    for (final float in [..._leftFloats, ..._rightFloats]) {
      if (float.rect.bottom > height) {
        height = float.rect.bottom;
      }
    }

    size = constraints.constrain(Size(_maxWidth, height));
  }

  /// Step 1: Tokenization - Convert UDT tree to flat list of Fragments
  void _ensureFragments() {
    if (_fragments.isNotEmpty) return;
    if (_document == null) return;

    _fragments = [];
    _lastBlockMarginBottom = 0;
    _tokenizeNode(_document!, null);
  }

  void _tokenizeNode(UDTNode node, UDTNode? parentBlock) {
    switch (node.type) {
      case NodeType.document:
        for (final child in node.children) {
          _tokenizeNode(child, null);
        }
        break;

      case NodeType.block:
        _tokenizeBlock(node, parentBlock);
        break;

      case NodeType.inline:
        _tokenizeInline(node);
        break;

      case NodeType.text:
        _tokenizeText(node as TextNode);
        break;

      case NodeType.atomic:
        _tokenizeAtomic(node as AtomicNode);
        break;

      case NodeType.lineBreak:
        _fragments.add(Fragment.lineBreak(
          sourceNode: node,
          style: node.style,
        ));
        break;

      case NodeType.ruby:
        _tokenizeRuby(node as RubyNode);
        break;

      case NodeType.table:
        _tokenizeTable(node as TableNode);
        break;

      default:
        for (final child in node.children) {
          _tokenizeNode(child, parentBlock);
        }
    }
  }

  /// Track list item indices for ordered lists
  final Map<UDTNode, int> _listItemIndices = {};

  void _tokenizeBlock(UDTNode node, UDTNode? parentBlock) {
    final style = node.style;
    final tagName = node.tagName?.toLowerCase();

    // Handle margin collapsing
    final marginTop = style.margin.top;
    final collapsedMargin = math.max(marginTop, _lastBlockMarginBottom);
    final effectiveMarginTop = collapsedMargin - _lastBlockMarginBottom;

    if (effectiveMarginTop > 0 || _fragments.isNotEmpty) {
      _fragments.add(_BlockStartFragment(
        sourceNode: node,
        style: style,
        marginTop: effectiveMarginTop,
        paddingTop: style.padding.top,
        paddingLeft: style.padding.left,
        paddingRight: style.padding.right,
      ));
    }

    // Add list marker for <li> elements
    if (tagName == 'li' && parentBlock != null) {
      final parentTag = parentBlock.tagName?.toLowerCase();
      final isOrdered = parentTag == 'ol';

      // Get or calculate list item index
      int index = 1;
      if (isOrdered) {
        // Count previous li siblings
        index = (_listItemIndices[parentBlock] ?? 0) + 1;
        _listItemIndices[parentBlock] = index;
      }

      // Get list-style-type from parent list (ul/ol)
      final listStyleType = parentBlock.style.listStyleType;

      // Generate marker text based on list-style-type
      final marker = _generateListMarker(listStyleType, index, isOrdered);

      _fragments.add(_ListMarkerFragment(
        sourceNode: node,
        style: style,
        marker: marker,
        isOrdered: isOrdered,
        index: index,
      ));
    }

    if (style.float != HyperFloat.none) {
      _fragments.add(_FloatFragment(
        sourceNode: node,
        style: style,
        floatDirection: style.float,
      ));
    }

    // Code blocks (<pre>) are rendered as child widgets with syntax highlighting
    // Create a placeholder fragment instead of tokenizing the content
    if (tagName == 'pre') {
      _fragments.add(_CodeBlockFragment(
        sourceNode: node,
        style: style,
      ));
      // Skip tokenizing children - they're handled by CodeBlockWidget
    } else {
      for (final child in node.children) {
        _tokenizeNode(child, node);
      }
    }

    _fragments.add(_BlockEndFragment(
      sourceNode: node,
      style: style,
      marginBottom: style.margin.bottom,
      paddingBottom: style.padding.bottom,
    ));

    _lastBlockMarginBottom = style.margin.bottom;
  }

  void _tokenizeInline(UDTNode node) {
    // Add inline start marker for decoration tracking
    final hasDecoration = node.style.backgroundColor != null ||
        node.style.borderColor != null;

    if (hasDecoration) {
      _fragments.add(_InlineStartFragment(
        sourceNode: node,
        style: node.style,
      ));
    }

    for (final child in node.children) {
      _tokenizeNode(child, null);
    }

    if (hasDecoration) {
      _fragments.add(_InlineEndFragment(
        sourceNode: node,
        style: node.style,
      ));
    }
  }

  void _tokenizeText(TextNode node) {
    final text = node.text;
    if (text.isEmpty) return;

    final normalizedText = _normalizeWhitespace(text, node.style.whiteSpace);
    if (normalizedText.isEmpty) return;

    // SMART CHUNK MERGING STRATEGY:
    // Only merge SMALL fragments that don't contain spaces
    // This preserves word boundaries for proper line breaking
    // while still reducing fragmentation for things like "Hello" + "World" -> "HelloWorld"
    if (_fragments.isNotEmpty && !normalizedText.contains(' ')) {
      final lastFragment = _fragments.last;
      if (lastFragment.type == FragmentType.text &&
          lastFragment.text != null &&
          !lastFragment.text!.contains(' ') &&
          lastFragment.text!.length < 20 && // Don't merge long chunks
          normalizedText.length < 20 &&
          _canMergeStyles(lastFragment.style, node.style) &&
          lastFragment.sourceNode.parent == node.parent) {
        // Merge small non-space fragments
        final mergedText = lastFragment.text! + normalizedText;
        _fragments.removeLast();
        _fragments.add(Fragment.text(
          text: mergedText,
          sourceNode: lastFragment.sourceNode,
          style: lastFragment.style,
          characterOffset: lastFragment.characterOffset,
        ));
        return;
      }
    }

    _fragments.add(Fragment.text(
      text: normalizedText,
      sourceNode: node,
      style: node.style,
    ));
  }

  /// Check if two styles can be merged (same visual appearance)
  bool _canMergeStyles(ComputedStyle a, ComputedStyle b) {
    return a.fontSize == b.fontSize &&
        a.fontWeight == b.fontWeight &&
        a.fontStyle == b.fontStyle &&
        a.color == b.color &&
        a.fontFamily == b.fontFamily &&
        a.backgroundColor == b.backgroundColor &&
        a.textDecoration == b.textDecoration &&
        a.letterSpacing == b.letterSpacing;
  }

  String _normalizeWhitespace(String text, String? whiteSpace) {
    // Handle all CSS white-space property values
    // Reference: https://developer.mozilla.org/en-US/docs/Web/CSS/white-space
    switch (whiteSpace) {
      case 'pre':
      case 'pre-wrap':
      case 'break-spaces':
        // Preserve all whitespace (spaces, tabs, newlines)
        return text;

      case 'pre-line':
        // Collapse spaces and tabs, but preserve newlines
        return text.split('\n').map((line) {
          // Collapse consecutive spaces/tabs within each line
          return line.replaceAll(RegExp(r'[ \t]+'), ' ');
        }).join('\n');

      case 'nowrap':
      case 'normal':
      default:
        // Collapse all whitespace (spaces, tabs, newlines) into single spaces
        return text.replaceAll(RegExp(r'\s+'), ' ');
    }
  }

  /// Generate list marker text based on list-style-type and index
  String _generateListMarker(ListStyleType? listStyleType, int index, bool isOrdered) {
    final type = listStyleType ?? (isOrdered ? ListStyleType.decimal : ListStyleType.disc);

    switch (type) {
      case ListStyleType.decimal:
        return '$index. ';

      case ListStyleType.lowerRoman:
        return '${_toRomanNumeral(index).toLowerCase()}. ';

      case ListStyleType.upperRoman:
        return '${_toRomanNumeral(index)}. ';

      case ListStyleType.lowerAlpha:
        return '${_toAlphaNumeral(index).toLowerCase()}. ';

      case ListStyleType.upperAlpha:
        return '${_toAlphaNumeral(index)}. ';

      case ListStyleType.disc:
        return '• '; // Filled circle (default for ul)

      case ListStyleType.circle:
        return '○ '; // Hollow circle

      case ListStyleType.square:
        return '▪ '; // Filled square

      case ListStyleType.none:
        return '';
    }
  }

  /// Convert number to roman numerals (I, II, III, IV, V, etc.)
  String _toRomanNumeral(int num) {
    if (num <= 0 || num > 3999) return '$num'; // Fallback for out of range

    const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    const numerals = ['M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];

    String result = '';
    int remaining = num;

    for (int i = 0; i < values.length; i++) {
      while (remaining >= values[i]) {
        result += numerals[i];
        remaining -= values[i];
      }
    }

    return result;
  }

  /// Convert number to alphabetical numeral (A, B, C, ..., Z, AA, AB, etc.)
  String _toAlphaNumeral(int num) {
    if (num <= 0) return 'A'; // Fallback

    String result = '';
    int n = num;

    while (n > 0) {
      n--; // Adjust for 0-based indexing
      result = String.fromCharCode(65 + (n % 26)) + result;
      n ~/= 26;
    }

    return result;
  }

  /// Default placeholder size for images without dimensions
  static const double _defaultImageWidth = 200.0;
  // Note: default height is computed from width / aspect ratio
  static const double _defaultAspectRatio = 16.0 / 9.0;

  void _tokenizeAtomic(AtomicNode node) {
    double width;
    double height;

    if (node.tagName == 'img' && node.src != null) {
      final cached = _imageCache[node.src];

      if (cached?.state == ImageLoadState.loaded && cached?.image != null) {
        // Image loaded - use actual dimensions
        final image = cached!.image!;
        final imageWidth = image.width.toDouble();
        final imageHeight = image.height.toDouble();

        if (node.intrinsicWidth != null && node.intrinsicHeight != null) {
          // Both dimensions specified - use them
          width = node.intrinsicWidth!;
          height = node.intrinsicHeight!;
        } else if (node.intrinsicWidth != null) {
          // Only width specified - maintain aspect ratio
          width = node.intrinsicWidth!;
          height = width * (imageHeight / imageWidth);
        } else if (node.intrinsicHeight != null) {
          // Only height specified - maintain aspect ratio
          height = node.intrinsicHeight!;
          width = height * (imageWidth / imageHeight);
        } else {
          // No dimensions - use actual image size, constrained to maxWidth
          width = math.min(imageWidth, _maxWidth - 32); // Leave some margin
          height = width * (imageHeight / imageWidth);
        }
      } else {
        // Image not loaded yet - use specified dimensions or smart placeholder
        if (node.intrinsicWidth != null && node.intrinsicHeight != null) {
          width = node.intrinsicWidth!;
          height = node.intrinsicHeight!;
        } else if (node.intrinsicWidth != null) {
          width = node.intrinsicWidth!;
          height = width / _defaultAspectRatio;
        } else if (node.intrinsicHeight != null) {
          height = node.intrinsicHeight!;
          width = height * _defaultAspectRatio;
        } else {
          // No dimensions specified - use responsive placeholder
          // Width fills available space (with margin), height maintains 16:9 ratio
          width = math.min(_defaultImageWidth, _maxWidth - 32);
          height = width / _defaultAspectRatio;
        }
      }
    } else {
      // Non-image atomic element
      width = node.intrinsicWidth ?? defaultFloatSize;
      height = node.intrinsicHeight ?? defaultFloatSize;
    }

    // Check if this atomic element should float
    if (node.style.float != HyperFloat.none) {
      // Create float fragment instead of regular atomic fragment
      _fragments.add(_FloatFragment(
        sourceNode: node,
        style: node.style,
        floatDirection: node.style.float,
      ));
    } else {
      // Regular non-floating atomic element
      _fragments.add(Fragment.atomic(
        sourceNode: node,
        style: node.style,
        size: Size(width, height),
      ));
    }
  }

  void _tokenizeRuby(RubyNode node) {
    _fragments.add(Fragment.ruby(
      baseText: node.baseText,
      rubyText: node.rubyText,
      sourceNode: node,
      style: node.style,
    ));
  }

  void _tokenizeTable(TableNode node) {
    _fragments.add(_TableFragment(
      sourceNode: node,
      style: node.style,
    ));
  }

  /// Step 2: Measure all fragments
  void _measureFragments() {
    for (final fragment in _fragments) {
      if (fragment.measuredSize != null) continue;

      switch (fragment.type) {
        case FragmentType.text:
          final painter = _getTextPainter(fragment.text!, fragment.style);
          fragment.measuredSize = Size(painter.width, painter.height);
          break;

        case FragmentType.ruby:
          _measureRubyFragment(fragment);
          break;

        case FragmentType.lineBreak:
          final painter = _getTextPainter(' ', fragment.style);
          fragment.measuredSize = Size(0, painter.height);
          break;

        case FragmentType.atomic:
          // Already measured during tokenization
          break;
      }

      if (fragment is _BlockStartFragment ||
          fragment is _BlockEndFragment ||
          fragment is _FloatFragment ||
          fragment is _TableFragment ||
          fragment is _CodeBlockFragment ||
          fragment is _InlineStartFragment ||
          fragment is _InlineEndFragment) {
        fragment.measuredSize = Size.zero;
      }
    }
  }

  /// Ruby annotation size ratio (furigana is typically 50% of base text)
  static const double rubyFontSizeRatio = 0.5;

  /// Gap between ruby text and base text
  static const double rubyGap = 2.0;

  void _measureRubyFragment(Fragment fragment) {
    final baseStyle = fragment.style;
    // Ruby text is smaller than base text
    final rubyFontSize = baseStyle.fontSize * rubyFontSizeRatio;
    final rubyStyle = baseStyle.copyWith(fontSize: rubyFontSize);

    final basePainter = _getTextPainter(fragment.text!, baseStyle);
    final rubyPainter = _getTextPainter(fragment.rubyText!, rubyStyle);

    // Width is the maximum of base and ruby text
    final width = math.max(basePainter.width, rubyPainter.width);
    // Height includes base text + gap + ruby text
    final height = basePainter.height + rubyGap + rubyPainter.height;

    fragment.measuredSize = Size(width, height);
    // Store ruby height for painting
    fragment.rubyHeight = rubyPainter.height;
  }

  TextPainter _getTextPainter(String text, ComputedStyle style) {
    // Use a more robust cache key combining text and style properties
    final styleKey = style.fontSize.hashCode ^
        style.fontWeight.hashCode ^
        style.fontStyle.hashCode ^
        style.color.hashCode ^
        (style.fontFamily?.hashCode ?? 0) ^
        (style.lineHeight?.hashCode ?? 0) ^
        (style.letterSpacing?.hashCode ?? 0);
    final key = text.hashCode ^ styleKey;

    final cached = _textPainters.get(key);
    if (cached != null) {
      return cached;
    }

    // FIXED: baseStyle is the foundation, computed style overrides it
    final mergedStyle = _baseStyle.merge(style.toTextStyle());

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: mergedStyle,
      ),
      strutStyle: StrutStyle.fromTextStyle(mergedStyle, forceStrutHeight: true),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    _textPainters.put(key, painter);
    return painter;
  }

  /// Step 3: Line Breaking with Float Support
  ///
  /// PERFORMANCE OPTIMIZATION: Uses queue-based processing instead of List.insert()
  /// to avoid O(n²) complexity when splitting text fragments. The pendingFragments
  /// queue holds fragments that need to be processed next, eliminating costly
  /// list insertions in the middle of the fragments list.
  void _performLineLayout() {
    _lines.clear();
    _leftFloats.clear();
    _rightFloats.clear();

    if (_fragments.isEmpty) return;

    double currentY = 0;
    double currentX = 0;
    double lineHeight = 0;
    double maxBaseline = 0;
    List<Fragment> currentLineFragments = [];
    double leftInset = 0;
    double rightInset = 0;

    // Stack to track nested block indentation
    final List<double> leftPaddingStack = [0];
    final List<double> rightPaddingStack = [0];

    // Track active blocks for decoration (border-left, background)
    // Tuple: (fragment, startY, leftX, rightX)
    final List<(_BlockStartFragment, double, double, double)> activeBlocks = [];

    // PERFORMANCE: Queue for pending fragments from splits - avoids O(n²) List.insert()
    // When we split a fragment, the second part goes here instead of being inserted
    // into _fragments list. This is O(1) instead of O(n).
    Fragment? pendingFragment;

    void finishLine() {
      if (currentLineFragments.isEmpty) return;

      while (currentLineFragments.isNotEmpty &&
          currentLineFragments.last.isWhitespace) {
        currentLineFragments.removeLast();
      }

      if (currentLineFragments.isEmpty) return;

      final lineInfo = LineInfo(
        top: currentY,
        baseline: maxBaseline,
        leftInset: leftInset,
        rightInset: rightInset,
      );
      for (final frag in currentLineFragments) {
        lineInfo.add(frag);
      }
      // Set bounds after adding fragments
      lineInfo.bounds = Rect.fromLTWH(leftInset, currentY, lineInfo.width, lineHeight);
      _lines.add(lineInfo);

      currentY += lineHeight;
      currentLineFragments.clear();
      lineHeight = 0;
      maxBaseline = 0;
    }

    double getAvailableWidth() {
      // Start with accumulated block padding
      double floatLeftInset = leftPaddingStack.last;
      double floatRightInset = rightPaddingStack.last;

      // Add float insets
      for (final float in _leftFloats) {
        if (currentY >= float.rect.top && currentY < float.rect.bottom) {
          floatLeftInset = math.max(floatLeftInset, float.rect.right);
        }
      }

      for (final float in _rightFloats) {
        if (currentY >= float.rect.top && currentY < float.rect.bottom) {
          floatRightInset = math.max(floatRightInset, _maxWidth - float.rect.left);
        }
      }

      leftInset = floatLeftInset;
      rightInset = floatRightInset;

      return _maxWidth - leftInset - rightInset;
    }

    // Process a single fragment - extracted for reuse with pending fragments
    void processFragment(Fragment fragment) {
      if (fragment is _BlockStartFragment) {
        finishLine();
        currentY += fragment.marginTop + fragment.paddingTop;

        // ACCUMULATE padding for nested blocks
        final newLeftPadding = leftPaddingStack.last + fragment.paddingLeft;
        final newRightPadding = rightPaddingStack.last + fragment.paddingRight;
        leftPaddingStack.add(newLeftPadding);
        rightPaddingStack.add(newRightPadding);

        leftInset = newLeftPadding;
        rightInset = newRightPadding;
        currentX = leftInset;

        // Track this block for decoration (background, border-left, border-radius)
        final style = fragment.style;
        final hasBackground = style.backgroundColor != null;
        final hasBorderLeft = style.borderColor != null && style.borderWidth.left > 0;
        if (hasBackground || hasBorderLeft) {
          // Calculate the edge positions (account for parent padding but not this block's)
          final blockLeftX = leftPaddingStack.length > 1
              ? leftPaddingStack[leftPaddingStack.length - 2]
              : 0.0;
          final blockRightX = rightPaddingStack.length > 1
              ? _maxWidth - rightPaddingStack[rightPaddingStack.length - 2]
              : _maxWidth;
          // startY is BEFORE padding (current position includes padding, so subtract it)
          final blockStartY = currentY - fragment.paddingTop;
          activeBlocks.add((fragment, blockStartY, blockLeftX, blockRightX));
        }
        return;
      }

      // Handle list markers - render them in the margin area
      if (fragment is _ListMarkerFragment) {
        final painter = _getTextPainter(fragment.marker, fragment.style);
        fragment.measuredSize = Size(painter.width, painter.height);
        // Position marker in the left margin (before the content)
        fragment.offset = Offset(leftInset - painter.width - 4, currentY);
        return;
      }

      if (fragment is _BlockEndFragment) {
        finishLine();
        currentY += fragment.paddingBottom;

        // Check if this block has a decoration pending
        if (activeBlocks.isNotEmpty) {
          final (startFragment, startY, blockLeftX, blockRightX) = activeBlocks.last;
          if (startFragment.sourceNode == fragment.sourceNode) {
            activeBlocks.removeLast();
            // Create block decoration
            final style = fragment.style;
            _blockDecorations.add(_BlockDecoration(
              node: fragment.sourceNode,
              rect: Rect.fromLTRB(blockLeftX, startY, blockRightX, currentY),
              backgroundColor: style.backgroundColor,
              borderLeftColor: style.borderColor,
              borderLeftWidth: style.borderWidth.left,
              borderRadius: style.borderRadius,
            ));
          }
        }

        // Pop the padding stack
        if (leftPaddingStack.length > 1) leftPaddingStack.removeLast();
        if (rightPaddingStack.length > 1) rightPaddingStack.removeLast();

        leftInset = leftPaddingStack.last;
        rightInset = rightPaddingStack.last;
        currentX = leftInset;
        return;
      }

      if (fragment is _FloatFragment) {
        _layoutFloat(fragment, currentY);
        return;
      }

      if (fragment is _TableFragment) {
        finishLine();
        // Find the child RenderBox for this table and measure it
        RenderBox? tableChild = _findChildForFragment(fragment);
        double tableHeight = 200.0; // Default fallback
        double tableWidth = _maxWidth;

        if (tableChild != null) {
          // Layout the table to get its actual size
          tableChild.layout(
            BoxConstraints(maxWidth: _maxWidth),
            parentUsesSize: true,
          );
          tableHeight = tableChild.size.height;
          tableWidth = tableChild.size.width;
        }

        fragment.measuredSize = Size(tableWidth, tableHeight);
        fragment.offset = Offset(leftInset, currentY);
        currentY += tableHeight + 16; // Add margin after table
        return;
      }

      // Handle code blocks - rendered as child widgets with syntax highlighting
      if (fragment is _CodeBlockFragment) {
        finishLine();
        // Find the child RenderBox for this code block
        RenderBox? codeBlockChild = _findChildForFragment(fragment);
        double blockHeight = 100.0; // Default fallback
        double blockWidth = _maxWidth;

        if (codeBlockChild != null) {
          // Layout the code block to get its actual size
          codeBlockChild.layout(
            BoxConstraints(maxWidth: _maxWidth),
            parentUsesSize: true,
          );
          blockHeight = codeBlockChild.size.height;
          blockWidth = codeBlockChild.size.width;
        }

        fragment.measuredSize = Size(blockWidth, blockHeight);
        fragment.offset = Offset(leftInset, currentY);
        currentY += blockHeight + 8; // Add small margin after code block
        return;
      }

      // Skip inline markers
      if (fragment is _InlineStartFragment ||
          fragment is _InlineEndFragment) {
        return;
      }

      if (fragment.type == FragmentType.lineBreak) {
        finishLine();
        currentX = leftInset;
        return;
      }

      final availableWidth = getAvailableWidth();
      final remainingWidth = leftInset + availableWidth - currentX;

      // Check if fragment fits in remaining space
      if (fragment.width > remainingWidth) {
        if (fragment.type == FragmentType.text && fragment.text != null) {
          // Check if wrapping is allowed based on white-space property
          final whiteSpace = fragment.style.whiteSpace;
          final allowWrap = (whiteSpace != 'nowrap' && whiteSpace != 'pre');

          // Try to split text fragment (only if wrapping is allowed)
          if (allowWrap && currentLineFragments.isNotEmpty && remainingWidth > 20) {
            // Try to fit part of text on current line
            final splitResult = _splitTextFragment(fragment, remainingWidth);
            if (splitResult != null) {
              final (firstPart, secondPart) = splitResult;
              currentLineFragments.add(firstPart);
              _updateLineMetrics(firstPart, lineHeight, maxBaseline, (h, b) {
                lineHeight = h;
                maxBaseline = b;
              });
              finishLine();
              currentX = leftInset;
              // PERFORMANCE: Queue secondPart instead of inserting into list
              pendingFragment = secondPart;
              return;
            }
          }

          // Can't split to fit - start new line
          if (currentLineFragments.isNotEmpty) {
            finishLine();
            currentX = leftInset;
          }

          // Now check if fragment is wider than full line width
          final fullLineWidth = getAvailableWidth();
          if (fragment.width > fullLineWidth && fragment.text!.length > 1) {
            // Check if wrapping is allowed for force-split too
            final whiteSpace = fragment.style.whiteSpace;
            final allowWrap = (whiteSpace != 'nowrap' && whiteSpace != 'pre');

            if (allowWrap) {
              // Fragment is wider than entire line - FORCE split
              final forceSplit = _forceSplitTextFragment(fragment, fullLineWidth);
              if (forceSplit != null) {
                final (firstPart, secondPart) = forceSplit;
                currentLineFragments.add(firstPart);
                _updateLineMetrics(firstPart, lineHeight, maxBaseline, (h, b) {
                  lineHeight = h;
                  maxBaseline = b;
                });
                finishLine();
                currentX = leftInset;
                // PERFORMANCE: Queue secondPart instead of inserting into list
                pendingFragment = secondPart;
                return;
              }
            }
            // If nowrap/pre, let the text overflow (don't split)
          }
        } else {
          // Non-text fragment - just start new line if needed
          if (currentLineFragments.isNotEmpty) {
            finishLine();
            currentX = leftInset;
            getAvailableWidth();
          }
        }
      }

      fragment.offset = Offset(currentX, currentY);
      currentX += fragment.width;
      currentLineFragments.add(fragment);

      _updateLineMetrics(fragment, lineHeight, maxBaseline, (h, b) {
        lineHeight = h;
        maxBaseline = b;
      });
    }

    // Main loop with pending fragment support
    for (int i = 0; i < _fragments.length; i++) {
      // Process pending fragment first (from previous split)
      while (pendingFragment != null) {
        final frag = pendingFragment!;
        pendingFragment = null;
        processFragment(frag);
      }

      processFragment(_fragments[i]);
    }

    // Process any remaining pending fragment
    while (pendingFragment != null) {
      final frag = pendingFragment!;
      pendingFragment = null;
      processFragment(frag);
    }

    finishLine();
  }

  void _updateLineMetrics(
    Fragment fragment,
    double currentHeight,
    double currentBaseline,
    void Function(double, double) update,
  ) {
    double newHeight = currentHeight;
    double newBaseline = currentBaseline;

    if (fragment.height > newHeight) {
      newHeight = fragment.height;
    }

    // Calculate baseline using font metrics when available
    double baseline;
    if (fragment.type == FragmentType.text && fragment.text != null) {
      final painter = _getTextPainter(fragment.text!, fragment.style);
      // Use actual font baseline from TextPainter metrics
      baseline = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    } else if (fragment.type == FragmentType.ruby) {
      // Ruby has base text at bottom, so baseline is near bottom
      baseline = fragment.height * 0.85;
    } else {
      // For atomic/other elements, use bottom alignment
      baseline = fragment.height;
    }

    if (baseline > newBaseline) {
      newBaseline = baseline;
    }

    update(newHeight, newBaseline);
  }

  /// Check if a break position is within a CJK context (surrounded by CJK characters)
  /// This helps properly handle mixed CJK+Latin text by applying appropriate rules
  bool _isBreakInCjkContext(String text, int position) {
    if (position <= 0 || position >= text.length) return false;

    // Check character before and after break position
    final charBefore = text[position - 1];
    final charAfter = text[position];

    // If either side is CJK, consider it CJK context
    // This allows Kinsoku rules to apply at CJK/Latin boundaries
    final isBeforeCjk = KinsokuProcessor.isCjkCharacter(charBefore);
    final isAfterCjk = KinsokuProcessor.isCjkCharacter(charAfter);

    return isBeforeCjk || isAfterCjk;
  }

  (Fragment, Fragment)? _splitTextFragment(Fragment fragment, double maxWidth) {
    final text = fragment.text!;
    if (text.isEmpty) return null;

    final painter = _getTextPainter(text, fragment.style);
    final position = painter.getPositionForOffset(Offset(maxWidth, 0));
    int breakIndex = position.offset;

    if (breakIndex > 0 && breakIndex < text.length) {
      final beforeBreak = text.substring(0, breakIndex);
      final lastSpace = beforeBreak.lastIndexOf(' ');

      if (lastSpace > 0) {
        // Found a space before break point - use it
        breakIndex = lastSpace + 1;
      } else if (KinsokuProcessor.containsCjk(text)) {
        // Text contains CJK - check if break position is within CJK context
        final isCjkBreak = _isBreakInCjkContext(text, breakIndex);

        if (isCjkBreak) {
          // Break is in CJK region - apply Kinsoku rules
          breakIndex = KinsokuProcessor.findBreakPoint(text, breakIndex);
          if (breakIndex < 0) breakIndex = position.offset;
        } else {
          // Break is in Latin region of mixed text - treat as Latin
          // Look for next space AFTER break point to avoid breaking words
          final afterBreak = text.substring(breakIndex);
          final nextSpace = afterBreak.indexOf(' ');

          if (nextSpace >= 0) {
            // Found space after - but this means moving more to next line
            return null;
          }
          // No space in Latin part - may need force split
          return null;
        }
      } else {
        // Pure Latin text without space before break point
        // Look for next space AFTER break point to avoid breaking words
        final afterBreak = text.substring(breakIndex);
        final nextSpace = afterBreak.indexOf(' ');

        if (nextSpace >= 0) {
          // Found space after - but this means moving more to next line
          // Return null to signal "can't fit any complete word on this line"
          // The caller should start a new line and try again
          return null;
        }
        // No space at all in text - this is a single long word
        // Return null, let caller decide (may force split if word > line width)
        return null;
      }
    }

    if (breakIndex <= 0 || breakIndex >= text.length) {
      return null;
    }

    // Only trim spaces for normal/nowrap/pre-line modes
    // For pre/pre-wrap/break-spaces, preserve all whitespace
    final whiteSpace = fragment.style.whiteSpace;
    final shouldTrim = (whiteSpace != 'pre' &&
                        whiteSpace != 'pre-wrap' &&
                        whiteSpace != 'break-spaces');

    final firstPart = shouldTrim
        ? text.substring(0, breakIndex).trimRight()
        : text.substring(0, breakIndex);
    final secondPart = shouldTrim
        ? text.substring(breakIndex).trimLeft()
        : text.substring(breakIndex);

    if (firstPart.isEmpty || secondPart.isEmpty) {
      return null;
    }

    final firstFragment = Fragment.text(
      text: firstPart,
      sourceNode: fragment.sourceNode,
      style: fragment.style,
      characterOffset: fragment.characterOffset,
    );
    _measureFragment(firstFragment);

    final secondFragment = Fragment.text(
      text: secondPart,
      sourceNode: fragment.sourceNode,
      style: fragment.style,
      characterOffset: fragment.characterOffset + breakIndex,
    );
    _measureFragment(secondFragment);

    return (firstFragment, secondFragment);
  }

  void _measureFragment(Fragment fragment) {
    if (fragment.type == FragmentType.text && fragment.text != null) {
      final painter = _getTextPainter(fragment.text!, fragment.style);
      fragment.measuredSize = Size(painter.width, painter.height);
    }
  }

  /// Force split text fragment when entire text is wider than the available line
  /// This tries to respect word boundaries for Latin text, only breaking mid-word
  /// when a single word is wider than the entire line width
  (Fragment, Fragment)? _forceSplitTextFragment(Fragment fragment, double maxWidth) {
    final text = fragment.text!;
    if (text.length <= 1) return null;

    // First, try to find a word boundary that fits
    int breakIndex = -1;

    // Find all space positions
    final spaceIndices = <int>[];
    for (int i = 0; i < text.length; i++) {
      if (text[i] == ' ') {
        spaceIndices.add(i);
      }
    }

    // Try each word boundary from the end
    for (int i = spaceIndices.length - 1; i >= 0; i--) {
      final spaceIdx = spaceIndices[i];
      final testText = text.substring(0, spaceIdx + 1);
      final painter = _getTextPainter(testText, fragment.style);

      if (painter.width <= maxWidth) {
        breakIndex = spaceIdx + 1;
        break;
      }
    }

    // If we found a word boundary, use it
    if (breakIndex > 0 && breakIndex < text.length) {
      // Only trim spaces for normal/nowrap/pre-line modes
      final whiteSpace = fragment.style.whiteSpace;
      final shouldTrim = (whiteSpace != 'pre' &&
                          whiteSpace != 'pre-wrap' &&
                          whiteSpace != 'break-spaces');

      final firstPart = shouldTrim
          ? text.substring(0, breakIndex).trimRight()
          : text.substring(0, breakIndex);
      final secondPart = shouldTrim
          ? text.substring(breakIndex).trimLeft()
          : text.substring(breakIndex);

      if (firstPart.isNotEmpty && secondPart.isNotEmpty) {
        final firstFragment = Fragment.text(
          text: firstPart,
          sourceNode: fragment.sourceNode,
          style: fragment.style,
          characterOffset: fragment.characterOffset,
        );
        _measureFragment(firstFragment);

        final secondFragment = Fragment.text(
          text: secondPart,
          sourceNode: fragment.sourceNode,
          style: fragment.style,
          characterOffset: fragment.characterOffset + breakIndex,
        );
        _measureFragment(secondFragment);

        return (firstFragment, secondFragment);
      }
    }

    // No word boundary fits - check if this is CJK text (OK to break mid-character)
    if (KinsokuProcessor.containsCjk(text)) {
      // Use binary search to find the best break point for CJK
      int low = 1;
      int high = text.length - 1;
      int bestBreak = 1;

      while (low <= high) {
        final mid = (low + high) ~/ 2;
        final testText = text.substring(0, mid);
        final painter = _getTextPainter(testText, fragment.style);

        if (painter.width <= maxWidth) {
          bestBreak = mid;
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      }

      if (bestBreak >= 1 && bestBreak < text.length) {
        // Check if break is in CJK context for mixed text handling
        int finalBreak;
        if (_isBreakInCjkContext(text, bestBreak)) {
          // In CJK region - apply Kinsoku rules
          final kinsokuBreak = KinsokuProcessor.findBreakPoint(text, bestBreak);
          finalBreak = kinsokuBreak > 0 ? kinsokuBreak : bestBreak;
        } else {
          // In Latin region - look for nearby space to avoid mid-word break
          final beforeBreak = text.substring(0, bestBreak);
          final lastSpace = beforeBreak.lastIndexOf(' ');
          if (lastSpace > 0) {
            // Found space before - use it
            finalBreak = lastSpace + 1;
          } else {
            // No space found - use binary search result (will break mid-word)
            finalBreak = bestBreak;
          }
        }

        final firstPart = text.substring(0, finalBreak);
        final secondPart = text.substring(finalBreak);

        if (firstPart.isNotEmpty && secondPart.isNotEmpty) {
          final firstFragment = Fragment.text(
            text: firstPart,
            sourceNode: fragment.sourceNode,
            style: fragment.style,
            characterOffset: fragment.characterOffset,
          );
          _measureFragment(firstFragment);

          final secondFragment = Fragment.text(
            text: secondPart,
            sourceNode: fragment.sourceNode,
            style: fragment.style,
            characterOffset: fragment.characterOffset + finalBreak,
          );
          _measureFragment(secondFragment);

          return (firstFragment, secondFragment);
        }
      }
    }

    // For Latin text with a single word wider than the line - allow overflow
    // Don't break mid-word, just return null and let the word overflow
    return null;
  }

  /// Default float size when not specified in CSS
  static const double defaultFloatSize = 100.0;

  void _layoutFloat(Fragment fragment, double currentY) {
    if (fragment is! _FloatFragment) return;

    double width;
    double height;

    // Try to get size from the actual child widget (for images, etc.)
    final child = _findChildForFragment(fragment);
    if (child != null) {
      // Layout the child to get its actual size
      child.layout(BoxConstraints(maxWidth: _maxWidth), parentUsesSize: true);
      width = child.size.width;
      height = child.size.height;
    } else {
      // Fallback to CSS style or default size
      width = fragment.style.width ?? defaultFloatSize;
      height = fragment.style.height ?? defaultFloatSize;
    }

    // Get margin from CSS style for proper text spacing
    final margin = fragment.style.margin;

    // Apply default margin if none specified for better text spacing
    const defaultFloatMargin = 8.0;
    final rightMargin = margin.right > 0 ? margin.right : defaultFloatMargin;
    final leftMargin = margin.left > 0 ? margin.left : defaultFloatMargin;
    final bottomMargin = margin.bottom > 0 ? margin.bottom : defaultFloatMargin;

    Rect floatRect;

    if (fragment.floatDirection == HyperFloat.left) {
      double left = 0;
      for (final existing in _leftFloats) {
        if (existing.rect.bottom > currentY) {
          left = math.max(left, existing.rect.right);
        }
      }

      // Float rect includes margin on right and bottom for text spacing
      // Left and top margins are handled by positioning
      floatRect = Rect.fromLTWH(
        left,
        currentY,
        width + rightMargin,  // Add right margin so text doesn't stick
        height + bottomMargin, // Add bottom margin for vertical spacing
      );
      _leftFloats.add(_FloatArea(rect: floatRect, direction: HyperFloat.left));
    } else {
      double right = _maxWidth;
      for (final existing in _rightFloats) {
        if (existing.rect.bottom > currentY) {
          right = math.min(right, existing.rect.left);
        }
      }

      // Float rect includes margin on left and bottom for text spacing
      floatRect = Rect.fromLTWH(
        right - width - leftMargin, // Add left margin so text doesn't stick
        currentY,
        width + leftMargin,   // Total width including margin
        height + bottomMargin,
      );
      _rightFloats
          .add(_FloatArea(rect: floatRect, direction: HyperFloat.right));
    }

    fragment.measuredSize = Size(width, height);
    // Child widget position is at top-left of float rect (excludes margin)
    if (fragment.floatDirection == HyperFloat.left) {
      fragment.offset = floatRect.topLeft;
    } else {
      // For right float, offset child by left margin to position image correctly
      fragment.offset = Offset(floatRect.left + leftMargin, floatRect.top);
    }
  }

  /// Step 4: Position fragments within lines (baseline alignment)
  void _positionFragments() {
    for (final line in _lines) {
      double x = line.leftInset;

      for (final fragment in line.fragments) {
        double fragmentBaseline;

        // Calculate baseline for each fragment type
        if (fragment.type == FragmentType.text && fragment.text != null) {
          final painter = _getTextPainter(fragment.text!, fragment.style);
          fragmentBaseline = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
        } else if (fragment.type == FragmentType.ruby) {
          // Ruby text baseline is at the bottom of base text
          fragmentBaseline = fragment.height * 0.85;
        } else {
          // Atomic elements align to bottom
          fragmentBaseline = fragment.height;
        }

        final yOffset = line.baseline - fragmentBaseline;
        fragment.offset = Offset(x, line.top + math.max(0, yOffset));
        x += fragment.width;
      }
    }
  }

  /// Step 5: Build inline decorations for background/border across line breaks
  void _buildInlineDecorations() {
    _inlineDecorations.clear();

    // Fast path: scan fragments once to find decorated inlines and their ranges
    final decoratedRanges = <UDTNode, (ComputedStyle, int, int)>{}; // node -> (style, startIdx, endIdx)

    for (int i = 0; i < _fragments.length; i++) {
      final fragment = _fragments[i];
      if (fragment is _InlineStartFragment) {
        decoratedRanges[fragment.sourceNode] = (fragment.style, i, -1);
      } else if (fragment is _InlineEndFragment) {
        final existing = decoratedRanges[fragment.sourceNode];
        if (existing != null) {
          decoratedRanges[fragment.sourceNode] = (existing.$1, existing.$2, i);
        }
      }
    }

    if (decoratedRanges.isEmpty) return;

    // Build set of all source nodes within each decorated range
    final nodeToDecorated = <UDTNode, UDTNode>{};
    for (final entry in decoratedRanges.entries) {
      final decoratedNode = entry.key;
      final (_, startIdx, endIdx) = entry.value;
      if (endIdx < 0) continue;

      for (int i = startIdx; i <= endIdx; i++) {
        final sourceNode = _fragments[i].sourceNode;
        nodeToDecorated[sourceNode] = decoratedNode;
      }
    }

    // Collect rects from lines efficiently
    final rectsMap = <UDTNode, List<Rect>>{};
    for (final node in decoratedRanges.keys) {
      rectsMap[node] = [];
    }

    for (final line in _lines) {
      for (final fragment in line.fragments) {
        final decoratedNode = nodeToDecorated[fragment.sourceNode];
        if (decoratedNode != null) {
          final rect = fragment.rect;
          if (rect != null) {
            // Expand rect by padding from the decorated node's style
            final (style, _, _) = decoratedRanges[decoratedNode]!;
            final padding = style.padding;

            final expandedRect = Rect.fromLTWH(
              rect.left - padding.left,
              rect.top - padding.top,
              rect.width + padding.left + padding.right,
              rect.height + padding.top + padding.bottom,
            );

            rectsMap[decoratedNode]!.add(expandedRect);
          }
        }
      }
    }

    // Create decorations
    for (final entry in decoratedRanges.entries) {
      final node = entry.key;
      final (style, _, _) = entry.value;
      final rects = rectsMap[node] ?? [];
      if (rects.isNotEmpty) {
        _inlineDecorations.add(_InlineDecoration(
          node: node,
          rects: rects,
          backgroundColor: style.backgroundColor,
          borderColor: style.borderColor,
          borderWidth: style.borderWidth.top,
          borderRadius: style.borderRadius,
        ));
      }
    }
  }

  /// Fragment range for efficient character lookup
  final List<(int, int, Fragment)> _fragmentRanges = []; // (startIndex, endIndex, fragment)

  /// Step 6: Build character mapping for selection (optimized)
  void _buildCharacterMapping() {
    _characterToFragment.clear();
    _fragmentRanges.clear();
    _totalCharacterCount = 0;

    // Build ranges instead of individual character mapping
    for (final fragment in _fragments) {
      if (fragment.type == FragmentType.text && fragment.text != null) {
        final startIdx = _totalCharacterCount;
        final endIdx = startIdx + fragment.text!.length;
        _fragmentRanges.add((startIdx, endIdx, fragment));
        _totalCharacterCount = endIdx;
      }
    }
  }

  /// Step 7: Layout child RenderBoxes
  void _layoutChildren() {
    // First, link children to their corresponding fragments
    _linkChildrenToFragments();

    // Then layout each child
    RenderBox? child = firstChild;

    while (child != null) {
      final parentData = child.parentData as HyperBoxParentData;
      bool wasLaidOut = false;

      if (parentData.isFloat) {
        // Float children use floatRect from float layout
        final floatFragment = _findFloatFragmentForNode(parentData.sourceNode);
        if (floatFragment != null) {
          parentData.floatRect = Rect.fromLTWH(
            floatFragment.offset?.dx ?? 0,
            floatFragment.offset?.dy ?? 0,
            floatFragment.measuredSize?.width ?? 100,
            floatFragment.measuredSize?.height ?? 100,
          );
        }

        if (parentData.floatRect != null) {
          child.layout(
            BoxConstraints.tight(parentData.floatRect!.size),
            parentUsesSize: true,
          );
          parentData.offset = parentData.floatRect!.topLeft;
          wasLaidOut = true;
        }
      } else if (parentData.fragment != null) {
        final fragment = parentData.fragment!;
        // Always layout to ensure parent data is properly cleaned
        child.layout(
          BoxConstraints.tight(fragment.measuredSize ?? Size.zero),
          parentUsesSize: true,
        );
        parentData.offset = fragment.offset ?? Offset.zero;
        wasLaidOut = true;
      } else if (parentData.sourceNode != null) {
        // Fallback: try to find fragment by source node
        final fragment = _findFragmentForNode(parentData.sourceNode!);
        if (fragment != null) {
          parentData.fragment = fragment;
          child.layout(
            BoxConstraints.tight(fragment.measuredSize ?? Size.zero),
            parentUsesSize: true,
          );
          parentData.offset = fragment.offset ?? Offset.zero;
          wasLaidOut = true;
        }
      }

      // CRITICAL: Ensure every child is laid out, even orphaned ones
      // This prevents parent data from staying dirty and causing assertion errors
      if (!wasLaidOut) {
        child.layout(BoxConstraints.tight(Size.zero), parentUsesSize: false);
        parentData.offset = Offset.zero;
      }

      child = parentData.nextSibling;
    }
  }

  /// Link child RenderBoxes to their corresponding fragments using ORDER-BASED matching
  ///
  /// This is critical for atomic elements (images, tables) to render correctly.
  /// Since fragments and children are both created by traversing the UDT in the same order,
  /// we can match them by iterating through both lists simultaneously.
  void _linkFragmentsToChildrenByOrder() {
    RenderBox? child = firstChild;

    for (final fragment in _fragments) {
      if (child == null) break;

      // Match atomic fragments (images, embeds) and special fragment types
      final isAtomicFragment = fragment.type == FragmentType.atomic;
      final isTableFragment = fragment is _TableFragment;
      final isCodeBlockFragment = fragment is _CodeBlockFragment;
      final isFloatFragment = fragment is _FloatFragment;

      if (isAtomicFragment || isTableFragment || isCodeBlockFragment || isFloatFragment) {
        final parentData = child.parentData as HyperBoxParentData;

        // Link fragment to child
        parentData.fragment = fragment;

        // Set float info if applicable
        if (isFloatFragment) {
          final floatFrag = fragment;
          parentData.isFloat = true;
          parentData.floatDirection = floatFrag.floatDirection;
        }

        // Move to next child
        child = parentData.nextSibling;
      }
    }
  }

  /// Legacy method - kept for fallback compatibility
  void _linkChildrenToFragments() {
    RenderBox? child = firstChild;

    while (child != null) {
      final parentData = child.parentData as HyperBoxParentData;

      // Skip if already linked by order-based method
      if (parentData.fragment != null) {
        child = parentData.nextSibling;
        continue;
      }

      if (parentData.sourceNode != null && !parentData.isFloat) {
        // Find the fragment that matches this source node
        parentData.fragment = _findFragmentForNode(parentData.sourceNode!);
      }

      child = parentData.nextSibling;
    }
  }

  /// Find child RenderBox for a given fragment
  RenderBox? _findChildForFragment(Fragment fragment) {
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as HyperBoxParentData;
      if (parentData.sourceNode == fragment.sourceNode) {
        return child;
      }
      child = parentData.nextSibling;
    }
    return null;
  }

  /// Find fragment that matches the given source node
  Fragment? _findFragmentForNode(UDTNode node) {
    for (final fragment in _fragments) {
      if (fragment.sourceNode == node) {
        return fragment;
      }
    }
    return null;
  }

  /// Find float fragment that matches the given source node
  Fragment? _findFloatFragmentForNode(UDTNode? node) {
    if (node == null) return null;
    for (final fragment in _fragments) {
      if (fragment is _FloatFragment && fragment.sourceNode == node) {
        return fragment;
      }
    }
    return null;
  }

  // ============================================
  // Painting
  // ============================================

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    // CSS Stacking Order:
    // 0. Block decorations (border-left for blockquote, etc.)
    _paintBlockDecorations(canvas, offset);

    // 1. Background and borders (inline decorations)
    _paintInlineDecorations(canvas, offset);

    // 2. Float elements (painted before inline content)
    _paintFloatImages(canvas, offset);

    // 3. Selection highlight (behind text)
    if (_selection != null && _selection!.isValid && !_selection!.isCollapsed) {
      _paintSelection(canvas, offset);
    }

    // 4. Inline content (text fragments)
    _paintTextFragments(canvas, offset);

    // 5. Inline images (non-float)
    _paintInlineImages(canvas, offset);

    // 6. Child render boxes (tables, positioned elements)
    defaultPaint(context, offset);
  }

  void _paintBlockDecorations(Canvas canvas, Offset offset) {
    for (final decoration in _blockDecorations) {
      final adjustedRect = decoration.rect.shift(offset);

      // Paint background if specified
      if (decoration.backgroundColor != null) {
        final bgPaint = Paint()..color = decoration.backgroundColor!;

        if (decoration.borderRadius != null) {
          // Draw rounded rectangle for code blocks, etc.
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              adjustedRect,
              topLeft: decoration.borderRadius!.topLeft,
              topRight: decoration.borderRadius!.topRight,
              bottomLeft: decoration.borderRadius!.bottomLeft,
              bottomRight: decoration.borderRadius!.bottomRight,
            ),
            bgPaint,
          );
        } else {
          canvas.drawRect(adjustedRect, bgPaint);
        }
      }

      // Paint border-left (for blockquote style)
      if (decoration.borderLeftColor != null && decoration.borderLeftWidth > 0) {
        final borderPaint = Paint()
          ..color = decoration.borderLeftColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = decoration.borderLeftWidth;

        canvas.drawLine(
          Offset(adjustedRect.left + decoration.borderLeftWidth / 2, adjustedRect.top),
          Offset(adjustedRect.left + decoration.borderLeftWidth / 2, adjustedRect.bottom),
          borderPaint,
        );
      }
    }
  }

  void _paintInlineDecorations(Canvas canvas, Offset offset) {
    for (final decoration in _inlineDecorations) {
      for (final rect in decoration.rects) {
        final adjustedRect = rect.shift(offset);

        // Paint background
        if (decoration.backgroundColor != null) {
          final paint = Paint()..color = decoration.backgroundColor!;

          if (decoration.borderRadius != null) {
            canvas.drawRRect(
              RRect.fromRectAndCorners(
                adjustedRect,
                topLeft: decoration.borderRadius!.topLeft,
                topRight: decoration.borderRadius!.topRight,
                bottomLeft: decoration.borderRadius!.bottomLeft,
                bottomRight: decoration.borderRadius!.bottomRight,
              ),
              paint,
            );
          } else {
            canvas.drawRect(adjustedRect, paint);
          }
        }

        // Paint border
        if (decoration.borderColor != null && decoration.borderWidth > 0) {
          final paint = Paint()
            ..color = decoration.borderColor!
            ..style = PaintingStyle.stroke
            ..strokeWidth = decoration.borderWidth;

          if (decoration.borderRadius != null) {
            canvas.drawRRect(
              RRect.fromRectAndCorners(
                adjustedRect,
                topLeft: decoration.borderRadius!.topLeft,
                topRight: decoration.borderRadius!.topRight,
                bottomLeft: decoration.borderRadius!.bottomLeft,
                bottomRight: decoration.borderRadius!.bottomRight,
              ),
              paint,
            );
          } else {
            canvas.drawRect(adjustedRect, paint);
          }
        }
      }
    }
  }

  void _paintSelection(Canvas canvas, Offset offset) {
    final selectionPaint = Paint()
      ..color = const Color(0x40007AFF); // iOS blue with 25% opacity

    int currentOffset = 0;
    for (final line in _lines) {
      for (final fragment in line.fragments) {
        if (fragment.type == FragmentType.text && fragment.text != null) {
          final fragmentStart = currentOffset;
          final fragmentEnd = currentOffset + fragment.text!.length;

          // Check if this fragment overlaps with selection
          if (fragmentEnd > _selection!.start &&
              fragmentStart < _selection!.end) {
            final selectStart =
                math.max(0, _selection!.start - fragmentStart);
            final selectEnd = math.min(
                fragment.text!.length, _selection!.end - fragmentStart);

            // Get selection rect within this fragment
            final painter = _getTextPainter(fragment.text!, fragment.style);
            final startOffset = painter
                .getOffsetForCaret(TextPosition(offset: selectStart),
                    Rect.zero)
                .dx;
            final endOffset = painter
                .getOffsetForCaret(TextPosition(offset: selectEnd), Rect.zero)
                .dx;

            final fragmentOffset = fragment.offset ?? Offset.zero;
            final selectionRect = Rect.fromLTWH(
              offset.dx + fragmentOffset.dx + startOffset,
              offset.dy + fragmentOffset.dy,
              endOffset - startOffset,
              fragment.height,
            );

            canvas.drawRect(selectionRect, selectionPaint);
          }

          currentOffset = fragmentEnd;
        }
      }
    }
  }

  void _paintTextFragments(Canvas canvas, Offset offset) {
    // First paint list markers
    for (final fragment in _fragments) {
      if (fragment is _ListMarkerFragment && fragment.offset != null) {
        _paintListMarker(canvas, offset, fragment);
      }
    }

    // Then paint line content
    for (final line in _lines) {
      for (final fragment in line.fragments) {
        if (fragment.type == FragmentType.text && fragment.text != null) {
          _paintTextFragment(canvas, offset, fragment);
        } else if (fragment.type == FragmentType.ruby) {
          _paintRubyFragment(canvas, offset, fragment);
        }
      }
    }
  }

  void _paintListMarker(Canvas canvas, Offset offset, _ListMarkerFragment fragment) {
    final painter = _getTextPainter(fragment.marker, fragment.style);
    painter.paint(canvas, offset + fragment.offset!);
  }

  void _paintTextFragment(Canvas canvas, Offset offset, Fragment fragment) {
    final fragmentOffset = fragment.offset ?? Offset.zero;
    final painter = _getTextPainter(fragment.text!, fragment.style);
    painter.paint(canvas, offset + fragmentOffset);
  }

  void _paintRubyFragment(Canvas canvas, Offset offset, Fragment fragment) {
    final fragmentOffset = fragment.offset ?? Offset.zero;

    final rubyFontSize = fragment.style.fontSize * rubyFontSizeRatio;
    final rubyStyle = fragment.style.copyWith(fontSize: rubyFontSize);
    final rubyPainter = _getTextPainter(fragment.rubyText!, rubyStyle);
    final basePainter = _getTextPainter(fragment.text!, fragment.style);

    final totalWidth = fragment.width;
    // Center both texts horizontally
    final rubyX = (totalWidth - rubyPainter.width) / 2;
    final baseX = (totalWidth - basePainter.width) / 2;

    // Ruby text is at the top, base text below
    const rubyY = 0.0;
    final baseY = (fragment.rubyHeight ?? rubyPainter.height) + rubyGap;

    rubyPainter.paint(
      canvas,
      offset + fragmentOffset + Offset(rubyX, rubyY),
    );

    basePainter.paint(
      canvas,
      offset + fragmentOffset + Offset(baseX, baseY),
    );
  }

  void _paintFloatImages(Canvas canvas, Offset offset) {
    // Paint images from float fragments ONLY if they don't have child widgets
    for (final fragment in _fragments) {
      if (fragment is _FloatFragment) {
        // Check if this fragment has a linked child widget - if so, skip canvas painting
        // The child widget (HyperImage) will handle rendering
        if (_hasChildWidgetForFragment(fragment)) continue;

        final node = fragment.sourceNode;
        if (node is AtomicNode && node.tagName == 'img') {
          _paintImage(canvas, offset, fragment, node);
        }
      }
    }
  }

  void _paintInlineImages(Canvas canvas, Offset offset) {
    // Paint non-float atomic images ONLY if they don't have child widgets
    for (final fragment in _fragments) {
      if (fragment.type == FragmentType.atomic && fragment is! _FloatFragment) {
        // Check if this fragment has a linked child widget - if so, skip canvas painting
        // The child widget (HyperImage) will handle rendering
        if (_hasChildWidgetForFragment(fragment)) continue;

        final node = fragment.sourceNode;
        if (node is AtomicNode && node.tagName == 'img') {
          _paintImage(canvas, offset, fragment, node);
        }
      }
    }
  }

  /// Check if a fragment has a linked child RenderBox widget
  bool _hasChildWidgetForFragment(Fragment fragment) {
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as HyperBoxParentData;
      if (parentData.fragment == fragment || parentData.sourceNode == fragment.sourceNode) {
        return true;
      }
      child = parentData.nextSibling;
    }
    return false;
  }

  void _paintImage(
      Canvas canvas, Offset offset, Fragment fragment, AtomicNode node) {
    final src = node.src;
    if (src == null) return;

    final fragmentOffset = fragment.offset ?? Offset.zero;
    final rect = Rect.fromLTWH(
      offset.dx + fragmentOffset.dx,
      offset.dy + fragmentOffset.dy,
      fragment.width,
      fragment.height,
    );

    final cached = _imageCache[src];

    if (cached?.state == ImageLoadState.loaded && cached?.image != null) {
      // Draw loaded image with rounded corners if specified
      final borderRadius = fragment.style.borderRadius;
      if (borderRadius != null) {
        canvas.save();
        canvas.clipRRect(RRect.fromRectAndCorners(
          rect,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        ));
      }

      paintImage(
        canvas: canvas,
        rect: rect,
        image: cached!.image!,
        fit: BoxFit.cover,
      );

      if (borderRadius != null) {
        canvas.restore();
      }
    } else if (cached?.state == ImageLoadState.loading) {
      // Draw modern skeleton placeholder
      _paintSkeletonPlaceholder(canvas, rect);
    } else {
      // Draw error placeholder with icon
      _paintErrorPlaceholder(canvas, rect);
    }
  }

  /// Paint a skeleton loading placeholder (similar to shimmer effect)
  void _paintSkeletonPlaceholder(Canvas canvas, Rect rect) {
    // Background
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [
          const Color(0xFFF0F0F0),
          const Color(0xFFE8E8E8),
          const Color(0xFFF0F0F0),
        ],
        [0.0, 0.5, 1.0],
      );

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, bgPaint);

    // Subtle border
    final borderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);

    // Image icon in center
    final center = rect.center;
    final iconPaint = Paint()..color = const Color(0xFFBDBDBD);

    // Draw a simple image icon (mountain landscape)
    final iconPath = Path();
    const iconSize = 24.0;

    // Frame
    iconPath.addRect(Rect.fromCenter(
      center: center,
      width: iconSize * 1.5,
      height: iconSize,
    ));

    canvas.drawPath(iconPath, iconPaint..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Mountains
    final mountainPath = Path();
    mountainPath.moveTo(center.dx - iconSize * 0.6, center.dy + iconSize * 0.3);
    mountainPath.lineTo(center.dx - iconSize * 0.2, center.dy - iconSize * 0.2);
    mountainPath.lineTo(center.dx + iconSize * 0.1, center.dy + iconSize * 0.1);
    mountainPath.lineTo(center.dx + iconSize * 0.3, center.dy - iconSize * 0.1);
    mountainPath.lineTo(center.dx + iconSize * 0.6, center.dy + iconSize * 0.3);

    canvas.drawPath(mountainPath, iconPaint..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  /// Paint an error placeholder with broken image icon
  void _paintErrorPlaceholder(Canvas canvas, Rect rect) {
    // Background
    final bgPaint = Paint()..color = const Color(0xFFFAFAFA);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);

    // Broken image icon
    final center = rect.center;
    final iconPaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const iconSize = 20.0;

    // Draw broken image icon (image frame with crack)
    final framePath = Path();
    framePath.addRect(Rect.fromCenter(
      center: center,
      width: iconSize * 1.5,
      height: iconSize,
    ));
    canvas.drawPath(framePath, iconPaint);

    // Diagonal crack
    canvas.drawLine(
      Offset(center.dx - iconSize * 0.5, center.dy - iconSize * 0.3),
      Offset(center.dx + iconSize * 0.5, center.dy + iconSize * 0.3),
      iconPaint..color = const Color(0xFFE57373),
    );
  }

  // ============================================
  // Hit Testing & Selection
  // ============================================

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // Custom hit test that skips children without valid size
    RenderBox? child = lastChild;
    while (child != null) {
      final childParentData = child.parentData as HyperBoxParentData;

      // Skip children that don't have a valid size
      if (!child.hasSize) {
        child = childParentData.previousSibling;
        continue;
      }

      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child!.hitTest(result, position: transformed);
        },
      );

      if (isHit) {
        return true;
      }

      child = childParentData.previousSibling;
    }
    return false;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      final position = event.localPosition;

      // Check for link tap
      final clickedFragment = _findFragmentAtPosition(position);
      if (clickedFragment != null) {
        final node = clickedFragment.sourceNode;
        if (node.tagName == 'a') {
          final href = node.attributes['href'];
          if (href != null && _onLinkTap != null) {
            _onLinkTap!(href);
            return;
          }
        }
      }

      // Start selection
      if (_selectable) {
        final charPos = _getCharacterPositionAtOffset(position);
        if (charPos >= 0) {
          _selectionStartPosition = charPos;
          _selection = HyperTextSelection(start: charPos, end: charPos);
          markNeedsPaint();
        }
      }
    } else if (event is PointerMoveEvent && _selectable) {
      if (_selectionStartPosition != null) {
        final charPos = _getCharacterPositionAtOffset(event.localPosition);
        if (charPos >= 0) {
          final start = math.min(_selectionStartPosition!, charPos);
          final end = math.max(_selectionStartPosition!, charPos);
          _selection = HyperTextSelection(start: start, end: end);
          markNeedsPaint();
        }
      }
    } else if (event is PointerUpEvent) {
      _selectionStartPosition = null;
      // Notify selection changed when user finishes selection
      if (_selection != null && !_selection!.isCollapsed) {
        _notifySelectionChanged();
      }
    }

    super.handleEvent(event, entry);
  }

  Fragment? _findFragmentAtPosition(Offset position) {
    for (final line in _lines) {
      if (position.dy >= line.top && position.dy < line.top + line.height) {
        for (final fragment in line.fragments) {
          final rect = fragment.rect;
          if (rect != null && rect.contains(position)) {
            return fragment;
          }
        }
      }
    }
    return null;
  }

  int _getCharacterPositionAtOffset(Offset position) {
    int currentOffset = 0;

    for (final line in _lines) {
      if (position.dy >= line.top && position.dy < line.top + line.height) {
        for (final fragment in line.fragments) {
          if (fragment.type == FragmentType.text && fragment.text != null) {
            final fragmentOffset = fragment.offset ?? Offset.zero;
            final fragmentRect = Rect.fromLTWH(
              fragmentOffset.dx,
              fragmentOffset.dy,
              fragment.width,
              fragment.height,
            );

            if (position.dx >= fragmentRect.left &&
                position.dx <= fragmentRect.right) {
              // Find character within fragment
              final painter = _getTextPainter(fragment.text!, fragment.style);
              final localX = position.dx - fragmentRect.left;
              final textPosition =
                  painter.getPositionForOffset(Offset(localX, 0));
              return currentOffset + textPosition.offset;
            }

            currentOffset += fragment.text!.length;
          }
        }
        // If we're on the line but past all fragments, return end of line
        return currentOffset;
      }

      // Add character count for this line
      for (final fragment in line.fragments) {
        if (fragment.type == FragmentType.text && fragment.text != null) {
          currentOffset += fragment.text!.length;
        }
      }
    }

    return -1;
  }

  /// Get selected text
  String? getSelectedText() {
    if (_selection == null || !_selection!.isValid || _selection!.isCollapsed) {
      return null;
    }

    final buffer = StringBuffer();
    int currentOffset = 0;

    for (final fragment in _fragments) {
      if (fragment.type == FragmentType.text && fragment.text != null) {
        final fragmentStart = currentOffset;
        final fragmentEnd = currentOffset + fragment.text!.length;

        if (fragmentEnd > _selection!.start &&
            fragmentStart < _selection!.end) {
          final selectStart = math.max(0, _selection!.start - fragmentStart);
          final selectEnd =
              math.min(fragment.text!.length, _selection!.end - fragmentStart);
          buffer.write(fragment.text!.substring(selectStart, selectEnd));
        }

        currentOffset = fragmentEnd;
      }
    }

    return buffer.isEmpty ? null : buffer.toString();
  }

  /// Copy selected text to clipboard
  Future<void> copySelection() async {
    final text = getSelectedText();
    if (text != null) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  /// Clear selection
  void clearSelection() {
    _selection = null;
    markNeedsPaint();
    _notifySelectionChanged();
  }

  /// Select all text
  void selectAll() {
    if (_totalCharacterCount > 0) {
      _selection =
          HyperTextSelection(start: 0, end: _totalCharacterCount);
      markNeedsPaint();
      _notifySelectionChanged();
    }
  }

  /// Get selection rects for rendering handles
  List<Rect> getSelectionRects() {
    if (_selection == null || !_selection!.isValid || _selection!.isCollapsed) {
      return [];
    }

    final rects = <Rect>[];
    int currentOffset = 0;

    for (final line in _lines) {
      for (final fragment in line.fragments) {
        if (fragment.type == FragmentType.text && fragment.text != null) {
          final fragmentStart = currentOffset;
          final fragmentEnd = currentOffset + fragment.text!.length;

          if (fragmentEnd > _selection!.start &&
              fragmentStart < _selection!.end) {
            final selectStart =
                math.max(0, _selection!.start - fragmentStart);
            final selectEnd = math.min(
                fragment.text!.length, _selection!.end - fragmentStart);

            final painter = _getTextPainter(fragment.text!, fragment.style);
            final startOffset = painter
                .getOffsetForCaret(TextPosition(offset: selectStart), Rect.zero)
                .dx;
            final endOffset = painter
                .getOffsetForCaret(TextPosition(offset: selectEnd), Rect.zero)
                .dx;

            final fragmentOffset = fragment.offset ?? Offset.zero;
            rects.add(Rect.fromLTWH(
              fragmentOffset.dx + startOffset,
              fragmentOffset.dy,
              endOffset - startOffset,
              fragment.height,
            ));
          }

          currentOffset = fragmentEnd;
        }
      }
    }

    return rects;
  }

  /// Get the rect for start handle
  Rect? getStartHandleRect() {
    final rects = getSelectionRects();
    if (rects.isEmpty) return null;
    return rects.first;
  }

  /// Get the rect for end handle
  Rect? getEndHandleRect() {
    final rects = getSelectionRects();
    if (rects.isEmpty) return null;
    return rects.last;
  }

  /// Update selection from handle drag
  void updateSelectionFromHandle(
    bool isStartHandle,
    Offset localPosition,
  ) {
    final charPos = _getCharacterPositionAtOffset(localPosition);
    if (charPos < 0 || _selection == null) return;

    if (isStartHandle) {
      if (charPos < _selection!.end) {
        _selection = HyperTextSelection(start: charPos, end: _selection!.end);
        markNeedsPaint();
      }
    } else {
      if (charPos > _selection!.start) {
        _selection = HyperTextSelection(start: _selection!.start, end: charPos);
        markNeedsPaint();
      }
    }
  }

  // ============================================
  // Debug
  // ============================================

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('fragmentCount', _fragments.length));
    properties.add(IntProperty('lineCount', _lines.length));
    properties.add(IntProperty('leftFloats', _leftFloats.length));
    properties.add(IntProperty('rightFloats', _rightFloats.length));
    properties.add(IntProperty('totalCharacters', _totalCharacterCount));
    properties.add(DiagnosticsProperty('selection', _selection));
  }
}

// ============================================
// Special Fragment Types
// ============================================

class _BlockStartFragment extends Fragment {
  final double marginTop;
  final double paddingTop;
  final double paddingLeft;
  final double paddingRight;

  _BlockStartFragment({
    required super.sourceNode,
    required super.style,
    this.marginTop = 0,
    this.paddingTop = 0,
    this.paddingLeft = 0,
    this.paddingRight = 0,
  }) : super(type: FragmentType.text, text: '');
}

class _BlockEndFragment extends Fragment {
  final double marginBottom;
  final double paddingBottom;

  _BlockEndFragment({
    required super.sourceNode,
    required super.style,
    this.marginBottom = 0,
    this.paddingBottom = 0,
  }) : super(type: FragmentType.text, text: '');
}

class _FloatFragment extends Fragment {
  final HyperFloat floatDirection;

  _FloatFragment({
    required super.sourceNode,
    required super.style,
    required this.floatDirection,
  }) : super(type: FragmentType.atomic);
}

class _TableFragment extends Fragment {
  _TableFragment({
    required super.sourceNode,
    required super.style,
  }) : super(type: FragmentType.atomic);
}

/// Fragment for code blocks (<pre> elements) that are rendered as child widgets
/// This acts as a placeholder in the fragment list, similar to _TableFragment
class _CodeBlockFragment extends Fragment {
  _CodeBlockFragment({
    required super.sourceNode,
    required super.style,
  }) : super(type: FragmentType.atomic);
}

class _InlineStartFragment extends Fragment {
  _InlineStartFragment({
    required super.sourceNode,
    required super.style,
  }) : super(type: FragmentType.text, text: '');
}

class _InlineEndFragment extends Fragment {
  _InlineEndFragment({
    required super.sourceNode,
    required super.style,
  }) : super(type: FragmentType.text, text: '');
}

/// Fragment for list markers (bullets, numbers)
class _ListMarkerFragment extends Fragment {
  /// The marker text (•, 1., 2., etc.)
  final String marker;

  /// Whether this is an ordered list
  final bool isOrdered;

  /// The list item index (1-based)
  final int index;

  _ListMarkerFragment({
    required super.sourceNode,
    required super.style,
    required this.marker,
    required this.isOrdered,
    required this.index,
  }) : super(type: FragmentType.text, text: marker);
}
