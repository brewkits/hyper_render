import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('PerformanceReport', () {
    test('creates report with all metrics', () {
      final report = PerformanceReport(
        parseTime: const Duration(milliseconds: 10),
        styleTime: const Duration(milliseconds: 5),
        layoutTime: const Duration(milliseconds: 15),
        paintTime: const Duration(milliseconds: 8),
        totalTime: const Duration(milliseconds: 40),
        nodeCount: 100,
        cssRuleCount: 50,
        cssRulesMatched: 25,
        memoryUsageBytes: 1024 * 100, // 100KB
        timestamp: DateTime(2026, 1, 1),
        label: 'test report',
      );

      expect(report.parseTimeMs, equals(10));
      expect(report.styleTimeMs, equals(5));
      expect(report.layoutTimeMs, equals(15));
      expect(report.paintTimeMs, equals(8));
      expect(report.totalTimeMs, equals(40));
      expect(report.nodeCount, equals(100));
      expect(report.cssRuleCount, equals(50));
      expect(report.cssRulesMatched, equals(25));
      expect(report.memoryUsageKb, equals(100.0));
      expect(report.memoryUsageMb, closeTo(0.0977, 0.001));
      expect(report.label, equals('test report'));
    });

    test('calculates CSS matching efficiency', () {
      final report = PerformanceReport(
        parseTime: Duration.zero,
        styleTime: Duration.zero,
        layoutTime: Duration.zero,
        paintTime: Duration.zero,
        totalTime: Duration.zero,
        nodeCount: 10,
        cssRuleCount: 100,
        cssRulesMatched: 25,
        memoryUsageBytes: 1024,
        timestamp: DateTime.now(),
      );

      expect(report.cssMatchingEfficiency, equals(25.0));
    });

    test('handles zero CSS rules', () {
      final report = PerformanceReport(
        parseTime: Duration.zero,
        styleTime: Duration.zero,
        layoutTime: Duration.zero,
        paintTime: Duration.zero,
        totalTime: Duration.zero,
        nodeCount: 10,
        cssRuleCount: 0,
        cssRulesMatched: 0,
        memoryUsageBytes: 1024,
        timestamp: DateTime.now(),
      );

      expect(report.cssMatchingEfficiency, equals(0.0));
    });

    group('Performance ratings', () {
      test('isExcellent for <16ms (60fps)', () {
        final report = PerformanceReport(
          parseTime: Duration.zero,
          styleTime: Duration.zero,
          layoutTime: Duration.zero,
          paintTime: Duration.zero,
          totalTime: const Duration(milliseconds: 15),
          nodeCount: 10,
          cssRuleCount: 0,
          cssRulesMatched: 0,
          memoryUsageBytes: 1024,
          timestamp: DateTime.now(),
        );

        expect(report.isExcellent, isTrue);
        expect(report.isGood, isTrue);
        expect(report.isAcceptable, isTrue);
        expect(report.rating, equals('Excellent'));
        expect(report.performanceScore, equals(100));
      });

      test('isGood for <50ms', () {
        final report = PerformanceReport(
          parseTime: Duration.zero,
          styleTime: Duration.zero,
          layoutTime: Duration.zero,
          paintTime: Duration.zero,
          totalTime: const Duration(milliseconds: 40),
          nodeCount: 10,
          cssRuleCount: 0,
          cssRulesMatched: 0,
          memoryUsageBytes: 1024,
          timestamp: DateTime.now(),
        );

        expect(report.isExcellent, isFalse);
        expect(report.isGood, isTrue);
        expect(report.isAcceptable, isTrue);
        expect(report.rating, equals('Good'));
        expect(report.performanceScore, equals(80));
      });

      test('isAcceptable for <100ms', () {
        final report = PerformanceReport(
          parseTime: Duration.zero,
          styleTime: Duration.zero,
          layoutTime: Duration.zero,
          paintTime: Duration.zero,
          totalTime: const Duration(milliseconds: 90),
          nodeCount: 10,
          cssRuleCount: 0,
          cssRulesMatched: 0,
          memoryUsageBytes: 1024,
          timestamp: DateTime.now(),
        );

        expect(report.isExcellent, isFalse);
        expect(report.isGood, isFalse);
        expect(report.isAcceptable, isTrue);
        expect(report.rating, equals('Acceptable'));
        expect(report.performanceScore, equals(60));
      });

      test('Slow for <200ms', () {
        final report = PerformanceReport(
          parseTime: Duration.zero,
          styleTime: Duration.zero,
          layoutTime: Duration.zero,
          paintTime: Duration.zero,
          totalTime: const Duration(milliseconds: 150),
          nodeCount: 10,
          cssRuleCount: 0,
          cssRulesMatched: 0,
          memoryUsageBytes: 1024,
          timestamp: DateTime.now(),
        );

        expect(report.isAcceptable, isFalse);
        expect(report.rating, equals('Slow'));
        expect(report.performanceScore, equals(40));
      });

      test('Poor for >=500ms', () {
        final report = PerformanceReport(
          parseTime: Duration.zero,
          styleTime: Duration.zero,
          layoutTime: Duration.zero,
          paintTime: Duration.zero,
          totalTime: const Duration(milliseconds: 600),
          nodeCount: 10,
          cssRuleCount: 0,
          cssRulesMatched: 0,
          memoryUsageBytes: 1024,
          timestamp: DateTime.now(),
        );

        expect(report.rating, equals('Poor'));
        expect(report.performanceScore, equals(0));
      });
    });

    test('toString() provides readable output', () {
      final report = PerformanceReport(
        parseTime: const Duration(milliseconds: 10),
        styleTime: const Duration(milliseconds: 5),
        layoutTime: const Duration(milliseconds: 15),
        paintTime: const Duration(milliseconds: 8),
        totalTime: const Duration(milliseconds: 40),
        nodeCount: 100,
        cssRuleCount: 50,
        cssRulesMatched: 25,
        memoryUsageBytes: 1024 * 100,
        timestamp: DateTime.now(),
        label: 'test',
      );

      final output = report.toString();
      expect(output, contains('Performance Report (test)'));
      expect(output, contains('Total: 40ms'));
      expect(output, contains('Parse: 10ms'));
      expect(output, contains('Style: 5ms'));
      expect(output, contains('Layout: 15ms'));
      expect(output, contains('Paint: 8ms'));
      expect(output, contains('Nodes: 100'));
      expect(output, contains('CSS Rules: 50'));
      expect(output, contains('Memory: 100.0KB'));
    });

    test('toJson() returns valid JSON', () {
      final report = PerformanceReport(
        parseTime: const Duration(milliseconds: 10),
        styleTime: const Duration(milliseconds: 5),
        layoutTime: const Duration(milliseconds: 15),
        paintTime: const Duration(milliseconds: 8),
        totalTime: const Duration(milliseconds: 40),
        nodeCount: 100,
        cssRuleCount: 50,
        cssRulesMatched: 25,
        memoryUsageBytes: 1024 * 100,
        timestamp: DateTime(2026, 1, 1, 12, 0, 0),
        label: 'test',
      );

      final json = report.toJson();
      expect(json['totalTimeMs'], equals(40));
      expect(json['parseTimeMs'], equals(10));
      expect(json['styleTimeMs'], equals(5));
      expect(json['layoutTimeMs'], equals(15));
      expect(json['paintTimeMs'], equals(8));
      expect(json['nodeCount'], equals(100));
      expect(json['cssRuleCount'], equals(50));
      expect(json['cssRulesMatched'], equals(25));
      expect(json['memoryUsageBytes'], equals(102400));
      expect(json['performanceScore'], equals(80));
      expect(json['rating'], equals('Good'));
      expect(json['label'], equals('test'));
    });
  });

  group('PerformanceMonitor', () {
    late PerformanceMonitor monitor;

    setUp(() {
      monitor = PerformanceMonitor();
    });

    test('starts and builds basic report', () {
      monitor.start(label: 'test');

      // Small delay to ensure time passes
      Future.delayed(const Duration(milliseconds: 1));

      final report = monitor.buildReport();

      expect(report.label, equals('test'));
      expect(report.totalTime.inMicroseconds, greaterThan(0));
    });

    test('tracks individual phases', () {
      monitor.start();

      monitor.startPhase('parse');
      // Simulate work
      var sum = 0;
      for (var i = 0; i < 1000; i++) {
        sum += i;
      }
      monitor.endPhase('parse');

      monitor.startPhase('layout');
      for (var i = 0; i < 500; i++) {
        sum += i;
      }
      monitor.endPhase('layout');

      final report = monitor.buildReport();

      expect(report.parseTime.inMicroseconds, greaterThan(0));
      expect(report.layoutTime.inMicroseconds, greaterThan(0));
      expect(sum, greaterThan(0)); // Use sum to avoid dead code elimination
    });

    test('measure() wraps synchronous operations', () {
      monitor.start();

      final result = monitor.measure('parse', () {
        var sum = 0;
        for (var i = 0; i < 1000; i++) {
          sum += i;
        }
        return sum;
      });

      final report = monitor.buildReport();

      expect(result, greaterThan(0));
      expect(report.parseTime.inMicroseconds, greaterThan(0));
    });

    test('measureAsync() wraps asynchronous operations', () async {
      monitor.start();

      final result = await monitor.measureAsync('parse', () async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 42;
      });

      final report = monitor.buildReport();

      expect(result, equals(42));
      expect(report.parseTime.inMilliseconds, greaterThanOrEqualTo(10));
    });

    test('recordNodeCount() stores node count', () {
      monitor.start();
      monitor.recordNodeCount(150);

      final report = monitor.buildReport();

      expect(report.nodeCount, equals(150));
    });

    test('recordCssStats() stores CSS statistics', () {
      monitor.start();
      monitor.recordCssStats(ruleCount: 200, rulesMatched: 50);

      final report = monitor.buildReport();

      expect(report.cssRuleCount, equals(200));
      expect(report.cssRulesMatched, equals(50));
    });

    test('recordMemoryUsage() stores memory usage', () {
      monitor.start();
      monitor.recordMemoryUsage(1024 * 500); // 500KB

      final report = monitor.buildReport();

      expect(report.memoryUsageBytes, equals(512000));
      expect(report.memoryUsageKb, equals(500.0));
    });

    test('reset() clears all state', () {
      monitor.start(label: 'test');
      monitor.startPhase('parse');
      monitor.endPhase('parse');
      monitor.recordNodeCount(100);

      monitor.reset();

      final report = monitor.buildReport();

      expect(report.parseTime, equals(Duration.zero));
      expect(report.nodeCount, equals(0));
      expect(report.label, isNull);
    });

    test('disabled monitor does not track', () {
      final disabledMonitor = PerformanceMonitor(enabled: false);

      disabledMonitor.start();
      disabledMonitor.startPhase('parse');
      disabledMonitor.endPhase('parse');

      final report = disabledMonitor.buildReport();

      // Should return a report with zero values
      expect(report.totalTime, equals(Duration.zero));
      expect(report.parseTime, equals(Duration.zero));
    });

    test('multiple phases tracked correctly', () {
      monitor.start();

      for (final phase in ['parse', 'style', 'layout', 'paint']) {
        monitor.startPhase(phase);
        // Simulate work
        for (var i = 0; i < 100; i++) {
          // ignore: unused_local_variable
          final x = i * 2;
        }
        monitor.endPhase(phase);
      }

      final report = monitor.buildReport();

      expect(report.parseTime.inMicroseconds, greaterThan(0));
      expect(report.styleTime.inMicroseconds, greaterThan(0));
      expect(report.layoutTime.inMicroseconds, greaterThan(0));
      expect(report.paintTime.inMicroseconds, greaterThan(0));
    });

    test('handles ending phase that was never started', () {
      monitor.start();
      monitor.endPhase('nonexistent');

      final report = monitor.buildReport();

      // Should not crash, just have zero duration
      expect(report.parseTime, equals(Duration.zero));
    });
  });

  group('PerformanceStats', () {
    late PerformanceStats stats;

    setUp(() {
      stats = PerformanceStats();
    });

    test('starts with no reports', () {
      expect(stats.reportCount, equals(0));
      expect(stats.averageTotalTimeMs, equals(0.0));
    });

    test('collects and aggregates reports', () {
      // Add 5 reports
      for (var i = 0; i < 5; i++) {
        stats.addReport(PerformanceReport(
          parseTime: Duration(milliseconds: 10 + i),
          styleTime: Duration(milliseconds: 5 + i),
          layoutTime: Duration(milliseconds: 15 + i),
          paintTime: Duration(milliseconds: 8 + i),
          totalTime: Duration(milliseconds: 40 + i * 4),
          nodeCount: 100 + i * 10,
          cssRuleCount: 50,
          cssRulesMatched: 25,
          memoryUsageBytes: 1024 * (100 + i * 10),
          timestamp: DateTime.now(),
        ));
      }

      expect(stats.reportCount, equals(5));
      expect(stats.averageTotalTimeMs, equals(48.0)); // (40+44+48+52+56)/5
      expect(stats.averageParseTimeMs, equals(12.0)); // (10+11+12+13+14)/5
      expect(stats.averageNodeCount, equals(120.0)); // (100+110+120+130+140)/5
    });

    test('calculates min/max correctly', () {
      stats.addReport(PerformanceReport(
        parseTime: Duration.zero,
        styleTime: Duration.zero,
        layoutTime: Duration.zero,
        paintTime: Duration.zero,
        totalTime: const Duration(milliseconds: 30),
        nodeCount: 100,
        cssRuleCount: 50,
        cssRulesMatched: 25,
        memoryUsageBytes: 1024,
        timestamp: DateTime.now(),
      ));

      stats.addReport(PerformanceReport(
        parseTime: Duration.zero,
        styleTime: Duration.zero,
        layoutTime: Duration.zero,
        paintTime: Duration.zero,
        totalTime: const Duration(milliseconds: 100),
        nodeCount: 100,
        cssRuleCount: 50,
        cssRulesMatched: 25,
        memoryUsageBytes: 1024,
        timestamp: DateTime.now(),
      ));

      stats.addReport(PerformanceReport(
        parseTime: Duration.zero,
        styleTime: Duration.zero,
        layoutTime: Duration.zero,
        paintTime: Duration.zero,
        totalTime: const Duration(milliseconds: 50),
        nodeCount: 100,
        cssRuleCount: 50,
        cssRulesMatched: 25,
        memoryUsageBytes: 1024,
        timestamp: DateTime.now(),
      ));

      expect(stats.minTotalTimeMs, equals(30));
      expect(stats.maxTotalTimeMs, equals(100));
    });

    test('calculates percentiles correctly', () {
      // Add 100 reports with increasing times
      for (var i = 1; i <= 100; i++) {
        stats.addReport(PerformanceReport(
          parseTime: Duration.zero,
          styleTime: Duration.zero,
          layoutTime: Duration.zero,
          paintTime: Duration.zero,
          totalTime: Duration(milliseconds: i),
          nodeCount: 100,
          cssRuleCount: 50,
          cssRulesMatched: 25,
          memoryUsageBytes: 1024,
          timestamp: DateTime.now(),
        ));
      }

      // P95 of [1..100] is 96 (95% * 100 = 95, floor(95) = 95, which is index 95 = value 96)
      expect(stats.p95TotalTimeMs, equals(96));
      expect(stats.p99TotalTimeMs, equals(100));
    });

    test('respects maxReports limit', () {
      final limitedStats = PerformanceStats(maxReports: 5);

      // Add 10 reports
      for (var i = 0; i < 10; i++) {
        limitedStats.addReport(PerformanceReport(
          parseTime: Duration.zero,
          styleTime: Duration.zero,
          layoutTime: Duration.zero,
          paintTime: Duration.zero,
          totalTime: Duration(milliseconds: i),
          nodeCount: 100,
          cssRuleCount: 50,
          cssRulesMatched: 25,
          memoryUsageBytes: 1024,
          timestamp: DateTime.now(),
        ));
      }

      // Should keep only the last 5
      expect(limitedStats.reportCount, equals(5));
    });

    test('clear() removes all reports', () {
      stats.addReport(PerformanceReport(
        parseTime: Duration.zero,
        styleTime: Duration.zero,
        layoutTime: Duration.zero,
        paintTime: Duration.zero,
        totalTime: const Duration(milliseconds: 40),
        nodeCount: 100,
        cssRuleCount: 50,
        cssRulesMatched: 25,
        memoryUsageBytes: 1024,
        timestamp: DateTime.now(),
      ));

      expect(stats.reportCount, equals(1));

      stats.clear();

      expect(stats.reportCount, equals(0));
      expect(stats.averageTotalTimeMs, equals(0.0));
    });

    test('toString() provides readable summary', () {
      stats.addReport(PerformanceReport(
        parseTime: const Duration(milliseconds: 10),
        styleTime: const Duration(milliseconds: 5),
        layoutTime: const Duration(milliseconds: 15),
        paintTime: const Duration(milliseconds: 8),
        totalTime: const Duration(milliseconds: 40),
        nodeCount: 100,
        cssRuleCount: 50,
        cssRulesMatched: 25,
        memoryUsageBytes: 1024 * 100,
        timestamp: DateTime.now(),
      ));

      final output = stats.toString();
      expect(output, contains('Performance Statistics (1 reports)'));
      expect(output, contains('Average Total:'));
      expect(output, contains('Min/Max:'));
      expect(output, contains('P95:'));
    });

    test('toJson() returns valid JSON', () {
      stats.addReport(PerformanceReport(
        parseTime: const Duration(milliseconds: 10),
        styleTime: const Duration(milliseconds: 5),
        layoutTime: const Duration(milliseconds: 15),
        paintTime: const Duration(milliseconds: 8),
        totalTime: const Duration(milliseconds: 40),
        nodeCount: 100,
        cssRuleCount: 50,
        cssRulesMatched: 25,
        memoryUsageBytes: 1024 * 100,
        timestamp: DateTime.now(),
      ));

      final json = stats.toJson();
      expect(json['reportCount'], equals(1));
      expect(json['averageTotalTimeMs'], equals(40.0));
      expect(json['minTotalTimeMs'], equals(40));
      expect(json['maxTotalTimeMs'], equals(40));
    });
  });

  group('Integration', () {
    test('full workflow with monitor and stats', () async {
      final monitor = PerformanceMonitor();
      final stats = PerformanceStats();

      // Simulate 3 render cycles
      for (var cycle = 0; cycle < 3; cycle++) {
        monitor.start(label: 'cycle $cycle');

        // Use actual async delays to ensure time passes
        await monitor.measureAsync('parse', () async {
          await Future.delayed(const Duration(milliseconds: 5));
        });

        await monitor.measureAsync('style', () async {
          await Future.delayed(const Duration(milliseconds: 3));
        });

        monitor.recordNodeCount(100 + cycle * 50);
        monitor.recordCssStats(ruleCount: 50, rulesMatched: 25);

        final report = monitor.buildReport();
        stats.addReport(report);

        monitor.reset();
      }

      expect(stats.reportCount, equals(3));
      expect(stats.averageTotalTimeMs, greaterThan(0));
      expect(stats.averageParseTimeMs, greaterThanOrEqualTo(5));
      expect(stats.averageStyleTimeMs, greaterThanOrEqualTo(3));
      expect(stats.averageNodeCount, equals(150.0)); // (100+150+200)/3
    });
  });
}
