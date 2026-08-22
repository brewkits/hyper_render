import 'dart:typed_data';

/// Common abstraction for file saving operations across IO and Web.
abstract class PlatformFileHelper {
  /// Save bytes to storage and return saved path (or identifier on Web).
  Future<String?> saveImageBytes(Uint8List bytes, String filename);

  /// Share image bytes via system share dialog.
  Future<bool> shareImageBytes(Uint8List bytes,
      {String? text, String? filename});

  /// Path to cache directory.
  Future<String?> getCacheDirectoryPath();

  /// Path to storage directory.
  Future<String?> getStorageDirectoryPath();
}
