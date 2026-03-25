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
      final rubyNodes = para.children.whereType<RubyNode>().toList();
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

  // ─── Selection / Character-offset tests ───────────────────────────────────

  group('LineInfo.characterCount with ruby', () {
    late ComputedStyle style;
    late RubyNode rubySource;

    setUp(() {
      style = ComputedStyle(fontSize: 16);
      rubySource = RubyNode(baseText: '漢字', rubyText: 'かんじ');
    });

    test('counts ruby base-text characters', () {
      final line = LineInfo();
      line.add(Fragment.ruby(
        baseText: '漢字',
        rubyText: 'かんじ',
        sourceNode: rubySource,
        style: style,
      ));
      // '漢字' is 2 characters
      expect(line.characterCount, equals(2));
    });

    test('counts text + ruby characters together', () {
      final textNode = TextNode('AB');
      final line = LineInfo();
      line.add(Fragment.text(
        text: 'AB',
        sourceNode: textNode,
        style: style,
      ));
      line.add(Fragment.ruby(
        baseText: '漢字',
        rubyText: 'かんじ',
        sourceNode: rubySource,
        style: style,
      ));
      // 'AB' (2) + '漢字' (2) = 4
      expect(line.characterCount, equals(4));
    });

    test('multiple ruby fragments are summed', () {
      final r1 = RubyNode(baseText: '東', rubyText: 'ひがし');
      final r2 = RubyNode(baseText: '京', rubyText: 'きょう');
      final line = LineInfo();
      line.add(Fragment.ruby(
          baseText: '東', rubyText: 'ひがし', sourceNode: r1, style: style));
      line.add(Fragment.ruby(
          baseText: '京', rubyText: 'きょう', sourceNode: r2, style: style));
      // '東' (1) + '京' (1) = 2
      expect(line.characterCount, equals(2));
    });

    test('atomic fragments are not counted', () {
      final atomicNode = AtomicNode(tagName: 'img', src: 'x.png');
      final line = LineInfo();
      line.add(Fragment.atomic(
        sourceNode: atomicNode,
        style: style,
        size: const Size(40, 40),
      ));
      expect(line.characterCount, equals(0));
    });
  });

  group('Fragment selection offset — ruby in mixed content', () {
    late ComputedStyle style;

    setUp(() {
      style = ComputedStyle(fontSize: 16);
    });

    test('ruby fragment text field holds base text only', () {
      final ruby = RubyNode(baseText: '東京', rubyText: 'とうきょう');
      final frag = Fragment.ruby(
        baseText: '東京',
        rubyText: 'とうきょう',
        sourceNode: ruby,
        style: style,
      );
      // .text is used as the character contribution in selection offset tracking
      expect(frag.text, equals('東京'));
      expect(frag.text!.length, equals(2));
      expect(frag.rubyText, equals('とうきょう'));
    });

    test('ruby fragment character length matches baseText', () {
      final cases = [
        ('字', 1),
        ('漢字', 2),
        ('東京都', 3),
        ('日本語テスト', 6),
      ];
      for (final (base, expectedLen) in cases) {
        final node = RubyNode(baseText: base, rubyText: 'よみ');
        final frag = Fragment.ruby(
          baseText: base,
          rubyText: 'よみ',
          sourceNode: node,
          style: style,
        );
        expect(frag.text!.length, equals(expectedLen),
            reason: 'baseText "$base"');
      }
    });

    test('selection offset accumulates correctly across text + ruby + text',
        () {
      // Simulate the currentOffset tracking used in _paintSelection /
      // getSelectedText / getSelectionRects.
      //
      // Layout: [ "ABC" | <ruby>漢字</ruby> | "DEF" ]
      //          off 0-3       off 3-5            off 5-8
      final textNode = TextNode('placeholder');
      final rubyNode = RubyNode(baseText: '漢字', rubyText: 'かんじ');

      final fragA =
          Fragment.text(text: 'ABC', sourceNode: textNode, style: style);
      final fragR = Fragment.ruby(
          baseText: '漢字', rubyText: 'かんじ', sourceNode: rubyNode, style: style);
      final fragB =
          Fragment.text(text: 'DEF', sourceNode: textNode, style: style);

      int offset = 0;

      // Consume 'ABC'
      final startA = offset;
      offset += fragA.text!.length; // offset = 3
      expect(startA, equals(0));
      expect(offset, equals(3));

      // Consume ruby '漢字'
      final startR = offset;
      offset += fragR.text!.length; // offset = 5
      expect(startR, equals(3));
      expect(offset, equals(5));

      // Consume 'DEF'
      final startB = offset;
      offset += fragB.text!.length; // offset = 8
      expect(startB, equals(5));
      expect(offset, equals(8));
    });

    test('ruby-only line characterCount equals base text length', () {
      final ruby1 = RubyNode(baseText: '日本', rubyText: 'にほん');
      final ruby2 = RubyNode(baseText: '語', rubyText: 'ご');
      final line = LineInfo();
      line.add(Fragment.ruby(
          baseText: '日本', rubyText: 'にほん', sourceNode: ruby1, style: style));
      line.add(Fragment.ruby(
          baseText: '語', rubyText: 'ご', sourceNode: ruby2, style: style));
      // '日本' (2) + '語' (1) = 3
      expect(line.characterCount, equals(3));
    });

    test('text after ruby starts at correct offset', () {
      // Verify that text fragments following a ruby fragment in the same line
      // are offset correctly (i.e., ruby chars were counted).
      final textNode = TextNode('foo');
      final rubyNode = RubyNode(baseText: '漢', rubyText: 'かん');

      final frags = [
        Fragment.text(text: 'Hello', sourceNode: textNode, style: style),
        Fragment.ruby(
            baseText: '漢', rubyText: 'かん', sourceNode: rubyNode, style: style),
        Fragment.text(text: 'World', sourceNode: textNode, style: style),
      ];

      // Simulate the skip-line currentOffset accumulation
      int offset = 0;
      final offsets = <int>[];
      for (final f in frags) {
        offsets.add(offset);
        if ((f.type == FragmentType.text || f.type == FragmentType.ruby) &&
            f.text != null) {
          offset += f.text!.length;
        }
      }

      expect(offsets[0], equals(0)); // "Hello" starts at 0
      expect(offsets[1], equals(5)); // ruby starts at 5 (after "Hello")
      expect(
          offsets[2], equals(6)); // "World" starts at 6 (after "Hello" + '漢')
    });
  });
}
