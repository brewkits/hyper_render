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

export 'package:hyper_render_core/hyper_render_core.dart'
    show
        ContentParser,
        ContentType,
        ParseResult,
        ExtendedContentParser,
        PlainTextParser,
        CssParserInterface,
        ParsedCssRule,
        SimpleInlineStyleParser,
        CodeHighlighter,
        PlainTextHighlighter,
        ImageClipboardHandler,
        DefaultImageClipboardHandler,
        ImageOperationResult;
