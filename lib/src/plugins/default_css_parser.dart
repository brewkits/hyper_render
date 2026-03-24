import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:csslib/parser.dart' as css_parser;
import 'package:csslib/visitor.dart' as css_ast;

/// Default CSS parser using csslib package
///
/// Provides full CSS stylesheet parsing with specificity calculation.
/// This is the default implementation provided by HyperRender.
class DefaultCssParser implements CssParserInterface {
  const DefaultCssParser();

  @override
  List<ParsedCssRule> parseStylesheet(String css) {
    if (css.isEmpty) return const [];

    try {
      final stylesheet = css_parser.parse(css);
      return _extractRules(stylesheet);
    } catch (e, st) {
      // Log CSS parsing error but don't throw
      // Return empty list for invalid CSS
      assert(() {
        debugPrint('[HyperRender] CSS parse error: $e\n$st');
        return true;
      }());
      return const [];
    }
  }

  List<ParsedCssRule> _extractRules(css_ast.StyleSheet stylesheet) {
    final rules = <ParsedCssRule>[];

    for (final topLevel in stylesheet.topLevels) {
      if (topLevel is css_ast.RuleSet) {
        final rule = _convertRuleSet(topLevel);
        if (rule != null) {
          rules.add(rule);
        }
      }
    }

    // Sort rules by specificity (lower first, so higher specificity wins)
    rules.sort((a, b) => a.specificity.compareTo(b.specificity));
    return rules;
  }

  ParsedCssRule? _convertRuleSet(css_ast.RuleSet ruleSet) {
    // Extract selector text
    final selector = _extractSelector(ruleSet.selectorGroup);
    if (selector.isEmpty) return null;

    // Extract declarations
    final declarations = <String, String>{};
    for (final declaration in ruleSet.declarationGroup.declarations) {
      if (declaration is css_ast.Declaration) {
        final property = declaration.property;
        final value = _extractValue(declaration.expression);
        if (property.isNotEmpty && value.isNotEmpty) {
          declarations[property] = value;
        }
      }
    }

    if (declarations.isEmpty) return null;

    return ParsedCssRule(
      selector: selector,
      declarations: declarations,
      specificity: _calculateSpecificity(selector),
    );
  }

  String _extractSelector(css_ast.SelectorGroup? selectorGroup) {
    if (selectorGroup == null) return '';
    return selectorGroup.selectors.map((s) => s.span?.text ?? '').join(', ');
  }

  String _extractValue(css_ast.Expression? expression) {
    if (expression == null) return '';
    return expression.span?.text ?? '';
  }

  /// Calculate CSS specificity for a selector
  /// Returns a single int encoding [inline, id, class, element] weight
  int _calculateSpecificity(String selector) {
    int ids = 0;
    int classes = 0;
    int elements = 0;

    // Count IDs (#id)
    ids = RegExp(r'#[a-zA-Z_-][\w-]*').allMatches(selector).length;

    // Count classes (.class), attributes ([attr]), and pseudo-classes (:hover)
    classes = RegExp(r'\.[a-zA-Z_-][\w-]*').allMatches(selector).length;
    classes += RegExp(r'\[[^\]]+\]').allMatches(selector).length;
    classes += RegExp(r':[a-zA-Z_-][\w-]*(?!\()').allMatches(selector).length;

    // Count elements (tag names) and pseudo-elements (::before)
    // This is simplified - doesn't handle all edge cases
    elements = RegExp(r'(?:^|\s|>|\+|~)([a-zA-Z][a-zA-Z0-9]*)')
        .allMatches(selector)
        .length;
    elements += RegExp(r'::[a-zA-Z_-][\w-]*').allMatches(selector).length;

    // Combine into single int: [0][ids][classes][elements]
    // Each segment can hold up to 255
    return (ids * 65536) + (classes * 256) + elements;
  }

  // ── @keyframes parsing ────────────────────────────────────────────────────

  @override
  Map<String, HyperKeyframes> parseKeyframes(String css) {
    if (css.isEmpty) return const {};

    final result = <String, HyperKeyframes>{};
    int i = 0;

    // Regex matches @keyframes / @-webkit-keyframes / @-moz-keyframes, etc.
    final atRule = RegExp(
      r'@(?:-(?:webkit|moz|ms|o)-)?keyframes\s+([\w-]+)\s*\{',
      caseSensitive: false,
    );

    while (i < css.length) {
      final match = atRule.firstMatch(css.substring(i));
      if (match == null) break;

      final animName = match.group(1)!;
      final bodyStart = i + match.end;

      // Brace-depth scan to find matching closing brace.
      int depth = 1;
      int j = bodyStart;
      while (j < css.length && depth > 0) {
        if (css[j] == '{') depth++;
        if (css[j] == '}') depth--;
        j++;
      }

      if (depth == 0) {
        final body = css.substring(bodyStart, j - 1);
        final kf = _parseKeyframeBody(animName, body);
        if (kf != null) result[animName] = kf;
        // Advance past the entire @keyframes block.
        i = j;
      } else {
        // Malformed CSS — skip just past the @ so we don't loop forever.
        i += match.start + 1;
      }
    }

    return result;
  }

