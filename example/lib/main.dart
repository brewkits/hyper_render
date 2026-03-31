import 'dart:async';

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
import 'demo_colors.dart';
import 'performance_deep_dive_demo.dart';
import 'animation_demo.dart';
import 'sprint3_demo.dart';
import 'html_heuristics_demo.dart';
import 'smart_table_demo.dart';
import 'formula_demo.dart';
import 'manga_demo.dart';
import 'cjk_languages_demo.dart';
import 'email_demo.dart';
import 'stress_test_demo.dart';
import 'why_hyper_render_demo.dart';
import 'enterprise_features_demo.dart';
import 'paged_mode_demo.dart';
import 'plugin_api_demo.dart';
import 'reader_app/library_screen.dart';

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
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      150 << 20; // 150 MB for demo images

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
          const SizedBox(height: 16),
          _buildWhyCard(context),
          const SizedBox(height: 8),
          // ── Highlights ────────────────────────────────────────────────────
          _buildSectionHeader(context, 'Highlights'),
          _buildDemoCard(
            context,
            icon: Icons.view_quilt,
            title: 'Float Layout',
            subtitle:
                'Text wraps around floated images — the feature no other Flutter HTML library has',
            color: DemoColors.primary,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FloatLayoutDemo())),
          ),
          _buildDemoCard(
            context,
            icon: Icons.email,
            title: 'HTML Email',
            subtitle:
                'Render real HTML emails natively — no WebView, no heavy dependencies',
            color: DemoColors.primary,
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const EmailDemo())),
          ),
          // ── Applications ──────────────────────────────────────────────────
          _buildSectionHeader(context, 'Applications & Solutions'),
          _buildDemoCard(
            context,
            icon: Icons.auto_stories,
            title: 'HyperReader App',
            subtitle:
                'Full e-book solution with paged mode, themes, and library management',
            color: Colors.deepPurple,
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const LibraryScreen())),
          ),
          // ── Layout ────────────────────────────────────────────────────────
          _buildSectionHeader(context, 'Layout'),
          _buildDemoCard(
            context,
            icon: Icons.table_chart,
            title: 'Tables',
            subtitle:
                'Simple, wide, nested tables — plus strategies for tables wider than the screen',
            color: DemoColors.secondary,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const _TablesHubPage())),
          ),
          _buildDemoCard(
            context,
            icon: Icons.view_column,
            title: 'Flexbox',
            subtitle:
                'CSS flexbox in pure Flutter — row/column, wrapping, alignment, gap',
            color: DemoColors.secondary,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FlexboxDemo())),
          ),
          _buildDemoCard(
            context,
            icon: Icons.rocket_launch,
            title: 'CSS Grid & Advanced Layout',
            subtitle:
                'CSS variables, grid, calc(), SVG, RTL/BiDi text, screenshot export',
            color: DemoColors.secondary,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const Sprint3Demo())),
          ),
          _buildDemoCard(
            context,
            icon: Icons.menu_book_outlined,
            title: 'Paged Mode',
            subtitle:
                'PageView-based e-book / reader UI — one section per page with HyperPageController navigation',
            color: DemoColors.secondary,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PagedModeDemo())),
          ),
          _buildDemoCard(
            context,
            icon: Icons.extension,
            title: 'Plugin API',
            subtitle:
                'Render custom HTML tags as Flutter widgets — block and inline tiers (v1.2.0)',
            color: DemoColors.secondary,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PluginApiDemo())),
          ),
          // ── Text & Typography ─────────────────────────────────────────────
          _buildSectionHeader(context, 'Text & Typography'),
          _buildDemoCard(
            context,
            icon: Icons.select_all,
            title: 'Text Selection',
            subtitle:
                'Long-press to select, drag handles to resize, Copy/Share/Search menu',
            color: DemoColors.accent,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EnhancedSelectionDemo())),
          ),
          _buildDemoCard(
            context,
            icon: Icons.menu_book,
            title: 'Japanese & Manga Typography',
            subtitle:
                'Furigana (ruby), vertical text, manga panel grid — Japanese content',
            color: const Color(0xFFB71C1C),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const MangaDemo())),
          ),
          _buildDemoCard(
            context,
            icon: Icons.language,
            title: '中文 · 繁體 · 한국어',
            subtitle:
                'Simplified Chinese, Traditional Chinese poetry, Korean tech article — CJK rendering',
            color: const Color(0xFF1565C0),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CjkLanguagesDemo())),
          ),
          _buildDemoCard(
            context,
            icon: Icons.style,
            title: 'CSS Properties',
            subtitle:
                'text-shadow, text-overflow, border styles, writing direction, 60+ properties',
            color: DemoColors.accent,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CssPropertiesDemo())),
          ),
          // ── Media & Integration ───────────────────────────────────────────
          _buildSectionHeader(context, 'Media & Integration'),
          _buildDemoCard(
            context,
            icon: Icons.perm_media,
            title: 'Images & Video',
            subtitle:
                'Image loading/fallback, pinch-to-zoom and pan, video thumbnail player',
            color: DemoColors.warning,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const _MediaHubPage())),
          ),
          _buildDemoCard(
            context,
            icon: Icons.widgets,
            title: 'Widget Injection & Animation',
            subtitle:
                'Embed live Flutter widgets and animated components inside HTML content',
            color: DemoColors.warning,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const _WidgetIntegrationHubPage())),
          ),
          _buildDemoCard(
            context,
            icon: Icons.data_object,
            title: 'Input Formats',
            subtitle:
                'Render Markdown and Quill Delta (rich-text editor JSON output)',
            color: DemoColors.warning,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const _InputFormatsHubPage())),
          ),
          _buildDemoCard(
            context,
            icon: Icons.calculate,
            title: 'Math Formulas',
            subtitle:
                'Greek letters, fractions, physics equations via custom widget builder',
            color: DemoColors.warning,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FormulaDemo())),
          ),
          // ── Advanced & Quality ────────────────────────────────────────────
          _buildSectionHeader(context, 'Advanced & Quality'),
          _buildDemoCard(
            context,
            icon: Icons.compare,
            title: 'Comparison & Performance',
            subtitle:
                'Side-by-side vs other libraries, unique features, stress test, render pipeline',
            color: DemoColors.success,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const _ComparisonPerfHubPage())),
          ),
          _buildDemoCard(
            context,
            icon: Icons.dark_mode,
            title: 'Dark Mode, Skeletons & Visual Quality',
            subtitle:
                'Theme switching, skeleton loading, error boundaries, crisp rendering',
            color: DemoColors.success,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const V21Showcase())),
          ),
          _buildDemoCard(
            context,
            icon: Icons.security,
            title: 'Security & Accessibility',
            subtitle:
                'XSS protection, screen reader support, WebView fallback detection',
            color: DemoColors.success,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const _QualityHubPage())),
          ),
          _buildDemoCard(
            context,
            icon: Icons.business_center,
            title: 'Enterprise Features',
            subtitle:
                'GPU resource safety, error routing, device tuning, deeplink security, zoom modes',
            color: const Color(0xFF1A237E),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EnterpriseFeaturesDemo())),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade700, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const WhyHyperRenderDemo())),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.emoji_events,
                    color: Color(0xFF4E2600), size: 32),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why HyperRender?',
                        style: TextStyle(
                          color: Color(0xFF4E2600),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Live demos · Feature matrix · 16/16 score vs other libraries',
                        style: TextStyle(
                            color: Color(0xFF7A3E00),
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '16/16',
                    style: TextStyle(
                        color: Color(0xFF4E2600),
                        fontWeight: FontWeight.w800,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.rocket_launch,
                    color: Colors.white, size: 30),
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
                        color: Colors.white,
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
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
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
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade400, size: 22),
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
<div style="font-family: sans-serif; line-height: 1.6;">
  <div style="background: #667eea; padding: 24px; border-radius: 16px; margin-bottom: 24px;">
    <h1 style="color: white; margin: 0;">🚀 HyperRender Engine</h1>
    <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0 0;">The Universal Content Engine for Flutter</p>
  </div>

  <h2 style="color: #1976D2; border-left: 4px solid #1976D2; padding-left: 12px;">1. Float Layout</h2>
  <div style="margin: 16px 0;">
    <img src="https://picsum.photos/100/100?random=1" style="float: left; width: 100px; height: 100px; margin: 0 16px 8px 0; border-radius: 12px;" />
    <p style="margin: 0;">
      This is an example of <strong style="color: #E91E63;">Float Layout</strong>. This text will automatically
      wrap around the image on the left. HyperRender uses the IFC algorithm like web browsers.
    </p>
  </div>
  <div style="clear: both; height: 16px;"></div>

  <h2 style="color: #9C27B0; border-left: 4px solid #9C27B0; padding-left: 12px;">2. Widget Injection</h2>
  <div style="text-align: center; margin: 16px 0; padding: 16px; background: #FFF3E0; border-radius: 12px;">
    <p style="margin: 0 0 12px 0; font-weight: bold;">🔔 Subscribe to receive notifications!</p>
    <subscribe-button></subscribe-button>
  </div>

  <h2 style="color: #00BCD4; border-left: 4px solid #00BCD4; padding-left: 12px;">3. Ruby Annotation</h2>
  <div style="background: #E0F7FA; padding: 16px; border-radius: 12px; margin: 16px 0;">
    <p style="font-size: 20px; margin: 0;">
      <ruby>日本語<rt>にほんご</rt></ruby>の<ruby>文章<rt>ぶんしょう</rt></ruby>を
      <ruby>完璧<rt>かんぺき</rt></ruby>に<ruby>表示<rt>ひょうじ</rt></ruby>できます。
    </p>
  </div>

  <h2 style="color: #607D8B; border-left: 4px solid #607D8B; padding-left: 12px;">4. Text Selection</h2>
  <div style="background: #ECEFF1; padding: 16px; border-radius: 12px;">
    <p style="margin: 0;">👆 <strong>Long press</strong> on text to show Copy menu!</p>
    <p style="margin: 8px 0 0 0;">Or drag to select, then long press to copy.</p>
  </div>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Sink Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
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
      icon: Icon(
          isSubscribed ? Icons.notifications_off : Icons.notifications_active),
      label: Text(isSubscribed ? 'Subscribed' : 'Subscribe'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSubscribed ? Colors.grey : Colors.redAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1)),
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
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        _showSnackBar(
            '🚀 Opening: ${uri.toString().length > 40 ? '${uri.toString().substring(0, 40)}...' : uri.toString()}');
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
<div style="font-family: sans-serif; line-height: 1.6;">
  <h2 style="color: #1976D2;">Float Left</h2>
  <div style="margin: 16px 0;">
    <img src="https://picsum.photos/120/120?random=10" style="float: left; width: 120px; height: 120px; margin: 0 16px 8px 0; border-radius: 12px;" />
    <p>
      This is an example of <strong>float: left</strong>. Text will automatically wrap around the image on the left.
      When the text is long enough, it will continue below the image naturally. This is a feature
      that flutter_html and flutter_widget_from_html do NOT support.
    </p>
    <p>
      HyperRender uses the IFC (Inline Formatting Context) algorithm like real web browsers
      to calculate the remaining space of each line and fill it with text fragments.
    </p>
  </div>

  <div style="clear: both; height: 32px;"></div>

  <h2 style="color: #9C27B0;">Float Right</h2>
  <div style="margin: 16px 0;">
    <img src="https://picsum.photos/100/100?random=11" style="float: right; width: 100px; height: 100px; margin: 0 0 8px 16px; border-radius: 50%;" />
    <p>
      Float also works on the <strong>right side</strong>! This circle floats right and text
      will fill the empty space on the left naturally.
    </p>
    <p>
      Try rotating the screen to see how smoothly the layout adapts.
    </p>
  </div>

  <div style="clear: both; height: 32px;"></div>

  <h2 style="color: #E91E63;">Left + Right</h2>
  <div style="margin: 16px 0;">
    <img src="https://picsum.photos/90/90?random=20" style="float: left; width: 90px; height: 90px; margin: 0 14px 8px 0; border-radius: 8px;" />
    <img src="https://picsum.photos/90/90?random=21" style="float: right; width: 90px; height: 90px; margin: 0 0 8px 14px; border-radius: 8px;" />
    <p>
      Hai ảnh ở <strong>hai phía</strong> — một float left, một float right. Văn bản tự động
      lấp đầy khoảng giữa. Layout engine phải tính toán đồng thời cả hai float boundary
      để xác định vùng hợp lệ cho từng dòng chữ.
    </p>
    <p>
      Đây là layout kiểu <em>tạp chí</em> — ảnh ghim hai góc, nội dung chảy ở giữa.
    </p>
  </div>

  <div style="clear: both; height: 32px;"></div>

  <h2 style="color: #FF5722;">Multiple Left Floats</h2>
  <div style="margin: 16px 0;">
    <img src="https://picsum.photos/80/80?random=12" style="float: left; width: 80px; height: 80px; margin: 0 12px 8px 0; border-radius: 8px;" />
    <img src="https://picsum.photos/80/80?random=13" style="float: left; width: 80px; height: 80px; margin: 0 12px 8px 0; border-radius: 8px;" />
    <p>
      Nhiều ảnh float left xếp cạnh nhau. Văn bản wrap quanh toàn bộ cụm ảnh.
      Đây là cách hiển thị ảnh theo hàng ngang trong bài viết.
    </p>
  </div>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Float Layout Demo',
      html: html,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: HyperViewer(html: html, selectable: true),
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
        child: HyperViewer(html: html, selectable: true),
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
<div style="font-family: sans-serif; line-height: 2;">
  <h2 style="color: #E91E63;">Ruby Annotation (振り仮名)</h2>
  <p>Ruby annotation hiển thị reading aids (furigana) phía trên kanji.</p>

  <div style="background: #FCE4EC; padding: 16px; border-radius: 12px; margin: 16px 0;">
    <h3 style="margin: 0 0 12px 0;">基本的な例 (Basic Examples)</h3>
    <p style="font-size: 22px; margin: 8px 0;">
      <ruby>日本語<rt>にほんご</rt></ruby>を<ruby>勉強<rt>べんきょう</rt></ruby>しています。
    </p>
    <p style="color: #666; font-size: 14px; margin: 0;">= I am studying Japanese.</p>
  </div>

  <div style="background: #E8F5E9; padding: 16px; border-radius: 12px; margin: 16px 0;">
    <h3 style="margin: 0 0 12px 0;">文学作品 (Literature)</h3>
    <p style="font-size: 20px; margin: 8px 0; font-style: italic;">
      <ruby>吾輩<rt>わがはい</rt></ruby>は<ruby>猫<rt>ねこ</rt></ruby>である。
      <ruby>名前<rt>なまえ</rt></ruby>はまだない。
    </p>
    <p style="color: #666; font-size: 14px; margin: 0;">— 夏目漱石「吾輩は猫である」</p>
  </div>

  <div style="background: #E3F2FD; padding: 16px; border-radius: 12px; margin: 16px 0;">
    <h3 style="margin: 0 0 12px 0;">地名 (Place Names)</h3>
    <p style="font-size: 20px; margin: 4px 0;">
      <ruby>東京<rt>とうきょう</rt></ruby> •
      <ruby>大阪<rt>おおさか</rt></ruby> •
      <ruby>京都<rt>きょうと</rt></ruby> •
      <ruby>北海道<rt>ほっかいどう</rt></ruby>
    </p>
  </div>

  <div style="background: #FFF3E0; padding: 16px; border-radius: 12px; margin: 16px 0;">
    <h3 style="margin: 0 0 12px 0;">中文拼音 (Chinese Pinyin)</h3>
    <p style="font-size: 20px; margin: 4px 0;">
      <ruby>你好<rt>nǐ hǎo</rt></ruby> •
      <ruby>谢谢<rt>xiè xiè</rt></ruby> •
      <ruby>中国<rt>zhōng guó</rt></ruby>
    </p>
  </div>
