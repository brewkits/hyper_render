/// Tests for CSS4 named color support in the style resolver.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('CSS4 Named Colors', () {
    Widget _widget(String style) => MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<span style="color: $style">text</span>',
            ),
          ),
        );

    testWidgets('basic colors still work', (tester) async {
      await tester.pumpWidget(_widget('red'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('aliceblue resolves without error', (tester) async {
      await tester.pumpWidget(_widget('aliceblue'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('crimson resolves without error', (tester) async {
      await tester.pumpWidget(_widget('crimson'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('deepskyblue resolves without error', (tester) async {
      await tester.pumpWidget(_widget('deepskyblue'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('rebeccapurple resolves without error', (tester) async {
      await tester.pumpWidget(_widget('rebeccapurple'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('darkslateblue resolves without error', (tester) async {
      await tester.pumpWidget(_widget('darkslateblue'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('lightgoldenrodyellow resolves without error', (tester) async {
      await tester.pumpWidget(_widget('lightgoldenrodyellow'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('grey (alias) resolves same as gray', (tester) async {
      await tester.pumpWidget(_widget('grey'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('aqua (alias for cyan) resolves', (tester) async {
      await tester.pumpWidget(_widget('aqua'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('fuchsia (alias for magenta) resolves', (tester) async {
      await tester.pumpWidget(_widget('fuchsia'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('unknown color falls back gracefully', (tester) async {
      await tester.pumpWidget(_widget('notacolor'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });
}
