import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

/// CSS Mastery — the capabilities added in the current development cycle.
///
/// Every panel here is **interactive**: you move a control and the CSS behind
/// the rendered HTML changes live. That matters more than a static screenshot,
/// because each of these properties was previously *parsed but not executed* —
/// the value landed in `ComputedStyle` and then changed nothing on screen.
/// Dragging a slider and watching the text actually reflow is the proof.
///
/// Covered here (all new, none of it demoed anywhere else):
///   • `border-collapse: separate` + `border-spacing`
///   • `text-align: justify` with real inter-word distribution
///   • `text-indent` (px and %)
///   • `width` / `min-width` / `max-width`, absolute and %
///   • system text scaling (WCAG 2.1 AA §1.4.4)
///   • `animation-play-state: paused | running`
///   • `text-align` overriding the RTL default
///   • `<ol start="N">`
class CssMasteryDemo extends StatefulWidget {
  const CssMasteryDemo({super.key});

  @override
  State<CssMasteryDemo> createState() => _CssMasteryDemoState();
}

class _CssMasteryDemoState extends State<CssMasteryDemo> {
  // Tables
  double _borderSpacing = 8;
  bool _separate = true;

  // Typography
  String _textAlign = 'justify';
  double _textIndent = 12;

  // Width constraints
  double _widthPercent = 60;
  double _minWidthPx = 0;

  // Accessibility
  double _textScale = 1.0;

  // Animation
  bool _animationRunning = true;

  static const _accent = Color(0xFF00695C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildDemoAppBar(
        context,
        title: 'CSS Mastery',
        accent: _accent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _intro(context),
          const SizedBox(height: 20),
          _tablesPanel(context),
          _typographyPanel(context),
          _widthPanel(context),
          _textScalingPanel(context),
          _animationPanel(context),
          _rtlPanel(context),
          _listStartPanel(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Intro ──────────────────────────────────────────────────────────────────

  Widget _intro(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      elevation: 0,
      color: _accent.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: _accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drag the controls — the CSS changes live',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Each property below used to parse correctly and then do nothing '
              'to the rendered output. These panels exist to prove the '
              'difference: move a control and watch the layout actually '
              'respond.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Tables: border-collapse / border-spacing ────────────────────────────

  Widget _tablesPanel(BuildContext context) {
    final css = _separate
        ? 'border-collapse: separate; '
            'border-spacing: ${_borderSpacing.round()}px'
        : 'border-collapse: collapse';

    return _panel(
      context,
      icon: Icons.grid_on,
      title: 'border-collapse & border-spacing',
      blurb: 'In `separate` mode every cell keeps its own outline and the gap '
          'between them is real layout space — the table grows as you widen it. '
          '`collapse` (the default) merges the borders into one shared grid.',
      controls: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('collapse')),
            ButtonSegment(value: true, label: Text('separate')),
          ],
          selected: {_separate},
          onSelectionChanged: (s) => setState(() => _separate = s.first),
        ),
        if (_separate)
          _slider(
            label: 'border-spacing',
            value: _borderSpacing,
            min: 0,
            max: 20,
            divisions: 20,
            suffix: 'px',
            onChanged: (v) => setState(() => _borderSpacing = v),
          ),
      ],
      css: css,
      html: '''
<table style="$css; width: 100%;">
  <tr><th>Region</th><th>Q1</th><th>Q2</th></tr>
  <tr><td>APAC</td><td>1,204</td><td>1,470</td></tr>
  <tr><td>EMEA</td><td>986</td><td>1,102</td></tr>
</table>
''',
    );
  }

  // ── 2. Typography: text-align / text-indent ────────────────────────────────

