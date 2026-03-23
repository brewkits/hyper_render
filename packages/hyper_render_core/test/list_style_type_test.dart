import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

/// Tests for list-related node structure and ComputedStyle.
///
/// Note: The codebase does not currently expose a `ListStyleType` enum or a
/// `listStyleType` property on [ComputedStyle].  These tests validate the
/// existing node-model API for building ordered/unordered list trees.
void main() {
  group('List Node Structure', () {
    test('unordered list node is a BlockNode with tagName ul', () {
      final ul = BlockNode(
        tagName: 'ul',
        children: [
          BlockNode(tagName: 'li', children: [TextNode('Item 1')]),
          BlockNode(tagName: 'li', children: [TextNode('Item 2')]),
        ],
      );

      expect(ul.tagName, equals('ul'));
      expect(ul.type, equals(NodeType.block));
      expect(ul.children.length, equals(2));
    });

    test('ordered list node is a BlockNode with tagName ol', () {
      final ol = BlockNode(
        tagName: 'ol',
        children: [
          BlockNode(tagName: 'li', children: [TextNode('First')]),
          BlockNode(tagName: 'li', children: [TextNode('Second')]),
        ],
      );

      expect(ol.tagName, equals('ol'));
      expect(ol.type, equals(NodeType.block));
      expect(ol.children.length, equals(2));
    });

    test('list item node is a BlockNode with tagName li', () {
      final li = BlockNode(
        tagName: 'li',
        children: [TextNode('List item')],
      );

      expect(li.tagName, equals('li'));
      expect(li.children.length, equals(1));
    });

    test('list item textContent returns all nested text', () {
      final li = BlockNode(
        tagName: 'li',
        children: [
          TextNode('Text '),
          InlineNode.strong(children: [TextNode('bold')]),
          TextNode(' more'),
        ],
      );

      expect(li.textContent, equals('Text bold more'));
    });
  });

  group('List ComputedStyle', () {
    test('list node can have custom ComputedStyle', () {
      final ul = BlockNode(
        tagName: 'ul',
        style: ComputedStyle(
          display: DisplayType.block,
          padding: const EdgeInsets.only(left: 24),
        ),
        children: [],
      );

      expect(ul.style.display, equals(DisplayType.block));
      expect(ul.style.padding.left, equals(24));
    });

    test('list item inherits color from parent list', () {
      final parentStyle = ComputedStyle(
        color: const Color(0xFF333333),
        display: DisplayType.block,
      );
      final childStyle = ComputedStyle();

      childStyle.inheritFrom(parentStyle);

      expect(childStyle.color, equals(const Color(0xFF333333)));
    });

    test('list item can override parent font-size', () {
      final parentStyle = ComputedStyle(fontSize: 20);
      final childStyle = ComputedStyle(fontSize: 14);
      childStyle.markExplicitlySet('font-size');

      childStyle.inheritFrom(parentStyle);

      // Explicit child value is preserved
      expect(childStyle.fontSize, equals(14));
    });

    test('ComputedStyle can be copied with different display', () {
      final base = ComputedStyle(display: DisplayType.block);
      final copy = base.copyWith(display: DisplayType.inline);

      expect(base.display, equals(DisplayType.block));
      expect(copy.display, equals(DisplayType.inline));
    });
  });

  group('Nested List Structure', () {
    test('nested lists build correctly', () {
      final root = BlockNode(
        tagName: 'ul',
        children: [
          BlockNode(
            tagName: 'li',
            children: [
              TextNode('Level 1'),
              BlockNode(
                tagName: 'ul',
                children: [
                  BlockNode(
                    tagName: 'li',
                    children: [TextNode('Level 2')],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      expect(root.tagName, equals('ul'));
      final li = root.children[0];
      expect(li.tagName, equals('li'));
      final innerUl = li.children[1];
      expect(innerUl.tagName, equals('ul'));
      final innerLi = innerUl.children[0];
      expect(innerLi.textContent, equals('Level 2'));
    });

    test('empty list has no children', () {
      final ul = BlockNode(tagName: 'ul', children: []);
      expect(ul.children.isEmpty, isTrue);
    });

    test('list with mixed children types', () {
      final ul = BlockNode(
        tagName: 'ul',
        children: [
          BlockNode(tagName: 'li', children: [TextNode('Valid item')]),
          BlockNode(tagName: 'div', children: [TextNode('Non-li child')]),
        ],
      );

      expect(ul.children.length, equals(2));
      expect(ul.children[0].tagName, equals('li'));
      expect(ul.children[1].tagName, equals('div'));
    });
  });

  group('List Item Complex Content', () {
    test('list item with inline elements', () {
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

    test('list preserves child order', () {
      final items = ['First', 'Second', 'Third'];
      final ol = BlockNode(
        tagName: 'ol',
        children: items
            .map((text) => BlockNode(
                  tagName: 'li',
                  children: [TextNode(text)],
                ))
            .toList(),
      );

      for (var i = 0; i < items.length; i++) {
        expect(ol.children[i].textContent, equals(items[i]));
      }
    });
  });
}
