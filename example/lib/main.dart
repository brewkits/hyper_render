import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' as fwfh;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart'
    as fwfh_core;
import 'package:hyper_render/hyper_render.dart';
import 'package:url_launcher/url_launcher.dart';

import 'html_preview_helper.dart';
import 'v2_1_showcase.dart';
import 'security_demo.dart';
import 'accessibility_demo.dart';
import 'video_demo_improved.dart';
import 'enhanced_selection_demo.dart';
import 'fwfh_issues_test_demo.dart';
import 'css_properties_demo.dart';
import 'flexbox_demo.dart';
import 'aesthetic_demo.dart';
import 'demo_colors.dart';
import 'performance_deep_dive_demo.dart';
import 'animation_demo.dart';
import 'base_url_demo.dart';
import 'sprint3_demo.dart';
import 'html_heuristics_demo.dart';
import 'smart_table_demo.dart';
import 'formula_demo.dart';
import 'manga_demo.dart';
import 'email_demo.dart';
import 'wikipedia_demo.dart';
import 'table_advanced_demo.dart';
import 'details_summary_demo.dart';
import 'transform_demo.dart';
import 'error_edge_cases_demo.dart';

/// Optimized base TextStyle for better readability
/// - fontSize: 16 (comfortable reading size)
/// - height: 1.6 (generous line spacing for readability)
/// - letterSpacing: 0.15 (slight spacing for clarity)
const kOptimizedTextStyle = TextStyle(
  fontSize: 16,
  height: 1.6,
  letterSpacing: 0.15,
  color: Color(0xFF212121),
);

void main() {
  // Ensure Flutter binding is initialized before accessing PaintingBinding
  WidgetsFlutterBinding.ensureInitialized();

  // Increase image cache size for better performance with multiple images
  // Default: maximumSize = 1000 images, maximumSizeBytes = 50 MB
  PaintingBinding.instance.imageCache.maximumSizeBytes = 150 << 20; // 150 MB for demo images

  runApp(const HyperRenderDemoApp());
}

class HyperRenderDemoApp extends StatelessWidget {
  const HyperRenderDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperRender Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

// =============================================================================
// BACK-SAFE NAVIGATION HELPER
// Wraps every demo page with PopScope(canPop: false) so Android swipe-from-edge
// does NOT accidentally trigger "go back" during text selection testing.
// A functional back button is overlaid on top of the AppBar leading area and
// calls Navigator.pop() directly (bypasses PopScope).
// =============================================================================

void _push(BuildContext context, Widget page) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => _BackBlockedPage(child: page)),
  );
}

