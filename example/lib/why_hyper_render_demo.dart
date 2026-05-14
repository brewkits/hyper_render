import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

/// "Why HyperRender?" — single knockout screen proving superiority.
///
/// Opens as the first card on the home page.
/// Delivers all competitive differentiators in one scrollable screen:
///   1. Live rendered HTML showcasing Float, Ruby, Widget injection, Details
///   2. Feature comparison matrix (HyperRender vs flutter_html vs fwfh)
///   3. Performance headline numbers
class WhyHyperRenderDemo extends StatelessWidget {
  const WhyHyperRenderDemo({super.key});

  // ─── Live showcase HTML ────────────────────────────────────────────────────
  static const _showcaseHtml = '''
<div style="font-family: sans-serif; line-height: 1.7; color: #1a1a2e;">

  <!-- ── 1. Float Layout ── -->
  <!-- Use dark text on light background so content is always readable,
       regardless of whether the block background-color renders. -->
  <div style="background: #ede7f6; border: 2px solid #7e57c2;
              padding: 16px 20px; border-radius: 14px; margin-bottom: 20px;">
    <p style="color: #4527a0; font-size: 11px; font-weight: 700; letter-spacing: 1.5px;
              margin: 0 0 6px 0; text-transform: uppercase;">
      ① Exclusive Feature
    </p>
    <p style="color: #311b92; font-size: 18px; font-weight: 800; margin: 0 0 12px 0;">
      Float Layout — Like Real Browsers
    </p>
    <img src="https://picsum.photos/seed/hr_why1/90/90"
         style="float: left; width: 90px; height: 90px; border-radius: 10px;
                margin: 0 14px 6px 0; padding: 4px; background: white; border: 2px solid #7e57c2;" />
    <p style="color: #37474f; font-size: 14px; margin: 0; line-height: 1.7;">
      This text wraps around the floated image exactly like a browser.
      HyperRender implements the full IFC (Inline Formatting Context) algorithm.
      <strong style="color: #311b92;">flutter_html and fwfh cannot do this.</strong>
      The text continues below the image when it runs out of space beside it.
    </p>
    <div style="clear: both;"></div>
  </div>

  <!-- ── 2. Ruby / CJK ── -->
  <div style="background: #fce4ec; border: 1.5px solid #f48fb1;
              padding: 16px 20px; border-radius: 14px; margin-bottom: 20px;">
    <p style="color: #880e4f; font-size: 11px; font-weight: 700; letter-spacing: 1.5px;
              margin: 0 0 6px 0; text-transform: uppercase;">
      ② Exclusive Feature
    </p>
    <p style="color: #880e4f; font-size: 17px; font-weight: 800; margin: 0 0 10px 0;">
      Ruby Annotation (振り仮名) — Proper Furigana
    </p>
    <p style="font-size: 22px; margin: 0 0 8px 0; line-height: 2.4;">
      <ruby>日本語<rt>にほんご</rt></ruby>を
      <ruby>完璧<rt>かんぺき</rt></ruby>に
      <ruby>表示<rt>ひょうじ</rt></ruby>できます。
    </p>
    <p style="font-size: 20px; margin: 0; line-height: 2.4;">
      <ruby>东京<rt>Dōngjīng</rt></ruby> •
      <ruby>北京<rt>Běijīng</rt></ruby> •
      <ruby>上海<rt>Shànghǎi</rt></ruby>
    </p>
    <p style="color: #ad1457; font-size: 13px; margin: 12px 0 0 0;">
      ❌ Other Flutter HTML libs: rt text appears garbled inline or is ignored completely.
    </p>
  </div>

  <!-- ── 3. Details/Summary ── -->
  <div style="background: #e8f5e9; border: 1.5px solid #a5d6a7;
              padding: 16px 20px; border-radius: 14px; margin-bottom: 20px;">
    <p style="color: #1b5e20; font-size: 11px; font-weight: 700; letter-spacing: 1.5px;
              margin: 0 0 6px 0; text-transform: uppercase;">
      ③ Exclusive Feature
    </p>
    <p style="color: #1b5e20; font-size: 17px; font-weight: 800; margin: 0 0 12px 0;">
      &lt;details&gt; / &lt;summary&gt; — Native Collapsible
    </p>
    <details style="background: white; border: 1px solid #c8e6c9; border-radius: 8px;
                    padding: 10px 14px; margin-bottom: 8px;">
      <summary style="font-weight: 700; color: #2e7d32; cursor: pointer;">
        Tap to expand — Why use HyperRender?
      </summary>
      <p style="margin: 10px 0 0 0; color: #333; font-size: 14px; line-height: 1.7;">
        HyperRender is the only Flutter HTML library that natively supports
        &lt;details&gt;/&lt;summary&gt; with animated expand/collapse — no JavaScript,
        no WebView, pure Flutter.
      </p>
    </details>
    <details style="background: white; border: 1px solid #c8e6c9; border-radius: 8px;
                    padding: 10px 14px;" open>
      <summary style="font-weight: 700; color: #2e7d32; cursor: pointer;">
        What about flutter_html / fwfh?
      </summary>
      <p style="margin: 10px 0 0 0; color: #333; font-size: 14px; line-height: 1.7;">
        Both render &lt;details&gt; as plain flat text — the collapse functionality
        is completely lost. HyperRender handles it natively.
      </p>
    </details>
  </div>

  <!-- ── 4. CSS Cascade with Style Tag ── -->
  <div style="background: #e3f2fd; border: 1.5px solid #90caf9;
              padding: 16px 20px; border-radius: 14px; margin-bottom: 20px;">
    <p style="color: #0d47a1; font-size: 11px; font-weight: 700; letter-spacing: 1.5px;
              margin: 0 0 6px 0; text-transform: uppercase;">
      ④ Full CSS Cascade
    </p>
    <p style="color: #0d47a1; font-size: 17px; font-weight: 800; margin: 0 0 12px 0;">
      &lt;style&gt; Tag + Class + ID + Inline — Full Specificity
    </p>
    <style>
      .demo-red { color: #d32f2f; font-weight: bold; }
      .demo-green { color: #388e3c; font-weight: bold; }
      #demo-unique { color: #7b1fa2; font-style: italic; font-weight: bold; }
    </style>
    <p style="font-size: 14px; margin: 4px 0;">
      Element style:
      <span style="color: #1565c0;">selector targets this span</span>
    </p>
    <p class="demo-red" style="font-size: 14px; margin: 4px 0;">
      .demo-red class (red bold text)
    </p>
    <p class="demo-green" style="font-size: 14px; margin: 4px 0;">
      .demo-green class (green bold text)
    </p>
    <p id="demo-unique" style="font-size: 14px; margin: 4px 0;">
      #demo-unique ID (purple italic — highest specificity)
    </p>
    <p style="color: #0d47a1; font-size: 13px; margin: 10px 0 0 0;">
      ❌ flutter_html: &lt;style&gt; tag is ignored. ⚠️ fwfh: ID selectors unreliable.
    </p>
  </div>

  <!-- ── 5. Text Selection ── -->
  <div style="background: #fff3e0; border: 1.5px solid #ffcc80;
              padding: 16px 20px; border-radius: 14px; margin-bottom: 20px;">
    <p style="color: #e65100; font-size: 11px; font-weight: 700; letter-spacing: 1.5px;
              margin: 0 0 6px 0; text-transform: uppercase;">
      ⑤ Built-in Text Selection
    </p>
    <p style="color: #e65100; font-size: 17px; font-weight: 800; margin: 0 0 10px 0;">
      Long-press → Drag Handles → Copy / Share
    </p>
    <p style="font-size: 14px; margin: 0; line-height: 1.8;">
      <strong>Long-press any text</strong> to activate handles.
      Drag handles to extend the selection across
      <span style="background: #fff9c4; padding: 1px 4px; border-radius: 3px;">highlighted spans</span>,
      <strong>bold text</strong>, <em>italic text</em>, and
      <span style="color: #d32f2f;">colored text</span> — all in one gesture.
    </p>
    <p style="color: #bf360c; font-size: 13px; margin: 10px 0 0 0;">
      ❌ fwfh: Crashes on SelectionArea with complex content.
      ⚠️ flutter_html: Selection breaks at widget boundaries.
    </p>
  </div>

</div>
''';

