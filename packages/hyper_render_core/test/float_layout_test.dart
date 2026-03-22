import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('HyperFloat — Enum values', () {
    test('HyperFloat has none, left, right values', () {
      expect(HyperFloat.values, contains(HyperFloat.none));
      expect(HyperFloat.values, contains(HyperFloat.left));
      expect(HyperFloat.values, contains(HyperFloat.right));
    });

    test('default float on ComputedStyle is HyperFloat.none', () {
      final style = ComputedStyle();
      expect(style.float, equals(HyperFloat.none));
    });

    test('ComputedStyle stores float: left', () {
      final style = ComputedStyle(float: HyperFloat.left);
      expect(style.float, equals(HyperFloat.left));
    });

    test('ComputedStyle stores float: right', () {
      final style = ComputedStyle(float: HyperFloat.right);
      expect(style.float, equals(HyperFloat.right));
    });
  });

  group('HyperClear — Enum values', () {
    test('HyperClear has none, left, right, both', () {
      expect(HyperClear.values, contains(HyperClear.none));
      expect(HyperClear.values, contains(HyperClear.left));
      expect(HyperClear.values, contains(HyperClear.right));
      expect(HyperClear.values, contains(HyperClear.both));
    });

    test('default clear on ComputedStyle is HyperClear.none', () {
      final style = ComputedStyle();
      expect(style.clear, equals(HyperClear.none));
    });

    test('ComputedStyle stores clear: left', () {
      final style = ComputedStyle(clear: HyperClear.left);
      expect(style.clear, equals(HyperClear.left));
    });

    test('ComputedStyle stores clear: right', () {
      final style = ComputedStyle(clear: HyperClear.right);
      expect(style.clear, equals(HyperClear.right));
    });

    test('ComputedStyle stores clear: both', () {
      final style = ComputedStyle(clear: HyperClear.both);
      expect(style.clear, equals(HyperClear.both));
    });
  });

  group('Float node construction', () {
    test('BlockNode with float left style', () {
      final node = BlockNode(
        tagName: 'div',
        style: ComputedStyle(
          float: HyperFloat.left,
          width: 100,
          height: 100,
        ),
        children: [TextNode('Float left')],
      );
      expect(node.style.float, equals(HyperFloat.left));
      expect(node.style.width, equals(100));
    });

    test('BlockNode with float right style', () {
      final node = BlockNode(
        tagName: 'div',
        style: ComputedStyle(
          float: HyperFloat.right,
          width: 80,
        ),
        children: [TextNode('Float right')],
      );
      expect(node.style.float, equals(HyperFloat.right));
    });

    test('AtomicNode image with float left', () {
      final img = AtomicNode.img(src: 'image.png', width: 200, height: 150);
      img.style = ComputedStyle(
        display: DisplayType.inlineBlock,
        float: HyperFloat.left,
        width: 200,
        height: 150,
      );
      expect(img.style.float, equals(HyperFloat.left));
      expect(img.style.width, equals(200));
    });

    test('paragraph after float has clear: both', () {
      final para = BlockNode.p(
        children: [TextNode('Cleared paragraph')],
      );
      para.style = ComputedStyle(
        display: DisplayType.block,
        clear: HyperClear.both,
      );
      expect(para.style.clear, equals(HyperClear.both));
    });

    test('float node in document tree', () {
      final floatImg = AtomicNode.img(src: 'photo.jpg', width: 150);
      final doc = DocumentNode(children: [
        BlockNode.div(children: [
          floatImg,
          BlockNode.p(children: [
            TextNode('Text wraps around the float'),
          ]),
        ]),
      ]);
      expect(doc.children.first.children, contains(floatImg));
    });
  });

  group('Float style inheritance', () {
    test('float is NOT inherited by children (stays at none)', () {
      final parent = ComputedStyle(float: HyperFloat.left);
      final child = ComputedStyle();
      child.inheritFrom(parent);
      // float is not an inherited property — child keeps its default
      expect(child.float, equals(HyperFloat.none));
    });

    test('clear is NOT inherited by children (stays at none)', () {
      final parent = ComputedStyle(clear: HyperClear.both);
      final child = ComputedStyle();
      child.inheritFrom(parent);
      // clear is not an inherited property — child keeps its default
      expect(child.clear, equals(HyperClear.none));
    });
  });

  group('Fragment — canBreak and whitespace around floats', () {
    test('whitespace fragment is whitespace', () {
      final style = ComputedStyle();
      final node = TextNode(' ');
      final frag = Fragment.text(text: '   ', sourceNode: node, style: style);
      expect(frag.isWhitespace, isTrue);
    });

    test('text fragment with spaces can break', () {
      final style = ComputedStyle();
      final node = TextNode('hello world');
      final frag = Fragment.text(
          text: 'hello world', sourceNode: node, style: style);
      expect(frag.canBreak, isTrue);
    });

    test('single word fragment cannot break', () {
      final style = ComputedStyle();
      final node = TextNode('hello');
      final frag =
          Fragment.text(text: 'hello', sourceNode: node, style: style);
      expect(frag.canBreak, isFalse);
    });

    test('line break fragment has zero size', () {
      final style = ComputedStyle();
      final node = LineBreakNode();
      final frag = Fragment.lineBreak(sourceNode: node, style: style);
      expect(frag.measuredSize, equals(Size.zero));
      expect(frag.width, equals(0));
      expect(frag.height, equals(0));
    });
  });

  group('LineInfo — left/right inset (float columns)', () {
    test('LineInfo default insets are 0', () {
      final line = LineInfo();
      expect(line.leftInset, equals(0));
      expect(line.rightInset, equals(0));
    });

    test('LineInfo stores non-zero insets', () {
      final line = LineInfo(leftInset: 120, rightInset: 80);
      expect(line.leftInset, equals(120));
      expect(line.rightInset, equals(80));
    });

    test('LineInfo width excludes insets (available width = total - insets)', () {
      // LineInfo.width sums fragment widths, not available width.
      // We test that fragments placed after inset still report correct width.
      final style = ComputedStyle();
      final node = TextNode('test');
      final frag = Fragment.text(text: 'test', sourceNode: node, style: style);
      frag.measuredSize = const Size(60, 20);

      final line = LineInfo(leftInset: 120, rightInset: 80);
      line.add(frag);

      expect(line.width, equals(60));
      expect(line.height, equals(20));
    });

    test('empty LineInfo has zero width and height', () {
      final line = LineInfo();
      expect(line.width, equals(0));
      expect(line.height, equals(0));
      expect(line.isEmpty, isTrue);
    });

    test('LineInfo characterCount sums text fragment lengths', () {
      final style = ComputedStyle();
      final node = TextNode('hello world');
      final frag1 =
          Fragment.text(text: 'hello', sourceNode: node, style: style);
      final frag2 =
          Fragment.text(text: ' world', sourceNode: node, style: style);
      final line = LineInfo();
      line.add(frag1);
      line.add(frag2);
      expect(line.characterCount, equals(11));
    });

    test('LineInfo characterCount counts lineBreak as 1', () {
      final style = ComputedStyle();
      final brNode = LineBreakNode();
      final frag = Fragment.lineBreak(sourceNode: brNode, style: style);
      final line = LineInfo();
      line.add(frag);
      expect(line.characterCount, equals(1));
    });
  });

  group('Document tree — float and clear elements', () {
    test('article with sidebar float structure', () {
      final sidebar = BlockNode(
        tagName: 'aside',
        style: ComputedStyle(float: HyperFloat.right, width: 200),
        children: [TextNode('Sidebar')],
      );
      final main = BlockNode(
        tagName: 'main',
        style: ComputedStyle(display: DisplayType.block),
        children: [TextNode('Main content')],
      );
      final clearfix = BlockNode(
        tagName: 'div',
        style: ComputedStyle(clear: HyperClear.both),
      );
      final article = BlockNode(
        tagName: 'article',
        children: [sidebar, main, clearfix],
      );

      expect(article.children.length, equals(3));
      expect(sidebar.style.float, equals(HyperFloat.right));
      expect(clearfix.style.clear, equals(HyperClear.both));
    });

    test('float image in paragraph node structure', () {
      final img = AtomicNode.img(src: 'banner.png', width: 300, height: 200);
      img.style = ComputedStyle(
        display: DisplayType.inlineBlock,
        float: HyperFloat.left,
        width: 300,
        height: 200,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
      );

      final para = BlockNode.p(children: [
        img,
        TextNode('Long text that wraps around the floated image.'),
      ]);

      expect(para.children.first, same(img));
      expect(img.parent, equals(para));
      expect(img.style.margin.right, equals(16));
    });

    test('multiple floats side by side', () {
      final left = BlockNode(
        tagName: 'div',
        style: ComputedStyle(float: HyperFloat.left, width: 100),
        children: [TextNode('Left')],
      );
      final right = BlockNode(
        tagName: 'div',
        style: ComputedStyle(float: HyperFloat.right, width: 100),
        children: [TextNode('Right')],
      );
      final container = BlockNode.div(children: [left, right]);

      expect(container.children.length, equals(2));
      expect(left.style.float, equals(HyperFloat.left));
      expect(right.style.float, equals(HyperFloat.right));
    });
  });
}
