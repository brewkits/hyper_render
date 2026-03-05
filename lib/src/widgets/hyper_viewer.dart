import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_html/hyper_render_html.dart';
import 'package:hyper_render_markdown/hyper_render_markdown.dart';

// ---------------------------------------------------------------------------
// Isolate helpers
// ---------------------------------------------------------------------------

/// Parameters passed to the background isolate for parsing.
class _ParseParams {
  final String content;
  final String contentType; // 'html' | 'markdown' | 'delta'
  final bool sanitize;
  final List<String>? allowedTags;
  final List<String>? allowedAttributes;
  final bool allowDataAttributes;
  final String? baseUrl;
  final String customCss;

  const _ParseParams({
    required this.content,
    required this.contentType,
    required this.sanitize,
    this.allowedTags,
    this.allowedAttributes,
    required this.allowDataAttributes,
    this.baseUrl,
    required this.customCss,
  });
}

/// Top-level function required by [compute] — runs in a separate isolate.
DocumentNode _parseInIsolate(_ParseParams p) {
  // Must set the static parser inside THIS isolate's global state.
  CssRuleIndex.parser = DefaultHtmlParser();

  String content = p.content;
  if (p.contentType == 'html' && p.sanitize) {
    content = HtmlSanitizer.sanitize(
      content,
      allowedTags: p.allowedTags,
      allowedAttributes: p.allowedAttributes,
      allowDataAttributes: p.allowDataAttributes,
    );
  }

  final ContentParser parser;
  switch (p.contentType) {
    case 'markdown':
      parser = const MarkdownContentParser();
      break;
    case 'delta':
      parser = DeltaAdapter();
      break;
    default:
      parser = DefaultHtmlParser();
  }

  return parser.parseWithOptions(
    content,
    baseUrl: p.baseUrl,
    customCss: p.customCss,
  );
}

// ---------------------------------------------------------------------------
// HyperViewer
// ---------------------------------------------------------------------------

/// A high-level widget that renders HTML, Markdown, or Quill Delta content
/// using HyperRender's custom layout engine.
///
/// `HyperViewer` is the primary entry point for embedding rich text content
/// in a Flutter application. It handles parsing, optional sanitization,
/// scrolling, and accessibility out of the box.
///
/// **Basic HTML usage:**
/// ```dart
/// HyperViewer(
///   html: '<h1>Hello World</h1><p>Some paragraph text.</p>',
///   onLinkTap: (url) => launchUrl(Uri.parse(url)),
/// )
/// ```
///
/// **Markdown usage:**
/// ```dart
/// HyperViewer.markdown(
///   markdown: '# Hello\n\nSome **bold** text.',
/// )
/// ```
///
/// **Quill Delta usage:**
/// ```dart
/// HyperViewer.delta(
///   delta: '{"ops":[{"insert":"Hello\\n"}]}',
/// )
/// ```
///
/// For HTML that contains unsupported CSS features (e.g. `position:fixed`,
/// `canvas` elements), use [fallbackBuilder] to display a native Flutter
/// widget instead:
/// ```dart
/// HyperViewer(
///   html: complexHtml,
///   fallbackBuilder: (_) => const Text('Content not supported'),
/// )
/// ```
class HyperViewer extends StatefulWidget {
  /// Raw content string (HTML, Markdown, or Delta JSON).
  /// Use the [html], [markdown], or [delta] named constructor parameter instead.
  final String content;

  /// The content format (html, markdown, or delta).
  final HyperContentType contentType;

  /// Rendering mode: [HyperRenderMode.auto] selects the best strategy based
  /// on content size; [HyperRenderMode.sync] always renders inline;
  /// [HyperRenderMode.virtualized] uses a lazy list for large documents.
  final HyperRenderMode mode;

  /// Whether the user can select and copy text. Defaults to `true`.
  final bool selectable;

  /// Callback invoked when the user taps a hyperlink. Receives the resolved URL.
  final Function(String)? onLinkTap;

  /// Callback invoked when the user taps an image. Receives the image URL.
  /// Only fires for `<img>` elements not already handled by [widgetBuilder].
  final void Function(String url)? onImageTap;

  /// Builder for custom widgets to replace atomic elements (e.g. `<img>`,
  /// `<video>`, custom HTML elements). Return `null` to fall back to the
  /// default behaviour.
  final HyperWidgetBuilder? widgetBuilder;

  /// Builder shown while the document is being parsed. Defaults to a
  /// [CircularProgressIndicator].
  final WidgetBuilder? placeholderBuilder;

  /// Base URL used to resolve relative URLs in `src` and `href` attributes.
  final String? baseUrl;

  /// Additional CSS injected after the document's own `<style>` blocks.
  ///
  /// ⚠️ **Security**: Do not pass user-supplied CSS strings here without
  /// server-side sanitization. Unlike the [html] parameter (which is sanitized
  /// by default), [customCss] is trusted as-is and injected directly into
  /// the style resolver.
  final String? customCss;

  /// When `true`, draws coloured outlines around each render box for debugging.
  final bool debugShowHyperRenderBounds;

