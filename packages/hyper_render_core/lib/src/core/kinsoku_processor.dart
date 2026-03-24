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
  /// Characters that cannot start a line (行頭禁則文字).
  ///
  /// Sources:
  /// - JIS X 4051 §4.3 (Japanese)
  /// - GB/T 15834-2011 §5 (Simplified Chinese)
  /// - CNS 11643 / MOE standard (Traditional Chinese)
  /// - KS X 1001 (Korean)
  static const String kinsokuStart =
      // ── Closing brackets (all CJK scripts) ─────────────────────────────
      '）」』】〉》〕〗〙〛'
      '｣' // U+FF63 halfwidth right corner bracket (Japanese/Korean)
      '〞〟' // U+301E/301F Traditional Chinese double-prime closing quotes
      // ── Punctuation (Japanese / Chinese shared) ──────────────────────
      '、。，．！？：；'
      // ── Small kana — cannot lead a syllable (Japanese) ───────────────
      'ぁぃぅぇぉっゃゅょゎ' // small Hiragana
      'ァィゥェォッャュョヮ' // small Katakana
      'ヵヶ' // small KA/KE
      // ── Japanese-specific ─────────────────────────────────────────────
      'ー' // prolonged sound mark
      '々〻' // iteration marks
      '・' // katakana middle dot
      '゛゜' // voiced / semi-voiced sound marks
      '〜' // wave dash
      '‐―' // hyphen, horizontal bar
      '…‥' // ellipsis, two-dot leader
      // ── Chinese (Simplified — GB/T 15834) ────────────────────────────
      '"\'' // U+201D " U+2019 ' — right smart quotes
      '·' // U+00B7 middle dot (name interpunct: 巴拉克·奥巴马)
      '—' // U+2014 em dash (must not open a line in Chinese)
      // ── Korean ────────────────────────────────────────────────────────
      '〃'; // U+3003 ditto mark (used in Korean/Japanese tables)

  /// Characters that cannot end a line (行末禁則文字).
  ///
  /// Sources: JIS X 4051, GB/T 15834, KS X 1001.
  static const String kinsokuEnd =
      // ── Opening brackets (all CJK scripts) ──────────────────────────
      '（「『【〈《〔〖〘〚'
      '｢' // U+FF62 halfwidth left corner bracket (Japanese/Korean)
      '〝' // U+301D Traditional Chinese left double-prime quotation mark
      '［｛' // U+FF3B fullwidth [ , U+FF5B fullwidth {
      // ── Chinese smart-quote opens ────────────────────────────────────
      '"\'' // U+201C " U+2018 '
  ;

  /// Matching bracket/quote pairs that must not be split across lines (分離禁止).
  ///
  /// Key = opening character, value = its corresponding closing character.
  static const Map<String, String> inseparablePairs = {
    // Japanese / shared CJK
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
    // Halfwidth corner brackets (Japanese/Korean)
    '｢': '｣',
    // Traditional Chinese double-prime quotes
    '〝': '〞',
    // Smart quotes (Chinese Simplified / Korean)
    '\u201C': '\u201D', // " "
    '\u2018': '\u2019', // ' '
    // Fullwidth brackets
    '［': '］',
    '｛': '｝',
  };

  // ── O(1) lookup sets ──────────────────────────────────────────────────────
  //
  // String.contains() on a kinsoku string is O(N) (linear scan through N chars).
  // Dart's text[i] operator also allocates a new single-character String on the
  // heap every call — a silent allocation tax in tight layout loops.
  //
  // These Set<int> tables are built once at class-load time from the canonical
  // kinsokuStart / kinsokuEnd strings.  Lookup via Set.contains(codeUnit) is:
  //   • O(1) amortised hash lookup (vs O(N) string scan)
  //   • Zero heap allocation (int is unboxed by the Dart VM in hot code)
  //
  // All kinsoku characters lie in the Basic Multilingual Plane (U+0000–U+FFFF),
  // so String.codeUnitAt() returns the exact Unicode code point — no surrogate
  // pair handling required.
  static final Set<int> _startCodes = _buildCodeSet(kinsokuStart);
  static final Set<int> _endCodes   = _buildCodeSet(kinsokuEnd);

  static Set<int> _buildCodeSet(String chars) {
    final set = <int>{};
    for (int i = 0; i < chars.length; i++) {
      set.add(chars.codeUnitAt(i));
    }
    return set;
  }

  /// Check if a character cannot start a line
  static bool cannotStartLine(String char) {
    if (char.isEmpty) return false;
    return _startCodes.contains(char.codeUnitAt(0));
  }

  /// Check if a character cannot end a line
  static bool cannotEndLine(String char) {
    if (char.isEmpty) return false;
    return _endCodes.contains(char.codeUnitAt(0));
  }

  /// Check if a break is allowed between two characters.
  ///
  /// Returns false if the next character cannot start a line (kinsoku start)
  /// or the current character cannot end a line (kinsoku end).
  static bool canBreakBetween(String current, String next) {
    if (current.isEmpty || next.isEmpty) return true;
    if (_startCodes.contains(next.codeUnitAt(0))) return false;
    if (_endCodes.contains(current.codeUnitAt(current.length - 1))) return false;
    return true;
  }

  /// Returns true if a line break is allowed between [text[i-1]] and [text[i]].
  ///
  /// Hot-path used inside the scan loops of [findBreakPoint].  Uses
  /// [String.codeUnitAt] (no String allocation) and [Set.contains] (O(1))
  /// instead of `text[i]` (String allocation) + `kinsokuStr.contains` (O(N)).
  static bool _canBreakAt(String text, int i) {
    if (_endCodes.contains(text.codeUnitAt(i - 1))) return false;
    if (_startCodes.contains(text.codeUnitAt(i))) return false;
    return true;
  }

  /// Find the best break point in a string near a given position.
  ///
  /// If the position is not a valid break point, searches backwards then
  /// forwards for the nearest valid break.
  ///
  /// Returns the index where the break should occur, or -1 if no valid
  /// break point is found.
  ///
  /// **Performance note**: uses [_canBreakAt] which avoids `O(N)` substring
  /// allocations per check. The previous implementation called
  /// `canBreakBetween(text.substring(0, i), text.substring(i))` inside every
  /// loop iteration, making the scan `O(N²)` in string allocations for a
  /// fragment of length N. This version is `O(N)`.
  static int findBreakPoint(String text, int preferredPosition) {
    if (text.isEmpty) return -1;
    if (preferredPosition >= text.length) return text.length;
    if (preferredPosition <= 0) return -1;

    // Check if preferred position is valid (O(1))
    if (_canBreakAt(text, preferredPosition)) return preferredPosition;

    // Search backwards for a valid break point (O(N), no substring allocs)
    for (int i = preferredPosition - 1; i > 0; i--) {
      if (_canBreakAt(text, i)) return i;
    }

    // No valid break point found before preferred position — try forward
    for (int i = preferredPosition + 1; i < text.length; i++) {
      if (_canBreakAt(text, i)) return i;
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

  /// Returns true if [code] (a UTF-16 code unit) belongs to a CJK or
  /// East-Asian script that requires character-level line breaking.
  ///
  /// This is the O(1) hot-path used by [containsCjk]. Accepts a raw code unit
  /// so the caller can use [String.codeUnitAt] and avoid the `text[i]` indexing
  /// operator which allocates a new single-character String in Dart.
  ///
  /// ### Coverage
  /// | Script | Range | Language |
  /// |--------|-------|----------|
  /// | CJK Unified Ideographs | U+4E00–U+9FFF | ZH / JA |
  /// | CJK Extension A | U+3400–U+4DBF | ZH (rare) |
  /// | CJK Compatibility Ideographs | U+F900–U+FAFF | ZH / JA |
  /// | CJK Symbols & Punctuation | U+3000–U+303F | ZH / JA / KO |
  /// | CJK Radicals Supplement | U+2E80–U+2EFF | ZH (dictionary) |
  /// | Kangxi Radicals | U+2F00–U+2FDF | ZH (dictionary) |
  /// | Hiragana | U+3040–U+309F | JA |
  /// | Katakana | U+30A0–U+30FF | JA |
  /// | Katakana Phonetic Extensions | U+31F0–U+31FF | JA (Ainu) |
  /// | Bopomofo | U+3100–U+312F | ZH-TW (注音) |
  /// | Bopomofo Extended | U+31A0–U+31BF | ZH-TW |
  /// | Fullwidth ASCII variants | U+FF00–U+FFEF | ZH / JA / KO |
  /// | Hangul Syllables | U+AC00–U+D7A3 | KO (modern) |
  /// | Hangul Jamo | U+1100–U+11FF | KO (combining) |
  /// | Hangul Compatibility Jamo | U+3130–U+318F | KO (fonts) |
  /// | Hangul Jamo Extended-A | U+A960–U+A97F | KO (rare) |
  /// | Hangul Jamo Extended-B | U+D7B0–U+D7FF | KO (rare) |
  ///
  /// CJK Extension B and above (U+20000+) require surrogate pairs in UTF-16
  /// and are not covered here — they represent rare classical characters.
  static bool isCjkCodeUnit(int code) {
    // ── Chinese / Japanese shared ──────────────────────────────────────────
    // CJK Unified Ideographs — the bulk of Kanji/Hanzi
    if (code >= 0x4E00 && code <= 0x9FFF) return true;
    // CJK Extension A — rare/classical Hanzi
    if (code >= 0x3400 && code <= 0x4DBF) return true;
    // CJK Compatibility Ideographs
    if (code >= 0xF900 && code <= 0xFAFF) return true;
    // CJK Symbols and Punctuation (includes 〇 々 etc.)
    if (code >= 0x3000 && code <= 0x303F) return true;
    // CJK Radicals Supplement (radical forms used in dictionaries)
    if (code >= 0x2E80 && code <= 0x2EFF) return true;
    // Kangxi Radicals (dictionary radical index)
    if (code >= 0x2F00 && code <= 0x2FDF) return true;

    // ── Japanese ──────────────────────────────────────────────────────────
    // Hiragana
    if (code >= 0x3040 && code <= 0x309F) return true;
    // Katakana
    if (code >= 0x30A0 && code <= 0x30FF) return true;
    // Katakana Phonetic Extensions (small kana for Ainu/foreign phonology)
    if (code >= 0x31F0 && code <= 0x31FF) return true;

    // ── Traditional Chinese (ZH-TW / ZH-HK) ──────────────────────────────
    // Bopomofo 注音符號 — phonetic script used in Taiwan
    if (code >= 0x3100 && code <= 0x312F) return true;
    // Bopomofo Extended
    if (code >= 0x31A0 && code <= 0x31BF) return true;

    // ── Fullwidth / Halfwidth forms (all CJK) ─────────────────────────────
    if (code >= 0xFF00 && code <= 0xFFEF) return true;

    // ── Korean ────────────────────────────────────────────────────────────
    // Hangul Syllables — all modern precomposed Korean syllable blocks
    if (code >= 0xAC00 && code <= 0xD7A3) return true;
    // Hangul Jamo — base consonant/vowel components
    if (code >= 0x1100 && code <= 0x11FF) return true;
    // Hangul Compatibility Jamo — used by Korean fonts and keyboards
    if (code >= 0x3130 && code <= 0x318F) return true;
    // Hangul Jamo Extended-A (rare archaic letters)
    if (code >= 0xA960 && code <= 0xA97F) return true;
    // Hangul Jamo Extended-B (rare archaic letters)
    if (code >= 0xD7B0 && code <= 0xD7FF) return true;

    return false;
  }

  /// Check if a character is a CJK character.
  ///
  /// Accepts a single-character [String]. Prefer [isCjkCodeUnit] in tight
  /// loops to avoid the `text[i]` String allocation.
  static bool isCjkCharacter(String char) {
    if (char.isEmpty) return false;
    return isCjkCodeUnit(char.codeUnitAt(0));
  }

  /// Check if text contains any CJK characters.
  ///
  /// Uses [codeUnitAt] directly to avoid allocating a String per character
  /// (Dart's `text[i]` operator creates a new single-char String each call).
  static bool containsCjk(String text) {
    for (int i = 0; i < text.length; i++) {
      if (isCjkCodeUnit(text.codeUnitAt(i))) return true;
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
