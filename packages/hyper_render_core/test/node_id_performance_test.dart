import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('NodeIdGenerator Performance', () {
    test('benchmark: generate 10K IDs', () {
      final generator = NodeIdGenerator();
      generator.reset();

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 10000; i++) {
        generator.next();
      }

      stopwatch.stop();

      print('10K IDs generated in ${stopwatch.elapsedMilliseconds}ms');

      // Should complete in <100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('benchmark: DateTime.now() overhead', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 10000; i++) {
        DateTime.now().microsecondsSinceEpoch;
      }

      stopwatch.stop();

      print('10K DateTime.now() calls: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('IDs are unique even when generated rapidly', () {
      final generator = NodeIdGenerator();
      generator.reset();

      final ids = <String>{};

      for (var i = 0; i < 1000; i++) {
        ids.add(generator.next());
      }

      // All IDs should be unique
      expect(ids.length, equals(1000));
    });
  });
}
