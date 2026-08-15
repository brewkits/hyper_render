/// Thrown by `EpubBook.open` when the bytes it was given are not a usable
/// EPUB — not a zip at all, or missing the structural pieces (`container.xml`,
/// an OPF package document, a spine) that every reader needs to show anything.
///
/// Damage that only affects *part* of a book — a chapter whose file is absent
/// from the archive, an unparsable table of contents, an image with a broken
/// `src` — deliberately does **not** throw: those degrade to a skipped chapter,
/// an empty [EpubBook.tableOfContents], or an untouched `src` respectively, so
/// a slightly-malformed book still opens.
class EpubFormatException implements Exception {
  /// What was wrong with the archive.
  final String message;

  /// Creates an exception describing [message].
  const EpubFormatException(this.message);

  @override
  String toString() => 'EpubFormatException: $message';
}
