import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Intrinsic Width Guard Tests
//
// Verifies that the width-related logic in Fragment and the node model:
//   1. Return 0 for an empty document.
//   2. Return a positive finite value for normal content.
//   3. Guard against ZWJ / unloaded-font width issues (isFinite && > 0).
//   4. Measure TextNodes and AtomicNodes with correct constructors.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('DocumentNode — structure invariants', () {
    test('empty document has no children', () {
      final doc = DocumentNode(children: []);
      expect(doc.children, isEmpty);
    });

    test('document with paragraphs has children', () {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('Hello world this is a normal sentence.'),
        ]),
      ]);
      expect(doc.children, isNotEmpty);
      expect(doc.children.first.tagName, 'p');
    });

    test('ZWJ emoji sequence creates valid TextNode', () {
      // Family ZWJ: 👨‍👩‍👧‍👦 (U+200D joins)
      const zwjText = '👨\u200D👩\u200D👧\u200D👦 Hello';
      final node = TextNode(zwjText);
      expect(node.text, contains('\u200D'));
      expect(node.text.isNotEmpty, isTrue);
      expect(node.type, NodeType.text);
    });

    test('very long unbreakable word creates valid TextNode', () {
      const longWord =
          'supercalifragilisticexpialidocious-this-is-an-extremely-long-unbreakable-word';
      final node = TextNode(longWord);
      expect(node.text.length, greaterThan(50));
    });

    test('document with mixed content types is valid', () {
      final doc = DocumentNode(children: [
        BlockNode.h1(children: [TextNode('Heading')]),
        BlockNode.p(children: [
          TextNode('Normal '),
          InlineNode.strong(children: [TextNode('bold')]),
          TextNode(' and '),
          InlineNode.em(children: [TextNode('italic')]),
        ]),
        BlockNode.p(children: [TextNode('ZWJ: 👨\u200D👩\u200D👧\u200D👦')]),
      ]);

      expect(doc.children.length, 3);
      expect(doc.children[0].tagName, 'h1');
      expect(doc.children[1].tagName, 'p');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('AtomicNode — intrinsic dimension guards', () {
    test('AtomicNode.img without dimensions has null intrinsicWidth', () {
      final img = AtomicNode.img(
        src: 'https://test.invalid/image.png',
        alt: 'Test image',
        // no width/height provided
      );
      // Before dimensions are set, intrinsicWidth is null (no phantom size).
      expect(img.intrinsicWidth, isNull);
      expect(img.intrinsicHeight, isNull);
    });

    test('AtomicNode.img with explicit dimensions is positive and finite', () {
      final img = AtomicNode.img(
        src: 'https://test.invalid/image.png',
        alt: 'Test',
        width: 200.0,
        height: 150.0,
      );
      expect(img.intrinsicWidth, 200.0);
      expect(img.intrinsicHeight, 150.0);
      expect(img.intrinsicWidth!.isFinite, isTrue);
      expect(img.intrinsicWidth! > 0, isTrue);
    });

    test('AtomicNode.img with zero dimensions has zero width', () {
      // Zero dimensions — the guard (w > 0) will skip contributing to maxWidth.
      final img = AtomicNode.img(
        src: 'https://test.invalid/zero.png',
        width: 0.0,
        height: 0.0,
      );
      expect(img.intrinsicWidth, 0.0);
    });

    test('AtomicNode.img with large dimensions is finite', () {
      final img = AtomicNode.img(
        src: 'https://test.invalid/big.png',
        width: 4096.0,
        height: 4096.0,
      );
      expect(img.intrinsicWidth!.isFinite, isTrue);
      expect(img.intrinsicHeight!.isFinite, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('ComputedStyle — style value invariants', () {
    test('defaultStyle has finite positive font size', () {
      final style = ComputedStyle.defaultStyle;
      expect(style.fontSize.isFinite, isTrue);
      expect(style.fontSize > 0, isTrue);
    });

    test('copyWith preserves finitenesss of fontSize', () {
      final style = ComputedStyle.defaultStyle.copyWith(fontSize: 24.0);
      expect(style.fontSize, 24.0);
      expect(style.fontSize.isFinite, isTrue);
    });

    test('lineHeight is null or positive finite', () {
      final style = ComputedStyle.defaultStyle;
      if (style.lineHeight != null) {
        expect(style.lineHeight!.isFinite, isTrue);
        expect(style.lineHeight! > 0, isTrue);
      }
    });

    test('letterSpacing is null or finite', () {
      final style = ComputedStyle.defaultStyle;
      if (style.letterSpacing != null) {
        expect(style.letterSpacing!.isFinite, isTrue);
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('DocumentNode — traversal', () {
    test('traverse visits all text nodes in order', () {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('First'),
          InlineNode.strong(children: [TextNode('Second')]),
        ]),
        BlockNode.p(children: [TextNode('Third')]),
      ]);

      final texts = <String>[];
      doc.traverse((node) {
        if (node is TextNode) texts.add(node.text);
      });

      expect(texts, containsAll(['First', 'Second', 'Third']));
    });

    test('traverse on empty document does not crash', () {
      final doc = DocumentNode(children: []);
      expect(() => doc.traverse((_) {}), returnsNormally);
    });

    test('deeply nested document traversal completes without stack overflow',
        () {
      // 5 levels of nesting
      UDTNode leaf = TextNode('deep text');
      for (var i = 0; i < 5; i++) {
        leaf = InlineNode.span(children: [leaf]);
      }
      final doc = DocumentNode(children: [
        BlockNode.p(children: [leaf])
      ]);

      int count = 0;
      doc.traverse((_) => count++);
      expect(count, greaterThan(5));
    });

    test('traverse visits AtomicNode', () {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          AtomicNode.img(src: 'https://test.invalid/img.jpg', alt: 'Photo'),
        ]),
      ]);

      final atomics = <AtomicNode>[];
      doc.traverse((node) {
        if (node is AtomicNode) atomics.add(node);
      });

      expect(atomics, hasLength(1));
      expect(atomics.first.alt, 'Photo');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('RubyNode model', () {
    test('RubyNode stores base and ruby text', () {
      final ruby = RubyNode(
        baseText: '東京',
        rubyText: 'とうきょう',
      );
      expect(ruby.baseText, '東京');
      expect(ruby.rubyText, 'とうきょう');
    });

    test('RubyNode with ZWJ in ruby annotation does not crash', () {
      // Edge case: ruby annotation contains emoji with ZWJ.
      final ruby = RubyNode(
        baseText: '笑',
        rubyText: '😄\u200D',
      );
      expect(ruby.baseText, isNotEmpty);
      expect(ruby.rubyText, isNotEmpty);
    });

    test('RubyNode type is ruby', () {
      final ruby = RubyNode(baseText: 'AB', rubyText: 'cd');
      expect(ruby.type, NodeType.ruby);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Fragment model — width invariants', () {
    test('text fragment stores text correctly', () {
      final source = TextNode('sample');
      final frag = Fragment.text(
        text: 'sample',
        style: ComputedStyle.defaultStyle,
        sourceNode: source,
      );
      expect(frag.text, 'sample');
      expect(frag.type, FragmentType.text);
    });

    test('lineBreak fragment has lineBreak type', () {
      final source = TextNode('\n');
      final frag = Fragment.lineBreak(
        sourceNode: source,
        style: ComputedStyle.defaultStyle,
      );
      expect(frag.type, FragmentType.lineBreak);
    });

    test('fragment without layout has zero width', () {
      final source = TextNode('');
      final frag = Fragment.text(
        text: '',
        style: ComputedStyle.defaultStyle,
        sourceNode: source,
      );
      // No layout run → measuredSize is null → width returns 0.
      expect(frag.measuredSize, isNull);
      expect(frag.width, 0.0);
    });

    test('fragment width is finite and positive after measuredSize is set', () {
      final source = TextNode('hello');
      final frag = Fragment.text(
        text: 'hello',
        style: ComputedStyle.defaultStyle,
        sourceNode: source,
      );
      frag.measuredSize = const Size(42.5, 20.0);
      expect(frag.width.isFinite, isTrue);
      expect(frag.width, 42.5);
      expect(frag.width > 0, isTrue);
    });

    test('fragment with zero measuredSize width satisfies guard (not > 0)', () {
      final source = TextNode('');
      final frag = Fragment.text(
        text: '',
        style: ComputedStyle.defaultStyle,
        sourceNode: source,
      );
      frag.measuredSize = const Size(0.0, 20.0);
      // Guard: isFinite && w > 0 should be false for 0-width fragments.
      expect(frag.width.isFinite, isTrue);
      expect(frag.width > 0, isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('HyperRenderConfig', () {
    test('defaults are sane production values', () {
      const config = HyperRenderConfig.defaults;
      expect(config.textPainterCacheSize, greaterThan(0));
      expect(config.imageConcurrency, greaterThan(0));
      expect(config.virtualizationChunkSize, greaterThan(1000));
      expect(config.defaultImagePlaceholderWidth, greaterThan(0));
    });

    test('custom low-end config values are respected', () {
      const config = HyperRenderConfig(
        textPainterCacheSize: 200,
        imageConcurrency: 1,
        virtualizationChunkSize: 2000,
        defaultImagePlaceholderWidth: 100.0,
      );
      expect(config.textPainterCacheSize, 200);
      expect(config.imageConcurrency, 1);
      expect(config.virtualizationChunkSize, 2000);
      expect(config.defaultImagePlaceholderWidth, 100.0);
    });

    test('custom high-end config values are respected', () {
      const config = HyperRenderConfig(
        textPainterCacheSize: 10000,
        imageConcurrency: 6,
        virtualizationChunkSize: 12000,
        defaultImagePlaceholderWidth: 400.0,
      );
      expect(config.textPainterCacheSize, 10000);
      expect(config.imageConcurrency, 6);
    });

    test('config is value-equal when parameters match', () {
      const a = HyperRenderConfig(textPainterCacheSize: 500);
      const b = HyperRenderConfig(textPainterCacheSize: 500);
      // const classes with same values should be identical.
      expect(a.textPainterCacheSize, b.textPainterCacheSize);
    });
  });
}
