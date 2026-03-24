import 'dart:isolate';

import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../parser/html/html_adapter.dart';
import '../plugins/default_delta_parser.dart';
import '../plugins/default_html_parser.dart';
import '../plugins/default_markdown_parser.dart';
import '../utils/html_heuristics.dart';
import '../utils/html_sanitizer.dart';
import '../utils/svg_builder.dart';
import 'virtualized_selection_controller.dart';
import 'virtualized_selection_overlay.dart';

/// Rendering mode for [HyperViewer].
///
/// Controls whether content is parsed and laid out synchronously or
/// asynchronously, and whether it is rendered as a single widget or via
/// a virtualised [ListView].
enum HyperRenderMode {
  /// Automatic selection: short content (< 10,000 chars) uses [sync]; longer
  /// content uses an async parse followed by [virtualized] layout.
  auto,

  /// Synchronous rendering on the main thread. Best for short snippets where
  /// parse time is negligible.
  sync,

  /// Asynchronous parse + [ListView.builder]-based virtualised rendering.
  /// Best for long documents (articles, emails, feeds).
  virtualized,
}

/// Content type for HyperViewer
enum HyperContentType {
  /// HTML content
  html,

  /// Quill Delta JSON
  delta,

  /// Markdown
  markdown,
}

class HyperViewer extends StatefulWidget {
  /// The content to render
  final String content;

  /// Type of content (html, delta, markdown)
  final HyperContentType contentType;

  /// Legacy parameter - use [content] instead
  /// Kept for backward compatibility
  @Deprecated('Use content parameter instead')
  String get html => content;

  final HyperRenderMode mode;
  final bool selectable;
  final Function(String)? onLinkTap;

  /// Additional URL schemes allowed by [onLinkTap], beyond the built-in
  /// whitelist (`http`, `https`, `mailto`, `tel`).
  ///
  /// Enterprise apps with custom deeplinks should list their schemes here:
  /// ```dart
  /// HyperViewer(
  ///   html: content,
  ///   onLinkTap: _handleLink,
  ///   allowedCustomSchemes: ['myapp', 'shopee', 'momo'],
  /// )
  /// ```
  final List<String>? allowedCustomSchemes;

  /// Engine performance configuration.
  ///
  /// Use this to tune cache sizes and concurrency for your target device tier:
  ///
  /// ```dart
  /// // Low-end Android (≤ 2 GB RAM)
  /// HyperViewer(
  ///   html: content,
  ///   renderConfig: HyperRenderConfig(
  ///     textPainterCacheSize: 500,
  ///     imageConcurrency: 2,
  ///     virtualizationChunkSize: 3000,
  ///   ),
  /// )
  /// ```
  ///
  /// Defaults to [HyperRenderConfig.defaults] which is tuned for mid-range devices.
  final HyperRenderConfig renderConfig;
  final HyperWidgetBuilder? widgetBuilder;
  final WidgetBuilder? placeholderBuilder;

  /// Base URL used to resolve relative `src` and `href` attributes in HTML.
  ///
  /// Example:
  /// ```dart
  /// HyperViewer(
  ///   html: '<img src="/images/logo.png">',
  ///   baseUrl: 'https://example.com',
  /// )
  /// // → renders as: https://example.com/images/logo.png
  /// ```
  final String? baseUrl;

  /// Extra CSS injected before the document's own styles.
  ///
  /// Useful for overriding default styles without modifying the HTML.
  ///
  /// Example:
  /// ```dart
  /// HyperViewer(
  ///   html: content,
  ///   customCss: 'body { font-size: 18px; } a { color: red; }',
  /// )
  /// ```
  final String? customCss;

  /// Draw colored outlines around each rendered fragment and line row.
  ///
  /// Equivalent to Flutter's [debugPaintSizeEnabled] but scoped to this widget.
  /// Blue outlines = line rows, orange outlines = individual text/image fragments.
  ///
  /// **Only use during development — has no effect in release builds by default.**
  ///
  /// Default: false
  final bool debugShowHyperRenderBounds;

  /// When false, `backdrop-filter` and CSS `filter` effects skip
  /// `canvas.saveLayer`. Disable on low-end devices to avoid rasterization
  /// overhead from complex compositing layers.
  final bool enableComplexFilters;

  /// Enable pinch-to-zoom and pan gestures
  /// Wraps content in InteractiveViewer for zoom/pan support
  final bool enableZoom;

  /// Minimum scale for zoom (default: 0.5)
  final double minScale;

  /// Maximum scale for zoom (default: 4.0)
  final double maxScale;

  /// Custom content parser for parsing content.
  /// If null, uses default parser based on [contentType].
  final ContentParser? contentParser;

  /// Custom code highlighter for syntax highlighting in code blocks.
  /// If null, uses DefaultCodeHighlighter (requires flutter_highlight).
  final CodeHighlighter? codeHighlighter;

  /// Show selection popup menu when text is selected.
  /// If true (default when selectable), shows Copy/Select All menu on selection.
  /// Set to false to disable the popup menu but keep selection enabled.
  final bool showSelectionMenu;

  /// Color of selection handles (default: theme primary color)
  final Color? selectionHandleColor;

  /// Color for text selection highlight (default: platform-adaptive blue)
  final Color? selectionColor;

