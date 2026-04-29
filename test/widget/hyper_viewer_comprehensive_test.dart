import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('HyperViewer Comprehensive', () {
    testWidgets('HyperViewer.markdown constructor', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer.markdown(
              markdown: '# Title\n\nContent',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('HyperViewer.delta constructor', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer.delta(
              delta: '{"ops":[{"insert":"Hello\\n"}]}',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('HyperViewer with enableZoom', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Zoomable</p>',
              enableZoom: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('HyperViewer with custom scroll physics', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Scrollable</p>',
              physics: NeverScrollableScrollPhysics(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('HyperViewerController jumpToId', (WidgetTester tester) async {
      final controller = HyperViewerController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p id="top">Top</p><div style="height: 1000px"></div><p id="bottom">Bottom</p>',
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      controller.jumpToId('bottom');
      await tester.pumpAndSettle();
    });

    testWidgets('HyperViewer handles re-parsing when content changes', (WidgetTester tester) async {
      String htmlContent = '<p>Old</p>';
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    HyperViewer(html: htmlContent),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        htmlContent = '<p>New</p>';
                      }),
                      child: const Text('Update'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
    });

    testWidgets('HyperViewer handles config changes', (WidgetTester tester) async {
      HyperRenderConfig config = const HyperRenderConfig(imageCacheSize: 10);
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    HyperViewer(html: '<p>Text</p>', renderConfig: config),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        config = const HyperRenderConfig(imageCacheSize: 20);
                      }),
                      child: const Text('Change Config'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change Config'));
      await tester.pumpAndSettle();
    });
  });
}
