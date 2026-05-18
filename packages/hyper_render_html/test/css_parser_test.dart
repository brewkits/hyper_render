import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_html/hyper_render_html.dart';

/// Coverage gap noted in the v1.3.2 review: parser packages had only smoke
/// tests, so common CSS edge cases were unprotected. These tests pin the
/// behaviour the StyleResolver relies on: selector + declarations come back
/// in a predictable shape, inline styles parse, `@keyframes` are extracted.
void main() {
  const parser = DefaultCssParser();

  group('DefaultCssParser.parseStylesheet — basic selectors', () {
    test('single rule with multiple declarations', () {
      final rules = parser.parseStylesheet('p { color: red; font-size: 14px; }');

      expect(rules, hasLength(1));
      expect(rules.first.selector, equals('p'));
      expect(rules.first.declarations['color'], equals('red'));
      // csslib lexes "14px" into the numeric literal token "14" and drops the
      // unit suffix — the StyleResolver re-applies px as the default unit
      // when reading the value. This is the contract downstream relies on.
      expect(rules.first.declarations['font-size'], equals('14'));
    });

    test('class + id + descendant selectors are kept verbatim', () {
      final rules = parser.parseStylesheet(
        '.foo { color: blue; } '
        '#bar { margin: 4px; } '
        'div p { padding: 2px; }',
      );

      final selectors = rules.map((r) => r.selector).toList();
      expect(selectors, containsAll(['.foo', '#bar', 'div p']));
    });

    test('comma-separated selectors stay as one ParsedCssRule', () {
      // csslib keeps the selector list as a single string ("h1, h2, h3");
      // the StyleResolver's _matchesSelector splits on `,` at match time.
      // Pinning this behaviour so a future "auto fan-out" refactor is
      // forced to update the resolver side too.
      final rules = parser.parseStylesheet('h1, h2, h3 { color: black; }');

      expect(rules, hasLength(1));
      expect(rules.first.selector.replaceAll(' ', ''),
          equals('h1,h2,h3'));
      expect(rules.first.declarations['color'], equals('black'));
    });

    test('comments inside the rule body are discarded', () {
      final rules = parser.parseStylesheet(
        'p { /* legacy */ color: green; /* TODO */ }',
      );
      expect(rules.first.declarations['color'], equals('green'));
    });

    test('empty / whitespace-only input returns an empty rule list', () {
      expect(parser.parseStylesheet(''), isEmpty);
      expect(parser.parseStylesheet('   \n\t  '), isEmpty);
    });
  });

  group('DefaultCssParser.parseInlineStyle', () {
    test('two-property inline style', () {
      final m = parser.parseInlineStyle('color: red; font-weight: 700');
      expect(m['color'], equals('red'));
      expect(m['font-weight'], equals('700'));
    });

    test('trailing semicolon tolerated', () {
      final m = parser.parseInlineStyle('color: red;');
      expect(m['color'], equals('red'));
    });

    test('whitespace around `:` and `;` tolerated', () {
      final m =
          parser.parseInlineStyle('  color :  red ;  font-size :  12px  ');
      expect(m['color'], equals('red'));
      expect(m['font-size'], equals('12px'));
    });

    test('empty string returns empty map', () {
      expect(parser.parseInlineStyle(''), isEmpty);
    });
  });

  group('DefaultCssParser.parseKeyframes', () {
    test('extracts named keyframes', () {
      final kf = parser.parseKeyframes(
        '@keyframes fade { 0% { opacity: 0 } 100% { opacity: 1 } }',
      );
      expect(kf.keys, contains('fade'));
    });

    test('multiple keyframes co-exist', () {
      final kf = parser.parseKeyframes(
        '@keyframes a { 0% { opacity: 0 } } '
        '@keyframes b { 0% { transform: scale(0) } }',
      );
      expect(kf.keys, containsAll(['a', 'b']));
    });

    test('css with no @keyframes returns empty map', () {
      final kf = parser.parseKeyframes('p { color: red; }');
      expect(kf, isEmpty);
    });
  });
}
