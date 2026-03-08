import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';

void main() {
  group('SuperClipboardHandler', () {
    group('capability flags', () {
      test('isImageCopySupported is true (non-web)', () {
        final handler = SuperClipboardHandler();
        // kIsWeb is false in test environment
        expect(handler.isImageCopySupported, isTrue);
      });

      test('isSaveSupported is true (non-web)', () {
        final handler = SuperClipboardHandler();
        expect(handler.isSaveSupported, isTrue);
      });

      test('isShareSupported is always true', () {
        final handler = SuperClipboardHandler();
        expect(handler.isShareSupported, isTrue);
      });

      test('supportedFormats contains standard image types', () {
        final handler = SuperClipboardHandler();
        final formats = handler.supportedFormats;
        expect(formats, contains('image/png'));
        expect(formats, contains('image/jpeg'));
        expect(formats, contains('image/gif'));
        expect(formats, contains('image/webp'));
      });
    });

    group('copyImageFromUrl — HTTP failures', () {
      test('returns false on non-200 HTTP response', () async {
        final handler = SuperClipboardHandler(
          httpClient: MockClient((_) async => http.Response('Not Found', 404)),
        );
        final result = await handler.copyImageFromUrl('https://example.com/image.png');
        expect(result, isFalse);
      });

      test('returns false on 500 server error', () async {
        final handler = SuperClipboardHandler(
          httpClient: MockClient((_) async => http.Response('Error', 500)),
        );
        final result = await handler.copyImageFromUrl('https://example.com/image.png');
        expect(result, isFalse);
      });

      test('returns false on network exception', () async {
        final handler = SuperClipboardHandler(
          httpClient: MockClient((_) async => throw Exception('No network')),
        );
        final result = await handler.copyImageFromUrl('https://example.com/image.png');
        expect(result, isFalse);
      });
    });

    group('saveImageFromUrl — HTTP failures', () {
      test('returns null on non-200 HTTP response', () async {
        final handler = SuperClipboardHandler(
          httpClient: MockClient((_) async => http.Response('Not Found', 404)),
        );
        final result = await handler.saveImageFromUrl('https://example.com/image.png');
        expect(result, isNull);
      });

      test('returns null on network exception', () async {
        final handler = SuperClipboardHandler(
          httpClient: MockClient((_) async => throw Exception('No network')),
        );
        final result = await handler.saveImageFromUrl('https://example.com/image.png');
        expect(result, isNull);
      });
    });

    group('shareImageFromUrl — HTTP failures', () {
      test('returns false on non-200 HTTP response', () async {
        final handler = SuperClipboardHandler(
          httpClient: MockClient((_) async => http.Response('Not Found', 404)),
        );
        final result = await handler.shareImageFromUrl('https://example.com/image.png');
        expect(result, isFalse);
      });

      test('returns false on network exception', () async {
        final handler = SuperClipboardHandler(
          httpClient: MockClient((_) async => throw Exception('No network')),
        );
        final result = await handler.shareImageFromUrl('https://example.com/image.png');
        expect(result, isFalse);
      });
    });

    group('copyImageBytes — no SystemClipboard in test env', () {
      test('returns false when SystemClipboard.instance is null', () async {
        final handler = SuperClipboardHandler();
        // In test environment SystemClipboard.instance is null → returns false
        final result = await handler.copyImageBytes(
          Uint8List.fromList([137, 80, 78, 71]), // PNG magic bytes
          mimeType: 'image/png',
        );
        expect(result, isFalse);
      });

      test('returns false for jpeg bytes when clipboard unavailable', () async {
        final handler = SuperClipboardHandler();
        final result = await handler.copyImageBytes(
          Uint8List.fromList([0xFF, 0xD8, 0xFF]), // JPEG magic bytes
          mimeType: 'image/jpeg',
        );
        expect(result, isFalse);
      });
    });

    group('implements ImageClipboardHandler interface', () {
      test('SuperClipboardHandler is an ImageClipboardHandler', () {
        final handler = SuperClipboardHandler();
        expect(handler, isA<ImageClipboardHandler>());
      });
    });
  });

  group('DefaultImageClipboardHandler', () {
    test('isImageCopySupported is false', () {
      const handler = DefaultImageClipboardHandler();
      expect(handler.isImageCopySupported, isFalse);
    });

    test('isSaveSupported is false', () {
      const handler = DefaultImageClipboardHandler();
      expect(handler.isSaveSupported, isFalse);
    });

    test('isShareSupported is false', () {
      const handler = DefaultImageClipboardHandler();
      expect(handler.isShareSupported, isFalse);
    });

    test('supportedFormats is empty', () {
      const handler = DefaultImageClipboardHandler();
      expect(handler.supportedFormats, isEmpty);
    });

    test('copyImageBytes returns false', () async {
      const handler = DefaultImageClipboardHandler();
      final result = await handler.copyImageBytes(Uint8List(4));
      expect(result, isFalse);
    });

    test('saveImageFromUrl returns null', () async {
      const handler = DefaultImageClipboardHandler();
      final result = await handler.saveImageFromUrl('https://example.com/img.png');
      expect(result, isNull);
    });

    test('saveImageBytes returns null', () async {
      const handler = DefaultImageClipboardHandler();
      final result = await handler.saveImageBytes(Uint8List(4));
      expect(result, isNull);
    });

    test('shareImageBytes returns false', () async {
      const handler = DefaultImageClipboardHandler();
      final result = await handler.shareImageBytes(Uint8List(4));
      expect(result, isFalse);
    });
  });

  group('ImageOperationResult', () {
    test('success factory sets success=true', () {
      final result = ImageOperationResult.success(filePath: '/tmp/img.png');
      expect(result.success, isTrue);
      expect(result.filePath, '/tmp/img.png');
      expect(result.error, isNull);
    });

    test('failure factory sets success=false with error', () {
      final result = ImageOperationResult.failure('something went wrong');
      expect(result.success, isFalse);
      expect(result.error, 'something went wrong');
      expect(result.filePath, isNull);
    });
  });
}
