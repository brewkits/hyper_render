import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint, defaultTargetPlatform, kDebugMode, TargetPlatform;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../model/computed_style.dart';
import '../model/fragment.dart';
import '../model/node.dart';
import 'hyper_render_config.dart';
import 'hyper_render_debug_hooks.dart';
import 'image_provider.dart';
import 'kinsoku_processor.dart';
import 'lazy_image_queue.dart';

part 'render_hyper_box_types.dart';
part 'render_hyper_box_fragments.dart';
part 'render_hyper_box_layout.dart';
part 'render_hyper_box_paint.dart';
part 'render_hyper_box_selection.dart';
part 'render_hyper_box_accessibility.dart';

// ── Library-level cached Paint objects ────────────────────────────────────────
//
// These paints have fixed colors AND fixed properties so a single instance is
// shared across all RenderHyperBox instances. Declared at library scope so
// part files (render_hyper_box_paint.dart) can access them without any class
// qualifier. Safe because Flutter's rendering pipeline is single-threaded and
// paint() is never re-entrant.

/// Empty paint used for `canvas.saveLayer` calls (backdrop-filter / CSS filter).
final Paint _sLayerPaint = Paint();

// Skeleton placeholder:
final Paint _skeletonBasePaint = Paint()
  ..color = const Color(0xFFEEEEEE)
  ..isAntiAlias = true;
final Paint _skeletonBorderPaint = Paint()
  ..color = const Color(0xFFE0E0E0)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.0
  ..isAntiAlias = true;
final Paint _skeletonIndicatorPaint = Paint()
  ..color = const Color(0xFFE0E0E0)
  ..isAntiAlias = true;

/// Shimmer highlight — [shader] is replaced each frame; the Paint wrapper is reused.
final Paint _shimmerHighlightPaint = Paint()..isAntiAlias = true;

// Error placeholder:
final Paint _errorBgPaint = Paint()
  ..color = const Color(0xFFFAFAFA)
  ..isAntiAlias = true;
final Paint _errorBorderPaint = Paint()
  ..color = const Color(0xFFE0E0E0)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.0
  ..isAntiAlias = true;
final Paint _errorFramePaint = Paint()
  ..color = const Color(0xFFD1D5DB)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.5
  ..isAntiAlias = true;
final Paint _errorSlashPaint = Paint()
  ..color = const Color(0xFFF87171)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.5
  ..strokeCap = StrokeCap.round
  ..isAntiAlias = true;

// ─────────────────────────────────────────────────────────────────────────────
// Compiled-once regex constants for hot paths in RenderHyperBox.
// Using a library-level final avoids re-compiling the DFA on every call.
final _kWhitespaceSplitter = RegExp(r'\s+');

