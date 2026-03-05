/// Example 06: Text Selection
///
/// Demonstrates HyperRender's full text selection support:
/// - Selecting text with mouse/touch
/// - Copy to clipboard
/// - Custom selection colors
/// - Selection across different styled elements
/// - Accessibility considerations
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_render/hyper_render.dart';

class TextSelectionExample extends StatelessWidget {
  const TextSelectionExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('06: Text Selection'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.touch_app, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Try It Out!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Long-press (mobile) or click-drag (desktop) to select text\n'
                      '• Select across headings, paragraphs, and styled elements\n'
                      '• Use the toolbar to copy selected text\n'
                      '• Notice how selection works seamlessly across different styles',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Main content with text selection enabled
            HyperViewer(
              html: '''
                <article>
                  <h1>Text Selection Support</h1>

                  <p>
                    HyperRender provides <strong>full native text selection</strong>
                    support out of the box. This is a critical feature for content
                    apps where users need to copy quotes, definitions, or references.
                  </p>

                  <h2>How It Works</h2>

                  <p>
                    Unlike widget-tree based HTML renderers that struggle with
                    selection across multiple widgets, HyperRender's single
                    <code>RenderObject</code> architecture makes text selection
                    natural and seamless.
                  </p>

                  <h3>Cross-Element Selection</h3>

                  <p>
                    You can select text that spans across <strong>different elements</strong>,
                    <em>different styles</em>, and even <code>inline code</code> without
                    any issues. Try selecting this entire paragraph including the styled words!
                  </p>

                  <blockquote>
                    "The ability to select and copy text is fundamental to user
                    experience. HyperRender treats it as a first-class feature."
                    <br><em>— UX Design Principles</em>
                  </blockquote>

                  <h2>Use Cases</h2>

                  <ul>
                    <li><strong>Documentation Apps:</strong> Copy code snippets and commands</li>
                    <li><strong>Reading Apps:</strong> Highlight and share quotes</li>
                    <li><strong>News Apps:</strong> Copy article excerpts</li>
                    <li><strong>Email Clients:</strong> Copy addresses and phone numbers</li>
                  </ul>

                  <h3>Technical Details</h3>

                  <ol>
                    <li>Selection handled by Flutter's native <code>TextPainter</code></li>
                    <li>Supports both mouse (desktop) and touch (mobile) selection</li>
                    <li>Copy to clipboard via system toolbar or context menu</li>
                    <li>Respects platform selection conventions (iOS vs Android)</li>
                  </ol>

                  <h2>Customization</h2>

                  <p>
                    You can customize selection behavior and appearance:
                  </p>

                  <ul>
                    <li>Enable/disable selection via <code>selectable</code> parameter</li>
                    <li>Custom selection color (matches Flutter theme by default)</li>
                    <li>Selection toolbar customization</li>
                  </ul>

                  <h3>Accessibility</h3>

                  <p>
                    Text selection is crucial for accessibility. Screen readers
                    can navigate selected text, and users with motor impairments
                    can use assistive selection tools.
                  </p>

                  <div style="background: #FFF3CD; padding: 16px; border-radius: 8px; margin: 16px 0;">
                    <strong>💡 Try This:</strong><br>
                    Select this entire yellow box including the icon and bold text.
                    Notice how selection works seamlessly across inline styles and colors!
                  </div>

                  <h2>Performance</h2>

                  <p>
                    Selection performance remains excellent even on large documents.
                    HyperRender's efficient rendering pipeline ensures that selection
                    gestures are responsive and smooth.
                  </p>

                  <h3>Best Practices</h3>

                  <ol>
                    <li>Keep selection enabled unless you have a specific reason to disable it</li>
                    <li>Test selection on both mobile and desktop platforms</li>
                    <li>Ensure selection color has sufficient contrast with your theme</li>
                    <li>Provide clear visual feedback when text is selected</li>
                    <li>Test with long documents to verify performance</li>
                  </ol>

                  <p style="background: #E3F2FD; padding: 16px; border-radius: 8px; margin-top: 24px;">
                    <strong>Challenge:</strong> Try selecting text from the first heading
                    all the way down to this paragraph. HyperRender handles multi-paragraph
                    selection with ease! 🎯
                  </p>
                </article>
              ''',

              // Text selection is enabled by default, but you can control it:
              // selectable: true,  // Enable/disable selection

              onLinkTap: (url) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Link: $url')),
                );
              },
            ),

            const SizedBox(height: 24),

            // Demo card showing programmatic copy
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Programmatic Copy Example',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'In addition to user selection, you can programmatically '
                      'copy text to clipboard:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          const ClipboardData(
                            text: 'HyperRender provides full native text selection support!',
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Text copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.content_copy),
                      label: const Text('Copy Sample Text'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
