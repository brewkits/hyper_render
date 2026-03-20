import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('HyperTextDirection — Enum values', () {
    test('HyperTextDirection has ltr and rtl', () {
      expect(HyperTextDirection.values, contains(HyperTextDirection.ltr));
      expect(HyperTextDirection.values, contains(HyperTextDirection.rtl));
    });

    test('isRtl returns true for rtl', () {
      final style = ComputedStyle(hyperDirection: HyperTextDirection.rtl);
      expect(style.isRtl, isTrue);
    });

    test('isRtl returns false for ltr', () {
      final style = ComputedStyle(hyperDirection: HyperTextDirection.ltr);
      expect(style.isRtl, isFalse);
    });

    test('isRtl returns false when hyperDirection is null', () {
      final style = ComputedStyle();
      expect(style.isRtl, isFalse);
    });
  });

  group('ComputedStyle — hyperDirection', () {
    test('default hyperDirection is null (not set)', () {
      final style = ComputedStyle();
      expect(style.hyperDirection, isNull);
    });

    test('stores hyperDirection: ltr', () {
      final style = ComputedStyle(hyperDirection: HyperTextDirection.ltr);
      expect(style.hyperDirection, equals(HyperTextDirection.ltr));
    });

    test('stores hyperDirection: rtl', () {
      final style = ComputedStyle(hyperDirection: HyperTextDirection.rtl);
      expect(style.hyperDirection, equals(HyperTextDirection.rtl));
    });

    test('hyperDirection is inherited from parent', () {
      final parent = ComputedStyle(hyperDirection: HyperTextDirection.rtl);
      final child = ComputedStyle();
      child.inheritFrom(parent);
      expect(child.hyperDirection, equals(HyperTextDirection.rtl));
    });

    test('child can override parent hyperDirection to ltr', () {
      final parent = ComputedStyle(hyperDirection: HyperTextDirection.rtl);
      final child = ComputedStyle(hyperDirection: HyperTextDirection.ltr);
      child.inheritFrom(parent);
      expect(child.hyperDirection, equals(HyperTextDirection.ltr));
    });

    test('ltr child with rtl parent keeps ltr', () {
      final parent = ComputedStyle(hyperDirection: HyperTextDirection.rtl);
      final child = ComputedStyle(hyperDirection: HyperTextDirection.ltr);
      child.inheritFrom(parent);
      expect(child.isRtl, isFalse);
    });
  });

  group('HyperTextAlign — RTL-aware alignment', () {
    test('HyperTextAlign has left, right, center, justify', () {
      expect(HyperTextAlign.values, contains(HyperTextAlign.left));
      expect(HyperTextAlign.values, contains(HyperTextAlign.right));
      expect(HyperTextAlign.values, contains(HyperTextAlign.center));
      expect(HyperTextAlign.values, contains(HyperTextAlign.justify));
    });

    test('right-aligned style', () {
      final style = ComputedStyle(textAlign: HyperTextAlign.right);
      expect(style.textAlign, equals(HyperTextAlign.right));
    });

    test('textAlign is inherited', () {
      final parent = ComputedStyle(textAlign: HyperTextAlign.right);
      final child = ComputedStyle();
      child.inheritFrom(parent);
      expect(child.textAlign, equals(HyperTextAlign.right));
    });

    test('inheritFrom copies parent textAlign to child', () {
      // Note: inheritFrom directly assigns textAlign = parent.textAlign,
      // so parent always wins for textAlign (CSS resolver handles explicit overrides
      // by NOT calling inheritFrom for explicitly-set properties).
      final parent = ComputedStyle(textAlign: HyperTextAlign.right);
      final child = ComputedStyle(textAlign: HyperTextAlign.left);
      child.inheritFrom(parent);
      expect(child.textAlign, equals(HyperTextAlign.right));
    });
  });

  group('RTL node structure', () {
    test('BlockNode with RTL direction attribute', () {
      final div = BlockNode(
        tagName: 'div',
        attributes: {'dir': 'rtl'},
        style: ComputedStyle(
          display: DisplayType.block,
          hyperDirection: HyperTextDirection.rtl,
        ),
        children: [TextNode('مرحبا بالعالم')],
      );
      expect(div.style.hyperDirection, equals(HyperTextDirection.rtl));
      expect(div.style.isRtl, isTrue);
      expect(div.attributes['dir'], equals('rtl'));
    });

    test('BlockNode with LTR direction attribute', () {
      final div = BlockNode(
        tagName: 'div',
        attributes: {'dir': 'ltr'},
        style: ComputedStyle(
          display: DisplayType.block,
          hyperDirection: HyperTextDirection.ltr,
        ),
        children: [TextNode('Hello World')],
      );
      expect(div.style.hyperDirection, equals(HyperTextDirection.ltr));
      expect(div.style.isRtl, isFalse);
    });

    test('Arabic text node stored correctly', () {
      const arabicText = 'مرحبا بالعالم';
      final node = TextNode(arabicText);
      expect(node.text, equals(arabicText));
      expect(node.text.length, greaterThan(0));
    });

    test('Hebrew text node stored correctly', () {
      const hebrewText = 'שלום עולם';
      final node = TextNode(hebrewText);
      expect(node.text, equals(hebrewText));
    });

    test('mixed LTR/RTL text in same paragraph', () {
      final para = BlockNode.p(children: [
        TextNode('Hello '),
        TextNode('مرحبا'),
        TextNode(' World'),
      ]);
      expect(para.children.length, equals(3));
      expect(para.textContent, equals('Hello مرحبا World'));
    });

    test('RTL paragraph with right text-align', () {
      final para = BlockNode(
        tagName: 'p',
        style: ComputedStyle(
          display: DisplayType.block,
          hyperDirection: HyperTextDirection.rtl,
          textAlign: HyperTextAlign.right,
        ),
        children: [TextNode('نص عربي')],
      );
      expect(para.style.isRtl, isTrue);
      expect(para.style.textAlign, equals(HyperTextAlign.right));
    });

    test('document with RTL and LTR sections', () {
      final doc = DocumentNode(children: [
        BlockNode(
          tagName: 'div',
          style: ComputedStyle(
              display: DisplayType.block,
              hyperDirection: HyperTextDirection.ltr),
          children: [
            BlockNode.h1(children: [TextNode('English Section')]),
            BlockNode.p(children: [TextNode('Left-to-right text.')]),
          ],
        ),
        BlockNode(
          tagName: 'div',
          attributes: {'dir': 'rtl'},
          style: ComputedStyle(
              display: DisplayType.block,
              hyperDirection: HyperTextDirection.rtl),
          children: [
            BlockNode.p(children: [TextNode('نص عربي للاختبار')]),
          ],
        ),
      ]);

      int ltrDivs = 0;
      int rtlDivs = 0;
      doc.traverse((n) {
        if (n.style.hyperDirection == HyperTextDirection.ltr) ltrDivs++;
        if (n.style.hyperDirection == HyperTextDirection.rtl) rtlDivs++;
      });
      expect(ltrDivs, greaterThan(0));
      expect(rtlDivs, greaterThan(0));
    });
  });

  group('RTL style inheritance chain', () {
    test('deeply nested child inherits RTL direction', () {
      final root = BlockNode(
        tagName: 'div',
        style: ComputedStyle(
          display: DisplayType.block,
          hyperDirection: HyperTextDirection.rtl,
        ),
      );
      final child = BlockNode.p();
      final grandchild = InlineNode.span();
      final leafStyle = ComputedStyle();

      root.appendChild(child);
      child.appendChild(grandchild);

      // Manually apply inheritance (as resolver would do)
      child.style.inheritFrom(root.style);
      grandchild.style.inheritFrom(child.style);
      leafStyle.inheritFrom(grandchild.style);

      expect(child.style.isRtl, isTrue);
      expect(grandchild.style.isRtl, isTrue);
      expect(leafStyle.isRtl, isTrue);
    });

    test('inline element can override parent RTL to LTR', () {
      final rtlPara = BlockNode(
        tagName: 'p',
        style: ComputedStyle(
          display: DisplayType.block,
          hyperDirection: HyperTextDirection.rtl,
        ),
      );
      final ltrSpan = InlineNode(
        tagName: 'span',
        attributes: {'dir': 'ltr'},
        style: ComputedStyle(
          display: DisplayType.inline,
          hyperDirection: HyperTextDirection.ltr,
        ),
        children: [TextNode('LTR island')],
      );
      rtlPara.appendChild(ltrSpan);

      expect(rtlPara.style.isRtl, isTrue);
      expect(ltrSpan.style.isRtl, isFalse);
    });

    test('sibling nodes can have different directions', () {
      final para = BlockNode.div(children: [
        InlineNode(
          tagName: 'span',
          style: ComputedStyle(hyperDirection: HyperTextDirection.ltr),
          children: [TextNode('English')],
        ),
        InlineNode(
          tagName: 'span',
          style: ComputedStyle(hyperDirection: HyperTextDirection.rtl),
          children: [TextNode('عربي')],
        ),
      ]);

      final spans = para.children.cast<InlineNode>();
      expect(spans.first.style.isRtl, isFalse);
      expect(spans.last.style.isRtl, isTrue);
    });
  });

  group('HyperRenderWidget — RTL integration', () {
    testWidgets('renders RTL document without crash', (tester) async {
      final doc = DocumentNode(children: [
        BlockNode(
          tagName: 'p',
          style: ComputedStyle(
            display: DisplayType.block,
            hyperDirection: HyperTextDirection.rtl,
          ),
          children: [TextNode('مرحبا بالعالم')],
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: HyperRenderWidget(
                document: doc,
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      // Widget renders without exceptions
      expect(find.byType(HyperRenderWidget), findsOneWidget);
    });

    testWidgets('renders LTR document in RTL Directionality', (tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [TextNode('Hello World')]),
      ]);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 200,
                child: HyperRenderWidget(
                  document: doc,
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(HyperRenderWidget), findsOneWidget);
    });

    testWidgets('empty RTL document renders without crash', (tester) async {
      final doc = DocumentNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperRenderWidget(
              document: doc,
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      );

      await tester.pump();
    });
  });
}
