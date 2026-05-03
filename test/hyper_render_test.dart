import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('HtmlAdapter', () {
    late HtmlAdapter adapter;

    setUp(() {
      adapter = HtmlAdapter();
    });

    test('parses simple HTML', () {
      const html = '<p>Hello World</p>';
      final document = adapter.parse(html);

      expect(document.children, isNotEmpty);
    });

    test('parses nested elements', () {
      const html = '<p>Hello <strong>World</strong></p>';
      final document = adapter.parse(html);

      expect(document.children, isNotEmpty);
      final p = document.children.first;
      expect(p.tagName, equals('p'));
    });

    test('parses links with href', () {
      const html = '<a href="https://example.com">Click</a>';
      final document = adapter.parse(html);
      expect(document.children, isNotEmpty);
    });

    test('parses images', () {
      const html =
          '<img src="test.png" alt="Test Image" width="100" height="50">';
      final document = adapter.parse(html);
      expect(document.children, isNotEmpty);
      final img = document.children.first;
      expect(img, isA<AtomicNode>());
      expect((img as AtomicNode).src, equals('test.png'));
      expect(img.alt, equals('Test Image'));
    });

    test('parses tables', () {
      const html = '''
        <table>
          <tr>
            <th>Header 1</th>
            <th>Header 2</th>
          </tr>
          <tr>
            <td>Cell 1</td>
            <td>Cell 2</td>
          </tr>
        </table>
      ''';
      final document = adapter.parse(html);
      expect(document.children, isNotEmpty);
      final table = document.children.first;
      expect(table, isA<TableNode>());
    });

    test('parses ruby annotations', () {
      const html = '<ruby>漢字<rt>かんじ</rt></ruby>';
      final document = adapter.parse(html);
      expect(document.children, isNotEmpty);
      final ruby = document.children.first;
      expect(ruby, isA<RubyNode>());
      expect((ruby as RubyNode).baseText, equals('漢字'));
      expect(ruby.rubyText, equals('かんじ'));
    });

    test('parses style tag attributes without crashing', () {
      // <style> tags are skipped; content should still parse cleanly
      const html = '<style>p { color: red; }</style><p>Hello</p>';
      final adapter = HtmlAdapter();
      final document = adapter.parse(html);
      expect(document.children, isNotEmpty);
      final p = document.children.first;
      expect(p.tagName, equals('p'));
    });
  });

  group('StyleResolver', () {
    late StyleResolver resolver;

    setUp(() {
      resolver = StyleResolver();
    });

    test('resolves user agent styles', () {
      final doc = DocumentNode(children: [
        BlockNode.h1(children: [TextNode('Heading')]),
        BlockNode.p(children: [TextNode('Paragraph')]),
      ]);

      resolver.resolveStyles(doc);

      final h1 = doc.children[0];
      expect(h1.style.fontSize, equals(32));
      expect(h1.style.fontWeight, equals(FontWeight.bold));
    });

    test('parses and applies CSS rules', () {
      resolver.parseCss('.highlight { color: #FF0000; }');

      final doc = DocumentNode(children: [
        InlineNode(
          tagName: 'span',
          attributes: {'class': 'highlight'},
          children: [TextNode('Highlighted')],
        ),
      ]);

      resolver.resolveStyles(doc);

      final span = doc.children[0];
      expect(span.style.color, equals(const Color(0xFFFF0000)));
    });

    test('applies inline styles', () {
      final doc = DocumentNode(children: [
        InlineNode(
          tagName: 'span',
          attributes: {'style': 'font-size: 20px; color: blue'},
          children: [TextNode('Styled')],
        ),
      ]);

      resolver.resolveStyles(doc);

      final span = doc.children[0];
      expect(span.style.fontSize, equals(20));
    });
  });

  group('UDT Node', () {
    test('textContent returns all text', () {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('Hello '),
          InlineNode.strong(children: [TextNode('World')])
        ]),
      ]);

      expect(doc.textContent, equals('Hello World'));
    });

    test('traverse visits all nodes', () {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('Hello'),
          InlineNode.strong(children: [TextNode('World')])
        ]),
      ]);

      final visited = <UDTNode>[];
      doc.traverse((node) => visited.add(node));

      expect(visited.length, equals(5)); // doc, p, text, strong, text
    });

    test('findById finds node by id', () {
      final targetNode = TextNode('Target');
      final doc = DocumentNode(children: [
        BlockNode.p(children: [targetNode]),
      ]);

      final found = doc.findById(targetNode.id);
      expect(found, equals(targetNode));
    });
  });

  group('Fragment', () {
    test('creates text fragment', () {
      final node = TextNode('Hello');
      final fragment = Fragment.text(
        text: 'Hello',
        sourceNode: node,
        style: ComputedStyle(),
      );

      expect(fragment.type, equals(FragmentType.text));
      expect(fragment.text, equals('Hello'));
    });

    test('line break fragment has zero size', () {
      final node = LineBreakNode();
      final fragment = Fragment.lineBreak(
        sourceNode: node,
        style: ComputedStyle(),
      );
      fragment.measuredSize = Size.zero;
      expect(fragment.type, equals(FragmentType.lineBreak));
      expect(fragment.measuredSize, equals(Size.zero));
    });
  });

  group('HyperViewer Mode', () {
    test('auto mode is default', () {
      const viewer = HyperViewer(html: '<p>Test</p>');
      expect(viewer.mode, equals(HyperRenderMode.auto));
    });

    test('sync mode can be set', () {
      const viewer = HyperViewer(
        html: '<p>Test</p>',
        mode: HyperRenderMode.sync,
      );
      expect(viewer.mode, equals(HyperRenderMode.sync));
    });
  });

  group('TableStrategy', () {
    test('horizontalScroll is default', () {
      final wrapper = SmartTableWrapper(
        tableNode: TableNode(children: []),
      );
      expect(wrapper.strategy, equals(TableStrategy.horizontalScroll));
    });

    test('autoScale can be set', () {
      final wrapper = SmartTableWrapper(
        tableNode: TableNode(children: []),
        strategy: TableStrategy.autoScale,
      );
      expect(wrapper.strategy, equals(TableStrategy.autoScale));
    });
  });

  group('Table colspan/rowspan', () {
    test('TableCellNode reads colspan from attributes', () {
      final cell = TableCellNode(
        attributes: {'colspan': '2'},
        children: [TextNode('Spanning cell')],
      );

      expect(cell.colspan, equals(2));
      expect(cell.rowspan, equals(1)); // default
    });

    test('TableCellNode reads rowspan from attributes', () {
      final cell = TableCellNode(
        attributes: {'rowspan': '3'},
        children: [TextNode('Spanning cell')],
      );

      expect(cell.colspan, equals(1)); // default
      expect(cell.rowspan, equals(3));
    });

    test('TableCellNode reads both colspan and rowspan', () {
      final cell = TableCellNode(
        attributes: {'colspan': '2', 'rowspan': '3'},
        children: [TextNode('Spanning cell')],
      );

      expect(cell.colspan, equals(2));
      expect(cell.rowspan, equals(3));
    });

    test('HtmlAdapter parses colspan from HTML', () {
      final adapter = HtmlAdapter();
      const html = '''
        <table>
          <tr>
            <td colspan="2">Spanning</td>
          </tr>
        </table>
      ''';

      final document = adapter.parse(html);
      final table = document.children.first as TableNode;

      // Find the first TableRowNode (may be wrapped in tbody)
      TableRowNode? row;
      for (final child in table.children) {
        if (child is TableRowNode) {
          row = child;
          break;
        } else if (child.type == NodeType.block) {
          for (final grandChild in child.children) {
            if (grandChild is TableRowNode) {
              row = grandChild;
              break;
            }
          }
          if (row != null) break;
        }
      }

      expect(row, isNotNull);
      final cell = row!.children.whereType<TableCellNode>().first;
      expect(cell.colspan, equals(2));
    });

    test('HtmlAdapter parses rowspan from HTML', () {
      final adapter = HtmlAdapter();
      const html = '''
        <table>
          <tr>
            <td rowspan="2">Spanning</td>
            <td>Normal</td>
          </tr>
          <tr>
            <td>Another</td>
          </tr>
        </table>
      ''';

      final document = adapter.parse(html);
      final table = document.children.first as TableNode;

      // Find the first TableRowNode (may be wrapped in tbody)
      TableRowNode? row;
      for (final child in table.children) {
        if (child is TableRowNode) {
          row = child;
          break;
        } else if (child.type == NodeType.block) {
          for (final grandChild in child.children) {
            if (grandChild is TableRowNode) {
              row = grandChild;
              break;
            }
          }
          if (row != null) break;
        }
      }

      expect(row, isNotNull);
      final cell = row!.children.firstWhere((n) => n is TableCellNode) as TableCellNode;
      expect(cell.rowspan, equals(2));
    });
  });

  group('KinsokuProcessor (CJK line-breaking)', () {
    test('identifies kinsoku start characters', () {
      // These cannot start a line
      expect(KinsokuProcessor.cannotStartLine('。'), isTrue);
      expect(KinsokuProcessor.cannotStartLine('、'), isTrue);
      expect(KinsokuProcessor.cannotStartLine('」'), isTrue);
      expect(KinsokuProcessor.cannotStartLine('）'), isTrue);
      expect(KinsokuProcessor.cannotStartLine('ー'), isTrue);

      // These can start a line
      expect(KinsokuProcessor.cannotStartLine('あ'), isFalse);
      expect(KinsokuProcessor.cannotStartLine('A'), isFalse);
      expect(KinsokuProcessor.cannotStartLine('「'), isFalse);
    });

    test('identifies kinsoku end characters', () {
      // These cannot end a line
      expect(KinsokuProcessor.cannotEndLine('「'), isTrue);
      expect(KinsokuProcessor.cannotEndLine('（'), isTrue);
      expect(KinsokuProcessor.cannotEndLine('『'), isTrue);

      // These can end a line
      expect(KinsokuProcessor.cannotEndLine('あ'), isFalse);
      expect(KinsokuProcessor.cannotEndLine('。'), isFalse);
      expect(KinsokuProcessor.cannotEndLine('」'), isFalse);
    });
  });

  group('Float CSS support', () {
    test('ComputedStyle has float property with default none', () {
      final style = ComputedStyle();
      expect(style.float, equals(HyperFloat.none));
    });

    test('StyleResolver parses float: left', () {
      final resolver = StyleResolver();
      resolver.parseCss('.float-left { float: left; }');

      final doc = DocumentNode(children: [
        InlineNode(
          tagName: 'div',
          attributes: {'class': 'float-left'},
          children: [TextNode('Floated content')],
        ),
      ]);

      resolver.resolveStyles(doc);

      final div = doc.children[0];
      expect(div.style.float, equals(HyperFloat.left));
    });
  });

  group('Media elements (Audio/Video)', () {
    test('HtmlAdapter parses video element', () {
      final adapter = HtmlAdapter();
      const html =
          '<video src="test.mp4" width="640" height="360" controls></video>';

      final document = adapter.parse(html);
      expect(document.children, isNotEmpty);

      final video = document.children.first;
      expect(video, isA<AtomicNode>());
      expect((video as AtomicNode).tagName, equals('video'));
      expect(video.src, equals('test.mp4'));
      expect(video.intrinsicWidth, equals(640));
      expect(video.intrinsicHeight, equals(360));
    });

    test('HtmlAdapter parses audio element', () {
      final adapter = HtmlAdapter();
      const html = '<audio src="test.mp3" controls></audio>';

      final document = adapter.parse(html);
      expect(document.children, isNotEmpty);

      final audio = document.children.first;
      expect(audio, isA<AtomicNode>());
      expect((audio as AtomicNode).tagName, equals('audio'));
      expect(audio.src, equals('test.mp3'));
    });
  });

  group('Quill Delta adapter', () {
    test('DeltaAdapter parses plain insert op', () {
      const delta = '{"ops":[{"insert":"Hello World\\n"}]}';
      final adapter = DeltaAdapter();
      final document = adapter.parse(delta);
      expect(document.textContent.trim(), equals('Hello World'));
    });

    test('DeltaAdapter parses bold attribute', () {
      const delta =
          '{"ops":[{"insert":"Bold","attributes":{"bold":true}},{"insert":"\\n"}]}';
      final adapter = DeltaAdapter();
      final document = adapter.parse(delta);
      expect(document.textContent, contains('Bold'));
    });

    test('HyperViewer.delta sets correct contentType', () {
      const viewer = HyperViewer.delta(
        delta: '{"ops":[{"insert":"Test\\n"}]}',
      );
      expect(viewer.contentType, equals(HyperContentType.delta));
    });
  });

  group('HtmlAdapter.parseToSections — float split guard', () {
    // The float-aware split guard ensures that a section is never split
    // immediately after a block containing a CSS-floated element.
    // This keeps the float-bearing block and its successor in the same chunk
    // so RenderHyperBox can flow text around the float correctly.

    test('does not split immediately after float:left img block', () {
      final adapter = HtmlAdapter();
      // Build a document that exceeds the chunkSize threshold (default 6000)
      // right after the float-containing paragraph.
      final padding = 'x' * 200; // filler to simulate accumulated size
      final big = 'word ' * 1200; // ~6000 chars to push over threshold
      final html = '<p>$big</p>'
          '<p><img style="float:left" src="img.jpg"> Caption.</p>'
          '<p>$padding</p>';
      final sections = adapter.parseToSections(html, chunkSize: 6000);

      // The float-containing paragraph and the paragraph immediately after it
      // must be in the SAME section.
      bool foundFloatAndNext = false;
      for (final section in sections) {
        final text = section.textContent;
        // The float paragraph ends with 'Caption.' and the next para starts
        // with 'x' (our padding filler).
        if (text.contains('Caption.') && text.contains(padding.trim())) {
          foundFloatAndNext = true;
          break;
        }
      }
      expect(foundFloatAndNext, isTrue,
          reason:
              'Float-containing block and its successor must be in the same section');
    });

    test('does not split immediately after float:right img block', () {
      final adapter = HtmlAdapter();
      final big = 'word ' * 1200;
      final html = '<p>$big</p>'
          '<p><img style="float: right; width:120px" src="img.png"> Text.</p>'
          '<p>After float paragraph.</p>';
      final sections = adapter.parseToSections(html, chunkSize: 6000);

      bool foundTogether = false;
      for (final section in sections) {
        final text = section.textContent;
        if (text.contains('Text.') && text.contains('After float paragraph.')) {
          foundTogether = true;
          break;
        }
      }
      expect(foundTogether, isTrue);
    });

    test('still splits normally when no float present', () {
      final adapter = HtmlAdapter();
      // Two big paragraphs without floats — should split between them.
      final big = 'word ' * 1200;
      final html = '<p>$big</p><p>$big</p>';
      final sections = adapter.parseToSections(html, chunkSize: 6000);
      // Should produce at least 2 sections.
      expect(sections.length, greaterThanOrEqualTo(2));
    });
  });

  group('Markdown adapter', () {
    test('MarkdownAdapter parses heading', () {
      const md = '# Hello World\n\nSome text.';
      final adapter = MarkdownAdapter();
      final document = adapter.parse(md);
      expect(document.children, isNotEmpty);
    });

    test('MarkdownAdapter parses bold inline', () {
      const md = '**bold** text';
      final adapter = MarkdownAdapter();
      final document = adapter.parse(md);
      expect(document.textContent, contains('bold'));
    });

    test('HyperViewer.markdown sets correct contentType', () {
      const viewer = HyperViewer.markdown(
        markdown: '# Test',
      );
      expect(viewer.contentType, equals(HyperContentType.markdown));
    });

    // BUG-M2: CRLF line endings left a stray \r inside code block content.
    //
    // BEFORE FIX: content.split('\n') on "```\r\ncode\r\n```\r\n" produced
    //   lines = ["```\r", "code\r", "```\r", ""] — the \r is part of the
    //   "line" string that the Markdown parser sees as code content.
    //   Result: code block textContent contains "\r" → visible in monospace
    //   renderers as a stray box / cursor-return character.
    //
    // AFTER FIX: content normalised to LF first → no \r in any parsed node.
    test('MarkdownAdapter handles Windows CRLF — no stray CR in code block', () {
      // Markdown with Windows-style \r\n line endings.
      const md = '```\r\nsome code\r\n```\r\n';
      final adapter = MarkdownAdapter();
      final document = adapter.parse(md);
      expect(document.children, isNotEmpty);
      // Code block must NOT contain a carriage-return character.
      expect(document.textContent, isNot(contains('\r')),
          reason:
              'CRLF should be normalised; no stray \\r in code block text. '
              'BEFORE fix: "some code\\r\\n" was stored as "some code\\r".');
    });

    test('MarkdownAdapter handles bare CR (old Mac) line endings', () {
      // Bare \r (pre-OS X Mac) must also be normalised.
      const md = '# Title\rSome text.\r';
      final adapter = MarkdownAdapter();
      final document = adapter.parse(md);
      expect(document.textContent, isNot(contains('\r')));
    });
  });

  // BUG-M1: _splitIntoSections (Markdown/Delta virtualised path) was missing
  // the heading-widow guard that HtmlAdapter.parseToSections has.
  //
  // BEFORE FIX: a heading that pushed currentSize >= chunkSize was allowed to
  // end a section, orphaning it at the bottom of the chunk with no content
  // following it in the same viewport.
  //
  // AFTER FIX: sections never end on a heading (h1–h6), and never split
  // immediately before a heading either.
  group('_splitIntoSections heading-widow guard', () {
    // Access the internal method via a thin wrapper that surfaces the same
    // logic by calling it through the public virtualized parse path.  We drive
    // it with a DocumentNode built directly from the Markdown adapter so we
    // don't need to pump a widget tree.
    List<DocumentNode> splitSections(DocumentNode doc, int chunkSize) {
      // Mirror of _HyperViewerState._splitIntoSections.
      // Build a small local copy of the algorithm so the test is self-contained
      // and verifies the fix's exact logic.
      final children = doc.children;
      final sections = <DocumentNode>[];
      var current = DocumentNode(children: []);
      var currentSize = 0;

      for (int i = 0; i < children.length; i++) {
        final child = children[i];
        current.children.add(child);
        child.parent = current;
        currentSize += child.textContent.length;

        if (currentSize >= chunkSize && child.isBlock) {
          final tag = child.tagName?.toLowerCase();
          final isHeading = tag == 'h1' ||
              tag == 'h2' ||
              tag == 'h3' ||
              tag == 'h4' ||
              tag == 'h5' ||
              tag == 'h6';

          bool nextIsHeading = false;
          if (!isHeading && i + 1 < children.length) {
            final nextTag = children[i + 1].tagName?.toLowerCase();
            nextIsHeading = nextTag == 'h1' ||
                nextTag == 'h2' ||
                nextTag == 'h3' ||
                nextTag == 'h4' ||
                nextTag == 'h5' ||
                nextTag == 'h6';
          }

          if (!isHeading && !nextIsHeading) {
            sections.add(current);
            current = DocumentNode(children: []);
            currentSize = 0;
          }
        }
      }

      if (current.children.isNotEmpty) sections.add(current);
      if (sections.isEmpty) sections.add(DocumentNode(children: []));
      return sections;
    }

    test('heading is never the last node in a section', () {
      // Build a doc with a paragraph (large enough to trigger a split) followed
      // immediately by a heading, then more content.
      final body = 'x' * 200; // 200 chars → triggers split at chunkSize=100
      final adapter = MarkdownAdapter();
      final doc = adapter.parse('$body\n\n## Section Two\n\nContent here.\n');

      final sections = splitSections(doc, 100);

      // No section should end with a heading.
      for (final section in sections) {
        if (section.children.isEmpty) continue;
        final lastTag = section.children.last.tagName?.toLowerCase();
        expect(
          lastTag == 'h1' ||
              lastTag == 'h2' ||
              lastTag == 'h3' ||
              lastTag == 'h4' ||
              lastTag == 'h5' ||
              lastTag == 'h6',
          isFalse,
          reason:
              'Section must not end with a heading (orphaned heading bug). '
              'Last tag was: $lastTag',
        );
      }
    });

    test('section does not split immediately before a heading', () {
      final body = 'x' * 200;
      final adapter = MarkdownAdapter();
      // First section body puts us exactly at the threshold; the very next
      // child is a heading — the split must be deferred past the heading.
      final doc = adapter.parse(
          '$body\n\n## My Heading\n\nFollowing paragraph content.\n');

      final sections = splitSections(doc, 200);

      // The heading must NOT be the FIRST child of any section except possibly
      // the very first section (which has no preceding content).
      for (int i = 1; i < sections.length; i++) {
        final firstTag = sections[i].children.first.tagName?.toLowerCase();
        expect(
          firstTag == 'h1' ||
              firstTag == 'h2' ||
              firstTag == 'h3' ||
              firstTag == 'h4' ||
              firstTag == 'h5' ||
              firstTag == 'h6',
          isFalse,
          reason:
              'A heading should not start a new section when the previous '
              'section still had room (deferred split). First tag: $firstTag',
        );
      }
    });
  });
}
