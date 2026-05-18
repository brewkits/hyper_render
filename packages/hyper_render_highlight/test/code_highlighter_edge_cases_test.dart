import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_highlight/hyper_render_highlight.dart';

/// Edge cases for [DefaultCodeHighlighter] beyond the happy-path tests:
/// empty / whitespace input, unknown languages, very long blocks, syntax
/// errors. The contract is that the highlighter is total — it never throws
/// and always returns spans whose joined text equals the input.
void main() {
  const highlighter = DefaultCodeHighlighter();

  group('input edge cases', () {
    test('empty string yields spans that round-trip to empty', () {
      final spans = highlighter.highlight('', 'dart');
      expect(spans.map((s) => s.toPlainText()).join(), equals(''));
    });

    test('whitespace-only input round-trips verbatim', () {
      const code = '   \n\t  \n';
      final spans = highlighter.highlight(code, 'dart');
      expect(spans.map((s) => s.toPlainText()).join(), equals(code));
    });

    test('unknown language falls back to auto-detect, never throws', () {
      const code = 'def foo(): pass';
      expect(
        () => highlighter.highlight(code, 'this-language-doesnt-exist'),
        returnsNormally,
      );
    });

    test('malformed source still round-trips', () {
      // Unterminated string would crash a naive lexer.
      const code = 'String x = "hello;\n int y = 1;';
      final spans = highlighter.highlight(code, 'dart');
      expect(spans.map((s) => s.toPlainText()).join(), equals(code));
    });

    test('5KB block highlights without OOM / quadratic blowup', () {
      final code = StringBuffer();
      for (int i = 0; i < 200; i++) {
        code.writeln('final v$i = $i;');
      }
      final spans = highlighter.highlight(code.toString(), 'dart');
      expect(spans.map((s) => s.toPlainText()).join(), equals(code.toString()));
    });
  });

  group('language coverage sanity', () {
    test('common language identifiers all resolve', () {
      const popular = [
        'dart', 'javascript', 'typescript', 'python', 'java',
        'kotlin', 'swift', 'go', 'rust', 'cpp', 'csharp',
        'ruby', 'php', 'shell', 'json', 'xml', 'yaml',
      ];
      for (final lang in popular) {
        expect(highlighter.isLanguageSupported(lang), isTrue,
            reason: 'expected "$lang" to be supported');
      }
    });

    test('plaintext is always supported (used as fallback)', () {
      expect(highlighter.isLanguageSupported('plaintext'), isTrue);
      final spans = highlighter.highlight('any text\nat all', 'plaintext');
      expect(spans, isNotEmpty);
    });
  });

  group('theme switching', () {
    test('every HighlightTheme value resolves to a non-empty themeName', () {
      for (final t in HighlightTheme.values) {
        final h = DefaultCodeHighlighter(theme: t);
        expect(h.themeName, isNotEmpty);
      }
    });

    test('themeName is stable across calls', () {
      const h = DefaultCodeHighlighter(theme: HighlightTheme.dracula);
      expect(h.themeName, equals('dracula'));
      expect(h.themeName, equals('dracula'));
    });
  });
}
