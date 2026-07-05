// Security / fuzz tests for v1.5.0 timing-function + color parsing.
//
// Malformed or hostile CSS values must never crash the parser or the renderer;
// they should fall back to safe defaults (keyword curve / null params / null
// color).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

ComputedStyle? _styleOfDiv(String inlineStyle) {
  final adapter = HtmlAdapter();
  final doc = adapter.parse('<div style="$inlineStyle">x</div>');
  final resolver = StyleResolver();
  resolver.resolveStyles(doc);
  ComputedStyle? found;
  void walk(UDTNode n) {
    if (found != null) return;
    if (n.tagName == 'div') {
      found = n.style;
      return;
    }
    for (final c in n.children) {
      walk(c);
    }
  }

  walk(doc);
  return found;
}

void main() {
  group('StyleResolver.parseCssColor null-safety', () {
    test('valid colors parse', () {
      expect(StyleResolver.parseCssColor('#fff'), const Color(0xFFFFFFFF));
      expect(StyleResolver.parseCssColor('#336699'), const Color(0xFF336699));
      expect(StyleResolver.parseCssColor('rgb(255, 0, 0)'),
          const Color(0xFFFF0000));
      expect(StyleResolver.parseCssColor('red'), isNotNull);
    });

    test('invalid hex returns null instead of throwing', () {
      expect(StyleResolver.parseCssColor('#zzz'), isNull);
      expect(StyleResolver.parseCssColor('#gggggg'), isNull);
      expect(StyleResolver.parseCssColor('#12'), isNull);
    });

    test('out-of-range / malformed rgb clamps or returns null', () {
      // Channels clamp into range.
      expect(StyleResolver.parseCssColor('rgb(999, -50, 12)'),
          const Color.fromARGB(255, 255, 0, 12));
      // Beyond int64 → null, no throw.
      expect(StyleResolver.parseCssColor('rgb(999999999999999999999, 0, 0)'),
          isNull);
      expect(StyleResolver.parseCssColor('rgba()'), isNull);
      expect(StyleResolver.parseCssColor('not-a-color'), isNull);
    });
  });

  group('malformed timing functions fall back safely', () {
    const badTimings = <String>[
      'cubic-bezier()',
      'cubic-bezier(1)',
      'cubic-bezier(a, b, c, d)',
      'cubic-bezier(0.1, 0.2, 0.3)',
      'cubic-bezier(0.1, 0.2, 0.3, 0.4, 0.5)',
      'steps()',
      'steps(0)',
      'steps(-3, end)',
      'steps(3, sideways)',
      'steps(999999999999999999999, end)',
      'cubic-bezier(NaN, 0, 0, 1)',
      'cubic-bezier(0,0,0,0); background:url(javascript:alert(1))',
      'wobble-bezier(0,0,1,1)',
    ];

    for (final t in badTimings) {
      test('transition "$t" does not throw', () {
        expect(() => _styleOfDiv('transition: all 1s $t'), returnsNormally);
        final style = _styleOfDiv('transition: all 1s $t');
        // Whatever survives, it must be a valid transition object.
        expect(style, isNotNull);
      });
    }

    testWidgets('renderer survives malformed timing in a real document',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html:
                  '<div style="transition: all 1s cubic-bezier(a,b,c,d); animation-timing-function: steps(-1, nowhere)">x</div>',
              mode: HyperRenderMode.sync,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  });

  group('malformed colors in keyframes fall back safely', () {
    testWidgets('garbage color keyframe values do not crash renderer',
        (tester) async {
      const html = '''
<style>
  @keyframes bad {
    from { background-color: not-a-color; color: #zzz; }
    to   { background-color: rgb(999, -50, 12); color: rgba(); }
  }
  .b { width: 40px; height: 40px; }
</style>
<div class="b" style="animation: bad 1s infinite;"></div>
''';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, mode: HyperRenderMode.sync),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    });

    testWidgets('animated color cannot smuggle a script URL', (tester) async {
      // Ensure color parsing never treats a url()/javascript: payload as valid.
      const html = '''
<style>
  @keyframes x { from { color: url(javascript:alert(1)); } to { color: #fff; } }
  .b { width: 40px; height: 40px; }
</style>
<div class="b" style="animation: x 1s infinite;"></div>
''';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, mode: HyperRenderMode.sync),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  });
}
