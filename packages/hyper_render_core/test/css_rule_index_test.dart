import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('CssRuleIndex', () {
    late CssRuleIndex index;

    setUp(() {
      index = CssRuleIndex();
    });

    group('Indexing by selector type', () {
      test('indexes simple tag selectors', () {
        index.addRule(ParsedCssRule(
          selector: 'div',
          declarations: {'color': 'red'},
        ));
        index.addRule(ParsedCssRule(
          selector: 'p',
          declarations: {'color': 'blue'},
        ));

        final stats = index.getStats();
        expect(stats.tagRules, equals(2));
        expect(stats.totalRules, equals(2));
      });

      test('indexes class selectors', () {
        index.addRule(ParsedCssRule(
          selector: '.button',
          declarations: {'padding': '10px'},
        ));
        index.addRule(ParsedCssRule(
          selector: '.card',
          declarations: {'border': '1px solid'},
        ));

        final stats = index.getStats();
        expect(stats.classRules, equals(2));
        expect(stats.totalRules, equals(2));
      });

      test('indexes ID selectors', () {
        index.addRule(ParsedCssRule(
          selector: '#header',
          declarations: {'height': '60px'},
        ));
        index.addRule(ParsedCssRule(
          selector: '#footer',
          declarations: {'height': '40px'},
        ));

        final stats = index.getStats();
        expect(stats.idRules, equals(2));
        expect(stats.totalRules, equals(2));
      });

      test('indexes universal selectors', () {
        index.addRule(ParsedCssRule(
          selector: '*',
          declarations: {'box-sizing': 'border-box'},
        ));

        final stats = index.getStats();
        expect(stats.universalRules, equals(1));
        expect(stats.totalRules, equals(1));
      });

      test('indexes complex selectors as universal', () {
        index.addRule(ParsedCssRule(
          selector: 'div p',
          declarations: {'margin': '10px'},
        ));
        index.addRule(ParsedCssRule(
          selector: 'div > span',
          declarations: {'display': 'block'},
        ));
        index.addRule(ParsedCssRule(
          selector: 'p + span',
          declarations: {'margin-top': '5px'},
        ));

        final stats = index.getStats();
        expect(stats.universalRules, equals(3));
        expect(stats.totalRules, equals(3));
      });

      test('prioritizes ID over class over tag in compound selectors', () {
        index.addRule(ParsedCssRule(
          selector: 'div.button#submit',
          declarations: {'color': 'green'},
        ));

        final stats = index.getStats();
        // Should be indexed by ID (highest specificity)
        expect(stats.idRules, equals(1));
        expect(stats.classRules, equals(0));
        expect(stats.tagRules, equals(0));
      });

      test('indexes by class when no ID present', () {
        index.addRule(ParsedCssRule(
          selector: 'div.container',
          declarations: {'width': '100%'},
        ));

        final stats = index.getStats();
        expect(stats.classRules, equals(1));
        expect(stats.tagRules, equals(0));
      });

      test('indexes tag with pseudo-class', () {
        index.addRule(ParsedCssRule(
          selector: 'a:hover',
          declarations: {'color': 'blue'},
        ));
        index.addRule(ParsedCssRule(
          selector: 'p:first-child',
          declarations: {'margin-top': '0'},
        ));

        final stats = index.getStats();
        // Should index by tag name
        expect(stats.tagRules, equals(2));
      });

      test('indexes tag with attribute selector', () {
        index.addRule(ParsedCssRule(
          selector: 'input[type="text"]',
          declarations: {'border': '1px solid'},
        ));

        final stats = index.getStats();
        expect(stats.tagRules, equals(1));
      });
    });

    group('getCandidates()', () {
      setUp(() {
        // Add various rules
        index.addRule(ParsedCssRule(
          selector: 'div',
          declarations: {'display': 'block'},
        ));
        index.addRule(ParsedCssRule(
          selector: '.button',
          declarations: {'padding': '10px'},
        ));
        index.addRule(ParsedCssRule(
          selector: '#header',
          declarations: {'height': '60px'},
        ));
        index.addRule(ParsedCssRule(
          selector: '*',
          declarations: {'box-sizing': 'border-box'},
        ));
        index.addRule(ParsedCssRule(
          selector: 'div p',
          declarations: {'margin': '5px'},
        ));
      });

      test('returns tag rules for node with tag name', () {
        final node = BlockNode(tagName: 'div', children: []);
        final candidates = index.getCandidates(node);

        // Should get: div rule, universal rule, and complex selector
        expect(candidates.length, greaterThanOrEqualTo(2));
        expect(
          candidates.any((r) => r.selector == 'div'),
          isTrue,
        );
        expect(
          candidates.any((r) => r.selector == '*'),
          isTrue,
        );
      });

      test('returns class rules for node with classes', () {
        final node = BlockNode(
          tagName: 'button',
          attributes: {'class': 'button'},
          children: [],
        );
        final candidates = index.getCandidates(node);

        expect(
          candidates.any((r) => r.selector == '.button'),
          isTrue,
        );
        expect(
          candidates.any((r) => r.selector == '*'),
          isTrue,
        );
      });

      test('returns ID rules for node with ID', () {
        final node = BlockNode(
          tagName: 'header',
          attributes: {'id': 'header'},
          children: [],
        );
        final candidates = index.getCandidates(node);

        expect(
          candidates.any((r) => r.selector == '#header'),
          isTrue,
        );
        expect(
          candidates.any((r) => r.selector == '*'),
          isTrue,
        );
      });

      test('returns multiple matching rules for node with tag, class, and ID', () {
        final node = BlockNode(
          tagName: 'div',
          attributes: {
            'id': 'header',
            'class': 'button',
          },
          children: [],
        );
        final candidates = index.getCandidates(node);

        // Should get: div rule, .button rule, #header rule, universal, and complex
        expect(candidates.length, greaterThanOrEqualTo(4));
        expect(
          candidates.any((r) => r.selector == 'div'),
          isTrue,
        );
        expect(
          candidates.any((r) => r.selector == '.button'),
          isTrue,
        );
        expect(
          candidates.any((r) => r.selector == '#header'),
          isTrue,
        );
        expect(
          candidates.any((r) => r.selector == '*'),
          isTrue,
        );
      });

      test('returns only universal rules for node without tag/class/ID', () {
        final node = TextNode('Hello');
        final candidates = index.getCandidates(node);

        // Should only get universal rules
        expect(
          candidates.every((r) => r.selector == '*' || r.selector.contains(' ')),
          isTrue,
        );
      });

      test('returns rules for multiple classes', () {
        index.addRule(ParsedCssRule(
          selector: '.primary',
          declarations: {'color': 'blue'},
        ));
        index.addRule(ParsedCssRule(
          selector: '.large',
          declarations: {'font-size': '20px'},
        ));

        final node = BlockNode(
          tagName: 'button',
          attributes: {'class': 'button primary large'},
          children: [],
        );
        final candidates = index.getCandidates(node);

        expect(
          candidates.any((r) => r.selector == '.button'),
          isTrue,
        );
        expect(
          candidates.any((r) => r.selector == '.primary'),
          isTrue,
        );
        expect(
          candidates.any((r) => r.selector == '.large'),
          isTrue,
        );
      });

      test('handles case-insensitive tag names', () {
        final node = BlockNode(tagName: 'DIV', children: []);
        final candidates = index.getCandidates(node);

        // Should match 'div' rule despite uppercase
        expect(
          candidates.any((r) => r.selector == 'div'),
          isTrue,
        );
      });
    });

    group('clear()', () {
      test('removes all indexed rules', () {
        index.addRule(ParsedCssRule(
          selector: 'div',
          declarations: {'color': 'red'},
        ));
        index.addRule(ParsedCssRule(
          selector: '.button',
          declarations: {'padding': '10px'},
        ));
        index.addRule(ParsedCssRule(
          selector: '#header',
          declarations: {'height': '60px'},
        ));

        expect(index.totalRules, greaterThan(0));

        index.clear();

        final stats = index.getStats();
        expect(stats.totalRules, equals(0));
        expect(stats.tagRules, equals(0));
        expect(stats.classRules, equals(0));
        expect(stats.idRules, equals(0));
        expect(stats.universalRules, equals(0));
      });

      test('can add rules after clearing', () {
        index.addRule(ParsedCssRule(
          selector: 'div',
          declarations: {'color': 'red'},
        ));
        index.clear();

        index.addRule(ParsedCssRule(
          selector: 'p',
          declarations: {'color': 'blue'},
        ));

        expect(index.totalRules, equals(1));
      });
    });

    group('Edge cases', () {
      test('handles empty selector', () {
        index.addRule(ParsedCssRule(
          selector: '',
          declarations: {'color': 'red'},
        ));

        final stats = index.getStats();
        // Empty selector should go to universal
        expect(stats.universalRules, equals(1));
      });

      test('handles whitespace-only selector', () {
        index.addRule(ParsedCssRule(
          selector: '   ',
          declarations: {'color': 'red'},
        ));

        final stats = index.getStats();
        expect(stats.universalRules, equals(1));
      });

      test('handles selector with extra whitespace', () {
        index.addRule(ParsedCssRule(
          selector: '  div  ',
          declarations: {'color': 'red'},
        ));

        final stats = index.getStats();
        expect(stats.tagRules, equals(1));
      });

      test('handles multiple rules with same selector', () {
        index.addRule(ParsedCssRule(
          selector: 'div',
          declarations: {'color': 'red'},
        ));
        index.addRule(ParsedCssRule(
          selector: 'div',
          declarations: {'background': 'blue'},
        ));

        final node = BlockNode(tagName: 'div', children: []);
        final candidates = index.getCandidates(node);

        // Should have both div rules
        final divRules = candidates.where((r) => r.selector.trim() == 'div').toList();
        expect(divRules.length, equals(2));
      });

      test('handles special characters in class names', () {
        index.addRule(ParsedCssRule(
          selector: '.my-button',
          declarations: {'padding': '10px'},
        ));
        index.addRule(ParsedCssRule(
          selector: '.button_primary',
          declarations: {'color': 'blue'},
        ));

        final stats = index.getStats();
        expect(stats.classRules, equals(2));
      });

      test('handles special characters in ID names', () {
        index.addRule(ParsedCssRule(
          selector: '#my-header',
          declarations: {'height': '60px'},
        ));
        index.addRule(ParsedCssRule(
          selector: '#header_main',
          declarations: {'width': '100%'},
        ));

        final stats = index.getStats();
        expect(stats.idRules, equals(2));
      });
    });

    group('Statistics', () {
      test('provides accurate statistics', () {
        index.addRule(ParsedCssRule(selector: 'div', declarations: {}));
        index.addRule(ParsedCssRule(selector: 'p', declarations: {}));
        index.addRule(ParsedCssRule(selector: '.button', declarations: {}));
        index.addRule(ParsedCssRule(selector: '#header', declarations: {}));
        index.addRule(ParsedCssRule(selector: '*', declarations: {}));

        final stats = index.getStats();

        expect(stats.tagRules, equals(2));
        expect(stats.classRules, equals(1));
        expect(stats.idRules, equals(1));
        expect(stats.universalRules, equals(1));
        expect(stats.totalRules, equals(5));
      });

      test('calculates average rules per tag', () {
        index.addRule(ParsedCssRule(selector: 'div', declarations: {}));
        index.addRule(ParsedCssRule(selector: 'div', declarations: {}));
        index.addRule(ParsedCssRule(selector: 'p', declarations: {}));

        final stats = index.getStats();

        // 2 tags (div, p), 3 total tag rules -> average 1.5
        expect(stats.averageRulesPerTag, equals(1.5));
      });

      test('handles zero average when no tag rules', () {
        index.addRule(ParsedCssRule(selector: '.button', declarations: {}));
        index.addRule(ParsedCssRule(selector: '#header', declarations: {}));

        final stats = index.getStats();

        expect(stats.averageRulesPerTag, equals(0));
      });

      test('toString() provides readable output', () {
        index.addRule(ParsedCssRule(selector: 'div', declarations: {}));
        index.addRule(ParsedCssRule(selector: '.button', declarations: {}));

        final stats = index.getStats();
        final output = stats.toString();

        expect(output, contains('CSS Index Statistics'));
        expect(output, contains('Tag rules:'));
        expect(output, contains('Class rules:'));
        expect(output, contains('ID rules:'));
        expect(output, contains('Universal rules:'));
        expect(output, contains('Total rules:'));
      });
    });

    group('Performance characteristics', () {
      test('handles large number of rules efficiently', () {
        final stopwatch = Stopwatch()..start();

        // Add 1000 rules
        for (var i = 0; i < 1000; i++) {
          index.addRule(ParsedCssRule(
            selector: 'tag$i',
            declarations: {'color': 'red'},
          ));
        }

        stopwatch.stop();

        expect(index.totalRules, equals(1000));
        // Should complete quickly (< 100ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('getCandidates is fast with many rules', () {
        // Add 1000 rules
        for (var i = 0; i < 500; i++) {
          index.addRule(ParsedCssRule(selector: 'div$i', declarations: {}));
          index.addRule(ParsedCssRule(selector: '.class$i', declarations: {}));
        }

        final node = BlockNode(
          tagName: 'div',
          attributes: {'class': 'button'},
          children: [],
        );

        final stopwatch = Stopwatch()..start();

        // Get candidates 100 times
        for (var i = 0; i < 100; i++) {
          index.getCandidates(node);
        }

        stopwatch.stop();

        // Should be very fast (< 10ms for 100 calls)
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });
    });
  });
}
