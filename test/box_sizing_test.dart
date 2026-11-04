// CSS box-sizing, measured through real geometry: line capacity (the test font
// has 16px square glyphs at the default size) and painted pixels.
//
// Covers in-flow canvas blocks, which is the scope documented in
// doc/CSS_PROPERTIES_MATRIX.md and doc/LIMITATIONS.md.

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

import 'support/geometry_probe.dart';

final _word = 'W' * 60;

/// Characters on the first line of a 60-character word inside [style].
Future<int> _capacity(WidgetTester tester, String style) async {
  await pumpHtml(tester, '<div style="$style">$_word</div>');
  return firstLineChars(tester);
}

void main() {
  group('line capacity', () {
    testWidgets('matches the issue: 12 characters, 10 with border-box',
        (tester) async {
      expect(await _capacity(tester, 'width:200px;padding:20px'), 12);
      expect(
        await _capacity(
            tester, 'width:200px;padding:20px;box-sizing:border-box'),
        10,
      );
    });

    testWidgets('content-box behaves like the default', (tester) async {
      expect(
        await _capacity(
            tester, 'width:200px;padding:20px;box-sizing:content-box'),
        12,
      );
    });

    testWidgets('an invalid value is ignored', (tester) async {
      expect(
        await _capacity(tester, 'width:200px;padding:20px;box-sizing:banana'),
        12,
      );
    });

    testWidgets('a later declaration wins', (tester) async {
      expect(
        await _capacity(
          tester,
          'box-sizing:border-box;width:200px;padding:20px;'
          'box-sizing:content-box',
        ),
        12,
      );
    });

    testWidgets('border width is subtracted too', (tester) async {
      // 200 − 40 padding − 20 border = 140px, which holds 8 glyphs.
      expect(
        await _capacity(
          tester,
          'width:200px;padding:20px;border:10px solid #000;'
          'box-sizing:border-box',
        ),
        8,
      );
    });

    testWidgets('percentage width', (tester) async {
      expect(await _capacity(tester, 'width:50%;padding:20px'), 12);
      expect(
        await _capacity(tester, 'width:50%;padding:20px;box-sizing:border-box'),
        10,
      );
    });

    testWidgets('max-width, absolute and percentage', (tester) async {
      const bb = 'padding:20px;box-sizing:border-box';
      expect(await _capacity(tester, 'max-width:200px;$bb'), 10);
      expect(await _capacity(tester, 'max-width:50%;$bb'), 10);
    });

    testWidgets('min-width, absolute and percentage', (tester) async {
      const bb = 'width:50px;padding:20px;box-sizing:border-box';
      expect(await _capacity(tester, 'min-width:200px;$bb'), 10);
      expect(await _capacity(tester, 'min-width:50%;$bb'), 10);
      // Percentage min-width also applies without border-box.
      expect(await _capacity(tester, 'width:50px;min-width:50%'), 12);
    });

    testWidgets('min-width still wins over max-width', (tester) async {
      expect(
        await _capacity(
          tester,
          'max-width:100px;min-width:200px;padding:20px;box-sizing:border-box',
        ),
        10,
      );
    });

    testWidgets('padding wider than the width floors at 0 without throwing',
        (tester) async {
      await pumpHtml(
        tester,
        '<div style="width:30px;padding:20px;box-sizing:border-box">A</div>'
        '<p>after</p>',
      );
      expect(tester.takeException(), isNull);
      expect(fragmentOf(tester, 'after'), isNotNull);
    });

    testWidgets('width:100% with padding fills the container either way',
        (tester) async {
      expect(await _capacity(tester, 'width:100%;padding:20px'), 22);
      expect(
        await _capacity(
            tester, 'width:100%;padding:20px;box-sizing:border-box'),
        22,
      );
    });
  });

  group('nesting and inheritance', () {
    testWidgets('a nested % resolves against the parent content box',
        (tester) async {
      // Outer content 300−20=280; inner 50% = 140, minus its 20 padding = 120.
      await pumpHtml(
        tester,
        '<div style="width:300px;padding:10px;box-sizing:border-box">'
        '<div style="width:50%;padding:10px;box-sizing:border-box">$_word</div>'
        '</div>',
      );
      expect(firstLineChars(tester), 7);
    });

    testWidgets('box-sizing is not inherited', (tester) async {
      await pumpHtml(
        tester,
        '<div style="box-sizing:border-box">'
        '<div style="width:200px;padding:20px">$_word</div></div>',
      );
      expect(firstLineChars(tester), 12);
    });
  });

  group('stylesheets', () {
    testWidgets('the common reset applies through <style>', (tester) async {
      await pumpHtml(
        tester,
        '<style>*, *::before, *::after { box-sizing: border-box }</style>'
        '<div style="width:200px;padding:20px">$_word</div>',
      );
      expect(firstLineChars(tester), 10);
    });

    testWidgets('it applies through customCss', (tester) async {
      await pumpHtml(
        tester,
        '<div class="box">$_word</div>',
        customCss: '.box { width:200px; padding:20px; box-sizing:border-box }',
      );
      expect(firstLineChars(tester), 10);
    });
  });

  group('painted box', () {
    Future<PixelExtent> redOf(WidgetTester tester, String style,
        {String body = 'A'}) async {
      await pumpHtml(
          tester, '<div style="background:$probeRed;$style">$body</div>');
      return (await capture(tester)).extent(isRed)!;
    }

    testWidgets('border-box: the background is exactly the declared width',
        (tester) async {
      final red =
          await redOf(tester, 'width:200px;padding:20px;box-sizing:border-box');
      expect(red.left, 0);
      expect(red.right, 199);
    });

    testWidgets('content-box: the background adds padding to the width',
        (tester) async {
      final red = await redOf(tester, 'width:200px;padding:20px');
      expect(red.left, 0);
      expect(red.right, 239);
    });

    testWidgets('a border is inside the declared border-box width',
        (tester) async {
      await pumpHtml(
        tester,
        '<div style="width:200px;padding:20px;box-sizing:border-box;'
        'border:10px solid rgb(0,0,255)">A</div>',
      );
      final blue = (await capture(tester)).extent(isBlue)!;
      expect(blue.left, 0);
      expect(blue.right, 199);
    });

    testWidgets('a border adds to a content-box width', (tester) async {
      await pumpHtml(
        tester,
        '<div style="width:200px;padding:20px;'
        'border:10px solid rgb(0,0,255)">A</div>',
      );
      final blue = (await capture(tester)).extent(isBlue)!;
      expect(blue.right, 259);
    });

    testWidgets('no width constraint: still the full container',
        (tester) async {
      final red = await redOf(tester, 'padding:20px');
      expect(red.left, 0);
      expect(red.right, 399);
    });

    testWidgets('a width larger than the container is capped to it',
        (tester) async {
      final red = await redOf(tester, 'width:900px;padding:20px');
      expect(red.right, 399);
    });

    testWidgets('max-width that does not bind: still the full container',
        (tester) async {
      final red = await redOf(tester, 'max-width:900px');
      expect(red.right, 399);
    });

    testWidgets('a nested box stays inside its parent', (tester) async {
      await pumpHtml(
        tester,
        '<div style="width:200px;padding:10px;box-sizing:border-box">'
        '<div style="background:$probeRed;width:900px;padding:4px">A</div></div>',
      );
      final red = (await capture(tester)).extent(isRed)!;
      expect(red.left, 10);
      expect(red.right, 189);
    });

    testWidgets('a width change recomputes the box', (tester) async {
      const html = '<div style="background:$probeRed;width:50%">A</div>';
      await pumpHtml(tester, html, width: 400);
      expect((await capture(tester)).extent(isRed)!.right, 199);
      await pumpHtml(tester, html, width: 200);
      expect((await capture(tester)).extent(isRed)!.right, 99);
    });
  });

  test('ComputedStyle: defaults to content-box and survives copyWith', () {
    expect(ComputedStyle().boxSizing, HyperBoxSizing.contentBox);
    expect(
      ComputedStyle(boxSizing: HyperBoxSizing.borderBox).copyWith().boxSizing,
      HyperBoxSizing.borderBox,
    );
  });

  testWidgets('no regression when width is unset: identical layout',
      (tester) async {
    await pumpHtml(tester, '<div style="padding:20px">$_word</div><p>Z</p>');
    final plain = fragmentTopLeft(tester, 'Z');
    final height = tester.getSize(find.byType(HyperViewer)).height;
    await pumpHtml(tester,
        '<div style="padding:20px;box-sizing:border-box">$_word</div><p>Z</p>');
    expect(fragmentTopLeft(tester, 'Z'), plain);
    expect(tester.getSize(find.byType(HyperViewer)).height, height);
  });
}
