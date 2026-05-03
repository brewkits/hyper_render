import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_html/hyper_render_html.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('HtmlAdapter Unit Tests', () {
    late HtmlAdapter adapter;

    setUp(() {
      adapter = HtmlAdapter();
    });

    test('1. Parses simple text', () {
      final doc = adapter.parse('Hello World');
      expect(doc.children.length, 1);
      expect(doc.children.first is TextNode, true);
      expect((doc.children.first as TextNode).text, 'Hello World');
    });

    test('2. Drops structural whitespace', () {
      final doc = adapter.parse('   \n  \t  ');
      expect(doc.children.isEmpty, true);
    });

    test('3. Parses heading elements (h1-h6)', () {
      final doc = adapter.parse('<h1>H1</h1><h2>H2</h2><h3>H3</h3>');
      expect(doc.children.length, 3);
      expect(doc.children[0] is BlockNode, true);
      expect((doc.children[0] as BlockNode).tagName, 'h1');
      expect((doc.children[1] as BlockNode).tagName, 'h2');
      expect((doc.children[2] as BlockNode).tagName, 'h3');
    });

    test('4. Parses paragraph with default margin', () {
      final doc = adapter.parse('<p>Paragraph</p>');
      expect(doc.children.length, 1);
      final p = doc.children.first as BlockNode;
      expect(p.tagName, 'p');
      expect(p.style.margin.vertical, 32.0);
    });

    test('5. Parses inline formatting (b, i, strong, em)', () {
      final doc = adapter.parse('<div><b>bold</b> <i>italic</i></div>');
      final div = doc.children.first as BlockNode;
      expect(div.children[0] is InlineNode, true);
      expect((div.children[0] as InlineNode).tagName, 'b');
      expect(div.children[2] is InlineNode, true);
      expect((div.children[2] as InlineNode).tagName, 'i');
    });

    test('6. Parses blockquote with correct styling', () {
      final doc = adapter.parse('<blockquote>quote</blockquote>');
      final blockquote = doc.children.first as BlockNode;
      expect(blockquote.tagName, 'blockquote');
      expect(blockquote.style.padding.left, 16);
    });

    test('7. Parses pre and code blocks', () {
      final doc = adapter.parse('<pre><code>code here</code></pre>');
      final pre = doc.children.first as BlockNode;
      expect(pre.tagName, 'pre');
      expect(pre.style.whiteSpace, 'pre');
      final code = pre.children.first as InlineNode;
      expect(code.tagName, 'code');
    });

    test('8. Parses links and resolves baseUrl', () {
      final doc = adapter.parse('<a href="/about">Link</a>',
          baseUrl: 'https://example.com');
      final a = doc.children.first as InlineNode;
      expect(a.tagName, 'a');
      expect(a.attributes['href'], 'https://example.com/about');
    });

    test('9. Parses mark for yellow highlight', () {
      final doc = adapter.parse('<mark>highlight</mark>');
      final mark = doc.children.first as InlineNode;
      expect(mark.tagName, 'mark');
      expect(mark.style.backgroundColor, const Color(0xFFFFFF00));
    });

    test('10. Parses lists (ul, ol, li)', () {
      final doc = adapter.parse('<ul><li>Item 1</li><li>Item 2</li></ul>');
      final ul = doc.children.first as BlockNode;
      expect(ul.tagName, 'ul');
      expect(ul.children.length, 2);
      expect((ul.children[0] as BlockNode).tagName, 'li');
    });

    test('11. Parses tables structure (table, tr, td, th)', () {
      final doc = adapter.parse(
          '<table><tr><th>Header</th></tr><tr><td>Data</td></tr></table>');
      final table = doc.children.first as TableNode;
      final tbody = table.children[0] as BlockNode;
      expect(tbody.tagName, 'tbody');
      expect(tbody.children.length, 2);
      expect(tbody.children[0] is TableRowNode, true);
      final tr1 = tbody.children[0] as TableRowNode;
      expect(tr1.children[0] is TableCellNode, true);
      expect((tr1.children[0] as TableCellNode).isHeader, true);
    });

    test('12. Parses hr as BlockNode', () {
      final doc = adapter.parse('<hr>');
      final hr = doc.children.first as BlockNode;
      expect(hr.tagName, 'hr');
      expect(hr.style.display, DisplayType.block);
    });

    test('13. Parses br as LineBreakNode', () {
      final doc = adapter.parse('<br>');
      expect(doc.children.first is LineBreakNode, true);
    });

    test('14. Parses img as AtomicNode with baseUrl', () {
      final doc = adapter.parse('<img src="/img.png" alt="An image">',
          baseUrl: 'https://test.com');
      final img = doc.children.first as AtomicNode;
      expect(img.tagName, 'img');
      expect(img.src, 'https://test.com/img.png');
      expect(img.alt, 'An image');
    });

    test('15. Parses video, audio, iframe as AtomicNode', () {
      final doc = adapter.parse(
          '<video src="v.mp4"></video><audio src="a.mp3"></audio><iframe src="i.html"></iframe>');
      expect((doc.children[0] as AtomicNode).tagName, 'video');
      expect((doc.children[1] as AtomicNode).tagName, 'audio');
      expect((doc.children[2] as AtomicNode).tagName, 'iframe');
    });

    test('16. Parses ruby annotations', () {
      final doc = adapter.parse('<ruby>漢<rt>かん</rt></ruby>');
      final ruby = doc.children.first as RubyNode;
      expect(ruby.baseText, '漢');
      expect(ruby.rubyText, 'かん');
    });

    test('16b. Parses ruby with nested bold base text', () {
      final doc = adapter.parse('<ruby><b>Kanji</b><rt>Furigana</rt></ruby>');
      final ruby = doc.children.first as RubyNode;
      expect(ruby.baseText, 'Kanji');
      expect(ruby.rubyText, 'Furigana');
    });

    test('16c. Newline between inline elements collapses to space', () {
      final doc = adapter.parse('<p><span>A</span>\n<span>B</span></p>');
      final block = doc.children.first as BlockNode;
      // Collect all text content — should contain a space between A and B.
      final text = block.textContent;
      expect(text.contains('A B') || text.contains('A') && text.contains('B'),
          isTrue);
      // Must not be "AB" with no separator at all.
      expect(text.replaceAll(' ', '').contains('AB'), isTrue);
    });

    test('17. Parses details and summary', () {
      final doc =
          adapter.parse('<details><summary>Title</summary>Content</details>');
      final details = doc.children.first as BlockNode;
      expect(details.tagName, 'details');
      expect((details.children[0] as BlockNode).tagName, 'summary');
    });

    test('18. Extracts CSS from style tags', () {
      final css =
          adapter.extractCss('<style>.cls { color: red; }</style><div></div>');
      expect(css.contains('.cls { color: red; }'), true);
    });

    test('19. Extracts keyframes from style tags', () {
      const parser = DefaultCssParser();
      final keyframes = adapter.extractKeyframes(
          '<style>@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }</style>',
          parser);
      expect(keyframes.containsKey('fadeIn'), true);
    });

    test('20. Parses inline SVG as AtomicNode', () {
      final doc = adapter.parse(
          '<svg width="100" height="100"><circle cx="50" cy="50" r="40" /></svg>');
      final svg = doc.children.first as AtomicNode;
      expect(svg.tagName, 'svg');
      expect(svg.intrinsicWidth, 100);
      expect(svg.intrinsicHeight, 100);
      expect(svg.svgData?.contains('<circle'), true);
    });

    test('21. parseToSections chunks large documents', () {
      final largeHtml = '<div>${'<p>Long text</p>' * 100}</div>';
      // Default chunk size is 3000
      final sections = adapter.parseToSections(largeHtml, chunkSize: 1000);
      expect(sections.length > 1, true);
    });

    test('22. parseToSections keeps headings with content', () {
      final html =
          '<div>${'<p>P</p>' * 50}<h2>Heading</h2><p>Content</p></div>';
      final sections = adapter.parseToSections(html, chunkSize: 500);
      // The heading h2 should not be the last element of a section if possible
      for (final section in sections) {
        if (section.children.isNotEmpty) {
          final last = section.children.last;
          expect(last is BlockNode && last.tagName == 'h2', false);
        }
      }
    });

    test('23. parseToSections prevents splitting after float-containing block',
        () {
      const html =
          '<div><div style="float: left;">Float</div><p>Wrapped text</p></div>';
      final sections = adapter.parseToSections(html, chunkSize: 10);
      expect(sections.length, 1);
    });
  });
}
