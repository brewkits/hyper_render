import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('NodeIdGenerator', () {
    setUp(() {
      // Reset before each test
      NodeIdGenerator().reset();
    });

    test('generates unique IDs', () {
      final gen = NodeIdGenerator();
      final id1 = gen.next();
      final id2 = gen.next();
      final id3 = gen.next();

      expect(id1, isNot(equals(id2)));
      expect(id2, isNot(equals(id3)));
      expect(id1, isNot(equals(id3)));
    });

    test('includes timestamp in ID', () {
      final gen = NodeIdGenerator();
      final id = gen.next();

      expect(id, startsWith('node_'));
      expect(id, contains('_'));

      // Should have format: node_{timestamp}_{counter}
      final parts = id.split('_');
      expect(parts.length, equals(3));
      expect(parts[0], equals('node'));
      expect(int.tryParse(parts[1]), isNotNull); // timestamp
      expect(int.tryParse(parts[2]), isNotNull); // counter
    });

    test('counter increments', () {
      final gen = NodeIdGenerator();
      gen.reset();

      expect(gen.counter, equals(0));

      gen.next();
      expect(gen.counter, equals(1));

      gen.next();
      expect(gen.counter, equals(2));

      gen.next();
      expect(gen.counter, equals(3));
    });

    test('resets counter at 1M to prevent overflow', () {
      final gen = NodeIdGenerator();
      gen.reset();

      // Simulate approaching overflow
      for (var i = 0; i < 999999; i++) {
        gen.next();
      }

      expect(gen.counter, equals(999999));

      // Next call should reset
      gen.next();
      expect(gen.counter, equals(0));
    });

    test('reset() sets counter back to zero', () {
      final gen = NodeIdGenerator();

      gen.next();
      gen.next();
      gen.next();

      expect(gen.counter, equals(3));

      gen.reset();
      expect(gen.counter, equals(0));
    });

    test('singleton pattern - same instance', () {
      final gen1 = NodeIdGenerator();
      final gen2 = NodeIdGenerator();

      expect(identical(gen1, gen2), isTrue);

      gen1.next();
      expect(gen2.counter, equals(1)); // Same instance, same counter
    });

    test('UDTNode uses generator for IDs', () {
      NodeIdGenerator().reset();

      final node1 = TextNode('Hello');
      final node2 = TextNode('World');

      // IDs should be different
      expect(node1.id, isNot(equals(node2.id)));

      // Should use new format
      expect(node1.id, startsWith('node_'));
      expect(node2.id, startsWith('node_'));
    });

    test('custom IDs still work', () {
      final node = TextNode('Test', id: 'custom-id-123');

      expect(node.id, equals('custom-id-123'));
    });

    test('stress test - generate 10K IDs', () {
      NodeIdGenerator().reset();

      final ids = <String>{};
      for (var i = 0; i < 10000; i++) {
        final node = TextNode('Node $i');
        ids.add(node.id);
      }

      // All IDs should be unique
      expect(ids.length, equals(10000));
    });
  });
}
