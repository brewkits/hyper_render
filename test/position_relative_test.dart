// CSS `position: relative`, measured through real geometry: fragment offsets,
// sibling positions, painted pixels, and hit-testing at the moved location.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

import 'support/geometry_probe.dart';

const _rel = 'position:relative;';

/// How far [text] moved between [plain] and [moved] (both full HTML documents).
Future<Offset> _shift(
  WidgetTester tester,
  String plain,
  String moved,
  String text,
) async {
  await pumpHtml(tester, plain);
  final before = fragmentTopLeft(tester, text);
  await pumpHtml(tester, moved);
  return fragmentTopLeft(tester, text) - before;
}

/// Shift of a block's text given its inline [style].
Future<Offset> _blockShift(WidgetTester tester, String style) => _shift(
      tester,
      '<p>Z</p><div>AAA</div>',
      '<p>Z</p><div style="$style">AAA</div>',
      'AAA',
    );

void main() {
  group('offsets', () {
    testWidgets('a block moves by top and left', (tester) async {
      expect(await _blockShift(tester, '${_rel}top:30px;left:20px'),
          const Offset(20, 30));
    });

    testWidgets('an inline span moves by top and left', (tester) async {
      expect(
        await _shift(
          tester,
          '<p>XX<span>AAA</span>YY</p>',
          '<p>XX<span style="${_rel}top:30px;left:20px">AAA</span>YY</p>',
          'AAA',
        ),
        const Offset(20, 30),
      );
    });

    testWidgets('bottom and right move the opposite way', (tester) async {
      expect(await _blockShift(tester, '${_rel}bottom:10px;right:5px'),
          const Offset(-5, -10));
    });

    testWidgets('negative offsets', (tester) async {
      expect(await _blockShift(tester, '${_rel}top:-10px;left:-5px'),
          const Offset(-5, -10));
    });

    testWidgets('top wins over bottom, left wins over right', (tester) async {
      expect(
        await _blockShift(
            tester, '${_rel}top:30px;bottom:9px;left:20px;right:9px'),
        const Offset(20, 30),
      );
    });

    testWidgets('em, rem and pt lengths resolve', (tester) async {
      expect(
          await _blockShift(tester, '${_rel}left:1rem'), const Offset(16, 0));
      expect(await _blockShift(tester, '${_rel}left:1em'), const Offset(16, 0));
    });

    testWidgets('auto, percentages and garbage do not move it', (tester) async {
      expect(
          await _blockShift(tester, '${_rel}top:auto;left:auto'), Offset.zero);
      expect(await _blockShift(tester, '${_rel}top:10%;left:10%'), Offset.zero);
      expect(await _blockShift(tester, '${_rel}top:banana'), Offset.zero);
    });

    testWidgets('a later top:auto cancels an earlier top', (tester) async {
      expect(
          await _blockShift(tester, '${_rel}top:30px;top:auto'), Offset.zero);
    });

    testWidgets('it applies through a stylesheet', (tester) async {
      expect(
        await _shift(
          tester,
          '<p>Z</p><div class="r">AAA</div>',
          '<style>.r{position:relative;top:30px}</style>'
              '<p>Z</p><div class="r">AAA</div>',
          'AAA',
        ),
        const Offset(0, 30),
      );
    });

    for (final position in ['static', 'absolute', 'fixed', 'sticky']) {
      testWidgets('position:$position ignores the offsets', (tester) async {
        expect(
          await _blockShift(tester, 'position:$position;top:30px;left:20px'),
          Offset.zero,
        );
      });
    }

    testWidgets('offsets without position do nothing', (tester) async {
      expect(await _blockShift(tester, 'top:30px;left:20px'), Offset.zero);
    });

    testWidgets('nested relative boxes add up', (tester) async {
      expect(
        await _shift(
          tester,
          '<div><div>AAA</div></div>',
          '<div style="${_rel}top:10px;left:1px">'
              '<div style="${_rel}top:20px;left:2px">AAA</div></div>',
          'AAA',
        ),
        const Offset(3, 30),
      );
    });

    testWidgets('descendants move with the box, but offsets do not inherit',
        (tester) async {
      expect(
        await _shift(
          tester,
          '<div><div><span>AAA</span></div></div>',
          // The inner elements declare `relative` with no offsets of their own:
          // an inherited `top` would move the text twice.
          '<div style="${_rel}top:10px">'
              '<div style="position:relative"><span>AAA</span></div></div>',
          'AAA',
        ),
        const Offset(0, 10),
      );
    });

    testWidgets('every wrapped line of a block moves', (tester) async {
      final word = 'W' * 60;
      await pumpHtml(tester, '<div>$word</div>');
      final plain = lineFragments(tester);
      await pumpHtml(
          tester, '<div style="${_rel}left:7px;top:3px">$word</div>');
      final moved = lineFragments(tester);
      expect(plain.length, greaterThan(1));
      expect(moved.length, plain.length);
      for (var i = 0; i < plain.length; i++) {
        expect(moved[i]['offsetX'], (plain[i]['offsetX'] as double) + 7);
        expect(moved[i]['offsetY'], (plain[i]['offsetY'] as double) + 3);
      }
    });

    testWidgets('a list item marker moves with its item', (tester) async {
      await pumpHtml(tester, '<ul><li>AAA</li></ul>');
      final plain = await capture(tester);
      final plainX =
          plain.extent((r, g, b) => r < 80 && g < 80 && b < 80)!.left;
      await pumpHtml(tester, '<ul><li style="${_rel}left:30px">AAA</li></ul>');
      final moved = await capture(tester);
      expect(
        moved.extent((r, g, b) => r < 80 && g < 80 && b < 80)!.left,
        plainX + 30,
      );
    });

    test('ComputedStyle.relativeOffset follows the writing direction', () {
      final style = ComputedStyle(
        position: 'relative',
        insetLeft: 20,
        insetRight: 5,
        insetTop: 30,
        insetBottom: 9,
      );
      expect(style.relativeOffset(), const Offset(20, 30));
      expect(style.relativeOffset(rtl: true), const Offset(-5, 30));
      expect(ComputedStyle(insetLeft: 20).relativeOffset(), Offset.zero);
    });
  });

  group('layout is untouched', () {
    Future<void> expectSameFlow(
      WidgetTester tester,
      String Function(String style) html,
      List<String> siblings,
    ) async {
      await pumpHtml(tester, html(''));
      final height = viewerHeight(tester);
      final before = {for (final s in siblings) s: fragmentTopLeft(tester, s)};

      await pumpHtml(tester, html('${_rel}top:300px;left:50px'));
      expect(viewerHeight(tester), height);
      for (final s in siblings) {
        expect(fragmentTopLeft(tester, s), before[s], reason: s);
      }
    }

    testWidgets('following blocks and box height, after a block',
        (tester) async {
      await expectSameFlow(
        tester,
        (s) => '<p>BEFORE</p><div style="$s">AAA</div><p>AFTER</p>',
        ['BEFORE', 'AFTER'],
      );
    });

    testWidgets('following text, after an inline span', (tester) async {
      await expectSameFlow(
        tester,
        (s) => '<p>XX<span style="$s">AAA</span>YY</p><p>AFTER</p>',
        ['XX', 'YY', 'AFTER'],
      );
    });

    testWidgets('a table inside the box moves without changing the height',
        (tester) async {
      const html =
          '<div style="%S"><table><tr><td>cell</td></tr></table></div>';
      await pumpHtml(tester, html.replaceFirst('%S', ''));
      final height = viewerHeight(tester);
      final table = find.byType(SmartTableWrapper);
      final before = tester.getTopLeft(table);

      await pumpHtml(
          tester, html.replaceFirst('%S', '${_rel}top:40px;left:9px'));
      expect(viewerHeight(tester), height);
      expect(tester.getTopLeft(table) - before, const Offset(9, 40));
    });

    testWidgets('a flex container moves without changing the height',
        (tester) async {
      const html = '<p>Z</p><div style="display:flex;%S"><div>AAA</div></div>';
      await pumpHtml(tester, html.replaceFirst('%S', ''));
      final height = viewerHeight(tester);
      final flex = find.byType(FlexContainerWidget);
      final before = tester.getTopLeft(flex);

      await pumpHtml(
          tester, html.replaceFirst('%S', '${_rel}top:40px;left:9px'));
      expect(viewerHeight(tester), height);
      expect(tester.getTopLeft(flex) - before, const Offset(9, 40));
    });

    testWidgets('re-running layout does not compound the shift',
        (tester) async {
      const html = '<details><summary>S</summary><p>body</p></details>'
          '<div style="background:$probeRed;${_rel}left:30px;padding:4px">'
          'AAA</div>';
      await pumpHtml(tester, html);
      final closedText = fragmentOf(tester, 'AAA');
      final closedRed = (await capture(tester)).extent(isRed)!;

      final details = find.byType(HyperDetailsWidget);
      final tapAt = tester.getTopLeft(details) + const Offset(30, 10);
      await tester.tapAt(tapAt);
      await tester.pumpAndSettle();
      expect(fragmentOf(tester, 'AAA')['offsetX'], closedText['offsetX']);
      expect((await capture(tester)).extent(isRed)!.left, closedRed.left);

      await tester.tapAt(tapAt);
      await tester.pumpAndSettle();
      expect(fragmentOf(tester, 'AAA')['offsetX'], closedText['offsetX']);
      expect(fragmentOf(tester, 'AAA')['offsetY'], closedText['offsetY']);
      expect((await capture(tester)).extent(isRed)!.top, closedRed.top);
    });
  });

  group('painting', () {
    testWidgets('a block background moves with the box', (tester) async {
      await pumpHtml(
          tester,
          '<p>Z</p><div style="background:$probeRed;width:100px;padding:4px">'
          'A</div><p>Z</p><p>Z</p><p>Z</p>');
      final plain = (await capture(tester)).extent(isRed)!;
      await pumpHtml(
          tester,
          '<p>Z</p><div style="background:$probeRed;width:100px;padding:4px;'
          '${_rel}top:30px;left:20px">A</div><p>Z</p><p>Z</p><p>Z</p>');
      final moved = (await capture(tester)).extent(isRed)!;
      expect(moved.left, plain.left + 20);
      expect(moved.right, plain.right + 20);
      expect(moved.top, plain.top + 30);
      expect(moved.width, plain.width);
    });

    testWidgets('an inline background moves with its span', (tester) async {
      const span = 'background:$probeRed;padding:0 9px';
      // Trailing paragraphs keep the moved span inside the clipped box.
      const tail = '<p>Z</p><p>Z</p><p>Z</p>';
      await pumpHtml(tester, '<p>XX<span style="$span">A</span></p>$tail');
      final plain = (await capture(tester)).extent(isRed)!;
      await pumpHtml(tester,
          '<p>XX<span style="$span;${_rel}top:30px;left:20px">A</span></p>$tail');
      final moved = (await capture(tester)).extent(isRed)!;
      // The right edge: the left padding sits behind "XX" until the span moves.
      expect(moved.right, plain.right + 20);
      expect(moved.top, plain.top + 30);
    });

    testWidgets('glyphs are painted at the moved position', (tester) async {
      await pumpHtml(
          tester,
          '<p>Z</p><div style="color:$probeRed;${_rel}top:30px;left:20px">'
          'AAA</div><p>Z</p><p>Z</p>');
      final red = (await capture(tester)).extent(isRed)!;
      expect(red.left, 20);
      expect(red.right, 67);
      expect(red.top, 78);
    });

    testWidgets('text from a line far below is painted where it lands',
        (tester) async {
      // Moved text gets its own paint pass, culled by its own rect rather than
      // its line's. Note this can't prove the culling half: the box composites,
      // so its canvas clip is unbounded and per-line culling doesn't bite in a
      // widget test. It does fail if that separate pass is removed.
      final filler = '<div>x</div>' * 60;
      await pumpHtml(tester,
          '$filler<div style="color:$probeRed;${_rel}top:-800px">AAA</div>');
      final red = (await capture(tester)).extent(isRed);
      expect(red, isNotNull);
      expect(red!.top, 160);
    });

    Future<ProbePixels> sandwich(WidgetTester tester, String html) async {
      await tester.binding.setSurfaceSize(const Size(400, 600));
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: probeBoundaryKey,
              child: SizedBox(
                width: 400,
                height: 600,
                child: Column(
                  children: [
                    Container(height: 100, color: Colors.white),
                    // Nothing below: a widget here would paint over any overflow
                    // and hide what the "below" test is looking for.
                    HyperViewer(html: html, mode: HyperRenderMode.sync),
                  ],
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return capture(tester);
    }

    testWidgets('content cannot paint over the host app above the viewer',
        (tester) async {
      final pixels = await sandwich(
        tester,
        '<div style="background:$probeRed;${_rel}top:-80px;padding:8px">A</div>',
      );
      // Clipped to the viewer, whose first pixel row is y=100.
      final red = pixels.extent(isRed);
      if (red != null) expect(red.top, greaterThanOrEqualTo(100));
    });

    testWidgets('content cannot paint over the host app below the viewer',
        (tester) async {
      await pumpHtml(tester, '<div style="padding:8px">A</div>');
      final height = viewerHeight(tester);
      final pixels = await sandwich(
        tester,
        '<div style="background:$probeRed;${_rel}top:80px;padding:8px">A</div>',
      );
      final red = pixels.extent(isRed);
      if (red != null) {
        expect(red.bottom, lessThan(100 + height));
      }
    });

    testWidgets('a small shift stays visible inside the box', (tester) async {
      final pixels = await sandwich(
        tester,
        '<div style="padding:30px;background:rgb(0,0,255)">'
        '<div style="color:$probeRed;${_rel}top:10px;left:10px">A</div></div>',
      );
      final red = pixels.extent(isRed)!;
      expect(red.left, 40);
      expect(red.top, 140);
    });

    testWidgets('no relative content: no clip layer is pushed', (tester) async {
      // Normal documents must keep painting exactly as before.
      final pixels = await sandwich(tester, '<div>AAA</div>');
      expect(pixels, isNotNull);
      expect(hyperBoxes(tester).first.debugHasDisplacedContent, isFalse);
    });
  });

  group('hit-testing and selection', () {
    testWidgets('a character resolves at its moved position', (tester) async {
      await pumpHtml(
          tester, '<div>AAAA</div><div style="${_rel}left:100px">BBBB</div>');
      final box = hyperBoxes(tester).first;
      final start = fragmentOf(tester, 'BBBB')['charStart'] as int;
      final y = fragmentOf(tester, 'BBBB')['offsetY'] as double;
      // Just inside the third glyph, nearest its leading edge: x = 100 + 2.25×16.
      expect(box.getCharacterPositionAtOffset(Offset(136, y + 8)), start + 2);
    });

    testWidgets('moved vertically into another line band it still resolves',
        (tester) async {
      await pumpHtml(
        tester,
        '<div>AAAA</div><div>BBBB</div>'
        '<div style="${_rel}top:-32px;left:100px">CCCC</div>',
      );
      final box = hyperBoxes(tester).first;
      final c = fragmentOf(tester, 'CCCC');
      expect(c['offsetY'], 0);
      expect(
        box.getCharacterPositionAtOffset(const Offset(120, 8)),
        (c['charStart'] as int) + 1,
      );
      // AAAA, which owns that band, still resolves on its own glyphs.
      final a = fragmentOf(tester, 'AAAA');
      expect(
        box.getCharacterPositionAtOffset(const Offset(20, 8)),
        (a['charStart'] as int) + 1,
      );
    });

    testWidgets('a link is tappable where it is painted, not where it was',
        (tester) async {
      final tapped = <String>[];
      await tester.binding.setSurfaceSize(const Size(400, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              key: probeBoundaryKey,
              width: 400,
              child: HyperViewer(
                html: '<div>AAAA</div><div>BBBB</div><div>CCCC</div>'
                    '<div style="${_rel}top:-48px;left:100px">'
                    '<a href="https://example.com/x">LINK</a></div>',
                mode: HyperRenderMode.sync,
                onLinkTap: tapped.add,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final origin = tester.getTopLeft(find.byType(HyperViewer));
      final link = fragmentOf(tester, 'LINK');
      expect(link['offsetY'], 0);

      await tester
          .tapAt(origin + const Offset(10, 56)); // where it was laid out
      await tester.pump(const Duration(milliseconds: 500));
      expect(tapped, isEmpty);

      await tester.tapAt(origin + const Offset(116, 8)); // where it is painted
      await tester.pump(const Duration(milliseconds: 500));
      expect(tapped, ['https://example.com/x']);
    });

    testWidgets('getBoxesForCharRange reports the moved rect', (tester) async {
      await pumpHtml(tester, '<div>AAAA</div><div>BBBB</div>');
      final plainStart = fragmentOf(tester, 'BBBB')['charStart'] as int;
      final plain = hyperBoxes(tester)
          .first
          .getBoxesForCharRange(plainStart, plainStart + 4)
          .single;

      await pumpHtml(tester,
          '<div>AAAA</div><div style="${_rel}top:50px;left:60px">BBBB</div>');
      final start = fragmentOf(tester, 'BBBB')['charStart'] as int;
      final moved = hyperBoxes(tester)
          .first
          .getBoxesForCharRange(start, start + 4)
          .single;
      expect(moved.topLeft - plain.topLeft, const Offset(60, 50));
      expect(moved.size, plain.size);
    });

    testWidgets('selection rects and the highlight follow the moved text',
        (tester) async {
      await pumpHtml(
          tester, '<div style="${_rel}top:50px;left:60px">BBBB</div><p>Z</p>');
      final box = hyperBoxes(tester).first;
      final start = fragmentOf(tester, 'BBBB')['charStart'] as int;
      box.selection = HyperTextSelection(start: start, end: start + 4);
      final rects = box.getSelectionRects();
      expect(rects, isNotEmpty);
      expect(rects.first.left, 60);
      expect(rects.first.top, greaterThanOrEqualTo(50));
    });

    testWidgets('selected text keeps document order', (tester) async {
      await pumpHtml(
          tester,
          '<div>AAAA</div>'
          '<div style="${_rel}top:-16px;left:100px">BBBB</div><div>CCCC</div>');
      final box = hyperBoxes(tester).first;
      box.selection = HyperTextSelection(start: 0, end: 12 + 2);
      final text = box.getSelectedText()!;
      expect(text.replaceAll('\n', ''), 'AAAABBBBCCCC');
    });
  });

  group('widget path', () {
    testWidgets('a flex item moves and its sibling stays', (tester) async {
      const html = '<div style="display:flex">'
          '<div style="%S">AAA</div><div>BBB</div></div>';
      await pumpHtml(tester, html.replaceFirst('%S', ''));
      final a = tester.getTopLeft(find.text('AAA'));
      final b = tester.getTopLeft(find.text('BBB'));
      final height = viewerHeight(tester);

      await pumpHtml(
          tester, html.replaceFirst('%S', '${_rel}top:30px;left:20px'));
      expect(tester.getTopLeft(find.text('AAA')) - a, const Offset(20, 30));
      expect(tester.getTopLeft(find.text('BBB')), b);
      expect(viewerHeight(tester), height);
    });

    testWidgets('a grid item moves and its sibling stays', (tester) async {
      const html = '<div style="display:grid;grid-template-columns:1fr 1fr">'
          '<div style="%S">AAA</div><div>BBB</div></div>';
      await pumpHtml(tester, html.replaceFirst('%S', ''));
      final a = tester.getTopLeft(find.text('AAA'));
      final b = tester.getTopLeft(find.text('BBB'));

      await pumpHtml(
          tester, html.replaceFirst('%S', '${_rel}top:30px;left:20px'));
      expect(tester.getTopLeft(find.text('AAA')) - a, const Offset(20, 30));
      expect(tester.getTopLeft(find.text('BBB')), b);
    });
  });

  group('combinations', () {
    testWidgets('an animated relative block paints and stays in place',
        (tester) async {
      await pumpHtml(
        tester,
        '<style>@keyframes f{from{opacity:.5}to{opacity:1}}</style><p>Z</p>'
        '<div style="animation:f 200ms;background:$probeRed;${_rel}left:30px;'
        'padding:4px">AAA</div>',
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      // Mid-animation the red is translucent over white, so match "reddish".
      final tinted = (await capture(tester))
          .extent((r, g, b) => r > 200 && r - g > 40 && r - b > 40)!;
      expect(tinted.left, 30);
      expect(fragmentOf(tester, 'AAA')['offsetX'], 34);
    });

    testWidgets('box-sizing and position combine', (tester) async {
      await pumpHtml(
        tester,
        '<div style="width:200px;padding:20px;box-sizing:border-box;'
        'background:$probeRed;${_rel}left:30px">A</div>',
      );
      final red = (await capture(tester)).extent(isRed)!;
      expect(red.left, 30);
      expect(red.right, 229);
    });
  });
}