// ─────────────────────────────────────────────────────────────────────────────

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

  /// Engine configuration — tunable cache sizes, concurrency, chunk size.
  /// Defaults to [HyperRenderConfig.defaults] (5000 TextPainters, 3 concurrent
  /// image loads, 6000-char virtualization chunks).
  HyperRenderConfig _config;

  /// Text painters cache. Size driven by [HyperRenderConfig.textPainterCacheSize].
  /// The LRU eviction calls [TextPainter.dispose] so native resources are freed.
  late final _LruCache<int, TextPainter> _textPainters = _LruCache(
    maxSize: _config.textPainterCacheSize,
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

  /// LRU image cache — bounded by [HyperRenderConfig.imageCacheSize].
  ///
  /// Evicting an entry calls [ui.Image.dispose] to release the GPU texture.
  /// If a paint pass requests a URL that was evicted, [_paintImage] shows a
  /// shimmer and schedules a re-fetch via [addPostFrameCallback].
  late final _LruCache<String, CachedImage> _imageCache = _LruCache(
    maxSize: _config.imageCacheSize,
    onEvict: (ci) => ci.image?.dispose(),
  );

  /// Shimmer animation state.
  /// [_shimmerEpoch] marks when animation started; null = not animating.
  /// [_shimmerCallbackId] holds the pending [SchedulerBinding] frame callback
  /// id so we can cancel it in [dispose] to avoid callbacks on dead objects.
  Duration? _shimmerEpoch;
  int? _shimmerCallbackId;

  /// Returns a 0.0→1.0 phase value that advances with time, looping every
  /// [periodMs] milliseconds. Returns 0.0 when no loading is happening.
  /// Used by [_paintSkeletonPlaceholder] to animate the shimmer sweep.
  double get _shimmerPhase {
    final epoch = _shimmerEpoch;
    if (epoch == null) return 0.0;
    final elapsed = SchedulerBinding.instance.currentFrameTimeStamp - epoch;
    const periodMs = 1400.0; // 1.4 s per sweep — matches Material skeleton speed
    return (elapsed.inMicroseconds / 1000.0 % periodMs) / periodMs;
  }

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

  /// When false, skips `canvas.saveLayer` for `backdrop-filter` and CSS
  /// `filter` effects. Disable on low-end devices or when profiling shows
  /// excessive rasterization cost from complex filters.
  bool enableComplexFilters = true;

  /// When true, suppresses the top margin of the first block element in
  /// this render box. Used in virtualized mode where each section is a
  /// separate RenderHyperBox — without suppression, the last block margin of
  /// section N and the first block margin of section N+1 both render in full,
  /// producing double-spacing at section boundaries instead of CSS margin
  /// collapsing.
  bool _suppressFirstBlockMarginTop = false;
  bool get suppressFirstBlockMarginTop => _suppressFirstBlockMarginTop;
  set suppressFirstBlockMarginTop(bool value) {
    if (_suppressFirstBlockMarginTop == value) return;
    _suppressFirstBlockMarginTop = value;
    _invalidateLayout();
    markNeedsLayout();
  }

  /// Track list item indices for ordered lists
  final Map<UDTNode, int> _listItemIndices = {};

  /// Fragment range for efficient character lookup
  final List<(int, int, Fragment)> _fragmentRanges =
      []; // (startIndex, endIndex, fragment)

  /// Maps fragment → its linked child RenderBox for O(1) paint-time lookup.
  /// Rebuilt at the end of [_layoutChildren]; cleared by [_invalidateLayout].
  final Map<Fragment, RenderBox> _fragmentChildMap = {};

  /// Maps CSS `id` attribute values → their y-offset within this RenderObject.
  /// Populated during [_performLineLayout]; cleared by [_invalidateLayout].
  /// Consumed by [HyperViewerController.scrollToId].
  final Map<String, double> anchorOffsets = {};

  /// Heading anchors collected during [_performLineLayout].
  /// Each entry: `(level, text, cssId-or-null, yOffset)`.
  /// Cleared by [_invalidateLayout].
  final List<({int level, String text, String? cssId, double yOffset})>
      headingAnchors = [];

  /// Called after each layout pass with the updated [anchorOffsets] and
  /// [headingAnchors]. Consumers (e.g. [HyperViewerController]) use this to
  /// build scroll-to-id and TOC features.
  void Function(
    Map<String, double> offsets,
    List<({int level, String text, String? cssId, double yOffset})> headings,
  )? onAnchorLayout;

  /// Cached semantic nodes for headings and links.
  ///
  /// Reusing the same [SemanticsNode] objects across [assembleSemanticsNode]
  /// calls avoids the parentDataDirty assertion that fires in debug mode when
  /// newly created nodes are adopted by [SemanticsNode.updateWith].
  /// Modelled after the same pattern in Flutter's [RenderParagraph].
  final List<SemanticsNode> _cachedSemanticAnchorNodes = [];

  // ── Per-instance cached Paint objects ─────────────────────────────────────
  //
  // paint() runs at 60 fps during scrolling/animations. Allocating Paint()
  // inside the loop body generates GC pressure: a typical document with 10+
  // code blocks / blockquotes / tables creates 25-40 Paint objects per frame.
  // Solution: mutate a small set of cached instances instead.
  //
  // Instance fields are used for paints whose color/strokeWidth vary per draw.
  // Library-level constants (see top of file) cover paints with fixed properties.

  /// Reusable fill paint. Set `.color` (and optionally `.shader`) before use.
  final Paint _fillPaint = Paint()..isAntiAlias = true;

  /// Reusable stroke paint. Set `.color`, `.strokeWidth`, `.strokeCap` before
  /// use. `style` is always `PaintingStyle.stroke`.
  final Paint _strokePaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke;

  // ── Incremental layout dirty tracking ─────────────────────────────────────
  /// Bumped each time _fragments is rebuilt (via _ensureFragments).
  /// Line layout skips when this matches [_linesFragmentsVersion] AND
  /// [_linesMaxWidth] equals the current constraint width.
  int _fragmentsVersion = 0;

  /// The [_fragmentsVersion] value when _lines was last successfully built.
  int _linesFragmentsVersion = -1;

  /// The [_maxWidth] value when _lines was last successfully built.
  double _linesMaxWidth = double.nan;

  /// Default placeholder width for images without known dimensions.
  /// Driven by [HyperRenderConfig.defaultImagePlaceholderWidth].
  double get _defaultImageWidth => _config.defaultImagePlaceholderWidth;

  // Note: default height is computed from width / aspect ratio
  static const double _defaultAspectRatio = 16.0 / 9.0;

  /// Ruby annotation size ratio (furigana is typically 50% of base text)
  static const double rubyFontSizeRatio = 0.5;

  /// Gap between ruby text and base text
  static const double rubyGap = 2.0;

  /// Default float size when not specified in CSS
  static const double defaultFloatSize = 100.0;

  /// Stable identifier for this renderer instance.
  ///
  /// Used by [HyperRenderDebugHooks] so DevTools can address a specific
  /// renderer across layout passes.  Based on identity hash so it never
  /// changes for the lifetime of this object.
  late final String _debugId = 'r${identityHashCode(this).toRadixString(16)}';

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
    HyperRenderConfig config = HyperRenderConfig.defaults,
  })  : _document = document,
        _baseStyle = baseStyle,
        _imageLoader = imageLoader,
        _selectable = selectable,
        _textDirection = textDirection,
        _selectionColor = selectionColor,
        _config = config {
    // Apply image concurrency from config to the global queue.
    // The queue is a singleton; last writer wins — set once per widget tree
    // via HyperViewer.renderConfig to avoid conflicts.
    LazyImageQueue.instance.maxConcurrent = config.imageConcurrency;
  }

  // ============================================
  // Properties
  // ============================================

  DocumentNode? get document => _document;
  set document(DocumentNode? value) {
    if (_document == value) return;
    _document = value;
    // Dispose old link recognizers immediately so they don't accumulate in
    // memory until the widget is destroyed (e.g. feed apps that swap documents
    // frequently). New recognizers are created lazily in _performLineLayout.
    _disposeLinkRecognizers();
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

  HyperRenderConfig get config => _config;
  set config(HyperRenderConfig value) {
    if (_config == value) return;
    _config = value;
    LazyImageQueue.instance.maxConcurrent = value.imageConcurrency;
    // TextPainter cache size cannot be changed on an existing LRU instance
    // (the late-final field is already initialized). Changing cache size
    // requires a full layout invalidation so the cache is rebuilt next frame.
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
    if (kDebugMode) {
      HyperRenderDebugHooks.onRendererAttached?.call(_debugId, () => _document);
    }
  }

  @override
  void detach() {
    if (kDebugMode) {
      HyperRenderDebugHooks.onRendererDetached?.call(_debugId);
    }
    super.detach();
  }

  @override
  void dispose() {
    // Cancel pending shimmer frame callback to prevent callbacks on a disposed
    // RenderObject. SchedulerBinding.cancelFrameCallbackWithId is safe to call
    // with an id that has already fired (it's a no-op in that case).
    if (_shimmerCallbackId != null) {
      SchedulerBinding.instance
          .cancelFrameCallbackWithId(_shimmerCallbackId!);
      _shimmerCallbackId = null;
    }
    _disposeTextPainters();
    _disposeLinkRecognizers();
    _disposeImages();
    for (final node in _cachedSemanticAnchorNodes) {
      if (node.attached) node.detach(); // ignore: invalid_use_of_visible_for_testing_member
    }
    _cachedSemanticAnchorNodes.clear();
    super.dispose();
  }

  /// Releases in-memory caches without destroying the render object.
  ///
  /// Call this when the system signals low memory (e.g. from
  /// [WidgetsBindingObserver.didHaveMemoryPressure]). Text painters and
  /// images will be re-created on the next layout/paint pass.
  ///
  /// ```dart
  /// // In your State:
  /// @override
  /// void didHaveMemoryPressure() {
  ///   (context.findRenderObject() as RenderHyperBox?)?.clearMemoryCaches();
  /// }
  /// ```
  void clearMemoryCaches() {
    _disposeTextPainters();
    _disposeImages();
    markNeedsLayout(); // Re-measure text after cache clear
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
    // _LruCache.clear() calls onEvict on every entry, which calls
    // ci.image?.dispose().  The Dart GC cannot release the native GPU texture
    // backing a ui.Image — only dispose() does that.
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
    _fragmentChildMap.clear();

    anchorOffsets.clear();
    headingAnchors.clear();
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
  // Shimmer Animation
  // ============================================

  /// Starts the per-frame shimmer loop if not already running.
  /// Safe to call repeatedly — no-ops when already scheduled.
  void _ensureShimmerRunning() {
    if (_shimmerCallbackId != null) return;
    _shimmerCallbackId =
        SchedulerBinding.instance.scheduleFrameCallback(_onShimmerTick);
  }

  void _onShimmerTick(Duration timestamp) {
    _shimmerCallbackId = null;
    if (!attached) return;

    // Record start time on first tick.
    _shimmerEpoch ??= timestamp;

    final hasLoading =
        _imageCache.values.any((c) => c.state == ImageLoadState.loading);
    if (hasLoading) {
      markNeedsPaint();
      // Schedule the next frame to keep the animation going.
      _shimmerCallbackId =
          SchedulerBinding.instance.scheduleFrameCallback(_onShimmerTick);
    } else {
      // No more loading images — stop the loop and reset epoch.
      _shimmerEpoch = null;
    }
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
    _imageCache.put(src, const CachedImage(state: ImageLoadState.loading));
    // Start the shimmer animation loop as soon as the first image starts loading.
    if (attached) _ensureShimmerRunning();

    final loader = _imageLoader ?? defaultImageLoader;

    LazyImageQueue.instance.enqueue(
      url: src,
      priority: priority,
      loader: loader,
      onLoad: (ui.Image image) {
        if (!attached) {
          // Widget was removed from the tree while the image was loading.
          // We MUST call dispose() here — Dart GC cannot release the native GPU
          // texture backing ui.Image; only dispose() does that.  Skipping this
          // causes an unbounded GPU memory leak: each back-navigation leaks the
          // images that were still in flight.
          image.dispose();
          return;
        }
        _imageCache.put(src, CachedImage(
          image: image,
          state: ImageLoadState.loaded,
        ));
        // Invalidate fragments so _tokenizeAtomic re-reads actual image
        // dimensions. Preserves text painter cache (text metrics unchanged).
        _invalidateFragments();
        markNeedsLayout();
        markNeedsPaint();
      },
      onError: (Object error) {
        if (!attached) return;
        _imageCache.put(src, CachedImage(
          state: ImageLoadState.error,
          error: error.toString(),
        ));
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
    double maxWidth = 0;

    // ── O(F) strategy — one TextPainter call per text fragment ──────────────
    //
    // Previously this was O(W) — one layout call per word across the entire
    // document.  For a 3000-word article that means ~3000 TextPainter.layout()
    // calls synchronously on the main thread, causing 200–400 ms jank when the
    // widget is wrapped in IntrinsicWidth or DataTable.
    //
    // Key insight: the longest *measured* word is almost always the longest
    // *character-count* word.  The only edge case is a short wide-glyph run
    // ("WWW") vs a long narrow-glyph run ("iiiiiiiii"), which is negligible
    // for real prose.  By picking only the longest-by-char-count word per
    // fragment we reduce TextPainter calls from O(totalWords) to O(fragments).
    //
    // Two painters — one per text direction — are reused across all fragments
    // to avoid repeated native-object allocation.  They are NOT stored in
    // _textPainters so per-word spans don't pollute the LRU cache.
    final ltrPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final rtlPainter = TextPainter(textDirection: ui.TextDirection.rtl);

    for (final fragment in _fragments) {
      if (fragment.type == FragmentType.text && fragment.text != null) {
        final text = fragment.text!;
        // Find the single longest word by character count.  This is a
        // simple O(W) scan with no allocations beyond the split list itself,
        // far cheaper than W TextPainter.layout() calls.
        final words = text.split(_kWhitespaceSplitter);
        String longestWord = '';
        for (final w in words) {
          if (w.length > longestWord.length) longestWord = w;
        }
        if (longestWord.isEmpty) continue;

        final isRtl = fragment.style.isRtl;
        final measurePainter = isRtl ? rtlPainter : ltrPainter;
        final mergedStyle = _baseStyle.merge(fragment.style.toTextStyle());
        measurePainter.text = TextSpan(text: longestWord, style: mergedStyle);
        measurePainter.layout();
        if (measurePainter.width > maxWidth) {
          maxWidth = measurePainter.width;
        }
      } else if (fragment.type == FragmentType.atomic ||
          fragment.type == FragmentType.ruby) {
        // Ensure fragment is measured if it hasn't been already
        if (fragment.measuredSize == null) _measureFragment(fragment);
        // Guard against negative/NaN widths (e.g. unloaded image or ZWJ glyph
        // before its font is ready).
        final w = fragment.width;
        if (w.isFinite && w > maxWidth) {
          maxWidth = w;
        }
      }
    }

    ltrPainter.dispose();
    rtlPainter.dispose();

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
        // Guard against negative or NaN widths that can arise when a ZWJ
        // sequence is measured before its font is loaded, or when an atomic
        // fragment has not yet received its intrinsic size from the image
        // decoder.  Such values would produce garbage (negative) results that
        // confuse IntrinsicWidth parents and trigger assertion failures.
        final w = fragment.width;
        if (w.isFinite && w > 0) lineWidth += w;
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
    _performLineLayout(intrinsicMode: true);

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

      // Step 1.5: Link children to fragments, then immediately build the O(1)
      // lookup map so that _performLineLayout (Step 3) can call
      // _findChildForFragment in O(1) rather than falling through to the O(M)
      // linear scan.  Without the early _buildFragmentChildMap() call the map
      // was empty until _layoutChildren (Step 7) finished, causing every flex/
      // table/image lookup during line layout to scan the full child list.
      _linkFragmentsToChildrenByOrder();
      _buildFragmentChildMap();

      // Steps 2–6: Measure + line layout.
      // Run full line layout (including text measurement) only when document
      // content or constraint width has changed.  A <details> expand/collapse
      // only changes block heights — text fragments are untouched — so
      // _measureFragments() can be skipped for those frames.
      final bool fragmentsOrWidthChanged =
          _linesFragmentsVersion != _fragmentsVersion ||
          _linesMaxWidth != _maxWidth ||
          _lines.isEmpty;
      final bool hasDetailsFragments =
          _fragments.any((f) => f is _DetailsFragment);

      if (fragmentsOrWidthChanged) {
        // Full rebuild: text or constraint width changed.
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
      } else if (hasDetailsFragments) {
        // A details child changed height (each animation frame during
        // expand/collapse).  Re-run line layout to update block y-offsets, but
        // skip _measureFragments() — TextPainter output is identical because
        // text content and constraint width are both unchanged.
        _performLineLayout();
        _positionFragments();
        _buildInlineDecorations();
        _buildCharacterMapping();
      }

      // Step 7: Layout child RenderBoxes (always — child constraints may change)
      _layoutChildren();

      // Calculate final size
      double height = 0;
      if (_lines.isNotEmpty) {
        final lastLine = _lines.last;
        height = lastLine.top + lastLine.height;
      }

      // Block-level widgets (details, tables, code blocks, flex/grid containers)
      // update currentY but don't push a line.  When the content consists
      // ENTIRELY of such blocks _lines stays empty and height stays 0.
      // Extend height from fragment offsets + sizes for these block types.
      for (final fragment in _fragments) {
        if (fragment is _DetailsFragment ||
            fragment is _TableFragment ||
            fragment is _CodeBlockFragment ||
            fragment is _FlexFragment) {
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

      // Notify anchor/TOC consumers after layout is complete.
      if (onAnchorLayout != null &&
          (anchorOffsets.isNotEmpty || headingAnchors.isNotEmpty)) {
        onAnchorLayout!(
          Map.unmodifiable(anchorOffsets),
          List.unmodifiable(headingAnchors),
        );
      }

      // Notify DevTools of layout completion (debug mode only, no-op if no
      // listener is registered — HyperRenderDebugHooks.onLayoutComplete is
      // null in release builds and when devtools is not initialised).
      if (kDebugMode) {
        HyperRenderDebugHooks.onLayoutComplete?.call(
          _debugId,
          debugFragments,
          debugLines,
        );
      }
    } catch (e, stack) {
      // Error boundary: prevent full app crash, but report to Flutter framework
      // so Crashlytics / Sentry / FlutterError.onError can capture it.
      FlutterError.reportError(FlutterErrorDetails(
        exception: e,
        stack: stack,
        library: 'HyperRender',
        context: ErrorDescription('during performLayout() in RenderHyperBox'),
      ));

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
      if (_selection != null &&
          _selection!.isValid &&
          !_selection!.isCollapsed) {
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
      // Error boundary: prevent full app crash, but report to Flutter framework
      // so Crashlytics / Sentry / FlutterError.onError can capture it.
      FlutterError.reportError(FlutterErrorDetails(
        exception: e,
        stack: stack,
        library: 'HyperRender',
        context: ErrorDescription('during paint() in RenderHyperBox'),
      ));

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
          final hadSelection = _selection != null && !_selection!.isCollapsed;
          _selection = HyperTextSelection(start: start, end: end);
          // Trigger selection haptic on the first frame a non-collapsed
          // selection appears — matches iOS "selection click" and Android
          // vibration patterns for text selection initiation.
          if (!hadSelection && !_selection!.isCollapsed) {
            HapticFeedback.selectionClick();
          }
          markNeedsPaint();
        }
      }
    } else if (event is PointerUpEvent) {
      final upPosition = event.localPosition;
      final downPosition = _pointerDownPosition;
      _pointerDownPosition = null;
      _selectionStartPosition = null;

      // Fire link tap on PointerUp only when the finger hasn't moved (tap, not drag).
      //
      // Use Flutter's computeHitSlop() instead of a hardcoded pixel constant so
      // the threshold automatically matches platform gesture physics:
      //   - Mouse/trackpad: kPrecisePointerHitSlop  (1.0 px — very precise)
      //   - Touch:          DeviceGestureSettings.touchSlop ?? kTouchSlop (18.0)
      //   - Stylus:         same as touch by default
      // A hardcoded 8.0 was too tight for some touch screens (missed taps) and
      // too loose for mouse clicks (stray drags triggered taps).
      final tapSlop = computeHitSlop(
        event.kind,
        // DeviceGestureSettings is only available via MediaQuery in widget
        // context; pass null so computeHitSlop falls back to kTouchSlop (18 px)
        // for touch/stylus and kPrecisePointerHitSlop (1 px) for mouse.
        null,
      );
      final isTap = downPosition == null ||
          (upPosition - downPosition).distance < tapSlop;

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
                // Scheme security: always block javascript:, data:, file: etc.
                // The built-in safe set covers standard web links; apps can add
                // their own deep-link schemes via HyperRenderConfig.extraLinkSchemes
                // (e.g. 'myapp', 'shopee', 'fb', 'momo').
                const builtinSchemes = {'http', 'https', 'mailto', 'tel'};
                final scheme =
                    Uri.tryParse(href)?.scheme.toLowerCase() ?? '';
                final allowed = builtinSchemes.contains(scheme) ||
                    _config.extraLinkSchemes.contains(scheme);
                if (allowed) {
                  onLinkTap!(href);
                } else if (kDebugMode) {
                  debugPrint(
                    '[HyperRender] Blocked link tap — scheme "$scheme" not in '
                    'built-in set or HyperRenderConfig.extraLinkSchemes: $href',
                  );
                }
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
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..label = _buildTextContentForSemantics()
      ..textDirection = _textDirection;
  }

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    // Build semantic nodes for headings (h1–h6) and links (<a href>).
    //
    // These two element types are the primary WCAG 2.1 AA requirements for
    // a read-only renderer:
    //   • Headings: TalkBack/VoiceOver "swipe to next heading" navigation
    //   • Links:    double-tap to activate via the accessibility service
    //
    // Regular paragraph text is announced via the flat `label` set in
    // describeSemanticsConfiguration and does not need per-fragment nodes.
    //
    // We reuse the same SemanticsNode objects across calls (pooled in
    // _cachedSemanticAnchorNodes) instead of creating new ones every frame.
    // This mirrors the pattern used by Flutter's own RenderParagraph: newly
    // created SemanticsNodes get parentDataDirty=true when adopted, which
    // fires an assertion in flushSemantics() in debug mode.
    final anchors = _collectSemanticAnchors();
    final pool = List<SemanticsNode>.of(_cachedSemanticAnchorNodes);
    final newCache = <SemanticsNode>[];

    for (final anchor in anchors) {
      // Reuse a pooled node when available; only allocate a new one if needed.
      final semanticsNode = pool.isNotEmpty ? pool.removeAt(0) : SemanticsNode();
      newCache.add(semanticsNode);

      final cfg = SemanticsConfiguration()
        ..textDirection = _textDirection
        ..label = anchor.label;

      if (anchor.isHeading) {
        cfg.isHeader = true;
      } else {
        cfg.isLink = true;
        final href = anchor.href;
        if (href != null && onLinkTap != null) {
          cfg.onTap = () {
            // Reuse the same scheme-allow-list logic as pointer events.
            const builtinSchemes = {'http', 'https', 'mailto', 'tel'};
            final scheme = Uri.tryParse(href)?.scheme.toLowerCase() ?? '';
            if (builtinSchemes.contains(scheme) ||
                _config.extraLinkSchemes.contains(scheme)) {
              onLinkTap!(href);
            }
          };
        }
      }

      semanticsNode
        ..rect = anchor.rect
        ..updateWith(config: cfg, childrenInInversePaintOrder: const []);
    }

    // Detach any surplus cached nodes (document shrank or anchor count dropped).
    for (final stale in pool) {
      if (stale.attached) stale.detach(); // ignore: invalid_use_of_visible_for_testing_member
    }
    _cachedSemanticAnchorNodes
      ..clear()
      ..addAll(newCache);

    node.updateWith(
      config: config,
      // Anchors first (painted below child widgets), then child RenderObjects
      // (HyperDetailsWidget, HyperTable, CodeBlockWidget, etc.).
      childrenInInversePaintOrder: [
        ..._cachedSemanticAnchorNodes.reversed,
        ...children,
      ],
    );
  }

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
