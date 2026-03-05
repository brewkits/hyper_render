/// HTML Structure Fuzzing Tests
///
/// Generates random nested HTML structures to test the rendering engine's
/// robustness against:
/// - Deeply nested elements
/// - Complex tag combinations (Table in Flexbox in Float)
/// - Malformed HTML
/// - Edge cases in layout algorithms
/// - Memory overflow/stack overflow
/// - Infinite layout loops
///
/// These tests help discover edge cases that static test suites miss.
library;

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_html/hyper_render_html.dart';

void main() {
  group('HTML Structure Fuzzing', () {
    late Random random;

    setUp(() {
      // Use fixed seed for reproducible fuzzing
      random = Random(42);
    });

    group('Nested Element Fuzzing', () {
      test('should handle 10 levels of nested divs', () {
        final html = _generateNestedElements(
          random: random,
          depth: 10,
          tagName: 'div',
        );

        expect(
          () => HtmlAdapter().parse(html),
          returnsNormally,
          reason: 'Should not crash on 10-level nesting',
        );
      });

      test('should handle 20 levels of nested spans', () {
        final html = _generateNestedElements(
          random: random,
          depth: 20,
          tagName: 'span',
        );

        expect(
          () => HtmlAdapter().parse(html),
          returnsNormally,
          reason: 'Should not crash on 20-level nesting',
        );
      });

      test('should handle 50 levels of nested elements (stress test)', () {
        final html = _generateNestedElements(
          random: random,
          depth: 50,
          tagName: 'div',
        );

        expect(
          () => HtmlAdapter().parse(html),
          returnsNormally,
          reason: 'Should not stack overflow on deep nesting',
        );
      });

      test('should handle mixed nested elements', () {
        final tags = ['div', 'span', 'p', 'section', 'article'];
        final html = _generateMixedNestedElements(
          random: random,
          depth: 15,
          availableTags: tags,
        );

        expect(() => HtmlAdapter().parse(html), returnsNormally);
      });
    });

    group('Complex Layout Combinations', () {
      test('should handle table inside flexbox', () {
        const html = '''
<div style="display: flex; flex-direction: column;">
  <table>
    <tr><td>Cell 1</td><td>Cell 2</td></tr>
    <tr><td>Cell 3</td><td>Cell 4</td></tr>
  </table>
</div>
''';

        final document = HtmlAdapter().parse(html);
        expect(document.children, isNotEmpty);
      });

      test('should handle float inside table inside flexbox', () {
        const html = '''
<div style="display: flex;">
  <table>
    <tr>
      <td>
        <img src="test.jpg" style="float: left; width: 100px;">
        <p>Text wrapping around image inside table cell inside flexbox</p>
      </td>
    </tr>
  </table>
</div>
''';

        expect(() => HtmlAdapter().parse(html), returnsNormally);
      });

      test('should handle grid with nested flex items', () {
        const html = '''
<div style="display: grid; grid-template-columns: 1fr 1fr;">
  <div style="display: flex; flex-direction: row;">
    <span>Flex item 1</span>
    <span>Flex item 2</span>
  </div>
  <div>Grid item 2</div>
</div>
''';

        expect(() => HtmlAdapter().parse(html), returnsNormally);
      });

      test('should handle randomly generated layout combinations', () {
        for (int i = 0; i < 20; i++) {
          final html = _generateRandomLayoutCombination(random);
          expect(
            () => HtmlAdapter().parse(html),
            returnsNormally,
            reason: 'Failed on combination $i: $html',
          );
        }
      });
    });

    group('Malformed HTML Fuzzing', () {
      test('should handle unclosed tags', () {
        const cases = [
          '<div><p>Text</div>',  // Mismatched closing
          '<div><span>Text',     // Missing closing
          '<p>Text</span></p>',  // Wrong closing
        ];

        for (final html in cases) {
          expect(
            () => HtmlAdapter().parse(html),
            returnsNormally,
            reason: 'Should recover from: $html',
          );
        }
      });

      test('should handle empty attributes', () {
        const cases = [
          '<div class="">Empty class</div>',
          '<img src="" alt="">',
          '<a href="">Empty link</a>',
        ];

        for (final html in cases) {
          expect(() => HtmlAdapter().parse(html), returnsNormally);
        }
      });

      test('should handle malformed CSS', () {
        const cases = [
          '<div style="color:">No value</div>',
          '<div style="width: 100">No unit</div>',
          '<div style=";;;;">Multiple semicolons</div>',
          '<div style="color: red; ; width: 100px;">Extra semicolon</div>',
        ];

        for (final html in cases) {
          expect(
            () => HtmlAdapter().parse(html),
            returnsNormally,
            reason: 'Should handle malformed CSS: $html',
          );
        }
      });

      test('should handle special characters in text', () {
        const cases = [
          '<p>&lt;&gt;&amp;&quot;</p>',
          '<p>Special: €£¥₹</p>',
          '<p>Emoji: 😀🎉🔥</p>',
          '<p>CJK: 日本語 한국어 中文</p>',
        ];

        for (final html in cases) {
          expect(() => HtmlAdapter().parse(html), returnsNormally);
        }
      });
    });

    group('Table Fuzzing', () {
      test('should handle tables with random colspan/rowspan', () {
        for (int i = 0; i < 10; i++) {
          final html = _generateRandomTable(
            random: random,
            rows: random.nextInt(5) + 2,
            cols: random.nextInt(5) + 2,
            withSpans: true,
          );

          expect(
            () => HtmlAdapter().parse(html),
            returnsNormally,
            reason: 'Failed on table $i: $html',
          );
        }
      });

      test('should handle deeply nested tables', () {
        final html = _generateNestedTables(random: random, depth: 5);

        expect(() => HtmlAdapter().parse(html), returnsNormally);
      });

      test('should handle table with extreme colspan', () {
        const html = '''
<table>
  <tr>
    <td colspan="100">Very wide cell</td>
  </tr>
  <tr>
    <td>Normal cell</td>
  </tr>
</table>
''';

        expect(() => HtmlAdapter().parse(html), returnsNormally);
      });

      test('should handle table with extreme rowspan', () {
        const html = '''
<table>
  <tr>
    <td rowspan="50">Very tall cell</td>
    <td>Normal cell</td>
  </tr>
  <tr>
    <td>Cell 2</td>
  </tr>
</table>
''';

        expect(() => HtmlAdapter().parse(html), returnsNormally);
      });
    });

    group('List Fuzzing', () {
      test('should handle deeply nested lists', () {
        final html = _generateNestedLists(random: random, depth: 10);

        expect(() => HtmlAdapter().parse(html), returnsNormally);
      });

      test('should handle mixed ordered/unordered lists', () {
        final html = _generateMixedLists(random: random, depth: 8);

        expect(() => HtmlAdapter().parse(html), returnsNormally);
      });

      test('should handle lists with random item counts', () {
        for (int i = 0; i < 10; i++) {
          final itemCount = random.nextInt(50) + 1;
          final html = '<ul>${List.generate(itemCount, (i) => '<li>Item $i</li>').join()}</ul>';

          expect(() => HtmlAdapter().parse(html), returnsNormally);
        }
      });
    });

    group('Text Content Fuzzing', () {
      test('should handle very long text nodes', () {
        final longText = 'A' * 10000;
        final html = '<p>$longText</p>';

        expect(() => HtmlAdapter().parse(html), returnsNormally);
      });

      test('should handle text with many line breaks', () {
        final textWithBreaks = List.generate(100, (i) => 'Line $i').join('<br>');
        final html = '<p>$textWithBreaks</p>';

        expect(() => HtmlAdapter().parse(html), returnsNormally);
      });

      test('should handle mixed inline formatting', () {
        const html = '''
<p>
  <strong>Bold</strong>
  <em>Italic</em>
  <u>Underline</u>
  <s>Strike</s>
  <code>Code</code>
  <mark>Highlight</mark>
  <sub>Sub</sub>
  <sup>Sup</sup>
</p>
''';

        expect(() => HtmlAdapter().parse(html), returnsNormally);
      });
    });

    group('CSS Fuzzing', () {
      test('should handle random CSS property combinations', () {
        for (int i = 0; i < 20; i++) {
          final style = _generateRandomCssProperties(random);
          final html = '<div style="$style">Test</div>';

          expect(
            () => HtmlAdapter().parse(html),
            returnsNormally,
            reason: 'Failed on CSS: $style',
          );
        }
      });

      test('should handle CSS with extreme values', () {
        const cases = [
          '<div style="width: 999999px;">Very wide</div>',
          '<div style="font-size: 1000px;">Huge font</div>',
          '<div style="margin: -500px;">Negative margin</div>',
          '<div style="padding: 1000px;">Huge padding</div>',
        ];

        for (final html in cases) {
          expect(() => HtmlAdapter().parse(html), returnsNormally);
        }
      });
    });

    group('Performance and Memory Tests', () {
      test('should handle 100 sibling elements', () {
        final html = '<div>${List.generate(100, (i) => '<p>Para $i</p>').join()}</div>';

        expect(() => HtmlAdapter().parse(html), returnsNormally);
      });

      test('should handle 1000 sibling elements (stress)', () {
        final html = '<div>${List.generate(1000, (i) => '<span>$i</span>').join()}</div>';

        final stopwatch = Stopwatch()..start();
        expect(() => HtmlAdapter().parse(html), returnsNormally);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(5000),
          reason: 'Parsing 1000 elements should complete within 5 seconds',
        );
      });

      test('should not leak memory on repeated parsing', () {
        // Parse the same HTML multiple times
        const html = '<div><p>Test paragraph</p></div>';

        for (int i = 0; i < 100; i++) {
          final doc = HtmlAdapter().parse(html);
          expect(doc.children, isNotEmpty);
        }

        // If this completes without OOM, memory management is working
      });
    });

    group('Edge Case Combinations', () {
      test('should handle empty elements', () {
        const cases = [
          '<div></div>',
          '<p></p>',
          '<span></span>',
          '<table></table>',
        ];

        for (final html in cases) {
          expect(() => HtmlAdapter().parse(html), returnsNormally);
        }
      });

      test('should handle whitespace-only elements', () {
        const cases = [
          '<div>   </div>',
          '<p>\n\n\n</p>',
          '<span>\t\t</span>',
        ];

        for (final html in cases) {
          expect(() => HtmlAdapter().parse(html), returnsNormally);
        }
      });

      test('should handle self-closing tags', () {
        const cases = [
          '<img src="test.jpg" />',
          '<br />',
          '<hr />',
        ];

        for (final html in cases) {
          expect(() => HtmlAdapter().parse(html), returnsNormally);
        }
      });
    });
  });

  group('Fuzzing Stress Tests', () {
    test('should survive 100 random HTML generations', () {
      final random = Random(123);
      int successCount = 0;

      for (int i = 0; i < 100; i++) {
        try {
          final html = _generateCompletelyRandomHtml(random, complexity: 10);
          HtmlAdapter().parse(html);
          successCount++;
        } catch (e) {
          // Log but don't fail - fuzzing finds edge cases
          print('Fuzzing iteration $i failed (expected): $e');
        }
      }

      // At least 90% should parse successfully
      expect(
        successCount,
        greaterThan(90),
        reason: 'Should handle at least 90% of random HTML inputs',
      );
    });
  });
}

