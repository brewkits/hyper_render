import 'package:flutter/widgets.dart';

/// Selection handle position
enum SelectionHandlePosition { start, end }

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

/// Interface for selection overlay control
abstract class SelectionOverlayController {
  void selectAll();
  void clearSelection();
  void copySelection();
  String? get selectedText;
}
