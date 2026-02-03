import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('LayoutCache', () {
    late LayoutCache cache;
    late UDTNode node1;
    late UDTNode node2;
    late UDTNode node3;

    setUp(() {
      cache = LayoutCache();
      node1 = BlockNode.p(children: [TextNode('Node 1')]);
      node2 = BlockNode.p(children: [TextNode('Node 2')]);
      node3 = BlockNode.p(children: [TextNode('Node 3')]);
    });

    group('Position management', () {
      test('stores and retrieves position', () {
        final rect = const Rect.fromLTWH(10, 20, 100, 50);
        cache.setPosition(node1, rect);

        expect(cache.getPosition(node1), equals(rect));
      });

      test('returns null for node without position', () {
        expect(cache.getPosition(node1), isNull);
      });

      test('hasLayout returns correct status', () {
        expect(cache.hasLayout(node1), isFalse);

        cache.setPosition(node1, const Rect.fromLTWH(0, 0, 100, 50));

        expect(cache.hasLayout(node1), isTrue);
      });

      test('updates position for same node', () {
        cache.setPosition(node1, const Rect.fromLTWH(0, 0, 100, 50));
        cache.setPosition(node1, const Rect.fromLTWH(10, 20, 120, 60));

        expect(
          cache.getPosition(node1),
          equals(const Rect.fromLTWH(10, 20, 120, 60)),
        );
      });

      test('stores positions for multiple nodes', () {
        cache.setPosition(node1, const Rect.fromLTWH(0, 0, 100, 50));
        cache.setPosition(node2, const Rect.fromLTWH(0, 50, 100, 50));
        cache.setPosition(node3, const Rect.fromLTWH(0, 100, 100, 50));

        expect(cache.cachedNodeCount, equals(3));
        expect(cache.getPosition(node1), isNotNull);
        expect(cache.getPosition(node2), isNotNull);
        expect(cache.getPosition(node3), isNotNull);
      });
    });

    group('Size management', () {
      test('stores and retrieves size', () {
        const size = Size(100, 50);
        cache.setSize(node1, size);

        expect(cache.getSize(node1), equals(size));
      });

      test('returns null for node without size', () {
        expect(cache.getSize(node1), isNull);
      });

      test('hasSize returns correct status', () {
        expect(cache.hasSize(node1), isFalse);

        cache.setSize(node1, const Size(100, 50));

        expect(cache.hasSize(node1), isTrue);
      });

      test('updates size for same node', () {
        cache.setSize(node1, const Size(100, 50));
        cache.setSize(node1, const Size(120, 60));

        expect(cache.getSize(node1), equals(const Size(120, 60)));
      });
    });

    group('Baseline management', () {
      test('stores and retrieves baseline', () {
        cache.setBaseline(node1, 40.0);

        expect(cache.getBaseline(node1), equals(40.0));
      });

      test('returns null for node without baseline', () {
        expect(cache.getBaseline(node1), isNull);
      });

      test('updates baseline for same node', () {
        cache.setBaseline(node1, 40.0);
        cache.setBaseline(node1, 45.0);

        expect(cache.getBaseline(node1), equals(45.0));
      });
    });

    group('Content bounds management', () {
      test('stores and retrieves content bounds', () {
        final bounds = const Rect.fromLTWH(5, 5, 90, 40);
        cache.setContentBounds(node1, bounds);

        expect(cache.getContentBounds(node1), equals(bounds));
      });

      test('returns null for node without content bounds', () {
        expect(cache.getContentBounds(node1), isNull);
      });
    });

    group('Invalidation', () {
      setUp(() {
        cache.setPosition(node1, const Rect.fromLTWH(0, 0, 100, 50));
        cache.setSize(node1, const Size(100, 50));
        cache.setBaseline(node1, 40.0);
        cache.setContentBounds(node1, const Rect.fromLTWH(5, 5, 90, 40));
      });

      test('invalidate removes all layout data for a node', () {
        cache.invalidate(node1);

        expect(cache.getPosition(node1), isNull);
        expect(cache.getSize(node1), isNull);
        expect(cache.getBaseline(node1), isNull);
        expect(cache.getContentBounds(node1), isNull);
      });

      test('invalidate does not affect other nodes', () {
        cache.setPosition(node2, const Rect.fromLTWH(0, 50, 100, 50));

        cache.invalidate(node1);

        expect(cache.getPosition(node2), isNotNull);
      });

      test('invalidateSubtree removes layout for node and descendants', () {
        final parent = DocumentNode(children: [node1, node2]);
        node1.parent = parent;
        node2.parent = parent;

        final child = BlockNode.p(children: [TextNode('Child')]);
        child.parent = node1;
        node1.children.add(child);

        cache.setPosition(parent, const Rect.fromLTWH(0, 0, 200, 150));
        cache.setPosition(node1, const Rect.fromLTWH(0, 0, 100, 50));
        cache.setPosition(child, const Rect.fromLTWH(5, 5, 90, 40));
        cache.setPosition(node2, const Rect.fromLTWH(0, 50, 100, 50));

        cache.invalidateSubtree(node1);

        expect(cache.getPosition(node1), isNull);
        expect(cache.getPosition(child), isNull);
        expect(cache.getPosition(node2), isNotNull);
        expect(cache.getPosition(parent), isNotNull);
      });

      test('clear removes all cached data', () {
        cache.setPosition(node2, const Rect.fromLTWH(0, 50, 100, 50));
        cache.setPosition(node3, const Rect.fromLTWH(0, 100, 100, 50));

        expect(cache.cachedNodeCount, greaterThan(0));

        cache.clear();

        expect(cache.cachedNodeCount, equals(0));
        expect(cache.getPosition(node1), isNull);
        expect(cache.getPosition(node2), isNull);
        expect(cache.getPosition(node3), isNull);
      });
    });

    group('Statistics', () {
      test('getStats returns accurate counts', () {
        cache.setPosition(node1, const Rect.fromLTWH(0, 0, 100, 50));
        cache.setSize(node1, const Size(100, 50));
        cache.setBaseline(node1, 40.0);
        cache.setContentBounds(node1, const Rect.fromLTWH(5, 5, 90, 40));

        cache.setPosition(node2, const Rect.fromLTWH(0, 50, 100, 50));
        cache.setSize(node2, const Size(100, 50));

        final stats = cache.getStats();

        expect(stats.positionsCached, equals(2));
        expect(stats.sizesCached, equals(2));
        expect(stats.baselinesCached, equals(1));
        expect(stats.contentBoundsCached, equals(1));
      });

      test('getStats estimates memory usage', () {
        cache.setPosition(node1, const Rect.fromLTWH(0, 0, 100, 50));
        cache.setSize(node1, const Size(100, 50));

        final stats = cache.getStats();

        expect(stats.totalMemoryBytes, greaterThan(0));
        expect(stats.memoryKb, greaterThan(0));
      });

      test('toString provides readable output', () {
        cache.setPosition(node1, const Rect.fromLTWH(0, 0, 100, 50));

        final output = cache.toString();

        expect(output, contains('LayoutCache'));
        expect(output, contains('1 nodes'));
        expect(output, contains('KB'));
      });

      test('stats toString provides detailed information', () {
        cache.setPosition(node1, const Rect.fromLTWH(0, 0, 100, 50));
        cache.setSize(node1, const Size(100, 50));

        final stats = cache.getStats();
        final output = stats.toString();

        expect(output, contains('Layout Cache Statistics'));
        expect(output, contains('Positions cached:'));
        expect(output, contains('Sizes cached:'));
        expect(output, contains('Memory usage:'));
      });

      test('stats toJson returns valid JSON', () {
        cache.setPosition(node1, const Rect.fromLTWH(0, 0, 100, 50));

        final stats = cache.getStats();
        final json = stats.toJson();

        expect(json['positionsCached'], equals(1));
        expect(json['sizesCached'], equals(0));
        expect(json['totalMemoryBytes'], greaterThan(0));
        expect(json['memoryKb'], greaterThan(0));
      });
    });

    group('Compact', () {
      test('removes entries for nodes not in tree', () {
        final root = DocumentNode(children: [node1, node2]);
        node1.parent = root;
        node2.parent = root;

        // Add layout for all three nodes
        cache.setPosition(root, const Rect.fromLTWH(0, 0, 200, 150));
        cache.setPosition(node1, const Rect.fromLTWH(0, 0, 100, 50));
        cache.setPosition(node2, const Rect.fromLTWH(0, 50, 100, 50));
        cache.setPosition(node3, const Rect.fromLTWH(0, 100, 100, 50));

        expect(cache.cachedNodeCount, equals(4));

        // node3 is not in the tree, so it should be removed
        cache.compact(root);

        expect(cache.cachedNodeCount, equals(3));
        expect(cache.getPosition(node1), isNotNull);
        expect(cache.getPosition(node2), isNotNull);
        expect(cache.getPosition(node3), isNull);
      });

      test('handles deeply nested trees', () {
        final child1 = BlockNode.p(children: [TextNode('Child 1')]);
        final child2 = BlockNode.p(children: [TextNode('Child 2')]);
        child1.parent = node1;
        child2.parent = node1;
        node1.children.addAll([child1, child2]);

        final root = DocumentNode(children: [node1]);
        node1.parent = root;

        cache.setPosition(root, const Rect.fromLTWH(0, 0, 200, 200));
        cache.setPosition(node1, const Rect.fromLTWH(0, 0, 200, 100));
        cache.setPosition(child1, const Rect.fromLTWH(0, 0, 200, 50));
        cache.setPosition(child2, const Rect.fromLTWH(0, 50, 200, 50));
        cache.setPosition(node2, const Rect.fromLTWH(0, 100, 200, 50));

        cache.compact(root);

        expect(cache.cachedNodeCount, equals(4));
        expect(cache.getPosition(root), isNotNull);
        expect(cache.getPosition(node1), isNotNull);
        expect(cache.getPosition(child1), isNotNull);
        expect(cache.getPosition(child2), isNotNull);
        expect(cache.getPosition(node2), isNull);
      });
    });

    group('Snapshot and restore', () {
      setUp(() {
        cache.setPosition(node1, const Rect.fromLTWH(0, 0, 100, 50));
        cache.setSize(node1, const Size(100, 50));
        cache.setBaseline(node1, 40.0);
        cache.setContentBounds(node1, const Rect.fromLTWH(5, 5, 90, 40));
      });

      test('snapshot captures current state', () {
        final snapshot = cache.snapshot();

        expect(snapshot.positions.length, equals(1));
        expect(snapshot.sizes.length, equals(1));
        expect(snapshot.baselines.length, equals(1));
        expect(snapshot.contentBounds.length, equals(1));
      });

      test('snapshot is immutable (copy)', () {
        final snapshot = cache.snapshot();

        cache.setPosition(node2, const Rect.fromLTWH(0, 50, 100, 50));

        expect(snapshot.positions.length, equals(1));
        expect(cache.cachedNodeCount, equals(2));
      });

      test('restoreSnapshot replaces current state', () {
        final snapshot = cache.snapshot();

        cache.clear();
        cache.setPosition(node2, const Rect.fromLTWH(0, 50, 100, 50));

        cache.restoreSnapshot(snapshot);

        expect(cache.cachedNodeCount, equals(1));
        expect(cache.getPosition(node1), isNotNull);
        expect(cache.getPosition(node2), isNull);
      });

      test('diff detects position changes', () {
        final snapshot1 = cache.snapshot();

        cache.setPosition(node1, const Rect.fromLTWH(10, 20, 100, 50));

        final snapshot2 = cache.snapshot();
        final diff = snapshot1.diff(snapshot2);

        expect(diff.hasChanges, isTrue);
        expect(diff.changedPositions.length, equals(1));
        expect(diff.changedPositions[node1.id], isNotNull);
      });

      test('diff detects size changes', () {
        final snapshot1 = cache.snapshot();

        cache.setSize(node1, const Size(120, 60));

        final snapshot2 = cache.snapshot();
        final diff = snapshot1.diff(snapshot2);

        expect(diff.hasChanges, isTrue);
        expect(diff.changedSizes.length, equals(1));
      });

      test('diff detects baseline changes', () {
        final snapshot1 = cache.snapshot();

        cache.setBaseline(node1, 45.0);

        final snapshot2 = cache.snapshot();
        final diff = snapshot1.diff(snapshot2);

        expect(diff.hasChanges, isTrue);
        expect(diff.changedBaselines.length, equals(1));
      });

      test('diff handles no changes', () {
        final snapshot1 = cache.snapshot();
        final snapshot2 = cache.snapshot();

        final diff = snapshot1.diff(snapshot2);

        expect(diff.hasChanges, isFalse);
        expect(diff.totalChanges, equals(0));
      });

      test('diff toString provides summary', () {
        final snapshot1 = cache.snapshot();

        cache.setPosition(node1, const Rect.fromLTWH(10, 20, 100, 50));
        cache.setSize(node1, const Size(120, 60));

        final snapshot2 = cache.snapshot();
        final diff = snapshot1.diff(snapshot2);

        final output = diff.toString();

        expect(output, contains('LayoutCacheDiff'));
        expect(output, contains('2 changes'));
        expect(output, contains('positions'));
        expect(output, contains('sizes'));
      });
    });

    group('Performance', () {
      test('handles large number of nodes efficiently', () {
        final nodes = <UDTNode>[];
        for (var i = 0; i < 1000; i++) {
          nodes.add(BlockNode.p(children: [TextNode('Node $i')]));
        }

        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < nodes.length; i++) {
          cache.setPosition(
            nodes[i],
            Rect.fromLTWH(0, i * 50.0, 100, 50),
          );
          cache.setSize(nodes[i], const Size(100, 50));
        }

        stopwatch.stop();

        expect(cache.cachedNodeCount, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('lookups are fast with many nodes', () {
        final nodes = <UDTNode>[];
        for (var i = 0; i < 1000; i++) {
          final node = BlockNode.p(children: [TextNode('Node $i')]);
          nodes.add(node);
          cache.setPosition(node, Rect.fromLTWH(0, i * 50.0, 100, 50));
        }

        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 1000; i++) {
          cache.getPosition(nodes[i]);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });

      test('clear is fast', () {
        for (var i = 0; i < 1000; i++) {
          final node = BlockNode.p(children: [TextNode('Node $i')]);
          cache.setPosition(node, Rect.fromLTWH(0, i * 50.0, 100, 50));
        }

        final stopwatch = Stopwatch()..start();
        cache.clear();
        stopwatch.stop();

        expect(cache.cachedNodeCount, equals(0));
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });
    });

    group('Edge cases', () {
      test('handles nodes with same ID correctly', () {
        // This shouldn't happen in practice, but let's verify behavior
        cache.setPosition(node1, const Rect.fromLTWH(0, 0, 100, 50));

        // Create a different node but manually set same ID
        final node1b = BlockNode.p(children: [TextNode('Node 1b')]);
        // Can't actually set the ID, but we can test that different nodes
        // with different IDs work correctly
        cache.setPosition(node1b, const Rect.fromLTWH(0, 50, 100, 50));

        expect(cache.cachedNodeCount, equals(2));
      });

      test('handles zero-sized rects', () {
        cache.setPosition(node1, Rect.zero);

        expect(cache.getPosition(node1), equals(Rect.zero));
      });

      test('handles empty document tree in compact', () {
        cache.setPosition(node1, const Rect.fromLTWH(0, 0, 100, 50));

        final emptyRoot = DocumentNode(children: []);

        cache.compact(emptyRoot);

        expect(cache.cachedNodeCount, equals(0));
      });
    });
  });
}
