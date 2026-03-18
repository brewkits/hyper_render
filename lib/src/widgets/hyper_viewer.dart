import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/render_hyper_box.dart';
import '../interfaces/code_highlighter.dart';
import '../interfaces/content_parser.dart';
import '../model/node.dart';
import '../parser/html/html_adapter.dart';
import '../plugins/default_delta_parser.dart';
import '../plugins/default_html_parser.dart';
import '../plugins/default_markdown_parser.dart';
import '../style/resolver.dart';
import '../utils/html_heuristics.dart';
import '../utils/html_sanitizer.dart';
import 'hyper_render_widget.dart';
import 'hyper_selection_overlay.dart';

/// Chế độ render
enum HyperRenderMode {
  /// Tự động chọn (Nếu HTML ngắn -> Sync, nếu dài -> Async + Virtualization)
  auto,
  /// Render đồng bộ trên Main Thread (Tốt cho text ngắn)
  sync,
  /// Render bất đồng bộ + ListView (Tốt cho text dài)
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
  /// Defaults to [BouncingScrollPhysics].
  final ScrollPhysics? physics;

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
    this.captureKey,
    this.shrinkWrap = false,
    this.physics,
  })  : content = html,
        contentType = HyperContentType.html;

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
    this.captureKey,
    this.shrinkWrap = false,
    this.physics,
  })  : content = delta,
        contentType = HyperContentType.delta;

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
    this.captureKey,
    this.shrinkWrap = false,
    this.physics,
  })  : content = markdown,
        contentType = HyperContentType.markdown;

  @override
  State<HyperViewer> createState() => _HyperViewerState();
}

class _HyperViewerState extends State<HyperViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _contentFadeController;
  late final Animation<double> _contentFadeAnimation;
  // Dùng cho chế độ Sync
  DocumentNode? _syncDocument;

  // Dùng cho chế độ Virtualized
  List<DocumentNode>? _sections;
  bool _isLoading = true;

  /// Monotonically-increasing counter that prevents stale isolate results
  /// from overwriting a newer parse when the content changes rapidly.
  int _parseId = 0;

  @override
  void initState() {
    super.initState();
    _contentFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _contentFadeAnimation = CurvedAnimation(
      parent: _contentFadeController,
      curve: Curves.easeOut,
    );
    _parseContent();
  }

  @override
  void didUpdateWidget(covariant HyperViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.contentType != widget.contentType ||
        oldWidget.mode != widget.mode ||
        oldWidget.baseUrl != widget.baseUrl ||
        oldWidget.customCss != widget.customCss) {
      _parseContent();
    }
  }

  @override
  void dispose() {
    _contentFadeController.dispose();
    super.dispose();
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
        contentToRender = _resolveRelativeUrls(contentToRender, widget.baseUrl!);
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
      setState(() {
        _syncDocument = parser.parse(contentToRender);
        final resolver = StyleResolver();
        if (cssToApply.isNotEmpty) resolver.parseCss(cssToApply);
        resolver.resolveStyles(_syncDocument!);
        _sections = null;
        _isLoading = false;
      });
      _contentFadeController.forward();
    } else {
      // Async parsing (isolate path for large HTML content)
      if (widget.contentType == HyperContentType.html) {
        _contentFadeController.reset();
        setState(() => _isLoading = true);

        // Capture parse ID before async gap to detect stale results.
        final currentParseId = ++_parseId;
        compute(_parseAndChunk, (contentToRender, cssToApply)).then((sections) {
          if (mounted && _parseId == currentParseId) {
            setState(() {
              _sections = sections;
              _syncDocument = null;
              _isLoading = false;
            });
            _contentFadeController.forward();
          }
        });
      } else {
        // Fallback to sync parsing for Delta/Markdown
        _contentFadeController.reset();
        setState(() {
          _syncDocument = parser.parse(contentToRender);
          final resolver = StyleResolver();
          if (cssToApply.isNotEmpty) resolver.parseCss(cssToApply);
          resolver.resolveStyles(_syncDocument!);
          _sections = null;
          _isLoading = false;
        });
        _contentFadeController.forward();
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
        if (uri == null || uri.hasScheme) return m.group(0)!; // already absolute
        final resolved = baseUri.resolveUri(uri).toString();
        // Preserve original quote style
        final quote = m.group(0)!.contains('"') ? '"' : "'";
        return '$attr=$quote$resolved$quote';
      },
    );
  }

  // Static function that runs in an isolate — must not capture context.
  // Accepts a (html, css) record so CSS rules are available inside the isolate.
  static List<DocumentNode> _parseAndChunk((String, String) args) {
    final (html, css) = args;
    final adapter = HtmlAdapter();
    // chunkSize 6000: keeps each RenderHyperBox well under GPU texture limits
    // (~4096px physical on most devices). Smaller chunks spread layout cost
    // across frames and reduce peak memory vs the old 25000 setting.
    final sections = adapter.parseToSections(html, chunkSize: 6000);

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
    // Note: Zoom is NOT supported in virtualized mode due to:
    // 1. Conflicting scroll gestures between InteractiveViewer and ListView
    // 2. Unbounded constraints issues
    // 3. Performance considerations with large documents
    if (_sections != null) {
      return KeyedSubtree(
        key: const ValueKey('virtualized'),
        child: ListView.builder(
          // cacheExtent 800: pre-renders ~1 screen ahead/behind. Smaller than
          // the old 1500 because chunks are now 6000 chars (was 25000), so
          // each item is cheaper — we need fewer pixels of pre-render buffer.
          cacheExtent: 800,
          shrinkWrap: widget.shrinkWrap,
          physics: widget.physics ?? const BouncingScrollPhysics(),
          itemCount: _sections!.length,
          itemBuilder: (context, index) {
            // RepaintBoundary isolates each chunk into its own GPU layer.
            // Prevents a re-paint in one chunk from invalidating neighbours,
            // and keeps each composited layer well under GL_MAX_TEXTURE_SIZE.
            return RepaintBoundary(
              child: HyperRenderWidget(
                document: _sections![index],
                selectable: widget.selectable,
                selectionColor: widget.selectionColor,
                textDirection: widget.textDirection ?? Directionality.of(context),
                onLinkTap: widget.onLinkTap,
                widgetBuilder: widget.widgetBuilder,
                debugShowBounds: widget.debugShowHyperRenderBounds,
              ),
            );
          },
        ),
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
          widgetBuilder: widget.widgetBuilder,
          handleColor: widget.selectionHandleColor ?? Theme.of(context).primaryColor,
          menuActionsBuilder: widget.selectionMenuActionsBuilder,
          contextMenuBuilder: widget.selectionContextMenuBuilder,
          showHandles: true,
          autoShowMenu: true,
          debugShowBounds: widget.debugShowHyperRenderBounds,
        );
      } else {
        // Use HyperRenderWidget directly (no popup menu)
        content = HyperRenderWidget(
          document: _syncDocument!,
          selectable: widget.selectable,
          onLinkTap: widget.onLinkTap,
          widgetBuilder: widget.widgetBuilder,
          debugShowBounds: widget.debugShowHyperRenderBounds,
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
                    physics: widget.physics ?? const BouncingScrollPhysics(),
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
          physics: widget.physics ?? const BouncingScrollPhysics(),
          child: content,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}