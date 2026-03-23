import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

/// Performance tests for UDTNode ID generation.
///
/// The codebase does not expose a `NodeIdGenerator` class.  These tests
/// verify that creating many nodes with auto-generated IDs is fast and that
/// all IDs remain unique.
void main() {
  group('UDTNode ID generation performance', () {
    test('benchmark: create 10K TextNodes with unique IDs', () {
      final stopwatch = Stopwatch()..start();

      final ids = <String>{};
      for (var i = 0; i < 10000; i++) {
        ids.add(TextNode('Node $i').id);
      }

      stopwatch.stop();

      // ignore: avoid_print
      print('10K TextNodes created in ${stopwatch.elapsedMilliseconds}ms');

      // All IDs must be unique
      expect(ids.length, equals(10000));

      // Should complete in <200ms on any reasonable machine
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });

    test('IDs are unique even when generated rapidly', () {
      final ids = <String>{};
      for (var i = 0; i < 1000; i++) {
        ids.add(TextNode('Node $i').id);
      }

      expect(ids.length, equals(1000));
    });

    test('benchmark: DateTime.now() overhead for comparison', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 10000; i++) {
        DateTime.now().microsecondsSinceEpoch;
      }

      stopwatch.stop();

      // ignore: avoid_print
      print('10K DateTime.now() calls: ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
