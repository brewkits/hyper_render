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

  /// Selector specificity for cascade ordering
  /// Format: [inline, id, class, element] as a single int
  /// Higher value = higher priority
  final int specificity;

  const ParsedCssRule({
    required this.selector,
    required this.declarations,
    this.specificity = 0,
  });

  @override
  String toString() =>
      'ParsedCssRule($selector, specificity=$specificity, ${declarations.length} declarations)';
}

/// Simple inline style parser (no external dependencies)
///
/// Use this for basic inline style parsing without full CSS support
class SimpleInlineStyleParser implements CssParserInterface {
  const SimpleInlineStyleParser();

  @override
  List<ParsedCssRule> parseStylesheet(String css) {
    // Simple implementation doesn't support full stylesheets
    // Return empty list - inline styles only
    return const [];
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
