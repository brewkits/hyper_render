import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'epub_exception.dart';
import 'epub_path.dart';

/// The decoded contents of an `.epub` zip, keyed by normalised entry name.
///
/// Kept as a plain map rather than an [Archive] because every lookup in this
/// package is by path, and `Archive` only offers a linear scan.
class EpubArchive {
  final Map<String, Uint8List> _files;

  EpubArchive._(this._files);

  /// Unzips [bytes].
  ///
  /// Throws [EpubFormatException] when the bytes are not a readable zip.
  factory EpubArchive.decode(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw EpubFormatException('Not a readable zip archive: $e');
    }
    final files = <String, Uint8List>{};
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final content = file.readBytes();
      if (content == null) continue;
      files[epubNormalize(file.name)] = Uint8List.fromList(content);
    }
    if (files.isEmpty) {
      throw const EpubFormatException('Archive contains no files.');
    }
    return EpubArchive._(files);
  }

  /// Every entry name in the archive.
  Iterable<String> get names => _files.keys;

  /// Raw bytes for [path], or `null` when the archive has no such entry.
  Uint8List? read(String? path) => path == null ? null : _files[path];

  /// [path] decoded as text, or `null` when the entry is missing.
  ///
  /// EPUB mandates UTF-8 or UTF-16 for XML content; malformed sequences are
  /// replaced rather than thrown on, because a single bad byte in one chapter
  /// should not fail the whole book.
  String? readText(String? path) {
    final bytes = read(path);
    if (bytes == null) return null;
    return decodeEpubText(bytes);
  }
}

/// Decodes XML/XHTML bytes from an EPUB, honouring a UTF-8 or UTF-16 BOM.
String decodeEpubText(Uint8List bytes) {
  if (bytes.length >= 2) {
    if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return _decodeUtf16(bytes, 2, bigEndian: true);
    }
    if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return _decodeUtf16(bytes, 2, bigEndian: false);
    }
  }
  var start = 0;
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    start = 3;
  }
  return utf8.decode(
    start == 0 ? bytes : bytes.sublist(start),
    allowMalformed: true,
  );
}

String _decodeUtf16(Uint8List bytes, int start, {required bool bigEndian}) {
  final units = <int>[];
  for (var i = start; i + 1 < bytes.length; i += 2) {
    units.add(
      bigEndian
          ? (bytes[i] << 8) | bytes[i + 1]
          : (bytes[i + 1] << 8) | bytes[i],
    );
  }
  return String.fromCharCodes(units);
}
