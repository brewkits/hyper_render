// Regression test for flutter_html #1504 / #1314: CSS transform parsing must
// not use a negative-lookbehind regex.
//
// `RegExp(r'(?<![XY])translate\(...')` throws
// `FormatException: Illegal RegExp pattern` (native) /
// `SyntaxError: Invalid regular expression` (Flutter Web / older Safari),
// crashing the whole widget when a `@keyframes` transform is parsed. The
// lookbehind was redundant — `translate\(` already excludes
// `translateX(`/`translateY(` — and is now removed.
//
// This test locks the parse behavior so a future edit can't silently
// reintroduce a lookbehind (or change which axes each function sets).

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

HyperKeyframe? _fromFrame(String transform) {
  final css =
      '@keyframes k { from { transform: $transform; } to { opacity: 1; } }';
  final frames = const DefaultCssParser().parseKeyframes(css);
  final k = frames['k'];
  if (k == null || k.keyframes.isEmpty) return null;
  return k.keyframes.first;
}

void main() {
  group('CSS transform keyframe parsing (web-safe, no lookbehind)', () {
    test('translate(x, y) sets both axes', () {
      final k = _fromFrame('translate(10px, 20px)');
      expect(k?.translateX, 10);
      expect(k?.translateY, 20);
    });

    test('translate(x) sets only X', () {
      final k = _fromFrame('translate(10px)');
      expect(k?.translateX, 10);
      expect(k?.translateY, isNull);
    });

    test('translateX() sets only X, not caught by translate()', () {
      final k = _fromFrame('translateX(5px)');
      expect(k?.translateX, 5);
      expect(k?.translateY, isNull);
    });

    test('translateY() sets only Y', () {
      final k = _fromFrame('translateY(7px)');
      expect(k?.translateY, 7);
      expect(k?.translateX, isNull);
    });

    test('translateX + translateY combined', () {
      final k = _fromFrame('translateX(5px) translateY(7px)');
      expect(k?.translateX, 5);
      expect(k?.translateY, 7);
    });

    test('scale()', () {
      expect(_fromFrame('scale(1.5)')?.scale, 1.5);
    });

    test('translate + scale combined', () {
      final k = _fromFrame('translate(10px, 20px) scale(2)');
      expect(k?.translateX, 10);
      expect(k?.translateY, 20);
      expect(k?.scale, 2);
    });

    test('negative translate values', () {
      final k = _fromFrame('translate(-3px, -4px)');
      expect(k?.translateX, -3);
      expect(k?.translateY, -4);
    });

    test('rotate(deg)', () {
      expect(_fromFrame('rotate(45deg)')?.rotation, 45);
    });

    test('parsing a transform never throws (no illegal-regex crash)', () {
      // The whole point: this call path must not throw a FormatException from
      // an unsupported regex construct. Exercise every branch in one go.
      expect(
        () => _fromFrame(
            'translate(1px, 2px) translateX(3px) translateY(4px) scale(2) rotate(90deg)'),
        returnsNormally,
      );
    });
  });
}
