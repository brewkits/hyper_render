// Shared in-memory EPUB fixtures for this package's tests.
//
// Books are zipped on the fly rather than committed as binaries, which keeps
// malformed variants (missing chapter, broken TOC, odd filenames) one map
// entry away.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Zips [entries] in memory — a `String` value becomes a UTF-8 text entry,
/// a byte list is stored as-is. Building fixtures this way (rather than
/// committing a binary `.epub`) is what makes the malformed variants below
/// possible.
Uint8List buildEpub(Map<String, Object> entries) {
  final archive = Archive();
  entries.forEach((name, value) {
    archive.addFile(
      value is String
          ? ArchiveFile.string(name, value)
          : ArchiveFile.bytes(name, value as List<int>),
    );
  });
  return ZipEncoder().encodeBytes(archive);
}

const String containerXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''';

/// 1×1 transparent PNG.
final Uint8List pngBytes = base64.decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAE'
  'hQGAhKmMIQAAAABJRU5ErkJggg==',
);

String opfXml({
  String metadata = '''
    <dc:title>Test Book</dc:title>
    <dc:creator>A. Writer</dc:creator>''',
  String manifest = '''
    <item id="ch1" href="text/chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch2" href="text/chapter2.xhtml" media-type="application/xhtml+xml"/>
    <item id="css" href="styles/main.css" media-type="text/css"/>
    <item id="img" href="images/pic.png" media-type="image/png"/>''',
  String spine = '''
    <itemref idref="ch1"/>
    <itemref idref="ch2"/>''',
  String spineAttrs = '',
}) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
$metadata
  </metadata>
  <manifest>
$manifest
  </manifest>
  <spine$spineAttrs>
$spine
  </spine>
</package>
''';

String chapterXhtml(String body) => '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Chapter</title>
    <link rel="stylesheet" type="text/css" href="../styles/main.css"/>
  </head>
  <body>
$body
  </body>
</html>
''';
