# hyper_render_epub

EPUB container support for [HyperRender](https://pub.dev/packages/hyper_render). Unzips an
`.epub`, parses its OPF manifest/spine/table-of-contents, and resolves each chapter to
content `HyperViewer` can render directly.

---

## Status: early scaffolding (v0.1.0)

This package is **not feature-complete yet**. What exists today:

- ✅ `epubImageLoader` — a `HyperImageLoader` that decodes the `data:` URIs a future chapter
  parser will emit (EPUB images live inside the zip, not at a fetchable `http(s)://` URL),
  falling back to the normal network loader for anything else. Usable today with hand-built
  `data:` URIs.
- ❌ `EpubBook.open()` — container/OPF/spine/TOC parsing. Currently throws
  `UnimplementedError`. This is the next change.

The public shape (`EpubBook`, `EpubChapter`, `EpubTocEntry`) is fixed so the rest of the
package — and anyone building against it — has a stable target while parsing is filled in.

---

## Installation

```yaml
dependencies:
  hyper_render_epub: ^0.1.0
```

---

## Usage (once `EpubBook.open` lands)

```dart
import 'dart:io';
import 'package:hyper_render/hyper_render.dart';
import 'package:hyper_render_epub/hyper_render_epub.dart';

final bytes = await File('book.epub').readAsBytes();
final book = await EpubBook.open(bytes);

HyperViewer(
  html: book.chapters.first.html,
  customCss: book.chapters.first.css,
  imageLoader: epubImageLoader,
  mode: HyperRenderMode.paged,
)
```

`HyperViewer.imageLoader` requires `hyper_render` from `main` (not yet published to pub.dev
as of this package's 0.1.0) — on the current pub.dev release, pass `imageLoader` to the
lower-level `HyperRenderWidget` instead.

### A note on pagination

`HyperRenderMode.paged` paginates **one document** — it does not turn a whole book into a
single continuously-swipeable reader. This package's reading UX is chapter-at-a-time: build
one `HyperViewer(mode: paged)` per `book.chapters[i]` and handle next/previous-*chapter*
navigation yourself. Seamless pagination across chapter boundaries is a possible future
addition, not something this package (or HyperRender's engine) does today.

### Known CSS gaps this package inherits from the engine

Verified against `hyper_render_core`, not assumed:

- **`background-image: url(...)`** is parsed into `ComputedStyle.backgroundImage` but never
  painted — HyperRender's canvas paint layer doesn't read it. A chapter stylesheet with
  background images will not error, it will just render without them.
- **`@font-face src: url(...)`** has no support anywhere in the engine (no dynamic/runtime
  font loading API at all), so embedded EPUB fonts are not applied. Chapters fall back to
  whatever font the surrounding app uses.

Neither is planned for this package to work around — both are engine-level gaps, not
something a container/CSS-inlining layer can paper over.

---

## HyperRender Ecosystem

| Package | Description |
|---------|-------------|
| [hyper_render](https://pub.dev/packages/hyper_render) | Main package — `HyperViewer` widget, HTML + Markdown rendering |
| [hyper_render_core](https://pub.dev/packages/hyper_render_core) | Core engine: UDT model, `RenderHyperBox`, plugin API |
| [hyper_render_html](https://pub.dev/packages/hyper_render_html) | HTML + CSS → UDT parser |
| [hyper_render_markdown](https://pub.dev/packages/hyper_render_markdown) | Markdown (GFM) → UDT parser |
| [hyper_render_highlight](https://pub.dev/packages/hyper_render_highlight) | Syntax highlighting for `<code>` / `<pre>` blocks |
| [hyper_render_clipboard](https://pub.dev/packages/hyper_render_clipboard) | Image copy / save / share *(opt-in)* |
| [hyper_render_math](https://pub.dev/packages/hyper_render_math) | LaTeX / MathML rendering |
| **hyper_render_epub** | **EPUB container support** ← you are here |
| [hyper_render_devtools](https://pub.dev/packages/hyper_render_devtools) | Flutter DevTools inspector |

[Source](https://github.com/brewkits/hyper_render/tree/main/packages/hyper_render_epub) · [Issues](https://github.com/brewkits/hyper_render/issues) · [Changelog](CHANGELOG.md)

---

## License

MIT — see [LICENSE](LICENSE).
