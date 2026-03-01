import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

/// Accessibility Demo - Showcasing Screen Reader Support
class AccessibilityDemo extends StatefulWidget {
  const AccessibilityDemo({super.key});

  @override
  State<AccessibilityDemo> createState() => _AccessibilityDemoState();
}

class _AccessibilityDemoState extends State<AccessibilityDemo> {
  String _selectedContent = 'news_article';
  String _customLabel = '';
  bool _useCustomLabel = false;
  bool _excludeFromSemantics = false;

  static const Map<String, Map<String, String>> _contentExamples = {
    'news_article': {
      'name': 'News Article',
      'defaultLabel': 'Breaking news: Flutter 4.0 released',
      'html': '''
<article>
  <h1>Flutter 4.0 Released! 🎉</h1>
  <p><strong>Mountain View, CA</strong> - Today, Google announced the release of Flutter 4.0 with groundbreaking features.</p>

  <h2>What's New</h2>
  <ul>
    <li>Improved performance (30% faster)</li>
    <li>Better accessibility support</li>
    <li>New Material Design 3 widgets</li>
  </ul>

  <blockquote>
    "This is a game changer for mobile development"
    <footer>— Tim Sneath, Product Manager</footer>
  </blockquote>

  <p>Read more at <a href="https://flutter.dev">flutter.dev</a></p>
</article>
''',
    },
    'blog_post': {
      'name': 'Blog Post',
      'defaultLabel': 'Blog post: 10 tips for Flutter developers',
      'html': '''
<article>
  <h1>10 Tips for Flutter Developers</h1>
  <p>by <em>Jane Doe</em> • Published on Jan 15, 2026</p>

  <h2>Tip 1: Use const constructors</h2>
  <p>Always use <code>const</code> when possible to improve performance.</p>

  <pre><code>const MyWidget()  // Good
MyWidget()        // Not as good</code></pre>

  <h2>Tip 2: Hot reload is your friend</h2>
  <p>Take advantage of Flutter's hot reload for faster development.</p>

  <p><strong>Pro tip:</strong> Use <kbd>Ctrl+S</kbd> to trigger hot reload in VS Code.</p>
</article>
''',
    },
    'product_details': {
      'name': 'Product Details',
      'defaultLabel': 'Product: Premium wireless headphones',
      'html': '''
<article>
  <h1>Premium Wireless Headphones</h1>
  <img src="https://picsum.photos/300/200" alt="Black wireless headphones">

  <p>⭐⭐⭐⭐⭐ <small>(4.8/5 from 1,234 reviews)</small></p>

  <h2>Features</h2>
  <ul>
    <li>Active Noise Cancellation</li>
    <li>30-hour battery life</li>
    <li>Premium comfort</li>
  </ul>

  <p><strong>Price:</strong> \$299.99</p>
  <p><em>Free shipping on orders over \$50</em></p>
</article>
''',
    },
    'recipe': {
      'name': 'Recipe',
      'defaultLabel': 'Recipe: Chocolate chip cookies',
      'html': '''
<article>
  <h1>🍪 Chocolate Chip Cookies</h1>
  <p><strong>Prep time:</strong> 15 minutes | <strong>Cook time:</strong> 12 minutes</p>

  <h2>Ingredients</h2>
  <ul>
    <li>2 cups all-purpose flour</li>
    <li>1 cup butter, softened</li>
    <li>3/4 cup sugar</li>
    <li>2 eggs</li>
    <li>2 cups chocolate chips</li>
  </ul>

  <h2>Instructions</h2>
  <ol>
    <li>Preheat oven to 350°F (175°C)</li>
    <li>Mix butter and sugar until fluffy</li>
    <li>Add eggs and vanilla extract</li>
    <li>Gradually add flour</li>
    <li>Fold in chocolate chips</li>
    <li>Bake for 10-12 minutes</li>
  </ol>
</article>
''',
    },
    'email': {
      'name': 'Email Message',
      'defaultLabel': 'Email from John Smith: Meeting reminder',
      'html': '''
<article>
  <h2>Meeting Reminder</h2>
  <p><strong>From:</strong> John Smith &lt;john@example.com&gt;</p>
  <p><strong>To:</strong> You</p>
  <p><strong>Date:</strong> Today at 2:00 PM</p>

  <hr>

  <p>Hi Team,</p>

  <p>This is a reminder about our meeting tomorrow at <strong>10:00 AM</strong> in Conference Room B.</p>

  <p>Agenda:</p>
  <ul>
    <li>Q1 Review</li>
    <li>New project kickoff</li>
    <li>Team updates</li>
  </ul>

  <p>Please bring your laptops.</p>

  <p>Best regards,<br>John</p>
</article>
''',
    },
    'japanese_content': {
      'name': 'Japanese Content (CJK)',
      'defaultLabel': '日本語の記事',
      'html': '''
<article>
  <h1>日本語の記事</h1>
  <p>これは<ruby>日本語<rt>にほんご</rt></ruby>の<ruby>文章<rt>ぶんしょう</rt></ruby>です。</p>

  <h2>内容</h2>
  <p><ruby>振<rt>ふ</rt></ruby>り<ruby>仮名<rt>がな</rt></ruby>（ふりがな）のサポートが<ruby>完璧<rt>かんぺき</rt></ruby>です。</p>

  <blockquote>
    <ruby>漢字<rt>かんじ</rt></ruby>は<ruby>美<rt>うつく</rt></ruby>しい
  </blockquote>
</article>
''',
    },
  };