  /// Enables pinch-to-zoom via [InteractiveViewer]. Defaults to `false`.
  final bool enableZoom;

  /// Minimum zoom scale (only relevant when [enableZoom] is `true`).
  final double minScale;

  /// Maximum zoom scale (only relevant when [enableZoom] is `true`).
  final double maxScale;

  /// Whether to strip unsafe HTML tags and attributes before rendering.
  /// Defaults to `true` for HTML; `false` for Delta.
  final bool sanitize;

  /// Additional HTML tags to allow when [sanitize] is `true`. Extends the
  /// default allowlist rather than replacing it.
  final List<String>? allowedTags;

  /// Override the default allowed attribute list when [sanitize] is `true`.
  /// When set, replaces [HtmlSanitizer.defaultAllowedAttributes] entirely.
  /// When `null` (default), the built-in safe subset is used.
  final List<String>? allowedAttributes;

  /// Whether to preserve `data-*` attributes during sanitization.
  final bool allowDataAttributes;

  /// Accessibility label for the outer [Semantics] wrapper.
  /// Defaults to `'Article content'`.
  final String? semanticLabel;

  /// When `true`, the widget and all its descendants are excluded from the
  /// accessibility tree.
  final bool excludeSemantics;

  /// Builder invoked instead of rendering when [HtmlHeuristics.isComplex]
  /// returns `true` for the supplied HTML. Only evaluated for HTML content.
  ///
  /// Use this to render a native Flutter fallback for documents that contain
  /// unsupported CSS or elements (e.g. `<canvas>`, `position:fixed`).
  final WidgetBuilder? fallbackBuilder;

  /// A [GlobalKey] for a [RepaintBoundary] wrapping the rendered content.
  /// Pass a key here and call the capture extension to export the widget as
  /// a PNG image.
  final GlobalKey? captureKey;

  /// Called when content parsing fails. Provides the error and stack trace.
  final void Function(Object error, StackTrace stackTrace)? onError;

  // Selection customization

  /// Builder for custom context-menu actions shown when text is selected.
  final List<SelectionMenuAction> Function(SelectionOverlayController)?
      selectionMenuActionsBuilder;

  /// Colour of the drag-handle indicators shown at the edges of the selection.
  final Color? selectionHandleColor;

  /// Background colour of the selection highlight. Defaults to a translucent
  /// iOS-blue.
  final Color? selectionColor;

  /// Renders an HTML document.
  ///
  /// [html] is sanitized by default (see [sanitize]). Pass [baseUrl] to
  /// resolve relative URLs. Use [customCss] to inject extra styles.
  ///
  /// ```dart
  /// HyperViewer(
  ///   html: '<h1>Hello</h1>',
  ///   onLinkTap: (url) => launchUrl(Uri.parse(url)),
  ///   baseUrl: 'https://example.com',
  /// )
  /// ```
  const HyperViewer({
    super.key,
    required String html,
    this.mode = HyperRenderMode.auto,
    this.selectable = true,
    this.onLinkTap,
    this.onImageTap,
    this.widgetBuilder,
    this.placeholderBuilder,
    this.fallbackBuilder,
    this.enableZoom = false,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.sanitize = true,
    this.allowedTags,
    this.allowedAttributes,
    this.allowDataAttributes = false,
    this.semanticLabel,
    this.excludeSemantics = false,
    this.baseUrl,
    this.customCss,
    this.debugShowHyperRenderBounds = false,
    this.captureKey,
    this.onError,
    this.selectionMenuActionsBuilder,
    this.selectionHandleColor,
    this.selectionColor,
  })  : content = html,
        contentType = HyperContentType.html;

  /// Renders a Markdown document.
  ///
  /// CommonMark-compliant with GFM extensions (tables, strikethrough, etc.).
  ///
  /// ```dart
  /// HyperViewer.markdown(
  ///   markdown: '# Title\n\nSome **bold** text.',
  /// )
  /// ```
  const HyperViewer.markdown({
    super.key,
    required String markdown,
    this.mode = HyperRenderMode.auto,
    this.selectable = true,
    this.onLinkTap,
    this.onImageTap,
    this.widgetBuilder,
    this.placeholderBuilder,
    this.fallbackBuilder,
    this.enableZoom = false,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.sanitize = true,
    this.allowedTags,
    this.allowedAttributes,
    this.allowDataAttributes = false,
    this.semanticLabel,
    this.excludeSemantics = false,
    this.baseUrl,
    this.customCss,
    this.debugShowHyperRenderBounds = false,
    this.captureKey,
    this.onError,
    this.selectionMenuActionsBuilder,
    this.selectionHandleColor,
    this.selectionColor,
  })  : content = markdown,
        contentType = HyperContentType.markdown;

