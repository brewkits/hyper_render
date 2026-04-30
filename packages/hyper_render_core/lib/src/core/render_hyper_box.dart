import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

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

  /// Tunable cache sizes, concurrency, chunk size.
  HyperRenderConfig _config;

  /// Internal cache for TextPainters shared across instances to minimize memory usage.
  static final _LruCache<_TextPainterKey, TextPainter> _globalTextPainters =
      _LruCache(
    maxSize: 500, // Fixed global cap
    onEvict: (painter) => painter.dispose(),
  );

  /// Reference to the cache being used.
  _LruCache<_TextPainterKey, TextPainter> get _textPainters =>
      _globalTextPainters;

  /// Last collapsed margin (for margin collapsing between blocks)
  double _lastBlockMarginBottom = 0;

  /// Inline decorations for painting backgrounds/borders
  final List<_InlineDecoration> _inlineDecorations = [];

  /// Block decorations for painting border-left, backgrounds
  final List<_BlockDecoration> _blockDecorations = [];

  /// LRU image cache — bounded by [HyperRenderConfig.imageCacheSize].
  ///
  /// Evicting an entry removes it from the local cache without manually 
  /// disposing the `ui.Image`. Disposing an image that is currently in 
  /// the engine's rendering queue causes a fatal native crash. 
  /// The Dart GC and Flutter's ImageCache handle actual cleanup.
  late final _LruCache<String, CachedImage> _imageCache = _LruCache(
    maxSize: _config.imageCacheSize,
  );

  /// Subscription tokens returned by [LazyImageQueue.enqueue].
  /// Cancelled in [_disposeImages] so in-flight callbacks are dropped safely.
  final Set<int> _imageTokens = {};

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
    const periodMs =
        1400.0; // 1.4 s per sweep — matches Material skeleton speed
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

  /// Cumulative character count at the start of each line.
  ///
  /// `_lineStartOffsets[i]` is the number of text/ruby characters that
  /// appear in all lines *before* line `i`.  Built by [_buildCharacterMapping]
  /// after every layout; used by [_getCharacterPositionAtOffset] to avoid
  /// scanning all preceding lines when the user drags a selection handle
  /// (O(log N) binary-search instead of O(N) linear scan).
  final List<int> _lineStartOffsets = [];

  /// Color for text selection highlight
  Color? _selectionColor;

  /// Callback when selection changes
  VoidCallback? onSelectionChanged;

  /// When true, draws colored outlines over each fragment/line for debugging.
  /// Equivalent to Flutter's [debugPaintSizeEnabled] but scoped to this widget.
  bool debugShowBounds = false;

  // ── Plugin registry tag sets ───────────────────────────────────────────────
  //
  // Copied from [HyperPluginRegistry] when a registry is provided.  Stored as
  // plain [Set<String>] so the render object has no direct dependency on the
  // plugin registry class (avoids circular imports with the interfaces layer).
  //
  // Empty const sets are shared singletons — no allocation cost when no
  // plugins are registered.

  /// Tag names handled by **block-tier** plugins (full-width widget).
  Set<String> _blockPluginTags = const {};
  Set<String> get blockPluginTags => _blockPluginTags;
  set blockPluginTags(Set<String> value) {
    if (_blockPluginTags == value) return;
    _blockPluginTags = value;
    _invalidateLayout();
    markNeedsLayout();
  }

  /// Tag names handled by **inline-tier** plugins (inline widget).
  Set<String> _inlinePluginTags = const {};
  Set<String> get inlinePluginTags => _inlinePluginTags;
  set inlinePluginTags(Set<String> value) {
    if (_inlinePluginTags == value) return;
    _inlinePluginTags = value;
    _invalidateLayout();
    markNeedsLayout();
  }

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

  /// Floats inherited from the previous virtualized section.
  ///
  /// When set, [_performLineLayout] seeds [_leftFloats]/[_rightFloats] from
  /// these carryovers before processing any fragments, so that text in this
  /// section wraps around floats that began in the preceding section.
  List<FloatCarryover> _initialFloats = const [];
  List<FloatCarryover> get initialFloats => _initialFloats;
  set initialFloats(List<FloatCarryover> value) {
    // Avoid spurious re-layouts when carryover list is effectively the same.
    if (value.length == _initialFloats.length &&
        identical(value, _initialFloats)) {
      return;
    }
    _initialFloats = value;
    _invalidateLayout();
    markNeedsLayout();
  }

  /// Returns floats from this section that extend below its natural text height.
  ///
  /// Pass the result to the next section's [initialFloats] so its text wraps
  /// correctly alongside the continuation of tall float elements.
  ///
  /// Returns an empty list when no floats dangle past the section boundary.
  /// Only valid to call after layout has completed.
  List<FloatCarryover> get danglingFloats {
    // Natural height = bottom of last line (before float extension).
    // If no lines were laid out (e.g. chunk only contained a float),
    // natural height is 0 and the entire float overhangs.
    final naturalHeight =
        _lines.isEmpty ? 0.0 : (_lines.last.bounds?.bottom ?? 0.0);
    final result = <FloatCarryover>[];
    for (final float in _leftFloats) {
      if (float.rect.bottom > naturalHeight) {
        result.add(FloatCarryover(
          direction: float.direction,
          width: float.rect.width,
          overhangHeight: float.rect.bottom - naturalHeight,
        ));
      }
    }
    for (final float in _rightFloats) {
      if (float.rect.bottom > naturalHeight) {
        result.add(FloatCarryover(
          direction: float.direction,
          width: float.rect.width,
          overhangHeight: float.rect.bottom - naturalHeight,
        ));
      }
    }
    return result;
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

  /// Called after each layout pass with the list of floats that overhang the
  /// bottom of this section.  Pass the result to the next section's
  /// [initialFloats] to enable cross-chunk float continuity.
  ///
  /// Receives an empty list when no floats dangle past the section boundary.
  void Function(List<FloatCarryover> carryovers)? onFloatCarryover;

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

  /// Cache available width for the current line to avoid O(N_floats) lookup
  /// for every single fragment. Only needs recalculating when currentY changes
  /// or when new floats are added to the line.
  double? _cachedAvailableWidth;

  /// List of floats added during the CURRENT line. They are kept separate
  /// so that text on the current line doesn't wrap around a float that
  /// it triggered (which would cause infinite line-wrapping loops).
  /// They are flushed to the main float lists at the end of finishLine().
  final List<_FloatArea> _pendingLineLeftFloats = [];
  final List<_FloatArea> _pendingLineRightFloats = [];

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
        _config = config;

  // ============================================
  // Properties
  // ============================================

  DocumentNode? get document => _document;
  set document(DocumentNode? value) {
    if (_document == value) return;
    _document = value;
    _invalidateLayout();
    // Trigger image loading when a document arrives after initial attach.
    // Required for the async-parse path: attach() fires _loadImages() while
    // _document is still null; when the parsed document arrives via
    // updateRenderObject we must retry so images are actually queued.
    if (attached) _loadImages();
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
    // TextPainter cache size cannot be changed on an existing LRU instance
    // (the late-final field is already initialized). Changing cache size
    // requires a full layout invalidation so the cache is rebuilt next frame.
    markNeedsLayout();
  }

  HyperImageLoader? get imageLoader => _imageLoader;
  set imageLoader(HyperImageLoader? value) {
    if (_imageLoader == value) return;
    _imageLoader = value;
    // Dispose GPU resources before clearing, then re-trigger loading with the
    // new loader so images are not left in a permanent "loading" state after
    // the loader is swapped at runtime.
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

  /// Total character count in this render box (available after first layout).
  /// Used by VirtualizedSelectionController to register chunk sizes.
  int get totalCharacterCount => _totalCharacterCount;

  /// Public wrapper for the private _getCharacterPositionAtOffset.
  /// Used by VirtualizedSelectionController to map a pointer position to a
  /// char offset within this chunk.
  int getCharacterPositionAtOffset(Offset localPosition) =>
      _getCharacterPositionAtOffset(localPosition);

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
      SchedulerBinding.instance.cancelFrameCallbackWithId(_shimmerCallbackId!);
      _shimmerCallbackId = null;
    }
    _disposeImages();
    // Do NOT call detach() on cached semantic anchor nodes here.
    // Flutter's semantics teardown already detaches them during widget
    // unmounting — calling detach() again asserts inside SemanticsOwner
    // that the node is still in _nodes, which it no longer is.
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

  void _disposeImages() {
    // Cancel all pending/in-flight subscriptions so callbacks are not invoked
    // on this (now-disposing) RenderBox. For in-flight loads the queue will
    // dispose the ui.Image itself if no other subscribers remain.
    for (final token in _imageTokens) {
      LazyImageQueue.instance.cancel(token);
    }
    _imageTokens.clear();

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
    _lineStartOffsets.clear();
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
    _lineStartOffsets.clear();
    _totalCharacterCount = 0;
    _cachedMinIntrinsicWidth = null;
    _cachedMaxIntrinsicWidth = null;
    // _textPainters intentionally preserved: text metrics are unaffected
    // by image dimension changes.
  }

  void _notifySelectionChanged() {
    // Guard with attached check: selection events can fire during the dispose
    // sequence (e.g., a pointer gesture that completes after the widget is
    // removed from the tree). Calling onSelectionChanged after detach can
    // invoke state on a disposed widget.
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

    // Use a nullable variable rather than `late final` to handle the case where
    // the image is already in Flutter's image cache: defaultImageLoader calls
    // addListener() which may deliver the onLoad callback **synchronously**,
    // before enqueue() returns and the token value is known.  When that happens
    // pendingToken is still null, so the remove() call is skipped — which is
    // correct because the token hasn't been added to _imageTokens yet.
    int? pendingToken;

    final token = LazyImageQueue.instance.enqueue(
      url: src,
      priority: priority,
      loader: loader,
      onLoad: (ui.Image image) {
        if (!attached) {
          // Safety net: token should have been cancelled by _disposeImages(),
          // but guard here in case of unusual teardown ordering.
          // Each callback receives its own clone from the queue, so disposing
          // here does not affect other viewers sharing the same URL.
          image.dispose();
          return;
        }
        _imageTokens.remove(pendingToken);
        _imageCache.put(
            src,
            CachedImage(
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
        _imageTokens.remove(pendingToken);
        _imageCache.put(
            src,
            CachedImage(
              state: ImageLoadState.error,
              error: error.toString(),
            ));
        markNeedsPaint();
      },
    );
    pendingToken = token;
    _imageTokens.add(token);
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
        String longestWord = '';

        if (KinsokuProcessor.containsCjk(text)) {
          // CJK characters can break anywhere. The minimum intrinsic width is
          // the width of the widest single character, or the longest non-CJK word.
          final words = text.split(_kWhitespaceSplitter);
          for (final w in words) {
            if (KinsokuProcessor.containsCjk(w)) {
              if (longestWord.isEmpty && w.isNotEmpty) {
                longestWord = w[0];
              }
              // Extract the longest non-CJK sequence including punctuation and fullwidth forms
              final nonCjkParts = w.split(RegExp(r'[\u4E00-\u9FFF\u3000-\u303F\u3040-\u309F\u30A0-\u30FF\uAC00-\uD7A3\uFF00-\uFFEF]'));
              for (final part in nonCjkParts) {
                 if (part.length > longestWord.length) longestWord = part;
              }
            } else {
              if (w.length > longestWord.length) longestWord = w;
            }
          }
          if (longestWord.isEmpty && text.isNotEmpty) {
            longestWord = text[0]; // fallback
          }
        } else {
          final words = text.split(_kWhitespaceSplitter);
          for (final w in words) {
            if (w.length > longestWord.length) longestWord = w;
          }
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

    final result = _lines.isEmpty ? 0.0 : _lines.last.top + _lines.last.height;

    // Invalidate the layout-version cache so that the next performLayout()
    // always re-runs _performLineLayout at the real constraint width.
    // Without this, _performLineLayout overwrites _lines at the intrinsic
    // width but leaves _linesMaxWidth / _linesFragmentsVersion pointing at
    // that intrinsic run.  If the real constraint width happens to equal the
    // intrinsic width, performLayout() sees "already up-to-date" and skips
    // the full layout — leaving _lines built in intrinsicMode (no child
    // layout calls), which causes all child widgets to be mispositioned.
    _linesMaxWidth = double.nan;
    _linesFragmentsVersion = -1;

    return result;
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

      // Step 1.7: For inline-plugin fragments the widget size is unknown at
      // tokenization time.  Now that children are linked we can query each
      // child's intrinsic dimensions and store them on the fragment so that
      // Step 2 (_measureFragments) skips them (measuredSize != null).
      if (_inlinePluginTags.isNotEmpty) {
        _measureInlinePluginFragments();
      }

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

      // Extend height to include the full float so it is never visually clipped.
      // NOTE — "wasted space" trade-off: when a float is taller than the text
      // that flows alongside it, this produces empty whitespace to the side of
      // the float's lower portion.  In a true browser (no chunking) subsequent
      // paragraphs would fill that space.  Here they can't because they live in
      // a different RenderHyperBox chunk.  The HtmlAdapter._containsFloatChild
      // heuristic reduces the occurrence by keeping float-bearing blocks and
      // their immediate successors in the same chunk.  A full cross-chunk
      // FloatCarryover (image-split across ListView items) is tracked as a
      // future improvement in ROADMAP.md.
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

      // Notify float-carryover consumer so the next virtualized section can
      // seed its float insets and avoid text overflowing a dangling float.
      final carryover = onFloatCarryover;
      if (carryover != null) {
        carryover(danglingFloats);
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
      textPainter.dispose(); // dispose to free native Skia/Impeller resources
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

  // ── Public selection API (driven by widget-layer gesture recognizers) ─────────
  //
  // Selection is no longer tracked via raw PointerMove events in handleEvent
  // because handleEvent bypasses the gesture arena — it fired during parent
  // ScrollView scrolls, creating unwanted selections on every scroll attempt.
  //
  // Instead, HyperSelectionOverlay / VirtualizedChunk use a
  // LongPressGestureRecognizer (arena-based) so the OS correctly arbitrates:
  //   • quick touch + move  → scroll wins, long-press cancelled → no selection
  //   • hold 500 ms + drag  → long-press wins, scroll frozen    → selection
  //
  // These two methods are the only entry points for selection from gestures.

  /// Anchors the selection at [localPosition].  Call from `onLongPressStart`.
  void startSelectionAt(Offset localPosition) {
    if (!_selectable) return;
    final charPos = _getCharacterPositionAtOffset(localPosition);
    if (charPos < 0) return;
    _selectionStartPosition = charPos;
    _selection = HyperTextSelection(start: charPos, end: charPos);
    markNeedsPaint();
  }

  /// Extends the selection end to [localPosition].  Call from
  /// `onLongPressMoveUpdate` and handle `onPanUpdate`.
  void extendSelectionTo(Offset localPosition) {
    if (!_selectable || _selectionStartPosition == null) return;
    final charPos = _getCharacterPositionAtOffset(localPosition);
    if (charPos < 0) return;
    final start = math.min(_selectionStartPosition!, charPos);
    final end = math.max(_selectionStartPosition!, charPos);
    final hadSelection = _selection != null && !_selection!.isCollapsed;
    _selection = HyperTextSelection(start: start, end: end);
    if (!hadSelection && !_selection!.isCollapsed) {
      HapticFeedback.selectionClick();
    }
    markNeedsPaint();
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      final position = event.localPosition;
      _pointerDownPosition = position;
      // Selection is now initiated via LongPressGestureRecognizer at the widget
      // layer (see HyperSelectionOverlay / VirtualizedChunk).  Raw PointerDown
      // no longer starts selection so that quick touch-moves go to the scroll
      // view without accidentally extending selection.
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
                final scheme = Uri.tryParse(href)?.scheme.toLowerCase() ?? '';
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
      final semanticsNode =
          pool.isNotEmpty ? pool.removeAt(0) : SemanticsNode();
      newCache.add(semanticsNode);

      final cfg = SemanticsConfiguration()
        ..textDirection = _textDirection
        ..label = anchor.label;

      if (anchor.isHeading) {
        cfg.isHeader = true;
      } else if (anchor.isImage) {
        // Image with alt text: informational node — no role flags, just label.
        // Screen readers announce the label at the image's rect position so
        // users can navigate element-by-element (WCAG 1.1.1).
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

    // Do NOT call detach() on surplus pool nodes: node.updateWith() below
    // will call _replaceChildren, which calls _dropChild → detach() for any
    // node not in the new childrenInInversePaintOrder list.  Calling detach()
    // ourselves before updateWith() would leave them half-torn-down.
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
