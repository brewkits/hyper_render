// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

    testWidgets(
        'swapping streamingController re-parses immediately '
        '(bug: didUpdateWidget missed the swap)', (tester) async {
      final controllerA = HyperStreamingController(
          throttleDuration: Duration.zero, initialText: 'First message body');
      final controllerB = HyperStreamingController(
          throttleDuration: Duration.zero, initialText: 'Second message body');

      final handle = tester.ensureSemantics();

      Widget build(HyperStreamingController c) => MaterialApp(
            home: Scaffold(
              body: HyperViewer.streaming(
                streamingController: c,
                contentType: HyperContentType.markdown,
              ),
            ),
          );

      // FadeTransition excludes its child from the semantics tree while
      // opacity is 0 — settle past the 300ms fade before reading semantics.
      await tester.pumpWidget(build(controllerA));
      await tester.pump(const Duration(milliseconds: 350));
      expect(_collectSemanticLabels(tester),
          contains(contains('First message body')));

      await tester.pumpWidget(build(controllerB));
      await tester.pump(const Duration(milliseconds: 350));
      final labelsAfterSwap = _collectSemanticLabels(tester);
      expect(labelsAfterSwap, contains(contains('Second message body')));
      expect(labelsAfterSwap.any((l) => l.contains('First message body')),
          isFalse);
      handle.dispose();
    });

    testWidgets(
        'toggling autoRepairSyntax re-parses immediately without waiting '
        'for the next token (bug: didUpdateWidget missed it)', (tester) async {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);
      controller.append('Use the `HyperViewer');

      final handle = tester.ensureSemantics();

      Widget build(bool autoRepair) => MaterialApp(
            home: Scaffold(
              body: HyperViewer.streaming(
                streamingController: controller,
                contentType: HyperContentType.markdown,
                autoRepairSyntax: autoRepair,
              ),
            ),
          );

      await tester.pumpWidget(build(false));
      await tester.pump(const Duration(milliseconds: 350));
      expect(
          _collectSemanticLabels(tester).any((l) => l.contains('`')), isTrue);

      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 350));
      expect(
          _collectSemanticLabels(tester).any((l) => l.contains('`')), isFalse);
      handle.dispose();
    });

    testWidgets(
        'content fade does not restart on every streaming tick '
        '(bug: perpetual flicker)', (tester) async {
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

      final fadeFinder = find.descendant(
        of: find.byType(HyperViewer),
        matching: find.byType(FadeTransition),
      );

      controller.append('Hello ');
      await tester.pump();
      // Let the 300ms fade fully settle.
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.widget<FadeTransition>(fadeFinder).opacity.value, 1.0);

      // Rapid subsequent ticks, well inside the fade's own 300ms window,
      // must not restart it back toward 0.
      for (var i = 0; i < 5; i++) {
        controller.append('token$i ');
        await tester.pump(const Duration(milliseconds: 10));
        expect(tester.widget<FadeTransition>(fadeFinder).opacity.value, 1.0);
      }
    });

    testWidgets(
        'fallbackBuilder renders once streamed HTML becomes complex '
        '(bug: gate checked the always-empty widget.content)', (tester) async {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer.streaming(
              streamingController: controller,
              contentType: HyperContentType.html,
              fallbackBuilder: (context) => const Text('FALLBACK'),
            ),
          ),
        ),
      );

      expect(find.text('FALLBACK'), findsNothing);

      controller.append('<p>intro</p><canvas></canvas>');
      await tester.pump();

      expect(find.text('FALLBACK'), findsOneWidget);
    });

    testWidgets(
        'autoScrollToBottom attaches to the actual ListView in virtualized '
        'mode (bug: bound to the wrong scroll controller)', (tester) async {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: HyperViewer.streaming(
                streamingController: controller,
                mode: HyperRenderMode.virtualized,
                autoScrollToBottom: true,
                contentType: HyperContentType.markdown,
              ),
            ),
          ),
        ),
      );

      for (var i = 0; i < 30; i++) {
        controller.append(
            'Paragraph $i with enough text to overflow the viewport.\n\n');
        await tester.pump();
      }
      controller.complete();
      await tester.pumpAndSettle();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.controller, isNotNull);
      expect(listView.controller!.hasClients, isTrue);
    });

    testWidgets(
        'a code fence highlighted mid-stream never throws, including while '
        'the fence is still open and once StreamSyntaxNormalizer auto-closes '
        'it', (tester) async {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer.streaming(
              streamingController: controller,
              contentType: HyperContentType.markdown,
              codeHighlighter: const DefaultCodeHighlighter(),
            ),
          ),
        ),
      );

      // Each chunk leaves the ``` fence open (normalizeMarkdown auto-closes
      // it synthetically for that frame) until the final chunk actually
      // closes it — the highlighter must tolerate every intermediate state.
      const chunks = [
        '```dart\n',
        'void main() {\n',
        '  print("unterminated string',
        '");\n}\n',
        '```\n',
      ];
      for (final chunk in chunks) {
        controller.append(chunk);
        await tester.pump();
        expect(tester.takeException(), isNull);
      }

      controller.complete();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}

/// Flattens every [SemanticsNode] label in the current tree, mirroring the
/// helper in `accessibility_test.dart` — canvas-painted text has no `Text`
/// widget to query via `find.text`, so semantics is the only observable
/// surface for asserting on rendered content.
List<String> _collectSemanticLabels(WidgetTester tester) {
  final result = <String>[];
  void visit(SemanticsNode node) {
    result.add(node.getSemanticsData().label);
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
