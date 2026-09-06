import 'dart:async';
import 'package:fake_async/fake_async.dart';
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

    test('tokensPerSecond calculation works accurately', () {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);
      controller.append('Word 1 ');
      controller.append('Word 2 ');
      controller.append('Word 3');
      expect(controller.value.tokenCount, equals(3));
      expect(controller.tokensPerSecond, greaterThanOrEqualTo(0.0));
    });

    test('bindCustomStream maps custom object stream to string tokens',
        () async {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);
      final streamController = StreamController<Map<String, String>>();

      controller.bindCustomStream(
        streamController.stream,
        (map) => map['delta'] ?? '',
      );

      streamController.add({'delta': 'A '});
      streamController.add({'delta': 'B '});
      streamController.add({'delta': 'C'});
      await streamController.close();

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.text, equals('A B C'));
      expect(controller.isCompleted, isTrue);
    });

    test('pause and resume stream operations execute without error', () async {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);
      final streamController = StreamController<String>();

      controller.bindStream(streamController.stream);
      controller.pause();
      controller.resume();
      controller.cancel();
      await streamController.close();
    });

    test('append() after error() throws and leaves state unchanged', () {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);
      controller.append('Partial');
      controller.error('Network timeout');

      expect(() => controller.append('more'), throwsStateError);
      // The guard must reject before mutating anything.
      expect(controller.text, equals('Partial'));
      expect(controller.status, HyperStreamingStatus.error);
    });

    test('bindCustomStream funnels a throwing mapper into error()', () async {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);
      final streamController = StreamController<int>();

      controller.bindCustomStream(streamController.stream, (n) {
        if (n == 2) throw const FormatException('bad item');
        return 'n$n ';
      });

      streamController.add(1);
      streamController.add(2);
      await streamController.close();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Must not escape as an uncaught zone exception; must be routed to
      // error() instead, matching bindCustomStream's documented contract.
      expect(controller.status, HyperStreamingStatus.error);
      expect(controller.value.error, isA<FormatException>());
    });

    test(
        'a mapper failure after the controller already reached a terminal '
        'state does not overwrite that state', () async {
      final controller =
          HyperStreamingController(throttleDuration: Duration.zero);
      final streamController = StreamController<String>();
      var callCount = 0;

      controller.bindCustomStream(streamController.stream, (chunk) {
        callCount++;
        if (callCount == 1) {
          // Simulate some other code path completing the controller while
          // this bound stream is still emitting.
          controller.complete();
        }
        return chunk;
      });

      streamController.add('late');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // append() throws inside onData because the controller is already
      // completed; that must be swallowed, not funneled into error().
      expect(controller.status, HyperStreamingStatus.completed);
      expect(controller.value.error, isNull);
    });

    test('adaptive throttle backs off notification frequency for large buffers',
        () {
      fakeAsync((async) {
        var smallNotifications = 0;
        final small = HyperStreamingController();
        small.addListener(() => smallNotifications++);
        for (var i = 0; i < 50; i++) {
          small.append('x' * 20); // buffer stays well under 10,000 chars
          async.elapse(const Duration(milliseconds: 16));
        }

        var largeNotifications = 0;
        final large = HyperStreamingController(initialText: 'y' * 60000);
        large.addListener(() => largeNotifications++);
        for (var i = 0; i < 50; i++) {
          large.append('x' * 20); // buffer already past the 50,000 tier
          async.elapse(const Duration(milliseconds: 16));
        }

        expect(largeNotifications, lessThan(smallNotifications ~/ 2));
      });
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

    test('auto-closes unclosed LaTeX block math', () {
      const incomplete = r'Formula: $$ \frac{a}{b} + c';
      final normalized = StreamSyntaxNormalizer.normalizeMarkdown(incomplete);
      expect(normalized.endsWith('\$\$\n'), isTrue);
    });

    test('auto-closes unclosed inline LaTeX math', () {
      const incomplete = r'Formula: $x^2 + y^2';
      final normalized = StreamSyntaxNormalizer.normalizeMarkdown(incomplete);
      expect(normalized, equals(r'Formula: $x^2 + y^2$'));
    });

    test('auto-closes incomplete markdown links', () {
      const incomplete1 = '[HyperRender documentation';
      expect(StreamSyntaxNormalizer.normalizeMarkdown(incomplete1),
          equals('[HyperRender documentation]'));

      const incomplete2 = '[HyperRender](https://brewkits.dev';
      expect(StreamSyntaxNormalizer.normalizeMarkdown(incomplete2),
          equals('[HyperRender](https://brewkits.dev)'));
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

    test('preserves mathematical < comparison symbol in HTML text', () {
      const mathExpr = '<p>Formula: 5 < 10 and processing...</p>';
      final normalized = StreamSyntaxNormalizer.normalizeHtml(mathExpr);
      expect(normalized, equals(mathExpr));
    });

    test(
        'an odd asterisk inside an already-closed code fence does not '
        'corrupt later prose', () {
      const input = '```c\n'
          'int *ptr = &x;\n'
          '```\n'
          'Now the ordinary prose continues without any *asterisks* needed here.';
      expect(StreamSyntaxNormalizer.normalizeMarkdown(input), equals(input));
    });

    test(
        'an unmatched bracket inside an already-closed code fence does not '
        'append a stray link-repair character', () {
      const input = '```\n'
          'arr[0\n'
          '```\n'
          'Just normal prose without any links here.';
      expect(StreamSyntaxNormalizer.normalizeMarkdown(input), equals(input));
    });

    test(
        'closed-fence protection holds across successive growing-buffer '
        'ticks, while a genuine unclosed marker in the new tail is still '
        'repaired', () {
      // The fence body itself has one (odd) asterisk — must not combine
      // with the tail's own count.
      const fenced = '```c\nint *ptr = &x;\n```\n';
      const tick1 = '${fenced}The story continues with *incomplete';
      const tick2 = '${fenced}The story continues with *complete* text now.';

      expect(
          StreamSyntaxNormalizer.normalizeMarkdown(tick1), equals('$tick1*'));
      expect(StreamSyntaxNormalizer.normalizeMarkdown(tick2), equals(tick2));
    });

    test(
        'normalizeHtml is not fooled by a literal > inside a quoted '
        'attribute of a still-unterminated tag', () {
      const incomplete = '<p>Hello</p><div title="a>b';
      final normalized = StreamSyntaxNormalizer.normalizeHtml(incomplete);
      expect(normalized, equals('<p>Hello</p>'));
    });

    test(
        'normalizeHtml does not strip a complete tag with a quoted '
        'attribute', () {
      const complete = '<div class="foo bar" title="hello">Text';
      final normalized = StreamSyntaxNormalizer.normalizeHtml(complete);
      expect(normalized, equals(complete));
    });

    test('normalizeHtml quote-handling works with single quotes too', () {
      const incompleteSingle = "<p>Hello</p><div title='a>b";
      expect(StreamSyntaxNormalizer.normalizeHtml(incompleteSingle),
          equals('<p>Hello</p>'));

      const completeSingle = "<div class='foo bar' title='hello'>Text";
      expect(StreamSyntaxNormalizer.normalizeHtml(completeSingle),
          equals(completeSingle));
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
