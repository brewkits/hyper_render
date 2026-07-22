// Parse⇒render tests for CSS `border-collapse: separate` + `border-spacing`.
//
// WHY THESE ASSERTIONS: in the render object the inter-cell gap and the border
// thickness were unified into one `_borderWidth`. Splitting them (so separate
// mode can use a `border-spacing` gap) touched ~9 sizing/positioning sites. In
// the DEFAULT collapse mode the gap still equals the 1px border, so a site left
// un-converted stays invisible in collapse — it only surfaces in separate mode
// as a layout↔paint mismatch. These tests therefore drive separate mode with a
// gap clearly distinct from 1px and assert EXACT geometry deltas, so a missed
// site fails loudly.
//
// The delta form (size at spacing=12 minus size at spacing=4) is immune to
// font-measurement variance: the column/row content is identical, so only the
// gap term changes, isolating the `_cellGap × (n+1)` contribution at every site.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

TableNode _firstTable(UDTNode node) {
  if (node is TableNode) return node;
  for (final c in node.children) {
    final found = _tryTable(c);
    if (found != null) return found;
  }
  throw StateError('no TableNode in parsed document');
}

TableNode? _tryTable(UDTNode node) {
  if (node is TableNode) return node;
  for (final c in node.children) {
    final found = _tryTable(c);
    if (found != null) return found;
  }
  return null;
}

Future<Size> _tableSize(WidgetTester tester, String html) async {
  final doc = HtmlAdapter().parse(html);
  StyleResolver().resolveStyles(doc);
  final table = _firstTable(doc);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        // Horizontal scroll gives the table unbounded width, so it uses its
        // natural (content) column widths instead of stretching to fill the
        // viewport — otherwise surplus distribution hides the spacing delta.
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: HyperTable(tableNode: table, selectable: false),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return tester.getSize(find.byType(HyperTable));
}

/// Global left-x of the RichText whose plain text is exactly [cell].
Future<Map<String, double>> _cellXs(
    WidgetTester tester, String html, List<String> cells) async {
  final doc = HtmlAdapter().parse(html);
  StyleResolver().resolveStyles(doc);
  final table = _firstTable(doc);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        // Horizontal scroll gives the table unbounded width, so it uses its
        // natural (content) column widths instead of stretching to fill the
        // viewport — otherwise surplus distribution hides the spacing delta.
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: HyperTable(tableNode: table, selectable: false),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  final out = <String, double>{};
  for (final c in cells) {
    out[c] = tester.getTopLeft(find.text(c, findRichText: true)).dx;
  }
  return out;
}

String _grid(String tableStyle) => '<table style="$tableStyle">'
    '<tr><td>A</td><td>B</td></tr>'
    '<tr><td>C</td><td>D</td></tr>'
    '</table>';

void main() {
  group('border-collapse: separate + border-spacing', () {
    testWidgets('gap enters width sizing with multiplier (columns + 1)',
        (tester) async {
      // 2 columns → each +1px of spacing adds 3px of table width.
      final s4 = await _tableSize(
          tester, _grid('border-collapse:separate;border-spacing:4px'));
      final s12 = await _tableSize(
          tester, _grid('border-collapse:separate;border-spacing:12px'));
      expect(s12.width - s4.width, closeTo((12 - 4) * 3, 0.5));
    });

    testWidgets('gap enters height sizing with multiplier (rows + 1)',
        (tester) async {
      // 2 rows → each +1px of spacing adds 3px of table height.
      final s4 = await _tableSize(
          tester, _grid('border-collapse:separate;border-spacing:4px'));
      final s12 = await _tableSize(
          tester, _grid('border-collapse:separate;border-spacing:12px'));
      expect(s12.height - s4.height, closeTo((12 - 4) * 3, 0.5));
    });

    testWidgets('gap enters cell positioning (colX stepping)', (tester) async {
      // Distance between column-0 and column-1 cells grows by exactly one gap.
      final x4 = await _cellXs(tester,
          _grid('border-collapse:separate;border-spacing:4px'), ['A', 'B']);
      final x12 = await _cellXs(tester,
          _grid('border-collapse:separate;border-spacing:12px'), ['A', 'B']);
      final gap4 = x4['B']! - x4['A']!;
      final gap12 = x12['B']! - x12['A']!;
      expect(gap12 - gap4, closeTo(12 - 4, 0.5));
    });

    testWidgets('separate mode makes the table larger than collapse',
        (tester) async {
      final collapse =
          await _tableSize(tester, _grid('border-collapse:collapse'));
      final separate = await _tableSize(
          tester, _grid('border-collapse:separate;border-spacing:12px'));
      expect(separate.width, greaterThan(collapse.width));
      expect(separate.height, greaterThan(collapse.height));
    });

    testWidgets('default table renders identically to explicit collapse',
        (tester) async {
      // The refactor must not change the default (collapse) geometry.
      final byDefault = await _tableSize(tester, _grid(''));
      final explicit =
          await _tableSize(tester, _grid('border-collapse:collapse'));
      expect(byDefault.width, closeTo(explicit.width, 0.01));
      expect(byDefault.height, closeTo(explicit.height, 0.01));
    });
  });
}
