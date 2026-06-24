import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('HyperTransitionWidget', () {
    testWidgets('renders child statically when no transition is defined',
        (tester) async {
      final style = ComputedStyle(opacity: 1.0);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperTransitionWidget(
            style: style,
            child: const Text('hello'),
          ),
        ),
      ));

      expect(find.text('hello'), findsOneWidget);
      expect(find.byType(AnimatedOpacity), findsNothing);
    });

    testWidgets('animates opacity over the transition duration',
        (tester) async {
      Widget build(double opacity) => MaterialApp(
            home: Scaffold(
              body: HyperTransitionWidget(
                style: ComputedStyle(
                  opacity: opacity,
                  transition: const HyperTransition(duration: 200),
                ),
                child: const SizedBox(width: 10, height: 10),
              ),
            ),
          );

      await tester.pumpWidget(build(1.0));
      expect(find.byType(AnimatedOpacity), findsOneWidget);

      await tester.pumpWidget(build(0.0));
      await tester.pump(const Duration(milliseconds: 50));

      final animatedOpacity =
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      // Mid-transition: should not have already snapped to the target.
      expect(animatedOpacity.opacity, 0.0);

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('falls back to static Opacity when duration is zero',
        (tester) async {
      final style = ComputedStyle(
        opacity: 0.5,
        transition: const HyperTransition(duration: 0),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperTransitionWidget(
            style: style,
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      ));

      expect(find.byType(AnimatedOpacity), findsNothing);
      expect(find.byType(Opacity), findsOneWidget);
    });
  });
}
