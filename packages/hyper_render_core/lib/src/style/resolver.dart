import 'package:flutter/painting.dart';

import '../model/computed_style.dart';
import '../model/node.dart';
import '../interfaces/css_parser.dart';
import 'css_rule_index.dart';
import 'design_tokens.dart';

/// CSS Style Resolver
///
/// Resolves styles for UDT nodes following CSS cascade rules.
/// This is the ZERO-DEP version that does NOT parse CSS directly.
/// CSS parsing is done by external CssParserInterface implementations.
///
/// The resolver traverses the tree Top-Down:
/// 1. User Agent Styles - Browser defaults (h1 is bold, etc.)
/// 2. External/Internal CSS - CSS rules from <style> tags
/// 3. Inline Styles - style attribute on elements
/// 4. Inheritance - Properties like color, font-family from parent
///
/// **`!important` support**
///
/// CSS `!important` declarations in `<style>` blocks are honoured: they are
/// applied in a separate pass (step 4) after inline styles, so they win over
/// both normal author rules and inline `style=""` attributes, matching the
/// CSS cascade specification.
class StyleResolver {
  /// Parsed CSS rules (provided externally via CssParserInterface)
  final List<ParsedCssRule> _cssRules = [];

  /// CSS rule index for O(1) lookup by selector type
  final CssRuleIndex _ruleIndex = CssRuleIndex();

  /// Get parsed CSS rules (for debugging)
  List<ParsedCssRule> get cssRules => List.unmodifiable(_cssRules);

  /// Get CSS index statistics (for performance monitoring)
  CssIndexStats get indexStats => _ruleIndex.getStats();

  /// Parse CSS and add it to the rule index
  void parseCss(String css) {
    if (css.isEmpty) return;
    
    final parser = CssRuleIndex.parser ?? const SimpleInlineStyleParser();
    final rules = parser.parseStylesheet(css);
    if (rules.isNotEmpty) {
      addCssRules(rules);
    }
  }

