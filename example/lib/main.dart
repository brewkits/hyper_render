import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' as fwfh;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart'
    as fwfh_core;
import 'package:hyper_render/hyper_render.dart';

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
// HOME PAGE - Navigation to demos
// =============================================================================

class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HyperRender Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildDemoCard(
            context,
            icon: Icons.auto_awesome,
            title: 'Kitchen Sink',
            subtitle: 'Tất cả features: Float, Selection, Ruby, Widget Injection',
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KitchenSinkDemo()),
            ),
          ),
          _buildDemoCard(
            context,
            icon: Icons.view_quilt,
            title: 'Float Layout',
            subtitle: 'CSS float: left/right - Văn bản bao quanh ảnh',
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FloatLayoutDemo()),
            ),
          ),
          _buildDemoCard(
            context,
            icon: Icons.select_all,
            title: 'Text Selection',
            subtitle: 'Bôi đen, copy, handles - Long press để xem menu',
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SelectionDemo()),
            ),
          ),
          _buildDemoCard(
            context,
            icon: Icons.translate,
            title: 'Ruby Annotation',
            subtitle: '振り仮名 (Furigana) cho tiếng Nhật/Trung',
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RubyDemo()),
            ),
          ),
          _buildDemoCard(
            context,
            icon: Icons.widgets,
            title: 'Widget Injection',
            subtitle: 'Nhúng Flutter Widget vào HTML',
            color: Colors.pink,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WidgetInjectionDemo()),
            ),
          ),
          _buildDemoCard(
            context,
            icon: Icons.format_paint,
            title: 'Inline Decoration',
            subtitle: 'Background, border wrap đúng khi xuống dòng',
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InlineDecorationDemo()),
            ),
          ),
          _buildDemoCard(
            context,
            icon: Icons.article,
            title: 'Real Content',
            subtitle: 'Blog post, novel với full features',
            color: Colors.indigo,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RealContentDemo()),
            ),
          ),
          _buildDemoCard(
            context,
            icon: Icons.table_chart,
            title: 'Table Demos',
            subtitle: 'Simple, wide, complex, and nested tables',
            color: Colors.brown,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TableDemo()),
            ),
          ),
          _buildDemoCard(
            context,
            icon: Icons.code,
            title: 'Code Blocks',
            subtitle: 'Syntax highlighting with <pre><code> elements',
            color: Colors.deepPurple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CodeBlockDemo()),
            ),
          ),
          _buildDemoCard(
            context,
            icon: Icons.broken_image,
            title: 'Image Handling',
            subtitle: 'Automatic loading/error states for images',
            color: Colors.cyan,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImageHandlingDemo()),
            ),
          ),
          _buildDemoCard(
            context,
            icon: Icons.zoom_in,
            title: 'Zoom & Pan',
            subtitle: 'Pinch-to-zoom and pan gestures with InteractiveViewer',
            color: Colors.lightBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ZoomDemo()),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Comparison & Stress Test'),
          _buildDemoCard(
            context,
            icon: Icons.compare,
            title: 'Library Comparison',
            subtitle:
                'So sánh với flutter_html, flutter_widget_from_html',
            color: Colors.deepOrange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LibraryComparisonDemo()),
            ),
          ),
          _buildDemoCard(
            context,
            icon: Icons.speed,
            title: 'Stress Test',
            subtitle: 'Test với sách 1000 trang - Đo performance',
            color: Colors.red,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StressTestDemo()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade700, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rocket_launch, color: Colors.white, size: 40),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HyperRender',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Universal Content Engine for Flutter',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('Float Layout'),
              _buildChip('Selection'),
              _buildChip('Ruby'),
              _buildChip('Kinsoku'),
              _buildChip('Widget Injection'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
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
      Đây là ví dụ về <strong style="color: #E91E63;">Float Layout</strong>. Văn bản này sẽ tự động
      bao quanh hình ảnh bên trái. HyperRender sử dụng thuật toán IFC giống như trình duyệt web.
    </p>
  </div>
  <div style="clear: both; height: 16px;"></div>

  <h2 style="color: #9C27B0; border-left: 4px solid #9C27B0; padding-left: 12px;">2. Widget Injection</h2>
  <div style="text-align: center; margin: 16px 0; padding: 16px; background: #FFF3E0; border-radius: 12px;">
    <p style="margin: 0 0 12px 0; font-weight: bold;">🔔 Subscribe để nhận thông báo!</p>
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
    <p style="margin: 0;">👆 <strong>Long press</strong> trên văn bản để hiện menu Copy!</p>
    <p style="margin: 8px 0 0 0;">Hoặc kéo để bôi đen, sau đó long press để copy.</p>
  </div>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kitchen Sink Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: HyperViewer(
          html: htmlContent,
          selectable: true,
          onLinkTap: (url) => _showSnackBar('Link: $url'),
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
        _showSnackBar(isSubscribed ? '🔕 Đã hủy đăng ký' : '🔔 Đã đăng ký!');
      },
      icon: Icon(isSubscribed ? Icons.notifications_off : Icons.notifications_active),
      label: Text(isSubscribed ? 'Đã đăng ký' : 'Subscribe'),
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
      Đây là ví dụ về <strong>float: left</strong>. Văn bản sẽ tự động bao quanh hình ảnh bên trái.
      Khi văn bản đủ dài, nó sẽ tiếp tục xuống dưới hình ảnh một cách tự nhiên. Đây là tính năng
      mà flutter_html và flutter_widget_from_html KHÔNG hỗ trợ.
    </p>
    <p>
      HyperRender sử dụng thuật toán IFC (Inline Formatting Context) giống như trình duyệt web thực sự
      để tính toán khoảng trống còn lại của từng dòng và lấp đầy nó bằng các Fragment văn bản.
    </p>
  </div>

  <div style="clear: both; height: 32px;"></div>

  <h2 style="color: #9C27B0;">Float Right</h2>
  <div style="margin: 16px 0;">
    <img src="https://picsum.photos/100/100?random=11" style="float: right; width: 100px; height: 100px; margin: 0 0 8px 16px; border-radius: 50%;" />
    <p>
      Float cũng hoạt động ở <strong>bên phải</strong>! Hình tròn này float right và văn bản
      sẽ lấp đầy khoảng trống bên trái một cách tự nhiên.
    </p>
    <p>
      Thử xoay màn hình để thấy layout thích ứng mượt mà như thế nào.
    </p>
  </div>

  <div style="clear: both; height: 32px;"></div>

  <h2 style="color: #FF5722;">Multiple Floats</h2>
  <div style="margin: 16px 0;">
    <img src="https://picsum.photos/80/80?random=12" style="float: left; width: 80px; height: 80px; margin: 0 12px 8px 0; border-radius: 8px;" />
    <img src="https://picsum.photos/80/80?random=13" style="float: left; width: 80px; height: 80px; margin: 0 12px 8px 0; border-radius: 8px;" />
    <p>
      Nhiều float elements có thể xếp cạnh nhau. Văn bản sẽ wrap xung quanh tất cả chúng.
      Đây là layout kiểu magazine/newspaper rất phổ biến.
    </p>
  </div>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Float Layout Demo')),
      body: const Padding(
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

  <h2>Văn bản tiếng Việt</h2>
  <p>
    HyperRender là một thư viện Flutter mạnh mẽ cho phép render HTML, Markdown và Quill Delta
    với hiệu năng cao. Selection hoạt động mượt mà ngay cả với văn bản dài và phức tạp.
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
    return Scaffold(
      appBar: AppBar(title: const Text('Text Selection Demo')),
      body: const Padding(
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
      appBar: AppBar(title: const Text('Ruby Annotation Demo')),
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
  <p>Bạn có thể nhúng <strong>bất kỳ Flutter Widget nào</strong> vào giữa HTML bằng custom tags.</p>

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
      appBar: AppBar(title: const Text('Widget Injection Demo')),
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
  <p>Inline decoration wrap đúng cách khi xuống dòng - không giống RichText thông thường!</p>

  <h3>Highlight Text</h3>
  <p>
    Đây là văn bản bình thường với
    <span style="background: #FFEB3B; padding: 2px 6px; border-radius: 4px;">
      phần được highlight màu vàng
    </span>
    và tiếp tục văn bản bình thường.
  </p>

  <h3>Long Highlight (Multi-line)</h3>
  <p>
    <span style="background: #E1BEE7; padding: 4px 8px; border-radius: 4px;">
      Đây là một đoạn text dài có background màu tím và nó sẽ wrap xuống dòng mới
      trong khi vẫn giữ nguyên background ở mỗi dòng một cách chính xác như CSS thực sự.
      Bạn có thể thấy background tiếp tục ở dòng tiếp theo.
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
    return Scaffold(
      appBar: AppBar(title: const Text('Inline Decoration Demo')),
      body: const Padding(
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
    return Scaffold(
      appBar: AppBar(title: const Text('Real Content Demo')),
      body: const Padding(
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
  <h2 style="color: #4CAF50;">Simple Table</h2>
  <p>A basic table with headers and borders.</p>
  <table border="1" style="border-collapse: collapse; width: 100%;">
    <tr style="background-color: #f2f2f2;">
      <th>Name</th>
      <th>Role</th>
      <th>Email</th>
    </tr>
    <tr>
      <td>Viet Nguyen</td>
      <td>Engineer</td>
      <td>viet.nguyen@example.com</td>
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
      <td>Viet Nguyen</td>
    </tr>
    <tr>
      <td>Email</td>
      <td>viet.nguyen@example.com</td>
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
    return Scaffold(
      appBar: AppBar(title: const Text('Table Demo')),
      body: const Padding(
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
  <p>Demonstrate <code style="background: #F5F5F5; padding: 2px 6px; border-radius: 3px; font-family: monospace;">pre</code> and <code style="background: #F5F5F5; padding: 2px 6px; border-radius: 3px; font-family: monospace;">code</code> elements for displaying code snippets.</p>

  <h3 style="color: #512DA8; margin-top: 24px;">Dart Code Example</h3>
  <pre style="background: #282c34; color: #abb2bf; padding: 16px; border-radius: 8px; overflow-x: auto; font-family: 'Courier New', monospace; font-size: 14px; line-height: 1.5;"><code>void main() {
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
  <pre style="background: #1e1e1e; color: #d4d4d4; padding: 16px; border-radius: 8px; overflow-x: auto; font-family: 'Courier New', monospace; font-size: 14px; line-height: 1.5;"><code>&lt;!DOCTYPE html&gt;
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
  <pre style="background: #f6f8fa; color: #24292e; padding: 16px; border-radius: 8px; border: 1px solid #e1e4e8; overflow-x: auto; font-family: 'Courier New', monospace; font-size: 14px; line-height: 1.5;"><code>function fibonacci(n) {
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
  <pre style="background: #263238; color: #EEFFFF; padding: 16px; border-radius: 8px; overflow-x: auto; font-family: 'Courier New', monospace; font-size: 14px; line-height: 1.5;"><code>def quick_sort(arr):
    """QuickSort algorithm implementation"""
    if len(arr) <= 1:
        return arr

    pivot = arr[len(arr) // 2]
    left = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]

    return quick_sort(left) + middle + quick_sort(right)

# Test the function
numbers = [3, 6, 8, 10, 1, 2, 1]
sorted_numbers = quick_sort(numbers)
print(sorted_numbers)  # [1, 1, 2, 3, 6, 8, 10]</code></pre>

  <h3 style="color: #512DA8; margin-top: 24px;">Inline Code</h3>
  <p>
    You can also use inline code like
    <code style="background: #f5f5f5; color: #c7254e; padding: 2px 6px; border-radius: 3px; font-family: monospace; font-size: 14px;">const variable = "value";</code>
    within a paragraph. Use
    <code style="background: #f5f5f5; color: #c7254e; padding: 2px 6px; border-radius: 3px; font-family: monospace; font-size: 14px;">npm install</code>
    to install packages, or run
    <code style="background: #f5f5f5; color: #c7254e; padding: 2px 6px; border-radius: 3px; font-family: monospace; font-size: 14px;">flutter pub get</code>
    for Flutter projects.
  </p>

  <h3 style="color: #512DA8; margin-top: 24px;">Terminal/Shell Commands</h3>
  <pre style="background: #000000; color: #00ff00; padding: 16px; border-radius: 8px; overflow-x: auto; font-family: 'Courier New', monospace; font-size: 14px; line-height: 1.5;"><code>\$ flutter create my_app
\$ cd my_app
\$ flutter run

Launching lib/main.dart on Chrome in debug mode...
[✓] Built build/web/main.dart.js
  Serving DevTools at http://127.0.0.1:9100

[✓] Success! Your app is running at:
   http://localhost:12345</code></pre>

  <div style="background: #e8f5e9; padding: 16px; border-left: 4px solid #4caf50; margin-top: 24px; border-radius: 4px;">
    <p style="margin: 0; font-weight: bold; color: #2e7d32;">💡 Pro Tip</p>
    <p style="margin: 8px 0 0 0;">Code blocks with <code style="background: #fff; padding: 2px 6px; border-radius: 3px; font-family: monospace;">pre + code</code> preserve whitespace and formatting, making them perfect for displaying code snippets in documentation, tutorials, and technical blogs.</p>
  </div>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Code Blocks Demo')),
      body: const Padding(
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
    return Scaffold(
      appBar: AppBar(title: const Text('Image Handling Demo')),
      body: const Padding(
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
      'description': 'Furigana for Japanese text (HyperRender most accurate)',
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
  <p><em>Flutter_html often crashes on SelectionArea with complex content</em></p>
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
  ];

  int _currentTestIndex = 0;
  final Map<String, Duration> _renderTimes = {};

  String _getExpectedBehavior(int index) {
    switch (index) {
      case 0: // Float Layout
        return '✅ HyperRender: Text wraps around image | ❌ Others: Image appears above text';
      case 1: // Table colspan/rowspan
        return '✅ All libraries: Proper colspan/rowspan with width: 100% (fits screen)';
      case 2: // Ruby Annotation
        return '✅ HyperRender: Perfect alignment | ✅ fwfh: Good | ❌ flutter_html: Not supported';
      case 3: // Multiple Floats
        return '✅ HyperRender: Text wraps between images | ❌ Others: Images stack vertically';
      case 4: // Inline Background
        return '✅ HyperRender: Background wraps across lines | ❌ Others: Background is rectangular block';
      case 5: // CSS Specificity
        return '✅ HyperRender, fwfh: Correct cascade order | ❌ flutter_html: May ignore <style> tag';
      case 6: // Selection Stress
        return '✅ HyperRender, fwfh: Smooth selection | ❌ flutter_html: May crash with SelectionArea';
      case 7: // Wide Table Scroll
        return '✅ HyperRender: Auto-scales down to fit | ✅ fwfh: May scroll or wrap | ❌ flutter_html: May overflow';
      case 8: // Nested Lists
        return '✅ All libraries: Should render correctly with proper indentation';
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
        return Padding(
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
    const features = [
      ('Float Layout', true, false, false, false),
      ('Table colspan/rowspan', true, false, true, true),
      ('Ruby Annotation', true, false, true, true),
      ('Multiple Floats', true, false, false, false),
      ('Inline Bg Wrap', true, false, false, false),
      ('CSS Specificity', true, false, true, true),
      ('Selection (No Crash)', true, false, true, true),
      ('Custom Widgets', true, true, true, true),
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
      'Tiếng Việt cũng được hỗ trợ hoàn hảo. Đây là đoạn văn bản tiếng Việt để kiểm tra khả năng hiển thị các ký tự đặc biệt và dấu.',
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