  @override
  Widget build(BuildContext context) {
    final example = _contentExamples[_selectedContent]!;
    final semanticLabel = _useCustomLabel && _customLabel.isNotEmpty
        ? _customLabel
        : example['defaultLabel']!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Demo'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.accessibility_new),
            tooltip: 'Accessibility Info',
            onPressed: _showAccessibilityInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade900,
            child: Row(
              children: [
                const Icon(Icons.accessibility, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Screen Reader Support',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Enable TalkBack/VoiceOver to test accessibility',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content selector
                const Text(
                  'Content Type:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedContent,
                  isExpanded: true,
                  items: _contentExamples.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedContent = value!);
                  },
                ),

                const Divider(height: 24),

                // Semantic label
                const Text(
                  'Semantic Label (for screen readers):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                SwitchListTile(
                  title: const Text('Use custom label'),
                  value: _useCustomLabel,
                  onChanged: (value) {
                    setState(() => _useCustomLabel = value);
                  },
                ),

                if (_useCustomLabel)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Custom semantic label',
                        hintText: 'Enter descriptive label',
                        border: const OutlineInputBorder(),
                        helperText: 'What screen readers will announce',
                      ),
                      onChanged: (value) {
                        setState(() => _customLabel = value);
                      },
                    ),
                  ),

                const SizedBox(height: 8),

                // Current label display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.volume_up, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Screen reader will announce:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '"$semanticLabel"',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade900,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Exclude from semantics
                SwitchListTile(
                  title: const Text('Exclude from semantics'),
                  subtitle: const Text(
                    'Hide from screen readers (decorative content only)',
                  ),
                  value: _excludeFromSemantics,
                  activeThumbColor: Colors.orange,
                  onChanged: (value) {
                    setState(() => _excludeFromSemantics = value);
                  },
                ),

                if (_excludeFromSemantics)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Content will be hidden from screen readers',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Rendered content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status card
                  Card(
                    color: _excludeFromSemantics
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _excludeFromSemantics
                                ? Icons.visibility_off
                                : Icons.accessibility,
                            color: _excludeFromSemantics
                                ? Colors.orange
                                : Colors.green,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _excludeFromSemantics
                                      ? 'Hidden from Screen Readers'
                                      : 'Accessible to Screen Readers',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _excludeFromSemantics
                                        ? Colors.orange.shade900
                                        : Colors.green.shade900,
                                  ),
                                ),
                                Text(
                                  _excludeFromSemantics
                                      ? 'Content excluded from semantic tree'
                                      : 'Screen readers can access this content',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _excludeFromSemantics
                                        ? Colors.orange.shade700
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rendered content
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _excludeFromSemantics
                            ? Colors.orange.shade300
                            : Colors.blue.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: HyperViewer(
                      html: example['html']!,
                      semanticLabel:
                          _excludeFromSemantics ? null : semanticLabel,
                      excludeSemantics: _excludeFromSemantics,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Best practices
                  Card(
                    color: Colors.purple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb,
                                  color: Colors.purple.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Accessibility Best Practices',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.purple.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildBestPractice(
                            '✅ Provide descriptive labels',
                            'Use clear, meaningful semantic labels that describe the content',
                          ),
                          _buildBestPractice(
                            '✅ Include context in labels',
                            'e.g., "News article: Title" instead of just "Article"',
                          ),
                          _buildBestPractice(
                            '⚠️ Only exclude decorative content',
                            'Don\'t hide important information from screen readers',
                          ),
                          _buildBestPractice(
                            '✅ Test with screen readers',
                            'Enable TalkBack (Android) or VoiceOver (iOS) to test',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestPractice(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAccessibilityInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.accessibility_new, color: Colors.blue),
            SizedBox(width: 8),
            Text('Accessibility Support'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'HyperRender provides full accessibility support for screen readers:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildInfoItem('🔊', 'Semantic labels',
                  'Descriptive labels for screen readers'),
              _buildInfoItem('♿', 'WCAG compliant',
                  'Follows Web Content Accessibility Guidelines'),
              _buildInfoItem('📱', 'Platform support',
                  'Works with TalkBack (Android) and VoiceOver (iOS)'),
              _buildInfoItem('🎯', 'Selective exclusion',
                  'Exclude decorative content from semantic tree'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'How to Test:\n\n'
                  '• iOS: Settings → Accessibility → VoiceOver\n'
                  '• Android: Settings → Accessibility → TalkBack',
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
