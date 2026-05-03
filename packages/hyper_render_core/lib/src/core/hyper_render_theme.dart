import 'package:flutter/material.dart';

/// Theme data for HyperRender styling and interactive elements.
///
/// Use [HyperRenderTheme] InheritedWidget to apply this theme across
/// an entire widget tree without prop-drilling.
class HyperRenderThemeData {
  const HyperRenderThemeData({
    this.baseStyle,
    this.selectionColor,
    this.selectionHandleColor,
    this.menuBackgroundColor,
  });

  /// Base text style for the document.
  final TextStyle? baseStyle;

  /// Highlight color for selected text.
  final Color? selectionColor;

  /// Color of the drag handles for text selection.
  final Color? selectionHandleColor;

  /// Background color of the selection context menu.
  final Color? menuBackgroundColor;

  /// Create a copy with some overwritten properties.
  HyperRenderThemeData copyWith({
    TextStyle? baseStyle,
    Color? selectionColor,
    Color? selectionHandleColor,
    Color? menuBackgroundColor,
  }) {
    return HyperRenderThemeData(
      baseStyle: baseStyle ?? this.baseStyle,
      selectionColor: selectionColor ?? this.selectionColor,
      selectionHandleColor: selectionHandleColor ?? this.selectionHandleColor,
      menuBackgroundColor: menuBackgroundColor ?? this.menuBackgroundColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HyperRenderThemeData &&
        other.baseStyle == baseStyle &&
        other.selectionColor == selectionColor &&
        other.selectionHandleColor == selectionHandleColor &&
        other.menuBackgroundColor == menuBackgroundColor;
  }

  @override
  int get hashCode => Object.hash(
        baseStyle,
        selectionColor,
        selectionHandleColor,
        menuBackgroundColor,
      );
}

/// An InheritedWidget that provides [HyperRenderThemeData] to descendants.
class HyperRenderTheme extends InheritedWidget {
  const HyperRenderTheme({
    super.key,
    required this.data,
    required super.child,
  });

  final HyperRenderThemeData data;

  /// Returns the nearest [HyperRenderThemeData] up the tree, or null.
  static HyperRenderThemeData? of(BuildContext context) {
    final theme =
        context.dependOnInheritedWidgetOfExactType<HyperRenderTheme>();
    return theme?.data;
  }

  @override
  bool updateShouldNotify(HyperRenderTheme oldWidget) => data != oldWidget.data;
}
