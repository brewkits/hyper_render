// Tests for CSS `animation-play-state` (longhand + `animation` shorthand)
// and its execution in HyperAnimatedWidget: paused animations hold their
// current frame and resume from it when flipped back to running.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

ComputedStyle? _styleOfTag(String html, String tag) {
  final adapter = HtmlAdapter();
  final doc = adapter.parse(html);
  final resolver = StyleResolver();
  final css = adapter.extractCss(html);
  if (css.isNotEmpty) resolver.parseCss(css);
  resolver.resolveStyles(doc);

  ComputedStyle? found;
  void walk(UDTNode node) {
    if (found != null) return;
    if (node.tagName == tag) {
      found = node.style;
      return;
    }
    for (final c in node.children) {
      walk(c);
    }
  }

  walk(doc);
  return found;
}

double _opacityOf(WidgetTester tester) =>
    tester.widget<Opacity>(find.byType(Opacity).first).opacity;

Widget _animatedFadeIn({required bool paused, int? iterationCount = 1}) {
  return MaterialApp(
    home: HyperAnimatedWidget(
      animationName: 'fadeIn',
      duration: const Duration(milliseconds: 400),
      iterationCount: iterationCount,
      paused: paused,
      child: const Text('x'),
    ),
  );
}

void main() {
  group('animation-play-state parsing', () {
    test('longhand paused', () {
      final style = _styleOfTag(
        '<div style="animation-name: spin; animation-play-state: paused">x</div>',
        'div',
      );
      expect(style!.animationPlayState, HyperAnimationPlayState.paused);
    });

    test('longhand running (explicit)', () {
      final style = _styleOfTag(
        '<div style="animation-name: spin; animation-play-state: running">x</div>',
        'div',
      );
      expect(style!.animationPlayState, HyperAnimationPlayState.running);
      expect(style.isExplicitlySet('animation-play-state'), isTrue);
    });

    test('defaults to running', () {
      final style = _styleOfTag(
        '<div style="animation-name: spin">x</div>',
        'div',
      );
      expect(style!.animationPlayState, HyperAnimationPlayState.running);
      expect(style.isExplicitlySet('animation-play-state'), isFalse);
    });

    test('shorthand consumes paused without eating the animation name', () {
      final style = _styleOfTag(
        '<div style="animation: spin 2s linear infinite paused">x</div>',
        'div',
      );
      expect(style!.animationPlayState, HyperAnimationPlayState.paused);
      expect(style.animationName, 'spin');
      expect(style.animationDuration, 2000);
      expect(style.animationIterationCount, isNull); // infinite
      expect(style.animationTimingFunction, HyperTimingFunction.linear);
    });

    test('shorthand running keyword is not treated as the name', () {
      final style = _styleOfTag(
        '<div style="animation: 1s running fadeIn">x</div>',
        'div',
      );
      expect(style!.animationPlayState, HyperAnimationPlayState.running);
      expect(style.animationName, 'fadeIn');
    });

    test('invalid value is ignored', () {
      final style = _styleOfTag(
        '<div style="animation-play-state: bogus">x</div>',
        'div',
      );
      expect(style!.animationPlayState, HyperAnimationPlayState.running);
      expect(style.isExplicitlySet('animation-play-state'), isFalse);
    });

    test('value from <style> tag CSS rules', () {
      final style = _styleOfTag(
        '<style>.p { animation: fadeIn 1s paused; }</style>'
            '<div class="p">x</div>',
        'div',
      );
      expect(style!.animationPlayState, HyperAnimationPlayState.paused);
    });

    test('copyWith preserves and overrides play state', () {
      final style = ComputedStyle(
        animationPlayState: HyperAnimationPlayState.paused,
      );
      expect(
          style.copyWith().animationPlayState, HyperAnimationPlayState.paused);
      expect(
        style
            .copyWith(animationPlayState: HyperAnimationPlayState.running)
            .animationPlayState,
        HyperAnimationPlayState.running,
      );
    });

    test('fromStyle maps play state to the paused flag', () {
      final style = ComputedStyle(
        animationName: 'spin',
        animationPlayState: HyperAnimationPlayState.paused,
      );
      final w = HyperAnimatedWidget.fromStyle(
        style: style,
        child: const SizedBox(),
      );
      expect(w.paused, isTrue);
    });
  });

  group('HyperAnimatedWidget play state execution', () {
    testWidgets('paused widget never starts animating', (tester) async {
      await tester.pumpWidget(_animatedFadeIn(paused: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(_opacityOf(tester), 0.0);
    });

    testWidgets('flipping paused → running starts the animation',
        (tester) async {
      await tester.pumpWidget(_animatedFadeIn(paused: true));
      await tester.pump(const Duration(milliseconds: 600));
      expect(_opacityOf(tester), 0.0);

      await tester.pumpWidget(_animatedFadeIn(paused: false));
      // First short pump fires the zero-delay start timer and delivers the
      // ticker's first tick (elapsed 0); the next pump advances the animation.
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_opacityOf(tester), 1.0);
    });

    testWidgets('pausing mid-flight freezes the frame; resume continues',
        (tester) async {
      await tester.pumpWidget(_animatedFadeIn(paused: false));
      await tester.pump(const Duration(milliseconds: 1)); // start + first tick
      await tester.pump(const Duration(milliseconds: 200));
      final midValue = _opacityOf(tester);
      expect(midValue, greaterThan(0.0));
      expect(midValue, lessThan(1.0));

      await tester.pumpWidget(_animatedFadeIn(paused: true));
      await tester.pump(const Duration(milliseconds: 500));
      expect(_opacityOf(tester), midValue);

      await tester.pumpWidget(_animatedFadeIn(paused: false));
      await tester.pump(const Duration(milliseconds: 1)); // first tick
      await tester.pump(const Duration(milliseconds: 400));
      expect(_opacityOf(tester), 1.0);
    });

    testWidgets('paused infinite animation resumes with repeat',
        (tester) async {
      await tester
          .pumpWidget(_animatedFadeIn(paused: true, iterationCount: null));
      await tester.pump(const Duration(milliseconds: 600));
      expect(_opacityOf(tester), 0.0);

      await tester
          .pumpWidget(_animatedFadeIn(paused: false, iterationCount: null));
      await tester.pump(const Duration(milliseconds: 1)); // start + first tick
      await tester.pump(const Duration(milliseconds: 200));
      expect(_opacityOf(tester), greaterThan(0.0));

      // Unmount to stop the repeating controller before the test ends.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('rebuild with a new duration restarts iteration counting',
        (tester) async {
      // Run a 1-iteration animation to completion.
      await tester.pumpWidget(_animatedFadeIn(paused: false));
      await tester.pump(const Duration(milliseconds: 1)); // start + first tick
      await tester.pump(const Duration(milliseconds: 500));
      expect(_opacityOf(tester), 1.0);

      // Changing duration rebuilds the controller; the iteration counter
      // must reset so the new animation plays its full iteration again.
      await tester.pumpWidget(const MaterialApp(
        home: HyperAnimatedWidget(
          animationName: 'fadeIn',
          duration: Duration(milliseconds: 300),
          iterationCount: 1,
          child: Text('x'),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 1)); // start + first tick
      expect(_opacityOf(tester), 0.0);
      await tester.pump(const Duration(milliseconds: 150));
      final mid = _opacityOf(tester);
      expect(mid, greaterThan(0.0));
      await tester.pump(const Duration(milliseconds: 200));
      expect(_opacityOf(tester), 1.0);
    });
  });
}
