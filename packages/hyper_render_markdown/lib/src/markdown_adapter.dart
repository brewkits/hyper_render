import 'package:flutter/painting.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:hyper_render_core/hyper_render_core.dart';

/// Markdown to UDT adapter
///
/// Converts Markdown string into Unified Document Tree.
/// Uses the `markdown` package to parse Markdown AST,
/// then converts to UDT nodes.
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
class MarkdownAdapter {
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

  /// Parse Markdown content into DocumentNode
  DocumentNode parse(String content) {
    return parseExtended(content).document;
  }

  /// Parse with full result including metadata
  ParseResult parseExtended(String content) {
    final stopwatch = Stopwatch()..start();
    final warnings = <String>[];

    try {
      // Build extension set
      final extensionSet =
          enableGfm ? md.ExtensionSet.gitHubFlavored : md.ExtensionSet.none;

      // Build block syntaxes
      final blockSyntaxes = <md.BlockSyntax>[
        ...extensionSet.blockSyntaxes,
        if (customBlockSyntaxes != null) ...customBlockSyntaxes!,
      ];

      // Build inline syntaxes
      final inlineSyntaxes = <md.InlineSyntax>[
        ...extensionSet.inlineSyntaxes,
        if (customInlineSyntaxes != null) ...customInlineSyntaxes!,
      ];

      // Parse Markdown to AST
      final document = md.Document(
        extensionSet: extensionSet,
        blockSyntaxes: blockSyntaxes,
        inlineSyntaxes: inlineSyntaxes,
        encodeHtml: !enableInlineHtml,
      );

      final lines = content.split('\n');
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

      return ParseResult(
        document: DocumentNode(children: udtChildren),
        warnings: warnings,
        parseDuration: stopwatch.elapsed,
      );
    } catch (e) {
      warnings.add('Failed to parse Markdown: $e');
      return ParseResult(
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
            fontSize: 32,
            fontWeight: FontWeight.bold,
            margin: const EdgeInsets.symmetric(vertical: 21.44),
          ),
          children: children,
        );

      case 'h2':
        return BlockNode(
          tagName: 'h2',
          style: ComputedStyle(
            display: DisplayType.block,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            margin: const EdgeInsets.symmetric(vertical: 19.92),
          ),
          children: children,
        );

      case 'h3':
        return BlockNode(
          tagName: 'h3',
          style: ComputedStyle(
            display: DisplayType.block,
            fontSize: 18.72,
            fontWeight: FontWeight.bold,
            margin: const EdgeInsets.symmetric(vertical: 18.72),
          ),
          children: children,
        );

      case 'h4':
      case 'h5':
      case 'h6':
        return BlockNode(
          tagName: tag,
          style: ComputedStyle(
            display: DisplayType.block,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            margin: const EdgeInsets.symmetric(vertical: 16),
          ),
          children: children,
        );

      // Paragraph
      case 'p':
        return BlockNode.p(children: children);

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
            whiteSpace: 'pre',
            backgroundColor: const Color(0xFF1E1E1E),
            color: const Color(0xFFD4D4D4),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 12),
            borderRadius: BorderRadius.circular(8),
            fontSize: 13,
            lineHeight: 1.6,
          ),
          children: children,
        );

      // Link
      case 'a':
        final href = attributes['href'] ?? '#';
        return InlineNode.a(href: href, children: children);

      // Image
      case 'img':
        final src = attributes['src'] ?? '';
        final alt = attributes['alt'];
        return AtomicNode.img(src: src, alt: alt);

      // Blockquote
      case 'blockquote':
        return BlockNode(
          tagName: 'blockquote',
          style: ComputedStyle(
            display: DisplayType.block,
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
            padding: const EdgeInsets.only(left: 16),
            borderColor: const Color(0xFFCCCCCC),
            borderWidth: const EdgeInsets.only(left: 4),
          ),
          children: children,
        );

      // Lists
      case 'ul':
        return BlockNode(
          tagName: 'ul',
          style: ComputedStyle(
            display: DisplayType.block,
            padding: const EdgeInsets.only(left: 40),
            margin: const EdgeInsets.symmetric(vertical: 16),
          ),
          children: children,
        );

      case 'ol':
        return BlockNode(
          tagName: 'ol',
          style: ComputedStyle(
            display: DisplayType.block,
            padding: const EdgeInsets.only(left: 40),
            margin: const EdgeInsets.symmetric(vertical: 16),
          ),
          children: children,
        );

      case 'li':
        return BlockNode(
          tagName: 'li',
          style: ComputedStyle(
            display: DisplayType.block,
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
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
            borderColor: const Color(0xFFCCCCCC),
            margin: const EdgeInsets.symmetric(vertical: 16),
          ),
          children: [],
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
  List<UDTNode> _convertChildren(
      List<md.Node>? nodes, List<String> warnings) {
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
