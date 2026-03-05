/// Pure Dart tests for FloatLayoutCalculator
///
/// NO Flutter dependencies! Runs in milliseconds!
library;

import 'package:test/test.dart';
import 'dart:ui' show Rect;

import 'package:hyper_render_core/src/layout/float_layout_calculator.dart';
import 'package:hyper_render_core/src/model/computed_style.dart';

void main() {
  group('FloatLayoutCalculator', () {
    late FloatLayoutCalculator calculator;

    setUp(() {
      calculator = const FloatLayoutCalculator();
    });

    group('calculateAvailableWidth', () {
      test('returns full width with no floats', () {
        final width = calculator.calculateAvailableWidth(
          currentY: 50,
          maxWidth: 300,
          leftFloats: [],
          rightFloats: [],
          leftPadding: 0,
          rightPadding: 0,
        );

        expect(width, 300);
      });

      test('reduces width for left float', () {
        final leftFloats = [
          FloatArea(
            rect: Rect.fromLTWH(0, 0, 100, 100),
            side: HyperFloat.left,
          ),
        ];

        final width = calculator.calculateAvailableWidth(
          currentY: 50, // Inside float range
          maxWidth: 300,
          leftFloats: leftFloats,
          rightFloats: [],
          leftPadding: 0,
          rightPadding: 0,
        );

        expect(width, 200); // 300 - 100
      });

      test('reduces width for right float', () {
        final rightFloats = [
          FloatArea(
            rect: Rect.fromLTWH(200, 0, 100, 100),
            side: HyperFloat.right,
          ),
        ];

        final width = calculator.calculateAvailableWidth(
          currentY: 50,
          maxWidth: 300,
          leftFloats: [],
          rightFloats: rightFloats,
          leftPadding: 0,
          rightPadding: 0,
        );

        expect(width, 200); // 300 - 100
      });

      test('reduces width for both floats', () {
        final leftFloats = [
          FloatArea(
            rect: Rect.fromLTWH(0, 0, 50, 100),
            side: HyperFloat.left,
          ),
        ];

        final rightFloats = [
          FloatArea(
            rect: Rect.fromLTWH(250, 0, 50, 100),
            side: HyperFloat.right,
          ),
        ];

        final width = calculator.calculateAvailableWidth(
          currentY: 50,
          maxWidth: 300,
          leftFloats: leftFloats,
          rightFloats: rightFloats,
          leftPadding: 0,
          rightPadding: 0,
        );

        expect(width, 200); // 300 - 50 - 50
      });

      test('ignores floats below current Y', () {
        final leftFloats = [
          FloatArea(
            rect: Rect.fromLTWH(0, 100, 100, 50), // Starts at Y=100
            side: HyperFloat.left,
          ),
        ];

        final width = calculator.calculateAvailableWidth(
          currentY: 50, // Above float
          maxWidth: 300,
          leftFloats: leftFloats,
          rightFloats: [],
          leftPadding: 0,
          rightPadding: 0,
        );

        expect(width, 300); // Not affected
      });

      test('ignores floats above current Y', () {
        final leftFloats = [
          FloatArea(
            rect: Rect.fromLTWH(0, 0, 100, 30), // Ends at Y=30
            side: HyperFloat.left,
          ),
        ];

        final width = calculator.calculateAvailableWidth(
          currentY: 50, // Below float
          maxWidth: 300,
          leftFloats: leftFloats,
          rightFloats: [],
          leftPadding: 0,
          rightPadding: 0,
        );

        expect(width, 300); // Not affected
      });

      test('respects padding', () {
        final width = calculator.calculateAvailableWidth(
          currentY: 50,
          maxWidth: 300,
          leftFloats: [],
          rightFloats: [],
          leftPadding: 20,
          rightPadding: 30,
        );

        expect(width, 250); // 300 - 20 - 30
      });
    });

    group('calculateInsets', () {
      test('returns padding with no floats', () {
        final insets = calculator.calculateInsets(
          currentY: 50,
          maxWidth: 300,
          leftFloats: [],
          rightFloats: [],
          leftPadding: 10,
          rightPadding: 20,
        );

        expect(insets.left, 10);
        expect(insets.right, 20);
      });

      test('includes left float', () {
        final leftFloats = [
          FloatArea(
            rect: Rect.fromLTWH(0, 0, 100, 100),
            side: HyperFloat.left,
          ),
        ];

        final insets = calculator.calculateInsets(
          currentY: 50,
          maxWidth: 300,
          leftFloats: leftFloats,
          rightFloats: [],
          leftPadding: 0,
          rightPadding: 0,
        );

        expect(insets.left, 100); // Float right edge
        expect(insets.right, 0);
      });

      test('uses max of padding and float', () {
        final leftFloats = [
          FloatArea(
            rect: Rect.fromLTWH(0, 0, 100, 100),
            side: HyperFloat.left,
          ),
        ];

        final insets = calculator.calculateInsets(
          currentY: 50,
          maxWidth: 300,
          leftFloats: leftFloats,
          rightFloats: [],
          leftPadding: 120, // Larger than float
          rightPadding: 0,
        );

        expect(insets.left, 120); // Padding wins
      });
    });

    group('findClearY', () {
      test('returns same Y when no floats', () {
        final clearY = calculator.findClearY(
          currentY: 50,
          leftFloats: [],
          rightFloats: [],
        );

        expect(clearY, 50);
      });

      test('returns past left float bottom', () {
        final leftFloats = [
          FloatArea(
            rect: Rect.fromLTWH(0, 0, 100, 150), // Bottom at 150
            side: HyperFloat.left,
          ),
        ];

        final clearY = calculator.findClearY(
          currentY: 50,
          leftFloats: leftFloats,
          rightFloats: [],
        );

        expect(clearY, 150);
      });

      test('returns past right float bottom', () {
        final rightFloats = [
          FloatArea(
            rect: Rect.fromLTWH(200, 0, 100, 120), // Bottom at 120
            side: HyperFloat.right,
          ),
        ];

        final clearY = calculator.findClearY(
          currentY: 50,
          leftFloats: [],
          rightFloats: rightFloats,
        );

        expect(clearY, 120);
      });

      test('returns past tallest float', () {
        final leftFloats = [
          FloatArea(
            rect: Rect.fromLTWH(0, 0, 50, 100), // Bottom at 100
            side: HyperFloat.left,
          ),
        ];

        final rightFloats = [
          FloatArea(
            rect: Rect.fromLTWH(250, 0, 50, 150), // Bottom at 150 (taller)
            side: HyperFloat.right,
          ),
        ];

        final clearY = calculator.findClearY(
          currentY: 50,
          leftFloats: leftFloats,
          rightFloats: rightFloats,
        );

        expect(clearY, 150); // Tallest float
      });

      test('respects clear type - left only', () {
        final leftFloats = [
          FloatArea(
            rect: Rect.fromLTWH(0, 0, 50, 100),
            side: HyperFloat.left,
          ),
        ];

        final rightFloats = [
          FloatArea(
            rect: Rect.fromLTWH(250, 0, 50, 150),
            side: HyperFloat.right,
          ),
        ];

        final clearY = calculator.findClearY(
          currentY: 50,
          leftFloats: leftFloats,
          rightFloats: rightFloats,
          clearType: HyperClear.left,
        );

        expect(clearY, 100); // Only left float
      });

      test('respects clear type - right only', () {
        final leftFloats = [
          FloatArea(
            rect: Rect.fromLTWH(0, 0, 50, 100),
            side: HyperFloat.left,
          ),
        ];

        final rightFloats = [
          FloatArea(
            rect: Rect.fromLTWH(250, 0, 50, 150),
            side: HyperFloat.right,
          ),
        ];

        final clearY = calculator.findClearY(
          currentY: 50,
          leftFloats: leftFloats,
          rightFloats: rightFloats,
          clearType: HyperClear.right,
        );

        expect(clearY, 150); // Only right float
      });
    });

    group('FloatArea', () {
      test('affectsY returns true for Y inside', () {
        final float = FloatArea(
          rect: Rect.fromLTWH(0, 50, 100, 100), // Y: 50-150
          side: HyperFloat.left,
        );

        expect(float.affectsY(50), isTrue); // At top
        expect(float.affectsY(100), isTrue); // Middle
        expect(float.affectsY(149), isTrue); // Just before bottom
      });

      test('affectsY returns false for Y outside', () {
        final float = FloatArea(
          rect: Rect.fromLTWH(0, 50, 100, 100), // Y: 50-150
          side: HyperFloat.left,
        );

        expect(float.affectsY(49), isFalse); // Before
        expect(float.affectsY(150), isFalse); // At bottom (exclusive)
        expect(float.affectsY(200), isFalse); // After
      });

      test('properties are correct', () {
        final float = FloatArea(
          rect: Rect.fromLTWH(10, 20, 100, 50),
          side: HyperFloat.left,
        );

        expect(float.left, 10);
        expect(float.top, 20);
        expect(float.width, 100);
        expect(float.height, 50);
        expect(float.right, 110); // 10 + 100
        expect(float.bottom, 70); // 20 + 50
      });
    });
  });
}
