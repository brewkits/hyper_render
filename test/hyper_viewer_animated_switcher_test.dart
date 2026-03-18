
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('HyperViewer AnimatedSwitcher Layout Issue', () {
    testWidgets('should not throw RenderBox was not laid out during content switch', (WidgetTester tester) async {
      final String initialHtml = '<h1>Loading...</h1>';
      final String loadedHtml = '<h1>Loaded Content</h1><p>This is some content that is a bit longer to simulate a real document.</p>';

      // A simple StatefulWidget to hold and change the HyperViewer's content
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: _TestHyperViewerContainer(
                initialHtml: initialHtml,
                loadedHtml: loadedHtml,
              ),
            ),
          ),
        ),
      );

      // Initial state: loading content
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Loaded Content'), findsNothing);

      // Trigger content change
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // After content change: loaded content should be visible
      expect(find.text('Loading...'), findsNothing);
      expect(find.text('Loaded Content'), findsOneWidget);

      // No RenderBox was not laid out exception should be thrown
      // The test will fail if such an exception occurs before this point.
    });
  });
}

class _TestHyperViewerContainer extends StatefulWidget {
  final String initialHtml;
  final String loadedHtml;

  const _TestHyperViewerContainer({
    required this.initialHtml,
    required this.loadedHtml,
  });

  @override
  State<_TestHyperViewerContainer> createState() => _TestHyperViewerContainerState();
}

class _TestHyperViewerContainerState extends State<_TestHyperViewerContainer> {
  late String _currentHtml;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentHtml = widget.initialHtml;
  }

  void _loadContent() {
    setState(() {
      _isLoading = false;
      _currentHtml = widget.loadedHtml;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // HyperViewer inside Column (inside SingleChildScrollView) gets unbounded vertical constraints
        HyperViewer(
          key: ValueKey(_isLoading ? 'loading' : 'loaded'),
          html: _currentHtml,
          // Ensure auto mode for virtualization is possible
          mode: HyperRenderMode.auto,
          // Fix: Use shrinkWrap to prevent unbounded height error inside SingleChildScrollView
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Placeholder builder to show the loading indicator
          placeholderBuilder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? _loadContent : null,
          child: const Text('Load Content'),
        ),
      ],
    );
  }
}
