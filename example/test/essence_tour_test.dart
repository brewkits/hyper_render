// Tests the guided "why HyperRender" tour.
//
// The tour's value is that every step DEMONSTRATES its claim with a live
// rendering instead of asserting it in prose, so the tests check that each
// step actually mounts a renderer and that navigation walks all seven steps.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:example/essence_tour_demo.dart';

/// Drives a PageView transition to completion: the scroll animation needs
/// several frames before `onPageChanged` fires and the counter updates.
Future<void> _settlePage(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: EssenceTourDemo()));
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('opens on step 1 with a live rendering, not just prose',
      (tester) async {
    await _pump(tester);

    expect(find.text('1 / 7'), findsOneWidget);
    expect(find.textContaining('CSS float'), findsWidgets);
    // The step's claim is shown, and the markup is actually rendered.
    expect(find.textContaining('neither implements float'), findsOneWidget);
    expect(find.byType(HyperViewer), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Next walks through every step, each rendering its own markup',
      (tester) async {
    await _pump(tester);

    for (var step = 1; step < 7; step++) {
      await tester.tap(find.text('Next'));
      await _settlePage(tester);
      expect(find.text('${step + 1} / 7'), findsOneWidget,
          reason: 'should be on step ${step + 1}');
      // Every step demonstrates itself with a real rendering. (PageView keeps
      // neighbouring pages alive, so more than one viewer can be mounted.)
      expect(find.byType(HyperViewer), findsWidgets,
          reason: 'step ${step + 1} must render its markup');
      expect(tester.takeException(), isNull);
    }

    // The final step offers to leave rather than a dead "Next".
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('Back returns to the previous step', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Next'));
    await _settlePage(tester);
    expect(find.text('2 / 7'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await _settlePage(tester);
    expect(find.text('1 / 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
