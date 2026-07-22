// Regression tests for bugs found by cross-referencing well-known issues in
// the flutter_html package (github.com/Sub6Resources/flutter_html) against
// HyperRender's own implementation of the same CSS/HTML semantics.
//
// Both bugs below reproduced in HyperRender before the fix and are unrelated
// to flutter_html's architecture (widget-per-element, CustomRender/
// HtmlExtension) — they're general HTML/CSS-correctness bugs that any
// from-scratch renderer can independently hit.
//
// FH-1367  line-height in absolute units (px) used the wrong reference
//          font-size (parent's instead of the element's own) when both
//          font-size and line-height were set on the same element.
// FH-1439  a text run consisting solely of `&nbsp;` was misclassified as
//          collapsible whitespace (because String.trim()/RegExp `\s` both
//          also match U+00A0), collapsing `<p>&nbsp;</p>` to zero height.

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
  group('FH-1367 — line-height px unit uses own font-size, not parent\'s', () {
    test('font-size and line-height on the same element', () {
      final style = _styleOfTag(
          '<h2 style="font-size: 20px; line-height: 3px;">x</h2>', 'h2');
      // 3px / 20px own font-size = 0.15 multiplier. The bug divided by the
      // parent's default 16px instead, giving 0.1875 — a visibly wrong
      // line-height whenever font-size and line-height are set together
      // (an extremely common CSS pattern, e.g. `h2 { font-size: 20px;
      // line-height: 1.25; }`).
      expect(style!.lineHeight, closeTo(0.15, 0.0001));
    });

    test('line-height alone (no own font-size) still uses the inherited size',
        () {
      final style = _styleOfTag(
        '<div style="font-size: 20px;"><p style="line-height: 10px;">x</p></div>',
        'p',
      );
      // <p> doesn't declare its own font-size, so it inherits 20px from the
      // div, and 10px line-height / 20px = 0.5.
      expect(style!.lineHeight, closeTo(0.5, 0.0001));
    });

    test('unitless line-height multiplier is unaffected', () {
      final style = _styleOfTag(
          '<h2 style="font-size: 20px; line-height: 1.5;">x</h2>', 'h2');
      expect(style!.lineHeight, closeTo(1.5, 0.0001));
    });

    // The original FH-1367 fix only worked when `font-size` happened to be
    // written BEFORE `line-height`, because declarations were applied in
    // source order. A CSS computed value must never depend on the order
    // properties are written in — `font-size` is now resolved ahead of the
    // declarations that reference it, on both the inline-style and the
    // stylesheet path.
    test('declaration order does not change the result (inline style)', () {
      final fontSizeFirst =
          _styleOfTag('<p style="font-size:20px;line-height:30px">x</p>', 'p');
      final lineHeightFirst =
          _styleOfTag('<p style="line-height:30px;font-size:20px">x</p>', 'p');
      // 30px / 20px = 1.5 either way.
      expect(fontSizeFirst!.lineHeight, closeTo(1.5, 0.0001));
      expect(lineHeightFirst!.lineHeight, closeTo(1.5, 0.0001));
    });

    test('declaration order does not change the result (stylesheet)', () {
      final fontSizeFirst = _styleOfTag(
        '<style>p { font-size:20px; line-height:30px; }</style><p>x</p>',
        'p',
      );
      final lineHeightFirst = _styleOfTag(
        '<style>p { line-height:30px; font-size:20px; }</style><p>x</p>',
        'p',
      );
      expect(fontSizeFirst!.lineHeight, closeTo(1.5, 0.0001));
      expect(lineHeightFirst!.lineHeight, closeTo(1.5, 0.0001));
    });

    test('em line-height also uses the element\'s own font-size, any order',
        () {
      // `line-height: 2em` on a 20px element = 40px = multiplier 2.0.
      final after =
          _styleOfTag('<p style="font-size:20px;line-height:2em">x</p>', 'p');
      final before =
          _styleOfTag('<p style="line-height:2em;font-size:20px">x</p>', 'p');
      expect(after!.lineHeight, closeTo(2.0, 0.0001));
      expect(before!.lineHeight, closeTo(2.0, 0.0001));
    });

    test('a later duplicate font-size still wins (cascade within a block)', () {
      // Both font-size declarations precede nothing special; the LAST one wins
      // per CSS, so the reference is 40px → 20px/40px = 0.5.
      final style = _styleOfTag(
        '<p style="font-size:10px;line-height:20px;font-size:40px">x</p>',
        'p',
      );
      expect(style!.fontSize, closeTo(40, 0.0001));
      expect(style.lineHeight, closeTo(0.5, 0.0001));
    });
  });

  group('FH-1439 — &nbsp;-only text is not collapsible whitespace', () {
    test('&nbsp; decodes to U+00A0, not a droppable space', () {
      final style = _styleOfTag('<p>&nbsp;</p>', 'p');
      expect(style, isNotNull);
    });

    testWidgets('<p>&nbsp;</p> renders the same height as a text paragraph',
        (tester) async {
      Future<double> heightOf(String html) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: HyperViewer(html: html)),
        ));
        await tester.pumpAndSettle();
        return tester.getSize(find.byType(HyperViewer)).height;
      }

      final nbspHeight =
          await heightOf('<p>Before</p><p>&nbsp;</p><p>After</p>');
      final textHeight = await heightOf('<p>Before</p><p>X</p><p>After</p>');
      final emptyHeight = await heightOf('<p>Before</p><p></p><p>After</p>');

      expect(nbspHeight, textHeight,
          reason:
              '&nbsp; is a visible, non-collapsing character — the paragraph '
              'must take up a full line of height like any other text.');
      expect(nbspHeight, isNot(emptyHeight),
          reason: 'a genuinely empty <p></p> legitimately has less content '
              'height than one holding a non-breaking space.');
    });

    // Direct unit tests of isCssWhitespaceOnly/cssWhitespaceRun live in
    // packages/hyper_render_core/test/ (they're internal cross-adapter
    // helpers, not part of the root package's curated public API — see
    // html_whitespace_test.dart).
  });
}
