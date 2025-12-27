/// HyperRender Plugin Interfaces
///
/// This library exports all plugin interfaces for extending HyperRender.
/// Implement these interfaces to create custom plugins for:
/// - Content parsing (HTML, Markdown, Delta, custom formats)
/// - CSS parsing
/// - Code syntax highlighting
///
/// ## Usage
///
/// ```dart
/// import 'package:hyper_render/interfaces.dart';
///
/// class MyCustomParser implements ContentParser {
///   // Custom implementation
/// }
///
/// HyperViewer(
///   html: content,
///   contentParser: MyCustomParser(),
/// )
/// ```
library;

export 'content_parser.dart';
export 'css_parser.dart';
export 'code_highlighter.dart';
