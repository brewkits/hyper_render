import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:hyper_render_core/hyper_render_core.dart';

/// A [HyperImageLoader] for EPUB content.
///
/// [EpubChapter.html] images are rewritten to inline `data:` base64 URIs
/// (the bytes live inside the EPUB's zip archive, not at a fetchable
/// `http(s)://` URL — see the OPF/chapter parser), so this decodes those
/// directly instead of going through Flutter's `NetworkImage`, which does
/// not understand `data:` URIs and would fail every image load. Anything
/// that isn't a `data:` URI (e.g. a book that references genuine remote
/// cover art) falls back to [defaultImageLoader].
///
/// Stateless — it holds no reference to any particular [EpubBook] or
/// archive — so it is a stable top-level function safe to pass directly:
/// `HyperViewer(imageLoader: epubImageLoader)`. A closure rebuilt on every
/// `build()` would instead compare unequal each time and make
/// `RenderHyperBox` dispose and reload every image on every rebuild.
void epubImageLoader(
  String src,
  void Function(ui.Image image) onLoad,
  void Function(Object error) onError,
) {
  if (!src.startsWith('data:')) {
    defaultImageLoader(src, onLoad, onError);
    return;
  }

  try {
    final commaIndex = src.indexOf(',');
    if (commaIndex == -1) {
      throw FormatException('Malformed data URI (no comma): $src');
    }
    final meta = src.substring('data:'.length, commaIndex);
    if (!meta.endsWith(';base64')) {
      // Our own chapter/CSS rewriter always emits base64. A non-base64
      // data URI reaching here means something else constructed it.
      throw FormatException(
        'epubImageLoader only decodes base64 data URIs, got "$meta": $src',
      );
    }
    final bytes = base64.decode(src.substring(commaIndex + 1));
    _decode(bytes, onLoad, onError);
  } catch (e) {
    onError(e);
  }
}

void _decode(
  Uint8List bytes,
  void Function(ui.Image image) onLoad,
  void Function(Object error) onError,
) {
  // async/await + try/catch rather than .then()/.catchError() — chaining
  // through an inferred `Future<void>` from an async closure hits a known
  // Dart footgun where the error handler must return `FutureOr<Null>`
  // (not `void`), rejecting an otherwise-correct `void`-returning callback.
  Future<void> run() async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        onLoad(frame.image);
      } finally {
        codec.dispose();
      }
    } catch (e) {
      onError(e);
    }
  }

  run();
}
