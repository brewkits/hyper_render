import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/render_hyper_box.dart';
import '../model/node.dart';
import '../parser/html/html_adapter.dart';
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

  const HyperViewer({
    super.key,
    required this.html,
    this.mode = HyperRenderMode.auto,
    this.selectable = true,
    this.onLinkTap,
    this.widgetBuilder,
    this.placeholderBuilder,
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

    if (!useVirtualization) {
      // 1. Sync Parsing (Fast path for small content)
      setState(() {
        _syncDocument = HtmlAdapter().parse(widget.html);
        StyleResolver().resolveStyles(_syncDocument!);
        _sections = null;
        _isLoading = false;
      });
    } else {
      // 2. Async Parsing (Isolate path for large content)
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
    final sections = adapter.parseToSections(html, chunkSize: 3000); // 3000 chars per chunk

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
    if (_sections != null) {
      return ListView.builder(
        // Quan trọng: cacheExtent giúp render trước vài pixel để scroll mượt
        cacheExtent: 500,
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
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: HyperRenderWidget(
          document: _syncDocument!,
          selectable: widget.selectable,
          onLinkTap: widget.onLinkTap,
          widgetBuilder: widget.widgetBuilder,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}