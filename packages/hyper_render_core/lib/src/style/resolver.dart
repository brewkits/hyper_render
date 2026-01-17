import 'package:flutter/painting.dart';

import '../model/computed_style.dart';
import '../model/node.dart';
import '../interfaces/css_parser.dart';

/// CSS Style Resolver
///
/// Resolves styles for UDT nodes following CSS cascade rules.
/// This is the ZERO-DEP version that does NOT parse CSS directly.
/// CSS parsing is done by external CssParserInterface implementations.
///
/// Reference: doc1.txt - "1.2. Quy trình Resolve (Phân giải)"
/// The resolver traverses the tree Top-Down:
/// 1. User Agent Styles - Browser defaults (h1 is bold, etc.)
/// 2. External/Internal CSS - CSS rules from <style> tags
/// 3. Inline Styles - style attribute on elements
/// 4. Inheritance - Properties like color, font-family from parent
class StyleResolver {
  /// Parsed CSS rules (provided externally via CssParserInterface)
  final List<ParsedCssRule> _cssRules = [];

  /// Get parsed CSS rules (for debugging)
  List<ParsedCssRule> get cssRules => List.unmodifiable(_cssRules);

  /// User agent (default) styles
  static final Map<String, ComputedStyle> _userAgentStyles = {
    'h1': ComputedStyle(
      display: DisplayType.block,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      margin: const EdgeInsets.symmetric(vertical: 21.44),
    ),
    'h2': ComputedStyle(
      display: DisplayType.block,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      margin: const EdgeInsets.symmetric(vertical: 19.92),
    ),
    'h3': ComputedStyle(
      display: DisplayType.block,
      fontSize: 18.72,
      fontWeight: FontWeight.bold,
      margin: const EdgeInsets.symmetric(vertical: 18.72),
    ),
    'h4': ComputedStyle(
      display: DisplayType.block,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      margin: const EdgeInsets.symmetric(vertical: 21.28),
    ),
    'h5': ComputedStyle(
      display: DisplayType.block,
      fontSize: 13.28,
      fontWeight: FontWeight.bold,
      margin: const EdgeInsets.symmetric(vertical: 22.18),
    ),
    'h6': ComputedStyle(
      display: DisplayType.block,
      fontSize: 10.72,
      fontWeight: FontWeight.bold,
      margin: const EdgeInsets.symmetric(vertical: 24.97),
    ),
    'p': ComputedStyle(
      display: DisplayType.block,
      margin: const EdgeInsets.symmetric(vertical: 16),
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
      margin: const EdgeInsets.symmetric(vertical: 16),
      borderWidth: const EdgeInsets.only(top: 1),
      borderColor: const Color(0xFFDDDDDD),
    ),
    'mark': ComputedStyle(
      backgroundColor: const Color(0xFFFFEB3B), // Material Yellow
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    ),
    'sub': ComputedStyle(
      fontSize: 12,
      verticalAlign: HyperVerticalAlign.bottom,
    ),
    'sup': ComputedStyle(
      fontSize: 12,
      verticalAlign: HyperVerticalAlign.top,
    ),
    'small': ComputedStyle(
      fontSize: 13,
    ),
    'kbd': ComputedStyle(
      fontFamily: 'monospace',
      backgroundColor: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      borderWidth: const EdgeInsets.all(1),
      borderColor: const Color(0xFFCCCCCC),
      borderRadius: BorderRadius.circular(4),
      fontSize: 13,
    ),
    'code': ComputedStyle(
      fontFamily: 'monospace',
      backgroundColor: const Color(0xFFE8E8E8),
      color: const Color(0xFFE91E63),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      borderRadius: BorderRadius.circular(4),
      fontSize: 13,
    ),
    'pre': ComputedStyle(
      display: DisplayType.block,
      fontFamily: 'monospace',
      whiteSpace: 'pre',
      backgroundColor: const Color(0xFF1E1E1E),
      color: const Color(0xFFD4D4D4),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 12),
      borderRadius: BorderRadius.circular(8),
      fontSize: 13,
      lineHeight: 1.6,
    ),
    'blockquote': ComputedStyle(
      display: DisplayType.block,
      margin: const EdgeInsets.fromLTRB(0, 16, 0, 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      borderWidth: const EdgeInsets.only(left: 4),
      borderColor: const Color(0xFFDDDDDD),
      backgroundColor: const Color(0xFFF9F9F9),
    ),
    'ul': ComputedStyle(
      display: DisplayType.block,
      padding: const EdgeInsets.only(left: 40),
      margin: const EdgeInsets.symmetric(vertical: 16),
    ),
    'ol': ComputedStyle(
      display: DisplayType.block,
      padding: const EdgeInsets.only(left: 40),
      margin: const EdgeInsets.symmetric(vertical: 16),
    ),
    'li': ComputedStyle(
      display: DisplayType.block,
      margin: const EdgeInsets.symmetric(vertical: 4),
    ),
    'table': ComputedStyle(
      display: DisplayType.table,
      margin: const EdgeInsets.symmetric(vertical: 16),
      borderWidth: const EdgeInsets.all(1),
      borderColor: const Color(0xFFDDDDDD),
    ),
    'thead': ComputedStyle(
      display: DisplayType.block,
      backgroundColor: const Color(0xFFF5F5F5),
    ),
    'tr': ComputedStyle(
      display: DisplayType.tableRow,
      borderWidth: const EdgeInsets.only(bottom: 1),
      borderColor: const Color(0xFFEEEEEE),
    ),
    'td': ComputedStyle(
      display: DisplayType.tableCell,
      padding: const EdgeInsets.all(12),
      borderWidth: const EdgeInsets.all(1),
      borderColor: const Color(0xFFEEEEEE),
    ),
    'th': ComputedStyle(
      display: DisplayType.tableCell,
      fontWeight: FontWeight.bold,
      padding: const EdgeInsets.all(12),
      backgroundColor: const Color(0xFFF5F5F5),
      borderWidth: const EdgeInsets.all(1),
      borderColor: const Color(0xFFDDDDDD),
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
  }

  /// Clear all CSS rules
  void clearCssRules() {
    _cssRules.clear();
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
    for (final rule in _cssRules) {
      if (_matchesSelector(node, rule.selector)) {
        style = _applyDeclarations(
          style,
          rule.declarations,
          parentFontSize: parentFontSize,
        );
      }
    }

    // 3. Apply inline styles
    final inlineStyle = node.attributes['style'];
    if (inlineStyle != null && inlineStyle.isNotEmpty) {
      style = _parseInlineStyle(style, inlineStyle, parentFontSize: parentFontSize);
    }

    // 4. Inherit from parent
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

    final classMatches = RegExp(r'\.([a-zA-Z_-][a-zA-Z0-9_-]*)').allMatches(selector);
    for (final match in classMatches) {
      classParts.add(match.group(1)!);
    }

    final elementMatch = RegExp(r'^([a-zA-Z][a-zA-Z0-9]*)').firstMatch(selector);
    if (elementMatch != null) {
      elementPart = elementMatch.group(1);
    }

    if (elementPart != null && node.tagName != elementPart) {
      return false;
    }

    if (idPart != null && node.cssId != idPart) {
      return false;
    }

    for (final className in classParts) {
      if (!node.classList.contains(className)) {
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
    if (parts.length != 2) return false;

    final parentSelector = parts[0].trim();
    final childSelector = parts[1].trim();

    if (!_matchesSimpleSelector(node, childSelector)) {
      return false;
    }

    if (node.parent == null) return false;
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
  }) {
    for (final entry in declarations.entries) {
      style = _applySingleDeclaration(
        style,
        entry.key,
        entry.value,
        parentFontSize: parentFontSize,
      );
    }
    return style;
  }

  ComputedStyle _applySingleDeclaration(
    ComputedStyle style,
    String property,
    String value, {
    double? parentFontSize,
  }) {
    switch (property) {
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
        final margin = _parseEdgeInsets(value);
        if (margin != null) {
          style.margin = margin;
          style.markExplicitlySet('margin');
        }
        break;

      case 'padding':
        final padding = _parseEdgeInsets(value);
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
        final width = _parseLength(value);
        if (width != null) {
          style.width = width;
          style.markExplicitlySet('width');
        }
        break;

      case 'height':
        final height = _parseLength(value);
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
    }

    return style;
  }

  ComputedStyle _parseInlineStyle(
    ComputedStyle style,
    String inlineStyle, {
    double? parentFontSize,
  }) {
    final declarations = inlineStyle.split(';');
    for (final decl in declarations) {
      final parts = decl.split(':');
      if (parts.length == 2) {
        final property = parts[0].trim();
        final value = parts[1].trim();
        style = _applySingleDeclaration(
          style,
          property,
          value,
          parentFontSize: parentFontSize,
        );
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
  }

  // ============================================
  // CSS Value Parsers
  // ============================================

  static const double rootFontSize = 16.0;

  Color? _parseColor(String value) {
    value = value.trim().toLowerCase();

    if (value.startsWith('#')) {
      final hex = value.substring(1);
      if (hex.length == 3) {
        final r = hex[0] + hex[0];
        final g = hex[1] + hex[1];
        final b = hex[2] + hex[2];
        return Color(int.parse('FF$r$g$b', radix: 16));
      } else if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }

    final rgbMatch = RegExp(r'rgb\((\d+),\s*(\d+),\s*(\d+)\)').firstMatch(value);
    if (rgbMatch != null) {
      return Color.fromARGB(
        255,
        int.parse(rgbMatch.group(1)!),
        int.parse(rgbMatch.group(2)!),
        int.parse(rgbMatch.group(3)!),
      );
    }

    final rgbaMatch = RegExp(r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)').firstMatch(value);
    if (rgbaMatch != null) {
      return Color.fromARGB(
        (double.parse(rgbaMatch.group(4)!) * 255).toInt(),
        int.parse(rgbaMatch.group(1)!),
        int.parse(rgbaMatch.group(2)!),
        int.parse(rgbaMatch.group(3)!),
      );
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
    final length = _parseLength(value);
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

  EdgeInsets? _parseEdgeInsets(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    final values = parts.map((p) => _parseLength(p) ?? 0.0).toList();

    switch (values.length) {
      case 1: return EdgeInsets.all(values[0]);
      case 2: return EdgeInsets.symmetric(vertical: values[0], horizontal: values[1]);
      case 3: return EdgeInsets.only(top: values[0], left: values[1], right: values[1], bottom: values[2]);
      case 4: return EdgeInsets.only(top: values[0], right: values[1], bottom: values[2], left: values[3]);
      default: return null;
    }
  }

  double? _parseLength(String value) {
    value = value.trim().toLowerCase();

    if (value.endsWith('px')) {
      return double.tryParse(value.replaceAll('px', ''));
    }
    if (value.endsWith('pt')) {
      final pt = double.tryParse(value.replaceAll('pt', ''));
      return pt != null ? pt * 1.333 : null;
    }
    if (value.endsWith('em')) {
      return double.tryParse(value.replaceAll('em', ''));
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
    'black': Color(0xFF000000),
    'white': Color(0xFFFFFFFF),
    'red': Color(0xFFFF0000),
    'green': Color(0xFF008000),
    'blue': Color(0xFF0000FF),
    'yellow': Color(0xFFFFFF00),
    'cyan': Color(0xFF00FFFF),
    'magenta': Color(0xFFFF00FF),
    'gray': Color(0xFF808080),
    'grey': Color(0xFF808080),
    'orange': Color(0xFFFFA500),
    'purple': Color(0xFF800080),
    'pink': Color(0xFFFFC0CB),
    'brown': Color(0xFFA52A2A),
    'transparent': Color(0x00000000),
  };
}
