import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../../model/node.dart';
import '../../model/computed_style.dart';

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
    'pre': ComputedStyle(display: DisplayType.block, fontFamily: 'monospace', whiteSpace: 'pre'),
    'code': ComputedStyle(fontFamily: 'monospace', backgroundColor: const Color(0xFFF0F0F0)),
    'a': ComputedStyle(color: Colors.blue, textDecoration: TextDecoration.underline),
    'mark': ComputedStyle(backgroundColor: const Color(0xFFFFFF00)), // Yellow highlight
    'span': ComputedStyle(),
    'ul': ComputedStyle(display: DisplayType.block, padding: const EdgeInsets.only(left: 40)),
    'ol': ComputedStyle(display: DisplayType.block, padding: const EdgeInsets.only(left: 40)),
    'li': ComputedStyle(display: DisplayType.block, margin: const EdgeInsets.symmetric(vertical: 4)),
  'thead': ComputedStyle(display: DisplayType.block),
  'tbody': ComputedStyle(display: DisplayType.block),
  'tfoot': ComputedStyle(display: DisplayType.block),
  };

  DocumentNode parse(String html) {
    final document = html_parser.parse(html);
    return _parseDocument(document);
  }

  List<DocumentNode> parseToSections(String html, {int chunkSize = 3000}) {
    final document = html_parser.parse(html);
    final body = document.body;

    if (body == null) return [];

    List<DocumentNode> sections = [];
    DocumentNode currentSection = DocumentNode(children: []);
    int currentSize = 0;

    for (var child in body.nodes) {
      UDTNode? udtNode = _parseNode(child);
      
      if (udtNode != null) {
        currentSection.children.add(udtNode);
        currentSize += child.text?.length ?? 100;

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

  DocumentNode _parseDocument(dom.Document document) {
    final root = DocumentNode(children: []);
    if (document.body != null) {
      for (var child in document.body!.nodes) {
        final node = _parseNode(child);
        if (node != null) {
          root.children.add(node);
        }
      }
    }
    return root;
  }

  UDTNode? _parseNode(dom.Node node) {
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
        return AtomicNode(
          tagName: tagName,
          attributes: element.attributes.map((k, v) => MapEntry(k.toString(), v)),
          style: defaultStyle,
          src: element.attributes['src'],
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
            rubyText += child.text;
          }
        }
        return RubyNode(
          baseText: baseText.trim(),
          rubyText: rubyText.trim(),
          style: defaultStyle,
        );
      }

      final children = element.nodes.map(_parseNode).whereType<UDTNode>().toList();

      UDTNode result;
      if (tagName == 'table') {
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
