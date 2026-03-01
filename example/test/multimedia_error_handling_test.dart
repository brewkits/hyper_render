import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import the helper functions from multimedia_example.dart
// Note: These would need to be extracted to a separate file in a real app

/// Validates if a URL is safe and well-formed
bool _isValidUrl(String? url) {
  if (url == null || url.isEmpty) return false;

  final uri = Uri.tryParse(url);
  if (uri == null) return false;

  // Must have a scheme (http, https, etc.)
  if (!uri.hasScheme) return false;

  // Must have a host
  if (uri.host.isEmpty) return false;

  return true;
}

/// Creates a beautiful error widget for failed media loading
Widget _buildMediaErrorWidget(String message, {String? details}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      border: Border.all(color: Colors.red.shade200),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            color: Colors.red.shade900,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        if (details != null) ...[
          const SizedBox(height: 4),
          Text(
            details,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    ),
  );
}

/// Safe widget builder wrapper with error handling
Widget? _safeWidgetBuilder(
  Widget? Function() builder, {
  required String context,
}) {
  try {
    return builder();
  } catch (e, stackTrace) {
    // Log error in debug mode
    assert(() {
      print('Error in $context: $e');
      print(stackTrace);
      return true;
    }());

    // Return error widget
    return _buildMediaErrorWidget(
      'Widget failed to load',
      details: 'Error in $context: ${e.toString()}',
    );
  }
}

