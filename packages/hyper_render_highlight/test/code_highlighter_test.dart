import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_highlight/hyper_render_highlight.dart';

void main() {
  group('DefaultCodeHighlighter', () {
    const highlighter = DefaultCodeHighlighter();

    test('isLanguageSupported returns true for supported languages', () {
      expect(highlighter.isLanguageSupported('dart'), isTrue);
      expect(highlighter.isLanguageSupported('javascript'), isTrue);
      expect(highlighter.isLanguageSupported('python'), isTrue);
    });

    test('isLanguageSupported returns false for unsupported languages', () {
      expect(highlighter.isLanguageSupported('nonexistent_lang'), isFalse);
    });

    test('highlight returns TextSpans for supported language', () {
      const code = 'void main() { print("hello"); }';
      final spans = highlighter.highlight(code, 'dart');

      expect(spans, isNotEmpty);
      expect(spans.map((s) => s.toPlainText()).join(), code);
    });

    test('highlight returns TextSpans with auto-detection if language is null',
        () {
      const code = 'console.log("hello");';
      final spans = highlighter.highlight(code, null);

      expect(spans, isNotEmpty);
      expect(spans.map((s) => s.toPlainText()).join(), code);
    });

    test('supportedLanguages contains common languages', () {
      final langs = highlighter.supportedLanguages;
      expect(langs, contains('dart'));
      expect(langs, contains('html'));
      expect(langs, contains('css'));
      expect(langs, contains('plaintext'));
    });

    test('themeName returns current theme name', () {
      expect(highlighter.themeName, 'vs2015');

      const draculaHighlighter =
          DefaultCodeHighlighter(theme: HighlightTheme.dracula);
      expect(draculaHighlighter.themeName, 'dracula');
    });

    test('highlighting with different themes', () {
      const code = 'var x = 1;';

      for (final theme in HighlightTheme.values) {
        final themedHighlighter = DefaultCodeHighlighter(theme: theme);
        final spans = themedHighlighter.highlight(code, 'javascript');
        expect(spans, isNotEmpty);
        expect(spans.map((s) => s.toPlainText()).join(), code);
      }
    });

    test('highlighting with baseStyle', () {
      const code = 'var x = 1;';
      const baseStyle = TextStyle(fontSize: 20);
      const styledHighlighter = DefaultCodeHighlighter(baseStyle: baseStyle);

      final spans = styledHighlighter.highlight(code, 'javascript');
      expect(spans, isNotEmpty);
      // We check that at least some spans have the base style or merged style
      expect(spans.any((s) => s.style?.fontSize == 20), isTrue);
    });
  });
}
