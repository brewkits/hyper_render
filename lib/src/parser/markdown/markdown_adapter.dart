import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:flutter/painting.dart';
import 'package:markdown/markdown.dart' as md;
import '../adapter.dart';
import '../../utils/html_sanitizer.dart';

/// Markdown to UDT adapter
///
/// Converts Markdown string into Unified Document Tree.
/// Uses the `markdown` package to parse Markdown to HTML,
/// then uses our HTML parsing logic to build UDT.
///
/// ## Supported Markdown Syntax
///
/// ### Basic Formatting
/// - **Bold**: `**text**` or `__text__`
/// - *Italic*: `*text*` or `_text_`
/// - ~~Strikethrough~~: `~~text~~`
/// - `Code`: `` `code` ``
///
/// ### Headers
/// - `# H1` through `###### H6`
///
/// ### Links and Images
/// - `[text](url)` - Links
/// - `![alt](url)` - Images
///
/// ### Lists
/// - `- item` or `* item` - Unordered list
/// - `1. item` - Ordered list
///
/// ### Blocks
/// - `> quote` - Blockquote
/// - ``` code ``` - Code block
/// - `---` - Horizontal rule
///
/// ### Tables (GFM)
/// ```
/// | Header 1 | Header 2 |
/// |----------|----------|
/// | Cell 1   | Cell 2   |
/// ```
///
/// ## Extensions
///
/// By default, uses GitHub Flavored Markdown (GFM) extensions:
/// - Tables
/// - Strikethrough
/// - Autolinks
/// - Task lists
class MarkdownAdapter extends ExtendedDocumentAdapter {
  /// Enable GitHub Flavored Markdown extensions
  final bool enableGfm;

  /// Enable inline HTML in Markdown
  final bool enableInlineHtml;

  /// Custom block syntaxes
  final List<md.BlockSyntax>? customBlockSyntaxes;

  /// Custom inline syntaxes
  final List<md.InlineSyntax>? customInlineSyntaxes;

  MarkdownAdapter({
    this.enableGfm = true,
    this.enableInlineHtml = true,
    this.customBlockSyntaxes,
    this.customInlineSyntaxes,
  });

  @override
  InputType get inputType => InputType.markdown;

  @override
  AdapterResult parseExtended(String content) {
    final stopwatch = Stopwatch()..start();
    final warnings = <String>[];

    try {
      // Build extension set and syntax lists.
      // IMPORTANT: Never pass both extensionSet AND blockSyntaxes/inlineSyntaxes
      // to md.Document — the explicit lists override the extensionSet's syntaxes,
      // resulting in empty or broken parse output.
      //
      // Strategy:
      // - No custom syntaxes → use extensionSet only (no extra lists)
      // - Custom syntaxes → unroll GFM syntaxes into explicit lists (no extensionSet)
      final bool hasCustomSyntaxes =
          customBlockSyntaxes != null || customInlineSyntaxes != null;

      final md.Document document;
      if (!hasCustomSyntaxes) {
        // Simple path: let extensionSet own all syntaxes
        document = md.Document(
          extensionSet: enableGfm ? md.ExtensionSet.gitHubFlavored : null,
          encodeHtml: !enableInlineHtml,
        );
      } else {
        // Custom syntax path: merge GFM + custom into explicit lists
        final blockSyntaxes = <md.BlockSyntax>[
          if (enableGfm) ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
          ...customBlockSyntaxes!,
        ];
        final inlineSyntaxes = <md.InlineSyntax>[
          if (enableGfm) ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
          ...customInlineSyntaxes!,
        ];
        document = md.Document(
          blockSyntaxes: blockSyntaxes,
          inlineSyntaxes: inlineSyntaxes,
          encodeHtml: !enableInlineHtml,
        );
      }

      // Normalize line endings: \r\n (Windows) and bare \r (old Mac) → \n so
      // that the Markdown parser never sees a trailing \r inside a "line" (e.g.
      // "# Title\r" rendered as heading text with a stray carriage-return char).
      final lines = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
      final nodes = document.parseLines(lines);

      // Convert Markdown AST to UDT
      final udtChildren = <UDTNode>[];
      for (final node in nodes) {
        final udtNode = _convertNode(node, warnings);
        if (udtNode != null) {
          udtChildren.add(udtNode);
        }
      }

      stopwatch.stop();

      return AdapterResult(
        document: DocumentNode(children: udtChildren),
        warnings: warnings,
        parseDuration: stopwatch.elapsed,
      );
    } catch (e) {
      warnings.add('Failed to parse Markdown: $e');
      return AdapterResult(
        document: DocumentNode(),
        warnings: warnings,
        parseDuration: stopwatch.elapsed,
      );
    }
  }

  /// Convert Markdown node to UDT node
  UDTNode? _convertNode(md.Node node, List<String> warnings) {
    if (node is md.Text) {
      return TextNode(node.text);
    }

    if (node is md.Element) {
      return _convertElement(node, warnings);
    }

    return null;
  }

