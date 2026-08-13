import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_epub/hyper_render_epub.dart';

/// A tiny valid PNG, round-tripped through [ui.decodeImageFromPixels] +
/// [ui.Image.toByteData] so the test has no binary fixture to maintain.
Future<Uint8List> _tinyPng() async {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    Uint8List.fromList(List.filled(4 * 2 * 2, 255)), // 2x2 opaque white RGBA
    2,
    2,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  final image = await completer.future;
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

void main() {
  group('epubImageLoader', () {
    test('decodes a base64 data: URI', () async {
      final pngBytes = await _tinyPng();
      final dataUri = 'data:image/png;base64,${base64.encode(pngBytes)}';

      final loadedImage = Completer<ui.Image>();
      final loadedError = Completer<Object>();

      epubImageLoader(
        dataUri,
        loadedImage.complete,
        loadedError.complete,
      );

      final image = await loadedImage.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('onLoad was never called'),
      );
      expect(image.width, 2);
      expect(image.height, 2);
      expect(loadedError.isCompleted, isFalse);
    });

    test('reports an error for a malformed data URI (no comma)', () {
      Object? error;
      epubImageLoader('data:image/png;base64', (_) {}, (e) => error = e);
      expect(error, isA<FormatException>());
    });

    test('reports an error for a non-base64 data URI', () {
      Object? error;
      epubImageLoader(
        'data:text/plain,hello',
        (_) {},
        (e) => error = e,
      );
      expect(error, isA<FormatException>());
    });

    test(
        'a non-data: src does not throw synchronously (delegates to '
        'defaultImageLoader)', () {
      // Real network resolution isn't exercised here (no network in the
      // test environment) — this only proves the delegation branch is taken
      // instead of being (mis)treated as a malformed data URI.
      expect(
        () => epubImageLoader(
          'https://example.com/cover.png',
          (_) {},
          (_) {},
        ),
        returnsNormally,
      );
    });
  });

  group('EpubBook.open', () {
    test('is not implemented yet (scaffolding)', () async {
      // open() is async (see its dartdoc for why) — pass the Future itself
      // to throwsA/expectLater, not a closure, and await the expectation.
      await expectLater(
        EpubBook.open(Uint8List(0)),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
