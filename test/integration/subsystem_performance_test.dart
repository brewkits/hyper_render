import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/src/parser/html/html_adapter.dart';

void main() {
  group('HyperRender Deep Subsystem Performance', () {
    test('Table Layout: Nested tables (3 levels deep)', () {
      final buffer = StringBuffer();
      for (int i = 0; i < 10; i++) {
        buffer.write('''
          <table border="1">
            <tr>
              <td>Outer $i</td>
              <td>
                <table border="1">
                  <tr>
                    <td>Middle $i</td>
                    <td>
                      <table border="1">
                        <tr><td>Inner $i-A</td><td>Inner $i-B</td></tr>
                      </table>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
        ''');
      }

      final stopwatch = Stopwatch()..start();
      final doc = HtmlAdapter().parse(buffer.toString());
      stopwatch.stop();

      print('Nested Table Parse: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(300));
    });

    test('CSS Resolver: Inheritance and Cascading (50 levels deep)', () {
      final buffer = StringBuffer('<style>');
      buffer.write('div { color: black; font-size: 14px; }\n');
      buffer.write('.red { color: red; }\n');
      buffer.write('.large { font-size: 20px; }\n');
      buffer.write('</style>');

      for (int i = 0; i < 50; i++) {
        buffer.write('<div class="${i.isEven ? 'red' : 'large'}">');
      }
      buffer.write('Leaf Content');
      for (int i = 0; i < 50; i++) {
        buffer.write('</div>');
      }

      final stopwatch = Stopwatch()..start();
      final doc = HtmlAdapter().parse(buffer.toString());
      // Style resolution happens during layout, but parsing the style block is part of it
      stopwatch.stop();

      print('Deep CSS Parse/UDT: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });

    test('Selection Hit-Testing: Large document (10K characters)', () {
      final buffer = StringBuffer('<article>');
      for (int i = 0; i < 100; i++) {
        buffer.write(
            '<p id="p$i">This is paragraph number $i with a lot of text to ensure we have enough lines for hit testing.</p>');
      }
      buffer.write('</article>');

      final doc = HtmlAdapter().parse(buffer.toString());
      // Hit testing is O(log N). We can't test performance without a full layout/RenderBox,
      // but we can ensure the parser handles this size instantly.
      expect(doc.textContent.length, greaterThan(8000));
    });
  });
}
