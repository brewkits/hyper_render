import 'dart:collection';
import 'dart:io' show Platform;
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
import 'lazy_image_queue.dart';

part 'render_hyper_box_types.dart';
part 'render_hyper_box_fragments.dart';
part 'render_hyper_box_layout.dart';
part 'render_hyper_box_paint.dart';
part 'render_hyper_box_selection.dart';
part 'render_hyper_box_accessibility.dart';

/// Callback for handling link taps
typedef HyperLinkTapCallback = void Function(String url);

/// Callback for building custom widgets for embedded content
typedef HyperWidgetBuilder = Widget? Function(UDTNode node);

/// Callback when image loading state changes
typedef ImageLoadCallback = void Function(String src, ImageLoadState state);

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
  HyperLinkTapCallback? onLinkTap;

  /// Custom image loader (defaults to defaultImageLoader if not provided)
  HyperImageLoader? _imageLoader;

  /// Whether text selection is enabled
  bool _selectable;

  /// Text direction for layout (LTR or RTL)
  TextDirection _textDirection;

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

  /// Position recorded on PointerDown — used to detect tap-vs-drag for links.
  Offset? _pointerDownPosition;

  /// Total character count in document
  int _totalCharacterCount = 0;

  /// Cached intrinsic widths (invalidated on layout change)
  double? _cachedMinIntrinsicWidth;
  double? _cachedMaxIntrinsicWidth;

  /// Character offset to fragment mapping
  final Map<int, Fragment> _characterToFragment = {};

  /// Color for text selection highlight
  Color? _selectionColor;

  /// Callback when selection changes
  VoidCallback? onSelectionChanged;

  /// When true, draws colored outlines over each fragment/line for debugging.
  /// Equivalent to Flutter's [debugPaintSizeEnabled] but scoped to this widget.
  bool debugShowBounds = false;

  /// Track list item indices for ordered lists
  final Map<UDTNode, int> _listItemIndices = {};

  /// Fragment range for efficient character lookup
  final List<(int, int, Fragment)> _fragmentRanges = []; // (startIndex, endIndex, fragment)

  // ── Incremental layout dirty tracking ─────────────────────────────────────
  /// Bumped each time _fragments is rebuilt (via _ensureFragments).
  /// Line layout skips when this matches [_linesFragmentsVersion] AND
  /// [_linesMaxWidth] equals the current constraint width.
  int _fragmentsVersion = 0;

  /// The [_fragmentsVersion] value when _lines was last successfully built.
  int _linesFragmentsVersion = -1;

  /// The [_maxWidth] value when _lines was last successfully built.
  double _linesMaxWidth = double.nan;

  /// Default placeholder size for images without dimensions
  static const double _defaultImageWidth = 200.0;
  // Note: default height is computed from width / aspect ratio
  static const double _defaultAspectRatio = 16.0 / 9.0;

  /// Ruby annotation size ratio (furigana is typically 50% of base text)
  static const double rubyFontSizeRatio = 0.5;

  /// Gap between ruby text and base text
  static const double rubyGap = 2.0;

  /// Default float size when not specified in CSS
  static const double defaultFloatSize = 100.0;

  RenderHyperBox({
    DocumentNode? document,
    TextStyle baseStyle =
        const TextStyle(fontSize: 16, color: Color(0xFF000000)),
    this.onLinkTap,
    HyperImageLoader? imageLoader,
    bool selectable = true,
    TextDirection textDirection = TextDirection.ltr,
    Color? selectionColor,
    this.onSelectionChanged,
  })  : _document = document,
        _baseStyle = baseStyle,
        _imageLoader = imageLoader,
        _selectable = selectable,
        _textDirection = textDirection,
        _selectionColor = selectionColor;

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

  HyperImageLoader? get imageLoader => _imageLoader;
  set imageLoader(HyperImageLoader? value) {
    if (_imageLoader == value) return;
    _imageLoader = value;
    // BUG-C+E FIX: dispose GPU resources before clearing, then re-trigger
    // loading with the new loader so images are not left in a permanent
    // "loading" state after the loader is swapped at runtime.
    _disposeImages();
    if (attached) _loadImages();
    markNeedsLayout();
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

  HyperTextSelection? get selection => _selection;
  set selection(HyperTextSelection? value) {
    if (_selection == value) return;
    _selection = value;
    markNeedsPaint();
    _notifySelectionChanged();
  }

  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    _invalidateLayout();
    markNeedsLayout();
  }

  Color? get selectionColor => _selectionColor;
  set selectionColor(Color? value) {
    if (_selectionColor == value) return;
    _selectionColor = value;
    markNeedsPaint();
  }

  /// Whether the text direction is right-to-left
  bool get isRTL => _textDirection == TextDirection.rtl;

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
    // BUG-C FIX: ui.Image is a native GPU resource that must be explicitly
    // disposed. Calling _imageCache.clear() without dispose() leaks GPU
    // texture memory — the Dart GC cannot free it. This matters especially
    // when documents with many images are swapped frequently.
    for (final entry in _imageCache.values) {
      entry.image?.dispose();
    }
    _imageCache.clear();
  }

  void _invalidateLayout() {
    _fragments.clear();
    _lines.clear();
    _linesFragmentsVersion = -1;
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

  /// Lighter invalidation that preserves the text painter cache.
  ///
  /// Called when image dimensions change: fragments must be re-tokenized
  /// so [_tokenizeAtomic] reads the new image size, but text measurements
  /// are still valid and can be reused.
  void _invalidateFragments() {
    _fragments.clear();
    _lines.clear();
    _linesFragmentsVersion = -1;
    _leftFloats.clear();
    _rightFloats.clear();
    _inlineDecorations.clear();
    _blockDecorations.clear();
    _characterToFragment.clear();
    _fragmentRanges.clear();
    _totalCharacterCount = 0;
    _cachedMinIntrinsicWidth = null;
    _cachedMaxIntrinsicWidth = null;
    // _textPainters intentionally preserved: text metrics are unaffected
    // by image dimension changes.
  }

  void _notifySelectionChanged() {
    // BUG-B FIX: Guard with attached check. The selection setter and handleEvent
    // can fire during the dispose sequence (e.g., an ongoing pointer gesture
    // that completes after the widget is removed from the tree). Calling
    // onSelectionChanged after detach can invoke state on a disposed widget.
    if (!attached) return;
    onSelectionChanged?.call();
  }

  // ============================================
  // Image Loading
  // ============================================

  void _loadImages() {
    if (_document == null) return;

    // Collect images with their approximate document y-position for priority.
    final images = <({String src, int priority})>[];

    _document!.traverse((node) {
      if (node is AtomicNode && node.tagName == 'img') {
        final src = node.src;
        if (src != null && src.isNotEmpty && !_imageCache.containsKey(src)) {
          // Use the fragment's y-position as priority (top = 0 = highest).
          // Before layout, fall back to document order (index in list).
          final yPos = _findFragmentY(node);
          images.add((src: src, priority: yPos));
        }
      }
    });

    for (final img in images) {
      _loadImage(img.src, priority: img.priority);
    }
  }

  /// Returns the y-pixel offset of the first fragment belonging to [node],
  /// or a large value if not yet laid out (loads after visible images).
  int _findFragmentY(AtomicNode node) {
    for (final line in _lines) {
      for (final frag in line.fragments) {
        if (frag.sourceNode == node) {
          return line.top.toInt();
        }
      }
    }
    return 999999; // not laid out yet — lowest priority
  }

  void _loadImage(String src, {int priority = 999999}) {
    _imageCache[src] = const CachedImage(state: ImageLoadState.loading);

    final loader = _imageLoader ?? defaultImageLoader;

    LazyImageQueue.instance.enqueue(
      url: src,
      priority: priority,
      loader: loader,
      onLoad: (ui.Image image) {
        if (!attached) return;
        _imageCache[src] = CachedImage(
          image: image,
          state: ImageLoadState.loaded,
        );
        // Invalidate fragments so _tokenizeAtomic re-reads actual image
        // dimensions. Preserves text painter cache (text metrics unchanged).
        _invalidateFragments();
        markNeedsLayout();
        markNeedsPaint();
      },
      onError: (Object error) {
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

    // Walk fragments and track the width of each "logical line" (reset at block
    // boundaries and explicit line breaks).  Return the widest such line.
    // Summing all widths (the previous approach) produced values orders of
    // magnitude too large for documents with many paragraphs.
    double maxWidth = 0;
    double lineWidth = 0;

    void flushLine() {
      if (lineWidth > maxWidth) maxWidth = lineWidth;
      lineWidth = 0;
    }

    for (final fragment in _fragments) {
      if (fragment is _BlockStartFragment || fragment is _BlockEndFragment) {
        flushLine();
      } else if (fragment.type == FragmentType.lineBreak) {
        flushLine();
      } else if (fragment.type == FragmentType.text ||
          fragment.type == FragmentType.atomic ||
          fragment.type == FragmentType.ruby) {
        lineWidth += fragment.width;
      }
    }
    flushLine(); // flush any trailing line

    _cachedMaxIntrinsicWidth = maxWidth;
    return maxWidth;
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

    try {
      _maxWidth = constraints.maxWidth;

      // Step 1: Tokenization — rebuilds only if _fragments was cleared.
      _ensureFragments();

      // Step 1.5: Link children to fragments (CRITICAL - must be done right after fragments are created)
      // This uses order-based matching since fragments and children are created in same traversal order
      _linkFragmentsToChildrenByOrder();

      // Steps 2–6: Measure + line layout.
      // Skipped when fragments and constraint width are both unchanged —
      // e.g. a repaint-only trigger (selection change, scroll) that happens
      // to call performLayout.  Version mismatch forces a full rebuild.
      // <details> elements can change height dynamically (expand/collapse),
      // so always redo line layout when the document contains any.
      final bool hasDetailsFragments = _fragments.any((f) => f is _DetailsFragment);
      final bool needsLineLayout = _linesFragmentsVersion != _fragmentsVersion ||
          _linesMaxWidth != _maxWidth ||
          _lines.isEmpty ||
          hasDetailsFragments;

      if (needsLineLayout) {
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

        _linesFragmentsVersion = _fragmentsVersion;
        _linesMaxWidth = _maxWidth;
      }

      // Step 7: Layout child RenderBoxes (always — child constraints may change)
      _layoutChildren();

      // Calculate final size
      double height = 0;
      if (_lines.isNotEmpty) {
        final lastLine = _lines.last;
        height = lastLine.top + lastLine.height;
      }

      // Block-level widgets (details, tables, code blocks) are not included in
      // _lines — they update currentY but don't push a line.  When the content
      // consists ENTIRELY of such blocks (e.g. a page of <details> elements
      // with no surrounding text), _lines stays empty and height stays 0.
      // Extend height from fragment offsets + sizes for these block types.
      for (final fragment in _fragments) {
        if (fragment is _DetailsFragment ||
            fragment is _TableFragment ||
            fragment is _CodeBlockFragment) {
          final offset = fragment.offset;
          final measured = fragment.measuredSize;
          if (offset != null && measured != null) {
            final bottom = offset.dy + measured.height + 4; // +4 = block margin
            if (bottom > height) height = bottom;
          }
        }
      }

      for (final float in [..._leftFloats, ..._rightFloats]) {
        if (float.rect.bottom > height) {
          height = float.rect.bottom;
        }
      }

      size = constraints.constrain(Size(_maxWidth, height));
    } catch (e, stack) {
      // Error boundary: Catch layout errors to prevent full app crash
      debugPrint('HyperRender layout error: $e');
      debugPrintStack(stackTrace: stack);

      // Fallback: Render minimum viable size to show something
      size = constraints.constrain(Size(constraints.maxWidth, 0));
    }
  }

  // ============================================
  // Painting
  // ============================================

  @override
  void paint(PaintingContext context, Offset offset) {
    try {
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

      // 7. Debug bounds overlay (only when debugShowBounds is true)
      if (debugShowBounds) {
        _paintDebugBounds(canvas, offset);
      }
    } catch (e, stack) {
      // Error boundary: Catch paint errors to prevent full app crash
      debugPrint('HyperRender paint error: $e');
      debugPrintStack(stackTrace: stack);

      // Fallback: Paint error indicator (red box) to show something went wrong
      final paint = Paint()
        ..color = const Color(0x33FF0000) // Semi-transparent red
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      context.canvas.drawRect(offset & size, paint);

      // Draw error text
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '⚠ Render Error',
          style: TextStyle(color: Color(0xFFFF0000), fontSize: 12),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(context.canvas, offset + const Offset(8, 8));
      textPainter.dispose(); // BUG-14: must dispose to free native resources
    }
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
      _pointerDownPosition = position;

      // Start selection on PointerDown so drag tracking works immediately.
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
      final upPosition = event.localPosition;
      final downPosition = _pointerDownPosition;
      _pointerDownPosition = null;
      _selectionStartPosition = null;

      // Fire link tap on PointerUp only when the finger hasn't moved (tap, not drag).
      // Threshold: 8 logical pixels — small enough to feel instant, large enough
      // to ignore micro-jitter on touch screens.
      const tapThreshold = 8.0;
      final isTap = downPosition == null ||
          (upPosition - downPosition).distance < tapThreshold;

      if (isTap && onLinkTap != null) {
        final clickedFragment = _findFragmentAtPosition(upPosition);
        if (clickedFragment != null) {
          // Walk up the UDT parent chain to find the nearest <a> ancestor.
          // The fragment's sourceNode is always a TextNode or AtomicNode — it
          // is never the InlineNode for <a> itself.
          UDTNode? node = clickedFragment.sourceNode;
          while (node != null) {
            if (node.tagName == 'a') {
              final href = node.attributes['href'];
              if (href != null) {
                onLinkTap!(href);
              }
              break;
            }
            node = node.parent;
          }
        }
      }

      // Notify selection changed when user finishes drag-selection.
      if (_selection != null && !_selection!.isCollapsed) {
        _notifySelectionChanged();
      }
    }

    super.handleEvent(event, entry);
  }

  // ============================================
  // Accessibility (Semantics)
  // ============================================

  @override
  bool get isRepaintBoundary => true;

  // ============================================
  // Debug / DevTools API
  // ============================================

  /// Serialize the current UDT document tree to JSON-compatible maps.
  /// Used by the HyperRender DevTools extension.
  List<Map<String, dynamic>> debugUdtTree() {
    final doc = _document;
    if (doc == null) return [];
    return [_serializeNode(doc)];
  }

  /// Serialize current fragment list to JSON-compatible maps.
  List<Map<String, dynamic>> debugFragments() {
    return _fragments.map((f) {
      return <String, dynamic>{
        'type': f.type.name,
        'text': f.text,
        'width': f.measuredSize?.width,
        'height': f.measuredSize?.height,
        'offsetX': f.offset?.dx,
        'offsetY': f.offset?.dy,
        'nodeId': f.sourceNode.id,
        'nodeTag': f.sourceNode.tagName,
      };
    }).toList();
  }

  /// Serialize current line list to JSON-compatible maps.
  List<Map<String, dynamic>> debugLines() {
    return _lines.map((l) {
      return <String, dynamic>{
        'fragmentCount': l.fragments.length,
        'top': l.top,
        'baseline': l.baseline,
        'width': l.width,
        'height': l.height,
      };
    }).toList();
  }

  Map<String, dynamic> _serializeNode(UDTNode node) {
    return {
      'id': node.id,
      'type': node.type.name,
      'tagName': node.tagName,
      'childCount': node.children.length,
      'children': node.children.map(_serializeNode).toList(),
    };
  }

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

  BoxFit _getBoxFit(String? cssValue) {
    if (cssValue == null) return BoxFit.cover;
    switch (cssValue.toLowerCase().trim()) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'none':
        return BoxFit.none;
      case 'scale-down':
        return BoxFit.scaleDown;
      case 'fit-width':
        return BoxFit.fitWidth;
      case 'fit-height':
        return BoxFit.fitHeight;
      case 'cover':
      default:
        return BoxFit.cover;
    }
  }
}