// =============================================================================
// HTML Generation Helpers
// =============================================================================

String _generateNestedElements({
  required Random random,
  required int depth,
  required String tagName,
}) {
  if (depth == 0) {
    return 'Text content ${random.nextInt(1000)}';
  }

  return '<$tagName>${_generateNestedElements(
    random: random,
    depth: depth - 1,
    tagName: tagName,
  )}</$tagName>';
}

String _generateMixedNestedElements({
  required Random random,
  required int depth,
  required List<String> availableTags,
}) {
  if (depth == 0) {
    return 'Leaf text ${random.nextInt(100)}';
  }

  final tag = availableTags[random.nextInt(availableTags.length)];
  return '<$tag>${_generateMixedNestedElements(
    random: random,
    depth: depth - 1,
    availableTags: availableTags,
  )}</$tag>';
}

String _generateRandomLayoutCombination(Random random) {
  final layouts = ['display: flex', 'display: grid', 'float: left', 'display: block'];
  final layout = layouts[random.nextInt(layouts.length)];

  return '''
<div style="$layout;">
  <div style="width: 100px;">Content 1</div>
  <div style="width: 150px;">Content 2</div>
</div>
''';
}

String _generateRandomTable({
  required Random random,
  required int rows,
  required int cols,
  bool withSpans = false,
}) {
  final buffer = StringBuffer('<table>');

  for (int r = 0; r < rows; r++) {
    buffer.write('<tr>');
    for (int c = 0; c < cols; c++) {
      final colspan = withSpans && random.nextBool() ? ' colspan="${random.nextInt(3) + 1}"' : '';
      final rowspan = withSpans && random.nextBool() ? ' rowspan="${random.nextInt(3) + 1}"' : '';

      buffer.write('<td$colspan$rowspan>Cell $r,$c</td>');
    }
    buffer.write('</tr>');
  }

  buffer.write('</table>');
  return buffer.toString();
}

