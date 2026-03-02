import 'package:csslib/parser.dart' as css_parser;
import 'package:csslib/visitor.dart' as css_ast;
import 'package:hyper_render_core/hyper_render_core.dart';

/// Default CSS parser using csslib package
///
/// Provides full CSS stylesheet parsing with specificity calculation.
/// This is the default implementation provided by HyperRender.
class DefaultCssParser implements CssParserInterface {
  const DefaultCssParser();

  @override
  List<ParsedCssRule> parseStylesheet(String css) {
    if (css.isEmpty) return const [];

    try {
      final stylesheet = css_parser.parse(css);
      return _extractRules(stylesheet);
    } catch (e) {
      // Log CSS parsing error but don't throw
      // Return empty list for invalid CSS
      return const [];
    }
  }

  List<ParsedCssRule> _extractRules(css_ast.StyleSheet stylesheet) {
    final rules = <ParsedCssRule>[];

    for (final topLevel in stylesheet.topLevels) {
      if (topLevel is css_ast.RuleSet) {
        // Each individual selector in a comma group gets its own ParsedCssRule
        // so that specificity is computed per-selector (CSS spec §16.1).
        rules.addAll(_expandRuleSet(topLevel));
      }
    }

    // Sort rules by specificity (lower first, so higher specificity wins)
    rules.sort((a, b) => a.specificity.compareTo(b.specificity));
    return rules;
  }

  /// Expand a RuleSet into one [ParsedCssRule] per individual selector.
  ///
  /// `h1, h2 { color: red }` → two rules: one for `h1`, one for `h2`, each
  /// with its own specificity value.  Comma-grouped rules are no longer
  /// collapsed into a single selector string, which was the root cause of
  /// them being mis-indexed and mis-matched as descendant selectors.
  List<ParsedCssRule> _expandRuleSet(css_ast.RuleSet ruleSet) {
    // Extract declarations (shared across all selectors in this rule set)
    final declarations = <String, String>{};
    final importantDeclarations = <String, String>{};
    for (final declaration in ruleSet.declarationGroup.declarations) {
      if (declaration is css_ast.Declaration) {
        final property = declaration.property;
        final value = _extractValue(declaration.expression);
        if (property.isNotEmpty && value.isNotEmpty) {
          if (declaration.important == true) {
            importantDeclarations[property] = value;
          } else {
            declarations[property] = value;
          }
        }
      }
    }

    if (declarations.isEmpty && importantDeclarations.isEmpty) return const [];

    final selectorGroup = ruleSet.selectorGroup;
    if (selectorGroup == null) return const [];

    final results = <ParsedCssRule>[];
    for (final selector in selectorGroup.selectors) {
      final selectorText = selector.span?.text?.trim() ?? '';
      if (selectorText.isEmpty) continue;
      results.add(ParsedCssRule(
        selector: selectorText,
        declarations: declarations,
        importantDeclarations: importantDeclarations.isEmpty
            ? null
            : importantDeclarations,
        specificity: _calculateSpecificity(selectorText),
      ));
    }
    return results;
  }

  String _extractSelector(css_ast.SelectorGroup? selectorGroup) {
    if (selectorGroup == null) return '';
    // Filter out null/empty spans to avoid malformed selectors like "div, , p".
    return selectorGroup.selectors
        .map((s) => s.span?.text?.trim())
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(', ');
  }

  String _extractValue(css_ast.Expression? expression) {
    if (expression == null) return '';
    // csslib sets Expressions.span to only the first character for some value
    // types (e.g. hex colors get span '#' instead of the full '#E53935').
    // Iterate the individual term spans first for an accurate reconstruction.
    if (expression is css_ast.Expressions) {
      final termText = expression.expressions
          .map<String>((t) => t.span?.text.trim() ?? '')
          .where((s) => s.isNotEmpty)
          .join(' ');
      if (termText.isNotEmpty) return termText;
    }
    return expression.span?.text.trim() ?? '';
  }

  /// Calculate CSS specificity for a selector
  /// Returns a single int encoding [inline, id, class, element] weight
  int _calculateSpecificity(String selector) {
    int ids = 0;
    int classes = 0;
    int elements = 0;

    // Count IDs (#id)
    ids = RegExp(r'#[a-zA-Z_-][\w-]*').allMatches(selector).length;

    // Count classes (.class), attributes ([attr]), and pseudo-classes (:hover)
    classes = RegExp(r'\.[a-zA-Z_-][\w-]*').allMatches(selector).length;
    classes += RegExp(r'\[[^\]]+\]').allMatches(selector).length;
    classes +=
        RegExp(r':[a-zA-Z_-][\w-]*(?!\()').allMatches(selector).length;

    // Count elements (tag names) and pseudo-elements (::before)
    // This is simplified - doesn't handle all edge cases
    elements = RegExp(r'(?:^|\s|>|\+|~)([a-zA-Z][a-zA-Z0-9]*)')
        .allMatches(selector)
        .length;
    elements += RegExp(r'::[a-zA-Z_-][\w-]*').allMatches(selector).length;

    // Combine into single int: [0][ids][classes][elements]
    // Each segment can hold up to 255
    return (ids * 65536) + (classes * 256) + elements;
  }

  @override
  Map<String, String> parseInlineStyle(String style) {
    final result = <String, String>{};
    if (style.isEmpty) return result;

    final declarations = style.split(';');
    for (final decl in declarations) {
      final colonIndex = decl.indexOf(':');
      if (colonIndex > 0) {
        final property = decl.substring(0, colonIndex).trim();
        final rawValue = decl.substring(colonIndex + 1).trim();
        // Strip !important — not supported in inline styles; use specificity instead.
        final value = rawValue.replaceAll(
            RegExp(r'\s*!important\s*$', caseSensitive: false), '');
        if (property.isNotEmpty && value.isNotEmpty) {
          result[property] = value;
        }
      }
    }
    return result;
  }
}