</div>
''';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruby Annotation Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Padding(
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
      icon: Icon(
          _isSubscribed ? Icons.notifications_off : Icons.notifications_active),
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
        Text('$_likeCount',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
        child: HyperViewer(html: html, selectable: true),
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
        child: HyperViewer(html: html, selectable: true),
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

  <!-- ── 1. Basic styled table ─────────────────────────────────────────── -->
  <h2 style="color: #1976D2;">Basic Table</h2>
  <p>Header row, alternating row colors, full-width.</p>
  <table style="border-collapse: collapse; width: 100%;">
    <thead>
      <tr style="background: #1976D2; color: white;">
        <th style="padding: 10px 14px; text-align: left;">Name</th>
        <th style="padding: 10px 14px; text-align: left;">Role</th>
        <th style="padding: 10px 14px; text-align: left;">Status</th>
        <th style="padding: 10px 14px; text-align: left;">Joined</th>
      </tr>
    </thead>
    <tbody>
      <tr style="background: #ffffff;">
        <td style="padding: 8px 14px; border-bottom: 1px solid #e0e0e0;">Alice Chen</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e0e0e0;">Engineer</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e0e0e0;"><span style="background:#e8f5e9;color:#2e7d32;padding:2px 8px;border-radius:12px;font-size:13px;">Active</span></td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e0e0e0;">2022-03</td>
      </tr>
      <tr style="background: #f8f9fa;">
        <td style="padding: 8px 14px; border-bottom: 1px solid #e0e0e0;">Bob Kim</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e0e0e0;">Designer</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e0e0e0;"><span style="background:#fff8e1;color:#f57f17;padding:2px 8px;border-radius:12px;font-size:13px;">Away</span></td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e0e0e0;">2021-11</td>
      </tr>
      <tr style="background: #ffffff;">
        <td style="padding: 8px 14px; border-bottom: 1px solid #e0e0e0;">Carol Smith</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e0e0e0;">Product</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e0e0e0;"><span style="background:#e8f5e9;color:#2e7d32;padding:2px 8px;border-radius:12px;font-size:13px;">Active</span></td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e0e0e0;">2023-01</td>
      </tr>
      <tr style="background: #f8f9fa;">
        <td style="padding: 8px 14px;">Dan Park</td>
        <td style="padding: 8px 14px;">DevOps</td>
        <td style="padding: 8px 14px;"><span style="background:#fce4ec;color:#c62828;padding:2px 8px;border-radius:12px;font-size:13px;">Offline</span></td>
        <td style="padding: 8px 14px;">2020-06</td>
      </tr>
    </tbody>
  </table>

  <!-- ── 2. Colspan & Rowspan ───────────────────────────────────────────── -->
  <h2 style="color: #7B1FA2; margin-top: 32px;">Colspan &amp; Rowspan</h2>
  <p>Cells can span multiple columns or rows — used in schedules, reports, invoices.</p>
  <table style="border-collapse: collapse; width: 100%; border: 1px solid #ce93d8;">
    <tr style="background: #7B1FA2; color: white;">
      <th style="padding: 10px; border: 1px solid #ce93d8;" colspan="3">Q1 Sales Report</th>
      <th style="padding: 10px; border: 1px solid #ce93d8;" rowspan="2">YoY Change</th>
    </tr>
    <tr style="background: #f3e5f5;">
      <th style="padding: 8px 12px; border: 1px solid #ce93d8;">Region</th>
      <th style="padding: 8px 12px; border: 1px solid #ce93d8;">Jan</th>
      <th style="padding: 8px 12px; border: 1px solid #ce93d8;">Feb</th>
    </tr>
    <tr>
      <td style="padding: 8px 12px; border: 1px solid #e0e0e0;">North</td>
      <td style="padding: 8px 12px; border: 1px solid #e0e0e0;">\$12,000</td>
      <td style="padding: 8px 12px; border: 1px solid #e0e0e0;">\$14,500</td>
      <td style="padding: 8px 12px; border: 1px solid #e0e0e0; color: #2e7d32; font-weight: bold;">+21%</td>
    </tr>
    <tr style="background: #fafafa;">
      <td style="padding: 8px 12px; border: 1px solid #e0e0e0;">South</td>
      <td style="padding: 8px 12px; border: 1px solid #e0e0e0;">\$9,800</td>
      <td style="padding: 8px 12px; border: 1px solid #e0e0e0;">\$11,200</td>
      <td style="padding: 8px 12px; border: 1px solid #e0e0e0; color: #2e7d32; font-weight: bold;">+14%</td>
    </tr>
    <tr>
      <td style="padding: 8px 12px; border: 1px solid #e0e0e0; font-weight: bold;" colspan="2">Total</td>
      <td style="padding: 8px 12px; border: 1px solid #e0e0e0; font-weight: bold;">\$25,700</td>
      <td style="padding: 8px 12px; border: 1px solid #e0e0e0; font-weight: bold; color: #2e7d32;">+18%</td>
    </tr>
  </table>

  <!-- ── 3. Inline rich content in cells ───────────────────────────────── -->
  <h2 style="color: #E65100; margin-top: 32px;">Rich Content in Cells</h2>
  <p>Cells can contain <strong>bold</strong>, <em>italic</em>, <a href="#">links</a>, <code>code</code>, and inline badges.</p>
  <table style="border-collapse: collapse; width: 100%; border: 1px solid #ffccbc;">
    <thead>
      <tr style="background: #E65100; color: white;">
        <th style="padding: 10px 14px; text-align: left;">Package</th>
        <th style="padding: 10px 14px; text-align: left;">Version</th>
        <th style="padding: 10px 14px; text-align: left;">Notes</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="padding: 8px 14px; border-bottom: 1px solid #ffe0b2;"><code style="background:#fff3e0;padding:2px 6px;border-radius:4px;">hyper_render</code></td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #ffe0b2;"><strong>4.0.0</strong></td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #ffe0b2;">Current — <em>no WebView needed</em></td>
      </tr>
      <tr style="background: #fafafa;">
        <td style="padding: 8px 14px; border-bottom: 1px solid #ffe0b2;"><code style="background:#fff3e0;padding:2px 6px;border-radius:4px;">flutter_html</code></td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #ffe0b2;">3.0.0</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #ffe0b2;"><span style="background:#fce4ec;color:#c62828;padding:2px 8px;border-radius:12px;font-size:12px;">No float support</span></td>
      </tr>
      <tr>
        <td style="padding: 8px 14px;"><code style="background:#fff3e0;padding:2px 6px;border-radius:4px;">fwfh</code></td>
        <td style="padding: 8px 14px;">0.15.0</td>
        <td style="padding: 8px 14px;"><span style="background:#fce4ec;color:#c62828;padding:2px 8px;border-radius:12px;font-size:12px;">No ruby / details</span></td>
      </tr>
    </tbody>
  </table>

  <!-- ── 4. Nested table ───────────────────────────────────────────────── -->
  <h2 style="color: #00695C; margin-top: 32px;">Nested Table</h2>
  <p>A full table inside a table cell — the inner table renders completely.</p>
  <table style="border-collapse: collapse; width: 100%; border: 1px solid #b2dfdb;">
    <thead>
      <tr style="background: #00695C; color: white;">
        <th style="padding: 10px 14px; text-align: left;">Department</th>
        <th style="padding: 10px 14px; text-align: left;">Members</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="padding: 10px 14px; border-bottom: 1px solid #e0f2f1; vertical-align: top; font-weight: bold;">Engineering</td>
        <td style="padding: 10px 14px; border-bottom: 1px solid #e0f2f1;">
          <table style="border-collapse: collapse; width: 100%; background: #f0fffe;">
            <tr style="background: #b2dfdb;">
              <th style="padding: 5px 10px; text-align: left; font-size: 13px;">Name</th>
              <th style="padding: 5px 10px; text-align: left; font-size: 13px;">Level</th>
            </tr>
            <tr>
              <td style="padding: 5px 10px; border-top: 1px solid #e0f2f1; font-size: 13px;">Alice Chen</td>
              <td style="padding: 5px 10px; border-top: 1px solid #e0f2f1; font-size: 13px;">Senior</td>
            </tr>
            <tr>
              <td style="padding: 5px 10px; border-top: 1px solid #e0f2f1; font-size: 13px;">Bob Kim</td>
              <td style="padding: 5px 10px; border-top: 1px solid #e0f2f1; font-size: 13px;">Mid</td>
            </tr>
          </table>
        </td>
      </tr>
      <tr style="background: #fafafa;">
        <td style="padding: 10px 14px; vertical-align: top; font-weight: bold;">Design</td>
        <td style="padding: 10px 14px;">
          <table style="border-collapse: collapse; width: 100%; background: #fffde7;">
            <tr style="background: #fff9c4;">
              <th style="padding: 5px 10px; text-align: left; font-size: 13px;">Name</th>
              <th style="padding: 5px 10px; text-align: left; font-size: 13px;">Level</th>
            </tr>
            <tr>
              <td style="padding: 5px 10px; border-top: 1px solid #f0e0a0; font-size: 13px;">Carol Smith</td>
              <td style="padding: 5px 10px; border-top: 1px solid #f0e0a0; font-size: 13px;">Lead</td>
            </tr>
          </table>
        </td>
      </tr>
    </tbody>
  </table>

  <!-- ── 5. Pricing / comparison table ─────────────────────────────────── -->
  <h2 style="color: #1565C0; margin-top: 32px;">Pricing Table</h2>
  <p>Common real-world table pattern with mixed alignment and styled cells.</p>
  <table style="border-collapse: collapse; width: 100%; border: 1px solid #bbdefb;">
    <thead>
      <tr style="background: #1565C0; color: white;">
        <th style="padding: 10px 14px; text-align: left;">Feature</th>
        <th style="padding: 10px 14px; text-align: center;">Free</th>
        <th style="padding: 10px 14px; text-align: center; background: #1976D2;">Pro</th>
        <th style="padding: 10px 14px; text-align: center;">Enterprise</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e3f2fd;">HTML rendering</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e3f2fd; text-align: center; color: #2e7d32;">✓</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e3f2fd; text-align: center; color: #2e7d32; background: #e3f2fd;">✓</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e3f2fd; text-align: center; color: #2e7d32;">✓</td>
      </tr>
      <tr style="background: #fafafa;">
        <td style="padding: 8px 14px; border-bottom: 1px solid #e3f2fd;">Float layout</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e3f2fd; text-align: center; color: #c62828;">✗</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e3f2fd; text-align: center; color: #2e7d32; background: #e3f2fd;">✓</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e3f2fd; text-align: center; color: #2e7d32;">✓</td>
      </tr>
      <tr>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e3f2fd;">Widget injection</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e3f2fd; text-align: center; color: #c62828;">✗</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e3f2fd; text-align: center; color: #2e7d32; background: #e3f2fd;">✓</td>
        <td style="padding: 8px 14px; border-bottom: 1px solid #e3f2fd; text-align: center; color: #2e7d32;">✓</td>
      </tr>
      <tr style="background: #fafafa;">
        <td style="padding: 8px 14px;">Priority support</td>
        <td style="padding: 8px 14px; text-align: center; color: #c62828;">✗</td>
        <td style="padding: 8px 14px; text-align: center; color: #c62828; background: #e3f2fd;">✗</td>
        <td style="padding: 8px 14px; text-align: center; color: #2e7d32;">✓</td>
      </tr>
    </tbody>
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
        child: HyperViewer(html: html, selectable: true),
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
        child: HyperViewer(html: html, selectable: true),
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
<div style="font-family: sans-serif; line-height: 1.8; padding: 4px;">

  <h2 style="color: #00ACC1; margin-top: 0;">Image Handling</h2>
  <p style="color: #555;">HyperRender shows a shimmer skeleton while loading and a broken-image placeholder on failure.</p>

  <!-- ── Success: inline images, no flex/gap needed ── -->
  <h3 style="color: #00838F; margin-top: 20px;">✅ Network Images (loading + success)</h3>
  <p style="font-size:13px; color:#666;">Shimmer placeholder appears while each image loads:</p>

  <img src="https://picsum.photos/seed/hr1/180/130"
       style="width:180px; height:130px; border-radius:8px; margin:0 10px 10px 0;"
       alt="Image 1">
  <img src="https://picsum.photos/seed/hr2/180/130"
       style="width:180px; height:130px; border-radius:8px; margin:0 10px 10px 0;"
       alt="Image 2">
  <img src="https://picsum.photos/seed/hr3/180/130"
       style="width:180px; height:130px; border-radius:8px; margin:0 0 10px 0;"
       alt="Image 3">

  <!-- ── Intentional error ── -->
  <h3 style="color: #D32F2F; margin-top: 20px;">❌ Error Placeholder (intentional 404)</h3>
  <div style="background:#FFF3E0; padding:10px 14px; border-left:4px solid #FF9800; border-radius:4px; margin-bottom:12px;">
    <p style="margin:0; font-size:13px; color:#E65100;">
      The URL below intentionally returns 404 — showing the broken-image placeholder.
    </p>
  </div>
  <img src="https://example.com/nonexistent-image-404.jpg"
       style="width:180px; height:130px; border-radius:8px;"
       alt="Intentional 404 error">
  <p style="font-size:12px; color:#999; margin-top:4px;">
    ↑ Error placeholder: gray background + broken-image icon, dimensions preserved.
  </p>

  <!-- ── Float layout: good left + bad right ── -->
  <h3 style="color: #00838F; margin-top: 20px;">🖼 Float Layout + Mixed Results</h3>
  <div style="border:1px solid #E0E0E0; padding:14px; border-radius:8px; overflow:hidden;">

    <img src="https://picsum.photos/seed/hr4/160/120"
         style="float:left; width:160px; height:120px; border-radius:8px; margin:0 14px 8px 0;"
         alt="Float left — success">
    <p style="margin:0; font-size:14px;">
      <strong>Left:</strong> network image, loads successfully. Text wraps around it using HyperRender's float engine.
    </p>
    <div style="clear:both; height:10px;"></div>

    <img src="https://invalid-domain-xyz-fail.com/missing.jpg"
         style="float:right; width:160px; height:120px; border-radius:8px; margin:0 0 8px 14px;"
         alt="Float right — fail">
    <p style="margin:0; font-size:14px;">
      <strong>Right:</strong> invalid domain — shows error placeholder. Layout stays intact; placeholder holds the specified 160×120 space.
    </p>
    <div style="clear:both;"></div>
  </div>

  <!-- ── Full-width image — explicit height, NOT height:auto ── -->
  <h3 style="color: #00838F; margin-top: 20px;">📐 Full-Width Image</h3>
  <p style="font-size:13px; color:#666; margin-bottom:8px;">
    Use explicit <code>height</code> values — <code>height:auto</code> is not supported and renders as 0px.
  </p>
  <img src="https://picsum.photos/seed/hr5/800/240"
       style="width:100%; height:200px; border-radius:8px;"
       alt="Wide image">

  <!-- ── Summary ── -->
  <div style="background:#E8F5E9; padding:14px; border-left:4px solid #4CAF50; margin-top:20px; border-radius:4px;">
    <strong style="color:#2E7D32;">✨ Automatic Benefits</strong>
    <p style="margin:8px 0 0; font-size:13px; color:#424242; line-height:1.8;">
      • Shimmer skeleton while loading<br>
      • Broken-image placeholder on failure<br>
      • Dimensions preserved — no layout shift<br>
      • Works with float, inline, and block images<br>
      • <strong>Note:</strong> always use explicit <code>height</code>, not <code>height:auto</code>
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
        child: HyperViewer(html: html, selectable: true),
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
      'description':
          'Text wrapping around floated images (HyperRender exclusive)',
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
      'description':
          'Furigana for Japanese — HyperRender exclusive (fwfh & flutter_html show raw text)',
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
      'name': '4-Corner Floats',
      'description':
          '4 images pinned to each corner with text filling the middle',
      'html': '''
