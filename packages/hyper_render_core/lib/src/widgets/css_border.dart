import 'package:flutter/material.dart';

import '../model/computed_style.dart';

/// Builds a [Border] from [style]'s border widths, mapping zero-width sides
/// to [BorderSide.none].
///
/// A `BorderSide(width: 0, style: BorderStyle.solid)` is a hairline border in
/// Flutter and asserts when combined with a non-zero border radius, so sides
/// the CSS declared as `0px` must be omitted entirely (issue #12).
Border cssBorderFromStyle(ComputedStyle style) {
  final color = style.borderColor ?? Colors.transparent;
  BorderSide side(double width) =>
      width > 0 ? BorderSide(color: color, width: width) : BorderSide.none;
  return Border(
    top: side(style.borderWidth.top),
    right: side(style.borderWidth.right),
    bottom: side(style.borderWidth.bottom),
    left: side(style.borderWidth.left),
  );
}
