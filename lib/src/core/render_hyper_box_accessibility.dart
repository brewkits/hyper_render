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
        // Only add semantic node if it has a valid, visible rect
        if (rect != null && rect.width > 0 && rect.height > 0) {
          final linkNode = SemanticsNode();

          linkNode.updateWith(
            config: SemanticsConfiguration()
              ..isLink = true
              ..textDirection = _textDirection
              ..label = node.textContent
              ..hint = 'Link to $href'
              ..onTap = () {
                _onLinkTap?.call(href);
              },
          );

          linkNode.rect = rect;
          semanticNodes.add(linkNode);
        }
        return; // Don't process children of links separately
      }
    }

    // Handle headings - announce heading level
    if (node is BlockNode && node.tagName != null) {
      final headingLevel = _getHeadingLevel(node.tagName!);
      if (headingLevel > 0) {
        final rect = _getNodeRect(node);
        // Only add semantic node if it has a valid, visible rect
        if (rect != null && rect.width > 0 && rect.height > 0) {
          final headingNode = SemanticsNode();

          headingNode.updateWith(
            config: SemanticsConfiguration()
              ..isHeader = true
              ..textDirection = _textDirection
              ..label = node.textContent
              ..hint = 'Heading level $headingLevel',
          );

          headingNode.rect = rect;
          semanticNodes.add(headingNode);
        }
        return;
      }
    }

    // Handle images
    if (node is AtomicNode && node.tagName == 'img') {
      final rect = _getNodeRect(node);
      // Only add semantic node if it has a valid, visible rect
      if (rect != null && rect.width > 0 && rect.height > 0) {
        final imgNode = SemanticsNode();

        imgNode.updateWith(
          config: SemanticsConfiguration()
            ..isImage = true
            ..textDirection = _textDirection
            ..label = node.alt ?? 'Image',
        );

        imgNode.rect = rect;
        semanticNodes.add(imgNode);
      }
      return;
    }

    // Handle buttons (if any interactive elements)
    if (node is BlockNode && node.tagName == 'button') {
      final rect = _getNodeRect(node);
      // Only add semantic node if it has a valid, visible rect
      if (rect != null && rect.width > 0 && rect.height > 0) {
        final buttonNode = SemanticsNode();

        buttonNode.updateWith(
          config: SemanticsConfiguration()
            ..isButton = true
            ..textDirection = _textDirection
            ..label = node.textContent,
        );

        buttonNode.rect = rect;
        semanticNodes.add(buttonNode);
      }
      return;
    }

    // Recursively process children
    for (final child in node.children) {
      _buildSemanticNodes(child, semanticNodes, parentNode);
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
