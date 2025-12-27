import '../interfaces/content_parser.dart';
import '../model/node.dart';
import '../parser/markdown/markdown_adapter.dart';

/// Default Markdown parser using the `markdown` package
///
/// Converts Markdown to HTML internally, then parses to UDT.
/// This is the default implementation provided by HyperRender.
class DefaultMarkdownParser implements ContentParser {
  final MarkdownAdapter _adapter = MarkdownAdapter();

  DefaultMarkdownParser();

  @override
  ContentType get contentType => ContentType.markdown;

  @override
  DocumentNode parse(String content) {
    return _adapter.parse(content);
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
    // Parse entire document, then return as single section
    // Future: could implement section splitting for large documents
    return [parse(content)];
  }
}
