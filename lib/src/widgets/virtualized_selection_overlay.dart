import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

import 'virtualized_selection_controller.dart';

// ──────────────────────────────────────────────────────────────────────────────
// _VirtualizedChunk — per-item wrapper for the ListView
// ──────────────────────────────────────────────────────────────────────────────

/// Wraps a single [HyperRenderWidget] chunk and registers it with
/// [VirtualizedSelectionController] after the first layout.
class VirtualizedChunk extends StatefulWidget {
  const VirtualizedChunk({
    super.key,
    required this.chunkIndex,
    required this.document,
    required this.selectionController,
    required this.selectable,
    this.selectionColor,
    this.textDirection,
    this.onLinkTap,
    this.widgetBuilder,
    this.debugShowBounds = false,
    this.enableComplexFilters = false,
    required this.config,
    this.suppressFirstBlockMarginTop = false,
    this.onAnchorLayout,
    this.initialFloats = const [],
    this.onFloatCarryover,
    this.pluginRegistry,
  });

  final int chunkIndex;
  final DocumentNode document;
  final VirtualizedSelectionController selectionController;
  final bool selectable;
  final Color? selectionColor;
  final TextDirection? textDirection;
  final HyperLinkTapCallback? onLinkTap;
  final HyperWidgetBuilder? widgetBuilder;
  final bool debugShowBounds;
  final bool enableComplexFilters;
  final HyperRenderConfig config;
  final bool suppressFirstBlockMarginTop;
  final void Function(
    Map<String, double>,
    List<({int level, String text, String? cssId, double yOffset})>,
  )? onAnchorLayout;
  final List<FloatCarryover> initialFloats;
  final void Function(List<FloatCarryover>)? onFloatCarryover;
  final HyperPluginRegistry? pluginRegistry;

  @override
  State<VirtualizedChunk> createState() => _VirtualizedChunkState();
}

class _VirtualizedChunkState extends State<VirtualizedChunk> {
  final GlobalKey _renderKey = GlobalKey();
  bool _registered = false;

  /// Holds the parent scroll position while the user is drag-selecting inside
  /// this chunk, preventing the ListView from stealing the gesture.
  ScrollHoldController? _scrollHold;

