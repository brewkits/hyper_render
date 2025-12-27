import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper to open HTML in browser for comparison with HyperRender output
class HtmlPreviewHelper {
  /// Opens HTML content in the system browser
  /// Creates a temporary file and launches it
  static Future<void> openInBrowser(String html, {String title = 'Preview'}) async {
    try {
      // Wrap HTML with proper document structure and styling
      final fullHtml = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title - Original HTML</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.6;
      max-width: 800px;
      margin: 0 auto;
      padding: 20px;
      background: #fff;
    }
    pre {
      background: #1e1e1e;
      color: #d4d4d4;
      padding: 16px;
      border-radius: 8px;
      overflow-x: auto;
    }
    code {
      font-family: 'SF Mono', Monaco, 'Courier New', monospace;
    }
    img {
      max-width: 100%;
      height: auto;
    }
    table {
      border-collapse: collapse;
      width: 100%;
    }
    th, td {
      border: 1px solid #ddd;
      padding: 8px;
      text-align: left;
    }
    th {
      background: #f5f5f5;
    }
  </style>
</head>
<body>
  <div style="background: #e3f2fd; padding: 12px 16px; margin-bottom: 20px; border-radius: 8px; border-left: 4px solid #2196f3;">
    <strong>Original HTML</strong> - Compare this with HyperRender output
  </div>
  $html
</body>
</html>
''';

      // Get temp directory and create file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/hyper_render_preview_$timestamp.html');
      await file.writeAsString(fullHtml);

      // Launch in browser
      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch browser');
      }
    } catch (e) {
      debugPrint('Error opening HTML in browser: $e');
      rethrow;
    }
  }
}

/// A FloatingActionButton that opens HTML in browser
/// Use this in any demo screen for quick comparison
class ViewOriginalHtmlButton extends StatelessWidget {
  final String html;
  final String title;

  const ViewOriginalHtmlButton({
    super.key,
    required this.html,
    this.title = 'Preview',
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        try {
          await HtmlPreviewHelper.openInBrowser(html, title: title);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open browser: $e')),
            );
          }
        }
      },
      icon: const Icon(Icons.open_in_browser),
      label: const Text('View Original'),
      tooltip: 'Open original HTML in browser to compare',
    );
  }
}

/// Wrapper scaffold that adds "View Original" button to any demo
class DemoScaffold extends StatelessWidget {
  final String title;
  final String html;
  final Widget child;
  final List<Widget>? actions;

  const DemoScaffold({
    super.key,
    required this.title,
    required this.html,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // View Original button in AppBar (more compact)
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'View original HTML in browser',
            onPressed: () async {
              try {
                await HtmlPreviewHelper.openInBrowser(html, title: title);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open browser: $e')),
                  );
                }
              }
            },
          ),
          ...?actions,
        ],
      ),
      body: child,
    );
  }
}
