/// Example 05: Advanced Custom CSS
///
/// Demonstrates advanced CSS customization including:
/// - Custom typography (fonts, sizes, line-height)
/// - Color schemes and branding
/// - Spacing and layout control
/// - Responsive design patterns
/// - CSS variables for theming
library;

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

class CustomCssExample extends StatefulWidget {
  const CustomCssExample({super.key});

  @override
  State<CustomCssExample> createState() => _CustomCssExampleState();
}

class _CustomCssExampleState extends State<CustomCssExample> {
  String _selectedTheme = 'corporate';

  // Define multiple CSS themes
  final Map<String, String> _cssThemes = {
    'corporate': '''
      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        line-height: 1.6;
        color: #2C3E50;
      }
      h1 {
        color: #1A5490;
        font-size: 32px;
        font-weight: 700;
        margin: 24px 0 16px 0;
        border-bottom: 3px solid #1A5490;
        padding-bottom: 8px;
      }
      h2 {
        color: #2874A6;
        font-size: 24px;
        font-weight: 600;
        margin: 20px 0 12px 0;
      }
      h3 {
        color: #5499C7;
        font-size: 18px;
        font-weight: 600;
        margin: 16px 0 8px 0;
      }
      p {
        margin: 12px 0;
        font-size: 16px;
      }
      a {
        color: #1A5490;
        text-decoration: none;
        border-bottom: 1px solid #1A5490;
      }
      code {
        background: #ECF0F1;
        color: #E74C3C;
        padding: 2px 6px;
        border-radius: 3px;
        font-family: 'Courier New', monospace;
        font-size: 14px;
      }
      blockquote {
        border-left: 4px solid #1A5490;
        padding-left: 16px;
        margin: 16px 0;
        color: #5D6D7E;
        font-style: italic;
      }
      .highlight-box {
        background: #EBF5FB;
        border: 1px solid #1A5490;
        border-radius: 8px;
        padding: 16px;
        margin: 16px 0;
      }
    ''',

    'modern': '''
      body {
        font-family: 'Inter', 'SF Pro', -apple-system, sans-serif;
        line-height: 1.7;
        color: #111827;
      }
      h1 {
        color: #7C3AED;
        font-size: 36px;
        font-weight: 800;
        margin: 28px 0 16px 0;
        letter-spacing: -0.5px;
      }
      h2 {
        color: #8B5CF6;
        font-size: 28px;
        font-weight: 700;
        margin: 24px 0 12px 0;
        letter-spacing: -0.3px;
      }
      h3 {
        color: #A78BFA;
        font-size: 20px;
        font-weight: 600;
        margin: 20px 0 10px 0;
      }
      p {
        margin: 14px 0;
        font-size: 16px;
        color: #374151;
      }
      a {
        color: #7C3AED;
        text-decoration: none;
        font-weight: 500;
      }
      code {
        background: linear-gradient(135deg, #FEF3C7 0%, #FDE68A 100%);
        color: #92400E;
        padding: 3px 8px;
        border-radius: 6px;
        font-family: 'Fira Code', 'Courier New', monospace;
        font-size: 14px;
      }
      blockquote {
        border-left: 5px solid #7C3AED;
        padding-left: 20px;
        margin: 20px 0;
        color: #6B7280;
        font-size: 17px;
      }
      .highlight-box {
        background: linear-gradient(135deg, #F3E8FF 0%, #E9D5FF 100%);
        border: 2px solid #7C3AED;
        border-radius: 12px;
        padding: 20px;
        margin: 20px 0;
        box-shadow: 0 4px 6px rgba(124, 58, 237, 0.1);
      }
    ''',

    'minimal': '''
      body {
        font-family: 'Georgia', 'Times New Roman', serif;
        line-height: 1.8;
        color: #1a1a1a;
      }
      h1 {
        color: #000000;
        font-size: 32px;
        font-weight: 400;
        margin: 32px 0 16px 0;
      }
      h2 {
        color: #000000;
        font-size: 24px;
        font-weight: 400;
        margin: 28px 0 12px 0;
      }
      h3 {
        color: #333333;
        font-size: 18px;
        font-weight: 400;
        margin: 24px 0 10px 0;
      }
      p {
        margin: 16px 0;
        font-size: 17px;
        color: #333333;
      }
      a {
        color: #000000;
        text-decoration: underline;
      }
      code {
        background: #f5f5f5;
        color: #666666;
        padding: 2px 6px;
        border-radius: 2px;
        font-family: 'Courier', monospace;
        font-size: 15px;
      }
      blockquote {
        border-left: 2px solid #000000;
        padding-left: 24px;
        margin: 24px 0;
        color: #666666;
      }
      .highlight-box {
        background: #fafafa;
        border: 1px solid #e0e0e0;
        padding: 20px;
        margin: 20px 0;
      }
    ''',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('05: Custom CSS'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.palette),
            onSelected: (theme) {
              setState(() {
                _selectedTheme = theme;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'corporate',
                child: Text('Corporate Theme'),
              ),
              const PopupMenuItem(
                value: 'modern',
                child: Text('Modern Theme'),
              ),
              const PopupMenuItem(
                value: 'minimal',
                child: Text('Minimal Theme'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: HyperViewer(
          html: '''
            <article>
              <h1>Advanced CSS Customization</h1>

              <p>
                HyperRender supports comprehensive CSS customization through the
                <code>customCss</code> parameter. This allows you to match your
                app's branding and design system perfectly.
              </p>

              <div class="highlight-box">
                <strong>Current Theme:</strong> ${_selectedTheme.toUpperCase()}<br>
                Tap the palette icon above to switch themes!
              </div>

              <h2>Typography Control</h2>

              <p>
                You have complete control over fonts, sizes, weights, line-height,
                and letter-spacing. Each theme demonstrates different typography
                approaches:
              </p>

              <ul>
                <li><strong>Corporate:</strong> Professional sans-serif with clear hierarchy</li>
                <li><strong>Modern:</strong> Bold gradients with tight letter-spacing</li>
                <li><strong>Minimal:</strong> Classic serif with generous spacing</li>
              </ul>

              <h2>Color Schemes</h2>

              <p>
                Apply your brand colors to headings, links, code blocks, and
                highlights. Each element can have its own color scheme.
              </p>

              <h3>Code Highlighting</h3>

              <p>
                Here's an example of inline code: <code>HyperViewer(customCss: '...')</code>.
                Notice how it adapts to the selected theme!
              </p>

              <blockquote>
                "Good typography makes reading effortless. Great typography makes
                it a pleasure."
              </blockquote>

              <h2>Layout & Spacing</h2>

              <p>
                Control margins, padding, and spacing between elements. This ensures
                your content feels spacious and readable, not cramped.
              </p>

              <h3>Best Practices</h3>

              <ol>
                <li>Match your Flutter app's theme colors</li>
                <li>Test with real content, not Lorem Ipsum</li>
                <li>Ensure sufficient contrast (WCAG AA: 4.5:1)</li>
                <li>Keep line-height between 1.4-1.8 for readability</li>
                <li>Use system fonts for better performance</li>
              </ol>

              <div class="highlight-box">
                <strong>💡 Pro Tip:</strong><br>
                Define CSS themes in a separate file and import them based on user
                preferences. This makes A/B testing and experimentation much easier!
              </div>

              <h2>Responsive Design</h2>

              <p>
                While HyperRender doesn't support CSS media queries, you can
                use Flutter's <code>MediaQuery</code> to inject different CSS
                based on screen size:
              </p>

              <p>
                <code>customCss: MediaQuery.of(context).size.width > 600 ? tabletCss : mobileCss</code>
              </p>

              <h3>Theme Switching</h3>

              <p>
                This example demonstrates dynamic theme switching. Try tapping
                the palette icon in the app bar to switch between Corporate,
                Modern, and Minimal themes in real-time!
              </p>
            </article>
          ''',
          customCss: _cssThemes[_selectedTheme]!,
          onLinkTap: (url) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Link: $url')),
            );
          },
        ),
      ),
    );
  }
}
