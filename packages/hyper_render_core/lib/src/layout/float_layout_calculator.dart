/// Float Layout Calculator - Pure Dart
///
/// Extracted from RenderHyperBox to enable unit testing.
/// NO Flutter dependencies - pure geometry calculations.
library;

import 'dart:math' as math;
import 'dart:ui' show Rect;

import '../model/fragment.dart';
import '../model/computed_style.dart';

/// A float area occupying space in the layout
class FloatArea {
  final Rect rect;
  final HyperFloat side; // left or right
  final Fragment? sourceFragment;

  const FloatArea({
    required this.rect,
    required this.side,
    this.sourceFragment,
  });

  double get left => rect.left;
  double get top => rect.top;
  double get right => rect.right;
  double get bottom => rect.bottom;
  double get width => rect.width;
  double get height => rect.height;

  /// Check if this float affects a given Y coordinate
  bool affectsY(double y) {
    return y >= rect.top && y < rect.bottom;
  }

  @override
  String toString() =>
      'FloatArea(${side.name}, rect: $rect)';
}

/// Result of float layout calculation
class FloatLayoutResult {
  final FloatArea floatArea;
  final List<FloatArea> updatedLeftFloats;
  final List<FloatArea> updatedRightFloats;

  const FloatLayoutResult({
    required this.floatArea,
    required this.updatedLeftFloats,
    required this.updatedRightFloats,
  });
}

/// Pure Dart calculator for CSS float layout
///
/// NO Flutter dependencies!
/// Handles float positioning and space calculation.
class FloatLayoutCalculator {
  const FloatLayoutCalculator();

  /// Layout a float element
  ///
  /// Returns the FloatArea where the float was positioned.
  /// This is PURE calculation - no rendering!
  FloatArea layoutFloat({
    required Fragment fragment,
    required double currentY,
    required double maxWidth,
    required List<FloatArea> existingLeftFloats,
    required List<FloatArea> existingRightFloats,
    required double leftPadding,
    required double rightPadding,
  }) {
    final floatSide = fragment.style.float;
    final width = fragment.width;
    final height = fragment.height;

    double left;
    double top = currentY;

    if (floatSide == HyperFloat.left) {
      // Position at leftmost available position
      left = leftPadding;

      // Push right if there are existing left floats at this Y
      for (final existing in existingLeftFloats) {
        if (existing.affectsY(top)) {
          left = math.max(left, existing.right);
        }
      }

      // Check if there's enough space, otherwise move down
      while (left + width > maxWidth - rightPadding) {
        // Not enough space - find next Y position past some float
        final nextY = _findNextClearY(
          currentY: top,
          leftFloats: existingLeftFloats,
          rightFloats: existingRightFloats,
        );

        if (nextY <= top) {
          // No floats to clear - break to avoid infinite loop
          break;
        }

        top = nextY;
        left = leftPadding;

        // Recalculate left inset at new Y
        for (final existing in existingLeftFloats) {
          if (existing.affectsY(top)) {
            left = math.max(left, existing.right);
          }
        }
      }
    } else {
      // Float right
      left = maxWidth - width - rightPadding;

      // Push left if there are existing right floats at this Y
      for (final existing in existingRightFloats) {
        if (existing.affectsY(top)) {
          left = math.min(left, existing.left - width);
        }
      }

      // Check if there's enough space
      while (left < leftPadding) {
        // Not enough space - find next Y position past some float
        final nextY = _findNextClearY(
          currentY: top,
          leftFloats: existingLeftFloats,
          rightFloats: existingRightFloats,
        );

        if (nextY <= top) {
          break;
        }

        top = nextY;
        left = maxWidth - width - rightPadding;

        // Recalculate at new Y
        for (final existing in existingRightFloats) {
          if (existing.affectsY(top)) {
            left = math.min(left, existing.left - width);
          }
        }
      }
    }

    return FloatArea(
      rect: Rect.fromLTWH(left, top, width, height),
      side: floatSide,
      sourceFragment: fragment,
    );
  }

  /// Calculate available width at Y position considering floats
  ///
  /// Pure math - no Flutter!
  double calculateAvailableWidth({
    required double currentY,
    required double maxWidth,
    required List<FloatArea> leftFloats,
    required List<FloatArea> rightFloats,
    required double leftPadding,
    required double rightPadding,
  }) {
    double leftInset = leftPadding;
    double rightInset = rightPadding;

    // Add insets from active floats
    for (final float in leftFloats) {
      if (float.affectsY(currentY)) {
        leftInset = math.max(leftInset, float.right);
      }
    }

    for (final float in rightFloats) {
      if (float.affectsY(currentY)) {
        rightInset = math.max(rightInset, maxWidth - float.left);
      }
    }

    return maxWidth - leftInset - rightInset;
  }

  /// Find insets (left and right) at given Y
  ({double left, double right}) calculateInsets({
    required double currentY,
    required double maxWidth,
    required List<FloatArea> leftFloats,
    required List<FloatArea> rightFloats,
    required double leftPadding,
    required double rightPadding,
  }) {
    double leftInset = leftPadding;
    double rightInset = rightPadding;

    for (final float in leftFloats) {
      if (float.affectsY(currentY)) {
        leftInset = math.max(leftInset, float.right);
      }
    }

    for (final float in rightFloats) {
      if (float.affectsY(currentY)) {
        rightInset = math.max(rightInset, maxWidth - float.left);
      }
    }

    return (left: leftInset, right: rightInset);
  }

  /// Find Y position where full width is available (clear of floats)
  ///
  /// Pure logic!
  double findClearY({
    required double currentY,
    required List<FloatArea> leftFloats,
    required List<FloatArea> rightFloats,
    HyperClear clearType = HyperClear.both,
  }) {
    double clearY = currentY;

    if (clearType == HyperClear.left || clearType == HyperClear.both) {
      for (final float in leftFloats) {
        if (float.affectsY(currentY)) {
          clearY = math.max(clearY, float.bottom);
        }
      }
    }

    if (clearType == HyperClear.right || clearType == HyperClear.both) {
      for (final float in rightFloats) {
        if (float.affectsY(currentY)) {
          clearY = math.max(clearY, float.bottom);
        }
      }
    }

    return clearY;
  }

  double _findNextClearY({
    required double currentY,
    required List<FloatArea> leftFloats,
    required List<FloatArea> rightFloats,
  }) {
    double nextY = currentY + 1;

    for (final float in leftFloats) {
      if (float.affectsY(currentY)) {
        nextY = math.max(nextY, float.bottom);
      }
    }

    for (final float in rightFloats) {
      if (float.affectsY(currentY)) {
        nextY = math.max(nextY, float.bottom);
      }
    }

    return nextY;
  }
}
