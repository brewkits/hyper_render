import '../model/node.dart';

/// Input type for content parsers
enum ContentType {
  /// HTML content
  html,

  /// Quill Delta JSON
  delta,

  /// Markdown content
  markdown,

  /// Plain text
  plainText,
}

/// Interface for content parsing plugins
///
/// Implement this interface to provide custom content parsing.
/// This is the core interface for converting various input formats
/// into the Unified Document Tree (UDT).
///
/// Example custom implementation:
/// ```dart
/// class MyCustomHtmlParser implements ContentParser {
///   @override
///   ContentType get contentType => ContentType.html;
///
///   @override
///   DocumentNode parse(String content) {
///     // Custom parsing logic
///     return DocumentNode(children: [...]);
///   }
/// }
/// ```
abstract class ContentParser {
  /// The content type this parser handles
  ContentType get contentType;

  /// Parse input content into a UDT DocumentNode
  ///
  /// [content] - The raw input content (HTML, Markdown, Delta JSON, etc.)
  /// Returns the root DocumentNode of the UDT
  DocumentNode parse(String content);

  /// Parse content with additional options (optional override)
  ///
  /// [content] - The raw input content
  /// [baseUrl] - Base URL for resolving relative URLs
  /// [customCss] - Additional CSS to apply
  DocumentNode parseWithOptions(
    String content, {
    String? baseUrl,
    String? customCss,
  }) {
    return parse(content);
  }

  /// Parse content into sections for lazy loading (optional override)
  ///
  /// [content] - The raw input content
  /// [chunkSize] - Approximate character count per section
  /// Returns a list of DocumentNodes, each representing a section
  List<DocumentNode> parseToSections(String content, {int chunkSize = 3000}) {
    return [parse(content)];
  }
}

/// Parse result with metadata
class ParseResult {
  /// The parsed document tree
  final DocumentNode document;

  /// Extracted CSS rules (from <style> tags in HTML)
  final String? extractedCss;

  /// Warnings generated during parsing
  final List<String> warnings;

  /// Time taken to parse
  final Duration parseDuration;

  const ParseResult({
    required this.document,
    this.extractedCss,
    this.warnings = const [],
    this.parseDuration = Duration.zero,
  });
}

/// Extended parser interface with metadata support
abstract class ExtendedContentParser extends ContentParser {
  /// Parse with full result including metadata
  ParseResult parseExtended(String content);

  @override
  DocumentNode parse(String content) {
    return parseExtended(content).document;
  }
}

/// A simple plain text parser (no external dependencies)
///
/// Use this when you only need to render plain text
class PlainTextParser implements ContentParser {
  const PlainTextParser();

  @override
  ContentType get contentType => ContentType.plainText;

  @override
  DocumentNode parse(String content) {
    return DocumentNode(
      children: [
        BlockNode(
          tagName: 'p',
          children: [
            TextNode(content),
          ],
        ),
      ],
    );
  }

  @override
  DocumentNode parseWithOptions(
    String content, {
    String? baseUrl,
    String? customCss,
  }) {
    return parse(content);
  }

  @override
  List<DocumentNode> parseToSections(String content, {int chunkSize = 3000}) {
    return [parse(content)];
  }
}
