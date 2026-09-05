/// Syntax auto-repair utility for streaming Markdown and HTML tokens.
///
/// In streaming LLM responses, tokens arrive in incomplete syntactic fragments
/// (such as unclosed code fences, unclosed bold asterisks, or truncated HTML tags).
///
/// [StreamSyntaxNormalizer] auto-repairs transient syntax on-the-fly so that
/// intermediate streaming frames render without layout breakage or throwing
/// parser syntax errors.
class StreamSyntaxNormalizer {
  const StreamSyntaxNormalizer._();

  /// Normalizes an in-flight streaming Markdown string by auto-closing any
  /// unclosed formatting constructs (code fences, bold, italic, inline code).
  static String normalizeMarkdown(String input) {
    if (input.isEmpty) return input;

    var text = input;

    // 1. Code Fence Repair (``` or ~~~)
    final fenceMatches =
        RegExp(r'(^|\n)(```|~~~)', multiLine: true).allMatches(text);
    if (fenceMatches.length % 2 != 0) {
      final lastMatch = fenceMatches.last;
      final fenceType = lastMatch.group(2) ?? '```';
      text = '$text\n$fenceType\n';
      return text; // Inside code block, inline markdown formatting is ignored.
    }

    // Everything before the last closed fence is syntactically settled — a
    // stray unmatched backtick/asterisk/bracket *inside* an already-rendered
    // fence must not corrupt unrelated trailing prose, so parity/link scans
    // below are scoped to the text after that point.
    final safeStart = fenceMatches.isEmpty ? 0 : fenceMatches.last.end;
    final scanned = text.substring(safeStart);

    // 2. Inline Code Repair (`...`)
    final backtickCount = _countUnescaped(scanned, '`');
    if (backtickCount % 2 != 0) {
      text = '$text`';
    }

    // 3. Strikethrough Repair (~~...~~)
    final tildePairCount = _countOccurrences(scanned, '~~');
    if (tildePairCount % 2 != 0) {
      text = '$text~~';
    }

    // 4. Bold / Italic Asterisk Repair (***, **, *)
    final boldAsteriskCount = _countOccurrences(scanned, '**');
    if (boldAsteriskCount % 2 != 0) {
      text = '$text**';
    } else {
      // Check single asterisk if not inside bold
      final singleAsteriskCount = _countUnescaped(scanned, '*');
      if (singleAsteriskCount % 2 != 0) {
        text = '$text*';
      }
    }

    // 5. LaTeX Math Block Repair ($$...$$)
    final mathBlockCount = _countOccurrences(scanned, r'$$');
    if (mathBlockCount % 2 != 0) {
      text = '$text\n\$\$\n';
    } else {
      // 6. Inline Math Repair ($...$)
      final inlineMathCount = _countUnescaped(scanned, r'$');
      if (inlineMathCount % 2 != 0) {
        text = '$text\$';
      }
    }

    // 7. Incomplete Link Repair ([text](url...)
    final lastOpenBracket = scanned.lastIndexOf('[');
    final lastCloseBracket = scanned.lastIndexOf(']');
    final lastOpenParen = scanned.lastIndexOf('(');
    final lastCloseParen = scanned.lastIndexOf(')');

    if (lastOpenBracket > lastCloseBracket) {
      // Unclosed bracket link text: [text...
      text = '$text]';
    } else if (lastOpenParen > lastCloseParen &&
        lastOpenParen > lastOpenBracket) {
      // Unclosed url parenthesis: [text](https://...
      text = '$text)';
    }

    // 8. Incomplete Table Row Repair
    final lines = text.split('\n');
    if (lines.isNotEmpty) {
      final lastLine = lines.last.trim();
      if (lastLine.startsWith('|') && !lastLine.endsWith('|')) {
        text = '$text |';
      }
    }

    return text;
  }

  /// Normalizes an in-flight streaming HTML string by auto-closing truncated tags.
  static String normalizeHtml(String input) {
    if (input.isEmpty) return input;

    var text = input;

    // 1. If trailing is an incomplete tag opening like '<div style="foo' without '>'
    // Check for '<' followed by an HTML tag identifier (letter, '/', or '!') to avoid stripping mathematical '<'
    final tagMatches = RegExp(r'<[a-zA-Z/!]').allMatches(text);
    if (tagMatches.isNotEmpty) {
      final lastOpenBracket = tagMatches.last.start;
      final lastCloseBracket = _findTagClose(text, lastOpenBracket);
      if (lastOpenBracket > lastCloseBracket) {
        // Tag is cut midway, remove the partial tag for this frame
        text = text.substring(0, lastOpenBracket);
      }
    }

    return text;
  }

  /// Finds the index of the `>` that actually closes the tag starting at
  /// [tagStart], ignoring a `>` that appears inside a quoted attribute value
  /// (e.g. `<div title="a>b">`). Returns -1 if the tag is never closed.
  static int _findTagClose(String text, int tagStart) {
    String? quote;
    for (var i = tagStart; i < text.length; i++) {
      final ch = text[i];
      if (quote != null) {
        if (ch == quote) quote = null;
      } else if (ch == '"' || ch == "'") {
        quote = ch;
      } else if (ch == '>') {
        return i;
      }
    }
    return -1;
  }

  static int _countUnescaped(String text, String char) {
    var count = 0;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == char && (i == 0 || text[i - 1] != r'\')) {
        count++;
      }
    }
    return count;
  }

  static int _countOccurrences(String text, String pattern) {
    var count = 0;
    var index = 0;
    while ((index = text.indexOf(pattern, index)) != -1) {
      count++;
      index += pattern.length;
    }
    return count;
  }
}
