// Verifies the Performance tab of the Advanced Features showcase actually
// measures on-device instead of showing an empty, never-populated report list.
//
// The tab used to display "Target: <50ms" and a report section gated on
// `_performanceReports.isNotEmpty` — but nothing ever added to that list, so
// the reports never appeared and no measurement happened. It now has a
// "Measure …" button that times parse + style resolution with a real Stopwatch
// and records the result; this test drives that button and asserts a real
// report appears.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/v2_1_showcase.dart';

void main() {
  testWidgets('Performance tab records a real measurement when tapped',
      (tester) async {
    // Very tall viewport so the whole Performance tab is laid out without
    // needing to scroll a TabBarView-nested list (which also has a scrollable
    // TabBar, making a scrollUntilVisible target ambiguous).
    tester.view.physicalSize = const Size(1400, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: V21Showcase()));
    await tester.pump(const Duration(milliseconds: 100));

    // Switch to the Performance tab and let the TabBarView build it.
    await tester.tap(find.text('Performance'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // The perf tab is now active (its document-size dropdown is present) and no
    // measurement has been taken yet.
    expect(find.textContaining('Document Size:'), findsOneWidget);
    final measureBtn = find.byIcon(Icons.play_arrow);
    expect(measureBtn, findsOneWidget);
    expect(find.textContaining('Parse:'), findsNothing);

    // Measure — this runs a real Stopwatch over parse + style resolution.
    await tester.tap(measureBtn);
    await tester.pump(const Duration(milliseconds: 100));

    // A real report now appears with the measured phases + the honesty caveat.
    expect(find.textContaining('Parse:'), findsOneWidget);
    expect(find.textContaining('Style resolve:'), findsOneWidget);
    expect(find.textContaining('Layout & paint run asynchronously'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
