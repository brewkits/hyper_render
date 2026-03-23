import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

/// Enterprise Features Demo
///
/// Showcases the battle-hardened features added for production / super-app use:
///   Tab 0 — Resource Safety   : image.dispose(), Isolate cancellation
///   Tab 1 — Error Handling    : onError routing, FlutterError fallback
///   Tab 2 — Device Tuning     : HyperRenderConfig for low / mid / high-end
///   Tab 3 — Deeplink Security : allowedCustomSchemes whitelist
///   Tab 4 — Zoom Modes        : zoom in sync vs virtualized mode
class EnterpriseFeaturesDemo extends StatefulWidget {
  const EnterpriseFeaturesDemo({super.key});

  @override
  State<EnterpriseFeaturesDemo> createState() => _EnterpriseFeaturesDemoState();
}

class _EnterpriseFeaturesDemoState extends State<EnterpriseFeaturesDemo>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Features'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(icon: Icon(Icons.memory), text: 'Resources'),
            Tab(icon: Icon(Icons.error_outline), text: 'Errors'),
            Tab(icon: Icon(Icons.tune), text: 'Device Tuning'),
            Tab(icon: Icon(Icons.link), text: 'Deep Links'),
            Tab(icon: Icon(Icons.zoom_in), text: 'Zoom'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _ResourceSafetyTab(),
          _ErrorHandlingTab(),
          _DeviceTuningTab(),
          _DeeplinkSecurityTab(),
          _ZoomModesTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0 — Resource Safety
// ─────────────────────────────────────────────────────────────────────────────

class _ResourceSafetyTab extends StatefulWidget {
  const _ResourceSafetyTab();

  @override
  State<_ResourceSafetyTab> createState() => _ResourceSafetyTabState();
}

class _ResourceSafetyTabState extends State<_ResourceSafetyTab> {
  bool _showViewer = true;
  int _generation = 0;

  static const _html = '''
<h2>GPU Memory Safety</h2>
<p>When you navigate <strong>back</strong> while images are loading,
   HyperRender calls <code>image.dispose()</code> on every in-flight
   <code>ui.Image</code> before returning — releasing VRAM immediately
   rather than waiting for the Dart GC.</p>

<img src="https://picsum.photos/seed/enterprise1/400/200" alt="Test image 1">
<img src="https://picsum.photos/seed/enterprise2/400/200" alt="Test image 2">
<img src="https://picsum.photos/seed/enterprise3/400/200" alt="Test image 3">

<h3>Isolate Cancellation</h3>
<p>Every parse of large HTML runs in a dedicated <code>Isolate</code>
   spawned via <code>Isolate.spawn()</code>. Tapping <em>Unmount</em>
   below calls <code>_cancelParsing()</code> which sends
   <code>Isolate.kill(priority: Isolate.immediate)</code> —
   no orphaned isolate burns CPU after the user navigates away.</p>
''';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          color: const Color(0xFF1A237E),
          icon: Icons.shield,
          title: 'GPU Resource Safety',
          subtitle:
              'image.dispose() + Isolate.kill() prevent VRAM & CPU leaks',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: _showViewer ? 'Unmount viewer' : 'Mount viewer',
                icon: _showViewer ? Icons.stop : Icons.play_arrow,
                color:
                    _showViewer ? Colors.red.shade700 : Colors.green.shade700,
                onTap: () => setState(() => _showViewer = !_showViewer),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: 'Reload content',
                icon: Icons.refresh,
                color: Colors.indigo,
                onTap: () => setState(() => _generation++),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_showViewer)
          Container(
            height: 400,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.indigo.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: HyperViewer(
                key: ValueKey(_generation),
                html: _html,
              ),
            ),
          )
        else
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              'Viewer unmounted — all GPU textures & isolates released',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 16),
        _InfoBox(
          title: 'What happens under the hood',
          items: const [
            '• dispose() called → _cancelParsing() → Isolate.kill()',
            '• Every ui.Image in _imageCache gets image.dispose()',
            '• ReceivePort closed → no ghost callbacks fire',
            '• TextPainter LRU cache evicts painters via onEvict',
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Error Handling
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorHandlingTab extends StatefulWidget {
  const _ErrorHandlingTab();

  @override
  State<_ErrorHandlingTab> createState() => _ErrorHandlingTabState();
}

class _ErrorHandlingTabState extends State<_ErrorHandlingTab> {
  String? _lastError;
  int _scenario = 0;

  static const _scenarios = [
    ('Valid HTML', '<h2>Normal content</h2><p>Everything is fine here.</p>'),
    (
      'Malformed HTML',
      '<div><p>Unclosed paragraph<div>Mismatched<span>tags</p></div>',
    ),
    (
      'Empty content',
      '',
    ),
    (
      'Only whitespace',
      '   \n\t\n   ',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final (label, html) = _scenarios[_scenario];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          color: Colors.orange.shade800,
          icon: Icons.error_outline,
          title: 'Graceful Error Handling',
          subtitle:
              'onError routes to your handler; FlutterError.reportError as fallback',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_scenarios.length, (i) {
            return ChoiceChip(
              label: Text(_scenarios[i].$1),
              selected: _scenario == i,
              onSelected: (_) => setState(() {
                _scenario = i;
                _lastError = null;
              }),
            );
          }),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade200),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade800, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Scenario: $label',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 220,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: HyperViewer(
              html: html,
              onError: (error, stack) {
                setState(() => _lastError = error.toString());
              },
              placeholderBuilder: (_) => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_lastError != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.bug_report, color: Colors.red.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'onError received:\n$_lastError',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                const SizedBox(width: 8),
                Text(
                  'No errors — rendered successfully',
                  style: TextStyle(color: Colors.green.shade800),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        _InfoBox(
          title: 'How error routing works',
          items: const [
            '• onError provided → your callback receives (error, stackTrace)',
            '• onError absent → FlutterError.reportError() → Crashlytics/Sentry',
            '• Applies to sync parse, isolate errors, Delta/Markdown parse',
            '• Widget stays alive — never crashes the app',
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Device Tuning via HyperRenderConfig
// ─────────────────────────────────────────────────────────────────────────────

class _DeviceTuningTab extends StatefulWidget {
  const _DeviceTuningTab();

  @override
  State<_DeviceTuningTab> createState() => _DeviceTuningTabState();
}

class _DeviceTuningTabState extends State<_DeviceTuningTab> {
  int _tier = 1; // 0=low, 1=mid, 2=high

  // Records contain HyperRenderConfig which is const but Color is not
  // const-constructible in all contexts — use final instead of static const.
  static final _configs = [
    (
      'Low-end Android (≤ 2 GB RAM)',
      const HyperRenderConfig(
        textPainterCacheSize: 200,
        imageConcurrency: 1,
        virtualizationChunkSize: 2000,
        defaultImagePlaceholderWidth: 120.0,
      ),
      const Color(0xFFB71C1C),
      Icons.smartphone,
    ),
    (
      'Mid-range (Default)',
      HyperRenderConfig.defaults,
      const Color(0xFF1565C0),
      Icons.phone_android,
    ),
    (
      'Flagship / Tablet (≥ 8 GB RAM)',
      const HyperRenderConfig(
        textPainterCacheSize: 10000,
        imageConcurrency: 6,
        virtualizationChunkSize: 12000,
        defaultImagePlaceholderWidth: 400.0,
      ),
      const Color(0xFF1B5E20),
      Icons.tablet,
    ),
  ];

  static const _html = '''
<h2>Performance Tuning</h2>
<p>HyperRender adapts to the target device tier via
   <code>HyperRenderConfig</code>. Each parameter is documented with its
   impact on memory vs. speed trade-offs.</p>

<h3>What each parameter controls</h3>
<ul>
  <li><code>textPainterCacheSize</code> — LRU slots for <code>TextPainter</code> objects.
      More slots → faster re-render; more Dart heap.</li>
  <li><code>imageConcurrency</code> — parallel image downloads.
      Lower on slow networks or weak CPUs.</li>
  <li><code>virtualizationChunkSize</code> — characters per
      <code>RepaintBoundary</code> chunk. Smaller → each chunk renders faster
      but more chunks overall.</li>
  <li><code>defaultImagePlaceholderWidth</code> — placeholder box width
      before the real image loads. Match to your typical image width.</li>
</ul>

<h3>GPU texture limit</h3>
<p>Each chunk stays under the GPU's <code>GL_MAX_TEXTURE_SIZE</code>
   (~4096 px on most Android devices). Smaller chunks = smaller textures.</p>
''';

  @override
  Widget build(BuildContext context) {
    final (name, config, color, icon) = _configs[_tier];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          color: color,
          icon: icon,
          title: name,
          subtitle: 'HyperRenderConfig tuned for this device class',
        ),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Low'), icon: Icon(Icons.battery_alert)),
            ButtonSegment(value: 1, label: Text('Mid'), icon: Icon(Icons.battery_std)),
            ButtonSegment(value: 2, label: Text('High'), icon: Icon(Icons.battery_full)),
          ],
          selected: {_tier},
          onSelectionChanged: (s) => setState(() => _tier = s.first),
        ),
        const SizedBox(height: 16),
        _ConfigTable(config: config, color: color),
        const SizedBox(height: 16),
        Container(
          height: 360,
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: HyperViewer(
              key: ValueKey(_tier),
              html: _html,
              renderConfig: config,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfigTable extends StatelessWidget {
  const _ConfigTable({required this.config, required this.color});

  final HyperRenderConfig config;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('textPainterCacheSize', '${config.textPainterCacheSize}', 'Dart heap'),
      ('imageConcurrency', '${config.imageConcurrency}', 'Network threads'),
      ('virtualizationChunkSize', '${config.virtualizationChunkSize}', 'Chars/chunk'),
      ('imagePlaceholderWidth',
          '${config.defaultImagePlaceholderWidth.toStringAsFixed(0)} px',
          'Placeholder'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: rows.map((r) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    r.$1,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    r.$2,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.$3,
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Deeplink Security / allowedCustomSchemes
// ─────────────────────────────────────────────────────────────────────────────

class _DeeplinkSecurityTab extends StatefulWidget {
  const _DeeplinkSecurityTab();

  @override
  State<_DeeplinkSecurityTab> createState() => _DeeplinkSecurityTabState();
}

class _DeeplinkSecurityTabState extends State<_DeeplinkSecurityTab> {
  final List<String> _tappedUrls = [];
  final List<String> _blockedUrls = [];
  List<String> _customSchemes = ['shopee', 'myapp', 'momo'];

  static const _html = '''
<h2>URL Scheme Whitelist</h2>
<p>Tap the links below. HyperRender checks every URL against the
   <strong>built-in whitelist</strong> (http, https, mailto, tel) plus
   your <code>allowedCustomSchemes</code> before forwarding to your handler.</p>

<h3>Allowed schemes</h3>
<p><a href="https://example.com">https://example.com</a> — always allowed</p>
<p><a href="mailto:support@example.com">mailto:support@example.com</a> — always allowed</p>
<p><a href="tel:+84123456789">tel:+84123456789</a> — always allowed</p>
<p><a href="shopee://product/SKU-12345">shopee://product/SKU-12345</a> — custom scheme</p>
<p><a href="myapp://screen/profile">myapp://screen/profile</a> — custom scheme</p>
<p><a href="momo://pay?amount=50000">momo://pay?amount=50000</a> — custom scheme</p>

<h3>Blocked schemes</h3>
<p><a href="javascript:alert(1)">javascript:alert(1)</a> — always blocked</p>
<p><a href="data:text/html,<h1>injected</h1>">data: injection</a> — always blocked</p>
<p><a href="file:///etc/passwd">file:///etc/passwd</a> — always blocked</p>
<p><a href="unknown://deeplink">unknown://deeplink</a> — not in allowedCustomSchemes</p>
''';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          color: DemoColors.success,
          icon: Icons.security,
          title: 'Deep Link Security',
          subtitle:
              'allowedCustomSchemes extends the built-in scheme whitelist safely',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'allowedCustomSchemes:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  ..._customSchemes.map(
                    (s) => Chip(
                      label: Text(s),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () =>
                          setState(() => _customSchemes.remove(s)),
                    ),
                  ),
                  ActionChip(
                    label: const Text('+ shopify'),
                    onPressed: () {
                      if (!_customSchemes.contains('shopify')) {
                        setState(() => _customSchemes.add('shopify'));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 340,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: HyperViewer(
              key: ValueKey(_customSchemes.join(',')),
              html: _html,
              sanitize: false, // keep all hrefs for the demo
              allowedCustomSchemes: _customSchemes,
              onLinkTap: (url) {
                setState(() => _tappedUrls.insert(0, url));
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_tappedUrls.isNotEmpty) ...[
          const Text(
            'Forwarded to onLinkTap:',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.green),
          ),
          const SizedBox(height: 4),
          ..._tappedUrls.take(5).map(
                (u) => Text(
                  '✓ $u',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
          const SizedBox(height: 8),
        ],
        _InfoBox(
          title: 'Security model',
          items: const [
            '• Built-in allow: http, https, mailto, tel',
            '• Add enterprise deeplinks via allowedCustomSchemes',
            '• javascript:, data:, file: always blocked (no override)',
            '• Unknown schemes silently dropped — no error thrown',
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4 — Zoom Modes
// ─────────────────────────────────────────────────────────────────────────────

class _ZoomModesTab extends StatefulWidget {
  const _ZoomModesTab();

  @override
  State<_ZoomModesTab> createState() => _ZoomModesTabState();
}

class _ZoomModesTabState extends State<_ZoomModesTab> {
  bool _zoom = true;
  bool _virtualized = false;
  double _minScale = 0.5;
  double _maxScale = 4.0;

  static const _shortHtml = '''
<h2>Pinch to Zoom</h2>
<p>This content uses <strong>sync mode</strong>. InteractiveViewer wraps the
   entire widget tree, providing pinch-to-zoom and pan gestures.</p>
<table border="1" style="width:100%;border-collapse:collapse">
  <tr><th>Feature</th><th>Sync Mode</th><th>Virtualized Mode</th></tr>
  <tr><td>Zoom</td><td>✅</td><td>✅ (panEnabled: false)</td></tr>
  <tr><td>Pan</td><td>✅</td><td>❌ (ListView scrolls instead)</td></tr>
  <tr><td>Long docs</td><td>⚠️ may be slow</td><td>✅ virtualised</td></tr>
</table>
<p style="color:#666;font-size:14px;margin-top:8px">
  In virtualized mode, <code>panEnabled: false</code> ensures that
  ListView keeps scroll ownership while InteractiveViewer handles
  only the pinch-scale gesture — no gesture conflicts.
</p>
''';

  String get _html => _virtualized
      ? '<p>${'Virtualized content with many words. ' * 500}</p>$_shortHtml'
      : _shortHtml;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          color: Colors.purple.shade800,
          icon: Icons.zoom_in,
          title: 'Zoom in All Modes',
          subtitle:
              'InteractiveViewer in sync; panEnabled:false in virtualized',
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Enable zoom'),
          subtitle: const Text('Wraps content in InteractiveViewer'),
          value: _zoom,
          onChanged: (v) => setState(() => _zoom = v),
          activeColor: Colors.purple,
        ),
        SwitchListTile(
          title: const Text('Virtualized mode'),
          subtitle: const Text('Force async chunked rendering for long content'),
          value: _virtualized,
          onChanged: (v) => setState(() => _virtualized = v),
          activeColor: Colors.purple,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Min scale:'),
            Expanded(
              child: Slider(
                value: _minScale,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: _minScale.toStringAsFixed(1),
                onChanged: (v) => setState(() => _minScale = v),
                activeColor: Colors.purple,
              ),
            ),
            Text(_minScale.toStringAsFixed(1)),
          ],
        ),
        Row(
          children: [
            const Text('Max scale:'),
            Expanded(
              child: Slider(
                value: _maxScale,
                min: 1.0,
                max: 8.0,
                divisions: 14,
                label: _maxScale.toStringAsFixed(1),
                onChanged: (v) => setState(() => _maxScale = v),
                activeColor: Colors.purple,
              ),
            ),
            Text(_maxScale.toStringAsFixed(1)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 380,
          decoration: BoxDecoration(
            border: Border.all(
              color: _zoom ? Colors.purple.shade300 : Colors.grey.shade300,
              width: _zoom ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: HyperViewer(
              key: ValueKey('$_zoom-$_virtualized-$_minScale-$_maxScale'),
              html: _html,
              mode: _virtualized
                  ? HyperRenderMode.virtualized
                  : HyperRenderMode.sync,
              enableZoom: _zoom,
              minScale: _minScale,
              maxScale: _maxScale,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _InfoBox(
          title: 'Implementation detail',
          items: const [
            '• Sync + zoom → InteractiveViewer(minScale, maxScale, panEnabled: true)',
            '• Virtualized + zoom → InteractiveViewer(panEnabled: false) wraps ListView',
            '• panEnabled: false prevents gesture conflict with ListView scroll',
            '• Pinch-to-zoom still works; ListView keeps vertical scroll ownership',
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared UI components
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
