part of 'render_hyper_box.dart';

// Layout spacing constants — single source of truth for all magic numbers
const double _kDefaultInlinePluginWidth = 50.0;
const double _kDefaultInlinePluginHeight = 24.0;
const double _kDefaultFloatMargin = 8.0;

const double _kMinFloatYStep = 1.0;
const double _kImageMargin =
    0.0; // horizontal margin subtracted from maxWidth for images
const double _kDefaultFlexFallbackHeight = 50.0;
const double _kDefaultTableFallbackHeight = 200.0;
const double _kTableBottomMargin = 16.0;
const double _kCodeBlockBottomMargin = 8.0;
const double _kDetailsBottomMargin = 4.0;

/// Fallback width used when the widget is given an unbounded horizontal
/// constraint (e.g. an unwrapped Row child, horizontal SingleChildScrollView).
/// Flutter's BoxConstraints forbids passing `double.infinity` as minWidth, so
/// child render objects like _FlexFragment would crash without this clamp.
const double _kUnboundedWidthFallback = 800.0;

extension _RenderHyperBoxLayout on RenderHyperBox {
  /// Step 1: Tokenization - Convert UDT tree to flat list of Fragments
  void _ensureFragments() {
    if (_fragments.isNotEmpty) return;
    if (_document == null) return;

    _fragments = [];
    _relativeWidgetBoxes.clear();
    _hasRelative = _scanForRelative(_document!);
    _lastBlockMarginBottom = 0;
    _fragmentsVersion++; // signal that line layout must be redone
    // Reset list item counters so ordered-list numbering restarts from 1
    _listItemIndices.clear();
    _tokenizeNode(_document!, null);

    // Assign global offsets
    int offset = 0;
    for (final f in _fragments) {
      f.globalOffset = offset;
      if ((f.type == FragmentType.text || f.type == FragmentType.ruby) &&
          f.text != null) {
        offset += f.text!.length;
      } else if (f.type == FragmentType.lineBreak) {
        offset += 1;
      }
    }
    _totalCharacterCount = offset;
  }

  void _tokenizeNode(UDTNode node, UDTNode? parentBlock) {
    // CSS `display: none` removes the element AND its subtree from the box
    // tree entirely — it must not be measured, laid out, painted, selectable
    // or exposed to accessibility. Guarding here (the single entry point for
    // every node type) covers block/inline/text/atomic/line-break uniformly
    // and stops recursion into hidden children.
    //
    // Without this the canvas path rendered hidden content: common HTML like
    // email pre-headers, conditional CMS blocks and tracking wrappers use
    // `display: none`, so the text became visible and selectable.
    if (node.style.display == DisplayType.none) return;

    switch (node.type) {
      case NodeType.document:
        for (final child in node.children) {
          _tokenizeNode(child, null);
        }
        break;
      case NodeType.block:
        _handleBlockNode(node, parentBlock);
        break;
      case NodeType.inline:
        _handleInlineNode(node);
        break;
      case NodeType.text:
        _tokenizeText(node as TextNode);
        break;
      case NodeType.atomic:
        _tokenizeAtomic(node as AtomicNode);
        break;
      case NodeType.lineBreak:
        _fragments.add(Fragment.lineBreak(sourceNode: node, style: node.style));
        break;
      case NodeType.ruby:
        _tokenizeRuby(node as RubyNode);
        break;
      case NodeType.table:
        _tokenizeTable(node as TableNode);
        break;
      case NodeType.errorBoundary:
        _fragments.add(_FlexFragment(sourceNode: node, style: node.style));
        break;
      default:
        for (final child in node.children) {
          _tokenizeNode(child, parentBlock);
        }
    }
  }

  void _handleBlockNode(UDTNode node, UDTNode? parentBlock) {
    if (_blockPluginTags.isNotEmpty &&
        _blockPluginTags.contains(node.tagName?.toLowerCase())) {
      _tokenizeBlockPlugin(node);
    } else {
      _tokenizeBlock(node, parentBlock);
    }
  }

  void _handleInlineNode(UDTNode node) {
    // A custom tag (`<info-box>`, `<x-badge>`) has no UA display style, so the
    // adapters build it as an InlineNode even when its plugin is block-tier.
    // Routing it through the inline path never emits a fragment for the plugin
    // widget: the widget was built but never linked, laid out at 0x0 and never
    // painted. A registered block tag is a block whatever its node type.
    if (_blockPluginTags.isNotEmpty &&
        _blockPluginTags.contains(node.tagName?.toLowerCase())) {
      _tokenizeBlockPlugin(node);
      return;
    }
    if (_inlinePluginTags.isNotEmpty &&
        _inlinePluginTags.contains(node.tagName?.toLowerCase())) {
      _fragments.add(Fragment.atomic(
        sourceNode: node,
        style: node.style,
        size: Size(
          node.style.width ?? _kDefaultInlinePluginWidth,
          node.style.height ?? _kDefaultInlinePluginHeight,
        ),
      ));
    } else {
      _tokenizeInline(node);
    }
  }

