import 'package:flutter/material.dart';

/// LaTeX formula rendering support
///
/// This provides basic formula rendering for Quill Delta embeds.
/// For production use, consider using flutter_math_fork for full LaTeX support.
///
/// ## Supported Features (Basic)
///
/// - Superscript: `x^2`
/// - Subscript: `x_1`
/// - Fractions: `\frac{a}{b}`
/// - Greek letters: `\alpha`, `\beta`, etc.
/// - Common symbols: `\sum`, `\int`, `\sqrt`
///
/// ## Usage with Quill Delta
///
/// ```json
/// {
///   "ops": [
///     { "insert": { "formula": "E = mc^2" } }
///   ]
/// }
/// ```

/// Callback for custom formula rendering
typedef FormulaBuilder = Widget Function(
  BuildContext context,
  String formula,
);

/// Default formula widget using basic text rendering
///
/// This is a fallback renderer that displays formulas using
/// Unicode math symbols. For full LaTeX support, provide a
/// custom FormulaBuilder using flutter_math_fork.
class FormulaWidget extends StatelessWidget {
  /// The LaTeX formula string
  final String formula;

  /// Text style for the formula
  final TextStyle? style;

  /// Custom formula builder (e.g., using flutter_math_fork)
  final FormulaBuilder? customBuilder;

