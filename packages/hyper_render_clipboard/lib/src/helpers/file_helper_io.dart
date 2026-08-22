import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as paths;
import 'package:share_plus/share_plus.dart' as share_plus;
import 'file_helper_interface.dart';

/// IO implementation of PlatformFileHelper for Native platforms.
class PlatformFileHelperImpl implements PlatformFileHelper {
  const PlatformFileHelperImpl();

  @override
  Future<String?> getStorageDirectoryPath() async {
    try {
      if (Platform.isAndroid) {
        final ext = await paths.getExternalStorageDirectory();
        if (ext != null) return ext.path;
      }
      final doc = await paths.getApplicationDocumentsDirectory();
      return doc.path;
    } catch (e) {
      debugPrint('PlatformFileHelperImpl.getStorageDirectoryPath error: $e');
      return null;
    }
  }

  @override
  Future<String?> getCacheDirectoryPath() async {
    try {
      final cache = await paths.getTemporaryDirectory();
      return cache.path;
    } catch (e) {
      debugPrint('PlatformFileHelperImpl.getCacheDirectoryPath error: $e');
      return null;
    }
  }

  @override
  Future<String?> saveImageBytes(Uint8List bytes, String filename) async {
    try {
      final dirPath = await getStorageDirectoryPath();
      if (dirPath == null) return null;
      final file = File('$dirPath/$filename');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('PlatformFileHelperImpl.saveImageBytes error: $e');
      return null;
    }
  }

  @override
  Future<bool> shareImageBytes(
    Uint8List bytes, {
    String? text,
    String? filename,
  }) async {
    try {
      final cachePath = await getCacheDirectoryPath();
      if (cachePath == null) return false;
      final name =
          filename ?? 'share_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('$cachePath/$name');
      await file.writeAsBytes(bytes);

      await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          files: [share_plus.XFile(file.path)],
          text: text,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('PlatformFileHelperImpl.shareImageBytes error: $e');
      return false;
    }
  }
}
