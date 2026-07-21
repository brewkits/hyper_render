// Tests that CSS `max-width` on a block executes — it was parsed into
// ComputedStyle but never applied, so a `max-width` block laid its text out
// against the full container width. Found while auditing flutter_html for
// feature parity.
//
// Implemented via the line-breaker's existing per-block padding stack: a
// max-width block inflates its right inset so text wraps inside max-width.
// `%` max-width and `min-width` remain unsupported (see LIMITATIONS.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

Future<double> _height(WidgetTester tester, String html,
    {double width = 400}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: SingleChildScrollView(child: HyperViewer(html: html)),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return tester.getSize(find.byType(HyperViewer)).height;
}

const _longText =
    'This is a fairly long line of text that would fit on one line normally '
    'but must wrap when constrained';

void main() {
  group('max-width constrains block content width', () {
    testWidgets('narrow max-width forces earlier wrapping (taller)',
        (tester) async {
      final unconstrained = await _height(tester, '<div>$_longText</div>');
      final constrained = await _height(
          tester, '<div style="max-width: 100px;">$_longText</div>');
      expect(constrained, greaterThan(unconstrained),
          reason: 'max-width:100 must wrap the text into more lines');
    });

    testWidgets('max-width wider than content is a no-op', (tester) async {
      final normal = await _height(tester, '<div>short</div>');
      final withMax =
          await _height(tester, '<div style="max-width: 300px;">short</div>');
      expect(withMax, normal);
    });

    testWidgets('max-width on the first block (no top margin) still applies',
        (tester) async {
      // Regression guard: the first block with no margin previously skipped
      // its block-start fragment, which is what carries the width constraint.
      final unconstrained = await _height(tester, '<div>$_longText</div>');
      final constrained = await _height(
          tester, '<div style="max-width: 120px;">$_longText</div>');
      expect(constrained, greaterThan(unconstrained));
    });

    testWidgets('smaller max-width wraps more than a larger one',
        (tester) async {
      final narrow = await _height(
          tester, '<div style="max-width: 80px;">$_longText</div>');
      final wide = await _height(
          tester, '<div style="max-width: 200px;">$_longText</div>');
      expect(narrow, greaterThan(wide),
          reason: 'a tighter max-width should produce more wrapped lines');
    });

    testWidgets('nested content under max-width renders without crash',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: HyperViewer(
            html: '<div style="max-width: 150px;">'
                '<p>nested paragraph with enough text to wrap somewhere</p>'
                '<ul><li>list item</li></ul></div>',
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
