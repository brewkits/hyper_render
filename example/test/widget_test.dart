// Basic Flutter widget test for HyperRender example app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  testWidgets('HyperViewer renders basic HTML', (WidgetTester tester) async {
    // Build the HyperViewer widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HyperViewer(
            html: '<p>Hello World</p>',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that HyperViewer is rendered
    expect(find.byType(HyperViewer), findsOneWidget);
  });

  testWidgets('HyperViewer renders styled text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HyperViewer(
            html: '<p><strong>Bold</strong> and <em>Italic</em></p>',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that HyperViewer is rendered
    expect(find.byType(HyperViewer), findsOneWidget);
  });

  testWidgets('Demo app launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HyperViewer(
            html: '''
              <h1>Demo Test</h1>
              <p>This is a <strong>test</strong> of the demo app.</p>
            ''',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(HyperViewer), findsOneWidget);
  });
}
