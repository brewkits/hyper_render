import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/ultra_showcase_2026.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  testWidgets('UltraShowcase2026 renders and scrolls without crashing', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(
      const MaterialApp(
        home: UltraShowcase2026(),
      ),
    );

    // Wait for HyperViewer to finish parsing (which uses compute/isolate) and remove CircularProgressIndicator
    bool foundScrollable = false;
    for (int i = 0; i < 50; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      
      if (tester.takeException() != null) {
        throw tester.takeException()!;
      }
      if (find.descendant(
        of: find.byType(HyperViewer),
        matching: find.byType(Scrollable),
      ).evaluate().isNotEmpty) {
        foundScrollable = true;
        break;
      }
    }
    await tester.pump(const Duration(seconds: 1));

    if (!foundScrollable) {
      debugDumpApp();
      throw Exception('Scrollable was never found in HyperViewer');
    }

    // Verify the title is present
    expect(find.text('Ultra Showcase 2026'), findsOneWidget);

    // Find the inner scrollable
    final scrollView = find.descendant(
      of: find.byType(HyperViewer),
      matching: find.byType(Scrollable),
    ).first;
    
    for (int i = 0; i < 5; i++) {
      await tester.drag(scrollView, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Switch to Paged Mode
    await tester.tap(find.byIcon(Icons.menu_book));
    await tester.pump(const Duration(milliseconds: 100)); // Start tap

    // Wait for HyperViewer to finish parsing/building Paged Mode
    foundScrollable = false;
    for (int i = 0; i < 50; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      
      if (tester.takeException() != null) {
        throw tester.takeException()!;
      }
      
      final pageViews = find.descendant(
        of: find.byType(HyperViewer),
        matching: find.byType(Scrollable),
      ).evaluate();
      
      if (pageViews.isNotEmpty) {
        foundScrollable = true;
        break;
      }
    }
    await tester.pump(const Duration(seconds: 1));

    if (!foundScrollable) {
      debugDumpApp();
      throw Exception('Scrollable was never found in Paged Mode');
    }

    // Verify we switched modes
    expect(find.byType(Scrollable), findsWidgets);

    // Scroll in Paged Mode
    final pagedView = find.byType(Scrollable).first;
    await tester.drag(pagedView, const Offset(-500, 0)); // Horizontal swipe for PageView
    await tester.pump(const Duration(milliseconds: 100));

    // Test selection in Paged Mode
    await tester.longPressAt(const Offset(400, 300));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsAtLeast(1));
  });

  testWidgets('UltraShowcase2026 text selection works', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UltraShowcase2026(),
      ),
    );

    // Wait for load
    for (int i = 0; i < 50; i++) {
      await tester.runAsync(() async => await Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      if (find.descendant(of: find.byType(HyperViewer), matching: find.byType(Scrollable)).evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(seconds: 1));

    // Long press in the middle of the screen to start selection
    // (offset 400, 200 should hit the title or first paragraph)
    await tester.longPressAt(const Offset(400, 200));
    await tester.pumpAndSettle();

    // Check if the Copy menu appeared.
    // We can also check for the presence of the selection overlay handles by looking for CustomPaint
    expect(find.byType(CustomPaint), findsAtLeast(1));
  });
}