  Widget _typographyPanel(BuildContext context) {
    final css = 'text-align: $_textAlign; '
        'text-indent: ${_textIndent.round()}px';

    return _panel(
      context,
      icon: Icons.format_align_justify,
      title: 'text-align (incl. justify) & text-indent',
      blurb: '`justify` distributes the leftover space across the real '
          'inter-word gaps so every line but the last reaches the right edge — '
          'it is not a fake letter-spacing stretch. `text-indent` shifts only '
          'the first line, and selection follows the shifted glyphs.',
      controls: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'left', label: Text('left')),
            ButtonSegment(value: 'center', label: Text('center')),
            ButtonSegment(value: 'right', label: Text('right')),
            ButtonSegment(value: 'justify', label: Text('justify')),
          ],
          selected: {_textAlign},
          onSelectionChanged: (s) => setState(() => _textAlign = s.first),
        ),
        _slider(
          label: 'text-indent',
          value: _textIndent,
          min: 0,
          max: 60,
          divisions: 12,
          suffix: 'px',
          onChanged: (v) => setState(() => _textIndent = v),
        ),
      ],
      css: css,
      html: '''
<p style="$css">
Typography is the craft of arranging type so that the reader never notices the
arrangement at all. When the measure is right and the spacing is even, the eye
moves along the line without effort and the words do the work.
</p>
''',
    );
  }

  // ── 3. Width constraints ───────────────────────────────────────────────────

  Widget _widthPanel(BuildContext context) {
    final css = 'max-width: ${_widthPercent.round()}%; '
        '${_minWidthPx > 0 ? 'min-width: ${_minWidthPx.round()}px; ' : ''}'
        'background: rgba(0,105,92,0.08); padding: 12px';

    return _panel(
      context,
      icon: Icons.width_normal,
      title: 'width / min-width / max-width — px and %',
      blurb: 'A percentage resolves against the containing block, not the '
          'viewport, and it constrains the *content* width so the text really '
          'rewraps inside it. `min-width` wins over `max-width`, exactly as CSS '
          'specifies — push it past the max and watch the box widen again.',
      controls: [
        _slider(
          label: 'max-width',
          value: _widthPercent,
          min: 20,
          max: 100,
          divisions: 16,
          suffix: '%',
          onChanged: (v) => setState(() => _widthPercent = v),
        ),
        _slider(
          label: 'min-width (0 = unset)',
          value: _minWidthPx,
          min: 0,
          max: 320,
          divisions: 16,
          suffix: 'px',
          onChanged: (v) => setState(() => _minWidthPx = v),
        ),
      ],
      css: css,
      html: '''
<div style="$css">
This block is constrained by the values above. The text rewraps to fit the
resolved content width rather than overflowing or being clipped.
</div>
''',
    );
  }

  // ── 4. System text scaling (WCAG 1.4.4) ────────────────────────────────────

  Widget _textScalingPanel(BuildContext context) {
    return _panel(
      context,
      icon: Icons.accessibility_new,
      title: 'System text scaling — WCAG 2.1 AA §1.4.4',
      blurb: 'Rendered text now honours the OS "large text" setting the same '
          'way a Flutter `Text` widget does. The slider stands in for that '
          'system setting: metrics, line height and strut all scale together, '
          'so the layout stays correct instead of just getting bigger glyphs.',
      controls: [
        _slider(
          label: 'textScaler',
          value: _textScale,
          min: 0.8,
          max: 2.0,
          divisions: 12,
          suffix: '×',
          decimals: 1,
          onChanged: (v) => setState(() => _textScale = v),
        ),
      ],
      css: 'MediaQuery(textScaler: TextScaler.linear('
          '${_textScale.toStringAsFixed(1)}))',
      // The viewer reads MediaQuery.textScalerOf(context), so overriding the
      // MediaQuery here is exactly what the OS setting does in a real app.
      childOverride: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(_textScale),
        ),
        child: const HyperViewer(
          html: '<h3>Readable at any size</h3>'
              '<p>Accessibility is not a feature you add at the end. '
              'Text that refuses to scale is text some of your users '
              'simply cannot read.</p>',
          selectable: true,
        ),
      ),
    );
  }

  // ── 5. animation-play-state ────────────────────────────────────────────────

  Widget _animationPanel(BuildContext context) {
    final state = _animationRunning ? 'running' : 'paused';
    return _panel(
      context,
      icon: _animationRunning ? Icons.pause_circle : Icons.play_circle,
      title: 'animation-play-state',
      blurb: 'Pausing holds the current frame rather than resetting it, and '
          'resuming continues from exactly there. The frame loop also stops '
          'scheduling while paused, so a paused animation costs nothing.',
      controls: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
                value: true,
                label: Text('running'),
                icon: Icon(Icons.play_arrow)),
            ButtonSegment(
                value: false, label: Text('paused'), icon: Icon(Icons.pause)),
          ],
          selected: {_animationRunning},
          onSelectionChanged: (s) =>
              setState(() => _animationRunning = s.first),
        ),
      ],
      css: 'animation: pulse 1.6s ease-in-out infinite; '
          'animation-play-state: $state',
      html: '''
<style>
@keyframes pulse {
  0%   { opacity: 0.35; transform: scale(0.94); }
  50%  { opacity: 1;    transform: scale(1.04); }
  100% { opacity: 0.35; transform: scale(0.94); }
}
</style>
<div style="animation: pulse 1.6s ease-in-out infinite;
            animation-play-state: $state;
            background: #00695C; color: #ffffff;
            padding: 16px; text-align: center;">
  <strong>$state</strong>
</div>
''',
    );
  }

  // ── 6. RTL text-align override ─────────────────────────────────────────────

  Widget _rtlPanel(BuildContext context) {
    return _panel(
      context,
      icon: Icons.swap_horiz,
      title: 'text-align on a right-to-left tree',
      blurb: 'An RTL paragraph packs to the right by default (CSS `start`). '
          'An explicit `text-align` now overrides that — but leaving it unset '
          'keeps the correct RTL behaviour, so the common case is unchanged.',
      css: 'textDirection: rtl + explicit text-align',
      childOverride: const HyperViewer(
        html: '<p>مرحبا بالعالم — default (start → right)</p>'
            '<p style="text-align: left;">مرحبا بالعالم — explicit left</p>'
            '<p style="text-align: center;">مرحبا بالعالم — explicit center</p>',
        textDirection: TextDirection.rtl,
        selectable: true,
      ),
    );
  }

  // ── 7. <ol start> ──────────────────────────────────────────────────────────

  Widget _listStartPanel(BuildContext context) {
    return _panel(
      context,
      icon: Icons.format_list_numbered,
      title: '<ol start="N">',
      blurb: 'Ordered lists begin at the requested number instead of always '
          'restarting at 1 — needed whenever a list is split across sections.',
      css: '<ol start="7">',
      html: '''
<ol start="7">
  <li>Continues from seven</li>
  <li>Then eight</li>
</ol>
<ol>
  <li>A sibling list keeps its own counter</li>
</ol>
''',
    );
  }

  // ── Shared panel scaffolding ───────────────────────────────────────────────

  Widget _panel(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String blurb,
    required String css,
    String? html,
    Widget? childOverride,
    List<Widget> controls = const [],
  }) {
    assert(html != null || childOverride != null);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: _accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              blurb,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (controls.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...controls,
            ],
            const SizedBox(height: 12),
            // The CSS actually in effect, so the panel is self-documenting.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                css,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: childOverride ??
                  HyperViewer(
                    html: html!,
                    selectable: true,
                    // sync keeps every panel deterministic: these snippets are
                    // far below the virtualisation threshold anyway, and the
                    // controls rebuild them on every drag.
                    mode: HyperRenderMode.sync,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String suffix = '',
    int decimals = 0,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: _accent,
            label: '${value.toStringAsFixed(decimals)}$suffix',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            '${value.toStringAsFixed(decimals)}$suffix',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
