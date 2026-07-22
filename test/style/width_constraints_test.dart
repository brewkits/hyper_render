// Parse⇒render tests for block width constraints: min-width, and percentage
// width / max-width / text-indent. Absolute max-width already had coverage in
// max_width_test.dart; this file adds the constraints that were previously
// parsed-but-not-executed (min-width) or dropped (`%`).
//
// Per the project's anti-"parse-but-not-execute" rule, every assertion checks
// RENDERED output (height or fragment position), never just ComputedStyle.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

Future<double> _height(WidgetTester tester, String html,
    {double width = 400}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: SingleChildScrollView(child: HyperViewer(html: html)),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return tester.getSize(find.byType(HyperViewer)).height;
}

Future<List<double>> _lineLefts(WidgetTester tester, String html,
    {double width = 400}) async {
  final doc = HtmlAdapter().parse(html);
  StyleResolver().resolveStyles(doc);
  RenderHyperBox? box;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: HyperRenderWidget(
            document: doc,
            selectable: true,
            onRenderBoxReady: (b) => box = b,
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  box!.selectAll();
  final byLine = <double, double>{};
  for (final r in box!.getSelectionRects()) {
    if (!byLine.containsKey(r.top) || r.left < byLine[r.top]!) {
      byLine[r.top] = r.left;
    }
  }
  final entries = byLine.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((e) => e.value).toList();
}

const _long =
    'This is a fairly long line of text that would fit on one line normally '
    'but must wrap when constrained enough to matter here';

void main() {
  group('min-width (A1)', () {
    testWidgets('min-width wins over a narrower max-width', (tester) async {
      // max-width:80 alone wraps heavily; min-width:300 must override it
      // (CSS: min-width beats max-width), producing far fewer lines.
      final onlyMax =
          await _height(tester, '<div style="max-width: 80px;">$_long</div>');
      final minWins = await _height(tester,
          '<div style="max-width: 80px; min-width: 300px;">$_long</div>');
      expect(minWins, lessThan(onlyMax));
    });

    testWidgets('min-width wider than container is clamped (no crash)',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: HyperViewer(html: '<div style="min-width: 9999px;">x</div>'),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('percentage width / max-width (A4)', () {
    testWidgets('width:50% resolves to half the container', (tester) async {
      // width:50% of 400 == 200px; both should wrap identically.
      final pct =
          await _height(tester, '<div style="width: 50%;">$_long</div>');
      final abs =
          await _height(tester, '<div style="width: 200px;">$_long</div>');
      expect(pct, abs);
    });

    testWidgets('max-width:25% constrains a first block (no top margin)',
        (tester) async {
      // Regression guard: the block-start fragment that carries the constraint
      // is elided for a first no-margin block unless the width-constraint check
      // includes the percentage fields.
      final unconstrained = await _height(tester, '<div>$_long</div>');
      final constrained =
          await _height(tester, '<div style="max-width: 25%;">$_long</div>');
      expect(constrained, greaterThan(unconstrained));
    });

    testWidgets('nested %-width resolves against the parent, not the viewport',
        (tester) async {
      // Outer 50% of 400 = 200; inner 50% of 200 = 100.
      final nested = await _height(
        tester,
        '<div style="width: 50%;"><div style="width: 50%;">$_long</div></div>',
      );
      final direct =
          await _height(tester, '<div style="width: 100px;">$_long</div>');
      expect(nested, direct);
    });
  });

  group('percentage text-indent (A4)', () {
    testWidgets('text-indent:10% indents the first line by 10% of width',
        (tester) async {
      final xs =
          await _lineLefts(tester, '<p style="text-indent: 10%;">short</p>');
      // 10% of the ~400px content width ≈ 40px.
      expect(xs.first, closeTo(40, 5));
    });

    testWidgets('percentage indent only affects the first line',
        (tester) async {
      final xs = await _lineLefts(
        tester,
        '<p style="text-indent: 20%;">word1 word2 word3 word4 word5 word6</p>',
        width: 150,
      );
      expect(xs.length, greaterThan(1));
      expect(xs.first, greaterThan(15)); // 20% of 150 = 30
      expect(xs[1], closeTo(0, 2));
    });

    testWidgets('text-indent:% inherits to inline children', (tester) async {
      final xs = await _lineLefts(
          tester, '<p style="text-indent: 10%;"><b>bold</b> start</p>');
      expect(xs.first, closeTo(40, 5));
    });
  });

  // Degenerate geometry: a block whose own padding/margin is wider than the
  // viewport leaves NEGATIVE space for content. Combined with a width
  // constraint this used to reach `clamp(0.0, negativeAvail)` in
  // _performLineLayout, which throws ArgumentError (lowerLimit > upperLimit)
  // and crashes performLayout. Such CSS is common in the wild (email HTML,
  // fixed px padding on a narrow phone), so it must degrade, not crash.
  group('width constraints — degenerate/overflowing geometry', () {
    const overflowing = [
      '<div style="padding:300px;width:50%">Hello world</div>',
      '<div style="padding:300px;max-width:120px">Hello world</div>',
      '<div style="padding:300px;min-width:300px">Hello world</div>',
      '<div style="padding:300px;width:80px">Hello world</div>',
      '<div style="padding:150px;width:100%">Hello world</div>',
      // Nested: the OUTER block already exhausts the width, so the inner
      // block's own constraint resolves against a zero-width container.
      '<div style="padding:180px"><div style="width:50%">Nested</div></div>',
    ];

    for (final html in overflowing) {
      testWidgets('does not crash: ${html.substring(0, 40)}…', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // narrower than the padding above
              child: SingleChildScrollView(child: HyperViewer(html: html)),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('zero-width viewport with a width constraint is survivable',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 0,
            child: SingleChildScrollView(
              child: HyperViewer(html: '<div style="width:50%">x</div>'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
