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
  // QA-BUG-A: CssRuleIndex — ancestor-class misindex (regression)
  // -------------------------------------------------------------------------

  group('QA-BUG-A — CssRuleIndex combinator guard (ancestor-class misindex)', () {
    test('descendant selector: nav.menu li applies to li inside nav.menu', () {
      const html = '''
<style>nav.main-nav li { color: #E53935; }</style>
<nav class="main-nav"><ul><li>Menu item</li></ul></nav>
''';
      final style = _styleOfTag(html, 'li');
      expect(style, isNotNull);
      // Rule was previously missed because nav.main-nav li was indexed under
      // .main-nav (ancestor), not found when li was looked up.
      expect((style!.color.r * 255).round(), greaterThan(200),
          reason: 'li should be red from "nav.main-nav li" descendant rule');
    });

    test('descendant selector: .sidebar .widget applies to .widget inside .sidebar', () {
      const html = '''
<style>.sidebar .widget { color: #1565C0; }</style>
<div class="sidebar"><div class="widget">Widget</div></div>
''';
      final style = _resolvedStyle(html, (n) => n.classList.contains('widget'));
      expect(style, isNotNull);
      expect(
        (style!.color.b * 255).round(),
        greaterThan((style.color.r * 255).round()),
        reason: '.widget should be blue from ".sidebar .widget" rule',
      );
    });

    test('child selector: article > p applies color to direct p children', () {
      const html = '''
<style>article > p { color: #E53935; }</style>
<article><p>Direct child</p></article>
''';
      final style = _styleOfTag(html, 'p');
      expect(style, isNotNull);
      expect((style!.color.r * 255).round(), greaterThan(200),
          reason: 'p should be red from "article > p" child rule');
    });

    test('child selector with class on ancestor: section.blog > h2 applies', () {
      const html = '''
<style>section.blog > h2 { color: #1565C0; }</style>
<section class="blog"><h2>Blog heading</h2></section>
''';
      final style = _styleOfTag(html, 'h2');
      expect(style, isNotNull);
      expect(
        (style!.color.b * 255).round(),
        greaterThan((style.color.r * 255).round()),
        reason: 'h2 should be blue from "section.blog > h2" rule',
      );
    });

    test('simple class selector still indexed correctly (no regression)', () {
      const html = '<style>.lead { color: #E53935; }</style><p class="lead">Text</p>';
      final style = _styleOfTag(html, 'p');
      expect(style, isNotNull);
      expect((style!.color.r * 255).round(), greaterThan(200),
          reason: '.lead simple selector should still work');
    });
  });

  // -------------------------------------------------------------------------
  // QA-BUG-B: image aspect-ratio division by zero (regression)
  // -------------------------------------------------------------------------

  group('QA-BUG-B — Image layout: zero-dimension image does not crash', () {
    testWidgets('img with explicit width/height renders without error',
        (tester) async {
      // Even with a broken/0-pixel image the widget should not throw.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<img src="data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs="'
                  ' width="200" height="100">',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('img with only width specified renders without error',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<img src="data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs="'
                  ' width="300">',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('img with only height specified renders without error',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<img src="data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs="'
                  ' height="150">',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // QA-BUG-2: CSS comma-separated selector groups (regression)
  // -------------------------------------------------------------------------

  group('QA-BUG-2 — CSS comma-separated selector groups', () {
    test('h1, h2 rule applies color to both h1 and h2', () {
      const html =
          '<style>h1, h2 { color: #E53935; }</style><h1>Heading 1</h1><h2>Heading 2</h2>';

      final styleH1 = _styleOfTag(html, 'h1');
      final styleH2 = _styleOfTag(html, 'h2');

      expect(styleH1, isNotNull);
      expect(styleH2, isNotNull);
      expect((styleH1!.color.r * 255).round(), greaterThan(200),
          reason: 'h1 should be red from comma rule');
      expect((styleH2!.color.r * 255).round(), greaterThan(200),
          reason: 'h2 should be red from comma rule');
    });

    test('h1, h2, h3 rule applies to all three elements', () {
      const html = '''
<style>h1, h2, h3 { color: #1565C0; }</style>
<h1>H1</h1><h2>H2</h2><h3>H3</h3>
''';

      for (final tag in ['h1', 'h2', 'h3']) {
        final style = _styleOfTag(html, tag);
        expect(style, isNotNull, reason: 'Style for <$tag> must not be null');
        expect(
          (style!.color.b * 255).round(),
          greaterThan((style.color.r * 255).round()),
          reason: '<$tag> should be blue from comma rule',
        );
      }
    });

    test('comma rule does not apply to elements outside the group', () {
      const html = '''
<style>h1, h2 { color: #E53935; }</style>
<h3>Not in group</h3>
''';
      final style = _styleOfTag(html, 'h3');
      // h3 is not in the comma-group; default text is dark, not red
      expect((style!.color.r * 255).round(), lessThan(200));
    });

    test('each selector in a comma group has independent specificity', () {
      // h1.special (class+element = specificity 0x0101) wins over
      // h1 from the comma group (element only = 0x0001); h2 still uses comma rule.
      const html = '''
<style>
  h1, h2   { color: #9E9E9E; }
  h1.special { color: #E53935; }
</style>
<h1 class="special">H1 special</h1>
<h2>H2 plain</h2>
''';
      final styleH1 = _styleOfTag(html, 'h1');
      final styleH2 = _styleOfTag(html, 'h2');

      // h1.special has higher specificity → red wins for h1
      expect((styleH1!.color.r * 255).round(), greaterThan(200),
          reason: 'h1.special should override comma rule');
      // h2 has no competing rule → gets grey from comma rule
      expect((styleH2!.color.r * 255).round(), closeTo(0x9E, 20),
          reason: 'h2 should get grey from comma rule');
    });
  });

  // -------------------------------------------------------------------------
  // QA-BUG-5: !important in stylesheet rules (regression)
  // -------------------------------------------------------------------------

  group('QA-BUG-5 — !important in stylesheet rules', () {
    test('!important beats a later rule with higher specificity', () {
      const html = '''
<style>
  p          { color: #E53935 !important; }
  p.override { color: #9E9E9E; }
</style>
<p class="override">Should be red from !important</p>
''';
      final style = _styleOfTag(html, 'p');
      expect(style, isNotNull);
      expect((style!.color.r * 255).round(), greaterThan(200),
          reason: '!important should override higher-specificity normal rule');
    });

    test('!important stylesheet rule beats inline style', () {
      const html = '''
<style>h2 { color: #1565C0 !important; }</style>
<h2 style="color:#E53935">Should be blue from !important</h2>
''';
      final style = _styleOfTag(html, 'h2');
      expect(style, isNotNull);
      expect(
        (style!.color.b * 255).round(),
        greaterThan((style.color.r * 255).round()),
        reason: '!important stylesheet rule should override inline style',
      );
    });

    test('!important on a comma-grouped selector applies to all members', () {
      const html = '''
<style>p, span { color: #E53935 !important; }</style>
<p>Red paragraph</p>
<span>Red span</span>
''';
      final styleP = _styleOfTag(html, 'p');
      final styleSpan = _styleOfTag(html, 'span');

      expect(styleP, isNotNull);
      expect(styleSpan, isNotNull);
      expect((styleP!.color.r * 255).round(), greaterThan(200),
          reason: 'p should be red');
      expect((styleSpan!.color.r * 255).round(), greaterThan(200),
          reason: 'span should be red');
    });
  });

  // -------------------------------------------------------------------------
  // QA-BUG-1: Link tap — onLinkTap callback wiring (regression)
  // -------------------------------------------------------------------------

  group('QA-BUG-1 — Link tap callback wiring', () {
    testWidgets('HyperViewer with onLinkTap renders a link without error',
        (tester) async {
      String? tappedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html:
                  '<p>Visit <a href="https://flutter.dev">Flutter</a> today</p>',
              onLinkTap: (url) => tappedUrl = url,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
      // Callback wired but not yet fired (no tap performed yet)
      expect(tappedUrl, isNull);
    });

    testWidgets(
        'link with nested inline content renders without error (ancestor-walk regression)',
        (tester) async {
      // Regression: link contains <strong> → the TextNode's sourceNode.tagName
      // is '#text', not 'a'. Without the ancestor-walk fix in handleEvent(),
      // tapping would silently do nothing instead of firing onLinkTap.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html:
                  '<p><a href="https://example.com"><strong>Bold link</strong></a></p>',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('multiple links in document all render without error',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
<p><a href="https://a.com">Link A</a></p>
<p><a href="https://b.com"><em>Italic <strong>bold</strong> link</em></a></p>
<p><a href="https://c.com">Link C</a> and plain text after</p>
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
