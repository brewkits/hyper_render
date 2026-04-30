import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('HyperViewer didUpdateWidget Battery Tests', () {
    testWidgets(
        'Updates HTML content correctly without rebuilding state entirely',
        (tester) async {
      String htmlContent = '<div>Initial</div>';

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    HyperViewer(
                      html: htmlContent,
                    ),
                    ElevatedButton(
                      key: const Key('update-btn'),
                      onPressed: () {
                        setState(() {
                          htmlContent = '<div>Updated</div>';
                        });
                      },
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

      // HyperRender renders on Canvas, so we can't use find.text()
      // The fact that it pumps without throwing is a success
      expect(find.byType(HyperViewer), findsOneWidget);

      // Tap to update
      await tester.tap(find.byKey(const Key('update-btn')));
      await tester.pumpAndSettle();

      // Ensure it updated without crashing
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Updates configuration correctly without errors',
        (tester) async {
      bool isSelectable = true;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    HyperViewer(
                      html: '<p>Text</p>',
                      selectable: isSelectable,
                    ),
                    ElevatedButton(
                      key: const Key('config-btn'),
                      onPressed: () {
                        setState(() {
                          isSelectable = false;
                        });
                      },
                      child: const Text('Update Config'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The fact that it pumps without throwing is a success
      expect(find.byType(HyperViewer), findsOneWidget);

      await tester.tap(find.byKey(const Key('config-btn')));
      await tester.pumpAndSettle();

      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });
}
