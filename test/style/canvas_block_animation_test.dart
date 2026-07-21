// Tests for canvas-painted CSS block animation (RenderHyperBox paint tier).
//
// Unlike HyperAnimatedWidget (widget tree), this path animates content
// painted directly on RenderHyperBox's Canvas — plain paragraphs/divs with
// `animation-name` that are NOT flex/grid containers or plugin widgets.
// The frame-driver loop (SchedulerBinding.scheduleFrameCallback, no
// TickerProvider — see render_hyper_box_animation.dart) is tested here via
// SchedulerBinding.transientCallbackCount rather than pixel sampling, since
// RenderHyperBox internals are private to their library.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

const _fadeKeyframes = '<style>@keyframes fade { '
    'from { opacity: 0; } to { opacity: 1; } '
    '}</style>';

Widget _app(String html) {
  return MaterialApp(home: Scaffold(body: HyperViewer(html: html)));
}

void main() {
  group('Canvas block animation — rendering', () {
    testWidgets('animated block renders without throwing', (tester) async {
      await tester.pumpWidget(_app(
        '$_fadeKeyframes<p style="animation: fade 300ms ease-in-out">Hello</p>',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'animated block with background + transform renders without throwing',
        (tester) async {
      const keyframes = '<style>@keyframes slidein { '
          'from { opacity: 0; transform: translateX(-20px); } '
          'to { opacity: 1; transform: translateX(0); } '
          '}</style>';
      await tester.pumpWidget(_app(
        '$keyframes<div style="animation: slidein 300ms ease; '
        'background-color: #ff0000; padding: 8px;">'
        '<p>Animated block with a background</p></div>',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    });

    testWidgets('nested animated block renders without throwing',
        (tester) async {
      await tester.pumpWidget(_app(
        '$_fadeKeyframes'
        '<div style="animation: fade 200ms linear">'
        '<p style="animation: fade 200ms linear">Nested</p>'
        '</div>',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('animation-delay window renders the static style first',
        (tester) async {
      await tester.pumpWidget(_app(
        '$_fadeKeyframes<p style="animation: fade 200ms linear 300ms">Hello</p>',
      ));
      await tester.pump();
      // Still within the 300ms delay — must not throw or hide content.
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      // Past the delay, into the active phase.
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });

  group('Canvas block animation — frame-loop lifecycle', () {
    testWidgets('non-animated document schedules zero frame callbacks',
        (tester) async {
      await tester.pumpWidget(_app('<p>Hello world</p>'));
      await tester.pumpAndSettle();
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
    });

    testWidgets('running animation schedules a frame callback', (tester) async {
      await tester.pumpWidget(_app(
        '$_fadeKeyframes<p style="animation: fade 300ms linear">Hello</p>',
      ));
      await tester.pump();
      expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));
    });

    testWidgets('paused animation never schedules a frame callback',
        (tester) async {
      await tester.pumpWidget(_app(
        '$_fadeKeyframes<p style="animation: fade 400ms linear infinite; '
        'animation-play-state: paused;">Hello</p>',
      ));
      // A bare pump() races HyperViewer's own unrelated 300ms content-fade-in
      // AnimationController (unrelated to this feature — it may or may not
      // have registered its Ticker by the very first frame). Settle it first
      // so the assertion below isolates the CSS block-animation loop.
      for (int i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
    });

    testWidgets('infinite animation keeps ticking across many frames',
        (tester) async {
      await tester.pumpWidget(_app(
        '$_fadeKeyframes<p style="animation: fade 100ms linear infinite">Hello</p>',
      ));
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(
            SchedulerBinding.instance.transientCallbackCount, greaterThan(0));
      }
    });

    testWidgets('finite animation self-terminates the frame loop',
        (tester) async {
      // NOTE: `animation-iteration-count` is set as a separate longhand
      // rather than a bare trailing number in the shorthand
      // (`animation: fade 100ms linear 1`) — the shorthand parser's
      // `_parseDuration` accepts unitless integers, so a bare "1" is
      // consumed as a second duration (animation-delay: 1ms) before the
      // iteration-count fallback ever sees it. That's a pre-existing
      // resolver ambiguity (also affects the widget-tier animation path,
      // which shares the same shorthand parser), not something introduced
      // here — tracked separately rather than fixed as a drive-by.
      await tester.pumpWidget(_app(
        '$_fadeKeyframes<p style="animation: fade 100ms linear; '
        'animation-iteration-count: 1">Hello</p>',
      ));
      await tester.pump();
      expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));

      // Advance well past duration * iterationCount so the animation
      // finishes. Each tick's "still active?" check reads `finished`, which
      // is only updated by the *previous* frame's paint — so convergence
      // trails real elapsed time by a couple of frames; the margin here
      // (600ms of pumps for a 100ms/1-iteration animation) comfortably
      // covers that lag.
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
    });

    testWidgets('unmounting cancels the frame loop', (tester) async {
      await tester.pumpWidget(_app(
        '$_fadeKeyframes<p style="animation: fade 400ms linear infinite">Hello</p>',
      ));
      await tester.pump();
      expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));

      await tester.pumpWidget(const SizedBox());
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
    });

    testWidgets('flipping animation-play-state to paused stops the frame loop',
        (tester) async {
      const html = '$_fadeKeyframes<p style="animation: fade 400ms linear '
          'infinite; animation-play-state: running">Hello</p>';
      await tester.pumpWidget(_app(html));
      await tester.pump();
      expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));

      const pausedHtml = '$_fadeKeyframes<p style="animation: fade 400ms '
          'linear infinite; animation-play-state: paused">Hello</p>';
      await tester.pumpWidget(_app(pausedHtml));
      // Two independent things need to settle before the count reaches
      // zero: (1) a tick already pending from the running state can fire
      // once more before layout picks up the new (paused) document, and
      // (2) HyperViewer's own unrelated 300ms content-fade-in
      // AnimationController restarts on every new parse and contributes
      // its own transient callback until it completes. 400ms of pumps
      // comfortably covers both.
      for (int i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
    });
  });
}
