// Horizontal margins on in-flow canvas blocks, measured through fragment
// geometry and painted pixels.

import 'package:flutter_test/flutter_test.dart';

import 'support/geometry_probe.dart';

final _word = 'W' * 60;
const _bg = 'background:$probeRed;';

Future<PixelExtent> _box(WidgetTester tester, String style) async {
  await pumpHtml(tester, '<div style="$_bg$style;padding:4px">A</div>');
  return (await capture(tester)).extent(isRed)!;
}

void main() {
  group('lengths', () {
    testWidgets('margin-left and margin-right inset the box and its text',
        (tester) async {
      await pumpHtml(
        tester,
        '<div style="$_bg;margin-left:30px;margin-right:50px;padding:4px">AAA'
        '</div>',
      );
      expect(fragmentTopLeft(tester, 'AAA').dx, 34);
      final red = (await capture(tester)).extent(isRed)!;
      expect(red.left, 30);
      expect(red.right, 349);
    });

    testWidgets('the shorthand works', (tester) async {
      final red = await _box(tester, 'margin:0 40px');
      expect(red.left, 40);
      expect(red.right, 359);
    });

    testWidgets('margins narrow the line', (tester) async {
      await pumpHtml(tester, '<div>$_word</div>');
      expect(firstLineChars(tester), 25);
      await pumpHtml(tester, '<div style="margin:0 40px">$_word</div>');
      expect(firstLineChars(tester), 20);
    });

    testWidgets('a first block with only a margin keeps it', (tester) async {
      await pumpHtml(tester, '<div style="margin-left:30px">AAA</div>');
      expect(fragmentTopLeft(tester, 'AAA').dx, 30);
    });

    testWidgets('margins add up when nested', (tester) async {
      await pumpHtml(
        tester,
        '<div style="margin-left:10px"><div style="margin-left:20px">AAA</div>'
        '</div>',
      );
      expect(fragmentTopLeft(tester, 'AAA').dx, 30);
    });

    testWidgets('a margin is not inherited, and later text returns to the edge',
        (tester) async {
      await pumpHtml(
        tester,
        '<div style="margin-left:30px"><p>AAA</p></div><p>BBB</p>',
      );
      expect(fragmentTopLeft(tester, 'AAA').dx, 30);
      expect(fragmentTopLeft(tester, 'BBB').dx, 0);
    });

    testWidgets('a width and a margin combine', (tester) async {
      final red = await _box(tester, 'width:100px;margin-left:30px');
      expect(red.left, 30);
      expect(red.right, 137);
    });

    testWidgets('% width still resolves against the container', (tester) async {
      await pumpHtml(
        tester,
        '<div style="width:50%;margin-left:100px">$_word</div>',
      );
      expect(firstLineChars(tester), 12); // 200px, not 150px
    });

    testWidgets('a margin wider than the container does not throw',
        (tester) async {
      await pumpHtml(
        tester,
        '<div style="margin:0 900px">AAA</div><p>BBB</p>',
      );
      expect(tester.takeException(), isNull);
      expect(fragmentTopLeft(tester, 'BBB').dx, 0);
    });
  });

  group('auto', () {
    testWidgets('margin:0 auto centres a block with a width', (tester) async {
      final red = await _box(tester, 'width:200px;margin:0 auto');
      // Box is 208 wide with its padding, leaving 192: 96 on each side.
      expect(red.left, 96);
      expect(red.right, 303);
    });

    testWidgets('it centres the text with it', (tester) async {
      await pumpHtml(
        tester,
        '<div style="width:200px;padding:4px;margin:0 auto">AAA</div>',
      );
      expect(fragmentTopLeft(tester, 'AAA').dx, 100);
    });

    testWidgets('the common max-width layout centres, in stylesheet form',
        (tester) async {
      await pumpHtml(
        tester,
        '<style>.c{max-width:200px;margin:0 auto;box-sizing:border-box;'
        'padding:4px;$_bg}</style><div class="c">A</div>',
      );
      final red = (await capture(tester)).extent(isRed)!;
      expect(red.left, 100);
      expect(red.right, 299);
    });

    testWidgets('max-width wider than the container fills it', (tester) async {
      final red = await _box(tester, 'max-width:900px;margin:0 auto');
      expect(red.left, 0);
      expect(red.right, 399);
    });

    testWidgets('no width: auto is 0', (tester) async {
      final red = await _box(tester, 'margin:0 auto');
      expect(red.left, 0);
      expect(red.right, 399);
    });

    testWidgets('margin-left:auto pushes the box right', (tester) async {
      final red = await _box(tester, 'width:100px;margin-left:auto');
      expect(red.right, 399);
      expect(red.left, 292);
    });

    testWidgets('margin-right:auto leaves it at the left', (tester) async {
      final red = await _box(tester, 'width:100px;margin-right:auto');
      expect(red.left, 0);
      expect(red.right, 107);
    });

    testWidgets('auto with a fixed opposite margin takes what is left',
        (tester) async {
      final red =
          await _box(tester, 'width:100px;margin-left:auto;margin-right:20px');
      expect(red.right, 379);
    });

    testWidgets('a later length replaces auto', (tester) async {
      final red = await _box(
          tester, 'width:100px;margin:0 auto;margin-left:10px;margin-right:0');
      expect(red.left, 10);
    });

    testWidgets('three- and four-value shorthands read auto', (tester) async {
      expect((await _box(tester, 'width:192px;margin:0 auto 4px')).left, 100);
      expect(
          (await _box(tester, 'width:192px;margin:0 auto 4px auto')).left, 100);
    });

    testWidgets('it centres inside a parent with padding', (tester) async {
      await pumpHtml(
        tester,
        '<div style="padding:0 50px">'
        '<div style="$_bg;width:100px;margin:0 auto;padding:4px">A</div></div>',
      );
      final red = (await capture(tester)).extent(isRed)!;
      // Parent content 300 wide from x=50; box 108, so 96 on each side.
      expect(red.left, 146);
      expect(red.right, 253);
    });
  });

  group('negative margins', () {
    testWidgets('can reach into the parent padding', (tester) async {
      await pumpHtml(
        tester,
        '<div style="padding:0 20px"><div style="margin-left:-20px">AAA</div>'
        '</div>',
      );
      expect(fragmentTopLeft(tester, 'AAA').dx, 0);
    });

    testWidgets('cannot leave the render box', (tester) async {
      await pumpHtml(
        tester,
        '<div style="$_bg;margin:0 -500px;padding:4px">AAA</div>',
      );
      expect(fragmentTopLeft(tester, 'AAA').dx, 4);
      final red = (await capture(tester)).extent(isRed)!;
      expect(red.left, 0);
      expect(red.right, 399);
    });
  });

  group('other paths are unchanged', () {
    testWidgets('a float uses its own margin handling', (tester) async {
      await pumpHtml(
        tester,
        '<div style="float:left;width:100px;height:40px;margin-right:20px">'
        '</div><p>BBB</p>',
      );
      expect(fragmentTopLeft(tester, 'BBB').dx, 120);
    });

    testWidgets('a flex container is not inset twice', (tester) async {
      await pumpHtml(
        tester,
        '<div style="display:flex;margin-left:30px">'
        '<div style="background:$probeRed;padding:4px">A</div></div>',
      );
      expect((await capture(tester)).extent(isRed)!.left, 30);
    });

    testWidgets('position:relative moves a margined box', (tester) async {
      final red = await _box(
          tester, 'width:100px;margin-left:30px;position:relative;left:10px');
      expect(red.left, 40);
    });

    testWidgets('box-sizing keeps margins outside the box', (tester) async {
      final red = await _box(
          tester, 'width:100px;margin-left:30px;box-sizing:border-box');
      expect(red.left, 30);
      expect(red.right, 129);
    });
  });
}