  @override
  void initState() {
    super.initState();
    if (widget.selectable) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryRegister());
    }
  }

  @override
  void didUpdateWidget(VirtualizedChunk old) {
    super.didUpdateWidget(old);
    // Re-register if the document changed (char count may differ).
    if (old.document != widget.document) {
      _registered = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryRegister());
    }
  }

  @override
  void dispose() {
    _releaseScrollHold();
    if (_registered) {
      widget.selectionController.unregisterChunk(widget.chunkIndex);
    }
    super.dispose();
  }

  void _releaseScrollHold() {
    final hold = _scrollHold;
    _scrollHold = null;
    hold?.cancel();
  }

  void _tryRegister() {
    if (!mounted) return;
    final ro = _renderKey.currentContext?.findRenderObject();
    if (ro is! RenderHyperBox) return;
    final count = ro.totalCharacterCount;
    if (count == 0) {
      // Layout hasn't run yet — try again next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryRegister());
      return;
    }
    widget.selectionController
        .registerChunk(widget.chunkIndex, _renderKey, count);
    _registered = true;
  }

  void _onSelectionChanged() {
    // Notify the controller that handle rects may have moved.
    widget.selectionController.notifyHandleRectsChanged();
  }

  // ── Long-press driven selection ────────────────────────────────────────────

  void _onLongPressStart(LongPressStartDetails details) {
    if (!widget.selectable) return;
    final box = _renderKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    widget.selectionController.startSelection(widget.chunkIndex, local);
    // Freeze the ListView so drag-selection doesn't fight the scroll view.
    _releaseScrollHold();
    _scrollHold =
        Scrollable.maybeOf(context)?.position.hold(_releaseScrollHold);
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!widget.selectable) return;
    // Extend the END anchor while keeping start fixed — reuses the same path
    // as handle-dragging so cross-chunk selection works automatically.
    widget.selectionController
        .updateSelectionFromHandle(false, details.globalPosition);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _releaseScrollHold();
  }

  @override
  Widget build(BuildContext context) {
    final content = KeyedSubtree(
      key: _renderKey,
      child: HyperRenderWidget(
        document: widget.document,
        selectable: widget.selectable,
        selectionColor: widget.selectionColor,
        textDirection: widget.textDirection ?? Directionality.of(context),
        onLinkTap: widget.onLinkTap,
        widgetBuilder: widget.widgetBuilder,
        debugShowBounds: widget.debugShowBounds,
        enableComplexFilters: widget.enableComplexFilters,
        config: widget.config,
        suppressFirstBlockMarginTop: widget.suppressFirstBlockMarginTop,
        onSelectionChanged: widget.selectable ? _onSelectionChanged : null,
        onAnchorLayout: widget.onAnchorLayout,
        initialFloats: widget.initialFloats,
        onFloatCarryover: widget.onFloatCarryover,
        pluginRegistry: widget.pluginRegistry,
      ),
    );

    if (!widget.selectable) return content;

    // Wrap with a LongPressGestureDetector so selection competes in the gesture
    // arena against the ListView's VerticalDragGestureRecognizer.  A quick
    // touch-move → scroll wins and long-press is cancelled (no selection).
    // Only holding for ~500 ms starts selection and freezes the scroll.
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMoveUpdate,
      onLongPressEnd: _onLongPressEnd,
      child: content,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// VirtualizedSelectionOverlay — the Stack overlay for handles + Copy menu
// ──────────────────────────────────────────────────────────────────────────────

/// Wraps the virtualised [ListView] in a [Stack] and overlays selection
/// handles and a Copy popup menu that span across multiple chunks.
class VirtualizedSelectionOverlay extends StatefulWidget {
  const VirtualizedSelectionOverlay({
    super.key,
    required this.controller,
    required this.child,
    required this.handleColor,
    this.menuBackgroundColor,
    this.selectionMenuActionsBuilder,
  });

  final VirtualizedSelectionController controller;
  final Widget child;
  final Color handleColor;
  final Color? menuBackgroundColor;

  /// Overrides the default [Copy / Select All] menu. Receives the controller
  /// so custom actions can call [controller.getSelectedText()].
  final List<SelectionMenuAction> Function(VirtualizedSelectionController)?
      selectionMenuActionsBuilder;

  @override
  State<VirtualizedSelectionOverlay> createState() =>
      _VirtualizedSelectionOverlayState();
}

class _VirtualizedSelectionOverlayState
    extends State<VirtualizedSelectionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _menuAnim;
  late Animation<double> _menuScale;
  late Animation<double> _menuOpacity;

  bool _showMenu = false;
  bool _draggingStart = false;
  bool _draggingEnd = false;
  ScrollHoldController? _scrollHold;

  @override
  void initState() {
    super.initState();
    _menuAnim = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
    _menuScale = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _menuAnim, curve: Curves.easeOutCubic));
    _menuOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _menuAnim, curve: Curves.easeOut));
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(VirtualizedSelectionOverlay old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _releaseScrollHold();
    _menuAnim.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    if (widget.controller.hasSelection && !_draggingStart && !_draggingEnd) {
      _revealMenu();
    } else if (!widget.controller.hasSelection) {
      _dismissMenu();
    }
  }

  void _revealMenu() {
    if (!_showMenu) {
      setState(() => _showMenu = true);
      _menuAnim.forward();
    }
  }

  void _dismissMenu() {
    if (_showMenu) {
      _menuAnim.reverse().then((_) {
        if (mounted) setState(() => _showMenu = false);
      });
    }
  }

  void _releaseScrollHold() {
    final hold = _scrollHold;
    _scrollHold = null;
    hold?.cancel();
  }

  Future<void> _copySelection() async {
    final text = widget.controller.getSelectedText();
    if (text != null && text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ));
    }
    widget.controller.clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final hasSelection = ctrl.hasSelection;

    final startRect = hasSelection ? ctrl.startHandleRectInStack : null;
    final endRect = hasSelection ? ctrl.endHandleRectInStack : null;
    final topmostRect = hasSelection ? ctrl.topmostSelectionRectInStack : null;

    return TapRegion(
      onTapOutside: (_) {
        if (hasSelection || _showMenu) ctrl.clearSelection();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The virtualised list content.
          Listener(
            onPointerDown: (_) {
              // Guard: when the Copy menu is visible, pointer-down fires for
              // every tap in the Stack (including taps ON the menu buttons)
              // because the Listener is translucent and the menu overlaps the
              // content area.  Clearing selection here would nullify the text
              // before the button's onPressed fires, making copy silently fail.
              if (_showMenu) return;
              if (ctrl.hasSelection) ctrl.clearSelection();
            },
            behavior: HitTestBehavior.translucent,
            child: widget.child,
          ),

          // Start handle.
          if (hasSelection && startRect != null)
            _buildHandle(isStart: true, rect: startRect),

          // End handle.
          if (hasSelection && endRect != null)
            _buildHandle(isStart: false, rect: endRect),

          // Copy menu positioned above the topmost selected line.
          if (_showMenu && hasSelection && topmostRect != null)
            _buildMenu(context, topmostRect),
        ],
      ),
    );
  }

  void _autoScrollIfNearEdge(Offset globalPosition) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;

    final RenderBox? scrollableBox =
        scrollable.context.findRenderObject() as RenderBox?;
    if (scrollableBox == null) return;

    final localPosition = scrollableBox.globalToLocal(globalPosition);
    final size = scrollableBox.size;

    const threshold = 60.0;
    const maxStep = 20.0;
    double dy = 0.0;

    if (localPosition.dy < threshold) {
      dy = -maxStep * (1.0 - localPosition.dy / threshold);
    } else if (localPosition.dy > size.height - threshold) {
      dy = maxStep * (1.0 - (size.height - localPosition.dy) / threshold);
    }

    if (dy != 0.0) {
      final position = scrollable.position;
      final target = (position.pixels + dy)
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      if (target != position.pixels) {
        position.jumpTo(target);
      }
    }
  }

  Widget _buildHandle({required bool isStart, required Rect rect}) {
    final left = isStart ? rect.left - 11 : rect.right - 11;
    final top = isStart ? rect.top - 22 : rect.bottom;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanStart: (_) {
          if (isStart) {
            _draggingStart = true;
          } else {
            _draggingEnd = true;
          }
          _dismissMenu();
          _releaseScrollHold();
          _scrollHold =
              Scrollable.maybeOf(context)?.position.hold(_releaseScrollHold);
        },
        onPanUpdate: (details) {
          widget.controller
              .updateSelectionFromHandle(isStart, details.globalPosition);
          _autoScrollIfNearEdge(details.globalPosition);
        },
        onPanEnd: (_) {
          if (isStart) {
            _draggingStart = false;
          } else {
            _draggingEnd = false;
          }
          _releaseScrollHold();
          if (widget.controller.hasSelection) _revealMenu();
        },
        onPanCancel: () {
          _draggingStart = false;
          _draggingEnd = false;
          _releaseScrollHold();
        },
        child: CustomPaint(
          size: const Size(22, 22),
          painter: HyperTeardropHandlePainter(
            color: widget.handleColor,
            isStart: isStart,
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, Rect topmostRect) {
    // Clamp to 0 so the menu never goes above the Stack's bounds.
    // Flutter hit-testing does not follow Clip.none — children outside parent
    // bounds are unreachable even when visually rendered.
    final menuTop = (topmostRect.top - 8 - 56).clamp(0.0, double.infinity);

    return Positioned(
      left: 0,
      right: 0,
      top: menuTop,
      child: AnimatedBuilder(
        animation: _menuAnim,
        builder: (context, child) => Opacity(
          opacity: _menuOpacity.value,
          child: Transform.scale(scale: _menuScale.value, child: child),
        ),
        child: Center(
          child: _buildDefaultMenu(context),
        ),
      ),
    );
  }

  Widget _buildDefaultMenu(BuildContext context) {
    final bgColor =
        widget.menuBackgroundColor ?? Theme.of(context).colorScheme.surface;
    final actions =
        widget.selectionMenuActionsBuilder?.call(widget.controller) ??
            _defaultActions;

    return Material(
      elevation: 8,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: actions
                .map((a) => _MenuButton(
                    icon: a.icon, label: a.label, onTap: a.onPressed))
                .toList(),
          ),
        ),
      ),
    );
  }

  List<SelectionMenuAction> get _defaultActions => [
        SelectionMenuAction(
          icon: Icons.copy_rounded,
          label: 'Copy',
          onPressed: _copySelection,
        ),
        SelectionMenuAction(
          icon: Icons.select_all_rounded,
          label: 'All',
          onPressed: widget.controller.selectAll,
        ),
      ];
}

// ──────────────────────────────────────────────────────────────────────────────
// Supporting types
// ──────────────────────────────────────────────────────────────────────────────

class _MenuButton extends StatelessWidget {
  const _MenuButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

// HyperTeardropHandlePainter is defined in hyper_selection_overlay.dart
// and exported from hyper_render_core — no local copy needed.
