import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hyper_render_core/hyper_render_core.dart' show DesignTokens;
import '../core/hyper_render_config.dart';
import '../core/render_hyper_box.dart';
import '../interfaces/node_plugin.dart';
import '../model/node.dart';
import 'hyper_render_widget.dart';

/// Selection handle position
enum _HandlePosition { start, end }

/// Selection menu action
class SelectionMenuAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const SelectionMenuAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}

/// HyperSelectionOverlay - Provides selection UI features like SelectionArea
///
/// Features:
/// - Automatic popup menu when text is selected
/// - Native-style selection handles
/// - Keyboard shortcuts (Ctrl+A, Ctrl+C)
/// - Customizable actions (Copy, Select All, Share, etc.)
/// - Smooth animations
class HyperSelectionOverlay extends StatefulWidget {
  /// The document to render
  final DocumentNode document;

  /// Base text style
  final TextStyle baseStyle;

  /// Link tap callback
  final HyperLinkTapCallback? onLinkTap;

  /// Custom widget builder
  final HyperWidgetBuilder? widgetBuilder;

  /// Whether selection is enabled
  final bool selectable;

  /// Selection handle color
  final Color handleColor;

  /// Menu background color (defaults to surface color)
  final Color? menuBackgroundColor;

  /// Context menu builder (optional custom menu)
  final Widget Function(BuildContext, HyperSelectionOverlayState)?
      contextMenuBuilder;

  /// Custom menu actions (if null, uses default Copy + Select All)
  final List<SelectionMenuAction> Function(HyperSelectionOverlayState)?
      menuActionsBuilder;

  /// Color for text selection highlight
  final Color? selectionColor;

  /// Text direction for layout
  final TextDirection? textDirection;

  /// Whether to show handles
  final bool showHandles;

  /// Whether to automatically show menu on selection
  final bool autoShowMenu;

  /// Draw debug bounds around each fragment/line. See [RenderHyperBox.debugShowBounds].
  final bool debugShowBounds;

  /// Called after each layout pass with anchor id→yOffset map and heading list.
  /// Forwarded to the inner [HyperRenderWidget]. Used by [HyperViewerController].
  final void Function(
    Map<String, double> offsets,
    List<({int level, String text, String? cssId, double yOffset})> headings,
  )? onAnchorLayout;

  /// Engine configuration — cache sizes, link schemes, keyframe registry, etc.
  /// Forwarded to the inner [HyperRenderWidget] so plugins, animations, and
  /// scheme checks work correctly in selectable mode.
  final HyperRenderConfig config;

  /// Optional registry of custom HTML tag plugins.
  /// Forwarded to the inner [HyperRenderWidget].
  final HyperPluginRegistry? pluginRegistry;

  /// When false, skips canvas.saveLayer for backdrop-filter / CSS filter.
  /// Forwarded to the inner [HyperRenderWidget].
  final bool enableComplexFilters;

  const HyperSelectionOverlay({
    super.key,
    required this.document,
    this.baseStyle = const TextStyle(fontSize: 16, color: Color(0xFF000000)),
    this.onLinkTap,
    this.widgetBuilder,
    this.selectable = true,
    this.handleColor = const Color(0xFF2196F3),
    this.selectionColor,
    this.textDirection,
    this.menuBackgroundColor,
    this.contextMenuBuilder,
    this.menuActionsBuilder,
    this.showHandles = true,
    this.autoShowMenu = true,
    this.debugShowBounds = false,
    this.onAnchorLayout,
    this.config = HyperRenderConfig.defaults,
    this.pluginRegistry,
    this.enableComplexFilters = true,
  });

  @override
  State<HyperSelectionOverlay> createState() => HyperSelectionOverlayState();
}

