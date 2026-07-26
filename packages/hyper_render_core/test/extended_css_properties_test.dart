import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('Extended CSS Properties Test Suite', () {
    test(
        'letter-spacing and word-spacing properties parse and inherit correctly',
        () {
      final style = ComputedStyle(
        letterSpacing: 1.5,
        wordSpacing: 3.0,
      );

      expect(style.letterSpacing, equals(1.5));
      expect(style.wordSpacing, equals(3.0));

      final child = ComputedStyle();
      child.inheritFrom(style);

      expect(child.letterSpacing, equals(1.5));
      expect(child.wordSpacing, equals(3.0));
    });

    test('word-break and overflow-wrap properties parse and resolve correctly',
        () {
      final style = ComputedStyle(
        wordBreak: 'break-all',
        overflowWrap: 'break-word',
      );

      expect(style.wordBreak, equals('break-all'));
      expect(style.overflowWrap, equals('break-word'));
    });

    test('aspect-ratio property resolves in ComputedStyle', () {
      final style = ComputedStyle(aspectRatio: 1.7777);
      expect(style.aspectRatio, closeTo(1.7777, 0.001));
    });

    test('StyleResolver correctly resolves style rules from CSS rules', () {
      final resolver = StyleResolver();
      final doc = DocumentNode(children: [
        InlineNode(
          tagName: 'p',
          attributes: {
            'style':
                'letter-spacing: 2px; word-spacing: 4px; word-break: break-word;',
          },
          children: [],
        ),
      ]);

      resolver.resolveStyles(doc);

      final p = doc.children[0];
      expect(p.style.letterSpacing, equals(2.0));
      expect(p.style.wordSpacing, equals(4.0));
      expect(p.style.wordBreak, equals('break-word'));
    });
  });
}
