import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

class UltraShowcase2026 extends StatefulWidget {
  const UltraShowcase2026({super.key});

  @override
  State<UltraShowcase2026> createState() => _UltraShowcase2026State();
}

class _UltraShowcase2026State extends State<UltraShowcase2026> {
  int _viewMode = 0; // 0 = Scroll (Virtualized), 1 = Paged

  static const String editorialHtml = '''
<div style="font-family: serif; line-height: 1.8;">
  <h1 style="font-size: 32px; border-bottom: 2px solid #D32F2F; padding-bottom: 8px; margin-bottom: 24px; color: #B71C1C;">
    ハイパーレンダーの進化 (The Evolution of HyperRender)
  </h1>

  <img src="https://picsum.photos/400/400?random=1" style="float: left; width: 180px; height: 180px; border-radius: 8px; margin: 0 24px 16px 0; padding: 4px; background: white; border: 1px solid #e0e0e0; box-shadow: 0 4px 12px rgba(0,0,0,0.1);" />

  <p style="font-size: 18px;">
    <span style="font-size: 48px; line-height: 1; float: left; margin: 8px 12px 0 0; color: #D32F2F;">当</span>
    然のことながら、最新のレンダリングエンジンは、複雑なレイアウトを<ruby>完璧<rt>かんぺき</rt></ruby>に処理する必要があります。
    この記事では、Float、Ruby、およびインタラクティブな要素がどのように統合されているかをデモします。
    テキストは自然に画像の周りを回り込み、テキスト選択（Selection）もスムーズに機能します。
  </p>

  <p style="font-size: 18px;">
    We seamlessly mix <strong>English typography</strong> with CJK characters. The spacing and word-breaking (Kinsoku shori) 
    are handled meticulously. Try selecting text across this paragraph and the image float boundary—it just works.
  </p>

  <div style="clear: both; margin-bottom: 32px;"></div>

  <h2 style="color: #D81B60; border-left: 4px solid #D81B60; padding-left: 16px;">Selection Stress Test</h2>
  <p style="background: #FCE4EC; padding: 16px; border-radius: 8px; border: 1px dashed #F06292;">
    <strong>Try this:</strong> Long-press on the Japanese text above, then drag the selection handle down into this pink box. 
    HyperRender supports <em>Cross-Chunk Selection</em> even when content is virtualized!
  </p>

  <h2 style="color: #1976D2; border-left: 4px solid #1976D2; padding-left: 16px;">Interactive Physics (CSS + Widget)</h2>
  
  <div class="interactive-box" style="background: #F5F7FA; padding: 24px; border-radius: 12px; margin-bottom: 32px; border: 1px solid #CFD8DC;">
    <p style="margin-top: 0;"><strong>Quantum Mechanics Equation:</strong></p>
    <formula-widget equation="i\\hbar \\frac{\\partial}{\\partial t}\\Psi(r,t) = \\hat{H}\\Psi(r,t)"></formula-widget>
    <p style="font-size: 14px; color: #546E7A; margin-bottom: 0; margin-top: 16px;">
      Hover or interact with the formula above. This uses custom Flutter widgets injected into the HTML stream.
    </p>
  </div>
''';

  late String _fullHtml;

  @override
  void initState() {
    super.initState();
    _buildFullHtml();
  }

