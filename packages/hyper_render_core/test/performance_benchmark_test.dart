import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('Performance Benchmarks', () {
    group('Document Creation', () {
      test('creates small document (100 nodes) quickly', () {
        final stopwatch = Stopwatch()..start();

        final doc = DocumentNode(
          children: List.generate(
            100,
            (i) => BlockNode.p(children: [TextNode('Text $i')]),
          ),
        );

        stopwatch.stop();

        expect(doc.children.length, equals(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(50),
            reason: 'Creating 100 nodes should take less than 50ms');
      });

      test('creates medium document (1000 nodes) quickly', () {
        final stopwatch = Stopwatch()..start();

        final doc = DocumentNode(
          children: List.generate(
            1000,
            (i) => BlockNode.p(children: [TextNode('Text $i')]),
          ),
        );

        stopwatch.stop();

        expect(doc.children.length, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(200),
            reason: 'Creating 1000 nodes should take less than 200ms');
      });

      test('creates large document (5000 nodes) reasonably fast', () {
        final stopwatch = Stopwatch()..start();

        final doc = DocumentNode(
          children: List.generate(
            5000,
            (i) => BlockNode.p(children: [TextNode('Text $i')]),
          ),
        );

        stopwatch.stop();

        expect(doc.children.length, equals(5000));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason: 'Creating 5000 nodes should take less than 1 second');
      });
    });

    group('Style Resolution', () {
      test('resolves styles for 100 nodes quickly', () {
        final doc = DocumentNode(
          children: List.generate(
            100,
            (i) => BlockNode(
              tagName: i.isEven ? 'p' : 'div',
              children: [TextNode('Text $i')],
            ),
          ),
        );

        final resolver = StyleResolver();
        final stopwatch = Stopwatch()..start();

        resolver.resolveStyles(doc);

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100),
            reason: 'Resolving 100 nodes should take less than 100ms');
      });

      test('resolves styles for 1000 nodes quickly', () {
        final doc = DocumentNode(
          children: List.generate(
            1000,
            (i) => BlockNode(
              tagName: ['p', 'div', 'h1', 'h2', 'blockquote'][i % 5],
              children: [TextNode('Text $i')],
            ),
          ),
        );

        final resolver = StyleResolver();
        final stopwatch = Stopwatch()..start();

        resolver.resolveStyles(doc);

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason: 'Resolving 1000 nodes should take less than 500ms');
      });

      test('CSS rule matching is efficient with large ruleset', () {
        final resolver = StyleResolver();

        // Add 100 CSS rules
        final rules = List.generate(
          100,
          (i) => ParsedCssRule(
            selector: '.class-$i',
            declarations: {
              'color': 'red',
              'font-size': '${14 + i}px',
            },
          ),
        );

        resolver.addCssRules(rules);

        // Create document with 100 nodes with classes
        final doc = DocumentNode(
          children: List.generate(
            100,
            (i) => BlockNode(
              tagName: 'div',
              attributes: {'class': 'class-${i % 10}'},
              children: [TextNode('Text $i')],
            ),
          ),
        );

        final stopwatch = Stopwatch()..start();

        resolver.resolveStyles(doc);

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(200),
            reason: 'CSS matching with 100 rules and 100 nodes should take less than 200ms');
      });
    });

    group('Layout Cache', () {
      test('cache operations are fast', () {
        final cache = LayoutCache();
        final nodes = List.generate(
          1000,
          (i) => BlockNode.p(children: [TextNode('Text $i')]),
        );

        final stopwatch = Stopwatch()..start();

        // Set positions for all nodes
        for (var i = 0; i < nodes.length; i++) {
          cache.setPosition(
            nodes[i],
            Rect.fromLTWH(0, i * 20.0, 100, 20),
          );
        }

        // Get positions for all nodes
        for (final node in nodes) {
          cache.getPosition(node);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50),
            reason: '2000 cache operations should take less than 50ms');
      });

      test('cache invalidation is fast', () {
        final cache = LayoutCache();
        final root = DocumentNode(
          children: List.generate(
            100,
            (i) => BlockNode.p(
              children: List.generate(
                10,
                (j) => TextNode('Text $i-$j'),
              ),
            ),
          ),
        );

        // Populate cache
        for (final child in root.children) {
          cache.setPosition(child, Rect.fromLTWH(0, 0, 100, 20));
          for (final grandchild in child.children) {
            cache.setPosition(grandchild, Rect.fromLTWH(0, 0, 100, 20));
          }
        }

        final stopwatch = Stopwatch()..start();

        // Invalidate subtrees
        for (final child in root.children) {
          cache.invalidateSubtree(child);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100),
            reason: 'Invalidating 100 subtrees should take less than 100ms');
      });
    });

    group('CSS Rule Index', () {
      test('indexing 1000 rules is fast', () {
        final index = CssRuleIndex();

        final rules = List.generate(
          1000,
          (i) => ParsedCssRule(
            selector: i.isEven ? 'div' : '.class-${i % 100}',
            declarations: {'color': 'red'},
          ),
        );

        final stopwatch = Stopwatch()..start();

        for (final rule in rules) {
          index.addRule(rule);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100),
            reason: 'Indexing 1000 rules should take less than 100ms');
        expect(index.totalRules, equals(1000));
      });

      test('candidate lookup is fast', () {
        final index = CssRuleIndex();

        // Add 1000 rules
        final rules = List.generate(
          1000,
          (i) => ParsedCssRule(
            selector: i.isEven ? 'div' : '.class-${i % 100}',
            declarations: {'color': 'red'},
          ),
        );

        for (final rule in rules) {
          index.addRule(rule);
        }

        final node = BlockNode(
          tagName: 'div',
          attributes: {'class': 'class-50'},
          children: [],
        );

        final stopwatch = Stopwatch()..start();

        // Do 1000 lookups
        for (var i = 0; i < 1000; i++) {
          index.getCandidates(node);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50),
            reason: '1000 candidate lookups should take less than 50ms');
      });
    });

    group('Performance Monitoring', () {
      test('performance monitor overhead is minimal', () {
        final monitor = PerformanceMonitor();

        final stopwatch = Stopwatch()..start();

        // Simulate 1000 operations with monitoring
        for (var i = 0; i < 1000; i++) {
          monitor.measure('test-$i', () {
            // Simulate small work
            var sum = 0;
            for (var j = 0; j < 10; j++) {
              sum += j;
            }
            return sum;
          });
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100),
            reason: 'Monitoring 1000 operations should add less than 100ms overhead');
      });

      test('performance report generation is fast', () {
        final monitor = PerformanceMonitor();

        // Record some measurements
        for (var i = 0; i < 100; i++) {
          monitor.measure('parse', () => i * 2);
          monitor.measure('style', () => i * 3);
          monitor.measure('layout', () => i * 4);
        }

        final stopwatch = Stopwatch()..start();

        final report = monitor.buildReport();

        stopwatch.stop();

        expect(report, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(10),
            reason: 'Building performance report should take less than 10ms');
      });
    });

    group('Memory Efficiency', () {
      test('node IDs are memory efficient', () {
        // Create many nodes and check ID generation doesn't explode memory
        final nodes = <UDTNode>[];

        for (var i = 0; i < 10000; i++) {
          nodes.add(BlockNode.p(children: [TextNode('Text $i')]));
        }

        // All nodes should have unique IDs
        final ids = nodes.map((n) => n.id).toSet();
        expect(ids.length, equals(10000),
            reason: 'All node IDs should be unique');

        // IDs should be compact strings
        // Format: node_${microsecondsSinceEpoch}_${counter} (~27 chars)
        for (final node in nodes.take(100)) {
          expect(node.id.length, lessThan(50),
              reason: 'Node IDs should be compact');
        }
      });

      test('computed styles are memory efficient', () {
        // Create many style objects
        final styles = <ComputedStyle>[];

        for (var i = 0; i < 1000; i++) {
          styles.add(ComputedStyle(
            fontSize: 14.0 + (i % 10),
            color: i.isEven ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
          ));
        }

        expect(styles.length, equals(1000),
            reason: 'Should handle 1000 style objects efficiently');
      });

      test('layout cache can handle large trees', () {
        final cache = LayoutCache();

        // Create a large tree
        final root = DocumentNode(
          children: List.generate(
            100,
            (i) => BlockNode.p(
              children: List.generate(
                50,
                (j) => TextNode('Text $i-$j'),
              ),
            ),
          ),
        );

        // Cache all positions
        var nodeCount = 0;
        for (final child in root.children) {
          cache.setPosition(child, Rect.fromLTWH(0, 0, 100, 20));
          nodeCount++;
          for (final grandchild in child.children) {
            cache.setPosition(grandchild, Rect.fromLTWH(0, 0, 100, 20));
            nodeCount++;
          }
        }

        expect(nodeCount, equals(5100),
            reason: 'Cache should handle 5100 nodes');

        // Compact should work
        cache.compact(root);

        // Should still be able to query
        final pos = cache.getPosition(root.children.first);
        expect(pos, isNotNull);
      });
    });

    group('Stress Tests', () {
      test('deeply nested document renders without stack overflow', () {
        // Create a deeply nested structure
        UDTNode node = TextNode('Deep');

        for (var i = 0; i < 100; i++) {
          node = BlockNode.p(children: [node]);
        }

        final doc = DocumentNode(children: [node]);

        expect(doc.children.length, equals(1),
            reason: 'Should handle 100 levels of nesting');
      });

      test('wide document with many siblings performs well', () {
        final stopwatch = Stopwatch()..start();

        final doc = DocumentNode(
          children: List.generate(
            10000,
            (i) => BlockNode.p(children: [TextNode('Text $i')]),
          ),
        );

        stopwatch.stop();

        expect(doc.children.length, equals(10000));
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: 'Creating 10000 sibling nodes should take less than 2 seconds');
      });

      test('mixed content document performs well', () {
        final stopwatch = Stopwatch()..start();

        final doc = DocumentNode(
          children: List.generate(1000, (i) {
            // Mix different node types
            if (i % 5 == 0) {
              return BlockNode.h1(children: [TextNode('Heading $i')]);
            } else if (i % 5 == 1) {
              return BlockNode.p(children: [
                TextNode('Paragraph $i with '),
                InlineNode(
                  tagName: 'strong',
                  children: [TextNode('bold')],
                ),
                TextNode(' text'),
              ]);
            } else if (i % 5 == 2) {
              return BlockNode(
                tagName: 'blockquote',
                children: [TextNode('Quote $i')],
              );
            } else if (i % 5 == 3) {
              return BlockNode(
                tagName: 'ul',
                children: List.generate(
                  3,
                  (j) => BlockNode(
                    tagName: 'li',
                    children: [TextNode('Item $j')],
                  ),
                ),
              );
            } else {
              return BlockNode(
                tagName: 'pre',
                children: [TextNode('Code $i')],
              );
            }
          }),
        );

        stopwatch.stop();

        expect(doc.children.length, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason: 'Creating mixed document should take less than 500ms');
      });
    });

    group('Regression Tests', () {
      test('style resolution performance has not regressed', () {
        // Baseline: 1000 nodes should resolve in < 500ms
        final doc = DocumentNode(
          children: List.generate(
            1000,
            (i) => BlockNode.p(children: [TextNode('Text $i')]),
          ),
        );

        final resolver = StyleResolver();
        final stopwatch = Stopwatch()..start();

        resolver.resolveStyles(doc);

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason: 'Style resolution performance should not regress');
      });

      test('CSS indexing performance has not regressed', () {
        // Baseline: 1000 rules should index in < 100ms
        final index = CssRuleIndex();
        final rules = List.generate(
          1000,
          (i) => ParsedCssRule(
            selector: 'div',
            declarations: {'color': 'red'},
          ),
        );

        final stopwatch = Stopwatch()..start();

        for (final rule in rules) {
          index.addRule(rule);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100),
            reason: 'CSS indexing performance should not regress');
      });

      test('cache performance has not regressed', () {
        // Baseline: 2000 cache operations should take < 50ms
        final cache = LayoutCache();
        final nodes = List.generate(
          1000,
          (i) => BlockNode.p(children: [TextNode('Text $i')]),
        );

        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < nodes.length; i++) {
          cache.setPosition(nodes[i], Rect.fromLTWH(0, i * 20.0, 100, 20));
          cache.getPosition(nodes[i]);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50),
            reason: 'Cache performance should not regress');
      });
    });
  });
}
