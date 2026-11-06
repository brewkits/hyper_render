import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

import 'support/geometry_probe.dart';

void main() {
  final paragraphs =
      List.generate(120, (i) => '<p>Paragraph $i ${'word ' * 30}</p>').join();

  test('chunks retain nested ancestry and every paragraph exactly once', () {
    final sections = HtmlAdapter().parseToSections(
      '<main class="outer"><article id="article">$paragraphs</article></main>',
      chunkSize: 500,
    );
    expect(sections.length, greaterThan(10));
    final texts = <String>[];
    void visit(UDTNode node) {
      for (final child in node.children) {
        expect(child.parent, same(node));
        visit(child);
      }
      if (node is TextNode) texts.add(node.text);
    }

    for (final section in sections) {
      expect(section.children.single.attributes['class'], 'outer');
      expect(
          section.children.single.children.single.attributes['id'], 'article');
      visit(section);
    }
    expect(texts, List.generate(120, (i) => 'Paragraph $i ${'word ' * 30}'));
  });

  for (final mode in [HyperRenderMode.auto, HyperRenderMode.virtualized]) {
    for (final width in [400.0, 240.0, 180.0]) {
      testWidgets('$mode preserves CSS wrapper width at viewport $width',
          (tester) async {
        final controller = HyperViewerController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(MaterialApp(
          home: SizedBox(
            key: probeBoundaryKey,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                height: 600,
                child: HyperViewer(
                  controller: controller,
                  html: '<main style="padding:0 20px">'
                      '<article class="article">$paragraphs</article></main>',
                  customCss: '.article { max-width:200px; margin:0 auto; }'
                      '.article > p { margin:0; }',
                  mode: mode,
                  renderConfig:
                      const HyperRenderConfig(virtualizationChunkSize: 1000),
                ),
              ),
            ),
          ),
        ));
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        Set<String> checkVisibleChunks() {
          final boxes = hyperBoxes(tester);
          expect(boxes, isNotEmpty);
          expect(find.byType(ListView), findsOneWidget);
          final paragraphs = <String>{};
          for (final box in boxes) {
            final fragments = box.debugLineFragments();
            final first = fragments.firstWhere(
                (f) => (f['text'] as String? ?? '').startsWith('Para'));
            final expectedLeft = width > 240 ? (width - 200) / 2 : 20.0;
            expect(first['offsetX'], closeTo(expectedLeft, 0.1));
            paragraphs.add(fragments.map((f) => f['text'] ?? '').join());
          }
          return paragraphs;
        }

        final initial = checkVisibleChunks();
        controller.scrollController.jumpTo(2500);
        await tester.pump();
        final scrolled = checkVisibleChunks();
        expect(scrolled.difference(initial), isNotEmpty,
            reason: 'Later chunks must also retain wrapper geometry');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
