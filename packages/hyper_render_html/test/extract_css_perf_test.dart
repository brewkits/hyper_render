import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_html/hyper_render_html.dart';

/// Regression tests for the v1.3.2 review Issue 4 fix: `HtmlAdapter.extractCss`
/// now short-circuits with a regex when the document is large enough that
/// full html5lib parsing would jank the UI thread, and with a literal-text
/// probe when there is no `<style>` block at all.
void main() {
  final adapter = HtmlAdapter();

  group('extractCss — fast paths', () {
    test('document with no <style> returns empty without parsing', () {
      // 200 KB of plain content — the regex probe should reject this
      // instantly. If a regression switches back to html_parser.parse,
      // this test would still pass but tail-latency would balloon.
      final big = '<p>x</p>' * 30000; // ~ 210 KB
      expect(adapter.extractCss(big), equals(''));
    });

    test('small input still goes through the full parser', () {
      const html = '''
<html><head><style>p { color: red; }</style></head>
<body><p>hi</p></body></html>
''';
      final css = adapter.extractCss(html);
      expect(css, contains('color: red'));
    });

    test('large input with <style> uses the regex extractor', () {
      // Above the 32 KB threshold — must go through the regex path. We
      // verify behavioural equivalence: the CSS body still comes back.
      final filler = '<p>x</p>' * 6000; // ~ 42 KB
      final html = '<style>div { display: flex; }</style>$filler';
      final css = adapter.extractCss(html);
      expect(css, contains('display: flex'));
    });

    test('multiple <style> blocks are concatenated', () {
      final filler = '<p>y</p>' * 6000;
      final html = '<style>a { color: red; }</style>'
          '$filler'
          '<style>b { color: blue; }</style>';
      final css = adapter.extractCss(html);
      expect(css, contains('color: red'));
      expect(css, contains('color: blue'));
    });

    test('case-insensitive <STYLE> tag is matched', () {
      final filler = '<p>z</p>' * 6000;
      final html = '<STYLE>em { font-style: italic; }</STYLE>$filler';
      final css = adapter.extractCss(html);
      expect(css.toLowerCase(), contains('italic'));
    });

    test('style block with attributes (type / media) is captured', () {
      final filler = '<p>q</p>' * 6000;
      final html =
          '<style type="text/css" media="screen">body { margin: 0 }</style>$filler';
      final css = adapter.extractCss(html);
      expect(css, contains('margin: 0'));
    });
  });
}