void main() {
  group('URL Validation', () {
    test('validates correct HTTP URLs', () {
      expect(_isValidUrl('http://example.com'), isTrue);
      expect(_isValidUrl('http://example.com/path'), isTrue);
      expect(_isValidUrl('http://example.com:8080/path'), isTrue);
    });

    test('validates correct HTTPS URLs', () {
      expect(_isValidUrl('https://example.com'), isTrue);
      expect(_isValidUrl('https://www.example.com/page'), isTrue);
      expect(_isValidUrl('https://subdomain.example.com'), isTrue);
    });

    test('rejects null URLs', () {
      expect(_isValidUrl(null), isFalse);
    });

    test('rejects empty URLs', () {
      expect(_isValidUrl(''), isFalse);
      expect(_isValidUrl('   '), isFalse);
    });

    test('rejects URLs without scheme', () {
      expect(_isValidUrl('example.com'), isFalse);
      expect(_isValidUrl('www.example.com'), isFalse);
      expect(_isValidUrl('//example.com'), isFalse);
    });

    test('rejects malformed URLs', () {
      expect(_isValidUrl('not a url'), isFalse);
      expect(_isValidUrl('http://'), isFalse);
      expect(_isValidUrl('https://'), isFalse);
    });

    test('rejects URLs with invalid characters', () {
      expect(_isValidUrl('http://example .com'), isFalse);
      expect(_isValidUrl('http://example<>.com'), isFalse);
    });

    test('accepts data URLs', () {
      expect(_isValidUrl('data:text/plain;base64,SGVsbG8='), isTrue);
    });

    test('accepts file URLs', () {
      expect(_isValidUrl('file:///path/to/file'), isTrue);
    });
  });

  group('Error Widget', () {
    testWidgets('renders error message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _buildMediaErrorWidget('Test Error'),
          ),
        ),
      );

      expect(find.text('Test Error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders error message with details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _buildMediaErrorWidget(
              'Test Error',
              details: 'Additional details',
            ),
          ),
        ),
      );

      expect(find.text('Test Error'), findsOneWidget);
      expect(find.text('Additional details'), findsOneWidget);
    });

    testWidgets('does not show details when null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _buildMediaErrorWidget('Test Error'),
          ),
        ),
      );

      expect(find.text('Test Error'), findsOneWidget);
      // Should only have one Text widget (the message)
      expect(find.byType(Text), findsNWidgets(1));
    });
  });

  group('Safe Widget Builder', () {
    testWidgets('returns widget when no error', (tester) async {
      final widget = _safeWidgetBuilder(
        () => const Text('Success'),
        context: 'Test widget',
      );

      expect(widget, isA<Text>());
      expect((widget as Text).data, equals('Success'));
    });

    testWidgets('returns error widget when exception thrown', (tester) async {
      final widget = _safeWidgetBuilder(
        () => throw Exception('Test exception'),
        context: 'Test widget',
      );

      expect(widget, isA<Container>());

      // Verify error widget is rendered
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget!,
          ),
        ),
      );

      expect(find.text('Widget failed to load'), findsOneWidget);
      expect(find.textContaining('Test exception'), findsOneWidget);
    });

    testWidgets('handles null return', (tester) async {
      final widget = _safeWidgetBuilder(
        () => null,
        context: 'Test widget',
      );

      expect(widget, isNull);
    });

    testWidgets('includes context in error message', (tester) async {
      final widget = _safeWidgetBuilder(
        () => throw StateError('Bad state'),
        context: 'IFrame widget',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget!,
          ),
        ),
      );

      expect(find.textContaining('IFrame widget'), findsOneWidget);
    });

    test('catches different exception types', () {
      // ArgumentError
      var widget = _safeWidgetBuilder(
        () => throw ArgumentError('Invalid argument'),
        context: 'Test',
      );
      expect(widget, isNotNull);

      // StateError
      widget = _safeWidgetBuilder(
        () => throw StateError('Bad state'),
        context: 'Test',
      );
      expect(widget, isNotNull);

      // FormatException
      widget = _safeWidgetBuilder(
        () => throw const FormatException('Bad format'),
        context: 'Test',
      );
      expect(widget, isNotNull);

      // Generic Exception
      widget = _safeWidgetBuilder(
        () => throw Exception('Generic error'),
        context: 'Test',
      );
      expect(widget, isNotNull);
    });
  });

  group('Integration Scenarios', () {
    test('invalid iframe URL handling', () {
      // Simulate iframe widgetBuilder logic
      String? src = 'not a valid url';

      final widget = _safeWidgetBuilder(
        () {
          if (!_isValidUrl(src)) {
            return _buildMediaErrorWidget(
              'Invalid IFrame URL',
              details: 'Invalid URL: $src',
            );
          }
          return const Text('IFrame would load here');
        },
        context: 'IFrame widget',
      );

      expect(widget, isA<Container>()); // Error widget
    });

    test('null iframe src handling', () {
      String? src;

      final widget = _safeWidgetBuilder(
        () {
          if (!_isValidUrl(src)) {
            return _buildMediaErrorWidget(
              'Invalid IFrame URL',
              details: 'No src attribute provided',
            );
          }
          return const Text('IFrame would load here');
        },
        context: 'IFrame widget',
      );

      expect(widget, isA<Container>()); // Error widget
    });

    test('valid iframe URL handling', () {
      const src = 'https://www.youtube.com/embed/video123';

      final widget = _safeWidgetBuilder(
        () {
          if (!_isValidUrl(src)) {
            return _buildMediaErrorWidget('Invalid IFrame URL');
          }
          return const Text('IFrame: $src');
        },
        context: 'IFrame widget',
      );

      expect(widget, isA<Text>());
      expect((widget as Text).data, contains('youtube.com'));
    });

    test('missing chart data handling', () {
      String? dataStr;

      final widget = _safeWidgetBuilder(
        () {
          // ignore: unnecessary_null_comparison
          if (dataStr == null) {
            return _buildMediaErrorWidget(
              'Chart Data Missing',
              details: 'No data attribute provided',
            );
          }
          return const Text('Chart');
        },
        context: 'Chart widget',
      );

      expect(widget, isA<Container>()); // Error widget
    });

    test('invalid chart data format handling', () {
      const dataStr = 'not,valid,numbers,!@#';

      final widget = _safeWidgetBuilder(
        () {
          final data = dataStr
              .split(',')
              .map((e) => double.tryParse(e.trim()) ?? 0)
              .toList();

          // All parsed as 0 due to invalid format
          if (data.every((d) => d == 0)) {
            return _buildMediaErrorWidget(
              'Invalid Chart Data',
              details: dataStr,
            );
          }

          return Text('Chart: ${data.length} points');
        },
        context: 'Chart widget',
      );

      expect(widget, isA<Container>()); // Error widget
    });

    test('valid chart data handling', () {
      const dataStr = '10,20,30,40,50';

      final widget = _safeWidgetBuilder(
        () {
          final data = dataStr
              .split(',')
              .map((e) => double.tryParse(e.trim()) ?? 0)
              .toList();

          if (data.isEmpty || data.every((d) => d == 0)) {
            return _buildMediaErrorWidget('Invalid Chart Data');
          }

          return Text('Chart: ${data.length} points');
        },
        context: 'Chart widget',
      );

      expect(widget, isA<Text>());
      expect((widget as Text).data, equals('Chart: 5 points'));
    });
  });
}
