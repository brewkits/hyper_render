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
    if (node.tagName == 'button') {
      final rect = _getNodeRect(node);
      // Only add semantic node if it has a valid, visible rect
      if (rect != null && rect.width > 0 && rect.height > 0) {
        final buttonNode = SemanticsNode();
        final label = _ariaLabel(node) ?? node.textContent;
        buttonNode.updateWith(
          config: SemanticsConfiguration()
            ..isButton = true
            ..textDirection = _textDirection
            ..label = label,
        );
        buttonNode.rect = rect;
        semanticNodes.add(buttonNode);
      }
      return;
    }

    // Handle <input type="button"> / <input type="submit"> / <input type="reset">
    if (node.tagName == 'input') {
      final inputType = node.attributes['type']?.toLowerCase() ?? '';
      if (inputType == 'button' || inputType == 'submit' || inputType == 'reset') {
        final rect = _getNodeRect(node);
        if (rect != null && rect.width > 0 && rect.height > 0) {
          final btnNode = SemanticsNode();
          final label = _ariaLabel(node) ??
              node.attributes['value'] ??
              inputType;
          btnNode.updateWith(
            config: SemanticsConfiguration()
              ..isButton = true
              ..textDirection = _textDirection
              ..label = label,
          );
          btnNode.rect = rect;
          semanticNodes.add(btnNode);
        }
        return;
      }
    }

    // Handle <ul> / <ol> — announce as list
    if (node.tagName == 'ul' || node.tagName == 'ol') {
      final rect = _getNodeRect(node);
      if (rect != null && rect.width > 0 && rect.height > 0) {
        final listNode = SemanticsNode();
        final label = _ariaLabel(node) ??
            (node.tagName == 'ol' ? 'Ordered list' : 'List');
        listNode.updateWith(
          config: SemanticsConfiguration()
            ..isHeader = false
            ..textDirection = _textDirection
            ..label = label
            ..hint = 'list',
        );
        listNode.rect = rect;
        semanticNodes.add(listNode);
      }
      // Still recurse so list items get their own semantics
      for (final child in node.children) {
        _buildSemanticNodes(child, semanticNodes, parentNode);
      }
      return;
    }

    // Handle <li> — announce with ordinal position
    if (node.tagName == 'li') {
      final rect = _getNodeRect(node);
      if (rect != null && rect.width > 0 && rect.height > 0) {
        final position = _listItemPosition(node);
        final liNode = SemanticsNode();
        final labelText = _ariaLabel(node) ?? node.textContent;
        final hint = position > 0 ? 'Item $position' : 'List item';
        liNode.updateWith(
          config: SemanticsConfiguration()
            ..isHeader = false
            ..textDirection = _textDirection
            ..label = labelText
            ..hint = hint,
        );
        liNode.rect = rect;
        semanticNodes.add(liNode);
      }
      return;
    }

    // Handle ARIA role attribute
    final role = node.attributes['role']?.toLowerCase();
    if (role != null) {
      switch (role) {
        case 'button':
          final rect = _getNodeRect(node);
          if (rect != null && rect.width > 0 && rect.height > 0) {
            final roleNode = SemanticsNode();
            final label = _ariaLabel(node) ?? node.textContent;
            roleNode.updateWith(
              config: SemanticsConfiguration()
                ..isButton = true
                ..textDirection = _textDirection
                ..label = label,
            );
            roleNode.rect = rect;
            semanticNodes.add(roleNode);
          }
          return;
        case 'region':
        case 'landmark':
          final rect = _getNodeRect(node);
          if (rect != null && rect.width > 0 && rect.height > 0) {
            final regionNode = SemanticsNode();
            final label = _ariaLabel(node) ?? 'Region';
            regionNode.updateWith(
              config: SemanticsConfiguration()
                ..isHeader = false
                ..textDirection = _textDirection
                ..label = label,
            );
            regionNode.rect = rect;
            semanticNodes.add(regionNode);
          }
          // Recurse into region children
          for (final child in node.children) {
            _buildSemanticNodes(child, semanticNodes, parentNode);
          }
          return;
        case 'heading':
          final rect = _getNodeRect(node);
          if (rect != null && rect.width > 0 && rect.height > 0) {
            final headingNode = SemanticsNode();
            final label = _ariaLabel(node) ?? node.textContent;
            headingNode.updateWith(
              config: SemanticsConfiguration()
                ..isHeader = true
                ..textDirection = _textDirection
                ..label = label,
            );
            headingNode.rect = rect;
            semanticNodes.add(headingNode);
          }
          return;
        default:
          break;
      }
    }

    // Paragraph and landmark block elements — emit one SemanticsNode per block
    // so screen readers (VoiceOver, TalkBack) can navigate paragraph-by-paragraph.
    // We cover: <p>, <blockquote>, <pre>, and landmark containers
    // (<section>, <article>, <main>, <header>, <footer>, <nav>, <aside>).
    //
    // Landmark containers recurse into children AFTER emitting their own node
    // (they act as named regions). Leaf content blocks (<p>, <blockquote>, <pre>)
    // are treated as terminal — their full text goes into the label.
    const leafBlocks = {'p', 'blockquote', 'pre'};
    const landmarkBlocks = {
      'section', 'article', 'main', 'header', 'footer', 'nav', 'aside'
    };
    final tag = node.tagName;
    if (tag != null && (leafBlocks.contains(tag) || landmarkBlocks.contains(tag))) {
      final rect = _getNodeRect(node);
      if (rect != null && rect.width > 0 && rect.height > 0) {
        final text = _ariaLabel(node) ?? node.textContent;
        if (text.trim().isNotEmpty) {
          final blockNode = SemanticsNode();
          final config = SemanticsConfiguration()
            ..isReadOnly = true
            ..textDirection = _textDirection
            ..label = text.trim();
          if (tag == 'blockquote') {
            config.hint = 'Block quote';
          } else if (tag == 'pre') {
            config.hint = 'Code block';
          } else if (landmarkBlocks.contains(tag)) {
            // Landmark — use aria-label or tag name as hint
            config.hint = _ariaLabel(node) != null ? '' : tag;
          }
          blockNode.updateWith(config: config);
          blockNode.rect = rect;
          semanticNodes.add(blockNode);
        }
        if (landmarkBlocks.contains(tag)) {
          // Landmarks contain navigable sub-structure — recurse.
          for (final child in node.children) {
            _buildSemanticNodes(child, semanticNodes, parentNode);
          }
        }
        return;
      }
    }

    // Generic: if aria-label / aria-labelledby is present, emit a labelled node
    final ariaLabel = _ariaLabel(node);
    if (ariaLabel != null && ariaLabel.isNotEmpty) {
      final rect = _getNodeRect(node);
      if (rect != null && rect.width > 0 && rect.height > 0) {
        final ariaNode = SemanticsNode();
        ariaNode.updateWith(
          config: SemanticsConfiguration()
            ..isHeader = false
            ..textDirection = _textDirection
            ..label = ariaLabel,
        );
        ariaNode.rect = rect;
        semanticNodes.add(ariaNode);
        return;
      }
    }

    // Recursively process children
    for (final child in node.children) {
      _buildSemanticNodes(child, semanticNodes, parentNode);
    }
  }

  /// Returns the `aria-label` value, or resolves `aria-labelledby` to the
  /// text content of the referenced element (best-effort, id lookup).
  String? _ariaLabel(UDTNode node) {
    final direct = node.attributes['aria-label'];
    if (direct != null && direct.isNotEmpty) return direct;
    // aria-labelledby: look up referenced id within the same document.
    final labelledBy = node.attributes['aria-labelledby'];
    if (labelledBy != null && labelledBy.isNotEmpty) {
      final referenced = _findNodeById(labelledBy);
      if (referenced != null) return referenced.textContent;
    }
    return null;
  }

  /// Finds a node by its `id` attribute, scanning the full document.
  UDTNode? _findNodeById(String id) {
    if (_document == null) return null;
    UDTNode? found;
    _document!.traverse((n) {
      if (found == null && n.attributes['id'] == id) {
        found = n;
      }
    });
    return found;
  }

  /// Returns the 1-based ordinal position of a `<li>` within its parent list.
  int _listItemPosition(UDTNode liNode) {
    final p = liNode.parent;
    if (p == null) return 0;
    int position = 0;
    for (final child in p.children) {
      if (child.tagName == 'li') {
        position++;
        if (child == liNode) return position;
      }
    }
    return 0;
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
