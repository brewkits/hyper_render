import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

const _sampleText = 'The quick brown fox jumps over the lazy dog';

RenderHyperBox? _findBox(RenderObject? root) {
  if (root == null) return null;
  if (root is RenderHyperBox) return root;
  RenderHyperBox? found;
  root.visitChildren((child) => found ??= _findBox(child));
  return found;
}

Future<RenderHyperBox> _pump(WidgetTester tester, DocumentNode document,
    {double width = 300}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: HyperRenderWidget(document: document),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final box = _findBox(
    find.byType(HyperRenderWidget).evaluate().first.renderObject,
  );
  expect(box, isNotNull, reason: 'no RenderHyperBox was built');
  return box!;
}

DocumentNode _paragraph(String text) => DocumentNode(children: [
      BlockNode.p(children: [TextNode(text)])
    ]);

void main() {
  group('RenderHyperBox.getBoxesForCharRange', () {
    testWidgets('returns empty list for inverted or invalid ranges',
        (tester) async {
      final box = await _pump(tester, _paragraph(_sampleText));
      expect(box.getBoxesForCharRange(10, 5), isEmpty);
      expect(box.getBoxesForCharRange(5, 5), isEmpty);
    });

    testWidgets('returns exact bounding box for single word', (tester) async {
      final box = await _pump(tester, _paragraph(_sampleText));
      // "quick" is at offsets 4..9
      final rects = box.getBoxesForCharRange(4, 9);
      expect(rects, hasLength(1));
      final rect = rects.first;
      expect(rect.width, greaterThan(10.0));
      expect(rect.height, greaterThan(8.0));
      expect(rect.left, greaterThan(0.0));
    });

    testWidgets('returns contiguous boxes across multiple words on single line',
        (tester) async {
      final box = await _pump(tester, _paragraph(_sampleText), width: 600);
      // "The quick brown" at 0..15
      final rects = box.getBoxesForCharRange(0, 15);
      expect(rects, hasLength(1));
      expect(rects.first.left, closeTo(0.0, 2.0));
      expect(rects.first.width, greaterThan(50.0));
    });

    testWidgets(
        'merges mixed-styled inline fragments into a single contiguous rect on the same line',
        (tester) async {
      // Document with normal text followed by a bold span and normal text on one line:
      // "Hello " (normal) + "world" (bold) + " again" (normal)
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('Hello '),
          InlineNode.strong(
            children: [TextNode('world')],
          ),
          TextNode(' again'),
        ]),
      ]);

      final box = await _pump(tester, doc, width: 600);
      // Range 0..17 covers "Hello world again"
      final rects = box.getBoxesForCharRange(0, 17);
      expect(
        rects,
        hasLength(1),
        reason:
            'mixed-styled fragments on the same line must merge into a single seamless line highlight',
      );
      expect(rects.first.left, closeTo(0.0, 2.0));
      expect(rects.first.top, closeTo(16.0, 4.0));
      expect(rects.first.width, greaterThan(200.0));
    });

    testWidgets('returns boxes across lines when range wraps', (tester) async {
      // Narrow container forces wrapping
      final box = await _pump(tester, _paragraph(_sampleText), width: 120);
      // Full sentence range 0..43
      final rects = box.getBoxesForCharRange(0, _sampleText.length);
      expect(rects.length, greaterThan(1),
          reason: 'should produce rects per line');
    });

    testWidgets('preserves spaces in white-space:pre fragment', (tester) async {
      // A text node carrying white-space:pre directly — internal spaces must NOT
      // be trimmed by the isPreformatted guard in getBoxesForCharRange.
      // Without the guard, leading spaces at the selection edge would be stripped
      // and the returned rect would be narrower (or empty if all spaces).
      const preText = '   hello'; // 3 leading spaces + word
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode(preText, style: ComputedStyle(whiteSpace: 'pre')),
        ]),
      ]);

      final box = await _pump(tester, doc, width: 400);
      // Range 0..8 covers the entire "   hello" text including leading spaces.
      final rects = box.getBoxesForCharRange(0, preText.length);
      final helloRects = box.getBoxesForCharRange(3, 8);
      expect(rects, isNotEmpty,
          reason:
              'pre-formatted text with leading spaces should produce a rect');
      expect(helloRects, hasLength(1));
      expect(rects.first.width, greaterThan(helloRects.first.width));
    });

    testWidgets(
        'inline image between two words does not spuriously merge word rects',
        (tester) async {
      // "hello " + 16px image + " world" — the maxGap heuristic introduced in
      // f5a313b must not bridge the gap caused by the image column and collapse
      // two separate word rects into one.
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('hello '),
          AtomicNode.img(
            src: 'https://example.com/1x1.png',
            width: 16,
            height: 16,
          ),
          TextNode(' world'),
        ]),
      ]);

      final box = await _pump(tester, doc, width: 600);
      // Char range 0..12 covers the logical text "hello  world" (image is not
      // a text character, so "hello " is 6 chars and " world" is 6 chars).
      final rects = box.getBoxesForCharRange(0, 12);
      expect(rects, hasLength(2));
      // Each rect must have non-trivial width — not a collapsed zero-width rect.
      for (final r in rects) {
        expect(r.width, greaterThan(10.0),
            reason: 'each word rect should have real width');
      }
    });
  });
}
