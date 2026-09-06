import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

/// Regression tests for issue #15 — `display:flex; flex-wrap:wrap` with
/// children carrying a CSS `flex` shorthand used to emit
/// `Wrap → Expanded/Flexible`, which trips Flutter's
/// "Incorrect use of ParentDataWidget" assertion (`FlexParentData` applied to a
/// `RenderObject` set up for `WrapParentData`) and cascades into a broken
/// frame.
///
/// The tests assert geometry, not merely the absence of an exception: a
/// "doesn't throw" test passes happily while the cards are sized wrongly.
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

  /// Same, but with an unbounded height (the normal HyperViewer setting: a
  /// scroll view). Any `SizedBox(height: infinity)` from `align-self: stretch`
  /// must still be bounded by the layout, or `IntrinsicHeight` blows up.
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

  /// Width of the box that directly sizes the card containing [text].
  double cardWidth(WidgetTester tester, String text) {
    final box = find
        .ancestor(of: find.text(text), matching: find.byType(SizedBox))
        .first;
    return tester.getSize(box).width;
  }

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
      // 220*3 + 14*2 = 688 ≤ 800 → single row, each grows to (800-28)/3 = 257.33
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
      // `flex: 1` is `1 1 0%` — basis 0, so all items stay on one line and
      // split the container evenly.
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

    testWidgets('mixed flex and non-flex children fall back to Wrap safely',
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
      expect(
        find.descendant(of: find.byType(Wrap), matching: find.byType(Flexible)),
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

    testWidgets('wrap-reverse falls back to Wrap without asserting',
        (tester) async {
      const html = '''
<div style="display:flex;flex-wrap:wrap-reverse;gap:10px;">
  <div style="flex:1 1 220px;min-width:220px;">One</div>
  <div style="flex:1 1 220px;min-width:220px;">Two</div>
  <div style="flex:1 1 220px;min-width:220px;">Three</div>
</div>''';
      await pumpHtml(tester, html, width: 500);
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(of: find.byType(Wrap), matching: find.byType(Expanded)),
        findsNothing,
      );
      expect(
        find.descendant(of: find.byType(Wrap), matching: find.byType(Flexible)),
        findsNothing,
      );
    });

    testWidgets('align-self:stretch stays bounded under an unbounded height',
        (tester) async {
      // The wrapping-flex rows are wrapped in IntrinsicHeight so that
      // `align-self: stretch`'s SizedBox(height: infinity) has a finite bound
      // even when the viewer sits in a scroll view.
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
}
