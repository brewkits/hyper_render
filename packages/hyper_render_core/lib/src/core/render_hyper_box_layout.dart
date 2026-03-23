part of 'render_hyper_box.dart';

// Layout spacing constants — single source of truth for all magic numbers
const double _kImageMargin = 32.0; // horizontal margin subtracted from maxWidth for images
const double _kDefaultFlexFallbackHeight = 50.0;
const double _kDefaultTableFallbackHeight = 200.0;
const double _kDefaultCodeBlockFallbackHeight = 100.0;
const double _kDefaultDetailsFallbackHeight = 40.0;
const double _kTableBottomMargin = 16.0;
const double _kCodeBlockBottomMargin = 8.0;
const double _kDetailsBottomMargin = 4.0;

extension _RenderHyperBoxLayout on RenderHyperBox {
  /// Step 1: Tokenization - Convert UDT tree to flat list of Fragments
  void _ensureFragments() {
    if (_fragments.isNotEmpty) return;
    if (_document == null) return;

    _fragments = [];
    _lastBlockMarginBottom = 0;
    _fragmentsVersion++; // signal that line layout must be redone
    // Reset list item counters so ordered-list numbering restarts from 1
    _listItemIndices.clear();
    _tokenizeNode(_document!, null);
  }

  void _tokenizeNode(UDTNode node, UDTNode? parentBlock) {
    switch (node.type) {
      case NodeType.document:
        for (final child in node.children) {
          _tokenizeNode(child, null);
        }
        break;

      case NodeType.block:
        _tokenizeBlock(node, parentBlock);
        break;

      case NodeType.inline:
        _tokenizeInline(node);
        break;

      case NodeType.text:
        _tokenizeText(node as TextNode);
        break;

      case NodeType.atomic:
        _tokenizeAtomic(node as AtomicNode);
        break;

      case NodeType.lineBreak:
        _fragments.add(Fragment.lineBreak(
          sourceNode: node,
          style: node.style,
        ));
        break;

      case NodeType.ruby:
        _tokenizeRuby(node as RubyNode);
        break;

      case NodeType.table:
        _tokenizeTable(node as TableNode);
        break;

      case NodeType.errorBoundary:
        // Rendered as a full-width child widget (ErrorBoundaryWidget),
        // same layout semantics as a flex container.
        _fragments.add(_FlexFragment(sourceNode: node, style: node.style));
        break;

      default:
        for (final child in node.children) {
          _tokenizeNode(child, parentBlock);
        }
    }
  }

  void _tokenizeBlock(UDTNode node, UDTNode? parentBlock) {
    final style = node.style;
    final tagName = node.tagName?.toLowerCase();

    // Handle margin collapsing.
    // When suppressFirstBlockMarginTop is set (virtualized section N>0), treat
    // the very first block's marginTop as 0 so it collapses cleanly against
    // the previous section's last marginBottom instead of double-stacking.
    final rawMarginTop = style.margin.top;
    final marginTop = (_suppressFirstBlockMarginTop && _fragments.isEmpty)
        ? 0.0
        : rawMarginTop;
    final collapsedMargin = math.max(marginTop, _lastBlockMarginBottom);
    final effectiveMarginTop = collapsedMargin - _lastBlockMarginBottom;

    // Flex containers are rendered as FlexContainerWidget child widgets.
    // The widget handles its own padding/border internally, so we only inject
    // margin spacing via a zero-padding _BlockStartFragment.
    if (style.display == DisplayType.flex) {
      if (effectiveMarginTop > 0 || _fragments.isNotEmpty) {
        _fragments.add(_BlockStartFragment(
          sourceNode: node,
          style: style,
          marginTop: effectiveMarginTop,
          paddingTop: 0, // FlexContainerWidget handles its own padding
          paddingLeft: 0,
          paddingRight: 0,
        ));
      }
      _fragments.add(_FlexFragment(
        sourceNode: node,
        style: style,
      ));
      _fragments.add(_BlockEndFragment(
        sourceNode: node,
        style: style,
        marginBottom: style.margin.bottom,
        paddingBottom: 0, // FlexContainerWidget handles its own padding
      ));
      _lastBlockMarginBottom = style.margin.bottom;
      return;
    }

    if (effectiveMarginTop > 0 || _fragments.isNotEmpty) {
      _fragments.add(_BlockStartFragment(
        sourceNode: node,
        style: style,
        marginTop: effectiveMarginTop,
        paddingTop: style.padding.top,
        paddingLeft: style.padding.left,
        paddingRight: style.padding.right,
        truncateWithEllipsis: style.textOverflow == TextOverflow.ellipsis,
      ));
    }

    // Add list marker for <li> elements
    if (tagName == 'li' && parentBlock != null) {
      final parentTag = parentBlock.tagName?.toLowerCase();
      final isOrdered = parentTag == 'ol';

      // Get or calculate list item index
      int index = 1;
      if (isOrdered) {
        // Count previous li siblings
        index = (_listItemIndices[parentBlock] ?? 0) + 1;
        _listItemIndices[parentBlock] = index;
      }

      // Create marker text
      final marker = isOrdered ? '$index. ' : '• ';

      _fragments.add(_ListMarkerFragment(
        sourceNode: node,
        style: style,
        marker: marker,
        isOrdered: isOrdered,
        index: index,
      ));
    }

    if (style.float != HyperFloat.none) {
      _fragments.add(_FloatFragment(
        sourceNode: node,
        style: style,
        floatDirection: style.float,
      ));
    }

    // Code blocks (<pre>) are rendered as child widgets with syntax highlighting
    // Create a placeholder fragment instead of tokenizing the content
    if (tagName == 'pre') {
      _fragments.add(_CodeBlockFragment(
        sourceNode: node,
        style: style,
      ));
      // Skip tokenizing children - they're handled by CodeBlockWidget
    } else if (tagName == 'details') {
      // Skip tokenizing children — HyperDetailsWidget renders them internally.
      // Tokenizing here would cause children to appear twice (inline + via widget).
      _fragments.add(_DetailsFragment(
        sourceNode: node,
        style: style,
      ));
    } else {
      for (final child in node.children) {
        _tokenizeNode(child, node);
      }
    }

    _fragments.add(_BlockEndFragment(
      sourceNode: node,
      style: style,
      marginBottom: style.margin.bottom,
      paddingBottom: style.padding.bottom,
    ));

    _lastBlockMarginBottom = style.margin.bottom;
  }

  void _tokenizeInline(UDTNode node) {
    // Add inline start marker for decoration tracking
    final hasDecoration = node.style.backgroundColor != null ||
        node.style.borderColor != null ||
        node.style.backgroundGradient != null ||
        node.style.boxShadow != null ||
        node.style.filter != null ||
        node.style.backdropFilter != null;

    if (hasDecoration) {
      _fragments.add(_InlineStartFragment(
        sourceNode: node,
        style: node.style,
      ));
    }

    for (final child in node.children) {
      _tokenizeNode(child, null);
    }

    if (hasDecoration) {
      _fragments.add(_InlineEndFragment(
        sourceNode: node,
        style: node.style,
      ));
    }
  }

  void _tokenizeText(TextNode node) {
    final text = node.text;
    if (text.isEmpty) return;

    final normalizedText = _normalizeWhitespace(text, node.style.whiteSpace);
    if (normalizedText.isEmpty) return;

    // SMART CHUNK MERGING STRATEGY:
    // Only merge SMALL fragments that don't contain spaces
    // This preserves word boundaries for proper line breaking
    // while still reducing fragmentation for things like "Hello" + "World" -> "HelloWorld"
    if (_fragments.isNotEmpty && !normalizedText.contains(' ')) {
      final lastFragment = _fragments.last;
      if (lastFragment.type == FragmentType.text &&
          lastFragment.text != null &&
          !lastFragment.text!.contains(' ') &&
          lastFragment.text!.length < 20 && // Don't merge long chunks
          normalizedText.length < 20 &&
          _canMergeStyles(lastFragment.style, node.style) &&
          lastFragment.sourceNode.parent == node.parent &&
          _sameLinkContext(lastFragment.sourceNode, node)) {
        // Compare parent nodes for merge context
        // Merge small non-space fragments
        final mergedText = lastFragment.text! + normalizedText;
        _fragments.removeLast();
        _fragments.add(Fragment.text(
          text: mergedText,
          sourceNode: lastFragment.sourceNode, // Keep original sourceNode
          style: lastFragment.style,
          characterOffset: lastFragment.characterOffset,
        ));
        return;
      }
    }

    _fragments.add(Fragment.text(
      text: normalizedText,
      sourceNode: node,
      style: node.style,
    ));
  }

  /// Check if two styles can be merged (same visual appearance)
  bool _canMergeStyles(ComputedStyle a, ComputedStyle b) {
    return a.fontSize == b.fontSize &&
        a.fontWeight == b.fontWeight &&
        a.fontStyle == b.fontStyle &&
        a.color == b.color &&
        a.fontFamily == b.fontFamily &&
        a.backgroundColor == b.backgroundColor &&
        a.textDecoration == b.textDecoration &&
        a.letterSpacing == b.letterSpacing &&
        a.wordBreak == b.wordBreak &&
        a.overflowWrap == b.overflowWrap;
  }

