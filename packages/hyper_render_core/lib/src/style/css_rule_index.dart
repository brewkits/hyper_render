import '../interfaces/css_parser.dart';
import '../model/node.dart';

/// CSS Rule Index for O(1) rule lookup by selector type
///
/// Indexes CSS rules by their most specific selector component:
/// - Tag selectors: div, p, h1
/// - Class selectors: .button, .card
/// - ID selectors: #header, #footer
/// - Universal selectors: *, complex selectors
///
/// This reduces CSS matching from O(n×m) to O(n×k) where k << m
/// (k = relevant rules for a node, m = total rules)
///
/// Performance improvement: ~10x faster with 500+ rules
class CssRuleIndex {
  /// Global CSS Parser instance (provided by hyper_render_html)
  static CssParserInterface? parser;

  /// Add a raw CSS stylesheet to the index
  void addStyleSheet(String css) {
    if (parser == null) return;
    final rules = parser!.parseStylesheet(css);
    for (final rule in rules) {
      addRule(rule);
    }
  }

  /// Rules indexed by tag name (e.g., "div", "p", "h1")
  final Map<String, List<ParsedCssRule>> _byTag = {};

  /// Rules indexed by class name (e.g., ".button", ".card")
  final Map<String, List<ParsedCssRule>> _byClass = {};

  /// Rules indexed by ID (e.g., "#header", "#footer")
  final Map<String, List<ParsedCssRule>> _byId = {};

  /// Universal and complex selectors that must be checked for all nodes
  final List<ParsedCssRule> _universal = [];

  /// Total number of indexed rules
  int get totalRules =>
      _byTag.values.fold<int>(0, (sum, list) => sum + list.length) +
      _byClass.values.fold<int>(0, (sum, list) => sum + list.length) +
      _byId.values.fold<int>(0, (sum, list) => sum + list.length) +
      _universal.length;

  /// Add a CSS rule to the index
  ///
  /// Analyzes the selector and indexes it by the most specific component
  void addRule(ParsedCssRule rule) {
    final selector = rule.selector.trim();

    // Determine index category based on selector pattern
    final indexKey = _analyzeSelector(selector);

    switch (indexKey.type) {
      case _SelectorType.id:
        _byId.putIfAbsent(indexKey.value, () => []).add(rule);
        break;

      case _SelectorType.classSelector:
        _byClass.putIfAbsent(indexKey.value, () => []).add(rule);
        break;

      case _SelectorType.tag:
        _byTag.putIfAbsent(indexKey.value, () => []).add(rule);
        break;

      case _SelectorType.universal:
        _universal.add(rule);
        break;
    }

  }

  /// Get candidate rules that might match a node
  ///
  /// Returns only rules that could possibly match based on:
  /// - Node's tag name
  /// - Node's classes
  /// - Node's ID
  /// - Universal selectors
  ///
  /// This drastically reduces the number of rules to check
  List<ParsedCssRule> getCandidates(UDTNode node) {
    final candidates = <ParsedCssRule>[];

    // 1. Add tag-based rules (e.g., div, p, h1)
    final tagName = node.tagName?.toLowerCase();
    if (tagName != null) {
      candidates.addAll(_byTag[tagName] ?? []);
    }

    // 2. Add class-based rules (e.g., .button, .card)
    for (final className in node.classList) {
      candidates.addAll(_byClass['.$className'] ?? []);
    }

    // 3. Add ID-based rules (e.g., #header)
    final nodeId = node.cssId;
    if (nodeId != null) {
      candidates.addAll(_byId['#$nodeId'] ?? []);
    }

    // 4. Add universal selectors (must check these for all nodes)
    candidates.addAll(_universal);

    return candidates;
  }

  /// Clear all indexed rules
  void clear() {
    _byTag.clear();
    _byClass.clear();
    _byId.clear();
    _universal.clear();
  }

  /// Get statistics about the index (for debugging/optimization)
  CssIndexStats getStats() {
    return CssIndexStats(
      tagRules: _byTag.length,
      classRules: _byClass.length,
      idRules: _byId.length,
      universalRules: _universal.length,
      totalRules: totalRules,
      averageRulesPerTag:
          _byTag.isEmpty ? 0 : _byTag.values.map((l) => l.length).reduce((a, b) => a + b) / _byTag.length,
    );
  }

