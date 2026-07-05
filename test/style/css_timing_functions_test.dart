// Tests for cubic-bezier() and steps() CSS timing functions (v1.5.0).
//
// Covers: transition + animation shorthand/longhand parsing, parameter
// clamping, malformed-value fallback, and the HyperStepsCurve behaviour.

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

void main() {
  group('transition timing functions', () {
    test('parses cubic-bezier() control points', () {
      final style = _styleOfTag(
        '<div style="transition: opacity 0.3s cubic-bezier(0.4, 0, 0.2, 1)">x</div>',
        'div',
      );
      final t = style!.transition!;
      expect(t.duration, 300);
      expect(t.timingFunction, HyperTimingFunction.cubicBezier);
      final params = t.timingParams;
      expect(params, isA<HyperCubicBezierParams>());
      params as HyperCubicBezierParams;
      expect(params.x1, closeTo(0.4, 1e-9));
      expect(params.y1, closeTo(0.0, 1e-9));
      expect(params.x2, closeTo(0.2, 1e-9));
      expect(params.y2, closeTo(1.0, 1e-9));
    });

    test('clamps cubic-bezier x control points to [0, 1]', () {
      final style = _styleOfTag(
        '<div style="transition: all 1s cubic-bezier(1.5, -0.5, 2, 1.5)">x</div>',
        'div',
      );
      final params = style!.transition!.timingParams as HyperCubicBezierParams;
      expect(params.x1, 1.0);
      expect(params.x2, 1.0);
      // y stays unbounded per spec.
      expect(params.y1, -0.5);
      expect(params.y2, 1.5);
    });

    test('parses steps(n, end) and steps(n, start)', () {
      final endStyle = _styleOfTag(
        '<div style="transition: transform 1s steps(4, end)">x</div>',
        'div',
      );
      final endParams = endStyle!.transition!.timingParams as HyperStepsParams;
      expect(endParams.count, 4);
      expect(endParams.jumpStart, isFalse);

      final startStyle = _styleOfTag(
        '<div style="transition: transform 1s steps(3, start)">x</div>',
        'div',
      );
      final startParams =
          startStyle!.transition!.timingParams as HyperStepsParams;
      expect(startParams.count, 3);
      expect(startParams.jumpStart, isTrue);
    });

    test('step-start and step-end keywords', () {
      final start = _styleOfTag(
        '<div style="transition: opacity 1s step-start">x</div>',
        'div',
      );
      final startParams = start!.transition!.timingParams as HyperStepsParams;
      expect(startParams.count, 1);
      expect(startParams.jumpStart, isTrue);

      final end = _styleOfTag(
        '<div style="transition: opacity 1s step-end">x</div>',
        'div',
      );
      final endParams = end!.transition!.timingParams as HyperStepsParams;
      expect(endParams.jumpStart, isFalse);
    });
  });

  group('animation shorthand timing functions', () {
    test('cubic-bezier() inside animation shorthand is not split on commas',
        () {
      final style = _styleOfTag(
        '<div style="animation: spin 2s cubic-bezier(0.1, 0.7, 1, 0.1) infinite">x</div>',
        'div',
      );
      expect(style!.animationName, 'spin');
      expect(style.animationDuration, 2000);
      expect(style.animationIterationCount, isNull); // infinite
      expect(style.animationTimingFunction, HyperTimingFunction.cubicBezier);
      final params = style.animationTimingParams as HyperCubicBezierParams;
      expect(params.x1, closeTo(0.1, 1e-9));
      expect(params.y2, closeTo(0.1, 1e-9));
    });

    test('animation-timing-function longhand with steps()', () {
      final style = _styleOfTag(
        '<div style="animation-timing-function: steps(6, start)">x</div>',
        'div',
      );
      expect(style!.animationTimingFunction, HyperTimingFunction.steps);
      final params = style.animationTimingParams as HyperStepsParams;
      expect(params.count, 6);
      expect(params.jumpStart, isTrue);
    });
  });

  group('HyperStepsCurve', () {
    test('steps(4, end) jumps at end of each interval', () {
      const curve = HyperStepsCurve(4);
      expect(curve.transform(0.0), 0.0);
      expect(curve.transform(0.1), 0.0);
      expect(curve.transform(0.25), closeTo(0.25, 1e-9));
      expect(curve.transform(0.4), closeTo(0.25, 1e-9));
      expect(curve.transform(0.6), closeTo(0.5, 1e-9));
      expect(curve.transform(1.0), 1.0);
    });

    test('steps(4, start) jumps at start of each interval', () {
      const curve = HyperStepsCurve(4, jumpStart: true);
      expect(curve.transform(0.0), 0.0);
      expect(curve.transform(0.01), closeTo(0.25, 1e-9));
      expect(curve.transform(0.25), closeTo(0.25, 1e-9));
      expect(curve.transform(0.26), closeTo(0.5, 1e-9));
      expect(curve.transform(1.0), 1.0);
    });
  });

  group('HyperViewer renders parameterized timing without crash', () {
    testWidgets('cubic-bezier transition', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html:
                  '<div style="opacity:0.5;transition:opacity 0.3s cubic-bezier(0.4,0,0.2,1)">hi</div>',
              mode: HyperRenderMode.sync,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
