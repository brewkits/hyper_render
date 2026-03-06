import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('ErrorBoundaryNode', () {
    test('creates error boundary with required fields', () {
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      final node = ErrorBoundaryNode(
        error: error,
        stackTrace: stackTrace,
      );

      expect(node.type, equals(NodeType.errorBoundary));
      expect(node.tagName, equals('error-boundary'));
      expect(node.error, equals(error));
      expect(node.stackTrace, equals(stackTrace));
      expect(node.friendlyMessage, isNull);
      expect(node.originalContent, isNull);
    });

    test('creates error boundary with optional fields', () {
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      final node = ErrorBoundaryNode(
        error: error,
        stackTrace: stackTrace,
        friendlyMessage: 'Something went wrong',
        originalContent: '<div>Test</div>',
      );

      expect(node.friendlyMessage, equals('Something went wrong'));
      expect(node.originalContent, equals('<div>Test</div>'));
    });

    test('errorMessage returns error string', () {
      final error = Exception('Custom error message');
      final node = ErrorBoundaryNode(
        error: error,
        stackTrace: StackTrace.current,
      );

      expect(node.errorMessage, contains('Custom error message'));
    });

    test('errorMessage handles null error', () {
      final node = ErrorBoundaryNode(
        error: null,
        stackTrace: StackTrace.current,
      );

      expect(node.errorMessage, equals('Unknown error'));
    });

    test('shortStackTrace truncates long stack traces', () {
      // Create a stack trace with many lines
      final longStackTrace = StackTrace.fromString(
        List.generate(20, (i) => '#$i someFunction (file.dart:$i:1)')
            .join('\n'),
      );

      final node = ErrorBoundaryNode(
        error: Exception('Test'),
        stackTrace: longStackTrace,
      );

      final shortTrace = node.shortStackTrace;

      // Should only have first 5 lines + "... (X more lines)"
      expect(shortTrace, contains('#0'));
      expect(shortTrace, contains('#4'));
      expect(shortTrace, contains('(15 more lines)'));
      expect(shortTrace, isNot(contains('#10')));
    });

    test('shortStackTrace does not truncate short stack traces', () {
      final shortStackTrace = StackTrace.fromString(
        List.generate(3, (i) => '#$i someFunction (file.dart:$i:1)')
            .join('\n'),
      );

      final node = ErrorBoundaryNode(
        error: Exception('Test'),
        stackTrace: shortStackTrace,
      );

      final shortTrace = node.shortStackTrace;

      // Should include all lines, no truncation message
      expect(shortTrace, contains('#0'));
      expect(shortTrace, contains('#2'));
      expect(shortTrace, isNot(contains('more lines')));
    });

    test('toString includes error and message', () {
      final node = ErrorBoundaryNode(
        error: Exception('Test error'),
        stackTrace: StackTrace.current,
        friendlyMessage: 'Friendly message',
      );

      final string = node.toString();

      expect(string, contains('ErrorBoundaryNode'));
      expect(string, contains('Test error'));
      expect(string, contains('Friendly message'));
    });

    test('display style is block', () {
      final node = ErrorBoundaryNode(
        error: Exception('Test'),
        stackTrace: StackTrace.current,
      );

      expect(node.style.display, equals(DisplayType.block));
    });
  });

  group('ErrorBoundaryWidget', () {
    testWidgets('renders error message', (tester) async {
      final node = ErrorBoundaryNode(
        error: Exception('Test error'),
        stackTrace: StackTrace.current,
        friendlyMessage: 'Something went wrong',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundaryWidget(errorNode: node),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('uses default message when friendlyMessage is null',
        (tester) async {
      final node = ErrorBoundaryNode(
        error: Exception('Test error'),
        stackTrace: StackTrace.current,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundaryWidget(errorNode: node),
          ),
        ),
      );

      expect(find.text('An error occurred'), findsOneWidget);
    });

    testWidgets('shows/hides details on button tap', (tester) async {
      final node = ErrorBoundaryNode(
        error: Exception('Test error'),
        stackTrace: StackTrace.current,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundaryWidget(errorNode: node),
          ),
        ),
      );

      // Initially details are hidden
      expect(find.text('Show Details'), findsOneWidget);
      expect(find.text('Stack Trace:'), findsNothing);

      // Tap to show details
      await tester.tap(find.text('Show Details'));
      await tester.pumpAndSettle();

      expect(find.text('Hide Details'), findsOneWidget);
      expect(find.text('Stack Trace:'), findsOneWidget);

      // Tap to hide details
      await tester.tap(find.text('Hide Details'));
      await tester.pumpAndSettle();

      expect(find.text('Show Details'), findsOneWidget);
      expect(find.text('Stack Trace:'), findsNothing);
    });

    testWidgets('shows details initially when showDetailsInitially is true',
        (tester) async {
      final node = ErrorBoundaryNode(
        error: Exception('Test error'),
        stackTrace: StackTrace.current,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundaryWidget(
              errorNode: node,
              showDetailsInitially: true,
            ),
          ),
        ),
      );

      expect(find.text('Hide Details'), findsOneWidget);
      expect(find.text('Stack Trace:'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry is provided',
        (tester) async {
      bool retryPressed = false;

      final node = ErrorBoundaryNode(
        error: Exception('Test error'),
        stackTrace: StackTrace.current,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundaryWidget(
              errorNode: node,
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retryPressed, isTrue);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      final node = ErrorBoundaryNode(
        error: Exception('Test error'),
        stackTrace: StackTrace.current,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundaryWidget(errorNode: node),
          ),
        ),
      );

      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('shows original content when available', (tester) async {
      final node = ErrorBoundaryNode(
        error: Exception('Test error'),
        stackTrace: StackTrace.current,
        originalContent: '<div>Original HTML</div>',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundaryWidget(
              errorNode: node,
              showDetailsInitially: true,
            ),
          ),
        ),
      );

      expect(find.text('Original Content:'), findsOneWidget);
      expect(find.textContaining('Original HTML'), findsOneWidget);
    });

    testWidgets('copy button shows snackbar', (tester) async {
      final node = ErrorBoundaryNode(
        error: Exception('Test error'),
        stackTrace: StackTrace.current,
        friendlyMessage: 'Something went wrong',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBoundaryWidget(errorNode: node),
          ),
        ),
      );

      await tester.tap(find.text('Copy Error'));
      await tester.pump(); // Start clipboard
      await tester.pump(const Duration(milliseconds: 200)); // Wait for clipboard
      await tester.pump(); // Show snackbar
      await tester.pump(const Duration(milliseconds: 200)); // Animate snackbar

      expect(
        find.byType(SnackBar),
        findsOneWidget,
      );
      expect(
        find.text('Error details copied to clipboard'),
        findsOneWidget,
      );
    });

    testWidgets('adapts colors for dark mode', (tester) async {
      final node = ErrorBoundaryNode(
        error: Exception('Test error'),
        stackTrace: StackTrace.current,
      );

      // Test in dark mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ErrorBoundaryWidget(errorNode: node),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(ErrorBoundaryWidget), findsOneWidget);
    });
  });

  group('Integration with HyperRenderWidget', () {
    testWidgets('HyperRenderWidget renders ErrorBoundaryNode',
        (tester) async {
      final document = DocumentNode(children: [
        ErrorBoundaryNode(
          error: Exception('Parse error'),
          stackTrace: StackTrace.current,
          friendlyMessage: 'Failed to parse HTML',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperRenderWidget(document: document),
          ),
        ),
      );

      expect(find.text('Failed to parse HTML'), findsOneWidget);
      expect(find.byType(ErrorBoundaryWidget), findsOneWidget);
    });

    testWidgets('ErrorBoundaryNode within document tree', (tester) async {
      final semantics = tester.ensureSemantics();
      final document = DocumentNode(children: [
        BlockNode.h1(children: [TextNode('Title')]),
        ErrorBoundaryNode(
          error: Exception('Error in section'),
          stackTrace: StackTrace.current,
          friendlyMessage: 'Section failed to render',
        ),
        BlockNode.p(children: [TextNode('More content')]),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperRenderWidget(document: document),
          ),
        ),
      );

      // Should render normal content and error boundary
      // Note: Normal content is rendered by RenderHyperBox and exposed via semantics,
      // while ErrorBoundaryWidget uses a standard Text widget.
      expect(find.bySemanticsLabel(RegExp(r'Title')), findsOneWidget);
      expect(find.text('Section failed to render'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'More content')), findsOneWidget);
    });

    testWidgets('widgetBuilder can customize error boundary',
        (tester) async {
      final document = DocumentNode(children: [
        ErrorBoundaryNode(
          error: Exception('Custom error'),
          stackTrace: StackTrace.current,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperRenderWidget(
              document: document,
              widgetBuilder: (node) {
                if (node is ErrorBoundaryNode) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    child: const Text('Custom error widget'),
                  );
                }
                return null;
              },
            ),
          ),
        ),
      );

      expect(find.text('Custom error widget'), findsOneWidget);
      expect(find.byType(ErrorBoundaryWidget), findsNothing);
    });
  });
}
