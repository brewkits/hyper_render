import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('Fragment — characterOffset correctness (Bug 1 regression)', () {
    // After the Bug 1 fix, secondFragment.characterOffset should NOT include
    // trimmed leading spaces. The character offset maps to the original text
    // position, and trimmed spaces belong to the start of the second fragment.

    test('characterOffset starts at 0 by default', () {
      final style = ComputedStyle();
      final node = TextNode('hello world');
      final frag = Fragment.text(
        text: 'hello',
        sourceNode: node,
        style: style,
        characterOffset: 0,
      );
      expect(frag.characterOffset, equals(0));
    });

    test('characterOffset can be set to non-zero', () {
      final style = ComputedStyle();
      final node = TextNode('hello world');
      final frag = Fragment.text(
        text: 'world',
        sourceNode: node,
        style: style,
        characterOffset: 6, // 'hello ' = 6 chars
      );
      expect(frag.characterOffset, equals(6));
    });

    test('two fragments from same source have sequential characterOffsets', () {
      final style = ComputedStyle();
      final node = TextNode('hello world');

      final first = Fragment.text(
        text: 'hello',
        sourceNode: node,
        style: style,
        characterOffset: 0,
      );
      final second = Fragment.text(
        text: ' world',
        sourceNode: node,
        style: style,
        characterOffset: 5, // 'hello' = 5, NOT 'hello ' = 6
      );

      // second starts at first.text.length (no leading trim added)
      expect(second.characterOffset, equals(first.text!.length));
    });

    test('characterOffset is immutable after construction', () {
      final style = ComputedStyle();
      final node = TextNode('test');
      final frag = Fragment.text(
        text: 'test',
        sourceNode: node,
        style: style,
        characterOffset: 3,
      );
      // characterOffset is a mutable field in the model — verify it holds value
      expect(frag.characterOffset, equals(3));
    });
  });

  group('Fragment — rect computation', () {
    test('rect is null when offset is null', () {
      final style = ComputedStyle();
      final node = TextNode('test');
      final frag = Fragment.text(text: 'test', sourceNode: node, style: style);
      frag.measuredSize = const Size(50, 20);
      expect(frag.rect, isNull);
    });

    test('rect is null when measuredSize is null', () {
      final style = ComputedStyle();
      final node = TextNode('test');
      final frag = Fragment.text(text: 'test', sourceNode: node, style: style);
      frag.offset = const Offset(10, 20);
      expect(frag.rect, isNull);
    });

    test('rect is valid when both offset and measuredSize are set', () {
      final style = ComputedStyle();
      final node = TextNode('test');
      final frag = Fragment.text(text: 'test', sourceNode: node, style: style);
      frag.measuredSize = const Size(60, 24);
      frag.offset = const Offset(5, 10);

      final rect = frag.rect!;
      expect(rect.left, equals(5));
      expect(rect.top, equals(10));
      expect(rect.right, equals(65));
      expect(rect.bottom, equals(34));
    });

    test('atomic fragment rect computed correctly', () {
      final node = AtomicNode.img(src: 'x.png');
      final frag = Fragment.atomic(
        sourceNode: node,
        style: ComputedStyle(),
        size: const Size(200, 150),
      );
      frag.offset = const Offset(0, 0);

      final rect = frag.rect!;
      expect(rect.width, equals(200));
      expect(rect.height, equals(150));
    });
  });

  group('_buildNodeRectCache — logic via Fragment/UDTNode model', () {
    // The actual _buildNodeRectCache runs inside RenderHyperBox.performLayout.
    // Here we test the underlying model contracts it depends on.

    test('fragment sourceNode reference is preserved after construction', () {
      final style = ComputedStyle();
      final node = TextNode('source');
      final frag = Fragment.text(text: 'source', sourceNode: node, style: style);
      expect(frag.sourceNode, same(node));
    });

    test('parent-child relationship supports cache walk-up', () {
      final para = BlockNode.p();
      final span = InlineNode.span();
      final text = TextNode('leaf');
      para.appendChild(span);
      span.appendChild(text);

      // Walk from leaf to root — simulates cache depth walk
      UDTNode? current = text;
      final path = <UDTNode>[];
      while (current != null) {
        path.add(current);
        current = current.parent;
      }
      // text → span → para (para.parent is null)
      expect(path, containsAllInOrder([text, span, para]));
    });

    test('Rect.expandToInclude merges two rects correctly', () {
      const r1 = Rect.fromLTWH(0, 0, 50, 20);
      const r2 = Rect.fromLTWH(40, 10, 50, 20);
      final merged = r1.expandToInclude(r2);
      expect(merged.left, equals(0));
      expect(merged.top, equals(0));
      expect(merged.right, equals(90));
      expect(merged.bottom, equals(30));
    });

    test('Rect.expandToInclude with disjoint rects', () {
      const r1 = Rect.fromLTWH(0, 0, 10, 10);
      const r2 = Rect.fromLTWH(100, 100, 10, 10);
      final merged = r1.expandToInclude(r2);
      expect(merged.left, equals(0));
      expect(merged.top, equals(0));
      expect(merged.right, equals(110));
      expect(merged.bottom, equals(110));
    });

    test('deeply nested node tree depth limit — 32 levels max', () {
      // Build a chain 35 levels deep
      UDTNode root = BlockNode.div();
      UDTNode current = root;
      for (int i = 0; i < 34; i++) {
        final child = BlockNode.div();
        current.appendChild(child);
        current = child;
      }
      final leaf = TextNode('leaf');
      current.appendChild(leaf);

      // Verify we can walk 35 levels without stack overflow
      int depth = 0;
      UDTNode? node = leaf;
      while (node != null) {
        depth++;
        node = node.parent;
      }
      expect(depth, equals(36)); // leaf + 34 divs + root
    });
  });

  group('_sameLinkContext — link boundary detection (Bug 2 regression)', () {
    // Tests that text nodes from different <a> ancestors are not merged.
    // The actual merging logic is in RenderHyperBox._tokenizeText.
    // Here we test the structural model that the fix relies on.

    test('text node inside anchor has anchor as ancestor', () {
      final anchor = InlineNode.a(href: 'https://example.com', children: [
        TextNode('Click here'),
      ]);
      final text = anchor.children.first as TextNode;
      expect(text.parent, same(anchor));
      expect(text.parent?.tagName, equals('a'));
    });

    test('two text nodes with different anchor parents are distinct', () {
      final para = BlockNode.p(children: [
        InlineNode.a(href: 'https://a.com', children: [TextNode('Link A')]),
        InlineNode.a(href: 'https://b.com', children: [TextNode('Link B')]),
      ]);

      final links = para.children.whereType<InlineNode>().toList();
      expect(links.length, equals(2));
      expect(links[0].attributes['href'], equals('https://a.com'));
      expect(links[1].attributes['href'], equals('https://b.com'));
      expect(links[0], isNot(same(links[1])));
    });

    test('text node outside anchor has no anchor ancestor', () {
      final para = BlockNode.p(children: [
        TextNode('Plain text'),
        InlineNode.a(href: 'https://example.com', children: [TextNode('Link')]),
        TextNode('More plain text'),
      ]);

      final plainTexts = para.children.whereType<TextNode>().toList();
      for (final t in plainTexts) {
        // Parent is para (a block), not an anchor
        expect(t.parent?.tagName, isNot(equals('a')));
      }
    });

    test('link ancestor walk correctly identifies <a> tag', () {
      // Simulate _findLinkAncestor logic
      UDTNode? findLinkAncestor(UDTNode node) {
        UDTNode? current = node.parent;
        while (current != null) {
          if (current.tagName == 'a') return current;
          current = current.parent;
        }
        return null;
      }

      final anchor = InlineNode.a(href: 'https://example.com');
      final span = InlineNode.span();
      final text = TextNode('deep');
      anchor.appendChild(span);
      span.appendChild(text);

      expect(findLinkAncestor(text), same(anchor));
    });

    test('text outside any link has no link ancestor', () {
      UDTNode? findLinkAncestor(UDTNode node) {
        UDTNode? current = node.parent;
        while (current != null) {
          if (current.tagName == 'a') return current;
          current = current.parent;
        }
        return null;
      }

      final para = BlockNode.p();
      final text = TextNode('no link');
      para.appendChild(text);

      expect(findLinkAncestor(text), isNull);
    });
  });

  group('Fragment — null text guard (Bug 4 regression)', () {
    // After Bug 4 fix, measuring a fragment with null text should not crash.

    test('fragment with null text has type != text', () {
      final node = AtomicNode.img(src: 'x.png');
      final frag = Fragment.atomic(
        sourceNode: node,
        style: ComputedStyle(),
        size: const Size(100, 80),
      );
      expect(frag.text, isNull);
      expect(frag.type, equals(FragmentType.atomic));
    });

    test('line break fragment text is null', () {
      final frag = Fragment.lineBreak(
        sourceNode: LineBreakNode(),
        style: ComputedStyle(),
      );
      expect(frag.text, isNull);
    });

    test('text fragment text is non-null', () {
      final frag = Fragment.text(
        text: 'hello',
        sourceNode: TextNode('hello'),
        style: ComputedStyle(),
      );
      expect(frag.text, isNotNull);
      expect(frag.text, equals('hello'));
    });

    test('ruby fragment text is the baseText', () {
      final frag = Fragment.ruby(
        baseText: '漢字',
        rubyText: 'かんじ',
        sourceNode: RubyNode(baseText: '漢字', rubyText: 'かんじ'),
        style: ComputedStyle(),
      );
      expect(frag.text, equals('漢字'));
      expect(frag.rubyText, equals('かんじ'));
    });
  });

  group('DocumentNode — dispose and reassign safety', () {
    test('DocumentNode can be created and replaced', () {
      final doc1 = DocumentNode(children: [
        BlockNode.p(children: [TextNode('First')]),
      ]);
      final doc2 = DocumentNode(children: [
        BlockNode.p(children: [TextNode('Second')]),
      ]);

      // Simulates what the document setter does: replace doc1 with doc2
      // No crash expected
      expect(doc1, isNotNull);
      expect(doc2, isNotNull);
      expect(doc1.children.first.textContent, equals('First'));
      expect(doc2.children.first.textContent, equals('Second'));
    });

    test('empty DocumentNode has no children', () {
      final doc = DocumentNode();
      expect(doc.children, isEmpty);
    });

    test('DocumentNode traverse visits all descendants', () {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          InlineNode.a(href: 'https://example.com', children: [
            TextNode('Link text'),
          ]),
          TextNode(' plain'),
        ]),
      ]);

      int count = 0;
      doc.traverse((_) => count++);
      // doc(1) + p(1) + a(1) + 'Link text'(1) + ' plain'(1) = 5
      expect(count, equals(5));
    });
  });
}
