/// Example 03: Error Handling (IMPORTANT!)
///
/// This is the MOST IMPORTANT example. It demonstrates proper error handling:
/// - Loading states (showing spinner while fetching)
/// - Error states (showing error message with retry)
/// - Success states (showing content)
/// - Render error callbacks
/// - Graceful degradation
///
/// Every production app should follow these patterns.
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

class ErrorHandlingExample extends StatefulWidget {
  const ErrorHandlingExample({super.key});

  @override
  State<ErrorHandlingExample> createState() => _ErrorHandlingExampleState();
}

class _ErrorHandlingExampleState extends State<ErrorHandlingExample> {
  bool _isLoading = true;
  String? _error;
  String? _html;
  int _attemptCount = 0;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  /// Simulate fetching HTML from a server
  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _attemptCount++;
    });

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate random failures (50% chance to fail on first 2 attempts)
      if (_attemptCount < 3 && Random().nextBool()) {
        throw Exception('Network error: Connection timeout');
      }

      // Simulate success
      const html = '''
        <article>
          <h1>Content Loaded Successfully!</h1>

          <p>
            This content was "fetched" from a simulated server.
            Notice how the app handled the loading state gracefully.
          </p>

          <h2>Error Handling Best Practices</h2>

          <ol>
            <li><strong>Loading State:</strong> Show spinner + message</li>
            <li><strong>Error State:</strong> Show error + retry button</li>
            <li><strong>Success State:</strong> Render content</li>
            <li><strong>Render Errors:</strong> Use onError callback</li>
            <li><strong>Graceful Degradation:</strong> Always have a fallback</li>
          </ol>

          <h3>Common Error Scenarios</h3>

          <ul>
            <li>Network failures (timeout, no connection)</li>
            <li>Malformed HTML (unclosed tags, invalid structure)</li>
            <li>Image loading failures</li>
            <li>Large documents causing performance issues</li>
            <li>Unsupported CSS/HTML features</li>
          </ul>

          <p style="background: #f0f0f0; padding: 16px; border-radius: 8px;">
            <strong>💡 Tip:</strong> Always test your app with:
            <br>• Slow network conditions
            <br>• Airplane mode
            <br>• Malformed HTML
            <br>• Very large documents
          </p>

          <h2>Try It Out</h2>

          <p>
            Pull down to refresh and see the loading state again.
            The app will randomly fail on the first couple attempts
            to demonstrate error handling.
          </p>
        </article>
      ''';

      setState(() {
        _html = html;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('03: Error Handling'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadContent,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // ============================================================
    // STATE 1: LOADING
    // ============================================================
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Loading content...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Attempt $_attemptCount',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    // ============================================================
    // STATE 2: ERROR
    // ============================================================
    if (_error != null) {
      return SingleChildScrollView(
        // Important: Wrap in ScrollView for RefreshIndicator
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 100,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Failed to Load Content',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _loadContent,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ============================================================
    // STATE 3: SUCCESS - Render Content
    // ============================================================
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: HyperViewer(
        html: _html!,

        // ============================================================
        // IMPORTANT: Handle render errors
        // ============================================================
        onError: (error, stackTrace) {
          // This callback is called when rendering fails
          // (e.g., malformed HTML, layout errors)
          debugPrint('Render error: $error');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rendering warning: ${error.toString()}'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () {},
              ),
            ),
          );
        },

        // ============================================================
        // Optional: Placeholder while parsing
        // ============================================================
        placeholderBuilder: (context) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        },

        // ============================================================
        // Optional: Fallback if content is too complex
        // ============================================================
        fallbackBuilder: (context) {
          // This is called if HtmlHeuristics.isComplex() returns true
          return Container(
            padding: const EdgeInsets.all(24),
            color: Colors.yellow[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  'Content Too Complex',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This HTML contains features that may not render correctly '
                  '(e.g., position:fixed, canvas, complex JavaScript).',
                ),
                const SizedBox(height: 16),
                const Text('Consider using a WebView for this content.'),
              ],
            ),
          );
        },

        // Handle link taps
        onLinkTap: (url) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Open Link?'),
              content: Text(url),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // In production: launchUrl(Uri.parse(url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Would open: $url')),
                    );
                  },
                  child: const Text('Open'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error Handling Demo'),
        content: const SingleChildScrollView(
          child: Text(
            'This example demonstrates proper error handling:\n\n'
            '1. Loading State: Shows spinner while fetching\n\n'
            '2. Error State: Shows error message with retry button\n\n'
            '3. Success State: Renders content\n\n'
            '4. Render Errors: Uses onError callback\n\n'
            '5. Graceful Degradation: Has fallback widgets\n\n'
            'Pull down to refresh and see the states in action. '
            'The app will randomly fail a few times to demonstrate error handling.',
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