  /// Custom menu actions builder for the selection popup.
  /// If null, uses default Copy and Select All actions.
  final List<SelectionMenuAction> Function(HyperSelectionOverlayState)?
      selectionMenuActionsBuilder;

  /// Custom context menu builder for full customization.
  /// If provided, overrides the default menu completely.
  final Widget Function(BuildContext, HyperSelectionOverlayState)?
      selectionContextMenuBuilder;

  /// **SECURITY**: Sanitize HTML to prevent XSS attacks.
  ///
  /// When enabled, removes dangerous tags (<script>, <iframe>) and
  /// event handlers (onclick, onerror, etc.) before rendering.
  ///
  /// **IMPORTANT**: Always enable this when rendering untrusted HTML!
  ///
  /// Default: false (for backward compatibility)
  ///
  /// Example:
  /// ```dart
  /// // ✅ SAFE - Sanitize user-generated content
  /// HyperViewer(
  ///   html: userInput,
  ///   sanitize: true,
  /// )
  ///
  /// // ❌ UNSAFE - Never do this with untrusted HTML
  /// HyperViewer(html: userInput)
  /// ```
  final bool sanitize;

  /// Text direction for layout
  final TextDirection? textDirection;

  /// Custom list of allowed HTML tags when [sanitize] is enabled.
  ///
  /// If null, uses [HtmlSanitizer.defaultAllowedTags].
  ///
  /// Example:
  /// ```dart
  /// HyperViewer(
  ///   html: content,
  ///   sanitize: true,
  ///   allowedTags: ['p', 'a', 'img', 'strong', 'em'],
  /// )
  /// ```
  final List<String>? allowedTags;

  /// Allow data-* attributes when sanitizing.
  ///
  /// Default: false
  final bool allowDataAttributes;

  /// **ACCESSIBILITY**: Semantic label for screen readers.
  ///
  /// Describes the content for users with visual impairments.
  /// If null, a default label "Article content" is used.
  ///
  /// Example:
  /// ```dart
  /// HyperViewer(
  ///   html: newsArticle,
  ///   semanticLabel: 'News article: Breaking news title',
  /// )
  /// ```
  final String? semanticLabel;

  /// **ACCESSIBILITY**: Exclude from semantic tree.
  ///
  /// When true, this widget and its children are excluded from
  /// assistive technologies like screen readers.
  ///
  /// Default: false
  final bool excludeSemantics;

  /// Called instead of the normal render pipeline when
  /// [HtmlHeuristics.isComplex] detects content that hyper_render may not
  /// handle correctly (complex tables, unsupported CSS, streaming media, …).
  ///
  /// Typical use: provide a WebView widget for complex documents while keeping
  /// hyper_render for the common case.
  ///
  /// ```dart
  /// HyperViewer(
  ///   html: content,
  ///   fallbackBuilder: (ctx) => WebViewWidget(controller: _controller),
  /// )
  /// ```
  ///
  /// When `null` (default), hyper_render renders all content regardless of
  /// complexity.
  final WidgetBuilder? fallbackBuilder;

  /// Key for screenshot/print export via [HyperCaptureExtension].
  ///
  /// When provided, wraps the rendered content in a [RepaintBoundary] so
  /// [HyperCaptureExtension.toImage()] and [toPngBytes()] work correctly.
  ///
  /// ## Usage
  /// ```dart
  /// final captureKey = GlobalKey();
  ///
  /// HyperViewer(
  ///   html: content,
  ///   captureKey: captureKey,
  /// )
  ///
  /// // Later:
  /// final png = await captureKey.toPngBytes();
  /// ```
  final GlobalKey? captureKey;

  /// Whether the extent of the scroll view should be determined by the contents
  /// being viewed.
  ///
  /// If the scroll view does not shrink wrap, then the scroll view will expand
  /// to the maximum allowed size in the scrollDirection. If the scroll view
  /// has unbounded constraints in the scrollDirection, then [shrinkWrap] must
  /// be true.
  ///
  /// Shrink wrapping the content of the scroll view is significantly more
  /// expensive than expanding to the maximum allowed size because the content
  /// can expand and contract during scrolling, which means the size of the
  /// scroll view needs to be recomputed whenever the scroll position changes.
  ///
  /// Defaults to false.
  final bool shrinkWrap;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to [AlwaysScrollableScrollPhysics], which delegates to the
  /// platform-appropriate physics: bouncing on iOS/macOS, clamping with the
  /// Material stretch indicator on Android. Pass an explicit [ScrollPhysics]
  /// subclass to override this behaviour.
  final ScrollPhysics? physics;

  /// Called when content parsing fails.
  ///
  /// Provides the error and stack trace so the caller can log or display a
  /// friendly error state. Without this callback, parse errors are silently
  /// swallowed and the widget shows nothing.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Optional controller for scroll-to-anchor and TOC generation.
  ///
  /// When provided, the controller's [ScrollController] drives the scroll
  /// view, and its [HyperViewerController.headings] list is populated after
  /// each layout pass.
  ///
  /// ```dart
  /// final _ctrl = HyperViewerController();
  ///
  /// HyperViewer(html: content, controller: _ctrl)
  ///
  /// // Later:
  /// _ctrl.scrollToId('footnote-1');
  /// _ctrl.headings; // → List<HeadingAnchor>
  /// ```
  final HyperViewerController? controller;

