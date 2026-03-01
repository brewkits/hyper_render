import 'package:hyper_render_core/hyper_render_core.dart';
import 'markdown_adapter.dart';

/// Default Markdown parser implementing ContentParser interface
///
/// This parser uses the MarkdownAdapter to convert Markdown content
/// into the Unified Document Tree (UDT).
///
/// ## Usage
///
/// ```dart
/// final parser = MarkdownContentParser();
/// final document = parser.parse('# Hello World\n\nThis is **bold** text.');
///
/// // Or with HyperViewer
/// HyperViewer.markdown(
///   markdown: '# Title\n\nContent here...',
///   contentParser: MarkdownContentParser(enableGfm: true),
/// )
/// ```
class MarkdownContentParser implements ContentParser {
  /// Enable GitHub Flavored Markdown extensions
  final bool enableGfm;

  /// Enable inline HTML in Markdown
  final bool enableInlineHtml;

  /// Creates a Markdown parser
  ///
  /// [enableGfm] - Enable GitHub Flavored Markdown (tables, strikethrough, etc.)
  /// [enableInlineHtml] - Allow inline HTML in Markdown
  const MarkdownContentParser({
    this.enableGfm = true,
    this.enableInlineHtml = true,
  });

  @override
  ContentType get contentType => ContentType.markdown;

  @override
  DocumentNode parse(String content) {
    final adapter = MarkdownAdapter(
      enableGfm: enableGfm,
      enableInlineHtml: enableInlineHtml,
    );
    return adapter.parse(content);
  }

  @override
  DocumentNode parseWithOptions(
    String content, {
    String? baseUrl,
    String? customCss,
  }) {
    // Note: baseUrl and customCss are not directly applicable to Markdown
    // They could be used for post-processing if needed
    return parse(content);
  }

  @override
  List<DocumentNode> parseToSections(String content, {int chunkSize = 3000}) {
    // For now, parse as single document
    // Could be enhanced to split at heading boundaries for better virtualization
    return [parse(content)];
  }
}

/// Convenience function to parse Markdown string
DocumentNode parseMarkdown(String markdown, {bool enableGfm = true}) {
  return MarkdownContentParser(enableGfm: enableGfm).parse(markdown);
}
