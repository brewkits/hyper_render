/// Integration example showing how to use PerformanceMonitor in production
///
/// This file demonstrates best practices for performance monitoring in HyperRender
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('Performance Monitoring Examples', () {
    test('Example 1: Basic monitoring', () {
      // Create a performance monitor
      final monitor = PerformanceMonitor();

      // Start monitoring
      monitor.start(label: 'render-document');

      // Simulate document parsing
      monitor.startPhase('parse');
      final document = DocumentNode(children: [
        BlockNode.p(children: [TextNode('Hello World')]),
        BlockNode.p(children: [TextNode('This is a test')]),
      ]);
      monitor.endPhase('parse');

      // Record metrics (count nodes manually or estimate)
      var nodeCount = 1; // Document node
      void countNodes(UDTNode node) {
        nodeCount++;
        for (final child in node.children) {
          countNodes(child);
        }
      }
      for (final child in document.children) {
        countNodes(child);
      }
      monitor.recordNodeCount(nodeCount);

      // Build report
      final report = monitor.buildReport();

      print('\n--- Example 1: Basic Monitoring ---');
      print(report);

      expect(report.nodeCount, greaterThan(0));
      expect(report.label, equals('render-document'));
    });

    test('Example 2: Tracking CSS performance', () async {
      final monitor = PerformanceMonitor();
      monitor.start(label: 'css-resolution');

      // Simulate CSS rule processing
      final cssRules = <ParsedCssRule>[];
      for (var i = 0; i < 100; i++) {
        cssRules.add(ParsedCssRule(
          selector: i % 2 == 0 ? '.class$i' : 'div$i',
          declarations: {'color': 'red'},
        ));
      }

      monitor.startPhase('style');

      // Simulate CSS matching
      var matchedRules = 0;
      for (final rule in cssRules) {
        // Simulate matching logic
        if (rule.selector.startsWith('.')) {
          matchedRules++;
        }
        await Future.delayed(Duration.zero);
      }

      monitor.endPhase('style');

      // Record CSS stats
      monitor.recordCssStats(
        ruleCount: cssRules.length,
        rulesMatched: matchedRules,
      );

      final report = monitor.buildReport();

      print('\n--- Example 2: CSS Performance ---');
      print(report);
      print('CSS Matching Efficiency: ${report.cssMatchingEfficiency.toStringAsFixed(1)}%');

      expect(report.cssRuleCount, equals(100));
      expect(report.cssRulesMatched, equals(50));
      expect(report.cssMatchingEfficiency, equals(50.0));
    });

    test('Example 3: Aggregating multiple reports with PerformanceStats', () async {
      final stats = PerformanceStats();

      // Simulate multiple render cycles
      for (var i = 0; i < 10; i++) {
        final monitor = PerformanceMonitor();
        monitor.start(label: 'render-cycle-$i');

        // Simulate varying workloads
        await monitor.measureAsync('parse', () async {
          await Future.delayed(Duration(milliseconds: 5 + i));
        });

        await monitor.measureAsync('layout', () async {
          await Future.delayed(Duration(milliseconds: 3 + i ~/ 2));
        });

        monitor.recordNodeCount(50 + i * 10);

        final report = monitor.buildReport();
        stats.addReport(report);
      }

      print('\n--- Example 3: Aggregate Statistics ---');
      print(stats);

      expect(stats.reportCount, equals(10));
      expect(stats.averageTotalTimeMs, greaterThan(0));
      expect(stats.p95TotalTimeMs, greaterThan(stats.averageTotalTimeMs));
    });

    test('Example 4: Conditional monitoring (disabled in production)', () async {
      // In production, you might want to disable monitoring for performance
      final monitor = PerformanceMonitor(enabled: false);

      monitor.start();

      await monitor.measureAsync('parse', () async {
        // This won't be tracked
        await Future.delayed(const Duration(milliseconds: 10));
      });

      final report = monitor.buildReport();

      print('\n--- Example 4: Disabled Monitoring ---');
      print('Monitoring disabled, report shows zero times');
      print('Total time: ${report.totalTimeMs}ms');

      expect(report.totalTime, equals(Duration.zero));
    });

    test('Example 5: Memory tracking', () {
      final monitor = PerformanceMonitor();
      monitor.start(label: 'memory-test');

      // Create document
      final children = <UDTNode>[];
      for (var i = 0; i < 100; i++) {
        children.add(
          BlockNode.p(children: [
            TextNode('This is paragraph $i with some text content'),
          ]),
        );
      }
      final document = DocumentNode(children: children);

      // Count nodes
      var nodeCount = 1; // Document node
      void countNodes(UDTNode node) {
        nodeCount++;
        for (final child in node.children) {
          countNodes(child);
        }
      }
      for (final child in document.children) {
        countNodes(child);
      }

      // Estimate memory usage (rough approximation)
      final estimatedBytesPerNode = 200; // Rough estimate
      final totalBytes = nodeCount * estimatedBytesPerNode;

      monitor.recordNodeCount(nodeCount);
      monitor.recordMemoryUsage(totalBytes);

      final report = monitor.buildReport();

      print('\n--- Example 5: Memory Tracking ---');
      print('Nodes: ${report.nodeCount}');
      print('Estimated memory: ${report.memoryUsageKb.toStringAsFixed(1)}KB');
      print('Per node: ${(report.memoryUsageBytes / report.nodeCount).toStringAsFixed(0)} bytes');

      expect(report.memoryUsageKb, greaterThan(0));
    });

    test('Example 6: Performance rating and alerts', () async {
      final monitor = PerformanceMonitor();

      // Test different performance levels
      final testCases = [
        ('excellent', 10),
        ('good', 40),
        ('acceptable', 90),
        ('slow', 150),
        ('poor', 600),
      ];

      print('\n--- Example 6: Performance Ratings ---');

      for (final testCase in testCases) {
        final (label, delayMs) = testCase;

        monitor.start(label: label);
        await Future.delayed(Duration(milliseconds: delayMs));
        final report = monitor.buildReport();

        print('$label (${report.totalTimeMs}ms): '
            '${report.rating} [score: ${report.performanceScore}]');

        // Alert on poor performance
        if (!report.isAcceptable) {
          print('  ⚠️ WARNING: Performance below acceptable threshold!');
        }

        monitor.reset();
      }
    });

    test('Example 7: JSON export for analytics', () {
      final monitor = PerformanceMonitor();
      monitor.start(label: 'analytics-test');

      monitor.measure('parse', () {
        // Simulate work
        for (var i = 0; i < 1000; i++) {
          // ignore: unused_local_variable
          final x = i * 2;
        }
      });

      monitor.recordNodeCount(100);
      monitor.recordCssStats(ruleCount: 50, rulesMatched: 25);

      final report = monitor.buildReport();
      final json = report.toJson();

      print('\n--- Example 7: JSON Export ---');
      print('JSON for analytics: $json');

      expect(json['totalTimeMs'], isNotNull);
      expect(json['nodeCount'], equals(100));
      expect(json['rating'], isNotNull);
      expect(json['performanceScore'], isNotNull);
    });

    test('Example 8: Real-world workflow', () async {
      // Complete workflow simulating actual usage
      final monitor = PerformanceMonitor();
      final stats = PerformanceStats(maxReports: 50);

      print('\n--- Example 8: Real-World Workflow ---');

      // Simulate user scrolling through a feed with 5 documents
      for (var docIndex = 0; docIndex < 5; docIndex++) {
        monitor.start(label: 'document-$docIndex');

        // 1. Parse HTML/Markdown
        final parseResult = await monitor.measureAsync('parse', () async {
          await Future.delayed(const Duration(milliseconds: 8));
          return DocumentNode(children: [
            BlockNode.h1(children: [TextNode('Document $docIndex')]),
            BlockNode.p(children: [TextNode('Content here...')]),
          ]);
        });

        // 2. Resolve CSS
        await monitor.measureAsync('style', () async {
          await Future.delayed(const Duration(milliseconds: 5));
        });

        // 3. Layout
        await monitor.measureAsync('layout', () async {
          await Future.delayed(const Duration(milliseconds: 12));
        });

        // 4. Paint
        await monitor.measureAsync('paint', () async {
          await Future.delayed(const Duration(milliseconds: 3));
        });

        // Record metrics (count nodes)
        var nodeCount = 1;
        void countNodes(UDTNode node) {
          nodeCount++;
          for (final child in node.children) {
            countNodes(child);
          }
        }
        for (final child in parseResult.children) {
          countNodes(child);
        }
        monitor.recordNodeCount(nodeCount);
        monitor.recordCssStats(ruleCount: 100, rulesMatched: 30);
        monitor.recordMemoryUsage(1024 * 50); // 50KB

        final report = monitor.buildReport();
        stats.addReport(report);

        print('Document $docIndex: ${report.totalTimeMs}ms [${report.rating}]');

        monitor.reset();
      }

      print('\nAggregate Statistics:');
      print('  Average render time: ${stats.averageTotalTimeMs.toStringAsFixed(1)}ms');
      print('  P95: ${stats.p95TotalTimeMs}ms');
      print('  P99: ${stats.p99TotalTimeMs}ms');
      print('  Average memory: ${stats.averageMemoryKb.toStringAsFixed(1)}KB');

      expect(stats.reportCount, equals(5));
      expect(stats.averageTotalTimeMs, greaterThan(0));
    });

    test('Example 9: Using measure() for convenience', () {
      final monitor = PerformanceMonitor();
      monitor.start();

      // measure() automatically wraps timing
      final result = monitor.measure('complex-operation', () {
        var sum = 0;
        for (var i = 0; i < 10000; i++) {
          sum += i;
        }
        return sum;
      });

      final report = monitor.buildReport();

      print('\n--- Example 9: Convenience Methods ---');
      print('Operation result: $result');
      print('Time taken: ${report.totalTimeMs}ms');

      expect(result, greaterThan(0));
      expect(report.totalTime.inMicroseconds, greaterThan(0));
    });

    test('Example 10: Comparing performance before/after optimization', () async {
      final beforeStats = PerformanceStats();
      final afterStats = PerformanceStats();

      print('\n--- Example 10: Performance Comparison ---');

      // BEFORE optimization (slow CSS matching)
      print('BEFORE optimization:');
      for (var i = 0; i < 5; i++) {
        final monitor = PerformanceMonitor();
        monitor.start(label: 'before-$i');

        await monitor.measureAsync('style', () async {
          // Simulate O(n*m) CSS matching
          await Future.delayed(const Duration(milliseconds: 50));
        });

        monitor.recordCssStats(ruleCount: 500, rulesMatched: 100);

        final report = monitor.buildReport();
        beforeStats.addReport(report);
      }

      // AFTER optimization (indexed CSS matching)
      print('AFTER optimization:');
      for (var i = 0; i < 5; i++) {
        final monitor = PerformanceMonitor();
        monitor.start(label: 'after-$i');

        await monitor.measureAsync('style', () async {
          // Simulate O(n*k) indexed matching (10x faster)
          await Future.delayed(const Duration(milliseconds: 5));
        });

        monitor.recordCssStats(ruleCount: 500, rulesMatched: 100);

        final report = monitor.buildReport();
        afterStats.addReport(report);
      }

      print('Results:');
      print('  Before avg: ${beforeStats.averageStyleTimeMs.toStringAsFixed(1)}ms');
      print('  After avg: ${afterStats.averageStyleTimeMs.toStringAsFixed(1)}ms');

      final improvement =
          beforeStats.averageStyleTimeMs / afterStats.averageStyleTimeMs;
      print('  Speedup: ${improvement.toStringAsFixed(1)}x faster');

      expect(afterStats.averageStyleTimeMs,
          lessThan(beforeStats.averageStyleTimeMs));
    });
  });
}
