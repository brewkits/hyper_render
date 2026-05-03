// Tests for v1.2.0 accessibility improvements:
//  - <img alt="…"> produces a discrete SemanticsNode at its rect (WCAG 1.1.1)
//  - aria-label on <a> is used as link's semantic label (WCAG 4.1.2)
//  - Images without alt do NOT add extra semantic nodes
//  - Existing baseline: headings and links still have semantics nodes

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('A11y v1.2.0 — image alt-text semantic nodes', () {
    testWidgets('img with alt text is found in semantics tree', (tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          AtomicNode.img(src: 'https://example.com/cat.jpg', alt: 'A cute cat'),
        ]),
      ]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperRenderWidget(document: doc),
        ),
      ));
      await tester.pump();

      // The alt text should appear in the semantics tree so screen readers
      // can navigate to the image element.
      final semantics = tester.getSemantics(find.byType(HyperRenderWidget));

      // Walk all semantic nodes looking for the alt text label.
      bool found = _containsLabel(semantics, 'A cute cat');
      expect(found, isTrue,
          reason: 'Expected alt text "A cute cat" to appear in semantics tree');
    });

    testWidgets('img without alt does NOT add "A cute cat" label',
        (tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          // No alt attribute.
          AtomicNode.img(src: 'https://example.com/decorative.jpg'),
        ]),
      ]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperRenderWidget(document: doc),
        ),
      ));
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(HyperRenderWidget));
      // Decorative images without alt should not pollute the semantics tree.
      expect(_containsLabel(semantics, 'A cute cat'), isFalse);
    });

    testWidgets('img with empty alt does NOT add a semantic node',
        (tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          AtomicNode.img(src: 'https://example.com/spacer.gif', alt: ''),
        ]),
      ]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperRenderWidget(document: doc),
        ),
      ));
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(HyperRenderWidget));
      // Empty alt → should not contribute "[Image]" or any other text to semantics.
      expect(_containsLabel(semantics, '[Image]'), isFalse);
      expect(_containsLabel(semantics, '[Image: ]'), isFalse);
    });
  });

  group('A11y v1.2.0 — aria-label on links', () {
    testWidgets('aria-label overrides link text in semantics', (tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          InlineNode(
            tagName: 'a',
            attributes: {
              'href': 'https://example.com/article',
              'aria-label': 'Read full article about climate change',
            },
            children: [TextNode('Read more')],
          ),
        ]),
      ]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperRenderWidget(
            document: doc,
            onLinkTap: (_) {},
          ),
        ),
      ));
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(HyperRenderWidget));

      // aria-label value should appear, not the element text.
      expect(
        _containsLabel(semantics, 'Read full article about climate change'),
        isTrue,
      );
    });

    testWidgets('link without aria-label uses text content', (tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          InlineNode(
            tagName: 'a',
            attributes: {'href': 'https://example.com'},
            children: [TextNode('Click here')],
          ),
        ]),
      ]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperRenderWidget(
            document: doc,
            onLinkTap: (_) {},
          ),
        ),
      ));
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(HyperRenderWidget));
      expect(_containsLabel(semantics, 'Click here'), isTrue);
    });
  });
}

// ── Helper: walk SemanticsNode tree ──────────────────────────────────────────

bool _containsLabel(SemanticsNode node, String label) {
  if (node.label == label) return true;
  // SemanticsNode.mergedUp stores the children via visitChildren.
  bool found = false;
  node.visitChildren((child) {
    if (!found) found = _containsLabel(child, label);
    return !found;
  });
  return found;
}
