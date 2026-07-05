// ignore_for_file: avoid_print
// Performance benchmarks for v1.5.0 timing-function + color-keyframe parsing.
//
// Soft time budgets guard against parser regressions on animation-heavy CSS.

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/src/plugins/default_css_parser.dart';
import 'package:hyper_render/src/parser/html/html_adapter.dart';

void main() {
  group('v1.5.0 animation parsing performance', () {
    test('parses 1000 color keyframe blocks under budget', () {
      const parser = DefaultCssParser();
      final css = StringBuffer();
      for (var i = 0; i < 1000; i++) {
        css.write('''
@keyframes glow$i {
  from { background-color: #6366f1; color: #ffffff; }
  50%  { background-color: rgb(120, 80, 200); }
  to   { background-color: #ec4899; color: #000000; }
}
''');
      }

      final sw = Stopwatch()..start();
      final result = parser.parseKeyframes(css.toString());
      sw.stop();

      print('Parse 1000 color @keyframes: ${sw.elapsedMilliseconds}ms');
      expect(result, hasLength(1000));
      // Every block carries interpolable colors.
      expect(result['glow0']!.keyframes.first.backgroundColor, isNotNull);
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('resolves 2000 elements with cubic-bezier/steps timing under budget',
        () {
      final adapter = HtmlAdapter();
      final html = StringBuffer('<article>');
      for (var i = 0; i < 2000; i++) {
        final fn = i.isEven
            ? 'cubic-bezier(0.4, 0, 0.2, 1)'
            : 'steps(${(i % 8) + 1}, end)';
        html.write(
            '<div style="transition: transform 0.3s $fn; animation-timing-function: $fn">x</div>');
      }
      html.write('</article>');

      final sw = Stopwatch()..start();
      final doc = adapter.parse(html.toString());
      sw.stop();

      print('Parse+resolve 2000 timed elements: ${sw.elapsedMilliseconds}ms');
      expect(doc.children, isNotEmpty);
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });
  });
}