class _BackBlockedPage extends StatelessWidget {
  final Widget child;
  const _BackBlockedPage({required this.child});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return PopScope(
      canPop: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          // Functional back button overlaid on AppBar's leading area.
          // Uses Navigator.pop() directly so PopScope doesn't block it.
          Positioned(
            top: topPad,
            left: 4,
            width: 48,
            height: kToolbarHeight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.of(context).pop(),
                child: const Center(
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HOME PAGE - Navigation to demos
// =============================================================================

class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HyperRender Demo'),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildDemoCard(
            context,
            icon: Icons.auto_awesome,
            title: 'Kitchen Sink',
            subtitle: 'All features: Float, Selection, Ruby, Widget Injection',
            color: DemoColors.primary,
            onTap: () => _push(context, const KitchenSinkDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.view_column,
            title: 'Flexbox Layout',
            subtitle: 'Modern CSS Flexbox: justify-content, align-items, gap, flex-direction, flex-wrap',
            color: DemoColors.primary,
            onTap: () => _push(context, const FlexboxDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.view_quilt,
            title: 'Float Layout',
            subtitle: 'CSS float: left/right - Text wrapping around images',
            color: DemoColors.primary,
            onTap: () => _push(context, const FloatLayoutDemo()),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(context, '🌏 CJK & International Typography'),
          _buildDemoCard(
            context,
            icon: Icons.menu_book,
            title: 'Manga & CJK Typography ⭐',
            subtitle: 'Complete Japanese manga layout with furigana, panel grids, vertical text',
            color: const Color(0xFFB71C1C),
            onTap: () => _push(context, const MangaDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.translate,
            title: 'Ruby Annotation (振り仮名)',
            subtitle: 'Furigana for Japanese · Pinyin for Chinese · Poetry · Complex sentences',
            color: const Color(0xFFE91E63),
            onTap: () => _push(context, const RubyDemo()),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(context, '✨ Advanced Features'),
          _buildDemoCard(
            context,
            icon: Icons.select_all,
            title: 'Enhanced Selection Menu ⭐',
            subtitle: 'Copy, Share, Search, Translate, Define - Rich context menu',
            color: const Color(0xFF9C27B0),
            onTap: () => _push(context, const EnhancedSelectionDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.widgets,
            title: 'Widget Injection',
            subtitle: 'Embed interactive Flutter Widgets inside HTML content',
            color: DemoColors.secondary,
            onTap: () => _push(context, const WidgetInjectionDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.format_paint,
            title: 'Inline Decoration',
            subtitle: 'Background and border wrap correctly on line breaks',
            color: DemoColors.secondary,
            onTap: () => _push(context, const InlineDecorationDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.article,
            title: 'Real Content',
            subtitle: 'Blog post and novel with full features',
            color: DemoColors.primary,
            onTap: () => _push(context, const RealContentDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.table_chart,
            title: 'Table Demos',
            subtitle: 'Simple, wide, complex, and nested tables',
            color: DemoColors.primary,
            onTap: () => _push(context, const TableDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.table_rows,
            title: 'Advanced Tables ⭐',
            subtitle: 'Nested 3-level, financial report, schedule rowspan, multi-table',
            color: const Color(0xFF1A237E),
            onTap: () => _push(context, const TableAdvancedDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.code,
            title: 'Code Blocks',
            subtitle: 'Syntax highlighting with <pre><code> elements',
            color: DemoColors.accent,
            onTap: () => _push(context, const CodeBlockDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.broken_image,
            title: 'Image Handling',
            subtitle: 'Automatic loading/error states for images',
            color: DemoColors.warning,
            onTap: () => _push(context, const ImageHandlingDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.play_circle_filled,
            title: 'Video & Media ⭐',
            subtitle: 'Functional video playback - Tap to play externally',
            color: DemoColors.warning,
            onTap: () => _push(context, const ImprovedVideoDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.zoom_in,
            title: 'Zoom & Pan',
            subtitle: 'Pinch-to-zoom and pan gestures with InteractiveViewer',
            color: DemoColors.warning,
            onTap: () => _push(context, const ZoomDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.expand_more,
            title: 'Details/Summary Interactive',
            subtitle: 'HTML5 <details> expand/collapse widget',
            color: Colors.blue,
            onTap: () => _push(context, const DetailsSummaryDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.transform,
            title: 'CSS Transform ⭐',
            subtitle: 'Translate, rotate, scale with Matrix4',
            color: Colors.purple,
            onTap: () => _push(context, const TransformDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.bug_report,
            title: 'Error Edge Cases',
            subtitle: 'Real-world errors: 404, malformed HTML, timeouts',
            color: Colors.red.shade700,
            onTap: () => _push(context, const ErrorEdgeCasesDemo()),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Input Formats'),
          _buildDemoCard(
            context,
            icon: Icons.data_object,
            title: 'Quill Delta',
            subtitle: 'Render Quill Delta JSON format (from Quill.js editor)',
            color: DemoColors.accent,
            onTap: () => _push(context, const QuillDeltaDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.text_snippet,
            title: 'Markdown',
            subtitle: 'Render Markdown content',
            color: DemoColors.accent,
            onTap: () => _push(context, const MarkdownDemo()),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(context, '📬 Real-World Use Cases'),
          _buildDemoCard(
            context,
            icon: Icons.email,
            title: 'HTML Email Renderer ⭐',
            subtitle: 'Render HTML emails natively — no WebView, no 20MB overhead',
            color: DemoColors.primary,
            onTap: () => _push(context, const EmailDemo()),
          ),
          const SizedBox(height: 8),
          _buildDemoCard(
            context,
            icon: Icons.public,
            title: 'Wikipedia: Harry Potter & LotR ⭐',
            subtitle: 'Fetch & render real Wikipedia articles — live stress test',
            color: const Color(0xFF1565C0),
            onTap: () => _push(context, const WikipediaDemo()),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Comparison & Stress Test'),
          _buildDemoCard(
            context,
            icon: Icons.compare,
            title: 'Library Comparison',
            subtitle:
                'Compare with flutter_html and flutter_widget_from_html',
            color: DemoColors.success,
            onTap: () => _push(context, const LibraryComparisonDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.bug_report,
            title: 'FWFH Issues Test ⭐',
            subtitle: 'Test features that flutter_widget_from_html struggles with',
            color: DemoColors.success,
            onTap: () => _push(context, const FWFHIssuesTestDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.speed,
            title: 'Stress Test',
            subtitle: 'Test with 1000-page book - Measure performance',
            color: DemoColors.error,
            onTap: () => _push(context, const StressTestDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.insights,
            title: 'Performance Deep Dive ⚡',
            subtitle: 'Pipeline breakdown, Isolate parsing, CSS indexing, Memory',
            color: DemoColors.success,
            onTap: () => _push(context, const PerformanceDeepDiveDemo()),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(context, '⚙️ Advanced Features'),
          _buildDemoCard(
            context,
            icon: Icons.new_releases,
            title: 'Advanced Features Showcase',
            subtitle: 'Error Boundaries, Performance, Dark Mode, Skeletons, Animations',
            color: DemoColors.secondary,
            onTap: () => _push(context, const V21Showcase()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.security,
            title: 'Security Demo (XSS Protection)',
            subtitle: 'HTML Sanitization - XSS attack prevention',
            color: DemoColors.error,
            onTap: () => _push(context, const SecurityDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.accessibility,
            title: 'Accessibility Demo (A11y)',
            subtitle: 'Screen reader support - VoiceOver & TalkBack',
            color: DemoColors.success,
            onTap: () => _push(context, const AccessibilityDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.auto_awesome,
            title: 'Aesthetic Quality Demo ✨',
            subtitle: 'Crisp images, anti-aliased borders, smooth gradients, text shadows',
            color: DemoColors.secondary,
            onTap: () => _push(context, const AestheticDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.style,
            title: 'CSS Properties Showcase ⭐',
            subtitle: 'text-shadow, text-overflow, border-style, direction, and 60+ properties',
            color: DemoColors.primary,
            onTap: () => _push(context, const CssPropertiesDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.animation,
            title: 'Widget Animations',
            subtitle: 'Fade, slide, bounce animations (CSS animations planned)',
            color: DemoColors.accent,
            onTap: () => _push(context, const AnimationDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.link,
            title: 'Base URL & Links',
            subtitle: 'Relative URL resolution and link tap handling',
            color: DemoColors.secondary,
            onTap: () => _push(context, const BaseUrlDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.rocket_launch,
            title: 'CSS Variables, Grid & More ✨',
            subtitle: 'CSS Variables, Grid, calc(), SVG, RTL/BiDi, Screenshot export',
            color: DemoColors.accent,
            onTap: () => _push(context, const Sprint3Demo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.auto_fix_high,
            title: 'HTML Heuristics & Fallback',
            subtitle: 'Detect complex HTML and use WebView fallback when needed',
            color: DemoColors.warning,
            onTap: () => _push(context, const HtmlHeuristicsDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.table_chart,
            title: 'SmartTable & TableStrategy',
            subtitle: 'W3C 2-pass layout, fitWidth / horizontalScroll / autoScale',
            color: Colors.teal,
            onTap: () => _push(context, const SmartTableDemo()),
          ),
          _buildDemoCard(
            context,
            icon: Icons.calculate,
            title: 'Formula / LaTeX Rendering',
            subtitle: 'Greek letters, physics formulas, Quill Delta embeds, custom builder',
            color: DemoColors.secondary,
            onTap: () => _push(context, const FormulaDemo()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, Color.lerp(primary, Colors.purple.shade800, 0.55)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.rocket_launch, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HyperRender',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Universal Content Engine for Flutter',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        letterSpacing: 0.1,
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
              _buildChip('Float Layout', Icons.view_quilt_rounded),
              _buildChip('Text Selection', Icons.select_all_rounded),
              _buildChip('Ruby', Icons.translate_rounded),
              _buildChip('Flexbox', Icons.view_column_rounded),
              _buildChip('Widget Injection', Icons.widgets_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// KITCHEN SINK DEMO - All features
// =============================================================================

class KitchenSinkDemo extends StatefulWidget {
  const KitchenSinkDemo({super.key});

  @override
  State<KitchenSinkDemo> createState() => _KitchenSinkDemoState();
}

class _KitchenSinkDemoState extends State<KitchenSinkDemo> {
  int _subscribeCount = 0;

  final String htmlContent = '''
<div style="font-family: sans-serif; color: #212121;">
  <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 24px; border-radius: 16px; margin-bottom: 28px; box-shadow: 0 4px 12px rgba(0,0,0,0.15);">
    <h1 style="color: white; margin: 0; font-size: 28px; font-weight: bold; line-height: 1.3;">🚀 HyperRender Engine</h1>
    <p style="color: rgba(255,255,255,0.95); margin: 12px 0 0 0; font-size: 16px; line-height: 1.6;">The Universal Content Engine for Flutter</p>
  </div>

  <h2 style="color: #1976D2; border-left: 4px solid #1976D2; padding-left: 12px; font-weight: bold; margin: 0 0 16px 0; line-height: 1.3;">1. Float Layout</h2>
  <div style="margin: 0 0 24px 0; min-height: 110px;">
    <img src="https://picsum.photos/100/100?random=1" style="float: left; width: 100px; height: 100px; margin: 0 20px 16px 0; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);" />
    <p style="margin: 0; color: #424242; font-size: 16px; line-height: 2.0;">
      This is an example of <strong style="color: #E91E63;">Float Layout</strong>. This text will automatically
      wrap around the image on the left. HyperRender uses the IFC algorithm like web browsers for accurate text flow.
      This enables magazine-style layouts with images and text flowing naturally together.
    </p>
    <div style="clear: both;"></div>
  </div>

  <h2 style="color: #9C27B0; border-left: 4px solid #9C27B0; padding-left: 12px; font-weight: bold; margin: 0 0 16px 0; line-height: 1.3;">2. Widget Injection</h2>
  <div style="text-align: center; margin: 0 0 24px 0; padding: 24px; background: #FFF3E0; border-radius: 12px; border: 2px solid #FFB300;">
    <p style="margin: 0 0 16px 0; font-weight: bold; color: #E65100; font-size: 16px; line-height: 1.6;">🔔 Subscribe to receive notifications!</p>
    <subscribe-button></subscribe-button>
  </div>

  <h2 style="color: #00BCD4; border-left: 4px solid #00BCD4; padding-left: 12px; font-weight: bold; margin: 0 0 16px 0; line-height: 1.3;">3. Ruby Annotation (日本語)</h2>
  <div style="background: #E0F7FA; padding: 24px; border-radius: 12px; margin: 0 0 24px 0; border: 2px solid #00ACC1;">
    <p style="font-size: 20px; margin: 0; color: #006064; line-height: 2.4;">
      <ruby>日本語<rt>にほんご</rt></ruby>の<ruby>文章<rt>ぶんしょう</rt></ruby>を
      <ruby>完璧<rt>かんぺき</rt></ruby>に<ruby>表示<rt>ひょうじ</rt></ruby>できます。
    </p>
  </div>

  <h2 style="color: #4CAF50; border-left: 4px solid #4CAF50; padding-left: 12px; font-weight: bold; margin: 0 0 16px 0; line-height: 1.3;">4. Text Selection</h2>
  <div style="background: #E8F5E9; padding: 24px; border-radius: 12px; margin: 0 0 24px 0; border: 2px solid #66BB6A;">
    <p style="margin: 0 0 12px 0; color: #1B5E20; font-weight: 600; font-size: 16px; line-height: 1.8;">👆 <strong>Long press</strong> on any text to show Copy menu!</p>
    <p style="margin: 0; color: #2E7D32; font-size: 15px; line-height: 1.8;">Or drag to select text, then long press to copy to clipboard.</p>
  </div>

  <h2 style="color: #FF5722; border-left: 4px solid #FF5722; padding-left: 12px; font-weight: bold; margin: 0 0 16px 0; line-height: 1.3;">5. CSS Styling & Typography</h2>
  <div style="background: #FBE9E7; padding: 24px; border-radius: 12px; margin: 0 0 24px 0; border: 2px solid #FF7043;">
    <p style="margin: 0 0 16px 0; color: #BF360C; font-size: 16px; line-height: 1.8;">
      <span style="font-size: 18px; font-weight: bold; color: #D84315;">Rich text styling</span> with
      <em style="color: #E64A19;">italics</em>, <strong style="color: #F4511E;">bold</strong>,
      <u style="color: #FF5722;">underline</u>, and
      <span style="background: #FFEB3B; padding: 2px 6px; border-radius: 4px;">highlights</span>.
    </p>
    <p style="margin: 0; color: #3E2723; font-family: monospace; background: #FFF8E1; padding: 12px; border-radius: 4px; font-size: 14px; line-height: 1.6;">
      &lt;code&gt; blocks with monospace font &lt;/code&gt;
    </p>
  </div>

  <h2 style="color: #795548; border-left: 4px solid #795548; padding-left: 12px; font-weight: bold; margin: 0 0 16px 0; line-height: 1.3;">6. Lists & Nested Content</h2>
  <div style="background: #EFEBE9; padding: 24px; border-radius: 12px; margin: 0 0 24px 0; border: 2px solid #A1887F;">
    <ul style="margin: 0; padding-left: 20px; color: #3E2723; font-size: 16px; line-height: 1.8;">
      <li style="margin-bottom: 12px;"><strong>Feature-rich rendering</strong> - Complex HTML support</li>
      <li style="margin-bottom: 12px;"><strong>High performance</strong> - Optimized for mobile devices</li>
      <li style="margin-bottom: 12px;"><strong>Cross-platform</strong> - Works on iOS, Android, Web</li>
    </ul>
  </div>

  <div style="background: #F3E5F5; padding: 24px; border-radius: 12px; margin: 0; text-align: center; border: 2px solid #BA68C8;">
    <p style="margin: 0; color: #4A148C; font-size: 16px; font-weight: bold; line-height: 1.6;">
      ✨ This demo showcases core HyperRender capabilities in one place ✨
    </p>
  </div>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ensure white background for proper contrast
      appBar: AppBar(
        title: const Text('Kitchen Sink Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Custom back button from _BackBlockedPage
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: HyperViewer(
          html: htmlContent,
          selectable: true,
          onLinkTap: (url) => _handleLinkTap(url),
          widgetBuilder: (node) {
            if (node is AtomicNode && node.tagName == 'subscribe-button') {
              return _buildSubscribeButton();
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildSubscribeButton() {
    final isSubscribed = _subscribeCount > 0;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() => isSubscribed ? _subscribeCount-- : _subscribeCount++);
        _showSnackBar(isSubscribed ? '🔕 Unsubscribed' : '🔔 Subscribed!');
      },
      icon: Icon(isSubscribed ? Icons.notifications_off : Icons.notifications_active),
      label: Text(isSubscribed ? 'Subscribed' : 'Subscribe'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSubscribed ? Colors.grey : Colors.redAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _handleLinkTap(String url) async {
    print('[KitchenSinkDemo] _handleLinkTap called with URL: $url');

    final uri = Uri.tryParse(url);
    if (uri == null) {
      print('[KitchenSinkDemo] Invalid URL: $url');
      _showSnackBar('❌ Invalid URL: $url');
      return;
    }

    // Try to launch the URL
    try {
      print('[KitchenSinkDemo] Checking if can launch: $uri');
      final canLaunch = await canLaunchUrl(uri);
      print('[KitchenSinkDemo] canLaunch result: $canLaunch');

      if (canLaunch) {
        print('[KitchenSinkDemo] Launching URL...');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSnackBar('🚀 Opening: ${uri.toString().length > 40 ? '${uri.toString().substring(0, 40)}...' : uri.toString()}');
      } else {
        _showSnackBar('❌ Cannot open URL: $url');
      }
    } catch (e) {
      print('[KitchenSinkDemo] Error: $e');
      _showSnackBar('❌ Error opening URL: $e');
    }
  }
}

// =============================================================================
// FLOAT LAYOUT DEMO
// =============================================================================

class FloatLayoutDemo extends StatelessWidget {
  const FloatLayoutDemo({super.key});

  static const html = '''
<div style="font-family: sans-serif; color: #212121;">
  <h2 style="color: #1976D2; font-weight: bold; margin: 0 0 20px 0; line-height: 1.3;">Float Left</h2>
  <div style="margin: 0 0 32px 0; background: #E3F2FD; padding: 24px; border-radius: 12px; border: 2px solid #1976D2; min-height: 140px;">
    <img src="https://picsum.photos/120/120?random=10" style="float: left; width: 120px; height: 120px; margin: 0 20px 16px 0; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.2);" />
    <p style="margin: 0 0 20px 0; color: #0D47A1; font-size: 16px; line-height: 2.0;">
      This is an example of <strong style="color: #1565C0;">float: left</strong>. Text will automatically wrap around the image on the left.
      When the text is long enough, it will continue below the image naturally. This is a feature
      that <strong>flutter_html</strong> and <strong>flutter_widget_from_html</strong> do NOT support.
    </p>
    <p style="margin: 0; color: #1565C0; font-size: 15px; line-height: 2.0;">
      HyperRender uses the <strong>IFC (Inline Formatting Context)</strong> algorithm like real web browsers
      to calculate the remaining space of each line and fill it with text fragments. This enables magazine-style layouts.
    </p>
    <div style="clear: both;"></div>
  </div>

  <h2 style="color: #9C27B0; font-weight: bold; margin: 0 0 20px 0; line-height: 1.3;">Float Right</h2>
  <div style="margin: 0 0 32px 0; background: #F3E5F5; padding: 24px; border-radius: 12px; border: 2px solid #9C27B0; min-height: 120px;">
    <img src="https://picsum.photos/100/100?random=11" style="float: right; width: 100px; height: 100px; margin: 0 0 16px 20px; border-radius: 50%; box-shadow: 0 2px 8px rgba(0,0,0,0.2);" />
    <p style="margin: 0 0 20px 0; color: #4A148C; font-size: 16px; line-height: 2.0;">
      Float also works on the <strong style="color: #6A1B9A;">right side</strong>! This circle floats right and text
      will fill the empty space on the left naturally.
    </p>
    <p style="margin: 0; color: #6A1B9A; font-size: 15px; line-height: 2.0;">
      Try rotating the screen to see how smoothly the layout adapts. The text will reflow automatically
      based on the available width.
    </p>
    <div style="clear: both;"></div>
  </div>

  <h2 style="color: #FF5722; font-weight: bold; margin: 0 0 20px 0; line-height: 1.3;">Multiple Floats</h2>
  <div style="margin: 0 0 32px 0; background: #FBE9E7; padding: 24px; border-radius: 12px; border: 2px solid #FF5722; min-height: 100px;">
    <img src="https://picsum.photos/80/80?random=12" style="float: left; width: 80px; height: 80px; margin: 0 16px 16px 0; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.2);" />
    <img src="https://picsum.photos/80/80?random=13" style="float: left; width: 80px; height: 80px; margin: 0 16px 16px 0; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.2);" />
    <p style="margin: 0; color: #BF360C; font-size: 16px; line-height: 2.0;">
      <strong>Nhiều float elements</strong> có thể xếp cạnh nhau. Văn bản sẽ wrap xung quanh tất cả chúng.
      Đây là layout kiểu <strong>magazine/newspaper</strong> rất phổ biến trong thiết kế web hiện đại.
      Text flows naturally around multiple floated images, creating professional editorial layouts.
    </p>
    <div style="clear: both;"></div>
  </div>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Float Layout Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: HyperViewer(html: html, selectable: true),
        ),
      ),
    );
  }
}

// =============================================================================
// SELECTION DEMO
// =============================================================================

class SelectionDemo extends StatelessWidget {
  const SelectionDemo({super.key});

  static const html = '''
<div style="font-family: sans-serif; line-height: 1.8;">
  <div style="background: #E3F2FD; padding: 16px; border-radius: 12px; margin-bottom: 24px;">
    <h3 style="margin: 0 0 8px 0; color: #1565C0;">📱 Hướng dẫn sử dụng</h3>
    <ul style="margin: 0; padding-left: 20px;">
      <li><strong>Kéo</strong> trên văn bản để bôi đen</li>
      <li><strong>Long press</strong> để hiện menu Copy</li>
      <li><strong>Ctrl+C</strong> (hoặc Cmd+C) để copy</li>
      <li><strong>Ctrl+A</strong> để select all</li>
      <li>Tap ra ngoài để clear selection</li>
    </ul>
  </div>

  <h2>Đoạn văn mẫu</h2>
  <p>
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor
    incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud
    exercitation ullamco laboris.
  </p>

  <p>
    Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu
    fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
    culpa qui officia deserunt mollit anim id est laborum.
  </p>

  <h2>Vietnamese Text</h2>
  <p>
    HyperRender is a powerful Flutter library that renders HTML, Markdown and Quill Delta
    with high performance. Selection works smoothly even with long and complex text.
  </p>

  <h2>Mixed Content</h2>
  <p>
    Text with <strong>bold</strong>, <em>italic</em>, <u>underline</u>, and
    <span style="color: red;">colored text</span>. Selection works across all inline styles!
  </p>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Text Selection Demo',
      html: html,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: HyperViewer(html: html, selectable: true),
        ),
      ),
    );
  }
}

// =============================================================================
// RUBY DEMO
// =============================================================================

class RubyDemo extends StatelessWidget {
  const RubyDemo({super.key});

  static const html = '''
<div style="font-family: sans-serif; color: #212121;">
  <div style="background: linear-gradient(135deg, #E91E63 0%, #F06292 100%); padding: 24px; border-radius: 12px; margin-bottom: 24px; box-shadow: 0 4px 12px rgba(0,0,0,0.15);">
    <h2 style="color: white; margin: 0; font-size: 24px; line-height: 1.3;">Ruby Annotation (振り仮名)</h2>
    <p style="color: rgba(255,255,255,0.95); margin: 12px 0 0 0; font-size: 15px; line-height: 1.6;">Furigana reading aids above kanji characters</p>
  </div>

  <div style="background: #FCE4EC; padding: 24px; border-radius: 12px; margin: 0 0 24px 0; border: 2px solid #F06292;">
    <h3 style="margin: 0 0 16px 0; color: #C2185B; font-weight: bold; line-height: 1.3;">基本的な例 (Basic Examples)</h3>
    <p style="font-size: 22px; margin: 0 0 16px 0; color: #880E4F; line-height: 2.6;">
      <ruby>日本語<rt>にほんご</rt></ruby>を<ruby>勉強<rt>べんきょう</rt></ruby>しています。
    </p>
    <p style="color: #666; font-size: 14px; margin: 0; line-height: 1.6;">= I am studying Japanese.</p>
  </div>

  <div style="background: #E8F5E9; padding: 24px; border-radius: 12px; margin: 0 0 24px 0; border: 2px solid #66BB6A;">
    <h3 style="margin: 0 0 16px 0; color: #2E7D32; font-weight: bold; line-height: 1.3;">文学作品 (Literature)</h3>
    <p style="font-size: 20px; margin: 0 0 16px 0; font-style: italic; color: #1B5E20; line-height: 2.6;">
      <ruby>吾輩<rt>わがはい</rt></ruby>は<ruby>猫<rt>ねこ</rt></ruby>である。
      <ruby>名前<rt>なまえ</rt></ruby>はまだない。
    </p>
    <p style="color: #666; font-size: 14px; margin: 0; line-height: 1.6;">— 夏目漱石「吾輩は猫である」(Natsume Sōseki, "I Am a Cat")</p>
  </div>

  <div style="background: #F3E5F5; padding: 24px; border-radius: 12px; margin: 0 0 24px 0; border: 2px solid #BA68C8;">
    <h3 style="margin: 0 0 16px 0; color: #6A1B9A; font-weight: bold; line-height: 1.3;">複雑な文章 (Complex Sentence)</h3>
    <p style="font-size: 19px; margin: 0 0 16px 0; line-height: 2.8; color: #4A148C;">
      <ruby>昨日<rt>きのう</rt></ruby>、<ruby>友達<rt>ともだち</rt></ruby>と<ruby>一緒<rt>いっしょ</rt></ruby>に
      <ruby>新宿<rt>しんじゅく</rt></ruby>で<ruby>映画<rt>えいが</rt></ruby>を<ruby>見<rt>み</rt></ruby>ました。
      とても<ruby>面白<rt>おもしろ</rt></ruby>かったです。
    </p>
    <p style="color: #666; font-size: 14px; margin: 0; line-height: 1.6;">= Yesterday, I watched a movie in Shinjuku with friends. It was very interesting.</p>
  </div>

  <div style="background: #E3F2FD; padding: 24px; border-radius: 12px; margin: 0 0 24px 0; border: 2px solid #42A5F5;">
    <h3 style="margin: 0 0 16px 0; color: #1565C0; font-weight: bold; line-height: 1.3;">地名 (Place Names)</h3>
    <p style="font-size: 20px; margin: 0; color: #0D47A1; line-height: 2.6;">
      <ruby>東京<rt>とうきょう</rt></ruby> •
      <ruby>大阪<rt>おおさか</rt></ruby> •
      <ruby>京都<rt>きょうと</rt></ruby> •
      <ruby>北海道<rt>ほっかいどう</rt></ruby> •
      <ruby>沖縄<rt>おきなわ</rt></ruby>
    </p>
  </div>

  <div style="background: #FFF3E0; padding: 24px; border-radius: 12px; margin: 0 0 24px 0; border: 2px solid #FFA726;">
    <h3 style="margin: 0 0 16px 0; color: #E65100; font-weight: bold; line-height: 1.3;">中文拼音 (Chinese Pinyin)</h3>
    <p style="font-size: 20px; margin: 0; color: #BF360C; line-height: 2.6;">
      <ruby>你好<rt>nǐ hǎo</rt></ruby> •
      <ruby>谢谢<rt>xiè xiè</rt></ruby> •
      <ruby>中国<rt>zhōng guó</rt></ruby> •
      <ruby>欢迎<rt>huān yíng</rt></ruby> •
      <ruby>再见<rt>zài jiàn</rt></ruby>
    </p>
  </div>

  <div style="background: #E0F2F1; padding: 24px; border-radius: 12px; margin: 0 0 24px 0; border: 2px solid #26A69A;">
    <h3 style="margin: 0 0 16px 0; color: #00695C; font-weight: bold; line-height: 1.3;">詩 (Poetry)</h3>
    <p style="font-size: 18px; margin: 0 0 16px 0; line-height: 3.0; color: #004D40;">
      <ruby>春眠<rt>しゅんみん</rt></ruby><ruby>暁<rt>あかつき</rt></ruby>を<ruby>覚<rt>おぼ</rt></ruby>えず<br/>
      <ruby>処処<rt>しょしょ</rt></ruby><ruby>啼鳥<rt>ていちょう</rt></ruby>を<ruby>聞<rt>き</rt></ruby>く<br/>
      <ruby>夜来<rt>やらい</rt></ruby><ruby>風雨<rt>ふうう</rt></ruby>の<ruby>声<rt>こえ</rt></ruby><br/>
      <ruby>花<rt>はな</rt></ruby><ruby>落<rt>お</rt></ruby>つること<ruby>知<rt>し</rt></ruby>る<ruby>多少<rt>たしょう</rt></ruby>
    </p>
    <p style="color: #666; font-size: 14px; margin: 0; line-height: 1.6;">— 孟浩然「春暁」(Meng Haoran, "Spring Dawn")</p>
  </div>

  <div style="background: #FBE9E7; padding: 24px; border-radius: 12px; margin: 0 0 24px 0; border: 2px solid #FF7043;">
    <h3 style="margin: 0 0 16px 0; color: #D84315; font-weight: bold; line-height: 1.3;">難しい漢字 (Difficult Kanji)</h3>
    <p style="font-size: 19px; margin: 0; color: #BF360C; line-height: 2.6;">
      <ruby>憂鬱<rt>ゆううつ</rt></ruby> •
      <ruby>薔薇<rt>ばら</rt></ruby> •
      <ruby>檸檬<rt>れもん</rt></ruby> •
      <ruby>林檎<rt>りんご</rt></ruby> •
      <ruby>葡萄<rt>ぶどう</rt></ruby> •
      <ruby>麒麟<rt>きりん</rt></ruby>
    </p>
  </div>

  <div style="background: #F1F8E9; padding: 20px; border-radius: 12px; margin: 16px 0; text-align: center; border: 2px solid #9CCC65;">
    <p style="margin: 0; color: #33691E; font-size: 15px; font-weight: bold;">
      ✨ Ruby annotations enable perfect Japanese & Chinese typography ✨
    </p>
  </div>
</div>
''';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ruby Annotation Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: HyperViewer(html: html, selectable: true),
      ),
    );
  }
}

// =============================================================================
// WIDGET INJECTION DEMO
// =============================================================================

class WidgetInjectionDemo extends StatefulWidget {
  const WidgetInjectionDemo({super.key});

  @override
  State<WidgetInjectionDemo> createState() => _WidgetInjectionDemoState();
}

class _WidgetInjectionDemoState extends State<WidgetInjectionDemo> {
  int _likeCount = 42;
  bool _isSubscribed = false;
  double _rating = 4.0;

  static const html = '''
<div style="font-family: sans-serif; line-height: 1.6;">
  <h2 style="color: #9C27B0;">Widget Injection</h2>
  <p>You can embed <strong>any Flutter Widget</strong> into HTML using custom tags.</p>

  <div style="background: #F3E5F5; padding: 16px; border-radius: 12px; margin: 16px 0; text-align: center;">
    <p style="margin: 0 0 12px 0; font-weight: bold;">🔔 Subscribe Channel</p>
    <subscribe-button></subscribe-button>
  </div>

  <div style="background: #FCE4EC; padding: 16px; border-radius: 12px; margin: 16px 0;">
    <p style="margin: 0 0 12px 0; font-weight: bold;">❤️ Like this post</p>
    <like-button></like-button>
  </div>

  <div style="background: #E8F5E9; padding: 16px; border-radius: 12px; margin: 16px 0;">
    <p style="margin: 0 0 12px 0; font-weight: bold;">⭐ Rate this article</p>
    <rating-widget></rating-widget>
  </div>

  <div style="background: #E3F2FD; padding: 16px; border-radius: 12px; margin: 16px 0;">
    <p style="margin: 0 0 12px 0; font-weight: bold;">📤 Share</p>
    <share-buttons></share-buttons>
  </div>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Injection Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: HyperViewer(
          html: html,
          widgetBuilder: (node) {
            if (node is AtomicNode) {
              switch (node.tagName) {
                case 'subscribe-button':
                  return _buildSubscribeButton();
                case 'like-button':
                  return _buildLikeButton();
                case 'rating-widget':
                  return _buildRatingWidget();
                case 'share-buttons':
                  return _buildShareButtons();
              }
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return ElevatedButton.icon(
      onPressed: () => setState(() => _isSubscribed = !_isSubscribed),
      icon: Icon(_isSubscribed ? Icons.notifications_off : Icons.notifications_active),
      label: Text(_isSubscribed ? 'Subscribed ✓' : 'Subscribe'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isSubscribed ? Colors.grey : Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Widget _buildLikeButton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => setState(() => _likeCount++),
          icon: const Icon(Icons.favorite, color: Colors.pink),
          iconSize: 32,
        ),
        Text('$_likeCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRatingWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return IconButton(
          onPressed: () => setState(() => _rating = i + 1.0),
          icon: Icon(
            i < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          iconSize: 32,
        );
      }),
    );
  }

  Widget _buildShareButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _showSnackBar('Share to Facebook'),
          icon: const Icon(Icons.facebook, color: Colors.blue),
          iconSize: 32,
        ),
        IconButton(
          onPressed: () => _showSnackBar('Share to Twitter'),
          icon: const Icon(Icons.alternate_email, color: Colors.lightBlue),
          iconSize: 32,
        ),
        IconButton(
          onPressed: () => _showSnackBar('Copy link'),
          icon: const Icon(Icons.link, color: Colors.grey),
          iconSize: 32,
        ),
      ],
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

// =============================================================================
// INLINE DECORATION DEMO
// =============================================================================

class InlineDecorationDemo extends StatelessWidget {
  const InlineDecorationDemo({super.key});

  static const html = '''
<div style="font-family: sans-serif; line-height: 1.8;">
  <h2 style="color: #795548;">Inline Background & Border</h2>
  <p>Inline decoration wraps correctly on line breaks - unlike regular RichText!</p>

  <h3>Highlight Text</h3>
  <p>
    This is normal text with
    <span style="background: #FFEB3B; padding: 2px 6px; border-radius: 4px;">
      yellow highlighted part
    </span>
    and continues with normal text.
  </p>

  <h3>Long Highlight (Multi-line)</h3>
  <p>
    <span style="background: #E1BEE7; padding: 4px 8px; border-radius: 4px;">
      This is a long text with purple background and it will wrap to a new line
      while maintaining the background on each line exactly like real CSS.
      You can see the background continues on the next line.
    </span>
  </p>

  <h3>Inline Border</h3>
  <p>
    Text with
    <span style="border: 2px solid #2196F3; padding: 2px 8px; border-radius: 4px;">
      inline border
    </span>
    that also works correctly.
  </p>

  <h3>Code Inline</h3>
  <p>
    Use <code style="background: #F5F5F5; padding: 2px 6px; border-radius: 3px; font-family: monospace;">
    const variable = "value";</code> to define a constant.
  </p>

  <h3>Multiple Colors</h3>
  <p>
    <span style="background: #BBDEFB; padding: 2px 6px;">Blue</span>
    <span style="background: #C8E6C9; padding: 2px 6px;">Green</span>
    <span style="background: #FFCCBC; padding: 2px 6px;">Orange</span>
    <span style="background: #F8BBD9; padding: 2px 6px;">Pink</span>
  </p>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Inline Decoration Demo',
      html: html,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: HyperViewer(html: html, selectable: true),
        ),
      ),
    );
  }
}

// =============================================================================
// REAL CONTENT DEMO
// =============================================================================

class RealContentDemo extends StatelessWidget {
  const RealContentDemo({super.key});

  static const html = '''
<article style="font-family: Georgia, serif; line-height: 1.8;">
  <h1 style="font-size: 28px; margin-bottom: 8px;">The Future of Flutter</h1>
  <p style="color: #666; font-style: italic; margin-bottom: 24px;">
    Published December 25, 2024 • 5 min read
  </p>

  <img src="https://picsum.photos/400/200?random=20" style="float: left; width: 200px; height: 100px; margin: 0 20px 12px 0; border-radius: 8px;" />

  <p>
    Flutter has revolutionized cross-platform development. With its unique architecture
    and powerful widget system, developers can build beautiful apps for mobile, web, and desktop
    from a single codebase.
  </p>

  <p>
    The introduction of <strong>Material 3</strong> and improved performance in recent releases
    have made Flutter even more compelling for enterprise applications.
  </p>

  <div style="clear: both;"></div>

  <h2>Key Highlights</h2>
  <ul>
    <li><strong>Single codebase</strong> for iOS, Android, Web, and Desktop</li>
    <li><strong>Hot reload</strong> for instant development feedback</li>
    <li><strong>Rich ecosystem</strong> with thousands of packages</li>
    <li><strong>Custom rendering</strong> with Impeller engine</li>
  </ul>

  <blockquote style="border-left: 4px solid #1976D2; padding-left: 16px; margin: 24px 0; font-style: italic; color: #555;">
    "Flutter represents the future of cross-platform development. Its architecture
    allows for truly native performance while maintaining code reusability."
    <br><strong>— Industry Expert</strong>
  </blockquote>

  <h2>日本語コンテンツ</h2>
  <p>
    <ruby>日本<rt>にほん</rt></ruby>の<ruby>開発者<rt>かいはつしゃ</rt></ruby>も
    Flutterを<ruby>愛用<rt>あいよう</rt></ruby>しています。
    <ruby>美<rt>うつく</rt></ruby>しいUIと<ruby>高速<rt>こうそく</rt></ruby>な
    <ruby>開発<rt>かいはつ</rt></ruby>が<ruby>可能<rt>かのう</rt></ruby>です。
  </p>

  <div style="background: #263238; padding: 20px; border-radius: 12px; text-align: center; margin-top: 32px;">
    <p style="color: white; margin: 0; font-size: 16px;">
      ⚡ Powered by <strong style="color: #4FC3F7;">HyperRender</strong>
    </p>
    <p style="color: #90A4AE; margin: 8px 0 0 0; font-size: 14px;">
      The Universal Content Engine for Flutter
    </p>
  </div>
</article>
''';

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Real Content Demo',
      html: html,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: HyperViewer(html: html, selectable: true),
        ),
      ),
    );
  }
}

// =============================================================================
// TABLE DEMO
// =============================================================================

class TableDemo extends StatelessWidget {
  const TableDemo({super.key});

  static const html = '''
<div style="font-family: sans-serif; line-height: 1.6;">
  <h2 style="color: #4CAF50;">Simple Table</h2>
  <p>A basic table with headers and borders.</p>
  <table border="1" style="border-collapse: collapse; width: 100%;">
    <tr style="background-color: #f2f2f2;">
      <th>Name</th>
      <th>Role</th>
      <th>Email</th>
    </tr>
    <tr>
      <td>John Smith</td>
      <td>Engineer</td>
      <td>john.smith@example.com</td>
    </tr>
    <tr>
      <td>John Doe</td>
      <td>Designer</td>
      <td>john.doe@example.com</td>
    </tr>
  </table>

  <h2 style="color: #FF9800; margin-top: 32px;">Wide Table (with Horizontal Scroll)</h2>
  <p>This table is wider than the screen and should scroll horizontally by default.</p>
  <table border="1" style="border-collapse: collapse;">
    <tr>
      <th>Column 1</th><th>Column 2</th><th>Column 3</th><th>Column 4</th>
      <th>Column 5</th><th>Column 6</th><th>Column 7</th><th>Column 8</th>
    </tr>
    <tr>
      <td>Data 1.1</td><td>Data 1.2</td><td>Data 1.3</td><td>Data 1.4</td>
      <td>Data 1.5</td><td>Data 1.6</td><td>Data 1.7</td><td>Data 1.8</td>
    </tr>
     <tr>
      <td>Data 2.1</td><td>Data 2.2</td><td>Data 2.3</td><td>Data 2.4</td>
      <td>Data 2.5</td><td>Data 2.6</td><td>Data 2.7</td><td>Data 2.8</td>
    </tr>
  </table>

  <h2 style="color: #E91E63; margin-top: 32px;">Complex Table with Colspan & Rowspan</h2>
   <table border="1" style="border-collapse: collapse; width: 100%;">
    <tr>
      <th colspan="2">User Info</th>
      <th rowspan="3">Notes</th>
    </tr>
    <tr>
      <td>Name</td>
      <td>John Smith</td>
    </tr>
    <tr>
      <td>Email</td>
      <td>john.smith@example.com</td>
    </tr>
     <tr>
      <td colspan="3" style="text-align: center;">A note spanning all columns</td>
    </tr>
  </table>

  <h2 style="color: #2196F3; margin-top: 32px;">Nested Table</h2>
  <p>A table nested inside another table's cell.</p>
  <table border="1" style="border-collapse: collapse; width: 100%;">
    <tr>
      <th>Main Header 1</th>
      <th>Main Header 2 (Nested Table)</th>
    </tr>
    <tr>
      <td>Main Cell 1</td>
      <td>
        <table border="1" style="border-collapse: collapse; width: 100%; background-color: #f0f8ff;">
          <tr>
            <th>Nested A</th>
            <th>Nested B</th>
          </tr>
          <tr>
            <td>Nested A1</td>
            <td>Nested B1</td>
          </tr>
          <tr>
            <td>Nested A2</td>
            <td>Nested B2</td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Table Demo',
      html: html,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: HyperViewer(html: html, selectable: true),
        ),
      ),
    );
  }
}

// =============================================================================
// CODE BLOCK DEMO
// =============================================================================

class CodeBlockDemo extends StatelessWidget {
  const CodeBlockDemo({super.key});

  static const html = '''
<div style="font-family: sans-serif; line-height: 1.8; max-width: 800px;">
  <h2 style="color: #673AB7;">Code Blocks Demo</h2>
  <p>Demonstrate <code>pre</code> and <code>code</code> elements with <strong>syntax highlighting</strong> powered by highlight.js.</p>

  <h3 style="color: #512DA8; margin-top: 24px;">Dart Code Example</h3>
  <pre><code class="language-dart">void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperRender Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}</code></pre>

  <h3 style="color: #512DA8; margin-top: 24px;">HTML Example</h3>
  <pre><code class="language-html">&lt;!DOCTYPE html&gt;
&lt;html lang="en"&gt;
&lt;head&gt;
  &lt;meta charset="UTF-8"&gt;
  &lt;title&gt;HyperRender&lt;/title&gt;
  &lt;style&gt;
    body {
      font-family: sans-serif;
      line-height: 1.6;
    }
  &lt;/style&gt;
&lt;/head&gt;
&lt;body&gt;
  &lt;h1&gt;Welcome to HyperRender&lt;/h1&gt;
  &lt;p&gt;The Universal Content Engine&lt;/p&gt;
&lt;/body&gt;
&lt;/html&gt;</code></pre>

  <h3 style="color: #512DA8; margin-top: 24px;">JavaScript Example</h3>
  <pre><code class="language-javascript">function fibonacci(n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

// Generate Fibonacci sequence
const sequence = Array.from(
  { length: 10 },
  (_, i) => fibonacci(i)
);

console.log(sequence);
// Output: [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]</code></pre>

  <h3 style="color: #512DA8; margin-top: 24px;">Python Example</h3>
  <pre><code class="language-python">def quick_sort(arr):
    """QuickSort algorithm implementation"""
    if len(arr) <= 1:
        return arr

    pivot = arr[len(arr) // 2]
    left = [x for x in arr if x &lt; pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x &gt; pivot]

    return quick_sort(left) + middle + quick_sort(right)

# Test the function
numbers = [3, 6, 8, 10, 1, 2, 1]
sorted_numbers = quick_sort(numbers)
print(sorted_numbers)  # [1, 1, 2, 3, 6, 8, 10]</code></pre>

  <h3 style="color: #512DA8; margin-top: 24px;">JSON Example</h3>
  <pre><code class="language-json">{
  "name": "hyper_render",
  "version": "1.0.0",
  "description": "Universal Content Engine",
  "dependencies": {
    "flutter": ">=3.10.0",
    "flutter_highlight": "^0.7.0"
  },
  "features": ["HTML", "Markdown", "Delta"]
}</code></pre>

  <h3 style="color: #512DA8; margin-top: 24px;">Shell Commands</h3>
  <pre><code class="language-bash"># Create a new Flutter app
flutter create my_app
cd my_app

# Run the app
flutter run

# Build for production
flutter build apk --release</code></pre>

  <h3 style="color: #512DA8; margin-top: 24px;">Inline Code</h3>
  <p>
    You can also use inline code like <code>const variable = "value";</code>
    within a paragraph. Use <code>npm install</code> to install packages,
    or run <code>flutter pub get</code> for Flutter projects.
  </p>

  <div style="background: #e8f5e9; padding: 16px; border-left: 4px solid #4caf50; margin-top: 24px; border-radius: 4px;">
    <p style="margin: 0; font-weight: bold; color: #2e7d32;">💡 Syntax Highlighting</p>
    <p style="margin: 8px 0 0 0;">Code blocks now support <strong>180+ languages</strong> with automatic syntax highlighting. Just add <code>class="language-xxx"</code> to your code tags!</p>
  </div>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Code Blocks Demo',
      html: html,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: HyperViewer(html: html, selectable: true),
        ),
      ),
    );
  }
}

// =============================================================================
// IMAGE HANDLING DEMO
// =============================================================================

class ImageHandlingDemo extends StatelessWidget {
  const ImageHandlingDemo({super.key});

  static const html = '''
<div style="font-family: sans-serif; line-height: 1.8; max-width: 800px;">
  <h2 style="color: #00ACC1;">Image Handling Demo</h2>
  <p>HyperRender automatically handles image loading, error states, and placeholders.</p>

  <h3 style="color: #00838F; margin-top: 24px;">✅ Successfully Loaded Images</h3>
  <p>These images load successfully and display normally:</p>
  <div style="display: flex; gap: 16px; flex-wrap: wrap;">
    <img src="https://picsum.photos/200/150?random=1"
         style="border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);"
         alt="Random image 1">
    <img src="https://picsum.photos/200/150?random=2"
         style="border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);"
         alt="Random image 2">
    <img src="https://picsum.photos/200/150?random=3"
         style="border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);"
         alt="Random image 3">
  </div>

  <h3 style="color: #00838F; margin-top: 24px;">⏳ Loading State</h3>
  <p>While images are loading, HyperRender shows an elegant skeleton placeholder with a gradient shimmer effect:</p>
  <ul>
    <li>Subtle gradient background (light gray)</li>
    <li>Image icon in the center</li>
    <li>Rounded corners matching the final image</li>
    <li>Border to indicate placeholder state</li>
  </ul>

  <h3 style="color: #00838F; margin-top: 24px;">❌ Error State</h3>
  <p>When an image fails to load (404, network error, etc.), HyperRender displays a broken image placeholder:</p>

  <div style="background: #fff3e0; padding: 16px; border-left: 4px solid #ff9800; margin: 16px 0; border-radius: 4px;">
    <p style="margin: 0; font-weight: bold; color: #e65100;">⚠️ The image below will fail to load</p>
    <p style="margin: 8px 0 0 0;">This demonstrates the automatic error handling:</p>
  </div>

  <img src="https://example.com/nonexistent-image-404.jpg"
       style="width: 200px; height: 150px; border-radius: 8px; margin: 16px 0;"
       alt="This image will show error placeholder">

  <p>The error placeholder shows:</p>
  <ul>
    <li>Light gray background</li>
    <li>Broken image icon with red diagonal line</li>
    <li>Maintains specified dimensions</li>
    <li>Rounded corners for consistency</li>
  </ul>

  <h3 style="color: #00838F; margin-top: 24px;">🎨 Mixed Content Example</h3>
  <p>Here's a real-world example mixing successful and failed images:</p>

  <div style="border: 1px solid #e0e0e0; padding: 16px; border-radius: 8px; margin-top: 16px;">
    <h4 style="color: #424242; margin-top: 0;">Article with Images</h4>

    <img src="https://picsum.photos/300/200?random=4"
         style="float: left; margin: 0 16px 16px 0; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);"
         alt="Article thumbnail">

    <p>This paragraph has a successfully loaded image floated to the left. The text wraps around it naturally, demonstrating HyperRender's float layout capability combined with proper image handling.</p>

    <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>

    <div style="clear: both;"></div>

    <img src="https://invalid-domain-that-does-not-exist.com/image.jpg"
         style="float: right; margin: 0 0 16px 16px; width: 200px; height: 150px; border-radius: 8px;"
         alt="This will show error placeholder">

    <p>This paragraph has an image that fails to load, floated to the right. Even with the error, the layout remains intact and the error placeholder takes the specified dimensions.</p>

    <p>The placeholder prevents layout shift and provides visual feedback that content is missing.</p>

    <div style="clear: both;"></div>
  </div>

  <h3 style="color: #00838F; margin-top: 24px;">📱 Responsive Images</h3>
  <p>Images adapt to available width while maintaining aspect ratio:</p>

  <img src="https://picsum.photos/800/400?random=5"
       style="width: 100%; max-width: 600px; height: auto; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.15);"
       alt="Responsive wide image">

  <div style="background: #e8f5e9; padding: 16px; border-left: 4px solid #4caf50; margin-top: 24px; border-radius: 4px;">
    <p style="margin: 0; font-weight: bold; color: #2e7d32;">✨ Automatic Benefits</p>
    <p style="margin: 8px 0 0 0;">
      • No manual error handling needed<br>
      • Consistent placeholder UI across all images<br>
      • Prevents layout shift during loading<br>
      • Works with floats, inline, and block images<br>
      • Maintains specified dimensions
    </p>
  </div>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Image Handling Demo',
      html: html,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: HyperViewer(html: html, selectable: true),
        ),
      ),
    );
  }
}

// =============================================================================
// ZOOM & PAN DEMO
// =============================================================================

class ZoomDemo extends StatelessWidget {
  const ZoomDemo({super.key});

  static const html = '''
<div style="font-family: sans-serif; line-height: 1.8; max-width: 800px;">
  <h2 style="color: #0288D1;">Zoom & Pan Demo</h2>
  <p>Use pinch-to-zoom or trackpad gestures to zoom in/out. Pan by dragging while zoomed.</p>

  <div style="background: #E1F5FE; padding: 16px; border-left: 4px solid #0288D1; margin: 16px 0; border-radius: 4px;">
    <p style="margin: 0; font-weight: bold; color: #01579B;">🔍 Zoom Controls</p>
    <p style="margin: 8px 0 0 0;">
      • <strong>Mobile:</strong> Pinch with two fingers to zoom in/out<br>
      • <strong>Desktop:</strong> Ctrl + Mouse Wheel to zoom<br>
      • <strong>Trackpad:</strong> Pinch gesture (two fingers)<br>
      • <strong>Pan:</strong> Drag with one finger/mouse while zoomed
    </p>
  </div>

  <h3 style="color: #0277BD; margin-top: 24px;">Try Zooming on This Content</h3>

  <img src="https://picsum.photos/600/400?random=10"
       style="width: 100%; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.15); margin: 16px 0;"
       alt="High resolution test image">

  <h3 style="color: #0277BD; margin-top: 24px;">Small Text Test</h3>
  <p style="font-size: 12px;">
    This paragraph uses smaller font size (12px). Zoom in to read it comfortably.
    Zoom functionality is especially useful for:
  </p>
  <ul style="font-size: 12px;">
    <li>Reading fine print or detailed text</li>
    <li>Viewing high-resolution images up close</li>
    <li>Inspecting code blocks or technical diagrams</li>
    <li>Accessibility for users with visual impairments</li>
  </ul>

  <h3 style="color: #0277BD; margin-top: 24px;">Code Block with Small Font</h3>
  <pre style="background: #263238; color: #EEFFFF; padding: 16px; border-radius: 8px; overflow-x: auto; font-family: 'Courier New', monospace; font-size: 11px; line-height: 1.4;"><code>// Zoom in to read this small code
class HyperViewer extends StatefulWidget {
  final bool enableZoom;
  final double minScale;
  final double maxScale;

  const HyperViewer({
    this.enableZoom = false,
    this.minScale = 0.5,
    this.maxScale = 4.0,
  });
}</code></pre>

  <h3 style="color: #0277BD; margin-top: 24px;">Float Layout with Zoom</h3>
  <img src="https://picsum.photos/200/200?random=11"
       style="float: left; margin: 0 16px 16px 0; border-radius: 50%; box-shadow: 0 2px 8px rgba(0,0,0,0.1);"
       alt="Circular image">
  <p>
    Zoom functionality works perfectly with float layouts. This circular image is floated to the left,
    and you can zoom in to see details while the text wrapping is preserved.
  </p>
  <p>
    The zoom feature uses Flutter's InteractiveViewer widget, which provides smooth pinch-to-zoom
    and pan gestures across all platforms. It's integrated seamlessly with HyperRender's custom
    rendering engine.
  </p>
  <div style="clear: both;"></div>

  <h3 style="color: #0277BD; margin-top: 24px;">Usage Example</h3>
  <pre style="background: #f5f5f5; padding: 16px; border-radius: 8px; border: 1px solid #e0e0e0; overflow-x: auto; font-family: 'Courier New', monospace; font-size: 14px;"><code>HyperViewer(
  html: htmlContent,
  enableZoom: true,      // Enable zoom
  minScale: 0.5,         // Min zoom level
  maxScale: 4.0,         // Max zoom level
  selectable: true,      // Works with selection!
)</code></pre>

  <div style="background: #E8F5E9; padding: 16px; border-left: 4px solid #4CAF50; margin-top: 24px; border-radius: 4px;">
    <p style="margin: 0; font-weight: bold; color: #2E7D32;">✨ Key Features</p>
    <p style="margin: 8px 0 0 0;">
      • Smooth pinch-to-zoom on all platforms<br>
      • Configurable min/max scale levels<br>
      • Works with text selection<br>
      • Compatible with float layouts<br>
      • Pan to navigate while zoomed<br>
      • Zero performance impact when disabled
    </p>
  </div>

  <h3 style="color: #0277BD; margin-top: 24px;">Table with Zoom</h3>
  <table style="width: 100%; border-collapse: collapse; margin: 16px 0; font-size: 14px;">
    <thead>
      <tr style="background: #0277BD; color: white;">
        <th style="border: 1px solid #ddd; padding: 12px; text-align: left;">Feature</th>
        <th style="border: 1px solid #ddd; padding: 12px; text-align: left;">Mobile</th>
        <th style="border: 1px solid #ddd; padding: 12px; text-align: left;">Desktop</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="border: 1px solid #ddd; padding: 8px;">Zoom In</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Pinch out (2 fingers)</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Ctrl + Mouse Wheel Up</td>
      </tr>
      <tr style="background: #f5f5f5;">
        <td style="border: 1px solid #ddd; padding: 8px;">Zoom Out</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Pinch in (2 fingers)</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Ctrl + Mouse Wheel Down</td>
      </tr>
      <tr>
        <td style="border: 1px solid #ddd; padding: 8px;">Pan</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Drag with 1 finger</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Click and drag</td>
      </tr>
      <tr style="background: #f5f5f5;">
        <td style="border: 1px solid #ddd; padding: 8px;">Reset</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Double tap</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Double click</td>
      </tr>
    </tbody>
  </table>

  <p style="font-size: 12px; color: #666; margin-top: 32px;">
    Zoom in on this tiny text to test accessibility. Users with visual impairments can benefit greatly
    from zoom functionality when reading small print or detailed content.
  </p>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zoom & Pan Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: Text(
                'Pinch to Zoom',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: HyperViewer(
          html: html,
          selectable: true,
          enableZoom: true,
          minScale: 0.5,
          maxScale: 4.0,
        ),
      ),
    );
  }
}

// =============================================================================
// LIBRARY COMPARISON DEMO
// =============================================================================

class LibraryComparisonDemo extends StatefulWidget {
  const LibraryComparisonDemo({super.key});

  @override
  State<LibraryComparisonDemo> createState() => _LibraryComparisonDemoState();
}

class _LibraryComparisonDemoState extends State<LibraryComparisonDemo>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Test cases for comparison
  static const List<Map<String, String>> testCases = [
    {
      'name': 'Float Layout',
      'description': 'Text wrapping around floated images (HyperRender exclusive)',
      'html': '''
<div style="font-family: sans-serif; line-height: 1.6;">
  <img src="https://picsum.photos/100/100?random=50" style="float: left; width: 100px; height: 100px; margin: 0 16px 8px 0; border-radius: 12px;" />
  <p>
    This is an example of <strong>float: left</strong>. Text should wrap around the image on the left side naturally.
    When the text is long enough, it continues below the image seamlessly.
  </p>
  <p>
    Additional paragraph that should also respect the float and continue wrapping correctly.
  </p>
</div>
''',
    },
    {
      'name': 'Table with Colspan/Rowspan',
      'description': 'Complex table layout with spanning cells',
      'html': '''
<div style="font-family: sans-serif;">
  <table border="1" style="border-collapse: collapse; width: 100%;">
    <tr style="background: #f5f5f5;">
      <th colspan="2">User Info</th>
      <th rowspan="2">Status</th>
    </tr>
    <tr style="background: #f5f5f5;">
      <th>Name</th>
      <th>Email</th>
    </tr>
    <tr>
      <td>John Doe</td>
      <td>john@example.com</td>
      <td rowspan="2" style="text-align: center; color: green;">Active</td>
    </tr>
    <tr>
      <td>Jane Smith</td>
      <td>jane@example.com</td>
    </tr>
  </table>
</div>
''',
    },
    {
      'name': 'Ruby Annotation',
      'description': 'Furigana for Japanese — HyperRender exclusive (fwfh & flutter_html show raw text)',
      'html': '''
<div style="font-family: sans-serif; line-height: 2;">
  <p style="font-size: 22px;">
    <ruby>日本語<rt>にほんご</rt></ruby>を<ruby>勉強<rt>べんきょう</rt></ruby>しています。
  </p>
  <p style="font-size: 20px;">
    <ruby>東京<rt>とうきょう</rt></ruby> • <ruby>大阪<rt>おおさか</rt></ruby> • <ruby>京都<rt>きょうと</rt></ruby>
  </p>
</div>
''',
    },
    {
      'name': 'Multiple Floats',
      'description': 'Left and right floats in same paragraph',
      'html': '''
<div style="font-family: sans-serif; line-height: 1.6;">
  <img src="https://picsum.photos/80/80?random=1" style="float: left; width: 80px; height: 80px; margin: 0 12px 8px 0; border-radius: 50%;" />
  <img src="https://picsum.photos/80/80?random=2" style="float: right; width: 80px; height: 80px; margin: 0 0 8px 12px; border-radius: 50%;" />
  <p>
    This paragraph has images floating on <strong>both sides</strong>. The text should wrap between them naturally, creating a magazine-style layout. This is a challenging layout scenario that tests the rendering engine's float handling capabilities. Additional text to make the wrapping more visible.
  </p>
</div>
''',
    },
    {
      'name': 'Inline Background',
      'description': 'Background wrapping across lines (HyperRender exclusive)',
      'html': '''
<div style="font-family: sans-serif; line-height: 1.8;">
  <p>
    Normal text with
    <span style="background: #E1BEE7; padding: 4px 8px; border-radius: 4px;">
      a highlighted span that wraps to multiple lines when the text is long enough to demonstrate proper inline background behavior
    </span>
    and continues with normal text.
  </p>
</div>
''',
    },
    {
      'name': 'CSS Specificity',
      'description': 'Cascade and inheritance test',
      'html': '''
<div style="font-family: sans-serif; color: #333;">
  <style>
    p { color: blue; }
    .special { color: red; }
    #unique { color: green; }
  </style>
  <p>Normal paragraph (should be blue)</p>
  <p class="special">Class paragraph (should be red)</p>
  <p id="unique">ID paragraph (should be green)</p>
  <p style="color: purple;">Inline style (should be purple)</p>
</div>
''',
    },
    {
      'name': 'Selection Stress',
      'description': 'Large text for selection testing',
      'html': '''
<div style="font-family: sans-serif; line-height: 1.6;">
  <p><strong>Try selecting this text!</strong> The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.</p>
  <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
  <p>Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.</p>
  <p>Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
  <p><em>flutter_widget_from_html (fwfh) crashes on SelectionArea with complex content</em></p>
</div>
''',
    },
    {
      'name': 'Wide Table Scroll',
      'description': 'Very wide table (tests horizontal scroll)',
      'html': '''
<div style="font-family: sans-serif;">
  <p style="font-size: 12px; color: #666; margin-bottom: 8px;">This table is wider than screen - try scrolling horizontally</p>
  <table border="1" style="border-collapse: collapse;">
    <tr style="background: #f5f5f5;">
      <th>Column 1</th><th>Column 2</th><th>Column 3</th><th>Column 4</th>
      <th>Column 5</th><th>Column 6</th><th>Column 7</th><th>Column 8</th>
    </tr>
    <tr>
      <td>Data 1.1</td><td>Data 1.2</td><td>Data 1.3</td><td>Data 1.4</td>
      <td>Data 1.5</td><td>Data 1.6</td><td>Data 1.7</td><td>Data 1.8</td>
    </tr>
    <tr>
      <td>Data 2.1</td><td>Data 2.2</td><td>Data 2.3</td><td>Data 2.4</td>
      <td>Data 2.5</td><td>Data 2.6</td><td>Data 2.7</td><td>Data 2.8</td>
    </tr>
  </table>
</div>
''',
    },
    {
      'name': 'Nested Lists',
      'description': 'Multi-level ordered and unordered lists',
      'html': '''
<div style="font-family: sans-serif; line-height: 1.6;">
  <ul>
    <li>First item</li>
    <li>Second item
      <ul>
        <li>Nested item 1</li>
        <li>Nested item 2</li>
      </ul>
    </li>
    <li>Third item</li>
  </ul>
  <ol>
    <li>Ordered first</li>
    <li>Ordered second</li>
    <li>Ordered third</li>
  </ol>
</div>
''',
    },
    {
      'name': '<details>/<summary>',
      'description': 'Collapsible sections — HyperRender exclusive (fwfh & flutter_html show flat text)',
      'html': '''
<div style="font-family: sans-serif; line-height: 1.6;">
  <details>
    <summary>What is HyperRender?</summary>
    <p>HyperRender is a high-performance HTML/Markdown/Delta rendering engine for Flutter, built on a custom RenderObject rather than the Flutter widget tree.</p>
  </details>
  <details open>
    <summary>Why not use flutter_html?</summary>
    <p>flutter_html does not support CSS floats, ruby annotations, or the &lt;details&gt; element. It also has performance issues with large documents.</p>
  </details>
  <details>
    <summary>When to use fwfh?</summary>
    <p>Use flutter_widget_from_html for moderate complexity HTML where you need a stable, plugin-extensible library. Avoid text selection on large documents as it crashes.</p>
  </details>
</div>
''',
    },
  ];

  int _currentTestIndex = 0;
  final Map<String, Duration> _renderTimes = {};

  String _getExpectedBehavior(int index) {
    switch (index) {
      case 0: // Float Layout
        return '✅ HyperRender: Text wraps around image | ❌ flutter_html, fwfh: No float support — image stacks above text';
      case 1: // Table colspan/rowspan
        return '✅ HyperRender, fwfh: Proper colspan/rowspan | ⚠️ flutter_html: Basic cells only — spanning cells may break';
      case 2: // Ruby Annotation
        return '✅ HyperRender only: rt text renders above base | ❌ flutter_html: rt text appears inline (garbled) | ❌ fwfh: ruby treated as plain text';
      case 3: // Multiple Floats
        return '✅ HyperRender: Text wraps between both floats | ❌ flutter_html, fwfh: Both images stack vertically';
      case 4: // Inline Background
        return '✅ HyperRender: Highlight wraps across lines | ❌ flutter_html, fwfh: Background applied to full block (rectangular)';
      case 5: // CSS Specificity
        return '✅ HyperRender: Full cascade (element → class → ID → inline) | ⚠️ fwfh: Class selectors work, ID unreliable | ❌ flutter_html: <style> tag often ignored';
      case 6: // Selection Stress
        return '✅ HyperRender: Crash-free continuous selection | ⚠️ flutter_html: Works but selection breaks at widget boundaries | ❌ fwfh: Crashes on SelectionArea with complex content';
      case 7: // Wide Table Scroll
        return '✅ HyperRender: Table auto-scales down (FittedBox, min 60%) | ❌ flutter_html, fwfh: Table overflows container';
      case 8: // Nested Lists
        return '✅ HyperRender, fwfh: Proper indentation and markers | ⚠️ flutter_html: Indentation may be inconsistent';
      case 9: // Details/Summary
        return '✅ HyperRender only: Interactive collapsible with open/close | ❌ flutter_html, fwfh: <details> not supported — content shown as plain text';
      default:
        return 'Compare rendering across libraries';
    }
  }

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
    final testCase = testCases[_currentTestIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Comparison'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'HyperRender'),
            Tab(text: 'flutter_html'),
            Tab(text: 'fwfh'),
            Tab(text: 'fwfh_core'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Test case selector
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        value: _currentTestIndex,
                        isExpanded: true,
                        items: testCases.asMap().entries.map((e) {
                          return DropdownMenuItem(
                            value: e.key,
                            child: Text('${e.key + 1}/${testCases.length}: ${e.value['name']!}'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _currentTestIndex = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  testCase['description']!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getExpectedBehavior(_currentTestIndex),
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHyperRenderTab(testCase['html']!),
                _buildFlutterHtmlTab(testCase['html']!),
                _buildFwfhTab(testCase['html']!),
                _buildFwfhCoreTab(testCase['html']!),
              ],
            ),
          ),

          // Feature comparison table
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Feature Support:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildFeatureTable(),
                const SizedBox(height: 12),
                _buildPerformanceChart(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHyperRenderTab(String html) {
    return _buildTimedWidget(
      'HyperRender',
      () {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: HyperViewer(
            html: html,
            mode: HyperRenderMode.sync,
            selectable: true, // Enable text selection for testing
          ),
        );
      },
    );
  }

  Widget _buildFlutterHtmlTab(String html) {
    return _buildTimedWidget(
      'flutter_html',
      () => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: flutter_html.Html(data: html),
      ),
    );
  }

  Widget _buildFwfhTab(String html) {
    return _buildTimedWidget(
      'fwfh',
      () => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: fwfh.HtmlWidget(html),
      ),
    );
  }

  Widget _buildFwfhCoreTab(String html) {
    return _buildTimedWidget(
      'fwfh_core',
      () => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: fwfh_core.HtmlWidget(html),
      ),
    );
  }

  Widget _buildTimedWidget(String name, Widget Function() builder) {
    final stopwatch = Stopwatch()..start();
    final widget = builder();
    stopwatch.stop();
    _renderTimes[name] = stopwatch.elapsed;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.timer, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 4),
              Text(
                'Build: ${stopwatch.elapsedMicroseconds}µs',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
              ),
            ],
          ),
        ),
        Expanded(child: widget),
      ],
    );
  }

  Widget _buildFeatureTable() {
    // Format: (Feature, HyperRender, flutter_html, fwfh, fwfh_core)
    // Accuracy: verified against library source, GitHub issues, and live rendering
    const features = [
      ('Float layout', true, false, false, false),
      ('Table colspan/rowspan', true, false, true, true),
      ('Ruby / furigana', true, false, false, false),   // fwfh #1449 — not supported
      ('Multiple floats', true, false, false, false),
      ('Inline bg wrap', true, false, false, false),
      ('<style> tag CSS', true, false, true, true),     // flutter_html ignores; fwfh partial
      ('CSS specificity', true, false, true, true),     // fwfh partial; flutter_html minimal
      ('<details>/<summary>', true, false, false, false), // HyperRender exclusive
      ('Selection (no crash)', true, true, false, false), // fwfh crashes; flutter_html OK
      ('Custom widgets', true, true, true, true),
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: const [
            Padding(
              padding: EdgeInsets.all(4),
              child: Text('Feature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            Center(child: Text('HR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Center(child: Text('f_h', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Center(child: Text('fwfh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Center(child: Text('core', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          ],
        ),
        ...features.map((f) => TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(f.$1, style: const TextStyle(fontSize: 11)),
                ),
                _buildCheckmark(f.$2),
                _buildCheckmark(f.$3),
                _buildCheckmark(f.$4),
                _buildCheckmark(f.$5),
              ],
            )),
      ],
    );
  }

  Widget _buildCheckmark(bool supported) {
    return Center(
      child: Icon(
        supported ? Icons.check_circle : Icons.cancel,
        size: 16,
        color: supported ? Colors.green : Colors.red.shade300,
      ),
    );
  }

  Widget _buildPerformanceChart() {
    if (_renderTimes.isEmpty) return const SizedBox.shrink();
    final hyperTime = _renderTimes['HyperRender'];
    final htmlTime = _renderTimes['flutter_html'];
    final fwfhTime = _renderTimes['fwfh'];
    final fwfhCoreTime = _renderTimes['fwfh_core'];
    final maxTime = [hyperTime, htmlTime, fwfhTime, fwfhCoreTime]
        .whereType<Duration>()
        .map((d) => d.inMicroseconds)
        .fold(1, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Widget-tree build time (µs):',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text(
          'Measures Dart widget construction only — actual layout/paint is async.',
          style: TextStyle(fontSize: 10, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        _buildLibBar('HyperRender', hyperTime, maxTime, Colors.green),
        _buildLibBar('flutter_html', htmlTime, maxTime, Colors.orange),
        _buildLibBar('fwfh', fwfhTime, maxTime, Colors.blue),
        _buildLibBar('fwfh_core', fwfhCoreTime, maxTime, Colors.purple),
      ],
    );
  }

  Widget _buildLibBar(String name, Duration? time, int maxUs, Color color) {
    final us = time?.inMicroseconds ?? 0;
    final ratio = maxUs > 0 ? us / maxUs : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(name, style: const TextStyle(fontSize: 11)),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio.clamp(0.02, 1.0),
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 52,
            child: Text('$usµs',
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// STRESS TEST DEMO
// =============================================================================

class StressTestDemo extends StatefulWidget {
  const StressTestDemo({super.key});

  @override
  State<StressTestDemo> createState() => _StressTestDemoState();
}

class _StressTestDemoState extends State<StressTestDemo> {
  int _pageCount = 100;
  String _selectedLibrary = 'HyperRender';
  bool _isGenerating = false;
  String? _generatedContent;
  int? _characterCount;

  final List<int> pageCounts = [10, 50, 100, 500, 1000];
  final List<String> libraries = ['HyperRender', 'flutter_html', 'fwfh', 'fwfh_core'];

  static String _generateBookContent(int pages) {
    final buffer = StringBuffer();
    buffer.write('<article style="font-family: Georgia, serif; line-height: 1.8;">');
    buffer.write('<h1 style="text-align: center; margin-bottom: 24px;">📚 Generated Novel</h1>');
    buffer.write('<p style="text-align: center; color: #666; margin-bottom: 32px;">');
    buffer.write('$pages pages • Stress Test Content</p>');

    final paragraphs = [
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
      'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
      'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.',
      'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.',
      'Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.',
      '<ruby>日本語<rt>にほんご</rt></ruby>の<ruby>文章<rt>ぶんしょう</rt></ruby>を<ruby>完璧<rt>かんぺき</rt></ruby>に<ruby>表示<rt>ひょうじ</rt></ruby>できます。これは<ruby>多言語<rt>たげんご</rt></ruby>サポートのテストです。',
      'Vietnamese is fully supported. This is Vietnamese text to test the display of special characters and diacritics.',
    ];

    int paragraphsPerPage = 4;
    int totalParagraphs = pages * paragraphsPerPage;

    for (int i = 0; i < totalParagraphs; i++) {
      if (i % paragraphsPerPage == 0) {
        int pageNum = (i ~/ paragraphsPerPage) + 1;
        if (pageNum > 1) {
          buffer.write('<hr style="margin: 32px 0; border: none; border-top: 1px solid #ddd;" />');
        }
        buffer.write('<h2 style="color: #1976D2; margin: 24px 0 16px 0;">Chapter $pageNum</h2>');

        // Add occasional float images
        if (pageNum % 5 == 1) {
          buffer.write('<img src="https://picsum.photos/80/80?random=$pageNum" ');
          buffer.write('style="float: left; width: 80px; height: 80px; margin: 0 16px 8px 0; border-radius: 8px;" />');
        }
      }

      String paragraph = paragraphs[i % paragraphs.length];
      buffer.write('<p style="margin: 12px 0; text-align: justify;">$paragraph</p>');

      // Occasionally add styled elements
      if (i % 7 == 0) {
        buffer.write('<p style="background: #FFF3E0; padding: 12px; border-radius: 8px; margin: 16px 0;">');
        buffer.write('<strong>Note:</strong> This is a highlighted note section for page ${(i ~/ paragraphsPerPage) + 1}.');
        buffer.write('</p>');
      }
    }

    buffer.write('<div style="text-align: center; margin-top: 48px; padding: 24px; background: #263238; border-radius: 12px;">');
    buffer.write('<p style="color: white; margin: 0; font-size: 18px;">📖 The End</p>');
    buffer.write('<p style="color: #90A4AE; margin: 8px 0 0 0;">$pages pages rendered successfully</p>');
    buffer.write('</div>');
    buffer.write('</article>');

    return buffer.toString();
  }

  Future<void> _generateAndRender() async {
    setState(() => _isGenerating = true);

    // Generate content asynchronously to avoid blocking UI
    final content = await compute(_generateBookContent, _pageCount);

    if (mounted) {
      setState(() {
        _generatedContent = content;
        _characterCount = content.length;
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stress Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_generatedContent != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {
                _generatedContent = null;
                _characterCount = null;
              }),
              tooltip: 'Reset',
            ),
        ],
      ),
      body: _generatedContent == null ? _buildConfigPanel() : _buildRenderPanel(),
    );
  }

  Widget _buildConfigPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade700, Colors.orange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.speed, color: Colors.white, size: 40),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stress Test',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Test performance with long content',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Page count selector
          const Text(
            'Number of Pages:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: pageCounts.map((count) {
              final isSelected = _pageCount == count;
              return ChoiceChip(
                label: Text('$count'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _pageCount = count);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Library selector
          const Text(
            'Library:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: libraries.map((lib) {
              final isSelected = _selectedLibrary == lib;
              return ChoiceChip(
                label: Text(lib),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedLibrary = lib);
                },
              );
            }).toList(),
          ),

          const Spacer(),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateAndRender,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isGenerating ? 'Generating...' : 'Start Stress Test'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenderPanel() {
    return Column(
      children: [
        // Stats bar
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade100,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Pages', '$_pageCount'),
                  _buildStat('Chars', '${(_characterCount ?? 0) ~/ 1000}K'),
                  _buildStat('Library', _selectedLibrary),
                ],
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _buildRenderedContent(),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildRenderedContent() {
    final content = _generatedContent!;

    switch (_selectedLibrary) {
      case 'HyperRender':
        return HyperViewer(
          html: content,
          mode: HyperRenderMode.auto,
          selectable: true,
          placeholderBuilder: (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Parsing ${(_characterCount ?? 0) ~/ 1000}K characters...',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This may take a few seconds for large documents',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      case 'flutter_html':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: flutter_html.Html(data: content),
        );
      case 'fwfh':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: fwfh.HtmlWidget(content),
        );
      case 'fwfh_core':
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: fwfh_core.HtmlWidget(content),
        );
      default:
        return const Center(child: Text('Unknown library'));
    }
  }
}

// =============================================================================
// QUILL DELTA DEMO
// =============================================================================

class QuillDeltaDemo extends StatelessWidget {
  const QuillDeltaDemo({super.key});

  /// Sample Quill Delta JSON demonstrating various features
  static const deltaJson = '''
{
  "ops": [
    { "insert": "Building a Real-time Chat App with Flutter\\n", "attributes": { "header": 1 } },
    { "insert": "A comprehensive guide to implementing WebSocket-based messaging\\n", "attributes": { "color": "#666666", "italic": true } },
    { "insert": "\\n" },

    { "insert": "Introduction\\n", "attributes": { "header": 2 } },
    { "insert": "In this tutorial, we'll build a " },
    { "insert": "production-ready", "attributes": { "bold": true, "color": "#E91E63" } },
    { "insert": " chat application using " },
    { "insert": "Flutter", "attributes": { "bold": true, "color": "#02569B" } },
    { "insert": " and " },
    { "insert": "WebSockets", "attributes": { "bold": true, "color": "#FF6F00" } },
    { "insert": ". This is the same architecture used by apps like " },
    { "insert": "Slack", "attributes": { "italic": true, "link": "https://slack.com" } },
    { "insert": ", " },
    { "insert": "Discord", "attributes": { "italic": true, "link": "https://discord.com" } },
    { "insert": ", and " },
    { "insert": "WhatsApp", "attributes": { "italic": true, "link": "https://whatsapp.com" } },
    { "insert": ".\\n\\n" },

    { "insert": "Prerequisites\\n", "attributes": { "header": 2 } },
    { "insert": "Flutter SDK 3.0+", "attributes": { "bold": true } },
    { "insert": " - Latest stable version recommended" },
    { "insert": "\\n", "attributes": { "list": "bullet" } },
    { "insert": "Dart 3.0+", "attributes": { "bold": true } },
    { "insert": " - With null safety enabled" },
    { "insert": "\\n", "attributes": { "list": "bullet" } },
    { "insert": "Basic knowledge of ", "attributes": {} },
    { "insert": "async/await", "attributes": { "background": "#FFF3E0", "color": "#E65100" } },
    { "insert": " patterns" },
    { "insert": "\\n", "attributes": { "list": "bullet" } },
    { "insert": "Familiarity with ", "attributes": {} },
    { "insert": "Provider", "attributes": { "background": "#E3F2FD", "color": "#1565C0" } },
    { "insert": " or " },
    { "insert": "Riverpod", "attributes": { "background": "#E8F5E9", "color": "#2E7D32" } },
    { "insert": " state management" },
    { "insert": "\\n", "attributes": { "list": "bullet" } },
    { "insert": "\\n" },

    { "insert": "Key Features We'll Implement\\n", "attributes": { "header": 2 } },
    { "insert": "Real-time messaging with WebSocket", "attributes": {} },
    { "insert": "\\n", "attributes": { "list": "ordered" } },
    { "insert": "Message persistence with SQLite", "attributes": {} },
    { "insert": "\\n", "attributes": { "list": "ordered" } },
    { "insert": "Push notifications (FCM)", "attributes": {} },
    { "insert": "\\n", "attributes": { "list": "ordered" } },
    { "insert": "Typing indicators & read receipts", "attributes": {} },
    { "insert": "\\n", "attributes": { "list": "ordered" } },
    { "insert": "Image & file sharing", "attributes": {} },
    { "insert": "\\n", "attributes": { "list": "ordered" } },
    { "insert": "End-to-end encryption ", "attributes": {} },
    { "insert": "(E2EE)", "attributes": { "bold": true, "color": "#D32F2F" } },
    { "insert": "\\n", "attributes": { "list": "ordered" } },
    { "insert": "\\n" },

    { "insert": "The beauty of simplicity is that it allows complexity to emerge naturally.\\n", "attributes": {} },
    { "insert": "— John Maeda, The Laws of Simplicity", "attributes": { "italic": true } },
    { "insert": "\\n", "attributes": { "blockquote": true } },
    { "insert": "\\n" },

    { "insert": "Architecture Overview\\n", "attributes": { "header": 2 } },
    { "insert": "Our app follows the ", "attributes": {} },
    { "insert": "Clean Architecture", "attributes": { "bold": true } },
    { "insert": " pattern with three main layers:\\n\\n" },

    { "insert": "Presentation Layer", "attributes": { "header": 3 } },
    { "insert": "\\nWidgets, Pages, and State Management. Uses " },
    { "insert": "BLoC pattern", "attributes": { "background": "#FCE4EC", "color": "#C2185B" } },
    { "insert": " for reactive UI updates.\\n\\n" },

    { "insert": "Domain Layer", "attributes": { "header": 3 } },
    { "insert": "\\nBusiness logic, Use Cases, and Entities. " },
    { "insert": "Framework-independent", "attributes": { "underline": true } },
    { "insert": " - can be tested without Flutter.\\n\\n" },

    { "insert": "Data Layer", "attributes": { "header": 3 } },
    { "insert": "\\nRepositories, Data Sources, and Models. Handles " },
    { "insert": "API calls", "attributes": { "italic": true } },
    { "insert": ", " },
    { "insert": "caching", "attributes": { "italic": true } },
    { "insert": ", and " },
    { "insert": "local storage", "attributes": { "italic": true } },
    { "insert": ".\\n\\n" },

    { "insert": "Core Implementation\\n", "attributes": { "header": 2 } },
    { "insert": "Here's our WebSocket service implementation:\\n\\n" },
    { "insert": "class ChatWebSocket {\\n  late WebSocketChannel _channel;\\n  final _messageController = StreamController<Message>.broadcast();\\n  \\n  Stream<Message> get messages => _messageController.stream;\\n  \\n  Future<void> connect(String url, String token) async {\\n    _channel = WebSocketChannel.connect(\\n      Uri.parse(url),\\n      protocols: ['chat-protocol'],\\n    );\\n    \\n    // Authenticate\\n    _channel.sink.add(jsonEncode({'type': 'auth', 'token': token}));\\n    \\n    // Listen for messages\\n    _channel.stream.listen(\\n      (data) => _handleMessage(jsonDecode(data)),\\n      onError: (e) => _handleError(e),\\n      onDone: () => _handleDisconnect(),\\n    );\\n  }\\n  \\n  void sendMessage(String roomId, String content) {\\n    _channel.sink.add(jsonEncode({\\n      'type': 'message',\\n      'roomId': roomId,\\n      'content': content,\\n      'timestamp': DateTime.now().toIso8601String(),\\n    }));\\n  }\\n}" },
    { "insert": "\\n", "attributes": { "code-block": "dart" } },
    { "insert": "\\n" },

    { "insert": "Performance Metrics\\n", "attributes": { "header": 2 } },
    { "insert": "Our implementation achieves impressive benchmarks:\\n\\n" },

    { "insert": "Message Latency", "attributes": { "bold": true } },
    { "insert": "\\n" },
    { "insert": "< 50ms", "attributes": { "size": "large", "color": "#4CAF50", "bold": true } },
    { "insert": " average round-trip time" },
    { "insert": "\\n", "attributes": { "align": "center" } },
    { "insert": "\\n" },

    { "insert": "Memory Usage", "attributes": { "bold": true } },
    { "insert": "\\n" },
    { "insert": "~15MB", "attributes": { "size": "large", "color": "#2196F3", "bold": true } },
    { "insert": " with 10,000 cached messages" },
    { "insert": "\\n", "attributes": { "align": "center" } },
    { "insert": "\\n" },

    { "insert": "Battery Impact", "attributes": { "bold": true } },
    { "insert": "\\n" },
    { "insert": "< 2%", "attributes": { "size": "large", "color": "#FF9800", "bold": true } },
    { "insert": " per hour of active use" },
    { "insert": "\\n", "attributes": { "align": "center" } },
    { "insert": "\\n\\n" },

    { "insert": "Important Security Note\\n", "attributes": { "header": 2 } },
    { "insert": "Never store API keys or tokens in client-side code!", "attributes": { "bold": true, "color": "#D32F2F" } },
    { "insert": " Use secure token exchange via your backend server. All sensitive operations should be validated server-side." },
    { "insert": "\\n", "attributes": { "blockquote": true } },
    { "insert": "\\n" },

    { "insert": { "image": "https://picsum.photos/600/300" } },
    { "insert": "\\n" },
    { "insert": "Figure 1: App architecture diagram showing data flow between layers", "attributes": { "italic": true, "color": "#666666", "size": "small" } },
    { "insert": "\\n", "attributes": { "align": "center" } },
    { "insert": "\\n\\n" },

    { "insert": "What's Next?\\n", "attributes": { "header": 2 } },
    { "insert": "In " },
    { "insert": "Part 2", "attributes": { "bold": true, "link": "#part2" } },
    { "insert": ", we'll implement:\\n" },
    { "insert": "Message encryption with ", "attributes": {} },
    { "insert": "libsodium", "attributes": { "background": "#FFEBEE", "color": "#B71C1C" } },
    { "insert": "\\n", "attributes": { "list": "bullet" } },
    { "insert": "Offline-first sync with ", "attributes": {} },
    { "insert": "Drift", "attributes": { "background": "#E8EAF6", "color": "#283593" } },
    { "insert": "\\n", "attributes": { "list": "bullet" } },
    { "insert": "Push notifications via ", "attributes": {} },
    { "insert": "Firebase Cloud Messaging", "attributes": { "background": "#FFF8E1", "color": "#FF6F00" } },
    { "insert": "\\n", "attributes": { "list": "bullet" } },
    { "insert": "\\n\\n" },

    { "insert": "This Delta content was rendered with ", "attributes": { "color": "#666666" } },
    { "insert": "HyperRender", "attributes": { "bold": true, "color": "#6200EE" } },
    { "insert": " - demonstrating full Quill.js compatibility!", "attributes": { "color": "#666666" } },
    { "insert": "\\n" }
  ]
}
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quill Delta Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'View Delta JSON',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delta JSON'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        deltaJson,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: HyperViewer.delta(
            delta: deltaJson,
            selectable: true,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MARKDOWN DEMO
// =============================================================================

class MarkdownDemo extends StatelessWidget {
  const MarkdownDemo({super.key});

  static const markdown = '''
# Flutter State Management: A Complete Guide

> **Last updated:** December 2024 | **Reading time:** 12 min | **Level:** Intermediate

State management is one of the most discussed topics in Flutter development. This guide covers everything from basic concepts to advanced patterns used in production apps.

---

## Table of Contents

1. [Understanding State](#understanding-state)
2. [Built-in Solutions](#built-in-solutions)
3. [Popular Libraries](#popular-libraries)
4. [Comparison & Benchmarks](#comparison)
5. [Best Practices](#best-practices)

---

## Understanding State

In Flutter, **state** refers to any data that can change over time and affects what the UI displays. There are two types:

### Ephemeral State
- *Local* to a single widget
- Examples: current page in PageView, animation progress
- Solution: `StatefulWidget` + `setState()`

### App State
- *Shared* across multiple widgets
- Examples: user authentication, shopping cart, preferences
- Solution: State management libraries

> 💡 **Rule of thumb:** If you need to access the same state from multiple places in your widget tree, it's probably app state.

---

## Built-in Solutions

### InheritedWidget

The foundation of Flutter's reactivity system:

```dart
class AppState extends InheritedWidget {
  final int counter;
  final VoidCallback increment;

  const AppState({
    required this.counter,
    required this.increment,
    required Widget child,
  }) : super(child: child);

  static AppState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppState>()!;
  }

  @override
  bool updateShouldNotify(AppState oldWidget) {
    return counter != oldWidget.counter;
  }
}
```

### ValueNotifier + ValueListenableBuilder

Great for simple reactive values:

```dart
final counter = ValueNotifier<int>(0);

ValueListenableBuilder<int>(
  valueListenable: counter,
  builder: (context, value, child) {
    return Text('Count: \$value');
  },
)
```

---

## Popular Libraries

### Provider / Riverpod

The **recommended** solution by the Flutter team:

| Feature | Provider | Riverpod |
|---------|----------|----------|
| Compile-time safety | ❌ | ✅ |
| No BuildContext needed | ❌ | ✅ |
| Auto-dispose | Manual | ✅ |
| Testing | Good | Excellent |
| Learning curve | Low | Medium |

```dart
// Riverpod example
final counterProvider = StateProvider<int>((ref) => 0);

class CounterWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('Count: \$count');
  }
}
```

### BLoC / Cubit

**Business Logic Component** - great for complex apps:

```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
  void reset() => emit(0);
}

// In widget
BlocBuilder<CounterCubit, int>(
  builder: (context, count) {
    return Text('Count: \$count');
  },
)
```

### GetX

Minimalist approach with maximum features:

```dart
class Controller extends GetxController {
  var count = 0.obs;
  void increment() => count++;
}

// In widget - no builder needed!
Obx(() => Text('Count: \${controller.count}'))
```

---

## Performance Benchmarks

We tested each solution with 10,000 state updates:

| Library | Avg. Rebuild Time | Memory | Bundle Size |
|---------|-------------------|--------|-------------|
| setState | 0.8ms | Low | 0 KB |
| Provider | 1.2ms | Low | +12 KB |
| Riverpod | 1.1ms | Low | +45 KB |
| BLoC | 1.5ms | Medium | +89 KB |
| GetX | 0.9ms | Medium | +120 KB |
| MobX | 1.8ms | High | +200 KB |

> ⚠️ **Note:** These benchmarks are synthetic. Real-world performance depends on your specific use case.

---

## Best Practices

### ✅ Do

- **Keep state minimal** - Only store what you need
- **Separate concerns** - UI state vs business logic
- **Use selectors** - Rebuild only what changed
- **Test your state** - Unit test state logic separately

### ❌ Don't

- ~~Put everything in global state~~
- ~~Mix UI logic with business logic~~
- ~~Ignore memory leaks~~ (dispose your controllers!)
- ~~Over-engineer simple apps~~

---

## Decision Flowchart

```
Is state used by single widget?
├─ YES → setState() or ValueNotifier
└─ NO → Is it a simple app?
        ├─ YES → Provider
        └─ NO → Do you need strong typing?
                ├─ YES → Riverpod or BLoC
                └─ NO → GetX (if you prefer simplicity)
```

---

## Real-world Example

Here's how **Instagram-like** feed would be structured with Riverpod:

```dart
// Providers
final feedProvider = FutureProvider<List<Post>>((ref) async {
  final api = ref.read(apiProvider);
  return api.fetchFeed();
});

final likedPostsProvider = StateProvider<Set<String>>((ref) => {});

// Derived state
final isLikedProvider = Provider.family<bool, String>((ref, postId) {
  final likedPosts = ref.watch(likedPostsProvider);
  return likedPosts.contains(postId);
});

// Widget
class FeedScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);

    return feedAsync.when(
      data: (posts) => ListView.builder(
        itemCount: posts.length,
        itemBuilder: (_, i) => PostCard(post: posts[i]),
      ),
      loading: () => const ShimmerList(),
      error: (e, _) => ErrorWidget(message: e.toString()),
    );
  }
}
```

---

## Additional Resources

- 📚 [Official Flutter Docs](https://flutter.dev/docs/development/data-and-backend/state-mgmt)
- 🎥 [Flutter State Management - Video Course](https://example.com)
- 💬 [Flutter Community Discord](https://discord.gg/flutter)
- 📦 [Awesome Flutter](https://github.com/Solido/awesome-flutter)

---

![Architecture Diagram](https://picsum.photos/600/350)
*Figure: Clean Architecture with State Management layers*

---

*This Markdown content was rendered with* ***HyperRender*** *- demonstrating full GitHub Flavored Markdown support including tables, code blocks, task lists, and more!*
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'View Markdown Source',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Markdown Source'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        markdown,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: HyperViewer.markdown(
            markdown: markdown,
            selectable: true,
          ),
        ),
      ),
    );
  }
}

class VideoDemo extends StatelessWidget {
  const VideoDemo({super.key});

  @override
  Widget build(BuildContext context) {
    print('🚨🚨🚨 [VideoDemo] BUILD CALLED - YOU SHOULD SEE THIS! 🚨🚨🚨');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video & Media Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Video Placeholder with DefaultMediaWidget',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'HyperRender provides beautiful default placeholders for video elements. '
            'Hover over videos to see animations!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Video with poster
          const Text('Video with Poster Image:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          HyperViewer(
            html: '''
              <video
                src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                poster="https://peach.blender.org/wp-content/uploads/title_anouncement.jpg"
                width="640"
                height="360"
                controls>
              </video>
            ''',
            onLinkTap: (url) async {
              print('✅ [VideoDemo] TAP CALLBACK CALLED! URL: $url');
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 24),
          
          // Video without poster
          const Text('Video without Poster:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          HyperViewer(
            html: '''
              <video
                src="https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4"
                width="640"
                height="360"
                controls>
              </video>
            ''',
            onLinkTap: (url) async {
              print('✅ [VideoDemo] TAP CALLBACK CALLED! URL: $url');
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 24),
          
          // Multiple videos in grid
          const Text('Video Grid Layout:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          HyperViewer(
            html: '''
              <div style="display: flex; gap: 16px; flex-wrap: wrap;">
                <video
                  src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
                  poster="https://storage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg"
                  width="300"
                  height="200"
                  controls>
                </video>

                <video
                  src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
                  poster="https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg"
                  width="300"
                  height="200"
                  controls>
                </video>

                <video
                  src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"
                  poster="https://storage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg"
                  width="300"
                  height="200"
                  controls>
                </video>
              </div>
            ''',
            onLinkTap: (url) async {
              print('✅ [VideoDemo] TAP CALLBACK CALLED! URL: $url');
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 24),
          
          // Floated video with text wrapping
          const Text('Float Layout with Video (Unique Feature!):', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          HyperViewer(
            html: '''
              <h2>Article with Floated Video</h2>

              <video
                src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4"
                poster="https://storage.googleapis.com/gtv-videos-bucket/sample/images/WeAreGoingOnBullrun.jpg"
                width="320"
                height="180"
                style="float: left; margin-right: 16px; margin-bottom: 8px;"
                controls>
              </video>

              <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit.
              Text wraps naturally around the floated video, just like in a web browser!
              This is a unique feature that flutter_widget_from_html struggles with.</p>

              <p>Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
              Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.</p>

              <p>Duis aute irure dolor in reprehenderit in voluptate velit esse
              cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat
              non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>

              <div style="clear: both;"></div>

              <p>After clearing the float, text returns to normal width.</p>
            ''',
            selectable: true,
            onLinkTap: (url) async {
              print('✅ [VideoDemo] TAP CALLBACK CALLED! URL: $url');
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 24),
          
          // Info card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'About Video Support',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Default placeholders show play button with hover effects\n'
                    '• Poster images are supported and displayed beautifully\n'
                    '• Float layout works perfectly with videos (unique!)\n'
                    '• For actual playback, integrate video_player package\n'
                    '• See MULTIMEDIA_EXAMPLES.md for integration guide',
                    style: TextStyle(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Video URLs used
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Free Video URLs Used:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Big Buck Bunny - Blender Foundation\n'
                    '• Butterfly - Flutter assets\n'
                    '• Elephants Dream - Google GTV samples\n'
                    '• For Bigger Blazes - Google GTV samples\n'
                    '• Sintel - Blender Foundation\n'
                    '• We Are Going On Bullrun - Google GTV samples',
                    style: TextStyle(fontSize: 12, height: 1.8),
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
