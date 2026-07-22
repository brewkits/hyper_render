// DOCS ↔ CODE SYNC GUARD (the "no over-claim / no stale under-claim" net).
//
// The CSS support matrix (doc/CSS_PROPERTIES_MATRIX.md) has drifted from the
// code three times this project (claiming ✅ for properties that didn't execute;
// leaving a property ❌ after it shipped). This test locks the matrix to two
// things the code actually proves:
//
//  1. EXECUTION-VERIFIED — every property that has a render-level execution test
//     (test/style/css_execution_guard_test.dart + table_border_spacing_test.dart)
//     MUST be marked ✅ in the matrix. Downgrading or deleting such a row without
//     removing the test fails here.
//
//  2. STRUCTURALLY-UNSUPPORTED — properties the single-RenderObject design cannot
//     support (documented in doc/LIMITATIONS.md) MUST NOT be marked ✅. An
//     accidental over-claim (marking one ✅) fails here.
//
// This deliberately does NOT require *every* ✅ row to have a test — most CSS
// properties (color, font-weight, …) execute trivially and need no guard. It
// pins the two ends that actually drift.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

const _matrixPath = 'doc/CSS_PROPERTIES_MATRIX.md';

/// Properties with a render-level execution test proving they change output.
/// Keep in sync with css_execution_guard_test.dart + table_border_spacing_test.
const _executionVerified = <String>[
  'width',
  'max-width',
  'min-width',
  'padding',
  'margin',
  'font-size',
  'line-height',
  'text-align',
  'text-indent',
  'display',
  'white-space',
  'border-collapse',
  'border-spacing',
];

/// Properties the architecture cannot fully support (see LIMITATIONS.md).
/// The exact first-cell text as it appears in the matrix.
const _mustNotBeFull = <String>[
  'position: absolute',
  'position: fixed',
  'z-index',
];

/// Returns the status symbol (first char of the Status cell) for the first
/// matrix row whose first cell contains `prop` in backticks, or null.
String? _statusOf(List<String> lines, String prop) {
  for (final line in lines) {
    if (!line.startsWith('|')) continue;
    final cells = line.split('|').map((c) => c.trim()).toList();
    // cells[0] is empty (leading pipe); cells[1] = property, cells[2] = status.
    if (cells.length < 3) continue;
    if (cells[1].contains('`$prop`')) {
      return cells[2];
    }
  }
  return null;
}

void main() {
  group('docs ↔ code matrix sync', () {
    final lines = File(_matrixPath).readAsLinesSync();

    test('matrix file exists and is a table', () {
      expect(lines.where((l) => l.startsWith('|')), isNotEmpty);
    });

    for (final prop in _executionVerified) {
      test('execution-verified "$prop" is marked ✅ in the matrix', () {
        final status = _statusOf(lines, prop);
        expect(status, isNotNull,
            reason: '`$prop` has an execution test but no matrix row — '
                'add the row (or rename to match the test list).');
        expect(status, contains('✅'),
            reason: '`$prop` has an execution test proving it renders, but the '
                'matrix marks it "$status". Do not downgrade a proven property.');
      });
    }

    for (final prop in _mustNotBeFull) {
      test('structurally-unsupported "$prop" is NOT marked ✅', () {
        final status = _statusOf(lines, prop);
        if (status == null) return; // absent is fine
        expect(status.contains('✅'), isFalse,
            reason: '`$prop` is unsupported by the single-RenderObject design '
                '(see LIMITATIONS.md) but the matrix claims full support.');
      });
    }
  });
}
