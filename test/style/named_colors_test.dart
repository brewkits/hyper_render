/// Tests for CSS4 named color support in the style resolver.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('CSS4 Named Colors', () {
    Widget widget(String style) => MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<span style="color: $style">text</span>',
            ),
          ),
        );

    testWidgets('basic colors still work', (tester) async {
      await tester.pumpWidget(widget('red'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('aliceblue resolves without error', (tester) async {
      await tester.pumpWidget(widget('aliceblue'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('crimson resolves without error', (tester) async {
      await tester.pumpWidget(widget('crimson'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('deepskyblue resolves without error', (tester) async {
      await tester.pumpWidget(widget('deepskyblue'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('rebeccapurple resolves without error', (tester) async {
      await tester.pumpWidget(widget('rebeccapurple'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('darkslateblue resolves without error', (tester) async {
      await tester.pumpWidget(widget('darkslateblue'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('lightgoldenrodyellow resolves without error', (tester) async {
      await tester.pumpWidget(widget('lightgoldenrodyellow'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('grey (alias) resolves same as gray', (tester) async {
      await tester.pumpWidget(widget('grey'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('aqua (alias for cyan) resolves', (tester) async {
      await tester.pumpWidget(widget('aqua'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('fuchsia (alias for magenta) resolves', (tester) async {
      await tester.pumpWidget(widget('fuchsia'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('unknown color falls back gracefully', (tester) async {
      await tester.pumpWidget(widget('notacolor'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });
}
