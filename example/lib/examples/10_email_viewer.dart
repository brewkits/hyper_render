/// Example 10: Email Viewer
///
/// Demonstrates HyperRender for email client use case:
/// - Rendering email HTML safely (XSS protection critical!)
/// - Handling inline images and attachments
/// - Collapsible quoted replies
/// - Contact cards
/// - Action buttons (reply, forward, delete)
/// - Threading support
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_render/hyper_render.dart';

class Email {
  final String id;
  final String from;
  final String fromEmail;
  final String subject;
  final DateTime timestamp;
  final String htmlBody;
  final List<String> to;
  final List<String> cc;
  final bool hasAttachments;
  final int attachmentCount;
  final bool isStarred;
  final bool isRead;

  Email({
    required this.id,
    required this.from,
    required this.fromEmail,
    required this.subject,
    required this.timestamp,
    required this.htmlBody,
    required this.to,
    this.cc = const [],
    this.hasAttachments = false,
    this.attachmentCount = 0,
    this.isStarred = false,
    this.isRead = true,
  });
}

class EmailViewerExample extends StatefulWidget {
  const EmailViewerExample({super.key});

  @override
  State<EmailViewerExample> createState() => _EmailViewerExampleState();
}

class _EmailViewerExampleState extends State<EmailViewerExample> {
  bool _showQuotedText = false;
  bool _isStarred = false;