  // ─── Feature matrix (rendered as HTML via HyperViewer) ─────────────────────
  static const _matrixHtml = '''
<div style="font-family: sans-serif;">
  <table style="border-collapse: collapse; font-size: 13px;">
    <thead>
      <tr style="background: #1a237e; color: white;">
        <th style="padding: 10px 12px; text-align: left; border-radius: 6px 0 0 0;">Feature</th>
        <th style="padding: 10px 8px; text-align: center; min-width: 88px; background: #283593;">HyperRender</th>
        <th style="padding: 10px 8px; text-align: center; min-width: 72px;">flutter_html</th>
        <th style="padding: 10px 8px; text-align: center; min-width: 48px; border-radius: 0 6px 0 0;">fwfh</th>
      </tr>
    </thead>
    <tbody>
      <tr style="background: #f8f9ff;">
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">Float layout (CSS float)</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ Full</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
      </tr>
      <tr>
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">Ruby / Furigana annotation</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ Full</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
      </tr>
      <tr style="background: #f8f9ff;">
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">&lt;details&gt; / &lt;summary&gt;</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ Animated</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
      </tr>
      <tr>
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">CSS Flexbox</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ Full</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #e65100; font-size: 12px;">⚠️ Partial</td>
      </tr>
      <tr style="background: #f8f9ff;">
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">CSS Grid</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ Full</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
      </tr>
      <tr>
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">&lt;style&gt; tag + CSS cascade</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ Full</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌ Ignored</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #e65100; font-size: 12px;">⚠️ Partial</td>
      </tr>
      <tr style="background: #f8f9ff;">
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">CSS Variables (--custom)</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ Full</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
      </tr>
      <tr>
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">Text selection + handles</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ Native</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #e65100; font-size: 12px;">⚠️ Partial</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌ Crashes</td>
      </tr>
      <tr style="background: #f8f9ff;">
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">Widget injection (custom tags)</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ Any widget</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #e65100; font-size: 12px;">⚠️ Limited</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #e65100; font-size: 12px;">⚠️ Plugin</td>
      </tr>
      <tr>
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">Table colspan + rowspan</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ Full</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #e65100; font-size: 12px;">⚠️ Basic</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #1b5e20;">✅</td>
      </tr>
      <tr style="background: #f8f9ff;">
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">Inline background wrap</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ Per-line</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌ Block only</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌ Block only</td>
      </tr>
      <tr>
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">RTL / BiDi text</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ Full</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #e65100; font-size: 12px;">⚠️ Partial</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #e65100; font-size: 12px;">⚠️ Partial</td>
      </tr>
      <tr style="background: #f8f9ff;">
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">XSS sanitization (built-in)</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ Built-in</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #e65100; font-size: 12px;">⚠️ Partial</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #e65100; font-size: 12px;">⚠️ Partial</td>
      </tr>
      <tr>
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">Dark mode (DesignTokens)</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ 27 tokens</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
      </tr>
      <tr style="background: #f8f9ff;">
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">Virtualized (large docs)</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ O(1) scroll</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
      </tr>
      <tr>
        <td style="padding: 8px 12px; border-bottom: 1px solid #e8eaf6; font-weight: 600;">Screenshot / PNG export</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; background: #e8f5e9; color: #1b5e20; font-weight: 700;">✅ Built-in</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
        <td style="padding: 8px; text-align: center; border-bottom: 1px solid #e8eaf6; color: #b71c1c;">❌</td>
      </tr>
      <tr style="background: #e8f5e9;">
        <td style="padding: 10px 12px; font-weight: 800; color: #1b5e20;">Score</td>
        <td style="padding: 10px 8px; text-align: center; font-weight: 800; font-size: 16px; color: #1b5e20;">16 / 16</td>
        <td style="padding: 10px 8px; text-align: center; font-weight: 800; font-size: 15px; color: #b71c1c;">3 / 16</td>
        <td style="padding: 10px 8px; text-align: center; font-weight: 800; font-size: 15px; color: #e65100;">4 / 16</td>
      </tr>
    </tbody>
  </table>
  <p style="font-size: 11px; color: #9e9e9e; margin: 8px 0 0 0; font-style: italic;">
    ✅ Supported · ⚠️ Partial/Plugin needed · ❌ Not supported
  </p>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Why HyperRender?'),
        backgroundColor: DemoColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHero(),
          const SizedBox(height: 20),
          _buildSection(
            title: 'Live Feature Showcase',
            subtitle: 'Rendered here — no WebView, no plugins',
            icon: Icons.play_circle_filled,
            color: DemoColors.primary,
            child: HyperViewer(
              html: _showcaseHtml,
              mode: HyperRenderMode.sync,
              selectable: true,
              // shrinkWrap: true is required when embedding a selectable
              // HyperViewer inside a ListView.  Without it, HyperViewer wraps
              // in its own SingleChildScrollView which:
              //   1. Intercepts vertical drag before the outer ListView —
              //      the scroll gesture conflict makes it impossible to scroll
              //      down the page after a long-press selection starts.
              //   2. Breaks copy-to-clipboard: the selection popup positions
              //      itself relative to the inner scroll offset, not the screen.
              shrinkWrap: true,
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Feature Comparison Matrix',
            subtitle: 'HyperRender vs flutter_html vs fwfh',
            icon: Icons.compare,
            color: DemoColors.success,
            child: HyperViewer(
              html: _matrixHtml,
              mode: HyperRenderMode.sync,
              shrinkWrap: true,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsRow(),
          const SizedBox(height: 16),
          _buildArchCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3B8E), Color(0xFF1A56DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A56DB).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2), width: 1),
                ),
                child: const Center(
                  child: Text(
                    'HR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CSS float. No other Flutter\nHTML library can do this.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Single RenderObject · Zero WebView · XSS-safe by default',
                      style: TextStyle(
                        color: Color(0xFFB8CEFC),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroChip(Icons.view_quilt_rounded, 'Float Layout'),
              _heroChip(Icons.translate_rounded, 'Ruby / CJK'),
              _heroChip(Icons.view_column_rounded, 'CSS Flexbox + Grid'),
              _heroChip(Icons.style_rounded, 'Full CSS Cascade'),
              _heroChip(Icons.widgets_rounded, 'Widget Injection'),
              _heroChip(Icons.select_all_rounded, 'Text Selection'),
              _heroChip(Icons.security_rounded, 'XSS Protection'),
              _heroChip(Icons.dark_mode_rounded, 'Dark Mode'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard('1 646', 'Tests passing',
                Icons.check_circle_outline, const Color(0xFF2E7D32))),
        const SizedBox(width: 10),
        Expanded(
            child: _buildStatCard(
                '60 FPS', 'Scroll', Icons.speed, Colors.indigo)),
        const SizedBox(width: 10),
        Expanded(
            child: _buildStatCard('<100ms', 'Parse', Icons.timer_outlined,
                const Color(0xFFBF360C))),
        const SizedBox(width: 10),
        Expanded(
            child: _buildStatCard(
                '8 MB', 'RAM (25k)', Icons.memory, const Color(0xFF00695C))),
      ],
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildArchCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.architecture,
                    color: Colors.indigo.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Architecture Advantage',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.indigo.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _archRow(
            Icons.layers,
            'Custom RenderObject Engine',
            'Bypasses the Flutter widget tree entirely — lower overhead, more control',
            Colors.indigo,
          ),
          _archRow(
            Icons.memory,
            'Virtualized ListView.builder',
            'O(1) scroll performance regardless of document length — 1000-page books scroll at 60 fps',
            Colors.teal,
          ),
          _archRow(
            Icons.offline_bolt,
            'Isolate Parsing',
            'HTML/CSS parsed off the main thread — UI never stutters on large documents',
            Colors.orange,
          ),
          _archRow(
            Icons.security,
            'Zero External Dependencies',
            'hyper_render_core depends only on Flutter SDK — small APK, fast startup',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _archRow(IconData icon, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  desc,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
