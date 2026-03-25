import 'dart:io';
import 'package:path_provider/path_provider.dart' as paths;
import '../interfaces/file_system_provider.dart';

class DefaultFileSystemProvider implements FileSystemProvider {
  @override
  Future<Directory> getStorageDirectory() async {
    if (Platform.isAndroid) {
      return (await paths.getExternalStorageDirectory()) ??
          await paths.getApplicationDocumentsDirectory();
    }
    return await paths.getApplicationDocumentsDirectory();
  }

  @override
  Future<Directory> getCacheDirectory() async =>
      await paths.getTemporaryDirectory();
  @override
  Future<Directory> getDocumentsDirectory() async =>
      await paths.getApplicationDocumentsDirectory();
  @override
  Future<Directory?> getDownloadsDirectory() async =>
      await paths.getDownloadsDirectory();
}