  /// Emit fragments for a block-plugin node (full-width child widget).
  ///
  /// Mirrors the margin/padding handling of flex-container blocks so CSS
  /// spacing is preserved even though the node's children are not recursed.
  void _tokenizeBlockPlugin(UDTNode node) {
    final style = node.style;
    final rawMarginTop = style.margin.top;
    final marginTop = (_suppressFirstBlockMarginTop && _fragments.isEmpty)
        ? 0.0
        : rawMarginTop;
    final collapsedMargin = math.max(marginTop, _lastBlockMarginBottom);
    final effectiveMarginTop = collapsedMargin - _lastBlockMarginBottom;

    if (effectiveMarginTop > 0 || _fragments.isNotEmpty) {
      _fragments.add(_BlockStartFragment(
        sourceNode: node,
        style: style,
        marginTop: effectiveMarginTop,
        paddingTop: 0,
        paddingLeft: 0,
        paddingRight: 0,
      ));
    }
    _fragments.add(_FlexFragment(sourceNode: node, style: style));
    _fragments.add(_BlockEndFragment(
      sourceNode: node,
      style: style,
      marginBottom: style.margin.bottom,
      paddingBottom: 0,
    ));
    _lastBlockMarginBottom = style.margin.bottom;
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

    // Flex containers and Grid containers are rendered as child widgets.
    // The widget handles its own padding/border internally, so we only inject
    // margin spacing via a zero-padding _BlockStartFragment.
    if (style.display == DisplayType.flex ||
        style.display == DisplayType.grid) {
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

    // A block-start fragment is normally elided for the very first block when
    // it has no top margin (nothing to space). But the block-start fragment is
    // also what carries this block's padding and any width constraint onto the
    // line-breaker's padding stack — so it must still be emitted when the block
    // has non-zero padding or a width constraint, even as the first block.
    // (A first `<p>` was unaffected only because it has a default top margin;
    // a first `<div style="padding:…">` silently lost its padding.)
    final hasWidthConstraint = style.width != null ||
        style.widthPercent != null ||
        style.maxWidth != null ||
        style.maxWidthPercent != null ||
        style.minWidth != null ||
        style.minWidthPercent != null;
    final hasPadding = style.padding != EdgeInsets.zero;
    // The block-start fragment also carries the decoration, so a first block
    // styled only with a background or border must keep it too. Mirrors the
    // `hasBackground || hasBorderLeft` test in _performLineLayout.
    final hasDecoration = style.backgroundColor != null ||
        style.backgroundGradient != null ||
        (style.borderColor != null && style.borderWidth.left > 0);
    if (effectiveMarginTop > 0 ||
        _fragments.isNotEmpty ||
        hasWidthConstraint ||
        hasPadding ||
        hasDecoration ||
        style.margin.left != 0 ||
        style.margin.right != 0 ||
        style.textOverflow == TextOverflow.ellipsis) {
      _fragments.add(_BlockStartFragment(
        sourceNode: node,
        style: style,
        marginTop: effectiveMarginTop,
        paddingTop: style.padding.top,
        paddingLeft: style.padding.left,
        paddingRight: style.padding.right,
        truncateWithEllipsis: style.textOverflow == TextOverflow.ellipsis,
        appliesHorizontalMargins: style.float == HyperFloat.none,
      ));
    }

    // Add list marker for <li> elements
    if (tagName == 'li' && parentBlock != null) {
      final parentTag = parentBlock.tagName?.toLowerCase();
      final isOrdered = parentTag == 'ol';

      // Resolve effective list-style-type: li overrides parent, then parent,
      // then default (disc for ul, decimal for ol).
      final effectiveType = style.listStyleType ??
          parentBlock.style.listStyleType ??
          (isOrdered ? 'decimal' : 'disc');

      // list-style-type: none → suppress marker entirely.
      if (effectiveType != 'none') {
        int index = 1;
        if (isOrdered) {
          final existing = _listItemIndices[parentBlock];
          if (existing == null) {
            // First <li> of this <ol>: honour the `start` attribute
            // (`<ol start="5">` → 5, 6, 7…). A malformed/absent value
            // defaults to 1, matching the HTML spec.
            index = int.tryParse(parentBlock.attributes['start'] ?? '') ?? 1;
          } else {
            index = existing + 1;
          }
          _listItemIndices[parentBlock] = index;
        }

        final marker = _buildListMarker(effectiveType, isOrdered, index);

        _fragments.add(_ListMarkerFragment(
          sourceNode: node,
          style: style,
          marker: marker,
          isOrdered: isOrdered,
          index: index,
        ));
      }
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
      _hasDetailFragments = true;
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
    return text.replaceAll(_kWhitespaceSplitter, ' ');
  }

  void _tokenizeAtomic(AtomicNode node) {
    double width;
    double height;

    if (node.tagName == 'img' && node.src != null) {
      final cached = _imageCache.get(node.src!);

      if (cached?.state == ImageLoadState.loaded && cached?.image != null) {
        // Image loaded - use actual dimensions
        final image = cached!.image!;
        final imageWidth = image.width.toDouble();
        final imageHeight = image.height.toDouble();

        // Clamp available width (leave a small margin so content doesn't touch edges).
        final maxW =
            _maxWidth > _kImageMargin ? _maxWidth - _kImageMargin : _maxWidth;
        // CSS style takes priority over HTML attrs (customCss/inline style wins).
        final dimW = node.style.width ?? node.intrinsicWidth;
        final dimH = node.style.height ?? node.intrinsicHeight;
        if (dimW != null && dimH != null) {
          // Both dimensions specified — scale down proportionally if wider than viewport.
          final scale = (dimW > maxW && dimW > 0) ? maxW / dimW : 1.0;
          width = dimW * scale;
          height = dimH * scale;
        } else if (dimW != null) {
          width = math.min(dimW, maxW);
          final ar = node.style.aspectRatio;
          if (ar != null && ar > 0) {
            height = width / ar;
          } else {
            height = imageWidth > 0 ? width * (imageHeight / imageWidth) : 0;
          }
        } else if (dimH != null) {
          height = dimH;
          final ar = node.style.aspectRatio;
          if (ar != null && ar > 0) {
            width = height * ar;
          } else {
            width = imageHeight > 0 ? height * (imageWidth / imageHeight) : 0;
          }
        } else {
          if (imageWidth > 0) {
            width = math.min(imageWidth, maxW);
            final ar = node.style.aspectRatio;
            if (ar != null && ar > 0) {
              height = width / ar;
            } else {
              height = width * (imageHeight / imageWidth);
            }
          } else {
            width = 0;
            height = 0;
          }
        }
      } else {
        // Image not loaded yet - use specified dimensions or smart placeholder
        final maxW =
            _maxWidth > _kImageMargin ? _maxWidth - _kImageMargin : _maxWidth;
        // CSS style takes priority over HTML attrs (customCss/inline style wins).
        final dimW = node.style.width ?? node.intrinsicWidth;
        final dimH = node.style.height ?? node.intrinsicHeight;
        if (dimW != null && dimH != null) {
          final scale = (dimW > maxW && dimW > 0) ? maxW / dimW : 1.0;
          width = dimW * scale;
          height = dimH * scale;
        } else if (dimW != null) {
          width = math.min(dimW, maxW);
          final ar = node.style.aspectRatio;
          height = width / (ar ?? RenderHyperBox._defaultAspectRatio);
        } else if (dimH != null) {
          height = dimH;
          final ar = node.style.aspectRatio;
          width = height * (ar ?? RenderHyperBox._defaultAspectRatio);
        } else {
          width = math.min(_defaultImageWidth, maxW);
          final ar = node.style.aspectRatio;
          height = width / (ar ?? RenderHyperBox._defaultAspectRatio);
        }
      }
    } else if (node.tagName == 'video') {
      final maxW = _maxWidth > 16 ? _maxWidth - 16 : _maxWidth;
      final intrinsicW = node.intrinsicWidth;
      final intrinsicH = node.intrinsicHeight;
      final ar = node.style.aspectRatio;
      if (intrinsicW != null && intrinsicH != null) {
        final scale =
            (intrinsicW > maxW && intrinsicW > 0) ? maxW / intrinsicW : 1.0;
        width = intrinsicW * scale;
        height = intrinsicH * scale;
      } else if (intrinsicW != null) {
        width = math.min(intrinsicW, maxW);
        height = width / (ar ?? RenderHyperBox._defaultAspectRatio);
      } else {
        width = math.min(320.0, maxW);
        height = width / (ar ?? RenderHyperBox._defaultAspectRatio);
      }
    } else if (node.tagName == 'audio') {
      // Audio: compact horizontal bar — matches DefaultMediaWidget._buildAudioPlaceholder
      width = math.min(node.intrinsicWidth ?? 300.0,
          _maxWidth > 16 ? _maxWidth - 16 : _maxWidth);
      height = node.intrinsicHeight ?? 64.0;
    } else if (node.tagName == 'formula') {
      // Inline formula — estimate width from character count, fixed line height
      final formulaText = node.attributes['formula'] ?? node.src ?? '';
      width = node.intrinsicWidth ??
          (formulaText.length * 9.0)
              .clamp(60.0, _maxWidth > 32 ? _maxWidth - 32 : _maxWidth);
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

  /// Step 1.7: Update inline-plugin fragment sizes from child widget intrinsics.
  ///
  /// Called after [_buildFragmentChildMap] so [_fragmentChildMap] is populated.
  /// For each [Fragment.atomic] whose sourceNode tag is in [_inlinePluginTags],
  /// ask the linked [RenderBox] for its intrinsic dimensions and store them on
  /// [Fragment.measuredSize] before [_measureFragments] (Step 2) runs.
  /// [_measureFragments] skips fragments that already have a [measuredSize].
  void _measureInlinePluginFragments() {
    for (final fragment in _fragments) {
      if (fragment.type != FragmentType.atomic) continue;
      final tag = fragment.sourceNode.tagName?.toLowerCase();
      if (tag == null || !_inlinePluginTags.contains(tag)) continue;

      final child = _fragmentChildMap[fragment];
      if (child == null) continue;

      // Dry-layout: getMaxIntrinsicWidth/Height never triggers a full layout
      // pass — safe to call before child.layout().
      final w =
          child.getMaxIntrinsicWidth(double.infinity).clamp(1.0, _maxWidth);
      final h = child.getMinIntrinsicHeight(w);
      fragment.measuredSize = Size(w, h > 0 ? h : 24.0);
    }
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
            fragment.baseline = 0;
            break;
          }
          final painter = _getTextPainter(text, fragment.style);
          fragment.measuredSize = Size(painter.width, painter.height);
          fragment.baseline =
              painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
          break;

        case FragmentType.ruby:
          _measureRubyFragment(fragment);
          break;

        case FragmentType.lineBreak:
          final painter = _getTextPainter(' ', fragment.style);
          fragment.measuredSize = Size(0, painter.height);
          fragment.baseline =
              painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
          break;

        case FragmentType.atomic:
          // Already measured during tokenization
          fragment.baseline = fragment.measuredSize?.height;
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
    fragment.baseline = height * 0.85;
  }

  /// The style a text/ruby fragment should actually be measured, painted and
  /// hit-tested with, folding in any `text-align: justify` word-spacing set on
  /// the fragment. Returns the fragment's own style unchanged when not
  /// justified (the common case), so there's no allocation on the hot path.
  ComputedStyle _effectiveFragmentStyle(Fragment fragment) {
    if (fragment.justifyWordSpacing == 0) return fragment.style;
    return fragment.style.copyWith(
      wordSpacing:
          (fragment.style.wordSpacing ?? 0) + fragment.justifyWordSpacing,
    );
  }

  /// Whether [whiteSpace] preserves preformatted whitespace and line breaks.
  bool _isPreformattedWhiteSpace(String? whiteSpace) {
    return whiteSpace == 'pre' ||
        whiteSpace == 'pre-wrap' ||
        whiteSpace == 'break-spaces';
  }

  TextPainter _getTextPainter(String text, ComputedStyle style) {
    // Per-fragment text direction (supports RTL via CSS direction: rtl)
    final fragmentDirection =
        style.isRtl ? ui.TextDirection.rtl : textDirection;

    final key = _TextPainterKey(
      text: text,
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      fontStyle: style.fontStyle,
      color: style.color,
      fontFamily: style.fontFamily,
      lineHeight: style.lineHeight,
      letterSpacing: style.letterSpacing,
      wordSpacing: style.wordSpacing,
      textDirection: fragmentDirection,
      textScaler: _textScaler,
    );

    final cached = _textPainters.get(key);
    if (cached != null) {
      return cached;
    }

    // FIXED: baseStyle is the foundation, computed style overrides it
    final mergedStyle = _baseStyle.merge(style.toTextStyle());

    // Pre/pre-wrap/break-spaces fragments may contain multi-line text; allow unlimited lines
    final isPreformatted = _isPreformattedWhiteSpace(style.whiteSpace);
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
      strutStyle:
          StrutStyle.fromTextStyle(mergedStyle, forceStrutHeight: false),
      textDirection: fragmentDirection,
      // System accessibility text scaling (WCAG 1.4.4). Applied here at the
      // painter level rather than by inflating fontSize so em-based metrics,
      // strut, and letter-spacing scale consistently the way Flutter's own
      // Text/RichText do.
      textScaler: _textScaler,
      maxLines: maxLines,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: true,
        applyHeightToLastDescent: true,
      ),
    )..layout();
    if (kDebugMode) HyperRenderDebugHooks.onTextPainterLayout?.call();

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
    // Built by this pass, so a re-run (width change, details toggle, intrinsic
    // query) must start empty or the previous pass's rects keep painting.
    _blockDecorations.clear();
    // Undo earlier shifts first: a fragment line layout doesn't re-place, such
    // as one it splits or replaces, would otherwise keep gaining the shift.
    _displaced.forEach((fragment, shift) {
      final offset = fragment.offset;
      if (offset != null) fragment.offset = offset - shift;
    });
    _displaced.clear();
    _displacedOnLines.clear();

    // Reset layout caches
    _cachedAvailableWidth = null;
    _pendingLineLeftFloats.clear();
    _pendingLineRightFloats.clear();

    // Clear any prior ellipsis-truncation state. Fragments persist across
    // layout passes (_ensureFragments only rebuilds when _fragments is
    // cleared), so a width change that now fits the full text must drop
    // any stale "hidden" flags from a previous narrower pass.
    for (final f in _fragments) {
      f.ellipsisVisibleLength = null;
    }

    // Seed floats inherited from the previous virtualized section so that
    // text in this section correctly wraps around a float that began in the
    // preceding chunk (cross-chunk float continuity).
    for (final carryover in _initialFloats) {
      final floatRect = carryover.direction == HyperFloat.left
          ? Rect.fromLTWH(0, 0, carryover.width, carryover.overhangHeight)
          : Rect.fromLTWH(_maxWidth - carryover.width, 0, carryover.width,
              carryover.overhangHeight);
      final area = _FloatArea(
          rect: floatRect,
          direction: carryover.direction,
          imageSrc: carryover.imageSrc);
      if (carryover.direction == HyperFloat.left) {
        _leftFloats.add(area);
      } else {
        _rightFloats.add(area);
      }
    }

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

    double getAvailableWidth() {
      if (_cachedAvailableWidth != null) return _cachedAvailableWidth!;

      assert(
        _leftFloats.length + _rightFloats.length <= 50,
        'HyperRender: ${_leftFloats.length + _rightFloats.length} active floats'
        ' — layout may be slow',
      );
      // Start with accumulated block padding
      double floatLeftInset = leftPaddingStack.last;
      double floatRightInset = rightPaddingStack.last;

      // Add float insets - O(Floats) but only called once per line or float addition
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

      _cachedAvailableWidth =
          math.max(0.0, _maxWidth - floatLeftInset - floatRightInset);
      return _cachedAvailableWidth!;
    }

    void finishLine() {
      if (currentLineFragments.isEmpty) {
        // Even if empty, if we had pending floats, flush them now.
        if (_pendingLineLeftFloats.isNotEmpty ||
            _pendingLineRightFloats.isNotEmpty) {
          _leftFloats.addAll(_pendingLineLeftFloats);
          _rightFloats.addAll(_pendingLineRightFloats);
          _pendingLineLeftFloats.clear();
          _pendingLineRightFloats.clear();
          _cachedAvailableWidth = null;
        }
        return;
      }

      while (currentLineFragments.isNotEmpty &&
          currentLineFragments.last.isWhitespace) {
        currentLineFragments.removeLast();
      }

      // Collapsible spaces at the end of a line hang (CSS Text 3 §4.1.2):
      // they must not count toward the width text-align centers or
      // right-aligns, or the visible glyphs end up one space off.
      if (currentLineFragments.isNotEmpty) {
        final last = currentLineFragments.last;
        final ws = last.style.whiteSpace;
        if (last.type == FragmentType.text &&
            last.text != null &&
            last.text!.endsWith(' ') &&
            ws != 'pre' &&
            ws != 'pre-wrap' &&
            ws != 'break-spaces') {
          final trimmed = Fragment.text(
            text: last.text!.trimRight(),
            sourceNode: last.sourceNode,
            style: last.style,
            characterOffset: last.characterOffset,
          )
            ..globalOffset = last.globalOffset
            ..offset = last.offset
            ..ellipsisVisibleLength = last.ellipsisVisibleLength;
          _measureFragment(trimmed);
          currentLineFragments[currentLineFragments.length - 1] = trimmed;
        }
      }

      if (currentLineFragments.isEmpty) {
        // Line became empty after trimming whitespace - just flush floats.
        _leftFloats.addAll(_pendingLineLeftFloats);
        _rightFloats.addAll(_pendingLineRightFloats);
        _pendingLineLeftFloats.clear();
        _pendingLineRightFloats.clear();
        _cachedAvailableWidth = null;
        return;
      }

      final lineInfo = LineInfo(
        top: currentY,
        baseline: maxBaseline,
        leftInset: leftInset,
        rightInset: rightInset,
      );
      final currentLineIndex = _lines.length;
      for (final frag in currentLineFragments) {
        frag.lineIndex = currentLineIndex;
        lineInfo.add(frag);
      }
      // Guard against zero lineHeight: when all fragments have measuredSize ==
      // null (e.g. zero-dimension images) the computed height is 0. A
      // zero-height bounds rect would place the next line at the same Y,
      // producing overlapping content.
      final safeLineHeight = lineHeight > 0 ? lineHeight : 1.0;
      // Set bounds after adding fragments
      lineInfo.bounds =
          Rect.fromLTWH(leftInset, currentY, lineInfo.width, safeLineHeight);
      _lines.add(lineInfo);

      currentY += safeLineHeight;
      currentLineFragments.clear();
      lineHeight = 0;
      maxBaseline = 0;

      // Flush floats that were triggered by this line so next line can wrap around them.
      _leftFloats.addAll(_pendingLineLeftFloats);
      _rightFloats.addAll(_pendingLineRightFloats);
      _pendingLineLeftFloats.clear();
      _pendingLineRightFloats.clear();

      // Reset width cache for new line Y
      _cachedAvailableWidth = null;
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

        // The box edges: the containing block's content edges, moved in by this
        // block's margins. Clamped to this render box, so a negative margin can
        // reach into a parent's padding but no margin can place a background
        // outside the box, over the host app.
        final margin =
            fragment.appliesHorizontalMargins ? fragment.style.margin : null;
        final boxLeftInset =
            (leftPaddingStack.last + (margin?.left ?? 0)).clamp(0.0, _maxWidth);
        final boxRightInset = (rightPaddingStack.last + (margin?.right ?? 0))
            .clamp(0.0, _maxWidth);

        // ACCUMULATE padding for nested blocks
        var newLeftPadding = boxLeftInset + fragment.paddingLeft;
        var newRightPadding = boxRightInset + fragment.paddingRight;
        // Left edge of this block's painted box. Moves if `auto` margins do.
        var boxLeftX = boxLeftInset;

        // CSS width constraints on a block, resolved via the existing per-block
        // padding stack (no separate per-block width machinery needed). We pick
        // a target content width, then inflate the right inset so the
        // line-breaker wraps text inside it.
        //
        // The containing block's content width — what `%` resolves against per
        // CSS — is `_maxWidth − parentLeftInset − parentRightInset`, i.e. the
        // stack tops BEFORE this block's own padding was added.
        final st = fragment.style;
        // Right edge of this block's painted box, when `width` & co. narrow it.
        // Null keeps the default: the full width of the containing block.
        double? constrainedBoxRight;
        if (st.width != null ||
            st.widthPercent != null ||
            st.maxWidth != null ||
            st.maxWidthPercent != null ||
            st.minWidth != null ||
            st.minWidthPercent != null) {
          // Floored at 0: cumulative padding can exceed the viewport width
          // (e.g. `padding:300px` inside a 200px container), which would make
          // this negative and turn a `%` width into a negative target.
          final containerContent = math.max(
              0.0, _maxWidth - leftPaddingStack.last - rightPaddingStack.last);
          // Flex and grid containers draw their own padding and border in a
          // child widget, so neither applies to this canvas-side box.
          final isWidgetBox =
              st.display == DisplayType.flex || st.display == DisplayType.grid;
          final borderSum =
              isWidgetBox ? 0.0 : st.borderWidth.left + st.borderWidth.right;
          // `border-box` widths include padding and border; the line breaker
          // needs the content width that leaves.
          final boxExtras = st.boxSizing == HyperBoxSizing.borderBox
              ? fragment.paddingLeft + fragment.paddingRight + borderSum
              : 0.0;
          double toContent(double specified) =>
              math.max(0.0, specified - boxExtras);

          // Default target: this block's own content width (full available).
          var target = _maxWidth - newLeftPadding - newRightPadding;

          // Explicit width (absolute or %) sets the target outright.
          if (st.width != null) {
            target = toContent(st.width!);
          } else if (st.widthPercent != null) {
            target = toContent(containerContent * st.widthPercent!);
          }
          // max-width caps it (absolute wins over % if both somehow set).
          final maxW = st.maxWidth ??
              (st.maxWidthPercent != null
                  ? containerContent * st.maxWidthPercent!
                  : null);
          if (maxW != null && target > toContent(maxW)) {
            target = toContent(maxW);
          }
          // min-width raises it — and wins over max-width per CSS.
          final minW = st.minWidth ??
              (st.minWidthPercent != null
                  ? containerContent * st.minWidthPercent!
                  : null);
          if (minW != null && target < toContent(minW)) {
            target = toContent(minW);
          }
          // Clamp into the available content box: this single-column flow model
          // has no per-block horizontal overflow, so a target wider than the
          // container is capped rather than overflowing.
          //
          // `avail` MUST be floored at 0 before it becomes clamp's upper limit:
          // when a block's own padding exceeds the viewport it goes negative,
          // and `clamp(0.0, negative)` throws ArgumentError (lowerLimit >
          // upperLimit), crashing performLayout. Flooring collapses the block's
          // content width to 0 instead — no room for content, but no crash.
          final avail =
              math.max(0.0, _maxWidth - newLeftPadding - newRightPadding);
          target = target.clamp(0.0, avail);

          // Painted width. Borders don't reserve line-breaker space yet, so
          // they count here only.
          final boxWidth =
              fragment.paddingLeft + target + fragment.paddingRight + borderSum;

          // `auto` margins share the free space: centred when both are auto.
          if (fragment.appliesHorizontalMargins &&
              (st.marginLeftAuto || st.marginRightAuto)) {
            final free = math.max(
                0.0, _maxWidth - boxLeftInset - boxRightInset - boxWidth);
            if (st.marginLeftAuto) {
              final shift = st.marginRightAuto ? free / 2 : free;
              boxLeftX += shift;
              newLeftPadding += shift;
            }
          }

          // Capped so a box never paints past its containing block.
          if (!isWidgetBox) {
            constrainedBoxRight =
                math.min(_maxWidth - boxRightInset, boxLeftX + boxWidth);
          }
          newRightPadding = _maxWidth - newLeftPadding - target;
        }

        leftPaddingStack.add(newLeftPadding);
        rightPaddingStack.add(newRightPadding);

        leftInset = newLeftPadding;
        rightInset = newRightPadding;
        currentX = leftInset;
        // The insets just changed; drop the cached available width so the next
        // getAvailableWidth() recomputes against this block's constraints.
        _cachedAvailableWidth = null;

        // Track this block for decoration (background, border-left, border-radius)
        final style = fragment.style;
        final hasBackground =
            style.backgroundColor != null || style.backgroundGradient != null;
        final hasBorderLeft =
            style.borderColor != null && style.borderWidth.left > 0;
        if (hasBackground || hasBorderLeft) {
          // The painted box: inside the margins, outside this block's padding.
          final blockLeftX = boxLeftX;
          final blockRightX = math.max(
              blockLeftX, constrainedBoxRight ?? (_maxWidth - boxRightInset));
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
        // Position marker in the margin before the list content.
        // For LTR: left of the content indent.
        // For RTL: right of the content indent (mirror to right edge).
        if (isRTL) {
          fragment.offset = Offset(
            _maxWidth - rightInset + 4,
            currentY,
          );
        } else {
          fragment.offset = Offset(leftInset - painter.width - 4, currentY);
        }
        return;
      }

      if (fragment is _BlockEndFragment) {
        finishLine();
        currentY += fragment.paddingBottom + fragment.marginBottom;

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
        double blockHeight = 0.0;
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
        double blockHeight = 0.0;
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
              BoxConstraints(
                  minWidth: detailsMaxWidth, maxWidth: detailsMaxWidth),
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
        // Mark suppressed text fragments as fully hidden so
        // getSelectedText / a11y don't leak content behind the "…".
        if ((fragment.type == FragmentType.text ||
                fragment.type == FragmentType.ruby) &&
            fragment.text != null) {
          fragment.ellipsisVisibleLength = 0;
        }
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

      // Collapsible spaces at the start of a line are removed (CSS Text 3
      // §4.1.2), e.g. the indentation newline after `<p>` or after `<br>`.
      if (currentLineFragments.isEmpty &&
          fragment.type == FragmentType.text &&
          fragment.text != null) {
        final ws = fragment.style.whiteSpace;
        if (ws != 'pre' && ws != 'pre-wrap' && ws != 'break-spaces') {
          final text = fragment.text!;
          var lead = 0;
          while (lead < text.length && text.codeUnitAt(lead) == 0x20) {
            lead++;
          }
          if (lead == text.length) return;
          if (lead > 0) {
            fragment = Fragment.text(
              text: text.substring(lead),
              sourceNode: fragment.sourceNode,
              style: fragment.style,
              characterOffset: fragment.characterOffset + lead,
            )..globalOffset = fragment.globalOffset + lead;
            _measureFragment(fragment);
          }
        }
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
          (fragment.type == FragmentType.text ||
              fragment.type == FragmentType.ruby) &&
          fragment.text != null &&
          fragment.width > remainingWidth) {
        const ellipsisChar = '\u2026'; // …
        final ellipsisPainter = _getTextPainter(ellipsisChar, fragment.style);
        final fitWidth = remainingWidth - ellipsisPainter.width;

        // Record how many characters from this fragment actually survived
        // the truncation pass so getSelectedText / a11y don't leak the
        // clipped suffix. Defaults to 0 (fully hidden) and gets raised when
        // a partial prefix fits on the line.
        fragment.ellipsisVisibleLength = 0;

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
              )
                ..globalOffset = fragment.globalOffset
                ..ellipsisVisibleLength = clippedText.length;
              _measureFragment(truncFrag);
              truncFrag.offset = Offset(currentX, currentY);
              currentLineFragments.add(truncFrag);
              _updateLineMetrics(truncFrag, lineHeight, maxBaseline, (h, b) {
                lineHeight = h;
                maxBaseline = b;
              });
              fragment.ellipsisVisibleLength = clippedText.length;
            }
          }
        }
        if (currentLineFragments.isEmpty) {
          // Not even enough room for ellipsis alone — just show ellipsis
          final ellipsisFrag = Fragment.text(
            text: ellipsisChar,
            sourceNode: fragment.sourceNode,
            style: fragment.style,
            characterOffset: fragment.characterOffset,
          )
            ..globalOffset = fragment.globalOffset
            ..ellipsisVisibleLength = 0;
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

          // Can't split to fit - start new line, and process the fragment
          // again there so the line-start rules (leading-space collapse)
          // apply to it.
          if (currentLineFragments.isNotEmpty) {
            finishLine();
            currentX = leftInset;
            pendingFragment = fragment;
            return;
          }

          // Now check if fragment is wider than full line width
          final fullLineWidth = getAvailableWidth();
          if (fragment.width > fullLineWidth && fragment.text!.length > 1) {
            // Fast path: When there are no active or pending floats and the fragment
            // starts at the beginning of a line, available width is uniform across all
            // lines. Layout the entire text in a single TextPainter pass via native
            // ICU line-breaking, avoiding thousands of individual TextPainter.layout() calls.
            final bool canUseNativeMultiLine = _leftFloats.isEmpty &&
                _rightFloats.isEmpty &&
                _pendingLineLeftFloats.isEmpty &&
                _pendingLineRightFloats.isEmpty &&
                currentLineFragments.isEmpty &&
                fullLineWidth > 0 &&
                ellipsisDepth == 0 &&
                !fragment.style.isRtl &&
                textDirection != ui.TextDirection.rtl &&
                fragment.style.wordBreak != 'break-all' &&
                fragment.style.textOverflow != TextOverflow.ellipsis &&
                !_isPreformattedWhiteSpace(fragment.style.whiteSpace) &&
                fragment.style.whiteSpace != 'nowrap';

            if (canUseNativeMultiLine) {
              final text = fragment.text!;
              final totalLen = text.length;
              final fragmentDirection =
                  fragment.style.isRtl ? ui.TextDirection.rtl : textDirection;
              final mergedStyle =
                  _baseStyle.merge(fragment.style.toTextStyle());
              final strutStyle = StrutStyle.fromTextStyle(mergedStyle,
                  forceStrutHeight: false);

              final multiPainter = _scratchCandidatePainter ??= TextPainter();
              multiPainter
                ..text = TextSpan(text: text, style: mergedStyle)
                ..strutStyle = strutStyle
                ..textDirection = fragmentDirection
                ..textScaler = _textScaler
                ..maxLines = null
                ..textHeightBehavior = const TextHeightBehavior(
                  applyHeightToFirstAscent: true,
                  applyHeightToLastDescent: true,
                )
                ..layout(maxWidth: fullLineWidth);
              if (kDebugMode) {
                HyperRenderDebugHooks.onTextPainterLayout?.call();
                HyperRenderDebugHooks.onLineLayoutTextPainter?.call();
              }

              final metrics = multiPainter.computeLineMetrics();
              if (metrics.length > 1) {
                int startOffset = 0;
                for (int mIdx = 0; mIdx < metrics.length; mIdx++) {
                  final lm = metrics[mIdx];
                  int endOffset;
                  if (mIdx == metrics.length - 1) {
                    endOffset = totalLen;
                  } else {
                    final nextLm = metrics[mIdx + 1];
                    final nextLineY = nextLm.baseline - nextLm.ascent / 2;
                    final nextStartPos = multiPainter.getPositionForOffset(
                      Offset(0, nextLineY),
                    );
                    endOffset = nextStartPos.offset;
                    if (endOffset <= startOffset || endOffset > totalLen) {
                      final lineY = lm.baseline - lm.ascent / 2;
                      final pos = multiPainter.getPositionForOffset(
                        Offset(fullLineWidth, lineY),
                      );
                      endOffset = pos.offset;
                    }
                  }

                  if (endOffset <= startOffset && startOffset < totalLen) {
                    endOffset = startOffset + 1;
                  } else if (endOffset > totalLen) {
                    endOffset = totalLen;
                  }

                  final lineText = text.substring(startOffset, endOffset);
                  final lineFrag = Fragment.text(
                    text: lineText,
                    sourceNode: fragment.sourceNode,
                    style: fragment.style,
                    characterOffset: fragment.characterOffset + startOffset,
                  )..globalOffset = fragment.globalOffset + startOffset;

                  lineFrag.measuredSize = Size(lm.width, lm.height);
                  lineFrag.baseline = lm.ascent;

                  lineFrag.offset = Offset(currentX, currentY);
                  currentLineFragments.add(lineFrag);
                  _updateLineMetrics(lineFrag, lineHeight, maxBaseline, (h, b) {
                    lineHeight = h;
                    maxBaseline = b;
                  });

                  if (mIdx < metrics.length - 1) {
                    finishLine();
                    currentX = leftInset;
                  } else {
                    currentX += lineFrag.width;
                  }
                  startOffset = endOffset;
                }
                return;
              }
            }

            // A float narrows this line and not even the first word fits
            // beside it: move down past the float (as CSS line boxes do)
            // instead of splitting the word after its first letter.
            final contentWidth =
                _maxWidth - leftPaddingStack.last - rightPaddingStack.last;
            if (fullLineWidth < contentWidth - 0.5 &&
                !_leadingUnitFits(fragment, fullLineWidth)) {
              double? floatBottom;
              for (final float in [..._leftFloats, ..._rightFloats]) {
                if (currentY >= float.rect.top &&
                    currentY < float.rect.bottom &&
                    (floatBottom == null || float.rect.bottom < floatBottom)) {
                  floatBottom = float.rect.bottom;
                }
              }
              if (floatBottom != null) {
                currentY = floatBottom;
                _cachedAvailableWidth = null;
                getAvailableWidth(); // refreshes leftInset for the new Y
                currentX = leftInset;
                pendingFragment = fragment;
                return;
              }
            }

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

      // An oversized tail carries an estimated infinite width; measure it for
      // real once it is placed. Do NOT also measure `measuredSize == null`
      // fragments: a floated block's own text arrives unmeasured (known gap),
      // and measuring it adds a phantom line height.
      if (fragment.width.isInfinite) {
        _measureFragment(fragment);
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
    if (fragment.baseline != null) return fragment.baseline!;
    if (fragment.type == FragmentType.text && fragment.text != null) {
      final painter = _getTextPainter(fragment.text!, fragment.style);
      final b =
          painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      fragment.baseline = b;
      return b;
    } else if (fragment.type == FragmentType.ruby) {
      final b = fragment.height * 0.85;
      fragment.baseline = b;
      return b;
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

  /// Rendered width of the first [length] code units of [painter]'s
  /// single-line text, read from the caret position: measured from the left
  /// edge for LTR and from the right edge for RTL. A caret lookup is cheap,
  /// unlike summing `getBoxesForSelection(0, length)`, which costs O(length)
  /// per call on a long paragraph.
  double _prefixWidth(TextPainter painter, int length) {
    if (length <= 0) return 0;
    final caretX =
        painter.getOffsetForCaret(TextPosition(offset: length), Rect.zero).dx;
    return painter.textDirection == ui.TextDirection.rtl
        ? painter.width - caretX
        : caretX;
  }

  /// The longest prefix of [text] (laid out single-line in [painter]) whose
  /// rendered width is at most [maxWidth].
  ///
  /// `getPositionForOffset(Offset(maxWidth, 0))` alone is not enough: it
  /// returns the *nearest* caret, up to half a glyph past [maxWidth], and in
  /// an RTL painter `x = maxWidth` from the left is the logical end of the
  /// text, not its start. The probe is mirrored for RTL and the result is
  /// corrected against measured prefix widths.
  int _fitPrefixLength(TextPainter painter, String text, double maxWidth) {
    const epsilon = 0.01;
    final rtl = painter.textDirection == ui.TextDirection.rtl;
    final probeX = rtl ? painter.width - maxWidth : maxWidth;
    var fit = painter
        .getPositionForOffset(Offset(probeX, 0))
        .offset
        .clamp(0, text.length);
    while (fit > 0 && _prefixWidth(painter, fit) > maxWidth + epsilon) {
      fit--;
    }
    while (fit < text.length &&
        _prefixWidth(painter, fit + 1) <= maxWidth + epsilon) {
      fit++;
    }
    return fit;
  }

  /// Whether the first unbreakable unit of [fragment] (its first word, or its
  /// first character where any character boundary may break) fits in [width].
  bool _leadingUnitFits(Fragment fragment, double width) {
    final text = fragment.text!;
    final painter = _getTextPainter(text, fragment.style);
    final fit = _fitPrefixLength(painter, text, width);
    if (fit <= 0) return false;
    if (fragment.style.wordBreak == 'break-all' ||
        KinsokuProcessor.containsCjk(text)) {
      return true;
    }
    var wordStart = 0;
    while (wordStart < text.length && text[wordStart] == ' ') {
      wordStart++;
    }
    final space = text.indexOf(' ', wordStart);
    return (space < 0 ? text.length : space) <= fit;
  }

  /// The number of characters of [text], from [start], that could possibly fit
  /// on one line of [maxWidth] (plus a safety margin). Candidate prefixes are
  /// bounded by this so a long paragraph is not re-shaped from scratch for
  /// every line (O(N^2)).
  ///
  /// Walks the text adding the narrowest width each character can have: a full
  /// width CJK character is 1em, anything else is assumed to be at least
  /// 0.25em, both scaled by the active text scaler. Measuring the actual text
  /// matters for mixed content: a Latin run after a single CJK character must
  /// not inherit the CJK bound, or a line is cut short.
  int _safeCandidateCharLimit(
      String text, int start, double maxWidth, ComputedStyle style) {
    const margin = 64;
    final effectiveWidth = maxWidth > 0 ? maxWidth : 1.0;
    final fontSize =
        _textScaler.scale(style.fontSize > 0 ? style.fontSize : 16.0);
    final cjkMin = fontSize;
    final otherMin = fontSize * 0.25;
    var width = 0.0;
    var i = start;
    while (i < text.length && width < effectiveWidth) {
      width += KinsokuProcessor.isCjkCodeUnit(text.codeUnitAt(i))
          ? cjkMin
          : otherMin;
      i++;
    }
    return (i - start) + margin;
  }

  /// Reusable TextPainter for layout candidate prefixes, avoiding allocating
  /// transient objects or thrashing the global [_textPainters] cache.
  TextPainter _getCandidatePainter(
    String text,
    ComputedStyle style, {
    TextStyle? preMergedStyle,
    StrutStyle? preStrutStyle,
  }) {
    final fragmentDirection =
        style.isRtl ? ui.TextDirection.rtl : textDirection;
    final mergedStyle = preMergedStyle ?? _baseStyle.merge(style.toTextStyle());
    final strutStyle = preStrutStyle ??
        StrutStyle.fromTextStyle(mergedStyle, forceStrutHeight: false);
    final isPreformatted = _isPreformattedWhiteSpace(style.whiteSpace);
    final maxLines = isPreformatted ? null : 1;

    final painter = _scratchCandidatePainter ??= TextPainter();
    painter
      ..text = TextSpan(text: text, style: mergedStyle)
      ..strutStyle = strutStyle
      ..textDirection = fragmentDirection
      ..textScaler = _textScaler
      ..maxLines = maxLines
      ..textHeightBehavior = const TextHeightBehavior(
        applyHeightToFirstAscent: true,
        applyHeightToLastDescent: true,
      )
      ..layout();
    if (kDebugMode) {
      HyperRenderDebugHooks.onTextPainterLayout?.call();
      HyperRenderDebugHooks.onLineLayoutTextPainter?.call();
    }
    return painter;
  }

  (Fragment, Fragment)? _splitTextFragment(Fragment fragment, double maxWidth) {
    final text = fragment.text!;
    if (text.isEmpty) return null;

    final safeLimit =
        _safeCandidateCharLimit(text, 0, maxWidth, fragment.style);
    final isCandidate = text.length > safeLimit;
    final candidateText = isCandidate ? text.substring(0, safeLimit) : text;

    final painter = isCandidate
        ? _getCandidatePainter(candidateText, fragment.style)
        : _getTextPainter(candidateText, fragment.style);
    final fitIndex = _fitPrefixLength(painter, candidateText, maxWidth);
    int breakIndex = fitIndex;

    if (breakIndex > 0 && breakIndex < candidateText.length) {
      final style = fragment.style;
      final bool breakAll = style.wordBreak == 'break-all';
      final bool overflowWrap = style.overflowWrap == 'break-word' ||
          style.overflowWrap == 'anywhere';

      if (breakAll) {
        // word-break: break-all -> Break at any character
      } else {
        // Search from breakIndex inclusive: a space right after the fitting
        // prefix means the whole word before it fits.
        final lastSpace = candidateText.lastIndexOf(' ', breakIndex);

        if (lastSpace > 0) {
          // Found a space before break point - use it
          breakIndex = lastSpace + 1;
        } else if (KinsokuProcessor.containsCjk(candidateText)) {
          // Text contains CJK - check if break position is within CJK context
          final isCjkBreak = _isBreakInCjkContext(candidateText, breakIndex);

          if (isCjkBreak) {
            // Break is in CJK region - apply Kinsoku rules
            breakIndex =
                KinsokuProcessor.findBreakPoint(candidateText, breakIndex);
            if (breakIndex < 0) breakIndex = fitIndex;
          } else if (overflowWrap) {
            // Latin-region break with overflow-wrap -> Break at character
          } else {
            // Break is in Latin region of mixed text - treat as Latin
            // Look for next space AFTER break point to avoid breaking words
            final nextSpace = text.indexOf(' ', breakIndex);

            if (nextSpace >= 0 || candidateText.length < text.length) {
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
          final nextSpace = text.indexOf(' ', breakIndex);

          if (nextSpace >= 0 || candidateText.length < text.length) {
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

    // Ensure breakIndex aligns with grapheme cluster boundaries.
    // This prevents splitting emojis (even with ZWJ) or complex scripts.
    if (breakIndex > 0 && breakIndex < candidateText.length) {
      final range = candidateText.characters.iterator;
      int currentOffset = 0;
      while (range.moveNext()) {
        int nextOffset = currentOffset + range.current.length;
        if (nextOffset > breakIndex) {
          // The grapheme cluster crosses the breakIndex. Snap back.
          breakIndex = currentOffset;
          break;
        }
        currentOffset = nextOffset;
        if (currentOffset == breakIndex) break;
      }
      if (breakIndex <= 0) return null;
    }

    // Only trim spaces for normal/nowrap/pre-line modes
    // For pre/pre-wrap/break-spaces, preserve all whitespace
    final whiteSpace = fragment.style.whiteSpace;
    final shouldTrim = !_isPreformattedWhiteSpace(whiteSpace);

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
    )..globalOffset = fragment.globalOffset;

    if (firstPart.length == breakIndex) {
      final w = _prefixWidth(painter, breakIndex);
      firstFragment.measuredSize = Size(w, painter.height);
      firstFragment.baseline =
          painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    } else {
      _measureFragment(firstFragment);
    }

    // characterOffset points to the START of secondPart in the document.
    // We use `breakIndex` (not `breakIndex + trimmedLeading`) so that trimmed
    // leading spaces are still covered by this fragment's character range —
    // otherwise those space characters create a gap in the selection mapping.
    final secondFragment = Fragment.text(
      text: secondPart,
      sourceNode: fragment.sourceNode,
      style: fragment.style,
      characterOffset: fragment.characterOffset + breakIndex,
    )..globalOffset = fragment.globalOffset + breakIndex;

    // Optimization: If secondPart is far longer than could fit on ANY line in
    // this container, skip expensive HarfBuzz layout and assign an estimated size.
    // Container width _maxWidth is used rather than line maxWidth to avoid
    // erroneously assuming the tail fits on the next full-width line.
    final safeContainerLimit =
        _safeCandidateCharLimit(text, breakIndex, _maxWidth, fragment.style);
    if (secondPart.length > safeContainerLimit) {
      secondFragment.measuredSize = Size(double.infinity, firstFragment.height);
      secondFragment.baseline = firstFragment.baseline;
    } else {
      _measureFragment(secondFragment);
    }

    return (firstFragment, secondFragment);
  }

  void _measureFragment(Fragment fragment) {
    if (fragment.type == FragmentType.text && fragment.text != null) {
      final painter = _getTextPainter(fragment.text!, fragment.style);
      fragment.measuredSize = Size(painter.width, painter.height);
      fragment.baseline =
          painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    }
  }

  /// Force split text fragment when entire text is wider than the available line
  /// This tries to respect word boundaries for Latin text, only breaking mid-word
  /// when a single word is wider than the entire line width
  (Fragment, Fragment)? _forceSplitTextFragment(
      Fragment fragment, double maxWidth) {
    final text = fragment.text!;
    if (text.length <= 1) return null;

    final style = fragment.style;
    final bool breakAll = style.wordBreak == 'break-all';
    final bool overflowWrap =
        style.overflowWrap == 'break-word' || style.overflowWrap == 'anywhere';

    final safeLimit = _safeCandidateCharLimit(text, 0, maxWidth, style);
    final isCandidate = text.length > safeLimit;
    final candidateText = isCandidate ? text.substring(0, safeLimit) : text;

    // Longest prefix that really fits (not the nearest caret, which can run
    // half a glyph past maxWidth, and mirrored for RTL painters).
    final painter = isCandidate
        ? _getCandidatePainter(candidateText, style)
        : _getTextPainter(candidateText, style);
    final fitIndex = _fitPrefixLength(painter, candidateText, maxWidth);

    // First, try to find a word boundary that fits. word-break: break-all
    // fills the line by character instead.
    int breakIndex = -1;
    if (!breakAll) {
      // A space at fitIndex itself still counts: the word before it fits.
      final space = fitIndex < candidateText.length
          ? candidateText.lastIndexOf(' ', fitIndex)
          : candidateText.lastIndexOf(' ');
      if (space >= 0) breakIndex = space + 1;
    }

    // If no word boundary fits, but overflow-wrap is enabled, or word-break: break-all
    // then force split at character level
    if (breakIndex == -1 &&
        (breakAll ||
            overflowWrap ||
            KinsokuProcessor.containsCjk(candidateText))) {
      breakIndex = fitIndex;

      // Adjust for CJK rules if applicable
      if (KinsokuProcessor.containsCjk(candidateText)) {
        final kinsokuBreak =
            KinsokuProcessor.findBreakPoint(candidateText, breakIndex);
        if (kinsokuBreak > 0) breakIndex = kinsokuBreak;
      }
    }

    // Fallback: a single word wider than the whole line. Break it after as
    // many characters as fit, as Flutter's Text does.
    if (breakIndex <= 0) breakIndex = math.max(1, fitIndex);
    if (breakIndex >= text.length) return null;

    // Collapsible spaces at the wrap hang past the line end: keep them out of
    // the next line's start (so its glyphs keep their character offsets).
    final ws = style.whiteSpace;
    final shouldTrim = !_isPreformattedWhiteSpace(ws);
    if (shouldTrim) {
      while (breakIndex < text.length && text[breakIndex] == ' ') {
        breakIndex++;
      }
      if (breakIndex >= text.length) return null;
    }

    // Ensure breakIndex aligns with grapheme cluster boundaries.
    if (breakIndex > 0 && breakIndex < candidateText.length) {
      final range = candidateText.characters.iterator;
      int currentOffset = 0;
      while (range.moveNext()) {
        int nextOffset = currentOffset + range.current.length;
        if (nextOffset > breakIndex) {
          // If we snap back to 0, snap forward instead so we don't return null
          // and get stuck dropping content.
          if (currentOffset == 0) {
            breakIndex = nextOffset;
          } else {
            breakIndex = currentOffset;
          }
          break;
        }
        currentOffset = nextOffset;
        if (currentOffset == breakIndex) break;
      }
    }

    // The trailing space is not part of the line's width, so text-align
    // centers / right-aligns the visible glyphs (as _splitTextFragment does).
    final rawFirst = text.substring(0, breakIndex);
    final trimmedFirst = shouldTrim ? rawFirst.trimRight() : rawFirst;
    final firstPart = trimmedFirst.isEmpty ? rawFirst : trimmedFirst;
    final secondPart = text.substring(breakIndex);

    final firstFragment = Fragment.text(
      text: firstPart,
      sourceNode: fragment.sourceNode,
      style: fragment.style,
      characterOffset: fragment.characterOffset,
    )..globalOffset = fragment.globalOffset;

    if (firstPart.length == breakIndex) {
      final w = _prefixWidth(painter, breakIndex);
      firstFragment.measuredSize = Size(w, painter.height);
      firstFragment.baseline =
          painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    } else {
      _measureFragment(firstFragment);
    }

    final secondFragment = Fragment.text(
      text: secondPart,
      sourceNode: fragment.sourceNode,
      style: fragment.style,
      characterOffset: fragment.characterOffset + breakIndex,
    )..globalOffset = fragment.globalOffset + breakIndex;

    final safeContainerLimit =
        _safeCandidateCharLimit(text, breakIndex, _maxWidth, fragment.style);
    if (secondPart.length > safeContainerLimit) {
      secondFragment.measuredSize = Size(double.infinity, firstFragment.height);
      secondFragment.baseline = firstFragment.baseline;
    } else {
      _measureFragment(secondFragment);
    }

    return (firstFragment, secondFragment);
  }

  /// Recursively extracts plain text content from a [UDTNode] subtree.
  /// Used by heading-anchor collection to provide human-readable TOC labels.
  /// Returns the marker string for a list item given its CSS list-style-type.
  String _buildListMarker(String type, bool isOrdered, int index) {
    switch (type) {
      case 'disc':
        return '• ';
      case 'circle':
        return '◦ ';
      case 'square':
        return '▪ ';
      case 'decimal':
        return '$index. ';
      case 'decimal-leading-zero':
        return '${index.toString().padLeft(2, '0')}. ';
      case 'lower-alpha':
      case 'lower-latin':
        return '${_indexToAlpha(index, uppercase: false)}. ';
      case 'upper-alpha':
      case 'upper-latin':
        return '${_indexToAlpha(index, uppercase: true)}. ';
      case 'lower-roman':
        return '${_indexToRoman(index).toLowerCase()}. ';
      case 'upper-roman':
        return '${_indexToRoman(index)}. ';
      default:
        return isOrdered ? '$index. ' : '• ';
    }
  }

  String _indexToAlpha(int index, {required bool uppercase}) {
    // 1→a, 2→b, …26→z, 27→aa, etc.
    final base = uppercase ? 'A'.codeUnitAt(0) : 'a'.codeUnitAt(0);
    var n = index;
    final buf = StringBuffer();
    while (n > 0) {
      n--;
      buf.write(String.fromCharCode(base + n % 26));
      n ~/= 26;
    }
    return buf.toString().split('').reversed.join();
  }

  String _indexToRoman(int n) {
    const vals = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    const syms = [
      'M',
      'CM',
      'D',
      'CD',
      'C',
      'XC',
      'L',
      'XL',
      'X',
      'IX',
      'V',
      'IV',
      'I'
    ];
    final buf = StringBuffer();
    var remaining = n;
    for (var i = 0; i < vals.length; i++) {
      while (remaining >= vals[i]) {
        buf.write(syms[i]);
        remaining -= vals[i];
      }
    }
    return buf.toString();
  }

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
    const defaultFloatMargin = _kDefaultFloatMargin;
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
      final cached = _imageCache.get(sourceNode.src!);
      if (cached?.state == ImageLoadState.loaded && cached?.image != null) {
        final img = cached!.image!;
        final imgW = img.width.toDouble();
        final imgH = img.height.toDouble();
        // CSS style takes priority over HTML attrs per CSS cascade spec.
        final dimW = sourceNode.style.width ?? sourceNode.intrinsicWidth;
        final dimH = sourceNode.style.height ?? sourceNode.intrinsicHeight;
        if (dimW != null && dimH != null) {
          final scale =
              (dimW > availableWidth && dimW > 0) ? availableWidth / dimW : 1.0;
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
          sourceNode.style.width ??
              sourceNode.intrinsicWidth ??
              sourceNode.style.maxWidth ??
              _defaultImageWidth,
          availableWidth,
        );
        height = sourceNode.style.height ??
            sourceNode.intrinsicHeight ??
            (width / RenderHyperBox._defaultAspectRatio);
      }
    } else {
      // Non-image float: measure via intrinsic APIs to avoid a double layout
      // (this runs inside _performLineLayout; _layoutChildren will do the real layout).
      // Respect explicit CSS dimensions if provided.
      final child = _findChildForFragment(fragment);
      if (child != null && !availableWidth.isInfinite && availableWidth > 0) {
        final cssWidth = fragment.style.width;
        final cssHeight = fragment.style.height;

        width = cssWidth != null
            ? math.min(cssWidth, availableWidth)
            : math.min(
                child.getMaxIntrinsicWidth(availableWidth),
                availableWidth,
              );

        height = cssHeight ?? child.getMaxIntrinsicHeight(width);
      } else {
        width = math.min(
          fragment.style.width ?? RenderHyperBox.defaultFloatSize,
          availableWidth.isInfinite
              ? RenderHyperBox.defaultFloatSize
              : availableWidth,
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
          double lowestBottom = floatY + _kMinFloatYStep;
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
        assert(() {
          debugPrint('HyperRender: left float exceeded maxIterations — '
              'falling back to lowest active float to prevent overlap.');
          return true;
        }());
        double lowestBottom = currentY;
        for (final existing in _leftFloats) {
          lowestBottom = math.max(lowestBottom, existing.rect.bottom);
        }
        for (final existing in _rightFloats) {
          lowestBottom = math.max(lowestBottom, existing.rect.bottom);
        }
        floatY = lowestBottom;
      }

      // Float rect includes margin on right and bottom for text spacing
      floatRect = Rect.fromLTWH(
        left,
        floatY,
        width + rightMargin,
        height + bottomMargin,
      );
      final imgSrc = fragment.sourceNode is AtomicNode
          ? (fragment.sourceNode as AtomicNode).src
          : null;
      _pendingLineLeftFloats.add(_FloatArea(
          rect: floatRect, direction: HyperFloat.left, imageSrc: imgSrc));
      _cachedAvailableWidth = null;
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
          double lowestBottom = floatY + _kMinFloatYStep;
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
        assert(() {
          debugPrint('HyperRender: right float exceeded maxIterations — '
              'falling back to lowest active float to prevent overlap.');
          return true;
        }());
        double lowestBottom = currentY;
        for (final existing in _leftFloats) {
          lowestBottom = math.max(lowestBottom, existing.rect.bottom);
        }
        for (final existing in _rightFloats) {
          lowestBottom = math.max(lowestBottom, existing.rect.bottom);
        }
        floatY = lowestBottom;
      }

      // Float rect includes margin on left and bottom for text spacing
      floatRect = Rect.fromLTWH(
        right - width - leftMargin,
        floatY,
        width + leftMargin,
        height + bottomMargin,
      );
      final imgSrc = fragment.sourceNode is AtomicNode
          ? (fragment.sourceNode as AtomicNode).src
          : null;
      _pendingLineRightFloats.add(_FloatArea(
          rect: floatRect, direction: HyperFloat.right, imageSrc: imgSrc));
      _cachedAvailableWidth = null;
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
  /// Whether [node]'s subtree has a `position: relative` element, recording
  /// which flex and grid containers hold one.
  bool _scanForRelative(UDTNode node) {
    if (node.style.display == DisplayType.none) return false;
    var found = node.style.position == 'relative';
    final isWidgetBox = node.style.display == DisplayType.flex ||
        node.style.display == DisplayType.grid;
    for (final child in node.children) {
      if (_scanForRelative(child)) found = true;
    }
    if (found && isWidgetBox) _relativeWidgetBoxes.add(node);
    return found;
  }

  /// Records each node's shift: its own offset plus its relative ancestors'.
  ///
  /// Walks down from this box's document rather than up `node.parent`: building
  /// a nested box's document re-parents the shared nodes, so a walk up can stop
  /// short of a relative ancestor.
  void _collectRelativeShifts(UDTNode node, Offset inherited) {
    final shift = inherited + node.style.relativeOffset(rtl: isRTL);
    _relativeShifts[node] = shift;
    for (final child in node.children) {
      _collectRelativeShifts(child, shift);
    }
  }

  /// Applies `position: relative`: moves each element's fragments and block
  /// decoration by its shift.
  ///
  /// Runs after line layout and positioning, so sibling layout never sees the
  /// shift. Lines, floats' wrap areas and anchors keep their in-flow values.
  /// Child widgets follow, since [_layoutChildren] reads `fragment.offset`.
  void _applyRelativeOffsets() {
    _relativeShifts.clear();
    _hasMovedContent = _relativeWidgetBoxes.isNotEmpty;
    if (!_hasRelative || _document == null) return;
    _collectRelativeShifts(_document!, Offset.zero);

    bool move(Fragment fragment) {
      final offset = fragment.offset;
      if (offset == null || _displaced.containsKey(fragment)) return false;
      final shift = _relativeShifts[fragment.sourceNode] ?? Offset.zero;
      if (shift == Offset.zero) return false;
      fragment.offset = offset + shift;
      _displaced[fragment] = shift;
      return true;
    }

    // Lines hold exactly the text that gets drawn.
    for (final line in _lines) {
      for (final fragment in line.fragments) {
        if (move(fragment)) _displacedOnLines.add(fragment);
      }
    }
    // `_fragments` adds what isn't on a line, such as list markers and floats.
    _fragments.forEach(move);
    for (final decoration in _blockDecorations) {
      final shift = _relativeShifts[decoration.node] ?? Offset.zero;
      if (shift == Offset.zero) continue;
      decoration.rect = decoration.rect.shift(shift);
      decoration.moved = true;
      _hasMovedContent = true;
    }
    if (_displaced.isNotEmpty) _hasMovedContent = true;
  }

  void _positionFragments() {
    // Tracks blocks whose first line has already consumed their `text-indent`,
    // so only the FIRST line of each block is indented (CSS semantics). Lines
    // are visited in document/vertical order, so the first line seen for a
    // block is its first line.
    final indentedBlocks = <UDTNode>{};

    for (int li = 0; li < _lines.length; li++) {
      final line = _lines[li];
      // Reset any justification from a previous pass so it never compounds.
      for (final f in line.fragments) {
        f.justifyWordSpacing = 0;
      }

      // CSS text-align (inherited, so any fragment on the line carries the
      // block's value). Applied here as a per-line horizontal shift of the
      // free space so that hit-testing/selection — which read fragment.offset
      // directly — stay correct for free. `justify` is not a single shift
      // (it distributes inter-word space) and is handled just below.
      final lineAlign = _lineTextAlign(line);

      // Justify: distribute free space across inter-word gaps by widening each
      // space (via per-fragment wordSpacing). Skipped on RTL, on the last line
      // of a block, and on any line ending in a forced break — matching
      // browsers, which leave those lines at their natural (start) alignment.
      if (!isRTL &&
          lineAlign == HyperTextAlign.justify &&
          !_isLastLineOfBlock(li) &&
          !_lineEndsInForcedBreak(line)) {
        _applyJustify(line);
      }

      double x;
      if (isRTL) {
        // RTL default is `start` = right-packed. We only diverge from that
        // when the paragraph carries an EXPLICIT text-align — the
        // explicitly-set flag survives onto the fragment's style, so an unset
        // RTL paragraph (flag false) still right-packs as before, avoiding the
        // old bug where re-applying the `left` default left-packed every RTL
        // line.
        final rightPacked = _maxWidth - line.rightInset - line.width;
        if (_lineTextAlignIsExplicit(line)) {
          final available = _maxWidth - line.leftInset - line.rightInset;
          final freeSpace = math.max(0.0, available - line.width);
          switch (_lineTextAlign(line)) {
            case HyperTextAlign.left:
              x = line.leftInset;
            case HyperTextAlign.center:
              x = line.leftInset + freeSpace / 2;
            case HyperTextAlign.right:
            case HyperTextAlign.justify:
              // right and justify both keep the RTL start edge (justify in RTL
              // is not distributed yet — a deliberate limitation).
              x = rightPacked;
          }
        } else {
          x = rightPacked;
        }
      } else {
        // LTR: apply text-align as a per-line shift of the free space. Reading
        // fragment.offset keeps hit-testing/selection correct for free.
        final align = _lineTextAlign(line);
        final available = _maxWidth - line.leftInset - line.rightInset;
        final freeSpace = math.max(0.0, available - line.width);
        final double alignShift;
        switch (align) {
          case HyperTextAlign.center:
            alignShift = freeSpace / 2;
          case HyperTextAlign.right:
            alignShift = freeSpace;
          case HyperTextAlign.left:
          case HyperTextAlign.justify:
            // justify falls back to left start-x; inter-word space
            // distribution is a separate, not-yet-implemented step.
            alignShift = 0;
        }
        x = line.leftInset + alignShift;
      }

      // CSS text-indent: shift only the FIRST line of a block rightward.
      // LTR only (RTL is right-packed above and indent direction flips). The
      // shift moves fragment.offset, so selection/hit-testing stay correct.
      // A `%` indent resolves against the block's own content width, which for
      // this line is `_maxWidth − leftInset − rightInset`.
      if (!isRTL && line.fragments.isNotEmpty) {
        final st = line.fragments.first.style;
        double indent = st.textIndent ?? 0;
        if (st.textIndentPercent != null) {
          final contentWidth =
              math.max(0.0, _maxWidth - line.leftInset - line.rightInset);
          indent += contentWidth * st.textIndentPercent!;
        }
        if (indent > 0) {
          final block = _nearestBlockAncestor(line.fragments.first.sourceNode);
          if (block != null && indentedBlocks.add(block)) {
            x += indent;
          }
        }
      }

      for (final fragment in line.fragments) {
        final fragmentBaseline = _fragmentBaseline(fragment);
        final yOffset = line.baseline - fragmentBaseline;
        fragment.offset = Offset(x, line.top + math.max(0, yOffset));
        // Advance by the JUSTIFIED width: wordSpacing adds a fixed px per
        // space, so effective width = measured width + spaces × extra.
        x += fragment.width +
            (fragment.justifyWordSpacing == 0
                ? 0.0
                : _spaceCount(fragment.text) * fragment.justifyWordSpacing);
      }
    }
  }

  /// Number of collapsible inter-word spaces in [text] (justification gaps).
  int _spaceCount(String? text) {
    if (text == null || text.isEmpty) return 0;
    var n = 0;
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x20) n++;
    }
    return n;
  }

  /// Sets `justifyWordSpacing` on each text fragment of [line] so the line's
  /// last visible glyph reaches the right edge. Free space is spread across
  /// INTERNAL word gaps only — a trailing space (left over from the wrap) is
  /// excluded from the gap count and its width is added back to the free
  /// space, so the final word lands exactly at the edge (matching browsers).
  void _applyJustify(LineInfo line) {
    final available = _maxWidth - line.leftInset - line.rightInset;

    // Total gaps, and the trailing-whitespace run on the last text fragment.
    var totalGaps = 0;
    Fragment? lastText;
    for (final f in line.fragments) {
      if (f.type == FragmentType.text && (f.text?.isNotEmpty ?? false)) {
        totalGaps += _spaceCount(f.text);
        lastText = f;
      }
    }
    var trailingSpaces = 0;
    if (lastText != null) {
      final t = lastText.text!;
      for (var i = t.length - 1; i >= 0 && t.codeUnitAt(i) == 0x20; i--) {
        trailingSpaces++;
      }
    }
    final internalGaps = totalGaps - trailingSpaces;
    if (internalGaps <= 0) return; // single word (or all trailing) — no justify

    // Width of the trailing spaces, to add back into the distributable space.
    final trailingWidth = trailingSpaces == 0
        ? 0.0
        : trailingSpaces * _getTextPainter(' ', lastText!.style).width;

    final freeSpace = available - line.width + trailingWidth;
    if (freeSpace <= 0) return;

    final extra = freeSpace / internalGaps;
    for (final f in line.fragments) {
      if (f.type == FragmentType.text) f.justifyWordSpacing = extra;
    }
  }

  /// Whether line index [li] is the last line of its containing block — such
  /// lines are not justified (CSS leaves the final line at start alignment).
  bool _isLastLineOfBlock(int li) {
    final line = _lines[li];
    if (line.fragments.isEmpty) return true;
    final block = _nearestBlockAncestor(line.fragments.first.sourceNode);
    if (li + 1 >= _lines.length) return true;
    final next = _lines[li + 1];
    if (next.fragments.isEmpty) return true;
    return _nearestBlockAncestor(next.fragments.first.sourceNode) != block;
  }

  /// Whether [line] ends in a forced `<br>` break (its final line is not
  /// justified, same as a block's last line).
  bool _lineEndsInForcedBreak(LineInfo line) {
    for (var i = line.fragments.length - 1; i >= 0; i--) {
      final f = line.fragments[i];
      if (f.type == FragmentType.lineBreak) return true;
      if (f.type == FragmentType.text && (f.text?.trim().isEmpty ?? true)) {
        continue; // skip trailing whitespace
      }
      return false;
    }
    return false;
  }

  /// Resolves the CSS `text-align` in effect for [line]. `text-align`
  /// inherits, so every fragment on the line shares the block's value; we
  /// read it from the first fragment. Lines with no fragments default to left.
  HyperTextAlign _lineTextAlign(LineInfo line) {
    if (line.fragments.isEmpty) return HyperTextAlign.left;
    return line.fragments.first.style.textAlign;
  }

  /// Whether the line's block set `text-align` explicitly (vs inheriting the
  /// engine default). Used to decide if an RTL line should override its
  /// default right-packing.
  ///
  /// The line's first fragment is usually a TextNode that *inherited*
  /// text-align, so its own explicit flag is false even when the enclosing
  /// block set it — we walk up to the nearest block ancestor and check there.
  bool _lineTextAlignIsExplicit(LineInfo line) {
    if (line.fragments.isEmpty) return false;
    var node = _nearestBlockAncestor(line.fragments.first.sourceNode);
    // Walk further up while the value is still inherited, so a text-align set
    // on an ancestor block (e.g. a wrapping <div>) also counts.
    while (node != null) {
      if (node.style.isExplicitlySet('text-align')) return true;
      node = node.parent;
    }
    return false;
  }

  /// Nearest block-level ancestor of [node] (itself if it is a [BlockNode]),
  /// used to attribute a line to the block whose `text-indent` it should
  /// consume. Returns null if no block ancestor exists.
  UDTNode? _nearestBlockAncestor(UDTNode node) {
    UDTNode? n = node;
    while (n != null) {
      if (n is BlockNode) return n;
      n = n.parent;
    }
    return null;
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

        // Back to in-flow coordinates. A decoration moves by its own node's
        // shift, not its content's: an outer span's background stays on the
        // line when a relative child inside it moves away.
        final fragmentShift = _displaced[fragment];
        final flowRect = fragmentShift == null
            ? visualRect
            : visualRect.shift(-fragmentShift);

        for (final decoratedNode in decoratedNodes) {
          final rangeEntry = decoratedRanges[decoratedNode];
          if (rangeEntry == null) continue;
          final (style, _, _) = rangeEntry;
          final padding = style.padding;
          final nodeRect =
              flowRect.shift(_relativeShifts[decoratedNode] ?? Offset.zero);
          final expandedRect = Rect.fromLTWH(
            nodeRect.left - padding.left,
            nodeRect.top - padding.top,
            nodeRect.width + padding.left + padding.right,
            nodeRect.height + padding.top + padding.bottom,
          );

          final list = rectsMap[decoratedNode]!;
          if (list.isNotEmpty) {
            final last = list.last;
            // OPTIMIZATION: Merge rects on the same line if they are adjacent or overlapping.
            // This drastically reduces the number of Rect objects and draw calls.
            if ((last.top - expandedRect.top).abs() < 0.1 &&
                (last.bottom - expandedRect.bottom).abs() < 0.1 &&
                expandedRect.left <= last.right + 1.0) {
              list[list.length - 1] = last.expandToInclude(expandedRect);
              continue;
            }
          }
          list.add(expandedRect);
        }
      }
    }

    // Create decorations
    for (final entry in decoratedRanges.entries) {
      final node = entry.key;
      final (style, _, _) = entry.value;
      final rects = rectsMap[node] ?? [];
      if (rects.isNotEmpty) {
        final moved = (_relativeShifts[node] ?? Offset.zero) != Offset.zero;
        if (moved) _hasMovedContent = true;
        _inlineDecorations.add(_InlineDecoration(
          node: node,
          rects: rects,
          moved: moved,
          style: _InlineDecorationStyle(
            backgroundColor: style.backgroundColor,
            backgroundGradient: style.backgroundGradient,
            borderColor: style.borderColor,
            borderWidth: style.borderWidth.top,
            borderRadius: style.borderRadius,
            boxShadow: style.boxShadow,
            filter: style.filter,
            backdropFilter: style.backdropFilter,
          ),
        ));
      }
    }
  }

  /// Step 6: Build character mapping for selection (optimized)
  void _buildCharacterMapping() {
    _lineStartOffsets.clear();
    // _totalCharacterCount is already computed in _ensureFragments

    // Build per-line start offsets for O(log N) selection hit-testing.
    // _lineStartOffsets[i] = cumulative char count before line i.
    for (final line in _lines) {
      int? lineStart;
      for (final frag in line.fragments) {
        if ((frag.type == FragmentType.text ||
                frag.type == FragmentType.ruby) &&
            frag.text != null) {
          lineStart = frag.globalOffset;
          break;
        }
      }
      _lineStartOffsets.add(lineStart ??
          (_lineStartOffsets.isNotEmpty ? _lineStartOffsets.last : 0));
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
          final detailsWidth = fragment.measuredSize?.width ?? _maxWidth;
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
            final detailsWidth = fragment.measuredSize?.width ?? _maxWidth;
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

      if (parentData.fragment != null) {
        child = parentData.nextSibling;
        continue;
      }

      if (unlinkedFragmentIndex < unlinkedFragments.length) {
        final fragment = unlinkedFragments[unlinkedFragmentIndex];
        parentData.fragment = fragment;

        if (fragment is _FloatFragment) {
          parentData.isFloat = true;
          parentData.floatDirection = fragment.floatDirection;
        }
        unlinkedFragmentIndex++;
      } else {
        // FIX: Log mismatch instead of silent failure
        assert(() {
          debugPrint(
              '[HyperRender] Layout Warning: More child widgets than fragments. '
              'Node: ${parentData.sourceNode?.tagName}');
          return true;
        }());
      }

      child = parentData.nextSibling;
    }

    // Check for the opposite case: more fragments than widgets
    // It is valid for `unlinkedFragments.length > unlinkedFragmentIndex` if the
    // Widget builder (HyperRenderWidget) intentionally dropped an invalid node
    // (e.g., an <img> with a missing src, or an unhandled plugin node).
    // Therefore, we no longer print a layout warning here.
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
