import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/node.dart';

/// Widget that displays error boundaries in a user-friendly way
///
/// Shows a beautiful error UI with:
/// - Error icon and message
/// - Expandable details (stack trace)
/// - Copy error button
/// - Retry option (if provided)
///
/// Example:
/// ```dart
/// ErrorBoundaryWidget(
///   errorNode: errorBoundaryNode,
///   onRetry: () => retryParsing(),
/// )
/// ```
class ErrorBoundaryWidget extends StatefulWidget {
  /// The error boundary node to display
  final ErrorBoundaryNode errorNode;

  /// Optional callback to retry the operation
  final VoidCallback? onRetry;

  /// Whether to show technical details by default
  final bool showDetailsInitially;

  const ErrorBoundaryWidget({
    super.key,
    required this.errorNode,
    this.onRetry,
    this.showDetailsInitially = false,
  });

  @override
  State<ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget> {
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _showDetails = widget.showDetailsInitially;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.shade900.withValues(alpha:0.2) : Colors.red.shade50,
        border: Border.all(
          color: isDark ? Colors.red.shade700 : Colors.red.shade200,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon and message
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.errorNode.friendlyMessage ?? 'An error occurred',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.red.shade300 : Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.errorNode.errorMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.red.shade200 : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              // Show/Hide Details button
              TextButton.icon(
                icon: Icon(
                  _showDetails ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Text(_showDetails ? 'Hide Details' : 'Show Details'),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.red.shade300 : Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  setState(() {
                    _showDetails = !_showDetails;
                  });
                },
              ),

              const SizedBox(width: 8),

              // Copy Error button
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Error'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.red.shade300 : Colors.red.shade700,
                  side: BorderSide(
                    color: isDark ? Colors.red.shade700 : Colors.red.shade300,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _copyErrorToClipboard(context),
              ),

              // Retry button (if callback provided)
              if (widget.onRetry != null) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.red.shade700 : Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: widget.onRetry,
                ),
              ],
            ],
          ),

          // Expandable details section
          if (_showDetails) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Stack trace
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stack Trace:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    widget.errorNode.shortStackTrace,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            // Original content (if available)
            if (widget.errorNode.originalContent != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original Content:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      widget.errorNode.originalContent!.length > 500
                          ? '${widget.errorNode.originalContent!.substring(0, 500)}...'
                          : widget.errorNode.originalContent!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Copy error details to clipboard
  Future<void> _copyErrorToClipboard(BuildContext context) async {
    final buffer = StringBuffer();
    buffer.writeln('Error: ${widget.errorNode.errorMessage}');
    if (widget.errorNode.friendlyMessage != null) {
      buffer.writeln('Message: ${widget.errorNode.friendlyMessage}');
    }
    buffer.writeln('\nStack Trace:');
    buffer.writeln(widget.errorNode.stackTrace.toString());

    if (widget.errorNode.originalContent != null) {
      buffer.writeln('\nOriginal Content:');
      buffer.writeln(widget.errorNode.originalContent);
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error details copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
