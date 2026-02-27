import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

/// Widget Animations Demo
/// Shows Flutter widget-level animations wrapping HyperViewer content.
/// NOTE: CSS animation/transition/transform parsing is planned for a future version.
class AnimationDemo extends StatelessWidget {
  const AnimationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Animations'),
        backgroundColor: DemoColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _DisclaimerCard(),
          SizedBox(height: 20),
          _WidgetAnimationsSection(),
          SizedBox(height: 20),
          _ExtensionMethodsSection(),
          SizedBox(height: 20),
          _RoadmapSection(),
        ],
      ),
    );
  }
}

// =============================================================================
// DISCLAIMER CARD
// =============================================================================

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Animation Status',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            '⚠️',
            'CSS animation/transition/transform properties are not yet parsed from CSS strings',
            Colors.orange.shade700,
          ),
          const SizedBox(height: 6),
          _buildStatusRow(
            '✅',
            'Widget-level animations work perfectly with HyperAnimatedWidget',
            Colors.green.shade700,
          ),
          const SizedBox(height: 6),
          _buildStatusRow(
            '🗺️',
            'CSS animation support is planned for a future version',
            Colors.blue.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String emoji, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: color)),
        ),
      ],
    );
  }
}

// =============================================================================
// SECTION 1: WIDGET ANIMATIONS
// =============================================================================

class _WidgetAnimationsSection extends StatelessWidget {
  const _WidgetAnimationsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Widget Animations', Icons.animation),
        const SizedBox(height: 12),
        const Text(
          'HyperAnimatedWidget wraps any widget with keyframe animations. '
          'These work at the Flutter widget level, independent of CSS parsing.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        _buildAnimationCard(
          'fadeIn',
          'Fade In',
          Colors.blue.shade50,
          Colors.blue.shade700,
        ),
        const SizedBox(height: 12),
        _buildAnimationCard(
          'slideInLeft',
          'Slide In from Left',
          Colors.purple.shade50,
          Colors.purple.shade700,
        ),
        const SizedBox(height: 12),
        _buildAnimationCard(
          'bounce',
          'Bounce',
          Colors.green.shade50,
          Colors.green.shade700,
        ),
        const SizedBox(height: 12),
        _buildAnimationCard(
          'pulse',
          'Pulse',
          Colors.orange.shade50,
          Colors.orange.shade700,
        ),
      ],
    );
  }

  Widget _buildAnimationCard(
    String name,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    const html = '''
<div style="font-family: sans-serif; padding: 8px;">
  <h3 style="margin: 0 0 8px 0;">Animated Content</h3>
  <p style="margin: 0; color: #555; font-size: 14px;">
    This HyperViewer widget is wrapped with a widget-level animation.
    The HTML content itself has no animation CSS — the animation is applied
    by <strong>HyperAnimatedWidget</strong> at the Flutter layer.
  </p>
</div>
''';

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'animation: "$name"',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          HyperAnimatedWidget(
            animationName: name,
            duration: const Duration(milliseconds: 800),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: textColor.withValues(alpha: 0.2)),
              ),
              padding: const EdgeInsets.all(8),
              child: HyperViewer(
                html: html,
                mode: HyperRenderMode.sync,
              ),
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
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// =============================================================================
// SECTION 2: EXTENSION METHODS
// =============================================================================

class _ExtensionMethodsSection extends StatefulWidget {
  const _ExtensionMethodsSection();

  @override
  State<_ExtensionMethodsSection> createState() =>
      _ExtensionMethodsSectionState();
}

class _ExtensionMethodsSectionState extends State<_ExtensionMethodsSection> {
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
            Text(
              'Extension Methods',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'HyperAnimationExtension adds convenient animation methods to any Widget.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        // Code sample
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '// Extension methods on Widget:\n'
            'HyperViewer(html: html)\n'
            '  .fadeIn()          // Fade in on first render\n'
            '  .slideInLeft()     // Slide from left\n'
            '  .bounce()          // Bounce effect\n'
            '  .pulse()           // Pulse scale effect',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFFCDD6F4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => setState(() => _visible = !_visible),
              icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
              label: Text(_visible ? 'Hide (will fadeIn on show)' : 'Show with fadeIn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DemoColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_visible)
          HyperViewer(
            html: '<div style="font-family: sans-serif; padding: 8px;">'
                '<p><strong>fadeIn()</strong> extension applied to this HyperViewer.</p>'
                '<p style="color: #555; font-size: 13px;">'
                'Hide and show to see the animation trigger again.</p></div>',
            mode: HyperRenderMode.sync,
          ).fadeIn(),
      ],
    );
  }
}

// =============================================================================
// SECTION 3: ROADMAP
// =============================================================================

class _RoadmapSection extends StatelessWidget {
  const _RoadmapSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.map, color: DemoColors.accent, size: 24),
            SizedBox(width: 8),
            Text(
              'CSS Animation Roadmap',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Planned CSS Animation Features',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildRoadmapItem(
                    '📌', 'animation-name', 'Link CSS keyframes by name',
                    false),
                _buildRoadmapItem(
                    '📌', 'animation-duration', 'Control animation timing',
                    false),
                _buildRoadmapItem(
                    '📌', 'animation-timing-function',
                    'ease, linear, cubic-bezier()', false),
                _buildRoadmapItem(
                    '📌', 'animation-iteration-count',
                    'infinite, 1, 2, etc.', false),
                _buildRoadmapItem(
                    '📌', 'animation-direction', 'normal, reverse, alternate',
                    false),
                _buildRoadmapItem(
                    '📌', 'transition', 'CSS property transitions', false),
                _buildRoadmapItem(
                    '📌', 'transform', 'translate, rotate, scale, skew', false),
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Current: HyperKeyframes system provides '
                          'equivalent functionality at the widget level',
                          style: TextStyle(
                              fontSize: 13, color: Colors.green.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoadmapItem(
      String emoji, String property, String description, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(done ? '✅' : emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: done
                            ? Colors.green.shade700
                            : Colors.black87)),
                Text(description,
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
