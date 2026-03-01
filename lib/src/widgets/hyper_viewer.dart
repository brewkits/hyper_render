import 'package:flutter/material.dart';

import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_core/src/style/css_rule_index.dart';
import 'package:hyper_render_core/src/interfaces/selection_types.dart';
import 'package:hyper_render_html/hyper_render_html.dart';
import 'package:hyper_render_markdown/hyper_render_markdown.dart';

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

  // Selection customization

  /// Builder for custom context-menu actions shown when text is selected.
  final List<SelectionMenuAction> Function(SelectionOverlayController)? selectionMenuActionsBuilder;

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
    this.widgetBuilder,
    this.placeholderBuilder,
    this.fallbackBuilder,
    this.enableZoom = false,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.sanitize = true,
    this.allowedTags,
    this.allowDataAttributes = false,
    this.semanticLabel,
    this.excludeSemantics = false,
    this.baseUrl,
    this.customCss,
    this.debugShowHyperRenderBounds = false,
    this.captureKey,
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
    this.widgetBuilder,
    this.placeholderBuilder,
    this.fallbackBuilder,
    this.enableZoom = false,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.sanitize = true,
    this.allowedTags,
    this.allowDataAttributes = false,
    this.semanticLabel,
    this.excludeSemantics = false,
    this.baseUrl,
    this.customCss,
    this.debugShowHyperRenderBounds = false,
    this.captureKey,
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
    this.widgetBuilder,
    this.placeholderBuilder,
    this.fallbackBuilder,
    this.enableZoom = false,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.sanitize = false,
    this.allowedTags,
    this.allowDataAttributes = false,
    this.semanticLabel,
    this.excludeSemantics = false,
    this.baseUrl,
    this.customCss,
    this.debugShowHyperRenderBounds = false,
    this.captureKey,
    this.selectionMenuActionsBuilder,
    this.selectionHandleColor,
    this.selectionColor,
  })  : content = delta,
        contentType = HyperContentType.delta;

  @override
  State<HyperViewer> createState() => _HyperViewerState();
}

class _HyperViewerState extends State<HyperViewer> {
  DocumentNode? _syncDocument;
  bool _isLoading = true;
  int _parseId = 0;

  @override
  void initState() {
    super.initState();
    _parseContent();
  }

  @override
  void didUpdateWidget(covariant HyperViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content || oldWidget.contentType != widget.contentType) {
      _parseContent();
    }
  }

  void _parseContent() {
    final currentParseId = ++_parseId;
    setState(() => _isLoading = true);

    String contentToRender = widget.content;
    String cssToApply = widget.customCss ?? '';

    if (widget.contentType == HyperContentType.html) {
      if (widget.sanitize) {
        contentToRender = HtmlSanitizer.sanitize(contentToRender, allowedTags: widget.allowedTags);
      }
    }

    // Register CSS parser
    CssRuleIndex.parser = DefaultHtmlParser();

    ContentParser parser;
    if (widget.contentType == HyperContentType.markdown) {
      parser = const MarkdownContentParser();
    } else if (widget.contentType == HyperContentType.delta) {
      parser = DeltaAdapter();
    } else {
      parser = DefaultHtmlParser();
    }

    try {
      final doc = parser.parseWithOptions(contentToRender, baseUrl: widget.baseUrl, customCss: cssToApply);

      if (mounted && _parseId == currentParseId) {
        setState(() {
          _syncDocument = doc;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _parseId == currentParseId) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Invoke fallbackBuilder when the HTML content is too complex to render correctly
    if (widget.fallbackBuilder != null &&
        widget.contentType == HyperContentType.html &&
        HtmlHeuristics.isComplex(widget.content)) {
      return widget.fallbackBuilder!(context);
    }

    Widget body;

    if (_isLoading) {
      body = widget.placeholderBuilder?.call(context) ?? const Center(child: CircularProgressIndicator());
    } else if (_syncDocument == null) {
      body = const Center(child: Text('Error loading content'));
    } else {
      body = SingleChildScrollView(
        child: HyperRenderWidget(
          document: _syncDocument!,
          selectable: widget.selectable,
          onLinkTap: widget.onLinkTap,
          widgetBuilder: widget.widgetBuilder,
          selectionMenuActionsBuilder: widget.selectionMenuActionsBuilder,
          selectionHandleColor: widget.selectionHandleColor,
          selectionColor: widget.selectionColor,
          debugShowHyperRenderBounds: widget.debugShowHyperRenderBounds,
        ),
      );
    }

    if (widget.captureKey != null) {
      body = RepaintBoundary(key: widget.captureKey, child: body);
    }

    if (widget.excludeSemantics) {
      return Semantics(excludeSemantics: true, child: body);
    }

    return Semantics(
      label: widget.semanticLabel ?? 'Article content',
      child: body,
    );
  }
}

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