  /// Convert Markdown element to UDT node
  UDTNode? _convertElement(md.Element element, List<String> warnings) {
    final tag = element.tag;
    final children = _convertChildren(element.children, warnings);
    final attributes = element.attributes;

    switch (tag) {
      // Headers
      case 'h1':
        return BlockNode(
          tagName: 'h1',
          style: ComputedStyle(
            display: DisplayType.block,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            margin: const EdgeInsets.only(top: 20, bottom: 8),
          ),
          children: children,
        );

      case 'h2':
        return BlockNode(
          tagName: 'h2',
          style: ComputedStyle(
            display: DisplayType.block,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            margin: const EdgeInsets.only(top: 16, bottom: 6),
          ),
          children: children,
        );

      case 'h3':
        return BlockNode(
          tagName: 'h3',
          style: ComputedStyle(
            display: DisplayType.block,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            margin: const EdgeInsets.only(top: 14, bottom: 4),
          ),
          children: children,
        );

      case 'h4':
        return BlockNode(
          tagName: 'h4',
          style: ComputedStyle(
            display: DisplayType.block,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
          ),
          children: children,
        );

      case 'h5':
      case 'h6':
        return BlockNode(
          tagName: tag,
          style: ComputedStyle(
            display: DisplayType.block,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            margin: const EdgeInsets.only(top: 10, bottom: 2),
          ),
          children: children,
        );

      // Paragraph
      case 'p':
        return BlockNode(
          tagName: 'p',
          style: ComputedStyle(
            display: DisplayType.block,
            margin: const EdgeInsets.only(bottom: 8),
          ),
          children: children,
        );

      // Bold
      case 'strong':
        return InlineNode.strong(children: children);

      // Italic
      case 'em':
        return InlineNode.em(children: children);

      // Strikethrough
      case 'del':
        return InlineNode.s(children: children);

      // Code (inline)
      case 'code':
        return InlineNode.code(children: children);

      // Code block
      case 'pre':
        return BlockNode(
          tagName: 'pre',
          style: ComputedStyle(
            display: DisplayType.block,
            fontFamily: 'monospace',
            backgroundColor: const Color(0x0D000000),
            padding: const EdgeInsets.all(12),
          ),
          children: children,
        );

      // Link — sanitize href to block javascript:/vbscript: XSS
      case 'a':
        final rawHref = attributes['href'] ?? '#';
        final href = HtmlSanitizer.isSafeUrl(rawHref) ? rawHref : '#';
        return InlineNode.a(href: href, children: children);

      // Image — sanitize src to block javascript:/data: XSS
      case 'img':
        final rawSrc = attributes['src'] ?? '';
        final src = HtmlSanitizer.isSafeUrl(rawSrc) ? rawSrc : '';
        final alt = attributes['alt'];
        return AtomicNode.img(src: src, alt: alt);

      // Blockquote
      case 'blockquote':
        return BlockNode.blockquote(children: children);

      // Lists
      case 'ul':
        return BlockNode(
          tagName: 'ul',
          style: ComputedStyle(
            display: DisplayType.block,
            padding: const EdgeInsets.only(left: 24),
          ),
          children: children,
        );

      case 'ol':
        return BlockNode(
          tagName: 'ol',
          style: ComputedStyle(
            display: DisplayType.block,
            padding: const EdgeInsets.only(left: 24),
          ),
          children: children,
        );

      case 'li':
        // Check for task list item
        if (element.attributes.containsKey('class') &&
            element.attributes['class']!.contains('task-list-item')) {
          final isChecked = children.isNotEmpty &&
              children.first is AtomicNode &&
              (children.first as AtomicNode).attributes['checked'] == 'true';

          return BlockNode(
            tagName: 'li',
            attributes: {'data-task': isChecked ? 'checked' : 'unchecked'},
            style: ComputedStyle(display: DisplayType.block),
            children: children,
          );
        }

        return BlockNode(
          tagName: 'li',
          style: ComputedStyle(display: DisplayType.block),
          children: children,
        );

      // Table
      case 'table':
        return TableNode(children: children);

      case 'thead':
      case 'tbody':
        return BlockNode(
          tagName: tag,
          children: children,
        );

      case 'tr':
        return TableRowNode(children: children);

      case 'th':
        return TableCellNode(
          isHeader: true,
          children: children,
        );

      case 'td':
        return TableCellNode(
          isHeader: false,
          children: children,
        );

      // Line break
      case 'br':
        return LineBreakNode();

      // Horizontal rule
      case 'hr':
        return BlockNode(
          tagName: 'hr',
          style: ComputedStyle(
            display: DisplayType.block,
            borderWidth: const EdgeInsets.only(top: 1),
            borderColor: const Color(0x33000000),
            margin: const EdgeInsets.symmetric(vertical: 16),
          ),
          children: [],
        );

      // Task list checkbox
      case 'input':
        final isChecked = attributes['checked'] == 'true';
        return AtomicNode(
          tagName: 'input',
          attributes: {
            'type': 'checkbox',
            'checked': isChecked ? 'true' : 'false',
          },
        );

      default:
        // Unknown tag - wrap in span
        warnings.add('Unknown Markdown element: $tag');
        return InlineNode(
          tagName: tag,
          children: children,
        );
    }
  }

  /// Convert list of Markdown nodes to UDT nodes
  List<UDTNode> _convertChildren(List<md.Node>? nodes, List<String> warnings) {
    if (nodes == null || nodes.isEmpty) return [];

    final result = <UDTNode>[];
    for (final node in nodes) {
      final udtNode = _convertNode(node, warnings);
      if (udtNode != null) {
        result.add(udtNode);
      }
    }
    return result;
  }
}

/// Extension methods for MarkdownAdapter
extension MarkdownAdapterExtensions on String {
  /// Parse this string as Markdown and return DocumentNode
  DocumentNode parseMarkdown({bool enableGfm = true}) {
    final adapter = MarkdownAdapter(enableGfm: enableGfm);
    return adapter.parse(this);
  }
}
