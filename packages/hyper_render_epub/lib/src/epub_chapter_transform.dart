import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import 'epub_archive.dart';
import 'epub_opf.dart';
import 'epub_path.dart';

/// The `html` + `css` pair a single chapter resolves to.
class ChapterContent {
  /// Body content, images inlined and stylesheet links removed.
  final String html;

  /// Concatenated text of every stylesheet the chapter linked to.
  final String css;

  const ChapterContent(this.html, this.css);
}

/// Turns one chapter's raw XHTML into `HyperViewer`-ready content.
///
/// * `<link rel="stylesheet">` and `<style>` elements are removed and their
///   text is concatenated into [ChapterContent.css], in document order —
///   HyperRender never fetches an external stylesheet, and a `<head>` `<style>`
///   would be lost outright since only body content is kept.
/// * `<img src>` pointing inside the archive becomes an inline base64 `data:`
///   URI, because the bytes live in the zip and there is nothing for a network
///   image loader to fetch.
/// * `<img src="*.svg">` is *replaced by the SVG markup itself*, not by a
///   `data:` URI: `UrlSafety` blocks `data:image/svg` outright (an SVG can
///   carry `<script>`), while an inline `<svg>` element is explicitly kept by
///   `HyperRender`'s sanitizer (scripts stripped) and rendered by `HyperViewer`
///   through `flutter_svg`. Note the scope — that renderer is chained in by
///   `HyperViewer`, so SVG chapters need the `hyper_render` package, not core's
///   `HyperRenderWidget` alone.
/// * Everything else — `<a href>` cross-chapter links, unresolvable sources —
///   is preserved as authored.
///
/// Parsed with the HTML5 parser rather than an XML one: real EPUBs are full of
/// undeclared entities and unclosed tags that a strict XHTML parse rejects.
ChapterContent transformChapter({
  required String source,
  required String chapterPath,
  required EpubArchive archive,
  required OpfPackage opf,
}) {
  final dom.Document document;
  try {
    document = html_parser.parse(source);
  } catch (_) {
    return ChapterContent(source, '');
  }
  final baseDir = epubDirOf(chapterPath);

  // One document-order pass over both stylesheet carriers: a `<style>` in
  // `<head>` would otherwise be dropped by the body-only extraction below,
  // and a later rule must still win over an earlier one.
  final css = StringBuffer();
  void appendCss(String label, String text) {
    if (text.trim().isEmpty) return;
    if (css.isNotEmpty) css.writeln();
    css.writeln('/* $label */');
    css.write(text.trim());
  }

  for (final element in document.querySelectorAll('*').toList()) {
    switch (element.localName) {
      case 'link':
        final rel = (element.attributes['rel'] ?? '').toLowerCase();
        if (!rel.split(RegExp(r'\s+')).contains('stylesheet')) continue;
        final path = epubResolve(baseDir, element.attributes['href'] ?? '');
        final text = archive.readText(path);
        if (text != null) appendCss(path!, text);
        element.remove();
      case 'style':
        appendCss('$chapterPath <style>', element.text);
        element.remove();
    }
  }

  for (final img in document.querySelectorAll('img')) {
    final src = img.attributes['src'];
    if (src == null) continue;
    final path = epubResolve(baseDir, src);
    if (path == null) continue; // http(s):, data:, or same-document link
    final bytes = archive.read(path);
    if (bytes == null) continue; // missing entry — leave the src visible
    final mediaType = _mediaTypeFor(path, opf);
    if (mediaType.contains('svg')) {
      final svg = _svgElementFrom(decodeEpubText(bytes));
      // A file that declares itself SVG but holds no <svg> element keeps its
      // original src rather than being replaced by nothing.
      if (svg != null) {
        for (final attribute in const ['width', 'height', 'class', 'style']) {
          final value = img.attributes[attribute];
          if (value != null && !svg.attributes.containsKey(attribute)) {
            svg.attributes[attribute] = value;
          }
        }
        img.replaceWith(svg);
      }
      continue;
    }
    img.attributes['src'] = 'data:$mediaType;base64,${base64.encode(bytes)}';
    // A srcset left behind would point at unresolvable relative paths.
    img.attributes.remove('srcset');
  }

  final body = document.body;
  return ChapterContent(
    (body?.innerHtml ?? document.outerHtml).trim(),
    css.toString(),
  );
}

/// The `<svg>` element inside [source], detached from its parse tree.
///
/// Going through the HTML5 parser also drops the `<?xml …?>` declaration and
/// `<!DOCTYPE svg …>` preamble standalone SVG files carry, and it preserves
/// camelCase attributes (`viewBox`, `preserveAspectRatio`) — verified, because
/// a lowercased `viewbox` would silently break every SVG's scaling.
dom.Element? _svgElementFrom(String source) {
  try {
    final svg = html_parser.parse(source).querySelector('svg');
    return svg?..remove();
  } catch (_) {
    return null;
  }
}

/// The `media-type` to stamp on a `data:` URI — the OPF manifest's declaration
/// first (authoritative), then the file extension.
String _mediaTypeFor(String path, OpfPackage opf) {
  final declared = opf.byPath[path]?.mediaType;
  if (declared != null && declared.startsWith('image/')) return declared;

  final dot = path.lastIndexOf('.');
  final extension = dot == -1 ? '' : path.substring(dot + 1).toLowerCase();
  switch (extension) {
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'bmp':
      return 'image/bmp';
    case 'svg':
      return 'image/svg+xml';
    case 'jpg':
    case 'jpeg':
    default:
      return 'image/jpeg';
  }
}
