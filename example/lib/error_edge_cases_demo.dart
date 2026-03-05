/// Error Edge Cases Demo
///
/// Demonstrates real-world error scenarios that production apps will encounter.
/// This complements examples/03_error_handling.dart with specific edge cases:
/// - 404 images (very common)
/// - Malformed HTML (unclosed tags)
/// - Corrupt images (0x0 dimensions)
/// - Image timeouts
/// - Giant tables (performance issues)
/// - Deep nested tables
/// - Mixed error scenarios
///
/// IMPORTANT: These are REAL error cases, not simulations.
library;

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

class ErrorEdgeCasesDemo extends StatefulWidget {
  const ErrorEdgeCasesDemo({super.key});

  @override
  State<ErrorEdgeCasesDemo> createState() => _ErrorEdgeCasesDemoState();
}

class _ErrorEdgeCasesDemoState extends State<ErrorEdgeCasesDemo> {
  final List<String> _errorLog = [];
  int _errorCount = 0;

  void _logError(String error) {
    setState(() {
      _errorCount++;
      _errorLog.insert(0, '[${DateTime.now().toIso8601String().substring(11, 19)}] $error');
      if (_errorLog.length > 10) {
        _errorLog.removeLast(); // Keep only last 10
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Edge Cases'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_errorCount > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_errorCount errors',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Error log panel
          if (_errorLog.isNotEmpty)
            Container(
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bug_report, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Error Log (last ${_errorLog.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() {
                          _errorLog.clear();
                          _errorCount = 0;
                        }),
                        child: const Text('Clear', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ..._errorLog.map((log) => Text(
                        log,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
                ],
              ),
            ),

          // Main content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Intro card
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange.shade700, size: 28),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Real-World Error Scenarios',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'This demo tests REAL error cases that production apps encounter. '
                          'Watch the error log above to see how HyperRender handles each case gracefully.',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Case 1: 404 Image
                _ErrorCase(
                  title: '1. 404 Image (Very Common)',
                  description: 'Images that return HTTP 404 Not Found',
                  severity: 'HIGH',
                  html: _case404Image,
                  onError: _logError,
                ),

                // Case 2: Malformed HTML
                _ErrorCase(
                  title: '2. Malformed HTML (Common)',
                  description: 'Unclosed tags, invalid nesting',
                  severity: 'MEDIUM',
                  html: _caseMalformedHtml,
                  onError: _logError,
                ),

                // Case 3: Corrupt Image
                _ErrorCase(
                  title: '3. Corrupt Image (Rare)',
                  description: '0x0 pixel images that cause division-by-zero',
                  severity: 'MEDIUM',
                  html: _caseCorruptImage,
                  onError: _logError,
                ),

                // Case 4: Timeout
                _ErrorCase(
                  title: '4. Image Timeout (Common)',
                  description: 'Slow servers that take >10 seconds',
                  severity: 'HIGH',
                  html: _caseTimeout,
                  onError: _logError,
                ),

                // Case 5: Giant Table
                _ErrorCase(
                  title: '5. Giant Table (Uncommon)',
                  description: 'Table with 100+ cells causes performance issues',
                  severity: 'MEDIUM',
                  html: _caseGiantTable,
                  onError: _logError,
                ),

                // Case 6: Nested Tables
                _ErrorCase(
                  title: '6. Deep Nested Tables (Uncommon)',
                  description: 'Tables nested >3 levels trigger limits',
                  severity: 'LOW',
                  html: _caseNestedTables,
                  onError: _logError,
                ),

                // Case 7: Mixed Errors
                _ErrorCase(
                  title: '7. Mixed Errors (Production Reality)',
                  description: 'Multiple issues in one document',
                  severity: 'HIGH',
                  html: _caseMixedErrors,
                  onError: _logError,
                ),

                const SizedBox(height: 24),

                // Summary card
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
                              'Error Handling Strategy',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '✅ Graceful Degradation: App never crashes\n'
                          '✅ Partial Rendering: Valid content still displays\n'
                          '✅ Error Callbacks: onError notifies but doesn\'t block\n'
                          '✅ Placeholder Images: Broken images show placeholder\n'
                          '✅ Malformed HTML: Parser recovers automatically\n'
                          '✅ Performance Limits: Giant content triggers warnings',
                          style: TextStyle(fontSize: 13, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Edge case HTML content
  static const _case404Image = '''
    <div style="padding: 16px; border: 2px solid #FF5722; border-radius: 8px;">
      <h3>Article with Missing Image</h3>
      <img src="https://httpstat.us/404" alt="This image returns 404">
      <p>The image above will fail to load with HTTP 404. HyperRender shows
      a placeholder instead of crashing or leaving blank space.</p>
      <p>This is <strong>very common</strong> in production when:</p>
      <ul>
        <li>CDN links expire</li>
        <li>Images are deleted</li>
        <li>URLs are typo'd in CMS</li>
      </ul>
    </div>
  ''';

  static const _caseMalformedHtml = '''
    <div style="padding: 16px; border: 2px solid #FF9800; border-radius: 8px;">
      <h3>Malformed HTML Test</h3>
      <p>This HTML has unclosed tags:
      <div>Unclosed div
      <p>Unclosed paragraph
      <strong>Unclosed strong

      <p>HyperRender's parser auto-closes tags to prevent rendering issues.</p>

      <p>Common in production when:
      <ul>
        <li>CMS generates broken HTML</li>
        <li>User copy-pastes from Word</li>
        <li>WYSIWYG editors misbehave
      </ul>
    </div>
  ''';

  static const _caseCorruptImage = '''
    <div style="padding: 16px; border: 2px solid #9C27B0; border-radius: 8px;">
      <h3>Corrupt Image Test</h3>
      <p>This is a 1x1 transparent GIF that used to cause division-by-zero:</p>
      <img src="data:image/gif;base64,R0lGODlhAQABAAAAACw="
           alt="Corrupt image"
           style="border: 2px solid red;">
      <p>HyperRender v1.0.0 guards against imageWidth &lt;= 0 to prevent crashes.</p>
      <p><strong>Fixed in v1.0.0:</strong> Image layout division-by-zero bug</p>
    </div>
  ''';

  static const _caseTimeout = '''
    <div style="padding: 16px; border: 2px solid #F44336; border-radius: 8px;">
      <h3>Slow Image Server</h3>
      <p>This image URL intentionally delays response:</p>
      <img src="https://httpbin.org/delay/10" alt="Slow image (10s delay)">
      <p><em>Note: This may take 10+ seconds to fail.</em></p>
      <p>HyperRender shows a placeholder while waiting. The rest of the
      content renders immediately - users can read while images load.</p>
    </div>
  ''';

  static const _caseGiantTable = '''
    <div style="padding: 16px; border: 2px solid #3F51B5; border-radius: 8px;">
      <h3>Large Table Performance Test</h3>
      <p>This table has 50 cells (10x5). Giant tables (&gt;100 cells)
      may trigger performance warnings.</p>
      <table border="1" style="border-collapse: collapse; font-size: 11px;">
        <tr><td>A1</td><td>B1</td><td>C1</td><td>D1</td><td>E1</td><td>F1</td><td>G1</td><td>H1</td><td>I1</td><td>J1</td></tr>
        <tr><td>A2</td><td>B2</td><td>C2</td><td>D2</td><td>E2</td><td>F2</td><td>G2</td><td>H2</td><td>I2</td><td>J2</td></tr>
        <tr><td>A3</td><td>B3</td><td>C3</td><td>D3</td><td>E3</td><td>F3</td><td>G3</td><td>H3</td><td>I3</td><td>J3</td></tr>
        <tr><td>A4</td><td>B4</td><td>C4</td><td>D4</td><td>E4</td><td>F4</td><td>G4</td><td>H4</td><td>I4</td><td>J4</td></tr>
        <tr><td>A5</td><td>B5</td><td>C5</td><td>D5</td><td>E5</td><td>F5</td><td>G5</td><td>H5</td><td>I5</td><td>J5</td></tr>
      </table>
      <p style="margin-top: 12px; font-size: 12px; color: #666;">
        <strong>Performance Note:</strong> Tables with 100-500 cells show warnings.
        Tables &gt;500 cells may cause jank on mobile devices.
      </p>
    </div>
  ''';

  static const _caseNestedTables = '''
    <div style="padding: 16px; border: 2px solid #009688; border-radius: 8px;">
      <h3>Nested Tables Test</h3>
      <p>Tables nested beyond depth 3 are limited to prevent O(N³) performance:</p>
      <table border="1" style="border-collapse: collapse;">
        <tr><td>Level 1
          <table border="1" style="border-collapse: collapse; background: #FFEBEE;">
            <tr><td>Level 2
              <table border="1" style="border-collapse: collapse; background: #E1F5FE;">
                <tr><td>Level 3 (limit!)
                  <table border="1">
                    <tr><td>Level 4 (may trigger warning)</td></tr>
                  </table>
                </td></tr>
              </table>
            </td></tr>
          </table>
        </td></tr>
      </table>
      <p style="margin-top: 12px; font-size: 12px; color: #666;">
        <strong>See:</strong> TABLE_LAYOUT_INTRINSIC_PROBLEM.md for technical details.
      </p>
    </div>
  ''';

  static const _caseMixedErrors = '''
    <div style="padding: 16px; border: 2px solid #E91E63; border-radius: 8px;">
      <h3>Real-World Scenario: Multiple Issues</h3>
      <p>Production HTML often has MULTIPLE problems at once:</p>

      <!-- 404 image -->
      <img src="https://httpstat.us/404" alt="Missing" width="100">

      <!-- Malformed HTML -->
      <div>Unclosed div
      <p>Unclosed paragraph

      <!-- Valid content mixed in -->
      <p>But valid content <strong>still renders</strong>!</p>

      <!-- Another 404 -->
      <img src="https://example.com/does-not-exist.jpg" alt="Also missing">

      <!-- More valid content -->
      <ul>
        <li>Item 1</li>
        <li>Item 2
        <!-- Unclosed li -->
      </ul>

      <blockquote style="border-left: 4px solid #E91E63; padding-left: 12px;">
        <strong>Key Insight:</strong> Partial failures don't block the entire document.
        Users can still read the article even if some images fail or HTML is broken.
      </blockquote>
    </div>
  ''';
}

class _ErrorCase extends StatelessWidget {
  final String title;
  final String description;
  final String severity;
  final String html;
  final Function(String) onError;

  const _ErrorCase({
    required this.title,
    required this.description,
    required this.severity,
    required this.html,
    required this.onError,
  });

  MaterialColor get _severityColor {
    switch (severity) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _severityColor[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _severityColor),
              ),
              child: Text(
                severity,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _severityColor[900],
                ),
              ),
            ),
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
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: HyperViewer(
            html: html,
            onError: (error, stackTrace) {
              onError('${title.split('.')[0]}: ${error.toString().substring(0, 50)}...');
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
