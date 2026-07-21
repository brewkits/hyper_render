// Regression test for flutter_html #1480 (and its root #266): the `start`
// attribute on `<ol>` was ignored — `<ol start="5">` always numbered from 1.
//
// Marker text is painted on the RenderHyperBox canvas (not a Text widget), so
// we introspect it via the debug fragment dump, where each `_ListMarkerFragment`
// exposes its rendered marker string as `text`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

Future<List<String>> _markers(WidgetTester tester, String html) async {
  final doc = HtmlAdapter().parse(html);
  StyleResolver().resolveStyles(doc);

  RenderHyperBox? box;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: HyperRenderWidget(
          document: doc,
          onRenderBoxReady: (b) => box = b,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();

  // Ordered-list markers end in ". " (e.g. "5. "); bullets are "• ".
  return box!
      .debugFragments()
      .map((f) => f['text'] as String?)
      .whereType<String>()
      .where((t) => RegExp(r'^\s*\d+\.\s*$').hasMatch(t))
      .map((t) => t.trim())
      .toList();
}

void main() {
  group('FH-1480 — <ol start="N"> honours the start attribute', () {
    testWidgets('start="5" numbers from 5', (tester) async {
      final markers = await _markers(
        tester,
        '<ol start="5"><li>a</li><li>b</li><li>c</li></ol>',
      );
      expect(markers, ['5.', '6.', '7.']);
    });

    testWidgets('no start attribute still numbers from 1', (tester) async {
      final markers = await _markers(
        tester,
        '<ol><li>a</li><li>b</li></ol>',
      );
      expect(markers, ['1.', '2.']);
    });

    testWidgets('malformed start value falls back to 1', (tester) async {
      final markers = await _markers(
        tester,
        '<ol start="abc"><li>a</li><li>b</li></ol>',
      );
      expect(markers, ['1.', '2.']);
    });

    testWidgets('two independent ordered lists keep separate counters',
        (tester) async {
      final markers = await _markers(
        tester,
        '<ol start="10"><li>a</li></ol><ol><li>x</li><li>y</li></ol>',
      );
      expect(markers, ['10.', '1.', '2.']);
    });
  });
}
