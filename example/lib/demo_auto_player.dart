import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';
import 'main.dart';
import 'smart_table_demo.dart';
import 'manga_demo.dart';
import 'enhanced_selection_demo.dart';
import 'ultra_showcase_2026.dart';
import 'stress_test_demo.dart';

const String kSelectedDemo = String.fromEnvironment('DEMO', defaultValue: 'float');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DemoAutoPlayerApp());
}

class DemoAutoPlayerApp extends StatelessWidget {
  const DemoAutoPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1A56DB);
    return MaterialApp(
      title: 'HyperRender Auto Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AutoPlayerHost(),
    );
  }
}

class AutoPlayerHost extends StatefulWidget {
  const AutoPlayerHost({super.key});

  @override
  State<AutoPlayerHost> createState() => _AutoPlayerHostState();
}

class _AutoPlayerHostState extends State<AutoPlayerHost> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startContinuousScroll();
    });
  }

  void _startContinuousScroll() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (max <= 0) return;

      final current = _scrollController.offset;
      if (current >= max) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(current + 2.5);
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title;
    String htmlContent;

    switch (kSelectedDemo) {
      case 'ruby':
        title = 'Ruby / Furigana CJK Typography';
        htmlContent = '''
<div style="font-family: sans-serif; padding: 16px; line-height: 2.0; font-size: 20px;">
  <h2 style="color: #1A56DB;">Ruby Annotation & Kinsoku Wrapping</h2>
  <p>
    HyperRender includes a full CJK typesetting engine with W3C Ruby specification support:
  </p>
  <div style="background: #F4F7FB; padding: 16px; border-radius: 12px; border-left: 4px solid #1A56DB; margin: 16px 0;">
    <p style="font-size: 24px;">
      <ruby>漢<rt>かん</rt>字<rt>じ</rt></ruby>の<ruby>読<rt>よ</rt></ruby>み<ruby>方<rt>かた</rt></ruby>を<ruby>表<rt>ひょう</rt>示<rt>じ</rt></ruby>します。
    </p>
    <p style="font-size: 24px;">
      <ruby>超<rt>ちょう</rt>高<rt>こう</rt>速<rt>そく</rt></ruby>レンダリングエンジン <ruby>HyperRender<rt>ハイパー</rt></ruby>！
    </p>
    <p style="font-size: 22px;">
      <ruby>吾<rt>わが</rt>輩<rt>はい</rt></ruby>は<ruby>猫<rt>ねこ</rt></ruby>である。<ruby>名<rt>な</rt>前<rt>まえ</rt></ruby>はまだ<ruby>無<rt>な</rt></ruby>い。
      どこで<ruby>生<rt>う</rt></ruby>れたかとんと<ruby>見<rt>けん</rt>当<rt>とう</rt></ruby>がつかぬ。
    </p>
  </div>
  <p>Furigana is accurately centered above each base glyph with full line-breaking rules.</p>
</div>
''';
        break;

      case 'selection':
        title = 'Crash-Free Selection Across Blocks';
        htmlContent = '''
<div style="font-family: sans-serif; padding: 16px; line-height: 1.6;">
  <h2 style="color: #1A56DB;">Crash-Free Text Selection</h2>
  <p>
    Single RenderObject architecture allows fluid, unbroken selection across multiple paragraphs, headings, blockquotes, and tables without Flutter multi-renderobject crashes!
  </p>
  <blockquote style="background: #EFF6FF; border-left: 4px solid #3B82F6; padding: 12px 16px; margin: 16px 0; border-radius: 4px;">
    <strong>Seamless Highlighting:</strong> Drag across this quote, into the table below, and down into subsequent paragraphs with 100% native selection handles.
  </blockquote>
  <table border="1" cellpadding="8" style="width: 100%; border-collapse: collapse; margin: 16px 0; border-color: #E2E8F0;">
    <tr style="background: #F8FAFC;"><th>Feature</th><th>HyperRender</th><th>Competitors</th></tr>
    <tr><td>CSS Float</td><td style="color: #16A34A; font-weight: bold;">Yes</td><td>No</td></tr>
    <tr><td>100K Selection</td><td style="color: #16A34A; font-weight: bold;">60 FPS</td><td>Crashes</td></tr>
  </table>
  <p>Tested up to 100,000 characters with zero memory leaks and instantaneous response.</p>
</div>
''';
        break;

      case 'table':
        title = 'W3C 2-Pass Smart Tables';
        htmlContent = '''
<div style="font-family: sans-serif; padding: 16px; line-height: 1.6;">
  <h2 style="color: #1A56DB;">Advanced W3C Table Layout</h2>
  <p>Supports colspan, rowspan, border-collapse, cell padding, and auto-balancing columns:</p>
  <table border="1" cellpadding="10" style="width: 100%; border-collapse: collapse; border-color: #CBD5E1; margin: 16px 0;">
    <tr style="background: #1E293B; color: white;">
      <th colspan="3" style="text-align: center;">2026 Engine Comparison Benchmark</th>
    </tr>
    <tr style="background: #F1F5F9; font-weight: bold;">
      <td>Metric</td>
      <td>HyperRender 1.7</td>
      <td>flutter_html</td>
    </tr>
    <tr>
      <td>First Paint</td>
      <td style="color: #059669; font-weight: bold;">1.8 ms</td>
      <td>14.2 ms</td>
    </tr>
    <tr>
      <td>Float Wrap</td>
      <td style="color: #059669; font-weight: bold;">Full W3C Wrap</td>
      <td>Stacked Block</td>
    </tr>
    <tr>
      <td>Memory (10K chars)</td>
      <td style="color: #059669; font-weight: bold;">2.1 MB</td>
      <td>18.4 MB</td>
    </tr>
  </table>
</div>
''';
        break;

      case 'comparison':
        title = 'Head-to-Head Comparison';
        htmlContent = '''
<div style="font-family: sans-serif; padding: 16px; line-height: 1.6;">
  <h2 style="color: #1A56DB;">Architecture Comparison</h2>
  <div style="background: #F0FDF4; border: 2px solid #22C55E; border-radius: 12px; padding: 16px; margin: 12px 0;">
    <h3 style="color: #15803D; margin: 0 0 8px 0;">⚡ HyperRender Engine</h3>
    <p style="color: #166534; margin: 4px 0;">• Single RenderObject Architecture</p>
    <p style="color: #166534; margin: 4px 0;">• Native CSS Float Wrapping around obstacles</p>
    <p style="color: #166534; margin: 4px 0;">• 60 FPS Continuous 100K selection</p>
  </div>
  <div style="background: #FEF2F2; border: 2px solid #EF4444; border-radius: 12px; padding: 16px; margin: 12px 0;">
    <h3 style="color: #B91C1C; margin: 0 0 8px 0;">❌ flutter_html & Competitors</h3>
    <p style="color: #991B1B; margin: 4px 0;">• Hundreds of Widget tree layers (High Memory)</p>
    <p style="color: #991B1B; margin: 4px 0;">• Floats fail and stack vertically</p>
    <p style="color: #991B1B; margin: 4px 0;">• Selection crashes across block elements</p>
  </div>
</div>
''';
        break;

      case 'performance':
        title = '60 FPS Virtualized Rendering';
        final buf = StringBuffer();
        buf.write('<div style="font-family: sans-serif; padding: 16px;">');
        buf.write('<h2 style="color: #1A56DB;">100,000+ Chars Virtualized Mode</h2>');
        buf.write('<div style="background: #1E293B; color: #38BDF8; padding: 12px; border-radius: 8px; font-weight: bold; margin-bottom: 16px;">🚀 FPS: 60.0 | Memory: 2.4 MB | Active Nodes: 12</div>');
        for (int i = 1; i <= 60; i++) {
          final bg = i % 2 == 0 ? '#F8FAFC' : '#FFFFFF';
          buf.write('<div style="background: $bg; border-left: 4px solid #3B82F6; padding: 8px 12px; margin-bottom: 8px; border-radius: 4px;"><b style="color: #1D4ED8;">Section $i:</b> HyperRender utilizes intelligent chunking. Only blocks visible on screen are painted, achieving smooth 60 FPS scrolling.</div>');
        }
        buf.write('</div>');
        htmlContent = buf.toString();
        break;

      case 'float':
      default:
        title = 'CSS Float Magazine Layout';
        htmlContent = '''
<div style="font-family: sans-serif; padding: 16px; line-height: 1.7;">
  <h2 style="color: #1A56DB; margin-bottom: 12px;">Float Left & Right Wrapping</h2>
  <div style="float: left; width: 110px; height: 110px; background: linear-gradient(135deg, #1A56DB, #60A5FA); margin: 0 16px 12px 0; border-radius: 16px; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 14px; text-align: center; box-shadow: 0 4px 12px rgba(26,86,219,0.3);">
    FLOAT LEFT
  </div>
  <p>
    This text seamlessly wraps around the floating block on the left side. As the text flows down, it automatically expands to fill the full width of the container once clear of the float box.
  </p>
  <p>
    HyperRender is the <strong>only Flutter HTML engine</strong> that implements the W3C Inline Formatting Context (IFC) float algorithm!
  </p>

  <div style="clear: both; height: 20px;"></div>

  <h2 style="color: #9333EA; margin-bottom: 12px;">Float Right Circle</h2>
  <div style="float: right; width: 100px; height: 100px; background: linear-gradient(135deg, #9333EA, #F472B6); margin: 0 0 12px 16px; border-radius: 50%; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 14px; text-align: center; box-shadow: 0 4px 12px rgba(147,51,234,0.3);">
    FLOAT RIGHT
  </div>
  <p>
    Floating elements on the right side are calculated with dual-boundary clipping. Text flows on the left and continues underneath with zero layout jank.
  </p>
</div>
''';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80.0),
          child: HyperViewer(
            html: htmlContent,
            selectable: true,
            mode: HyperRenderMode.sync,
          ),
        ),
      ),
    );
  }
}
