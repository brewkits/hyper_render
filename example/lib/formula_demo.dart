import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

// =============================================================================
// FormulaWidget Demo
//
// Demonstrates LaTeX/math rendering via FormulaWidget:
//   • Basic Unicode substitution (built-in renderer)
//   • Greek letters and math symbols
//   • Physics and chemistry formulas
//   • Quill Delta integration with formula embeds
//   • Custom FormulaBuilder hook (flutter_math_fork pattern)
// =============================================================================

class FormulaDemo extends StatefulWidget {
  const FormulaDemo({super.key});

  @override
  State<FormulaDemo> createState() => _FormulaDemoState();
}

class _FormulaDemoState extends State<FormulaDemo>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FormulaWidget — LaTeX Rendering'),
        backgroundColor: DemoColors.secondary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.calculate, size: 16), text: 'Formulas'),
            Tab(icon: Icon(Icons.science, size: 16), text: 'Physics'),
            Tab(icon: Icon(Icons.insert_drive_file, size: 16), text: 'Delta'),
            Tab(icon: Icon(Icons.extension, size: 16), text: 'Custom Builder'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FormulasTab(),
          _PhysicsTab(),
          _DeltaTab(),
          _CustomBuilderTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Basic formulas: Greek letters, symbols, fractions, roots
// ─────────────────────────────────────────────────────────────────────────────

class _FormulasTab extends StatelessWidget {
  const _FormulasTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Greek Letters', color: DemoColors.secondary),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FormulaChip(r'\alpha'),
              _FormulaChip(r'\beta'),
              _FormulaChip(r'\gamma'),
              _FormulaChip(r'\delta'),
              _FormulaChip(r'\epsilon'),
              _FormulaChip(r'\theta'),
              _FormulaChip(r'\lambda'),
              _FormulaChip(r'\mu'),
              _FormulaChip(r'\pi'),
              _FormulaChip(r'\sigma'),
              _FormulaChip(r'\phi'),
              _FormulaChip(r'\omega'),
              _FormulaChip(r'\Gamma'),
              _FormulaChip(r'\Delta'),
              _FormulaChip(r'\Sigma'),
              _FormulaChip(r'\Omega'),
            ],
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Math Symbols', color: DemoColors.secondary),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FormulaChip(r'\sum'),
              _FormulaChip(r'\prod'),
              _FormulaChip(r'\int'),
              _FormulaChip(r'\infty'),
              _FormulaChip(r'\partial'),
              _FormulaChip(r'\nabla'),
              _FormulaChip(r'\pm'),
              _FormulaChip(r'\times'),
              _FormulaChip(r'\div'),
              _FormulaChip(r'\leq'),
              _FormulaChip(r'\geq'),
              _FormulaChip(r'\neq'),
              _FormulaChip(r'\approx'),
              _FormulaChip(r'\equiv'),
              _FormulaChip(r'\in'),
              _FormulaChip(r'\forall'),
              _FormulaChip(r'\exists'),
            ],
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Fractions & Roots', color: DemoColors.secondary),
          _FormulaRow(label: 'Simple fraction:', latex: r'\frac{a}{b}'),
          _FormulaRow(label: 'Square root:', latex: r'\sqrt{x^2 + y^2}'),
          _FormulaRow(label: 'Nested fraction:', latex: r'\frac{\alpha + \beta}{\gamma}'),
          _FormulaRow(label: 'Euler\'s identity:', latex: r'e^{i\pi} + 1 = 0'),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Superscripts & Subscripts', color: DemoColors.secondary),
          _FormulaRow(label: 'Area:', latex: r'A = \pi r^2'),
          _FormulaRow(label: 'Series:', latex: r'x_1 + x_2 + ... + x_n'),
          _FormulaRow(label: 'CO₂:', latex: r'CO_2'),
          _FormulaRow(label: 'Power:', latex: r'2^{10} = 1024'),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Dart API', color: DemoColors.secondary),
          _CodeSnippet(code: '''// Basic usage — built-in Unicode renderer
FormulaWidget(
  formula: r'E = mc^2',
)

// With custom text style
FormulaWidget(
  formula: r'\\frac{\\alpha + \\beta}{\\gamma}',
  style: TextStyle(fontSize: 18, color: Colors.deepPurple),
)'''),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Physics & chemistry formulas
// ─────────────────────────────────────────────────────────────────────────────

