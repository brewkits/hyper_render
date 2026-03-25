import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

/// Animation Demo
///
/// Shows three layers of animation support in HyperRender:
///   1. CSS @keyframes parsed from `<style>` tags — zero Dart glue needed.
///   2. Widget-level animations via [HyperAnimatedWidget].
///   3. Extension-method shortcuts (.fadeIn(), .bounce(), etc.).
class AnimationDemo extends StatelessWidget {
  const AnimationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animations'),
        backgroundColor: DemoColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _StatusCard(),
          SizedBox(height: 20),
          _CssKeyframesSection(),
          SizedBox(height: 20),
          _WidgetAnimationsSection(),
          SizedBox(height: 20),
          _ExtensionMethodsSection(),
          SizedBox(height: 20),
          _CapabilityTable(),
        ],
      ),
    );
  }
}

// =============================================================================
// STATUS CARD
// =============================================================================

class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'CSS Animation Support — v1.1.2',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row('✅', '@keyframes parsed from <style> tags automatically'),
          _row('✅', 'animation-name, animation-duration, animation-delay'),
          _row('✅', 'animation-timing-function (ease, linear, ease-in/out)'),
          _row('✅', 'animation-iteration-count, animation-direction'),
          _row('✅', 'opacity, translateX/Y, scale, rotate transforms'),
          _row('✅', 'Vendor prefixes: @-webkit-keyframes, @-moz-keyframes'),
          _row('✅', 'Widget-level HyperAnimatedWidget + extension methods'),
        ],
      ),
    );
  }

  Widget _row(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.green.shade900),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 1: CSS @KEYFRAMES PARSED FROM HTML
// =============================================================================

class _CssKeyframesSection extends StatelessWidget {
  const _CssKeyframesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('CSS @keyframes from HTML', Icons.code),
        const SizedBox(height: 8),
        const Text(
          'HyperViewer automatically extracts @keyframes from <style> tags '
          'and wires them to AnimationController. No Dart code needed.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        _buildLiveExample(
          label: 'fadeIn + slideUp',
          accentColor: Colors.indigo,
          html: '''
<style>
  @keyframes fadeSlideUp {
    from { opacity: 0; transform: translateY(24px); }
    to   { opacity: 1; transform: translateY(0px); }
  }
  .card {
    animation-name: fadeSlideUp;
    animation-duration: 700ms;
    animation-timing-function: ease-out;
    font-family: sans-serif;
    padding: 16px;
    background: #EEF2FF;
    border-radius: 8px;
  }
  h3 { margin: 0 0 6px 0; color: #3730a3; font-size: 16px; }
  p  { margin: 0; color: #4338ca; font-size: 14px; }
</style>
<div class="card">
  <h3>Slide-up on load</h3>
  <p>This card is animated purely via CSS @keyframes — no Dart code.</p>
</div>
''',
          codeSnippet:
              '@keyframes fadeSlideUp {\n'
              '  from { opacity: 0; transform: translateY(24px); }\n'
              '  to   { opacity: 1; transform: translateY(0px);  }\n'
              '}\n'
              '.card {\n'
              '  animation-name: fadeSlideUp;\n'
              '  animation-duration: 700ms;\n'
              '}',
        ),
        const SizedBox(height: 12),
        _buildLiveExample(
          label: 'Bounce + scale combo',
          accentColor: Colors.teal,
          html: '''
<style>
  @keyframes popIn {
    0%   { opacity: 0; transform: scale(0.6); }
    70%  { transform: scale(1.08); }
    100% { opacity: 1; transform: scale(1); }
  }
  .badge {
    animation-name: popIn;
    animation-duration: 500ms;
    animation-timing-function: ease-out;
    display: inline-block;
    background: #CCFBF1;
    color: #0f766e;
    font-family: sans-serif;
    font-size: 15px;
    font-weight: bold;
    padding: 10px 20px;
    border-radius: 24px;
  }
</style>
<div style="text-align:center; padding:16px;">
  <span class="badge">🎉 Pop-in animation!</span>
</div>
''',
          codeSnippet:
              '@keyframes popIn {\n'
              '  0%   { opacity: 0; transform: scale(0.6); }\n'
              '  70%  { transform: scale(1.08); }\n'
              '  100% { opacity: 1; transform: scale(1); }\n'
              '}',
        ),
        const SizedBox(height: 12),
        _buildLiveExample(
          label: 'Staggered list items',
          accentColor: Colors.deepOrange,
          html: '''
<style>
  @keyframes slideRight {
    from { opacity: 0; transform: translateX(-40px); }
    to   { opacity: 1; transform: translateX(0px); }
  }
  .item {
    animation-name: slideRight;
    animation-timing-function: ease-out;
    font-family: sans-serif;
    padding: 8px 12px;
    margin-bottom: 6px;
    background: #FFF7ED;
    border-left: 3px solid #ea580c;
    border-radius: 4px;
    font-size: 14px;
    color: #9a3412;
  }
  .a { animation-duration: 400ms; }
  .b { animation-duration: 600ms; }
  .c { animation-duration: 800ms; }
</style>
<div>
  <div class="item a">Item 1 — 400 ms</div>
  <div class="item b">Item 2 — 600 ms</div>
  <div class="item c">Item 3 — 800 ms</div>
</div>
''',
          codeSnippet:
              '/* Stagger via animation-duration */\n'
              '.a { animation-duration: 400ms; }\n'
              '.b { animation-duration: 600ms; }\n'
              '.c { animation-duration: 800ms; }',
        ),
      ],
    );
  }

  Widget _buildLiveExample({
    required String label,
    required MaterialColor accentColor,
    required String html,
    required String codeSnippet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: accentColor.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Icon(Icons.play_circle_filled,
                    color: accentColor.shade700, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accentColor.shade800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Live render
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.shade100),
              ),
              padding: const EdgeInsets.all(8),
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
              ),
            ),
          ),
          // Code snippet
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Text(
              codeSnippet,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFFCDD6F4),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: DemoColors.accent, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// =============================================================================
