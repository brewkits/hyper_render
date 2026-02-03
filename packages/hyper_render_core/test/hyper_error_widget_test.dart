import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('HyperErrorWidget', () {
    testWidgets('renders basic error widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperErrorWidget(
              message: 'Test error',
              icon: Icons.error,
            ),
          ),
        ),
      );

      expect(find.text('Test error'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      var retryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperErrorWidget(
              message: 'Test error',
              icon: Icons.error,
              onRetry: () => retryTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryTapped, isTrue);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperErrorWidget(
              message: 'Test error',
              icon: Icons.error,
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('uses custom retry label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperErrorWidget(
              message: 'Test error',
              icon: Icons.error,
              onRetry: () {},
              retryLabel: 'Try Again',
            ),
          ),
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('compact mode reduces sizes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperErrorWidget(
              message: 'Test error',
              icon: Icons.error,
              compact: true,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, equals(32.0));
    });

    testWidgets('normal mode uses larger sizes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperErrorWidget(
              message: 'Test error',
              icon: Icons.error,
              compact: false,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, equals(48.0));
    });

    testWidgets('respects width and height constraints', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperErrorWidget(
              message: 'Test error',
              icon: Icons.error,
              width: 200.0,
              height: 150.0,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(HyperErrorWidget),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints?.maxWidth, equals(200.0));
    });

    group('Named constructors', () {
      testWidgets('HyperErrorWidget.error uses error styling', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperErrorWidget.error(
                message: 'Error message',
              ),
            ),
          ),
        );

        expect(find.text('Error message'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('HyperErrorWidget.warning uses warning styling', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperErrorWidget.warning(
                message: 'Warning message',
              ),
            ),
          ),
        );

        expect(find.text('Warning message'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      });

      testWidgets('HyperErrorWidget.info uses info styling', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperErrorWidget.info(
                message: 'Info message',
              ),
            ),
          ),
        );

        expect(find.text('Info message'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('HyperErrorWidget.network uses network styling', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperErrorWidget.network(),
            ),
          ),
        );

        expect(find.text('Network error'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      });

      testWidgets('HyperErrorWidget.image shows image error', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperErrorWidget.image(),
            ),
          ),
        );

        expect(find.text('Failed to load image'), findsOneWidget);
        expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      });

      testWidgets('HyperErrorWidget.video shows video error', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperErrorWidget.video(),
            ),
          ),
        );

        expect(find.text('Failed to load video'), findsOneWidget);
        expect(find.byIcon(Icons.videocam_off_outlined), findsOneWidget);
      });

      testWidgets('named constructors accept custom messages', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperErrorWidget.image(
                message: 'Custom image error',
              ),
            ),
          ),
        );

        expect(find.text('Custom image error'), findsOneWidget);
        expect(find.text('Failed to load image'), findsNothing);
      });
    });

    group('Dark mode', () {
      testWidgets('adapts to dark theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: HyperErrorWidget.error(
                message: 'Error in dark mode',
              ),
            ),
          ),
        );

        expect(find.text('Error in dark mode'), findsOneWidget);
        // Widget should render without errors in dark mode
      });

      testWidgets('adapts to light theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(
              body: HyperErrorWidget.error(
                message: 'Error in light mode',
              ),
            ),
          ),
        );

        expect(find.text('Error in light mode'), findsOneWidget);
      });
    });

    group('Border control', () {
      testWidgets('shows border by default', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperErrorWidget(
                message: 'Test',
                icon: Icons.error,
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(HyperErrorWidget),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.border, isNotNull);
      });

      testWidgets('can hide border', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperErrorWidget(
                message: 'Test',
                icon: Icons.error,
                showBorder: false,
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(HyperErrorWidget),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.border, isNull);
      });
    });

    group('Text overflow', () {
      testWidgets('truncates long messages', (tester) async {
        const longMessage = 'This is a very long error message that should be truncated when it exceeds the maximum number of lines allowed for display in the error widget';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                child: HyperErrorWidget(
                  message: longMessage,
                  icon: Icons.error,
                ),
              ),
            ),
          ),
        );

        final text = tester.widget<Text>(find.text(longMessage));
        expect(text.overflow, equals(TextOverflow.ellipsis));
        expect(text.maxLines, equals(4));
      });

      testWidgets('compact mode has fewer max lines', (tester) async {
        const longMessage = 'Long message';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperErrorWidget(
                message: longMessage,
                icon: Icons.error,
                compact: true,
              ),
            ),
          ),
        );

        final text = tester.widget<Text>(find.text(longMessage));
        expect(text.maxLines, equals(2));
      });
    });
  });

  group('HyperErrorIndicator', () {
    testWidgets('renders compact error indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperErrorIndicator(
              message: 'Error',
              icon: Icons.error,
            ),
          ),
        ),
      );

      expect(find.text('Error'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('tappable when onTap provided', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperErrorIndicator(
              message: 'Error',
              icon: Icons.error,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(HyperErrorIndicator));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('not tappable when onTap is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperErrorIndicator(
              message: 'Error',
              icon: Icons.error,
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('uses small icon size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperErrorIndicator(
              message: 'Error',
              icon: Icons.error,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, equals(16.0));
    });

    testWidgets('truncates long text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              child: HyperErrorIndicator(
                message: 'Very long error message that should be truncated',
                icon: Icons.error,
              ),
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(
        find.text('Very long error message that should be truncated'),
      );
      expect(text.maxLines, equals(1));
      expect(text.overflow, equals(TextOverflow.ellipsis));
    });

    group('Error types', () {
      testWidgets('error type uses error color', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperErrorIndicator(
                message: 'Error',
                type: HyperErrorType.error,
              ),
            ),
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(DesignTokens.errorColor));
      });

      testWidgets('warning type uses warning color', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperErrorIndicator(
                message: 'Warning',
                type: HyperErrorType.warning,
              ),
            ),
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(DesignTokens.warningColor));
      });

      testWidgets('info type uses info color', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HyperErrorIndicator(
                message: 'Info',
                type: HyperErrorType.info,
              ),
            ),
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(DesignTokens.infoColor));
      });

      testWidgets('adapts to dark mode', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: HyperErrorIndicator(
                message: 'Error',
                type: HyperErrorType.error,
              ),
            ),
          ),
        );

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, equals(DesignTokens.darkErrorColor));
      });
    });
  });

  group('Integration', () {
    testWidgets('error widget works in real layouts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                const Text('Header'),
                const HyperErrorWidget.image(
                  width: 300,
                  height: 200,
                ),
                const Text('Footer'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Failed to load image'), findsOneWidget);
      expect(find.text('Footer'), findsOneWidget);
    });

    testWidgets('multiple error widgets render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const HyperErrorWidget.error(message: 'Error 1'),
                const HyperErrorWidget.warning(message: 'Warning 1'),
                const HyperErrorWidget.info(message: 'Info 1'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Error 1'), findsOneWidget);
      expect(find.text('Warning 1'), findsOneWidget);
      expect(find.text('Info 1'), findsOneWidget);
    });

    testWidgets('works with theme changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: HyperErrorWidget.error(message: 'Test'),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);

      // Rebuild with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: HyperErrorWidget.error(message: 'Test'),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Test'), findsOneWidget);
    });
  });
}
