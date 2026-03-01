import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/render_hyper_box.dart';
import '../model/node.dart';
import '../interfaces/selection_types.dart';
import 'hyper_render_widget.dart';

/// HyperSelectionOverlay - Provides selection UI features like SelectionArea
class HyperSelectionOverlay extends StatefulWidget {
  final DocumentNode document;
  final TextStyle baseStyle;
  final HyperLinkTapCallback? onLinkTap;
  final HyperWidgetBuilder? widgetBuilder;
  final bool selectable;
  final Color handleColor;
  final Color? menuBackgroundColor;
  final Widget Function(BuildContext, SelectionOverlayController)? contextMenuBuilder;
  final List<SelectionMenuAction> Function(SelectionOverlayController)? menuActionsBuilder;
  final bool showHandles;
  final bool showMenu;
  final VoidCallback? onSelectionChanged;

  const HyperSelectionOverlay({
    super.key,
    required this.document,
    this.baseStyle = const TextStyle(fontSize: 16, color: Color(0xFF000000)),
    this.onLinkTap,
    this.widgetBuilder,
    this.selectable = true,
    this.handleColor = const Color(0xFF2196F3),
    this.menuBackgroundColor,
    this.contextMenuBuilder,
    this.menuActionsBuilder,
    this.showHandles = true,
    this.showMenu = true,
    this.onSelectionChanged,
  });

  @override
  State<HyperSelectionOverlay> createState() => HyperSelectionOverlayState();
}

class HyperSelectionOverlayState extends State<HyperSelectionOverlay> 
    with SingleTickerProviderStateMixin 
    implements SelectionOverlayController {
  
  final GlobalKey _renderKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void selectAll() {
    final renderBox = _renderKey.currentContext?.findRenderObject() as RenderHyperBox?;
    renderBox?.selectAll();
  }

  @override
  void clearSelection() {
    final renderBox = _renderKey.currentContext?.findRenderObject() as RenderHyperBox?;
    renderBox?.clearSelection();
  }

  @override
  void copySelection() {
    final renderBox = _renderKey.currentContext?.findRenderObject() as RenderHyperBox?;
    final text = renderBox?.getSelectedText();
    if (text != null && text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
    }
  }

  @override
  String? get selectedText {
    final renderBox = _renderKey.currentContext?.findRenderObject() as RenderHyperBox?;
    return renderBox?.getSelectedText();
  }

  bool get hasSelection {
    final text = selectedText;
    return text != null && text.isNotEmpty;
  }

  HyperTextSelection? get selection {
    final renderBox = _renderKey.currentContext?.findRenderObject() as RenderHyperBox?;
    return renderBox?.selection;
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) => clearSelection(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _focusNode.requestFocus();
          clearSelection();
        },
        child: Focus(
          focusNode: _focusNode,
          child: Stack(
            children: [
              HyperRenderWidget(
                key: _renderKey,
                document: widget.document,
                baseStyle: widget.baseStyle,
                onLinkTap: widget.onLinkTap,
                widgetBuilder: widget.widgetBuilder,
                selectable: widget.selectable,
                onSelectionChanged: (_) => widget.onSelectionChanged?.call(),
                selectionMenuActionsBuilder: widget.menuActionsBuilder,
                selectionHandleColor: widget.handleColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension to quickly wrap a [HyperRenderWidget] in a [HyperSelectionOverlay].
extension HyperRenderWidgetSelectionExtension on HyperRenderWidget {
  HyperSelectionOverlay withSelectionOverlay({
    Color? handleColor,
    Widget Function(BuildContext, SelectionOverlayController)? contextMenuBuilder,
    VoidCallback? onSelectionChanged,
  }) {
    return HyperSelectionOverlay(
      document: document,
      baseStyle: baseStyle,
      onLinkTap: onLinkTap,
      widgetBuilder: widgetBuilder,
      selectable: selectable,
      handleColor: handleColor ?? const Color(0xFF2196F3),
      contextMenuBuilder: contextMenuBuilder,
      onSelectionChanged: onSelectionChanged,
    );
  }
}
