import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

/// Base URL & Link Handling Demo
/// Shows relative URL resolution and link tap handling with HyperViewer.
class BaseUrlDemo extends StatefulWidget {
  const BaseUrlDemo({super.key});

  @override
  State<BaseUrlDemo> createState() => _BaseUrlDemoState();
}

class _BaseUrlDemoState extends State<BaseUrlDemo> {
  final List<String> _linkLog = [];
  String _baseUrl = 'https://picsum.photos/';
  String _customHtml = '<p>Edit the base URL and HTML below.</p>';
  final _htmlController = TextEditingController();
  final _baseUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _htmlController.text =
        '<p>Tap <a href="200/300">an image link</a> or <a href="mailto:test@example.com">send email</a>.</p>';
    _baseUrlController.text = _baseUrl;
  }

  @override
  void dispose() {
    _htmlController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  void _handleLinkTap(String url) {
    setState(() {
      _linkLog.insert(0, '${_timestamp()} → $url');
      if (_linkLog.length > 8) _linkLog.removeLast();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link tapped: $url'),
        duration: const Duration(seconds: 2),
        backgroundColor: DemoColors.secondary,
      ),
    );
  }

  String _timestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  /// Resolve a relative URL against a base URL (simple string concat approach).
  String _resolveUrl(String base, String relative) {
    if (relative.startsWith('http://') || relative.startsWith('https://')) {
      return relative;
    }
    if (relative.startsWith('mailto:') || relative.startsWith('tel:')) {
      return relative;
    }
    final trimmedBase = base.endsWith('/') ? base : '$base/';
    final trimmedRel =
        relative.startsWith('/') ? relative.substring(1) : relative;
    return '$trimmedBase$trimmedRel';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Base URL & Links'),
        backgroundColor: DemoColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSection1RelativeUrl(),
          const SizedBox(height: 20),
          _buildSection2LinkHandling(),
          const SizedBox(height: 20),
          _buildSection3Interactive(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.deepPurple.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.link, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text('Base URL & Link Handling',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ]),
          SizedBox(height: 8),
          Text(
            'Resolve relative URLs against a base, and intercept link taps '
            'for navigation, mailto, tel, and external URLs.',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSection1RelativeUrl() {
    const baseImgUrl = 'https://picsum.photos/';
    final resolvedHtml = '''
<div style="font-family: sans-serif;">
  <h3 style="color: #7E57C2;">Relative URL Resolution</h3>
  <p style="color: #555; font-size: 13px;">
    Base: <code>$baseImgUrl</code><br>
    Images below use relative paths — they are resolved against the base URL.
  </p>
  <div style="display: flex; gap: 8px; flex-wrap: wrap;">
    <div style="text-align: center; margin: 4px;">
      <img src="${_resolveUrl(baseImgUrl, '150/150?random=10')}"
           style="width: 100px; height: 100px; border-radius: 8px;" />
      <p style="font-size: 11px; color: #888; margin: 4px 0;">150/150?random=10</p>
    </div>
    <div style="text-align: center; margin: 4px;">
      <img src="${_resolveUrl(baseImgUrl, '150/150?random=20')}"
           style="width: 100px; height: 100px; border-radius: 8px;" />
      <p style="font-size: 11px; color: #888; margin: 4px 0;">150/150?random=20</p>
    </div>
    <div style="text-align: center; margin: 4px;">
      <img src="${_resolveUrl(baseImgUrl, '150/150?random=30')}"
           style="width: 100px; height: 100px; border-radius: 8px;" />
      <p style="font-size: 11px; color: #888; margin: 4px 0;">150/150?random=30</p>
    </div>
  </div>
</div>
''';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.link, color: DemoColors.secondary),
              SizedBox(width: 8),
              Text('1. Relative URL Resolution',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 8),
            Text(
              'Relative URLs like "150/150?random=10" are resolved against '
              '"$baseImgUrl" to form complete URLs before loading.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            // Show resolved URLs
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resolved URLs:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.purple)),
                  const SizedBox(height: 4),
                  _buildResolvedUrl(
                      baseImgUrl, '150/150?random=10'),
                  _buildResolvedUrl(
                      baseImgUrl, '150/150?random=20'),
                  _buildResolvedUrl(
                      baseImgUrl, '150/150?random=30'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: HyperViewer(
                html: resolvedHtml,
                mode: HyperRenderMode.sync,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolvedUrl(String base, String relative) {
    final resolved = _resolveUrl(base, relative);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        '"$relative" → $resolved',
        style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Colors.deepPurple),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSection2LinkHandling() {
    const linkHtml = '''
<div style="font-family: sans-serif; line-height: 1.8;">
  <h3 style="color: #7E57C2; margin-bottom: 8px;">Tap the links below:</h3>
  <p>🌐 <a href="https://flutter.dev">External: flutter.dev</a></p>
  <p>📧 <a href="mailto:hello@example.com">Email: hello@example.com</a></p>
  <p>📞 <a href="tel:+1234567890">Phone: +1234567890</a></p>
  <p>🔗 <a href="/relative/path">Relative: /relative/path</a></p>
  <p>📄 <a href="page/about">Relative: page/about</a></p>
</div>
''';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.touch_app, color: DemoColors.secondary),
              SizedBox(width: 8),
              Text('2. Link Tap Handling',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 8),
            Text(
              'onLinkTap: callback intercepts all link taps. '
              'Handle navigation, mailto, tel, or external URLs as you need.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: HyperViewer(
                html: linkHtml,
                mode: HyperRenderMode.sync,
                onLinkTap: _handleLinkTap,
              ),
            ),
            const SizedBox(height: 12),
            if (_linkLog.isNotEmpty) ...[
              const Text('Link tap log:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _linkLog
                      .map((log) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              log,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Color(0xFFA6E3A1)),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    Text('Tap a link above to see it logged here',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection3Interactive() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.tune, color: DemoColors.secondary),
              SizedBox(width: 8),
              Text('3. Interactive Base URL Resolver',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 8),
            Text(
              'Enter a base URL and HTML with relative links/images. '
              'See how they resolve.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                prefixIcon: Icon(Icons.public),
                border: OutlineInputBorder(),
                hintText: 'https://example.com/',
              ),
              onChanged: (v) => setState(() => _baseUrl = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _htmlController,
              decoration: const InputDecoration(
                labelText: 'Custom HTML',
                prefixIcon: Icon(Icons.code),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (v) => setState(() => _customHtml = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() {
                  _baseUrl = _baseUrlController.text;
                  _customHtml = _htmlController.text;
                }),
                icon: const Icon(Icons.refresh),
                label: const Text('Apply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DemoColors.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Base URL:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.purple)),
                  Text(
                    _baseUrl.isEmpty ? '(empty)' : _baseUrl,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.deepPurple),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Rendered output:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: HyperViewer(
                html: _customHtml,
                mode: HyperRenderMode.sync,
                onLinkTap: _handleLinkTap,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Note: HyperViewer\'s onLinkTap callback receives the URL as '
              'written in the HTML. Resolve against baseUrl in your callback '
              'for relative URLs.',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
