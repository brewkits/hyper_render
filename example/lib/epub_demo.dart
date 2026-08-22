// EPUB container demo — what `hyper_render_epub` actually does.
//
// The book is zipped in memory at startup (see buildSampleEpub) rather than
// shipped as a binary fixture, so everything on screen came out of a real
// `.epub` container: `META-INF/container.xml` → OPF manifest/spine → per-chapter
// XHTML, images pulled out of the zip, and a stylesheet the chapters `<link>` to.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:hyper_render_epub/hyper_render_epub.dart';

import 'demo_colors.dart';

class EpubDemo extends StatefulWidget {
  const EpubDemo({super.key});

  @override
  State<EpubDemo> createState() => _EpubDemoState();
}

class _EpubDemoState extends State<EpubDemo> {
  EpubBook? _book;
  EpubReaderController? _controller;
  Object? _error;
  var _mode = HyperRenderMode.paged;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final book = await EpubBook.open(await buildSampleEpub());
      if (!mounted) return;
      setState(() {
        _book = book;
        _controller = EpubReaderController(book: book);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: buildDemoAppBar(
        context,
        title: 'EPUB Container',
        accent: DemoColors.secondary,
        actions: [
          if (controller != null)
            IconButton(
              tooltip: 'Table of contents',
              icon: const Icon(Icons.list),
              onPressed: () => _showToc(controller),
            ),
          if (controller != null)
            IconButton(
              tooltip: _mode == HyperRenderMode.paged
                  ? 'Switch to scrolling'
                  : 'Switch to pages',
              icon: Icon(_mode == HyperRenderMode.paged
                  ? Icons.view_day_outlined
                  : Icons.auto_stories_outlined),
              onPressed: () => setState(() => _mode =
                  _mode == HyperRenderMode.paged
                      ? HyperRenderMode.auto
                      : HyperRenderMode.paged),
            ),
        ],
      ),
      body: switch ((_error, controller)) {
        (final Object e, _) => _ErrorView(error: e),
        (_, null) => const Center(child: CircularProgressIndicator()),
        (_, final EpubReaderController c) => _reader(c),
      },
    );
  }

  Widget _reader(EpubReaderController controller) {
    final book = _book!;
    return Column(
      children: [
        _BookHeader(book: book),
        const Divider(height: 1),
        Expanded(
          child: EpubReader(
            controller: controller,
            mode: _mode,
            // The reader's own preferences, applied after the book's own CSS.
            customCss: 'body { padding: 16px; line-height: 1.6; }',
            onExternalLinkTap: (href) =>
                ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('External link (not opened): $href')),
            ),
          ),
        ),
        const Divider(height: 1),
        _ChapterBar(controller: controller),
      ],
    );
  }

  void _showToc(EpubReaderController controller) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              dense: true,
              title: Text('Table of contents',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Parsed from the EPUB3 nav document'),
            ),
            for (final entry in controller.book.tableOfContents)
              ListTile(
                title: Text(entry.title),
                // An entry's href may carry a #fragment and is relative to the
                // OPF, not the chapter — the controller resolves both.
                selected: controller.chapterIndexForHref(entry.href) ==
                    controller.chapterIndex,
                onTap: () {
                  final index = controller.chapterIndexForHref(entry.href);
                  if (index != null) controller.goTo(index);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _BookHeader extends StatelessWidget {
  const _BookHeader({required this.book});

  final EpubBook book;

  @override
  Widget build(BuildContext context) {
    final cover = book.coverImage;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cover != null && book.coverMediaType != 'image/svg+xml')
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child:
                  Image.memory(cover, width: 48, height: 64, fit: BoxFit.cover),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title ?? 'Untitled',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(book.author ?? 'Unknown author',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  '${book.chapters.length} spine items · '
                  '${book.tableOfContents.length} TOC entries · '
                  'cover ${book.coverMediaType ?? "none"}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterBar extends StatelessWidget {
  const _ChapterBar({required this.controller});

  final EpubReaderController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: controller.hasPrevious ? controller.previous : null,
            ),
            Expanded(
              child: Text(
                controller.chapter.title ?? controller.chapter.href,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: controller.hasNext ? controller.next : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not open the sample book:\n$error',
              textAlign: TextAlign.center),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// The sample book — a real EPUB container, zipped at runtime.
// ─────────────────────────────────────────────────────────────────────────────

/// Public so `test/epub_demo_test.dart` can open the very bytes the screen
/// opens, rather than a parallel fixture that could drift from it.
Future<Uint8List> buildSampleEpub() async {
  final cover = await _renderPng(180, 240, (canvas, size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C6BC0), Color(0xFF26A69A)],
        ).createShader(Offset.zero & size),
    );
  });
  final plate = await _renderPng(160, 120, (canvas, size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFECEFF1));
    final paint = Paint()..color = const Color(0xFF5C6BC0);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * (0.2 + i * 0.15), size.height * 0.5),
        6.0 + i * 3,
        paint,
      );
    }
  });

  final archive = Archive()
    ..addFile(ArchiveFile.string('mimetype', 'application/epub+zip'))
    ..addFile(ArchiveFile.string('META-INF/container.xml', _containerXml))
    ..addFile(ArchiveFile.string('OEBPS/content.opf', _opf))
    ..addFile(ArchiveFile.string('OEBPS/nav.xhtml', _nav))
    ..addFile(ArchiveFile.string('OEBPS/styles/main.css', _css))
    ..addFile(ArchiveFile.string('OEBPS/images/diagram.svg', _diagramSvg))
    ..addFile(ArchiveFile.bytes('OEBPS/images/cover.png', cover))
    ..addFile(ArchiveFile.bytes('OEBPS/images/plate.png', plate))
    ..addFile(ArchiveFile.string('OEBPS/text/ch1.xhtml', _chapter1))
    ..addFile(ArchiveFile.string('OEBPS/text/ch2.xhtml', _chapter2))
    ..addFile(ArchiveFile.string('OEBPS/text/ch3.xhtml', _chapter3));

  return ZipEncoder().encodeBytes(archive);
}

