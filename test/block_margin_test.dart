// Horizontal margins on in-flow canvas blocks, measured through fragment
// geometry and painted pixels.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

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

  group('code blocks', () {
    Finder preChild() => find.byType(CodeBlockWidget);

    testWidgets('a margin narrows the block instead of pushing it out',
        (tester) async {
      await pumpHtml(tester, '<pre style="margin:0 40px">x</pre><p>Z</p>');
      final rect = tester.getRect(preChild());
      expect(rect.left, 40);
      expect(rect.right, lessThanOrEqualTo(360));
    });

    testWidgets('a huge margin stays inside the box', (tester) async {
      await pumpHtml(tester, '<pre style="margin-left:900px">x</pre><p>Z</p>');
      expect(tester.takeException(), isNull);
      expect(tester.getRect(preChild()).right, lessThanOrEqualTo(400));
    });
  });

  group('floats inside a block with margins', () {
    const image = 'float:%S;width:50px;height:50px';

    // An empty float paints nothing of its own, so read its laid-out position.
    double floatX(WidgetTester tester) => hyperBoxes(tester)
        .first
        .debugFragments()
        .firstWhere((f) => f['type'] == 'atomic')['offsetX'] as double;

    testWidgets('a left float sits at the container edge, with text beside it',
        (tester) async {
      await pumpHtml(
        tester,
        '<div style="width:200px;margin:0 auto">'
        '<div style="${image.replaceFirst('%S', 'left')};background:$probeRed">'
        '</div><span>AAA</span></div>',
      );
      expect(floatX(tester), 100);
      // Beside the float: container edge + 50 + the default 8px float margin.
      expect(fragmentTopLeft(tester, 'AAA').dx, 158);
    });

    testWidgets('a right float sits at the container edge', (tester) async {
      await pumpHtml(
        tester,
        '<div style="width:200px;margin:0 auto">'
        '<div style="${image.replaceFirst('%S', 'right')};'
        'background:$probeRed"></div><span>AAA</span></div>',
      );
      // Right edge 300, minus 50 wide.
      expect(floatX(tester), 250);
      expect(fragmentTopLeft(tester, 'AAA').dx, 100);
    });

    testWidgets('text wraps beside the float inside the container',
        (tester) async {
      await pumpHtml(
        tester,
        '<div style="margin-left:100px">'
        '<div style="${image.replaceFirst('%S', 'left')}"></div>'
        '<span>AAA</span></div>',
      );
      expect(fragmentTopLeft(tester, 'AAA').dx, 158);
    });

    testWidgets('a float clears the parent padding, not its own',
        (tester) async {
      await pumpHtml(
        tester,
        '<div style="padding:0 30px"><div style="float:left;width:50px;'
        'height:50px;padding:0 10px;background:$probeRed"></div>'
        '<span>AAA</span></div><p>Z</p>',
      );
      expect(floatX(tester), 30);
    });
  });

  group('inline !important', () {
    for (final style in [
      'width:200px;margin:auto !important',
      'width:200px;margin:0 auto!important',
      'width:200px;margin:0 auto !important',
      'width:200px;margin-left:auto !important;margin-right:auto !important',
    ]) {
      testWidgets(style, (tester) async {
        final red = await _box(tester, style);
        expect(red.left, 96);
      });
    }

    testWidgets('other properties accept it too', (tester) async {
      final red = await _box(tester, 'margin-left:30px !important');
      expect(red.left, 30);
    });
  });

  group('em margins', () {
    testWidgets('use the element font size, in any order', (tester) async {
      for (final style in [
        'font-size:32px;margin-left:2em',
        'margin-left:2em;font-size:32px',
        'font-size:32px;margin:0 0 0 2em',
      ]) {
        await pumpHtml(tester, '<div style="$style">AAA</div>');
        expect(fragmentTopLeft(tester, 'AAA').dx, 64, reason: style);
      }
    });

    testWidgets('a vertical em margin does too', (tester) async {
      await pumpHtml(tester, '<p>Z</p><div>AAA</div>');
      final plain = fragmentTopLeft(tester, 'AAA').dy;
      await pumpHtml(tester,
          '<p>Z</p><div style="font-size:32px;margin-top:1em">AAA</div>');
      expect(
          fragmentTopLeft(tester, 'AAA').dy, greaterThanOrEqualTo(plain + 16));
    });
  });

  group('right-to-left', () {
    Future<PixelExtent> rtlBox(WidgetTester tester, String style) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: probeBoundaryKey,
              child: SizedBox(
                width: 400,
                height: 200,
                child: HyperViewer(
                  html: '<div style="$_bg$style;padding:4px">A</div>',
                  mode: HyperRenderMode.sync,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return (await capture(tester)).extent(isRed)!;
    }

    setUp(() {});

    testWidgets('a box with a width anchors to the right edge', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      final red = await rtlBox(tester, 'width:100px;margin-right:30px');
      expect(red.right, 369);
      expect(red.left, 262);
    });

    testWidgets('margin-right:auto pushes it left', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      final red = await rtlBox(tester, 'width:100px;margin-right:auto');
      expect(red.left, 0);
    });

    testWidgets('margin:0 auto still centres', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      final red = await rtlBox(tester, 'width:192px;margin:0 auto');
      expect(red.left, 100);
    });
  });

  group('flex container background', () {
    testWidgets('stays inside the margins', (tester) async {
      await pumpHtml(
        tester,
        '<p>Z</p><div style="display:flex;margin:0 30px;background:$probeRed;'
        'padding:4px"><div>A</div></div>',
      );
      final red = (await capture(tester)).extent(isRed)!;
      expect(red.left, 30);
      expect(red.right, 369);
    });
  });

  group('intrinsic width', () {
    testWidgets('leaves room for margins and padding', (tester) async {
      Future<int> lines(String style) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: probeBoundaryKey,
                child: IntrinsicWidth(
                  child: HyperViewer(
                    html: '<div style="$style">Hello world</div>',
                    mode: HyperRenderMode.sync,
                    selectable: false,
                  ),
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        return lineFragments(tester).length;
      }

      final plain = await lines('');
      expect(await lines('margin-left:40px'), plain);
      expect(await lines('padding:0 25px'), plain);
    });
  });
}
