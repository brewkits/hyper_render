import 'dart:typed_data';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'file_helper_interface.dart';

/// Web implementation of PlatformFileHelper for Web/WASM runtimes.
class PlatformFileHelperImpl implements PlatformFileHelper {
  const PlatformFileHelperImpl();

  @override
  Future<String?> getStorageDirectoryPath() async => null;

  @override
  Future<String?> getCacheDirectoryPath() async => null;

  @override
  Future<String?> saveImageBytes(Uint8List bytes, String filename) async {
    // Web environment: file downloads are handled in-browser
    return null;
  }

  @override
  Future<bool> shareImageBytes(
    Uint8List bytes, {
    String? text,
    String? filename,
  }) async {
    try {
      final name =
          filename ?? 'share_${DateTime.now().millisecondsSinceEpoch}.png';
      await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          files: [share_plus.XFile.fromData(bytes, name: name)],
          text: text,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
