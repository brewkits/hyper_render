import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

      if (Platform.isIOS || Platform.isAndroid) {
        // On mobile: use data URI approach
        final dataUri = Uri.dataFromString(
          fullHtml,
          mimeType: 'text/html',
          encoding: utf8,
        );
        if (await canLaunchUrl(dataUri)) {
          await launchUrl(dataUri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch browser');
        }
      } else {
        // On desktop: create temp file and open
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/hyper_render_preview_$timestamp.html');
        await file.writeAsString(fullHtml);

        final uri = Uri.file(file.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          throw Exception('Could not launch browser');
        }
      }
    } catch (e) {
      debugPrint('Error opening HTML in browser: $e');
      rethrow;
    }
  }

  /// Show HTML in a dialog with WebView-like display
  /// Use this as fallback when browser launch fails
  static void showInDialog(BuildContext context, String html, {String title = 'Preview'}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title - Original HTML'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              html,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: html));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('HTML copied to clipboard')),
              );
            },
            child: const Text('Copy HTML'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
          // View Original button - shows HTML source
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'View original HTML source',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HtmlSourceViewer(
                    title: title,
                    html: html,
                  ),
                ),
              );
            },
          ),
          ...?actions,
        ],
      ),
      body: child,
    );
  }
}

/// Full screen HTML source viewer
class HtmlSourceViewer extends StatelessWidget {
  final String title;
  final String html;

  const HtmlSourceViewer({
    super.key,
    required this.title,
    required this.html,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$title - HTML Source'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy HTML to clipboard',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: html));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('HTML copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Try opening in browser',
            onPressed: () async {
              try {
                await HtmlPreviewHelper.openInBrowser(html, title: title);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Browser not available: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF1E1E1E),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            html,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFFD4D4D4),
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
