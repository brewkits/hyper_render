// A first block styled ONLY with a background or border used to paint nothing:
// its _BlockStartFragment (which carries the decoration) was elided because the
// emit condition checked margin/padding/width/ellipsis but not decoration.

import 'package:flutter_test/flutter_test.dart';

import 'package:hyper_render/hyper_render.dart';

import 'support/geometry_probe.dart';

void main() {
  testWidgets('a first block with only a background paints it', (tester) async {
    await pumpHtml(tester, '<div style="background:$probeRed">AAA</div>');
    final red = (await capture(tester)).extent(isRed);
    // The glyphs cover x 0–47, so the background shows from x=48 to the edge.
    expect(red, isNotNull);
    expect(red!.left, 48);
    expect(red.right, 399);
  });

  testWidgets('a first block paints the same as a later block', (tester) async {
    await pumpHtml(tester, '<div style="background:$probeRed">AAA</div>');
    final first = (await capture(tester)).extent(isRed);
    await pumpHtml(
        tester, '<p>Z</p><div style="background:$probeRed">AAA</div>');
    final later = (await capture(tester)).extent(isRed);
    expect(first?.left, later?.left);
    expect(first?.right, later?.right);
    expect(first?.height, later?.height);
  });

  testWidgets('a first block with only a gradient paints it', (tester) async {
    await pumpHtml(
        tester,
        '<div style="background:linear-gradient(to right,#ff0000,#ff0000)">'
        'AAA</div>');
    expect((await capture(tester)).extent(isRed), isNotNull);
  });

  testWidgets('a gradient on a later block and an inline span paints too',
      (tester) async {
    const gradient = 'linear-gradient(to right,#ff0000,#ff0000)';
    await pumpHtml(tester, '<p>Z</p><div style="background:$gradient">A</div>');
    expect((await capture(tester)).extent(isRed), isNotNull);

    await pumpHtml(tester,
        '<p>Z<span style="background:$gradient;padding:0 9px">A</span>');
    expect((await capture(tester)).extent(isRed), isNotNull);
  });

  testWidgets('a first block with only a border paints it', (tester) async {
    await pumpHtml(
        tester, '<div style="border:4px solid rgb(0,0,255)">AAA</div>');
    final blue = (await capture(tester)).extent(isBlue);
    expect(blue, isNotNull);
    expect(blue!.right, greaterThan(390));
  });

  testWidgets('emitting the decoration does not move the text', (tester) async {
    await pumpHtml(tester, '<div>AAA</div><p>BBB</p>');
    final plainA = fragmentTopLeft(tester, 'AAA');
    final plainB = fragmentTopLeft(tester, 'BBB');
    final plainH = viewerHeight(tester);

    await pumpHtml(
        tester, '<div style="background:$probeRed">AAA</div><p>BBB</p>');
    expect(fragmentTopLeft(tester, 'AAA'), plainA);
    expect(fragmentTopLeft(tester, 'BBB'), plainB);
    expect(viewerHeight(tester), plainH);
  });

  testWidgets('re-running line layout leaves no stale decoration behind',
      (tester) async {
    const html = '<details><summary>S</summary><p>body</p></details>'
        '<div style="background:$probeRed">AAA</div>';
    await pumpHtml(tester, html);
    final closed = (await capture(tester)).extent(isRed)!;

    // A details toggle re-runs line layout without invalidating the fragments,
    // and the block below moves down. Its old rect must not keep painting.
    final details = find.byType(HyperDetailsWidget);
    await tester.tapAt(tester.getTopLeft(details) + const Offset(30, 10));
    await tester.pumpAndSettle();
    final open = (await capture(tester)).extent(isRed)!;

    expect(open.top, greaterThan(closed.top));
    expect(open.height, closed.height);
  });
}