class HyperSelectionOverlayState extends State<HyperSelectionOverlay>
    with SingleTickerProviderStateMixin {
  /// Global key for accessing RenderHyperBox
  final GlobalKey _renderKey = GlobalKey();

  /// Focus node for keyboard shortcuts
  final FocusNode _focusNode = FocusNode();

  /// Whether context menu is showing
  bool _showContextMenu = false;

  /// Selection handles positions and rects (cached to avoid redundant passes)
  Rect? _startHandleRect;
  Rect? _endHandleRect;
  List<Rect> _selectionRects = const [];

  /// Holds the scroll position while a handle is being dragged, preventing
  /// the ancestor SingleChildScrollView / ListView from scrolling and stealing
  /// the gesture away from the handle's PanGestureRecognizer.
  ScrollHoldController? _scrollHold;

  /// Animation controller for menu
  late AnimationController _menuAnimController;
  late Animation<double> _menuScaleAnim;
  late Animation<double> _menuOpacityAnim;

  /// Get the RenderHyperBox
  RenderHyperBox? get _renderBox {
    final renderObject = _renderKey.currentContext?.findRenderObject();
    if (renderObject is RenderHyperBox) {
      return renderObject;
    }
    return null;
  }

  /// Get current selection
  HyperTextSelection? get selection => _renderBox?.selection;

  /// Check if has selection
  bool get hasSelection =>
      selection != null && selection!.isValid && !selection!.isCollapsed;

  /// Get selected text
  String? get selectedText => _renderBox?.getSelectedText();

  @override
  void initState() {
    super.initState();
    _menuAnimController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _menuScaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _menuAnimController, curve: Curves.easeOutCubic),
    );
    _menuOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _menuAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _releaseScrollHold();
    _focusNode.dispose();
    _menuAnimController.dispose();
    super.dispose();
  }

  void _releaseScrollHold() {
    // Null the field BEFORE calling cancel() to break the re-entrant callback
    // cycle: cancel() → goBallistic → beginActivity → HoldScrollActivity.dispose()
    // → onHoldCanceled() = _releaseScrollHold. Without this guard, _scrollHold is
    // still non-null when dispose fires, causing infinite mutual recursion.
    final hold = _scrollHold;
    _scrollHold = null;
    hold?.cancel();
  }

  /// Called when selection changes in RenderHyperBox
  void _onSelectionChanged() {
    _updateHandlePositions();

    if (widget.autoShowMenu && hasSelection) {
      _showMenu();
    } else {
      _hideMenu();
    }
  }

  void _showMenu() {
    if (!_showContextMenu) {
      setState(() => _showContextMenu = true);
      _menuAnimController.forward();
    }
  }

  void _hideMenu() {
    if (_showContextMenu) {
      _menuAnimController.reverse().then((_) {
        if (mounted) {
          setState(() => _showContextMenu = false);
        }
      });
    }
  }

  /// Copy selected text to clipboard
  Future<void> copySelection() async {
    final text = _renderBox?.getSelectedText();
    if (text != null && text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      _showCopiedSnackBar();
      clearSelection();
    }
  }

  /// Clear selection
  void clearSelection() {
    _renderBox?.clearSelection();
    _focusNode.unfocus();
    setState(() {
      _startHandleRect = null;
      _endHandleRect = null;
    });
    _hideMenu();
  }

  /// Select all text
  void selectAll() {
    _renderBox?.selectAll();
    _updateHandlePositions();
    _focusNode.requestFocus();
  }

  void _showCopiedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Long-press driven selection (arena-safe) ─────────────────────────────
  //
  // Selection is initiated by a LongPressGestureRecognizer which competes in
  // the gesture arena.  The parent ScrollView uses a VerticalDragRecognizer
  // that wins on quick-move → scroll works normally.  Only when the finger
  // holds for ~500 ms does the long-press win and freeze the scroll.
  //
  // This replaces the old RenderHyperBox.handleEvent(PointerMove) approach
  // that bypassed the arena and started selection on every scroll attempt.

  void _onLongPressStart(LongPressStartDetails details) {
    if (!widget.selectable) return;
    final box = _renderKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    _renderBox?.startSelectionAt(local);
    _focusNode.requestFocus();
    // Freeze the ancestor scroll view for the duration of the selection drag.
    _releaseScrollHold();
    _scrollHold =
        Scrollable.maybeOf(context)?.position.hold(_releaseScrollHold);
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!widget.selectable) return;
    final box = _renderKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    _renderBox?.extendSelectionTo(local);
    _updateHandlePositions();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _releaseScrollHold();
    _onSelectionChanged();
  }

  void _updateHandlePositions() {
    final renderBox = _renderBox;
    if (renderBox == null) return;

    final rects = renderBox.getSelectionRects();
    setState(() {
      _selectionRects = rects;
      _startHandleRect = rects.isEmpty ? null : rects.first;
      _endHandleRect = rects.isEmpty ? null : rects.last;
    });
  }

  void _handleTapOutside() {
    if (hasSelection || _showContextMenu) {
      clearSelection();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // Ctrl+A - Select All
    if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
      selectAll();
      return KeyEventResult.handled;
    }

    // Ctrl+C - Copy
    if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyC) {
      if (hasSelection) {
        copySelection();
        return KeyEventResult.handled;
      }
    }

    // Escape - Clear selection
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      clearSelection();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Calculate menu position above selection (uses cached rects — no extra pass)
  Offset _calculateMenuPosition() {
    if (_selectionRects.isEmpty) return Offset.zero;

    double minY = double.infinity;
    double centerX = 0;
    for (final rect in _selectionRects) {
      if (rect.top < minY) {
        minY = rect.top;
        centerX = rect.center.dx;
      }
    }
    return Offset(centerX, minY - 8);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Listener(
        // Use Listener instead of GestureDetector(onTapDown) so we don't enter the
        // gesture arena. GestureDetector competes with inner TextButton recognizers
        // and can prevent copy/share button onPressed from firing when the menu is
        // visible. Listener fires on pointer-down without arena participation.
        onPointerDown: (event) {
          if (_showContextMenu) return;
          if (hasSelection) clearSelection();
        },
        behavior: HitTestBehavior.translucent,
        child: TapRegion(
          onTapOutside: (_) => _handleTapOutside(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main content — wrapped with LongPressGestureDetector so that
              // text selection competes in the gesture arena against the parent
              // ScrollView's VerticalDragGestureRecognizer.
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPressStart: _onLongPressStart,
                onLongPressMoveUpdate: _onLongPressMoveUpdate,
                onLongPressEnd: _onLongPressEnd,
                child: KeyedSubtree(
                  key: _renderKey,
                  child: HyperRenderWidget(
                    document: widget.document,
                    baseStyle: widget.baseStyle,
                    onLinkTap: widget.onLinkTap,
                    widgetBuilder: widget.widgetBuilder,
                    selectable: widget.selectable,
                    selectionColor: widget.selectionColor,
                    textDirection:
                        widget.textDirection ?? Directionality.of(context),
                    onSelectionChanged: _onSelectionChanged,
                    debugShowBounds: widget.debugShowBounds,
                    onAnchorLayout: widget.onAnchorLayout,
                    config: widget.config,
                    pluginRegistry: widget.pluginRegistry,
                    enableComplexFilters: widget.enableComplexFilters,
                  ),
                ),
              ),

              // Selection handles
              if (hasSelection && widget.selectable && widget.showHandles) ...[
                if (_startHandleRect != null)
                  _buildHandle(_HandlePosition.start, _startHandleRect!),
                if (_endHandleRect != null)
                  _buildHandle(_HandlePosition.end, _endHandleRect!),
              ],

              // Context menu (positioned above selection)
              if (_showContextMenu && hasSelection)
                _buildAnimatedContextMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedContextMenu(BuildContext context) {
    final menuPosition = _calculateMenuPosition();

    // Clamp to 0: Flutter hit-testing does not follow Clip.none — a Positioned
    // child above the Stack's origin (negative top) is visually rendered but
    // unreachable via pointer events.
    return Positioned(
      left: 0,
      right: 0,
      top: (menuPosition.dy - 56).clamp(0.0, double.infinity),
      child: AnimatedBuilder(
        animation: _menuAnimController,
        builder: (context, child) {
          return Opacity(
            opacity: _menuOpacityAnim.value,
            child: Transform.scale(
              scale: _menuScaleAnim.value,
              child: child,
            ),
          );
        },
        child: Center(
          child: widget.contextMenuBuilder != null
              ? widget.contextMenuBuilder!(context, this)
              : _buildDefaultContextMenu(context),
        ),
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

    // Speed scales linearly with proximity: 0 px/event at threshold edge → 20 px/event at screen edge.
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

  Widget _buildHandle(_HandlePosition position, Rect rect) {
    final isStart = position == _HandlePosition.start;

    // Native-style teardrop handle positioning
    final left = isStart ? rect.left - 11 : rect.right - 11;
    final top = isStart ? rect.top - 22 : rect.bottom;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanStart: (_) {
          _focusNode.requestFocus();
          _hideMenu(); // Hide menu while dragging
          // Freeze the ancestor scroll view so the handle drag wins the arena.
          _releaseScrollHold();
          _scrollHold =
              Scrollable.maybeOf(context)?.position.hold(_releaseScrollHold);
        },
        onPanUpdate: (details) {
          final renderBox = _renderBox;
          if (renderBox == null) return;

          final RenderBox? box =
              _renderKey.currentContext?.findRenderObject() as RenderBox?;
          if (box == null) return;

          final localPosition = box.globalToLocal(details.globalPosition);
          renderBox.updateSelectionFromHandle(isStart, localPosition);
          _updateHandlePositions();
          _autoScrollIfNearEdge(details.globalPosition);
        },
        onPanEnd: (_) {
          _releaseScrollHold(); // Restore scroll after handle drag completes.
          if (hasSelection && widget.autoShowMenu) {
            _showMenu();
          }
        },
        onPanCancel: () {
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

  Widget _buildDefaultContextMenu(BuildContext context) {
    final actions = widget.menuActionsBuilder?.call(this) ?? _defaultActions;
    final bgColor =
        widget.menuBackgroundColor ?? Theme.of(context).colorScheme.surface;

    return Material(
      elevation: 8,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: actions.map((action) {
              return _ContextMenuButton(
                icon: action.icon,
                label: action.label,
                onTap: action.onPressed,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<SelectionMenuAction> get _defaultActions => [
        SelectionMenuAction(
          icon: Icons.copy_rounded,
          label: 'Copy',
          onPressed: copySelection,
        ),
        SelectionMenuAction(
          icon: Icons.select_all_rounded,
          label: 'All',
          onPressed: selectAll,
        ),
      ];
}

class _ContextMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContextMenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use Material TextButton for professional appearance
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space1_5,
          vertical: DesignTokens.space1,
        ),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        ),
      ),
    );
  }
}

/// Custom painter for native-style teardrop selection handles
class HyperTeardropHandlePainter extends CustomPainter {
  final Color color;
  final bool isStart;

  HyperTeardropHandlePainter({
    required this.color,
    required this.isStart,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (isStart) {
      // Teardrop pointing up (for start handle)
      // Circle at bottom, point at top
      path.moveTo(w / 2, 0); // Top point
      path.quadraticBezierTo(w, h * 0.4, w * 0.85, h * 0.7); // Right curve
      path.arcToPoint(
        Offset(w * 0.15, h * 0.7),
        radius: Radius.circular(w * 0.35),
        clockwise: false,
      ); // Bottom arc
      path.quadraticBezierTo(0, h * 0.4, w / 2, 0); // Left curve
    } else {
      // Teardrop pointing down (for end handle)
      // Circle at top, point at bottom
      path.moveTo(w / 2, h); // Bottom point
      path.quadraticBezierTo(w, h * 0.6, w * 0.85, h * 0.3); // Right curve
      path.arcToPoint(
        Offset(w * 0.15, h * 0.3),
        radius: Radius.circular(w * 0.35),
        clockwise: true,
      ); // Top arc
      path.quadraticBezierTo(0, h * 0.6, w / 2, h); // Left curve
    }

    path.close();

    // Draw shadow first
    canvas.drawPath(path.shift(const Offset(1, 1)), shadowPaint);

    // Draw handle
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(HyperTeardropHandlePainter oldDelegate) {
    return color != oldDelegate.color || isStart != oldDelegate.isStart;
  }
}

/// Extension to easily use HyperSelectionOverlay
extension HyperRenderWidgetSelectionExtension on HyperRenderWidget {
  /// Wrap with selection overlay for full UX features
  Widget withSelectionOverlay({
    Color handleColor = const Color(0xFF2196F3),
    Widget Function(BuildContext, HyperSelectionOverlayState)?
        contextMenuBuilder,
  }) {
    return HyperSelectionOverlay(
      document: document,
      baseStyle: baseStyle,
      onLinkTap: onLinkTap,
      widgetBuilder: widgetBuilder,
      selectable: selectable,
      handleColor: handleColor,
      contextMenuBuilder: contextMenuBuilder,
    );
  }
}
