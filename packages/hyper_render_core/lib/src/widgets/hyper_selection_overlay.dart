import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hyper_render_core/hyper_render_core.dart' show DesignTokens;
import '../core/render_hyper_box.dart';
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

  /// Selection handles positions
  Rect? _startHandleRect;
  Rect? _endHandleRect;

  /// Which handle is being dragged (for potential future animation/haptic feedback)
  // ignore: unused_field
  _HandlePosition? _draggingHandle;

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
    _focusNode.dispose();
    _menuAnimController.dispose();
    super.dispose();
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
      _showCopiedSnackBar();
      clearSelection();
    }
  }

  /// Clear selection
  void clearSelection() {
    _renderBox?.clearSelection();
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

  void _updateHandlePositions() {
    final renderBox = _renderBox;
    if (renderBox == null) return;

    setState(() {
      _startHandleRect = renderBox.getStartHandleRect();
      _endHandleRect = renderBox.getEndHandleRect();
    });
  }

  void _handleTapOutside() {
    if (hasSelection || _showContextMenu) {
      clearSelection();
    }
  }

  void _handleTap(TapDownDetails details) {
    // Hide menu and clear selection on tap
    if (_showContextMenu || hasSelection) {
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

  /// Calculate menu position above selection
  Offset _calculateMenuPosition() {
    if (_startHandleRect == null) return Offset.zero;

    final RenderBox? box =
        _renderKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;

    // Get all selection rects to find the topmost point
    final selectionRects = _renderBox?.getSelectionRects() ?? [];
    if (selectionRects.isEmpty) return Offset.zero;

    // Find the topmost and leftmost point of selection
    double minY = double.infinity;
    double centerX = 0;
    for (final rect in selectionRects) {
      if (rect.top < minY) {
        minY = rect.top;
        centerX = rect.center.dx;
      }
    }

    // Position menu above selection with some padding
    return Offset(centerX, minY - 8);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTapDown: _handleTap,
        behavior: HitTestBehavior.translucent,
        child: TapRegion(
          onTapOutside: (_) => _handleTapOutside(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main content
              KeyedSubtree(
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

    return Positioned(
      left: 0,
      right: 0,
      top: menuPosition.dy -
          56, // Dynamic menu height (adjusted for Material buttons)
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
          _draggingHandle = position;
          _focusNode.requestFocus();
          _hideMenu(); // Hide menu while dragging
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
        },
        onPanEnd: (_) {
          _draggingHandle = null;
          if (hasSelection && widget.autoShowMenu) {
            _showMenu();
          }
        },
        child: CustomPaint(
          size: const Size(22, 22),
          painter: _TeardropHandlePainter(
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
class _TeardropHandlePainter extends CustomPainter {
  final Color color;
  final bool isStart;

  _TeardropHandlePainter({
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
  bool shouldRepaint(_TeardropHandlePainter oldDelegate) {
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
