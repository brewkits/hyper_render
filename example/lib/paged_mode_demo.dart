// Demo for HyperRenderMode.paged — PageView-based e-book / reader UI.
// Shows HyperPageController navigation and live page indicator.

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'html_preview_helper.dart';

const _kChapterHtml = '''
<h1>Chapter 1: The Beginning</h1>
<p>HyperRender supports a <strong>paged mode</strong> that renders one document
section per page — ideal for e-book readers, article viewers, and reading apps.</p>
<p>Each section maps to one page in a <code>PageView</code>. Navigation is driven
by a <code>HyperPageController</code> that you supply from the outside.</p>

<h2>Features</h2>
<ul>
  <li>One document chunk per page</li>
  <li>Programmatic navigation (<code>nextPage</code>, <code>animateToPage</code>)</li>
  <li>Reactive <code>ValueNotifier&lt;int&gt; currentPage</code> for page indicators</li>
  <li>Optional <code>enableZoom: true</code> wraps each page in InteractiveViewer</li>
</ul>

<h1>Chapter 2: How It Works</h1>
<p>The HTML is parsed and split into <em>DocumentNode</em> sections at heading
boundaries. Each section is laid out independently in a
<code>RepaintBoundary</code>, so Flutter only repaints the visible page.</p>
<p>The dirty-flag incremental layout introduced in v1.2.0 means unchanged sections
are reused across re-parses — a significant performance win for live-updating
content like RSS feeds or CMS previews.</p>

<h1>Chapter 3: CSS Support</h1>
<p>All HyperRender CSS features work inside paged mode:</p>
<ul>
  <li>CSS floats — text wraps around images</li>
  <li>Flexbox and CSS Grid</li>
  <li>CSS animations via <code>@keyframes</code></li>
  <li>Custom fonts, text-shadow, box-shadow</li>
</ul>
<blockquote>
  <p><em>"The best renderer is the one you don't notice."</em></p>
</blockquote>

<h1>Chapter 4: Next Steps</h1>
<p>Check the <a href="https://github.com/brewkits/hyper_render">GitHub repo</a>
for full API docs, more demos, and the plugin development guide.</p>
<p>Try enabling <strong>zoom</strong> with the button in the top-right corner of
this demo to see <code>InteractiveViewer</code> in action inside paged mode.</p>
''';

class PagedModeDemo extends StatefulWidget {
  const PagedModeDemo({super.key});

  @override
  State<PagedModeDemo> createState() => _PagedModeDemoState();
}

class _PagedModeDemoState extends State<PagedModeDemo> {
  late final HyperPageController _ctrl;
  bool _enableZoom = false;

  @override
  void initState() {
    super.initState();
    _ctrl = HyperPageController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Paged Mode',
      html: _kChapterHtml,
      actions: [
        IconButton(
          tooltip: _enableZoom ? 'Disable zoom' : 'Enable zoom',
          icon: Icon(_enableZoom ? Icons.zoom_out : Icons.zoom_in),
          onPressed: () => setState(() => _enableZoom = !_enableZoom),
        ),
      ],
      child: Column(
        children: [
          Expanded(
            child: HyperViewer(
              html: _kChapterHtml,
              mode: HyperRenderMode.paged,
              pageController: _ctrl,
              enableZoom: _enableZoom,
            ),
          ),
          _PageBar(ctrl: _ctrl),
        ],
      ),
    );
  }
}

class _PageBar extends StatefulWidget {
  const _PageBar({required this.ctrl});
  final HyperPageController ctrl;

  @override
  State<_PageBar> createState() => _PageBarState();
}

class _PageBarState extends State<_PageBar> {
  @override
  void initState() {
    super.initState();
    widget.ctrl.currentPage.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    widget.ctrl.currentPage.removeListener(_onPageChanged);
    super.dispose();
  }

  void _onPageChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final page = widget.ctrl.currentPage.value;
    final count = widget.ctrl.pageCount;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: page > 0
                ? () => widget.ctrl.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                count > 0 ? 'Page ${page + 1} of $count' : '…',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: count > 0 && page < count - 1
                ? () => widget.ctrl.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
          ),
        ],
      ),
    );
  }
}
