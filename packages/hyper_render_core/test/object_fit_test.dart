import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('CSS object-fit tests', () {
    test('StyleResolver parses valid object-fit values', () {
      final validValues = ['cover', 'contain', 'fill', 'none', 'scale-down'];
      final resolver = StyleResolver();

      for (final value in validValues) {
        final doc = DocumentNode(children: [
          InlineNode(
            tagName: 'img',
            attributes: {'style': 'object-fit: $value'},
            children: [],
          ),
        ]);

        resolver.resolveStyles(doc);

        final img = doc.children[0];
        expect(img.style.objectFit, equals(value));
        expect(img.style.isExplicitlySet('object-fit'), isTrue);
      }
    });

    test('StyleResolver ignores invalid object-fit values', () {
      final resolver = StyleResolver();
      final doc = DocumentNode(children: [
        InlineNode(
          tagName: 'img',
          attributes: {'style': 'object-fit: invalid-value'},
          children: [],
        ),
      ]);

      resolver.resolveStyles(doc);

      final img = doc.children[0];
      expect(img.style.objectFit, isNull);
      expect(img.style.isExplicitlySet('object-fit'), isFalse);
    });

    test('ComputedStyle.copyWith retains object-fit', () {
      final style = ComputedStyle(objectFit: 'cover');
      final copied = style.copyWith(color: const Color(0xFF000000));

      expect(copied.objectFit, equals('cover'));
      expect(copied.color, equals(const Color(0xFF000000)));
    });
  });
}
