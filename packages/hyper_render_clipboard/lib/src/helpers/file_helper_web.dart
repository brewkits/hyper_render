import 'dart:typed_data';
import 'file_helper_interface.dart';

/// Web/WASM implementation of [PlatformFileHelper].
///
/// Avoids importing `share_plus` or `path_provider` on Web/WASM targets to maintain
/// 100% WASM runtime compatibility without pulling in transitive `dart:io` dependencies.
class PlatformFileHelperImpl implements PlatformFileHelper {
  const PlatformFileHelperImpl();

  @override
  Future<String?> getStorageDirectoryPath() async => null;

  @override
  Future<String?> getCacheDirectoryPath() async => null;

  @override
  Future<String?> saveImageBytes(Uint8List bytes, String filename) async {
    // In web/WASM environments, file saving directly to OS filesystem is not supported.
    return null;
  }

  @override
  Future<bool> shareImageBytes(
    Uint8List bytes, {
    String? text,
    String? filename,
  }) async {
    // Web/WASM share fallback without pulling native share_plus dependencies
    return false;
  }
}