  /// Analyze a selector to determine the best index key
  ///
  /// **Important**: Complex selectors (those containing descendant/child/sibling
  /// combinators — space, `>`, `+`, `~`) are routed to the `_universal` bucket
  /// regardless of whether they contain a `#` or `.`.
  ///
  /// Rationale: The index must be keyed by the *subject* (rightmost) component
  /// of the selector. For a rule like `nav.menu li`, the subject is `li`, not
  /// `.menu`. Detecting the rightmost component without a full selector parser
  /// is error-prone, so any selector with a combinator is placed in `_universal`
  /// and filtered by `_matchesSelector()` at call time — which is correct,
  /// though slightly less efficient than precise bucket placement.
  _SelectorIndexKey _analyzeSelector(String selector) {
    final trimmed = selector.trim();

    // ── Complex selectors with combinators → universal bucket ─────────────────
    // Must check BEFORE `.` / `#` tests because `nav.menu li` contains `.` but
    // its subject is `li`, not `.menu`. Indexing by `.menu` would cause the rule
    // to be missed when `li` elements are matched.
    final hasDescendant = trimmed.contains(' ');
    final hasChild = trimmed.contains('>');
    final hasSibling = trimmed.contains('+') || trimmed.contains('~');
    if (hasDescendant || hasChild || hasSibling) {
      return _SelectorIndexKey(_SelectorType.universal, trimmed);
    }

    // ── Simple / compound selectors only below this line ──────────────────────

    // ID selector (highest specificity), no combinators
    // Examples: #header, #footer, div#main, a#nav-link
    if (trimmed.contains('#')) {
      final match = RegExp(r'#([\w-]+)').firstMatch(trimmed);
      if (match != null) {
        return _SelectorIndexKey(_SelectorType.id, '#${match.group(1)}');
      }
    }

    // Class selector, no combinators
    // Examples: .button, .card, div.container, p.lead
    if (trimmed.contains('.')) {
      final match = RegExp(r'\.([\w-]+)').firstMatch(trimmed);
      if (match != null) {
        return _SelectorIndexKey(_SelectorType.classSelector, '.${match.group(1)}');
      }
    }

    // Simple tag selector (no combinators, no class/id/attr)
    // Examples: div, p, h1, span
    if (trimmed.isNotEmpty &&
        !trimmed.contains('.') &&
        !trimmed.contains('#') &&
        !trimmed.contains('[') &&
        trimmed != '*') {
      return _SelectorIndexKey(_SelectorType.tag, trimmed.toLowerCase());
    }

    // Compound tag+attribute/pseudo-class but no combinators
    // Examples: div[attr], p:first-child, a:hover, input[type="text"]
    final tagMatch = RegExp(r'^([\w-]+)').firstMatch(trimmed);
    if (tagMatch != null && tagMatch.group(1) != '*') {
      return _SelectorIndexKey(_SelectorType.tag, tagMatch.group(1)!.toLowerCase());
    }

    // Universal or attribute-only selectors: *, [lang], :root
    return _SelectorIndexKey(_SelectorType.universal, trimmed);
  }
}

/// Selector type for indexing
enum _SelectorType {
  id,           // #id
  classSelector, // .class
  tag,          // div, p, h1
  universal,    // *, complex selectors
}

/// Key for indexing a selector
class _SelectorIndexKey {
  final _SelectorType type;
  final String value;

  _SelectorIndexKey(this.type, this.value);
}

/// Statistics about CSS rule indexing
class CssIndexStats {
  final int tagRules;
  final int classRules;
  final int idRules;
  final int universalRules;
  final int totalRules;
  final double averageRulesPerTag;

  CssIndexStats({
    required this.tagRules,
    required this.classRules,
    required this.idRules,
    required this.universalRules,
    required this.totalRules,
    required this.averageRulesPerTag,
  });

  @override
  String toString() {
    return '''
CSS Index Statistics:
  Tag rules: $tagRules
  Class rules: $classRules
  ID rules: $idRules
  Universal rules: $universalRules
  Total rules: $totalRules
  Avg rules per tag: ${averageRulesPerTag.toStringAsFixed(1)}
''';
  }
}
