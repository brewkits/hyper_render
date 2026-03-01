import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';

// We need to test the LRU cache which is private in render_hyper_box.dart
// So we'll create a copy of it here for testing purposes
// This mirrors the implementation in render_hyper_box.dart

import 'dart:collection';

/// LRU Cache implementation for testing
class LruCache<K, V> {
  final int _maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();
  final void Function(V)? _onEvict;

  LruCache({required int maxSize, void Function(V)? onEvict})
      : _maxSize = maxSize,
        _onEvict = onEvict;

  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    final existing = _cache.remove(key);
    if (existing != null) {
      _onEvict?.call(existing);
    }

    while (_cache.length >= _maxSize) {
      final eldest = _cache.keys.first;
      final evicted = _cache.remove(eldest);
      if (evicted != null) {
        _onEvict?.call(evicted);
      }
    }

    _cache[key] = value;
  }

  bool containsKey(K key) => _cache.containsKey(key);

  void clear() {
    final onEvict = _onEvict;
    if (onEvict != null) {
      for (final value in _cache.values) {
        onEvict(value);
      }
    }
    _cache.clear();
  }

  int get length => _cache.length;

  Iterable<V> get values => _cache.values;
}

void main() {
  group('LruCache', () {
    group('Basic operations', () {
      test('put and get', () {
        final cache = LruCache<int, String>(maxSize: 10);

        cache.put(1, 'one');
        cache.put(2, 'two');
        cache.put(3, 'three');

        expect(cache.get(1), equals('one'));
        expect(cache.get(2), equals('two'));
        expect(cache.get(3), equals('three'));
      });

      test('get returns null for missing key', () {
        final cache = LruCache<int, String>(maxSize: 10);

        expect(cache.get(999), isNull);
      });

      test('containsKey works correctly', () {
        final cache = LruCache<int, String>(maxSize: 10);

        cache.put(1, 'one');

        expect(cache.containsKey(1), isTrue);
        expect(cache.containsKey(2), isFalse);
      });

      test('length returns correct count', () {
        final cache = LruCache<int, String>(maxSize: 10);

        expect(cache.length, equals(0));

        cache.put(1, 'one');
        expect(cache.length, equals(1));

        cache.put(2, 'two');
        expect(cache.length, equals(2));
      });

      test('values returns all values', () {
        final cache = LruCache<int, String>(maxSize: 10);

        cache.put(1, 'one');
        cache.put(2, 'two');
        cache.put(3, 'three');

        expect(cache.values.toList(), containsAll(['one', 'two', 'three']));
      });
    });

    group('Eviction', () {
      test('evicts eldest when capacity exceeded', () {
        final cache = LruCache<int, String>(maxSize: 3);

        cache.put(1, 'one');
        cache.put(2, 'two');
        cache.put(3, 'three');
        cache.put(4, 'four'); // Should evict 'one'

        expect(cache.length, equals(3));
        expect(cache.get(1), isNull); // Evicted
        expect(cache.get(2), equals('two'));
        expect(cache.get(3), equals('three'));
        expect(cache.get(4), equals('four'));
      });

      test('get updates access order', () {
        final cache = LruCache<int, String>(maxSize: 3);

        cache.put(1, 'one');
        cache.put(2, 'two');
        cache.put(3, 'three');

        // Access '1' to make it recently used
        cache.get(1);

        cache.put(4, 'four'); // Should evict '2' (now the eldest)

        expect(cache.get(1), equals('one')); // Not evicted
        expect(cache.get(2), isNull); // Evicted
        expect(cache.get(3), equals('three'));
        expect(cache.get(4), equals('four'));
      });

      test('calls onEvict callback when evicting', () {
        final evicted = <String>[];
        final cache = LruCache<int, String>(
          maxSize: 2,
          onEvict: (value) => evicted.add(value),
        );

        cache.put(1, 'one');
        cache.put(2, 'two');
        cache.put(3, 'three'); // Evicts 'one'
        cache.put(4, 'four'); // Evicts 'two'

        expect(evicted, equals(['one', 'two']));
      });

      test('calls onEvict when replacing existing key', () {
        final evicted = <String>[];
        final cache = LruCache<int, String>(
          maxSize: 3,
          onEvict: (value) => evicted.add(value),
        );

        cache.put(1, 'one');
        cache.put(1, 'ONE'); // Replace existing

        expect(evicted, equals(['one']));
        expect(cache.get(1), equals('ONE'));
      });
    });

    group('Clear', () {
      test('clear removes all entries', () {
        final cache = LruCache<int, String>(maxSize: 10);

        cache.put(1, 'one');
        cache.put(2, 'two');
        cache.put(3, 'three');

        cache.clear();

        expect(cache.length, equals(0));
        expect(cache.get(1), isNull);
        expect(cache.get(2), isNull);
        expect(cache.get(3), isNull);
      });

      test('clear calls onEvict for all entries', () {
        final evicted = <String>[];
        final cache = LruCache<int, String>(
          maxSize: 10,
          onEvict: (value) => evicted.add(value),
        );

        cache.put(1, 'one');
        cache.put(2, 'two');
        cache.put(3, 'three');

        cache.clear();

        expect(evicted.length, equals(3));
        expect(evicted, containsAll(['one', 'two', 'three']));
      });
    });

    group('Edge cases', () {
      test('maxSize of 1 only holds one element', () {
        final cache = LruCache<int, String>(maxSize: 1);

        cache.put(1, 'one');
        expect(cache.length, equals(1));
        expect(cache.get(1), equals('one'));

        cache.put(2, 'two');
        expect(cache.length, equals(1));
        expect(cache.get(1), isNull);
        expect(cache.get(2), equals('two'));
      });

      test('putting same key multiple times updates value', () {
        final cache = LruCache<int, String>(maxSize: 10);

        cache.put(1, 'one');
        cache.put(1, 'ONE');
        cache.put(1, 'One');

        expect(cache.length, equals(1));
        expect(cache.get(1), equals('One'));
      });

      test('get on non-existent key does not affect cache', () {
        final cache = LruCache<int, String>(maxSize: 10);

        cache.put(1, 'one');
        cache.get(999);

        expect(cache.length, equals(1));
        expect(cache.containsKey(999), isFalse);
      });
    });

    group('With TextPainter-like objects', () {
      test('can cache TextPainter objects', () {
        var disposeCount = 0;

        final cache = LruCache<int, TextPainter>(
          maxSize: 2,
          onEvict: (painter) {
            painter.dispose();
            disposeCount++;
          },
        );

        final painter1 = TextPainter(
          text: const TextSpan(text: 'Hello'),
          textDirection: TextDirection.ltr,
        )..layout();

        final painter2 = TextPainter(
          text: const TextSpan(text: 'World'),
          textDirection: TextDirection.ltr,
        )..layout();

        final painter3 = TextPainter(
          text: const TextSpan(text: 'Test'),
          textDirection: TextDirection.ltr,
        )..layout();

        cache.put(1, painter1);
        cache.put(2, painter2);
        expect(disposeCount, equals(0));

        cache.put(3, painter3); // Evicts painter1
        expect(disposeCount, equals(1));

        cache.clear();
        expect(disposeCount, equals(3));
      });
    });

    group('LRU ordering', () {
      test('maintains correct LRU order', () {
        final evictOrder = <int>[];
        final cache = LruCache<int, String>(
          maxSize: 3,
          onEvict: (value) => evictOrder.add(int.parse(value)),
        );

        // Add 1, 2, 3
        cache.put(1, '1');
        cache.put(2, '2');
        cache.put(3, '3');

        // Access 1 and 2 (1 becomes most recent, then 2)
        cache.get(1);
        cache.get(2);

        // Add 4 - should evict 3 (oldest accessed)
        cache.put(4, '4');
        expect(evictOrder, equals([3]));

        // Add 5 - should evict 1 (now oldest)
        cache.put(5, '5');
        expect(evictOrder, equals([3, 1]));

        // Add 6 - should evict 2
        cache.put(6, '6');
        expect(evictOrder, equals([3, 1, 2]));
      });

      test('put moves existing key to most recent', () {
        final evictOrder = <int>[];
        final cache = LruCache<int, String>(
          maxSize: 3,
          onEvict: (value) => evictOrder.add(int.parse(value.substring(0, 1))),
        );

        cache.put(1, '1');
        cache.put(2, '2');
        cache.put(3, '3');

        // Update 1 - moves it to most recent
        cache.put(1, '1-updated');

        // Add 4 - should evict 2 (now oldest)
        cache.put(4, '4');

        // First eviction is the old value of key 1
        expect(evictOrder, equals([1, 2]));
      });
    });
  });
}
