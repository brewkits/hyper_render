/// CJK Line-Breaking Processor (Kinsoku Shori - 禁則処理)
///
/// Implements Japanese typography rules for proper line breaking:
/// - Kinsoku Start (行頭禁則): Characters that cannot start a line
/// - Kinsoku End (行末禁則): Characters that cannot end a line
///
/// Reference: JIS X 4051 (日本語文書の組版方法)
/// Reference: doc3.md - "Requirement 3: CJK/Japanese Line-breaking"
library;

/// Kinsoku processor for CJK line-breaking rules
class KinsokuProcessor {
  /// Characters that cannot start a line (行頭禁則文字)
  ///
  /// These include:
  /// - Closing brackets: ）」』】〉》〕〗〙〛
  /// - Punctuation: 、。，．！？：；
  /// - Small kana: ぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮ
  /// - Prolonged sound mark: ー
  /// - Special characters: 々〻
  static const String kinsokuStart = '）」』】〉》〕〗〙〛'
      '、。，．！？：；'
      'ぁぃぅぇぉっゃゅょゎ'
      'ァィゥェォッャュョヮ'
      'ヵヶ'
      'ー'
      '々〻'
      '・'
      '゛゜'
      '〜'
      '‐'
      '―'
      '…'
      '‥';

  /// Characters that cannot end a line (行末禁則文字)
  ///
  /// These include:
  /// - Opening brackets: （「『【〈《〔〖〘〚
  static const String kinsokuEnd = '（「『【〈《〔〖〘〚';

  /// Characters that should not be separated (分離禁止)
  ///
  /// These pairs should stay together on the same line
  static const Map<String, String> inseparablePairs = {
    '（': '）',
    '「': '」',
    '『': '』',
    '【': '】',
    '〈': '〉',
    '《': '》',
    '〔': '〕',
    '〖': '〗',
    '〘': '〙',
    '〚': '〛',
  };

  /// Check if a character cannot start a line
  static bool cannotStartLine(String char) {
    if (char.isEmpty) return false;
    return kinsokuStart.contains(char[0]);
  }

  /// Check if a character cannot end a line
  static bool cannotEndLine(String char) {
    if (char.isEmpty) return false;
    return kinsokuEnd.contains(char[0]);
  }

  /// Check if a break is allowed between two characters
  ///
  /// Returns false if:
  /// - The next character cannot start a line (kinsoku start)
  /// - The current character cannot end a line (kinsoku end)
  static bool canBreakBetween(String current, String next) {
    if (current.isEmpty || next.isEmpty) return true;

    final currentChar = current[current.length - 1];
    final nextChar = next[0];

    // Cannot break if next char cannot start a line
    if (cannotStartLine(nextChar)) {
      return false;
    }

    // Cannot break if current char cannot end a line
    if (cannotEndLine(currentChar)) {
      return false;
    }

    return true;
  }

  /// Find the best break point in a string near a given position
  ///
  /// If the position is not a valid break point, this method will search
  /// backwards for a valid break point.
  ///
  /// Returns the index where the break should occur, or -1 if no valid
  /// break point is found.
  static int findBreakPoint(String text, int preferredPosition) {
    if (text.isEmpty) return -1;
    if (preferredPosition >= text.length) return text.length;
    if (preferredPosition <= 0) return -1;

    // Check if preferred position is valid
    if (canBreakBetween(text.substring(0, preferredPosition),
        text.substring(preferredPosition))) {
      return preferredPosition;
    }

    // Search backwards for a valid break point
    for (int i = preferredPosition - 1; i > 0; i--) {
      if (canBreakBetween(text.substring(0, i), text.substring(i))) {
        return i;
      }
    }

    // No valid break point found before preferred position
    // Try searching forward
    for (int i = preferredPosition + 1; i < text.length; i++) {
      if (canBreakBetween(text.substring(0, i), text.substring(i))) {
        return i;
      }
    }

    // No valid break point found
    return -1;
  }

  /// Process a line of text and return adjusted break points
  ///
  /// This method takes a list of word boundaries (from text layout)
  /// and adjusts them according to kinsoku rules.
  static List<int> adjustBreakPoints(String text, List<int> originalBreaks) {
    if (originalBreaks.isEmpty) return [];

    final adjusted = <int>[];

    for (final breakPoint in originalBreaks) {
      final adjustedPoint = findBreakPoint(text, breakPoint);
      if (adjustedPoint > 0 && !adjusted.contains(adjustedPoint)) {
        adjusted.add(adjustedPoint);
      }
    }

    adjusted.sort();
    return adjusted;
  }

  /// Check if a character is a CJK character
  ///
  /// This includes:
  /// - CJK Unified Ideographs (U+4E00 - U+9FFF)
  /// - Hiragana (U+3040 - U+309F)
  /// - Katakana (U+30A0 - U+30FF)
  /// - CJK Symbols and Punctuation (U+3000 - U+303F)
  /// - Fullwidth ASCII variants (U+FF00 - U+FFEF)
  static bool isCjkCharacter(String char) {
    if (char.isEmpty) return false;

    final code = char.codeUnitAt(0);

    // CJK Unified Ideographs
    if (code >= 0x4E00 && code <= 0x9FFF) return true;

    // Hiragana
    if (code >= 0x3040 && code <= 0x309F) return true;

    // Katakana
    if (code >= 0x30A0 && code <= 0x30FF) return true;

    // CJK Symbols and Punctuation
    if (code >= 0x3000 && code <= 0x303F) return true;

    // Fullwidth forms
    if (code >= 0xFF00 && code <= 0xFFEF) return true;

    // CJK Unified Ideographs Extension A
    if (code >= 0x3400 && code <= 0x4DBF) return true;

    return false;
  }

  /// Check if text contains any CJK characters
  static bool containsCjk(String text) {
    for (int i = 0; i < text.length; i++) {
      if (isCjkCharacter(text[i])) {
        return true;
      }
    }
    return false;
  }
}

/// Extension for String to apply kinsoku processing
extension KinsokuStringExtension on String {
  /// Check if this character cannot start a line
  bool get isKinsokuStart => KinsokuProcessor.cannotStartLine(this);

  /// Check if this character cannot end a line
  bool get isKinsokuEnd => KinsokuProcessor.cannotEndLine(this);

  /// Check if this is a CJK character
  bool get isCjk => KinsokuProcessor.isCjkCharacter(this);

  /// Check if this string contains CJK characters
  bool get containsCjk => KinsokuProcessor.containsCjk(this);
}
