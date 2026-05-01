import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('HyperViewer AnimatedSwitcher Layout Issue', () {
    testWidgets(
        'should not throw RenderBox was not laid out during content switch',
        (WidgetTester tester) async {
      const String initialHtml = '<h1>Loading...</h1>';
      const String loadedHtml =
          '<h1>Loaded Content</h1><p>This is some content that is a bit longer to simulate a real document.</p>';

      // A simple StatefulWidget to hold and change the HyperViewer's content
      await tester.pumpWidget(
        const MaterialApp(
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

      // HyperViewer renders text via TextPainter (custom RenderObject), not as
      // standard Text/RichText widgets, so find.text() cannot locate it.
      // The test verifies no layout exception is thrown during the content switch.

      // Confirm ElevatedButton is present (the widget tree is healthy)
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Trigger content change
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // If we reach here without a 'RenderBox was not laid out' exception
      // (or parentDataDirty semantics assertion), the test passes.
      expect(find.byType(ElevatedButton), findsOneWidget);
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
  State<_TestHyperViewerContainer> createState() =>
      _TestHyperViewerContainerState();
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