  void _buildFullHtml() {
    final buffer = StringBuffer();
    buffer.write(editorialHtml);

    // Library Comparison Matrix
    buffer.write('''
  <h2 style="color: #F57C00; border-left: 4px solid #F57C00; padding-left: 16px;">Library Comparison Matrix</h2>
  <p style="font-size: 16px;">
    Why choose <strong>HyperRender</strong> over other popular rendering solutions? The table below highlights the architectural and feature differences.
  </p>
  <table style="width: 100%; border-collapse: collapse; margin-bottom: 32px; font-family: sans-serif; font-size: 14px;">
    <thead>
      <tr style="background: #F57C00; color: white;">
        <th style="padding: 12px; border: 1px solid #E65100; text-align: left;">Feature / Library</th>
        <th style="padding: 12px; border: 1px solid #E65100; text-align: center;">HyperRender</th>
        <th style="padding: 12px; border: 1px solid #E65100; text-align: center;">flutter_html</th>
        <th style="padding: 12px; border: 1px solid #E65100; text-align: center;">flutter_widget_from_html</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="padding: 10px; border: 1px solid #FFE0B2; font-weight: bold;">Float Layout Engine</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #2E7D32; background: #FFF3E0;">✅ Full Support</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #C62828;">❌ None</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #C62828;">❌ None</td>
      </tr>
      <tr style="background: #FAFAFA;">
        <td style="padding: 10px; border: 1px solid #FFE0B2; font-weight: bold;">Ruby Annotation (CJK)</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #2E7D32; background: #FFF3E0;">✅ Full Support</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #C62828;">❌ Flat Text</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #C62828;">❌ Flat Text</td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #FFE0B2; font-weight: bold;">Text Selection</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #2E7D32; background: #FFF3E0;">✅ Seamless</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #F57F17;">⚠️ Box-by-Box</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #C62828;">❌ Crashes on complex HTML</td>
      </tr>
      <tr style="background: #FAFAFA;">
        <td style="padding: 10px; border: 1px solid #FFE0B2; font-weight: bold;">Widget Injection</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #2E7D32; background: #FFF3E0;">✅ Native (Any Widget)</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #555;">Via CustomRender</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #555;">Via Factory</td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #FFE0B2; font-weight: bold;">Large HTML Virtualization</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #2E7D32; background: #FFF3E0;">✅ Chunked (60fps)</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #F57F17;">⚠️ High Memory</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #C62828;">❌ Freezes UI</td>
      </tr>
      <tr style="background: #FAFAFA;">
        <td style="padding: 10px; border: 1px solid #FFE0B2; font-weight: bold;">Rendering Architecture</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #2E7D32; background: #FFF3E0;">Custom RenderObject</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #555;">Widget Tree Mapping</td>
        <td style="padding: 10px; border: 1px solid #FFE0B2; text-align: center; color: #555;">Widget Tree Mapping</td>
      </tr>
    </tbody>
  </table>
''');

    buffer.write('''
  <h2 style="color: #388E3C; border-left: 4px solid #388E3C; padding-left: 16px;">The "Giant Div" Virtualization</h2>
  <p>Below is a massive simulated block of text inside a single <code>&lt;div&gt;</code>. HyperRender chunks and virtualizes it so it runs at 60fps.</p>
''');

    // Simulate legacy HTML with one giant div and lots of text
    buffer.write(
        '<div style="font-size: 16px; color: #424242; text-align: justify;">');
    for (int i = 0; i < 50; i++) {
      buffer.write('''
        <p>
          [Section \${i + 1}] Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
          <ruby>仮想化<rt>かそうか</rt></ruby> allows us to render massive documents. 
          Nullam in dui mauris. Vivamus hendrerit arcu sed erat molestie vehicula. 
          Sed auctor neque eu tellus rhoncus ut eleifend nibh porttitor. 
          Ut in nulla enim. Phasellus molestie magna non est bibendum non venenatis nisl tempor.
          Suspendisse dictum feugiat nisl ut dapibus. Mauris iaculis porttitor posuere.
        </p>
      ''');
    }
    buffer.write('</div></div>');
    _fullHtml = buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ultra Showcase 2026',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_viewMode == 0 ? Icons.menu_book : Icons.view_stream),
            tooltip: _viewMode == 0
                ? 'Switch to Paged Mode'
                : 'Switch to Scroll Mode',
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == 0 ? 1 : 0;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFFAFAFA),
              child: _viewMode == 0 ? _buildScrollMode() : _buildPagedMode(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollMode() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.none,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: HyperViewer(
              key: const ValueKey('scroll-viewer'),
              html: _fullHtml,
              selectable: true,
              selectionColor: Colors.blue.withValues(alpha: 0.35),
              widgetBuilder: _customWidgetBuilder,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagedMode() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.none,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: HyperViewer(
              key: const ValueKey('paged-viewer'),
              mode: HyperRenderMode.paged,
              html: _fullHtml,
              selectable: true,
              selectionColor: Colors.blue.withValues(alpha: 0.35),
              widgetBuilder: _customWidgetBuilder,
            ),
          ),
        ),
      ),
    );
  }

  Widget? _customWidgetBuilder(UDTNode node) {
    if (node is AtomicNode && node.tagName == 'formula-widget') {
      final equation = node.attributes['equation'] ?? 'E=mc^2';
      return _InteractiveFormula(equation: equation);
    }
    return null;
  }
}

class _InteractiveFormula extends StatefulWidget {
  final String equation;
  const _InteractiveFormula({required this.equation});

  @override
  State<_InteractiveFormula> createState() => _InteractiveFormulaState();
}

class _InteractiveFormulaState extends State<_InteractiveFormula> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: _isHovered ? Colors.blue.shade300 : Colors.grey.shade300,
              width: 2),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Center(
          child: Text(
            widget.equation,
            style: TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 24,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
              color: _isHovered ? Colors.blue.shade800 : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
