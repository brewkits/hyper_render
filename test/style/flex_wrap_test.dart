import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

/// Regression tests for issue #15 — `display:flex; flex-wrap:wrap`.
///
/// Two distinct crashes are guarded here, because the first fix caused the
/// second:
///
///  1. Mapping a wrapping flex container to Flutter's `Wrap` while its items
///     were still wrapped in `FlexItemWidget` put `Expanded`/`Flexible`
///     (`FlexParentData`) under `WrapParentData` — the reported bug.
///  2. Replacing that with a `LayoutBuilder`-driven Column of Rows made every
///     wrapping container unable to answer intrinsic queries. CSS's default
///     `align-items: stretch` puts an `IntrinsicHeight` above every nested
///     flex container, so *nested* wrapping flex died on contact with a much
///     larger cascade than the original bug.
///
/// Both are now handled by `RenderFlexWrap`, a real render object.
///
/// The helpers below deliberately anchor on [FlexWrapItem] — the box the
/// render object actually sizes. An earlier version of this file matched
/// `SizedBox` instead, which silently returned the *test harness's* own
/// `SizedBox` whenever the item was not sized, so assertions could pass for
/// the wrong reason. `cardWidth returns the item box, not the harness box`
/// below is the negative control that pins this down.
void main() {
  Future<void> pumpHtml(
    WidgetTester tester,
    String html, {
    required double width,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: HyperViewer(html: html)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Unbounded height (the normal setting: a scroll view).
  Future<void> pumpScrolling(
    WidgetTester tester,
    String html, {
    required double width,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: width, child: HyperViewer(html: html)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Width of the flex item box that `RenderFlexWrap` sized for [text].
  double cardWidth(WidgetTester tester, String text) => tester
      .getSize(find
          .ancestor(of: find.text(text), matching: find.byType(FlexWrapItem))
          .first)
      .width;

  double cardTop(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  const cards = '''
<div style="display:flex;flex-wrap:wrap;gap:14px;">
  <div style="flex:1 1 220px;min-width:220px;">Card 1</div>
  <div style="flex:1 1 220px;min-width:220px;">Card 2</div>
  <div style="flex:1 1 220px;min-width:220px;">Card 3</div>
</div>''';

  group('issue #15 — flex-wrap:wrap with flex children', () {
    testWidgets('renders without a ParentDataWidget assertion', (tester) async {
      await pumpHtml(tester, cards, width: 500);
      expect(tester.takeException(), isNull);
    });

    testWidgets('never attaches Expanded/Flexible beneath a Wrap',
        (tester) async {
      await pumpHtml(tester, cards, width: 500);
      expect(
        find.descendant(of: find.byType(Wrap), matching: find.byType(Expanded)),
        findsNothing,
      );
      expect(
        find.descendant(of: find.byType(Wrap), matching: find.byType(Flexible)),
        findsNothing,
      );
    });

    testWidgets('wraps to a second row when space is insufficient',
        (tester) async {
      // 500px container, 220px basis, 14px gap → 220+14+220 = 454 fits two
      // cards; the third moves to a new row.
      await pumpHtml(tester, cards, width: 500);
      expect(tester.takeException(), isNull);
      expect(cardTop(tester, 'Card 1'), cardTop(tester, 'Card 2'));
      expect(cardTop(tester, 'Card 3'), greaterThan(cardTop(tester, 'Card 1')));
    });

    testWidgets('flex-grow distributes the free space on each row',
        (tester) async {
      await pumpHtml(tester, cards, width: 500);
      expect(tester.takeException(), isNull);
      // Row 1: (500 - 14) / 2 = 243 each. Row 2: card 3 grows to the full 500.
      expect(cardWidth(tester, 'Card 1'), closeTo(243, 0.5));
      expect(cardWidth(tester, 'Card 2'), closeTo(243, 0.5));
      expect(cardWidth(tester, 'Card 3'), closeTo(500, 0.5));
    });

    testWidgets('all three fit on one row when the container is wide',
        (tester) async {
      // 220*3 + 14*2 = 688 ≤ 800 → one row, each grows to (800-28)/3 = 257.33
      await pumpHtml(tester, cards, width: 800);
      expect(tester.takeException(), isNull);
      expect(cardTop(tester, 'Card 1'), cardTop(tester, 'Card 2'));
      expect(cardTop(tester, 'Card 2'), cardTop(tester, 'Card 3'));
      expect(cardWidth(tester, 'Card 1'), closeTo(772 / 3, 0.5));
    });

    testWidgets('min-width is respected when it exceeds the flex basis',
        (tester) async {
      const html = '''
<div style="display:flex;flex-wrap:wrap;">
  <div style="flex:0 0 50px;min-width:180px;">Wide</div>
  <div style="flex:0 0 50px;">Narrow</div>
</div>''';
      await pumpHtml(tester, html, width: 400);
      expect(tester.takeException(), isNull);
      expect(cardWidth(tester, 'Wide'), closeTo(180, 0.5));
      expect(cardWidth(tester, 'Narrow'), closeTo(50, 0.5));
    });

    testWidgets('bare `flex: 1` children share the row equally',
        (tester) async {
      // `flex: 1` is `1 1 0%` — the shorthand's implied basis is 0, not auto.
      const html = '''
<div style="display:flex;flex-wrap:wrap;">
  <div style="flex:1;">A</div>
  <div style="flex:1;">B</div>
</div>''';
      await pumpHtml(tester, html, width: 400);
      expect(tester.takeException(), isNull);
      expect(cardTop(tester, 'A'), cardTop(tester, 'B'));
      expect(cardWidth(tester, 'A'), closeTo(200, 0.5));
      expect(cardWidth(tester, 'B'), closeTo(200, 0.5));
    });

    testWidgets('mixed flex and non-flex children do not assert',
        (tester) async {
      const html = '''
<div style="display:flex;flex-wrap:wrap;gap:8px;">
  <div style="flex:1 1 100px;">Flexy</div>
  <div>Plain</div>
</div>''';
      await pumpHtml(tester, html, width: 400);
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(of: find.byType(Wrap), matching: find.byType(Expanded)),
        findsNothing,
      );
    });

    testWidgets('flex-direction:column + wrap falls back without asserting',
        (tester) async {
      const html = '''
<div style="display:flex;flex-direction:column;flex-wrap:wrap;gap:6px;">
  <div style="flex:1 1 40px;">Top</div>
  <div style="flex:1 1 40px;">Bottom</div>
</div>''';
      await pumpHtml(tester, html, width: 400);
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(of: find.byType(Wrap), matching: find.byType(Expanded)),
        findsNothing,
      );
    });

    testWidgets('wrap-reverse lays the runs out bottom-up', (tester) async {
      const html = '''
<div style="display:flex;flex-wrap:wrap-reverse;gap:10px;">
  <div style="flex:1 1 220px;min-width:220px;">One</div>
  <div style="flex:1 1 220px;min-width:220px;">Two</div>
  <div style="flex:1 1 220px;min-width:220px;">Three</div>
</div>''';
      await pumpHtml(tester, html, width: 500);
      expect(tester.takeException(), isNull);
      // "Three" is on the second run, which wrap-reverse puts on top.
      expect(cardTop(tester, 'Three'), lessThan(cardTop(tester, 'One')));
    });

    testWidgets('many wrapping cards render without cascading errors',
        (tester) async {
      final buf =
          StringBuffer('<div style="display:flex;flex-wrap:wrap;gap:14px;">');
      for (var i = 1; i <= 12; i++) {
        buf.write('<div style="flex:1 1 220px;min-width:220px;">Card $i</div>');
      }
      buf.write('</div>');
      await pumpHtml(tester, buf.toString(), width: 700);
      expect(tester.takeException(), isNull);
      expect(find.text('Card 12'), findsOneWidget);
    });
  });

  group('cross-axis alignment', () {
    testWidgets('align-self:stretch stays bounded under an unbounded height',
        (tester) async {
      const html = '''
<div style="display:flex;flex-wrap:wrap;gap:14px;">
  <div style="flex:1 1 220px;min-width:220px;align-self:stretch;">Tall</div>
  <div style="flex:1 1 220px;min-width:220px;">Short</div>
</div>''';
      await pumpScrolling(tester, html, width: 500);
      expect(tester.takeException(), isNull);
      expect(cardWidth(tester, 'Tall'), closeTo(243, 0.5));
    });

    testWidgets('align-items:stretch does not assert', (tester) async {
      const html = '''
<div style="display:flex;flex-wrap:wrap;align-items:stretch;gap:14px;">
  <div style="flex:1 1 220px;min-width:220px;">A</div>
  <div style="flex:1 1 220px;min-width:220px;">B</div>
</div>''';
      await pumpScrolling(tester, html, width: 500);
      expect(tester.takeException(), isNull);
    });

    testWidgets('align-items:baseline supplies a textBaseline to the Row',
        (tester) async {
      // CrossAxisAlignment.baseline without a textBaseline trips
      // "textBaseline is required if you specify the crossAxisAlignment with
      // CrossAxisAlignment.baseline".
      const html = '''
<div style="display:flex;flex-wrap:wrap;align-items:baseline;gap:14px;">
  <div style="flex:1 1 220px;min-width:220px;">A</div>
  <div style="flex:1 1 220px;min-width:220px;">B</div>
</div>''';
      await pumpScrolling(tester, html, width: 500);
      expect(tester.takeException(), isNull);
    });

    testWidgets('align-items:baseline does not assert on the nowrap path',
        (tester) async {
      const html = '''
<div style="display:flex;align-items:baseline;gap:14px;">
  <div style="flex:1 1 220px;">A</div>
  <div style="flex:1 1 220px;">B</div>
</div>''';
      await pumpScrolling(tester, html, width: 500);
      expect(tester.takeException(), isNull);
    });
  });

  group('nested wrapping flex (the LayoutBuilder-intrinsics regression)', () {
    // Every case here queries intrinsics across the wrapping container. A
    // LayoutBuilder-based implementation throws "LayoutBuilder does not
    // support returning intrinsic dimensions" plus ~34 cascading layout
    // errors on each of them.

    testWidgets('inside a nowrap flex with the default align-items:stretch',
        (tester) async {
      const html = '''
<div style="display:flex;align-items:stretch;">
  <div style="display:flex;flex-wrap:wrap;gap:10px;">
    <div style="flex:1 1 100px;">a</div>
    <div style="flex:1 1 100px;">b</div>
  </div>
  <div>side</div>
</div>''';
      await pumpScrolling(tester, html, width: 500);
      expect(tester.takeException(), isNull);
    });

    testWidgets('as an align-self:stretch item', (tester) async {
      const html = '''
<div style="display:flex;">
  <div style="align-self:stretch;display:flex;flex-wrap:wrap;">
    <div style="flex:1 1 100px;">a</div>
  </div>
</div>''';
      await pumpScrolling(tester, html, width: 500);
      expect(tester.takeException(), isNull);
    });

    testWidgets('wrapping flex directly inside wrapping flex', (tester) async {
      const html = '''
<div style="display:flex;flex-wrap:wrap;">
  <div style="flex:1 1 200px;display:flex;flex-wrap:wrap;">
    <div style="flex:1 1 90px;">x</div>
    <div style="flex:1 1 90px;">y</div>
  </div>
</div>''';
      await pumpScrolling(tester, html, width: 500);
      expect(tester.takeException(), isNull);
    });

    testWidgets('explicit align-items:flex-start also stays clean',
        (tester) async {
      // The falsification control: with stretch opted out there is no
      // IntrinsicHeight, so this shape survived even the broken build. It must
      // keep working, or a "fix" that only special-cases stretch would pass.
      const html = '''
<div style="display:flex;align-items:flex-start;">
  <div style="display:flex;flex-wrap:wrap;align-items:flex-start;gap:10px;">
    <div style="flex:1 1 100px;">a</div>
    <div style="flex:1 1 100px;">b</div>
  </div>
  <div>side</div>
</div>''';
      await pumpScrolling(tester, html, width: 500);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no IntrinsicHeight is introduced at all', (tester) async {
      // The old implementation added one IntrinsicHeight per flex line
      // (align-items defaults to stretch, so effectively always) — an extra
      // layout pass per row, and the thing that made the subtree
      // intrinsic-hostile in the first place.
      await pumpHtml(tester, cards, width: 500);
      expect(find.byType(IntrinsicHeight), findsNothing);
    });

    testWidgets('inside a table cell and a list item', (tester) async {
      const html = '''
<table><tr><td>
  <div style="display:flex;flex-wrap:wrap;gap:8px;">
    <div style="flex:1 1 120px;">t1</div><div style="flex:1 1 120px;">t2</div>
  </div>
</td></tr></table>
<ul><li>
  <div style="display:flex;flex-wrap:wrap;gap:8px;">
    <div style="flex:1 1 100px;">l1</div><div style="flex:1 1 100px;">l2</div>
  </div>
</li></ul>''';
      await pumpScrolling(tester, html, width: 500);
      expect(tester.takeException(), isNull);
    });

    testWidgets('under an unbounded main axis (horizontal scroll)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: HyperViewer(html: '''
<div style="display:flex;flex-wrap:wrap;gap:8px;">
  <div style="flex:1 1 100px;">u1</div><div style="flex:1 1 100px;">u2</div>
</div>'''),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('CSS sizing that used to be parsed but never applied', () {
    testWidgets('percentage flex-basis resolves against the container',
        (tester) async {
      const html = '''
<div style="display:flex;flex-wrap:wrap;">
  <div style="flex:0 0 50%;">H1</div>
  <div style="flex:0 0 50%;">H2</div>
</div>''';
      await pumpHtml(tester, html, width: 500);
      expect(tester.takeException(), isNull);
      expect(cardWidth(tester, 'H1'), closeTo(250, 0.5));
      expect(cardWidth(tester, 'H2'), closeTo(250, 0.5));
      expect(cardTop(tester, 'H1'), cardTop(tester, 'H2'));
    });

    testWidgets('min-width alone (no flex shorthand) is honoured',
        (tester) async {
      const html = '''
<div style="display:flex;flex-wrap:wrap;">
  <div style="min-width:300px;">MW</div>
</div>''';
      await pumpHtml(tester, html, width: 500);
      expect(tester.takeException(), isNull);
      expect(cardWidth(tester, 'MW'), closeTo(300, 0.5));
    });

    testWidgets('percentage min-width resolves against the container',
        (tester) async {
      const html = '''
<div style="display:flex;flex-wrap:wrap;">
  <div style="min-width:60%;">PM</div>
</div>''';
      await pumpHtml(tester, html, width: 500);
      expect(tester.takeException(), isNull);
      expect(cardWidth(tester, 'PM'), closeTo(300, 0.5));
    });

    testWidgets('max-width caps a grown item', (tester) async {
      const html = '''
<div style="display:flex;flex-wrap:wrap;">
  <div style="flex:1 1 100px;max-width:150px;">Cap</div>
</div>''';
      await pumpHtml(tester, html, width: 500);
      expect(tester.takeException(), isNull);
      expect(cardWidth(tester, 'Cap'), closeTo(150, 0.5));
    });

    testWidgets('an `&nbsp;`-only flex item is not swallowed', (tester) async {
      // Dart's String.trim() treats U+00A0 as whitespace; CSS Text Level 3
      // does not. Trimming with it deleted the item outright.
      const html = '''
<div style="display:flex;flex-wrap:wrap;">
  <div style="flex:1 1 100px;">&nbsp;</div>
  <div style="flex:1 1 100px;">B</div>
</div>''';
      await pumpHtml(tester, html, width: 400);
      expect(tester.takeException(), isNull);
      expect(find.byType(FlexWrapItem), findsNWidgets(2));
    });
  });

  group('auto basis (no flex-basis, no width)', () {
    // Every other test declares an explicit basis, so `_baseOf`'s fallback to
    // child.getMaxIntrinsicWidth — which also runs inside computeDryLayout and
    // the intrinsic getters — would otherwise be unexercised.

    testWidgets('sizes from max-content and does not assert', (tester) async {
      const html = '''
<div style="display:flex;flex-wrap:wrap;gap:8px;">
  <div style="flex-shrink:1;">short</div>
  <div style="flex-shrink:1;">a much longer item label</div>
</div>''';
      await pumpHtml(tester, html, width: 500);
      expect(tester.takeException(), isNull);
      expect(cardWidth(tester, 'short'),
          lessThan(cardWidth(tester, 'a much longer item label')));
    });

    testWidgets('survives an ancestor that forces intrinsics/dry layout',
        (tester) async {
      const html = '''
<div style="display:flex;align-items:stretch;">
  <div style="display:flex;flex-wrap:wrap;gap:8px;">
    <div style="flex-shrink:1;">auto one</div>
    <div style="flex-shrink:1;">auto two</div>
  </div>
  <div>side</div>
</div>''';
      await pumpScrolling(tester, html, width: 500);
      expect(tester.takeException(), isNull);
    });

    testWidgets('flex: 1 1 auto keeps an auto basis, unlike flex: 1',
        (tester) async {
      // `flex: 1` implies a 0% basis (items split evenly); the explicit
      // three-value `auto` form must not.
      const html = '''
<div style="display:flex;flex-wrap:wrap;">
  <div style="flex:1 1 auto;">tiny</div>
  <div style="flex:1 1 auto;">a longer label</div>
</div>''';
      await pumpHtml(tester, html, width: 500);
      expect(tester.takeException(), isNull);
      // Both fit on one line, so free space is split evenly on top of two
      // different bases — the wider base stays wider.
      expect(cardTop(tester, 'tiny'), cardTop(tester, 'a longer label'));
      expect(cardWidth(tester, 'tiny'),
          lessThan(cardWidth(tester, 'a longer label')));
    });
  });

  group('nowrap path is unaffected by the flex-basis shorthand change', () {
    // The resolver now sets flexBasisPercent = 0 for `flex: 1`. FlexItemWidget
    // reads only flexGrow/flexShrink/alignSelf, so nowrap geometry must be
    // byte-identical — but nothing asserted that before, so it could not tell
    // "unchanged" from "untested".

    testWidgets('flex: 1 siblings split a nowrap row evenly', (tester) async {
      const html = '''
<div style="display:flex;">
  <div style="flex:1;">N1</div>
  <div style="flex:1;">N2</div>
</div>''';
      await pumpHtml(tester, html, width: 400);
      expect(tester.takeException(), isNull);
      expect(tester.getTopLeft(find.text('N1')).dy,
          tester.getTopLeft(find.text('N2')).dy);
      // Expanded(flex: 1) each → the row splits in half.
      expect(tester.getTopLeft(find.text('N2')).dx, closeTo(200, 1.0));
    });

    testWidgets('unequal flex-grow still splits proportionally',
        (tester) async {
      const html = '''
<div style="display:flex;">
  <div style="flex:1;">P1</div>
  <div style="flex:3;">P2</div>
</div>''';
      await pumpHtml(tester, html, width: 400);
      expect(tester.takeException(), isNull);
      expect(tester.getTopLeft(find.text('P2')).dx, closeTo(100, 1.0));
    });
  });

  group('test-helper integrity', () {
    testWidgets('cardWidth returns the item box, not the harness box',
        (tester) async {
      // Negative control for the helper itself. A previous version matched
      // `SizedBox`, so when no per-item box existed it silently returned the
      // harness's SizedBox(width: 500) — and an assertion of "Card 3 == 500"
      // passed for entirely the wrong reason.
      await pumpHtml(tester, cards, width: 500);
      // Card 1 is 243 wide inside a 500-wide harness: the helper cannot be
      // reading the harness box.
      expect(cardWidth(tester, 'Card 1'), isNot(closeTo(500, 0.5)));
      expect(cardWidth(tester, 'Card 1'), closeTo(243, 0.5));
      // And it anchors on a box the render object owns.
      expect(find.byType(FlexWrapItem), findsNWidgets(3));
    });
  });
}
