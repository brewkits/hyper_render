// Tests the side-by-side mode of the Library Comparison demo.
//
// The comparison is the app's strongest positioning asset: it renders the SAME
// HTML through HyperRender and through a rival at the same time. With the old
// tabs-only layout the user had to switch back and forth and remember the
// previous rendering to notice a difference; side-by-side makes it immediate.
// These tests assert both renderers are actually mounted together and that the
// controls switch rival / view mode.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' as fwfh;
import 'package:hyper_render/hyper_render.dart';
import 'package:example/main.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: LibraryComparisonDemo()));
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('opens side-by-side with BOTH renderers mounted at once',
      (tester) async {
    await _pump(tester);

    // Split view is the default — this is the whole point of the screen.
    expect(find.text('Side by side'), findsOneWidget);
    // Both libraries render the same document simultaneously.
    expect(find.byType(HyperViewer), findsOneWidget);
    expect(find.byType(flutter_html.Html), findsOneWidget);
    // Column headers name what the user is looking at.
    expect(find.text('HyperRender'), findsWidgets);
    expect(find.text('flutter_html'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching the rival swaps the right-hand column',
      (tester) async {
    await _pump(tester);
    expect(find.byType(flutter_html.Html), findsOneWidget);

    // Pick fwfh as the rival.
    await tester.tap(find.text('vs flutter_html'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('vs fwfh').last);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(fwfh.HtmlWidget), findsOneWidget);
    expect(find.byType(flutter_html.Html), findsNothing);
    // HyperRender stays put on the left.
    expect(find.byType(HyperViewer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tabs mode shows one library at a time', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Tabs'));
    await tester.pump(const Duration(milliseconds: 300));

    // Back to a single rendering: the rival column is gone.
    expect(find.byType(HyperViewer), findsOneWidget);
    expect(find.byType(flutter_html.Html), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
