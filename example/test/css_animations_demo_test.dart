// Functional test for the CSS Animations demo screen.
//
// Mounts the demo (which now showcases cubic-bezier / steps timing and
// color/background-color keyframes) and pumps animation frames to confirm the
// screen renders and animates without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/css_animations_demo.dart';

void main() {
  testWidgets('CssAnimationsDemo renders and animates without exceptions',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CssAnimationsDemo()));

    // Title present.
    expect(find.text('CSS Animations Demo'), findsOneWidget);

    // Drive several animation frames across the infinite loops.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 1500));

    expect(tester.takeException(), isNull);
  });
}
