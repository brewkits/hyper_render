import 'package:hyper_render_core/hyper_render_core.dart';

/// Input type for the content adapter
enum InputType {
  /// HTML string
  html,

  /// Quill Delta JSON
  delta,

  /// Markdown string (future)
  markdown,
}

/// Base interface for content adapters.
///
/// Adapters convert different input formats (HTML, Delta, Markdown) into the
/// Unified Document Tree (UDT). The rendering core never receives raw HTML or
/// Delta directly — all content passes through an adapter first.
abstract class DocumentAdapter {
  /// Input type this adapter handles
  InputType get inputType;

  /// Parse input content into a UDT DocumentNode
  ///
  /// [content] - The raw input content (HTML string, Delta JSON, etc.)
  /// Returns the root DocumentNode of the UDT
  DocumentNode parse(String content);

  /// Parse input with additional options
  ///
  /// [content] - The raw input content
  /// [baseUrl] - Base URL for resolving relative URLs
  /// [customStylesheet] - Additional CSS to apply
  DocumentNode parseWithOptions(
    String content, {
    String? baseUrl,
    String? customStylesheet,
  }) {
    return parse(content);
  }
}

/// Adapter result with metadata
class AdapterResult {
  /// The parsed document tree
  final DocumentNode document;

  /// Extracted CSS rules (from <style> tags)
  final String? extractedCss;

  /// Warnings during parsing
  final List<String> warnings;

  /// Parse duration for performance monitoring
  final Duration parseDuration;

  AdapterResult({
    required this.document,
    this.extractedCss,
    this.warnings = const [],
    this.parseDuration = Duration.zero,
  });
}

/// Extended adapter interface with metadata
abstract class ExtendedDocumentAdapter extends DocumentAdapter {
  /// Parse with full result including metadata
  AdapterResult parseExtended(String content);

  @override
  DocumentNode parse(String content) {
    return parseExtended(content).document;
  }
}
