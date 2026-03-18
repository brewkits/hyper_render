import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:super_clipboard/super_clipboard.dart' as super_clipboard;

import 'interfaces/file_system_provider.dart';
import 'providers/default_file_system_provider.dart';

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
  final http.Client _client;
  final FileSystemProvider _fileSystem;

  /// Creates a SuperClipboardHandler
  ///
  /// Optionally provide a custom [httpClient] for testing or custom configuration.
  /// Optionally provide a custom [fileSystem] for platform-specific file handling.
  SuperClipboardHandler({
    http.Client? httpClient,
    FileSystemProvider? fileSystem,
  })  : _client = httpClient ?? http.Client(),
        _fileSystem = fileSystem ?? DefaultFileSystemProvider();

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
      final clipboard = super_clipboard.SystemClipboard.instance;
      if (clipboard == null) return false;

      final item = super_clipboard.DataWriterItem();

      // Add image data based on mime type
      switch (mimeType?.toLowerCase()) {
        case 'image/jpeg':
        case 'image/jpg':
          item.add(super_clipboard.Formats.jpeg(bytes));
          break;
        case 'image/gif':
          item.add(super_clipboard.Formats.gif(bytes));
          break;
        case 'image/webp':
          item.add(super_clipboard.Formats.webp(bytes));
          break;
        case 'image/tiff':
          item.add(super_clipboard.Formats.tiff(bytes));
          break;
        case 'image/png':
        default:
          // Default to PNG
          item.add(super_clipboard.Formats.png(bytes));
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
      final dir = await _fileSystem.getStorageDirectory();

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
      final tempDir = await _fileSystem.getCacheDirectory();
      final name = filename ?? 'share_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$name');
      await file.writeAsBytes(bytes);

      // Share using share_plus
      await share_plus.Share.shareXFiles(
        [share_plus.XFile(file.path)],
        text: text,
      );
      return true;
    } catch (e) {
      debugPrint('SuperClipboardHandler.shareImageBytes error: $e');
      return false;
    }
  }

  @override
  bool get isCopySupported => true;

  @override
  bool get isImageCopySupported => !kIsWeb;

  @override
  bool get isSaveSupported => !kIsWeb;

  @override
  bool get isShareSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

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