  /// Renders a Quill Delta document (JSON string).
  ///
  /// Sanitization is disabled by default for Delta content since it is
  /// typically produced by a trusted editor.
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
    this.onImageTap,
    this.widgetBuilder,
    this.placeholderBuilder,
    this.fallbackBuilder,
    this.enableZoom = false,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.sanitize = false,
    this.allowedTags,
    this.allowedAttributes,
    this.allowDataAttributes = false,
    this.semanticLabel,
    this.excludeSemantics = false,
    this.baseUrl,
    this.customCss,
    this.debugShowHyperRenderBounds = false,
    this.captureKey,
    this.onError,
    this.selectionMenuActionsBuilder,
    this.selectionHandleColor,
    this.selectionColor,
  })  : content = delta,
        contentType = HyperContentType.delta;

  @override
  State<HyperViewer> createState() => _HyperViewerState();
}

class _HyperViewerState extends State<HyperViewer> {
  DocumentNode? _document;
  bool _isLoading = true;
  bool _isComplexHtml = false;
  int _parseId = 0;

  @override
  void initState() {
    super.initState();
    _updateComplexityCache();
    _parseContent();
  }

  @override
  void didUpdateWidget(covariant HyperViewer old) {
    super.didUpdateWidget(old);
    if (old.content != widget.content ||
        old.contentType != widget.contentType) {
      _updateComplexityCache();
      _parseContent();
    }
  }

  void _updateComplexityCache() {
    _isComplexHtml = widget.contentType == HyperContentType.html &&
        widget.fallbackBuilder != null &&
        HtmlHeuristics.isComplex(widget.content);
  }

  Future<void> _parseContent() async {
    final id = ++_parseId;
    if (mounted) setState(() => _isLoading = true);

    // Performance warnings in debug mode (only for HTML)
    if (kDebugMode && widget.contentType == HyperContentType.html) {
      final analysisResult = PerformanceAnalyzer.analyze(widget.content);
      if (analysisResult.count > 0) {
        analysisResult.printWarnings();
      }
    }

    try {
      final params = _ParseParams(
        content: widget.content,
        contentType: widget.contentType.name,
        sanitize: widget.sanitize,
        allowedTags: widget.allowedTags,
        allowedAttributes: widget.allowedAttributes,
        allowDataAttributes: widget.allowDataAttributes,
        baseUrl: widget.baseUrl,
        customCss: widget.customCss ?? '',
      );
      final doc = await Future.microtask(() => _parseInIsolate(params));
      if (mounted && _parseId == id) {
        setState(() {
          _document = doc;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      if (mounted && _parseId == id) {
        setState(() => _isLoading = false);
        widget.onError?.call(e, st);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplexHtml) return widget.fallbackBuilder!(context);

    Widget body;

    if (_isLoading) {
      body = widget.placeholderBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    } else if (_document == null) {
      body = const Center(child: Text('Error loading content'));
    } else {
      body = _buildDocumentView();
    }

    if (widget.captureKey != null) {
      body = RepaintBoundary(key: widget.captureKey, child: body);
    }
    if (widget.enableZoom) {
      body = InteractiveViewer(
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        child: body,
      );
    }
    if (widget.excludeSemantics) {
      return Semantics(excludeSemantics: true, child: body);
    }
    return Semantics(
      label: widget.semanticLabel ?? 'Article content',
      child: body,
    );
  }

  Widget _buildDocumentView() {
    final doc = _document!;
    final useVirtualized =
        widget.mode == HyperRenderMode.virtualized ||
            (widget.mode == HyperRenderMode.auto &&
                widget.content.length > 30000);

    if (useVirtualized && doc.children.isNotEmpty) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: doc.children.length,
        itemBuilder: (ctx, i) {
          final block = doc.children[i];
          final blockDoc = DocumentNode(children: [block])..style = doc.style;
          return HyperRenderWidget(
            document: blockDoc,
            selectable: widget.selectable,
            onLinkTap: widget.onLinkTap,
            onImageTap: widget.onImageTap,
            widgetBuilder: widget.widgetBuilder,
            selectionMenuActionsBuilder: widget.selectionMenuActionsBuilder,
            selectionHandleColor: widget.selectionHandleColor,
            selectionColor: widget.selectionColor,
            debugShowHyperRenderBounds: widget.debugShowHyperRenderBounds,
          );
        },
      );
    }

    return SingleChildScrollView(
      child: HyperRenderWidget(
        document: doc,
        selectable: widget.selectable,
        onLinkTap: widget.onLinkTap,
        onImageTap: widget.onImageTap,
        widgetBuilder: widget.widgetBuilder,
        selectionMenuActionsBuilder: widget.selectionMenuActionsBuilder,
        selectionHandleColor: widget.selectionHandleColor,
        selectionColor: widget.selectionColor,
        debugShowHyperRenderBounds: widget.debugShowHyperRenderBounds,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Rendering strategy for [HyperViewer].
enum HyperRenderMode {
  /// Automatically chooses between [sync] and [virtualized] based on document size.
  auto,

  /// Always renders the full document inline inside a [SingleChildScrollView].
  sync,

  /// Renders the document using a virtualized [ListView] for large content.
  virtualized,
}

/// Content format accepted by [HyperViewer].
enum HyperContentType {
  /// HTML5 markup (default).
  html,

  /// Quill Delta JSON.
  delta,

  /// CommonMark Markdown with GFM extensions.
  markdown,
}
