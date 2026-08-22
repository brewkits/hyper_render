import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('HyperStreamingController Tests', () {
    test('initial state is idle and empty', () {
      final controller = HyperStreamingController();
      expect(controller.text, isEmpty);
      expect(controller.status, HyperStreamingStatus.idle);
      expect(controller.isStreaming, isFalse);
      expect(controller.isCompleted, isFalse);
      expect(controller.value.tokenCount, equals(0));
    });

    test('initial text constructor sets text and initial state', () {
      final controller = HyperStreamingController(initialText: 'Starting...');
      expect(controller.text, equals('Starting...'));
      expect(controller.status, HyperStreamingStatus.idle);
    });

    test(
        'append chunks updates text and status synchronously when throttle is zero',
        () {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);
      controller.append('Hello');
      expect(controller.text, equals('Hello'));
      expect(controller.status, HyperStreamingStatus.streaming);
      expect(controller.isStreaming, isTrue);

      controller.append(', World!');
      expect(controller.text, equals('Hello, World!'));
      expect(controller.value.tokenCount, equals(2));
    });

    test('complete() sets completed state and final text', () {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);
      controller.append('Done');
      controller.complete();

      expect(controller.status, HyperStreamingStatus.completed);
      expect(controller.isCompleted, isTrue);
      expect(controller.isStreaming, isFalse);
      expect(controller.value.completedAt, isNotNull);
      expect(controller.value.duration, isNotNull);
    });

    test('error() sets error state', () {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);
      controller.append('Partial');
      controller.error('Network timeout');

      expect(controller.status, HyperStreamingStatus.error);
      expect(controller.value.hasError, isTrue);
      expect(controller.value.error, equals('Network timeout'));
    });

    test('reset() clears buffer and returns to idle', () {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);
      controller.append('Test');
      controller.complete();
      expect(controller.isCompleted, isTrue);

      controller.reset();
      expect(controller.text, isEmpty);
      expect(controller.status, HyperStreamingStatus.idle);
      expect(controller.value.tokenCount, equals(0));
    });

    test('bindStream receives all stream tokens and completes', () async {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);
      final streamController = StreamController<String>();

      controller.bindStream(streamController.stream);

      streamController.add('Token 1 ');
      streamController.add('Token 2 ');
      streamController.add('Token 3');
      await streamController.close();

      // Wait for stream event loop
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.text, equals('Token 1 Token 2 Token 3'));
      expect(controller.status, HyperStreamingStatus.completed);
      expect(controller.value.tokenCount, equals(3));
    });
  });

  group('StreamSyntaxNormalizer Tests', () {
    test('auto-closes odd code block fences', () {
      const incomplete =
          'Here is code:\n```dart\nvoid main() {\n  print("Hi");\n}';
      final normalized = StreamSyntaxNormalizer.normalizeMarkdown(incomplete);
      expect(normalized.endsWith('```\n'), isTrue);
    });

    test('does not modify even closed code block fences', () {
      const complete = 'Here is code:\n```dart\nvoid main() {}\n```\n';
      final normalized = StreamSyntaxNormalizer.normalizeMarkdown(complete);
      expect(normalized, equals(complete));
    });

    test('auto-closes unclosed inline code backticks', () {
      const incomplete = 'Use the `HyperViewer';
      final normalized = StreamSyntaxNormalizer.normalizeMarkdown(incomplete);
      expect(normalized, equals('Use the `HyperViewer`'));
    });

    test('auto-closes unclosed bold asterisks', () {
      const incomplete = 'This is **very important';
      final normalized = StreamSyntaxNormalizer.normalizeMarkdown(incomplete);
      expect(normalized, equals('This is **very important**'));
    });

    test('auto-closes unclosed single asterisk italic', () {
      const incomplete = 'This is *italic';
      final normalized = StreamSyntaxNormalizer.normalizeMarkdown(incomplete);
      expect(normalized, equals('This is *italic*'));
    });

    test('auto-closes unclosed strikethrough', () {
      const incomplete = 'This is ~~deleted text';
      final normalized = StreamSyntaxNormalizer.normalizeMarkdown(incomplete);
      expect(normalized, equals('This is ~~deleted text~~'));
    });

    test('auto-closes incomplete markdown table rows', () {
      const incomplete =
          '| Header 1 | Header 2 |\n|---|---|\n| Cell 1 | Cell 2';
      final normalized = StreamSyntaxNormalizer.normalizeMarkdown(incomplete);
      expect(normalized.endsWith('|'), isTrue);
    });

    test('strips incomplete trailing HTML tag in progress', () {
      const incomplete = '<p>Hello</p><div class="ca';
      final normalized = StreamSyntaxNormalizer.normalizeHtml(incomplete);
      expect(normalized, equals('<p>Hello</p>'));
    });
  });

  group('HyperTypingCaret Widget Tests', () {
    testWidgets('renders bar style caret', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperTypingCaret(style: HyperTypingCaretStyle.bar),
          ),
        ),
      );

      expect(find.byType(HyperTypingCaret), findsOneWidget);
    });

    testWidgets('renders block style caret', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperTypingCaret(style: HyperTypingCaretStyle.block),
          ),
        ),
      );

      expect(find.byType(HyperTypingCaret), findsOneWidget);
    });

    testWidgets('renders custom builder caret', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperTypingCaret(
              style: HyperTypingCaretStyle.custom,
              customBuilder: (context, opacity) => Text('CURSOR ($opacity)'),
            ),
          ),
        ),
      );

      expect(find.textContaining('CURSOR'), findsOneWidget);
    });
  });
}