  /// Pre-parsed document node. When set, the parse step is skipped entirely.
  /// Used by [HyperViewer.fromNode] and by consumers who pre-process the AST.
  final DocumentNode? _prebuiltDocument;

  /// Creates a HyperViewer for HTML content (default)
  ///
  /// ```dart
  /// HyperViewer(html: '<p>Hello World</p>')
  ///
  /// // With sanitization (recommended for user content)
  /// HyperViewer(
  ///   html: userInput,
  ///   sanitize: true,
  /// )
  /// ```
  const HyperViewer({
    super.key,
    required String html,
    this.mode = HyperRenderMode.auto,
    this.selectable = true,
    this.onLinkTap,
    this.allowedCustomSchemes,
    this.widgetBuilder,
    this.placeholderBuilder,
    this.fallbackBuilder,
    this.enableZoom = false,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.contentParser,
    this.codeHighlighter,
    this.showSelectionMenu = true,
    this.selectionHandleColor,
    this.selectionColor,
    this.selectionMenuActionsBuilder,
    this.selectionContextMenuBuilder,
    this.sanitize = true,
    this.textDirection,
    this.allowedTags,
    this.allowDataAttributes = false,
    this.semanticLabel,
    this.excludeSemantics = false,
    this.baseUrl,
    this.customCss,
    this.debugShowHyperRenderBounds = false,
    this.enableComplexFilters = true,
    this.captureKey,
    this.shrinkWrap = false,
    this.physics,
    this.onError,
    this.controller,
    this.renderConfig = HyperRenderConfig.defaults,
  })  : content = html,
        contentType = HyperContentType.html,
        _prebuiltDocument = null;

  /// Creates a HyperViewer for Quill Delta JSON content
  ///
  /// ```dart
  /// HyperViewer.delta(
  ///   delta: '{"ops":[{"insert":"Hello World\\n"}]}',
  /// )
  /// ```
  const HyperViewer.delta({
    super.key,
    required String delta,
    this.mode = HyperRenderMode.auto,
    this.selectable = true,
    this.onLinkTap,
    this.allowedCustomSchemes,
    this.widgetBuilder,
    this.placeholderBuilder,
    this.fallbackBuilder,
    this.enableZoom = false,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.contentParser,
    this.codeHighlighter,
    this.showSelectionMenu = true,
    this.selectionHandleColor,
    this.selectionColor,
    this.selectionMenuActionsBuilder,
    this.selectionContextMenuBuilder,
    this.sanitize = true,
    this.textDirection,
    this.allowedTags,
    this.allowDataAttributes = false,
    this.semanticLabel,
    this.excludeSemantics = false,
    this.baseUrl,
    this.customCss,
    this.debugShowHyperRenderBounds = false,
    this.enableComplexFilters = true,
    this.captureKey,
    this.shrinkWrap = false,
    this.physics,
    this.onError,
    this.controller,
    this.renderConfig = HyperRenderConfig.defaults,
  })  : content = delta,
        contentType = HyperContentType.delta,
        _prebuiltDocument = null;

  /// Creates a HyperViewer for Markdown content
  ///
  /// ```dart
  /// HyperViewer.markdown(
  ///   markdown: '# Hello World\n\nThis is **bold** text.',
  /// )
  /// ```
  const HyperViewer.markdown({
    super.key,
    required String markdown,
    this.mode = HyperRenderMode.auto,
    this.selectable = true,
    this.onLinkTap,
    this.allowedCustomSchemes,
    this.widgetBuilder,
    this.placeholderBuilder,
    this.fallbackBuilder,
    this.enableZoom = false,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.contentParser,
    this.codeHighlighter,
    this.showSelectionMenu = true,
    this.selectionHandleColor,
    this.selectionColor,
    this.selectionMenuActionsBuilder,
    this.selectionContextMenuBuilder,
    this.sanitize = true,
    this.textDirection,
    this.allowedTags,
    this.allowDataAttributes = false,
    this.semanticLabel,
    this.excludeSemantics = false,
    this.baseUrl,
    this.customCss,
    this.debugShowHyperRenderBounds = false,
    this.enableComplexFilters = true,
    this.captureKey,
    this.shrinkWrap = false,
    this.physics,
    this.onError,
    this.controller,
    this.renderConfig = HyperRenderConfig.defaults,
  })  : content = markdown,
        contentType = HyperContentType.markdown,
        _prebuiltDocument = null;

  /// Creates a [HyperViewer] from a pre-parsed [DocumentNode], skipping
  /// the parse step entirely.
  ///
  /// Useful when you want to pre-process or transform the AST before rendering:
  ///
  /// ```dart
  /// final doc = HtmlAdapter().parse(rawHtml);
  /// // Strip ad nodes, inject CSS classes, etc.
  /// HyperViewer.fromNode(document: doc, controller: myController)
  /// ```
  const HyperViewer.fromNode({
    super.key,
    required DocumentNode document,
    this.selectable = true,
    this.onLinkTap,
    this.allowedCustomSchemes,
    this.widgetBuilder,
    this.enableZoom = false,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.showSelectionMenu = true,
    this.selectionHandleColor,
    this.selectionColor,
    this.selectionMenuActionsBuilder,
    this.selectionContextMenuBuilder,
    this.textDirection,
    this.semanticLabel,
    this.excludeSemantics = false,
    this.debugShowHyperRenderBounds = false,
    this.enableComplexFilters = true,
    this.captureKey,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.renderConfig = HyperRenderConfig.defaults,
  })  : content = '',
        contentType = HyperContentType.html,
        mode = HyperRenderMode.sync,
        placeholderBuilder = null,
        fallbackBuilder = null,
        contentParser = null,
        codeHighlighter = null,
        sanitize = false,
        allowedTags = null,
        allowDataAttributes = false,
        baseUrl = null,
        customCss = null,
        onError = null,
        _prebuiltDocument = document;

