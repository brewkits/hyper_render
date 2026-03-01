/// Interface for CSS parsing plugins
///
/// Implement this interface to provide custom CSS parsing.
/// Default implementation uses csslib package.
///
/// Example custom implementation:
/// ```dart
/// class CustomCssParser implements CssParserInterface {
///   @override
///   List<ParsedCssRule> parseStylesheet(String css) {
///     // Custom CSS parsing logic
///     return [...];
///   }
///
///   @override
///   Map<String, String> parseInlineStyle(String style) {
///     // Parse style="..." attribute
///     return {...};
///   }
/// }
/// ```
abstract class CssParserInterface {
  /// Parse a CSS stylesheet string into rules
  ///
  /// [css] - The CSS stylesheet content
  /// Returns a list of parsed CSS rules
  List<ParsedCssRule> parseStylesheet(String css);

  /// Parse an inline style attribute
  ///
  /// [style] - The style attribute value (e.g., "color: red; font-size: 16px")
  /// Returns a map of property -> value
  Map<String, String> parseInlineStyle(String style);
}

/// Represents a parsed CSS rule
///
/// This is a simple data class that can be created by any CSS parser.
class ParsedCssRule {
  /// The CSS selector (e.g., "h1", ".class", "#id", "div > p")
  final String selector;

  /// CSS declarations as property -> value map
  /// e.g., {"color": "red", "font-size": "16px"}
  final Map<String, String> declarations;

  /// Declarations marked with `!important`.
  /// Applied after inline styles in the cascade, per CSS spec.
  final Map<String, String> importantDeclarations;

  /// Selector specificity for cascade ordering
  /// Format: [inline, id, class, element] as a single int
  /// Higher value = higher priority
  final int specificity;

  const ParsedCssRule({
    required this.selector,
    required this.declarations,
    Map<String, String>? importantDeclarations,
    this.specificity = 0,
  }) : importantDeclarations = importantDeclarations ?? const {};

  @override
  String toString() =>
      'ParsedCssRule($selector, specificity=$specificity, '
      '${declarations.length} normal + ${importantDeclarations.length} !important)';
}

/// Simple inline style parser (no external dependencies)
///
/// Use this for basic inline style parsing without full CSS support
class SimpleInlineStyleParser implements CssParserInterface {
  const SimpleInlineStyleParser();

  @override
  List<ParsedCssRule> parseStylesheet(String css) {
    final rules = <ParsedCssRule>[];
    if (css.isEmpty) return rules;

    // Very basic regex-based CSS parser for simple rules
    // Pattern: selector { property: value; ... }
    final ruleRegex = RegExp(r'([^{]+)\{([^}]+)\}');
    final matches = ruleRegex.allMatches(css);

    for (final match in matches) {
      final selector = match.group(1)!.trim();
      final body = match.group(2)!.trim();
      final declarations = parseInlineStyle(body);

      if (selector.isNotEmpty && declarations.isNotEmpty) {
        rules.add(ParsedCssRule(
          selector: selector,
          declarations: declarations,
          specificity: _calculateBasicSpecificity(selector),
        ));
      }
    }
    return rules;
  }

  int _calculateBasicSpecificity(String selector) {
    if (selector.startsWith('#')) return 100;
    if (selector.startsWith('.')) return 10;
    return 1;
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
        final value = decl.substring(colonIndex + 1).trim();
        if (property.isNotEmpty && value.isNotEmpty) {
          result[property] = value;
        }
      }
    }
    return result;
  }
}
