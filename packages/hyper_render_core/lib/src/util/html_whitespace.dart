/// Canonical CSS/HTML "collapsible whitespace" definition shared by every
/// parser / layout stage in the HyperRender ecosystem.
///
/// CSS Text Module Level 3 defines the whitespace characters subject to
/// collapsing as space (U+0020), tab (U+0009), line feed (U+000A), carriage
/// return (U+000D), and form feed (U+000C) — nothing else. In particular
/// U+00A0 NO-BREAK SPACE (the character `&nbsp;` decodes to) is explicitly
/// NOT one of them: it is a normal, always-visible printing character that
/// must survive whitespace collapsing and must not be treated as "empty"
/// content when deciding whether a text run/paragraph has visible height.
///
/// Dart's built-in [String.trim] and the `\s` character class in [RegExp]
/// both follow Unicode's general `White_Space` property, which — unlike the
/// CSS definition — DOES include U+00A0. Using either of those against
/// HTML-sourced text silently turns `&nbsp;` into a collapsible space and
/// can collapse an entire `<p>&nbsp;</p>` down to zero height. Route any
/// "is this text run only insignificant whitespace" / "collapse runs of
/// whitespace to one space" decision through this file instead of
/// `.trim()`/`\s` directly.
library;

/// Matches one or more CSS-collapsible whitespace characters. Use with
/// `text.replaceAll(cssWhitespaceRun, ' ')` to collapse whitespace runs
/// the way CSS does, without touching U+00A0 or other Unicode spaces.
final RegExp cssWhitespaceRun = RegExp('[ \t\n\r\f]+');

/// Whether [text] contains no characters other than CSS-collapsible
/// whitespace (space/tab/LF/CR/FF). Empty strings count as whitespace-only.
///
/// Use in place of `text.trim().isEmpty`, which also matches a lone
/// `&nbsp;` (U+00A0) and would misclassify meaningful non-breaking-space
/// content as droppable/collapsible.
bool isCssWhitespaceOnly(String text) =>
    text.replaceAll(cssWhitespaceRun, '').isEmpty;