  const FormulaWidget({
    super.key,
    required this.formula,
    this.style,
    this.customBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Use custom builder if provided
    if (customBuilder != null) {
      return customBuilder!(context, formula);
    }

    // Use basic Unicode rendering
    return _buildBasicFormula(context);
  }

  Widget _buildBasicFormula(BuildContext context) {
    final textStyle = style ??
        DefaultTextStyle.of(context).style.copyWith(
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
            );

    // Convert basic LaTeX to Unicode
    final converted = _convertToUnicode(formula);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        converted,
        style: textStyle,
      ),
    );
  }

  /// Convert basic LaTeX to Unicode text
  String _convertToUnicode(String latex) {
    var result = latex;

    // Greek letters
    result = result
        .replaceAll(r'\alpha', 'α')
        .replaceAll(r'\beta', 'β')
        .replaceAll(r'\gamma', 'γ')
        .replaceAll(r'\delta', 'δ')
        .replaceAll(r'\epsilon', 'ε')
        .replaceAll(r'\zeta', 'ζ')
        .replaceAll(r'\eta', 'η')
        .replaceAll(r'\theta', 'θ')
        .replaceAll(r'\iota', 'ι')
        .replaceAll(r'\kappa', 'κ')
        .replaceAll(r'\lambda', 'λ')
        .replaceAll(r'\mu', 'μ')
        .replaceAll(r'\nu', 'ν')
        .replaceAll(r'\xi', 'ξ')
        .replaceAll(r'\pi', 'π')
        .replaceAll(r'\rho', 'ρ')
        .replaceAll(r'\sigma', 'σ')
        .replaceAll(r'\tau', 'τ')
        .replaceAll(r'\upsilon', 'υ')
        .replaceAll(r'\phi', 'φ')
        .replaceAll(r'\chi', 'χ')
        .replaceAll(r'\psi', 'ψ')
        .replaceAll(r'\omega', 'ω');

    // Capital Greek letters
    result = result
        .replaceAll(r'\Gamma', 'Γ')
        .replaceAll(r'\Delta', 'Δ')
        .replaceAll(r'\Theta', 'Θ')
        .replaceAll(r'\Lambda', 'Λ')
        .replaceAll(r'\Xi', 'Ξ')
        .replaceAll(r'\Pi', 'Π')
        .replaceAll(r'\Sigma', 'Σ')
        .replaceAll(r'\Phi', 'Φ')
        .replaceAll(r'\Psi', 'Ψ')
        .replaceAll(r'\Omega', 'Ω');

    // Math symbols
    result = result
        .replaceAll(r'\sum', '∑')
        .replaceAll(r'\prod', '∏')
        .replaceAll(r'\int', '∫')
        .replaceAll(r'\oint', '∮')
        .replaceAll(r'\infty', '∞')
        .replaceAll(r'\partial', '∂')
        .replaceAll(r'\nabla', '∇')
        .replaceAll(r'\pm', '±')
        .replaceAll(r'\mp', '∓')
        .replaceAll(r'\times', '×')
        .replaceAll(r'\div', '÷')
        .replaceAll(r'\cdot', '·')
        .replaceAll(r'\leq', '≤')
        .replaceAll(r'\geq', '≥')
        .replaceAll(r'\neq', '≠')
        .replaceAll(r'\approx', '≈')
        .replaceAll(r'\equiv', '≡')
        .replaceAll(r'\subset', '⊂')
        .replaceAll(r'\supset', '⊃')
        .replaceAll(r'\subseteq', '⊆')
        .replaceAll(r'\supseteq', '⊇')
        .replaceAll(r'\in', '∈')
        .replaceAll(r'\notin', '∉')
        .replaceAll(r'\cup', '∪')
        .replaceAll(r'\cap', '∩')
        .replaceAll(r'\emptyset', '∅')
        .replaceAll(r'\forall', '∀')
        .replaceAll(r'\exists', '∃')
        .replaceAll(r'\neg', '¬')
        .replaceAll(r'\land', '∧')
        .replaceAll(r'\lor', '∨')
        .replaceAll(r'\to', '→')
        .replaceAll(r'\rightarrow', '→')
        .replaceAll(r'\leftarrow', '←')
        .replaceAll(r'\leftrightarrow', '↔')
        .replaceAll(r'\Rightarrow', '⇒')
        .replaceAll(r'\Leftarrow', '⇐')
        .replaceAll(r'\Leftrightarrow', '⇔');

    // Handle fractions: \frac{a}{b} -> a/b
    final fracRegex = RegExp(r'\\frac\{([^}]*)\}\{([^}]*)\}');
    result = result.replaceAllMapped(fracRegex, (match) {
      return '${match.group(1)}/${match.group(2)}';
    });

    // Handle sqrt: \sqrt{x} -> √x
    final sqrtRegex = RegExp(r'\\sqrt\{([^}]*)\}');
    result = result.replaceAllMapped(sqrtRegex, (match) {
      return '√(${match.group(1)})';
    });

    // Handle superscripts: x^2 -> x²
    result = result
        .replaceAll('^0', '⁰')
        .replaceAll('^1', '¹')
        .replaceAll('^2', '²')
        .replaceAll('^3', '³')
        .replaceAll('^4', '⁴')
        .replaceAll('^5', '⁵')
        .replaceAll('^6', '⁶')
        .replaceAll('^7', '⁷')
        .replaceAll('^8', '⁸')
        .replaceAll('^9', '⁹')
        .replaceAll('^n', 'ⁿ')
        .replaceAll('^i', 'ⁱ');

    // Handle subscripts: x_1 -> x₁
    result = result
        .replaceAll('_0', '₀')
        .replaceAll('_1', '₁')
        .replaceAll('_2', '₂')
        .replaceAll('_3', '₃')
        .replaceAll('_4', '₄')
        .replaceAll('_5', '₅')
        .replaceAll('_6', '₆')
        .replaceAll('_7', '₇')
        .replaceAll('_8', '₈')
        .replaceAll('_9', '₉')
        .replaceAll('_n', 'ₙ')
        .replaceAll('_i', 'ᵢ');

    // Clean up remaining braces
    result = result.replaceAll('{', '').replaceAll('}', '');

    return result;
  }
}

/// FormulaInfo for media-style handling
class FormulaInfo {
  /// The LaTeX formula string
  final String formula;

  /// Display mode (inline or block)
  final bool displayMode;

  const FormulaInfo({
    required this.formula,
    this.displayMode = false,
  });
}

/// Extension to parse formula from Quill Delta
extension FormulaParser on Map<String, dynamic> {
  /// Check if this embed is a formula
  bool get isFormula => containsKey('formula');

  /// Get formula string
  String? get formulaString => this['formula']?.toString();

  /// Get FormulaInfo
  FormulaInfo? get formulaInfo {
    final formula = formulaString;
    if (formula == null) return null;
    return FormulaInfo(formula: formula);
  }
}
