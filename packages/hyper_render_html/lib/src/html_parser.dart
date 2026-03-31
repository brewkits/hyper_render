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
    return _adapter.parse(content, baseUrl: baseUrl);
  }

  @override
  List<DocumentNode> parseToSections(
    String content, {
    int chunkSize = 3000,
    String? baseUrl,
  }) {
    return _adapter.parseToSections(content,
        chunkSize: chunkSize, baseUrl: baseUrl);
  }
}
