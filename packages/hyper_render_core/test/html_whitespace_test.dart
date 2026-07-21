import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('isCssWhitespaceOnly / cssWhitespaceRun', () {
    final nbsp = String.fromCharCode(0x00A0);

    test('recognizes real CSS whitespace as whitespace-only', () {
      expect(isCssWhitespaceOnly('   '), isTrue);
      expect(isCssWhitespaceOnly('\t\n\r\f'), isTrue);
      expect(isCssWhitespaceOnly(''), isTrue);
    });

    test('&nbsp; (U+00A0) is NOT whitespace-only, unlike String.trim()', () {
      // Sanity-check the premise this helper exists to fix: Dart's built-in
      // trim() DOES treat U+00A0 as trimmable, which is wrong per CSS.
      expect(nbsp.trim().isEmpty, isTrue);
      expect(isCssWhitespaceOnly(nbsp), isFalse);
    });

    test('mixed nbsp + real whitespace is not whitespace-only', () {
      expect(isCssWhitespaceOnly('  $nbsp  '), isFalse);
      expect(isCssWhitespaceOnly('  text'), isFalse);
    });

    test('cssWhitespaceRun collapses runs of real whitespace to one space', () {
      expect('a   b'.replaceAll(cssWhitespaceRun, ' '), 'a b');
      expect('a\n\n\tb'.replaceAll(cssWhitespaceRun, ' '), 'a b');
    });

    test('cssWhitespaceRun does not match &nbsp;', () {
      final input = 'a${nbsp}b';
      expect(input.replaceAll(cssWhitespaceRun, ' '), input);
    });
  });
}