  final Email _email = Email(
    id: '1',
    from: 'Sarah Johnson',
    fromEmail: 'sarah.johnson@example.com',
    subject: 'Q1 Performance Review - HyperRender Integration',
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    to: ['you@example.com'],
    cc: ['team@example.com', 'manager@example.com'],
    hasAttachments: true,
    attachmentCount: 2,
    isRead: true,
    htmlBody: '''
      <div style="font-family: -apple-system, sans-serif; font-size: 14px; line-height: 1.6; color: #1a1a1a;">
        <p>Hi Team,</p>

        <p>
          I wanted to share our Q1 results for the HyperRender integration project.
          Overall, the results have been <strong>outstanding</strong> and exceeded
          our initial projections.
        </p>

        <h3 style="color: #1976D2; margin-top: 20px;">Key Metrics</h3>

        <table style="width: 100%; border-collapse: collapse; margin: 16px 0;">
          <thead>
            <tr style="background: #f5f5f5;">
              <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Metric</th>
              <th style="padding: 12px; text-align: right; border: 1px solid #ddd;">Before</th>
              <th style="padding: 12px; text-align: right; border: 1px solid #ddd;">After</th>
              <th style="padding: 12px; text-align: right; border: 1px solid #ddd;">Change</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td style="padding: 10px; border: 1px solid #ddd;">Render Time</td>
              <td style="padding: 10px; border: 1px solid #ddd; text-align: right;">180ms</td>
              <td style="padding: 10px; border: 1px solid #ddd; text-align: right;">69ms</td>
              <td style="padding: 10px; border: 1px solid #ddd; text-align: right; color: #4CAF50; font-weight: bold;">-62%</td>
            </tr>
            <tr style="background: #fafafa;">
              <td style="padding: 10px; border: 1px solid #ddd;">Frame Drops</td>
              <td style="padding: 10px; border: 1px solid #ddd; text-align: right;">23%</td>
              <td style="padding: 10px; border: 1px solid #ddd; text-align: right;">2%</td>
              <td style="padding: 10px; border: 1px solid #ddd; text-align: right; color: #4CAF50; font-weight: bold;">-91%</td>
            </tr>
            <tr>
              <td style="padding: 10px; border: 1px solid #ddd;">User Satisfaction</td>
              <td style="padding: 10px; border: 1px solid #ddd; text-align: right;">73%</td>
              <td style="padding: 10px; border: 1px solid #ddd; text-align: right;">94%</td>
              <td style="padding: 10px; border: 1px solid #ddd; text-align: right; color: #4CAF50; font-weight: bold;">+29%</td>
            </tr>
          </tbody>
        </table>

        <h3 style="color: #1976D2; margin-top: 20px;">Technical Highlights</h3>

        <ul>
          <li>
            <strong>CSS Float Support:</strong> Enabled magazine-style layouts
            that were previously impossible
          </li>
          <li>
            <strong>Performance:</strong> Achieved 60fps scrolling even with
            1000+ paragraph documents
          </li>
          <li>
            <strong>Security:</strong> Built-in XSS sanitization prevented
            3 potential vulnerabilities
          </li>
          <li>
            <strong>Developer Experience:</strong> Migration took only 2 days
            vs projected 2 weeks
          </li>
        </ul>

        <div style="background: #E3F2FD; border-left: 4px solid #1976D2; padding: 16px; margin: 20px 0; border-radius: 4px;">
          <strong style="color: #1565C0;">💡 Key Insight</strong><br><br>
          The single RenderObject architecture was the game-changer. It eliminated
          the coordination overhead between widgets and enabled features we couldn't
          build before.
        </div>

        <h3 style="color: #1976D2; margin-top: 20px;">Next Steps</h3>

        <ol>
          <li>
            <strong>Mobile Benchmarking:</strong> We need comprehensive mobile
            device testing to validate performance claims
          </li>
          <li>
            <strong>A11y Audit:</strong> Conduct full accessibility audit
          </li>
          <li>
            <strong>Documentation:</strong> Create migration guides for other teams
          </li>
          <li>
            <strong>Case Study:</strong> Publish findings at FlutterCon 2026
          </li>
        </ol>

        <p style="margin-top: 24px;">
          Please review the attached reports and let me know if you have any questions.
          I've scheduled a team meeting for Friday at 2pm to discuss Q2 plans.
        </p>

        <p>
          Best regards,<br>
          <strong>Sarah Johnson</strong><br>
          <span style="color: #666; font-size: 12px;">
            Senior Engineering Manager<br>
            Mobile Platform Team<br>
            sarah.johnson@example.com
          </span>
        </p>

        <hr style="border: none; border-top: 1px solid #ddd; margin: 24px 0;">

        <div style="color: #666; font-size: 12px; margin-top: 20px;">
          <p><strong>Attachments:</strong></p>
          <ul style="list-style: none; padding: 0;">
            <li>📊 Q1_Performance_Report.pdf (1.2 MB)</li>
            <li>📈 Benchmarks_Detailed.xlsx (456 KB)</li>
          </ul>
        </div>
      </div>
    ''',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('10: Email Viewer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isStarred ? Icons.star : Icons.star_border),
            onPressed: () {
              setState(() => _isStarred = !_isStarred);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isStarred ? 'Starred' : 'Unstarred'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Email header
          _EmailHeader(email: _email),

          const Divider(height: 1),

          // Email body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main content
                  HyperViewer(
                    html: _email.htmlBody,
                    onLinkTap: (url) {
                      _showLinkDialog(context, url);
                    },
                    onError: (error, stackTrace) {
                      debugPrint('Render error: $error');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Email rendering warning: ${error.toString()}'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                  ),

                  // Quoted text section (collapsed by default)
                  if (!_showQuotedText) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => setState(() => _showQuotedText = true),
                      icon: const Icon(Icons.expand_more, size: 20),
                      label: const Text('Show quoted text'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Previous Message',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.expand_less, size: 20),
                                onPressed: () => setState(() => _showQuotedText = false),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          HyperViewer(
                            html: '''
                              <div style="font-family: sans-serif; font-size: 13px; color: #555;">
                                <p>On Mar 1, 2026, at 10:34 AM, John Smith wrote:</p>
                                <p>
                                  Sarah, can you provide a status update on the HyperRender
                                  integration? We need this for the board meeting next week.
                                </p>
                                <p>Thanks,<br>John</p>
                              </div>
                            ''',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _replyToEmail(context),
                    icon: const Icon(Icons.reply),
                    label: const Text('Reply'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _forwardEmail(context),
                    icon: const Icon(Icons.forward),
                    label: const Text('Forward'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Email?'),
        content: const Text('This email will be moved to trash.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email moved to trash')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_email_unread),
              title: const Text('Mark as Unread'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked as unread')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: const Text('Add Label'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report Spam'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Link?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This email contains a link to:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                url,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Make sure you trust this sender before opening links.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Would open: $url')),
              );
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  void _replyToEmail(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Composing reply to ${_email.from}...'),
        action: SnackBarAction(label: 'Open', onPressed: () {}),
      ),
    );
  }

  void _forwardEmail(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forwarding email...')),
    );
  }
}

class _EmailHeader extends StatelessWidget {
  final Email email;

  const _EmailHeader({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject
          Text(
            email.subject,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // From
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade700,
                child: Text(
                  email.from[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          email.from,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        if (email.hasAttachments)
                          Icon(
                            Icons.attach_file,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                      ],
                    ),
                    Text(
                      '<${email.fromEmail}>',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatTime(email.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // To/CC
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'to ',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Expanded(
                child: Text(
                  '${email.to.join(", ")}${email.cc.isNotEmpty ? ", cc: ${email.cc.join(", ")}" : ""}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 1) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