class _PhysicsTab extends StatelessWidget {
  const _PhysicsTab();

  static const _formulas = [
    (
      label: 'Einstein — Mass-Energy',
      latex: r'E = mc^2',
      desc: 'Energy equals mass times speed of light squared',
    ),
    (
      label: 'Newton — 2nd Law',
      latex: r'F = ma',
      desc: 'Force equals mass times acceleration',
    ),
    (
      label: 'Pythagorean Theorem',
      latex: r'c^2 = a^2 + b^2',
      desc: 'Squares of the legs equal the square of the hypotenuse',
    ),
    (
      label: 'Quadratic Formula',
      latex: r'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}',
      desc: 'Roots of ax² + bx + c = 0',
    ),
    (
      label: 'Euler\'s Identity',
      latex: r'e^{i\pi} + 1 = 0',
      desc: 'Connects five fundamental mathematical constants',
    ),
    (
      label: 'Gaussian Integral',
      latex: r'\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}',
      desc: 'Area under the bell curve equals √π',
    ),
    (
      label: 'Maxwell — Gauss\'s Law',
      latex: r'\nabla \cdot E = \frac{\rho}{\epsilon_0}',
      desc: 'Electric field divergence equals charge density over ε₀',
    ),
    (
      label: 'Schrödinger Equation',
      latex: r'i\hbar \frac{\partial}{\partial t}\Psi = \hat{H}\Psi',
      desc: 'Describes quantum state evolution over time',
    ),
    (
      label: 'Water molecule',
      latex: r'H_2O',
      desc: 'Two hydrogen atoms, one oxygen atom',
    ),
    (
      label: 'Carbon dioxide',
      latex: r'CO_2',
      desc: 'One carbon, two oxygen atoms',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _formulas.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final f = _formulas[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f.desc,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FormulaWidget(
                formula: f.latex,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Quill Delta integration
// ─────────────────────────────────────────────────────────────────────────────

class _DeltaTab extends StatelessWidget {
  const _DeltaTab();

  // Simulates rendering a Quill Delta document that contains formula embeds
  static const _deltaJson = '''
{
  "ops": [
    {"insert": "Physics Formulas\\n", "attributes": {"header": 1}},
    {"insert": "The energy-mass equivalence "},
    {"insert": {"formula": "E = mc^2"}},
    {"insert": " was derived by Einstein in 1905.\\n"},
    {"insert": "\\n"},
    {"insert": "The quadratic formula "},
    {"insert": {"formula": "x = \\\\frac{-b \\\\pm \\\\sqrt{b^2 - 4ac}}{2a"}},
    {"insert": " solves any quadratic equation.\\n"},
    {"insert": "\\n"},
    {"insert": "Euler's identity "},
    {"insert": {"formula": "e^{i\\\\pi} + 1 = 0"}},
    {"insert": " is often called the most beautiful equation.\\n"},
    {"insert": "\\n"},
    {"insert": "Set membership is written as "},
    {"insert": {"formula": "x \\\\in S"}},
    {"insert": " and for all is "},
    {"insert": {"formula": "\\\\forall x \\\\in \\\\mathbb{R}"}},
    {"insert": ".\\n"}
  ]
}
''';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Quill Delta with Formula Embeds',
              color: Colors.indigo),
          const Text(
            'HyperViewer renders Quill Delta JSON with inline formula embeds. '
            'Each {"formula": "..."} embed is rendered via FormulaWidget.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: HyperViewer.delta(
              delta: _deltaJson,
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Delta JSON Format', color: Colors.indigo),
          _CodeSnippet(code: r'''final deltaJson = '{'
  '"ops": ['
  '  {"insert": "The energy formula "},'
  '  {"insert": {"formula": "E = mc^2"}},'
  '  {"insert": " was derived by Einstein.\n"}'
  ']'
'}';

HyperViewer.delta(delta: deltaJson)'''),
          const SizedBox(height: 20),
          _SectionHeader(
              title: 'FormulaParser Extension', color: Colors.indigo),
          const Text(
            'Use the FormulaParser extension to check Quill embed maps:',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          _CodeSnippet(code: r'''// Check if a Quill Delta embed is a formula
final embed = {"formula": "E = mc^2"};
print(embed.isFormula);      // true
print(embed.formulaString);  // "E = mc^2"

final info = embed.formulaInfo;  // FormulaInfo
print(info?.formula);     // "E = mc^2"
print(info?.displayMode); // false (inline)'''),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4 — Custom FormulaBuilder (flutter_math_fork pattern)
// ─────────────────────────────────────────────────────────────────────────────

class _CustomBuilderTab extends StatefulWidget {
  const _CustomBuilderTab();

  @override
  State<_CustomBuilderTab> createState() => _CustomBuilderTabState();
}

class _CustomBuilderTabState extends State<_CustomBuilderTab> {
  bool _useCustomBuilder = false;

  // Simulates what flutter_math_fork would render — uses styled Text for demo
  Widget _mockFlutterMathBuilder(BuildContext context, String formula) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '[flutter_math: $formula]',
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formulas = [
      r'E = mc^2',
      r'\frac{-b \pm \sqrt{b^2-4ac}}{2a}',
      r'\int_{0}^{\infty} e^{-x} dx = 1',
      r'\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}',
      r'\nabla \times B = \mu_0 J + \mu_0\epsilon_0 \frac{\partial E}{\partial t}',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Custom FormulaBuilder',
              color: DemoColors.warning),
          const Text(
            'Swap the built-in Unicode renderer for a full LaTeX engine '
            '(e.g. flutter_math_fork) by providing a customBuilder. '
            'Toggle below to compare renderers:',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          // Toggle switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DemoColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: DemoColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.swap_horiz,
                    color: DemoColors.warning, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Renderer:',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                Text(
                  _useCustomBuilder
                      ? 'flutter_math_fork (mock)'
                      : 'Built-in Unicode',
                  style: TextStyle(
                    fontSize: 12,
                    color: _useCustomBuilder
                        ? Colors.indigo
                        : Colors.teal.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value: _useCustomBuilder,
                  onChanged: (v) => setState(() => _useCustomBuilder = v),
                  activeThumbColor: Colors.indigo,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...formulas.map((latex) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latex,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 4),
                    FormulaWidget(
                      formula: latex,
                      style: const TextStyle(fontSize: 16),
                      customBuilder: _useCustomBuilder
                          ? _mockFlutterMathBuilder
                          : null,
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          _SectionHeader(
              title: 'Integration with flutter_math_fork',
              color: DemoColors.warning),
          _CodeSnippet(code: r'''// pubspec.yaml
// dependencies:
//   flutter_math_fork: ^0.7.4

import 'package:flutter_math_fork/flutter_math.dart';

FormulaWidget(
  formula: r'\frac{-b \pm \sqrt{b^2-4ac}}{2a}',
  customBuilder: (context, formula) {
    return Math.tex(
      formula,
      textStyle: const TextStyle(fontSize: 18),
      onErrorFallback: (err) => Text(
        formula,  // graceful fallback
        style: const TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  },
)'''),
          const SizedBox(height: 16),
          _SectionHeader(
              title: 'Global customBuilder via HyperViewer',
              color: DemoColors.warning),
          _CodeSnippet(code: r'''// Apply flutter_math_fork to ALL formulas in a document
HyperViewer(
  html: myDeltaJson,
  format: HyperRenderFormat.delta,
  widgetBuilder: (context, node) {
    if (node is AtomicNode && node.tagName == 'formula') {
      final formula = node.attributes['data'] ?? '';
      return Math.tex(formula,
        textStyle: const TextStyle(fontSize: 16));
    }
    return null; // fall through to default
  },
)'''),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _FormulaChip extends StatelessWidget {
  final String latex;
  const _FormulaChip(this.latex);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FormulaWidget(formula: latex),
        const SizedBox(height: 2),
        Text(
          latex,
          style: TextStyle(
              fontSize: 9, color: Colors.grey.shade500, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}

class _FormulaRow extends StatelessWidget {
  final String label;
  final String latex;
  const _FormulaRow({required this.label, required this.latex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ),
          FormulaWidget(formula: latex, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
              width: 3,
              height: 18,
              color: color,
              margin: const EdgeInsets.only(right: 8)),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeSnippet extends StatelessWidget {
  final String code;
  const _CodeSnippet({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Color(0xFFCDD6F4),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
