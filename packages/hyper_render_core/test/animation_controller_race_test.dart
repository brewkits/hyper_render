import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

/// Repro / falsification test for the v1.3.3 review claim that
/// [HyperAnimatedWidget] crashes when a fast `didUpdateWidget` cycle
/// replaces the [AnimationController] while a `Future.delayed`-based
/// start is still pending.
///
/// The claim was that the closure captures the OLD `_controller` value
/// at the moment `_setupAnimation()` runs, so when the timer fires after
/// `didUpdateWidget` has called `_controller.dispose()` and assigned a
/// new instance, `forward()` is invoked on the disposed object and
/// throws.
///
/// That is not how Dart closures capture instance fields. A closure
/// over `_controller` captures the implicit `this` and reads
/// `this._controller` at call time — which always points to the
/// currently-live controller. This test makes the race observable:
/// build the widget, change its animationName mid-flight (forcing
/// `didUpdateWidget` to dispose and recreate the controller), pump
/// past the delay, and assert no exception was thrown.
///
/// If a future refactor switches to capturing the local controller
/// reference instead of the field, this test will fail and the claim
/// becomes accurate again.
void main() {
  testWidgets(
    'didUpdateWidget mid-delay does not crash on stale Future.delayed',
    (tester) async {
      // Built-in fadeIn / fadeOut differ enough that
      // HyperAnimatedWidget.didUpdateWidget takes the dispose-and-recreate
      // branch when the animationName changes between pumps.
      Widget build(String name) => MaterialApp(
            home: Scaffold(
              body: HyperAnimatedWidget(
                animationName: name,
                duration: const Duration(milliseconds: 100),
                delay: const Duration(milliseconds: 50),
                iterationCount: 1, // one-shot — avoid the infinite loop
                child: const SizedBox(width: 10, height: 10),
              ),
            ),
          );

      await tester.pumpWidget(build('fadeIn'));
      // Trigger didUpdateWidget BEFORE the 50 ms start delay fires.
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pumpWidget(build('fadeOut'));

      // Pump past the delay window. If the original Future.delayed had
      // captured the disposed controller (TL's claim) this would surface
      // "AnimationController used after dispose". We deliberately do NOT
      // pumpAndSettle — the animation only auto-completes after the
      // 100 ms duration and that adds nothing to the falsification.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull,
          reason:
              'stale Timer must not touch the disposed controller after '
              '_setupAnimation reassigned _controller');
      // Tear down cleanly so the test ends.
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
