/// Golden tests for canvas-painted CSS block animation (RenderHyperBox
/// paint tier — see render_hyper_box_animation.dart).
///
/// Unlike the frame-loop-lifecycle tests in
/// test/style/canvas_block_animation_test.dart (which only assert
/// "doesn't throw" / "schedules a frame callback"), these lock down the
/// actual painted pixels at a fixed point mid-animation — specifically to
/// guard against the `saveLayer` bounds bug where opacity + transform
/// combined clipped a translated block to its pre-transform position.
///
/// Run once to generate reference images:
///   flutter test test/golden/canvas_block_animation_golden_test.dart --update-goldens
///
/// Then run normally to compare:
///   flutter test test/golden/canvas_block_animation_golden_test.dart
///
/// Excluded from normal CI runs via: --exclude-tags golden
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

final _goldenKey = GlobalKey();

Future<void> _pumpAnimated(
  WidgetTester tester,
  String html, {
  required Duration advanceBy,
}) async {
  final adapter = HtmlAdapter();
  final doc = adapter.parse(html);
  final resolver = StyleResolver();
  final css = adapter.extractCss(html);
  if (css.isNotEmpty) resolver.parseCss(css);
  resolver.resolveStyles(doc);
  const cssParser = DefaultCssParser();
  final keyframes = adapter.extractKeyframes(html, cssParser);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 200),
          devicePixelRatio: 1.0,
          textScaler: TextScaler.noScaling,
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            // A wide left inset (rather than the usual 16px) gives a
            // translateX(-40px)-style keyframe visible room to shift into —
            // without it, a full-width block already sits flush against the
            // capture edge and a clip-bounds regression (content cut at its
            // pre-transform position) would be indistinguishable from the
            // container's own edge.
            padding: const EdgeInsets.fromLTRB(60, 16, 16, 16),
            child: SizedBox(
              key: _goldenKey,
              width: 308,
              height: 168,
              child: HyperRenderWidget(
                document: doc,
                baseStyle: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF1A1A1A),
                ),
                config: HyperRenderConfig(keyframeRegistry: keyframes),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  // First pump: mounts, lays out, stamps the animation's epoch, and starts
  // the SchedulerBinding frame loop. Then advance by exactly `advanceBy` in
  // one jump so the interpolated progress at capture time is deterministic
  // regardless of how many intermediate frames a real device would render.
  await tester.pump();
  await tester.pump(advanceBy);
}

void main() {
  group('Golden — Canvas block animation', () {
    testWidgets('opacity + translateX at 50% progress', (tester) async {
      // Regression test for the saveLayer-bounds bug: the opacity layer used
      // to be bounded by the block's PRE-transform rect, clipping the left
      // edge once translateX shifted the content outside those bounds.
      await _pumpAnimated(
        tester,
        '<style>@keyframes slidein { '
        'from { opacity: 0; transform: translateX(-40px); } '
        'to { opacity: 1; transform: translateX(0); } '
        '}</style>'
        // A <p> (not <div>) so the block resolves to `display: block` and
        // gets a _BlockDecoration without relying on a default stylesheet —
        // this test harness parses HTML directly (HtmlAdapter + StyleResolver)
        // without HyperViewer's tag-default CSS layer.
        '<p style="animation: slidein 400ms linear; '
        'background-color: #ffe0e0; padding: 12px;">'
        'Sliding in text</p>',
        // 25% progress (not 50%) keeps translateX at -30px — closer to the
        // full -40px displacement, making a clip-bounds regression at the
        // pre-transform left edge maximally visible.
        advanceBy: const Duration(milliseconds: 100),
      );
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/canvas_block_animation_slidein_50pct.png'),
      );
    });

    testWidgets('paused animation renders a stable frozen frame',
        (tester) async {
      await _pumpAnimated(
        tester,
        '<style>@keyframes fade { from { opacity: 0; } to { opacity: 1; } '
        '}</style>'
        '<p style="animation: fade 400ms linear; '
        'animation-play-state: paused;">Paused text</p>',
        advanceBy: const Duration(milliseconds: 500),
      );
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/canvas_block_animation_paused.png'),
      );
    });

    // The opacity layer's bounds are now the block's own rect rather than the
    // whole canvas (so one animating block doesn't allocate a document-sized
    // buffer every frame). A box-shadow paints OUTSIDE that rect, so it is the
    // case most likely to get clipped by bounds that are too tight —
    // _animatedLayerBounds has to grow the rect by each shadow's
    // offset + spread + blur. Nothing checked that before this golden.
    testWidgets('box-shadow is not clipped by the opacity layer bounds',
        (tester) async {
      await _pumpAnimated(
        tester,
        '<style>@keyframes fade { from { opacity: 0.2; } to { opacity: 0.8; } '
        '}</style>'
        // Large blur + spread + a downward/rightward offset, so the shadow
        // extends well past the block on three sides.
        '<p style="animation: fade 400ms linear; '
        'background-color: #2050c0; padding: 10px; '
        'box-shadow: 6px 8px 14px 4px #d02020;">Shadowed</p>',
        advanceBy: const Duration(milliseconds: 200),
      );
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/canvas_block_animation_boxshadow.png'),
      );
    });
  });
}
