import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('CJK & Ruby Stress Tests', () {
    testWidgets('Extremely dense Ruby text', (tester) async {
      final buffer = StringBuffer('<p>');
      for (int i = 0; i < 200; i++) {
        buffer.write('<ruby>漢字<rt>かんじ</rt></ruby> ');
      }
      buffer.write('</p>');

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
    });

    testWidgets('Mixed CJK and Latin with Kinsoku line breaking',
        (tester) async {
      const html = '''
<p style="width: 200px;">
  This is a mix of English and Japanese to test line breaking rules. 
  今日は良い天気ですね。富士山に行きたいです。
  「括弧」や『引用』の動作、。、。、。
  123,456,789円。
</p>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, mode: HyperRenderMode.sync),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Large vertical CJK text block', (tester) async {
      final buffer = StringBuffer('<div style="line-height: 2.0;">');
      for (int i = 0; i < 50; i++) {
        buffer.write('<p>吾輩は猫である。名前はまだ無い。どこで生れたかとんと見当がつかぬ。$i</p>');
      }
      buffer.write('</div>');

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
    });
  });
}
