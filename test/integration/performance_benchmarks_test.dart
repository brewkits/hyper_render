// ignore_for_file: avoid_print, unused_local_variable
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/src/parser/html/html_adapter.dart';
import 'package:hyper_render/src/plugins/default_css_parser.dart';

void main() {
  group('HyperRender Performance Benchmarks', () {
    test('CSS Selector Engine: 1000 rules matching performance', () {
      const parser = DefaultCssParser();
      final styleBuffer = StringBuffer();
      for (int i = 0; i < 1000; i++) {
        styleBuffer.write('.class$i { color: red; }\n');
      }

      final stopwatch = Stopwatch()..start();
      final rules = parser.parseStylesheet(styleBuffer.toString());
      stopwatch.stop();

      print('CSS Parse (1000 rules): ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
      expect(rules, hasLength(1000));
    });

    test('HTML Parser: 1MB HTML throughput', () {
      final adapter = HtmlAdapter();
      final buffer = StringBuffer('<article>');
      for (int i = 0; i < 5000; i++) {
        buffer.write(
            '<p>Paragraph $i with some <strong>bold</strong> and <em>italic</em> text.</p>');
      }
      buffer.write('</article>');
      final html = buffer.toString();

      final stopwatch = Stopwatch()..start();
      final doc = adapter.parse(html);
      stopwatch.stop();

      print('HTML Parse (1MB): ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(doc.children, isNotEmpty);
    });

    test('Table Logic: Complex table construction performance', () {
      final adapter = HtmlAdapter();
      final buffer = StringBuffer('<table>');
      for (int r = 0; r < 200; r++) {
        buffer.write('<tr>');
        for (int c = 0; c < 20; c++) {
          buffer.write('<td>Row $r Col $c</td>');
        }
        buffer.write('</tr>');
      }
      buffer.write('</table>');

      final stopwatch = Stopwatch()..start();
      final doc = adapter.parse(buffer.toString());
      stopwatch.stop();

      print('Table construction (200x20): ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('Virtualized Splitter: Sectioning performance', () {
      final adapter = HtmlAdapter();
      final buffer = StringBuffer();
      for (int i = 0; i < 10000; i++) {
        buffer.write('<p>Line $i</p>');
      }

      final stopwatch = Stopwatch()..start();
      final sections =
          adapter.parseToSections(buffer.toString(), chunkSize: 1000);
      stopwatch.stop();

      print(
          'Section splitting (10K nodes): ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(sections.length, greaterThan(1));
    });
  });
}
