import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('HyperRender Stress Tests', () {
    testWidgets('Extremely deep nesting (100 levels)', (tester) async {
      final buffer = StringBuffer();
      for (int i = 0; i < 100; i++) {
        buffer.write(
            '<div style="padding-left: 2px; border-left: 1px solid red;">');
      }
      buffer.write('<span>Deeply nested content</span>');
      for (int i = 0; i < 100; i++) {
        buffer.write('</div>');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                  html: buffer.toString(), mode: HyperRenderMode.sync),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Large number of small elements (5000 spans)', (tester) async {
      final buffer = StringBuffer('<p>');
      for (int i = 0; i < 5000; i++) {
        buffer.write('<span>Span $i </span>');
      }
      buffer.write('</p>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
                html: buffer.toString(), mode: HyperRenderMode.sync),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('Massive table (10 columns x 30 rows)', (tester) async {
      final buffer = StringBuffer('<table border="1" style="width: 1000px;">');
      for (int r = 0; r < 30; r++) {
        buffer.write('<tr>');
        for (int c = 0; c < 10; c++) {
          buffer.write('<td>R$r C$c</td>');
        }
        buffer.write('</tr>');
      }
      buffer.write('</table>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 2000),
                  child: HyperViewer(
                      html: buffer.toString(), mode: HyperRenderMode.sync),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Rapid content updates (50 times)', (tester) async {
      String htmlContent = '<p>Initial Content</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Expanded(
                        child: HyperViewer(
                            html: htmlContent, mode: HyperRenderMode.sync)),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        htmlContent =
                            '<p>Content iteration ${DateTime.now().millisecondsSinceEpoch}</p>';
                      }),
                      child: const Text('Update'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      for (int i = 0; i < 50; i++) {
        await tester.tap(find.text('Update'));
        await tester.pump();
      }

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Extreme CSS specificity conflict (1000 rules)',
        (tester) async {
      final styleBuffer = StringBuffer('<style>');
      for (int i = 0; i < 1000; i++) {
        styleBuffer.write('.class$i { color: rgb(${(i % 255)}, 0, 0); }\n');
      }
      styleBuffer.write('</style>');

      final bodyBuffer = StringBuffer('<div>');
      for (int i = 0; i < 100; i++) {
        bodyBuffer.write(
            '<p class="class${i % 1000} class${(i + 1) % 1000}">Text $i</p>');
      }
      bodyBuffer.write('</div>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
                html: styleBuffer.toString() + bodyBuffer.toString(),
                mode: HyperRenderMode.sync),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
