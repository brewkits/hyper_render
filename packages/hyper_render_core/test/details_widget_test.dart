import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('DetailsWidget', () {
    group('Basic Rendering', () {
      testWidgets('renders with default summary', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [
            TextNode('Content'),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        // Should show default "Details" summary
        expect(find.text('Details'), findsOneWidget);
        expect(find.byType(DetailsWidget), findsOneWidget);
      });

      testWidgets('renders with custom summary', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [
            BlockNode(
              tagName: 'summary',
              children: [TextNode('Custom Summary')],
            ),
            TextNode('Content'),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        expect(find.text('Custom Summary'), findsOneWidget);
      });

      testWidgets('shows disclosure triangle', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [TextNode('Content')],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        // Should have arrow icon
        expect(find.byType(Icon), findsOneWidget);
        expect(find.byIcon(Icons.arrow_right), findsOneWidget);
      });
    });

    group('Expand/Collapse Behavior', () {
      testWidgets('initially collapsed when open=false', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [
            BlockNode(
              tagName: 'summary',
              children: [TextNode('Summary')],
            ),
            TextNode('Hidden Content'),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        // Summary visible, content hidden
        expect(find.text('Summary'), findsOneWidget);
        expect(find.text('Hidden Content'), findsNothing);
      });

      testWidgets('initially expanded when open=true', (tester) async {
        final detailsNode = DetailsNode(
          open: true,
          children: [
            BlockNode(
              tagName: 'summary',
              children: [TextNode('Summary')],
            ),
            TextNode('Visible Content'),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        // Both visible
        expect(find.text('Summary'), findsOneWidget);
        expect(find.text('Visible Content'), findsOneWidget);
      });

      testWidgets('expands on tap', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [
            BlockNode(
              tagName: 'summary',
              children: [TextNode('Summary')],
            ),
            TextNode('Content'),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        // Initially collapsed
        expect(find.text('Content'), findsNothing);

        // Tap to expand
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Now expanded
        expect(find.text('Content'), findsOneWidget);
      });

      testWidgets('collapses on second tap', (tester) async {
        final detailsNode = DetailsNode(
          open: true,
          children: [
            BlockNode(
              tagName: 'summary',
              children: [TextNode('Summary')],
            ),
            TextNode('Content'),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        // Initially expanded
        expect(find.text('Content'), findsOneWidget);

        // Tap to collapse
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Now collapsed
        expect(find.text('Content'), findsNothing);
      });

      testWidgets('toggles multiple times', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [TextNode('Content')],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        for (int i = 0; i < 3; i++) {
          // Tap to expand
          await tester.tap(find.byType(InkWell));
          await tester.pumpAndSettle();
          expect(find.text('Content'), findsOneWidget);

          // Tap to collapse
          await tester.tap(find.byType(InkWell));
          await tester.pumpAndSettle();
          expect(find.text('Content'), findsNothing);
        }
      });
    });

    group('Smooth Animations', () {
      testWidgets('has AnimatedRotation for icon', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [TextNode('Content')],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        // Should have AnimatedRotation widget
        expect(find.byType(AnimatedRotation), findsOneWidget);
      });

      testWidgets('has AnimatedSize for content', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [TextNode('Content')],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        // Should have AnimatedSize widget
        expect(find.byType(AnimatedSize), findsOneWidget);
      });

      testWidgets('animates icon rotation on expand', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [TextNode('Content')],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        // Get initial rotation
        final animatedRotation1 = tester.widget<AnimatedRotation>(
          find.byType(AnimatedRotation),
        );
        expect(animatedRotation1.turns, equals(0.0));

        // Tap to expand
        await tester.tap(find.byType(InkWell));
        await tester.pump(); // Start animation
        await tester.pump(const Duration(milliseconds: 150)); // Mid-animation

        // Rotation should be animating (between 0 and 0.25)
        final animatedRotation2 = tester.widget<AnimatedRotation>(
          find.byType(AnimatedRotation),
        );
        expect(animatedRotation2.turns, equals(0.25));
      });

      testWidgets('animates content size on expand', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [
            BlockNode(
              tagName: 'summary',
              children: [TextNode('Summary')],
            ),
            BlockNode(
              tagName: 'p',
              children: [TextNode('Content Line 1')],
            ),
            BlockNode(
              tagName: 'p',
              children: [TextNode('Content Line 2')],
            ),
            BlockNode(
              tagName: 'p',
              children: [TextNode('Content Line 3')],
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        // Get initial height (collapsed)
        final initialHeight = tester.getSize(find.byType(AnimatedSize)).height;
        expect(initialHeight, equals(0.0)); // Should be collapsed

        // Tap to expand
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle(); // Complete animation

        // Final height should be greater than 0
        final finalHeight = tester.getSize(find.byType(AnimatedSize)).height;
        expect(finalHeight, greaterThan(0.0));
      });

      testWidgets('uses correct animation duration', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [TextNode('Content')],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        final animatedSize = tester.widget<AnimatedSize>(
          find.byType(AnimatedSize),
        );

        // Should use DesignTokens.durationMedium (300ms)
        expect(animatedSize.duration, equals(DesignTokens.durationMedium));
      });

      testWidgets('uses correct animation curve', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [TextNode('Content')],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        final animatedSize = tester.widget<AnimatedSize>(
          find.byType(AnimatedSize),
        );

        // Should use DesignTokens.curveStandard (Curves.easeInOut)
        expect(animatedSize.curve, equals(DesignTokens.curveStandard));
      });

      testWidgets('animation completes smoothly', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [
            BlockNode(
              tagName: 'summary',
              children: [TextNode('Summary')],
            ),
            TextNode('Content'),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        // Tap to expand
        await tester.tap(find.byType(InkWell));

        // Let animation complete
        await tester.pumpAndSettle();

        // Content should be fully visible
        expect(find.text('Content'), findsOneWidget);

        // Animation should have completed (pumpAndSettle ensures all animations are done)
        // Verify we can interact with the widget
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Content should be hidden again
        expect(find.text('Content'), findsNothing);
      });
    });

    group('Multiple Children', () {
      testWidgets('renders multiple content children', (tester) async {
        final detailsNode = DetailsNode(
          open: true,
          children: [
            BlockNode(
              tagName: 'summary',
              children: [TextNode('Summary')],
            ),
            TextNode('Line 1'),
            TextNode('Line 2'),
            TextNode('Line 3'),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        expect(find.text('Line 1'), findsOneWidget);
        expect(find.text('Line 2'), findsOneWidget);
        expect(find.text('Line 3'), findsOneWidget);
      });

      testWidgets('hides/shows all content children', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [
            BlockNode(
              tagName: 'summary',
              children: [TextNode('Summary')],
            ),
            TextNode('Line 1'),
            TextNode('Line 2'),
            TextNode('Line 3'),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        // Initially hidden
        expect(find.text('Line 1'), findsNothing);
        expect(find.text('Line 2'), findsNothing);
        expect(find.text('Line 3'), findsNothing);

        // Tap to expand
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // All visible
        expect(find.text('Line 1'), findsOneWidget);
        expect(find.text('Line 2'), findsOneWidget);
        expect(find.text('Line 3'), findsOneWidget);
      });
    });

    group('Styling', () {
      testWidgets('applies base style to summary', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [
            BlockNode(
              tagName: 'summary',
              children: [TextNode('Summary')],
            ),
          ],
        );

        const baseStyle = TextStyle(fontSize: 18, color: Colors.blue);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(
                detailsNode: detailsNode,
                baseStyle: baseStyle,
              ),
            ),
          ),
        );

        final textWidget = tester.widget<Text>(find.text('Summary'));
        expect(textWidget.style?.fontSize, equals(18));
        expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
      });

      testWidgets('applies base style to content', (tester) async {
        final detailsNode = DetailsNode(
          open: true,
          children: [
            BlockNode(
              tagName: 'summary',
              children: [TextNode('Summary')],
            ),
            TextNode('Content'),
          ],
        );

        const baseStyle = TextStyle(fontSize: 16, color: Colors.green);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(
                detailsNode: detailsNode,
                baseStyle: baseStyle,
              ),
            ),
          ),
        );

        final textWidget = tester.widget<Text>(find.text('Content'));
        expect(textWidget.style?.fontSize, equals(16));
        expect(textWidget.style?.color, equals(Colors.green));
      });

      testWidgets('summary is bold', (tester) async {
        final detailsNode = DetailsNode(
          open: false,
          children: [
            BlockNode(
              tagName: 'summary',
              children: [TextNode('Bold Summary')],
            ),
          ],
        );

        const baseStyle = TextStyle(fontSize: 14);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(
                detailsNode: detailsNode,
                baseStyle: baseStyle,
              ),
            ),
          ),
        );

        final textWidget = tester.widget<Text>(find.text('Bold Summary'));
        expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
      });

      testWidgets('content has left padding', (tester) async {
        final detailsNode = DetailsNode(
          open: true,
          children: [TextNode('Content')],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        // Content should be wrapped in Padding
        final padding = tester.widget<Padding>(
          find.descendant(
            of: find.byType(AnimatedSize),
            matching: find.byType(Padding),
          ).first,
        );

        expect(padding.padding, equals(const EdgeInsets.only(left: 24.0, top: 4.0, bottom: 4.0)));
      });
    });

    group('Integration', () {
      testWidgets('works in scrollable list', (tester) async {
        final detailsNodes = List.generate(
          5,
          (i) => DetailsNode(
            open: false,
            children: [
              BlockNode(
                tagName: 'summary',
                children: [TextNode('Item $i')],
              ),
              TextNode('Content $i'),
            ],
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: detailsNodes.length,
                itemBuilder: (context, index) {
                  return DetailsWidget(detailsNode: detailsNodes[index]);
                },
              ),
            ),
          ),
        );

        // All summaries visible
        for (int i = 0; i < 5; i++) {
          expect(find.text('Item $i'), findsOneWidget);
        }

        // Expand first item
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        expect(find.text('Content 0'), findsOneWidget);
      });

      testWidgets('nested text extraction works', (tester) async {
        final detailsNode = DetailsNode(
          open: true,
          children: [
            BlockNode(
              tagName: 'summary',
              children: [
                TextNode('Part 1 '),
                BlockNode(
                  tagName: 'strong',
                  children: [TextNode('Bold')],
                ),
                TextNode(' Part 2'),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DetailsWidget(detailsNode: detailsNode),
            ),
          ),
        );

        // Text extraction should concatenate all text nodes
        expect(find.text('Part 1 Bold Part 2'), findsOneWidget);
      });
    });
  });
}
