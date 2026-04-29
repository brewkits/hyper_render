import '../core/animation_controller.dart';
import '../interfaces/code_highlighter.dart';

/// Configuration for the HyperRender engine.
///
/// All values have production-tested defaults. Tune per device tier:
///
/// ```dart
/// // Low-end Android (≤ 2 GB RAM)
/// HyperRenderConfig(
///   textPainterCacheSize: 500,
///   imageCacheSize: 10,
///   imageConcurrency: 2,
///   virtualizationChunkSize: 3000,
/// )
///
/// // High-end / tablet
/// HyperRenderConfig(
///   textPainterCacheSize: 10000,
///   imageCacheSize: 60,
///   imageConcurrency: 6,
///   virtualizationChunkSize: 12000,
/// )
/// ```
class HyperRenderConfig {
  const HyperRenderConfig({
    this.textPainterCacheSize = 5000,
    this.imageCacheSize = 30,
    this.defaultImagePlaceholderWidth = 200.0,
    this.imageConcurrency = 3,
    this.virtualizationChunkSize = 6000,
    this.extraLinkSchemes = const {},
    this.codeHighlighter,
    this.keyframeRegistry = const {},
    this.useMicrotaskParsing = false,
  })  : assert(
            textPainterCacheSize > 0, 'textPainterCacheSize must be positive'),
        assert(imageCacheSize > 0, 'imageCacheSize must be positive'),
        assert(defaultImagePlaceholderWidth > 0,
            'defaultImagePlaceholderWidth must be positive'),
        assert(imageConcurrency > 0, 'imageConcurrency must be positive'),
        assert(
            virtualizationChunkSize >= 1000,
            'virtualizationChunkSize must be >= 1000 '
            '(smaller values cause excessive section fragmentation)');

  /// Maximum number of [TextPainter] instances kept in the LRU cache.
  ///
  /// Each entry uses ~4 KB of Dart heap. The default of 5000 (~20 MB) is
  /// suitable for novel-reader / long-article apps. Reduce on low-RAM devices.
  ///
  /// Default: 5000
  final int textPainterCacheSize;

  /// Maximum number of decoded [ui.Image] objects kept per [RenderHyperBox].
  ///
  /// Each decoded image occupies GPU texture memory proportional to its pixel
  /// dimensions (width × height × 4 bytes RGBA).  A 1920×1080 image ~8 MB;
  /// a typical article thumbnail at 800×600 ~2 MB.
  ///
  /// When the limit is exceeded the least-recently-used (LRU) image is
  /// disposed (GPU texture freed) and re-fetched on demand if it becomes
  /// visible again.  The re-fetch shows a shimmer placeholder until the
  /// image is decoded.
  ///
  /// Tune per device tier:
  /// - Low-end Android/iOS (≤ 2 GB RAM): 10–15
  /// - Standard (default):               30
  /// - High-end / tablet:                60+
  ///
  /// Default: 30
  final int imageCacheSize;

  /// Placeholder width (px) for images whose dimensions are not yet known.
  ///
  /// Used while the image is loading; the layout re-runs once real dimensions
  /// arrive. Lower values cause less layout shift; higher values reduce
  /// shimmer height jumps on images wider than the viewport.
  ///
  /// Default: 200.0
  final double defaultImagePlaceholderWidth;

  /// Maximum simultaneous image downloads from [LazyImageQueue].
  ///
  /// Increase for fast connections / high-density grids; decrease to reduce
  /// bandwidth on metered connections or slow servers.
  ///
  /// Default: 3
  final int imageConcurrency;

  /// Character count per section in [HyperRenderMode.virtualized].
  ///
  /// Each section is rendered by a separate [RenderHyperBox] inside a
  /// [RepaintBoundary], capped below GPU texture size limits (~8192 px).
  /// Lower values = more sections = smoother scroll, higher memory overhead.
  ///
  /// Default: 6000
  final int virtualizationChunkSize;

