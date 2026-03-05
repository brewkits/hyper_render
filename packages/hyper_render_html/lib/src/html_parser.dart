import 'package:hyper_render_core/hyper_render_core.dart';

import 'html_adapter.dart';
import 'css_parser.dart';

/// Default HTML parser using the `html` package
///
/// Provides full HTML parsing with proper DOM tree construction.
/// This is the default implementation provided by HyperRender.
class DefaultHtmlParser implements ContentParser, CssParserInterface {
  final HtmlAdapter _adapter = HtmlAdapter();

  DefaultHtmlParser();

  @override
  ContentType get contentType => ContentType.html;

  @override
  DocumentNode parse(String content) {
    return _adapter.parse(content);
  }

  @override
  List<ParsedCssRule> parseStylesheet(String css) {
    return const DefaultCssParser().parseStylesheet(css);
  }

  @override
  Map<String, String> parseInlineStyle(String style) {
    return const DefaultCssParser().parseInlineStyle(style);
  }

  @override
  DocumentNode parseWithOptions(
    String content, {
    String? baseUrl,
    String? customCss,
  }) {
    final doc = _adapter.parse(content, baseUrl: baseUrl);

    // Always resolve styles so that inline style="" attributes and embedded
    // <style> tags are applied to the document tree.
    final resolver = StyleResolver();

    // 1. Embedded <style> blocks inside the HTML
    final embeddedCss = _adapter.extractCss(content);
    if (embeddedCss.isNotEmpty) {
      resolver.parseCss(embeddedCss);
    }

    // 2. Caller-provided custom CSS (overrides embedded)
    if (customCss != null && customCss.isNotEmpty) {
      resolver.parseCss(customCss);
    }

    resolver.resolveStyles(doc);
    return doc;
  }

  @override
  List<DocumentNode> parseToSections(String content, {int chunkSize = 3000}) {
    return _adapter.parseToSections(content, chunkSize: chunkSize);
  }
}
