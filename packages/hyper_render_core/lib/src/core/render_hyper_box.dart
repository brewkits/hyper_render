import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../model/computed_style.dart';
import '../model/fragment.dart';
import '../model/fragment_types.dart';
import '../model/node.dart';
import '../interfaces/selection_types.dart';
import '../layout/layout_engines.dart';
import 'image_provider.dart';
import 'kinsoku_processor.dart';
import 'render_config.dart';
import 'production_monitor.dart'; // Week 3-4: Production validation monitoring

part 'render_hyper_box_types.dart';
part 'render_hyper_box_fragments.dart';
part 'render_hyper_box_layout.dart';
part 'render_hyper_box_layout_engines.dart';
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
  /// Uses LRU cache with max entries configured via [HyperRenderConfig.textPainterCacheMaxEntries].
  /// The LRU eviction ensures memory stays bounded while keeping frequently used painters.
  late final _LruCache<int, TextPainter> _textPainters = _LruCache(
    maxSize: HyperRenderConfig.textPainterCacheMaxEntries,
    onEvict: (painter) => painter.dispose(),
  );

  /// Last collapsed margin (for margin collapsing between blocks)
  double _lastBlockMarginBottom = 0;

  /// Inline decorations for painting backgrounds/borders
  final List<_InlineDecoration> _inlineDecorations = [];

  /// Block decorations for painting border-left, backgrounds
  final List<_BlockDecoration> _blockDecorations = [];

  /// Image cache — LinkedHashMap preserves insertion order for LRU eviction
  final LinkedHashMap<String, CachedImage> _imageCache = LinkedHashMap();

  /// Total bytes of loaded images currently in cache
  int _imageCacheBytes = 0;

  /// Maximum image cache size, driven by [HyperRenderConfig.imageCacheMaxMb].
  static int get _imageCacheMaxBytes =>
      HyperRenderConfig.imageCacheMaxMb * 1024 * 1024;

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

  /// Callback when selection changes (receives current selection, may be null when cleared)
  void Function(HyperTextSelection?)? onSelectionChanged;

  /// Track list item indices for ordered lists
  final Map<UDTNode, int> _listItemIndices = {};

  /// Custom selection menu actions builder
  List<SelectionMenuAction> Function(SelectionOverlayController)? selectionMenuActionsBuilder;

  /// Custom color for selection handles
  Color? _selectionHandleColor;
  Color? get selectionHandleColor => _selectionHandleColor;
  set selectionHandleColor(Color? value) {
    if (_selectionHandleColor == value) return;
    _selectionHandleColor = value;
    markNeedsPaint();
  }

  /// Custom color for selected text background
  Color? _selectionColor;
  Color? get selectionColor => _selectionColor;
  set selectionColor(Color? value) {
    if (_selectionColor == value) return;
    _selectionColor = value;
    markNeedsPaint();
  }

  /// Whether to show layout boundaries for debugging
  bool _debugShowHyperRenderBounds;
  bool get debugShowHyperRenderBounds => _debugShowHyperRenderBounds;
  set debugShowHyperRenderBounds(bool value) {
    if (_debugShowHyperRenderBounds == value) return;
    _debugShowHyperRenderBounds = value;
    markNeedsPaint();
  }

  /// Fragment range for efficient character lookup
  final List<(int, int, Fragment)> _fragmentRanges = []; // (startIndex, endIndex, fragment)

  /// Current viewport clip bounds used for paint-time culling.
  /// Null means culling is disabled (e.g., in tests where no clip layer is pushed).
  Rect? _paintClipBounds;

  // ── Incremental layout dirty tracking ─────────────────────────────────────
  int _fragmentsVersion = 0;
  int _linesFragmentsVersion = -1;
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
    HyperLinkTapCallback? onLinkTap,
    HyperImageLoader? imageLoader,
    bool selectable = true,
    this.onSelectionChanged,
    List<SelectionMenuAction> Function(SelectionOverlayController)? selectionMenuActionsBuilder,
    Color? selectionHandleColor,
    Color? selectionColor,
    bool debugShowHyperRenderBounds = false,
  })  : _document = document,
        _baseStyle = baseStyle,
        onLinkTap = onLinkTap,
        _imageLoader = imageLoader,
        _selectable = selectable,
        selectionMenuActionsBuilder = selectionMenuActionsBuilder,
        _selectionHandleColor = selectionHandleColor,
        _selectionColor = selectionColor,
        _debugShowHyperRenderBounds = debugShowHyperRenderBounds;

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
    // BUG-E FIX: Dispose GPU images before clearing cache to prevent leaks
    _disposeImages();
    if (attached) {
      _loadImages();
    }
  }

  HyperTextSelection? get selection => _selection;
  set selection(HyperTextSelection? value) {
    if (_selection == value) return;
    _selection = value;
    markNeedsPaint();
    onSelectionChanged?.call(_selection);
  }

  /// Notify selection changed (call after modifying _selection directly)
  void _notifySelectionChanged() {
    // BUG-B FIX: Guard with attached check. Selection events can fire during
    // the dispose sequence (e.g., an ongoing pointer gesture that completes
    // after the widget is removed). Calling onSelectionChanged after detach
    // can trigger setState on a disposed widget.
    if (!attached) return;
    onSelectionChanged?.call(_selection);
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
    _disposeImages();
    super.dispose();
  }

  void _disposeTextPainters() {
    // LRU cache will call dispose on each painter via onEvict callback
    _textPainters.clear();
  }

  void _disposeImages() {
    // BUG-C FIX: ui.Image is a native GPU resource that must be explicitly
    // disposed. Calling clear() without dispose() leaks GPU texture memory
    // that the Dart GC cannot free.
    for (final entry in _imageCache.values) {
      entry.image?.dispose();
    }
    _imageCache.clear();
    _imageCacheBytes = 0;
  }

  /// Evict the oldest cached images until total bytes <= _imageCacheMaxBytes.
  /// Called after each successful image load to enforce the LRU size limit.
  void _evictImageCacheIfNeeded(int addedBytes) {
    _imageCacheBytes += addedBytes;
    while (_imageCacheBytes > _imageCacheMaxBytes && _imageCache.isNotEmpty) {
      final eldest = _imageCache.keys.first;
      final evicted = _imageCache.remove(eldest);
      if (evicted?.image != null) {
        final img = evicted!.image!;
        final evictedBytes = img.width * img.height * 4;
        _imageCacheBytes = (_imageCacheBytes - evictedBytes).clamp(0, _imageCacheBytes);
        img.dispose();
      }
    }
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
    // BUG-9 FIX: Clear list item indices so ordered list numbering resets
    // correctly when the document changes (e.g., items added/removed).
    _listItemIndices.clear();
    _disposeTextPainters();
  }

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
    // BUG-9 FIX: Also clear here so image-dimension change doesn't carry over
    // stale ordered list counters.
    _listItemIndices.clear();
    // _textPainters intentionally preserved
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
        // Enforce LRU 50MB cap after each successful image load
        _evictImageCacheIfNeeded(image.width * image.height * 4);
        _invalidateFragments();
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

    try {
      _maxWidth = constraints.maxWidth;

      // Step 1: Tokenization — rebuilds only if _fragments was cleared.
      _ensureFragments();

      // Step 1.5: Link children to fragments (CRITICAL)
      _linkChildrenToFragments();

      // Steps 2–6: Skipped when fragments and constraint width are unchanged.
      final bool needsLineLayout = _linesFragmentsVersion != _fragmentsVersion ||
          _linesMaxWidth != _maxWidth ||
          _lines.isEmpty;

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

      // Cache the estimated clip bounds for viewport culling in paint helpers.
      // estimatedBounds.isEmpty means no clip layer — disable culling (tests/goldens).
      final eb = context.estimatedBounds;
      _paintClipBounds = eb.isEmpty ? null : eb;

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
    } catch (e, stack) {
      // Error boundary: Catch paint errors to prevent full app crash
      debugPrint('HyperRender paint error: $e');
      debugPrintStack(stackTrace: stack);

      // Fallback: Paint error indicator (red box) to show something went wrong
      final paint = Paint()
        ..color = const Color(0x33FF0000) // Semi-transparent red
        ..style = PaintingStyle.fill;
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

      // Check for link tap — walk the ancestor chain because text fragments
      // use TextNode as sourceNode (tagName '#text'), not the parent <a> node.
      final clickedFragment = _findFragmentAtPosition(position);
      if (clickedFragment != null) {
        UDTNode? node = clickedFragment.sourceNode;
        while (node != null) {
          if (node.tagName == 'a') {
            final href = node.attributes['href'];
            if (href != null && onLinkTap != null) {
              onLinkTap!(href);
              return;
            }
            break; // Found <a> but no href — stop walking.
          }
          node = node.parent;
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

  // ============================================
  // Accessibility (Semantics)
  // ============================================

  @override
  bool get isRepaintBoundary => true;

  /// Builds semantic information for accessibility tools (TalkBack, VoiceOver)
  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    // Mark as semantics boundary - we handle our own semantic children
    config.isSemanticBoundary = true;

    // Enable text-based semantics
    config.textDirection = TextDirection.ltr;

    // If selectable, expose text selection actions
    if (_selectable && _selection != null && !_selection!.isCollapsed) {
      config.isSelected = true;
      config.value = getSelectedText() ?? '';
    }

    // Build the full text content for this render object
    final textContent = _buildTextContentForSemantics();
    if (textContent.isNotEmpty) {
      config.label = textContent;
      config.isReadOnly = true;
    }
  }

  /// Assembles semantic nodes for complex content (links, images, headings)
  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    // First, let the parent do its work with child widgets (images, tables, etc.)
    super.assembleSemanticsNode(node, config, children);

    // Now add semantic nodes for our inline content
    final semanticChildren = <SemanticsNode>[];

    // Process the document tree to extract semantic information
    if (_document != null) {
      _buildSemanticNodes(_document!, semanticChildren, node);
    }

    // Add any children from child render objects (images, tables, etc.)
    for (final child in children) {
      semanticChildren.add(child);
    }

    // Update the node with all children
    if (semanticChildren.isNotEmpty) {
      node.updateWith(
        config: config,
        childrenInInversePaintOrder: semanticChildren,
      );
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