  HyperKeyframes? _parseKeyframeBody(String name, String body) {
    final keyframes = <HyperKeyframe>[];

    // Match "from { ... }", "to { ... }", "0% { ... }", "0%, 100% { ... }".
    // Declarations must not contain nested braces (valid @keyframes CSS).
    final blockPat = RegExp(
      r'((?:(?:from|to|\d+(?:\.\d+)?%)\s*,?\s*)+)\{([^}]*)\}',
      caseSensitive: false,
    );

    for (final m in blockPat.allMatches(body)) {
      final selectors = m.group(1)!;
      final decls = _parseKfDeclarations(m.group(2)!);

      for (final raw in selectors.split(',')) {
        final offset = _kfSelectorToOffset(raw.trim());
        if (offset != null) {
          keyframes.add(_kfDeclarationsToKeyframe(offset, decls));
        }
      }
    }

    if (keyframes.isEmpty) return null;

    keyframes.sort((a, b) => a.offset.compareTo(b.offset));
    return HyperKeyframes(name: name, keyframes: keyframes);
  }

  double? _kfSelectorToOffset(String sel) {
    final s = sel.toLowerCase();
    if (s == 'from') return 0.0;
    if (s == 'to') return 1.0;
    final m = RegExp(r'^(\d+(?:\.\d+)?)%$').firstMatch(s);
    if (m != null) return (double.tryParse(m.group(1)!) ?? 0) / 100.0;
    return null;
  }

  Map<String, String> _parseKfDeclarations(String decls) {
    final result = <String, String>{};
    for (final decl in decls.split(';')) {
      final colon = decl.indexOf(':');
      if (colon > 0) {
        final prop = decl.substring(0, colon).trim().toLowerCase();
        final val = decl.substring(colon + 1).trim();
        if (prop.isNotEmpty && val.isNotEmpty) result[prop] = val;
      }
    }
    return result;
  }

  HyperKeyframe _kfDeclarationsToKeyframe(
      double offset, Map<String, String> decls) {
    double? opacity;
    double? translateX;
    double? translateY;
    double? scale;
    double? rotation;

    if (decls.containsKey('opacity')) {
      opacity = double.tryParse(decls['opacity']!);
    }

    final transform = decls['transform'];
    if (transform != null) {
      // translateX(...)
      final txM =
          RegExp(r'translateX\(\s*(-?[\d.]+)(?:px|%|rem|em|vw|vh)?\s*\)')
              .firstMatch(transform);
      if (txM != null) translateX = double.tryParse(txM.group(1)!);

      // translateY(...)
      final tyM =
          RegExp(r'translateY\(\s*(-?[\d.]+)(?:px|%|rem|em|vw|vh)?\s*\)')
              .firstMatch(transform);
      if (tyM != null) translateY = double.tryParse(tyM.group(1)!);

      // translate(x, y)  — only when not preceded by X or Y
      final tM = RegExp(
        r'(?<![XY])translate\(\s*(-?[\d.]+)(?:px)?\s*(?:,\s*(-?[\d.]+)(?:px)?)?\s*\)',
      ).firstMatch(transform);
      if (tM != null) {
        translateX ??= double.tryParse(tM.group(1)!);
        if (tM.group(2) != null) translateY ??= double.tryParse(tM.group(2)!);
      }

      // scale(...)
      final scaleM =
          RegExp(r'(?<![XY])scale\(\s*([\d.]+)\s*\)').firstMatch(transform);
      if (scaleM != null) scale = double.tryParse(scaleM.group(1)!);

      // rotate(Ndeg)
      final rotM =
          RegExp(r'rotate\(\s*(-?[\d.]+)deg\s*\)').firstMatch(transform);
      if (rotM != null) rotation = double.tryParse(rotM.group(1)!);
    }

    return HyperKeyframe(
      offset: offset,
      opacity: opacity,
      translateX: translateX,
      translateY: translateY,
      scale: scale,
      rotation: rotation,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Map<String, String> parseInlineStyle(String style) {
    final result = <String, String>{};
    if (style.isEmpty) return result;

    final declarations = style.split(';');
    for (final decl in declarations) {
      final colonIndex = decl.indexOf(':');
      if (colonIndex > 0) {
        final property = decl.substring(0, colonIndex).trim();
        final value = decl.substring(colonIndex + 1).trim();
        if (property.isNotEmpty && value.isNotEmpty) {
          result[property] = value;
        }
      }
    }
    return result;
  }
}
