part of 'render_hyper_box.dart';

extension _RenderHyperBoxAccessibility on RenderHyperBox {
  /// Builds a plain text representation of the content for screen readers
  String _buildTextContentForSemantics() {
    if (_document == null) return '';

    final buffer = StringBuffer();
    _document!.traverse((node) {
      switch (node.type) {
        case NodeType.text:
          buffer.write((node as TextNode).text);
          break;
        case NodeType.ruby:
          // For ruby text, read both base and annotation
          final ruby = node as RubyNode;
          buffer.write('${ruby.baseText} (${ruby.rubyText})');
          break;
        case NodeType.lineBreak:
          buffer.write(' ');
          break;
        case NodeType.atomic:
          // For images, read alt text
          final atomic = node as AtomicNode;
          if (atomic.alt != null && atomic.alt!.isNotEmpty) {
            buffer.write('[Image: ${atomic.alt}] ');
          } else if (atomic.tagName == 'img') {
            buffer.write('[Image] ');
          }
          break;
        default:
          break;
      }
    });

    return buffer.toString().trim();
  }

  /// Recursively builds semantic nodes for the document tree
  void _buildSemanticNodes(
    UDTNode node,
    List<SemanticsNode> semanticNodes,
    SemanticsNode parentNode,
  ) {
    // Handle links - they need special semantic treatment
    if (node is InlineNode && node.tagName == 'a') {
      final href = node.attributes['href'];
      if (href != null) {
        final rect = _getNodeRect(node);
        if (rect != null && rect.width > 0 && rect.height > 0) {
          final linkNode = SemanticsNode();
          final ariaLinkLabel = node.attributes['aria-label'];
          linkNode.updateWith(
            config: SemanticsConfiguration()
              ..isLink = true
              ..textDirection = TextDirection.ltr
              ..label = ariaLinkLabel ?? node.textContent
              ..hint = 'Link to $href'
              ..onTap = () {
                onLinkTap?.call(href);
              },
          );
          linkNode.rect = rect;
          semanticNodes.add(linkNode);
        }
        return;
      }
    }

    // Handle headings h1-h6 — announce heading level; aria-label overrides text
    if (node is BlockNode && node.tagName != null) {
      final headingLevel = _getHeadingLevel(node.tagName!);
      if (headingLevel > 0) {
        final rect = _getNodeRect(node);
        if (rect != null && rect.width > 0 && rect.height > 0) {
          final headingNode = SemanticsNode();
          final ariaHeadingLabel = node.attributes['aria-label'];
          headingNode.updateWith(
            config: SemanticsConfiguration()
              ..isHeader = true
              ..textDirection = TextDirection.ltr
              ..label = ariaHeadingLabel ?? node.textContent
              ..hint = 'Heading level $headingLevel',
          );
          headingNode.rect = rect;
          semanticNodes.add(headingNode);
        }
        return;
      }
    }

    // Handle images — use aria-label or alt text
    if (node is AtomicNode && node.tagName == 'img') {
      final rect = _getNodeRect(node);
      if (rect != null && rect.width > 0 && rect.height > 0) {
        final imgNode = SemanticsNode();
        imgNode.updateWith(
          config: SemanticsConfiguration()
            ..isImage = true
            ..textDirection = TextDirection.ltr
            ..label = node.attributes['aria-label'] ?? node.alt ?? 'Image',
        );
        imgNode.rect = rect;
        semanticNodes.add(imgNode);
      }
      return;
    }

    // Handle buttons (tagName == 'button')
    if (node is BlockNode && node.tagName == 'button') {
      final rect = _getNodeRect(node);
      if (rect != null && rect.width > 0 && rect.height > 0) {
        final buttonNode = SemanticsNode();
        final ariaLabel = node.attributes['aria-label'];
        buttonNode.updateWith(
          config: SemanticsConfiguration()
            ..isButton = true
            ..textDirection = TextDirection.ltr
            ..label = ariaLabel ?? node.textContent,
        );
        buttonNode.rect = rect;
        semanticNodes.add(buttonNode);
      }
      return;
    }

    // Handle ARIA role attribute — maps to semantic properties for any element
    final role = node.attributes['role'];
    final ariaLabel = node.attributes['aria-label'];
    if (role != null) {
      switch (role) {
        case 'button':
          final rect = _getNodeRect(node);
          if (rect != null && rect.width > 0 && rect.height > 0) {
            final n = SemanticsNode();
            n.updateWith(
              config: SemanticsConfiguration()
                ..isButton = true
                ..textDirection = TextDirection.ltr
                ..label = ariaLabel ?? node.textContent,
            );
            n.rect = rect;
            semanticNodes.add(n);
          }
          return;
        case 'heading':
          final rect = _getNodeRect(node);
          if (rect != null && rect.width > 0 && rect.height > 0) {
            final n = SemanticsNode();
            n.updateWith(
              config: SemanticsConfiguration()
                ..isHeader = true
                ..textDirection = TextDirection.ltr
                ..label = ariaLabel ?? node.textContent,
            );
            n.rect = rect;
            semanticNodes.add(n);
          }
          return;
        case 'region':
        case 'navigation':
        case 'main':
        case 'banner':
        case 'contentinfo':
          // Landmarks: emit a labeled node then recurse into children
          if (ariaLabel != null) {
            final rect = _getNodeRect(node);
            if (rect != null && rect.width > 0 && rect.height > 0) {
              final n = SemanticsNode();
              n.updateWith(
                config: SemanticsConfiguration()
                  ..textDirection = TextDirection.ltr
                  ..label = ariaLabel,
              );
              n.rect = rect;
              semanticNodes.add(n);
            }
          }
          // Fall through to recurse children
          break;
        default:
          break;
      }
    }

    // Handle landmark HTML elements (nav, main, header, footer, article, section)
    if (node is BlockNode && node.tagName != null) {
      final tag = node.tagName!;
      if (tag == 'nav' || tag == 'main' || tag == 'header' ||
          tag == 'footer' || tag == 'article' || tag == 'section') {
        final label = ariaLabel ?? _landmarkLabel(tag);
        if (label != null) {
          final rect = _getNodeRect(node);
          if (rect != null && rect.width > 0 && rect.height > 0) {
            final n = SemanticsNode();
            n.updateWith(
              config: SemanticsConfiguration()
                ..textDirection = TextDirection.ltr
                ..label = label,
            );
            n.rect = rect;
            semanticNodes.add(n);
          }
        }
        // Recurse into children without returning — children may have more semantics
        for (final child in node.children) {
          _buildSemanticNodes(child, semanticNodes, parentNode);
        }
        return;
      }
    }

    // Handle list containers (ul/ol) — enumerate li children with ordinal hints
    if (node is BlockNode &&
        (node.tagName == 'ul' || node.tagName == 'ol')) {
      final liChildren = node.children
          .whereType<BlockNode>()
          .where((c) => c.tagName == 'li')
          .toList();
      final total = liChildren.length;
      int index = 0;
      for (final child in node.children) {
        if (child is BlockNode && child.tagName == 'li') {
          index++;
          final rect = _getNodeRect(child);
          if (rect != null && rect.width > 0 && rect.height > 0) {
            final n = SemanticsNode();
            n.updateWith(
              config: SemanticsConfiguration()
                ..textDirection = TextDirection.ltr
                ..label = child.textContent.trim()
                ..hint = 'Item $index of $total',
            );
            n.rect = rect;
            semanticNodes.add(n);
          }
          // Recurse deeper (nested lists, links inside li, etc.)
          for (final grandchild in child.children) {
            _buildSemanticNodes(grandchild, semanticNodes, parentNode);
          }
        } else {
          _buildSemanticNodes(child, semanticNodes, parentNode);
        }
      }
      return;
    }

    // Handle standalone li (outside ul/ol context — rare but valid)
    if (node is BlockNode && node.tagName == 'li') {
      final rect = _getNodeRect(node);
      if (rect != null && rect.width > 0 && rect.height > 0) {
        final n = SemanticsNode();
        n.updateWith(
          config: SemanticsConfiguration()
            ..textDirection = TextDirection.ltr
            ..label = node.textContent.trim(),
        );
        n.rect = rect;
        semanticNodes.add(n);
      }
      return;
    }

    // Handle pre/code blocks — announce as "Code block: [content]"
    if (node is BlockNode && node.tagName == 'pre') {
      final rect = _getNodeRect(node);
      if (rect != null && rect.width > 0 && rect.height > 0) {
        final n = SemanticsNode();
        n.updateWith(
          config: SemanticsConfiguration()
            ..textDirection = TextDirection.ltr
            ..label = 'Code block: ${node.textContent.trim()}',
        );
        n.rect = rect;
        semanticNodes.add(n);
      }
      return;
    }

    // Recursively process children
    for (final child in node.children) {
      _buildSemanticNodes(child, semanticNodes, parentNode);
    }
  }

