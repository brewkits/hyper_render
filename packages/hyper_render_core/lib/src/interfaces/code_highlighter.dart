import 'package:flutter/painting.dart';

/// Interface for code syntax highlighting plugins
///
/// Implement this interface to provide custom syntax highlighting.
/// Default implementation uses flutter_highlight package.
///
/// Example custom implementation:
/// ```dart
/// class PrismHighlighter implements CodeHighlighter {
///   @override
///   List<TextSpan> highlight(String code, String? language) {
///     // Use Prism.js via WebView or custom logic
///     return [...];
///   }
///
///   @override
///   Set<String> get supportedLanguages => {'dart', 'javascript', 'python'};
/// }
/// ```
abstract class CodeHighlighter {
  /// Highlight code and return styled TextSpans
  ///
  /// [code] - The source code to highlight
  /// [language] - The programming language (e.g., 'dart', 'python', 'javascript')
  ///             If null, attempt auto-detection or return plain text
  ///
  /// Returns a list of TextSpan with appropriate styling
  List<TextSpan> highlight(String code, String? language);

  /// Set of supported language identifiers
  ///
  /// Common identifiers: 'dart', 'java', 'python', 'javascript', 'typescript',
  /// 'html', 'css', 'sql', 'json', 'yaml', 'markdown', 'bash', 'shell'
  Set<String> get supportedLanguages;

  /// Check if a language is supported
  bool isLanguageSupported(String language) =>
      supportedLanguages.contains(language.toLowerCase());

  /// Theme name for the highlighter (optional)
  /// Default implementations may use this for theme selection
  String get themeName => 'default';
}

/// A no-op highlighter that returns plain text
///
/// Use this when syntax highlighting is not needed or not available
class PlainTextHighlighter implements CodeHighlighter {
  final TextStyle? _baseStyle;

  const PlainTextHighlighter({TextStyle? baseStyle}) : _baseStyle = baseStyle;

  @override
  List<TextSpan> highlight(String code, String? language) {
    return [TextSpan(text: code, style: _baseStyle)];
  }

  @override
  Set<String> get supportedLanguages => const {};

  @override
  bool isLanguageSupported(String language) => false;

  @override
  String get themeName => 'plain';
}
