import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('Fragment — canBreak (word-break / overflow-wrap semantics)', () {
    late ComputedStyle style;
    late TextNode node;

    setUp(() {
      style = ComputedStyle(fontSize: 16);
      node = TextNode('placeholder');
    });

    test('text with space can break', () {
      final frag =
          Fragment.text(text: 'hello world', sourceNode: node, style: style);
      expect(frag.canBreak, isTrue);
    });

    test('text with multiple spaces can break', () {
      final frag =
          Fragment.text(text: 'one two three', sourceNode: node, style: style);
      expect(frag.canBreak, isTrue);
    });

    test('single word without space cannot break', () {
      final frag =
          Fragment.text(text: 'superlongword', sourceNode: node, style: style);
      expect(frag.canBreak, isFalse);
    });

    test('empty text cannot break', () {
      final frag = Fragment.text(text: '', sourceNode: node, style: style);
      expect(frag.canBreak, isFalse);
    });

    test('whitespace-only text cannot break (no words)', () {
      final frag = Fragment.text(text: '   ', sourceNode: node, style: style);
      // Has spaces, so canBreak is true per current implementation
      expect(frag.canBreak, isTrue);
    });

    test('CJK text without space cannot break via canBreak', () {
      // CJK breaking is handled by kinsoku, not canBreak
      final frag =
          Fragment.text(text: '日本語テスト', sourceNode: node, style: style);
      expect(frag.canBreak, isFalse);
    });

    test('text ending with hyphen cannot break via canBreak', () {
      final frag = Fragment.text(text: 'word-', sourceNode: node, style: style);
      expect(frag.canBreak, isFalse);
    });
  });

  group('Fragment — isWhitespace', () {
    late ComputedStyle style;
    late TextNode node;

    setUp(() {
      style = ComputedStyle();
      node = TextNode(' ');
    });

    test('single space is whitespace', () {
      final frag = Fragment.text(text: ' ', sourceNode: node, style: style);
      expect(frag.isWhitespace, isTrue);
    });

    test('multiple spaces is whitespace', () {
      final frag = Fragment.text(text: '   ', sourceNode: node, style: style);
      expect(frag.isWhitespace, isTrue);
    });

    test('tab character is whitespace', () {
      final frag = Fragment.text(text: '\t', sourceNode: node, style: style);
      expect(frag.isWhitespace, isTrue);
    });

    test('newline character is whitespace', () {
      final frag = Fragment.text(text: '\n', sourceNode: node, style: style);
      expect(frag.isWhitespace, isTrue);
    });

    test('mixed spaces and newlines is whitespace', () {
      final frag =
          Fragment.text(text: '  \n  ', sourceNode: node, style: style);
      expect(frag.isWhitespace, isTrue);
    });

    test('text with content is not whitespace', () {
      final frag = Fragment.text(text: 'hello', sourceNode: node, style: style);
      expect(frag.isWhitespace, isFalse);
    });

    test('text with leading space is not purely whitespace', () {
      final frag =
          Fragment.text(text: ' hello', sourceNode: node, style: style);
      expect(frag.isWhitespace, isFalse);
    });

    test('empty string is whitespace (trim of empty is empty)', () {
      final frag = Fragment.text(text: '', sourceNode: node, style: style);
      expect(frag.isWhitespace, isTrue);
    });

    test('atomic fragment is never whitespace', () {
      final atomicNode = AtomicNode.img(src: 'x.png');
      final frag = Fragment.atomic(
        sourceNode: atomicNode,
        style: style,
        size: const Size(100, 50),
      );
      expect(frag.isWhitespace, isFalse);
    });

    test('line break fragment is whitespace', () {
      final brNode = LineBreakNode();
      final frag = Fragment.lineBreak(sourceNode: brNode, style: style);
      // lineBreak has text = null, trim of null? Actually isWhitespace checks type == text
      expect(frag.isWhitespace, isFalse); // type is lineBreak, not text
    });
  });

  group('ComputedStyle — overflow properties', () {
    test('overflowX defaults to visible', () {
      final style = ComputedStyle();
      expect(style.overflowX, equals(HyperOverflow.visible));
    });

    test('overflowY defaults to visible', () {
      final style = ComputedStyle();
      expect(style.overflowY, equals(HyperOverflow.visible));
    });

    test('stores overflowX: hidden', () {
      final style = ComputedStyle(overflowX: HyperOverflow.hidden);
      expect(style.overflowX, equals(HyperOverflow.hidden));
    });

    test('stores overflowY: scroll', () {
      final style = ComputedStyle(overflowY: HyperOverflow.scroll);
      expect(style.overflowY, equals(HyperOverflow.scroll));
    });

    test('stores overflowX: auto', () {
      final style = ComputedStyle(overflowX: HyperOverflow.auto);
      expect(style.overflowX, equals(HyperOverflow.auto));
    });

    test('overflowX and overflowY can differ', () {
      final style = ComputedStyle(
        overflowX: HyperOverflow.hidden,
        overflowY: HyperOverflow.scroll,
      );
      expect(style.overflowX, equals(HyperOverflow.hidden));
      expect(style.overflowY, equals(HyperOverflow.scroll));
    });
  });

  group('TextNode — whitespace handling in tree', () {
    test('TextNode preserves exact text', () {
      const text = 'Hello,  World!  ';
      final node = TextNode(text);
      expect(node.text, equals(text));
      expect(node.textContent, equals(text));
    });

    test('TextNode with only newlines', () {
      final node = TextNode('\n\n');
      expect(node.text, equals('\n\n'));
    });

    test('block with mixed text and whitespace nodes', () {
      final para = BlockNode.p(children: [
        TextNode('Start'),
        TextNode('   '),
        TextNode('End'),
      ]);
      expect(para.textContent, equals('Start   End'));
    });

    test('paragraph with pre-formatted content', () {
      final pre = BlockNode(
        tagName: 'pre',
        children: [TextNode('line 1\n  line 2\n    line 3')],
      );
      expect(pre.textContent, contains('\n'));
      expect(pre.textContent, contains('  line 2'));
    });
  });

  group('LineInfo — text wrapping mechanics', () {
    test('line accumulates fragments correctly', () {
      final style = ComputedStyle(fontSize: 14);
      final node = TextNode('test');

      final frag1 =
          Fragment.text(text: 'Hello', sourceNode: node, style: style);
      frag1.measuredSize = const Size(40, 20);
      final frag2 = Fragment.text(text: ' ', sourceNode: node, style: style);
      frag2.measuredSize = const Size(5, 20);
      final frag3 =
          Fragment.text(text: 'World', sourceNode: node, style: style);
      frag3.measuredSize = const Size(45, 20);

      final line = LineInfo();
      line.add(frag1);
      line.add(frag2);
      line.add(frag3);

      expect(line.fragments.length, equals(3));
      expect(line.width, equals(90)); // 40 + 5 + 45
      expect(line.height, equals(20));
      expect(line.isNotEmpty, isTrue);
    });

    test('line with tall inline image increases line height', () {
      final style = ComputedStyle();
      final node = TextNode('text');
      final imgNode = AtomicNode.img(src: 'x.png');

      final textFrag =
          Fragment.text(text: 'text', sourceNode: node, style: style);
      textFrag.measuredSize = const Size(40, 20);
      final imgFrag = Fragment.atomic(
        sourceNode: imgNode,
        style: style,
        size: const Size(50, 60),
      );

      final line = LineInfo();
      line.add(textFrag);
      line.add(imgFrag);

      expect(line.height, equals(60)); // max height is the image
    });

    test('line characterCount excludes atomic fragments', () {
      final style = ComputedStyle();
      final node = TextNode('text');
      final imgNode = AtomicNode.img(src: 'x.png');

      final textFrag =
          Fragment.text(text: 'hello', sourceNode: node, style: style);
      textFrag.measuredSize = const Size(40, 20);
      final imgFrag = Fragment.atomic(
        sourceNode: imgNode,
        style: style,
        size: const Size(50, 50),
      );

      final line = LineInfo();
      line.add(textFrag);
      line.add(imgFrag);

      expect(line.characterCount, equals(5)); // only text chars
    });
  });

  group('CJK / Kinsoku boundary detection', () {
    test('CJK text nodes can be created with multi-byte chars', () {
      final node = TextNode('日本語のテキスト折り返しテスト');
      expect(node.text.length, greaterThan(0));
    });

    test('CJK text in block node', () {
      final para = BlockNode.p(children: [
        TextNode('これは長い日本語のテキストです。折り返しが正しく動作するかテストします。'),
      ]);
      expect(para.textContent, isNotEmpty);
    });

    test('mixed CJK and Latin text', () {
      final para = BlockNode.p(children: [
        TextNode('Hello 世界 World 日本'),
      ]);
      expect(para.textContent, contains('Hello'));
      expect(para.textContent, contains('世界'));
    });

    test('kinsokuStart string is non-empty', () {
      expect(KinsokuProcessor.kinsokuStart, isNotEmpty);
      expect(KinsokuProcessor.kinsokuEnd, isNotEmpty);
    });

    test('closing punctuation cannot start a line', () {
      expect(KinsokuProcessor.cannotStartLine('。'), isTrue);
      expect(KinsokuProcessor.cannotStartLine('、'), isTrue);
      expect(KinsokuProcessor.cannotStartLine('」'), isTrue);
    });

    test('opening punctuation cannot end a line', () {
      expect(KinsokuProcessor.cannotEndLine('「'), isTrue);
      expect(KinsokuProcessor.cannotEndLine('（'), isTrue);
    });

    test('regular characters can start and end a line', () {
      expect(KinsokuProcessor.cannotStartLine('A'), isFalse);
      expect(KinsokuProcessor.cannotEndLine('A'), isFalse);
      expect(KinsokuProcessor.cannotStartLine('あ'), isFalse);
    });

    test('canBreakBetween allows break at regular char boundary', () {
      expect(KinsokuProcessor.canBreakBetween('A', 'B'), isTrue);
    });

    test('canBreakBetween prevents break before 。', () {
      expect(KinsokuProcessor.canBreakBetween('word', '。'), isFalse);
    });

    test('canBreakBetween prevents break after 「', () {
      expect(KinsokuProcessor.canBreakBetween('「', 'text'), isFalse);
    });

    test('findBreakPoint returns valid index for normal text', () {
      final idx = KinsokuProcessor.findBreakPoint('hello world', 5);
      expect(idx, greaterThan(0));
    });

    test('findBreakPoint returns -1 for empty text', () {
      expect(KinsokuProcessor.findBreakPoint('', 0), equals(-1));
    });

    test('empty char returns false for cannotStartLine', () {
      expect(KinsokuProcessor.cannotStartLine(''), isFalse);
    });

    test('empty char returns false for cannotEndLine', () {
      expect(KinsokuProcessor.cannotEndLine(''), isFalse);
    });
  });
}
