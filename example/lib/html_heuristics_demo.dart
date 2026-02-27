import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

// =============================================================================
// HtmlHeuristics + fallbackBuilder Demo
//
// Demonstrates:
//  1. HtmlHeuristics.isComplex() / hasComplexTables() / hasUnsupportedCss()
//     / hasUnsupportedElements() — live detection on arbitrary HTML.
//  2. HyperViewer.fallbackBuilder — show a mock WebView fallback for HTML
//     that exceeds hyper_render's supported subset.
//  3. The recommended hybrid pattern: HyperRender for simple content,
//     WebView for complex documents.
// =============================================================================

class HtmlHeuristicsDemo extends StatefulWidget {
  const HtmlHeuristicsDemo({super.key});

  @override
  State<HtmlHeuristicsDemo> createState() => _HtmlHeuristicsDemoState();
}

class _HtmlHeuristicsDemoState extends State<HtmlHeuristicsDemo>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('HtmlHeuristics & fallbackBuilder'),
        backgroundColor: DemoColors.warning,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.check_circle, size: 16), text: 'Simple HTML'),
            Tab(icon: Icon(Icons.warning, size: 16), text: 'Complex HTML'),
            Tab(icon: Icon(Icons.search, size: 16), text: 'Live Checker'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SimpleHtmlTab(),
          _ComplexHtmlTab(),
          _LiveCheckerTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Simple HTML: HyperViewer renders normally, fallback NOT triggered
// ─────────────────────────────────────────────────────────────────────────────

class _SimpleHtmlTab extends StatelessWidget {
  const _SimpleHtmlTab();

  static const _html = '''
<article>
  <h1 style="color:#1976D2">Simple Article</h1>
  <p>This HTML is <strong>simple</strong> — HyperRender handles it natively.
     The <code>fallbackBuilder</code> is provided but will <em>not</em> be
     called because <code>HtmlHeuristics.isComplex()</code> returns
     <strong>false</strong>.</p>
  <ul>
    <li>Standard block elements (p, h1–h6, ul/ol/li)</li>
    <li>Inline formatting (strong, em, code, a)</li>
    <li>Tables without complex colspan/rowspan</li>
    <li>Images and media</li>
  </ul>
  <blockquote style="border-left:4px solid #1976D2; padding-left:12px; color:#555">
    "HyperRender is optimised for article-style HTML — the vast majority of
    real-world content falls into this category."
  </blockquote>
  <table border="1" style="border-collapse:collapse; width:100%">
    <tr style="background:#e3f2fd">
      <th>Check</th><th>Result</th>
    </tr>
    <tr><td>isComplex()</td><td style="color:green">✓ false → render with HyperRender</td></tr>
    <tr><td>hasComplexTables()</td><td style="color:green">✓ false</td></tr>
    <tr><td>hasUnsupportedCss()</td><td style="color:green">✓ false</td></tr>
    <tr><td>hasUnsupportedElements()</td><td style="color:green">✓ false</td></tr>
  </table>
</article>
''';

  @override
  Widget build(BuildContext context) {
    final isComplex = HtmlHeuristics.isComplex(_html);
    return Column(
      children: [
        _HeuristicsResultBanner(html: _html),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: _html,
              mode: HyperRenderMode.sync,
              semanticLabel: 'Simple article demo',
              fallbackBuilder: (_) => const _MockWebViewFallback(),
            ),
          ),
        ),
        if (!isComplex)
          Container(
            color: Colors.green.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'HyperViewer rendered natively — fallbackBuilder was NOT called.',
                    style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Complex HTML: fallbackBuilder IS triggered
// ─────────────────────────────────────────────────────────────────────────────

class _ComplexHtmlTab extends StatelessWidget {
  const _ComplexHtmlTab();

  // Contains position:fixed → HtmlHeuristics.hasUnsupportedCss() → true
  static const _complexHtml = '''
<div>
  <nav style="position:fixed; top:0; left:0; right:0; background:#fff; z-index:999;
              height:56px; display:flex; align-items:center; padding:0 16px;">
    <strong>Fixed Navigation Bar</strong>
  </nav>
  <div style="margin-top:56px; padding:16px">
    <h1>App with Fixed Navbar</h1>
    <p>This HTML uses <code>position:fixed</code> which requires a browser
       viewport model — hyper_render does not support it.</p>
    <canvas id="myChart" width="400" height="200"></canvas>
    <p>There is also a &lt;canvas&gt; element for charts.</p>
    <table>
      <tr>
        <td colspan="5">Merged header across 5 columns</td>
      </tr>
    </table>
  </div>
</div>
''';

  // A simpler complex trigger: position:absolute
  static const _absoluteHtml = '''
<div style="position:relative; height:200px; background:#f5f5f5">
  <div style="position:absolute; top:20px; left:30px; background:#e3f2fd; padding:8px">
    Absolutely positioned box
  </div>
  <div style="position:absolute; bottom:20px; right:30px; background:#fce4ec; padding:8px">
    Another absolute box
  </div>
</div>
<p>This layout relies on <code>position:absolute</code> — not supported by hyper_render.</p>
''';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: DemoColors.warning.withValues(alpha: 0.08),
            child: const TabBar(
              labelColor: Color(0xFF7B3F00),
              unselectedLabelColor: Colors.grey,
              indicatorColor: DemoColors.warning,
              tabs: [
                Tab(text: 'fixed + canvas + colspan≥5'),
                Tab(text: 'position:absolute'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ComplexExample(html: _complexHtml),
                _ComplexExample(html: _absoluteHtml),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplexExample extends StatelessWidget {
  final String html;
  const _ComplexExample({required this.html});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeuristicsResultBanner(html: html),
        Expanded(
          child: HyperViewer(
            html: html,
            mode: HyperRenderMode.sync,
            semanticLabel: 'Complex HTML demo',
            fallbackBuilder: (_) => const _MockWebViewFallback(),
          ),
        ),
        Container(
          color: Colors.orange.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'HtmlHeuristics.isComplex() = true → fallbackBuilder was called '
                  '(mock WebView shown below).',
                  style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Live Checker: type arbitrary HTML and see heuristic results
// ─────────────────────────────────────────────────────────────────────────────

class _LiveCheckerTab extends StatefulWidget {
  const _LiveCheckerTab();

  @override
  State<_LiveCheckerTab> createState() => _LiveCheckerTabState();
}

class _LiveCheckerTabState extends State<_LiveCheckerTab> {
  final _ctrl = TextEditingController(
    text: '<div style="position:fixed">sticky bar</div>',
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final html = _ctrl.text;
    final complex = HtmlHeuristics.isComplex(html);
    final complexTables = HtmlHeuristics.hasComplexTables(html);
    final unsupportedCss = HtmlHeuristics.hasUnsupportedCss(html);
    final unsupportedElements = HtmlHeuristics.hasUnsupportedElements(html);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _ctrl,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Enter HTML to analyse',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey.shade50,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _ctrl.clear();
                  setState(() {});
                },
              ),
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Card(
            color: complex ? Colors.orange.shade50 : Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _resultRow('isComplex()', complex),
                  const Divider(height: 16),
                  _resultRow('hasComplexTables()', complexTables,
                      hint: 'colspan/rowspan ≥ 3'),
                  _resultRow('hasUnsupportedCss()', unsupportedCss,
                      hint: 'position:fixed/abs, z-index, clip-path…'),
                  _resultRow('hasUnsupportedElements()', unsupportedElements,
                      hint: 'canvas, input, select, form…'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        complex ? Icons.warning_amber : Icons.check_circle,
                        color: complex
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          complex
                              ? 'Recommendation: use fallbackBuilder → WebView'
                              : 'Recommendation: render with HyperViewer',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: complex
                                ? Colors.orange.shade900
                                : Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: _CodeSnippet(),
        ),
      ],
    );
  }

  Widget _resultRow(String label, bool value, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            value ? Icons.close : Icons.check,
            color: value ? Colors.orange.shade700 : Colors.green.shade700,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  TextSpan(
                    text: ' → ${value ? 'true' : 'false'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: value
                          ? Colors.orange.shade800
                          : Colors.green.shade800,
                    ),
                  ),
                  if (hint != null)
                    TextSpan(
                      text: '  ($hint)',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Compact banner showing all 4 heuristic results for the given HTML
class _HeuristicsResultBanner extends StatelessWidget {
  final String html;
  const _HeuristicsResultBanner({required this.html});

  @override
  Widget build(BuildContext context) {
    final complex = HtmlHeuristics.isComplex(html);
    final complexTables = HtmlHeuristics.hasComplexTables(html);
    final unsupportedCss = HtmlHeuristics.hasUnsupportedCss(html);
    final unsupportedElements = HtmlHeuristics.hasUnsupportedElements(html);

    return Container(
      color: complex
          ? Colors.orange.withValues(alpha: 0.1)
          : Colors.green.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            complex ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: complex ? Colors.orange.shade700 : Colors.green.shade700,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                _chip('isComplex', complex),
                _chip('tables', complexTables),
                _chip('css', unsupportedCss),
                _chip('elements', unsupportedElements),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool value) {
    return Chip(
      label: Text(
        '$label: ${value ? 'true' : 'false'}',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor:
          value ? Colors.orange.shade100 : Colors.green.shade100,
      labelStyle: TextStyle(
        color: value ? Colors.orange.shade900 : Colors.green.shade900,
        fontFamily: 'monospace',
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}

/// Simulates a WebView fallback widget (in a real app, use webview_flutter)
class _MockWebViewFallback extends StatelessWidget {
  const _MockWebViewFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.web, color: Colors.blueGrey.shade600, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'WebView fallback (simulated)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'webview_flutter',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.open_in_browser,
                    size: 40, color: Colors.blueGrey.shade300),
                const SizedBox(height: 8),
                Text(
                  'Complex HTML rendered in WebView',
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'In production: replace with WebView(controller: ...) '
                  'from package:webview_flutter',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: Colors.blueGrey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeSnippet extends StatelessWidget {
  const _CodeSnippet();

  @override
  Widget build(BuildContext context) {
    const code = '''// Hybrid pattern: HyperRender + WebView
HyperViewer(
  html: myHtml,
  fallbackBuilder: (context) {
    // Called only when HtmlHeuristics.isComplex(myHtml) == true
    return WebViewWidget(controller: webCtrl);
  },
)

// Or check manually:
if (HtmlHeuristics.isComplex(html)) {
  // render with WebView
} else {
  // render with HyperViewer (faster, native)
}''';

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
