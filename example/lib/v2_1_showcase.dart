import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:hyper_render_core/hyper_render_core.dart'
    show DesignTokens, SkeletonParagraph, SkeletonListItem, SkeletonCard;

/// Advanced Features Showcase
/// Demonstrates Error Boundaries, Performance, Dark Mode, Skeletons, Animations
class V21Showcase extends StatefulWidget {
  const V21Showcase({super.key});

  @override
  State<V21Showcase> createState() => _V21ShowcaseState();
}

class _V21ShowcaseState extends State<V21Showcase>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Advanced Features Showcase'),
          centerTitle: false,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            // Dark mode toggle
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              tooltip: 'Toggle Dark Mode',
              onPressed: () {
                setState(() => _isDarkMode = !_isDarkMode);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.error_outline), text: 'Error Boundaries'),
              Tab(icon: Icon(Icons.speed), text: 'Performance'),
              Tab(icon: Icon(Icons.dark_mode), text: 'Dark Mode'),
              Tab(icon: Icon(Icons.hourglass_empty), text: 'Skeletons'),
              Tab(icon: Icon(Icons.palette), text: 'Design Tokens'),
              Tab(icon: Icon(Icons.animation), text: 'Animations'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _ErrorBoundariesDemo(),
            _PerformanceMonitoringDemo(),
            _DarkModeDemo(isDarkMode: _isDarkMode),
            _LoadingSkeletonsDemo(),
            _DesignTokensDemo(),
            _AnimationsDemo(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Error Boundaries Demo
// ============================================================================

class _ErrorBoundariesDemo extends StatefulWidget {
  @override
  State<_ErrorBoundariesDemo> createState() => _ErrorBoundariesDemoState();
}

class _ErrorBoundariesDemoState extends State<_ErrorBoundariesDemo> {
  String _selectedScenario = 'parse_error';

  static const Map<String, Map<String, String>> _scenarios = {
    'parse_error': {
      'name': 'Parse Error',
      'html': '<p>Valid content</p><script>Invalid markup',
      'description': 'Malformed HTML that causes parsing errors',
    },
    'network_error': {
      'name': 'Network Error (Image)',
      'html': '<img src="https://invalid-domain-xyz123.com/image.jpg" alt="Broken">',
      'description': 'Images that fail to load',
    },
    'valid_content': {
      'name': 'Valid Content',
      'html': '<h2>Success! ✅</h2><p>This content renders perfectly.</p>',
      'description': 'No errors - everything works',
    },
  };

  @override
  Widget build(BuildContext context) {
    final scenario = _scenarios[_selectedScenario]!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield, color: Colors.orange.shade700, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🛡️ Error Boundaries',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Graceful error handling with beautiful error UI',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text('Supported in v1.0.0:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildFeatureItem('ErrorBoundaryNode - catches parsing errors'),
                _buildFeatureItem('HyperErrorWidget - beautiful error UI'),
                _buildFeatureItem('Automatic error recovery'),
                _buildFeatureItem('Retry functionality'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Scenario selector
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Test Scenario:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedScenario,
                  isExpanded: true,
                  items: _scenarios.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedScenario = value!);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  scenario['description']!,
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Rendered content with error boundary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: scenario['html']!,
              // Errors are automatically caught and displayed
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Code example
        ExpansionTile(
          title: const Text('View Code Example'),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade900,
              child: const SelectableText(
                '''
// Automatic error boundaries
HyperViewer(
  html: htmlContent,
  // Parsing errors caught automatically
)

// Custom error handling
HyperViewer(
  html: content,
  widgetBuilder: (node) {
    if (node is AtomicNode && node.tagName == 'img') {
      return Image.network(
        node.src!,
        errorBuilder: (context, error, stack) {
          return HyperErrorWidget.image(
            message: 'Failed to load image',
            onRetry: () => setState(() {}),
          );
        },
      );
    }
    return null;
  },
)
''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

// ============================================================================
// Performance Monitoring Demo
// ============================================================================

class _PerformanceMonitoringDemo extends StatefulWidget {
  @override
  State<_PerformanceMonitoringDemo> createState() =>
      _PerformanceMonitoringDemoState();
}

class _PerformanceMonitoringDemoState
    extends State<_PerformanceMonitoringDemo> {
  final List<Map<String, dynamic>> _performanceReports = [];
  String _selectedSize = 'small';

  static final Map<String, Map<String, dynamic>> _sizes = {
    'small': {
      'name': 'Small (1KB)',
      'html': '<p>Small content</p>' * 20,
      'target': '< 50ms',
    },
    'medium': {
      'name': 'Medium (10KB)',
      'html': '<p>Medium content with more text. </p>' * 200,
      'target': '< 100ms',
    },
    'large': {
      'name': 'Large (50KB)',
      'html': '<p>Large content with lots of text. </p>' * 1000,
      'target': '< 200ms',
    },
  };

  @override
  Widget build(BuildContext context) {
    final size = _sizes[_selectedSize]!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.speed, color: Colors.blue.shade700, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚡ Performance Monitoring',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Track render performance in production',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text('Supported in v1.0.0:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildFeatureItem('PerformanceMonitor class'),
                _buildFeatureItem('P95/P99 percentile tracking'),
                _buildFeatureItem('Performance ratings'),
                _buildFeatureItem('JSON export for analytics'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Size selector
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document Size:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedSize,
                  isExpanded: true,
                  items: _sizes.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text('${entry.value['name']} - Target: ${entry.value['target']}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSize = value!;
                      _performanceReports.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Render with performance monitoring
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: size['html'],
              // Performance monitoring would go here in real implementation
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Performance reports
        if (_performanceReports.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Reports:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ..._performanceReports.map((report) {
                    return _buildPerformanceReport(report);
                  }),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Code example
        ExpansionTile(
          title: const Text('View Code Example'),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade900,
              child: const SelectableText(
                '''
// Track performance
HyperViewer(
  html: htmlContent,
  onPerformanceReport: (report) {
    print('Parse: \${report.parseTime.inMilliseconds}ms');
    print('Style: \${report.styleTime.inMilliseconds}ms');
    print('Layout: \${report.layoutTime.inMilliseconds}ms');
    print('Rating: \${report.rating}'); // Excellent/Good/Slow

    // Send to analytics
    if (report.totalTime.inMilliseconds > 500) {
      analytics.trackSlowRender(report.toJson());
    }
  },
)

// Or use PerformanceMonitor directly
final monitor = PerformanceMonitor();
final result = monitor.measure('render', () {
  return parser.parse(html);
});
final report = monitor.buildReport();
print('P95: \${report.p95Duration.inMilliseconds}ms');
''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildPerformanceReport(Map<String, dynamic> report) {
    final rating = report['rating'] as String;
    final color = rating == 'Excellent'
        ? Colors.green
        : rating == 'Good'
            ? Colors.blue
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                rating,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '${report['total']}ms',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Parse: ${report['parse']}ms • Style: ${report['style']}ms • Layout: ${report['layout']}ms',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Dark Mode Demo
// ============================================================================

class _DarkModeDemo extends StatelessWidget {
  final bool isDarkMode;

  const _DarkModeDemo({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    const html = '''
<article>
  <h1>Dark Mode Support 🌙</h1>
  <p>All colors automatically adapt to theme brightness!</p>

  <h2>Text Colors</h2>
  <p>Primary text color changes based on theme.</p>
  <p><strong>Bold text</strong> and <em>italic text</em> also adapt.</p>

  <h2>Links</h2>
  <p>Check out <a href="https://flutter.dev">this link</a> - color adapts!</p>

  <h2>Code Blocks</h2>
  <pre><code>// Code background and text adapt
const darkMode = true;
if (darkMode) {
  print('Dark theme active');
}</code></pre>

  <h2>Semantic Colors</h2>
  <p><mark>Highlighted text</mark> adapts to dark mode.</p>
  <blockquote>
    Quotes have proper contrast in both themes.
  </blockquote>
</article>
''';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Card(
          color: isDarkMode ? Colors.grey.shade800 : Colors.indigo.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: isDarkMode ? Colors.yellow : Colors.indigo.shade700,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDarkMode ? '🌙 Dark Mode Active' : '☀️ Light Mode Active',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            '27 context-aware color methods',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text('Supported in v1.0.0:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildFeatureItem('27 context-aware color methods'),
                _buildFeatureItem('Automatic theme detection'),
                _buildFeatureItem('Text, links, code, semantic colors'),
                _buildFeatureItem('Works with nested themes'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Rendered content
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: html,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Color showcase
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Design Tokens Colors:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildColorSwatch(context, 'Text Primary', DesignTokens.getTextPrimary(context)),
                _buildColorSwatch(context, 'Text Secondary', DesignTokens.getTextSecondary(context)),
                _buildColorSwatch(context, 'Link Color', DesignTokens.getLinkColor(context)),
                _buildColorSwatch(context, 'Background', DesignTokens.getBackgroundColor(context)),
                _buildColorSwatch(context, 'Code Background', DesignTokens.getCodeBackground(context)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Code example
        ExpansionTile(
          title: const Text('View Code Example'),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade900,
              child: const SelectableText(
                '''
// Automatic dark mode
MaterialApp(
  theme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  home: HyperViewer(
    html: content,
    // Colors adapt automatically!
  ),
)

// Use design tokens in custom widgets
Container(
  color: DesignTokens.getBackgroundColor(context),
  child: Text(
    'Hello',
    style: TextStyle(
      color: DesignTokens.getTextPrimary(context),
    ),
  ),
)
''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(BuildContext context, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Continued in next part...

// ============================================================================
// Loading Skeletons Demo
// ============================================================================

class _LoadingSkeletonsDemo extends StatefulWidget {
  @override
  State<_LoadingSkeletonsDemo> createState() => _LoadingSkeletonsDemoState();
}

class _LoadingSkeletonsDemoState extends State<_LoadingSkeletonsDemo> {
  bool _showLoading = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Card(
          color: Colors.teal.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.teal.shade700, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⏳ Loading Skeletons',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Beautiful shimmer animations',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text('Supported in v1.0.0:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildFeatureItem('LoadingSkeleton widget'),
                _buildFeatureItem('Pre-built patterns (Card, List, Grid)'),
                _buildFeatureItem('Shimmer animation'),
                _buildFeatureItem('Dark mode support'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Toggle
        Card(
          child: SwitchListTile(
            title: const Text('Show Loading State'),
            value: _showLoading,
            onChanged: (value) {
              setState(() => _showLoading = value);
            },
          ),
        ),

        const SizedBox(height: 16),

        // Examples
        if (_showLoading) ...[
          _buildSkeletonExample(
            'Skeleton Paragraph',
            SkeletonParagraph(lines: 3),
          ),
          _buildSkeletonExample(
            'Skeleton List Item',
            SkeletonListItem(showTrailing: true),
          ),
          _buildSkeletonExample(
            'Skeleton Card',
            SkeletonCard(lines: 4, imageHeight: 150),
          ),
        ] else ...[
          _buildContentExample(
            'Content Loaded',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Article Title',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Lorem ipsum dolor sit amet, consectetur adipiscing elit.'),
                const SizedBox(height: 16),
                Image.network(
                  'https://picsum.photos/400/200',
                  fit: BoxFit.cover,
                  height: 200,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Code example
        ExpansionTile(
          title: const Text('View Code Example'),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade900,
              child: const SelectableText(
                '''
// Basic skeleton
LoadingSkeleton.text(width: 200, height: 16)
LoadingSkeleton.circle(size: 48)
LoadingSkeleton.rectangle(width: 300, height: 200)

// Pre-built patterns
SkeletonParagraph(lines: 3)
SkeletonListItem(showAvatar: true)
SkeletonCard(lines: 4, showImage: true)
SkeletonGrid(itemCount: 6, crossAxisCount: 2)

// With HyperViewer
HyperViewer(
  html: isLoading ? null : content,
  onLoadingBuilder: (context) {
    return SkeletonCard(lines: 5, showAvatar: true);
  },
)
''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSkeletonExample(String title, Widget skeleton) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            skeleton,
          ],
        ),
      ),
    );
  }

  Widget _buildContentExample(String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Design Tokens Demo
// ============================================================================

class _DesignTokensDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Card(
          color: Colors.purple.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette, color: Colors.purple.shade700, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎨 Design Tokens',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Material Design 3 compliant system',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text('Supported in v1.0.0:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildFeatureItem('Typography scale (Display to Label)'),
                _buildFeatureItem('8pt grid spacing system'),
                _buildFeatureItem('Border radius tokens'),
                _buildFeatureItem('Elevation & shadows'),
                _buildFeatureItem('Color palette (light + dark)'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Typography
        _buildSection('Typography', [
          _buildTypoExample('Display', DesignTokens.headingStyle(1)),
          _buildTypoExample('Heading 1', DesignTokens.headingStyle(1)),
          _buildTypoExample('Heading 2', DesignTokens.headingStyle(2)),
          _buildTypoExample('Body', const TextStyle(fontSize: DesignTokens.bodyLargeFontSize)),
        ]),

        // Spacing
        _buildSection('Spacing (8pt Grid)', [
          _buildSpacingExample('space1', DesignTokens.space1),
          _buildSpacingExample('space2', DesignTokens.space2),
          _buildSpacingExample('space3', DesignTokens.space3),
          _buildSpacingExample('space4', DesignTokens.space4),
        ]),

        // Border Radius
        _buildSection('Border Radius', [
          _buildRadiusExample('Small', DesignTokens.radiusSmall),
          _buildRadiusExample('Medium', DesignTokens.radiusMedium),
          _buildRadiusExample('Large', DesignTokens.radiusLarge),
        ]),

        // Elevation
        _buildSection('Elevation', [
          _buildElevationExample('Level 1', DesignTokens.shadow(DesignTokens.elevation1)),
          _buildElevationExample('Level 2', DesignTokens.shadow(DesignTokens.elevation2)),
          _buildElevationExample('Level 3', DesignTokens.shadow(DesignTokens.elevation3)),
        ]),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTypoExample(String label, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text('The quick brown fox', style: style),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacingExample(String label, double space) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label (${space}px)',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Container(
            width: space,
            height: 32,
            color: Colors.blue.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusExample(String label, double radius) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label (${radius}px)',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Container(
            width: 80,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple.shade300,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElevationExample(String label, List<BoxShadow> shadows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Container(
            width: 80,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: shadows,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Animations Demo
// ============================================================================

class _AnimationsDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const html = '''
<article>
  <h1>Smooth Animations</h1>

  <details>
    <summary>Click to expand (Smooth animation!)</summary>
    <p>This content animates smoothly with:</p>
    <ul>
      <li>AnimatedSize for height transition (300ms)</li>
      <li>AnimatedRotation for icon (90° turn)</li>
      <li>Design tokens for timing curves</li>
    </ul>
  </details>

  <details open>
    <summary>Already expanded</summary>
    <p>Click the summary to collapse with animation.</p>
  </details>

  <details>
    <summary>Nested details elements</summary>
    <details>
      <summary>Inner details 1</summary>
      <p>Each level animates independently!</p>
    </details>
    <details>
      <summary>Inner details 2</summary>
      <p>Smooth animations at every level.</p>
    </details>
  </details>
</article>
''';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Card(
          color: Colors.pink.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.animation, color: Colors.pink.shade700, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✨ Smooth Animations',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Details element with animations',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text('Supported in v1.0.0:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildFeatureItem('AnimatedSize for expand/collapse'),
                _buildFeatureItem('AnimatedRotation for icons'),
                _buildFeatureItem('Design tokens timing (300ms)'),
                _buildFeatureItem('Smooth easing curves'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Demo
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: html,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Info
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Try It!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Click on the <summary> elements above to see smooth animations.'),
                const SizedBox(height: 12),
                _buildInfoItem('Height', 'AnimatedSize widget (300ms)'),
                _buildInfoItem('Icon', 'AnimatedRotation (90°)'),
                _buildInfoItem('Timing', 'DesignTokens.durationMedium'),
                _buildInfoItem('Curve', 'DesignTokens.curveStandard'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
