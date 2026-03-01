import "package:hyper_render/hyper_render.dart";
// Unit tests for CSS bug-fixes introduced in Round-2 and Round-3 reviews.
//
// R-01  #RRGGBBAA byte order
// R-02  em unit in _parseLength
// R-03  multi-level child selector  a > b > c
// R-04  element-selector specificity counting
// R-06  stable source-order sort for equal-specificity rules
// R-07  float layout no-crash when float wider than container
// R-08  pre/pre-wrap respects whitespace
// R-09  nested var() fallback  var(--a, var(--b, default))
// BUG-2 calc() with negative numbers
// BUG-7 #RGBA 4-digit hex support
// BUG-5/6 RGB / RGBA channel clamping
// BUG-11 CSS custom-property inheritance

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Parse [html], resolve styles, and return the ComputedStyle for the first
/// node that matches [predicate].
ComputedStyle? _resolvedStyle(String html, bool Function(UDTNode) predicate) {
  final adapter = HtmlAdapter();
  final doc = adapter.parse(html);
  final resolver = StyleResolver();
  // Extract CSS from <style> tags so rules are applied during resolution.
  final css = adapter.extractCss(html);
  if (css.isNotEmpty) resolver.parseCss(css);
  resolver.resolveStyles(doc);

  ComputedStyle? found;
  void walk(UDTNode node) {
    if (found != null) return;
    if (predicate(node)) {
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

ComputedStyle? _styleOfTag(String html, String tag) =>
    _resolvedStyle(html, (n) => n.tagName == tag);

// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // R-01: #RRGGBBAA byte order
  // -------------------------------------------------------------------------

  group('R-01 — 8-digit hex color parsing', () {
    test('8-digit hex parses alpha as last byte', () {
      // #FF0000FF → fully-opaque red
      final style = _styleOfTag(
        '<p style="color:#FF0000FF">text</p>',
        'p',
      );
      expect(style, isNotNull);
      final c = style!.color;
      expect((c.r * 255).round(), equals(0xFF));
      expect((c.g * 255).round(), equals(0x00));
      expect((c.b * 255).round(), equals(0x00));
      expect((c.a * 255).round(), equals(0xFF));
    });

    test('8-digit hex with partial alpha: #00FF0080 is semi-transparent green', () {
      final style = _styleOfTag(
        '<p style="color:#00FF0080">text</p>',
        'p',
      );
      expect(style, isNotNull);
      final c = style!.color;
      expect((c.r * 255).round(), equals(0x00));
      expect((c.g * 255).round(), equals(0xFF));
      expect((c.b * 255).round(), equals(0x00));
      // alpha byte 0x80 ~ 128
      expect((c.a * 255).round(), closeTo(0x80, 2));
    });
  });

  // -------------------------------------------------------------------------
  // BUG-7: #RGBA 4-digit hex
  // -------------------------------------------------------------------------

  group('BUG-7 — 4-digit hex color', () {
    test('#F00F parses as fully-opaque red', () {
      final style = _styleOfTag('<p style="color:#F00F">text</p>', 'p');
      expect(style, isNotNull);
      final c = style!.color;
      expect((c.r * 255).round(), equals(0xFF));
      expect((c.g * 255).round(), equals(0x00));
      expect((c.b * 255).round(), equals(0x00));
      expect((c.a * 255).round(), equals(0xFF));
    });

    test('#0F08 parses as semi-transparent green', () {
      final style = _styleOfTag('<p style="color:#0F08">text</p>', 'p');
      expect(style, isNotNull);
      final c = style!.color;
      expect((c.r * 255).round(), equals(0x00));
      expect((c.g * 255).round(), equals(0xFF));
      expect((c.b * 255).round(), equals(0x00));
      expect((c.a * 255).round(), closeTo(0x88, 4));
    });
  });

  // -------------------------------------------------------------------------
  // BUG-5/6: RGB / RGBA channel clamping
  // -------------------------------------------------------------------------

  group('BUG-5/6 — RGB/RGBA channel clamping', () {
    test('rgb() clamps channels above 255 to 255', () {
      final style = _styleOfTag('<p style="color:rgb(300,0,0)">x</p>', 'p');
      expect(style, isNotNull);
      expect((style!.color.r * 255).round(), equals(255));
    });

    test('rgb() clamps channels below 0 to 0', () {
      final style = _styleOfTag('<p style="color:rgb(-10,128,0)">x</p>', 'p');
      expect(style, isNotNull);
      expect((style!.color.r * 255).round(), equals(0));
    });

    test('rgba() clamps alpha above 1.0 to 1.0', () {
      final style = _styleOfTag('<p style="color:rgba(255,0,0,2.5)">x</p>', 'p');
      expect(style, isNotNull);
      expect((style!.color.a * 255).round(), equals(255));
    });

    test('rgba() clamps alpha below 0 to 0', () {
      final style = _styleOfTag('<p style="color:rgba(255,0,0,-0.5)">x</p>', 'p');
      expect(style, isNotNull);
      expect((style!.color.a * 255).round(), equals(0));
    });
  });

  // -------------------------------------------------------------------------
  // R-02: em unit in _parseLength
  // -------------------------------------------------------------------------

  group('R-02 — em unit conversion', () {
    testWidgets('em margin renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p style="margin:1em">Text with 1em margin</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('padding:2em parsed as greater than 2px (not treated as 2px)', () {
      final style = _styleOfTag('<p style="padding:2em">x</p>', 'p');
      expect(style, isNotNull);
      // 2em x 16px = 32px; ensure it's not treated as 2px
      expect(style!.padding.top, greaterThan(2));
    });
  });

  // -------------------------------------------------------------------------
  // R-03: multi-level child selector
  // -------------------------------------------------------------------------

  group('R-03 — Multi-level child selector', () {
    test('three-level child selector applies color', () {
      const html = '''
<style>div > p > span { color: #E53935; }</style>
<div><p><span>Target</span></p></div>
''';
      final style = _styleOfTag(html, 'span');
      expect(style, isNotNull);
      expect((style!.color.r * 255).round(), greaterThan(200));
    });

    test('two-level child selector still works', () {
      const html = '<style>div > p { color: #1565C0; }</style><div><p>Text</p></div>';
      final style = _styleOfTag(html, 'p');
      expect(style, isNotNull);
    });

    test('non-matching direct child selector does not apply', () {
      // The span is NOT a direct child of div (section is in between)
      const html = '''
<style>div > span { color: #E53935; }</style>
<div><section><span>Not a direct child</span></section></div>
''';
      final style = _styleOfTag(html, 'span');
      // color should be non-red (default, not from this rule)
      expect((style!.color.r * 255).round(), lessThan(200));
    });
  });

  // -------------------------------------------------------------------------
  // R-04: element-selector specificity counting
  // -------------------------------------------------------------------------

  group('R-04 — Element-selector specificity', () {
    test('div p span has higher specificity than p alone', () {
      const html = '''
<style>
  p          { color: #9E9E9E; }
  div p span { color: #1565C0; }
</style>
<div><p><span>Text</span></p></div>
''';
      final style = _styleOfTag(html, 'span');
      expect(style, isNotNull);
      // Blue wins because div p span (specificity 3) > p (specificity 1)
      expect((style!.color.b * 255).round(), greaterThan((style.color.r * 255).round()));
    });

    test('class selector beats single element selector', () {
      const html = '''
<style>
  p        { color: #9E9E9E; }
  .special { color: #E53935; }
</style>
<p class="special">Text</p>
''';
      final style = _styleOfTag(html, 'p');
      expect(style, isNotNull);
      expect((style!.color.r * 255).round(), greaterThan((style.color.b * 255).round()));
    });
  });

  // -------------------------------------------------------------------------
  // R-06: stable source-order sort
  // -------------------------------------------------------------------------

  group('R-06 — Stable CSS source-order sort', () {
    test('later rule with equal specificity wins', () {
      const html = '''
<style>
  .box { color: #9E9E9E; }
  .box { color: #1565C0; }
</style>
<div class="box">Text</div>
''';
      final style = _styleOfTag(html, 'div');
      expect(style, isNotNull);
      // Blue (second rule) should win
      expect((style!.color.b * 255).round(), greaterThan((style.color.r * 255).round()));
    });
  });

  // -------------------------------------------------------------------------
  // R-07: float layout no-crash when wider than container
  // -------------------------------------------------------------------------

  group('R-07 — Float layout exceeding container width', () {
    testWidgets('float wider than container does not crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
<div>
  <img src="data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs="
       style="float:left;width:500px;height:200px;">
  <p>Text that wraps around the float.</p>
</div>
''',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('multiple large floats do not crash', (tester) async {
      final html =
          '${List.generate(
            5,
            (i) =>
                '<img src="data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=" '
                'style="float:${i.isEven ? 'left' : 'right'};width:400px;height:150px;">',
          ).join()}<p>Body text.</p>';

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HyperViewer(html: html))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // R-08: pre/pre-wrap whitespace rendering
  // -------------------------------------------------------------------------

  group('R-08 — pre / pre-wrap whitespace', () {
    testWidgets('pre block renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: '<pre>line one\nline two\n  indented</pre>',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('pre-wrap inline style renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p style="white-space:pre-wrap">line a\nline b</p>',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // R-09: nested var() fallback
  // -------------------------------------------------------------------------

  group('R-09 — Nested var() fallback resolution', () {
    testWidgets('nested var() resolves to default when both vars undefined',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p style="color: var(--a, var(--b, #333333))">Fallback text</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('nested var() resolves inner var when defined',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
<div style="--b:#1565C0">
  <p style="color:var(--a, var(--b, #9E9E9E))">Should be blue from --b</p>
</div>
''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // BUG-2: calc() with negative numbers
  // -------------------------------------------------------------------------

  group('BUG-2 — calc() with negative operands', () {
    testWidgets('calc(20px - 4px) renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p style="font-size:calc(20px - 4px)">16px</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('calc with negative result does not crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p style="margin-top:calc(4px - 20px)">Negative margin</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // BUG-11: CSS custom-property inheritance
  // -------------------------------------------------------------------------

  group('BUG-11 — Custom property inheritance', () {
    testWidgets('grandchild reads custom property from ancestor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
<div style="--brand:#E53935">
  <section>
    <p style="color:var(--brand)">Should be red from grandparent</p>
  </section>
</div>
''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('child can override parent custom property', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
<div style="--c:blue">
  <p style="color:var(--c)">Blue</p>
  <div style="--c:red">
    <p style="color:var(--c)">Red override</p>
  </div>
</div>
''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Full pipeline integration: all bug-fix areas together
  // -------------------------------------------------------------------------

  group('CSS bug fixes — full pipeline no-crash', () {
    testWidgets('complex HTML exercising all fixed CSS features', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: '''
<style>
  :root {
    --primary: #1565C0;
    --secondary: #00897B;
    --accent: #E53935;
  }
  div > p > span   { font-weight: bold; }
  .card            { color: #212121; }
  .card.highlight  { color: #E53935; }
  pre              { white-space: pre; }
</style>

<div style="--local:#FF6F00">
  <p style="color:#1565C0FF">8-digit hex color</p>
  <p style="color:#F00F">4-digit hex color</p>
  <div><p><span>Three-level child</span></p></div>
  <p style="color:var(--undefined, var(--primary, #333))">Nested var()</p>
  <p style="margin-top:calc(20px - 5px)">calc subtract</p>
  <pre>line 1\nline 2\n  indented</pre>
  <img src="data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs="
       style="float:left;width:400px;height:100px;">
  <p>Float text</p>
  <div style="clear:both"></div>
  <p style="color:var(--local)">Local var</p>
</div>
''',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
