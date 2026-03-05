/// Details/Summary Interactive Demo
///
/// Demonstrates the <details>/<summary> interactive disclosure widget.
/// This is a native HTML5 feature for expandable/collapsible content.
///
/// Key Features:
/// - Click to expand/collapse
/// - Maintains state
/// - Accessible (screen readers announce expanded/collapsed)
/// - No JavaScript required
library;

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

class DetailsSummaryDemo extends StatelessWidget {
  const DetailsSummaryDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details/Summary Interactive'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.expand_more, color: Colors.blue.shade700, size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Interactive Disclosure',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Click any summary to expand/collapse content',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'The <details> element creates an interactive widget that '
                    'users can open and close. The <summary> element defines '
                    'the visible heading.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Example 1: Basic usage
          _SectionTitle('1. Basic Usage'),
          HyperViewer(
            html: _basicExample,
          ),

          const SizedBox(height: 24),

          // Example 2: Styled details
          _SectionTitle('2. Styled Disclosure'),
          HyperViewer(
            html: _styledExample,
          ),

          const SizedBox(height: 24),

          // Example 3: Nested details
          _SectionTitle('3. Nested Disclosures'),
          HyperViewer(
            html: _nestedExample,
          ),

          const SizedBox(height: 24),

          // Example 4: FAQ pattern
          _SectionTitle('4. FAQ Pattern'),
          HyperViewer(
            html: _faqExample,
          ),

          const SizedBox(height: 24),

          // Example 5: Initially open
          _SectionTitle('5. Initially Open (open attribute)'),
          HyperViewer(
            html: _openExample,
          ),

          const SizedBox(height: 24),

          // Example 6: Rich content
          _SectionTitle('6. Rich Content Inside'),
          HyperViewer(
            html: _richContentExample,
          ),

          const SizedBox(height: 24),

