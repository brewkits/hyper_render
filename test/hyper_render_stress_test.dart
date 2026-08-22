import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('HyperRender Stress Tests', () {
    testWidgets('Massive DOM depth does not stack overflow',
        (WidgetTester tester) async {
      // Generate a 1,000 deep nested DOM tree
      var html = '';
      for (var i = 0; i < 1000; i++) {
        html += '<div>';
      }
      html += 'Deep Node';
      for (var i = 0; i < 1000; i++) {
        html += '</div>';
      }

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperViewer(html: html),
        ),
      ));

      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Renders 10,000 consecutive paragraphs efficiently',
        (WidgetTester tester) async {
      // Generate 10,000 paragraphs
      final sb = StringBuffer();
      for (var i = 0; i < 10000; i++) {
        sb.write(
            '<p>Paragraph \$i with some text to fill up the layout engine.</p>');
      }

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperViewer(
            html: sb.toString(),
            // Ensure we use virtualized mode for this massive string
            mode: HyperRenderMode.virtualized,
          ),
        ),
      ));

      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });
}