  /// Returns a descriptive label for landmark HTML elements, or null for generic ones.
  String? _landmarkLabel(String tagName) {
    switch (tagName) {
      case 'nav':
        return 'Navigation';
      case 'main':
        return 'Main content';
      case 'header':
        return 'Page header';
      case 'footer':
        return 'Page footer';
      default:
        return null; // section/article only get labels via aria-label
    }
  }

  /// Gets the heading level from a tag name (h1 = 1, h2 = 2, etc.)
  int _getHeadingLevel(String tagName) {
    switch (tagName) {
      case 'h1':
        return 1;
      case 'h2':
        return 2;
      case 'h3':
        return 3;
      case 'h4':
        return 4;
      case 'h5':
        return 5;
      case 'h6':
        return 6;
      default:
        return 0;
    }
  }

  /// Gets the bounding rect for a node based on its fragments
  Rect? _getNodeRect(UDTNode node) {
    double? minX, minY, maxX, maxY;

    for (final fragment in _fragments) {
      if (fragment.sourceNode == node || _isDescendantOf(fragment.sourceNode, node)) {
        final rect = fragment.rect;
        if (rect != null) {
          minX = minX == null ? rect.left : math.min(minX, rect.left);
          minY = minY == null ? rect.top : math.min(minY, rect.top);
          maxX = maxX == null ? rect.right : math.max(maxX, rect.right);
          maxY = maxY == null ? rect.bottom : math.max(maxY, rect.bottom);
        }
      }
    }

    if (minX != null && minY != null && maxX != null && maxY != null) {
      return Rect.fromLTRB(minX, minY, maxX, maxY);
    }
    return null;
  }

  /// Checks if a node is a descendant of another node
  bool _isDescendantOf(UDTNode? child, UDTNode parent) {
    if (child == null) return false;
    if (child == parent) return true;

    for (final parentChild in parent.children) {
      if (_isDescendantOf(child, parentChild)) {
        return true;
      }
    }
    return false;
  }
}
