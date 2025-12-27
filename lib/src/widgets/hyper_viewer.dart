import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/render_hyper_box.dart';
import '../interfaces/code_highlighter.dart';
import '../interfaces/content_parser.dart';
import '../model/node.dart';
import '../parser/html/html_adapter.dart';
import '../plugins/default_html_parser.dart';
import '../style/resolver.dart';
import 'hyper_render_widget.dart';

/// Chế độ render
enum HyperRenderMode {
  /// Tự động chọn (Nếu HTML ngắn -> Sync, nếu dài -> Async + Virtualization)
  auto,
  /// Render đồng bộ trên Main Thread (Tốt cho text ngắn)
  sync,
  /// Render bất đồng bộ + ListView (Tốt cho text dài)
  virtualized,
}

class HyperViewer extends StatefulWidget {
  final String html;
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

  /// Custom content parser for parsing HTML/Markdown/etc.
  /// If null, uses DefaultHtmlParser.
  ///
  /// Example with custom parser:
  /// ```dart
  /// HyperViewer(
  ///   html: content,
  ///   contentParser: MyCustomParser(),
  /// )
  /// ```
  final ContentParser? contentParser;

  /// Custom code highlighter for syntax highlighting in code blocks.
  /// If null, uses DefaultCodeHighlighter (requires flutter_highlight).
  ///
  /// Example with custom highlighter:
  /// ```dart
  /// HyperViewer(
  ///   html: content,
  ///   codeHighlighter: PlainTextHighlighter(), // No syntax highlighting
  /// )
  /// ```
  final CodeHighlighter? codeHighlighter;

  const HyperViewer({
    super.key,
    required this.html,
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
  });

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
    if (oldWidget.html != widget.html || oldWidget.mode != widget.mode) {
      _parseContent();
    }
  }

  void _parseContent() {
    final useVirtualization = widget.mode == HyperRenderMode.virtualized ||
        (widget.mode == HyperRenderMode.auto && widget.html.length > 10000); // Ngưỡng 10k ký tự

    // Use custom parser if provided, otherwise use default HTML parser
    final parser = widget.contentParser ?? DefaultHtmlParser();

    if (!useVirtualization) {
      // 1. Sync Parsing (Fast path for small content)
      setState(() {
        _syncDocument = parser.parse(widget.html);
        StyleResolver().resolveStyles(_syncDocument!);
        _sections = null;
        _isLoading = false;
      });
    } else {
      // 2. Async Parsing (Isolate path for large content)
      // Note: Custom parser cannot be passed to isolate, so we use default
      // HtmlAdapter for virtualized mode. This is a trade-off for performance.
      setState(() => _isLoading = true);

      // Sử dụng compute để đẩy việc nặng sang thread khác
      compute(_parseAndChunk, widget.html).then((sections) {
        if (mounted) {
          setState(() {
            _sections = sections;
            _syncDocument = null;
            _isLoading = false;
          });
        }
      });
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
    if (_isLoading) {
      return widget.placeholderBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    // Case 1: Virtualized List (cho văn bản dài)
    // Note: Zoom is NOT supported in virtualized mode due to:
    // 1. Conflicting scroll gestures between InteractiveViewer and ListView
    // 2. Unbounded constraints issues
    // 3. Performance considerations with large documents
    if (_sections != null) {
      return ListView.builder(
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
      );
    }

    // Case 2: Single Widget (cho văn bản ngắn)
    if (_syncDocument != null) {
      final content = HyperRenderWidget(
        document: _syncDocument!,
        selectable: widget.selectable,
        onLinkTap: widget.onLinkTap,
        widgetBuilder: widget.widgetBuilder,
      );

      // Wrap with zoom if enabled (only for sync mode)
      if (widget.enableZoom) {
        return InteractiveViewer(
          minScale: widget.minScale,
          maxScale: widget.maxScale,
          boundaryMargin: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: content,
          ),
        );
      }

      // No zoom - standard scroll view
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    return const SizedBox.shrink();
  }
}