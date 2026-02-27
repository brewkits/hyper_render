import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('CSS Indexing Performance', () {
    test('benchmark: indexed lookup vs linear search with 500 rules', () {
      // Create 500 CSS rules
      final rules = <ParsedCssRule>[];
      for (var i = 0; i < 100; i++) {
        rules.add(ParsedCssRule(selector: 'div$i', declarations: {'color': 'red'}));
        rules.add(ParsedCssRule(selector: 'p$i', declarations: {'color': 'blue'}));
        rules.add(ParsedCssRule(selector: '.class$i', declarations: {'padding': '10px'}));
        rules.add(ParsedCssRule(selector: '#id$i', declarations: {'margin': '5px'}));
        rules.add(ParsedCssRule(selector: 'span$i a$i', declarations: {'text-decoration': 'none'}));
      }

      // Build index
      final index = CssRuleIndex();
      for (final rule in rules) {
        index.addRule(rule);
      }

      // Create test node
      final node = BlockNode(
        tagName: 'div',
        attributes: {
          'class': 'button primary',
          'id': 'submit',
        },
        children: [],
      );

      print('\nTesting with ${rules.length} CSS rules');
      print('Node: <div class="button primary" id="submit">');

      // Benchmark: Linear search (old approach)
      final linearStopwatch = Stopwatch()..start();
      var linearMatches = 0;

      for (var i = 0; i < 1000; i++) {
        for (final rule in rules) {
          // Simulate checking if selector might match
          // (In real code, this would call _matchesSelector)
          if (rule.selector.contains('div') ||
              rule.selector.contains('button') ||
              rule.selector.contains('primary') ||
              rule.selector.contains('submit') ||
              rule.selector.contains('*')) {
            linearMatches++;
          }
        }
      }

      linearStopwatch.stop();

      // Benchmark: Indexed lookup (new approach)
      final indexedStopwatch = Stopwatch()..start();
      var indexedCandidates = 0;

      for (var i = 0; i < 1000; i++) {
        final candidates = index.getCandidates(node);
        indexedCandidates += candidates.length;
      }

      indexedStopwatch.stop();

      print('\nResults (1000 iterations):');
      print('  Linear search: ${linearStopwatch.elapsedMilliseconds}ms');
      print('  Indexed lookup: ${indexedStopwatch.elapsedMilliseconds}ms');

      final speedup = linearStopwatch.elapsedMilliseconds /
          indexedStopwatch.elapsedMilliseconds;
      print('  Speedup: ${speedup.toStringAsFixed(1)}x faster');

      print('\nCandidate reduction:');
      print('  Linear matches (1000 iters): $linearMatches');
      print('  Linear would check: ${rules.length} rules per node');
      print('  Indexed checks: ${(indexedCandidates / 1000).toStringAsFixed(1)} rules per node');
      print('  Reduction: ${(100 * (1 - indexedCandidates / 1000 / rules.length)).toStringAsFixed(1)}%');

      // Indexed should be significantly faster
      expect(indexedStopwatch.elapsedMilliseconds,
          lessThan(linearStopwatch.elapsedMilliseconds));

      // Should reduce candidate set significantly
      expect(indexedCandidates / 1000, lessThan(rules.length * 0.5));
    });

    test('benchmark: real-world scenario with 1000 rules and 100 nodes', () {
      // Create realistic CSS rules
      final rules = <ParsedCssRule>[];

      // Common resets and base styles
      rules.add(ParsedCssRule(selector: '*', declarations: {'box-sizing': 'border-box'}));
      rules.add(ParsedCssRule(selector: 'body', declarations: {'margin': '0'}));
      rules.add(ParsedCssRule(selector: 'html', declarations: {'font-size': '16px'}));

      // Typography
      for (var i = 1; i <= 6; i++) {
        rules.add(ParsedCssRule(selector: 'h$i', declarations: {'font-weight': 'bold'}));
      }
      rules.add(ParsedCssRule(selector: 'p', declarations: {'margin': '1em 0'}));
      rules.add(ParsedCssRule(selector: 'a', declarations: {'color': 'blue'}));
      rules.add(ParsedCssRule(selector: 'strong', declarations: {'font-weight': 'bold'}));
      rules.add(ParsedCssRule(selector: 'em', declarations: {'font-style': 'italic'}));

      // Common components (200 rules)
      for (var i = 0; i < 50; i++) {
        rules.add(ParsedCssRule(selector: '.btn$i', declarations: {'padding': '10px'}));
        rules.add(ParsedCssRule(selector: '.card$i', declarations: {'border': '1px solid'}));
        rules.add(ParsedCssRule(selector: '.container$i', declarations: {'width': '100%'}));
        rules.add(ParsedCssRule(selector: '#section$i', declarations: {'margin': '20px'}));
      }

      // Complex selectors (200 rules)
      for (var i = 0; i < 50; i++) {
        rules.add(ParsedCssRule(selector: 'div p', declarations: {'line-height': '1.5'}));
        rules.add(ParsedCssRule(selector: '.card > h2', declarations: {'margin-top': '0'}));
        rules.add(ParsedCssRule(selector: 'p + p', declarations: {'margin-top': '0.5em'}));
        rules.add(ParsedCssRule(selector: 'a:hover', declarations: {'text-decoration': 'underline'}));
      }

      // More specific rules (until we reach 1000)
      while (rules.length < 1000) {
        final i = rules.length;
        if (i % 4 == 0) {
          rules.add(ParsedCssRule(selector: 'div$i', declarations: {'display': 'block'}));
        } else if (i % 4 == 1) {
          rules.add(ParsedCssRule(selector: '.style$i', declarations: {'color': 'black'}));
        } else if (i % 4 == 2) {
          rules.add(ParsedCssRule(selector: '#elem$i', declarations: {'position': 'relative'}));
        } else {
          rules.add(ParsedCssRule(selector: 'span$i a$i', declarations: {'display': 'inline'}));
        }
      }

      print('\nReal-world test: ${rules.length} CSS rules');

      // Build index
      final indexBuildStopwatch = Stopwatch()..start();
      final index = CssRuleIndex();
      for (final rule in rules) {
        index.addRule(rule);
      }
      indexBuildStopwatch.stop();

      print('Index build time: ${indexBuildStopwatch.elapsedMilliseconds}ms');

      final stats = index.getStats();
      print('Index statistics:');
      print('  Tag rules: ${stats.tagRules}');
      print('  Class rules: ${stats.classRules}');
      print('  ID rules: ${stats.idRules}');
      print('  Universal rules: ${stats.universalRules}');

      // Create 100 realistic nodes
      final nodes = <UDTNode>[
        BlockNode(tagName: 'div', children: []),
        BlockNode(tagName: 'p', children: []),
        BlockNode(tagName: 'h1', children: []),
        BlockNode(tagName: 'span', children: []),
        BlockNode(
          tagName: 'button',
          attributes: {'class': 'btn'},
          children: [],
        ),
        BlockNode(
          tagName: 'div',
          attributes: {'class': 'card'},
          children: [],
        ),
        BlockNode(
          tagName: 'div',
          attributes: {'class': 'container'},
          children: [],
        ),
        BlockNode(
          tagName: 'section',
          attributes: {'id': 'main'},
          children: [],
        ),
      ];

      // Replicate to 100 nodes
      while (nodes.length < 100) {
        nodes.add(nodes[nodes.length % 8]);
      }

      // Benchmark indexed lookup
      final indexedStopwatch = Stopwatch()..start();
      var totalCandidates = 0;

      for (final node in nodes) {
        final candidates = index.getCandidates(node);
        totalCandidates += candidates.length;
      }

      indexedStopwatch.stop();

      print('\nProcessing 100 nodes:');
      print('  Time: ${indexedStopwatch.elapsedMilliseconds}ms');
      print('  Average candidates per node: ${(totalCandidates / nodes.length).toStringAsFixed(1)}');
      print('  Reduction: ${(100 * (1 - totalCandidates / nodes.length / rules.length)).toStringAsFixed(1)}%');

      // Should process 100 nodes very quickly
      expect(indexedStopwatch.elapsedMilliseconds, lessThan(50));

      // Average candidates should be much less than total rules
      expect(totalCandidates / nodes.length, lessThan(rules.length * 0.3));
    });

    test('memory efficiency: index overhead is acceptable', () {
      final rules = <ParsedCssRule>[];

      // Create 1000 rules
      for (var i = 0; i < 1000; i++) {
        if (i % 3 == 0) {
          rules.add(ParsedCssRule(selector: 'div$i', declarations: {}));
        } else if (i % 3 == 1) {
          rules.add(ParsedCssRule(selector: '.class$i', declarations: {}));
        } else {
          rules.add(ParsedCssRule(selector: '#id$i', declarations: {}));
        }
      }

      // Build index
      final index = CssRuleIndex();
      for (final rule in rules) {
        index.addRule(rule);
      }

      // Verify all rules are indexed
      expect(index.totalRules, equals(1000));

      final stats = index.getStats();
      print('\nMemory efficiency with 1000 rules:');
      print('  Tag buckets: ${stats.tagRules}');
      print('  Class buckets: ${stats.classRules}');
      print('  ID buckets: ${stats.idRules}');
      print('  Universal: ${stats.universalRules}');
      print('  Total indexed: ${stats.totalRules}');

      // All rules should be accounted for
      expect(stats.totalRules, equals(rules.length));
    });

    test('index rebuild performance', () {
      final rules = <ParsedCssRule>[];
      for (var i = 0; i < 500; i++) {
        rules.add(ParsedCssRule(selector: 'div$i', declarations: {}));
      }

      final index = CssRuleIndex();

      // Benchmark rebuild
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 10; i++) {
        index.clear();
        for (final rule in rules) {
          index.addRule(rule);
        }
      }

      stopwatch.stop();

      print('\n10 rebuilds with 500 rules: ${stopwatch.elapsedMilliseconds}ms');
      print('Average rebuild time: ${(stopwatch.elapsedMilliseconds / 10).toStringAsFixed(1)}ms');

      // Should rebuild quickly
      expect(stopwatch.elapsedMilliseconds / 10, lessThan(10));
    });
  });
}
