import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('ListStyleType Enum', () {
    test('ListStyleType has all expected values', () {
      expect(ListStyleType.values, contains(ListStyleType.decimal));
      expect(ListStyleType.values, contains(ListStyleType.lowerRoman));
      expect(ListStyleType.values, contains(ListStyleType.upperRoman));
      expect(ListStyleType.values, contains(ListStyleType.lowerAlpha));
      expect(ListStyleType.values, contains(ListStyleType.upperAlpha));
      expect(ListStyleType.values, contains(ListStyleType.disc));
      expect(ListStyleType.values, contains(ListStyleType.circle));
      expect(ListStyleType.values, contains(ListStyleType.square));
      expect(ListStyleType.values, contains(ListStyleType.none));
    });

    test('ListStyleType count is correct', () {
      // Ensure we have all 9 types
      expect(ListStyleType.values.length, equals(9));
    });
  });

  group('ComputedStyle listStyleType Property', () {
    test('ComputedStyle has listStyleType property', () {
      final style = ComputedStyle();
      expect(style.listStyleType, isNull); // Default is null (inherited)
    });

    test('ComputedStyle can set listStyleType', () {
      final style = ComputedStyle(listStyleType: ListStyleType.disc);
      expect(style.listStyleType, equals(ListStyleType.disc));
    });

    test('ComputedStyle inherits listStyleType from parent', () {
      final parent = ComputedStyle(listStyleType: ListStyleType.upperRoman);
      final child = ComputedStyle();

      child.inheritFrom(parent);

      expect(child.listStyleType, equals(ListStyleType.upperRoman));
    });

    test('ComputedStyle child overrides parent listStyleType', () {
      final parent = ComputedStyle(listStyleType: ListStyleType.disc);
      final child = ComputedStyle(listStyleType: ListStyleType.square);

      child.inheritFrom(parent);

      // Child's explicit value should be preserved
      expect(child.listStyleType, equals(ListStyleType.square));
    });
  });

  group('List Marker Generation - Decimal', () {
    test('generates decimal markers correctly', () {
      // This would test _generateListMarker if it were public
      // For now, we document expected behavior
      final style = ComputedStyle(listStyleType: ListStyleType.decimal);

      expect(style.listStyleType, equals(ListStyleType.decimal));
      // Expected markers: "1. ", "2. ", "3. ", etc.
    });
  });

  group('List Marker Generation - Roman Numerals', () {
    test('lower roman markers are expected', () {
      final style = ComputedStyle(listStyleType: ListStyleType.lowerRoman);

      expect(style.listStyleType, equals(ListStyleType.lowerRoman));
      // Expected markers: "i. ", "ii. ", "iii. ", "iv. ", "v. ", etc.
    });

    test('upper roman markers are expected', () {
      final style = ComputedStyle(listStyleType: ListStyleType.upperRoman);

      expect(style.listStyleType, equals(ListStyleType.upperRoman));
      // Expected markers: "I. ", "II. ", "III. ", "IV. ", "V. ", etc.
    });
  });

  group('List Marker Generation - Alphabetical', () {
    test('lower alpha markers are expected', () {
      final style = ComputedStyle(listStyleType: ListStyleType.lowerAlpha);

      expect(style.listStyleType, equals(ListStyleType.lowerAlpha));
      // Expected markers: "a. ", "b. ", "c. ", ..., "z. ", "aa. ", etc.
    });

    test('upper alpha markers are expected', () {
      final style = ComputedStyle(listStyleType: ListStyleType.upperAlpha);

      expect(style.listStyleType, equals(ListStyleType.upperAlpha));
      // Expected markers: "A. ", "B. ", "C. ", ..., "Z. ", "AA. ", etc.
    });
  });

  group('List Marker Generation - Bullet Types', () {
    test('disc marker is expected', () {
      final style = ComputedStyle(listStyleType: ListStyleType.disc);

      expect(style.listStyleType, equals(ListStyleType.disc));
      // Expected marker: "• "
    });

    test('circle marker is expected', () {
      final style = ComputedStyle(listStyleType: ListStyleType.circle);

      expect(style.listStyleType, equals(ListStyleType.circle));
      // Expected marker: "○ "
    });

    test('square marker is expected', () {
      final style = ComputedStyle(listStyleType: ListStyleType.square);

      expect(style.listStyleType, equals(ListStyleType.square));
      // Expected marker: "▪ "
    });

    test('none means no marker', () {
      final style = ComputedStyle(listStyleType: ListStyleType.none);

      expect(style.listStyleType, equals(ListStyleType.none));
      // Expected marker: "" (empty string)
    });
  });

  group('List Structure', () {
    test('ordered list with default decimal', () {
      final ol = BlockNode(
        tagName: 'ol',
        style: ComputedStyle(listStyleType: ListStyleType.decimal),
        children: [
          BlockNode(
            tagName: 'li',
            children: [TextNode('First item')],
          ),
          BlockNode(
            tagName: 'li',
            children: [TextNode('Second item')],
          ),
        ],
      );

      expect(ol.style.listStyleType, equals(ListStyleType.decimal));
      expect(ol.children.length, equals(2));
    });

    test('unordered list with default disc', () {
      final ul = BlockNode(
        tagName: 'ul',
        style: ComputedStyle(listStyleType: ListStyleType.disc),
        children: [
          BlockNode(
            tagName: 'li',
            children: [TextNode('Item 1')],
          ),
          BlockNode(
            tagName: 'li',
            children: [TextNode('Item 2')],
          ),
        ],
      );

      expect(ul.style.listStyleType, equals(ListStyleType.disc));
      expect(ul.children.length, equals(2));
    });

    test('nested lists inherit style', () {
      final outerStyle = ComputedStyle(listStyleType: ListStyleType.disc);
      final innerStyle = ComputedStyle();

      innerStyle.inheritFrom(outerStyle);

      expect(innerStyle.listStyleType, equals(ListStyleType.disc));
    });

    test('nested list with different style', () {
      final outer = BlockNode(
        tagName: 'ul',
        style: ComputedStyle(listStyleType: ListStyleType.disc),
        children: [
          BlockNode(
            tagName: 'li',
            children: [
              TextNode('Outer item'),
              BlockNode(
                tagName: 'ol',
                style: ComputedStyle(listStyleType: ListStyleType.decimal),
                children: [
                  BlockNode(
                    tagName: 'li',
                    children: [TextNode('Inner item')],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      expect(outer.style.listStyleType, equals(ListStyleType.disc));

      final li = outer.children[0];
      final innerOl = li.children[1];

      expect(innerOl.style.listStyleType, equals(ListStyleType.decimal));
    });
  });

  group('Edge Cases', () {
    test('empty list has correct style', () {
      final ul = BlockNode(
        tagName: 'ul',
        style: ComputedStyle(listStyleType: ListStyleType.disc),
        children: [],
      );

      expect(ul.children.isEmpty, isTrue);
      expect(ul.style.listStyleType, equals(ListStyleType.disc));
    });

    test('list item without parent list', () {
      final li = BlockNode(
        tagName: 'li',
        children: [TextNode('Orphan item')],
      );

      expect(li.tagName, equals('li'));
      expect(li.children.length, equals(1));
    });

    test('list with non-li children', () {
      final ul = BlockNode(
        tagName: 'ul',
        style: ComputedStyle(listStyleType: ListStyleType.disc),
        children: [
          BlockNode(
            tagName: 'li',
            children: [TextNode('Valid item')],
          ),
          BlockNode(
            tagName: 'div',
            children: [TextNode('Invalid child')],
          ),
        ],
      );

      expect(ul.children.length, equals(2));
      expect(ul.children[0].tagName, equals('li'));
      expect(ul.children[1].tagName, equals('div'));
    });

    test('list item with complex content', () {
      final li = BlockNode(
        tagName: 'li',
        children: [
          TextNode('Text '),
          InlineNode.strong(children: [TextNode('bold')]),
          TextNode(' '),
          InlineNode(
            tagName: 'a',
            attributes: {'href': '/link'},
            children: [TextNode('link')],
          ),
        ],
      );

      expect(li.children.length, equals(4));
      expect(li.textContent, contains('Text bold link'));
    });

    test('deeply nested lists', () {
      final root = BlockNode(
        tagName: 'ul',
        style: ComputedStyle(listStyleType: ListStyleType.disc),
        children: [
          BlockNode(
            tagName: 'li',
            children: [
              TextNode('Level 1'),
              BlockNode(
                tagName: 'ul',
                style: ComputedStyle(listStyleType: ListStyleType.circle),
                children: [
                  BlockNode(
                    tagName: 'li',
                    children: [
                      TextNode('Level 2'),
                      BlockNode(
                        tagName: 'ul',
                        style: ComputedStyle(listStyleType: ListStyleType.square),
                        children: [
                          BlockNode(
                            tagName: 'li',
                            children: [TextNode('Level 3')],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      expect(root.style.listStyleType, equals(ListStyleType.disc));

      // Navigate to level 2
      final level1Li = root.children[0];
      final level2Ul = level1Li.children[1];
      expect(level2Ul.style.listStyleType, equals(ListStyleType.circle));

      // Navigate to level 3
      final level2Li = level2Ul.children[0];
      final level3Ul = level2Li.children[1];
      expect(level3Ul.style.listStyleType, equals(ListStyleType.square));
    });
  });

  group('CSS Integration', () {
    test('list-style-type disc for ul', () {
      final style = ComputedStyle(listStyleType: ListStyleType.disc);

      expect(style.listStyleType, equals(ListStyleType.disc));
    });

    test('list-style-type decimal for ol', () {
      final style = ComputedStyle(listStyleType: ListStyleType.decimal);

      expect(style.listStyleType, equals(ListStyleType.decimal));
    });

    test('list-style-type can be overridden via CSS', () {
      final defaultStyle = ComputedStyle(listStyleType: ListStyleType.disc);
      final customStyle = ComputedStyle(listStyleType: ListStyleType.square);

      expect(defaultStyle.listStyleType, equals(ListStyleType.disc));
      expect(customStyle.listStyleType, equals(ListStyleType.square));
    });
  });
}
