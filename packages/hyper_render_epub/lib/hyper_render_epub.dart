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
/// import 'package:hyper_render_epub/hyper_render_epub.dart';
///
/// final book = await EpubBook.open(await File('book.epub').readAsBytes());
/// final controller = EpubReaderController(book: book);
///
/// EpubReader(controller: controller) // dispose the controller when done
/// ```
///
/// [EpubReader] is thin — it renders [EpubReaderController]'s current chapter
/// through `HyperViewer` and resolves link taps. To render chapters yourself,
/// pass [EpubChapter.html] / [EpubChapter.css] to a `HyperViewer` directly, and
/// do not omit `imageLoader: epubImageLoader`: chapter images are inline
/// `data:` URIs and the default network loader cannot decode them.
library;

export 'src/epub_book.dart';
export 'src/epub_exception.dart';
export 'src/epub_image_loader.dart';
export 'src/epub_reader.dart';