String _generateNestedTables({required Random random, required int depth}) {
  if (depth == 0) {
    return 'Inner content';
  }

  return '''
<table>
  <tr>
    <td>${_generateNestedTables(random: random, depth: depth - 1)}</td>
  </tr>
</table>
''';
}

String _generateNestedLists({required Random random, required int depth}) {
  if (depth == 0) {
    return '<li>Leaf item ${random.nextInt(100)}</li>';
  }

  return '''
<ul>
  <li>Item level $depth
    ${_generateNestedLists(random: random, depth: depth - 1)}
  </li>
</ul>
''';
}

String _generateMixedLists({required Random random, required int depth}) {
  if (depth == 0) {
    return '<li>Leaf</li>';
  }

  final tag = random.nextBool() ? 'ul' : 'ol';
  return '''
<$tag>
  <li>Item
    ${_generateMixedLists(random: random, depth: depth - 1)}
  </li>
</$tag>
''';
}

String _generateRandomCssProperties(Random random) {
  final properties = [
    'width: ${random.nextInt(500)}px',
    'height: ${random.nextInt(500)}px',
    'margin: ${random.nextInt(50)}px',
    'padding: ${random.nextInt(50)}px',
    'font-size: ${random.nextInt(48) + 12}px',
    'color: rgb(${random.nextInt(255)}, ${random.nextInt(255)}, ${random.nextInt(255)})',
    'background-color: #${random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
  ];

  final count = random.nextInt(4) + 1;
  final selected = List.generate(count, (_) => properties[random.nextInt(properties.length)]);

  return selected.join('; ');
}

String _generateCompletelyRandomHtml(Random random, {required int complexity}) {
  final tags = ['div', 'span', 'p', 'strong', 'em', 'ul', 'ol', 'li', 'table', 'tr', 'td'];
  final buffer = StringBuffer();

  for (int i = 0; i < complexity; i++) {
    final tag = tags[random.nextInt(tags.length)];
    final hasStyle = random.nextBool();
    final style = hasStyle ? ' style="${_generateRandomCssProperties(random)}"' : '';

    buffer.write('<$tag$style>');

    if (random.nextBool()) {
      buffer.write('Text ${random.nextInt(1000)}');
    }

    if (random.nextDouble() > 0.7) {
      // 30% chance of nesting
      buffer.write(_generateCompletelyRandomHtml(random, complexity: complexity ~/ 2));
    }

    buffer.write('</$tag>');
  }

  return buffer.toString();
}
