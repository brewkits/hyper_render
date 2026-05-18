import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../parser/html/html_adapter.dart';
import '../plugins/default_css_parser.dart';
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

  /// Asynchronous parse + [PageView.builder]-based paginated rendering.
  ///
  /// Each page corresponds to one document chunk (same chunking as
  /// [virtualized]). Suitable for e-book / epub / reader UIs where the user
  /// swipes between pages rather than scrolling continuously.
  ///
  /// Supply a [HyperPageController] via [HyperViewer.pageController] to
  /// programmatically jump to a page or observe page changes.
  paged,
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

/// Interface for selection operations in the context menu.
///
/// This is passed to [HyperViewer.selectionMenuActionsBuilder] to allow
/// custom actions (like Share or Search) to access the selected text.
abstract class HyperSelectionState {
  /// The currently selected text, or null if nothing is selected.
  String? get selectedText;

  /// Selects the entire document.
  void selectAll();

  /// Clears the current selection and dismisses the menu.
  void clearSelection();
}

class HyperViewer extends StatefulWidget {
  /// The content to render
  final String content;

  /// Type of content (html, delta, markdown)
  final HyperContentType contentType;

  /// Controls whether to use virtualized (lazy) or standard rendering.
  ///
  /// - [HyperRenderMode.auto] (default): chooses virtualized mode automatically
  ///   for documents longer than 10,000 characters, standard for shorter ones.
  /// - [HyperRenderMode.sync]: always render the full document in a single
  ///   [Column]. Best for short, embeddable content.
  /// - [HyperRenderMode.virtualized]: always use a [ListView.builder] so only
  ///   visible sections are laid out. Required for very long documents.
  final HyperRenderMode mode;

  /// Whether the user can select and copy text.
  ///
  /// Wraps the content in a [SelectionArea] when true. Defaults to false.
  final bool selectable;

  /// Called when the user taps a hyperlink.
  ///
  /// The callback receives the resolved URL string (relative URLs are resolved
  /// against [baseUrl] if provided). Return without side-effects to suppress
  /// the default behavior (no URL launcher is bundled — add `url_launcher` and
  /// call `launchUrl` yourself as needed).
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

  /// Override the default widget for specific node types.
  ///
  /// Called for every [UDTNode] before the built-in renderer is used. Return a
  /// widget to replace the default rendering, or `null` to fall through to the
  /// built-in behavior.
  ///
  /// Example — replace all `<img>` nodes with a custom cached-network-image:
  /// ```dart
  /// widgetBuilder: (node) {
  ///   if (node is AtomicNode && node.tagName == 'img' && node.src != null) {
  ///     return CachedNetworkImage(imageUrl: node.src!);
  ///   }
  ///   return null; // use default rendering
  /// },
  /// ```
  final HyperWidgetBuilder? widgetBuilder;

  /// Widget shown while content is being parsed.
  ///
  /// Defaults to a centered [CircularProgressIndicator] when null.
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
  final List<SelectionMenuAction> Function(HyperSelectionState)?
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
  /// Default: **true** — sanitization is on by default. Disable only when
  /// you fully control the HTML source (e.g. your own API, static assets).
  ///
  /// Example:
  /// ```dart
  /// // ✅ SAFE - default sanitize:true protects against XSS
  /// HyperViewer(html: userInput)
  ///
  /// // ⚠️ ONLY disable for fully trusted, controlled HTML sources
  /// HyperViewer(html: trustedStaticContent, sanitize: false)
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
  /// [HyperCaptureExtension.toImage()] and `toPngBytes()` work correctly.
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

  /// Optional controller for [HyperRenderMode.paged] mode.
  ///
  /// Provides programmatic page navigation and page-count/current-page
  /// observation.  Ignored when [mode] is not [HyperRenderMode.paged].
  ///
  /// ```dart
  /// final _page = HyperPageController();
  ///
  /// HyperViewer(
  ///   html: longContent,
  ///   mode: HyperRenderMode.paged,
  ///   pageController: _page,
  /// )
  ///
  /// // Jump to page 3
  /// _page.animateToPage(3);
  /// ```
  final HyperPageController? pageController;

  /// Optional registry of custom HTML tag plugins.
  ///
  /// Plugins registered here intercept specific HTML tag names and render them
  /// as arbitrary Flutter widgets instead of the built-in canvas renderer.
  ///
  /// ```dart
  /// final registry = HyperPluginRegistry()
  ///   ..register(MyBlockPlugin())   // isInline == false
  ///   ..register(MyInlinePlugin()); // isInline == true
  ///
  /// HyperViewer(html: html, pluginRegistry: registry)
  /// ```
  ///
  /// See [HyperNodePlugin] and [HyperPluginRegistry] for full API docs.
  final HyperPluginRegistry? pluginRegistry;

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
    this.pageController,
    this.pluginRegistry,
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
    this.pageController,
    this.pluginRegistry,
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
    this.pageController,
    this.pluginRegistry,
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
    this.pluginRegistry,
    this.onError,
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
        pageController = null,
        _prebuiltDocument = document;