<div style="font-family: sans-serif; line-height: 1.6;">
  <img src="https://picsum.photos/90/90?random=41" style="float: left; width: 90px; height: 90px; margin: 0 14px 10px 0; border-radius: 8px;" />
  <img src="https://picsum.photos/90/90?random=42" style="float: right; width: 90px; height: 90px; margin: 0 0 10px 14px; border-radius: 8px;" />
  <p>
    Two images anchor the <strong>top corners</strong>. Text flows naturally in the space between them, respecting both left and right float boundaries at the same time. This tests simultaneous multi-float layout.
  </p>
  <img src="https://picsum.photos/90/90?random=43" style="float: left; width: 90px; height: 90px; margin: 0 14px 0 0; border-radius: 8px;" />
  <img src="https://picsum.photos/90/90?random=44" style="float: right; width: 90px; height: 90px; margin: 0 0 0 14px; border-radius: 8px;" />
  <p>
    Two more images anchor the <strong>bottom corners</strong>. The middle column of text continues to wrap correctly even when four floats are active across two rows. This is the most complex float scenario.
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
      'description':
          'Collapsible sections — HyperRender exclusive (fwfh & flutter_html show flat text)',
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
  bool _showInfoPanel = false;

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
                            child: Text(
                                '${e.key + 1}/${testCases.length}: ${e.value['name']!}'),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _currentTestIndex = v!),
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
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getExpectedBehavior(_currentTestIndex),
                          style: TextStyle(
                              fontSize: 11, color: Colors.blue.shade900),
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

          // Feature comparison table (collapsible)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle button row
                InkWell(
                  onTap: () => setState(() => _showInfoPanel = !_showInfoPanel),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.table_chart_outlined,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Feature Comparison',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _showInfoPanel
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showInfoPanel)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeatureTable(),
                          const SizedBox(height: 12),
                          _buildPerformanceChart(),
                        ],
                      ),
                    ),
                  ),
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
        return HyperViewer(
          html: html,
          mode: HyperRenderMode.sync,
          selectable: true,
        );
      },
    );
  }

  Widget _buildFlutterHtmlTab(String html) {
    return _buildTimedWidget(
      'flutter_html',
      () => ClipRect(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: flutter_html.Html(data: html),
        ),
      ),
    );
  }

  Widget _buildFwfhTab(String html) {
    return _buildTimedWidget(
      'fwfh',
      () => ClipRect(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: fwfh.HtmlWidget(html),
        ),
      ),
    );
  }

  Widget _buildFwfhCoreTab(String html) {
    return _buildTimedWidget(
      'fwfh_core',
      () => ClipRect(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: fwfh_core.HtmlWidget(html),
        ),
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
      (
        'Ruby / furigana',
        true,
        false,
        false,
        false
      ), // fwfh #1449 — not supported
      ('Multiple floats', true, false, false, false),
      ('Inline bg wrap', true, false, false, false),
      (
        '<style> tag CSS',
        true,
        false,
        true,
        true
      ), // flutter_html ignores; fwfh partial
      (
        'CSS specificity',
        true,
        false,
        true,
        true
      ), // fwfh partial; flutter_html minimal
      (
        '<details>/<summary>',
        true,
        false,
        false,
        false
      ), // HyperRender exclusive
      (
        'Selection (no crash)',
        true,
        true,
        false,
        false
      ), // fwfh crashes; flutter_html OK
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
              child: Text('Feature',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            Center(
                child: Text('HR',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Center(
                child: Text('f_h',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Center(
                child: Text('fwfh',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Center(
                child: Text('core',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
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
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: HyperViewer.delta(
          delta: deltaJson,
          selectable: true,
          showSelectionMenu: false,
          onError: (e, st) => debugPrint('QuillDeltaDemo error: $e\n$st'),
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
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: HyperViewer.markdown(
          markdown: markdown,
          selectable: true,
          showSelectionMenu: false,
          onError: (e, st) => debugPrint('MarkdownDemo error: $e\n$st'),
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
          const Text('Video with Poster Image:',
              style: TextStyle(fontWeight: FontWeight.bold)),
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
              
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.platformDefault);
              }
            },
          ),
          const SizedBox(height: 24),

          // Video without poster
          const Text('Video without Poster:',
              style: TextStyle(fontWeight: FontWeight.bold)),
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
              
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.platformDefault);
              }
            },
          ),
          const SizedBox(height: 24),

          // Multiple videos in grid
          const Text('Video Grid Layout:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          HyperViewer(
            html: '''
              <div style="display: flex; gap: 16px; flex-wrap: wrap;">
                <video
                  src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
                  poster="https://picsum.photos/seed/elephants/300/200"
                  width="300"
                  height="200"
                  controls>
                </video>

                <video
                  src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
                  poster="https://picsum.photos/seed/blazes/300/200"
                  width="300"
                  height="200"
                  controls>
                </video>

                <video
                  src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"
                  poster="https://picsum.photos/seed/sintel/300/200"
                  width="300"
                  height="200"
                  controls>
                </video>
              </div>
            ''',
            onLinkTap: (url) async {
              
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.platformDefault);
              }
            },
          ),
          const SizedBox(height: 24),

          // Floated video with text wrapping
          const Text('Float Layout with Video (Unique Feature!):',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          HyperViewer(
            html: '''
              <h2>Article with Floated Video</h2>

              <video
                src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4"
                poster="https://picsum.photos/seed/bullrun/320/180"
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
              
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.platformDefault);
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

// =============================================================================
// HUB PAGES — sub-navigation screens grouping related demos
// =============================================================================

Widget _hubCard(
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
            offset: const Offset(0, 2)),
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
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                            letterSpacing: -0.1)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade300, size: 22),
            ],
          ),
        ),
      ),
    ),
  );
}

AppBar _hubAppBar(BuildContext context, String title) => AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: true,
    );

class _TablesHubPage extends StatelessWidget {
  const _TablesHubPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _hubAppBar(context, 'Tables'),
      backgroundColor: const Color(0xFFF5F5F7),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hubCard(context,
              icon: Icons.table_chart,
              title: 'Basic Tables',
              subtitle:
                  'Simple, wide, nested, and complex tables with auto column sizing',
              color: DemoColors.primary,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TableDemo()))),
          _hubCard(context,
              icon: Icons.table_chart_outlined,
              title: 'Wide Table Strategies',
              subtitle:
                  'Tables wider than the screen — scroll, shrink-to-fit, or auto scale',
              color: Colors.teal,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SmartTableDemo()))),
        ],
      ),
    );
  }
}

class _MediaHubPage extends StatelessWidget {
  const _MediaHubPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _hubAppBar(context, 'Images & Video'),
      backgroundColor: const Color(0xFFF5F5F7),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hubCard(context,
              icon: Icons.broken_image,
              title: 'Images',
              subtitle:
                  'Loading placeholders, error fallback, network and asset images',
              color: DemoColors.warning,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ImageHandlingDemo()))),
          _hubCard(context,
              icon: Icons.zoom_in,
              title: 'Zoom & Pan',
              subtitle:
                  'Pinch to zoom and pan images — works with float and inline images',
              color: DemoColors.warning,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ZoomDemo()))),
          _hubCard(context,
              icon: Icons.play_circle_filled,
              title: 'Video',
              subtitle:
                  'Video thumbnail with play button — tap to open in external player',
              color: DemoColors.warning,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ImprovedVideoDemo()))),
        ],
      ),
    );
  }
}

class _WidgetIntegrationHubPage extends StatelessWidget {
  const _WidgetIntegrationHubPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _hubAppBar(context, 'Widget Injection & Animation'),
      backgroundColor: const Color(0xFFF5F5F7),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hubCard(context,
              icon: Icons.widgets,
              title: 'Widget Injection',
              subtitle:
                  'Embed live Flutter widgets (charts, buttons, sliders) inside HTML content',
              color: DemoColors.secondary,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WidgetInjectionDemo()))),
          _hubCard(context,
              icon: Icons.animation,
              title: 'Animated Widgets',
              subtitle:
                  'Injected widgets can animate — fade, slide, bounce inside HTML',
              color: DemoColors.accent,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AnimationDemo()))),
        ],
      ),
    );
  }
}

class _InputFormatsHubPage extends StatelessWidget {
  const _InputFormatsHubPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _hubAppBar(context, 'Input Formats'),
      backgroundColor: const Color(0xFFF5F5F7),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hubCard(context,
              icon: Icons.text_snippet,
              title: 'Markdown',
              subtitle:
                  'Render .md content — headings, lists, bold, code, links',
              color: DemoColors.accent,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MarkdownDemo()))),
          _hubCard(context,
              icon: Icons.data_object,
              title: 'Quill Delta',
              subtitle: 'Render JSON output from the Quill.js rich text editor',
              color: DemoColors.accent,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const QuillDeltaDemo()))),
        ],
      ),
    );
  }
}

class _ComparisonPerfHubPage extends StatelessWidget {
  const _ComparisonPerfHubPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _hubAppBar(context, 'Comparison & Performance'),
      backgroundColor: const Color(0xFFF5F5F7),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hubCard(context,
              icon: Icons.compare,
              title: 'vs flutter_html & fwfh',
              subtitle:
                  'Side-by-side rendering of the same HTML in 3 libraries',
              color: DemoColors.success,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LibraryComparisonDemo()))),
          _hubCard(context,
              icon: Icons.bug_report,
              title: 'Features Other Libraries Miss',
              subtitle:
                  'Float layout, ruby, details/summary, inline decoration — all unsupported elsewhere',
              color: DemoColors.success,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FWFHIssuesTestDemo()))),
          _hubCard(context,
              icon: Icons.speed,
              title: 'Stress Test — 1000-Page Book',
              subtitle:
                  'Render and scroll a very long document — measure frame time and DOM node count',
              color: DemoColors.error,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StressTestDemo()))),
          _hubCard(context,
              icon: Icons.insights,
              title: 'Performance Deep Dive',
              subtitle:
                  'Step-by-step render pipeline breakdown — parse, tokenize, layout, paint',
              color: DemoColors.success,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PerformanceDeepDiveDemo()))),
        ],
      ),
    );
  }
}

class _QualityHubPage extends StatelessWidget {
  const _QualityHubPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _hubAppBar(context, 'Security & Accessibility'),
      backgroundColor: const Color(0xFFF5F5F7),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hubCard(context,
              icon: Icons.security,
              title: 'XSS Protection',
              subtitle:
                  'Malicious <script> and event handlers are stripped before rendering',
              color: DemoColors.error,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SecurityDemo()))),
          _hubCard(context,
              icon: Icons.accessibility,
              title: 'Accessibility',
              subtitle:
                  'Semantic labels for screen readers — VoiceOver and TalkBack',
              color: DemoColors.success,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AccessibilityDemo()))),
          _hubCard(context,
              icon: Icons.auto_fix_high,
              title: 'WebView Fallback',
              subtitle:
                  'Detect HTML that is too complex and fall back to a WebView automatically',
              color: DemoColors.warning,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HtmlHeuristicsDemo()))),
        ],
      ),
    );
  }
}
