import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

/// CSS Variables, Grid & More — v1.0.0 Feature Showcase
///
/// Demonstrates advanced CSS features supported in HyperRender v1.0.0:
///   1. CSS Variables (--custom-property / var())
///   2. CSS Grid Layout
///   3. CSS calc()
///   4. SVG Inline Rendering
///   5. RTL / BiDi Support
///   6. Print / Screenshot Export
class Sprint3Demo extends StatefulWidget {
  const Sprint3Demo({super.key});

  @override
  State<Sprint3Demo> createState() => _Sprint3DemoState();
}

class _Sprint3DemoState extends State<Sprint3Demo>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Screenshot tab state
  final _captureKey = GlobalKey();
  Uint8List? _capturedBytes;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSS Variables, Grid & More'),
        backgroundColor: DemoColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.data_object, size: 16), text: 'CSS Vars'),
            Tab(icon: Icon(Icons.grid_view, size: 16), text: 'Grid'),
            Tab(icon: Icon(Icons.calculate, size: 16), text: 'calc()'),
            Tab(icon: Icon(Icons.image, size: 16), text: 'SVG'),
            Tab(icon: Icon(Icons.format_textdirection_r_to_l, size: 16), text: 'RTL'),
            Tab(icon: Icon(Icons.camera_alt, size: 16), text: 'Screenshot'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildCssVarsTab(),
          _buildGridTab(),
          _buildCalcTab(),
          _buildSvgTab(),
          _buildRtlTab(),
          _buildScreenshotTab(),
        ],
      ),
    );
  }

  // ── CSS Variables ─────────────────────────────────────────────────────────

  Widget _buildCssVarsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('CSS Custom Properties (var())'),
        const Text(
          'Define once, use everywhere. Variables cascade and inherit '
          'through the parent element chain.',
          style: TextStyle(color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 16),
        _htmlCard(
          label: ':root variables — global design tokens',
          html: '''<style>
  :root {
    --primary:   #1565c0;
    --accent:    #00897b;
    --bg-light:  #e8f5e9;
  }
</style>
<div style="background:var(--bg-light);border-radius:8px;padding:16px">
  <h3 style="color:var(--primary);margin:0 0 8px">Primary Heading</h3>
  <p style="margin:0 0 6px">Normal paragraph text.</p>
  <a style="color:var(--accent);font-weight:bold">Accent link color</a>
</div>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'Inheritance — child reads parent\'s variable',
          html: '''<div style="--brand:#e53935;border:1px solid #eee;border-radius:8px;padding:12px">
  <strong>Parent:</strong> <code>--brand: #e53935</code>
  <div style="margin-top:8px;padding:8px;background:#fce4ec;border-radius:6px">
    <span style="color:var(--brand)">✓ Child reads var(--brand)</span>
    <div style="margin-top:6px;padding:6px;background:#ffebee;border-radius:4px">
      <em style="color:var(--brand)">✓ Grandchild also reads it</em>
    </div>
  </div>
</div>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'Fallback: var(--name, fallback)',
          html: '''<p style="color:var(--not-defined, #9c27b0)">
  <code>var(--not-defined, #9c27b0)</code> — uses fallback purple</p>
<p style="font-size:var(--unknown-size, 20px)">
  <code>var(--unknown-size, 20px)</code> — font-size from fallback</p>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'Child scope overrides parent variable',
          html: '''<div style="--color:#1565c0">
  <p style="color:var(--color)">Blue from parent</p>
  <div style="--color:#e53935">
    <p style="color:var(--color)">Red — overridden in child scope</p>
    <p style="color:var(--color)">Still red in grandchild</p>
  </div>
  <p style="color:var(--color)">Blue again — back to parent scope</p>
</div>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'Design-token theming — same component, different tokens',
          html: '''<style>
  .card         { --bg:#f5f5f5; --border:#e0e0e0; --title:#212121; }
  .card-primary { --bg:#e3f2fd; --border:#1565c0; --title:#0d47a1; }
  .card-success { --bg:#e8f5e9; --border:#2e7d32; --title:#1b5e20; }
  .card-warn    { --bg:#fff3e0; --border:#e65100; --title:#bf360c; }
</style>
<div class="card card-primary"
     style="padding:10px;border:2px solid var(--border);background:var(--bg);
            border-radius:6px;margin-bottom:8px">
  <strong style="color:var(--title)">Primary Card</strong>
  <p style="margin:4px 0 0;font-size:13px">CSS variables power design systems</p>
</div>
<div class="card card-success"
     style="padding:10px;border:2px solid var(--border);background:var(--bg);
            border-radius:6px;margin-bottom:8px">
  <strong style="color:var(--title)">Success Card</strong>
  <p style="margin:4px 0 0;font-size:13px">Same markup, different token values</p>
</div>
<div class="card card-warn"
     style="padding:10px;border:2px solid var(--border);background:var(--bg);
            border-radius:6px">
  <strong style="color:var(--title)">Warning Card</strong>
  <p style="margin:4px 0 0;font-size:13px">No class changes needed — just token values</p>
</div>''',
        ),
      ],
    );
  }

  // ── CSS Grid ──────────────────────────────────────────────────────────────

  Widget _buildGridTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('CSS Grid Layout'),
        const Text(
          'Two-dimensional layout with flexible column sizing, '
          'repeat(), and column-span support.',
          style: TextStyle(color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 16),
        _htmlCard(
          label: 'Equal columns: 1fr 1fr 1fr',
          html: '''<div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:6px">
  <div style="background:#bbdefb;padding:10px;text-align:center;border-radius:4px">Col 1</div>
  <div style="background:#c8e6c9;padding:10px;text-align:center;border-radius:4px">Col 2</div>
  <div style="background:#ffe0b2;padding:10px;text-align:center;border-radius:4px">Col 3</div>
  <div style="background:#f8bbd9;padding:10px;text-align:center;border-radius:4px">Col 4</div>
  <div style="background:#d1c4e9;padding:10px;text-align:center;border-radius:4px">Col 5</div>
  <div style="background:#b2ebf2;padding:10px;text-align:center;border-radius:4px">Col 6</div>
</div>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'Mixed units: 120px sidebar | 2fr main | 1fr aside',
          html: '''<div style="display:grid;grid-template-columns:120px 2fr 1fr;gap:6px">
  <div style="background:#e3f2fd;padding:10px;border-radius:4px">
    <strong>Fixed 120px</strong><br><small>Sidebar</small>
  </div>
  <div style="background:#e8f5e9;padding:10px;border-radius:4px">
    <strong>2fr — main</strong><br><small>Gets double the flexible space</small>
  </div>
  <div style="background:#fff3e0;padding:10px;border-radius:4px">
    <strong>1fr aside</strong>
  </div>
</div>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'repeat(4, 1fr) — calendar-style grid',
          html: '''<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:4px">
  <div style="background:#b3e5fc;padding:8px;text-align:center;border-radius:4px;font-size:13px">Jan</div>
  <div style="background:#b3e5fc;padding:8px;text-align:center;border-radius:4px;font-size:13px">Feb</div>
  <div style="background:#b3e5fc;padding:8px;text-align:center;border-radius:4px;font-size:13px">Mar</div>
  <div style="background:#b3e5fc;padding:8px;text-align:center;border-radius:4px;font-size:13px">Apr</div>
  <div style="background:#e1f5fe;padding:8px;text-align:center;border-radius:4px;font-size:13px">May</div>
  <div style="background:#e1f5fe;padding:8px;text-align:center;border-radius:4px;font-size:13px">Jun</div>
  <div style="background:#e1f5fe;padding:8px;text-align:center;border-radius:4px;font-size:13px">Jul</div>
  <div style="background:#e1f5fe;padding:8px;text-align:center;border-radius:4px;font-size:13px">Aug</div>
</div>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'grid-column: span N — spanning layout',
          html: '''<div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:6px">
  <div style="grid-column:span 3;background:#1565c0;color:white;padding:10px;
              text-align:center;border-radius:4px;font-weight:bold">
    Header (span 3 — full width)
  </div>
  <div style="grid-column:span 2;background:#e3f2fd;padding:10px;border-radius:4px">
    Main content (span 2)
  </div>
  <div style="background:#e8f5e9;padding:10px;border-radius:4px">
    Sidebar (1 col)
  </div>
  <div style="background:#fff3e0;padding:10px;border-radius:4px">A</div>
  <div style="background:#fff3e0;padding:10px;border-radius:4px">B</div>
  <div style="background:#fff3e0;padding:10px;border-radius:4px">C</div>
  <div style="grid-column:span 3;background:#546e7a;color:white;padding:10px;
              text-align:center;border-radius:4px;font-weight:bold">
    Footer (span 3 — full width)
  </div>
</div>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'Photo gallery — repeat(3, 1fr) with wide feature',
          html: '''<div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px">
  <div style="background:#ef9a9a;height:70px;border-radius:6px;
              display:flex;align-items:center;justify-content:center;font-size:24px">🖼</div>
  <div style="background:#80cbc4;height:70px;border-radius:6px;
              display:flex;align-items:center;justify-content:center;font-size:24px">🖼</div>
  <div style="background:#a5d6a7;height:70px;border-radius:6px;
              display:flex;align-items:center;justify-content:center;font-size:24px">🖼</div>
  <div style="grid-column:span 2;background:#90caf9;height:70px;border-radius:6px;
              display:flex;align-items:center;justify-content:center;font-size:24px">
    🖼 Wide
  </div>
  <div style="background:#ce93d8;height:70px;border-radius:6px;
              display:flex;align-items:center;justify-content:center;font-size:24px">🖼</div>
</div>''',
        ),
      ],
    );
  }

  // ── CSS calc() ────────────────────────────────────────────────────────────

  Widget _buildCalcTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('CSS calc()'),
        const Text(
          'Arithmetic in CSS — mix units with correct operator precedence '
          '(* and / before + and -).',
          style: TextStyle(color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 16),
        _htmlCard(
          label: 'Basic arithmetic: +  −  ×  ÷',
          html: '''<p style="font-size:calc(8px + 8px)">
  <code>calc(8px + 8px)</code> → 16px font-size</p>
<p style="font-size:calc(24px - 4px)">
  <code>calc(24px - 4px)</code> → 20px font-size</p>
<p style="font-size:calc(4 * 5px)">
  <code>calc(4 * 5px)</code> → 20px font-size</p>
<p style="font-size:calc(48px / 3)">
  <code>calc(48px / 3)</code> → 16px font-size</p>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'Operator precedence — * before +',
          html: '''<div style="background:#e3f2fd;padding:8px;border-radius:6px;margin-bottom:8px">
  <p style="margin:0;font-size:calc(2 * 6px + 4px)">
    <code>calc(2 * 6px + 4px)</code> = 16px
    <small>(multiply first: 12px, then add 4px)</small>
  </p>
</div>
<div style="background:#e8f5e9;padding:8px;border-radius:6px">
  <p style="margin:0;font-size:calc(4px + 2 * 6px)">
    <code>calc(4px + 2 * 6px)</code> = 16px
    <small>(still 16px — same result regardless of order)</small>
  </p>
</div>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'em and rem units',
          html: '''<p style="font-size:calc(1em + 4px)">
  <code>calc(1em + 4px)</code> — 1em (parent font-size) + 4px</p>
<p style="font-size:calc(1rem + 2px)">
  <code>calc(1rem + 2px)</code> — 1rem (root 16px) + 2px = 18px</p>
<div style="padding:calc(0.5em + 6px);background:#fff3e0;border-radius:4px">
  padding: <code>calc(0.5em + 6px)</code>
</div>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'Combined with CSS variables',
          html: '''<div style="--sp:8px;--base:14px">
  <p style="font-size:calc(var(--base) + 4px)">
    <code>calc(var(--base) + 4px)</code> = 18px
  </p>
  <p style="margin:calc(var(--sp) * 2);background:#f3e5f5;border-radius:4px;padding:6px">
    <code>margin: calc(var(--sp) * 2)</code> = 16px
  </p>
  <div style="padding:calc(var(--sp) + 4px);background:#e8f5e9;border-radius:4px">
    <code>padding: calc(var(--sp) + 4px)</code> = 12px
  </div>
</div>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'Responsive-style layout with calc()',
          html: '''<div style="background:#e8f5e9;
                  padding:calc(8px + 4px);
                  border-radius:calc(4px + 4px);
                  border:calc(0 + 2px) solid #4caf50">
  <strong>All from calc():</strong><br>
  padding = calc(8px + 4px) = 12px<br>
  border-radius = calc(4px + 4px) = 8px<br>
  border-width = calc(0 + 2px) = 2px
</div>''',
        ),
      ],
    );
  }

  // ── SVG ───────────────────────────────────────────────────────────────────

  Widget _buildSvgTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('SVG Inline Rendering'),
        const Text(
          'Inline <svg> elements are detected during HTML parsing '
          'and rendered as atomic nodes in the fragment pipeline.',
          style: TextStyle(color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 16),
        _htmlCard(
          label: 'Simple circle SVG',
          html: '''<p>An inline SVG circle next to text:</p>
<svg width="60" height="60" viewBox="0 0 60 60">
  <circle cx="30" cy="30" r="28" fill="#e3f2fd" stroke="#1565c0" stroke-width="3"/>
  <text x="30" y="35" text-anchor="middle" font-size="12" fill="#1565c0" font-weight="bold">SVG</text>
</svg>
<p>Content continues after the SVG element normally.</p>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'SVG bar chart',
          html: '''<svg width="100%" height="100" viewBox="0 0 300 100">
  <rect x="10"  y="30" width="40" height="60" fill="#1565c0" rx="4"/>
  <rect x="60"  y="10" width="40" height="80" fill="#00897b" rx="4"/>
  <rect x="110" y="50" width="40" height="40" fill="#e53935" rx="4"/>
  <rect x="160" y="20" width="40" height="70" fill="#f57c00" rx="4"/>
  <rect x="210" y="40" width="40" height="50" fill="#8e24aa" rx="4"/>
  <text x="30"  y="98" text-anchor="middle" font-size="9" fill="#555">Q1</text>
  <text x="80"  y="98" text-anchor="middle" font-size="9" fill="#555">Q2</text>
  <text x="130" y="98" text-anchor="middle" font-size="9" fill="#555">Q3</text>
  <text x="180" y="98" text-anchor="middle" font-size="9" fill="#555">Q4</text>
  <text x="230" y="98" text-anchor="middle" font-size="9" fill="#555">Q5</text>
</svg>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'SVG icon inline with text',
          html: '''<h3>
  <svg width="22" height="22" viewBox="0 0 24 24" style="vertical-align:middle">
    <path d="M12 2L2 7l10 5 10-5-10-5z" fill="#43a047"/>
    <path d="M2 17l10 5 10-5" fill="none" stroke="#43a047" stroke-width="2"/>
    <path d="M2 12l10 5 10-5" fill="none" stroke="#43a047" stroke-width="2"/>
  </svg>
  Heading with SVG Icon
</h3>
<p>SVG icons work inline with text headings and paragraphs.</p>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'Multiple SVG shapes side by side',
          html: '''<div style="display:flex;gap:12px;align-items:center">
  <svg width="48" height="48" viewBox="0 0 48 48">
    <rect x="4" y="4" width="40" height="40" rx="8" fill="#e91e63" opacity="0.85"/>
  </svg>
  <svg width="48" height="48" viewBox="0 0 48 48">
    <polygon points="24,4 44,40 4,40" fill="#ff9800" opacity="0.85"/>
  </svg>
  <svg width="48" height="48" viewBox="0 0 48 48">
    <circle cx="24" cy="24" r="21" fill="#4caf50" opacity="0.85"/>
  </svg>
  <p style="margin:0">Shapes inline in a flex row</p>
</div>''',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border.all(color: Colors.amber.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'For full SVG support (gradients, filters, animations), '
                  'add flutter_svg to your project and register a custom widget '
                  'builder via HyperViewer\'s widgetBuilder parameter.',
                  style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── RTL / BiDi ────────────────────────────────────────────────────────────

  Widget _buildRtlTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('RTL / BiDi Support'),
        const Text(
          'direction: rtl and dir= HTML attribute are supported. '
          'Direction is inherited and applied per-fragment in TextPainter.',
          style: TextStyle(color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 16),
        _htmlCard(
          label: 'Arabic — direction: rtl',
          html: '''<div style="direction:rtl;border:1px solid #1565c0;border-radius:8px;padding:12px">
  <h3 style="margin:0 0 8px;color:#1565c0">مرحبا بالعالم</h3>
  <p style="margin:0">
    هذا نص عربي يُكتب من اليمين إلى اليسار.
    يدعم HyperRender النصوص ثنائية الاتجاه بالكامل.
  </p>
</div>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'Hebrew — dir attribute',
          html: '''<p dir="rtl" style="border-right:3px solid #e53935;padding-right:12px;color:#333">
  שלום עולם — dir="rtl" on the paragraph element
</p>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'Mixed LTR and RTL paragraphs',
          html: '''<p>English paragraph — left to right (default).</p>
<p style="direction:rtl;background:#fff3e0;padding:8px;border-radius:4px">
  نص عربي من اليمين إلى اليسار
</p>
<p>English again — back to LTR.</p>
<p style="direction:rtl;background:#e8f5e9;padding:8px;border-radius:4px">
  فارسی: این متن از راست به چپ است
</p>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'RTL with inline formatting (bold, italic, underline)',
          html: '''<div style="direction:rtl">
  <p>
    هذا النص يحتوي على <strong>نص عريض</strong>
    و <em>نص مائل</em> و <u>نص مسطر</u>.
    التنسيق الداخلي يعمل بشكل صحيح مع RTL.
  </p>
</div>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'RTL list',
          html: '''<ul style="direction:rtl;padding-right:24px;padding-left:0">
  <li>العنصر الأول</li>
  <li>العنصر الثاني</li>
  <li>العنصر الثالث</li>
</ul>''',
        ),
        const SizedBox(height: 12),
        _htmlCard(
          label: 'RTL in grid layout',
          html: '''<div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;direction:rtl">
  <div style="background:#e3f2fd;padding:10px;border-radius:4px;text-align:right">خلية 1</div>
  <div style="background:#e8f5e9;padding:10px;border-radius:4px;text-align:right">خلية 2</div>
  <div style="background:#fff3e0;padding:10px;border-radius:4px;text-align:right">خلية 3</div>
  <div style="background:#f3e5f5;padding:10px;border-radius:4px;text-align:right">خلية 4</div>
</div>''',
        ),
      ],
    );
  }

  // ── Screenshot / Export ────────────────────────────────────────────────────

  Widget _buildScreenshotTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('Screenshot / Export'),
        const Text(
          'Pass a GlobalKey as captureKey to HyperViewer, then call '
          'key.toPngBytes() to capture the rendered content as PNG.',
          style: TextStyle(color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 16),

        // Capture area
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade200, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: Colors.blue.shade50,
                child: const Row(
                  children: [
                    Icon(Icons.crop_free, size: 14, color: Colors.blue),
                    SizedBox(width: 6),
                    Text(
                      'Capture area (tap button below)',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              HyperViewer(
                captureKey: _captureKey,
                html: '''<div style="padding:20px;font-family:sans-serif;background:#fff">
  <div style="--primary:#1565c0;--accent:#00897b">
    <h2 style="color:var(--primary);margin:0 0 8px">HyperRender v1.0.0</h2>
    <p style="margin:0 0 12px;color:#555">Screenshot captured via captureKey.toPngBytes()</p>
  </div>
  <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-bottom:12px">
    <div style="background:#e3f2fd;padding:10px;border-radius:6px;text-align:center;font-size:13px">
      <strong>CSS Grid</strong>
    </div>
    <div style="background:#e8f5e9;padding:10px;border-radius:6px;text-align:center;font-size:13px">
      <strong>var()</strong>
    </div>
    <div style="background:#fff3e0;padding:10px;border-radius:6px;text-align:center;font-size:13px">
      <strong>calc()</strong>
    </div>
  </div>
  <p style="margin:0;font-size:12px;color:#999;text-align:right">
    Pixel ratio: 2× — high-DPI ready
  </p>
</div>''',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Capture button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: DemoColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _capturing ? null : _captureScreenshot,
            icon: _capturing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.camera_alt),
            label: Text(_capturing ? 'Capturing…' : 'Capture as PNG (2× DPI)'),
          ),
        ),

        // Captured image preview
        if (_capturedBytes != null) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: Colors.green.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        'Captured ${(_capturedBytes!.length / 1024).toStringAsFixed(1)} KB PNG',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                Image.memory(_capturedBytes!, fit: BoxFit.contain),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
        const Text(
          'API usage:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '''import 'package:hyper_render/hyper_render.dart';

final captureKey = GlobalKey();

// 1. Attach key to HyperViewer
HyperViewer(
  captureKey: captureKey,
  html: '<p>Content to capture</p>',
);

// 2. Capture as PNG bytes (high-DPI)
final bytes = await captureKey.toPngBytes(pixelRatio: 2.0);

// 3. Save / share / display
Image.memory(bytes!);

// Or get a dart:ui Image object:
final image = await captureKey.toImage(pixelRatio: 3.0);''',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Color(0xFF9CDCFE),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _captureScreenshot() async {
    setState(() => _capturing = true);
    try {
      final bytes = await _captureKey.toPngBytes(pixelRatio: 2.0);
      if (mounted) {
        setState(() {
          _capturedBytes = bytes;
          _capturing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _capturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: DemoColors.primary,
        ),
      ),
    );
  }

  Widget _htmlCard({required String label, required String html}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                letterSpacing: 0.3,
              ),
            ),
            const Divider(height: 10),
            HyperViewer(html: html),
          ],
        ),
      ),
    );
  }
}
