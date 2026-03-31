import 'package:hyper_render_core/hyper_render_core.dart';
import '../parser/delta/delta_adapter.dart';

/// Default Delta parser using DeltaAdapter
///
/// Parses Quill Delta JSON format into DocumentNode.
///
/// ## Usage
/// ```dart
/// final parser = DefaultDeltaParser();
/// final document = parser.parse(deltaJson);
/// ```
///
/// ## Delta Format
/// ```json
/// {
///   "ops": [
///     { "insert": "Hello " },
///     { "insert": "World", "attributes": { "bold": true } },
///     { "insert": "\n" }
///   ]
/// }
/// ```
///
/// ## Supported Features
/// - Text formatting: bold, italic, underline, strikethrough
/// - Colors: text color, background color
/// - Fonts: family, size (small, normal, large, huge, or px)
/// - Links: clickable hyperlinks
/// - Headers: h1-h6
/// - Lists: ordered (numbered), bullet
/// - Code blocks with syntax highlighting
/// - Block quotes
/// - Text alignment: left, center, right, justify
/// - Indentation
/// - Images and videos
/// - Formulas (LaTeX)
class DefaultDeltaParser implements ContentParser {
  /// Creates a DefaultDeltaParser
  const DefaultDeltaParser();

  @override
  ContentType get contentType => ContentType.delta;

  @override
  DocumentNode parse(String content) {
    return DeltaAdapter().parse(content);
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
  List<DocumentNode> parseToSections(
    String content, {
    int chunkSize = 3000,
    String? baseUrl,
  }) {
    // Delta format doesn't support chunking easily
    return [parse(content)];
  }

  /// Parse with extended result including warnings
  ParseResult parseExtended(String content) {
    final adapter = DeltaAdapter();
    final result = adapter.parseExtended(content);
    return ParseResult(
      document: result.document,
      warnings: result.warnings,
      parseDuration: result.parseDuration,
    );
  }
}

/// Extension to easily convert Delta JSON to document
extension DeltaParserExtension on String {
  /// Parse this string as Quill Delta JSON
  DocumentNode parseDelta() {
    return const DefaultDeltaParser().parse(this);
  }
}
