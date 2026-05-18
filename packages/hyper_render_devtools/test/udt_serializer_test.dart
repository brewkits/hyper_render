import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_devtools/hyper_render_devtools.dart';

/// Tests for the JSON serialiser that DevTools uses to send UDT trees and
/// computed styles across the VM service boundary. The contract is:
///
///   1. Every public node field shows up at the same key on every call so
///      the DevTools panel can rely on the shape.
///   2. Tree depth is capped so a deeply-nested document can't blow up the
///      service-extension payload.
///   3. Text-node text is truncated (200 chars) so logs / inspector views
///      don't choke on a single huge text run.
void main() {
  group('UdtSerializer.serializeNode', () {
    test('emits the expected baseline keys for every node', () {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [TextNode('hello')]),
      ]);

      final json = UdtSerializer.serializeNode(doc);

      expect(json['id'], isNotNull);
      expect(json['type'], equals('document'));
      expect(json['attributes'], isA<Map<String, String>>());
      expect(json['style'], isA<Map<String, dynamic>>());
      expect(json['childCount'], equals(1));
      expect(json['children'], isA<List<dynamic>>());
    });

    test('preserves tagName for block nodes', () {
      final doc = DocumentNode(children: [
        BlockNode.h1(children: [TextNode('Title')]),
      ]);

      final json = UdtSerializer.serializeNode(doc);
      final h1 = (json['children'] as List).first as Map<String, dynamic>;

      expect(h1['tagName'], equals('h1'));
      expect(h1['type'], equals('block'));
    });

    test('text nodes carry their text payload', () {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [TextNode('the body text')]),
      ]);

      final json = UdtSerializer.serializeNode(doc);
      final p = (json['children'] as List).first as Map<String, dynamic>;
      final text = (p['children'] as List).first as Map<String, dynamic>;

      expect(text['type'], equals('text'));
      expect(text['text'], equals('the body text'));
    });

    test('text payload is truncated to 200 chars', () {
      final long = 'x' * 500;
      final doc = DocumentNode(children: [
        BlockNode.p(children: [TextNode(long)]),
      ]);

      final json = UdtSerializer.serializeNode(doc);
      final p = (json['children'] as List).first as Map<String, dynamic>;
      final text = (p['children'] as List).first as Map<String, dynamic>;

      expect((text['text'] as String).length, equals(200));
    });

    test('AtomicNode emits src/alt/intrinsic dims', () {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          AtomicNode(
            tagName: 'img',
            attributes: const {'src': 'https://x/y.png', 'alt': 'cat'},
            src: 'https://x/y.png',
            alt: 'cat',
            intrinsicWidth: 120,
            intrinsicHeight: 80,
            style: ComputedStyle(),
          ),
        ]),
      ]);

      final p =
          (UdtSerializer.serializeNode(doc)['children'] as List).first as Map;
      final img = (p['children'] as List).first as Map<String, dynamic>;

      expect(img['type'], equals('atomic'));
      expect(img['tagName'], equals('img'));
      expect(img['src'], equals('https://x/y.png'));
      expect(img['alt'], equals('cat'));
      expect(img['intrinsicWidth'], equals(120));
      expect(img['intrinsicHeight'], equals(80));
    });

    test('tree depth is capped at 20 to bound payload size', () {
      // Build a 25-level deep chain so the truncation marker must appear.
      UDTNode leaf = TextNode('leaf');
      for (int i = 0; i < 25; i++) {
        leaf = BlockNode.div(children: [leaf]);
      }
      final doc = DocumentNode(children: [leaf as BlockNode]);

      // Walk down until we hit a level where children was zeroed out by the
      // depth cap. At that node the truncation flag must be set, and the
      // original tree was deep enough that this must happen before depth 25.
      Map<String, dynamic> cur = UdtSerializer.serializeNode(doc);
      bool sawTruncated = false;
      for (int safety = 0; safety < 30; safety++) {
        if (cur['childrenTruncated'] == true) {
          sawTruncated = true;
          break;
        }
        final kids = cur['children'] as List;
        if (kids.isEmpty) break;
        cur = kids.first as Map<String, dynamic>;
      }
      expect(sawTruncated, isTrue,
          reason: 'serializer must mark deeply nested branches as truncated');
    });
  });

  group('UdtSerializer.serializeStyle', () {
    test('emits known keys for an empty style', () {
      final json = UdtSerializer.serializeStyle(ComputedStyle());

      // Spot-check a handful of keys the DevTools panel reads.
      for (final key in [
        'width',
        'height',
        'margin',
        'padding',
        'color',
        'fontSize',
        'display',
        'opacity',
      ]) {
        expect(json.containsKey(key), isTrue,
            reason: 'style payload missing key "$key"');
      }
    });

    test('encodes color as a stable int', () {
      final json = UdtSerializer.serializeStyle(
        ComputedStyle(color: const Color(0xFF112233)),
      );
      expect(json['color'], isA<int>());
    });

    test('round-trips a non-trivial padding/margin', () {
      final json = UdtSerializer.serializeStyle(ComputedStyle(
        padding: const EdgeInsets.fromLTRB(1, 2, 3, 4),
        margin: const EdgeInsets.fromLTRB(5, 6, 7, 8),
      ));
      final pad = json['padding'] as Map;
      final mar = json['margin'] as Map;
      expect(pad['left'], equals(1));
      expect(pad['top'], equals(2));
      expect(pad['right'], equals(3));
      expect(pad['bottom'], equals(4));
      expect(mar['left'], equals(5));
      expect(mar['bottom'], equals(8));
    });
  });

  group('UdtSerializer.serializeTree', () {
    test('returns a single-element list wrapping the document', () {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [TextNode('hi')]),
      ]);
      final tree = UdtSerializer.serializeTree(doc);

      expect(tree, isA<List<Map<String, dynamic>>>());
      expect(tree.length, equals(1));
      expect(tree.first['type'], equals('document'));
    });
  });
}
