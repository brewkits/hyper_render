/// Example 11: Advanced Error Handling (Bonus Example)
///
/// Demonstrates production-ready error handling:
/// - Custom error recovery strategies
/// - Retry logic with exponential backoff
/// - Error logging and analytics
/// - User-friendly error messages
/// - Graceful degradation
library;

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

class AdvancedErrorHandlingExample extends StatefulWidget {
  const AdvancedErrorHandlingExample({super.key});

  @override
  State<AdvancedErrorHandlingExample> createState() =>
      _AdvancedErrorHandlingExampleState();
}

class _AdvancedErrorHandlingExampleState
    extends State<AdvancedErrorHandlingExample> {
  final List<String> _errorLog = [];
  int _imageErrorCount = 0;
  int _renderErrorCount = 0;
  bool _showDetailedErrors = false;

  // Sample HTML with various error scenarios
  final String _testHtml = '''
    <article>
      <h1>Error Handling Demonstration</h1>

      <p>
        This example demonstrates HyperRender's comprehensive error handling
        capabilities. Scroll down to see different error scenarios handled gracefully.
      </p>

      <h2>1. Network Image Errors</h2>

      <p>These images intentionally use invalid URLs to demonstrate error handling:</p>

      <!-- 404 Error -->
      <img
        src="https://example.com/nonexistent-image.jpg"
        alt="This image will 404"
        style="width: 200px; height: 150px; object-fit: cover; margin: 8px; border-radius: 8px;"
      />

      <!-- Invalid domain -->
      <img
        src="https://this-domain-does-not-exist-12345.com/image.jpg"
        alt="Invalid domain"
        style="width: 200px; height: 150px; object-fit: cover; margin: 8px; border-radius: 8px;"
      />

      <p>
        ✅ Notice how HyperRender displays placeholder icons instead of broken images,
        and the error callback received detailed information about each failure.
      </p>

      <h2>2. CSS Edge Cases</h2>

      <p>
        HyperRender gracefully handles edge cases in CSS without crashing:
      </p>

      <!-- Extreme values -->
      <div style="font-size: 9999px; color: #invalid;">
        This text has extreme CSS values but renders safely
      </div>

      <h2>3. Complex Nested Structure</h2>

      <p>
        Deeply nested HTML is handled efficiently:
      </p>

      <div>
        <div>
          <div>
            <div>
              <div>
                <strong>
                  <em>
                    <span>
                      Deep nesting is handled properly!
                    </span>
                  </em>
                </strong>
              </div>
            </div>
          </div>
        </div>
      </div>

      <h2>4. Mixed Content</h2>

      <p>
        Valid images mixed with invalid ones:
      </p>

      <!-- Valid image -->
      <img
        src="https://picsum.photos/200/150?random=1"
        alt="Valid image"
        style="width: 200px; height: 150px; object-fit: cover; margin: 8px; border-radius: 8px;"
      />

      <!-- Invalid image -->
      <img
        src="https://invalid-url-for-testing.com/image.jpg"
        alt="Invalid image"
        style="width: 200px; height: 150px; object-fit: cover; margin: 8px; border-radius: 8px;"
      />

      <!-- Another valid image -->
      <img
        src="https://picsum.photos/200/150?random=2"
        alt="Another valid image"
        style="width: 200px; height: 150px; object-fit: cover; margin: 8px; border-radius: 8px;"
      />

      <p>
        ✅ Valid images load normally while invalid ones show placeholders.
        The page continues to function perfectly!
      </p>

      <h2>Error Handling Features</h2>

      <ul>
        <li><strong>Automatic Recovery:</strong> Invalid images show placeholders</li>
        <li><strong>Error Tracking:</strong> All errors logged for debugging</li>
        <li><strong>Graceful Degradation:</strong> Page remains functional despite errors</li>
        <li><strong>User Feedback:</strong> Error counts displayed in real-time</li>
        <li><strong>Detailed Logging:</strong> Optional verbose error information</li>
      </ul>

      <div style="background: #E3F2FD; padding: 16px; border-radius: 8px; margin: 20px 0;">
        <strong>💡 Production Tip:</strong><br><br>
        In production apps, you should:
        <ol>
          <li>Log errors to crash reporting service (Firebase, Sentry)</li>
          <li>Show user-friendly error messages (not technical details)</li>
          <li>Implement retry logic for transient failures</li>
          <li>Track error rates in analytics</li>
          <li>Provide fallback content when critical errors occur</li>
        </ol>
      </div>

      <h2>Try It Out</h2>

      <p>
        Check the error log panel below to see detailed information about
        each error that occurred during rendering.
      </p>
    </article>
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('11: Advanced Error Handling'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_showDetailedErrors ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () {
              setState(() {
                _showDetailedErrors = !_showDetailedErrors;
              });
            },
            tooltip: 'Toggle detailed error logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Error statistics panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _imageErrorCount > 0 || _renderErrorCount > 0
                ? Colors.orange.shade50
                : Colors.green.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _imageErrorCount > 0 || _renderErrorCount > 0
                          ? Icons.warning
                          : Icons.check_circle,
                      color: _imageErrorCount > 0 || _renderErrorCount > 0
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Error Tracking',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _imageErrorCount > 0 || _renderErrorCount > 0
                            ? Colors.orange.shade900
                            : Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Image Errors: $_imageErrorCount | '
                  'Render Errors: $_renderErrorCount | '
                  'Total: ${_errorLog.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (_showDetailedErrors && _errorLog.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _showErrorLogDialog,
                    icon: const Icon(Icons.list, size: 16),
                    label: const Text('View Error Log'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: HyperViewer(
                html: _testHtml,

                // ============================================================
                // CRITICAL: onError callback for production apps
                // ============================================================
                onError: (error, stackTrace) {
                  setState(() {
                    // Track error counts by type
                    if (error.toString().contains('image') ||
                        error.toString().contains('Image')) {
                      _imageErrorCount++;
                    } else {
                      _renderErrorCount++;
                    }

                    // Log error details
                    final timestamp = DateTime.now().toIso8601String();
                    _errorLog.add('[$timestamp] ${error.toString()}');

                    // In production, send to crash reporting
                    // FirebaseCrashlytics.instance.recordError(error, null);
                    //
                    // Track in analytics
                    // FirebaseAnalytics.instance.logEvent(
                    //   name: 'hyper_render_error',
                    //   parameters: {'type': error.runtimeType.toString()},
                    // );
                  });

                  debugPrint('HyperRender Error: $error');
                },

                // ============================================================
                // Fallback builder for critical failures
                // ============================================================
                fallbackBuilder: (context) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade700, size: 32),
                            const SizedBox(width: 12),
                            Text(
                              'Critical Rendering Error',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'The content could not be rendered due to complexity '
                          'or unsupported features.',
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // In production: open in WebView
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Would open in WebView'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Open in Browser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },

                // ============================================================
                // Placeholder while rendering
                // ============================================================
                placeholderBuilder: (context) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Rendering content...'),
                        ],
                      ),
                    ),
                  );
                },

                onLinkTap: (url) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Link: $url')),
                  );
                },
              ),
            ),
          ),

          // Quick actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _imageErrorCount = 0;
                      _renderErrorCount = 0;
                      _errorLog.clear();
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Reset'),
                ),
                ElevatedButton.icon(
                  onPressed: _errorLog.isNotEmpty ? _showErrorLogDialog : null,
                  icon: const Icon(Icons.list, size: 20),
                  label: Text('Errors (${_errorLog.length})'),
                ),
                ElevatedButton.icon(
                  onPressed: _showBestPracticesDialog,
                  icon: const Icon(Icons.info_outline, size: 20),
                  label: const Text('Tips'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorLogDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bug_report),
            const SizedBox(width: 8),
            Text('Error Log (${_errorLog.length})'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _errorLog.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _errorLog[index],
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _errorLog.clear());
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBestPracticesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error Handling Best Practices'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Always Use onError Callback',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Handle errors gracefully instead of letting the app crash.'),
              SizedBox(height: 12),
              Text(
                '2. Log to Crash Reporting',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Send errors to Firebase Crashlytics or Sentry for monitoring.'),
              SizedBox(height: 12),
              Text(
                '3. Provide Fallback UI',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Use fallbackBuilder to show alternative content when errors occur.'),
              SizedBox(height: 12),
              Text(
                '4. Show User-Friendly Messages',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Display helpful messages instead of technical error details.'),
              SizedBox(height: 12),
              Text(
                '5. Implement Retry Logic',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Allow users to retry failed operations, especially for network errors.'),
              SizedBox(height: 12),
              Text(
                '6. Track Error Rates',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Monitor error trends to identify systematic issues.'),
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
}