  @override
  State<HyperViewer> createState() => _HyperViewerState();
}

// ──────────────────────────────────────────────────────────────────────────────
// Selection Adapters
// ──────────────────────────────────────────────────────────────────────────────

class _SyncSelectionAdapter implements HyperSelectionState {
  _SyncSelectionAdapter(this.state);
  final HyperSelectionOverlayState state;
  @override
  String? get selectedText => state.selectedText;
  @override
  void selectAll() => state.selectAll();
  @override
  void clearSelection() => state.clearSelection();
}

class _VirtualizedSelectionAdapter implements HyperSelectionState {
  _VirtualizedSelectionAdapter(this.controller);
  final VirtualizedSelectionController controller;
  @override
  String? get selectedText => controller.getSelectedText();
  @override
  void selectAll() => controller.selectAll();
  @override
  void clearSelection() => controller.clearSelection();
}

class _HyperViewerState extends State<HyperViewer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _contentFadeController;
  late final Animation<double> _contentFadeAnimation;

  // Used for Sync mode
  DocumentNode? _syncDocument;

  // Used for Virtualized / Paged mode
  List<DocumentNode>? _sections;

  /// Content fingerprint per section.
  ///
  /// Computed as `Object.hashAll` over each child node's `textContent`.
  /// When a parse produces new sections, unchanged sections (same hash) are
  /// reused from [_sections] so their [RenderHyperBox] instances skip
  /// re-layout — achieving ~90% rebuild reduction for live-updating feeds.
  List<int> _sectionHashes = const [];

  /// Internal [PageController] used when [widget.mode] is
  /// [HyperRenderMode.paged] and no external [HyperPageController] is supplied.
  PageController? _ownedPageController;

  /// The effective [PageController] for paged mode.
  PageController? get _pageCtrl =>
      widget.pageController?._ctrl ?? _ownedPageController;

  bool _isLoading = true;

  /// Float carryovers indexed by section: _floatCarryovers[N] holds the
  /// dangling floats produced by section N's layout, to be passed as
  /// initialFloats to section N+1.
  final List<List<FloatCarryover>> _floatCarryovers = [];

  /// Per-section [RenderHyperBox] registry, keyed by chunk index.
  ///
  /// Populated by the `onRenderBoxReady` callback fired in
  /// [HyperRenderWidget.createRenderObject] / `updateRenderObject` whenever a
  /// section's render object is created or updated. Lets [_onFloatCarryover]
  /// synchronously push new `initialFloats` to section N+1's RenderObject
  /// during section N's layout pass — eliminating the 1-frame visual flash
  /// that an `addPostFrameCallback + setState` round-trip causes.
  final Map<int, RenderHyperBox> _sectionBoxes = {};

  /// Monotonically-increasing counter that prevents stale isolate results
  /// from overwriting a newer parse when the content changes rapidly.
  int _parseId = 0;

  /// Last section count reported to [HyperPageController._onSectionsReady].
  /// Used to avoid re-registering [addPostFrameCallback] on every [build] call
  /// when the count hasn't changed.
  int _lastNotifiedPageCount = -1;

  /// `@keyframes` rules extracted from the document's own `<style>` tags.
  ///
  /// Merged with [HyperViewer.renderConfig.keyframeRegistry] in
  /// [_effectiveConfig] so CSS animations declared inline in the HTML
  /// automatically work without any extra configuration.
  Map<String, HyperKeyframes> _docKeyframes = const {};

  /// Cached result of [_buildEffectiveConfig].
  ///
  /// Invalidated whenever [widget.renderConfig], [widget.allowedCustomSchemes],
  /// or [_docKeyframes] changes. Avoids allocating a new [HyperRenderConfig]
  /// on every [build()] call (which runs on every scroll frame).
  HyperRenderConfig? _cachedEffectiveConfig;

  /// GlobalKey placed on the Stack that wraps the virtualized ListView.
  /// Used by [VirtualizedSelectionController] to convert chunk-local
  /// coordinates to Stack coordinates for handle and menu positioning.
  final GlobalKey _virtualizedStackKey = GlobalKey();

  /// Selection orchestrator for cross-chunk selection in virtualized mode.
  VirtualizedSelectionController? _virtualizedSelectionController;

  /// Effective render config — merges [HyperViewer.renderConfig] with:
  ///   1. `@keyframes` rules extracted from the document's own `<style>` tags.
  ///   2. [HyperViewer.allowedCustomSchemes] merged into [HyperRenderConfig.extraLinkSchemes]
  ///      so the render layer's scheme check in [RenderHyperBox.handleEvent] allows
  ///      the same custom deep-link schemes as the widget-layer [_safeOnLinkTap].
  ///
  /// Result is cached in [_cachedEffectiveConfig] and invalidated when
  /// [widget.renderConfig], [widget.allowedCustomSchemes], or [_docKeyframes] changes,
  /// avoiding per-frame allocations during scroll/animation.
  HyperRenderConfig get _effectiveConfig =>
      _cachedEffectiveConfig ??= _buildEffectiveConfig();

  HyperRenderConfig _buildEffectiveConfig() {
    final rc = widget.renderConfig;
    final customSchemes = widget.allowedCustomSchemes;
    final hasDocKeyframes = _docKeyframes.isNotEmpty;

    // Fast path: nothing to merge.
    if ((customSchemes == null || customSchemes.isEmpty) && !hasDocKeyframes) {
      return rc;
    }

    // Direct null check so Dart promotes customSchemes to List<String> in the branch.
    final mergedSchemes = (customSchemes != null && customSchemes.isNotEmpty)
        ? {...rc.extraLinkSchemes, ...customSchemes}
        : rc.extraLinkSchemes;

    final mergedKeyframes = hasDocKeyframes
        ? <String, HyperKeyframes>{...rc.keyframeRegistry, ..._docKeyframes}
        : rc.keyframeRegistry;

    return HyperRenderConfig(
      textPainterCacheSize: rc.textPainterCacheSize,
      imageCacheSize: rc.imageCacheSize,
      defaultImagePlaceholderWidth: rc.defaultImagePlaceholderWidth,
      imageConcurrency: rc.imageConcurrency,
      virtualizationChunkSize: rc.virtualizationChunkSize,
      extraLinkSchemes: mergedSchemes,
      codeHighlighter: rc.codeHighlighter,
      keyframeRegistry: mergedKeyframes,
      useMicrotaskParsing: rc.useMicrotaskParsing,
      useRepaintBoundary: rc.useRepaintBoundary,
    );
  }

  @override
  void initState() {
    super.initState();
    RenderHyperBox.setGlobalTextCacheSize(
        widget.renderConfig.textPainterCacheSize);
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
    if (widget.mode == HyperRenderMode.paged && widget.pageController == null) {
      _ownedPageController = PageController();
    }
    _parseContent();
  }

  @override
  void didUpdateWidget(covariant HyperViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // BUG-02: Handle selectable toggle — create/dispose controller as needed.
    if (oldWidget.selectable != widget.selectable) {
      if (widget.selectable) {
        _virtualizedSelectionController = VirtualizedSelectionController(
          sectionsGetter: () => _sections ?? const [],
          listViewKey: _virtualizedStackKey,
        );
      } else {
        _virtualizedSelectionController?.dispose();
        _virtualizedSelectionController = null;
      }
    }

    // BUG-05: When customCss changes the section hashes are stale (they only
    // cover text, not styles). Reset them so every section re-layouts.
    if (oldWidget.customCss != widget.customCss) {
      _sectionHashes = const [];
    }

    if (oldWidget.renderConfig.textPainterCacheSize !=
        widget.renderConfig.textPainterCacheSize) {
      RenderHyperBox.setGlobalTextCacheSize(
          widget.renderConfig.textPainterCacheSize);
    }

    // Invalidate effective-config cache when any input that affects it changes.
    if (oldWidget.renderConfig != widget.renderConfig ||
        oldWidget.allowedCustomSchemes != widget.allowedCustomSchemes) {
      _cachedEffectiveConfig = null;
    }

    if (oldWidget.content != widget.content ||
        oldWidget.contentType != widget.contentType ||
        oldWidget.mode != widget.mode ||
        oldWidget.baseUrl != widget.baseUrl ||
        oldWidget.customCss != widget.customCss ||
        oldWidget.sanitize != widget.sanitize ||
        !listEquals(oldWidget.allowedTags, widget.allowedTags) ||
        oldWidget.allowDataAttributes != widget.allowDataAttributes ||
        oldWidget.fallbackBuilder != widget.fallbackBuilder ||
        // BUG-08: Compare full renderConfig (value equality now available).
        oldWidget.renderConfig != widget.renderConfig ||
        oldWidget.pluginRegistry != widget.pluginRegistry) {
      _parseContent();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelParsing();
    _contentFadeController.dispose();
    _virtualizedSelectionController?.dispose();
    _ownedPageController?.dispose();
    super.dispose();
  }

  /// Signals that any in-flight parse result should be discarded.
  ///
  /// [compute()] futures cannot be cancelled after they start — the isolate
  /// will run to completion regardless. The [_parseId] counter ensures stale
  /// results are silently dropped when they arrive after content changes.
  /// Use [HyperRenderConfig.useMicrotaskParsing] in tests to avoid real
  /// isolate spawning.
  void _cancelParsing() {
    // Incrementing _parseId is handled by _parseContent() before each parse.
    // Nothing else to cancel here — compute() is fire-and-forget.
  }

  // ── Dirty-flag incremental layout ────────────────────────────────────────

  /// Stable content fingerprint for a single [DocumentNode] section.
  ///
  /// Walks the entire subtree and accumulates:
  ///   - Node tagName + type
  ///   - TextNode text content
  ///   - AtomicNode src/alt (so `<img src="a.jpg">` ≠ `<img src="b.jpg">`)
  ///   - All HTML attributes (so class/id/style/href changes invalidate the cache)
  ///   - Child count at every depth
  ///
  /// Without including attributes, two parses producing structurally identical
  /// trees with different `src` / `class` / `style` hash to the same value,
  /// causing [_mergeSections] to reuse the stale [DocumentNode] and silently
  /// drop the new AST — freezing dynamic content (image swaps, theme toggles,
  /// state class changes) at the first-rendered version.
  static int _hashSection(DocumentNode doc) {
    final parts = <Object?>[];
    _accumulateHashParts(doc, parts);
    return Object.hashAll(parts);
  }

  static void _accumulateHashParts(UDTNode node, List<Object?> out) {
    out
      ..add(node.type)
      ..add(node.tagName);

    if (node is TextNode) {
      // Include length explicitly. Object.hashAll on Web (JS) has weaker hash
      // quality than the VM and can collide on long strings; mixing in the
      // length signature dramatically reduces collision probability without
      // any additional traversal cost.
      out
        ..add(node.text.length)
        ..add(node.text);
    } else if (node is AtomicNode) {
      out
        ..add(node.src)
        ..add(node.alt);
    }

    // Attributes — keys sorted so map ordering doesn't change the hash.
    final attrs = node.attributes;
    if (attrs.isNotEmpty) {
      final keys = attrs.keys.toList()..sort();
      for (final k in keys) {
        out
          ..add(k)
          ..add(attrs[k]);
      }
    }

    out.add(node.children.length);
    for (final child in node.children) {
      _accumulateHashParts(child, out);
    }
  }

  /// Merges freshly parsed [newSections] with the current [_sections] list,
  /// reusing existing [DocumentNode] objects wherever the content hash is
  /// unchanged.
  ///
  /// Returns the merged list and updates [_sectionHashes] in place.
  List<DocumentNode> _mergeSections(List<DocumentNode> newSections) {
    final newHashes = newSections.map(_hashSection).toList(growable: false);
    final oldSections = _sections;
    final oldHashes = _sectionHashes;

    if (oldSections == null ||
        oldSections.isEmpty ||
        oldHashes.length != oldSections.length) {
      _sectionHashes = newHashes;
      return newSections;
    }

    // Build a map from hash → queue of old sections for O(1) reuse lookup.
    // Using a queue (not a plain map) handles hash collisions: two sections
    // with identical text content produce the same hash. With a plain map the
    // second entry silently overwrites the first, causing both new sections to
    // receive the same old DocumentNode object and producing duplicate
    // ValueKeys in the ListView (Flutter assertion error in debug mode).
    final Map<int, List<DocumentNode>> oldByHash = {};
    for (var i = 0; i < oldSections.length; i++) {
      oldByHash.putIfAbsent(oldHashes[i], () => []).add(oldSections[i]);
    }

    final merged = List<DocumentNode>.generate(newSections.length, (i) {
      final h = newHashes[i];
      final queue = oldByHash[h];
      return (queue != null && queue.isNotEmpty)
          ? queue.removeAt(0)
          : newSections[i];
    }, growable: false);

    _sectionHashes = newHashes;
    return merged;
  }

  /// Splits a [DocumentNode] into sections of approximately [chunkSize]
  /// characters for Markdown/Delta content in virtualized/paged mode.
  ///
  /// Splits only on block boundaries so inline elements are never torn apart.
  static List<DocumentNode> _splitIntoSections(
      DocumentNode doc, int chunkSize) {
    if (doc.children.isEmpty) return [doc];

    final children = doc.children;
    final sections = <DocumentNode>[];
    var current = DocumentNode(children: []);
    var currentSize = 0;

    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      current.children.add(child);
      // Only set parent when the node hasn't been assigned yet — avoids
      // overwriting the parent pointer of reused nodes from _mergeSections,
      // which would corrupt ancestor-chain traversal (e.g. link resolution).
      child.parent ??= current;
      currentSize += child.textContent.length;

      if (currentSize >= chunkSize && child.isBlock) {
        // Heading-widow guard: never end a section on a heading — the heading
        // should lead the content that follows it, not trail the section above.
        final tag = child.tagName?.toLowerCase();
        final isHeading = tag == 'h1' ||
            tag == 'h2' ||
            tag == 'h3' ||
            tag == 'h4' ||
            tag == 'h5' ||
            tag == 'h6';

        // Also guard the reverse: if the NEXT child is a heading, keep it in
        // the current section so it opens the next chunk rather than appearing
        // as a lone last element here.
        bool nextIsHeading = false;
        if (!isHeading && i + 1 < children.length) {
          final nextTag = children[i + 1].tagName?.toLowerCase();
          nextIsHeading = nextTag == 'h1' ||
              nextTag == 'h2' ||
              nextTag == 'h3' ||
              nextTag == 'h4' ||
              nextTag == 'h5' ||
              nextTag == 'h6';
        }

        if (!isHeading && !nextIsHeading) {
          sections.add(current);
          current = DocumentNode(children: []);
          currentSize = 0;
        }
      }
    }

    if (current.children.isNotEmpty) sections.add(current);
    if (sections.isEmpty) sections.add(DocumentNode(children: []));
    return sections;
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
    return (UDTNode node) => buildSvgWidget(node) ?? userBuilder?.call(node);
  }

  /// Stores dangling floats from section [index] so section [index+1] picks
  /// them up the next time it lays out.
  ///
  /// Called from `RenderHyperBox.performLayout` during section [index]'s
  /// layout pass. We CANNOT call [setState] here ("setState during layout"
  /// assertion) so we mutate [_floatCarryovers] silently and push the new
  /// floats directly onto section [index+1]'s RenderObject (when registered
  /// via [_sectionBoxes]). The RO's `initialFloats` setter calls
  /// `markNeedsLayout()`, which Flutter's pipeline owner picks up — section
  /// [index+1] then lays out with the correct initialFloats IN THE SAME
  /// frame, avoiding the 1-frame visual flash that an
  /// `addPostFrameCallback + setState` round-trip caused previously.
  ///
  /// When section [index+1] hasn't been built yet (outside viewport), the
  /// direct-update path is skipped — but [_floatCarryovers] is still updated
  /// so [ListView.builder]'s itemBuilder picks up the correct value when the
  /// section eventually scrolls into view.
  void _onFloatCarryover(int index, List<FloatCarryover> carryovers) {
    if (!mounted) return;
    // Grow the list if needed.
    while (_floatCarryovers.length <= index) {
      _floatCarryovers.add(const []);
    }
    // No-op short-circuit: nothing to propagate.
    final prev = _floatCarryovers[index];
    if (prev.isEmpty && carryovers.isEmpty) return;

    bool isSame = prev.length == carryovers.length;
    if (isSame) {
      for (int i = 0; i < prev.length; i++) {
        if (prev[i].direction != carryovers[i].direction ||
            prev[i].width != carryovers[i].width ||
            prev[i].overhangHeight != carryovers[i].overhangHeight) {
          isSame = false;
          break;
        }
      }
    }
    if (isSame) return;

    // 1) Update storage immediately — itemBuilder closures capture this list,
    //    so subsequent rebuilds (and any later widget reads) see the new value
    //    without needing setState.
    _floatCarryovers[index] = carryovers;

    // 2) Push directly onto section N+1's RenderObject if it exists. Because
    //    we're running inside section N's performLayout (i.e. before section
    //    N+1's layout begins), the markNeedsLayout that fires from the setter
    //    is consumed by the same frame's pipeline — section N+1 lays out with
    //    the new initialFloats and the text wraps correctly on first paint.
    final next = _sectionBoxes[index + 1];
    if (next != null && next.attached) {
      next.initialFloats = carryovers;
    }
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
      // Relative URLs (scheme == '') are always forwarded — the app's handler
      // is responsible for resolving them against a base URL.
      final isRelative = scheme.isEmpty;
      // BUG-03/09: Check BOTH allowedCustomSchemes (legacy widget param) AND
      // renderConfig.extraLinkSchemes so neither registration path silently
      // drops deep-link taps.
      final customSchemes = widget.allowedCustomSchemes;
      final configSchemes = widget.renderConfig.extraLinkSchemes;
      final isAllowed = isRelative ||
          _kAllowedSchemes.contains(scheme) ||
          (customSchemes != null && customSchemes.contains(scheme)) ||
          configSchemes.contains(scheme);
      if (isAllowed) {
        handler(url);
      } else {
        assert(() {
          debugPrint(
              '[HyperRender] Blocked link tap with disallowed scheme: $url');
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

  /// Returns the CSS parser used for @keyframes extraction.
  CssParserInterface _getDefaultCssParser() => const DefaultCssParser();

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

    // Reset extracted keyframes and section hash cache so stale animations /
    // dirty-flag data don't persist across full content changes.
    _docKeyframes = const {};
    _cachedEffectiveConfig = null;
    _sectionHashes = const [];
    _lastNotifiedPageCount = -1;
    // Drop stale section RenderBox references — new sections will re-register
    // via onRenderBoxReady. Without this, _onFloatCarryover could write to a
    // RenderObject belonging to the previous document.
    _sectionBoxes.clear();

    String contentToRender = widget.content;
    // CSS collected from <style> tags + customCss (applied to resolver directly,
    // not injected as a <style> tag so the sanitizer cannot strip it).
    // customCss applies to all content types (HTML, Markdown, Delta).
    String cssToApply = widget.customCss ?? '';

    if (widget.contentType == HyperContentType.html) {
      // 1. Extract CSS from <style> elements BEFORE sanitization.
      //    The sanitizer strips <style> tags, so we must grab them first.
      final adapter = HtmlAdapter();
      final docCss = adapter.extractCss(contentToRender);

      // customCss is lower priority (applied first); docCss wins on conflict.
      if (docCss.isNotEmpty) {
        cssToApply = '${widget.customCss ?? ''}\n$docCss';
      }

      // Extract @keyframes rules so CSS animations declared inside <style>
      // tags work automatically (merged into _effectiveConfig.keyframeRegistry).
      if (docCss.isNotEmpty) {
        final cssParser = _getDefaultCssParser();
        final extracted = cssParser.parseKeyframes(docCss);
        if (extracted.isNotEmpty) {
          _docKeyframes = extracted;
          _cachedEffectiveConfig = null;
        }
      }

      // 2. Sanitize (strips <style> tags — safe, CSS already extracted above)
      // Note: baseUrl resolution is handled INSIDE the parser/adapter
      // for better robustness than regex replacement.
      if (widget.sanitize) {
        contentToRender = HtmlSanitizer.sanitize(
          contentToRender,
          allowedTags: widget.allowedTags,
          allowDataAttributes: widget.allowDataAttributes,
        );
      }
    } else if (widget.contentType == HyperContentType.markdown &&
        widget.sanitize) {
      // Markdown with `enableInlineHtml: true` (the default) passes raw HTML
      // straight to the renderer; `<script>` / `<style>` / `<iframe>` blocks
      // would otherwise survive into inline nodes and either flash as visible
      // garbage or — for plugin authors who self-execute embedded scripts —
      // become a live XSS surface. Pre-sanitize the markdown string so the
      // same blocklist used for HTML applies; plain markdown syntax (`#`,
      // `*`, `[`) is left untouched because the HTML parser treats it as
      // text content.
      contentToRender = HtmlSanitizer.sanitize(
        contentToRender,
        allowedTags: widget.allowedTags,
        allowDataAttributes: widget.allowDataAttributes,
      );
    }

    final useVirtualization = widget.mode == HyperRenderMode.virtualized ||
        widget.mode == HyperRenderMode.paged ||
        (widget.mode == HyperRenderMode.auto && contentToRender.length > 10000);

    final parser = _getDefaultParser();

    if (!useVirtualization) {
      // Sync parsing (fast path for small content)
      _contentFadeController.reset();
      try {
        final doc = parser is ExtendedContentParser
            ? parser.parseWithOptions(contentToRender,
                baseUrl: widget.baseUrl, customCss: cssToApply)
            : parser.parse(contentToRender);

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

        final args = (
          contentToRender,
          cssToApply,
          widget.baseUrl,
          widget.renderConfig.virtualizationChunkSize,
        );

        Future<List<DocumentNode>> parseFuture;
        if (widget.renderConfig.useMicrotaskParsing || kIsWeb) {
          parseFuture = Future.microtask(() => _parseAndChunk(args));
        } else {
          parseFuture = compute(_parseAndChunk, args);
        }

        parseFuture.then((fresh) {
          if (!mounted || _parseId != currentParseId) return;
          final merged = _mergeSections(fresh);
          setState(() {
            _sections = merged;
            _syncDocument = null;
            _isLoading = false;
            _floatCarryovers.clear(); // reset carryovers for new content
          });
          _contentFadeController.forward();
        }).catchError((Object e, StackTrace st) {
          if (mounted && _parseId == currentParseId) {
            _reportError(e, st);
            setState(() => _isLoading = false);
          }
        });
      } else {
        // Fallback to sync parsing for Delta/Markdown in virtualized/paged mode.
        _contentFadeController.reset();
        try {
          final doc = parser is ExtendedContentParser
              ? parser.parseWithOptions(contentToRender,
                  baseUrl: widget.baseUrl, customCss: cssToApply)
              : parser.parse(contentToRender);

          final resolver = StyleResolver();
          if (cssToApply.isNotEmpty) resolver.parseCss(cssToApply);
          resolver.resolveStyles(doc);

          // BUG-06: Markdown/Delta in virtualized/paged mode was wrapped as a
          // single section, defeating the virtualization entirely for large docs.
          // Split the document into chunkSize-bounded sections so the correct
          // ListView/PageView builder gets multiple sections to work with.
          final chunkSize = widget.renderConfig.virtualizationChunkSize;
          final rawSections = _splitIntoSections(doc, chunkSize);
          final merged = _mergeSections(rawSections);
          setState(() {
            _sections = merged;
            _syncDocument = null;
            _isLoading = false;
            _floatCarryovers.clear();
          });
          _contentFadeController.forward();
        } catch (e, st) {
          _reportError(e, st);
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // Static function that runs in an isolate — must not capture context.
  // Accepts a (html, css, baseUrl, chunkSize) record so CSS rules are available inside the isolate.
  static List<DocumentNode> _parseAndChunk(
      (String, String, String?, int) args) {
    final (html, css, baseUrl, chunkSize) = args;
    final adapter = HtmlAdapter();
    // chunkSize: keeps each RenderHyperBox well under GPU texture limits
    // (~4096px physical on most devices). Configurable via HyperRenderConfig.
    final sections =
        adapter.parseToSections(html, chunkSize: chunkSize, baseUrl: baseUrl);

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

    // Case 1a: Paged mode (PageView.builder, one chunk per page)
    if (_sections != null && widget.mode == HyperRenderMode.paged) {
      return _buildPagedContent(context);
    }

    // Case 1b: Virtualized List (for long text)
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
          // Retrieve carryover from previous section (if layout already ran).
          final prevCarryover = (index > 0 && _floatCarryovers.length >= index)
              ? _floatCarryovers[index - 1]
              : const <FloatCarryover>[];
          // ValueKey from the section hash: Flutter reconciles list items by
          // key, so unchanged sections keep their existing RenderHyperBox and
          // skip re-layout entirely (dirty-flag incremental layout).
          final sectionKey = _sectionHashes.length > index
              ? ValueKey(_sectionHashes[index])
              : ValueKey(index);
          final Widget chunk = selCtrl != null
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
                  config: _effectiveConfig,
                  suppressFirstBlockMarginTop: index > 0,
                  initialFloats: prevCarryover,
                  onFloatCarryover: (carryovers) =>
                      _onFloatCarryover(index, carryovers),
                  pluginRegistry: widget.pluginRegistry,
                  onRenderBoxReady: (box) => _sectionBoxes[index] = box,
                )
              : HyperRenderWidget(
                  document: _sections![index],
                  selectable: false,
                  textDirection: dir,
                  onLinkTap: _safeOnLinkTap,
                  widgetBuilder: _effectiveWidgetBuilder,
                  debugShowBounds: widget.debugShowHyperRenderBounds,
                  enableComplexFilters: widget.enableComplexFilters,
                  config: _effectiveConfig,
                  suppressFirstBlockMarginTop: index > 0,
                  initialFloats: prevCarryover,
                  onFloatCarryover: (carryovers) =>
                      _onFloatCarryover(index, carryovers),
                  pluginRegistry: widget.pluginRegistry,
                  onRenderBoxReady: (box) => _sectionBoxes[index] = box,
                );

          // RenderHyperBox is already an internal RepaintBoundary
          // (isRepaintBoundary => true); the outer widget-layer wrapper adds
          // explicit isolation that ListView's compositor recognises. On
          // very low-RAM devices with many small chunks the extra layers can
          // exhaust VRAM, so HyperRenderConfig.useRepaintBoundary lets users
          // opt out.
          if (_effectiveConfig.useRepaintBoundary) {
            return RepaintBoundary(key: sectionKey, child: chunk);
          }
          return KeyedSubtree(key: sectionKey, child: chunk);
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
              selectionMenuActionsBuilder:
                  widget.selectionMenuActionsBuilder != null
                      ? (ctrl) => widget.selectionMenuActionsBuilder!(
                          _VirtualizedSelectionAdapter(ctrl))
                      : null,
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

    // Case 2: Single Widget (for short text)
    if (_syncDocument != null) {
      Widget content;

      // Use HyperSelectionOverlay for full selection UX with popup menu
      if (widget.selectable && widget.showSelectionMenu) {
        content = HyperSelectionOverlay(
          document: _syncDocument!,
          selectable: true,
          onLinkTap: _safeOnLinkTap,
          widgetBuilder: _effectiveWidgetBuilder,
          handleColor:
              widget.selectionHandleColor ?? Theme.of(context).primaryColor,
          selectionColor: widget.selectionColor,
          menuActionsBuilder: widget.selectionMenuActionsBuilder != null
              ? (state) => widget
                  .selectionMenuActionsBuilder!(_SyncSelectionAdapter(state))
              : null,
          contextMenuBuilder: widget.selectionContextMenuBuilder,
          showHandles: true,
          autoShowMenu: true,
          debugShowBounds: widget.debugShowHyperRenderBounds,
          onAnchorLayout: widget.controller?._onAnchorLayout,
          config: _effectiveConfig,
          pluginRegistry: widget.pluginRegistry,
          enableComplexFilters: widget.enableComplexFilters,
        );
      } else {
        // Use HyperRenderWidget directly (no popup menu)
        content = HyperRenderWidget(
          document: _syncDocument!,
          selectable: widget.selectable,
          onLinkTap: _safeOnLinkTap,
          widgetBuilder: _effectiveWidgetBuilder,
          debugShowBounds: widget.debugShowHyperRenderBounds,
          onAnchorLayout: widget.controller?._onAnchorLayout,
          config: _effectiveConfig,
          pluginRegistry: widget.pluginRegistry,
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
                    physics:
                        widget.physics ?? const AlwaysScrollableScrollPhysics(),
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

  // ── Paged rendering ───────────────────────────────────────────────────────

  Widget _buildPagedContent(BuildContext context) {
    final sections = _sections!;
    final dir = widget.textDirection ?? Directionality.of(context);
    final ctrl = _pageCtrl;

    // Notify the HyperPageController about the final page count once sections
    // are ready (post-frame so the PageView has been built).
    // Guard: only register once per distinct count to avoid accumulating
    // callbacks on every build() call (e.g. during scroll or parent rebuilds).
    if (sections.length != _lastNotifiedPageCount &&
        widget.pageController != null) {
      _lastNotifiedPageCount = sections.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.pageController?._onSectionsReady(sections.length);
      });
    }

    final pageView = PageView.builder(
      controller: ctrl,
      itemCount: sections.length,
      onPageChanged: widget.pageController?._onPageChanged,
      itemBuilder: (context, index) {
        final sectionKey = _sectionHashes.length > index
            ? ValueKey('${_sectionHashes[index]}_$index')
            : ValueKey(index);
        // Each page: full available height, with vertical scroll for overflowing
        // sections (e.g. a single very long chapter).
        final Widget pageContent;
        if (widget.selectable && widget.showSelectionMenu) {
          pageContent = HyperSelectionOverlay(
            document: sections[index],
            selectable: true,
            onLinkTap: _safeOnLinkTap,
            widgetBuilder: _effectiveWidgetBuilder,
            handleColor:
                widget.selectionHandleColor ?? Theme.of(context).primaryColor,
            selectionColor: widget.selectionColor,
            menuActionsBuilder: widget.selectionMenuActionsBuilder != null
                ? (state) => widget
                    .selectionMenuActionsBuilder!(_SyncSelectionAdapter(state))
                : null,
            contextMenuBuilder: widget.selectionContextMenuBuilder,
            showHandles: true,
            autoShowMenu: true,
            debugShowBounds: widget.debugShowHyperRenderBounds,
            config: _effectiveConfig,
            pluginRegistry: widget.pluginRegistry,
            enableComplexFilters: widget.enableComplexFilters,
          );
        } else {
          pageContent = HyperRenderWidget(
            document: sections[index],
            selectable: widget.selectable,
            textDirection: dir,
            onLinkTap: _safeOnLinkTap,
            widgetBuilder: _effectiveWidgetBuilder,
            debugShowBounds: widget.debugShowHyperRenderBounds,
            enableComplexFilters: widget.enableComplexFilters,
            config: _effectiveConfig,
            suppressFirstBlockMarginTop: index > 0,
            pluginRegistry: widget.pluginRegistry,
          );
        }

        final scrollable = SingleChildScrollView(
          physics: widget.physics ?? const ClampingScrollPhysics(),
          child: pageContent,
        );
        if (_effectiveConfig.useRepaintBoundary) {
          return RepaintBoundary(key: sectionKey, child: scrollable);
        }
        return KeyedSubtree(key: sectionKey, child: scrollable);
      },
    );

    return KeyedSubtree(
      key: const ValueKey('paged'),
      child: widget.enableZoom
          ? InteractiveViewer(
              panEnabled: false,
              scaleEnabled: true,
              minScale: widget.minScale,
              maxScale: widget.maxScale,
              child: pageView,
            )
          : pageView,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HyperPageController — paged-mode navigation
// ─────────────────────────────────────────────────────────────────────────────

/// Controller for [HyperViewer] in [HyperRenderMode.paged] mode.
///
/// Provides programmatic navigation and exposes the current page and total
/// page count as a [ValueNotifier] so the UI can react to page changes.
///
/// ```dart
/// final _page = HyperPageController();
///
/// @override
/// void dispose() {
///   _page.dispose();
///   super.dispose();
/// }
///
/// // Jump to page 5 with animation
/// _page.animateToPage(5);
///
/// // Listen to page changes
/// ValueListenableBuilder<int>(
///   valueListenable: _page.currentPage,
///   builder: (context, page, _) => Text('Page ${page + 1} / ${_page.pageCount}'),
/// )
/// ```
class HyperPageController {
  final PageController _ctrl;

  /// The current page index (0-based). Updated on every page change.
  final ValueNotifier<int> currentPage;

  HyperPageController({int initialPage = 0})
      : currentPage = ValueNotifier<int>(initialPage),
        _ctrl = PageController(initialPage: initialPage);

  /// Total number of pages.  Updated once the document has been parsed.
  int get pageCount => _pageCount;
  int _pageCount = 0;

  void _onPageChanged(int page) {
    currentPage.value = page;
  }

  void _onSectionsReady(int count) {
    _pageCount = count;
  }

  /// Animate to [page] (0-based).
  void animateToPage(
    int page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    _ctrl.animateToPage(page, duration: duration, curve: curve);
  }

  /// Jump to [page] instantly without animation.
  void jumpToPage(int page) => _ctrl.jumpToPage(page);

  /// Move to the next page if one exists.
  void nextPage({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    _ctrl.nextPage(duration: duration, curve: curve);
  }

  /// Move to the previous page if one exists.
  void previousPage({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    _ctrl.previousPage(duration: duration, curve: curve);
  }

  /// Release resources.  Call this in the parent widget's [State.dispose].
  void dispose() {
    _ctrl.dispose();
    currentPage.dispose();
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
