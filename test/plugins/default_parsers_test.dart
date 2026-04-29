import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/src/plugins/default_html_parser.dart';
import 'package:hyper_render/src/plugins/default_markdown_parser.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('DefaultHtmlParser', () {
    final parser = DefaultHtmlParser();

    test('contentType returns ContentType.html', () {
      expect(parser.contentType, ContentType.html);
    });

    test('parse simple HTML', () {
      const html = '<p>Hello</p>';
      final doc = parser.parse(html);
      expect(doc.children, isNotEmpty);
    });

    test('parseWithOptions', () {
      const html = '<p>Hello</p>';
      final doc = parser.parseWithOptions(html, baseUrl: 'https://example.com');
      expect(doc.children, isNotEmpty);
    });

    test('parseToSections', () {
      const html = '<p>Section 1</p><p>Section 2</p>';
      final sections = parser.parseToSections(html, chunkSize: 10);
      expect(sections, isNotEmpty);
    });
  });

  group('DefaultMarkdownParser', () {
    final parser = DefaultMarkdownParser();

    test('contentType returns ContentType.markdown', () {
      expect(parser.contentType, ContentType.markdown);
    });

    test('parse simple Markdown', () {
      const md = '# Hello';
      final doc = parser.parse(md);
      expect(doc.children, isNotEmpty);
    });

    test('parseWithOptions', () {
      const md = '# Hello';
      final doc = parser.parseWithOptions(md);
      expect(doc.children, isNotEmpty);
    });

    test('parseToSections returns single section', () {
      const md = '# Hello';
      final sections = parser.parseToSections(md);
      expect(sections, hasLength(1));
    });
  });
}
