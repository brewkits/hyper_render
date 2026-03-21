import 'dart:ui' as ui;

import 'package:csslib/parser.dart' as css_parser;
import 'package:csslib/visitor.dart' as css_ast;
import 'package:flutter/painting.dart' hide BorderStyle, TextDirection;

import '../model/computed_style.dart';
import '../model/node.dart';

/// CSS Style Resolver
///
/// Resolves styles for UDT nodes following CSS cascade rules.
///
/// Reference: doc1.txt - "1.2. Quy trình Resolve (Phân giải)"
/// The resolver traverses the tree Top-Down:
/// 1. User Agent Styles - Browser defaults (h1 is bold, etc.)
/// 2. External/Internal CSS - CSS rules from <style> tags
/// 3. Inline Styles - style attribute on elements
/// 4. Inheritance - Properties like color, font-family from parent
///
/// **CSS `!important` support**
///
/// `!important` declarations are stored separately in [CssRule.importantDeclarations]
/// and applied after inline styles in step 4 of the cascade, matching the CSS spec.
/// Higher-specificity `!important` rules still win over lower-specificity ones.
class StyleResolver {
  /// Parsed CSS rules from <style> tags
  final List<CssRule> _cssRules = [];

  /// Get parsed CSS rules (for debugging)
  List<CssRule> get cssRules => List.unmodifiable(_cssRules);

