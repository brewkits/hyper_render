// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() {
  group('HyperViewer Accessibility', () {
    testWidgets('has default semantic label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Test content</p>',
            ),
          ),
        ),
      );

      // Find Semantics widget
      final semanticsFinder = find.bySemanticsLabel('Article content');
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('uses custom semantic label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>News article</p>',
              semanticLabel: 'Breaking news: Flutter 4.0 released',
            ),
          ),
        ),
      );

      final semanticsFinder =
          find.bySemanticsLabel('Breaking news: Flutter 4.0 released');
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('can exclude from semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Decorative content</p>',
              excludeSemantics: true,
            ),
          ),
        ),
      );

      // When excludeSemantics is true, the label should not be in semantic tree
      final semanticsFinder = find.bySemanticsLabel('Article content');
      expect(semanticsFinder, findsNothing);
    });

    testWidgets('works with different content types', (tester) async {
      // HTML
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<h1>Title</h1><p>Content</p>',
              semanticLabel: 'HTML article',
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('HTML article'), findsOneWidget);

      // Markdown
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer.markdown(
              markdown: '# Title\n\nContent',
              semanticLabel: 'Markdown document',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Markdown document'), findsOneWidget);
    });

    testWidgets('semantic label updates on content change', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>First content</p>',
              semanticLabel: 'First article',
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('First article'), findsOneWidget);

      // Update content
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Second content</p>',
              semanticLabel: 'Second article',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Second article'), findsOneWidget);
      expect(find.bySemanticsLabel('First article'), findsNothing);
    });

    testWidgets('semantic label persists during loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html:
                  '<p>${'Long content ' * 500}</p>', // Reduced from 2000 to avoid timeout
              mode: HyperRenderMode.virtualized,
              semanticLabel: 'Large article',
              renderConfig: const HyperRenderConfig(useMicrotaskParsing: true),
            ),
          ),
        ),
      );

      // Semantic label should be present even during loading
      expect(find.bySemanticsLabel('Large article'), findsOneWidget);

      // Pump a few frames instead of waiting for settle (which may timeout with virtualized lists)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // And after loading starts
      expect(find.bySemanticsLabel('Large article'), findsOneWidget);
    });

    testWidgets('combines with selectable mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Selectable and accessible</p>',
              selectable: true,
              semanticLabel: 'Selectable article',
            ),
          ),
        ),
      );

      // Should have both semantic label and be selectable
      expect(find.bySemanticsLabel('Selectable article'), findsOneWidget);
    });

    test('semantic parameters are optional', () {
      // Should compile without semantic parameters
      const viewer = HyperViewer(
        html: '<p>Test</p>',
      );

      expect(viewer.semanticLabel, isNull);
      expect(viewer.excludeSemantics, isFalse);
    });
  });

  // ── WCAG 2.1 AA — semantic tree structure ──────────────────────────────────
  //
  // These tests walk the raw SemanticsNode tree produced by RenderHyperBox to
  // verify that headings, links, and images expose the correct flags and labels.
  // They use _collectAllSemanticNodes() rather than find.bySemanticsLabel()
  // because the semantic anchor nodes are custom RenderObject children that are
  // not associated with widget Elements.

  group('Semantic tree — WCAG 2.1 AA verification', () {
    testWidgets('h1-h6 headings produce isHeader semantic nodes (WCAG 1.3.1)',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                mode: HyperRenderMode.sync,
                html: '<h1>Section Title</h1><p>Body text.</p>',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nodes = _collectAllSemanticNodes(tester);
      expect(
        nodes.any((d) =>
            d.label == 'Section Title' &&
            d.hasFlag(SemanticsFlag.isHeader)),
        isTrue,
        reason: 'WCAG 1.3.1: <h1> must produce an isHeader semantic node',
      );
      handle.dispose();
    });

    testWidgets('links produce isLink semantic nodes (WCAG 4.1.2)',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                mode: HyperRenderMode.sync,
                html: '<p><a href="https://example.com">Visit example</a></p>',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nodes = _collectAllSemanticNodes(tester);
      expect(
        nodes.any((d) =>
            d.label == 'Visit example' &&
            d.hasFlag(SemanticsFlag.isLink)),
        isTrue,
        reason: 'WCAG 4.1.2: <a href> must produce an isLink semantic node',
      );
      handle.dispose();
    });

    testWidgets('aria-label on link overrides visible text (WCAG 4.1.2)',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperViewer(
                mode: HyperRenderMode.sync,
                html:
                    '<a href="https://example.com" aria-label="Open documentation site">Docs</a>',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nodes = _collectAllSemanticNodes(tester);
      expect(
        nodes.any((d) =>
            d.label == 'Open documentation site' &&
            d.hasFlag(SemanticsFlag.isLink)),
        isTrue,
        reason: 'WCAG 4.1.2: aria-label must override link text in semantics',
      );
      handle.dispose();
    });

    testWidgets('image alt text is included in semantic label (WCAG 1.1.1)',
        (tester) async {
      await mockNetworkImagesFor(() async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: HyperViewer(
                  mode: HyperRenderMode.sync,
                  html: '<img src="photo.jpg" alt="A red apple on a white table">',
                ),
              ),
            ),
          ),
        );
        // pump instead of pumpAndSettle to avoid timeouts with Image.network + mock
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Alt text appears in the flat content label via _buildTextContentForSemantics
        // and/or as a discrete anchor node at the image's layout rect.
        final nodes = _collectAllSemanticNodes(tester);
        expect(
          nodes.any((d) => d.label.contains('A red apple on a white table')),
          isTrue,
          reason:
              'WCAG 1.1.1: <img alt="..."> must expose alt text in semantics',
        );
        handle.dispose();
      });
    });

    testWidgets(
        'decorative images with empty alt are not announced (WCAG 1.1.1)',
        (tester) async {
      await mockNetworkImagesFor(() async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: HyperViewer(
                  mode: HyperRenderMode.sync,
                  html: '<p>Text only</p><img src="decorative.jpg" alt="">',
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // alt="" marks the image as decorative — _buildTextContentForSemantics
        // must NOT emit '[Image]' for it (WCAG 1.1.1).
        final nodes = _collectAllSemanticNodes(tester);
        expect(
          nodes.any((d) => d.label.contains('[Image]')),
          isFalse,
          reason:
              'WCAG 1.1.1: <img alt=""> is decorative — must not contribute to semantic labels',
        );
        handle.dispose();
      });
    });

    testWidgets('multiple headings all marked as isHeader', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: HyperViewer(
                mode: HyperRenderMode.sync,
                html: '<h1>Title</h1><h2>Subtitle</h2><h3>Section</h3>',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nodes = _collectAllSemanticNodes(tester);
      final headerNodes =
          nodes.where((d) => d.hasFlag(SemanticsFlag.isHeader)).toList();
      expect(
        headerNodes.length,
        greaterThanOrEqualTo(3),
        reason: 'All h1/h2/h3 elements must each produce an isHeader node',
      );
      handle.dispose();
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Recursively collects [SemanticsData] for every node in the semantic tree.
///
/// This is needed (rather than [find.bySemanticsLabel]) because the heading
/// and link anchor nodes are created by [RenderHyperBox.assembleSemanticsNode]
/// as custom [SemanticsNode] children not associated with widget Elements.
List<SemanticsData> _collectAllSemanticNodes(WidgetTester tester) {
  final result = <SemanticsData>[];
  void visit(SemanticsNode node) {
    result.add(node.getSemanticsData());
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  final owner = tester.binding.pipelineOwner.semanticsOwner;
  if (owner?.rootSemanticsNode != null) {
    visit(owner!.rootSemanticsNode!);
  }
  return result;
}
