// Regression tests for bugs found by auditing flutter_widget_from_html's
// closed-issue tracker against HyperRender. Each reproduced independently
// before the fix; none is specific to FWFH's architecture.
//
// FH-inf   Non-finite CSS values (1e999 -> Infinity) crashed layout with a
//          BoxConstraints assertion — malformed/hostile CSS could crash the app.
// FWFH-488 `display: none` was parsed but NOT executed on the canvas path:
//          hidden elements (and hidden table rows/cells) still rendered and
//          were selectable. Common in email pre-headers and CMS blocks.
// FWFH-676 An `<a>` with no href was styled as a link (blue + underline);
//          browsers only style `a[href]`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

ComputedStyle? _styleOf(String html, bool Function(UDTNode) pred) {
  final adapter = HtmlAdapter();
  final doc = adapter.parse(html);
  final resolver = StyleResolver();
  final css = adapter.extractCss(html);
  if (css.isNotEmpty) resolver.parseCss(css);
  resolver.resolveStyles(doc);
  ComputedStyle? found;
  void walk(UDTNode n) {
    if (found != null) return;
    if (pred(n)) {
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

Future<double> _viewerHeight(WidgetTester tester, String html) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: HyperViewer(html: html)),
  ));
  await tester.pumpAndSettle();
  return tester.getSize(find.byType(HyperViewer)).height;
}

void main() {
  group('Non-finite CSS values are rejected, not laid out', () {
    testWidgets('1e999 in various properties does not crash', (tester) async {
      // double.tryParse('1e999') == Infinity; without a finite check this
      // propagated into box constraints and threw during performLayout.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HyperViewer(
              html: '<div style="margin: 1e999px;">a</div>'
                  '<div style="font-size: 1e999px;">b</div>'
                  '<div style="width: 1e999px; height: 1e999px;">c</div>'
                  '<div style="padding: 1e400rem;">d</div>',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    test('overflowing length parses to null (declaration ignored)', () {
      final s = _styleOf('<div style="font-size: 1e999px;">x</div>',
          (n) => n.tagName == 'div');
      // font-size falls back to inherited default, not Infinity.
      expect(s!.fontSize.isFinite, isTrue);
    });
  });

  group('display: none is executed (not just parsed)', () {
    testWidgets('hidden div occupies no height', (tester) async {
      final withHidden = await _viewerHeight(
          tester, '<p>A</p><div style="display:none">HIDDEN</div><p>B</p>');
      final without = await _viewerHeight(tester, '<p>A</p><p>B</p>');
      expect(withHidden, without);
    });

    testWidgets('hidden paragraph occupies no height', (tester) async {
      final withHidden = await _viewerHeight(
          tester, '<p>A</p><p style="display:none">HIDDEN</p><p>B</p>');
      final without = await _viewerHeight(tester, '<p>A</p><p>B</p>');
      expect(withHidden, without);
    });

    testWidgets('hidden table row occupies no height', (tester) async {
      final withHidden = await _viewerHeight(
        tester,
        '<table><tr><td>A</td></tr>'
        '<tr style="display:none"><td>HIDDEN</td></tr></table>',
      );
      final oneRow =
          await _viewerHeight(tester, '<table><tr><td>A</td></tr></table>');
      expect(withHidden, oneRow);
    });

    testWidgets('hidden content is not selectable', (tester) async {
      final doc = HtmlAdapter()
          .parse('<p>Visible</p><div style="display:none">SECRET</div>');
      StyleResolver().resolveStyles(doc);
      RenderHyperBox? box;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperRenderWidget(
            document: doc,
            selectable: true,
            onRenderBoxReady: (b) => box = b,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      box!.selectAll();
      final text = box!.getSelectedText() ?? '';
      expect(text.contains('SECRET'), isFalse,
          reason: 'display:none content must not be selectable');
      expect(text.contains('Visible'), isTrue);
    });
  });

  group('<a> without href is not styled as a link', () {
    test('href-less anchor has no underline', () {
      final s = _styleOf('<a>plain text</a>', (n) => n.tagName == 'a');
      expect(s!.textDecoration, isNot(TextDecoration.underline));
    });

    test('empty href is not a link', () {
      final s = _styleOf('<a href="">x</a>', (n) => n.tagName == 'a');
      expect(s!.textDecoration, isNot(TextDecoration.underline));
    });

    test('anchor WITH href keeps link styling', () {
      final s =
          _styleOf('<a href="https://x.com">x</a>', (n) => n.tagName == 'a');
      expect(s!.textDecoration, TextDecoration.underline);
    });

    test('href + text-decoration:none override wins', () {
      final s = _styleOf(
          '<a href="https://x.com" style="text-decoration:none">x</a>',
          (n) => n.tagName == 'a');
      expect(s!.textDecoration, TextDecoration.none);
    });
  });
}
