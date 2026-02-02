import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('CSS Color Parsing Edge Cases', () {
    test('parses hex colors correctly', () {
      final style1 = ComputedStyle(color: const Color(0xFFFF0000));
      expect(style1.color, equals(const Color(0xFFFF0000)));

      final style2 = ComputedStyle(color: const Color(0xFF00FF00));
      expect(style2.color, equals(const Color(0xFF00FF00)));
    });

    test('handles transparent color', () {
      final style = ComputedStyle(color: Colors.transparent);
      expect(style.color, equals(Colors.transparent));
    });

    test('handles null color (inheritable)', () {
      final style = ComputedStyle();
      expect(style.color, isNull);
    });

    test('inherits color from parent', () {
      final parent = ComputedStyle(color: Colors.blue);
      final child = ComputedStyle();

      child.inheritFrom(parent);

      expect(child.color, equals(Colors.blue));
    });
  });

  group('CSS Font Size Edge Cases', () {
    test('handles zero font size', () {
      final style = ComputedStyle(fontSize: 0);
      expect(style.fontSize, equals(0));
    });

    test('handles very large font size', () {
      final style = ComputedStyle(fontSize: 999);
      expect(style.fontSize, equals(999));
    });

    test('rejects negative font size', () {
      expect(
        () => ComputedStyle(fontSize: -10),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('handles null font size (inheritable)', () {
      final style = ComputedStyle();
      expect(style.fontSize, isNull);
    });

    test('inherits font size from parent', () {
      final parent = ComputedStyle(fontSize: 20);
      final child = ComputedStyle();

      child.inheritFrom(parent);

      expect(child.fontSize, equals(20));
    });

    test('child can override parent font size', () {
      final parent = ComputedStyle(fontSize: 20);
      final child = ComputedStyle(fontSize: 16);

      child.inheritFrom(parent);

      expect(child.fontSize, equals(16));
    });
  });

  group('CSS Dimension Validation', () {
    test('rejects negative width', () {
      expect(
        () => ComputedStyle(width: -100),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative height', () {
      expect(
        () => ComputedStyle(height: -50),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative minWidth', () {
      expect(
        () => ComputedStyle(minWidth: -10),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative maxWidth', () {
      expect(
        () => ComputedStyle(maxWidth: -10),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative minHeight', () {
      expect(
        () => ComputedStyle(minHeight: -10),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative maxHeight', () {
      expect(
        () => ComputedStyle(maxHeight: -10),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts zero dimensions', () {
      final style = ComputedStyle(
        width: 0,
        height: 0,
        minWidth: 0,
        maxWidth: 0,
      );
      expect(style.width, equals(0));
      expect(style.height, equals(0));
    });

    test('accepts positive dimensions', () {
      final style = ComputedStyle(
        width: 100,
        height: 200,
        minWidth: 50,
        maxWidth: 150,
      );
      expect(style.width, equals(100));
      expect(style.height, equals(200));
    });
  });

  group('CSS Opacity Validation', () {
    test('rejects opacity less than 0', () {
      expect(
        () => ComputedStyle(opacity: -0.5),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects opacity greater than 1', () {
      expect(
        () => ComputedStyle(opacity: 1.5),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts opacity 0 (fully transparent)', () {
      final style = ComputedStyle(opacity: 0);
      expect(style.opacity, equals(0));
    });

    test('accepts opacity 1 (fully opaque)', () {
      final style = ComputedStyle(opacity: 1);
      expect(style.opacity, equals(1));
    });

    test('accepts opacity 0.5 (semi-transparent)', () {
      final style = ComputedStyle(opacity: 0.5);
      expect(style.opacity, equals(0.5));
    });
  });

  group('CSS Margin and Padding Edge Cases', () {
    test('handles all-zero margin', () {
      final style = ComputedStyle(margin: EdgeInsets.zero);
      expect(style.margin, equals(EdgeInsets.zero));
    });

    test('handles all-zero padding', () {
      final style = ComputedStyle(padding: EdgeInsets.zero);
      expect(style.padding, equals(EdgeInsets.zero));
    });

    test('handles negative margins', () {
      final style = ComputedStyle(
        margin: const EdgeInsets.only(left: -10, top: -5),
      );
      expect(style.margin.left, equals(-10));
      expect(style.margin.top, equals(-5));
    });

    test('margin does not inherit', () {
      final parent = ComputedStyle(margin: const EdgeInsets.all(10));
      final child = ComputedStyle();

      child.inheritFrom(parent);

      // Margin should NOT be inherited
      expect(child.margin, isNull);
    });

    test('padding does not inherit', () {
      final parent = ComputedStyle(padding: const EdgeInsets.all(10));
      final child = ComputedStyle();

      child.inheritFrom(parent);

      // Padding should NOT be inherited
      expect(child.padding, isNull);
    });

    test('handles asymmetric margin', () {
      final style = ComputedStyle(
        margin: const EdgeInsets.only(
          left: 5,
          right: 10,
          top: 15,
          bottom: 20,
        ),
      );

      expect(style.margin.left, equals(5));
      expect(style.margin.right, equals(10));
      expect(style.margin.top, equals(15));
      expect(style.margin.bottom, equals(20));
    });

    test('handles asymmetric padding', () {
      final style = ComputedStyle(
        padding: const EdgeInsets.only(
          left: 1,
          right: 2,
          top: 3,
          bottom: 4,
        ),
      );

      expect(style.padding.left, equals(1));
      expect(style.padding.right, equals(2));
      expect(style.padding.top, equals(3));
      expect(style.padding.bottom, equals(4));
    });
  });

  group('CSS Display Type Edge Cases', () {
    test('default display is inline', () {
      final style = ComputedStyle();
      expect(style.display, equals(DisplayType.inline));
    });

    test('handles all display types', () {
      expect(DisplayType.values, contains(DisplayType.inline));
      expect(DisplayType.values, contains(DisplayType.block));
      expect(DisplayType.values, contains(DisplayType.none));
    });

    test('display none hides element', () {
      final style = ComputedStyle(display: DisplayType.none);
      expect(style.display, equals(DisplayType.none));
    });

    test('display does not inherit', () {
      final parent = ComputedStyle(display: DisplayType.block);
      final child = ComputedStyle();

      child.inheritFrom(parent);

      // Display should use default, not inherit
      expect(child.display, equals(DisplayType.inline));
    });
  });

  group('CSS Text Decoration Edge Cases', () {
    test('handles no decoration', () {
      final style = ComputedStyle(textDecoration: TextDecoration.none);
      expect(style.textDecoration, equals(TextDecoration.none));
    });

    test('handles underline', () {
      final style = ComputedStyle(textDecoration: TextDecoration.underline);
      expect(style.textDecoration, equals(TextDecoration.underline));
    });

    test('handles lineThrough', () {
      final style = ComputedStyle(textDecoration: TextDecoration.lineThrough);
      expect(style.textDecoration, equals(TextDecoration.lineThrough));
    });

    test('handles overline', () {
      final style = ComputedStyle(textDecoration: TextDecoration.overline);
      expect(style.textDecoration, equals(TextDecoration.overline));
    });

    test('textDecoration inherits from parent', () {
      final parent = ComputedStyle(textDecoration: TextDecoration.underline);
      final child = ComputedStyle();

      child.inheritFrom(parent);

      expect(child.textDecoration, equals(TextDecoration.underline));
    });
  });

  group('CSS Font Weight Edge Cases', () {
    test('handles normal weight', () {
      final style = ComputedStyle(fontWeight: FontWeight.normal);
      expect(style.fontWeight, equals(FontWeight.normal));
    });

    test('handles bold weight', () {
      final style = ComputedStyle(fontWeight: FontWeight.bold);
      expect(style.fontWeight, equals(FontWeight.bold));
    });

    test('handles numeric weights', () {
      final style100 = ComputedStyle(fontWeight: FontWeight.w100);
      expect(style100.fontWeight, equals(FontWeight.w100));

      final style900 = ComputedStyle(fontWeight: FontWeight.w900);
      expect(style900.fontWeight, equals(FontWeight.w900));
    });

    test('fontWeight inherits from parent', () {
      final parent = ComputedStyle(fontWeight: FontWeight.bold);
      final child = ComputedStyle();

      child.inheritFrom(parent);

      expect(child.fontWeight, equals(FontWeight.bold));
    });
  });

  group('CSS Text Align Edge Cases', () {
    test('handles all text align values', () {
      final left = ComputedStyle(textAlign: HyperTextAlign.left);
      expect(left.textAlign, equals(HyperTextAlign.left));

      final right = ComputedStyle(textAlign: HyperTextAlign.right);
      expect(right.textAlign, equals(HyperTextAlign.right));

      final center = ComputedStyle(textAlign: HyperTextAlign.center);
      expect(center.textAlign, equals(HyperTextAlign.center));

      final justify = ComputedStyle(textAlign: HyperTextAlign.justify);
      expect(justify.textAlign, equals(HyperTextAlign.justify));
    });

    test('textAlign inherits from parent', () {
      final parent = ComputedStyle(textAlign: HyperTextAlign.center);
      final child = ComputedStyle();

      child.inheritFrom(parent);

      expect(child.textAlign, equals(HyperTextAlign.center));
    });
  });

  group('CSS Border Edge Cases', () {
    test('handles border properties', () {
      final style = ComputedStyle(
        borderColor: Colors.red,
        borderWidth: const EdgeInsets.all(2),
      );

      expect(style.borderColor, equals(Colors.red));
      expect(style.borderWidth, equals(const EdgeInsets.all(2)));
    });

    test('handles asymmetric border width', () {
      final style = ComputedStyle(
        borderWidth: const EdgeInsets.only(
          top: 1,
          bottom: 2,
          left: 3,
          right: 4,
        ),
      );

      expect(style.borderWidth.top, equals(1));
      expect(style.borderWidth.bottom, equals(2));
      expect(style.borderWidth.left, equals(3));
      expect(style.borderWidth.right, equals(4));
    });

    test('border does not inherit', () {
      final parent = ComputedStyle(
        borderColor: Colors.black,
        borderWidth: const EdgeInsets.all(1),
      );
      final child = ComputedStyle();

      child.inheritFrom(parent);

      expect(child.borderColor, isNull);
      expect(child.borderWidth, equals(EdgeInsets.zero)); // default value
    });
  });

  group('CSS Float Edge Cases', () {
    test('default float is none', () {
      final style = ComputedStyle();
      expect(style.float, equals(HyperFloat.none));
    });

    test('handles float left', () {
      final style = ComputedStyle(float: HyperFloat.left);
      expect(style.float, equals(HyperFloat.left));
    });

    test('handles float right', () {
      final style = ComputedStyle(float: HyperFloat.right);
      expect(style.float, equals(HyperFloat.right));
    });

    test('float does not inherit', () {
      final parent = ComputedStyle(float: HyperFloat.left);
      final child = ComputedStyle();

      child.inheritFrom(parent);

      expect(child.float, equals(HyperFloat.none));
    });
  });

  group('CSS Width and Height Edge Cases', () {
    test('handles zero width', () {
      final style = ComputedStyle(width: 0);
      expect(style.width, equals(0));
    });

    test('handles zero height', () {
      final style = ComputedStyle(height: 0);
      expect(style.height, equals(0));
    });

    test('handles very large dimensions', () {
      final style = ComputedStyle(width: 9999, height: 9999);
      expect(style.width, equals(9999));
      expect(style.height, equals(9999));
    });

    test('handles null dimensions', () {
      final style = ComputedStyle();
      expect(style.width, isNull);
      expect(style.height, isNull);
    });

    test('width and height do not inherit', () {
      final parent = ComputedStyle(width: 100, height: 200);
      final child = ComputedStyle();

      child.inheritFrom(parent);

      expect(child.width, isNull);
      expect(child.height, isNull);
    });
  });

  group('CSS Background Color Edge Cases', () {
    test('handles solid background color', () {
      final style = ComputedStyle(backgroundColor: Colors.red);
      expect(style.backgroundColor, equals(Colors.red));
    });

    test('handles transparent background', () {
      final style = ComputedStyle(backgroundColor: Colors.transparent);
      expect(style.backgroundColor, equals(Colors.transparent));
    });

    test('handles null background (no background)', () {
      final style = ComputedStyle();
      expect(style.backgroundColor, isNull);
    });

    test('backgroundColor does not inherit', () {
      final parent = ComputedStyle(backgroundColor: Colors.yellow);
      final child = ComputedStyle();

      child.inheritFrom(parent);

      expect(child.backgroundColor, isNull);
    });
  });

  group('CSS Inheritance Behavior', () {
    test('inheritable properties are inherited', () {
      final parent = ComputedStyle(
        color: Colors.blue,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        textAlign: HyperTextAlign.center,
        listStyleType: ListStyleType.disc,
      );

      final child = ComputedStyle();
      child.inheritFrom(parent);

      expect(child.color, equals(Colors.blue));
      expect(child.fontSize, equals(16));
      expect(child.fontWeight, equals(FontWeight.bold));
      expect(child.textAlign, equals(HyperTextAlign.center));
      expect(child.listStyleType, equals(ListStyleType.disc));
    });

    test('non-inheritable properties are not inherited', () {
      final parent = ComputedStyle(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(20),
        borderColor: Colors.black,
        borderWidth: const EdgeInsets.all(1),
        backgroundColor: Colors.yellow,
        width: 100,
        height: 200,
        display: DisplayType.block,
        float: HyperFloat.left,
      );

      final child = ComputedStyle();
      child.inheritFrom(parent);

      expect(child.margin, isNull);
      expect(child.padding, isNull);
      expect(child.borderColor, isNull);
      expect(child.borderWidth, equals(EdgeInsets.zero)); // default value
      expect(child.backgroundColor, isNull);
      expect(child.width, isNull);
      expect(child.height, isNull);
      expect(child.display, equals(DisplayType.inline)); // default, not inherited
      expect(child.float, equals(HyperFloat.none)); // default, not inherited
    });

    test('child explicit values override inherited values', () {
      final parent = ComputedStyle(
        color: Colors.blue,
        fontSize: 16,
      );

      final child = ComputedStyle(
        color: Colors.red,
        fontSize: 20,
      );

      child.inheritFrom(parent);

      // Child's explicit values should be preserved
      expect(child.color, equals(Colors.red));
      expect(child.fontSize, equals(20));
    });

    test('deep inheritance chain', () {
      final grandparent = ComputedStyle(color: Colors.blue, fontSize: 16);
      final parent = ComputedStyle();
      final child = ComputedStyle();

      parent.inheritFrom(grandparent);
      child.inheritFrom(parent);

      expect(child.color, equals(Colors.blue));
      expect(child.fontSize, equals(16));
    });
  });

  group('CSS toTextStyle Conversion', () {
    test('converts basic properties to TextStyle', () {
      final style = ComputedStyle(
        color: Colors.red,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      );

      final textStyle = style.toTextStyle();

      expect(textStyle.color, equals(Colors.red));
      expect(textStyle.fontSize, equals(18));
      expect(textStyle.fontWeight, equals(FontWeight.bold));
    });

    test('handles null properties in TextStyle conversion', () {
      final style = ComputedStyle();

      final textStyle = style.toTextStyle();

      // Should not throw, just create TextStyle with nulls
      expect(textStyle, isNotNull);
    });

    test('converts text decoration to TextStyle', () {
      final style = ComputedStyle(
        textDecoration: TextDecoration.underline,
      );

      final textStyle = style.toTextStyle();

      expect(textStyle.decoration, equals(TextDecoration.underline));
    });
  });
}