  /// Returns true when both nodes are in the same link context.
  /// Prevents merging a text node outside a link with one inside <a href="...">.
  bool _sameLinkContext(UDTNode a, UDTNode b) {
    return _findLinkAncestor(a) == _findLinkAncestor(b);
  }

  /// Walks up the ancestor chain to find the nearest <a> element, or null.
  UDTNode? _findLinkAncestor(UDTNode node) {
    UDTNode? current = node.parent;
    while (current != null) {
      if (current.tagName?.toLowerCase() == 'a') return current;
      current = current.parent;
    }
    return null;
  }

  String _normalizeWhitespace(String text, String? whiteSpace) {
    if (whiteSpace == 'pre' || whiteSpace == 'pre-wrap') {
      return text;
    }
    // Collapse multiple whitespace into single space
    // but preserve at least one space between words
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  void _tokenizeAtomic(AtomicNode node) {
    double width;
    double height;

    if (node.tagName == 'img' && node.src != null) {
      final cached = _imageCache[node.src];

      if (cached?.state == ImageLoadState.loaded && cached?.image != null) {
        // Image loaded - use actual dimensions
        final image = cached!.image!;
        final imageWidth = image.width.toDouble();
        final imageHeight = image.height.toDouble();

        // Clamp available width (leave a small margin so content doesn't touch edges).
        final maxW = _maxWidth > _kImageMargin ? _maxWidth - _kImageMargin : _maxWidth;
        // Prefer HTML attrs first, then CSS style dims (width:80px etc.).
        final dimW = node.intrinsicWidth ?? node.style.width;
        final dimH = node.intrinsicHeight ?? node.style.height;
        if (dimW != null && dimH != null) {
          // Both dimensions specified — scale down proportionally if wider than viewport.
          final scale = dimW > maxW ? maxW / dimW : 1.0;
          width = dimW * scale;
          height = dimH * scale;
        } else if (dimW != null) {
          // Only width specified — maintain aspect ratio from actual image.
          width = math.min(dimW, maxW);
          // Guard: avoid division by zero for degenerate images (width == 0).
          height = imageWidth > 0 ? width * (imageHeight / imageWidth) : 0;
        } else if (dimH != null) {
          // Only height specified - maintain aspect ratio
          height = dimH;
          // Guard: avoid division by zero for degenerate images (height == 0).
          width = imageHeight > 0 ? height * (imageWidth / imageHeight) : 0;
        } else {
          // No dimensions - use actual image size, constrained to maxWidth.
          // Guard: degenerate images with zero width produce no output.
          if (imageWidth > 0) {
            width = math.min(imageWidth, maxW);
            height = width * (imageHeight / imageWidth);
          } else {
            width = 0;
            height = 0;
          }
        }
      } else {
        // Image not loaded yet - use specified dimensions or smart placeholder
        final maxW = _maxWidth > _kImageMargin ? _maxWidth - _kImageMargin : _maxWidth;
        // Prefer HTML width/height attrs, then CSS style dims, then defaults.
        final dimW = node.intrinsicWidth ?? node.style.width;
        final dimH = node.intrinsicHeight ?? node.style.height;
        if (dimW != null && dimH != null) {
          final scale = dimW > maxW ? maxW / dimW : 1.0;
          width = dimW * scale;
          height = dimH * scale;
        } else if (dimW != null) {
          width = math.min(dimW, maxW);
          height = width / RenderHyperBox._defaultAspectRatio;
        } else if (dimH != null) {
          height = dimH;
          width = height * RenderHyperBox._defaultAspectRatio;
        } else {
          // No dimensions specified - use responsive placeholder
          // Width fills available space (with margin), height maintains 16:9 ratio
          width = math.min(_defaultImageWidth, maxW);
          height = width / RenderHyperBox._defaultAspectRatio;
        }
      }
    } else if (node.tagName == 'video') {
      // Video: clamp intrinsic width to available viewport width.
      final maxW = _maxWidth > 16 ? _maxWidth - 16 : _maxWidth;
      final intrinsicW = node.intrinsicWidth;
      final intrinsicH = node.intrinsicHeight;
      if (intrinsicW != null && intrinsicH != null) {
        final scale = intrinsicW > maxW ? maxW / intrinsicW : 1.0;
        width = intrinsicW * scale;
        height = intrinsicH * scale;
      } else if (intrinsicW != null) {
        width = math.min(intrinsicW, maxW);
        height = width / RenderHyperBox._defaultAspectRatio;
      } else {
        width = math.min(320.0, maxW);
        height = width / RenderHyperBox._defaultAspectRatio;
      }
    } else if (node.tagName == 'audio') {
      // Audio: compact horizontal bar — matches DefaultMediaWidget._buildAudioPlaceholder
      width = math.min(
          node.intrinsicWidth ?? 300.0,
          _maxWidth > 16 ? _maxWidth - 16 : _maxWidth);
      height = node.intrinsicHeight ?? 64.0;
    } else if (node.tagName == 'formula') {
      // Inline formula — estimate width from character count, fixed line height
      final formulaText = node.attributes['formula'] ?? node.src ?? '';
      width = node.intrinsicWidth ??
          (formulaText.length * 9.0).clamp(60.0, _maxWidth > 32 ? _maxWidth - 32 : _maxWidth);
      height = node.intrinsicHeight ?? 32.0;
    } else {
      // Generic atomic element
      width = node.intrinsicWidth ?? RenderHyperBox.defaultFloatSize;
      height = node.intrinsicHeight ?? RenderHyperBox.defaultFloatSize;
    }

    // Check if this atomic element should float
    if (node.style.float != HyperFloat.none) {
      // Create float fragment instead of regular atomic fragment
      _fragments.add(_FloatFragment(
        sourceNode: node,
        style: node.style,
        floatDirection: node.style.float,
      ));
    } else {
      // Regular non-floating atomic element
      _fragments.add(Fragment.atomic(
        sourceNode: node,
        style: node.style,
        size: Size(width, height),
      ));
    }
  }

  void _tokenizeRuby(RubyNode node) {
    _fragments.add(Fragment.ruby(
      baseText: node.baseText,
      rubyText: node.rubyText,
      sourceNode: node,
      style: node.style,
    ));
  }

  void _tokenizeTable(TableNode node) {
    _fragments.add(_TableFragment(
      sourceNode: node,
      style: node.style,
    ));
  }

  /// Step 2: Measure all fragments
  void _measureFragments() {
    for (final fragment in _fragments) {
      if (fragment.measuredSize != null) continue;

      switch (fragment.type) {
        case FragmentType.text:
          final text = fragment.text;
          if (text == null || text.isEmpty) {
            fragment.measuredSize = Size.zero;
            break;
          }
          final painter = _getTextPainter(text, fragment.style);
          fragment.measuredSize = Size(painter.width, painter.height);
          break;

        case FragmentType.ruby:
          _measureRubyFragment(fragment);
          break;

        case FragmentType.lineBreak:
          final painter = _getTextPainter(' ', fragment.style);
          fragment.measuredSize = Size(0, painter.height);
          break;

        case FragmentType.atomic:
          // Already measured during tokenization
          break;
      }

      if (fragment is _BlockStartFragment ||
          fragment is _BlockEndFragment ||
          fragment is _FloatFragment ||
          fragment is _FlexFragment ||
          fragment is _TableFragment ||
          fragment is _CodeBlockFragment ||
          fragment is _DetailsFragment ||
          fragment is _InlineStartFragment ||
          fragment is _InlineEndFragment) {
        fragment.measuredSize = Size.zero;
      }
    }
  }

  void _measureRubyFragment(Fragment fragment) {
    final baseStyle = fragment.style;
    // Ruby text is smaller than base text
    final rubyFontSize = baseStyle.fontSize * RenderHyperBox.rubyFontSizeRatio;
    final rubyStyle = baseStyle.copyWith(fontSize: rubyFontSize);

    final basePainter = _getTextPainter(fragment.text!, baseStyle);
    final rubyPainter = _getTextPainter(fragment.rubyText!, rubyStyle);

    // Width is the maximum of base and ruby text
    final width = math.max(basePainter.width, rubyPainter.width);
    // Height includes base text + gap + ruby text
    final height =
        basePainter.height + RenderHyperBox.rubyGap + rubyPainter.height;

    fragment.measuredSize = Size(width, height);
    // Store ruby height for painting
    fragment.rubyHeight = rubyPainter.height;
  }

  TextPainter _getTextPainter(String text, ComputedStyle style) {
    // Per-fragment text direction (supports RTL via CSS direction: rtl)
    final fragmentDirection =
        style.isRtl ? ui.TextDirection.rtl : textDirection;

    // Composite key using Object.hash to avoid XOR collision (a^b == b^a)
    final key = Object.hash(
      text,
      style.fontSize,
      style.fontWeight,
      style.fontStyle,
      style.color,
      style.fontFamily,
      style.lineHeight,
      style.letterSpacing,
      fragmentDirection,
    );

    final cached = _textPainters.get(key);
    if (cached != null) {
      return cached;
    }

    // FIXED: baseStyle is the foundation, computed style overrides it
    final mergedStyle = _baseStyle.merge(style.toTextStyle());

    // Pre/pre-wrap fragments may contain multi-line text; allow unlimited lines
    final isPreformatted =
        style.whiteSpace == 'pre' || style.whiteSpace == 'pre-wrap';
    final maxLines = isPreformatted ? null : 1;

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: mergedStyle,
      ),
      // forceStrutHeight: false — let each fragment's font metrics determine line
      // height naturally, same as how RichText / flutter_html behaves.
      // forceStrutHeight: true was causing all lines to be the same height even
      // when no explicit line-height was set, making text look mechanically spaced.
      strutStyle: StrutStyle.fromTextStyle(mergedStyle, forceStrutHeight: false),
      textDirection: fragmentDirection,
      maxLines: maxLines,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: true,
        applyHeightToLastDescent: true,
      ),
    )..layout();

    _textPainters.put(key, painter);
    return painter;
  }

  /// Step 3: Line Breaking with Float Support
  ///
  /// PERFORMANCE OPTIMIZATION: Uses queue-based processing instead of List.insert()
  /// to avoid O(n²) complexity when splitting text fragments. The pendingFragments
  /// queue holds fragments that need to be processed next, eliminating costly
  /// list insertions in the middle of the fragments list.
  void _performLineLayout({bool intrinsicMode = false}) {
    _lines.clear();
    _leftFloats.clear();
    _rightFloats.clear();

    if (_fragments.isEmpty) return;

    double currentY = 0;
    double currentX = 0;
    double lineHeight = 0;
    double maxBaseline = 0;
    List<Fragment> currentLineFragments = [];
    double leftInset = 0;
    double rightInset = 0;

    // Stack to track nested block indentation
    final List<double> leftPaddingStack = [0];
    final List<double> rightPaddingStack = [0];

    // Track active blocks for decoration (border-left, background)
    // Tuple: (fragment, startY, leftX, rightX)
    final List<(_BlockStartFragment, double, double, double)> activeBlocks = [];

    // Single-slot split buffer: when a fragment is split, the second part is
    // stored here instead of being List.insert()-ed (which is O(n)). The while
    // loops below drain it before advancing to the next fragment, so chains of
    // splits are handled correctly even though only one slot is used.
    Fragment? pendingFragment;

    // Ellipsis truncation state.
    // Incremented when entering a block with truncateWithEllipsis=true,
    // decremented on its matching _BlockEndFragment.
    int ellipsisDepth = 0;
    // After truncating a line with "…", skip all remaining text fragments
    // until we exit the ellipsis block.
    bool skipEllipsisContent = false;

    void finishLine() {
      if (currentLineFragments.isEmpty) return;

      while (currentLineFragments.isNotEmpty &&
          currentLineFragments.last.isWhitespace) {
        currentLineFragments.removeLast();
      }

      if (currentLineFragments.isEmpty) return;

      final lineInfo = LineInfo(
        top: currentY,
        baseline: maxBaseline,
        leftInset: leftInset,
        rightInset: rightInset,
      );
      for (final frag in currentLineFragments) {
        lineInfo.add(frag);
      }
      // BUG-F FIX: Guard against zero lineHeight. This happens when all
      // fragments on the line have measuredSize == null (e.g., zero-dimension
      // images) or a height of 0. A zero-height bounds rect causes the next
      // line to paint at the same Y, producing overlapping content.
      final safeLineHeight = lineHeight > 0 ? lineHeight : 1.0;
      // Set bounds after adding fragments
      lineInfo.bounds =
          Rect.fromLTWH(leftInset, currentY, lineInfo.width, safeLineHeight);
      _lines.add(lineInfo);

      currentY += safeLineHeight;
      currentLineFragments.clear();
      lineHeight = 0;
      maxBaseline = 0;
    }

    double getAvailableWidth() {
      assert(
        _leftFloats.length + _rightFloats.length <= 50,
        'HyperRender: ${_leftFloats.length + _rightFloats.length} active floats'
        ' — layout may be slow',
      );
      // Start with accumulated block padding
      double floatLeftInset = leftPaddingStack.last;
      double floatRightInset = rightPaddingStack.last;

      // Add float insets
      for (final float in _leftFloats) {
        if (currentY >= float.rect.top && currentY < float.rect.bottom) {
          floatLeftInset = math.max(floatLeftInset, float.rect.right);
        }
      }

      for (final float in _rightFloats) {
        if (currentY >= float.rect.top && currentY < float.rect.bottom) {
          floatRightInset =
              math.max(floatRightInset, _maxWidth - float.rect.left);
        }
      }

      leftInset = floatLeftInset;
      rightInset = floatRightInset;

      return _maxWidth - leftInset - rightInset;
    }

    /// Get the Y position needed to clear floats based on the clear property
    /// Returns the current Y if no clearing is needed
    double getClearPosition(HyperClear clear) {
      if (clear == HyperClear.none) return currentY;

      double clearY = currentY;

      // Clear left floats
      if (clear == HyperClear.left || clear == HyperClear.both) {
        for (final float in _leftFloats) {
          if (float.rect.bottom > clearY) {
            clearY = float.rect.bottom;
          }
        }
      }

      // Clear right floats
      if (clear == HyperClear.right || clear == HyperClear.both) {
        for (final float in _rightFloats) {
          if (float.rect.bottom > clearY) {
            clearY = float.rect.bottom;
          }
        }
      }

      return clearY;
    }

    // Process a single fragment - extracted for reuse with pending fragments
    void processFragment(Fragment fragment) {
      if (fragment is _BlockStartFragment) {
        finishLine();

        // Apply CSS clear property - move below floats if needed
        final clearY = getClearPosition(fragment.style.clear);
        if (clearY > currentY) {
          currentY = clearY;
        }

        currentY += fragment.marginTop + fragment.paddingTop;

        // ACCUMULATE padding for nested blocks
        final newLeftPadding = leftPaddingStack.last + fragment.paddingLeft;
        final newRightPadding = rightPaddingStack.last + fragment.paddingRight;
        leftPaddingStack.add(newLeftPadding);
        rightPaddingStack.add(newRightPadding);

        leftInset = newLeftPadding;
        rightInset = newRightPadding;
        currentX = leftInset;

        // Track this block for decoration (background, border-left, border-radius)
        final style = fragment.style;
        final hasBackground =
            style.backgroundColor != null || style.backgroundGradient != null;
        final hasBorderLeft =
            style.borderColor != null && style.borderWidth.left > 0;
        if (hasBackground || hasBorderLeft) {
          // Calculate the edge positions (account for parent padding but not this block's)
          final blockLeftX = leftPaddingStack.length > 1
              ? leftPaddingStack[leftPaddingStack.length - 2]
              : 0.0;
          final blockRightX = rightPaddingStack.length > 1
              ? _maxWidth - rightPaddingStack[rightPaddingStack.length - 2]
              : _maxWidth;
          // startY is BEFORE padding (current position includes padding, so subtract it)
          final blockStartY = currentY - fragment.paddingTop;
          activeBlocks.add((fragment, blockStartY, blockLeftX, blockRightX));
        }

        // Track ellipsis context
        if (fragment.truncateWithEllipsis) {
          ellipsisDepth++;
          skipEllipsisContent = false;
        }

        // ── Anchor & TOC tracking ─────────────────────────────────────────
        // Record the y-offset of any block that carries a CSS `id` attribute.
        final blockY = currentY - fragment.paddingTop - fragment.marginTop;
        final anchorId = fragment.sourceNode.cssId;
        if (anchorId != null && anchorId.isNotEmpty) {
          anchorOffsets[anchorId] = blockY;
        }
        // Heading anchor (h1–h6): record level + text for TOC generation.
        final tag = fragment.sourceNode.tagName;
        if (tag != null && tag.length == 2 && tag[0] == 'h') {
          final level = int.tryParse(tag[1]);
          if (level != null && level >= 1 && level <= 6) {
            final headingText = _extractNodeText(fragment.sourceNode);
            headingAnchors.add((
              level: level,
              text: headingText,
              cssId: anchorId,
              yOffset: blockY,
            ));
          }
        }

        return;
      }

      // Handle list markers - render them in the margin area
      if (fragment is _ListMarkerFragment) {
        final painter = _getTextPainter(fragment.marker, fragment.style);
        fragment.measuredSize = Size(painter.width, painter.height);
        // Position marker in the left margin (before the content)
        fragment.offset = Offset(leftInset - painter.width - 4, currentY);
        return;
      }

      if (fragment is _BlockEndFragment) {
        finishLine();
        currentY += fragment.paddingBottom;

        // Clear ellipsis context when leaving the truncation block
        if (fragment.style.textOverflow == TextOverflow.ellipsis &&
            ellipsisDepth > 0) {
          ellipsisDepth--;
          if (ellipsisDepth == 0) skipEllipsisContent = false;
        }

        // Check if this block has a decoration pending
        if (activeBlocks.isNotEmpty) {
          final (startFragment, startY, blockLeftX, blockRightX) =
              activeBlocks.last;
          if (startFragment.sourceNode == fragment.sourceNode) {
            activeBlocks.removeLast();
            // Create block decoration
            final style = fragment.style;
            // fullBorder = true when top/right/bottom sides also have width, meaning
            // this is a full-box border (CSS `border: X` shorthand) rather than
            // left-only (blockquote style).
            final fullBorder = style.borderWidth.top > 0 ||
                style.borderWidth.right > 0 ||
                style.borderWidth.bottom > 0;
            _blockDecorations.add(_BlockDecoration(
              node: fragment.sourceNode,
              rect: Rect.fromLTRB(blockLeftX, startY, blockRightX, currentY),
              backgroundColor: style.backgroundColor,
              backgroundGradient: style.backgroundGradient,
              borderLeftColor: style.borderColor,
              borderLeftWidth: style.borderWidth.left,
              borderRadius: style.borderRadius,
              boxShadow: style.boxShadow,
              fullBorder: fullBorder,
              borderStyle: style.borderStyle,
              filter: style.filter,
              backdropFilter: style.backdropFilter,
            ));
          }
        }

        // Pop the padding stack
        if (leftPaddingStack.length > 1) leftPaddingStack.removeLast();
        if (rightPaddingStack.length > 1) rightPaddingStack.removeLast();

        leftInset = leftPaddingStack.last;
        rightInset = rightPaddingStack.last;
        currentX = leftInset;
        return;
      }

      if (fragment is _FloatFragment) {
        _layoutFloat(fragment, currentY);
        return;
      }

      if (fragment is _FlexFragment) {
        finishLine();
        // The _BlockStartFragment for a flex container uses paddingLeft=0,
        // so leftInset here is the PARENT's inset (not the flex container's own padding).
        // The FlexContainerWidget handles its own padding internally.
        final double availWidth =
            math.max(0.0, _maxWidth - leftInset - rightInset);
        final RenderBox? flexChild = _findChildForFragment(fragment);
        double flexHeight = _kDefaultFlexFallbackHeight;

        if (flexChild != null) {
          if (intrinsicMode) {
            flexHeight = flexChild.getMaxIntrinsicHeight(availWidth);
          } else {
            flexChild.layout(
              BoxConstraints(minWidth: availWidth, maxWidth: availWidth),
              parentUsesSize: true,
            );
            flexHeight = flexChild.size.height;
          }
        }

        fragment.measuredSize = Size(availWidth, flexHeight);
        fragment.offset = Offset(leftInset, currentY);
        currentY += flexHeight;
        return;
      }

      if (fragment is _TableFragment) {
        finishLine();
        // Find the child RenderBox for this table and measure it
        RenderBox? tableChild = _findChildForFragment(fragment);
        double tableHeight = _kDefaultTableFallbackHeight;
        double tableWidth = _maxWidth;
        // Subtract the current block insets so the table does not overflow
        // when it is nested inside a padded block element.
        final tableMaxWidth =
            (_maxWidth - leftInset - rightInset).clamp(0.0, _maxWidth);

        if (tableChild != null) {
          if (intrinsicMode) {
            // During intrinsic measurement calling layout() + size is forbidden.
            // Use intrinsic APIs instead.
            tableHeight = tableChild.getMaxIntrinsicHeight(tableMaxWidth);
          } else {
            tableChild.layout(
              BoxConstraints(maxWidth: tableMaxWidth),
              parentUsesSize: true,
            );
            tableHeight = tableChild.size.height;
            tableWidth = tableChild.size.width;
          }
        }

        fragment.measuredSize = Size(tableWidth, tableHeight);
        fragment.offset = Offset(leftInset, currentY);
        currentY += tableHeight + _kTableBottomMargin;
        return;
      }

      // Handle code blocks - rendered as child widgets with syntax highlighting
      if (fragment is _CodeBlockFragment) {
        finishLine();
        // Find the child RenderBox for this code block
        RenderBox? codeBlockChild = _findChildForFragment(fragment);
        double blockHeight = _kDefaultCodeBlockFallbackHeight;
        double blockWidth = _maxWidth;

        if (codeBlockChild != null) {
          if (intrinsicMode) {
            blockHeight = codeBlockChild.getMaxIntrinsicHeight(_maxWidth);
          } else {
            codeBlockChild.layout(
              BoxConstraints(maxWidth: _maxWidth),
              parentUsesSize: true,
            );
            blockHeight = codeBlockChild.size.height;
            blockWidth = codeBlockChild.size.width;
          }
        }

        fragment.measuredSize = Size(blockWidth, blockHeight);
        fragment.offset = Offset(leftInset, currentY);
        currentY += blockHeight + _kCodeBlockBottomMargin;
        return;
      }

      // Handle <details>/<summary> - rendered as HyperDetailsWidget child
      if (fragment is _DetailsFragment) {
        finishLine();
        RenderBox? detailsChild = _findChildForFragment(fragment);
        double blockHeight = _kDefaultDetailsFallbackHeight;
        double blockWidth = _maxWidth;
        // Subtract the current block insets so the details widget does not
        // overflow when it is nested inside a padded block element.
        final detailsMaxWidth =
            (_maxWidth - leftInset - rightInset).clamp(0.0, _maxWidth);

        if (detailsChild != null) {
          if (intrinsicMode) {
            blockHeight = detailsChild.getMaxIntrinsicHeight(detailsMaxWidth);
          } else {
            detailsChild.layout(
              BoxConstraints(maxWidth: detailsMaxWidth),
              parentUsesSize: true,
            );
            blockHeight = detailsChild.size.height;
            blockWidth = detailsChild.size.width;
          }
        }

        fragment.measuredSize = Size(blockWidth, blockHeight);
        fragment.offset = Offset(leftInset, currentY);
        currentY += blockHeight + _kDetailsBottomMargin;
        return;
      }

      // Skip inline markers
      if (fragment is _InlineStartFragment || fragment is _InlineEndFragment) {
        return;
      }

      // Skip remaining content in an ellipsis block after truncation
      if (skipEllipsisContent) {
        if (fragment.type == FragmentType.lineBreak) {
          // A line break inside a nowrap/ellipsis block still resets position
          // but does not produce a new visual line.
          currentX = leftInset;
        }
        return;
      }

      if (fragment.type == FragmentType.lineBreak) {
        finishLine();
        currentX = leftInset;
        return;
      }

      final availableWidth = getAvailableWidth();
      // If floats were placed before any text on this line, currentX may still
      // be 0 (or behind the float boundary). Clamp it so remainingWidth is
      // computed from the actual start of the float-clear zone, not from 0.
      if (currentX < leftInset) currentX = leftInset;
      final remainingWidth = leftInset + availableWidth - currentX;

      // Ellipsis truncation: when inside a block with text-overflow:ellipsis
      // and the fragment overflows the line, clip and append "…" instead of
      // wrapping to the next line.
      if (ellipsisDepth > 0 &&
          fragment.type == FragmentType.text &&
          fragment.text != null &&
          fragment.width > remainingWidth) {
        const ellipsisChar = '\u2026'; // …
        final ellipsisPainter = _getTextPainter(ellipsisChar, fragment.style);
        final fitWidth = remainingWidth - ellipsisPainter.width;

        if (fitWidth > 0) {
          // Find how many characters fit before the ellipsis
          final painter = _getTextPainter(fragment.text!, fragment.style);
          final pos = painter.getPositionForOffset(Offset(fitWidth, 0));
          final cutAt = pos.offset.clamp(0, fragment.text!.length);
          if (cutAt > 0) {
            final clippedText = fragment.text!.substring(0, cutAt).trimRight();
            if (clippedText.isNotEmpty) {
              final truncFrag = Fragment.text(
                text: '$clippedText$ellipsisChar',
                sourceNode: fragment.sourceNode,
                style: fragment.style,
                characterOffset: fragment.characterOffset,
              );
              _measureFragment(truncFrag);
              truncFrag.offset = Offset(currentX, currentY);
              currentLineFragments.add(truncFrag);
              _updateLineMetrics(truncFrag, lineHeight, maxBaseline, (h, b) {
                lineHeight = h;
                maxBaseline = b;
              });
            }
          }
        } else if (currentLineFragments.isEmpty) {
          // Not even enough room for ellipsis alone — just show ellipsis
          final ellipsisFrag = Fragment.text(
            text: ellipsisChar,
            sourceNode: fragment.sourceNode,
            style: fragment.style,
            characterOffset: fragment.characterOffset,
          );
          _measureFragment(ellipsisFrag);
          ellipsisFrag.offset = Offset(currentX, currentY);
          currentLineFragments.add(ellipsisFrag);
          _updateLineMetrics(ellipsisFrag, lineHeight, maxBaseline, (h, b) {
            lineHeight = h;
            maxBaseline = b;
          });
        }

        finishLine();
        currentX = leftInset;
        skipEllipsisContent = true;
        return;
      }

      // Check if fragment fits in remaining space
      if (fragment.width > remainingWidth) {
        if (fragment.type == FragmentType.text && fragment.text != null) {
          // Try to split text fragment
          if (currentLineFragments.isNotEmpty && remainingWidth > 20) {
            // Try to fit part of text on current line
            final splitResult = _splitTextFragment(fragment, remainingWidth);
            if (splitResult != null) {
              final (firstPart, secondPart) = splitResult;
              currentLineFragments.add(firstPart);
              _updateLineMetrics(firstPart, lineHeight, maxBaseline, (h, b) {
                lineHeight = h;
                maxBaseline = b;
              });
              finishLine();
              currentX = leftInset;
              // PERFORMANCE: Queue secondPart instead of inserting into list
              pendingFragment = secondPart;
              return;
            }
          }

          // Can't split to fit - start new line
          if (currentLineFragments.isNotEmpty) {
            finishLine();
            currentX = leftInset;
          }

          // Now check if fragment is wider than full line width
          final fullLineWidth = getAvailableWidth();
          if (fragment.width > fullLineWidth && fragment.text!.length > 1) {
            // Fragment is wider than entire line - FORCE split
            final forceSplit = _forceSplitTextFragment(fragment, fullLineWidth);
            if (forceSplit != null) {
              final (firstPart, secondPart) = forceSplit;
              currentLineFragments.add(firstPart);
              _updateLineMetrics(firstPart, lineHeight, maxBaseline, (h, b) {
                lineHeight = h;
                maxBaseline = b;
              });
              finishLine();
              currentX = leftInset;
              // PERFORMANCE: Queue secondPart instead of inserting into list
              pendingFragment = secondPart;
              return;
            }
          }
        } else {
          // Non-text fragment - just start new line if needed
          if (currentLineFragments.isNotEmpty) {
            finishLine();
            getAvailableWidth();
            currentX = leftInset;
          }
        }
      }

      fragment.offset = Offset(currentX, currentY);
      currentX += fragment.width;
      currentLineFragments.add(fragment);

      _updateLineMetrics(fragment, lineHeight, maxBaseline, (h, b) {
        lineHeight = h;
        maxBaseline = b;
      });
    }

    // Main loop with pending fragment support
    for (int i = 0; i < _fragments.length; i++) {
      // Process pending fragment first (from previous split)
      while (pendingFragment != null) {
        final frag = pendingFragment!;
        pendingFragment = null;
        processFragment(frag);
      }

      processFragment(_fragments[i]);
    }

    // Process any remaining pending fragment
    while (pendingFragment != null) {
      final frag = pendingFragment!;
      pendingFragment = null;
      processFragment(frag);
    }

    finishLine();
  }

  /// Returns the distance from the top of [fragment] to its baseline.
  /// Single source of truth used by both [_updateLineMetrics] and [_positionFragments].
  double _fragmentBaseline(Fragment fragment) {
    if (fragment.type == FragmentType.text && fragment.text != null) {
      final painter = _getTextPainter(fragment.text!, fragment.style);
      return painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    } else if (fragment.type == FragmentType.ruby) {
      return fragment.height * 0.85;
    }
    return fragment.height; // atomic: bottom-align
  }

  void _updateLineMetrics(
    Fragment fragment,
    double currentHeight,
    double currentBaseline,
    void Function(double, double) update,
  ) {
    double newHeight = currentHeight;
    double newBaseline = currentBaseline;

    if (fragment.height > newHeight) {
      newHeight = fragment.height;
    }

    final baseline = _fragmentBaseline(fragment);
    if (baseline > newBaseline) {
      newBaseline = baseline;
    }

    update(newHeight, newBaseline);
  }

  /// Check if a break position is within a CJK context (surrounded by CJK characters)
  /// This helps properly handle mixed CJK+Latin text by applying appropriate rules
  bool _isBreakInCjkContext(String text, int position) {
    if (position <= 0 || position >= text.length) return false;

    // Check character before and after break position
    final charBefore = text[position - 1];
    final charAfter = text[position];

    // If either side is CJK, consider it CJK context
    final isBeforeCjk = KinsokuProcessor.isCjkCharacter(charBefore);
    final isAfterCjk = KinsokuProcessor.isCjkCharacter(charAfter);

    return isBeforeCjk || isAfterCjk;
  }

  (Fragment, Fragment)? _splitTextFragment(Fragment fragment, double maxWidth) {
    final text = fragment.text!;
    if (text.isEmpty) return null;

    final painter = _getTextPainter(text, fragment.style);
    final position = painter.getPositionForOffset(Offset(maxWidth, 0));
    int breakIndex = position.offset;

    if (breakIndex > 0 && breakIndex < text.length) {
      final style = fragment.style;
      final bool breakAll = style.wordBreak == 'break-all';
      final bool overflowWrap = style.overflowWrap == 'break-word' ||
          style.overflowWrap == 'anywhere';

      if (breakAll) {
        // word-break: break-all -> Break at any character
      } else {
        final beforeBreak = text.substring(0, breakIndex);
        final lastSpace = beforeBreak.lastIndexOf(' ');

        if (lastSpace > 0) {
          // Found a space before break point - use it
          breakIndex = lastSpace + 1;
        } else if (KinsokuProcessor.containsCjk(text)) {
          // Text contains CJK - check if break position is within CJK context
          final isCjkBreak = _isBreakInCjkContext(text, breakIndex);

          if (isCjkBreak) {
            // Break is in CJK region - apply Kinsoku rules
            breakIndex = KinsokuProcessor.findBreakPoint(text, breakIndex);
            if (breakIndex < 0) breakIndex = position.offset;
          } else if (overflowWrap) {
            // Latin-region break with overflow-wrap -> Break at character
          } else {
            // Break is in Latin region of mixed text - treat as Latin
            // Look for next space AFTER break point to avoid breaking words
            final afterBreak = text.substring(breakIndex);
            final nextSpace = afterBreak.indexOf(' ');

            if (nextSpace >= 0) {
              // Found space after - but this means moving more to next line
              return null;
            }
            // No space in Latin part - may need force split
            return null;
          }
        } else if (overflowWrap) {
          // Latin text with overflow-wrap: break-word -> Break at character if no space
        } else {
          // Pure Latin text without space before break point
          // Look for next space AFTER break point to avoid breaking words
          final afterBreak = text.substring(breakIndex);
          final nextSpace = afterBreak.indexOf(' ');

          if (nextSpace >= 0) {
            // Found space after - but this means moving more to next line
            // Return null to signal "can't fit any complete word on this line"
            // The caller should start a new line and try again
            return null;
          }
          // No space at all in text - this is a single long word
          // Return null, let caller decide (may force split if word > line width)
          return null;
        }
      }
    }

    if (breakIndex <= 0 || breakIndex >= text.length) {
      return null;
    }

    // Only trim spaces for normal/nowrap/pre-line modes
    // For pre/pre-wrap/break-spaces, preserve all whitespace
    final whiteSpace = fragment.style.whiteSpace;
    final shouldTrim = (whiteSpace != 'pre' &&
        whiteSpace != 'pre-wrap' &&
        whiteSpace != 'break-spaces');

    final firstPart = shouldTrim
        ? text.substring(0, breakIndex).trimRight()
        : text.substring(0, breakIndex);
    final secondRaw = text.substring(breakIndex);
    final secondPart = shouldTrim ? secondRaw.trimLeft() : secondRaw;

    if (firstPart.isEmpty || secondPart.isEmpty) {
      return null;
    }

    final firstFragment = Fragment.text(
      text: firstPart,
      sourceNode: fragment.sourceNode,
      style: fragment.style,
      characterOffset: fragment.characterOffset,
    );
    _measureFragment(firstFragment);

    // characterOffset points to the START of secondPart in the document.
    // We use `breakIndex` (not `breakIndex + trimmedLeading`) so that trimmed
    // leading spaces are still covered by this fragment's character range —
    // otherwise those space characters create a gap in the selection mapping.
    final secondFragment = Fragment.text(
      text: secondPart,
      sourceNode: fragment.sourceNode,
      style: fragment.style,
      characterOffset: fragment.characterOffset + breakIndex,
    );
    _measureFragment(secondFragment);

    return (firstFragment, secondFragment);
  }

  void _measureFragment(Fragment fragment) {
    if (fragment.type == FragmentType.text && fragment.text != null) {
      final painter = _getTextPainter(fragment.text!, fragment.style);
      fragment.measuredSize = Size(painter.width, painter.height);
    }
  }

  /// Force split text fragment when entire text is wider than the available line
  /// This tries to respect word boundaries for Latin text, only breaking mid-word
  /// when a single word is wider than the entire line width
  (Fragment, Fragment)? _forceSplitTextFragment(
      Fragment fragment, double maxWidth) {
    final text = fragment.text!;
    if (text.length <= 1) return null;

    // First, try to find a word boundary that fits
    int breakIndex = -1;

    // Find all space positions
    final spaceIndices = <int>[];
    for (int i = 0; i < text.length; i++) {
      if (text[i] == ' ') {
        spaceIndices.add(i);
      }
    }

    // Use the full-text painter + getPositionForOffset to find where maxWidth
    // cuts off the text, then snap back to the nearest space boundary.
    // This is O(1) painter calls instead of O(words) substring painters.
    if (spaceIndices.isNotEmpty) {
      final painter = _getTextPainter(text, fragment.style);
      final charPos = painter.getPositionForOffset(Offset(maxWidth, 0)).offset;
      // Find the rightmost space that is at or before the cut position
      int lo = 0, hi = spaceIndices.length - 1;
      while (lo <= hi) {
        final mid = (lo + hi) >> 1;
        if (spaceIndices[mid] < charPos) {
          breakIndex = spaceIndices[mid] + 1;
          lo = mid + 1;
        } else {
          hi = mid - 1;
        }
      }
    }

    // If no word boundary fits, but overflow-wrap is enabled, or word-break: break-all
    // then force split at character level
    final style = fragment.style;
    final bool breakAll = style.wordBreak == 'break-all';
    final bool overflowWrap =
        style.overflowWrap == 'break-word' || style.overflowWrap == 'anywhere';

    if (breakIndex == -1 &&
        (breakAll || overflowWrap || KinsokuProcessor.containsCjk(text))) {
      final painter = _getTextPainter(text, fragment.style);
      final position = painter.getPositionForOffset(Offset(maxWidth, 0));
      breakIndex = position.offset;

      // Adjust for CJK rules if applicable
      if (KinsokuProcessor.containsCjk(text)) {
        final kinsokuBreak = KinsokuProcessor.findBreakPoint(text, breakIndex);
        if (kinsokuBreak > 0) breakIndex = kinsokuBreak;
      }
    }

    // Fallback: no word boundary or CJK break was found. Split at the first
    // character to avoid dropping the fragment entirely. Single-char text
    // cannot be split further.
    if (breakIndex <= 0 || breakIndex >= text.length) {
      if (text.length > 1) {
        breakIndex = 1;
      } else {
        return null;
      }
    }

    final firstPart = text.substring(0, breakIndex);
    final secondPart = text.substring(breakIndex);

    final firstFragment = Fragment.text(
      text: firstPart,
      sourceNode: fragment.sourceNode,
      style: fragment.style,
      characterOffset: fragment.characterOffset,
    );
    _measureFragment(firstFragment);

    final secondFragment = Fragment.text(
      text: secondPart,
      sourceNode: fragment.sourceNode,
      style: fragment.style,
      characterOffset: fragment.characterOffset + breakIndex,
    );
    _measureFragment(secondFragment);

    return (firstFragment, secondFragment);
  }

  /// Recursively extracts plain text content from a [UDTNode] subtree.
  /// Used by heading-anchor collection to provide human-readable TOC labels.
  String _extractNodeText(UDTNode node) {
    if (node is TextNode) return node.text;
    final buf = StringBuffer();
    for (final child in node.children) {
      buf.write(_extractNodeText(child));
    }
    return buf.toString().trim();
  }

  void _layoutFloat(Fragment fragment, double currentY) {
    if (fragment is! _FloatFragment) return;
    // Can't position floats without a finite container width.
    if (_maxWidth.isInfinite || _maxWidth <= 0) return;

    // Compute margins FIRST so we can leave room when laying out the child.
    final margin = fragment.style.margin;
    const defaultFloatMargin = 8.0;
    final rightMargin = margin.right > 0 ? margin.right : defaultFloatMargin;
    final leftMargin = margin.left > 0 ? margin.left : defaultFloatMargin;
    final bottomMargin = margin.bottom > 0 ? margin.bottom : defaultFloatMargin;

    // Reserve horizontal margin space so totalWidth always fits in _maxWidth.
    final hMargin =
        fragment.floatDirection == HyperFloat.left ? rightMargin : leftMargin;
    final availableWidth = math.max(0.0, _maxWidth - hMargin);

    double width;
    double height;

    // For img floats, derive dimensions from _imageCache (same logic as _tokenizeAtomic).
    // This avoids a separate HyperImage child widget (which would cause duplicate HTTP
    // loads) and gives correct dimensions once the image has loaded.
    final sourceNode = fragment.sourceNode;
    if (sourceNode is AtomicNode &&
        sourceNode.tagName == 'img' &&
        sourceNode.src != null) {
      final cached = _imageCache[sourceNode.src];
      if (cached?.state == ImageLoadState.loaded && cached?.image != null) {
        final img = cached!.image!;
        final imgW = img.width.toDouble();
        final imgH = img.height.toDouble();
        // Prefer HTML attrs, then CSS style dims (width:180px etc.).
        final dimW = sourceNode.intrinsicWidth ?? sourceNode.style.width;
        final dimH = sourceNode.intrinsicHeight ?? sourceNode.style.height;
        if (dimW != null && dimH != null) {
          final scale = dimW > availableWidth ? availableWidth / dimW : 1.0;
          width = dimW * scale;
          height = dimH * scale;
        } else if (dimW != null) {
          width = math.min(dimW, availableWidth);
          height = imgW > 0
              ? width * (imgH / imgW)
              : RenderHyperBox.defaultFloatSize;
        } else if (dimH != null) {
          height = dimH;
          width = imgH > 0
              ? height * (imgW / imgH)
              : RenderHyperBox.defaultFloatSize;
        } else {
          // No explicit dimensions: constrain to CSS max-width or available space
          final cssMaxWidth = sourceNode.style.maxWidth;
          final naturalCap = cssMaxWidth ?? math.min(imgW, availableWidth);
          width = math.min(naturalCap, availableWidth);
          height = imgW > 0
              ? width * (imgH / imgW)
              : RenderHyperBox.defaultFloatSize;
        }
      } else {
        // Image not yet loaded — use CSS dimensions or a 16:9 placeholder
        width = math.min(
          sourceNode.intrinsicWidth ??
              sourceNode.style.width ??
              sourceNode.style.maxWidth ??
              _defaultImageWidth,
          availableWidth,
        );
        height = sourceNode.intrinsicHeight ??
            sourceNode.style.height ??
            (width / RenderHyperBox._defaultAspectRatio);
      }
    } else {
      // Non-image float: measure via intrinsic APIs to avoid a double layout
      // (this runs inside _performLineLayout; _layoutChildren will do the real layout).
      final child = _findChildForFragment(fragment);
      if (child != null && !availableWidth.isInfinite && availableWidth > 0) {
        width = math.min(
          child.getMaxIntrinsicWidth(availableWidth),
          availableWidth,
        );
        height = child.getMaxIntrinsicHeight(width);
      } else {
        width = math.min(
          fragment.style.width ?? RenderHyperBox.defaultFloatSize,
          availableWidth.isInfinite ? RenderHyperBox.defaultFloatSize : availableWidth,
        );
        height = fragment.style.height ?? RenderHyperBox.defaultFloatSize;
      }
    }

    Rect floatRect;
    double floatY = currentY;

    if (fragment.floatDirection == HyperFloat.left) {
      double left = 0;

      // Early exit: if the float is wider than the container it can never fit
      // horizontally regardless of Y position. Clamp to container width so the
      // loop below always terminates in O(1) for this degenerate case instead
      // of spending all 100 iterations advancing 1px at a time on an empty
      // float list (lowestBottom = floatY + 1 fallback).
      if (width + rightMargin > _maxWidth) {
        width = math.max(0.0, _maxWidth - rightMargin);
      }

      // Find available position - may need to move down if float doesn't fit
      // This handles multiple floats stacking correctly.
      // Convergence guarantee: each iteration advances floatY by at least the
      // height of one active float, so the loop terminates in at most
      // O(activeFloats) iterations — always well below maxIterations.
      bool foundPosition = false;
      int iterations = 0;
      const maxIterations = 100;

      while (!foundPosition && iterations < maxIterations) {
        left = 0;

        // Check existing left floats at current Y position
        for (final existing in _leftFloats) {
          if (floatY >= existing.rect.top && floatY < existing.rect.bottom) {
            left = math.max(left, existing.rect.right);
          }
        }

        // Check right floats to ensure there's enough space
        double rightEdge = _maxWidth;
        for (final existing in _rightFloats) {
          if (floatY >= existing.rect.top && floatY < existing.rect.bottom) {
            rightEdge = math.min(rightEdge, existing.rect.left);
          }
        }

        // Check if float fits in available space
        final totalWidth = width + rightMargin;
        if (left + totalWidth <= rightEdge) {
          foundPosition = true;
        } else {
          // Not enough space — advance floatY past the lowest active float.
          // Avoid the spread [..._leftFloats, ..._rightFloats] allocation
          // inside the loop by iterating both lists separately.
          double lowestBottom = floatY + 1;
          for (final existing in _leftFloats) {
            if (floatY >= existing.rect.top && floatY < existing.rect.bottom) {
              lowestBottom = math.max(lowestBottom, existing.rect.bottom);
            }
          }
          for (final existing in _rightFloats) {
            if (floatY >= existing.rect.top && floatY < existing.rect.bottom) {
              lowestBottom = math.max(lowestBottom, existing.rect.bottom);
            }
          }
          floatY = lowestBottom;
        }
        iterations++;
      }

      if (!foundPosition) {
        // BUG-D FIX: assert() is erased in release builds — the bad floatY
        // value was silently used, causing content overlap in production.
        // Fall back to currentY (place float at the current line position)
        // and always log so developers see it regardless of build mode.
        debugPrint('HyperRender: left float exceeded maxIterations — '
            'falling back to currentY. Reduce float density to avoid this.');
        floatY = currentY;
      }

      // Float rect includes margin on right and bottom for text spacing
      floatRect = Rect.fromLTWH(
        left,
        floatY,
        width + rightMargin,
        height + bottomMargin,
      );
      _leftFloats.add(_FloatArea(rect: floatRect, direction: HyperFloat.left));
    } else {
      double right = _maxWidth;

      // Early exit: clamp oversized right float to container width.
      if (width + leftMargin > _maxWidth) {
        width = math.max(0.0, _maxWidth - leftMargin);
      }

      // Find available position - may need to move down if float doesn't fit
      bool foundPosition = false;
      int iterations = 0;
      const maxIterations = 100;

      while (!foundPosition && iterations < maxIterations) {
        right = _maxWidth;

        // Check existing right floats at current Y position
        for (final existing in _rightFloats) {
          if (floatY >= existing.rect.top && floatY < existing.rect.bottom) {
            right = math.min(right, existing.rect.left);
          }
        }

        // Check left floats to ensure there's enough space
        double leftEdge = 0;
        for (final existing in _leftFloats) {
          if (floatY >= existing.rect.top && floatY < existing.rect.bottom) {
            leftEdge = math.max(leftEdge, existing.rect.right);
          }
        }

        // Check if float fits in available space
        final totalWidth = width + leftMargin;
        if (right - totalWidth >= leftEdge) {
          foundPosition = true;
        } else {
          // Not enough space — advance floatY without list spread allocation.
          double lowestBottom = floatY + 1;
          for (final existing in _leftFloats) {
            if (floatY >= existing.rect.top && floatY < existing.rect.bottom) {
              lowestBottom = math.max(lowestBottom, existing.rect.bottom);
            }
          }
          for (final existing in _rightFloats) {
            if (floatY >= existing.rect.top && floatY < existing.rect.bottom) {
              lowestBottom = math.max(lowestBottom, existing.rect.bottom);
            }
          }
          floatY = lowestBottom;
        }
        iterations++;
      }

      if (!foundPosition) {
        // BUG-D FIX (right float): same fix as left float above.
        debugPrint('HyperRender: right float exceeded maxIterations — '
            'falling back to currentY. Reduce float density to avoid this.');
        floatY = currentY;
      }

      // Float rect includes margin on left and bottom for text spacing
      floatRect = Rect.fromLTWH(
        right - width - leftMargin,
        floatY,
        width + leftMargin,
        height + bottomMargin,
      );
      _rightFloats
          .add(_FloatArea(rect: floatRect, direction: HyperFloat.right));
    }

    fragment.measuredSize = Size(width, height);
    // Child widget position is at top-left of float rect (excludes margin)
    if (fragment.floatDirection == HyperFloat.left) {
      fragment.offset = floatRect.topLeft;
    } else {
      // For right float, offset child by left margin to position image correctly
      fragment.offset = Offset(floatRect.left + leftMargin, floatRect.top);
    }
  }

  /// Step 4: Position fragments within lines (baseline alignment)
  /// Handles both LTR (left-to-right) and RTL (right-to-left) text directions
  void _positionFragments() {
    for (final line in _lines) {
      // For RTL, start from the right side and move left
      // For LTR, start from the left side and move right
      double x =
          isRTL ? (_maxWidth - line.rightInset - line.width) : line.leftInset;

      for (final fragment in line.fragments) {
        final fragmentBaseline = _fragmentBaseline(fragment);
        final yOffset = line.baseline - fragmentBaseline;
        fragment.offset = Offset(x, line.top + math.max(0, yOffset));
        x += fragment.width;
      }
    }
  }

  /// Step 5: Build inline decorations for background/border across line breaks
  void _buildInlineDecorations() {
    _inlineDecorations.clear();

    // Fast path: scan fragments once to find decorated inlines and their ranges.
    // endIdx is nullable: null means the closing _InlineEndFragment hasn't been
    // seen yet (open range); non-null means the range is complete.
    final decoratedRanges = <UDTNode,
        (ComputedStyle, int, int?)>{}; // node -> (style, startIdx, endIdx?)

    for (int i = 0; i < _fragments.length; i++) {
      final fragment = _fragments[i];
      if (fragment is _InlineStartFragment) {
        decoratedRanges[fragment.sourceNode] = (fragment.style, i, null);
      } else if (fragment is _InlineEndFragment) {
        final existing = decoratedRanges[fragment.sourceNode];
        if (existing != null) {
          decoratedRanges[fragment.sourceNode] = (existing.$1, existing.$2, i);
        }
      }
    }

    if (decoratedRanges.isEmpty) return;

    // Build a map from each fragment's source node to ALL decorated ancestor
    // nodes that cover it. Uses List to support nested decorations like
    // <span bg:red><span bg:blue>text</span></span>.
    final nodeToDecorated = <UDTNode, List<UDTNode>>{};
    for (final entry in decoratedRanges.entries) {
      final decoratedNode = entry.key;
      final (_, startIdx, endIdx) = entry.value;
      if (endIdx == null) continue;

      for (int i = startIdx; i <= endIdx; i++) {
        final sourceNode = _fragments[i].sourceNode;
        nodeToDecorated.putIfAbsent(sourceNode, () => []).add(decoratedNode);
      }
    }

    // Collect rects from lines efficiently
    final rectsMap = <UDTNode, List<Rect>>{};
    for (final node in decoratedRanges.keys) {
      rectsMap[node] = [];
    }

    for (final line in _lines) {
      for (final fragment in line.fragments) {
        final decoratedNodes = nodeToDecorated[fragment.sourceNode];
        if (decoratedNodes == null) continue;

        // Compute the visual rect for this fragment once, then apply it to
        // ALL decorated ancestors (supports nested inline decorations).
        Rect? visualRect;
        if (fragment.type == FragmentType.text && fragment.text != null) {
          // Trim leading/trailing whitespace for visual bounds.
          // HTML whitespace normalization inserts spaces at inline-element
          // boundaries; using the raw fragment rect would bleed the
          // decoration into those inter-element gaps.
          final text = fragment.text!;
          int start = 0;
          int end = text.length;
          while (start < end && text[start] == ' ') {
            start++;
          }
          while (end > start && text[end - 1] == ' ') {
            end--;
          }
          if (start < end) {
            final fragmentOffset = fragment.offset ?? Offset.zero;
            final painter = _getTextPainter(text, fragment.style);
            final boxes = painter.getBoxesForSelection(
              TextSelection(baseOffset: start, extentOffset: end),
              boxHeightStyle: ui.BoxHeightStyle.tight,
            );
            if (boxes.isNotEmpty) {
              final left = boxes.map((b) => b.left).reduce(math.min);
              final top = boxes.map((b) => b.top).reduce(math.min);
              final right = boxes.map((b) => b.right).reduce(math.max);
              final bottom = boxes.map((b) => b.bottom).reduce(math.max);
              visualRect = Rect.fromLTRB(
                fragmentOffset.dx + left,
                fragmentOffset.dy + top,
                fragmentOffset.dx + right,
                fragmentOffset.dy + bottom,
              );
            }
          }
        } else {
          // Non-text fragments (images, ruby, etc.) use the raw rect.
          visualRect = fragment.rect;
        }

        if (visualRect == null) continue;

        for (final decoratedNode in decoratedNodes) {
          final rangeEntry = decoratedRanges[decoratedNode];
          if (rangeEntry == null) continue;
          final (style, _, _) = rangeEntry;
          final padding = style.padding;
          final expandedRect = Rect.fromLTWH(
            visualRect.left - padding.left,
            visualRect.top - padding.top,
            visualRect.width + padding.left + padding.right,
            visualRect.height + padding.top + padding.bottom,
          );
          rectsMap[decoratedNode]?.add(expandedRect);
        }
      }
    }

    // Create decorations
    for (final entry in decoratedRanges.entries) {
      final node = entry.key;
      final (style, _, _) = entry.value;
      final rects = rectsMap[node] ?? [];
      if (rects.isNotEmpty) {
        _inlineDecorations.add(_InlineDecoration(
          node: node,
          rects: rects,
          backgroundColor: style.backgroundColor,
          backgroundGradient: style.backgroundGradient,
          borderColor: style.borderColor,
          borderWidth: style.borderWidth.top,
          borderRadius: style.borderRadius,
          boxShadow: style.boxShadow,
          filter: style.filter,
          backdropFilter: style.backdropFilter,
        ));
      }
    }
  }

  /// Step 6: Build character mapping for selection (optimized)
  void _buildCharacterMapping() {
    _characterToFragment.clear();
    _fragmentRanges.clear();
    _totalCharacterCount = 0;

    // Build ranges instead of individual character mapping
    for (final fragment in _fragments) {
      if (fragment.type == FragmentType.text && fragment.text != null) {
        final startIdx = _totalCharacterCount;
        final endIdx = startIdx + fragment.text!.length;
        _fragmentRanges.add((startIdx, endIdx, fragment));
        _totalCharacterCount = endIdx;
      }
    }
  }

  /// Step 7: Layout child RenderBoxes
  void _layoutChildren() {
    // First, link children to their corresponding fragments
    _linkFragmentsToChildrenByOrder();

    // Then layout each child
    RenderBox? child = firstChild;

    while (child != null) {
      final parentData = child.parentData as HyperBoxParentData;
      bool wasLaidOut = false;

      if (parentData.isFloat) {
        // Float children use floatRect from float layout
        final floatFragment = _findFloatFragmentForNode(parentData.sourceNode);
        if (floatFragment != null) {
          parentData.floatRect = Rect.fromLTWH(
            floatFragment.offset?.dx ?? 0,
            floatFragment.offset?.dy ?? 0,
            floatFragment.measuredSize?.width ?? 100,
            floatFragment.measuredSize?.height ?? 100,
          );
        }

        if (parentData.floatRect != null) {
          child.layout(
            BoxConstraints.tight(parentData.floatRect!.size),
            parentUsesSize: true,
          );
          parentData.offset = parentData.floatRect!.topLeft;
          wasLaidOut = true;
        }
      } else if (parentData.fragment != null) {
        final fragment = parentData.fragment!;
        // Always layout to ensure parent data is properly cleaned
        if (fragment is _DetailsFragment) {
          // Use the measured width (set during _performLineLayout) so the
          // details widget stays within its padded-block bounds.
          // Unconstrained height is kept so the expand/collapse animation
          // can change height without making this a relayout boundary.
          final detailsWidth =
              fragment.measuredSize?.width ?? _maxWidth;
          child.layout(BoxConstraints(maxWidth: detailsWidth),
              parentUsesSize: true);
        } else {
          child.layout(
            BoxConstraints.tight(fragment.measuredSize ?? Size.zero),
            parentUsesSize: true,
          );
        }
        if (parentData.offset != (fragment.offset ?? Offset.zero)) {
          parentData.offset = fragment.offset ?? Offset.zero;
          child.markNeedsSemanticsUpdate();
        }
        wasLaidOut = true;
      } else if (parentData.sourceNode != null) {
        // Fallback: try to find fragment by source node
        final fragment = _findFragmentForNode(parentData.sourceNode!);
        if (fragment != null) {
          parentData.fragment = fragment;
          if (fragment is _DetailsFragment) {
            final detailsWidth =
                fragment.measuredSize?.width ?? _maxWidth;
            child.layout(BoxConstraints(maxWidth: detailsWidth),
                parentUsesSize: true);
          } else {
            child.layout(
              BoxConstraints.tight(fragment.measuredSize ?? Size.zero),
              parentUsesSize: true,
            );
          }
          if (parentData.offset != (fragment.offset ?? Offset.zero)) {
            parentData.offset = fragment.offset ?? Offset.zero;
            child.markNeedsSemanticsUpdate();
          }
          wasLaidOut = true;
        }
      }

      // CRITICAL: Ensure every child is laid out, even orphaned ones
      // This prevents parent data from staying dirty and causing assertion errors
      if (!wasLaidOut) {
        child.layout(BoxConstraints.tight(Size.zero), parentUsesSize: false);
        parentData.offset = Offset.zero;
      }

      child = parentData.nextSibling;
    }

    // Build the O(1) fragment→child lookup map used by paint & _findChildForFragment.
    _buildFragmentChildMap();
  }

  /// Builds (or rebuilds) the [_fragmentChildMap] from current [parentData.fragment]
  /// assignments.
  ///
  /// Called:
  /// - In [performLayout] Step 1.5 immediately after [_linkFragmentsToChildrenByOrder],
  ///   so that [_findChildForFragment] has O(1) access during [_performLineLayout]
  ///   (Step 3) — without this early call every lookup fell through to the O(M)
  ///   linear scan while the map was still empty.
  /// - Again at the end of [_layoutChildren] (Step 7) to capture any
  ///   fragment–child re-assignments that happened during child layout.
  void _buildFragmentChildMap() {
    _fragmentChildMap.clear();
    RenderBox? child = firstChild;
    while (child != null) {
      final pd = child.parentData as HyperBoxParentData;
      if (pd.fragment != null) {
        _fragmentChildMap[pd.fragment!] = child;
      }
      child = pd.nextSibling;
    }
  }

  /// Link child RenderBoxes to their corresponding fragments using ORDER-BASED matching
  ///
  /// This is critical for atomic elements (images, tables) to render correctly.
  /// Since fragments and children are both created by traversing the UDT in the same order,
  /// we can match them by iterating through both lists simultaneously.
  /// Links fragments to their corresponding child RenderBoxes using sourceNode-based matching.
  void _linkFragmentsToChildrenByOrder() {
    // Step 1: Build a map of sourceNode -> Fragment for quick lookup.
    //
    // Only include fragments that correspond to CHILD RenderBoxes (images,
    // tables, code blocks, details widgets, floats, flex containers).
    //
    // _BlockStartFragment and _BlockEndFragment share the same sourceNode as
    // the widget fragments (_DetailsFragment, _TableFragment, etc.) but use
    // FragmentType.text.  Including them here would overwrite the correct
    // widget-fragment entry, causing the child to get linked to the wrong
    // fragment and therefore laid out at Size.zero / Offset.zero.
    final fragmentMap = <UDTNode, Fragment>{};
    for (final fragment in _fragments) {
      final isWidgetFragment = fragment is _TableFragment ||
          fragment is _CodeBlockFragment ||
          fragment is _DetailsFragment ||
          fragment is _FloatFragment ||
          fragment is _FlexFragment ||
          (fragment.type == FragmentType.atomic &&
              fragment is! _TableFragment &&
              fragment is! _CodeBlockFragment &&
              fragment is! _DetailsFragment &&
              fragment is! _FloatFragment &&
              fragment is! _FlexFragment);

      if (isWidgetFragment) {
        fragmentMap[fragment.sourceNode] = fragment;
      }
    }

    // Step 2: Link children to fragments using sourceNode matching (primary method)
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as HyperBoxParentData;
      Fragment? matchedFragment;

      if (parentData.sourceNode != null) {
        matchedFragment = fragmentMap[parentData.sourceNode];
      }

      if (matchedFragment != null) {
        parentData.fragment = matchedFragment;
        // Set float info if applicable
        if (matchedFragment is _FloatFragment) {
          parentData.isFloat = true;
          parentData.floatDirection = matchedFragment.floatDirection;
        }
      }
      // If not linked by sourceNode, it remains unlinked for now.

      child = parentData.nextSibling;
    }

    // Step 3: Fallback — link remaining unlinked children by order.
    // This handles cases where sourceNode is null or doesn't match.
    //
    // Build a Set of already-linked fragments in O(M) so the "is already
    // linked?" check below is O(1) instead of O(M) per fragment.
    // Without this Set, the previous implementation had an inner while-loop
    // per fragment, making the whole step O(fragments × children) = O(N×M).
    final alreadyLinked = <Fragment>{};
    {
      RenderBox? c = firstChild;
      while (c != null) {
        final pd = c.parentData as HyperBoxParentData;
        if (pd.fragment != null) alreadyLinked.add(pd.fragment!);
        c = pd.nextSibling;
      }
    }

    final unlinkedFragments = _fragments.where((f) {
      final isAtomicFragment = f.type == FragmentType.atomic;
      final isTableFragment = f is _TableFragment;
      final isCodeBlockFragment = f is _CodeBlockFragment;
      final isDetailsFragment = f is _DetailsFragment;
      final isFloatFragment = f is _FloatFragment;

      // Only consider fragments that map to child RenderBoxes.
      if (!(isAtomicFragment ||
          isTableFragment ||
          isCodeBlockFragment ||
          isDetailsFragment ||
          isFloatFragment)) {
        return false;
      }

      // O(1) check — uses the Set built above.
      return !alreadyLinked.contains(f);
    }).toList();

    int unlinkedFragmentIndex = 0;
    child = firstChild;
    while (child != null) {
      final parentData = child.parentData as HyperBoxParentData;

      // Skip children that are already linked by sourceNode (Step 2).
      if (parentData.fragment != null) {
        child = parentData.nextSibling;
        continue;
      }

      // Link remaining children using the order of unlinked fragments.
      // This is the critical fallback.
      if (unlinkedFragmentIndex < unlinkedFragments.length) {
        final fragment = unlinkedFragments[unlinkedFragmentIndex];
        parentData.fragment = fragment;

        // Set float info if applicable
        if (fragment is _FloatFragment) {
          parentData.isFloat = true;
          parentData.floatDirection = fragment.floatDirection;
        }
        unlinkedFragmentIndex++;
      } else {
        // No unlinked fragment available for this child — leave it unlinked.
        // _layoutChildren will fall through to the Size.zero fallback for any
        // child whose parentData.fragment is still null after this pass.
      }

      child = parentData.nextSibling;
    }
  }

  /// Find child RenderBox for a given fragment
  RenderBox? _findChildForFragment(Fragment fragment) {
    // Fast path: use the O(1) map built during _layoutChildren.
    final cached = _fragmentChildMap[fragment];
    if (cached != null) return cached;

    // Fallback linear scan (e.g. before first layout or after invalidation).
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as HyperBoxParentData;
      if (parentData.sourceNode == fragment.sourceNode) {
        return child;
      }
      child = parentData.nextSibling;
    }
    return null;
  }

  /// Find fragment that matches the given source node
  Fragment? _findFragmentForNode(UDTNode node) {
    for (final fragment in _fragments) {
      if (fragment.sourceNode == node) {
        return fragment;
      }
    }
    return null;
  }

  /// Find float fragment that matches the given source node
  Fragment? _findFloatFragmentForNode(UDTNode? node) {
    if (node == null) return null;
    for (final fragment in _fragments) {
      if (fragment is _FloatFragment && fragment.sourceNode == node) {
        return fragment;
      }
    }
    return null;
  }
}
