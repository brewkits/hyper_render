import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('HyperViewer.streaming Integration Tests', () {
    testWidgets('renders initial empty streaming container', (tester) async {
      final controller = HyperStreamingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer.streaming(
              streamingController: controller,
            ),
          ),
        ),
      );

      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('updates UI reactively as stream emits chunks', (tester) async {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer.streaming(
              streamingController: controller,
              contentType: HyperContentType.markdown,
            ),
          ),
        ),
      );

      controller.append('# Hello AI Stream\n\n');
      await tester.pump();
      expect(find.byType(HyperViewer), findsOneWidget);

      controller.append('This is a **streaming** test.');
      await tester.pump();
      expect(find.byType(HyperViewer), findsOneWidget);

      controller.complete();
      await tester.pump();
      expect(controller.isCompleted, isTrue);
    });

    testWidgets('auto-repairs incomplete syntax in-flight', (tester) async {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer.streaming(
              streamingController: controller,
              autoRepairSyntax: true,
              contentType: HyperContentType.markdown,
            ),
          ),
        ),
      );

      // Incomplete code fence
      controller.append(
          'Here is some code:\n```dart\nvoid main() {\n  print("Hello");');
      await tester.pump();

      // Ensure no crash or exception occurred during intermediate AST parse
      expect(find.byType(HyperViewer), findsOneWidget);

      // Complete the fence
      controller.append('\n}\n```\nDone!');
      controller.complete();
      await tester.pump();

      expect(controller.isCompleted, isTrue);
    });

    testWidgets('displays typing caret while streaming is active',
        (tester) async {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer.streaming(
              streamingController: controller,
              showTypingCaret: true,
              caretStyle: HyperTypingCaretStyle.bar,
            ),
          ),
        ),
      );

      controller.append('Streaming in progress...');
      await tester.pump();

      expect(find.byType(HyperTypingCaret), findsOneWidget);

      controller.complete();
      await tester.pump();

      // Caret disappears on completion
      expect(find.byType(HyperTypingCaret), findsNothing);
    });

    testWidgets(
        'autoScrollToBottom works seamlessly without external controller',
        (tester) async {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: HyperViewer.streaming(
                streamingController: controller,
                autoScrollToBottom: true,
                contentType: HyperContentType.markdown,
              ),
            ),
          ),
        ),
      );

      // Append large content that causes overflow
      for (var i = 0; i < 20; i++) {
        controller
            .append('Paragraph $i with enough text to overflow viewport.\n\n');
        await tester.pump();
      }

      controller.complete();
      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });
}
