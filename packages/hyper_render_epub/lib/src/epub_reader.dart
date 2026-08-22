import 'package:flutter/widgets.dart';
import 'package:hyper_render/hyper_render.dart';

import 'epub_book.dart';
import 'epub_image_loader.dart';
import 'epub_path.dart';

/// Reading position within an [EpubBook], plus the href → chapter resolution a
/// reader needs for table-of-contents jumps and cross-chapter links.
///
/// A [ChangeNotifier], so a table-of-contents panel, a progress indicator and
/// the [EpubReader] itself can all watch the same position:
///
/// ```dart
/// final controller = EpubReaderController(book: book);
/// …
/// ListenableBuilder(
///   listenable: controller,
///   builder: (context, _) => Text(controller.chapter.title ?? ''),
/// )
/// ```
///
/// Call [dispose] when the owning widget is disposed.
class EpubReaderController extends ChangeNotifier {
  /// The book being read.
  final EpubBook book;

  int _chapterIndex;

  /// Zip-relative chapter path → index, resolved once.
  ///
  /// [chapterIndexForHref] is called per table-of-contents row per rebuild, so
  /// resolving every chapter's href on every call would be O(chapters × rows).
  /// First entry wins, matching [EpubBook.chapters] order.
  final Map<String, int> _indexByPath;

  /// Creates a controller positioned at [initialChapter].
  ///
  /// [initialChapter] is clamped into range, so restoring a saved position
  /// from a book that has since changed cannot throw.
  EpubReaderController({required this.book, int initialChapter = 0})
      : _chapterIndex = book.chapters.isEmpty
            ? 0
            : initialChapter.clamp(
                0,
                book.chapters.length - 1,
              ),
        _indexByPath = {
          for (var i = book.chapters.length - 1; i >= 0; i--)
            if (epubResolve('', book.chapters[i].href) case final path?)
              path: i,
        };

  /// Index of the chapter currently being read.
  int get chapterIndex => _chapterIndex;

  /// The chapter currently being read.
  ///
  /// Throws [StateError] when the book has no chapters — a book that parsed to
  /// zero readable chapters has nothing for a reader to show, and silently
  /// handing back an empty placeholder would hide that.
  EpubChapter get chapter {
    if (book.chapters.isEmpty) {
      throw StateError('This EpubBook has no readable chapters.');
    }
    return book.chapters[_chapterIndex];
  }

  /// Whether [next] would move.
  bool get hasNext => _chapterIndex < book.chapters.length - 1;

  /// Whether [previous] would move.
  bool get hasPrevious => _chapterIndex > 0;

  /// Moves to the next chapter, if there is one.
  void next() => goTo(_chapterIndex + 1);

  /// Moves to the previous chapter, if there is one.
  void previous() => goTo(_chapterIndex - 1);

  /// Moves to [index], ignoring out-of-range values.
  void goTo(int index) {
    if (index < 0 || index >= book.chapters.length) return;
    if (index == _chapterIndex) return;
    _chapterIndex = index;
    notifyListeners();
  }

  /// The chapter [href] points at, or `null` when it points outside the book.
  ///
  /// Accepts both coordinate systems a reader runs into: an
  /// [EpubTocEntry.href] (OPF-relative, possibly with a `#fragment`) and the
  /// raw `<a href>` of the chapter currently open (relative to *that chapter's*
  /// directory) — pass [relativeTo] for the latter, which [EpubReader] does
  /// automatically on link taps.
  int? chapterIndexForHref(String href, {String? relativeTo}) {
    final target = epubResolve(epubDirOf(relativeTo ?? ''), href);
    if (target == null) return null; // external URL or same-document anchor
    return _indexByPath[target];
  }

  /// Navigates to whatever [href] points at, relative to the open chapter.
  ///
  /// Returns false when the href leaves the book (an `http(s)` link, an
  /// unresolvable path) — the caller then decides whether to open a browser.
  bool openHref(String href) {
    final index = chapterIndexForHref(href, relativeTo: chapter.href);
    if (index == null) return false;
    goTo(index);
    return true;
  }
}

/// Renders the chapter an [EpubReaderController] is positioned on.
///
/// Deliberately thin — no `Scaffold`, no app bar, no table-of-contents drawer.
/// It renders one chapter and resolves link taps; chrome and navigation UI
/// belong to the app, which already has [EpubReaderController] to drive them.
///
/// ```dart
/// Column(children: [
///   Expanded(child: EpubReader(controller: controller)),
///   Row(children: [
///     TextButton(onPressed: controller.hasPrevious ? controller.previous : null,
///                child: const Text('Previous')),
///     TextButton(onPressed: controller.hasNext ? controller.next : null,
///                child: const Text('Next')),
///   ]),
/// ])
/// ```
///
/// Chapter-at-a-time by design: [HyperRenderMode.paged] paginates *one*
/// document, so page-turns stay inside a chapter and chapter boundaries are
/// crossed through the controller.
class EpubReader extends StatelessWidget {
  /// Reading position and href resolution.
  final EpubReaderController controller;

  /// How the chapter itself is rendered. `paged` gives swipeable pages;
  /// [HyperRenderMode.auto] gives a continuous scroll.
  final HyperRenderMode mode;

  /// Called for links that do not resolve to a chapter in this book —
  /// `http(s)://` references, or a broken relative path. In-book links never
  /// reach this callback; they move [controller] instead.
  final void Function(String href)? onExternalLinkTap;

  /// Extra CSS applied after the chapter's own stylesheets, so it wins — a
  /// reader's font-size / margin / colour preferences go here.
  final String? customCss;

  /// Forwarded to [HyperViewer.selectable].
  final bool selectable;

  /// Forwarded to [HyperViewer.textScaler]; defaults to the ambient
  /// `MediaQuery` scaler.
  final TextScaler? textScaler;

  /// Shown when the book parsed to zero readable chapters.
  final WidgetBuilder? emptyBuilder;

  /// Creates a reader for [controller].
  const EpubReader({
    super.key,
    required this.controller,
    this.mode = HyperRenderMode.paged,
    this.onExternalLinkTap,
    this.customCss,
    this.selectable = true,
    this.textScaler,
    this.emptyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.book.chapters.isEmpty) {
          return emptyBuilder?.call(context) ?? const SizedBox.shrink();
        }
        final chapter = controller.chapter;
        return HyperViewer(
          // A new key per chapter rather than one long-lived viewer: it resets
          // paged mode to page 0 and drops the previous chapter's parsed
          // document (and its decoded images) instead of holding the whole
          // book resident. Keyed by index, not by chapter id — a spine may
          // list the same manifest item twice, and two adjacent chapters
          // sharing a key would have Flutter reuse the element, which is the
          // page-reset this key exists to force.
          key: ValueKey<int>(controller.chapterIndex),
          html: chapter.html,
          customCss: _mergeCss(chapter.css, customCss),
          // Chapter images are inline `data:` URIs; the default network loader
          // cannot decode those.
          imageLoader: epubImageLoader,
          mode: mode,
          selectable: selectable,
          textScaler: textScaler,
          onLinkTap: _onLinkTap,
        );
      },
    );
  }

  void _onLinkTap(String href) {
    if (controller.openHref(href)) return;
    onExternalLinkTap?.call(href);
  }

  static String? _mergeCss(String chapterCss, String? extra) {
    if (extra == null || extra.trim().isEmpty) {
      return chapterCss.isEmpty ? null : chapterCss;
    }
    if (chapterCss.isEmpty) return extra;
    return '$chapterCss\n\n/* EpubReader.customCss */\n$extra';
  }
}