/// Draws [draw] onto a [w]×[h] canvas and encodes the result as PNG.
Future<Uint8List> _renderPng(
  int w,
  int h,
  void Function(Canvas canvas, Size size) draw,
) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder), Size(w.toDouble(), h.toDouble()));
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(w, h);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

const _containerXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''';

const _opf = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="bookid">urn:uuid:hyper-render-sample</dc:identifier>
    <dc:title>Anatomy of an EPUB</dc:title>
    <dc:creator>HyperRender</dc:creator>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="css" href="styles/main.css" media-type="text/css"/>
    <item id="cover" href="images/cover.png" media-type="image/png" properties="cover-image"/>
    <item id="plate" href="images/plate.png" media-type="image/png"/>
    <item id="diagram" href="images/diagram.svg" media-type="image/svg+xml"/>
    <item id="ch1" href="text/ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch2" href="text/ch2.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch3" href="text/ch3.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="ch1"/>
    <itemref idref="ch2"/>
    <itemref idref="ch3"/>
  </spine>
</package>
''';

const _nav = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol>
        <li><a href="text/ch1.xhtml">1 — The container</a></li>
        <li><a href="text/ch2.xhtml">2 — Images inside the zip</a></li>
        <li><a href="text/ch3.xhtml">3 — Links and typography</a></li>
      </ol>
    </nav>
  </body>
</html>
''';

// Linked, not inline: HyperRender never fetches an external stylesheet, so the
// package strips the <link> and hands this text over as `EpubChapter.css`.
const _css = '''
h1 { font-size: 22px; color: #3949AB; margin-bottom: 4px; }
p  { font-size: 15px; margin: 0 0 12px 0; }
.plate { float: left; margin: 0 14px 8px 0; width: 160px; }
.note { background: #F1F3F9; border-left: 3px solid #5C6BC0; padding: 8px 12px; }
ruby rt { font-size: 10px; color: #5C6BC0; }
''';

const _diagramSvg = '''
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 90" width="200" height="90">
  <rect x="2" y="2" width="196" height="86" rx="6" fill="#E8EAF6" stroke="#5C6BC0"/>
  <text x="100" y="34" font-size="14" text-anchor="middle" fill="#3949AB">container.xml</text>
  <text x="100" y="56" font-size="12" text-anchor="middle" fill="#5C6BC0">→ content.opf</text>
  <text x="100" y="74" font-size="12" text-anchor="middle" fill="#5C6BC0">→ spine → chapters</text>
</svg>
''';

String _chapterHtml(String body) => '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <link rel="stylesheet" type="text/css" href="../styles/main.css"/>
  </head>
  <body>
$body
  </body>
</html>
''';

final _chapter1 = _chapterHtml('''
    <h1>1 — The container</h1>
    <p>An <code>.epub</code> is a zip. Opening it means reading
    <code>META-INF/container.xml</code> to find the OPF package document, then
    following its manifest and spine to the chapters — which is what produced
    this page.</p>
    <img src="../images/diagram.svg" alt="container.xml to spine"/>
    <p class="note">That diagram is an SVG file from inside the zip. It is
    spliced into the chapter as an inline &lt;svg&gt; element rather than a
    <code>data:</code> URI, because <code>UrlSafety</code> blocks
    <code>data:image/svg</code> — an SVG can carry a script.</p>
''');

final _chapter2 = _chapterHtml('''
    <h1>2 — Images inside the zip</h1>
    <img class="plate" src="../images/plate.png" alt="plate"/>
    <p>The image on the left never existed at an <code>http(s)://</code> URL —
    its bytes live in the archive. The chapter transform rewrote its
    <code>src</code> to an inline base64 <code>data:</code> URI, and
    <code>epubImageLoader</code> decodes that; the default network loader
    cannot.</p>
    <p>It is also floated. Text wrapping around a floated image is the thing
    that motivated HyperRender's single-RenderObject layout in the first place,
    and it is what makes a print-styled book render the way its author
    intended.</p>
    <p>Scroll or swipe on — the paragraph keeps flowing beside the plate until
    it clears the bottom edge, then reclaims the full column width.</p>
''');

final _chapter3 = _chapterHtml('''
    <h1>3 — Links and typography</h1>
    <p>Books cross-reference themselves. This link points at
    <a href="ch1.xhtml">the first chapter</a> — a relative path resolved
    against <em>this</em> chapter's directory, not the OPF's. Tapping it moves
    the reader; an <a href="https://example.com/">outside link</a> is handed to
    your own callback instead.</p>
    <p>Ruby annotations survive the trip through the container:
    <ruby>漢<rt>かん</rt>字<rt>じ</rt></ruby> — positioned above the base text,
    not inline after it.</p>
    <p class="note">Everything styling this page came from
    <code>styles/main.css</code>, a file the chapters &lt;link&gt; to. The
    package hands it over as <code>EpubChapter.css</code>, which this demo
    passes to <code>HyperViewer.customCss</code>.</p>
''');
