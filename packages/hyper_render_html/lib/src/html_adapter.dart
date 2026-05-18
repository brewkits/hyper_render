import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:hyper_render_core/hyper_render_core.dart';

/// HTML to UDT adapter
///
/// Converts HTML strings into Unified Document Tree (UDT) nodes.
/// Supports CSS styles, relative URL resolution, and document chunking
/// for virtualized rendering.
class HtmlAdapter {
  static final Map<String, ComputedStyle> _defaultStyles = {
    'h1': ComputedStyle(
        display: DisplayType.block,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        margin: const EdgeInsets.symmetric(vertical: 21.44)),
    'h2': ComputedStyle(
        display: DisplayType.block,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        margin: const EdgeInsets.symmetric(vertical: 19.92)),
    'h3': ComputedStyle(
        display: DisplayType.block,
        fontSize: 18.72,
        fontWeight: FontWeight.bold,
        margin: const EdgeInsets.symmetric(vertical: 18.72)),
    'p': ComputedStyle(
        display: DisplayType.block,
        margin: const EdgeInsets.symmetric(vertical: 16)),
    'div': ComputedStyle(display: DisplayType.block),
    'b': ComputedStyle(fontWeight: FontWeight.bold),
    'strong': ComputedStyle(fontWeight: FontWeight.bold),
    'i': ComputedStyle(fontStyle: FontStyle.italic),
    'em': ComputedStyle(fontStyle: FontStyle.italic),
    'blockquote': ComputedStyle(
      display: DisplayType.block,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
      padding: const EdgeInsets.only(left: 16),
      borderColor: const Color(0x33000000),
      borderWidth: const EdgeInsets.only(left: 4),
    ),
    'pre': ComputedStyle(
      display: DisplayType.block,
      fontFamily: 'monospace',
      whiteSpace: 'pre',
      backgroundColor: const Color(0x0D000000),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 12),
      borderRadius: BorderRadius.circular(8),
      fontSize: 13,
      lineHeight: 1.6,
    ),
    'code': ComputedStyle(
      fontFamily: 'monospace',
      backgroundColor: const Color(0x14000000),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      borderRadius: BorderRadius.circular(4),
      fontSize: 13,
    ),
    'a': ComputedStyle(
        color: Colors.blue, textDecoration: TextDecoration.underline),
    'mark': ComputedStyle(
        backgroundColor: const Color(0xFFFFFF00)), // Yellow highlight
    'span': ComputedStyle(),
    'ul': ComputedStyle(
      display: DisplayType.block,
      padding: const EdgeInsets.only(left: 40),
    ),
    'ol': ComputedStyle(
      display: DisplayType.block,
      padding: const EdgeInsets.only(left: 40),
    ),
    'li': ComputedStyle(
        display: DisplayType.block,
        margin: const EdgeInsets.symmetric(vertical: 4)),
    'thead': ComputedStyle(display: DisplayType.block),
    'tbody': ComputedStyle(display: DisplayType.block),
    'tfoot': ComputedStyle(display: DisplayType.block),
  };

  /// Parses [html] into a single [DocumentNode].
  DocumentNode parse(String html, {String? baseUrl}) {
    final document = html_parser.parse(html);
    return _parseDocument(document, baseUrl);
  }

  /// Extracts the concatenated text of all `<style>` elements in [html].
  ///
  /// Call this **before** sanitizing so that `<style>` tags are not stripped
  /// before the CSS rules are collected.
  String extractCss(String html) {
    final document = html_parser.parse(html);
    final buffer = StringBuffer();
    for (final el in document.querySelectorAll('style')) {
      final text = el.text;
      if (text.isNotEmpty) {
        buffer.write(text);
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }

  /// Parses `@keyframes` rules from all `<style>` elements in [html].
  ///
  /// Returns a map from animation name → [HyperKeyframes].  The result can be
  /// merged into [HyperRenderConfig.keyframeRegistry] so that the renderer
  /// can drive CSS animations declared in the document itself.
  ///
  /// Call this **before** sanitizing (same reason as [extractCss]).
  Map<String, HyperKeyframes> extractKeyframes(
      String html, CssParserInterface cssParser) {
    final css = extractCss(html);
    if (css.isEmpty) return const {};
    return cssParser.parseKeyframes(css);
  }

  /// Parses [html] into multiple [DocumentNode] chunks for virtualization.
  ///
  /// [chunkSize] is an estimate of the number of characters per section.
  /// Prevents splitting at sensitive boundaries like headings and floats.
  List<DocumentNode> parseToSections(String html,
      {int chunkSize = 3000, String? baseUrl}) {
    final document = html_parser.parse(html);
    final body = document.body;

    if (body == null) return [];

    List<DocumentNode> sections = [];
    DocumentNode currentSection = DocumentNode(children: []);
    int currentSize = 0;

    // Flatten nodes - if a container is too large, extract its children
    final nodesToProcess =
        _flattenLargeContainers(body.nodes.toList(), chunkSize);

    for (int i = 0; i < nodesToProcess.length; i++) {
      final child = nodesToProcess[i];
      final UDTNode? udtNode = _parseNode(child, baseUrl);

      if (udtNode != null) {
        currentSection.children.add(udtNode);
        currentSize += _estimateNodeSize(child);

        if (currentSize >= chunkSize && udtNode.isBlock) {
          // Protection logic from root adapter
          final lastTag = udtNode.tagName?.toLowerCase();
          final isHeading = lastTag == 'h1' ||
              lastTag == 'h2' ||
              lastTag == 'h3' ||
              lastTag == 'h4' ||
              lastTag == 'h5' ||
              lastTag == 'h6';

          bool nextIsHeading = false;
          if (!isHeading && i + 1 < nodesToProcess.length) {
            final nextTag = nodesToProcess[i + 1] is dom.Element
                ? (nodesToProcess[i + 1] as dom.Element)
                    .localName
                    ?.toLowerCase()
                : null;
            nextIsHeading = nextTag == 'h1' ||
                nextTag == 'h2' ||
                nextTag == 'h3' ||
                nextTag == 'h4' ||
                nextTag == 'h5' ||
                nextTag == 'h6';
          }

          final currentHasFloat = _containsFloatChild(child);
          if (!isHeading && !nextIsHeading && !currentHasFloat) {
            sections.add(currentSection);
            currentSection = DocumentNode(children: []);
            currentSize = 0;
          }
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

        final isContainer = const [
          'div',
          'section',
          'article',
          'main',
          'header',
          'footer',
          'aside'
        ].contains(tagName);

        final hasStyle = node.attributes['style']?.isNotEmpty == true;
        final hasClass = node.attributes['class']?.isNotEmpty == true;
        final canFlatten =
            isContainer && nodeSize > chunkSize && node.nodes.length > 1;

        if (canFlatten && !hasStyle && !hasClass) {
          result
              .addAll(_flattenLargeContainers(node.nodes.toList(), chunkSize));
        } else {
          result.add(node);
        }
      } else {
        result.add(node);
      }
    }

    return result;
  }

  int _estimateNodeSize(dom.Node node) {
    if (node is dom.Text) {
      return node.text.length;
    }
    if (node is dom.Element) {
      final textLength = node.text.length;
      final overhead = node.nodes.length * 10;
      return textLength + overhead;
    }
    return 50;
  }

  String? _resolveUrl(String? url, String? baseUrl) {
    if (url == null || url.isEmpty) return null;
    if (baseUrl == null || baseUrl.isEmpty) return url;

    try {
      return Uri.parse(baseUrl).resolve(url).toString();
    } catch (_) {
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
      final text = node.text;
      if (text == null || text.isEmpty) return null;
      if (text.trim().isEmpty) {
        if (text.contains('\n') || text.contains('\r')) {
          return TextNode(' ');
        }
        return TextNode(text);
      }
      return TextNode(text);
    }

    if (node.nodeType == dom.Node.ELEMENT_NODE) {
      final element = node as dom.Element;
      final tagName = element.localName?.toLowerCase() ?? 'div';
      final defaultStyle = _defaultStyles[tagName] ?? ComputedStyle();

      // Inline SVG handling
      if (tagName == 'svg') {
        return AtomicNode.svg(
          svgData: element.outerHtml,
          width: double.tryParse(element.attributes['width'] ?? ''),
          height: double.tryParse(element.attributes['height'] ?? ''),
        );
      }

      if (_isAtomic(element)) {
        if (tagName == 'br') {
          return LineBreakNode();
        }
        if (tagName == 'hr') {
          return BlockNode(
            tagName: 'hr',
            style: ComputedStyle(
              display: DisplayType.block,
              margin: const EdgeInsets.symmetric(vertical: 8),
              borderWidth: const EdgeInsets.only(bottom: 1),
              borderColor: const Color(0xFFCCCCCC),
              borderBottomStyle: HyperBorderStyle.solid,
            ),
          );
        }

        String? src = element.attributes['src'];
        if (src != null) {
          src = _resolveUrl(src, baseUrl);
        }

        return AtomicNode(
          tagName: tagName,
          attributes:
              element.attributes.map((k, v) => MapEntry(k.toString(), v)),
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
          if (child.nodeType == dom.Node.ELEMENT_NODE) {
            final childEl = child as dom.Element;
            if (childEl.localName == 'rt' || childEl.localName == 'rp') {
              if (childEl.localName == 'rt') rubyText += childEl.text;
            } else {
              baseText += childEl.text;
            }
          } else if (child.nodeType == dom.Node.TEXT_NODE) {
            baseText += child.text ?? '';
          }
        }
        return RubyNode(
          baseText: baseText.trim(),
          rubyText: rubyText.trim(),
          style: defaultStyle,
        );
      }

      if (tagName == 'a') {
        String? href = element.attributes['href'];
        if (href != null) {
          final resolvedHref = _resolveUrl(href, baseUrl);
          if (resolvedHref != null) {
            element.attributes['href'] = resolvedHref;
          }
        }
      }

      final children = element.nodes
          .map((n) => _parseNode(n, baseUrl))
          .whereType<UDTNode>()
          .toList();

      UDTNode result;
      if (tagName == 'details') {
        result = BlockNode(
          tagName: 'details',
          attributes:
              element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          style: defaultStyle,
          children: children,
        );
      } else if (tagName == 'summary') {
        // Summary is special — usually block-like inside <details> but semantic
        result = BlockNode(
          tagName: 'summary',
          attributes:
              element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          style: defaultStyle,
          children: children,
        );
      } else if (tagName == 'table') {
        result = TableNode(
          attributes:
              element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          style: defaultStyle,
          children: children,
        );
      } else if (tagName == 'tr') {
        result = TableRowNode(
          attributes:
              element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          style: defaultStyle,
          children: children,
        );
      } else if (tagName == 'td' || tagName == 'th') {
        result = TableCellNode(
          isHeader: tagName == 'th',
          attributes:
              element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          style: defaultStyle,
          children: children,
        );
      } else if (defaultStyle.display == DisplayType.block) {
        result = BlockNode(
          tagName: tagName,
          attributes:
              element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          style: defaultStyle,
          children: children,
        );
      } else {
        result = InlineNode(
          tagName: tagName,
          attributes:
              element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          style: defaultStyle,
          children: children,
        );
      }

      for (final child in children) {
        child.parent = result;
      }

      return result;
    }

    return null;
  }

  bool _isAtomic(dom.Element element) {
    return const ['img', 'video', 'audio', 'iframe', 'br', 'hr', 'input']
        .contains(element.localName);
  }

  bool _containsFloatChild(dom.Node node) {
    if (node is dom.Element) {
      // Inline style: match with or without space around the colon (float:left / float: left)
      final style = node.attributes['style'] ?? '';
      if (style.contains('float:left') ||
          style.contains('float: left') ||
          style.contains('float:right') ||
          style.contains('float: right')) {
        return true;
      }
      // CSS utility class names: Bootstrap 3 (pull-*), Bootstrap 4/5 (float-*,
      // float-start, float-end), Tailwind (float-left, float-right).
      final classes = node.attributes['class'] ?? '';
      if (classes.contains('float-left') ||
          classes.contains('float-right') ||
          classes.contains('float-start') ||
          classes.contains('float-end') ||
          classes.contains('pull-left') ||
          classes.contains('pull-right')) {
        return true;
      }
      for (final child in node.nodes) {
        if (_containsFloatChild(child)) return true;
      }
    }
    return false;
  }
}
