import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:hyper_render_core/hyper_render_core.dart';

class HtmlAdapter {
  static final Map<String, ComputedStyle> _defaultStyles = {
    'h1': ComputedStyle(display: DisplayType.block, fontSize: 32, fontWeight: FontWeight.bold, margin: const EdgeInsets.symmetric(vertical: 21.44)),
    'h2': ComputedStyle(display: DisplayType.block, fontSize: 24, fontWeight: FontWeight.bold, margin: const EdgeInsets.symmetric(vertical: 19.92)),
    'h3': ComputedStyle(display: DisplayType.block, fontSize: 18.72, fontWeight: FontWeight.bold, margin: const EdgeInsets.symmetric(vertical: 18.72)),
    'p': ComputedStyle(display: DisplayType.block, margin: const EdgeInsets.symmetric(vertical: 16)),
    'div': ComputedStyle(display: DisplayType.block),
    'b': ComputedStyle(fontWeight: FontWeight.bold),
    'strong': ComputedStyle(fontWeight: FontWeight.bold),
    'i': ComputedStyle(fontStyle: FontStyle.italic),
    'em': ComputedStyle(fontStyle: FontStyle.italic),
    'blockquote': ComputedStyle(
      display: DisplayType.block,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
      padding: const EdgeInsets.only(left: 16),
      borderColor: const Color(0xFFCCCCCC),
      borderWidth: const EdgeInsets.only(left: 4),
    ),
    'pre': ComputedStyle(
      display: DisplayType.block,
      fontFamily: 'monospace',
      whiteSpace: 'pre',
      backgroundColor: const Color(0xFF1E1E1E), // Dark background like VS Code
      color: const Color(0xFFD4D4D4), // Light text
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 12),
      borderRadius: BorderRadius.circular(8),
      fontSize: 13,
      lineHeight: 1.6,
    ),
    'code': ComputedStyle(
      fontFamily: 'monospace',
      backgroundColor: const Color(0xFFE8E8E8), // Light gray background
      color: const Color(0xFFE91E63), // Pink/magenta for inline code
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      borderRadius: BorderRadius.circular(4),
      fontSize: 13,
    ),
    'a': ComputedStyle(color: Colors.blue, textDecoration: TextDecoration.underline),
    'mark': ComputedStyle(backgroundColor: const Color(0xFFFFFF00)), // Yellow highlight
    'span': ComputedStyle(),
    'ul': ComputedStyle(
      display: DisplayType.block,
      padding: const EdgeInsets.only(left: 40),
      listStyleType: ListStyleType.disc, // Default bullet for unordered lists
    ),
    'ol': ComputedStyle(
      display: DisplayType.block,
      padding: const EdgeInsets.only(left: 40),
      listStyleType: ListStyleType.decimal, // Default numbers for ordered lists
    ),
    'li': ComputedStyle(display: DisplayType.block, margin: const EdgeInsets.symmetric(vertical: 4)),
  'thead': ComputedStyle(display: DisplayType.block),
  'tbody': ComputedStyle(display: DisplayType.block),
  'tfoot': ComputedStyle(display: DisplayType.block),
  };

  DocumentNode parse(String html, {String? baseUrl}) {
    final document = html_parser.parse(html);
    return _parseDocument(document, baseUrl);
  }

  /// Extracts concatenated text content from all `<style>` tags in [html].
  ///
  /// `@import` directives are stripped to prevent loading external stylesheets.
  String extractCss(String html) {
    final document = html_parser.parse(html);
    final buffer = StringBuffer();
    for (final style in document.querySelectorAll('style')) {
      buffer.writeln(style.text);
    }
    final css = buffer.toString();
    // Strip @import to prevent external stylesheet loading.
    return css.replaceAll(
        RegExp(r'@import\s+[^;]+;', caseSensitive: false), '');
  }

  List<DocumentNode> parseToSections(String html, {int chunkSize = 3000, String? baseUrl}) {
    final document = html_parser.parse(html);
    final body = document.body;

    if (body == null) return [];

    List<DocumentNode> sections = [];
    DocumentNode currentSection = DocumentNode(children: []);
    int currentSize = 0;

    // Flatten nodes - if a container is too large, extract its children
    final nodesToProcess = _flattenLargeContainers(body.nodes.toList(), chunkSize);

    for (var child in nodesToProcess) {
      UDTNode? udtNode = _parseNode(child, baseUrl);

      if (udtNode != null) {
        currentSection.children.add(udtNode);
        currentSize += _estimateNodeSize(child);

        if (currentSize >= chunkSize && udtNode.isBlock) {
          sections.add(currentSection);
          currentSection = DocumentNode(children: []);
          currentSize = 0;
        }
      }
    }

    if (currentSection.children.isNotEmpty) {
      sections.add(currentSection);
    }

    if (sections.isEmpty) {
      sections.add(DocumentNode(children: []));
    }

    return sections;
  }

  /// Flatten large container nodes (div, section, article, main) to enable virtualization
  /// This handles the "Giant Div" edge case where one wrapper contains all content
  List<dom.Node> _flattenLargeContainers(List<dom.Node> nodes, int chunkSize) {
    final result = <dom.Node>[];

    for (final node in nodes) {
      if (node is dom.Element) {
        final tagName = node.localName?.toLowerCase();
        final nodeSize = _estimateNodeSize(node);

        // If this is a large container element, extract its children instead
        final isContainer = const ['div', 'section', 'article', 'main', 'header', 'footer', 'aside']
            .contains(tagName);

        if (isContainer && nodeSize > chunkSize && node.nodes.length > 1) {
          // Recursively flatten children of this large container
          result.addAll(_flattenLargeContainers(node.nodes.toList(), chunkSize));
        } else {
          result.add(node);
        }
      } else {
        result.add(node);
      }
    }

    return result;
  }

  /// Estimate the size of a node for chunking purposes
  int _estimateNodeSize(dom.Node node) {
    if (node is dom.Text) {
      return node.text.length;
    }
    if (node is dom.Element) {
      // Estimate based on inner text + some overhead for tags/attributes
      final textLength = node.text.length;
      final overhead = node.nodes.length * 10; // Rough estimate for structure
      return textLength + overhead;
    }
    return 50; // Default estimate for unknown nodes
  }

  /// Resolve relative URLs with base URL.
  ///
  /// Handles cases like:
  /// - Relative: "/logo.png" + "https://example.com" = "https://example.com/logo.png"
  /// - Absolute: "https://cdn.com/img.png" + baseUrl = unchanged
  /// - Protocol-relative: "//cdn.com/img.png" + baseUrl = adds protocol
  ///
  /// Silently drops dangerous protocols to prevent XSS:
  /// `javascript:`, `vbscript:`, `data:text/...`, `data:application/...`
  String? _resolveUrl(String? url, String? baseUrl) {
    if (url == null || url.isEmpty) return null;

    // Block dangerous protocols — compare against lowercased, trimmed URL
    final lower = url.toLowerCase().trimLeft();
    if (lower.startsWith('javascript:') ||
        lower.startsWith('vbscript:') ||
        lower.startsWith('data:text') ||
        lower.startsWith('data:application')) {
      return null; // Silently drop to prevent XSS / code injection
    }

    if (baseUrl == null || baseUrl.isEmpty) return url;

    try {
      // Resolve relative URL with base
      return Uri.parse(baseUrl).resolve(url).toString();
    } catch (_) {
      // If parsing fails, return original URL
      return url;
    }
  }

  DocumentNode _parseDocument(dom.Document document, String? baseUrl) {
    final root = DocumentNode(children: []);
    if (document.body != null) {
      for (var child in document.body!.nodes) {
        final node = _parseNode(child, baseUrl);
        if (node != null) {
          root.children.add(node);
        }
      }
    }
    return root;
  }

  UDTNode? _parseNode(dom.Node node, String? baseUrl) {
    if (node.nodeType == dom.Node.TEXT_NODE) {
      if (node.text == null || node.text!.trim().isEmpty) return null;
      return TextNode(node.text!);
    }

    if (node.nodeType == dom.Node.ELEMENT_NODE) {
      final element = node as dom.Element;
      final tagName = element.localName?.toLowerCase() ?? 'div';
      final defaultStyle = _defaultStyles[tagName] ?? ComputedStyle();

      if (_isAtomic(element)) {
        if (tagName == 'br' || tagName == 'hr') {
          return LineBreakNode(); // Simplified
        }

        // Resolve src attribute for media elements (img, video, audio, iframe)
        String? src = element.attributes['src'];
        if (src != null) {
          src = _resolveUrl(src, baseUrl);
        }

        return AtomicNode(
          tagName: tagName,
          attributes: element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          style: defaultStyle,
          src: src,
          alt: element.attributes['alt'],
          intrinsicWidth: double.tryParse(element.attributes['width'] ?? ''),
          intrinsicHeight: double.tryParse(element.attributes['height'] ?? ''),
        );
      }

      if (tagName == 'ruby') {
        String baseText = '';
        String rubyText = '';
        for (var child in element.nodes) {
          if (child.nodeType == dom.Node.TEXT_NODE) {
            baseText += child.text ?? '';
          } else if (child.nodeType == dom.Node.ELEMENT_NODE && (child as dom.Element).localName == 'rt') {
            rubyText += child.text ?? '';
          }
        }
        return RubyNode(
          baseText: baseText.trim(),
          rubyText: rubyText.trim(),
          style: defaultStyle,
        );
      }

      // Resolve href attribute for link elements
      if (tagName == 'a') {
        String? href = element.attributes['href'];
        if (href != null) {
          final resolvedHref = _resolveUrl(href, baseUrl);
          if (resolvedHref != null) {
            element.attributes['href'] = resolvedHref;
          }
        }
      }

      final children = element.nodes.map((n) => _parseNode(n, baseUrl)).whereType<UDTNode>().toList();

      UDTNode result;
      if (tagName == 'details') {
        // Parse <details> element with optional 'open' attribute
        final isOpen = element.attributes.containsKey('open');
        result = DetailsNode(
          attributes: element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          style: defaultStyle,
          children: children,
          open: isOpen,
        );
      } else if (tagName == 'table') {
        result = TableNode(
          attributes: element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          style: defaultStyle,
          children: children,
        );
      } else if (tagName == 'tr') {
        result = TableRowNode(
          attributes: element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          style: defaultStyle,
          children: children,
        );
      } else if (tagName == 'td' || tagName == 'th') {
        result = TableCellNode(
          isHeader: tagName == 'th',
          attributes: element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          style: defaultStyle,
          children: children,
        );
      } else if (defaultStyle.display == DisplayType.block) {
        result = BlockNode(
          tagName: tagName,
          attributes: element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          style: defaultStyle,
          children: children,
        );
      } else {
        result = InlineNode(
          tagName: tagName,
          attributes: element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          style: defaultStyle,
          children: children,
        );
      }

      // Set parent reference for all children
      for (final child in children) {
        child.parent = result;
      }

      return result;
    }

    return null;
  }

  bool _isAtomic(dom.Element element) {
    return const ['img', 'video', 'audio', 'iframe', 'br', 'hr', 'input'].contains(element.localName);
  }

}
