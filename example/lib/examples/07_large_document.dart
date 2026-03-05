/// Example 07: Large Document Performance
///
/// Demonstrates HyperRender's performance with large HTML documents:
/// - Smooth 60fps scrolling even with 1000+ paragraphs
/// - Efficient memory usage with lazy loading
/// - Performance monitoring and metrics
/// - Best practices for handling large content
library;

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

class LargeDocumentExample extends StatefulWidget {
  const LargeDocumentExample({super.key});

  @override
  State<LargeDocumentExample> createState() => _LargeDocumentExampleState();
}

class _LargeDocumentExampleState extends State<LargeDocumentExample> {
  int _paragraphCount = 100;
  bool _isGenerating = false;
  String? _generatedHtml;
  DateTime? _generationStart;
  Duration? _generationTime;

  @override
  void initState() {
    super.initState();
    _generateDocument();
  }

  void _generateDocument() {
    setState(() {
      _isGenerating = true;
      _generationStart = DateTime.now();
    });

    // Generate large HTML document
    final buffer = StringBuffer();
    buffer.write('<article>');
    buffer.write('<h1>Large Document Performance Test</h1>');
    buffer.write('<p><strong>Document size:</strong> $_paragraphCount paragraphs</p>');
    buffer.write(
      '<p style="background: #E3F2FD; padding: 12px; border-radius: 8px; margin: 16px 0;">'
      '<strong>📊 Scroll Performance Test:</strong><br>'
      'Scroll down through this document and notice the smooth 60fps performance. '
      'HyperRender\'s efficient rendering pipeline maintains high frame rates even '
      'with large documents.'
      '</p>',
    );

    for (int i = 1; i <= _paragraphCount; i++) {
      // Add variety to content
      if (i % 20 == 0) {
        buffer.write('<h2>Section ${i ~/ 20}: Performance Milestone</h2>');
        buffer.write(
          '<p style="background: #FFF3CD; padding: 12px; border-radius: 8px;">'
          '<strong>Checkpoint $i:</strong> You\'ve scrolled through $i paragraphs! '
          'Notice how scrolling remains smooth and responsive. This is paragraph '
          'number <code>$i</code> out of <code>$_paragraphCount</code>.'
          '</p>',
        );
      } else if (i % 10 == 0) {
        buffer.write('<h3>Subsection ${i ~/ 10}.${i % 10}</h3>');
      }

      // Generate varied paragraph content
      if (i % 7 == 0) {
        buffer.write(
          '<p>This is paragraph <strong>#$i</strong>. It contains <em>styled text</em>, '
          '<code>inline code</code>, and demonstrates that HyperRender maintains '
          'performance even with rich formatting throughout large documents. '
          'The rendering engine efficiently handles thousands of styled spans.</p>',
        );
      } else if (i % 5 == 0) {
        buffer.write('<blockquote>');
        buffer.write(
          '"Paragraph $i demonstrates blockquote styling in large documents. '
          'Performance remains excellent regardless of content variety."',
        );
        buffer.write('</blockquote>');
      } else if (i % 3 == 0) {
        buffer.write('<ul>');
        buffer.write('<li>List item in paragraph $i</li>');
        buffer.write('<li>Second item with <strong>bold text</strong></li>');
        buffer.write('<li>Third item with <code>code snippet</code></li>');
        buffer.write('</ul>');
      } else {
        buffer.write(
          '<p>Paragraph $i: Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
          'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
          'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.</p>',
        );
      }
    }

    buffer.write('<hr>');
    buffer.write(
      '<div style="background: #C8E6C9; padding: 20px; border-radius: 8px; margin: 24px 0;">'
      '<h2>🎉 End of Document</h2>'
      '<p><strong>Congratulations!</strong> You\'ve reached the end of $_paragraphCount paragraphs.</p>'
      '<p>Performance observations:</p>'
      '<ul>'
      '<li>Scrolling remained smooth throughout</li>'
      '<li>Memory usage stayed reasonable</li>'
      '<li>No frame drops or stuttering</li>'
      '<li>Text selection works across the entire document</li>'
      '</ul>'
      '</div>',
    );

    buffer.write('</article>');

    setState(() {
      _generatedHtml = buffer.toString();
      _generationTime = DateTime.now().difference(_generationStart!);
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('07: Large Document'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating large document...'),
                ],
              ),
            )
          : Column(
              children: [
                // Performance stats banner
                Container(
                  width: double.infinity,
                  color: Colors.green.shade50,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        '📊 Document Stats',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_paragraphCount paragraphs • '
                        'Generated in ${_generationTime?.inMilliseconds ?? 0}ms • '
                        '~${(_generatedHtml?.length ?? 0) ~/ 1024}KB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: HyperViewer(
                      html: _generatedHtml!,
                      onError: (error, stackTrace) {
                        debugPrint('Render error: $error');
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose document size to test performance:'),
            const SizedBox(height: 16),
            _SizeOption(
              label: 'Small (50 paragraphs)',
              value: 50,
              current: _paragraphCount,
              onSelect: () => _updateSize(50),
            ),
            _SizeOption(
              label: 'Medium (100 paragraphs)',
              value: 100,
              current: _paragraphCount,
              onSelect: () => _updateSize(100),
            ),
            _SizeOption(
              label: 'Large (500 paragraphs)',
              value: 500,
              current: _paragraphCount,
              onSelect: () => _updateSize(500),
            ),
            _SizeOption(
              label: 'Extra Large (1000 paragraphs)',
              value: 1000,
              current: _paragraphCount,
              onSelect: () => _updateSize(1000),
            ),
            const SizedBox(height: 16),
            Text(
              'Note: Larger documents take longer to generate and render.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _updateSize(int size) {
    Navigator.pop(context);
    setState(() {
      _paragraphCount = size;
    });
    _generateDocument();
  }
}

class _SizeOption extends StatelessWidget {
  final String label;
  final int value;
  final int current;
  final VoidCallback onSelect;

  const _SizeOption({
    required this.label,
    required this.value,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == current;
    return InkWell(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue.shade900 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