// SECTION 2: WIDGET-LEVEL ANIMATIONS
// =============================================================================

class _WidgetAnimationsSection extends StatelessWidget {
  const _WidgetAnimationsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Widget-level Animations', Icons.animation),
        const SizedBox(height: 8),
        const Text(
          'Wrap any widget with HyperAnimatedWidget to animate it independently '
          'of the HTML content.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        _buildAnimationCard('fadeIn', 'Fade In',
            Colors.blue.shade50, Colors.blue.shade700),
        const SizedBox(height: 12),
        _buildAnimationCard('slideInLeft', 'Slide In from Left',
            Colors.purple.shade50, Colors.purple.shade700),
        const SizedBox(height: 12),
        _buildAnimationCard('bounce', 'Bounce',
            Colors.green.shade50, Colors.green.shade700),
        const SizedBox(height: 12),
        _buildAnimationCard('pulse', 'Pulse',
            Colors.orange.shade50, Colors.orange.shade700),
      ],
    );
  }

  Widget _buildAnimationCard(
      String name, String label, Color bgColor, Color textColor) {
    const html = '''
<div style="font-family: sans-serif; padding: 8px;">
  <h3 style="margin: 0 0 6px 0; font-size: 15px;">Animated Content</h3>
  <p style="margin: 0; color: #555; font-size: 13px;">
    Wrapped with <strong>HyperAnimatedWidget</strong> at the Flutter layer.
  </p>
</div>
''';

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle, color: textColor, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 14)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'animationName: "$name"',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          HyperAnimatedWidget(
            animationName: name,
            duration: const Duration(milliseconds: 800),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: textColor.withValues(alpha: 0.2)),
              ),
              padding: const EdgeInsets.all(8),
              child: HyperViewer(html: html, mode: HyperRenderMode.sync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: DemoColors.accent, size: 24),
        const SizedBox(width: 8),
        Text(title,
            style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// =============================================================================
// SECTION 3: EXTENSION METHODS
// =============================================================================

class _ExtensionMethodsSection extends StatefulWidget {
  const _ExtensionMethodsSection();

  @override
  State<_ExtensionMethodsSection> createState() =>
      _ExtensionMethodsSectionState();
}

class _ExtensionMethodsSectionState
    extends State<_ExtensionMethodsSection> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.extension, color: DemoColors.accent, size: 24),
            SizedBox(width: 8),
            Text('Extension Methods',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'HyperAnimationExtension adds convenience methods to any Widget.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'HyperViewer(html: html)\n'
            '  .fadeIn()       // Fade in on first build\n'
            '  .slideInLeft()  // Slide from left\n'
            '  .bounce()       // Bounce effect\n'
            '  .pulse()        // Pulse scale effect\n'
            '  .spin()         // Continuous rotation',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFFCDD6F4),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _visible = !_visible),
            icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
            label: Text(_visible
                ? 'Hide  (re-show triggers fadeIn)'
                : 'Show with fadeIn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DemoColors.accent,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_visible)
          HyperViewer(
            html: '<div style="font-family:sans-serif; padding:10px;">'
                '<p><strong>fadeIn()</strong> applied via extension method.</p>'
                '<p style="color:#555;font-size:13px;">'
                'Hide and show to replay.</p></div>',
            mode: HyperRenderMode.sync,
          ).fadeIn(),
      ],
    );
  }
}

// =============================================================================
// SECTION 4: CAPABILITY TABLE
// =============================================================================

class _CapabilityTable extends StatelessWidget {
  const _CapabilityTable();

  @override
  Widget build(BuildContext context) {
    final rows = [
      _Cap('animation-name', 'CSS @keyframes by name', true),
      _Cap('animation-duration', 'Timing control', true),
      _Cap('animation-timing-function', 'ease, linear, ease-in/out', true),
      _Cap('animation-delay', 'Delay before start', true),
      _Cap('animation-iteration-count', 'Repeat count (1, 2, …)', true),
      _Cap('animation-direction', 'normal, reverse, alternate', true),
      _Cap('opacity keyframe', 'Fade in/out', true),
      _Cap('transform: translate', 'Slide animations', true),
      _Cap('transform: scale', 'Zoom animations', true),
      _Cap('transform: rotate', 'Spin animations', true),
      _Cap('@-webkit-keyframes', 'Vendor prefix support', true),
      _Cap('animation-iteration-count: infinite',
          'Infinite loop (wiring in progress)', false),
      _Cap('CSS transitions', 'Property transitions', false),
      _Cap('transform: skew', 'Skew transforms', false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.table_chart, color: DemoColors.accent, size: 24),
            SizedBox(width: 8),
            Text('CSS Animation Coverage',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: rows
                  .map((r) => _buildRow(r.property, r.description, r.done))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String property, String desc, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          Text(done ? '✅' : '🚧',
              style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property,
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: done
                            ? Colors.green.shade800
                            : Colors.grey.shade700)),
                Text(desc,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cap {
  final String property;
  final String description;
  final bool done;
  const _Cap(this.property, this.description, this.done);
}
