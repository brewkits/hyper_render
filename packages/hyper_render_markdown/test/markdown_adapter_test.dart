import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_markdown/hyper_render_markdown.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('MarkdownAdapter Extra', () {
    final adapter = MarkdownAdapter();

    test('parse headers h1-h6', () {
      for (int i = 1; i <= 6; i++) {
        final md = '${'#' * i} Header $i';
        final result = adapter.parseExtended(md);
        final block = result.document.children[0] as BlockNode;
        expect(block.tagName, 'h$i');
      }
    });

    test('parse inline formatting', () {
      const md = '**bold** *italic* ~~strike~~ `code`';
      final result = adapter.parseExtended(md);
      final p = result.document.children[0] as BlockNode;
      // markdown package might use 'strong' or 'b', 'em' or 'i'
      expect(
          p.children.any((n) =>
              n is InlineNode && (n.tagName == 'strong' || n.tagName == 'b')),
          isTrue);
      expect(
          p.children.any((n) =>
              n is InlineNode && (n.tagName == 'em' || n.tagName == 'i')),
          isTrue);
      expect(
          p.children.any((n) =>
              n is InlineNode && (n.tagName == 'del' || n.tagName == 's')),
          isTrue);
      expect(p.children.any((n) => n is InlineNode && n.tagName == 'code'),
          isTrue);
    });

    test('parse code block', () {
      const md = '```dart\nvoid main() {}\n```';
      final result = adapter.parseExtended(md);
      final pre = result.document.children[0] as BlockNode;
      expect(pre.tagName, 'pre');
    });

    test('parse blockquote', () {
      const md = '> This is a quote';
      final result = adapter.parseExtended(md);
      final quote = result.document.children[0] as BlockNode;
      expect(quote.tagName, 'blockquote');
    });

    test('parse horizontal rule', () {
      const md = '---';
      final result = adapter.parseExtended(md);
      final hr = result.document.children[0] as BlockNode;
      expect(hr.tagName, 'hr');
    });

    test('parse lists', () {
      const md = '- Item 1\n- Item 2\n\n1. First\n2. Second';
      final result = adapter.parseExtended(md);
      expect((result.document.children[0] as BlockNode).tagName, 'ul');
      expect((result.document.children[1] as BlockNode).tagName, 'ol');
    });

    test('parse tables (GFM)', () {
      const md = '| A | B |\n|---|---|\n| 1 | 2 |';
      final result = adapter.parseExtended(md);
      expect(result.document.children[0], isA<TableNode>());
    });

    test('parse task lists', () {
      const md = '- [ ] Unchecked\n- [x] Checked';
      final result = adapter.parseExtended(md);
      final ul = result.document.children[0] as BlockNode;
      // md package generates <li class="task-list-item"><input type="checkbox">...
      expect(ul.children[0], isA<BlockNode>());
      expect((ul.children[0] as BlockNode).attributes['data-task'], isNotNull);
    });

    test('parse line break', () {
      const md = 'Line 1  \nLine 2'; // Two spaces at end of line for <br>
      final result = adapter.parseExtended(md);
      final p = result.document.children[0] as BlockNode;
      expect(p.children.any((n) => n is LineBreakNode), isTrue);
    });

    test('MarkdownAdapterExtensions works', () {
      final doc = '# Hello'.parseMarkdown();
      expect(doc.children[0], isA<BlockNode>());
    });
  });
}
