import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:super_clipboard/super_clipboard.dart' show DataWriterItem, Formats, SystemClipboard;

/// Image clipboard handler using super_clipboard package
///
/// Provides full support for:
/// - Copying images to clipboard (not just URLs)
/// - Saving images to device storage
/// - Sharing images via system share dialog
///
/// ## Usage
/// ```dart
/// import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';
///
/// HyperViewer(
///   html: content,
///   imageClipboardHandler: SuperClipboardHandler(),
/// )
/// ```
///
/// ## Platform Support
/// - macOS: Full support
/// - Windows: Full support
/// - Linux: Full support (requires xclip)
/// - iOS: Copy/Share support
/// - Android: Copy/Share support
/// - Web: Limited support
class SuperClipboardHandler implements ImageClipboardHandler {
  /// HTTP client for downloading images
  final http.Client? _httpClient;

  /// Creates a SuperClipboardHandler
  ///
  /// Optionally provide a custom [httpClient] for testing or custom configuration.
  SuperClipboardHandler({http.Client? httpClient}) : _httpClient = httpClient;

  http.Client get _client => _httpClient ?? http.Client();

  @override
  Future<bool> copyImageFromUrl(String imageUrl) async {
    try {
      // Download image
      final response = await _client.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return false;

      return copyImageBytes(
        response.bodyBytes,
        mimeType: response.headers['content-type'],
      );
    } catch (e) {
      debugPrint('SuperClipboardHandler.copyImageFromUrl error: $e');
      return false;
    }
  }

  @override
  Future<bool> copyImageBytes(Uint8List bytes, {String? mimeType}) async {
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) return false;

      final item = DataWriterItem();

      // Add image data based on mime type
      switch (mimeType?.toLowerCase()) {
        case 'image/jpeg':
        case 'image/jpg':
          item.add(Formats.jpeg(bytes));
          break;
        case 'image/gif':
          item.add(Formats.gif(bytes));
          break;
        case 'image/webp':
          item.add(Formats.webp(bytes));
          break;
        case 'image/tiff':
          item.add(Formats.tiff(bytes));
          break;
        case 'image/png':
        default:
          // Default to PNG
          item.add(Formats.png(bytes));
          break;
      }

      await clipboard.write([item]);
      return true;
    } catch (e) {
      debugPrint('SuperClipboardHandler.copyImageBytes error: $e');
      return false;
    }
  }

  @override
  Future<String?> saveImageFromUrl(String imageUrl, {String? filename}) async {
    try {
      // Download image
      final response = await _client.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;

      // Generate filename from URL if not provided
      final name = filename ?? _getFilenameFromUrl(imageUrl);

      return saveImageBytes(response.bodyBytes, filename: name);
    } catch (e) {
      debugPrint('SuperClipboardHandler.saveImageFromUrl error: $e');
      return null;
    }
  }

  @override
  Future<String?> saveImageBytes(Uint8List bytes, {String? filename}) async {
    try {
      // Get downloads/pictures directory
      final Directory dir;
      if (Platform.isAndroid) {
        dir = (await getExternalStorageDirectory()) ??
            await getApplicationDocumentsDirectory();
      } else if (Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        dir = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      // Generate unique filename if not provided
      final name = filename ?? 'image_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$name');

      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('SuperClipboardHandler.saveImageBytes error: $e');
      return null;
    }
  }

  @override
  Future<bool> shareImageFromUrl(String imageUrl, {String? text}) async {
    try {
      // Download image
      final response = await _client.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return false;

      final filename = _getFilenameFromUrl(imageUrl);
      return shareImageBytes(response.bodyBytes, text: text, filename: filename);
    } catch (e) {
      debugPrint('SuperClipboardHandler.shareImageFromUrl error: $e');
      return false;
    }
  }

  @override
  Future<bool> shareImageBytes(
    Uint8List bytes, {
    String? text,
    String? filename,
  }) async {
    try {
      // Save to temp file for sharing
      final tempDir = await getTemporaryDirectory();
      final name = filename ?? 'share_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$name');
      await file.writeAsBytes(bytes);

      // Share using share_plus
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
      );

      return true;
    } catch (e) {
      debugPrint('SuperClipboardHandler.shareImageBytes error: $e');
      return false;
    }
  }

  @override
  bool get isImageCopySupported => !kIsWeb; // Web has limited clipboard support

  @override
  bool get isSaveSupported => !kIsWeb;

  @override
  bool get isShareSupported => true; // share_plus supports all platforms

  @override
  List<String> get supportedFormats => const [
        'image/png',
        'image/jpeg',
        'image/gif',
        'image/webp',
        'image/bmp',
      ];

  /// Extract filename from URL
  String _getFilenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last;
        if (lastSegment.contains('.')) {
          return lastSegment;
        }
      }
    } catch (_) {}
    return 'image_${DateTime.now().millisecondsSinceEpoch}.png';
  }
}