  /// Syntax-highlighting plugin for `<pre><code>` blocks.
  ///
  /// When `null` (default), code blocks are rendered as plain monospace text.
  /// Plug in `HyperHighlighter` from `hyper_render_highlight` for full 180+
  /// language support without adding that dependency to every build target.
  ///
  /// ```dart
  /// HyperRenderConfig(
  ///   codeHighlighter: HyperHighlighter(theme: HyperHighlightTheme.atomOneDark),
  /// )
  /// ```
  final CodeHighlighter? codeHighlighter;

  /// Registry of CSS keyframe animations available to the renderer.
  ///
  /// Maps `animation-name` values (as found in CSS or the `animation-name`
  /// property) to their [HyperKeyframes] definition.  [RenderHyperBox] drives
  /// each registered animation with its own `SchedulerBinding` frame callback,
  /// so no external `AnimationController` or `TickerProvider` is required.
  ///
  /// Start with the built-in presets and add your own:
  ///
  /// ```dart
  /// HyperRenderConfig(
  ///   keyframeRegistry: {
  ///     ...HyperAnimations.all,            // fadeIn, pulse, bounce, …
  ///     'heroSlide': HyperKeyframes(
  ///       name: 'heroSlide',
  ///       keyframes: [
  ///         HyperKeyframe(offset: 0.0, translateY: 40.0, opacity: 0.0),
  ///         HyperKeyframe(offset: 1.0, translateY: 0.0,  opacity: 1.0),
  ///       ],
  ///     ),
  ///   },
  /// )
  /// ```
  ///
  /// CSS `@keyframes` blocks parsed from `<style>` tags are merged into this
  /// registry by the HTML adapter when a `CssParserInterface` that supports
  /// [CssParserInterface.parseKeyframes] is provided.
  ///
  /// Default: `const {}` (no preset animations; add [HyperAnimations.all] to
  /// enable the built-in library).
  final Map<String, HyperKeyframes> keyframeRegistry;

  /// If true, parsing runs synchronously inside a microtask instead of a
  /// separate isolate using `compute()`.
  /// This is highly recommended for unit/integration testing where isolates
  /// can cause test timeouts or synchronization issues.
  /// 
  /// Default: false
  final bool useMicrotaskParsing;

  /// Additional URL schemes permitted to reach [onLinkTap].
  ///
  /// HyperRender always allows the built-in safe set (`http`, `https`,
  /// `mailto`, `tel`) and always blocks dangerous schemes (`javascript:`,
  /// `data:`, `file:`, etc.).  Add your app's custom deep-link schemes here so
  /// tapping those links invokes [onLinkTap] instead of being silently dropped.
  ///
  /// ```dart
  /// HyperRenderConfig(
  ///   extraLinkSchemes: {'myapp', 'fb', 'shopee', 'momo'},
  /// )
  /// ```
  ///
  /// Schemes are compared case-insensitively.
  ///
  /// Default: `{}` (only the built-in safe set)
  final Set<String> extraLinkSchemes;

  /// Production-ready defaults, tuned against real-world documents.
  static const HyperRenderConfig defaults = HyperRenderConfig();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HyperRenderConfig &&
        other.textPainterCacheSize == textPainterCacheSize &&
        other.imageCacheSize == imageCacheSize &&
        other.defaultImagePlaceholderWidth == defaultImagePlaceholderWidth &&
        other.imageConcurrency == imageConcurrency &&
        other.virtualizationChunkSize == virtualizationChunkSize &&
        other.codeHighlighter == codeHighlighter &&
        other.extraLinkSchemes == extraLinkSchemes &&
        _mapsEqual(other.keyframeRegistry, keyframeRegistry);
  }

  @override
  int get hashCode => Object.hash(
        textPainterCacheSize,
        imageCacheSize,
        defaultImagePlaceholderWidth,
        imageConcurrency,
        virtualizationChunkSize,
        codeHighlighter,
        Object.hashAll(extraLinkSchemes),
        Object.hashAll(keyframeRegistry.keys),
      );

  static bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
