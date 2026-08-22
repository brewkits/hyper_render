import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/compat/flutter_html.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('flutter_html Drop-in Compatibility Layer', () {
    testWidgets('renders simple HTML through Html widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Html(
              data: '<h1>Title</h1><p>Hello from drop-in compatibility!</p>',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('handles empty or null data without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Html(data: null),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('converts custom style map into CSS', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Html(
              data: '<p class="highlight">Styled paragraph</p>',
              style: {
                '.highlight': 'color: red; font-weight: bold;',
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('triggers onLinkTap callback', (tester) async {
      String? tappedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Html(
              data: '<a href="https://brewkits.dev">BrewKits</a>',
              onLinkTap: (url, attributes, element) {
                tappedUrl = url;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final hyperViewer = tester.widget<HyperViewer>(find.byType(HyperViewer));
      expect(hyperViewer.onLinkTap, isNotNull);
      hyperViewer.onLinkTap!('https://brewkits.dev');
      expect(tappedUrl, equals('https://brewkits.dev'));
    });
  });
}