  // ── Rule index for O(1) candidate lookup ────────────────────────────────
  // After _extractRules, rules are partitioned by their "key" selector part:
  //   _rulesByTag['p']    — rules whose rightmost simple part is the element "p"
  //   _rulesByClass['foo'] — rules that require class "foo"
  //   _rulesById['bar']   — rules that require id "bar"
  //   _universalRules     — rules that can match anything (universal "*",
  //                         attribute selectors, combinators, pseudo-classes)
  //
  // _getCandidateRules(node) returns the union of all buckets that are relevant
  // for the given node, avoiding full iteration over unrelated rules.
  final Map<String, List<CssRule>> _rulesByTag = {};
  final Map<String, List<CssRule>> _rulesByClass = {};
  final Map<String, List<CssRule>> _rulesById = {};
  final List<CssRule> _universalRules = [];

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
      backgroundColor: const Color(0xFFE8E8E8), // Light gray background
      color: const Color(0xFFE91E63), // Pink/magenta for inline code
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      borderRadius: BorderRadius.circular(4),
      fontSize: 13,
    ),
    'pre': ComputedStyle(
      display: DisplayType.block,
      fontFamily: 'monospace',
      whiteSpace: 'pre',
      // Visual styling (background, padding, borderRadius) is intentionally omitted
      // here because <pre> blocks are rendered as CodeBlockWidget children that
      // handle their own visual presentation. Keeping these here causes a double-
      // painted dark background that covers the code widget's own background.
      margin: const EdgeInsets.symmetric(vertical: 12),
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
    'details': ComputedStyle(
      display: DisplayType.block,
      margin: const EdgeInsets.symmetric(vertical: 4),
    ),
    'summary': ComputedStyle(
      display: DisplayType.block,
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

  /// Parse CSS string and store rules
  void parseCss(String cssString) {
    if (cssString.isEmpty) return;

    try {
      final stylesheet = css_parser.parse(cssString);
      _extractRules(stylesheet);
    } catch (e) {
      // Silently ignore CSS parsing errors in production
    }
  }

  /// Extract CSS rules from parsed stylesheet
  void _extractRules(css_ast.StyleSheet stylesheet) {
    int sourceIndex = 0;
    for (final topLevel in stylesheet.topLevels) {
      if (topLevel is css_ast.RuleSet) {
        // One RuleSet may contain multiple comma-separated selectors.
        _cssRules.addAll(_convertRuleSet(topLevel, sourceIndex: sourceIndex++));
      }
    }

    // Stable sort: lower specificity first; same specificity preserves source order
    _cssRules.sort((a, b) {
      final cmp = a.specificity.compareTo(b.specificity);
      return cmp != 0 ? cmp : a.sourceIndex.compareTo(b.sourceIndex);
    });

    _buildRuleIndex();
  }

  /// Build O(1)-lookup index over [_cssRules].
  ///
  /// Each rule is placed into the most specific bucket we can identify from its
  /// selector string without full parsing:
  /// - Has `#id`   → [_rulesById]   (most specific)
  /// - Has `.cls`  → [_rulesByClass]
  /// - Starts with or ends in an element name → [_rulesByTag]
  /// - Otherwise   → [_universalRules]
  ///
  /// A rule can be in **multiple** buckets (e.g. `div.foo` → both tag and class).
  /// [_getCandidateRules] deduplicates with a Set when merging results.
  void _buildRuleIndex() {
    _rulesByTag.clear();
    _rulesByClass.clear();
    _rulesById.clear();
    _universalRules.clear();

    for (final rule in _cssRules) {
      // Extract the rightmost simple selector part (after any combinator).
      final rightmost = _rightmostSimplePart(rule.selector);

      bool indexed = false;

      // Index by id (#foo)
      final idMatch = RegExp(r'#([a-zA-Z_][a-zA-Z0-9_-]*)').firstMatch(rightmost);
      if (idMatch != null) {
        (_rulesById[idMatch.group(1)!] ??= []).add(rule);
        indexed = true;
      }

      // Index by class (.foo) — may be multiple classes
      for (final m in RegExp(r'\.([a-zA-Z_][a-zA-Z0-9_-]*)').allMatches(rightmost)) {
        (_rulesByClass[m.group(1)!] ??= []).add(rule);
        indexed = true;
      }

      // Index by tag (starts with letter, no # or .)
      final tagMatch = RegExp(r'^([a-zA-Z][a-zA-Z0-9]*)').firstMatch(rightmost);
      if (tagMatch != null) {
        (_rulesByTag[tagMatch.group(1)!.toLowerCase()] ??= []).add(rule);
        indexed = true;
      }

      if (!indexed) {
        _universalRules.add(rule);
      }
    }
  }

  /// Returns the rightmost simple selector part (after the last combinator).
  ///
  /// For `div > p.lead` → `p.lead`; for `h1 + p` → `p`; for `*` → `*`.
  static String _rightmostSimplePart(String selector) {
    // Split on combinator tokens (space, >, +, ~) and take the last part.
    final parts = selector.split(RegExp(r'\s*[>+~]\s*|\s+'));
    return parts.last.trim();
  }

  /// Returns the deduplicated set of candidate rules for [node].
  ///
  /// Merges: universal + tag-indexed + class-indexed + id-indexed buckets.
  /// The returned list is in insertion (specificity-sorted) order because
  /// [_buildRuleIndex] preserves [_cssRules] sort order within each bucket.
  List<CssRule> _getCandidateRules(UDTNode node) {
    final seen = <CssRule>{};
    final result = <CssRule>[];

    void add(List<CssRule>? bucket) {
      if (bucket == null) return;
      for (final r in bucket) {
        if (seen.add(r)) result.add(r);
      }
    }

    add(_universalRules);

    final tag = node.tagName?.toLowerCase();
    if (tag != null) add(_rulesByTag[tag]);

    final classAttr = node.attributes['class'];
    if (classAttr != null) {
      for (final cls in classAttr.split(RegExp(r'\s+'))) {
        if (cls.isNotEmpty) add(_rulesByClass[cls]);
      }
    }

    final id = node.attributes['id'];
    if (id != null && id.isNotEmpty) add(_rulesById[id]);

    // Re-sort the merged candidate list by (specificity, sourceIndex) so that
    // the cascade order is maintained correctly.
    result.sort((a, b) {
      final cmp = a.specificity.compareTo(b.specificity);
      return cmp != 0 ? cmp : a.sourceIndex.compareTo(b.sourceIndex);
    });

    return result;
  }

  /// Convert a csslib RuleSet to one [CssRule] per comma-separated selector.
  ///
  /// Previously the inner loop overwrote [selector] on every simple selector,
  /// which meant only the last class/element name was kept (e.g. "div p" became
  /// just "p").  We now use [sel.span?.text] which gives the exact source text
  /// of each selector (including combinators like space, ">", "+", "~").
  List<CssRule> _convertRuleSet(css_ast.RuleSet ruleSet,
      {int sourceIndex = 0}) {
    final selectorGroup = ruleSet.selectorGroup;
    if (selectorGroup == null || selectorGroup.selectors.isEmpty) {
      return const [];
    }

    // Collect declaration values once — shared across all selectors in the group.
    final declarations = <String, String>{};
    final importantDeclarations = <String, String>{};

    for (final decl in ruleSet.declarationGroup.declarations) {
      if (decl is css_ast.Declaration) {
        final expression = decl.expression;
        String value = '';

        if (expression is css_ast.Expressions) {
          final parts = <String>[];
          for (final expr in expression.expressions) {
            final text = expr.span?.text ?? '';
            if (text.isNotEmpty) parts.add(text);
          }
          value = parts.join(' ');
        } else if (expression != null) {
          value = expression.span?.text ?? '';
        }

        if (value.isNotEmpty) {
          if (decl.important) {
            importantDeclarations[decl.property] = value;
          } else {
            declarations[decl.property] = value;
          }
        }
      }
    }

    if (declarations.isEmpty && importantDeclarations.isEmpty) return const [];

    // Emit one CssRule per selector in the comma-separated group.
    final rules = <CssRule>[];
    for (final sel in selectorGroup.selectors) {
      // Use the span text for the full, correct selector string.
      // This preserves combinators (descendant space, child ">", etc.) and
      // compound selectors (e.g. "div.card > p.lead").
      final selector = sel.span?.text.trim() ?? '';
      if (selector.isEmpty) continue;

      rules.add(CssRule(
        selector: selector,
        declarations: Map.unmodifiable(declarations),
        importantDeclarations: Map.unmodifiable(importantDeclarations),
        specificity: _calculateSpecificity(selector),
        sourceIndex: sourceIndex,
      ));
    }
    return rules;
  }

  /// Calculate CSS specificity for a selector
  /// Reference: https://www.w3.org/TR/selectors-3/#specificity
  int _calculateSpecificity(String selector) {
    int specificity = 0;

    // ID selectors (#id) = 100
    specificity += RegExp(r'#[a-zA-Z_-]+').allMatches(selector).length * 100;

    // Class selectors (.class), attribute selectors, pseudo-classes = 10
    specificity += RegExp(r'\.[a-zA-Z_-]+').allMatches(selector).length * 10;
    specificity += RegExp(r'\[[^\]]+\]').allMatches(selector).length * 10;
    specificity += RegExp(r':[a-zA-Z_-]+').allMatches(selector).length * 10;

    // Element selectors, pseudo-elements = 1
    // Split by combinator chars and count parts that start with a letter
    final selectorParts = selector.split(RegExp(r'[\s>+~]+'));
    specificity += selectorParts
        .where((p) => p.isNotEmpty && RegExp(r'^[a-zA-Z]').hasMatch(p))
        .length;

    return specificity;
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
    // It should inherit from the pre block (dark theme with light text)
    if (tagName == 'code' && node.parent?.tagName?.toLowerCase() == 'pre') {
      style.backgroundColor = null; // Remove inline code background
      style.padding = EdgeInsets.zero; // Remove inline code padding
      // Color will be inherited from parent (pre) via _applyInheritance
    }

    // Apply dir="rtl"/"ltr" HTML attribute (maps to CSS direction)
    final dirAttr = node.attributes['dir'];
    if (dirAttr != null) {
      final dir = _parseDirection(dirAttr);
      if (dir != null) {
        style.hyperDirection = dir;
        style.markExplicitlySet('direction');
      }
    }

    // 2. Apply CSS rules (sorted by specificity, normal declarations only)
    //    Use O(1) candidate lookup via _getCandidateRules to avoid iterating
    //    over every rule for every node (previously O(Rules × Nodes)).
    final candidates = _getCandidateRules(node);
    for (final rule in candidates) {
      if (rule.declarations.isNotEmpty &&
          _matchesSelector(node, rule.selector)) {
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
  ///
  /// Supports:
  /// - Element selector: `p`, `div`
  /// - ID selector: `#myId`
  /// - Class selector: `.myClass`
  /// - Universal selector: `*`
  /// - Descendant selector: `div p` (p inside div)
  /// - Child selector: `div > p` (p direct child of div)
  /// - Adjacent sibling: `h1 + p` (p immediately after h1)
  /// - General sibling: `h1 ~ p` (p after h1, same parent)
  /// - Multiple classes: `.class1.class2`
  /// - Combined: `div.highlight`, `p#intro`
  bool _matchesSelector(UDTNode node, String selector) {
    selector = selector.trim();

    // Normalize optional whitespace around combinators so that both `div>p`
    // and `div > p` are treated identically.  We collapse any runs of spaces
    // back to a single space after insertion to avoid double-space issues.
    selector = selector
        .replaceAllMapped(RegExp(r'\s*([>+~])\s*'), (m) => ' ${m.group(1)} ')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();

    final parts = _tokenizeCombinators(selector);
    if (parts.isEmpty) return false;
    if (parts.length == 1) return _matchesSimpleSelector(node, parts[0].$1);
    return _matchesSelectorParts(node, parts, parts.length - 1);
  }

  /// Tokenizes a normalized selector string into a list of
  /// `(simpleSelector, combinator)` pairs.
  ///
  /// The **last** part always has a `null` combinator (it has no right-hand
  /// neighbour). All other parts carry the combinator that connects them to
  /// the next part:
  ///
  ///   `"div > p + span"`  →
  ///     `[("div", ">"), ("p", "+"), ("span", null)]`
  ///
  /// Parenthesised content (e.g. `:nth-child(2n+1)`) is treated as opaque —
  /// the `+` inside the parens is NOT interpreted as a combinator.
  static List<(String, String?)> _tokenizeCombinators(String selector) {
    final parts = <(String, String?)>[];
    final buf = StringBuffer();
    int depth = 0;
    int i = 0;

    while (i < selector.length) {
      final ch = selector[i];

      if (ch == '(') {
        depth++;
        buf.write(ch);
        i++;
        continue;
      }
      if (ch == ')') {
        depth--;
        buf.write(ch);
        i++;
        continue;
      }
      if (depth > 0) {
        buf.write(ch);
        i++;
        continue;
      }

      // At depth 0: check for combinator patterns.
      // After normalization, explicit combinators are always " X " (space,
      // combinator char, space).  Descendant combinator is a plain space.
      if (ch == ' ') {
        if (i + 2 < selector.length &&
            '>+~'.contains(selector[i + 1]) &&
            selector[i + 2] == ' ') {
          // Explicit combinator: " > ", " + ", or " ~ "
          if (buf.isNotEmpty) {
            parts.add((buf.toString(), selector[i + 1]));
            buf.clear();
          }
          i += 3; // skip ' ', combinator, ' '
          continue;
        }
        // Descendant combinator (plain space between simple selectors).
        if (buf.isNotEmpty) {
          parts.add((buf.toString(), ' '));
          buf.clear();
        }
        i++;
        continue;
      }

      buf.write(ch);
      i++;
    }

    if (buf.isNotEmpty) parts.add((buf.toString(), null));
    return parts;
  }

  /// Matches [node] against a tokenized selector list, working right-to-left.
  ///
  /// [partIdx] starts at `parts.length - 1` (the rightmost simple selector)
  /// and recurses leftward following each combinator.
  ///
  /// Examples of correctly handled mixed-combinator selectors:
  ///   - `div > p + span`  — child then adjacent-sibling
  ///   - `ul li:first-child` — descendant then structural pseudo-class
  ///   - `section > div ~ p` — child then general-sibling
  bool _matchesSelectorParts(
      UDTNode node, List<(String, String?)> parts, int partIdx) {
    if (!_matchesSimpleSelector(node, parts[partIdx].$1)) return false;
    if (partIdx == 0) return true; // all parts matched

    // The combinator is stored on the part to the LEFT (parts[partIdx-1].$2).
    final combinator = parts[partIdx - 1].$2!;

    switch (combinator) {
      case '>': // child combinator
        if (node.parent == null) return false;
        return _matchesSelectorParts(node.parent!, parts, partIdx - 1);

      case '+': // adjacent sibling combinator
        final prev = _getPreviousSibling(node);
        if (prev == null) return false;
        return _matchesSelectorParts(prev, parts, partIdx - 1);

      case '~': // general sibling combinator
        final parent = node.parent;
        if (parent == null) return false;
        final nodeIdx = parent.children.indexOf(node);
        for (int i = 0; i < nodeIdx; i++) {
          if (_matchesSelectorParts(parent.children[i], parts, partIdx - 1)) {
            return true;
          }
        }
        return false;

      case ' ': // descendant combinator
        UDTNode? ancestor = node.parent;
        while (ancestor != null) {
          if (_matchesSelectorParts(ancestor, parts, partIdx - 1)) return true;
          ancestor = ancestor.parent;
        }
        return false;

      default:
        return false;
    }
  }

  /// Match simple selector (no combinators)
  bool _matchesSimpleSelector(UDTNode node, String selector) {
    selector = selector.trim();

    // Universal selector
    if (selector == '*') return true;

    // Extract and evaluate pseudo-classes before structural matching.
    // e.g. "li:first-child" → base = "li", pseudos = [":first-child"]
    //      "div.highlight:hover" → base = "div.highlight", pseudos = [":hover"]
    final extracted = _extractPseudoClasses(selector);
    final base = extracted.base;
    final pseudos = extracted.pseudos;

    // Check all pseudo-classes first — if any fail, the selector doesn't match.
    for (final pseudo in pseudos) {
      if (!_matchesPseudoClass(node, pseudo)) return false;
    }

    // If the entire selector was just pseudo-classes, universal match.
    if (base.isEmpty) return true;

    // ID selector only: `#myId`
    if (base.startsWith('#') && !base.contains('.')) {
      final id = base.substring(1);
      return node.cssId == id;
    }

    // Class selector only: `.myClass`
    if (base.startsWith('.') && !base.contains('#')) {
      return _matchesClassSelector(node, base);
    }

    // Element selector only: `div`
    if (!base.contains('.') && !base.contains('#')) {
      return base == node.tagName;
    }

    // Combined selectors: `div.class`, `div#id`, `div.class1.class2`
    return _matchesCombinedSelector(node, base);
  }

  /// Splits a simple selector into its base part and any pseudo-class/pseudo-element
  /// suffixes.
  ///
  /// Example: `"li:first-child"` → `(base: "li", pseudos: [":first-child"])`
  /// Example: `"div.foo:hover"` → `(base: "div.foo", pseudos: [":hover"])`
  /// Example: `"p:nth-child(2n+1)"` → `(base: "p", pseudos: [":nth-child(2n+1)"])`
  static ({String base, List<String> pseudos}) _extractPseudoClasses(
      String selector) {
    final pseudos = <String>[];
    // Match ::pseudo-element or :pseudo-class (with optional parenthesised arg)
    // The character class [^()]+ prevents greedy match from swallowing nested
    // parens, but CSS pseudo-class args are never nested so this is sufficient.
    final result = selector.replaceAllMapped(
      RegExp(r'::?[a-zA-Z-]+(?:\([^()]*\))?'),
      (m) {
        pseudos.add(m.group(0)!.toLowerCase());
        return '';
      },
    );
    return (base: result.trim(), pseudos: pseudos);
  }

  /// Returns whether [node] satisfies a single pseudo-class or pseudo-element.
  ///
  /// **Structural pseudo-classes** — evaluated against the DOM tree:
  /// `:first-child`, `:last-child`, `:only-child`,
  /// `:nth-child(…)`, `:nth-last-child(…)`,
  /// `:first-of-type`, `:last-of-type`, `:only-of-type`.
  ///
  /// **Behavioral / dynamic pseudo-classes** — always return `false` because
  /// static rendering has no hover/focus/active state:
  /// `:hover`, `:focus`, `:active`, `:visited`, `:focus-within`,
  /// `:focus-visible`, `:checked`, `:disabled`, `:enabled`.
  ///
  /// **Unknown / future pseudo-classes** — return `true` (ignore) to avoid
  /// breaking forward-compatible CSS.
  bool _matchesPseudoClass(UDTNode node, String pseudo) {
    // ── Behavioral states — never true in static rendering ──────────────────
    const dynamic_ = {
      ':hover', ':focus', ':active', ':visited',
      ':focus-within', ':focus-visible', ':focus-ring',
      ':checked', ':indeterminate', ':disabled', ':enabled',
      ':placeholder-shown', ':autofill',
    };
    if (dynamic_.contains(pseudo)) return false;

    // ── Pseudo-elements — skip (not applicable to node matching) ────────────
    if (pseudo.startsWith('::')) return true;

    final parent = node.parent;

    // ── :first-child ────────────────────────────────────────────────────────
    if (pseudo == ':first-child') {
      return parent != null &&
          parent.children.isNotEmpty &&
          parent.children.first == node;
    }

    // ── :last-child ─────────────────────────────────────────────────────────
    if (pseudo == ':last-child') {
      return parent != null &&
          parent.children.isNotEmpty &&
          parent.children.last == node;
    }

    // ── :only-child ─────────────────────────────────────────────────────────
    if (pseudo == ':only-child') {
      return parent != null && parent.children.length == 1;
    }

    // ── :nth-child(…) ───────────────────────────────────────────────────────
    final nthChild = RegExp(r'^:nth-child\(([^)]+)\)$').firstMatch(pseudo);
    if (nthChild != null) {
      if (parent == null) return false;
      final idx = parent.children.indexOf(node) + 1; // 1-based
      return _matchesNthExpression(idx, nthChild.group(1)!.trim());
    }

    // ── :nth-last-child(…) ──────────────────────────────────────────────────
    final nthLast = RegExp(r'^:nth-last-child\(([^)]+)\)$').firstMatch(pseudo);
    if (nthLast != null) {
      if (parent == null) return false;
      final idx = parent.children.length - parent.children.indexOf(node); // 1-based from end
      return _matchesNthExpression(idx, nthLast.group(1)!.trim());
    }

    // ── :first-of-type ──────────────────────────────────────────────────────
    if (pseudo == ':first-of-type') {
      if (parent == null) return false;
      return parent.children
              .firstWhere(
                (c) => c.tagName == node.tagName,
                orElse: () => node,
              ) ==
          node;
    }

    // ── :last-of-type ───────────────────────────────────────────────────────
    if (pseudo == ':last-of-type') {
      if (parent == null) return false;
      return parent.children
              .lastWhere(
                (c) => c.tagName == node.tagName,
                orElse: () => node,
              ) ==
          node;
    }

    // ── :only-of-type ───────────────────────────────────────────────────────
    if (pseudo == ':only-of-type') {
      if (parent == null) return false;
      return parent.children.where((c) => c.tagName == node.tagName).length == 1;
    }

    // ── Unknown / future pseudo-classes → ignore (don't block matching) ─────
    return true;
  }

  /// Evaluates CSS `An+B` notation against a 1-based child [index].
  ///
  /// Supports: `odd`, `even`, a plain integer `N`, and the full `An+B` form.
  static bool _matchesNthExpression(int index, String expr) {
    expr = expr.toLowerCase().trim();
    if (expr == 'odd') return index % 2 == 1;
    if (expr == 'even') return index % 2 == 0;

    final plain = int.tryParse(expr);
    if (plain != null) return index == plain;

    // Parse An+B  (e.g. "2n+1", "-n+3", "n", "3n")
    final match =
        RegExp(r'^(-?\d*)?n(?:\+(\d+))?$').firstMatch(expr);
    if (match == null) return false;

    final aStr = match.group(1) ?? '1';
    final a = aStr.isEmpty || aStr == '+' ? 1 : (aStr == '-' ? -1 : int.tryParse(aStr) ?? 1);
    final b = int.tryParse(match.group(2) ?? '0') ?? 0;

    if (a == 0) return index == b;
    // index = a*n + b  →  n = (index - b) / a  must be a non-negative integer.
    //
    // Do NOT short-circuit on `numerator < 0` when a is negative:
    //   -n+3 (a=-1, b=3) → index=1: numerator = 1-3 = -2, n = -2/-1 = 2 ✓
    //   Removing the early-exit and relying solely on `n >= 0` handles both
    //   positive and negative step values correctly.
    final numerator = index - b;
    if (numerator % a != 0) return false;
    return numerator ~/ a >= 0;
  }

  /// Match class selector (can be multiple: `.class1.class2`)
  bool _matchesClassSelector(UDTNode node, String selector) {
    // Split by '.' and filter empty strings
    final classes = selector.split('.').where((c) => c.isNotEmpty).toList();
    if (classes.isEmpty) return false;

    // All classes must match
    for (final className in classes) {
      if (!node.classList.contains(className)) {
        return false;
      }
    }
    return true;
  }

  /// Match combined selector: `element.class`, `element#id`, `.class1.class2`
  bool _matchesCombinedSelector(UDTNode node, String selector) {
    String? elementPart;
    String? idPart;
    List<String> classParts = [];

    // Parse selector parts
    final idMatch = RegExp(r'#([a-zA-Z_-][a-zA-Z0-9_-]*)').firstMatch(selector);
    if (idMatch != null) {
      idPart = idMatch.group(1);
    }

    final classMatches =
        RegExp(r'\.([a-zA-Z_-][a-zA-Z0-9_-]*)').allMatches(selector);
    for (final match in classMatches) {
      classParts.add(match.group(1)!);
    }

    // Element is everything before first . or #
    final elementMatch =
        RegExp(r'^([a-zA-Z][a-zA-Z0-9]*)').firstMatch(selector);
    if (elementMatch != null) {
      elementPart = elementMatch.group(1);
    }

    // Check element
    if (elementPart != null && node.tagName != elementPart) {
      return false;
    }

    // Check ID
    if (idPart != null && node.cssId != idPart) {
      return false;
    }

    // Check all classes
    for (final className in classParts) {
      if (!node.classList.contains(className)) {
        return false;
      }
    }

    return elementPart != null || idPart != null || classParts.isNotEmpty;
  }

  /// Get previous sibling of a node
  UDTNode? _getPreviousSibling(UDTNode node) {
    final parent = node.parent;
    if (parent == null) return null;

    final index = parent.children.indexOf(node);
    if (index <= 0) return null;

    return parent.children[index - 1];
  }

  /// Merge two styles (later style wins) and mark overridden properties as explicit
  ComputedStyle _mergeStyles(ComputedStyle base, ComputedStyle override) {
    final result = ComputedStyle(
      width: override.width ?? base.width,
      height: override.height ?? base.height,
      margin:
          override.margin != EdgeInsets.zero ? override.margin : base.margin,
      padding:
          override.padding != EdgeInsets.zero ? override.padding : base.padding,
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

    // Mark properties from user-agent styles as explicitly set
    // This prevents them from being overridden by inheritance
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

  /// Apply CSS declarations to a style
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

  /// Apply a single CSS declaration
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
    value =
        _resolveCssValue(value, style.customProperties, inheritedCustomProps);

    switch (property) {
      case 'color':
        final color = _parseColor(value);
        if (color != null) {
          style.color = color;
          style.markExplicitlySet('color');
        }
        break;

      case 'background':
        // Shorthand for background-color, background-image, etc.
        if (value.contains('gradient')) {
          final gradient = _parseGradient(value);
          if (gradient != null) {
            style.backgroundGradient = gradient;
            style.markExplicitlySet('background-gradient');
          }
        } else if (value.contains('url(')) {
          final match =
              RegExp(r"""url\(["']?([^"')]+)["']?\)""").firstMatch(value);
          if (match != null) {
            style.backgroundImage = match.group(1);
            style.markExplicitlySet('background-image');
          }
        } else {
          final color = _parseColor(value);
          if (color != null) {
            style.backgroundColor = color;
            style.markExplicitlySet('background-color');
          }
        }

        // Check for background-size in shorthand (simplified)
        if (value.contains('cover')) {
          style.backgroundSize = 'cover';
          style.markExplicitlySet('background-size');
        } else if (value.contains('contain')) {
          style.backgroundSize = 'contain';
          style.markExplicitlySet('background-size');
        }
        break;

      case 'background-color':
        final color = _parseColor(value);
        if (color != null) {
          style.backgroundColor = color;
          style.markExplicitlySet('background-color');
        }
        break;

      case 'background-image':
        if (value.contains('gradient')) {
          final gradient = _parseGradient(value);
          if (gradient != null) {
            style.backgroundGradient = gradient;
            style.markExplicitlySet('background-gradient');
          }
        } else if (value.contains('url(')) {
          final match =
              RegExp(r"""url\(["']?([^"')]+)["']?\)""").firstMatch(value);
          if (match != null) {
            style.backgroundImage = match.group(1);
            style.markExplicitlySet('background-image');
          }
        }
        break;

      case 'background-size':
        style.backgroundSize = value.trim().toLowerCase();
        style.markExplicitlySet('background-size');
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
        final lineHeight =
            _parseLineHeight(value, parentFontSize: parentFontSize);
        if (lineHeight != null) {
          style.lineHeight = lineHeight;
          style.markExplicitlySet('line-height');
        }
        break;

      case 'letter-spacing':
        final spacing =
            _parseLengthWithContext(value, parentFontSize: parentFontSize);
        if (spacing != null) {
          style.letterSpacing = spacing;
          style.markExplicitlySet('letter-spacing');
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

      case 'margin-top':
        final val = _parseLength(value);
        if (val != null) {
          style.margin = style.margin.copyWith(top: val);
          style.markExplicitlySet('margin');
        }
        break;

      case 'margin-bottom':
        final val = _parseLength(value);
        if (val != null) {
          style.margin = style.margin.copyWith(bottom: val);
          style.markExplicitlySet('margin');
        }
        break;

      case 'margin-left':
        final val = _parseLength(value);
        if (val != null) {
          style.margin = style.margin.copyWith(left: val);
          style.markExplicitlySet('margin');
        }
        break;

      case 'margin-right':
        final val = _parseLength(value);
        if (val != null) {
          style.margin = style.margin.copyWith(right: val);
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

      case 'padding-top':
        final val = _parseLength(value);
        if (val != null) {
          style.padding = style.padding.copyWith(top: val);
          style.markExplicitlySet('padding');
        }
        break;

      case 'padding-bottom':
        final val = _parseLength(value);
        if (val != null) {
          style.padding = style.padding.copyWith(bottom: val);
          style.markExplicitlySet('padding');
        }
        break;

      case 'padding-left':
        final val = _parseLength(value);
        if (val != null) {
          style.padding = style.padding.copyWith(left: val);
          style.markExplicitlySet('padding');
        }
        break;

      case 'padding-right':
        final val = _parseLength(value);
        if (val != null) {
          style.padding = style.padding.copyWith(right: val);
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

      case 'border-left':
        final border = _parseBorderShorthand(value);
        if (border != null) {
          style.borderWidth = style.borderWidth.copyWith(left: border.$1);
          style.borderColor = border.$2;
          if (border.$3 != null) style.borderStyle = border.$3!;
          style.markExplicitlySet('border');
        }
        break;

      case 'border':
        final border = _parseBorderShorthand(value);
        if (border != null) {
          style.borderWidth = EdgeInsets.all(border.$1);
          style.borderColor = border.$2;
          if (border.$3 != null) style.borderStyle = border.$3!;
          style.markExplicitlySet('border');
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

      // Flexbox properties
      case 'flex-direction':
        final flexDir = _parseFlexDirection(value);
        if (flexDir != null) {
          style.flexDirection = flexDir;
          style.markExplicitlySet('flex-direction');
        }
        break;

      case 'justify-content':
        final justify = _parseJustifyContent(value);
        if (justify != null) {
          style.justifyContent = justify;
          style.markExplicitlySet('justify-content');
        }
        break;

      case 'align-items':
        final align = _parseAlignItems(value);
        if (align != null) {
          style.alignItems = align;
          style.markExplicitlySet('align-items');
        }
        break;

      case 'align-self':
        final alignSelf = _parseAlignItems(value);
        if (alignSelf != null) {
          style.alignSelf = alignSelf;
          style.markExplicitlySet('align-self');
        }
        break;

      case 'flex-wrap':
        final wrap = _parseFlexWrap(value);
        if (wrap != null) {
          style.flexWrap = wrap;
          style.markExplicitlySet('flex-wrap');
        }
        break;

      case 'gap':
        final length = _parseLength(value);
        if (length != null) {
          style.gap = length;
          style.rowGap = length;
          style.columnGap = length;
          style.markExplicitlySet('gap');
        }
        break;

      case 'row-gap':
        final length = _parseLength(value);
        if (length != null) {
          style.rowGap = length;
          style.markExplicitlySet('row-gap');
        }
        break;

      case 'column-gap':
        final length = _parseLength(value);
        if (length != null) {
          style.columnGap = length;
          style.markExplicitlySet('column-gap');
        }
        break;

      case 'flex':
        // Parse flex shorthand: flex-grow flex-shrink flex-basis
        final parts = value.trim().split(RegExp(r'\s+'));
        if (parts.isNotEmpty) {
          style.flexGrow = double.tryParse(parts[0]) ?? 0;
          if (parts.length > 1) {
            style.flexShrink = double.tryParse(parts[1]) ?? 1;
          }
          if (parts.length > 2) {
            style.flexBasis = _parseLength(parts[2]);
          }
          style.markExplicitlySet('flex');
        }
        break;

      case 'flex-grow':
        final flexGrow = double.tryParse(value.trim());
        if (flexGrow != null) {
          style.flexGrow = flexGrow;
          style.markExplicitlySet('flex-grow');
        }
        break;

      case 'flex-shrink':
        final flexShrink = double.tryParse(value.trim());
        if (flexShrink != null) {
          style.flexShrink = flexShrink;
          style.markExplicitlySet('flex-shrink');
        }
        break;

      case 'flex-basis':
        final flexBasis = _parseLength(value);
        if (flexBasis != null) {
          style.flexBasis = flexBasis;
          style.markExplicitlySet('flex-basis');
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

      case 'text-overflow':
        final textOverflow = _parseTextOverflow(value);
        if (textOverflow != null) {
          style.textOverflow = textOverflow;
          style.markExplicitlySet('text-overflow');
        }
        break;

      case 'word-break':
        style.wordBreak = value.trim().toLowerCase();
        style.markExplicitlySet('word-break');
        break;

      case 'overflow-wrap':
        style.overflowWrap = value.trim().toLowerCase();
        style.markExplicitlySet('overflow-wrap');
        break;

      case 'text-shadow':
        final shadows = _parseTextShadow(value);
        if (shadows != null && shadows.isNotEmpty) {
          style.textShadow = shadows;
          style.markExplicitlySet('text-shadow');
        }
        break;

      case 'box-shadow':
        final shadows = _parseBoxShadow(value);
        if (shadows != null && shadows.isNotEmpty) {
          style.boxShadow = shadows;
          style.markExplicitlySet('box-shadow');
        }
        break;

      case 'filter':
        final filter = _parseFilter(value);
        if (filter != null) {
          style.filter = filter;
          style.markExplicitlySet('filter');
        }
        break;

      case 'backdrop-filter':
        final filter = _parseFilter(value);
        if (filter != null) {
          style.backdropFilter = filter;
          style.markExplicitlySet('backdrop-filter');
        }
        break;

      case 'border-style':
        final borderStyle = _parseBorderStyle(value);
        if (borderStyle != null) {
          style.borderStyle = borderStyle;
          style.markExplicitlySet('border-style');
        }
        break;

      case 'border-top-style':
        final borderStyle = _parseBorderStyle(value);
        if (borderStyle != null) {
          style.borderTopStyle = borderStyle;
          style.markExplicitlySet('border-top-style');
        }
        break;

      case 'border-right-style':
        final borderStyle = _parseBorderStyle(value);
        if (borderStyle != null) {
          style.borderRightStyle = borderStyle;
          style.markExplicitlySet('border-right-style');
        }
        break;

      case 'border-bottom-style':
        final borderStyle = _parseBorderStyle(value);
        if (borderStyle != null) {
          style.borderBottomStyle = borderStyle;
          style.markExplicitlySet('border-bottom-style');
        }
        break;

      case 'border-left-style':
        final borderStyle = _parseBorderStyle(value);
        if (borderStyle != null) {
          style.borderLeftStyle = borderStyle;
          style.markExplicitlySet('border-left-style');
        }
        break;

      case 'direction':
        final direction = _parseDirection(value);
        if (direction != null) {
          style.hyperDirection = direction;
          style.markExplicitlySet('direction');
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
        // Parse "span 2" or "1 / 3" or "1 / span 2"
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

      case 'grid-column-start':
        final v = int.tryParse(value.trim()) ?? 0;
        style.gridColumnStart = v;
        style.markExplicitlySet('grid-column-start');
        break;

      case 'grid-column-end':
        final v = int.tryParse(value.trim()) ?? 0;
        style.gridColumnEnd = v;
        style.markExplicitlySet('grid-column-end');
        break;

      case 'grid-row-start':
        final v = int.tryParse(value.trim()) ?? 0;
        style.gridRowStart = v;
        style.markExplicitlySet('grid-row-start');
        break;

      case 'grid-row-end':
        final v = int.tryParse(value.trim()) ?? 0;
        style.gridRowEnd = v;
        style.markExplicitlySet('grid-row-end');
        break;

      case 'justify-items':
        final ji = _parseJustifyContent(value);
        if (ji != null) {
          style.justifyItems = ji;
          style.markExplicitlySet('justify-items');
        }
        break;

      case 'align-content':
        final ac = _parseJustifyContent(value);
        if (ac != null) {
          style.alignContent = ac;
          style.markExplicitlySet('align-content');
        }
        break;
    }

    return style;
  }

  // ============================================
  // CSS Value Preprocessor (var() and calc())
  // ============================================

  /// Resolve var() and calc() in a CSS value string.
  String _resolveCssValue(
    String value,
    Map<String, String> localCustomProps,
    Map<String, String>? inheritedCustomProps,
  ) {
    if (!value.contains('var(') && !value.contains('calc(')) return value;

    // Merge custom props: local + inherited (local wins)
    final allProps = <String, String>{};
    if (inheritedCustomProps != null) allProps.addAll(inheritedCustomProps);
    allProps.addAll(localCustomProps);

    // Resolve var() first (supports nested: var(--x, fallback))
    value = _resolveVarReferences(value, allProps);

    // Then evaluate calc()
    if (value.contains('calc(')) {
      value = _evaluateCalcInValue(value);
    }

    return value;
  }

  /// Resolve all var(--name, fallback) references in a value string.
  ///
  /// Resolves from innermost outward by matching only leaf var() calls
  /// (those whose content contains no nested parens). This correctly handles
  /// nested fallbacks like var(--a, var(--b, default)).
  String _resolveVarReferences(String value, Map<String, String> customProps) {
    for (int i = 0; i < 10; i++) {
      // [^()]+ ensures we only match leaf var() calls (no nested parens inside)
      final resolved = value.replaceAllMapped(
        RegExp(r'var\(\s*(--[\w-]+)\s*(?:,\s*([^()]+))?\s*\)'),
        (match) {
          final propName = match.group(1)!;
          final fallback = match.group(2)?.trim() ?? '';
          return customProps[propName] ?? fallback;
        },
      );
      if (resolved == value) break; // No more replacements
      value = resolved;
    }
    return value;
  }

  /// Evaluate all calc() expressions in a value string.
  ///
  /// Uses `[^()]+` (innermost-only) regex iterated until no more calc() remain,
  /// so nested expressions like `calc(100% - calc(20px * 2))` are resolved
  /// inside-out: inner `calc(20px * 2)` → `40px` first, then outer calc().
  String _evaluateCalcInValue(String value) {
    // [^()]+ matches only characters that are NOT parens, so it always finds
    // the *innermost* calc() — the one with no nested calls inside.
    final innerCalc = RegExp(r'calc\(([^()]+)\)');
    String current = value;
    // Iterate until stable (each pass resolves one nesting level).
    while (current.contains('calc(')) {
      final next = current.replaceAllMapped(innerCalc, (match) {
        final expr = match.group(1)!;
        final result = _evaluateCalcExpr(expr);
        if (result != null) return '${result}px';
        return match.group(0)!; // Keep original if can't evaluate
      });
      if (next == current) break; // No progress — avoid infinite loop
      current = next;
    }
    return current;
  }

  /// Evaluate a CSS calc() arithmetic expression to a pixel value.
  ///
  /// Supports: px, em (×16), rem (×16), unitless numbers.
  /// Operators: +, -, *, /
  /// Percentage values are preserved as-is (returned as null = skip).
  double? _evaluateCalcExpr(String expr) {
    expr = expr.trim();

    // Tokenize the expression — leading minus handled as part of number token
    final tokenPattern = RegExp(
      r'(-?[\d.]+)(px|em|rem|%)?\s*|([+\-*/])',
    );
    final tokens = tokenPattern.allMatches(expr).toList();
    if (tokens.isEmpty) return null;

    // Parse tokens into (value, operator) pairs
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
          case 'px':
          case '':
            px = num;
            break;
          case 'em':
          case 'rem':
            px = num * StyleResolver.rootFontSize;
            break;
          case '%':
            return null; // Can't resolve % without context
          default:
            px = num;
        }
        values.add(px);
      } else if (op != null) {
        operators.add(op);
      }
    }

    if (values.isEmpty) return null;
    if (values.length != operators.length + 1) return null;

    // First pass: handle * and /
    final vals = List<double>.from(values);
    final ops = List<String>.from(operators);
    int i = 0;
    while (i < ops.length) {
      if (ops[i] == '*') {
        vals[i] = vals[i] * vals[i + 1];
        vals.removeAt(i + 1);
        ops.removeAt(i);
      } else if (ops[i] == '/') {
        if (vals[i + 1] == 0) return null;
        vals[i] = vals[i] / vals[i + 1];
        vals.removeAt(i + 1);
        ops.removeAt(i);
      } else {
        i++;
      }
    }

    // Second pass: handle + and -
    double result = vals[0];
    for (int j = 0; j < ops.length; j++) {
      if (ops[j] == '+') {
        result += vals[j + 1];
      } else if (ops[j] == '-') {
        result -= vals[j + 1];
      }
    }

    return result;
  }

  /// Parse grid-column / grid-row shorthand.
  /// Returns (start, end, span) tuple.
  /// Examples: "span 2" → (0, 0, 2), "1 / 3" → (1, 3, 1), "auto" → (0, 0, 1)
  (int, int, int) _parseGridLine(String value) {
    value = value.trim().toLowerCase();
    if (value == 'auto') return (0, 0, 1);

    // "span N"
    final spanMatch = RegExp(r'^span\s+(\d+)$').firstMatch(value);
    if (spanMatch != null) {
      final span = int.tryParse(spanMatch.group(1)!) ?? 1;
      return (0, 0, span);
    }

    // "start / end" or "start / span N"
    if (value.contains('/')) {
      final parts = value.split('/').map((p) => p.trim()).toList();
      if (parts.length == 2) {
        final start = int.tryParse(parts[0]) ?? 0;
        final endStr = parts[1];
        final spanMatch2 = RegExp(r'^span\s+(\d+)$').firstMatch(endStr);
        if (spanMatch2 != null) {
          final span = int.tryParse(spanMatch2.group(1)!) ?? 1;
          return (start, 0, span);
        }
        final end = int.tryParse(endStr) ?? 0;
        return (start, end, end > start ? end - start : 1);
      }
    }

    // Plain integer
    final n = int.tryParse(value) ?? 0;
    return (n, 0, 1);
  }

  /// Parse line-height value
  double? _parseLineHeight(String value, {double? parentFontSize}) {
    value = value.trim().toLowerCase();
    if (value == 'normal') return null;
    // Unitless number (multiplier)
    final multiplier = double.tryParse(value);
    if (multiplier != null) return multiplier;
    // With units - convert to multiplier
    final length =
        _parseLengthWithContext(value, parentFontSize: parentFontSize);
    if (length != null && parentFontSize != null) {
      return length / parentFontSize;
    }
    return null;
  }

  /// Parse text-align value
  HyperTextAlign? _parseTextAlign(String value) {
    switch (value.trim().toLowerCase()) {
      case 'left':
        return HyperTextAlign.left;
      case 'center':
        return HyperTextAlign.center;
      case 'right':
        return HyperTextAlign.right;
      case 'justify':
        return HyperTextAlign.justify;
      default:
        return null;
    }
  }

  /// Parse border-radius value
  BorderRadius? _parseBorderRadius(String value) {
    final length = _parseLength(value);
    if (length != null) {
      return BorderRadius.circular(length);
    }
    return null;
  }

  /// Parse border shorthand (e.g., "1px solid red")
  (double, Color, HyperBorderStyle?)? _parseBorderShorthand(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    double width = 1.0;
    Color color = const Color(0xFF000000);
    HyperBorderStyle? borderStyle;

    for (final part in parts) {
      final w = _parseLength(part);
      if (w != null) {
        width = w;
        continue;
      }
      final s = _parseBorderStyle(part);
      if (s != null) {
        borderStyle = s;
        continue;
      }
      final c = _parseColor(part);
      if (c != null) {
        color = c;
      }
    }
    return (width, color, borderStyle);
  }

  /// Parse CSS float value
  HyperFloat? _parseFloat(String value) {
    switch (value.toLowerCase().trim()) {
      case 'left':
        return HyperFloat.left;
      case 'right':
        return HyperFloat.right;
      case 'none':
        return HyperFloat.none;
      default:
        return null;
    }
  }

  /// Parse CSS clear value
  HyperClear? _parseClear(String value) {
    switch (value.toLowerCase().trim()) {
      case 'left':
        return HyperClear.left;
      case 'right':
        return HyperClear.right;
      case 'both':
        return HyperClear.both;
      case 'none':
        return HyperClear.none;
      default:
        return null;
    }
  }

  /// Parse text-overflow value
  TextOverflow? _parseTextOverflow(String value) {
    switch (value.toLowerCase().trim()) {
      case 'clip':
        return TextOverflow.clip;
      case 'ellipsis':
        return TextOverflow.ellipsis;
      case 'fade':
        return TextOverflow.fade;
      case 'visible':
        return TextOverflow.visible;
      default:
        return null;
    }
  }

  /// Parse text-shadow value
  /// Supports multiple shadows: "2px 2px 4px rgba(0,0,0,0.5), 1px 1px 2px red"
  List<Shadow>? _parseTextShadow(String value) {
    if (value.toLowerCase().trim() == 'none') return null;

    final shadows = <Shadow>[];
    // Split by comma for multiple shadows
    final shadowDefinitions = value.split(',');

    for (final shadowDef in shadowDefinitions) {
      final parts = shadowDef.trim().split(RegExp(r'\s+'));
      if (parts.length < 3) continue; // Need at least x y blur

      double offsetX = 0;
      double offsetY = 0;
      double blurRadius = 0;
      Color color = const Color(0x33000000); // Default semi-transparent black

      // Parse values
      int numIndex = 0;
      for (final part in parts) {
        // Try to parse as length
        final length = _parseLength(part);
        if (length != null) {
          if (numIndex == 0) {
            offsetX = length;
          } else if (numIndex == 1) {
            offsetY = length;
          } else if (numIndex == 2) {
            blurRadius = length;
          }
          numIndex++;
          continue;
        }

        // Try to parse as color
        final parsedColor = _parseColor(part);
        if (parsedColor != null) {
          color = parsedColor;
        }
      }

      shadows.add(Shadow(
        offset: Offset(offsetX, offsetY),
        blurRadius: blurRadius,
        color: color,
      ));
    }

    return shadows.isEmpty ? null : shadows;
  }

  /// Parse box-shadow value
  /// Supports multiple shadows: "2px 2px 4px rgba(0,0,0,0.5), 1px 1px 2px red"
  List<BoxShadow>? _parseBoxShadow(String value) {
    if (value.toLowerCase().trim() == 'none') return null;

    final shadows = <BoxShadow>[];
    // Split by comma for multiple shadows
    final shadowDefinitions = value.split(',');

    for (final shadowDef in shadowDefinitions) {
      final parts = shadowDef.trim().split(RegExp(r'\s+'));
      if (parts.length < 2) continue; // Need at least x y

      double offsetX = 0;
      double offsetY = 0;
      double blurRadius = 0;
      double spreadRadius = 0;
      Color color = const Color(0x33000000); // Default semi-transparent black
      bool isInset = false;

      // Parse values
      int numIndex = 0;
      for (final part in parts) {
        if (part.toLowerCase() == 'inset') {
          isInset = true;
          continue;
        }

        // Try to parse as length
        final length = _parseLength(part);
        if (length != null) {
          if (numIndex == 0) {
            offsetX = length;
          } else if (numIndex == 1) {
            offsetY = length;
          } else if (numIndex == 2) {
            blurRadius = length;
          } else if (numIndex == 3) {
            spreadRadius = length;
          }
          numIndex++;
          continue;
        }

        // Try to parse as color
        final parsedColor = _parseColor(part);
        if (parsedColor != null) {
          color = parsedColor;
        }
      }

      shadows.add(BoxShadow(
        offset: Offset(offsetX, offsetY),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        color: color,
        // Flutter doesn't have a direct 'inset' property in BoxShadow,
        // but BlurStyle.inner can simulate it for some cases.
        blurStyle: isInset ? BlurStyle.inner : BlurStyle.normal,
      ));
    }

    return shadows.isEmpty ? null : shadows;
  }

  /// Parse CSS gradient
  Gradient? _parseGradient(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('linear-gradient(')) {
      return _parseLinearGradient(trimmed);
    }
    return null;
  }

  /// Basic linear-gradient parser
  Gradient? _parseLinearGradient(String value) {
    // Format: linear-gradient([angle | to side]?, color-stop1, color-stop2, ...)
    final contentMatch = RegExp(r'linear-gradient\((.*)\)').firstMatch(value);
    if (contentMatch == null) return null;

    final content = contentMatch.group(1)!;
    final parts = _splitGradientParts(content);
    if (parts.length < 2) return null;

    Alignment begin = Alignment.topCenter;
    Alignment end = Alignment.bottomCenter;
    int colorStartIndex = 0;

    // Check first part for direction
    final firstPart = parts[0].toLowerCase();
    if (firstPart.contains('to ')) {
      if (firstPart.contains('right')) {
        begin = Alignment.centerLeft;
        end = Alignment.centerRight;
        if (firstPart.contains('top')) begin = Alignment.bottomLeft;
        if (firstPart.contains('bottom')) begin = Alignment.topLeft;
      } else if (firstPart.contains('left')) {
        begin = Alignment.centerRight;
        end = Alignment.centerLeft;
        if (firstPart.contains('top')) begin = Alignment.bottomRight;
        if (firstPart.contains('bottom')) begin = Alignment.topRight;
      } else if (firstPart.contains('bottom')) {
        begin = Alignment.topCenter;
        end = Alignment.bottomCenter;
      } else if (firstPart.contains('top')) {
        begin = Alignment.bottomCenter;
        end = Alignment.topCenter;
      }
      colorStartIndex = 1;
    } else if (RegExp(r'^\d+deg').hasMatch(firstPart)) {
      // Simplified angle handling: 0deg=top, 90deg=right, 180deg=bottom, 270deg=left
      final angle = double.tryParse(
          RegExp(r'^\d+').firstMatch(firstPart)?.group(0) ?? '180');
      if (angle != null) {
        if (angle >= 45 && angle < 135) {
          begin = Alignment.centerLeft;
          end = Alignment.centerRight;
        } else if (angle >= 135 && angle < 225) {
          begin = Alignment.topCenter;
          end = Alignment.bottomCenter;
        } else if (angle >= 225 && angle < 315) {
          begin = Alignment.centerRight;
          end = Alignment.centerLeft;
        } else {
          begin = Alignment.bottomCenter;
          end = Alignment.topCenter;
        }
      }
      colorStartIndex = 1;
    }

    final colors = <Color>[];
    final stops = <double>[];

    for (int i = colorStartIndex; i < parts.length; i++) {
      final colorPart = parts[i].trim();
      final colorMatch =
          RegExp(r'^([^(]+(?:\([^)]*\))?)\s*(.*)$').firstMatch(colorPart);
      if (colorMatch == null) continue;

      final colorStr = colorMatch.group(1)!.trim();
      final stopStr = colorMatch.group(2)!.trim();

      final color = _parseColor(colorStr);
      if (color != null) {
        colors.add(color);
        if (stopStr.isNotEmpty) {
          final stop = _parsePercent(stopStr);
          if (stop != null) stops.add(stop);
        }
      }
    }

    if (colors.length < 2) return null;

    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
      stops: stops.length == colors.length ? stops : null,
    );
  }

  double? _parsePercent(String value) {
    final match = RegExp(r'(\d+(?:\.\d+)?)%').firstMatch(value);
    if (match != null) {
      return double.parse(match.group(1)!) / 100.0;
    }
    return null;
  }

  List<String> _splitGradientParts(String inner) {
    final parts = <String>[];
    int depth = 0;
    int start = 0;
    for (int i = 0; i < inner.length; i++) {
      if (inner[i] == '(') {
        depth++;
      } else if (inner[i] == ')') {
        depth--;
      } else if (inner[i] == ',' && depth == 0) {
        parts.add(inner.substring(start, i).trim());
        start = i + 1;
      }
    }
    parts.add(inner.substring(start).trim());
    return parts;
  }

  /// Parse CSS filter property: blur(5px) brightness(1.5) contrast(0.8)
  ui.ImageFilter? _parseFilter(String value) {
    if (value.toLowerCase().trim() == 'none') return null;

    final filterFuncs =
        RegExp(r'([a-z-]+)\(([^)]+)\)').allMatches(value.toLowerCase());
    if (filterFuncs.isEmpty) return null;

    final filters = <ui.ImageFilter>[];

    for (final match in filterFuncs) {
      final name = match.group(1);
      final args = match.group(2)!;

      switch (name) {
        case 'blur':
          final radius = _parseLength(args) ?? 0;
          if (radius > 0) {
            filters.add(ui.ImageFilter.blur(sigmaX: radius, sigmaY: radius));
          }
          break;
        case 'brightness':
          final amount = double.tryParse(args.replaceAll('%', '')) ?? 1.0;
          final factor = args.contains('%') ? amount / 100.0 : amount;
          if (factor != 1.0) {
            final matrix = <double>[
              factor,
              0,
              0,
              0,
              0,
              0,
              factor,
              0,
              0,
              0,
              0,
              0,
              factor,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ];
            filters.add(ui.ColorFilter.matrix(matrix));
          }
          break;
        case 'contrast':
          final amount = double.tryParse(args.replaceAll('%', '')) ?? 1.0;
          final factor = args.contains('%') ? amount / 100.0 : amount;
          if (factor != 1.0) {
            final t = (1.0 - factor) / 2.0;
            final matrix = <double>[
              factor,
              0,
              0,
              0,
              t * 255,
              0,
              factor,
              0,
              0,
              t * 255,
              0,
              0,
              factor,
              0,
              t * 255,
              0,
              0,
              0,
              1,
              0,
            ];
            filters.add(ui.ColorFilter.matrix(matrix));
          }
          break;
      }
    }

    if (filters.isEmpty) return null;
    if (filters.length == 1) return filters.first;

    return ui.ImageFilter.compose(
      outer: filters[0],
      inner: filters.length > 1
          ? filters[1]
          : filters[0], // Simplified compose for 2
    );
  }

  /// Parse border-style value
  HyperBorderStyle? _parseBorderStyle(String value) {
    switch (value.toLowerCase().trim()) {
      case 'none':
        return HyperBorderStyle.none;
      case 'solid':
        return HyperBorderStyle.solid;
      case 'dashed':
        return HyperBorderStyle.dashed;
      case 'dotted':
        return HyperBorderStyle.dotted;
      case 'double':
        return HyperBorderStyle.double;
      case 'groove':
        return HyperBorderStyle.groove;
      case 'ridge':
        return HyperBorderStyle.ridge;
      case 'inset':
        return HyperBorderStyle.inset;
      case 'outset':
        return HyperBorderStyle.outset;
      default:
        return null;
    }
  }

  /// Parse direction value
  HyperTextDirection? _parseDirection(String value) {
    switch (value.toLowerCase().trim()) {
      case 'ltr':
        return HyperTextDirection.ltr;
      case 'rtl':
        return HyperTextDirection.rtl;
      default:
        return null;
    }
  }

  /// Parse inline style attribute.
  ///
  /// Uses a paren-aware tokenizer to split on `;` only at depth 0.
  /// This correctly handles function calls such as `url('data:image/png;...')`,
  /// `calc(100% - 20px)`, `rgb(255,0,0)`, `var(--x)`, and `linear-gradient(…)`
  /// that contain semicolons, commas, or colons inside parentheses.
  ComputedStyle _parseInlineStyle(
    ComputedStyle style,
    String inlineStyle, {
    double? parentFontSize,
    Map<String, String>? inheritedCustomProps,
  }) {
    if (inlineStyle.isEmpty) return style;

    // Split on ';' only when not inside any pair of parentheses.
    final declarations = _splitDeclarations(inlineStyle);

    for (final decl in declarations) {
      // Split on the FIRST ':' to separate property from value.
      // (Values like `url(http://…)` contain colons — only the first one matters.)
      final colonIdx = decl.indexOf(':');
      if (colonIdx <= 0) continue;
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
    return style;
  }

  /// Split a CSS declaration block on `;` while respecting parentheses.
  ///
  /// A `;` inside `(…)` (e.g. inside `url(…)`, `calc(…)`, `rgb(…)`) is NOT
  /// treated as a declaration separator.
  static List<String> _splitDeclarations(String declarations) {
    final parts = <String>[];
    int depth = 0;
    int start = 0;
    for (int i = 0; i < declarations.length; i++) {
      final ch = declarations[i];
      if (ch == '(') {
        depth++;
      } else if (ch == ')') {
        if (depth > 0) depth--;
      } else if (ch == ';' && depth == 0) {
        final part = declarations.substring(start, i).trim();
        if (part.isNotEmpty) parts.add(part);
        start = i + 1;
      }
    }
    final last = declarations.substring(start).trim();
    if (last.isNotEmpty) parts.add(last);
    return parts;
  }

  /// Apply inheritance from parent
  ///
  /// Only inheritable properties are inherited, and only if not explicitly set.
  /// CSS Inheritable properties: color, font-*, line-height, letter-spacing,
  /// word-spacing, text-align, white-space, etc.
  void _applyInheritance(ComputedStyle style, ComputedStyle parentStyle) {
    // Color - inherit if not explicitly set
    if (!style.isExplicitlySet('color')) {
      style.color = parentStyle.color;
    }

    // Font size - inherit if not explicitly set
    if (!style.isExplicitlySet('font-size')) {
      style.fontSize = parentStyle.fontSize;
    }

    // Font weight - inherit if not explicitly set
    if (!style.isExplicitlySet('font-weight')) {
      style.fontWeight = parentStyle.fontWeight;
    }

    // Font style - inherit if not explicitly set
    if (!style.isExplicitlySet('font-style')) {
      style.fontStyle = parentStyle.fontStyle;
    }

    // Font family - inherit if not explicitly set
    if (!style.isExplicitlySet('font-family')) {
      style.fontFamily = parentStyle.fontFamily;
    }

    // Line height - inherit if not explicitly set
    if (!style.isExplicitlySet('line-height')) {
      style.lineHeight = parentStyle.lineHeight;
    }

    // Letter spacing - inherit if not explicitly set
    if (!style.isExplicitlySet('letter-spacing')) {
      style.letterSpacing = parentStyle.letterSpacing;
    }

    // Word spacing - inherit if not explicitly set
    if (!style.isExplicitlySet('word-spacing')) {
      style.wordSpacing = parentStyle.wordSpacing;
    }

    // Text align - inherit if not explicitly set
    if (!style.isExplicitlySet('text-align')) {
      style.textAlign = parentStyle.textAlign;
    }

    // White space - inherit if not explicitly set
    style.whiteSpace ??= parentStyle.whiteSpace;

    // Direction - inherit if not explicitly set
    if (!style.isExplicitlySet('direction')) {
      style.hyperDirection ??= parentStyle.hyperDirection;
    }

    // CSS custom properties cascade: always inherit parent's props, with child
    // definitions taking precedence (same as CSS spec for custom properties)
    if (parentStyle.customProperties.isNotEmpty) {
      final inherited = Map<String, String>.from(parentStyle.customProperties);
      inherited.addAll(style.customProperties); // child overrides parent
      style.customProperties = inherited;
    }
  }

  // ============================================
  // CSS Value Parsers
  // ============================================

  /// Parse CSS color value
  Color? _parseColor(String value) {
    value = value.trim().toLowerCase();

    // Hex color
    if (value.startsWith('#')) {
      final hex = value.substring(1);
      if (hex.length == 3) {
        // #RGB -> #RRGGBB
        final r = hex[0] + hex[0];
        final g = hex[1] + hex[1];
        final b = hex[2] + hex[2];
        return Color(int.parse('FF$r$g$b', radix: 16));
      } else if (hex.length == 4) {
        // CSS Color Level 4: #RGBA → each digit expands to two
        final r = hex[0] + hex[0];
        final g = hex[1] + hex[1];
        final b = hex[2] + hex[2];
        final a = hex[3] + hex[3];
        return Color(int.parse('$a$r$g$b', radix: 16));
      } else if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        // CSS: #RRGGBBAA → Flutter Color: 0xAARRGGBB
        final r = hex.substring(0, 2);
        final g = hex.substring(2, 4);
        final b = hex.substring(4, 6);
        final a = hex.substring(6, 8);
        return Color(int.parse('$a$r$g$b', radix: 16));
      }
    }

    // rgb(r, g, b) — supports negative values (clamped to 0)
    final rgbMatch =
        RegExp(r'rgb\((-?\d+),\s*(-?\d+),\s*(-?\d+)\)').firstMatch(value);
    if (rgbMatch != null) {
      final r = int.parse(rgbMatch.group(1)!).clamp(0, 255);
      final g = int.parse(rgbMatch.group(2)!).clamp(0, 255);
      final b = int.parse(rgbMatch.group(3)!).clamp(0, 255);
      return Color.fromARGB(255, r, g, b);
    }

    // rgba(r, g, b, a) — supports negative alpha (clamped to 0)
    final rgbaMatch =
        RegExp(r'rgba\((-?\d+),\s*(-?\d+),\s*(-?\d+),\s*(-?[\d.]+)\)')
            .firstMatch(value);
    if (rgbaMatch != null) {
      final r = int.parse(rgbaMatch.group(1)!).clamp(0, 255);
      final g = int.parse(rgbaMatch.group(2)!).clamp(0, 255);
      final b = int.parse(rgbaMatch.group(3)!).clamp(0, 255);
      final alpha =
          (double.tryParse(rgbaMatch.group(4)!) ?? 1.0).clamp(0.0, 1.0);
      return Color.fromARGB((alpha * 255).round(), r, g, b);
    }

    // Named colors
    return _namedColors[value];
  }

  /// Root font size for rem calculations (browser default is 16px)
  static const double rootFontSize = 16.0;

  /// Parse CSS font-size value
  ///
  /// [parentFontSize] is used for em calculations
  double? _parseFontSize(String value, {double? parentFontSize}) {
    value = value.trim().toLowerCase();

    // px value
    if (value.endsWith('px')) {
      return double.tryParse(value.replaceAll('px', ''));
    }

    // pt value (1pt = 1.333px)
    if (value.endsWith('pt')) {
      final pt = double.tryParse(value.replaceAll('pt', ''));
      return pt != null ? pt * 1.333 : null;
    }

    // rem value (relative to root font size)
    if (value.endsWith('rem')) {
      final rem = double.tryParse(value.replaceAll('rem', ''));
      return rem != null ? rem * rootFontSize : null;
    }

    // em value (relative to parent font size)
    if (value.endsWith('em')) {
      final em = double.tryParse(value.replaceAll('em', ''));
      if (em == null) return null;
      final base = parentFontSize ?? rootFontSize;
      return em * base;
    }

    // % value (relative to parent font size)
    if (value.endsWith('%')) {
      final percent = double.tryParse(value.replaceAll('%', ''));
      if (percent == null) return null;
      final base = parentFontSize ?? rootFontSize;
      return (percent / 100) * base;
    }

    // Keyword sizes
    switch (value) {
      case 'xx-small':
        return 9.0;
      case 'x-small':
        return 10.0;
      case 'small':
        return 13.0;
      case 'medium':
        return 16.0;
      case 'large':
        return 18.0;
      case 'x-large':
        return 24.0;
      case 'xx-large':
        return 32.0;
      case 'smaller':
        return (parentFontSize ?? rootFontSize) * 0.833;
      case 'larger':
        return (parentFontSize ?? rootFontSize) * 1.2;
    }

    // Plain number
    return double.tryParse(value);
  }

  /// Parse CSS length value with relative unit support
  ///
  /// [parentFontSize] is used for em calculations
  /// [rootFontSize] is used for rem calculations
  double? _parseLengthWithContext(
    String value, {
    double? parentFontSize,
  }) {
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
    if (value == '0') return 0;

    return double.tryParse(value);
  }

  /// Parse CSS font-weight value
  FontWeight? _parseFontWeight(String value) {
    value = value.trim().toLowerCase();

    switch (value) {
      case 'normal':
      case '400':
        return FontWeight.normal;
      case 'bold':
      case '700':
        return FontWeight.bold;
      case '100':
        return FontWeight.w100;
      case '200':
        return FontWeight.w200;
      case '300':
        return FontWeight.w300;
      case '500':
        return FontWeight.w500;
      case '600':
        return FontWeight.w600;
      case '800':
        return FontWeight.w800;
      case '900':
        return FontWeight.w900;
      default:
        return null;
    }
  }

  /// Parse CSS font-style value
  FontStyle? _parseFontStyle(String value) {
    value = value.trim().toLowerCase();
    switch (value) {
      case 'normal':
        return FontStyle.normal;
      case 'italic':
        return FontStyle.italic;
      default:
        return null;
    }
  }

  /// Parse CSS text-decoration value
  TextDecoration? _parseTextDecoration(String value) {
    value = value.trim().toLowerCase();
    switch (value) {
      case 'none':
        return TextDecoration.none;
      case 'underline':
        return TextDecoration.underline;
      case 'overline':
        return TextDecoration.overline;
      case 'line-through':
        return TextDecoration.lineThrough;
      default:
        return null;
    }
  }

  /// Parse CSS edge insets (margin, padding)
  EdgeInsets? _parseEdgeInsets(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    final values = parts.map((p) => _parseLength(p) ?? 0.0).toList();

    switch (values.length) {
      case 1:
        return EdgeInsets.all(values[0]);
      case 2:
        return EdgeInsets.symmetric(vertical: values[0], horizontal: values[1]);
      case 3:
        return EdgeInsets.only(
          top: values[0],
          left: values[1],
          right: values[1],
          bottom: values[2],
        );
      case 4:
        return EdgeInsets.only(
          top: values[0],
          right: values[1],
          bottom: values[2],
          left: values[3],
        );
      default:
        return null;
    }
  }

  /// Parse CSS length value (px, pt, em, etc.)
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
      final em = double.tryParse(value.replaceAll('em', ''));
      return em != null ? em * rootFontSize : null;
    }
    if (value == '0') return 0;

    return double.tryParse(value);
  }

  /// Parse CSS display value
  DisplayType? _parseDisplay(String value) {
    switch (value.trim().toLowerCase()) {
      case 'block':
        return DisplayType.block;
      case 'inline':
        return DisplayType.inline;
      case 'inline-block':
        return DisplayType.inlineBlock;
      case 'flex':
        return DisplayType.flex;
      case 'grid':
        return DisplayType.grid;
      case 'none':
        return DisplayType.none;
      case 'table':
        return DisplayType.table;
      case 'table-row':
        return DisplayType.tableRow;
      case 'table-cell':
        return DisplayType.tableCell;
      default:
        return null;
    }
  }

  /// Parse CSS flex-direction value
  FlexDirection? _parseFlexDirection(String value) {
    switch (value.trim().toLowerCase()) {
      case 'row':
        return FlexDirection.row;
      case 'row-reverse':
        return FlexDirection.rowReverse;
      case 'column':
        return FlexDirection.column;
      case 'column-reverse':
        return FlexDirection.columnReverse;
      default:
        return null;
    }
  }

  /// Parse CSS justify-content value
  JustifyContent? _parseJustifyContent(String value) {
    switch (value.trim().toLowerCase()) {
      case 'flex-start':
      case 'start':
        return JustifyContent.flexStart;
      case 'flex-end':
      case 'end':
        return JustifyContent.flexEnd;
      case 'center':
        return JustifyContent.center;
      case 'space-between':
        return JustifyContent.spaceBetween;
      case 'space-around':
        return JustifyContent.spaceAround;
      case 'space-evenly':
        return JustifyContent.spaceEvenly;
      default:
        return null;
    }
  }

  /// Parse CSS align-items value
  AlignItems? _parseAlignItems(String value) {
    switch (value.trim().toLowerCase()) {
      case 'flex-start':
      case 'start':
        return AlignItems.flexStart;
      case 'flex-end':
      case 'end':
        return AlignItems.flexEnd;
      case 'center':
        return AlignItems.center;
      case 'baseline':
        return AlignItems.baseline;
      case 'stretch':
        return AlignItems.stretch;
      default:
        return null;
    }
  }

  /// Parse CSS flex-wrap value
  FlexWrap? _parseFlexWrap(String value) {
    switch (value.trim().toLowerCase()) {
      case 'nowrap':
        return FlexWrap.nowrap;
      case 'wrap':
        return FlexWrap.wrap;
      case 'wrap-reverse':
        return FlexWrap.wrapReverse;
      default:
        return null;
    }
  }

  /// Named CSS colors
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

/// A CSS rule with selector and declarations
class CssRule {
  final String selector;
  final Map<String, String> declarations;

  /// Declarations marked with `!important` — applied after inline styles.
  final Map<String, String> importantDeclarations;
  final int specificity;

  /// Source order index — used to make specificity sort stable (later = higher)
  final int sourceIndex;

  CssRule({
    required this.selector,
    required this.declarations,
    Map<String, String>? importantDeclarations,
    required this.specificity,
    this.sourceIndex = 0,
  }) : importantDeclarations = importantDeclarations ?? const {};

  @override
  String toString() => 'CssRule($selector, specificity=$specificity, '
      '${declarations.length} normal + ${importantDeclarations.length} !important)';
}
