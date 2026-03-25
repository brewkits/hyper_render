// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

/// Benchmark for CSS rule lookup performance
///
/// Tests the O(1) indexed lookup vs hypothetical O(n) linear search
void main() {
  test('Benchmark: CSS Rule Lookup - 100 rules', () {
    final resolver = StyleResolver();
    resolver.parseCss(_generateCss(100));

    // Benchmark lookup by tag
    final times = <int>[];
    for (int i = 0; i < 1000; i++) {
      final stopwatch = Stopwatch()..start();

      final node = BlockNode(
        tagName: 'p',
        attributes: {'class': 'highlight', 'id': 'intro'},
      );

      final document = DocumentNode(children: [node]);
      resolver.resolveStyles(document);

      stopwatch.stop();
      times.add(stopwatch.elapsedMicroseconds);
    }

    _printResults('CSS Lookup (100 rules)', times);
  });

  test('Benchmark: CSS Rule Lookup - 1000 rules', () {
    final resolver = StyleResolver();
    resolver.parseCss(_generateCss(1000));

    final times = <int>[];
    for (int i = 0; i < 1000; i++) {
      final stopwatch = Stopwatch()..start();

      final node = BlockNode(
        tagName: 'div',
        attributes: {'class': 'container content'},
      );

      final document = DocumentNode(children: [node]);
      resolver.resolveStyles(document);

      stopwatch.stop();
      times.add(stopwatch.elapsedMicroseconds);
    }

    _printResults('CSS Lookup (1000 rules)', times);
  });

  test('Benchmark: CSS Rule Lookup - 5000 rules', () {
    final resolver = StyleResolver();
    resolver.parseCss(_generateCss(5000));

    final times = <int>[];
    for (int i = 0; i < 1000; i++) {
      final stopwatch = Stopwatch()..start();

      final node = BlockNode(
        tagName: 'article',
        attributes: {'class': 'main featured', 'id': 'top-story'},
      );

      final document = DocumentNode(children: [node]);
      resolver.resolveStyles(document);

      stopwatch.stop();
      times.add(stopwatch.elapsedMicroseconds);
    }

    _printResults('CSS Lookup (5000 rules)', times);
  });

  test('Benchmark: Complex Selector Matching', () {
    final resolver = StyleResolver();

    // Add complex rules via parseCss
    resolver.parseCss('''
      div.container > p.highlight { color: red; }
      article section p { font-size: 16px; }
      #main .content { padding: 20px; }
    ''');

    final times = <int>[];
    for (int i = 0; i < 1000; i++) {
      final stopwatch = Stopwatch()..start();

      final node = BlockNode(
        tagName: 'p',
        attributes: {'class': 'highlight important'},
      );

      final document = DocumentNode(children: [node]);
      resolver.resolveStyles(document);

      stopwatch.stop();
      times.add(stopwatch.elapsedMicroseconds);
    }

    _printResults('Complex Selector Matching', times);
  });
}

String _generateCss(int count) {
  final buffer = StringBuffer();
  for (int i = 0; i < count; i++) {
    if (i % 3 == 0) {
      buffer
          .writeln('tag$i { color: #${i.toRadixString(16).padLeft(6, '0')}; }');
    } else if (i % 3 == 1) {
      buffer.writeln('.class$i { font-size: ${14 + (i % 10)}px; }');
    } else {
      buffer.writeln('#id$i { padding: ${i % 20}px; }');
    }
  }
  return buffer.toString();
}

void _printResults(String testName, List<int> times) {
  times.sort();
  final min = times.first;
  final max = times.last;
  final avg = times.reduce((a, b) => a + b) / times.length;
  final median = times[times.length ~/ 2];
  final p95 = times[(times.length * 0.95).floor()];
  final p99 = times[(times.length * 0.99).floor()];

  print('\n${'=' * 60}');
  print('$testName Results:');
  print('  Lookups: ${times.length}');
  print('  Min:     ${min.toString().padLeft(5)}μs');
  print('  Median:  ${median.toString().padLeft(5)}μs');
  print('  Avg:     ${avg.toStringAsFixed(1).padLeft(7)}μs');
  print('  P95:     ${p95.toString().padLeft(5)}μs');
  print('  P99:     ${p99.toString().padLeft(5)}μs');
  print('  Max:     ${max.toString().padLeft(5)}μs');
  print('=' * 60);
}
