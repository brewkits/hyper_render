# Changelog — hyper_render_epub

## 0.1.0

Initial scaffolding — not published to pub.dev yet.

### ✨ New

- `epubImageLoader`: a `HyperImageLoader` that decodes `data:` base64 URIs directly (falls
  back to the normal network loader for any other scheme). Fully implemented and tested.
- Public API shape: `EpubBook`, `EpubChapter`, `EpubTocEntry`. `EpubBook.open(Uint8List)` is
  `Future<EpubBook>` (real parsing does real main-thread work — `ZipDecoder` + per-chapter
  base64 — over a whole book) and currently a stub that throws `UnimplementedError`;
  container/OPF/spine/TOC parsing is the next change.
