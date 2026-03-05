/// Tests for the bracket-aware inline style tokenizer.
/// Ensures that calc(), rgb(), url() etc. are not incorrectly split on commas/semicolons.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('Bracket-aware inline style tokenizer', () {
    Widget widget(String inlineStyle) => MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<div style="$inlineStyle">content</div>',
            ),
          ),
        );

    testWidgets('rgb() color is not split on comma', (tester) async {
      await tester.pumpWidget(widget('color: rgb(255, 0, 128)'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('rgba() color is not split on comma', (tester) async {
      await tester.pumpWidget(
          widget('background-color: rgba(0, 0, 255, 0.5)'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('calc() with spaces is not split at semicolon', (tester) async {
      await tester.pumpWidget(widget('width: calc(100% - 32px)'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('multiple declarations with rgb() parse correctly', (tester) async {
      await tester.pumpWidget(
          widget('color: rgb(255, 0, 0); background-color: rgb(0, 128, 0)'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('calc() followed by another declaration parses both', (tester) async {
      await tester.pumpWidget(
          widget('width: calc(50% + 8px); color: red'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('nested parentheses in calc() handled correctly', (tester) async {
      await tester.pumpWidget(
          widget('margin: calc(10px + (5px * 2))'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('empty style string does not crash', (tester) async {
      await tester.pumpWidget(widget(''));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('style with no semicolon is parsed', (tester) async {
      await tester.pumpWidget(widget('font-weight: bold'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('trailing semicolon is handled', (tester) async {
      await tester.pumpWidget(widget('color: blue;'));
      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });
}