  @override
  State<HyperViewer> createState() => _HyperViewerState();
}

/// Argument bundle sent into the parse isolate.
/// All fields must be sendable (primitives + SendPort).
class _ParseArgs {
  final String content;
  final String css;
  final int chunkSize;
  final SendPort port;
  const _ParseArgs(this.content, this.css, this.chunkSize, this.port);
}

class _HyperViewerState extends State<HyperViewer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _contentFadeController;
  late final Animation<double> _contentFadeAnimation;

  /// Active parse isolate — killed immediately when content changes or widget
  /// is disposed, preventing CPU waste from abandoned parses.
  Isolate? _parseIsolate;
  ReceivePort? _parseReceivePort;

  // Dùng cho chế độ Sync
  DocumentNode? _syncDocument;

  // Dùng cho chế độ Virtualized
  List<DocumentNode>? _sections;
  bool _isLoading = true;

  /// Float carryovers indexed by section: _floatCarryovers[N] holds the
  /// dangling floats produced by section N's layout, to be passed as
  /// initialFloats to section N+1.
  final List<List<FloatCarryover>> _floatCarryovers = [];

  /// Monotonically-increasing counter that prevents stale isolate results
  /// from overwriting a newer parse when the content changes rapidly.
  int _parseId = 0;

  /// GlobalKey placed on the Stack that wraps the virtualized ListView.
  /// Used by [VirtualizedSelectionController] to convert chunk-local
  /// coordinates to Stack coordinates for handle and menu positioning.
  final GlobalKey _virtualizedStackKey = GlobalKey();

  /// Selection orchestrator for cross-chunk selection in virtualized mode.
  VirtualizedSelectionController? _virtualizedSelectionController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _contentFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _contentFadeAnimation = CurvedAnimation(
      parent: _contentFadeController,
      curve: Curves.easeOut,
    );
    if (widget.selectable) {
      _virtualizedSelectionController = VirtualizedSelectionController(
        sectionsGetter: () => _sections ?? const [],
        listViewKey: _virtualizedStackKey,
      );
    }
    _parseContent();
  }

  @override
  void didUpdateWidget(covariant HyperViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.contentType != widget.contentType ||
        oldWidget.mode != widget.mode ||
        oldWidget.baseUrl != widget.baseUrl ||
        oldWidget.customCss != widget.customCss ||
        oldWidget.sanitize != widget.sanitize ||
        oldWidget.allowedTags != widget.allowedTags ||
        oldWidget.allowDataAttributes != widget.allowDataAttributes ||
        oldWidget.fallbackBuilder != widget.fallbackBuilder) {
      _parseContent();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelParsing();
    _contentFadeController.dispose();
    _virtualizedSelectionController?.dispose();
    super.dispose();
  }

  /// Kills any in-flight parse isolate and closes its ReceivePort.
  ///
  /// Called before spawning a new parse and in [dispose] so we never leave
  /// a CPU-burning isolate running after the widget is gone.
  void _cancelParsing() {
    _parseIsolate?.kill(priority: Isolate.immediate);
    _parseIsolate = null;
    _parseReceivePort?.close();
    _parseReceivePort = null;
  }

  /// Called by the system when available memory is low.
  ///
  /// Releases memory on three fronts:
  ///   1. TextPainter and image caches in every live [RenderHyperBox].
  ///   2. The [LazyImageQueue] pending queue — drops not-yet-started loads so
  ///      off-screen images are not decoded into a constrained heap.
  ///   3. Flutter's own decoded-image cache ([PaintingBinding.imageCache]) to
  ///      release GPU textures that Flutter holds independently of HyperRender.
  @override
  void didHaveMemoryPressure() {
    void clearBox(RenderObject obj) {
      if (obj is RenderHyperBox) {
        obj.clearMemoryCaches();
      }
      obj.visitChildren(clearBox);
    }

    final ro = context.findRenderObject();
    if (ro != null) clearBox(ro);

    // Drop pending (not-yet-started) image loads to avoid decoding off-screen
    // images into an already-constrained heap on low-memory devices.
    LazyImageQueue.instance.clearPending();

    // Release Flutter's own decoded-image cache.  This covers any images
    // loaded via Image.network / precacheImage that HyperRender didn't track.
    PaintingBinding.instance.imageCache.clear();
  }

  /// Routes a parse/render error to [HyperViewer.onError] when provided,
  /// or falls back to [FlutterError.reportError] so the problem is always
  /// visible in the console and to Crashlytics/Sentry — even when the caller
  /// forgot to supply an error handler.
  void _reportError(Object error, StackTrace stack) {
    if (widget.onError != null) {
      widget.onError!.call(error, stack);
    } else {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'HyperRender',
        context: ErrorDescription(
          'parsing content in HyperViewer. '
          'Add an onError callback to handle this gracefully.',
        ),
      ));
    }
  }

  /// Chains the built-in SVG builder before any user-supplied [widgetBuilder].
  ///
  /// SVG nodes are handled by [buildSvgWidget] using `flutter_svg`.
  /// All other nodes are passed to [widget.widgetBuilder] (if any).
  HyperWidgetBuilder get _effectiveWidgetBuilder {
    final userBuilder = widget.widgetBuilder;
    return (UDTNode node) =>
        buildSvgWidget(node) ?? userBuilder?.call(node);
  }

  /// Stores dangling floats from section [index] and triggers a rebuild of
  /// section [index+1] so it receives the updated [initialFloats].
  void _onFloatCarryover(int index, List<FloatCarryover> carryovers) {
    if (!mounted) return;
    // Grow the list if needed.
    while (_floatCarryovers.length <= index) {
      _floatCarryovers.add(const []);
    }
    // Only rebuild if the carryover actually changed.
    final prev = _floatCarryovers[index];
    if (prev.length == carryovers.length && carryovers.isEmpty) return;
    setState(() {
      _floatCarryovers[index] = carryovers;
    });
  }

  static const _kAllowedSchemes = {'http', 'https', 'mailto', 'tel'};

  /// Returns a wrapped [onLinkTap] callback that validates the URL scheme
  /// before forwarding to the user-supplied handler.
  ///
  /// Built-in whitelist: `http`, `https`, `mailto`, `tel`.
  /// Extend with [HyperViewer.allowedCustomSchemes] for app-specific deeplinks.
  Function(String)? get _safeOnLinkTap {
    final handler = widget.onLinkTap;
    if (handler == null) return null;
    return (String url) {
      final scheme = Uri.tryParse(url)?.scheme.toLowerCase() ?? '';
      final customSchemes = widget.allowedCustomSchemes;
      final isAllowed = _kAllowedSchemes.contains(scheme) ||
          (customSchemes != null && customSchemes.contains(scheme));
      if (isAllowed) {
        handler(url);
      } else {
        assert(() {
          debugPrint('[HyperRender] Blocked link tap with disallowed scheme: $url');
          return true;
        }());
      }
    };
  }

  /// Get the appropriate parser based on content type
  ContentParser _getDefaultParser() {
    if (widget.contentParser != null) {
      return widget.contentParser!;
    }

    switch (widget.contentType) {
      case HyperContentType.html:
        return DefaultHtmlParser();
      case HyperContentType.delta:
        return const DefaultDeltaParser();
      case HyperContentType.markdown:
        return DefaultMarkdownParser();
    }
  }

  void _parseContent() {
    // Fast path: pre-parsed AST — skip all parsing.
    if (widget._prebuiltDocument != null) {
      setState(() {
        _syncDocument = widget._prebuiltDocument;
        _sections = null;
        _isLoading = false;
      });
      _contentFadeController.forward();
      return;
    }

    String contentToRender = widget.content;
    // CSS collected from <style> tags + customCss (applied to resolver directly,
    // not injected as a <style> tag so the sanitizer cannot strip it).
    String cssToApply = '';

    if (widget.contentType == HyperContentType.html) {
      // 1. Extract CSS from <style> elements BEFORE sanitization.
      //    The sanitizer strips <style> tags, so we must grab them first.
      final adapter = HtmlAdapter();
      final docCss = adapter.extractCss(contentToRender);

      // customCss is lower priority (applied first); docCss wins on conflict.
      if (widget.customCss != null && widget.customCss!.isNotEmpty) {
        cssToApply = '${widget.customCss!}\n$docCss';
      } else {
        cssToApply = docCss;
      }

      // 2. Resolve relative URLs against baseUrl
      if (widget.baseUrl != null && widget.baseUrl!.isNotEmpty) {
        contentToRender =
            _resolveRelativeUrls(contentToRender, widget.baseUrl!);
      }

      // 3. Sanitize (strips <style> tags — safe, CSS already extracted above)
      if (widget.sanitize) {
        contentToRender = HtmlSanitizer.sanitize(
          contentToRender,
          allowedTags: widget.allowedTags,
          allowDataAttributes: widget.allowDataAttributes,
        );
      }
    }

    final useVirtualization = widget.mode == HyperRenderMode.virtualized ||
        (widget.mode == HyperRenderMode.auto && contentToRender.length > 10000);

    final parser = _getDefaultParser();

    if (!useVirtualization) {
      // Sync parsing (fast path for small content)
      _contentFadeController.reset();
      try {
        final doc = parser.parse(contentToRender);
        final resolver = StyleResolver();
        if (cssToApply.isNotEmpty) resolver.parseCss(cssToApply);
        resolver.resolveStyles(doc);
        setState(() {
          _syncDocument = doc;
          _sections = null;
          _isLoading = false;
        });
        _contentFadeController.forward();
      } catch (e, st) {
        _reportError(e, st);
        setState(() => _isLoading = false);
      }
    } else {
      // Async parsing (isolate path for large HTML content)
      if (widget.contentType == HyperContentType.html) {
        _contentFadeController.reset();
        setState(() => _isLoading = true);

        // Capture parse ID before async gap to detect stale results.
        final currentParseId = ++_parseId;

        // Cancel any in-flight isolate from a previous parse before spawning a
        // new one, so we don't burn CPU on an abandoned parse.
        _cancelParsing();
        final receivePort = ReceivePort();
        _parseReceivePort = receivePort;

        Isolate.spawn(
          _isolateEntry,
          _ParseArgs(
            contentToRender,
            cssToApply,
            widget.renderConfig.virtualizationChunkSize,
            receivePort.sendPort,
          ),
        ).then((isolate) {
          _parseIsolate = isolate;
          return receivePort.first;
        }).then((dynamic message) {
          // Isolate finished — release references.
          _parseIsolate = null;
          _parseReceivePort = null;
          if (!mounted || _parseId != currentParseId) return;
          if (message is List) {
            setState(() {
              _sections = List<DocumentNode>.from(message);
              _syncDocument = null;
              _isLoading = false;
              _floatCarryovers.clear(); // reset carryovers for new content
            });
            _contentFadeController.forward();
          } else {
            // _isolateEntry sent an error string.
            final err = FormatException(
              message is String ? message : 'Content parsing failed',
            );
            _reportError(err, StackTrace.empty);
            setState(() => _isLoading = false);
          }
        }).catchError((Object e, StackTrace st) {
          _cancelParsing();
          if (mounted && _parseId == currentParseId) {
            _reportError(e, st);
            setState(() => _isLoading = false);
          }
        });
      } else {
        // Fallback to sync parsing for Delta/Markdown
        _contentFadeController.reset();
        try {
          final doc = parser.parse(contentToRender);
          final resolver = StyleResolver();
          if (cssToApply.isNotEmpty) resolver.parseCss(cssToApply);
          resolver.resolveStyles(doc);
          setState(() {
            _syncDocument = doc;
            _sections = null;
            _isLoading = false;
          });
          _contentFadeController.forward();
        } catch (e, st) {
          _reportError(e, st);
          setState(() => _isLoading = false);
        }
      }
    }
  }

  /// Resolves relative `src` and `href` attribute values against [base].
  static String _resolveRelativeUrls(String html, String base) {
    final baseUri = Uri.tryParse(base);
    if (baseUri == null) return html;

    return html.replaceAllMapped(
      RegExp(r'''(src|href)=["']([^"']+)["']''', caseSensitive: false),
      (m) {
        final attr = m.group(1)!;
        final url = m.group(2)!;
        final uri = Uri.tryParse(url);
        if (uri == null || uri.hasScheme) {
          return m.group(0)!; // already absolute
        }
        final resolved = baseUri.resolveUri(uri).toString();
        // Preserve original quote style
        final quote = m.group(0)!.contains('"') ? '"' : "'";
        return '$attr=$quote$resolved$quote';
      },
    );
  }

  /// Isolate entry point. Runs [_parseAndChunk] and sends the result (or an
  /// error string) back via [_ParseArgs.port].
  ///
  /// Sending a plain `String` on error keeps the message always sendable —
  /// exception objects can hold closures or native resources that the isolate
  /// message protocol cannot transfer.
  static void _isolateEntry(_ParseArgs args) {
    try {
      final sections =
          _parseAndChunk((args.content, args.css, args.chunkSize));
      args.port.send(sections);
    } catch (e) {
      args.port.send('$e');
    }
  }

  // Static function that runs in an isolate — must not capture context.
  // Accepts a (html, css) record so CSS rules are available inside the isolate.
  static List<DocumentNode> _parseAndChunk((String, String, int) args) {
    final (html, css, chunkSize) = args;
    final adapter = HtmlAdapter();
    // chunkSize: keeps each RenderHyperBox well under GPU texture limits
    // (~4096px physical on most devices). Configurable via HyperRenderConfig.
    final sections = adapter.parseToSections(html, chunkSize: chunkSize);

    // Resolve styles in the isolate so the main thread doesn't bear the cost.
    final resolver = StyleResolver();
    if (css.isNotEmpty) resolver.parseCss(css);
    for (var section in sections) {
      resolver.resolveStyles(section);
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    // Delegate to fallbackBuilder when the content exceeds hyper_render's
    // supported subset (only checked for HTML; Delta/Markdown are always safe).
    if (widget.fallbackBuilder != null &&
        widget.contentType == HyperContentType.html &&
        HtmlHeuristics.isComplex(widget.content)) {
      return widget.fallbackBuilder!(context);
    }

    // Use FadeTransition instead of AnimatedSwitcher to avoid the
    // '_RenderObjectSemantics.parentDataDirty' assertion in debug builds.
    //
    // AnimatedSwitcher internally holds both old and new children in a Stack
    // during transitions. The Stack calls adoptChild() on its new child in the
    // same frame that PipelineOwner.flushSemantics() runs its debug check
    // (debugCheckForParentData), causing the assertion to fire.
    //
    // FadeTransition is a SingleChildRenderObjectWidget — it never reparents
    // children, so no adoptChild() is called during the fade.
    Widget content = _isLoading
        ? _buildContent(context)
        : FadeTransition(
            opacity: _contentFadeAnimation,
            child: _buildContent(context),
          );

    // Wrap with RepaintBoundary for screenshot capture if captureKey is set
    if (widget.captureKey != null) {
      content = RepaintBoundary(key: widget.captureKey, child: content);
    }

    // Wrap with Semantics for accessibility (unless excluded)
    return widget.excludeSemantics
        ? ExcludeSemantics(child: content)
        : Semantics(
            label: widget.semanticLabel ?? 'Article content',
            child: content,
          );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return KeyedSubtree(
        key: const ValueKey('loading'),
        child: widget.placeholderBuilder?.call(context) ??
            const Center(child: CircularProgressIndicator()),
      );
    }

    // Case 1: Virtualized List (cho văn bản dài)
    if (_sections != null) {
      final selCtrl = _virtualizedSelectionController;
      final dir = widget.textDirection ?? Directionality.of(context);

      // cacheExtent 800: pre-renders ~1 screen ahead/behind. Smaller than
      // the old 1500 because chunks are now 6000 chars (was 25000), so
      // each item is cheaper — we need fewer pixels of pre-render buffer.
      final listView = ListView.builder(
        cacheExtent: 800,
        controller: widget.controller?.scrollController,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        itemCount: _sections!.length,
        itemBuilder: (context, index) {
          // RepaintBoundary isolates each chunk into its own GPU layer.
          // Prevents a re-paint in one chunk from invalidating neighbours,
          // and keeps each composited layer well under GL_MAX_TEXTURE_SIZE.
          // Retrieve carryover from previous section (if layout already ran).
          final prevCarryover =
              (index > 0 && _floatCarryovers.length >= index)
                  ? _floatCarryovers[index - 1]
                  : const <FloatCarryover>[];
          return RepaintBoundary(
            child: selCtrl != null
                ? VirtualizedChunk(
                    chunkIndex: index,
                    document: _sections![index],
                    selectionController: selCtrl,
                    selectable: widget.selectable,
                    selectionColor: widget.selectionColor,
                    textDirection: dir,
                    onLinkTap: _safeOnLinkTap,
                    widgetBuilder: _effectiveWidgetBuilder,
                    debugShowBounds: widget.debugShowHyperRenderBounds,
                    enableComplexFilters: widget.enableComplexFilters,
                    config: widget.renderConfig,
                    suppressFirstBlockMarginTop: index > 0,
                    initialFloats: prevCarryover,
                    onFloatCarryover: (carryovers) =>
                        _onFloatCarryover(index, carryovers),
                  )
                : HyperRenderWidget(
                    document: _sections![index],
                    selectable: false,
                    textDirection: dir,
                    onLinkTap: _safeOnLinkTap,
                    widgetBuilder: _effectiveWidgetBuilder,
                    debugShowBounds: widget.debugShowHyperRenderBounds,
                    enableComplexFilters: widget.enableComplexFilters,
                    config: widget.renderConfig,
                    suppressFirstBlockMarginTop: index > 0,
                    initialFloats: prevCarryover,
                    onFloatCarryover: (carryovers) =>
                        _onFloatCarryover(index, carryovers),
                  ),
          );
        },
      );

      // Wrap with cross-chunk selection overlay when selectable.
      final Widget content = (selCtrl != null && widget.showSelectionMenu)
          ? VirtualizedSelectionOverlay(
              key: _virtualizedStackKey,
              controller: selCtrl,
              handleColor:
                  widget.selectionHandleColor ?? Theme.of(context).primaryColor,
              menuBackgroundColor: null,
              child: listView,
            )
          : KeyedSubtree(key: _virtualizedStackKey, child: listView);

      return KeyedSubtree(
        key: const ValueKey('virtualized'),
        // panEnabled: false — InteractiveViewer handles pinch-to-zoom only;
        // ListView retains scroll ownership so both gestures work together.
        child: widget.enableZoom
            ? InteractiveViewer(
                panEnabled: false,
                scaleEnabled: true,
                minScale: widget.minScale,
                maxScale: widget.maxScale,
                child: content,
              )
            : content,
      );
    }

    // Case 2: Single Widget (cho văn bản ngắn)
    if (_syncDocument != null) {
      Widget content;

      // Use HyperSelectionOverlay for full selection UX with popup menu
      if (widget.selectable && widget.showSelectionMenu) {
        content = HyperSelectionOverlay(
          document: _syncDocument!,
          selectable: true,
          onLinkTap: widget.onLinkTap,
          widgetBuilder: _effectiveWidgetBuilder,
          handleColor:
              widget.selectionHandleColor ?? Theme.of(context).primaryColor,
          menuActionsBuilder: widget.selectionMenuActionsBuilder,
          contextMenuBuilder: widget.selectionContextMenuBuilder,
          showHandles: true,
          autoShowMenu: true,
          debugShowBounds: widget.debugShowHyperRenderBounds,
          onAnchorLayout: widget.controller?._onAnchorLayout,
        );
      } else {
        // Use HyperRenderWidget directly (no popup menu)
        content = HyperRenderWidget(
          document: _syncDocument!,
          selectable: widget.selectable,
          onLinkTap: widget.onLinkTap,
          widgetBuilder: _effectiveWidgetBuilder,
          debugShowBounds: widget.debugShowHyperRenderBounds,
          onAnchorLayout: widget.controller?._onAnchorLayout,
          config: widget.renderConfig,
        );
      }

      // Wrap with zoom if enabled (only for sync mode)
      if (widget.enableZoom) {
        return KeyedSubtree(
          key: const ValueKey('sync-zoom'),
          child: InteractiveViewer(
            minScale: widget.minScale,
            maxScale: widget.maxScale,
            boundaryMargin: const EdgeInsets.all(20),
            child: widget.shrinkWrap
                ? content
                : SingleChildScrollView(
                    controller: widget.controller?.scrollController,
                    physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
                    child: content,
                  ),
          ),
        );
      }

      // No zoom - standard scroll view
      if (widget.shrinkWrap) {
        return KeyedSubtree(
          key: const ValueKey('sync'),
          child: content,
        );
      }

      return KeyedSubtree(
        key: const ValueKey('sync'),
        child: SingleChildScrollView(
          controller: widget.controller?.scrollController,
          physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
          child: content,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HeadingAnchor — one TOC entry
// ─────────────────────────────────────────────────────────────────────────────

/// A single entry in the table-of-contents emitted by [HyperViewerController].
///
/// ```dart
/// controller.headings.forEach((h) {
///   print('${'  ' * (h.level - 1)}${h.text}  →  ${h.yOffset.toStringAsFixed(0)}px');
/// });
/// ```
class HeadingAnchor {
  /// Heading level: 1 = `<h1>`, 6 = `<h6>`.
  final int level;

  /// Plain-text content of the heading (stripped of child tags).
  final String text;

  /// CSS `id` attribute of the heading element, or `null` if absent.
  final String? cssId;

  /// Y-offset (in logical pixels) of the heading top within the scroll view.
  final double yOffset;

  const HeadingAnchor({
    required this.level,
    required this.text,
    this.cssId,
    required this.yOffset,
  });

  @override
  String toString() =>
      'HeadingAnchor(h$level, "$text", id=${cssId ?? '-'}, y=${yOffset.toStringAsFixed(1)})';
}

// ─────────────────────────────────────────────────────────────────────────────
// HyperViewerController
// ─────────────────────────────────────────────────────────────────────────────

/// Controller for [HyperViewer] that exposes scroll-to-anchor and TOC APIs.
///
/// ## Usage
/// ```dart
/// final _controller = HyperViewerController();
///
/// @override
/// void dispose() {
///   _controller.dispose();
///   super.dispose();
/// }
///
/// @override
/// Widget build(BuildContext context) => HyperViewer(
///   html: content,
///   controller: _controller,
/// );
///
/// // Scroll to a named anchor:
/// _controller.scrollToId('section-2');
///
/// // Build a TOC sidebar:
/// _controller.headings.map((h) => ListTile(title: Text(h.text))).toList();
/// ```
class HyperViewerController extends ChangeNotifier {
  final ScrollController _scroll = ScrollController();

  /// Underlying [ScrollController] used by [HyperViewer].
  /// Attach custom listeners here if needed.
  ScrollController get scrollController => _scroll;

  /// Anchor-id → y-offset map populated after the first layout pass.
  /// Updated whenever content changes.
  Map<String, double> _anchorOffsets = const {};

  /// Heading anchors (h1–h6) emitted after each layout pass.
  /// Sorted by y-offset (document order).
  List<HeadingAnchor> _headings = const [];

  /// Heading anchors emitted after the last layout pass.
  ///
  /// Empty until the first layout completes. Notifies listeners after each
  /// update so TOC widgets can rebuild reactively.
  List<HeadingAnchor> get headings => _headings;

  /// Returns `true` if the controller has at least one registered anchor.
  bool get hasAnchors => _anchorOffsets.isNotEmpty || _headings.isNotEmpty;

  /// Called internally by [HyperViewer] after each layout pass.
  void _onAnchorLayout(
    Map<String, double> offsets,
    List<({int level, String text, String? cssId, double yOffset})> headings,
  ) {
    _anchorOffsets = offsets;
    _headings = headings
        .map((h) => HeadingAnchor(
              level: h.level,
              text: h.text,
              cssId: h.cssId,
              yOffset: h.yOffset,
            ))
        .toList();
    notifyListeners();
  }

  /// Smooth-scrolls the content so that the element with `id="[id]"` is
  /// visible at the top of the viewport.
  ///
  /// Does nothing if the id is not found or the scroll controller is not
  /// attached to a scroll view yet.
  ///
  /// ```dart
  /// controller.scrollToId('chapter-3');
  /// ```
  Future<void> scrollToId(
    String id, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOut,
    double offsetCorrection = 0.0,
  }) async {
    final offset = _anchorOffsets[id];
    if (offset == null) return;
    if (!_scroll.hasClients) return;
    final target = (offset + offsetCorrection)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    await _scroll.animateTo(target, duration: duration, curve: curve);
  }

  /// Jumps instantly to the element with `id="[id]"` without animation.
  void jumpToId(String id, {double offsetCorrection = 0.0}) {
    final offset = _anchorOffsets[id];
    if (offset == null) return;
    if (!_scroll.hasClients) return;
    final target = (offset + offsetCorrection)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.jumpTo(target);
  }

  /// Smooth-scrolls to the heading at [index] in [headings].
  Future<void> scrollToHeading(
    int index, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOut,
  }) async {
    if (index < 0 || index >= _headings.length) return;
    final h = _headings[index];
    if (h.cssId != null) {
      await scrollToId(h.cssId!, duration: duration, curve: curve);
    } else {
      if (!_scroll.hasClients) return;
      final target = h.yOffset.clamp(0.0, _scroll.position.maxScrollExtent);
      await _scroll.animateTo(target, duration: duration, curve: curve);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }
}
