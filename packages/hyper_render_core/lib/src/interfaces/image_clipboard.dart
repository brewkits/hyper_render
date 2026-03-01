
import 'package:flutter/services.dart';

/// Interface for image clipboard and sharing operations
///
/// This interface allows users to provide custom implementations
/// for copying images to clipboard, saving to device, and sharing.
///
/// ## Default Implementation
/// The [DefaultImageClipboardHandler] only supports copying URLs to clipboard.
/// For full image clipboard support, use a custom implementation with
/// packages like `super_clipboard`.
///
/// ## Example Custom Implementation
/// ```dart
/// class SuperClipboardHandler implements ImageClipboardHandler {
///   @override
///   Future<bool> copyImageFromUrl(String imageUrl) async {
///     final response = await http.get(Uri.parse(imageUrl));
///     final item = DataWriterItem();
///     item.add(Formats.png(response.bodyBytes));
///     await ClipboardWriter.instance.write([item]);
///     return true;
///   }
///   // ... other methods
/// }
/// ```
abstract class ImageClipboardHandler {
  /// Copy image from URL to clipboard
  ///
  /// Downloads the image and copies it to the system clipboard.
  /// Returns true if successful.
  Future<bool> copyImageFromUrl(String imageUrl);

  /// Copy image bytes directly to clipboard
  ///
  /// Copies raw image data to the system clipboard.
  /// Returns true if successful.
  Future<bool> copyImageBytes(Uint8List bytes, {String? mimeType});

  /// Save image from URL to device storage
  ///
  /// Downloads and saves the image to the device's gallery or downloads folder.
  /// Returns the saved file path if successful, null otherwise.
  Future<String?> saveImageFromUrl(String imageUrl, {String? filename});

  /// Save image bytes to device storage
  ///
  /// Saves raw image data to the device's gallery or downloads folder.
  /// Returns the saved file path if successful, null otherwise.
  Future<String?> saveImageBytes(Uint8List bytes, {String? filename});

  /// Share image from URL
  ///
  /// Opens the system share dialog with the image.
  /// Returns true if the share dialog was opened successfully.
  Future<bool> shareImageFromUrl(String imageUrl, {String? text});

  /// Share image bytes
  ///
  /// Opens the system share dialog with the image data.
  /// Returns true if the share dialog was opened successfully.
  Future<bool> shareImageBytes(Uint8List bytes, {String? text, String? filename});

  /// Check if full image clipboard is supported
  ///
  /// Returns true if this handler supports copying actual image data
  /// (not just URLs) to the clipboard.
  bool get isImageCopySupported;

  /// Check if saving images is supported
  bool get isSaveSupported;

  /// Check if sharing images is supported
  bool get isShareSupported;

  /// Get list of supported image formats for clipboard
  List<String> get supportedFormats;
}

/// Default implementation that only supports URL copying
///
/// This is a fallback implementation that copies the image URL
/// to the clipboard instead of the actual image data.
///
/// For full image clipboard support, use a package like `super_clipboard`
/// and implement [ImageClipboardHandler].
class DefaultImageClipboardHandler implements ImageClipboardHandler {
  const DefaultImageClipboardHandler();

  @override
  Future<bool> copyImageFromUrl(String imageUrl) async {
    // Fallback: copy URL to clipboard
    await Clipboard.setData(ClipboardData(text: imageUrl));
    return true;
  }

  @override
  Future<bool> copyImageBytes(Uint8List bytes, {String? mimeType}) async {
    // Not supported in default implementation
    return false;
  }

  @override
  Future<String?> saveImageFromUrl(String imageUrl, {String? filename}) async {
    // Not supported in default implementation
    return null;
  }

  @override
  Future<String?> saveImageBytes(Uint8List bytes, {String? filename}) async {
    // Not supported in default implementation
    return null;
  }

  @override
  Future<bool> shareImageFromUrl(String imageUrl, {String? text}) async {
    // Fallback: copy URL to clipboard
    await Clipboard.setData(ClipboardData(text: imageUrl));
    return true;
  }

  @override
  Future<bool> shareImageBytes(Uint8List bytes, {String? text, String? filename}) async {
    // Not supported in default implementation
    return false;
  }

  @override
  bool get isImageCopySupported => false;

  @override
  bool get isSaveSupported => false;

  @override
  bool get isShareSupported => false;

  @override
  List<String> get supportedFormats => const [];
}

/// Result of an image operation
class ImageOperationResult {
  /// Whether the operation was successful
  final bool success;

  /// Error message if operation failed
  final String? error;

  /// File path if operation saved a file
  final String? filePath;

  const ImageOperationResult({
    required this.success,
    this.error,
    this.filePath,
  });

  factory ImageOperationResult.success({String? filePath}) =>
      ImageOperationResult(success: true, filePath: filePath);

  factory ImageOperationResult.failure(String error) =>
      ImageOperationResult(success: false, error: error);
}
