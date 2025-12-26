import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/render_hyper_box.dart';
import '../model/node.dart';
import 'hyper_render_widget.dart';

/// Selection handle position
enum _HandlePosition { start, end }

/// HyperSelectionOverlay - Provides selection UI features
///
/// Features:
/// - Tap outside to clear selection
/// - Long press context menu (Copy)
/// - Keyboard shortcuts (Ctrl+A, Ctrl+C)
/// - Draggable selection handles
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

  /// Context menu builder (optional custom menu)
  final Widget Function(BuildContext, HyperSelectionOverlayState)?
      contextMenuBuilder;

  const HyperSelectionOverlay({
    super.key,
    required this.document,
    this.baseStyle = const TextStyle(fontSize: 16, color: Color(0xFF000000)),
    this.onLinkTap,
    this.widgetBuilder,
    this.selectable = true,
    this.handleColor = const Color(0xFF2196F3),
    this.contextMenuBuilder,
  });

  @override
  State<HyperSelectionOverlay> createState() => HyperSelectionOverlayState();
}

class HyperSelectionOverlayState extends State<HyperSelectionOverlay> {
  /// Global key for accessing RenderHyperBox
  final GlobalKey _renderKey = GlobalKey();

  /// Focus node for keyboard shortcuts
  final FocusNode _focusNode = FocusNode();

  /// Whether context menu is showing
  bool _showContextMenu = false;

  /// Context menu position
  Offset _contextMenuPosition = Offset.zero;

  /// Selection handles positions
  Rect? _startHandleRect;
  Rect? _endHandleRect;

  /// Which handle is being dragged (used for visual feedback)
  // ignore: unused_field
  _HandlePosition? _draggingHandle;

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

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Copy selected text to clipboard
  Future<void> copySelection() async {
    final text = _renderBox?.getSelectedText();
    if (text != null && text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      _showCopiedSnackBar();
    }
  }

  /// Clear selection
  void clearSelection() {
    _renderBox?.clearSelection();
    setState(() {
      _showContextMenu = false;
      _startHandleRect = null;
      _endHandleRect = null;
    });
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
    if (hasSelection) {
      clearSelection();
    }
  }

  void _handleLongPress(LongPressStartDetails details) {
    if (!widget.selectable) return;

    // Show context menu at long press position
    setState(() {
      _showContextMenu = true;
      _contextMenuPosition = details.globalPosition;
    });
  }

  void _handleTap(TapDownDetails details) {
    // Hide context menu on tap
    if (_showContextMenu) {
      setState(() {
        _showContextMenu = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTapDown: _handleTap,
        onLongPressStart: _handleLongPress,
        behavior: HitTestBehavior.translucent,
        child: TapRegion(
          onTapOutside: (_) => _handleTapOutside(),
          child: Stack(
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
                ),
              ),

              // Selection handles
              if (hasSelection && widget.selectable) ...[
                if (_startHandleRect != null)
                  _buildHandle(_HandlePosition.start, _startHandleRect!),
                if (_endHandleRect != null)
                  _buildHandle(_HandlePosition.end, _endHandleRect!),
              ],

              // Context menu
              if (_showContextMenu && hasSelection)
                _buildContextMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(_HandlePosition position, Rect rect) {
    final isStart = position == _HandlePosition.start;

    // Native-style teardrop handle positioning
    // Start handle: teardrop points up, positioned at top-left of selection
    // End handle: teardrop points down, positioned at bottom-right of selection
    final left = isStart ? rect.left - 1 : rect.right - 1;
    final top = isStart ? rect.top - 22 : rect.bottom;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanStart: (_) {
          _draggingHandle = position;
          _focusNode.requestFocus();
        },
        onPanUpdate: (details) {
          final renderBox = _renderBox;
          if (renderBox == null) return;

          // Convert global position to local
          final RenderBox? box =
              _renderKey.currentContext?.findRenderObject() as RenderBox?;
          if (box == null) return;

          final localPosition = box.globalToLocal(details.globalPosition);
          renderBox.updateSelectionFromHandle(isStart, localPosition);
          _updateHandlePositions();
        },
        onPanEnd: (_) {
          _draggingHandle = null;
        },
        // Native teardrop handle design
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

  Widget _buildContextMenu(BuildContext context) {
    if (widget.contextMenuBuilder != null) {
      return widget.contextMenuBuilder!(context, this);
    }

    return Positioned(
      left: _contextMenuPosition.dx - 50,
      top: _contextMenuPosition.dy - 60,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ContextMenuButton(
                icon: Icons.copy,
                label: 'Copy',
                onTap: () {
                  copySelection();
                  setState(() => _showContextMenu = false);
                },
              ),
              _ContextMenuButton(
                icon: Icons.select_all,
                label: 'Select All',
                onTap: () {
                  selectAll();
                  setState(() => _showContextMenu = false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
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
