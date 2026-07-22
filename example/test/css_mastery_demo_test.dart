// Functional test for the CSS Mastery demo screen.
//
// Each panel there is interactive, and every property it drives was previously
// "parsed but not executed" — so a test that only mounts the screen would miss
// the thing the demo exists to show. This drives the actual controls and
// asserts the RENDERED geometry changes in response, which is the same
// parse⇒render standard the library's own test suite holds itself to.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/css_mastery_demo.dart';
import 'package:hyper_render/hyper_render.dart';

/// Height of the HyperViewer inside the panel whose title is [panelTitle].
double _viewerHeightUnder(WidgetTester tester, String panelTitle) {
  final card = find.ancestor(
    of: find.text(panelTitle),
    matching: find.byType(Card),
  );
  final viewer = find.descendant(of: card, matching: find.byType(HyperViewer));
  return tester.getSize(viewer.first).height;
}

double _viewerWidthUnder(WidgetTester tester, String panelTitle) {
  final card = find.ancestor(
    of: find.text(panelTitle),
    matching: find.byType(Card),
  );
  final viewer = find.descendant(of: card, matching: find.byType(HyperViewer));
  return tester.getSize(viewer.first).width;
}

Future<void> _pumpDemo(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: CssMasteryDemo()));
  // NOT pumpAndSettle: the animation panel runs an `infinite` @keyframes
  // animation, so the frame loop never goes quiet and pumpAndSettle would
  // time out. Fixed-duration pumps are the correct tool here.
  await _frames(tester);
}

/// Advances a few frames deterministically (see [_pumpDemo]).
Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 32));
  await tester.pump(const Duration(milliseconds: 32));
}

void main() {
  testWidgets('renders every panel without exceptions', (tester) async {
    await _pumpDemo(tester);

    expect(find.text('CSS Mastery'), findsOneWidget);

    // The panels live in a ListView, so the ones below the fold are not built
    // yet — scroll each into view rather than assuming it is already mounted.
    for (final title in const [
      'border-collapse & border-spacing',
      'text-align (incl. justify) & text-indent',
      'width / min-width / max-width — px and %',
      'System text scaling — WCAG 2.1 AA §1.4.4',
      'animation-play-state',
      'text-align on a right-to-left tree',
      '<ol start="N">',
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(title), findsOneWidget, reason: 'missing panel: $title');
    }

    // Drive animation frames — the animation panel loops infinitely.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching to border-collapse:collapse shrinks the table',
      (tester) async {
    await _pumpDemo(tester);
    const panel = 'border-collapse & border-spacing';

    // Starts in `separate` with an 8px gap.
    final separateHeight = _viewerHeightUnder(tester, panel);

    await tester.tap(find.text('collapse'));
    await _frames(tester);
    final collapseHeight = _viewerHeightUnder(tester, panel);

    // Separate mode reserves a real gap around and between every cell, so the
    // table is strictly taller than the merged-border rendering.
    expect(separateHeight, greaterThan(collapseHeight));
    expect(tester.takeException(), isNull);
  });

  testWidgets('text-align and text-indent controls re-render', (tester) async {
    await _pumpDemo(tester);

    // Starts on `justify`; switching alignment must not throw and must keep
    // the paragraph laid out.
    await tester.tap(find.text('left'));
    await _frames(tester);
    await tester.tap(find.text('center'));
    await _frames(tester);

    expect(
        find.text('text-align (incl. justify) & text-indent'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('raising textScaler makes the scaled text taller',
      (tester) async {
    await _pumpDemo(tester);
    const panel = 'System text scaling — WCAG 2.1 AA §1.4.4';

    final atDefault = _viewerHeightUnder(tester, panel);

    // Drag the scaler slider to its maximum.
    final card = find.ancestor(
      of: find.text(panel),
      matching: find.byType(Card),
    );
    final slider = find.descendant(of: card, matching: find.byType(Slider));
    await tester.drag(slider, const Offset(500, 0));
    await _frames(tester);

    final scaledUp = _viewerHeightUnder(tester, panel);
    expect(scaledUp, greaterThan(atDefault),
        reason: 'text must actually grow with the system text scaler '
            '(WCAG 1.4.4), not just report a larger setting');
    expect(tester.takeException(), isNull);
  });

  testWidgets('pausing the animation keeps the panel stable', (tester) async {
    await _pumpDemo(tester);

    await tester.tap(find.text('paused'));
    await _frames(tester);

    // A paused animation must hold its frame — pumping further frames should
    // neither throw nor keep scheduling work.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('max-width slider changes the constrained block', (tester) async {
    await _pumpDemo(tester);
    const panel = 'width / min-width / max-width — px and %';

    final before = _viewerHeightUnder(tester, panel);
    expect(_viewerWidthUnder(tester, panel), greaterThan(0));

    // Narrow max-width → the text rewraps onto more lines → taller block.
    final card = find.ancestor(
      of: find.text(panel),
      matching: find.byType(Card),
    );
    final maxWidthSlider =
        find.descendant(of: card, matching: find.byType(Slider)).first;
    await tester.drag(maxWidthSlider, const Offset(-500, 0));
    await _frames(tester);

    final narrowed = _viewerHeightUnder(tester, panel);
    expect(narrowed, greaterThan(before),
        reason: 'a narrower max-width must rewrap the text, not clip it');
    expect(tester.takeException(), isNull);
  });
}
