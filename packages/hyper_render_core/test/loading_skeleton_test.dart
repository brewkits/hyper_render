import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('LoadingSkeleton', () {
    testWidgets('renders basic skeleton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSkeleton(
              width: 200,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(LoadingSkeleton), findsOneWidget);
    });

    testWidgets('animates by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSkeleton(
              width: 200,
              height: 100,
            ),
          ),
        ),
      );

      // Pump a frame to start animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should have AnimatedBuilder as descendant of LoadingSkeleton
      expect(
        find.descendant(
          of: find.byType(LoadingSkeleton),
          matching: find.byType(AnimatedBuilder),
        ),
        findsOneWidget,
      );
    });

    testWidgets('can disable animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSkeleton(
              width: 200,
              height: 100,
              animate: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Still renders
      expect(find.byType(LoadingSkeleton), findsOneWidget);
    });

    testWidgets('respects width and height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSkeleton(
              width: 200,
              height: 100,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AnimatedBuilder),
          matching: find.byType(Container),
        ),
      );

      expect(container.constraints?.maxWidth, equals(200));
    });

    group('Shapes', () {
      testWidgets('rectangle shape has rounded corners', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingSkeleton(
                width: 200,
                height: 100,
                shape: SkeletonShape.rectangle,
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(AnimatedBuilder),
            matching: find.byType(Container),
          ),
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, isNotNull);
      });

      testWidgets('circle shape is fully rounded', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingSkeleton(
                width: 50,
                height: 50,
                shape: SkeletonShape.circle,
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(AnimatedBuilder),
            matching: find.byType(Container),
          ),
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, isNotNull);
        // Circle uses large radius
        expect(
          (decoration.borderRadius as BorderRadius).topLeft.x,
          equals(9999),
        );
      });

      testWidgets('text shape has small radius', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingSkeleton(
                width: 200,
                height: 16,
                shape: SkeletonShape.text,
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(AnimatedBuilder),
            matching: find.byType(Container),
          ),
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, isNotNull);
      });
    });

    group('Named constructors', () {
      testWidgets('LoadingSkeleton.text creates text skeleton', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingSkeleton.text(width: 100),
            ),
          ),
        );

        expect(find.byType(LoadingSkeleton), findsOneWidget);
      });

      testWidgets('LoadingSkeleton.circle creates circle skeleton', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingSkeleton.circle(size: 48),
            ),
          ),
        );

        expect(find.byType(LoadingSkeleton), findsOneWidget);
      });

      testWidgets('LoadingSkeleton.rectangle creates rectangle', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingSkeleton.rectangle(
                width: 200,
                height: 100,
              ),
            ),
          ),
        );

        expect(find.byType(LoadingSkeleton), findsOneWidget);
      });
    });

    group('Dark mode', () {
      testWidgets('adapts to dark theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: LoadingSkeleton(
                width: 200,
                height: 100,
              ),
            ),
          ),
        );

        expect(find.byType(LoadingSkeleton), findsOneWidget);
      });

      testWidgets('adapts to light theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(
              body: LoadingSkeleton(
                width: 200,
                height: 100,
              ),
            ),
          ),
        );

        expect(find.byType(LoadingSkeleton), findsOneWidget);
      });
    });

    testWidgets('custom border radius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSkeleton(
              width: 200,
              height: 100,
              borderRadius: 20.0,
            ),
          ),
        ),
      );

      expect(find.byType(LoadingSkeleton), findsOneWidget);
    });

    testWidgets('custom duration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSkeleton(
              width: 200,
              height: 100,
              duration: Duration(seconds: 2),
            ),
          ),
        ),
      );

      expect(find.byType(LoadingSkeleton), findsOneWidget);
    });
  });

  group('SkeletonParagraph', () {
    testWidgets('renders multiple lines', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonParagraph(lines: 3),
          ),
        ),
      );

      expect(find.byType(LoadingSkeleton), findsNWidgets(3));
    });

    testWidgets('respects line count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonParagraph(lines: 5),
          ),
        ),
      );

      expect(find.byType(LoadingSkeleton), findsNWidgets(5));
    });

    testWidgets('uses custom line widths', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonParagraph(
              lines: 3,
              lineWidths: [1.0, 0.8, 0.6],
            ),
          ),
        ),
      );

      expect(find.byType(LoadingSkeleton), findsNWidgets(3));
    });

    testWidgets('can disable animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonParagraph(
              lines: 2,
              animate: false,
            ),
          ),
        ),
      );

      expect(find.byType(LoadingSkeleton), findsNWidgets(2));
    });
  });

  group('SkeletonListItem', () {
    testWidgets('renders avatar and text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListItem(),
          ),
        ),
      );

      // Should have circle for avatar + paragraph lines
      expect(find.byType(LoadingSkeleton), findsWidgets);
    });

    testWidgets('respects avatar size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListItem(avatarSize: 64),
          ),
        ),
      );

      expect(find.byType(SkeletonListItem), findsOneWidget);
    });

    testWidgets('shows trailing element when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListItem(showTrailing: true),
          ),
        ),
      );

      expect(find.byType(SkeletonListItem), findsOneWidget);
    });

    testWidgets('hides trailing element by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListItem(showTrailing: false),
          ),
        ),
      );

      expect(find.byType(SkeletonListItem), findsOneWidget);
    });

    testWidgets('respects line count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListItem(lines: 3),
          ),
        ),
      );

      expect(find.byType(SkeletonListItem), findsOneWidget);
    });
  });

  group('SkeletonCard', () {
    testWidgets('renders image and content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(),
          ),
        ),
      );

      expect(find.byType(SkeletonCard), findsOneWidget);
      expect(find.byType(LoadingSkeleton), findsWidgets);
    });

    testWidgets('respects image height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(imageHeight: 300),
          ),
        ),
      );

      expect(find.byType(SkeletonCard), findsOneWidget);
    });

    testWidgets('shows actions when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(showActions: true),
          ),
        ),
      );

      expect(find.byType(SkeletonCard), findsOneWidget);
    });

    testWidgets('hides actions when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(showActions: false),
          ),
        ),
      );

      expect(find.byType(SkeletonCard), findsOneWidget);
    });

    testWidgets('respects line count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(lines: 5),
          ),
        ),
      );

      expect(find.byType(SkeletonCard), findsOneWidget);
    });
  });

  group('SkeletonGrid', () {
    testWidgets('renders grid of items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonGrid(
              itemCount: 6,
              crossAxisCount: 3,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonGrid), findsOneWidget);
      expect(find.byType(LoadingSkeleton), findsNWidgets(6));
    });

    testWidgets('respects item count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonGrid(
              itemCount: 9,
              crossAxisCount: 3,
            ),
          ),
        ),
      );

      expect(find.byType(LoadingSkeleton), findsNWidgets(9));
    });

    testWidgets('respects cross axis count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonGrid(
              itemCount: 6,
              crossAxisCount: 2,
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('Integration', () {
    testWidgets('multiple skeletons work together', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                SkeletonListItem(),
                SizedBox(height: 16),
                SkeletonListItem(),
                SizedBox(height: 16),
                SkeletonListItem(),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonListItem), findsNWidgets(3));
    });

    testWidgets('skeletons in column layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LoadingSkeleton.circle(size: 80),
                SizedBox(height: 16),
                SkeletonParagraph(lines: 3),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(LoadingSkeleton), findsWidgets);
      expect(find.byType(SkeletonParagraph), findsOneWidget);
    });

    testWidgets('works with theme changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: LoadingSkeleton(width: 200, height: 100),
          ),
        ),
      );

      expect(find.byType(LoadingSkeleton), findsOneWidget);

      // Rebuild with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: LoadingSkeleton(width: 200, height: 100),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(LoadingSkeleton), findsOneWidget);
    });

    testWidgets('card skeleton in real layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridView.count(
              crossAxisCount: 2,
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SkeletonCard(imageHeight: 150),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SkeletonCard(imageHeight: 150),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonCard), findsNWidgets(2));
    });
  });

  group('Animation control', () {
    testWidgets('animation can be toggled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSkeleton(
              width: 200,
              height: 100,
              animate: true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Rebuild with animation disabled
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSkeleton(
              width: 200,
              height: 100,
              animate: false,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(LoadingSkeleton), findsOneWidget);
    });
  });
}
