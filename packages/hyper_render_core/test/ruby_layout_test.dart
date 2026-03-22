import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('RubyNode — Model', () {
    test('stores baseText and rubyText', () {
      final node = RubyNode(baseText: '漢字', rubyText: 'かんじ');
      expect(node.baseText, equals('漢字'));
      expect(node.rubyText, equals('かんじ'));
    });

    test('type is NodeType.ruby', () {
      final node = RubyNode(baseText: '日本語', rubyText: 'にほんご');
      expect(node.type, equals(NodeType.ruby));
      expect(node.tagName, equals('ruby'));
    });

    test('textContent returns baseText only', () {
      final node = RubyNode(baseText: '東京', rubyText: 'とうきょう');
      expect(node.textContent, equals('東京'));
    });

    test('empty strings are valid', () {
      final node = RubyNode(baseText: '', rubyText: '');
      expect(node.baseText, isEmpty);
      expect(node.rubyText, isEmpty);
    });

    test('accepts custom style', () {
      final style = ComputedStyle(fontSize: 20);
      final node = RubyNode(baseText: '漢', rubyText: 'かん', style: style);
      expect(node.style.fontSize, equals(20));
    });

    test('parent back-reference is null by default', () {
      final node = RubyNode(baseText: '字', rubyText: 'じ');
      expect(node.parent, isNull);
    });

    test('appendChild sets parent on ruby child', () {
      final doc = DocumentNode();
      final ruby = RubyNode(baseText: '日', rubyText: 'に');
      doc.appendChild(ruby);
      expect(ruby.parent, equals(doc));
      expect(doc.children, contains(ruby));
    });

    test('traverse visits the ruby node', () {
      final doc = DocumentNode(children: [
        RubyNode(baseText: '字', rubyText: 'じ'),
      ]);
      int rubyCount = 0;
      doc.traverse((n) {
        if (n.type == NodeType.ruby) rubyCount++;
      });
      expect(rubyCount, equals(1));
    });

    test('multiple ruby nodes in a paragraph', () {
      final para = BlockNode.p(children: [
        RubyNode(baseText: '日本', rubyText: 'にほん'),
        TextNode('は'),
        RubyNode(baseText: '綺麗', rubyText: 'きれい'),
        TextNode('です'),
      ]);
      final rubyNodes =
          para.children.whereType<RubyNode>().toList();
      expect(rubyNodes.length, equals(2));
      expect(rubyNodes[0].baseText, equals('日本'));
      expect(rubyNodes[1].baseText, equals('綺麗'));
    });

    test('textContent of paragraph with ruby joins correctly', () {
      final para = BlockNode.p(children: [
        RubyNode(baseText: '東', rubyText: 'ひがし'),
        TextNode('の'),
        RubyNode(baseText: '空', rubyText: 'そら'),
      ]);
      // textContent recurses into children → ruby.textContent = baseText
      expect(para.textContent, equals('東の空'));
    });

    test('deeply nested ruby in inline element', () {
      final span = InlineNode.span(children: [
        RubyNode(baseText: '山', rubyText: 'やま'),
      ]);
      expect(span.textContent, equals('山'));
      expect(span.children.first.type, equals(NodeType.ruby));
    });

    test('RubyNode has unique id per instance', () {
      final a = RubyNode(baseText: 'A', rubyText: 'a');
      final b = RubyNode(baseText: 'B', rubyText: 'b');
      expect(a.id, isNot(equals(b.id)));
    });
  });

  group('Fragment.ruby — Model', () {
    late ComputedStyle style;
    late RubyNode sourceNode;

    setUp(() {
      style = ComputedStyle(fontSize: 16);
      sourceNode = RubyNode(baseText: '漢字', rubyText: 'かんじ');
    });

    test('creates ruby fragment with correct fields', () {
      final frag = Fragment.ruby(
        baseText: '漢字',
        rubyText: 'かんじ',
        sourceNode: sourceNode,
        style: style,
      );
      expect(frag.type, equals(FragmentType.ruby));
      expect(frag.text, equals('漢字'));
      expect(frag.rubyText, equals('かんじ'));
    });

    test('sourceNode reference is preserved', () {
      final frag = Fragment.ruby(
        baseText: '漢字',
        rubyText: 'かんじ',
        sourceNode: sourceNode,
        style: style,
      );
      expect(frag.sourceNode, same(sourceNode));
    });

    test('ruby fragment has no measuredSize before layout', () {
      final frag = Fragment.ruby(
        baseText: '字',
        rubyText: 'じ',
        sourceNode: sourceNode,
        style: style,
      );
      expect(frag.measuredSize, isNull);
      expect(frag.width, equals(0));
      expect(frag.height, equals(0));
    });

    test('ruby fragment rect is null before layout', () {
      final frag = Fragment.ruby(
        baseText: '字',
        rubyText: 'じ',
        sourceNode: sourceNode,
        style: style,
      );
      expect(frag.rect, isNull);
    });

    test('ruby fragment rect is valid after offset + measuredSize set', () {
      final frag = Fragment.ruby(
        baseText: '字',
        rubyText: 'じ',
        sourceNode: sourceNode,
        style: style,
      );
      frag.measuredSize = const Size(30, 40);
      frag.offset = const Offset(10, 20);
      final rect = frag.rect!;
      expect(rect.left, equals(10));
      expect(rect.top, equals(20));
      expect(rect.width, equals(30));
      expect(rect.height, equals(40));
    });

    test('rubyHeight can be set after creation', () {
      final frag = Fragment.ruby(
        baseText: '日',
        rubyText: 'に',
        sourceNode: sourceNode,
        style: style,
      );
      frag.rubyHeight = 8.0;
      expect(frag.rubyHeight, equals(8.0));
    });

    test('toString shows base|ruby text', () {
      final frag = Fragment.ruby(
        baseText: '漢',
        rubyText: 'かん',
        sourceNode: sourceNode,
        style: style,
      );
      expect(frag.toString(), contains('漢'));
      expect(frag.toString(), contains('かん'));
    });

    test('canBreak is false for ruby fragments (no spaces)', () {
      final frag = Fragment.ruby(
        baseText: '漢字',
        rubyText: 'かんじ',
        sourceNode: sourceNode,
        style: style,
      );
      expect(frag.canBreak, isFalse);
    });

    test('isWhitespace is false for ruby fragments', () {
      final frag = Fragment.ruby(
        baseText: '漢字',
        rubyText: 'かんじ',
        sourceNode: sourceNode,
        style: style,
      );
      expect(frag.isWhitespace, isFalse);
    });
  });

  group('Ruby in Document Tree', () {
    test('document with mixed text and ruby traversal count', () {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('彼女は'),
          RubyNode(baseText: '綺麗', rubyText: 'きれい'),
          TextNode('だ'),
        ]),
        BlockNode.p(children: [
          RubyNode(baseText: '東京', rubyText: 'とうきょう'),
          TextNode('に住んでいます'),
        ]),
      ]);

      int rubyCount = 0;
      int textCount = 0;
      doc.traverse((n) {
        if (n.type == NodeType.ruby) rubyCount++;
        if (n.type == NodeType.text) textCount++;
      });

      expect(rubyCount, equals(2));
      expect(textCount, equals(3));
    });

    test('removeChild clears parent reference on ruby node', () {
      final para = BlockNode.p();
      final ruby = RubyNode(baseText: '字', rubyText: 'じ');
      para.appendChild(ruby);
      expect(ruby.parent, equals(para));

      para.removeChild(ruby);
      expect(ruby.parent, isNull);
    });

    test('findById works for ruby node', () {
      final ruby = RubyNode(baseText: '字', rubyText: 'じ');
      final doc = DocumentNode(children: [ruby]);
      expect(doc.findById(ruby.id), same(ruby));
    });

    test('ruby node classList is always empty (no class attribute)', () {
      final ruby = RubyNode(baseText: '字', rubyText: 'じ');
      expect(ruby.classList, isEmpty);
    });

    test('ruby node cssId is null without attributes', () {
      final ruby = RubyNode(baseText: '字', rubyText: 'じ');
      expect(ruby.cssId, isNull);
    });

    test('is not block-level', () {
      final ruby = RubyNode(baseText: '字', rubyText: 'じ');
      expect(ruby.isBlock, isFalse);
    });
  });
}
