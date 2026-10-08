import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:hyper_render/src/widgets/virtualized_selection_overlay.dart';

void main() {
  group('Selection Anchor Builder', () {
    testWidgets('calls selectionAnchorBuilder for start and end anchors',
        (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [TextNode('Hello World Selection Anchor Test')]),
      ]);

      final key = GlobalKey<HyperSelectionOverlayState>();
      final capturedDetails = <HyperSelectionAnchorDetails>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperSelectionOverlay(
              key: key,
              document: doc,
              handleColor: Colors.deepPurple,
              selectionAnchorBuilder: (context, details) {
                capturedDetails.add(details);
                return Container(
                  key: ValueKey('anchor-${details.type.name}'),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: details.handleColor,
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // No handles initially without selection
      expect(find.byKey(const ValueKey('anchor-start')), findsNothing);
      expect(find.byKey(const ValueKey('anchor-end')), findsNothing);
      expect(capturedDetails, isEmpty);

      // Select all text
      key.currentState!.selectAll();
      await tester.pumpAndSettle();

      // Both custom anchors should now be built
      expect(find.byKey(const ValueKey('anchor-start')), findsOneWidget);
      expect(find.byKey(const ValueKey('anchor-end')), findsOneWidget);

      expect(capturedDetails.length, greaterThanOrEqualTo(2));
      final startDetails = capturedDetails
          .firstWhere((d) => d.type == HyperSelectionAnchorType.start);
      final endDetails = capturedDetails
          .firstWhere((d) => d.type == HyperSelectionAnchorType.end);

      expect(startDetails.isStart, isTrue);
      expect(startDetails.isEnd, isFalse);
      expect(startDetails.handleColor, equals(Colors.deepPurple));
      expect(startDetails.isDragging, isFalse);
      expect(startDetails.rect, isNotNull);
      expect(startDetails.anchorPoint, isNotNull);
      expect(startDetails.defaultHandle, isNotNull);

      expect(endDetails.isStart, isFalse);
      expect(endDetails.isEnd, isTrue);
      expect(endDetails.handleColor, equals(Colors.deepPurple));
      expect(endDetails.isDragging, isFalse);
      expect(endDetails.rect, isNotNull);
      expect(endDetails.anchorPoint, isNotNull);
      expect(endDetails.defaultHandle, isNotNull);
    });

    testWidgets('tracks isDragging state during pan gesture on custom anchor',
        (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(
            children: [TextNode('Sample text for dragging interaction test')]),
      ]);

      final key = GlobalKey<HyperSelectionOverlayState>();
      final isDraggingValues = <bool>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperSelectionOverlay(
              key: key,
              document: doc,
              selectionAnchorBuilder: (context, details) {
                if (details.isStart) {
                  isDraggingValues.add(details.isDragging);
                }
                return Container(
                  key: ValueKey('drag-anchor-${details.type.name}'),
                  width: 30,
                  height: 30,
                  color: details.isDragging ? Colors.red : Colors.blue,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      key.currentState!.selectAll();
      await tester.pumpAndSettle();

      expect(isDraggingValues.last, isFalse);

      final startAnchorFinder = find.byKey(const ValueKey('drag-anchor-start'));
      expect(startAnchorFinder, findsOneWidget);

      // Start drag gesture on start anchor and move past touch slop to trigger onPanStart
      final gesture =
          await tester.startGesture(tester.getCenter(startAnchorFinder));
      await tester.pump();
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();

      // While dragging, isDragging should have updated to true
      expect(isDraggingValues.contains(true), isTrue);

      // Finish drag
      await gesture.up();
      await tester.pumpAndSettle();

      // Once drag ends, isDragging should be false again
      expect(isDraggingValues.last, isFalse);
    });

    testWidgets('falls back to default teardrop handles when builder is null',
        (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [TextNode('Default Handle Fallback Test')]),
      ]);

      final key = GlobalKey<HyperSelectionOverlayState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperSelectionOverlay(
              key: key,
              document: doc,
              handleColor: Colors.teal,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      key.currentState!.selectAll();
      await tester.pumpAndSettle();

      // Custom anchors should not exist
      expect(find.byKey(const ValueKey('anchor-start')), findsNothing);

      // Default CustomPaint handles should be present
      final customPaints =
          tester.widgetList<CustomPaint>(find.byType(CustomPaint));
      final hasTeardropPainter = customPaints.any(
        (cp) => cp.painter is HyperTeardropHandlePainter,
      );
      expect(hasTeardropPainter, isTrue);
    });

    testWidgets(
        'HyperRenderWidgetSelectionExtension passes selectionAnchorBuilder',
        (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [TextNode('Extension Test Content')]),
      ]);

      var builderCalled = false;

      final widget = HyperRenderWidget(
        document: doc,
      ).withSelectionOverlay(
        selectionAnchorBuilder: (context, details) {
          builderCalled = true;
          return const SizedBox(
            key: ValueKey('ext-custom-anchor'),
            width: 20,
            height: 20,
          );
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final overlayState = tester.state<HyperSelectionOverlayState>(
          find.byType(HyperSelectionOverlay));
      overlayState.selectAll();
      await tester.pumpAndSettle();

      expect(builderCalled, isTrue);
      expect(find.byKey(const ValueKey('ext-custom-anchor')), findsNWidgets(2));
    });

    testWidgets('HyperViewer in sync mode passes selectionAnchorBuilder',
        (WidgetTester tester) async {
      var builderCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Testing HyperViewer custom anchors sync mode</p>',
              mode: HyperRenderMode.sync,
              selectable: true,
              selectionAnchorBuilder: (context, details) {
                builderCalled = true;
                return SizedBox(
                  key: ValueKey('viewer-sync-anchor-${details.type.name}'),
                  width: 24,
                  height: 24,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final overlayState = tester.state<HyperSelectionOverlayState>(
          find.byType(HyperSelectionOverlay));
      overlayState.selectAll();
      await tester.pumpAndSettle();

      expect(builderCalled, isTrue);
      expect(find.byKey(const ValueKey('viewer-sync-anchor-start')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('viewer-sync-anchor-end')), findsOneWidget);
    });

    testWidgets('HyperViewer.markdown passes selectionAnchorBuilder',
        (WidgetTester tester) async {
      var builderCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer.markdown(
              markdown:
                  '# Markdown Title\nMarkdown body text for anchor testing.',
              mode: HyperRenderMode.sync,
              selectable: true,
              selectionAnchorBuilder: (context, details) {
                builderCalled = true;
                return SizedBox(
                  key: ValueKey('viewer-md-anchor-${details.type.name}'),
                  width: 22,
                  height: 22,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final overlayState = tester.state<HyperSelectionOverlayState>(
          find.byType(HyperSelectionOverlay));
      overlayState.selectAll();
      await tester.pumpAndSettle();

      expect(builderCalled, isTrue);
      expect(
          find.byKey(const ValueKey('viewer-md-anchor-start')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('viewer-md-anchor-end')), findsOneWidget);
    });

    testWidgets('HyperViewer.fromNode passes selectionAnchorBuilder',
        (WidgetTester tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [TextNode('Prebuilt DocumentNode Anchor Test')]),
      ]);

      var builderCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer.fromNode(
              document: doc,
              selectable: true,
              selectionAnchorBuilder: (context, details) {
                builderCalled = true;
                return const SizedBox(
                  key: ValueKey('fromNode-anchor'),
                  width: 20,
                  height: 20,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final overlayState = tester.state<HyperSelectionOverlayState>(
          find.byType(HyperSelectionOverlay));
      overlayState.selectAll();
      await tester.pumpAndSettle();

      expect(builderCalled, isTrue);
      expect(find.byKey(const ValueKey('fromNode-anchor')), findsNWidgets(2));
    });

    testWidgets('HyperViewer in virtualized mode passes selectionAnchorBuilder',
        (WidgetTester tester) async {
      var builderCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Virtualized Chunk 1</p><p>Virtualized Chunk 2</p>',
              mode: HyperRenderMode.virtualized,
              renderConfig: const HyperRenderConfig(useMicrotaskParsing: true),
              selectable: true,
              selectionAnchorBuilder: (context, details) {
                builderCalled = true;
                return SizedBox(
                  key: ValueKey('viewer-vrt-anchor-${details.type.name}'),
                  width: 26,
                  height: 26,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(VirtualizedSelectionOverlay), findsOneWidget);

      final vrtOverlay = tester.widget<VirtualizedSelectionOverlay>(
          find.byType(VirtualizedSelectionOverlay));
      vrtOverlay.controller.selectAll();
      await tester.pumpAndSettle();

      expect(builderCalled, isTrue);
      expect(find.byKey(const ValueKey('viewer-vrt-anchor-start')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('viewer-vrt-anchor-end')), findsOneWidget);
    });
  });
}
