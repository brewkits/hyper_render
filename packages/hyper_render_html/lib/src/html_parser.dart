import 'package:hyper_render_core/hyper_render_core.dart';

import 'html_adapter.dart';

/// Default HTML parser using the `html` package
///
/// Provides full HTML parsing with proper DOM tree construction.
/// This is the default implementation provided by HyperRender.
class DefaultHtmlParser implements ContentParser {
  final HtmlAdapter _adapter = HtmlAdapter();

  DefaultHtmlParser();

  @override
  ContentType get contentType => ContentType.html;

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
    // HtmlAdapter doesn't currently support these options
    // Future: could be extended to support base URL resolution
    return parse(content);
  }

  @override
  List<DocumentNode> parseToSections(String content, {int chunkSize = 3000}) {
    return _adapter.parseToSections(content, chunkSize: chunkSize);
  }
}