          // Technical notes
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Technical Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '✅ State Management: Expand/collapse state is maintained by HyperRender\n'
                    '✅ Accessibility: Screen readers announce "collapsed" or "expanded"\n'
                    '✅ Performance: Content is always rendered (not lazy-loaded)\n'
                    '✅ Styling: <summary> can be fully styled with CSS\n'
                    '✅ Events: Click anywhere on summary to toggle\n'
                    '✅ Native HTML5: No JavaScript required',
                    style: TextStyle(fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Use cases
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Common Use Cases',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• FAQ sections (frequently asked questions)\n'
                    '• Article table of contents\n'
                    '• "Read more" / "Show more" patterns\n'
                    '• Documentation sections\n'
                    '• Settings panels\n'
                    '• Code examples with descriptions\n'
                    '• Product specifications',
                    style: TextStyle(fontSize: 13, height: 1.8),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  static const _basicExample = '''
<details>
  <summary>Click to reveal the answer</summary>
  <p>The answer is 42! This content was hidden until you clicked.</p>
</details>

<details>
  <summary>What is HyperRender?</summary>
  <p>HyperRender is a high-performance HTML rendering library for Flutter
  that uses a custom RenderObject instead of a widget tree.</p>
</details>
''';

  static const _styledExample = '''
<style>
  details {
    border: 2px solid #6750A4;
    border-radius: 8px;
    padding: 12px;
    margin: 8px 0;
    background: #F3F0FF;
  }

  summary {
    font-weight: bold;
    color: #6750A4;
    cursor: pointer;
    padding: 4px 0;
    font-size: 16px;
  }

  details[open] summary {
    margin-bottom: 12px;
    padding-bottom: 8px;
    border-bottom: 2px solid #6750A4;
  }

  details p {
    margin: 8px 0 4px 0;
    color: #333;
  }
</style>

<details>
  <summary>📘 Why use details/summary?</summary>
  <p>The <code>&lt;details&gt;</code> element is perfect for hiding
  content that users can reveal on demand. It's accessible, semantic,
  and requires no JavaScript.</p>
</details>

<details>
  <summary>🚀 Performance Benefits</summary>
  <p>Content inside <code>&lt;details&gt;</code> is always rendered
  (not lazy-loaded), so expanding is instant. However, collapsed content
  doesn't affect layout until opened.</p>
</details>
''';

  static const _nestedExample = '''
<style>
  details { margin: 8px 0; padding: 12px; border: 1px solid #ddd; border-radius: 4px; }
  summary { font-weight: bold; cursor: pointer; padding: 4px 0; }
  details details { margin-left: 16px; background: #f9f9f9; }
</style>

<details>
  <summary>Level 1: Programming Languages</summary>
  <p>Click nested items to explore further:</p>

  <details>
    <summary>Level 2: Frontend</summary>
    <p>Technologies for building user interfaces:</p>

    <details>
      <summary>Level 3: JavaScript Frameworks</summary>
      <ul>
        <li>React</li>
        <li>Vue</li>
        <li>Angular</li>
      </ul>
    </details>

    <details>
      <summary>Level 3: CSS Frameworks</summary>
      <ul>
        <li>Tailwind</li>
        <li>Bootstrap</li>
        <li>Material UI</li>
      </ul>
    </details>
  </details>

  <details>
    <summary>Level 2: Backend</summary>
    <ul>
      <li>Node.js</li>
      <li>Python (Django, Flask)</li>
      <li>Ruby on Rails</li>
    </ul>
  </details>
</details>
''';

  static const _faqExample = '''
<style>
  .faq-container { max-width: 600px; }
  .faq-item {
    border-bottom: 1px solid #e0e0e0;
    margin: 0;
    padding: 0;
  }
  .faq-item summary {
    font-size: 16px;
    font-weight: 600;
    color: #1976D2;
    padding: 16px 0;
    cursor: pointer;
  }
  .faq-item summary::before {
    content: "Q: ";
    color: #1976D2;
    font-weight: bold;
  }
  .faq-item[open] summary {
    color: #0D47A1;
  }
  .faq-item p {
    padding: 0 0 16px 0;
    margin: 0;
    color: #555;
    line-height: 1.6;
  }
  .faq-item p::before {
    content: "A: ";
    font-weight: bold;
    color: #4CAF50;
  }
</style>

<div class="faq-container">
  <h2 style="color: #1976D2; margin-bottom: 16px;">Frequently Asked Questions</h2>

  <details class="faq-item">
    <summary>What platforms does HyperRender support?</summary>
    <p>HyperRender supports iOS, Android, macOS, Windows, Linux, and Web.
    It works on all platforms that Flutter supports.</p>
  </details>

  <details class="faq-item">
    <summary>How is it different from flutter_html?</summary>
    <p>HyperRender uses a custom RenderObject instead of a widget tree,
    enabling features like CSS float layout and seamless text selection
    across large documents.</p>
  </details>

  <details class="faq-item">
    <summary>Can I use it for production apps?</summary>
    <p>Yes! Version 1.0.0 is production-ready. It includes built-in
    HTML sanitization, error handling, and has been tested on real-world
    content.</p>
  </details>

  <details class="faq-item">
    <summary>Does it support all HTML tags?</summary>
    <p>HyperRender supports most common HTML tags including headings,
    paragraphs, lists, tables, images, links, and more. Unsupported tags
    like &lt;canvas&gt; or &lt;form&gt; can be replaced with Flutter
    widgets via widgetBuilder.</p>
  </details>
</div>
''';

  static const _openExample = '''
<style>
  details { padding: 12px; border: 1px solid #ddd; border-radius: 4px; margin: 8px 0; }
  summary { font-weight: bold; padding: 4px 0; }
  details[open] { background: #f0f8ff; border-color: #2196F3; }
</style>

<p><strong>Note:</strong> The <code>open</code> attribute makes details
expanded by default.</p>

<details open>
  <summary>This is initially open</summary>
  <p>This content is visible on page load because the
  <code>&lt;details open&gt;</code> attribute is present.</p>
  <p>Users can still collapse it by clicking the summary.</p>
</details>

<details>
  <summary>This is initially closed</summary>
  <p>This content is hidden by default. Click the summary to reveal it.</p>
</details>
''';

  static const _richContentExample = '''
<style>
  details {
    border: 2px solid #E91E63;
    border-radius: 12px;
    padding: 16px;
    margin: 12px 0;
    background: linear-gradient(to right, #FCE4EC, #F8BBD0);
  }
  summary {
    font-size: 18px;
    font-weight: bold;
    color: #C2185B;
    cursor: pointer;
    padding: 8px 0;
  }
  details[open] {
    background: white;
    border-color: #C2185B;
  }
</style>

<details>
  <summary>🎨 Rich Content Example</summary>

  <h3 style="color: #C2185B;">You can put anything inside!</h3>

  <p>Details can contain <strong>any HTML content</strong>:</p>

  <ul>
    <li>✅ Formatted text with <em>italic</em> and <strong>bold</strong></li>
    <li>✅ Lists (like this one)</li>
    <li>✅ Images (would need src)</li>
    <li>✅ Tables</li>
    <li>✅ Code blocks</li>
    <li>✅ Even <mark>highlighted text</mark></li>
  </ul>

  <blockquote style="border-left: 4px solid #E91E63; padding-left: 12px; color: #666;">
    "The details element is one of the most underused HTML5 features."
    <br><em>— Web Developer Wisdom</em>
  </blockquote>

  <pre style="background: #263238; color: #EEFFFF; padding: 12px; border-radius: 8px; overflow-x: auto;"><code>&lt;details&gt;
  &lt;summary&gt;Click me&lt;/summary&gt;
  &lt;p&gt;Hidden content here!&lt;/p&gt;
&lt;/details&gt;</code></pre>

  <p style="text-align: center; margin-top: 16px;">
    <strong>Pretty cool, right? 🚀</strong>
  </p>
</details>
''';
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1976D2),
        ),
      ),
    );
  }
}
