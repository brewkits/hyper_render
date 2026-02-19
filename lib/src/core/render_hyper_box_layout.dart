part of 'render_hyper_box.dart';

extension _RenderHyperBoxLayout on RenderHyperBox {
  /// Step 1: Tokenization - Convert UDT tree to flat list of Fragments
  void _ensureFragments() {
    if (_fragments.isNotEmpty) return;
    if (_document == null) return;

    _fragments = [];
    _lastBlockMarginBottom = 0;
    _fragmentsVersion++; // signal that line layout must be redone
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

      default:
        for (final child in node.children) {
          _tokenizeNode(child, parentBlock);
        }
    }
  }

  void _tokenizeBlock(UDTNode node, UDTNode? parentBlock) {
    final style = node.style;
    final tagName = node.tagName?.toLowerCase();

    // Handle margin collapsing
    final marginTop = style.margin.top;
    final collapsedMargin = math.max(marginTop, _lastBlockMarginBottom);
    final effectiveMarginTop = collapsedMargin - _lastBlockMarginBottom;

    if (effectiveMarginTop > 0 || _fragments.isNotEmpty) {
      _fragments.add(_BlockStartFragment(
        sourceNode: node,
        style: style,
        marginTop: effectiveMarginTop,
        paddingTop: style.padding.top,
        paddingLeft: style.padding.left,
        paddingRight: style.padding.right,
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
        node.style.borderColor != null;

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
          lastFragment.sourceNode.parent == node.parent) {
        // Merge small non-space fragments
        final mergedText = lastFragment.text! + normalizedText;
        _fragments.removeLast();
        _fragments.add(Fragment.text(
          text: mergedText,
          sourceNode: lastFragment.sourceNode,
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
        a.letterSpacing == b.letterSpacing;
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

        if (node.intrinsicWidth != null && node.intrinsicHeight != null) {
          // Both dimensions specified - use them
          width = node.intrinsicWidth!;
          height = node.intrinsicHeight!;
        } else if (node.intrinsicWidth != null) {
          // Only width specified - maintain aspect ratio
          width = node.intrinsicWidth!;
          height = width * (imageHeight / imageWidth);
        } else if (node.intrinsicHeight != null) {
          // Only height specified - maintain aspect ratio
          height = node.intrinsicHeight!;
          width = height * (imageWidth / imageHeight);
        } else {
          // No dimensions - use actual image size, constrained to maxWidth
          width = math.min(imageWidth, _maxWidth - 32); // Leave some margin
          height = width * (imageHeight / imageWidth);
        }
      } else {
        // Image not loaded yet - use specified dimensions or smart placeholder
        if (node.intrinsicWidth != null && node.intrinsicHeight != null) {
          width = node.intrinsicWidth!;
          height = node.intrinsicHeight!;
        } else if (node.intrinsicWidth != null) {
          width = node.intrinsicWidth!;
          height = width / RenderHyperBox._defaultAspectRatio;
        } else if (node.intrinsicHeight != null) {
          height = node.intrinsicHeight!;
          width = height * RenderHyperBox._defaultAspectRatio;
        } else {
          // No dimensions specified - use responsive placeholder
          // Width fills available space (with margin), height maintains 16:9 ratio
          width = math.min(RenderHyperBox._defaultImageWidth, _maxWidth - 32);
          height = width / RenderHyperBox._defaultAspectRatio;
        }
      }
    } else {
      // Non-image atomic element
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
          final painter = _getTextPainter(fragment.text!, fragment.style);
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
          fragment is _TableFragment ||
          fragment is _CodeBlockFragment ||
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
    final height = basePainter.height + RenderHyperBox.rubyGap + rubyPainter.height;

    fragment.measuredSize = Size(width, height);
    // Store ruby height for painting
    fragment.rubyHeight = rubyPainter.height;
  }

  TextPainter _getTextPainter(String text, ComputedStyle style) {
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
      _textDirection,
    );

    final cached = _textPainters.get(key);
    if (cached != null) {
      return cached;
    }

    // FIXED: baseStyle is the foundation, computed style overrides it
    final mergedStyle = _baseStyle.merge(style.toTextStyle());

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: mergedStyle,
      ),
      strutStyle: StrutStyle.fromTextStyle(mergedStyle, forceStrutHeight: true),
      textDirection: _textDirection,
      maxLines: 1,
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
  void _performLineLayout() {
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

    // PERFORMANCE: Queue for pending fragments from splits - avoids O(n²) List.insert()
    // When we split a fragment, the second part goes here instead of being inserted
    // into _fragments list. This is O(1) instead of O(n).
    Fragment? pendingFragment;

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
      // Set bounds after adding fragments
      lineInfo.bounds = Rect.fromLTWH(leftInset, currentY, lineInfo.width, lineHeight);
      _lines.add(lineInfo);

      currentY += lineHeight;
      currentLineFragments.clear();
      lineHeight = 0;
      maxBaseline = 0;
    }

    double getAvailableWidth() {
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
          floatRightInset = math.max(floatRightInset, _maxWidth - float.rect.left);
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
        final hasBackground = style.backgroundColor != null;
        final hasBorderLeft = style.borderColor != null && style.borderWidth.left > 0;
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

        // Check if this block has a decoration pending
        if (activeBlocks.isNotEmpty) {
          final (startFragment, startY, blockLeftX, blockRightX) = activeBlocks.last;
          if (startFragment.sourceNode == fragment.sourceNode) {
            activeBlocks.removeLast();
            // Create block decoration
            final style = fragment.style;
            _blockDecorations.add(_BlockDecoration(
              node: fragment.sourceNode,
              rect: Rect.fromLTRB(blockLeftX, startY, blockRightX, currentY),
              backgroundColor: style.backgroundColor,
              borderLeftColor: style.borderColor,
              borderLeftWidth: style.borderWidth.left,
              borderRadius: style.borderRadius,
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

      if (fragment is _TableFragment) {
        finishLine();
        // Find the child RenderBox for this table and measure it
        RenderBox? tableChild = _findChildForFragment(fragment);
        double tableHeight = 200.0; // Default fallback
        double tableWidth = _maxWidth;

        if (tableChild != null) {
          // Layout the table to get its actual size
          tableChild.layout(
            BoxConstraints(maxWidth: _maxWidth),
            parentUsesSize: true,
          );
          tableHeight = tableChild.size.height;
          tableWidth = tableChild.size.width;
        }

        fragment.measuredSize = Size(tableWidth, tableHeight);
        fragment.offset = Offset(leftInset, currentY);
        currentY += tableHeight + 16; // Add margin after table
        return;
      }

      // Handle code blocks - rendered as child widgets with syntax highlighting
      if (fragment is _CodeBlockFragment) {
        finishLine();
        // Find the child RenderBox for this code block
        RenderBox? codeBlockChild = _findChildForFragment(fragment);
        double blockHeight = 100.0; // Default fallback
        double blockWidth = _maxWidth;

        if (codeBlockChild != null) {
          // Layout the code block to get its actual size
          codeBlockChild.layout(
            BoxConstraints(maxWidth: _maxWidth),
            parentUsesSize: true,
          );
          blockHeight = codeBlockChild.size.height;
          blockWidth = codeBlockChild.size.width;
        }

        fragment.measuredSize = Size(blockWidth, blockHeight);
        fragment.offset = Offset(leftInset, currentY);
        currentY += blockHeight + 8; // Add small margin after code block
        return;
      }

      // Skip inline markers
      if (fragment is _InlineStartFragment ||
          fragment is _InlineEndFragment) {
        return;
      }

      if (fragment.type == FragmentType.lineBreak) {
        finishLine();
        currentX = leftInset;
        return;
      }

      final availableWidth = getAvailableWidth();
      final remainingWidth = leftInset + availableWidth - currentX;

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
            currentX = leftInset;
            getAvailableWidth();
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

    // Calculate baseline using font metrics when available
    double baseline;
    if (fragment.type == FragmentType.text && fragment.text != null) {
      final painter = _getTextPainter(fragment.text!, fragment.style);
      // Use actual font baseline from TextPainter metrics
      baseline = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    } else if (fragment.type == FragmentType.ruby) {
      // Ruby has base text at bottom, so baseline is near bottom
      baseline = fragment.height * 0.85;
    } else {
      // For atomic/other elements, use bottom alignment
      baseline = fragment.height;
    }

    if (baseline > newBaseline) {
      newBaseline = baseline;
    }

    update(newHeight, newBaseline);
  }

  (Fragment, Fragment)? _splitTextFragment(Fragment fragment, double maxWidth) {
    final text = fragment.text!;
    if (text.isEmpty) return null;

    final painter = _getTextPainter(text, fragment.style);
    final position = painter.getPositionForOffset(Offset(maxWidth, 0));
    int breakIndex = position.offset;

    if (breakIndex > 0 && breakIndex < text.length) {
      final beforeBreak = text.substring(0, breakIndex);
      final lastSpace = beforeBreak.lastIndexOf(' ');

      if (lastSpace > 0) {
        // Found a space before break point - use it
        breakIndex = lastSpace + 1;
      } else if (KinsokuProcessor.containsCjk(text)) {
        // CJK text - use kinsoku rules
        breakIndex = KinsokuProcessor.findBreakPoint(text, breakIndex);
        if (breakIndex < 0) breakIndex = position.offset;
      } else {
        // Latin text without space before break point
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

    if (breakIndex <= 0 || breakIndex >= text.length) {
      return null;
    }

    final firstPart = text.substring(0, breakIndex).trimRight();
    final secondPart = text.substring(breakIndex).trimLeft();

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
  (Fragment, Fragment)? _forceSplitTextFragment(Fragment fragment, double maxWidth) {
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

    // Try each word boundary from the end
    for (int i = spaceIndices.length - 1; i >= 0; i--) {
      final spaceIdx = spaceIndices[i];
      final testText = text.substring(0, spaceIdx + 1);
      final painter = _getTextPainter(testText, fragment.style);

      if (painter.width <= maxWidth) {
        breakIndex = spaceIdx + 1;
        break;
      }
    }

    // If we found a word boundary, use it
    if (breakIndex > 0 && breakIndex < text.length) {
      final firstPart = text.substring(0, breakIndex).trimRight();
      final secondPart = text.substring(breakIndex).trimLeft();

      if (firstPart.isNotEmpty && secondPart.isNotEmpty) {
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
    }

    // No word boundary fits - check if this is CJK text (OK to break mid-character)
    if (KinsokuProcessor.containsCjk(text)) {
      // Use binary search to find the best break point for CJK
      int low = 1;
      int high = text.length - 1;
      int bestBreak = 1;

      while (low <= high) {
        final mid = (low + high) ~/ 2;
        final testText = text.substring(0, mid);
        final painter = _getTextPainter(testText, fragment.style);

        if (painter.width <= maxWidth) {
          bestBreak = mid;
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      }

      if (bestBreak >= 1 && bestBreak < text.length) {
        final kinsokuBreak = KinsokuProcessor.findBreakPoint(text, bestBreak);
        final finalBreak = kinsokuBreak > 0 ? kinsokuBreak : bestBreak;

        final firstPart = text.substring(0, finalBreak);
        final secondPart = text.substring(finalBreak);

        if (firstPart.isNotEmpty && secondPart.isNotEmpty) {
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
            characterOffset: fragment.characterOffset + finalBreak,
          );
          _measureFragment(secondFragment);

          return (firstFragment, secondFragment);
        }
      }
    }

    // For Latin text with a single word wider than the line - allow overflow
    // Don't break mid-word, just return null and let the word overflow
    return null;
  }

  void _layoutFloat(Fragment fragment, double currentY) {
    if (fragment is! _FloatFragment) return;

    double width;
    double height;

    // Try to get size from the actual child widget (for images, etc.)
    final child = _findChildForFragment(fragment);
    if (child != null) {
      // Layout the child to get its actual size
      child.layout(BoxConstraints(maxWidth: _maxWidth), parentUsesSize: true);
      width = child.size.width;
      height = child.size.height;
    } else {
      // Fallback to CSS style or default size
      width = fragment.style.width ?? RenderHyperBox.defaultFloatSize;
      height = fragment.style.height ?? RenderHyperBox.defaultFloatSize;
    }

    // Get margin from CSS style for proper text spacing
    final margin = fragment.style.margin;

    // Apply default margin if none specified for better text spacing
    const defaultFloatMargin = 8.0;
    final rightMargin = margin.right > 0 ? margin.right : defaultFloatMargin;
    final leftMargin = margin.left > 0 ? margin.left : defaultFloatMargin;
    final bottomMargin = margin.bottom > 0 ? margin.bottom : defaultFloatMargin;

    Rect floatRect;
    double floatY = currentY;

    if (fragment.floatDirection == HyperFloat.left) {
      double left = 0;

      // Find available position - may need to move down if float doesn't fit
      // This handles multiple floats stacking correctly
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
          // Not enough space - move down below the lowest float at this Y
          double lowestBottom = floatY + 1;
          for (final existing in [..._leftFloats, ..._rightFloats]) {
            if (floatY >= existing.rect.top && floatY < existing.rect.bottom) {
              lowestBottom = math.max(lowestBottom, existing.rect.bottom);
            }
          }
          floatY = lowestBottom;
        }
        iterations++;
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
          // Not enough space - move down below the lowest float at this Y
          double lowestBottom = floatY + 1;
          for (final existing in [..._leftFloats, ..._rightFloats]) {
            if (floatY >= existing.rect.top && floatY < existing.rect.bottom) {
              lowestBottom = math.max(lowestBottom, existing.rect.bottom);
            }
          }
          floatY = lowestBottom;
        }
        iterations++;
      }

      // Float rect includes margin on left and bottom for text spacing
      floatRect = Rect.fromLTWH(
        right - width - leftMargin,
        floatY,
        width + leftMargin,
        height + bottomMargin,
      );
      _rightFloats.add(_FloatArea(rect: floatRect, direction: HyperFloat.right));
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
      double x = isRTL
          ? (_maxWidth - line.rightInset - line.width)
          : line.leftInset;

      for (final fragment in line.fragments) {
        double fragmentBaseline;

        // Calculate baseline for each fragment type
        if (fragment.type == FragmentType.text && fragment.text != null) {
          final painter = _getTextPainter(fragment.text!, fragment.style);
          fragmentBaseline = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
        } else if (fragment.type == FragmentType.ruby) {
          // Ruby text baseline is at the bottom of base text
          fragmentBaseline = fragment.height * 0.85;
        } else {
          // Atomic elements align to bottom
          fragmentBaseline = fragment.height;
        }

        final yOffset = line.baseline - fragmentBaseline;
        fragment.offset = Offset(x, line.top + math.max(0, yOffset));
        x += fragment.width;
      }
    }
  }

  /// Step 5: Build inline decorations for background/border across line breaks
  void _buildInlineDecorations() {
    _inlineDecorations.clear();

    // Fast path: scan fragments once to find decorated inlines and their ranges
    final decoratedRanges = <UDTNode, (ComputedStyle, int, int)>{}; // node -> (style, startIdx, endIdx)

    for (int i = 0; i < _fragments.length; i++) {
      final fragment = _fragments[i];
      if (fragment is _InlineStartFragment) {
        decoratedRanges[fragment.sourceNode] = (fragment.style, i, -1);
      } else if (fragment is _InlineEndFragment) {
        final existing = decoratedRanges[fragment.sourceNode];
        if (existing != null) {
          decoratedRanges[fragment.sourceNode] = (existing.$1, existing.$2, i);
        }
      }
    }

    if (decoratedRanges.isEmpty) return;

    // Build set of all source nodes within each decorated range
    final nodeToDecorated = <UDTNode, UDTNode>{};
    for (final entry in decoratedRanges.entries) {
      final decoratedNode = entry.key;
      final (_, startIdx, endIdx) = entry.value;
      if (endIdx < 0) continue;

      for (int i = startIdx; i <= endIdx; i++) {
        final sourceNode = _fragments[i].sourceNode;
        nodeToDecorated[sourceNode] = decoratedNode;
      }
    }

    // Collect rects from lines efficiently
    final rectsMap = <UDTNode, List<Rect>>{};
    for (final node in decoratedRanges.keys) {
      rectsMap[node] = [];
    }

    for (final line in _lines) {
      for (final fragment in line.fragments) {
        final decoratedNode = nodeToDecorated[fragment.sourceNode];
        if (decoratedNode != null) {
          final rect = fragment.rect;
          if (rect != null) {
            // Expand rect by padding from the decorated node's style
            final (style, _, _) = decoratedRanges[decoratedNode]!;
            final padding = style.padding;

            final expandedRect = Rect.fromLTWH(
              rect.left - padding.left,
              rect.top - padding.top,
              rect.width + padding.left + padding.right,
              rect.height + padding.top + padding.bottom,
            );

            rectsMap[decoratedNode]!.add(expandedRect);
          }
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
          borderColor: style.borderColor,
          borderWidth: style.borderWidth.top,
          borderRadius: style.borderRadius,
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
    _linkChildrenToFragments();

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
        child.layout(
          BoxConstraints.tight(fragment.measuredSize ?? Size.zero),
          parentUsesSize: true,
        );
        parentData.offset = fragment.offset ?? Offset.zero;
        wasLaidOut = true;
      } else if (parentData.sourceNode != null) {
        // Fallback: try to find fragment by source node
        final fragment = _findFragmentForNode(parentData.sourceNode!);
        if (fragment != null) {
          parentData.fragment = fragment;
          child.layout(
            BoxConstraints.tight(fragment.measuredSize ?? Size.zero),
            parentUsesSize: true,
          );
          parentData.offset = fragment.offset ?? Offset.zero;
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
  }

  /// Link child RenderBoxes to their corresponding fragments using ORDER-BASED matching
  ///
  /// This is critical for atomic elements (images, tables) to render correctly.
  /// Since fragments and children are both created by traversing the UDT in the same order,
  /// we can match them by iterating through both lists simultaneously.
  /// Links fragments to their corresponding child RenderBoxes using sourceNode-based matching.
  ///
  /// This is more robust than order-based matching because it uses the unique sourceNode
  /// reference to identify the correct fragment-child pair, preventing misalignment issues
  /// when the widget tree and fragment list update asynchronously.
  void _linkFragmentsToChildrenByOrder() {
    // Step 1: Build a map of sourceNode -> Fragment for quick lookup
    final fragmentMap = <UDTNode, Fragment>{};
    for (final fragment in _fragments) {
      final isAtomicFragment = fragment.type == FragmentType.atomic;
      final isTableFragment = fragment is _TableFragment;
      final isCodeBlockFragment = fragment is _CodeBlockFragment;
      final isFloatFragment = fragment is _FloatFragment;

      if (isAtomicFragment || isTableFragment || isCodeBlockFragment || isFloatFragment) {
        fragmentMap[fragment.sourceNode] = fragment;
      }
    }

    // Step 2: Link children to fragments using sourceNode matching (primary method)
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as HyperBoxParentData;

      if (parentData.sourceNode != null) {
        final matchedFragment = fragmentMap[parentData.sourceNode];
        if (matchedFragment != null) {
          parentData.fragment = matchedFragment;

          // Set float info if applicable
          if (matchedFragment is _FloatFragment) {
            parentData.isFloat = true;
            parentData.floatDirection = matchedFragment.floatDirection;
          }
        }
      }

      child = parentData.nextSibling;
    }

    // Step 3: Fallback - link remaining unlinked children by order
    // This handles cases where sourceNode is null (rare, but possible)
    child = firstChild;
    final unlinkedFragments = _fragments.where((f) {
      final isAtomicFragment = f.type == FragmentType.atomic;
      final isTableFragment = f is _TableFragment;
      final isCodeBlockFragment = f is _CodeBlockFragment;
      final isFloatFragment = f is _FloatFragment;

      if (!(isAtomicFragment || isTableFragment || isCodeBlockFragment || isFloatFragment)) {
        return false;
      }

      // Check if this fragment is already linked to a child
      RenderBox? c = firstChild;
      while (c != null) {
        final pd = c.parentData as HyperBoxParentData;
        if (pd.fragment == f) return false;
        c = pd.nextSibling;
      }
      return true;
    }).iterator;

    while (child != null) {
      final parentData = child.parentData as HyperBoxParentData;

      // Skip children that are already linked
      if (parentData.fragment != null) {
        child = parentData.nextSibling;
        continue;
      }

      // Try to get next unlinked fragment
      if (unlinkedFragments.moveNext()) {
        final fragment = unlinkedFragments.current;
        parentData.fragment = fragment;

        if (fragment is _FloatFragment) {
          parentData.isFloat = true;
          parentData.floatDirection = fragment.floatDirection;
        }
      }

      child = parentData.nextSibling;
    }
  }

  /// Legacy method - kept for fallback compatibility
  void _linkChildrenToFragments() {
    RenderBox? child = firstChild;

    while (child != null) {
      final parentData = child.parentData as HyperBoxParentData;

      // Skip if already linked by order-based method
      if (parentData.fragment != null) {
        child = parentData.nextSibling;
        continue;
      }

      if (parentData.sourceNode != null && !parentData.isFloat) {
        // Find the fragment that matches this source node
        parentData.fragment = _findFragmentForNode(parentData.sourceNode!);
      }

      child = parentData.nextSibling;
    }
  }

  /// Find child RenderBox for a given fragment
  RenderBox? _findChildForFragment(Fragment fragment) {
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