  /// User agent (default) styles
  static final Map<String, ComputedStyle> _userAgentStyles = {
    'h1': ComputedStyle(
      display: DisplayType.block,
      fontSize: DesignTokens.h1FontSize,
      fontWeight: DesignTokens.h1FontWeight,
      margin: EdgeInsets.symmetric(vertical: DesignTokens.h1MarginTop),
      lineHeight: 1.3, // Tighter line height for large headings
    ),
    'h2': ComputedStyle(
      display: DisplayType.block,
      fontSize: DesignTokens.h2FontSize,
      fontWeight: DesignTokens.h2FontWeight,
      margin: EdgeInsets.symmetric(vertical: DesignTokens.h2MarginTop),
      lineHeight: 1.35,
    ),
    'h3': ComputedStyle(
      display: DisplayType.block,
      fontSize: DesignTokens.h3FontSize,
      fontWeight: DesignTokens.h3FontWeight,
      margin: EdgeInsets.symmetric(vertical: DesignTokens.h3MarginTop),
      lineHeight: 1.4,
    ),
    'h4': ComputedStyle(
      display: DisplayType.block,
      fontSize: DesignTokens.h4FontSize,
      fontWeight: DesignTokens.h4FontWeight,
      margin: EdgeInsets.symmetric(vertical: DesignTokens.h4MarginTop),
      lineHeight: 1.45,
    ),
    'h5': ComputedStyle(
      display: DisplayType.block,
      fontSize: DesignTokens.h5FontSize,
      fontWeight: DesignTokens.h5FontWeight,
      margin: EdgeInsets.symmetric(vertical: DesignTokens.h5MarginTop),
      lineHeight: 1.5,
    ),
    'h6': ComputedStyle(
      display: DisplayType.block,
      fontSize: DesignTokens.h6FontSize,
      fontWeight: DesignTokens.h6FontWeight,
      margin: EdgeInsets.symmetric(vertical: DesignTokens.h6MarginTop),
      lineHeight: 1.5,
    ),
    'p': ComputedStyle(
      display: DisplayType.block,
      margin: EdgeInsets.symmetric(vertical: DesignTokens.space2),
      lineHeight: 1.7, // Increased from default 1.5 for better readability
    ),
    'div': ComputedStyle(display: DisplayType.block),
    'span': ComputedStyle(display: DisplayType.inline),
    'strong': ComputedStyle(fontWeight: FontWeight.bold),
    'b': ComputedStyle(fontWeight: FontWeight.bold),
    'em': ComputedStyle(fontStyle: FontStyle.italic),
    'i': ComputedStyle(fontStyle: FontStyle.italic),
    'u': ComputedStyle(textDecoration: TextDecoration.underline),
    's': ComputedStyle(textDecoration: TextDecoration.lineThrough),
    'del': ComputedStyle(textDecoration: TextDecoration.lineThrough),
    'a': ComputedStyle(
      color: const Color(0xFF1976D2), // Material Blue 700
      textDecoration: TextDecoration.underline,
    ),
    'hr': ComputedStyle(
      display: DisplayType.block,
      margin: EdgeInsets.symmetric(vertical: DesignTokens.space2),
      borderWidth: const EdgeInsets.only(top: 1),
      borderColor: DesignTokens.dividerColor,
    ),
    'mark': ComputedStyle(
      backgroundColor: DesignTokens.markBackground,
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space1, // 8px - comfortable spacing
        vertical: DesignTokens.space0_5, // 4px
      ),
    ),
    'sub': ComputedStyle(
      fontSize: DesignTokens.bodySmallFontSize,
      verticalAlign: HyperVerticalAlign.bottom,
    ),
    'sup': ComputedStyle(
      fontSize: DesignTokens.bodySmallFontSize,
      verticalAlign: HyperVerticalAlign.top,
    ),
    'small': ComputedStyle(
      fontSize: DesignTokens.bodySmallFontSize,
    ),
    'kbd': ComputedStyle(
      fontFamily: 'monospace',
      backgroundColor: DesignTokens.codeBackground,
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space1, // 8px - comfortable spacing
        vertical: DesignTokens.space0_5, // 4px
      ),
      borderWidth: const EdgeInsets.all(1),
      borderColor: DesignTokens.tableBorder,
      borderRadius: DesignTokens.radius(DesignTokens.radiusSmall),
      fontSize: 13.0,
    ),
    'code': ComputedStyle(
      fontFamily: DesignTokens.codeFontFamily,
      backgroundColor: DesignTokens.codeBackground,
      color: DesignTokens.codeText,
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space0_5, // 4px - comfortable spacing for inline code
        vertical: DesignTokens.space0_5 / 2, // 2px
      ),
      borderRadius: DesignTokens.radius(DesignTokens.radiusSmall),
      fontSize: DesignTokens.codeFontSize,
    ),
    'pre': ComputedStyle(
      display: DisplayType.block,
      fontFamily: DesignTokens.codeFontFamily,
      whiteSpace: 'pre',
      backgroundColor: DesignTokens.codeBlockBackground,
      color: DesignTokens.codeBlockText,
      padding: EdgeInsets.all(DesignTokens.space2),
      margin: EdgeInsets.symmetric(vertical: DesignTokens.space2),  // Increased from space1_5
      borderRadius: DesignTokens.radius(DesignTokens.radiusMedium),
      fontSize: DesignTokens.codeFontSize, // 14px for better code readability
      lineHeight: DesignTokens.codeLineHeight / DesignTokens.codeFontSize, // 1.43 (20/14)
    ),
    'blockquote': ComputedStyle(
      display: DisplayType.block,
      margin: EdgeInsets.fromLTRB(0, DesignTokens.space2, 0, DesignTokens.space2),
      padding: EdgeInsets.fromLTRB(DesignTokens.space3, DesignTokens.space2, DesignTokens.space3, DesignTokens.space2),  // More generous padding
      borderWidth: const EdgeInsets.only(left: 4), // Thicker left border for emphasis
      borderColor: DesignTokens.quoteBorder,
      backgroundColor: DesignTokens.quoteBackground,
      fontStyle: FontStyle.italic, // Italic text for quotes
      lineHeight: 1.75, // Extra generous line height
    ),
    'ul': ComputedStyle(
      display: DisplayType.block,
      padding: EdgeInsets.only(left: DesignTokens.space5),
      margin: EdgeInsets.symmetric(vertical: DesignTokens.space2),
      lineHeight: 1.7, // Better line height for list items
    ),
    'ol': ComputedStyle(
      display: DisplayType.block,
      padding: EdgeInsets.only(left: DesignTokens.space5),
      margin: EdgeInsets.symmetric(vertical: DesignTokens.space2),
      lineHeight: 1.7,
    ),
    'li': ComputedStyle(
      display: DisplayType.block,
      margin: EdgeInsets.symmetric(vertical: DesignTokens.space1), // Increased from space0_5 for breathing room
    ),
    'table': ComputedStyle(
      display: DisplayType.table,
      margin: EdgeInsets.symmetric(vertical: DesignTokens.space2),
      borderWidth: const EdgeInsets.all(1),
      borderColor: DesignTokens.quoteBorder,
    ),
    'thead': ComputedStyle(
      display: DisplayType.block,
      backgroundColor: DesignTokens.tableHeaderBackground,
    ),
    'tr': ComputedStyle(
      display: DisplayType.tableRow,
      borderWidth: const EdgeInsets.only(bottom: 1),
      borderColor: DesignTokens.tableBorder,
    ),
    'td': ComputedStyle(
      display: DisplayType.tableCell,
      padding: EdgeInsets.all(DesignTokens.space2), // Increased from space1_5 for more breathing room
      borderWidth: const EdgeInsets.all(1),
      borderColor: DesignTokens.tableBorder,
    ),
    'th': ComputedStyle(
      display: DisplayType.tableCell,
      fontWeight: FontWeight.bold,
      padding: EdgeInsets.all(DesignTokens.space2), // Increased from space1_5
      backgroundColor: DesignTokens.tableHeaderBackground,
      borderWidth: const EdgeInsets.all(1),
      borderColor: DesignTokens.quoteBorder,
    ),
  };

  /// Add pre-parsed CSS rules (from CssParserInterface)
  ///
  /// Use this method to add CSS rules that have been parsed by an external
  /// CSS parser implementation (e.g., from hyper_render_html package).
  void addCssRules(List<ParsedCssRule> rules) {
    _cssRules.addAll(rules);
    // Sort rules by specificity (lower first, so higher specificity wins)
    _cssRules.sort((a, b) => a.specificity.compareTo(b.specificity));

    // Rebuild index for fast lookup
    _rebuildIndex();
  }

  /// Clear all CSS rules
  void clearCssRules() {
    _cssRules.clear();
    _ruleIndex.clear();
  }

  /// Rebuild the CSS rule index
  ///
  /// Called after adding or modifying rules to update the index
  void _rebuildIndex() {
    _ruleIndex.clear();
    for (final rule in _cssRules) {
      _ruleIndex.addRule(rule);
    }
  }

  /// Resolve styles for entire document tree
  ///
  /// This method traverses the tree and computes final styles for each node,
  /// following the CSS cascade.
  void resolveStyles(DocumentNode document, {ComputedStyle? baseStyle}) {
    final base = baseStyle ?? ComputedStyle();
    _resolveNode(document, base);
  }

  /// Resolve styles for a single node and its children
  void _resolveNode(UDTNode node, ComputedStyle parentStyle) {
    // Start with default style
    ComputedStyle style = ComputedStyle();

    // Get parent font size for em/rem calculations
    final parentFontSize = parentStyle.fontSize;

    // 1. Apply user agent styles
    final tagName = node.tagName?.toLowerCase();
    if (tagName != null && _userAgentStyles.containsKey(tagName)) {
      style = _mergeStyles(style, _userAgentStyles[tagName]!);
    }

    // Special case: <code> inside <pre> should NOT have inline code styling
    if (tagName == 'code' && node.parent?.tagName?.toLowerCase() == 'pre') {
      style.backgroundColor = null;
      style.padding = EdgeInsets.zero;
    }

    // 2. Apply CSS rules (sorted by specificity)
    // ⚡ PERFORMANCE: Use index to get only relevant rules (10x faster!)
    final candidates = _ruleIndex.getCandidates(node);
    for (final rule in candidates) {
      if (_matchesSelector(node, rule.selector)) {
        style = _applyDeclarations(
          style,
          rule.declarations,
          parentFontSize: parentFontSize,
          inheritedCustomProps: parentStyle.customProperties,
        );
      }
    }

    // 3. Apply inline styles
    final inlineStyle = node.attributes['style'];
    if (inlineStyle != null && inlineStyle.isNotEmpty) {
      style = _parseInlineStyle(
        style,
        inlineStyle,
        parentFontSize: parentFontSize,
        inheritedCustomProps: parentStyle.customProperties,
      );
    }

    // 4. Apply !important declarations (win over inline styles, per CSS spec)
    for (final rule in candidates) {
      if (rule.importantDeclarations.isNotEmpty &&
          _matchesSelector(node, rule.selector)) {
        style = _applyDeclarations(
          style,
          rule.importantDeclarations,
          parentFontSize: parentFontSize,
          inheritedCustomProps: parentStyle.customProperties,
        );
      }
    }

    // 5. Inherit from parent
    _applyInheritance(style, parentStyle);

    // Store computed style on node
    node.style = style;

    // Resolve children
    for (final child in node.children) {
      _resolveNode(child, style);
    }
  }

  /// Check if a node matches a CSS selector
  bool _matchesSelector(UDTNode node, String selector) {
    selector = selector.trim();

    // Comma-separated selector group: `h1, h2, h3` — check each part independently.
    // Must be checked BEFORE the space/combinator checks because `"div, p"` contains
    // a space and would otherwise be mis-parsed as a descendant selector.
    if (selector.contains(',')) {
      return selector.split(',').any((s) => _matchesSelector(node, s.trim()));
    }

    // Child selector: `parent > child`
    if (selector.contains(' > ')) {
      return _matchesChildSelector(node, selector);
    }

    // Adjacent sibling selector: `prev + next`
    if (selector.contains(' + ')) {
      return _matchesAdjacentSiblingSelector(node, selector);
    }

    // General sibling selector: `prev ~ sibling`
    if (selector.contains(' ~ ')) {
      return _matchesGeneralSiblingSelector(node, selector);
    }

    // Descendant selector: `ancestor descendant`
    if (selector.contains(' ')) {
      return _matchesDescendantSelector(node, selector);
    }

    // Simple selector
    return _matchesSimpleSelector(node, selector);
  }

  bool _matchesSimpleSelector(UDTNode node, String selector) {
    selector = selector.trim();

    if (selector == '*') return true;

    if (selector.startsWith('#') && !selector.contains('.')) {
      return node.cssId == selector.substring(1);
    }

    if (selector.startsWith('.') && !selector.contains('#')) {
      return _matchesClassSelector(node, selector);
    }

    if (!selector.contains('.') && !selector.contains('#')) {
      return selector == node.tagName;
    }

    return _matchesCombinedSelector(node, selector);
  }

  bool _matchesClassSelector(UDTNode node, String selector) {
    final classes = selector.split('.').where((c) => c.isNotEmpty).toList();
    if (classes.isEmpty) return false;

    for (final className in classes) {
      if (!node.classList.contains(className)) {
        return false;
      }
    }
    return true;
  }

  bool _matchesCombinedSelector(UDTNode node, String selector) {
    String? elementPart;
    String? idPart;
    List<String> classParts = [];

    final idMatch = RegExp(r'#([a-zA-Z_-][a-zA-Z0-9_-]*)').firstMatch(selector);
    if (idMatch != null) {
      idPart = idMatch.group(1);
    }

    final classMatches = RegExp(r'\.([a-zA-Z0-9_-]+)').allMatches(selector);
    for (final match in classMatches) {
      classParts.add(match.group(1)!);
    }

    final elementMatch = RegExp(r'^([a-zA-Z0-9]+)').firstMatch(selector);
    if (elementMatch != null) {
      elementPart = elementMatch.group(1);
    }

    if (elementPart != null && node.tagName?.toLowerCase() != elementPart.toLowerCase()) {
      return false;
    }

    if (idPart != null && node.cssId != idPart) {
      return false;
    }

    final nodeClasses = node.classList;
    for (final className in classParts) {
      if (!nodeClasses.contains(className)) {
        return false;
      }
    }

    return elementPart != null || idPart != null || classParts.isNotEmpty;
  }

  bool _matchesDescendantSelector(UDTNode node, String selector) {
    final parts = selector.split(RegExp(r'\s+'));
    if (parts.length < 2) return false;

    final descendantSelector = parts.last;
    final ancestorSelector = parts.sublist(0, parts.length - 1).join(' ');

    if (!_matchesSimpleSelector(node, descendantSelector)) {
      return false;
    }

    UDTNode? ancestor = node.parent;
    while (ancestor != null) {
      if (_matchesSelector(ancestor, ancestorSelector)) {
        return true;
      }
      ancestor = ancestor.parent;
    }

    return false;
  }

  bool _matchesChildSelector(UDTNode node, String selector) {
    final parts = selector.split(' > ');
    if (parts.length < 2) return false;

    // Node must match the last (child) part
    if (!_matchesSimpleSelector(node, parts.last.trim())) return false;

    // Parent must match the rest (supports arbitrary depth)
    if (node.parent == null) return false;
    final parentSelector = parts.sublist(0, parts.length - 1).join(' > ');
    return _matchesSelector(node.parent!, parentSelector);
  }

  bool _matchesAdjacentSiblingSelector(UDTNode node, String selector) {
    final parts = selector.split(' + ');
    if (parts.length != 2) return false;

    final prevSelector = parts[0].trim();
    final nextSelector = parts[1].trim();

    if (!_matchesSimpleSelector(node, nextSelector)) {
      return false;
    }

    final prevSibling = _getPreviousSibling(node);
    if (prevSibling == null) return false;

    return _matchesSimpleSelector(prevSibling, prevSelector);
  }

  bool _matchesGeneralSiblingSelector(UDTNode node, String selector) {
    final parts = selector.split(' ~ ');
    if (parts.length != 2) return false;

    final prevSelector = parts[0].trim();
    final siblingSelector = parts[1].trim();

    if (!_matchesSimpleSelector(node, siblingSelector)) {
      return false;
    }

    final parent = node.parent;
    if (parent == null) return false;

    final nodeIndex = parent.children.indexOf(node);
    for (int i = 0; i < nodeIndex; i++) {
      if (_matchesSimpleSelector(parent.children[i], prevSelector)) {
        return true;
      }
    }

    return false;
  }

  UDTNode? _getPreviousSibling(UDTNode node) {
    final parent = node.parent;
    if (parent == null) return null;

    final index = parent.children.indexOf(node);
    if (index <= 0) return null;

    return parent.children[index - 1];
  }

  ComputedStyle _mergeStyles(ComputedStyle base, ComputedStyle override) {
    final result = ComputedStyle(
      width: override.width ?? base.width,
      height: override.height ?? base.height,
      margin: override.margin != EdgeInsets.zero ? override.margin : base.margin,
      padding: override.padding != EdgeInsets.zero ? override.padding : base.padding,
      borderWidth: override.borderWidth != EdgeInsets.zero
          ? override.borderWidth
          : base.borderWidth,
      borderColor: override.borderColor ?? base.borderColor,
      borderRadius: override.borderRadius ?? base.borderRadius,
      color: override.color,
      fontSize: override.fontSize,
      fontWeight: override.fontWeight,
      fontStyle: override.fontStyle,
      fontFamily: override.fontFamily ?? base.fontFamily,
      textDecoration: override.textDecoration ?? base.textDecoration,
      lineHeight: override.lineHeight ?? base.lineHeight,
      textAlign: override.textAlign,
      backgroundColor: override.backgroundColor ?? base.backgroundColor,
      display: override.display,
      opacity: override.opacity,
    );

    if (override.fontSize != ComputedStyle.defaultStyle.fontSize) {
      result.markExplicitlySet('font-size');
    }
    if (override.fontWeight != ComputedStyle.defaultStyle.fontWeight) {
      result.markExplicitlySet('font-weight');
    }
    if (override.fontStyle != ComputedStyle.defaultStyle.fontStyle) {
      result.markExplicitlySet('font-style');
    }
    if (override.color != ComputedStyle.defaultStyle.color) {
      result.markExplicitlySet('color');
    }
    if (override.margin != EdgeInsets.zero) {
      result.markExplicitlySet('margin');
    }
    if (override.padding != EdgeInsets.zero) {
      result.markExplicitlySet('padding');
    }
    if (override.display != ComputedStyle.defaultStyle.display) {
      result.markExplicitlySet('display');
    }
    if (override.textDecoration != null) {
      result.markExplicitlySet('text-decoration');
    }

    return result;
  }

  ComputedStyle _applyDeclarations(
    ComputedStyle style,
    Map<String, String> declarations, {
    double? parentFontSize,
    Map<String, String>? inheritedCustomProps,
  }) {
    for (final entry in declarations.entries) {
      style = _applySingleDeclaration(
        style,
        entry.key,
        entry.value,
        parentFontSize: parentFontSize,
        inheritedCustomProps: inheritedCustomProps,
      );
    }
    return style;
  }

  ComputedStyle _applySingleDeclaration(
    ComputedStyle style,
    String property,
    String value, {
    double? parentFontSize,
    Map<String, String>? inheritedCustomProps,
  }) {
    // CSS Custom Properties (--name: value)
    if (property.startsWith('--')) {
      style.customProperties[property] = value;
      return style;
    }

    // Resolve var() and calc() references before processing
    value = _resolveCssValue(value, style.customProperties, inheritedCustomProps);

    switch (property.toLowerCase()) {
      case 'color':
        final color = _parseColor(value);
        if (color != null) {
          style.color = color;
          style.markExplicitlySet('color');
        }
        break;

      case 'background':
      case 'background-color':
        final color = _parseColor(value);
        if (color != null) {
          style.backgroundColor = color;
          style.markExplicitlySet('background-color');
        }
        break;

      case 'font-size':
        final size = _parseFontSize(value, parentFontSize: parentFontSize);
        if (size != null) {
          style.fontSize = size;
          style.markExplicitlySet('font-size');
        }
        break;

      case 'font-weight':
        final weight = _parseFontWeight(value);
        if (weight != null) {
          style.fontWeight = weight;
          style.markExplicitlySet('font-weight');
        }
        break;

      case 'font-style':
        final fontStyle = _parseFontStyle(value);
        if (fontStyle != null) {
          style.fontStyle = fontStyle;
          style.markExplicitlySet('font-style');
        }
        break;

      case 'font-family':
        style.fontFamily = value.trim().replaceAll('"', '').replaceAll("'", '');
        style.markExplicitlySet('font-family');
        break;

      case 'text-decoration':
        final decoration = _parseTextDecoration(value);
        if (decoration != null) {
          style.textDecoration = decoration;
          style.markExplicitlySet('text-decoration');
        }
        break;

      case 'line-height':
        final lineHeight = _parseLineHeight(value, parentFontSize: parentFontSize);
        if (lineHeight != null) {
          style.lineHeight = lineHeight;
          style.markExplicitlySet('line-height');
        }
        break;

      case 'text-align':
        final align = _parseTextAlign(value);
        if (align != null) {
          style.textAlign = align;
          style.markExplicitlySet('text-align');
        }
        break;

      case 'margin':
        final margin = _parseEdgeInsets(value, currentFontSize: parentFontSize);
        if (margin != null) {
          style.margin = margin;
          style.markExplicitlySet('margin');
        }
        break;

      case 'padding':
        final padding = _parseEdgeInsets(value, currentFontSize: parentFontSize);
        if (padding != null) {
          style.padding = padding;
          style.markExplicitlySet('padding');
        }
        break;

      case 'border-radius':
        final radius = _parseBorderRadius(value);
        if (radius != null) {
          style.borderRadius = radius;
          style.markExplicitlySet('border-radius');
        }
        break;

      case 'width':
        final width = _parseLength(value, currentFontSize: parentFontSize);
        if (width != null) {
          style.width = width;
          style.markExplicitlySet('width');
        }
        break;

      case 'height':
        final height = _parseLength(value, currentFontSize: parentFontSize);
        if (height != null) {
          style.height = height;
          style.markExplicitlySet('height');
        }
        break;

      case 'display':
        final display = _parseDisplay(value);
        if (display != null) {
          style.display = display;
          style.markExplicitlySet('display');
        }
        break;

      case 'opacity':
        final opacity = double.tryParse(value);
        if (opacity != null) {
          style.opacity = opacity.clamp(0.0, 1.0);
          style.markExplicitlySet('opacity');
        }
        break;

      case 'float':
        final floatValue = _parseFloat(value);
        if (floatValue != null) {
          style.float = floatValue;
          style.markExplicitlySet('float');
        }
        break;

      case 'clear':
        final clearValue = _parseClear(value);
        if (clearValue != null) {
          style.clear = clearValue;
          style.markExplicitlySet('clear');
        }
        break;

      // ============================================
      // CSS Grid Properties
      // ============================================

      case 'grid-template-columns':
        style.gridTemplateColumns = value.trim();
        style.markExplicitlySet('grid-template-columns');
        break;

      case 'grid-template-rows':
        style.gridTemplateRows = value.trim();
        style.markExplicitlySet('grid-template-rows');
        break;

      case 'grid-auto-flow':
        style.gridAutoFlow = value.trim().toLowerCase();
        style.markExplicitlySet('grid-auto-flow');
        break;

      case 'grid-column':
        final colParsed = _parseGridLine(value);
        style.gridColumnStart = colParsed.$1;
        style.gridColumnEnd = colParsed.$2;
        style.gridColumnSpan = colParsed.$3;
        style.markExplicitlySet('grid-column');
        break;

      case 'grid-row':
        final rowParsed = _parseGridLine(value);
        style.gridRowStart = rowParsed.$1;
        style.gridRowEnd = rowParsed.$2;
        style.gridRowSpan = rowParsed.$3;
        style.markExplicitlySet('grid-row');
        break;
    }

    return style;
  }

  /// Splits an inline style string by `;` while respecting parentheses and
  /// brackets, so that `color: rgb(1,2,3); background: url(a;b)` is tokenized
  /// correctly into two declarations instead of four.
  List<String> _tokenizeInlineDeclarations(String css) {
    final result = <String>[];
    int depth = 0;
    int start = 0;
    for (int i = 0; i < css.length; i++) {
      final c = css[i];
      if (c == '(' || c == '[') {
        depth++;
      } else if (c == ')' || c == ']') {
        if (depth > 0) depth--;
      } else if (c == ';' && depth == 0) {
        final decl = css.substring(start, i).trim();
        if (decl.isNotEmpty) result.add(decl);
        start = i + 1;
      }
    }
    final last = css.substring(start).trim();
    if (last.isNotEmpty) result.add(last);
    return result;
  }

  ComputedStyle _parseInlineStyle(
    ComputedStyle style,
    String inlineStyle, {
    double? parentFontSize,
    Map<String, String>? inheritedCustomProps,
  }) {
    final declarations = _tokenizeInlineDeclarations(inlineStyle);
    for (final decl in declarations) {
      final colonIdx = decl.indexOf(':');
      if (colonIdx > 0) {
        final property = decl.substring(0, colonIdx).trim();
        final value = decl.substring(colonIdx + 1).trim();
        if (property.isNotEmpty && value.isNotEmpty) {
          style = _applySingleDeclaration(
            style,
            property,
            value,
            parentFontSize: parentFontSize,
            inheritedCustomProps: inheritedCustomProps,
          );
        }
      }
    }
    return style;
  }

  void _applyInheritance(ComputedStyle style, ComputedStyle parentStyle) {
    if (!style.isExplicitlySet('color')) {
      style.color = parentStyle.color;
    }
    if (!style.isExplicitlySet('font-size')) {
      style.fontSize = parentStyle.fontSize;
    }
    if (!style.isExplicitlySet('font-weight')) {
      style.fontWeight = parentStyle.fontWeight;
    }
    if (!style.isExplicitlySet('font-style')) {
      style.fontStyle = parentStyle.fontStyle;
    }
    if (!style.isExplicitlySet('font-family')) {
      style.fontFamily = parentStyle.fontFamily;
    }
    if (!style.isExplicitlySet('line-height')) {
      style.lineHeight = parentStyle.lineHeight;
    }
    if (!style.isExplicitlySet('text-align')) {
      style.textAlign = parentStyle.textAlign;
    }
    style.whiteSpace ??= parentStyle.whiteSpace;

    // CSS custom properties inherit — always merge parent into child (child overrides parent)
    if (parentStyle.customProperties.isNotEmpty) {
      style.customProperties = {...parentStyle.customProperties, ...style.customProperties};
    }
  }

  // ============================================
  // CSS Value Preprocessor (var() and calc())
  // ============================================

  String _resolveCssValue(
    String value,
    Map<String, String> localCustomProps,
    Map<String, String>? inheritedCustomProps,
  ) {
    if (!value.contains('var(') && !value.contains('calc(')) return value;
    final allProps = <String, String>{};
    if (inheritedCustomProps != null) allProps.addAll(inheritedCustomProps);
    allProps.addAll(localCustomProps);
    value = _resolveVarReferences(value, allProps);
    if (value.contains('calc(')) {
      value = _evaluateCalcInValue(value);
    }
    return value;
  }

  String _resolveVarReferences(String value, Map<String, String> customProps) {
    // Resolve from innermost outward: [^()]+ matches only leaf var() calls
    for (int i = 0; i < 10; i++) {
      final resolved = value.replaceAllMapped(
        RegExp(r'var\(\s*(--[\w-]+)\s*(?:,\s*([^()]+))?\s*\)'),
        (match) {
          final propName = match.group(1)!;
          final fallback = match.group(2)?.trim() ?? '';
          return customProps[propName] ?? fallback;
        },
      );
      if (resolved == value) break;
      value = resolved;
    }
    return value;
  }

  String _evaluateCalcInValue(String value) {
    return value.replaceAllMapped(
      RegExp(r'calc\(([^)]+)\)'),
      (match) {
        final result = _evaluateCalcExpr(match.group(1)!);
        if (result != null) return '${result}px';
        return match.group(0)!;
      },
    );
  }

  double? _evaluateCalcExpr(String expr) {
    expr = expr.trim();
    final tokenPattern = RegExp(r'(-?[\d.]+)(px|em|rem|%)?\s*|([+\-*/])');
    final tokens = tokenPattern.allMatches(expr).toList();
    if (tokens.isEmpty) return null;
    final values = <double>[];
    final operators = <String>[];
    for (final token in tokens) {
      final numStr = token.group(1);
      final unit = token.group(2) ?? '';
      final op = token.group(3);
      if (numStr != null) {
        final num = double.tryParse(numStr);
        if (num == null) return null;
        double px;
        switch (unit) {
          case 'px': case '': px = num; break;
          case 'em': case 'rem': px = num * 16.0; break;
          case '%': return null;
          default: px = num;
        }
        values.add(px);
      } else if (op != null) {
        operators.add(op);
      }
    }
    if (values.isEmpty || values.length != operators.length + 1) return null;
    final vals = List<double>.from(values);
    final ops = List<String>.from(operators);
    int i = 0;
    while (i < ops.length) {
      if (ops[i] == '*') {
        vals[i] *= vals[i + 1]; vals.removeAt(i + 1); ops.removeAt(i);
      } else if (ops[i] == '/') {
        if (vals[i + 1] == 0) return null;
        vals[i] /= vals[i + 1]; vals.removeAt(i + 1); ops.removeAt(i);
      } else { i++; }
    }
    double result = vals[0];
    for (int j = 0; j < ops.length; j++) {
      result += ops[j] == '+' ? vals[j + 1] : -vals[j + 1];
    }
    return result;
  }

  (int, int, int) _parseGridLine(String value) {
    value = value.trim().toLowerCase();
    if (value == 'auto') return (0, 0, 1);
    final spanMatch = RegExp(r'^span\s+(\d+)$').firstMatch(value);
    if (spanMatch != null) {
      return (0, 0, int.tryParse(spanMatch.group(1)!) ?? 1);
    }
    if (value.contains('/')) {
      final parts = value.split('/').map((p) => p.trim()).toList();
      if (parts.length == 2) {
        final start = int.tryParse(parts[0]) ?? 0;
        final spanMatch2 = RegExp(r'^span\s+(\d+)$').firstMatch(parts[1]);
        if (spanMatch2 != null) {
          return (start, 0, int.tryParse(spanMatch2.group(1)!) ?? 1);
        }
        final end = int.tryParse(parts[1]) ?? 0;
        return (start, end, end > start ? end - start : 1);
      }
    }
    final n = int.tryParse(value) ?? 0;
    return (n, 0, 1);
  }

  // ============================================
  // CSS Value Parsers
  // ============================================

  static const double rootFontSize = 16.0;

  Color? _parseColor(String value) {
    var colorStr = value.trim().toLowerCase();
    if (colorStr.isEmpty || colorStr == 'transparent') return const Color(0x00000000);
    if (colorStr == 'inherit') return null;

    // Handle named colors
    if (_namedColors.containsKey(colorStr)) {
      return _namedColors[colorStr];
    }

    // Handle Hex colors
    if (colorStr.startsWith('#')) {
      colorStr = colorStr.substring(1);
    }

    try {
      if (colorStr.length == 3) {
        final r = colorStr[0] + colorStr[0];
        final g = colorStr[1] + colorStr[1];
        final b = colorStr[2] + colorStr[2];
        return Color(int.parse('FF$r$g$b', radix: 16));
      } else if (colorStr.length == 4) {
        final r = colorStr[0] + colorStr[0];
        final g = colorStr[1] + colorStr[1];
        final b = colorStr[2] + colorStr[2];
        final a = colorStr[3] + colorStr[3];
        return Color(int.parse('$a$r$g$b', radix: 16));
      } else if (colorStr.length == 6) {
        return Color(int.parse('FF$colorStr', radix: 16));
      } else if (colorStr.length == 8) {
        // ARGB or RGBA? CSS standard is RRGGBBAA. Flutter is AARRGGBB.
        final r = colorStr.substring(0, 2);
        final g = colorStr.substring(2, 4);
        final b = colorStr.substring(4, 6);
        final a = colorStr.substring(6, 8);
        return Color(int.parse('$a$r$g$b', radix: 16));
      }
    } catch (_) {
      return null;
    }

    final rgbMatch = RegExp(r'rgb\((\d+),\s*(\d+),\s*(\d+)\)').firstMatch(value);
    if (rgbMatch != null) {
      final r = int.parse(rgbMatch.group(1)!).clamp(0, 255);
      final g = int.parse(rgbMatch.group(2)!).clamp(0, 255);
      final b = int.parse(rgbMatch.group(3)!).clamp(0, 255);
      return Color.fromARGB(255, r, g, b);
    }

    final rgbaMatch = RegExp(r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*(-?[\d.]+)\)').firstMatch(value);
    if (rgbaMatch != null) {
      final r = int.parse(rgbaMatch.group(1)!).clamp(0, 255);
      final g = int.parse(rgbaMatch.group(2)!).clamp(0, 255);
      final b = int.parse(rgbaMatch.group(3)!).clamp(0, 255);
      final alpha = (double.tryParse(rgbaMatch.group(4)!) ?? 1.0).clamp(0.0, 1.0);
      return Color.fromARGB((alpha * 255).round(), r, g, b);
    }

    return _namedColors[value];
  }

  double? _parseFontSize(String value, {double? parentFontSize}) {
    value = value.trim().toLowerCase();

    if (value.endsWith('px')) {
      return double.tryParse(value.replaceAll('px', ''));
    }
    if (value.endsWith('pt')) {
      final pt = double.tryParse(value.replaceAll('pt', ''));
      return pt != null ? pt * 1.333 : null;
    }
    if (value.endsWith('rem')) {
      final rem = double.tryParse(value.replaceAll('rem', ''));
      return rem != null ? rem * rootFontSize : null;
    }
    if (value.endsWith('em')) {
      final em = double.tryParse(value.replaceAll('em', ''));
      if (em == null) return null;
      return em * (parentFontSize ?? rootFontSize);
    }
    if (value.endsWith('%')) {
      final percent = double.tryParse(value.replaceAll('%', ''));
      if (percent == null) return null;
      return (percent / 100) * (parentFontSize ?? rootFontSize);
    }

    switch (value) {
      case 'xx-small': return 9.0;
      case 'x-small': return 10.0;
      case 'small': return 13.0;
      case 'medium': return 16.0;
      case 'large': return 18.0;
      case 'x-large': return 24.0;
      case 'xx-large': return 32.0;
    }

    return double.tryParse(value);
  }

  FontWeight? _parseFontWeight(String value) {
    value = value.trim().toLowerCase();

    switch (value) {
      case 'normal':
      case '400': return FontWeight.normal;
      case 'bold':
      case '700': return FontWeight.bold;
      case '100': return FontWeight.w100;
      case '200': return FontWeight.w200;
      case '300': return FontWeight.w300;
      case '500': return FontWeight.w500;
      case '600': return FontWeight.w600;
      case '800': return FontWeight.w800;
      case '900': return FontWeight.w900;
      default: return null;
    }
  }

  FontStyle? _parseFontStyle(String value) {
    switch (value.trim().toLowerCase()) {
      case 'normal': return FontStyle.normal;
      case 'italic': return FontStyle.italic;
      default: return null;
    }
  }

  TextDecoration? _parseTextDecoration(String value) {
    switch (value.trim().toLowerCase()) {
      case 'none': return TextDecoration.none;
      case 'underline': return TextDecoration.underline;
      case 'overline': return TextDecoration.overline;
      case 'line-through': return TextDecoration.lineThrough;
      default: return null;
    }
  }

  double? _parseLineHeight(String value, {double? parentFontSize}) {
    value = value.trim().toLowerCase();
    if (value == 'normal') return null;
    final multiplier = double.tryParse(value);
    if (multiplier != null) return multiplier;
    final length = _parseLength(value, currentFontSize: parentFontSize);
    if (length != null && parentFontSize != null) {
      return length / parentFontSize;
    }
    return null;
  }

  HyperTextAlign? _parseTextAlign(String value) {
    switch (value.trim().toLowerCase()) {
      case 'left': return HyperTextAlign.left;
      case 'center': return HyperTextAlign.center;
      case 'right': return HyperTextAlign.right;
      case 'justify': return HyperTextAlign.justify;
      default: return null;
    }
  }

  EdgeInsets? _parseEdgeInsets(String value, {double? currentFontSize}) {
    final parts = value.trim().split(RegExp(r'\s+'));
    final values = parts.map((p) => _parseLength(p, currentFontSize: currentFontSize) ?? 0.0).toList();

    switch (values.length) {
      case 1: return EdgeInsets.all(values[0]);
      case 2: return EdgeInsets.symmetric(vertical: values[0], horizontal: values[1]);
      case 3: return EdgeInsets.only(top: values[0], left: values[1], right: values[1], bottom: values[2]);
      case 4: return EdgeInsets.only(top: values[0], right: values[1], bottom: values[2], left: values[3]);
      default: return null;
    }
  }

  double? _parseLength(String value, {double? currentFontSize}) {
    value = value.trim().toLowerCase();

    if (value.endsWith('px')) {
      return double.tryParse(value.replaceAll('px', ''));
    }
    if (value.endsWith('pt')) {
      final pt = double.tryParse(value.replaceAll('pt', ''));
      return pt != null ? pt * 1.333 : null;
    }
    if (value.endsWith('em')) {
      final em = double.tryParse(value.replaceAll('em', ''));
      return em != null ? em * (currentFontSize ?? rootFontSize) : null;
    }
    if (value == '0') return 0;

    return double.tryParse(value);
  }

  BorderRadius? _parseBorderRadius(String value) {
    final length = _parseLength(value);
    if (length != null) {
      return BorderRadius.circular(length);
    }
    return null;
  }

  DisplayType? _parseDisplay(String value) {
    switch (value.trim().toLowerCase()) {
      case 'block': return DisplayType.block;
      case 'inline': return DisplayType.inline;
      case 'inline-block': return DisplayType.inlineBlock;
      case 'flex': return DisplayType.flex;
      case 'grid': return DisplayType.grid;
      case 'none': return DisplayType.none;
      case 'table': return DisplayType.table;
      case 'table-row': return DisplayType.tableRow;
      case 'table-cell': return DisplayType.tableCell;
      default: return null;
    }
  }

  HyperFloat? _parseFloat(String value) {
    switch (value.toLowerCase().trim()) {
      case 'left': return HyperFloat.left;
      case 'right': return HyperFloat.right;
      case 'none': return HyperFloat.none;
      default: return null;
    }
  }

  HyperClear? _parseClear(String value) {
    switch (value.toLowerCase().trim()) {
      case 'left': return HyperClear.left;
      case 'right': return HyperClear.right;
      case 'both': return HyperClear.both;
      case 'none': return HyperClear.none;
      default: return null;
    }
  }

  static const Map<String, Color> _namedColors = {
    // Basic
    'black': Color(0xFF000000),
    'white': Color(0xFFFFFFFF),
    'red': Color(0xFFFF0000),
    'green': Color(0xFF008000),
    'blue': Color(0xFF0000FF),
    'yellow': Color(0xFFFFFF00),
    'cyan': Color(0xFF00FFFF),
    'aqua': Color(0xFF00FFFF),
    'magenta': Color(0xFFFF00FF),
    'fuchsia': Color(0xFFFF00FF),
    'gray': Color(0xFF808080),
    'grey': Color(0xFF808080),
    'orange': Color(0xFFFFA500),
    'purple': Color(0xFF800080),
    'pink': Color(0xFFFFC0CB),
    'transparent': Color(0x00000000),
    'lime': Color(0xFF00FF00),
    'maroon': Color(0xFF800000),
    'navy': Color(0xFF000080),
    'olive': Color(0xFF808000),
    'silver': Color(0xFFC0C0C0),
    'teal': Color(0xFF008080),
    // Extended CSS4 named colors
    'aliceblue': Color(0xFFF0F8FF),
    'antiquewhite': Color(0xFFFAEBD7),
    'aquamarine': Color(0xFF7FFFD4),
    'azure': Color(0xFFF0FFFF),
    'beige': Color(0xFFF5F5DC),
    'bisque': Color(0xFFFFE4C4),
    'blanchedalmond': Color(0xFFFFEBCD),
    'blueviolet': Color(0xFF8A2BE2),
    'brown': Color(0xFFA52A2A),
    'burlywood': Color(0xFFDEB887),
    'cadetblue': Color(0xFF5F9EA0),
    'chartreuse': Color(0xFF7FFF00),
    'chocolate': Color(0xFFD2691E),
    'coral': Color(0xFFFF7F50),
    'cornflowerblue': Color(0xFF6495ED),
    'cornsilk': Color(0xFFFFF8DC),
    'crimson': Color(0xFFDC143C),
    'darkblue': Color(0xFF00008B),
    'darkcyan': Color(0xFF008B8B),
    'darkgoldenrod': Color(0xFFB8860B),
    'darkgray': Color(0xFFA9A9A9),
    'darkgrey': Color(0xFFA9A9A9),
    'darkgreen': Color(0xFF006400),
    'darkkhaki': Color(0xFFBDB76B),
    'darkmagenta': Color(0xFF8B008B),
    'darkolivegreen': Color(0xFF556B2F),
    'darkorange': Color(0xFFFF8C00),
    'darkorchid': Color(0xFF9932CC),
    'darkred': Color(0xFF8B0000),
    'darksalmon': Color(0xFFE9967A),
    'darkseagreen': Color(0xFF8FBC8F),
    'darkslateblue': Color(0xFF483D8B),
    'darkslategray': Color(0xFF2F4F4F),
    'darkslategrey': Color(0xFF2F4F4F),
    'darkturquoise': Color(0xFF00CED1),
    'darkviolet': Color(0xFF9400D3),
    'deeppink': Color(0xFFFF1493),
    'deepskyblue': Color(0xFF00BFFF),
    'dimgray': Color(0xFF696969),
    'dimgrey': Color(0xFF696969),
    'dodgerblue': Color(0xFF1E90FF),
    'firebrick': Color(0xFFB22222),
    'floralwhite': Color(0xFFFFFAF0),
    'forestgreen': Color(0xFF228B22),
    'gainsboro': Color(0xFFDCDCDC),
    'ghostwhite': Color(0xFFF8F8FF),
    'gold': Color(0xFFFFD700),
    'goldenrod': Color(0xFFDAA520),
    'greenyellow': Color(0xFFADFF2F),
    'honeydew': Color(0xFFF0FFF0),
    'hotpink': Color(0xFFFF69B4),
    'indianred': Color(0xFFCD5C5C),
    'indigo': Color(0xFF4B0082),
    'ivory': Color(0xFFFFFFF0),
    'khaki': Color(0xFFF0E68C),
    'lavender': Color(0xFFE6E6FA),
    'lavenderblush': Color(0xFFFFF0F5),
    'lawngreen': Color(0xFF7CFC00),
    'lemonchiffon': Color(0xFFFFFACD),
    'lightblue': Color(0xFFADD8E6),
    'lightcoral': Color(0xFFF08080),
    'lightcyan': Color(0xFFE0FFFF),
    'lightgoldenrodyellow': Color(0xFFFAFAD2),
    'lightgray': Color(0xFFD3D3D3),
    'lightgrey': Color(0xFFD3D3D3),
    'lightgreen': Color(0xFF90EE90),
    'lightpink': Color(0xFFFFB6C1),
    'lightsalmon': Color(0xFFFFA07A),
    'lightseagreen': Color(0xFF20B2AA),
    'lightskyblue': Color(0xFF87CEFA),
    'lightslategray': Color(0xFF778899),
    'lightslategrey': Color(0xFF778899),
    'lightsteelblue': Color(0xFFB0C4DE),
    'lightyellow': Color(0xFFFFFFE0),
    'limegreen': Color(0xFF32CD32),
    'linen': Color(0xFFFAF0E6),
    'mediumaquamarine': Color(0xFF66CDAA),
    'mediumblue': Color(0xFF0000CD),
    'mediumorchid': Color(0xFFBA55D3),
    'mediumpurple': Color(0xFF9370DB),
    'mediumseagreen': Color(0xFF3CB371),
    'mediumslateblue': Color(0xFF7B68EE),
    'mediumspringgreen': Color(0xFF00FA9A),
    'mediumturquoise': Color(0xFF48D1CC),
    'mediumvioletred': Color(0xFFC71585),
    'midnightblue': Color(0xFF191970),
    'mintcream': Color(0xFFF5FFFA),
    'mistyrose': Color(0xFFFFE4E1),
    'moccasin': Color(0xFFFFE4B5),
    'navajowhite': Color(0xFFFFDEAD),
    'oldlace': Color(0xFFFDF5E6),
    'olivedrab': Color(0xFF6B8E23),
    'orangered': Color(0xFFFF4500),
    'orchid': Color(0xFFDA70D6),
    'palegoldenrod': Color(0xFFEEE8AA),
    'palegreen': Color(0xFF98FB98),
    'paleturquoise': Color(0xFFAFEEEE),
    'palevioletred': Color(0xFFDB7093),
    'papayawhip': Color(0xFFFFEFD5),
    'peachpuff': Color(0xFFFFDAB9),
    'peru': Color(0xFFCD853F),
    'plum': Color(0xFFDDA0DD),
    'powderblue': Color(0xFFB0E0E6),
    'rosybrown': Color(0xFFBC8F8F),
    'royalblue': Color(0xFF4169E1),
    'saddlebrown': Color(0xFF8B4513),
    'salmon': Color(0xFFFA8072),
    'sandybrown': Color(0xFFF4A460),
    'seagreen': Color(0xFF2E8B57),
    'seashell': Color(0xFFFFF5EE),
    'sienna': Color(0xFFA0522D),
    'skyblue': Color(0xFF87CEEB),
    'slateblue': Color(0xFF6A5ACD),
    'slategray': Color(0xFF708090),
    'slategrey': Color(0xFF708090),
    'snow': Color(0xFFFFFAFA),
    'springgreen': Color(0xFF00FF7F),
    'steelblue': Color(0xFF4682B4),
    'tan': Color(0xFFD2B48C),
    'thistle': Color(0xFFD8BFD8),
    'tomato': Color(0xFFFF6347),
    'turquoise': Color(0xFF40E0D0),
    'violet': Color(0xFFEE82EE),
    'wheat': Color(0xFFF5DEB3),
    'whitesmoke': Color(0xFFF5F5F5),
    'yellowgreen': Color(0xFF9ACD32),
    // CSS system/special
    'rebeccapurple': Color(0xFF663399),
  };
}
