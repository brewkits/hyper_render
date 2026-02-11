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
    this.enableZoom = false,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.contentParser,
    this.codeHighlighter,
    this.showSelectionMenu = true,
    this.selectionHandleColor,
    this.selectionMenuActionsBuilder,
    this.selectionContextMenuBuilder,
    this.sanitize = false,
    this.allowedTags,
    this.allowDataAttributes = false,
    this.semanticLabel,
    this.excludeSemantics = false,
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
    this.enableZoom = false,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.contentParser,
    this.codeHighlighter,
    this.showSelectionMenu = true,
    this.selectionHandleColor,
    this.selectionMenuActionsBuilder,
    this.selectionContextMenuBuilder,
    this.sanitize = false,
    this.allowedTags,
    this.allowDataAttributes = false,
    this.semanticLabel,
    this.excludeSemantics = false,
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
    this.enableZoom = false,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.contentParser,
    this.codeHighlighter,
    this.showSelectionMenu = true,
    this.selectionHandleColor,
    this.selectionMenuActionsBuilder,
    this.selectionContextMenuBuilder,
    this.sanitize = false,
    this.allowedTags,
    this.allowDataAttributes = false,
    this.semanticLabel,
    this.excludeSemantics = false,
  })  : content = markdown,
        contentType = HyperContentType.markdown;

  @override
  State<HyperViewer> createState() => _HyperViewerState();
}

class _HyperViewerState extends State<HyperViewer> {
  // Dùng cho chế độ Sync
  DocumentNode? _syncDocument;

  // Dùng cho chế độ Virtualized
  List<DocumentNode>? _sections;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _parseContent();
  }

  @override
  void didUpdateWidget(covariant HyperViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.contentType != widget.contentType ||
        oldWidget.mode != widget.mode) {
      _parseContent();
    }
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
    // Sanitize content if enabled (HTML only)
    final contentToRender = widget.sanitize &&
            widget.contentType == HyperContentType.html
        ? HtmlSanitizer.sanitize(
            widget.content,
            allowedTags: widget.allowedTags,
            allowDataAttributes: widget.allowDataAttributes,
          )
        : widget.content;

    final useVirtualization = widget.mode == HyperRenderMode.virtualized ||
        (widget.mode == HyperRenderMode.auto && contentToRender.length > 10000);

    final parser = _getDefaultParser();

    if (!useVirtualization) {
      // 1. Sync Parsing (Fast path for small content)
      setState(() {
        _syncDocument = parser.parse(contentToRender);
        StyleResolver().resolveStyles(_syncDocument!);
        _sections = null;
        _isLoading = false;
      });
    } else {
      // 2. Async Parsing (Isolate path for large content)
      // Note: For virtualized mode, we only support HTML currently
      // Delta and Markdown are parsed synchronously
      if (widget.contentType == HyperContentType.html) {
        setState(() => _isLoading = true);

        compute(_parseAndChunk, contentToRender).then((sections) {
          if (mounted) {
            setState(() {
              _sections = sections;
              _syncDocument = null;
              _isLoading = false;
            });
          }
        });
      } else {
        // Fallback to sync parsing for Delta/Markdown
        setState(() {
          _syncDocument = parser.parse(contentToRender);
          StyleResolver().resolveStyles(_syncDocument!);
          _sections = null;
          _isLoading = false;
        });
      }
    }
  }

  // Hàm static để chạy trong Isolate (không được dính context)
  static List<DocumentNode> _parseAndChunk(String html) {
    final adapter = HtmlAdapter();
    // Increased chunkSize from 12000 to 25000 for better performance:
    // - 800K HTML → ~32 sections (vs 67 sections with 12000)
    // - Larger sections mean fewer layout passes
    // - ListView.builder still virtualizes efficiently
    // - Each section renders independently, so larger = fewer re-layouts
    final sections = adapter.parseToSections(html, chunkSize: 25000);

    // Resolve styles luôn trong isolate để main thread nhẹ gánh
    final resolver = StyleResolver();
    for (var section in sections) {
      resolver.resolveStyles(section);
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    print('📺 [HyperViewer] build() called, contentType=${widget.contentType}, onLinkTap=${widget.onLinkTap != null ? 'SET' : 'NULL'}');

    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _buildContent(context),
    );

    // Wrap with Semantics for accessibility
    return Semantics(
      label: widget.semanticLabel ?? 'Article content',
      excludeSemantics: widget.excludeSemantics,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    print('📺 [HyperViewer] _buildContent: isLoading=$_isLoading, sections=${_sections != null ? 'YES(${_sections!.length})' : 'NO'}, syncDocument=${_syncDocument != null ? 'YES' : 'NO'}');

    if (_isLoading) {
      print('📺 [HyperViewer] Showing loading indicator');
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
      print('📺 [HyperViewer] Using VIRTUALIZED mode with ${_sections!.length} sections');
      return KeyedSubtree(
        key: const ValueKey('virtualized'),
        child: ListView.builder(
          // Increased cacheExtent to 1500 for smoother scrolling with large documents:
          // - Pre-renders ~1-2 screens ahead/behind
          // - Reduces visible lag during fast scrolling
          // - Trade-off: slightly higher memory usage
          cacheExtent: 1500,
          physics: const BouncingScrollPhysics(),
          itemCount: _sections!.length,
          itemBuilder: (context, index) {
            return HyperRenderWidget(
              document: _sections![index],
              selectable: widget.selectable,
              onLinkTap: widget.onLinkTap,
              widgetBuilder: widget.widgetBuilder,
            );
          },
        ),
      );
    }

    // Case 2: Single Widget (cho văn bản ngắn)
    if (_syncDocument != null) {
      print('📺 [HyperViewer] Using SYNC mode, selectable=${widget.selectable}, showSelectionMenu=${widget.showSelectionMenu}');
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
        );
      } else {
        // Use HyperRenderWidget directly (no popup menu)
        content = HyperRenderWidget(
          document: _syncDocument!,
          selectable: widget.selectable,
          onLinkTap: widget.onLinkTap,
          widgetBuilder: widget.widgetBuilder,
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: content,
            ),
          ),
        );
      }

      // No zoom - standard scroll view
      return KeyedSubtree(
        key: const ValueKey('sync'),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: content,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}