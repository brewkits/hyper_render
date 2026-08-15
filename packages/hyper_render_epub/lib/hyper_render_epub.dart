/// EPUB container support for HyperRender.
///
/// Unzips an `.epub`, parses its OPF manifest/spine/TOC, and resolves each
/// chapter to content `HyperViewer` can render directly — images rewritten
/// to inline `data:` URIs (they live inside the zip, not at a fetchable
/// `http(s)://` URL) and external stylesheets concatenated for
/// `HyperViewer.customCss`.
///
/// ## Quick start
///
/// ```dart
/// import 'package:hyper_render/hyper_render.dart';
/// import 'package:hyper_render_epub/hyper_render_epub.dart';
///
/// final bytes = await File('book.epub').readAsBytes();
/// final book = await EpubBook.open(bytes);
///
/// HyperViewer(
///   html: book.chapters.first.html,
///   customCss: book.chapters.first.css,
///   imageLoader: epubImageLoader,
///   mode: HyperRenderMode.paged,
/// )
/// ```
library;

export 'src/epub_book.dart';
export 'src/epub_exception.dart';
export 'src/epub_image_loader.dart';
export 'src/epub_reader.dart';
