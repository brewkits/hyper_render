import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

/// A guided tour of what actually makes HyperRender different.
///
/// The app has 30+ demos, each drilling into one area. That's the right shape
/// for someone evaluating a specific feature, and the wrong shape for someone
/// asking "why would I use this at all?" — the answer is spread across a dozen
/// screens. This tour is the second shape: one linear pass, each step a live
/// rendering plus one line on why it matters, in the order that builds the
/// argument.
///
/// Every claim here is one the project can back: the float uniqueness is
/// verified against both competitors' source, the CSS count is reproducible by
/// counting declaration handlers, and the architectural points are visible in
/// the code. No frame-rate or memory numbers — see doc/COMPARISON_MATRIX.md for
/// why those are deliberately absent.
class EssenceTourDemo extends StatefulWidget {
  const EssenceTourDemo({super.key});

  @override
  State<EssenceTourDemo> createState() => _EssenceTourDemoState();
}

class _EssenceTourDemoState extends State<EssenceTourDemo> {
  final _controller = PageController();
  int _page = 0;

  static const _accent = Color(0xFF1A56DB);

  late final List<_TourStep> _steps = [
    // ── 1. The one nobody else has ────────────────────────────────────────
    const _TourStep(
      icon: Icons.view_quilt,
      title: 'CSS float — the one nobody else has',
      why: 'Magazine layouts, blogs and HTML email all wrap text around '
          'images. A widget-tree renderer maps each tag to a widget, and a '
          'widget cannot know where the previous widget\'s last line ended — '
          'so the image gets its own row and the text starts below it. '
          'HyperRender lays the whole document out on one canvas, so the line '
          'breaker knows exactly which space the float occupies.',
      claim: 'Verified against flutter_html and FWFH source: neither '
          'implements float.',
      html: '''
<img src="https://picsum.photos/seed/tour_float/120/120"
     style="float:left; width:120px; height:120px; border-radius:10px;
            margin:0 14px 8px 0;" />
<p>Text flows around the floated image, line by line, and continues underneath
once it runs past the bottom edge — the same way a browser does it. Resize the
window and the wrap recomputes; the image never sits on a line of its own.</p>
<p>A second paragraph keeps respecting the same float.</p>
<div style="clear:both;"></div>
''',
    ),

    // ── 2. CJK typography ─────────────────────────────────────────────────
    const _TourStep(
      icon: Icons.translate,
      title: 'Ruby annotations & CJK line breaking',
      why: 'Japanese, Chinese and Korean text needs furigana sitting ABOVE '
          'the base characters, and line breaks that never strand punctuation '
          'at the start of a line (kinsoku shori). Without native ruby, <rt> '
          'falls inline beside the base and the reading becomes noise.',
      claim: 'Rendered natively — no WebView, no per-character widget tree.',
      html: '''
<p style="font-size:19px; line-height:2.2;">
  <ruby>漢字<rt>かんじ</rt></ruby>に<ruby>振<rt>ふ</rt></ruby>り<ruby>仮名<rt>がな</rt></ruby>を
  <ruby>付<rt>つ</rt></ruby>けて<ruby>読<rt>よ</rt></ruby>みやすくします。
</p>
<p style="font-size:15px; line-height:2;">
  約物（、。「」）が行頭に来ないよう、禁則処理を行います。日本語の文章でも
  自然な改行になります。
</p>
''',
    ),

    // ── 3. Selection across the whole document ────────────────────────────
    const _TourStep(
      icon: Icons.select_all,
      title: 'One document, one selection',
      why: 'Drag across headings, paragraphs, a list and a table below. The '
          'selection is continuous because the document is a single '
          'RenderObject with one hit-test tree. Renderers built from one '
          'widget per tag select per widget, so the same drag fragments at '
          'every boundary.',
      claim: 'Try it: long-press and drag through the different block types.',
      html: '''
<h3>Select from this heading…</h3>
<p>…through this paragraph, <strong>past the bold run</strong> and the
<span style="background:#fff3a3;">highlighted span</span>, without the
selection breaking apart.</p>
<ul><li>Into a list item</li><li>And the next one</li></ul>
<table style="border-collapse:collapse; width:100%;">
  <tr><td style="border:1px solid #ccc; padding:6px;">…and into</td>
      <td style="border:1px solid #ccc; padding:6px;">a table cell.</td></tr>
</table>
''',
    ),

    // ── 4. Real CSS engine ────────────────────────────────────────────────
    const _TourStep(
      icon: Icons.style,
      title: 'A real CSS engine, not a style mapper',
      why: 'The cascade, specificity, inheritance and shorthands are '
          'implemented — so a <style> block behaves the way the author '
          'expected, instead of only inline attributes being honoured.',
      claim: '189 CSS declarations handled, counted from the parser source '
          '(flutter_html: 51).',
      html: '''
<style>
  .card { background:#eef2ff; border-left:4px solid #1a56db; padding:12px;
          border-radius:8px; }
  .card h4 { color:#1a56db; margin:0 0 6px 0; }
  .card p  { margin:0; color:#334155; }
  #special { background:#fef9c3; border-left-color:#ca8a04; }
  #special h4 { color:#a16207; }
</style>
<div class="card"><h4>Class selector</h4><p>Styled from a &lt;style&gt; block.</p></div>
<div class="card" id="special"><h4>ID beats class</h4>
  <p>Specificity resolved the way CSS specifies.</p></div>
''',
    ),

    // ── 5. Layout systems ─────────────────────────────────────────────────
    const _TourStep(
      icon: Icons.dashboard,
      title: 'Flexbox, Grid and tables that behave',
      why: 'Content from a CMS or an email template uses whatever layout the '
          'author reached for. Flex and grid containers lay out as containers, '
          'and tables get a W3C-style two-pass column algorithm with colspan '
          'and rowspan — not a best-effort approximation.',
      claim: 'Same markup a browser would take.',
      html: '''
<div style="display:flex; gap:8px; margin-bottom:12px;">
  <div style="flex:2; background:#dbeafe; padding:10px; border-radius:6px;">flex: 2</div>
  <div style="flex:1; background:#bfdbfe; padding:10px; border-radius:6px;">flex: 1</div>
</div>
<div style="display:grid; grid-template-columns: 1fr 1fr 1fr; gap:8px;
            margin-bottom:12px;">
  <div style="background:#e0e7ff; padding:10px; border-radius:6px;">grid</div>
  <div style="background:#e0e7ff; padding:10px; border-radius:6px;">3 × 1fr</div>
  <div style="background:#e0e7ff; padding:10px; border-radius:6px;">columns</div>
</div>
<table style="border-collapse:collapse; width:100%;">
  <tr><th colspan="2" style="border:1px solid #94a3b8; padding:6px;
      background:#f1f5f9;">colspan = 2</th></tr>
  <tr><td rowspan="2" style="border:1px solid #94a3b8; padding:6px;">rowspan<br/>= 2</td>
      <td style="border:1px solid #94a3b8; padding:6px;">cell</td></tr>
  <tr><td style="border:1px solid #94a3b8; padding:6px;">cell</td></tr>
</table>
''',
    ),

    // ── 6. Accessibility ──────────────────────────────────────────────────
    const _TourStep(
      icon: Icons.accessibility_new,
      title: 'Accessible by default',
      why: 'Headings, links, images and lists are exposed to screen readers '
          'with the right roles, and text honours the system "large text" '
          'setting the same way a Flutter Text does — WCAG 2.1 AA §1.4.4. '
          'Content that refuses to scale is content some users cannot read.',
      claim: 'Semantics tree + text scaling, not an afterthought.',
      html: '''
<h3>A real heading (announced as one)</h3>
<p>A <a href="https://example.com">link with an accessible name</a>, an image
with alt text, and a list — all exposed with the correct roles.</p>
<img src="https://picsum.photos/seed/tour_a11y/80/80"
     alt="Descriptive alt text" style="width:80px; border-radius:6px;" />
<ol><li>Ordered item one</li><li>Ordered item two</li></ol>
''',
    ),

    // ── 7. Safety ─────────────────────────────────────────────────────────
    const _TourStep(
      icon: Icons.shield,
      title: 'Safe with untrusted HTML',
      why: 'Rendering user-generated or emailed HTML means rendering whatever '
          'someone else wrote. Sanitisation is ON by default: scripts never '
          'run (there is no JS engine at all), and dangerous URL schemes are '
          'blocked before they reach a tap handler or an image loader.',
      claim: 'The markup below contains a script tag and a javascript: link — '
          'neither does anything.',
      html: '''
<p>Trusted content renders normally.</p>
<script>alert('this never runs');</script>
<p><a href="javascript:alert('blocked')">This link is neutralised</a> —
tapping it does nothing.</p>
<img src="javascript:alert('blocked')" alt="blocked image source" />
<p style="color:#15803d;">Everything above rendered safely.</p>
''',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildDemoAppBar(
        context,
        title: 'Why HyperRender — the tour',
        accent: _accent,
      ),
      body: Column(
        children: [
          _progress(context),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _steps.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => _stepView(context, _steps[i], i),
            ),
          ),
          _navBar(context),
        ],
      ),
    );
  }

  Widget _progress(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= _page
                      ? _accent
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i != _steps.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  Widget _stepView(BuildContext context, _TourStep step, int index) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Row(
          children: [
            Icon(step.icon, color: _accent, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${index + 1}. ${step.title}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, height: 1.25),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          step.why,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: scheme.onSurface.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border(left: BorderSide(color: _accent, width: 3)),
          ),
          child: Text(
            step.claim,
            style:
                TextStyle(fontSize: 12.5, height: 1.4, color: scheme.onSurface),
          ),
        ),
        const SizedBox(height: 14),
        // The live rendering — the actual argument.
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(12),
          child: HyperViewer(
            html: step.html,
            mode: HyperRenderMode.sync,
            selectable: true,
          ),
        ),
      ],
    );
  }

  Widget _navBar(BuildContext context) {
    final isLast = _page == _steps.length - 1;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _page == 0
                  ? null
                  : () => _controller.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
              icon: const Icon(Icons.chevron_left),
              label: const Text('Back'),
            ),
            const Spacer(),
            Text('${_page + 1} / ${_steps.length}',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6))),
            const Spacer(),
            FilledButton.icon(
              onPressed: isLast
                  ? () => Navigator.of(context).pop()
                  : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
              icon: Icon(isLast ? Icons.check : Icons.chevron_right),
              label: Text(isLast ? 'Done' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourStep {
  final IconData icon;
  final String title;

  /// Why this matters to someone shipping an app — the part a feature list
  /// leaves out.
  final String why;

  /// The specific, checkable claim behind the step.
  final String claim;

  /// Markup rendered live underneath, so the step is demonstrated, not asserted.
  final String html;

  const _TourStep({
    required this.icon,
    required this.title,
    required this.why,
    required this.claim,
    required this.html,
  });
}
