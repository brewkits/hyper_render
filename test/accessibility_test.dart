import "package:hyper_render/hyper_render.dart";
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HyperViewer Accessibility', () {
    testWidgets('has default semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
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
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>News article</p>',
              semanticLabel: 'Breaking news: Flutter 4.0 released',
            ),
          ),
        ),
      );

      final semanticsFinder = find.bySemanticsLabel('Breaking news: Flutter 4.0 released');
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('can exclude from semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
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
        MaterialApp(
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
        MaterialApp(
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
        MaterialApp(
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
        MaterialApp(
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
              html: '<p>${'Long content ' * 500}</p>', // Reduced from 2000 to avoid timeout
              mode: HyperRenderMode.virtualized,
              semanticLabel: 'Large article',
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
        MaterialApp(
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
}
