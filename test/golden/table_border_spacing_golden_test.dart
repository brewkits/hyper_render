/// Golden tests for CSS `border-collapse` on tables.
///
/// The widget test test/table_border_spacing_test.dart locks down the geometry
/// (sizes + cell offsets) numerically. These goldens lock down the PAINT: that
/// separate mode draws a per-cell outline with visible spacing between cells,
/// and that collapse mode still draws the merged grid bars.
///
/// Run once to generate reference images:
///   flutter test test/golden/table_border_spacing_golden_test.dart --update-goldens
/// Then run normally to compare. Excluded from CI via: --exclude-tags golden
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

TableNode? _tryTable(UDTNode node) {
  if (node is TableNode) return node;
  for (final c in node.children) {
    final found = _tryTable(c);
    if (found != null) return found;
  }
  return null;
}

Future<void> _pumpTable(WidgetTester tester, String html, Key key) async {
  final doc = HtmlAdapter().parse(html);
  StyleResolver().resolveStyles(doc);
  final table = _tryTable(doc)!;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 200),
          devicePixelRatio: 1.0,
          textScaler: TextScaler.noScaling,
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.topLeft,
              // Unbounded width → natural (content-sized) columns, so the
              // per-cell outlines and the spacing gaps are clearly visible
              // rather than stretched across the viewport.
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: RepaintBoundary(
                  key: key,
                  child: HyperTable(
                    tableNode: table,
                    selectable: false,
                    borderColor: const Color(0xFF3355AA),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _grid(String style) => '<table style="$style">'
    '<tr><td>A1</td><td>B1</td></tr>'
    '<tr><td>A2</td><td>B2</td></tr>'
    '</table>';

void main() {
  group('Golden — table border-collapse', () {
    testWidgets('separate mode draws per-cell outlines with spacing',
        (tester) async {
      final key = GlobalKey();
      await _pumpTable(
        tester,
        _grid('border-collapse:separate;border-spacing:10px'),
        key,
      );
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/table_border_spacing_separate.png'),
      );
    });

    testWidgets('collapse mode draws merged grid bars', (tester) async {
      final key = GlobalKey();
      await _pumpTable(tester, _grid('border-collapse:collapse'), key);
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/table_border_spacing_collapse.png'),
      );
    });
  });
}
