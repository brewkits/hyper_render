/// Example 04: Dark Mode Support
///
/// Demonstrates theme-aware HTML rendering with custom CSS.
library;

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

class DarkModeExample extends StatelessWidget {
  const DarkModeExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('04: Dark Mode'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: HyperViewer(
          html: '''
            <article>
              <h1>Dark Mode Support</h1>

              <p>
                This page automatically adapts to your system theme!
                Try switching between light and dark mode in your device settings.
              </p>

              <h2>How It Works</h2>

              <p>
                HyperRender uses <code>customCss</code> to apply theme-specific styles.
                You can check <code>Theme.of(context).brightness</code> and inject
                appropriate CSS colors.
              </p>

              <div style="background: var(--card-bg, #f5f5f5); padding: 16px; border-radius: 8px; margin: 16px 0;">
                <strong>Current Mode:</strong> ${isDark ? 'Dark 🌙' : 'Light ☀️'}
              </div>

              <h3>Best Practices</h3>

              <ul>
                <li>Use CSS custom properties (variables)</li>
                <li>Test in both light and dark modes</li>
                <li>Ensure sufficient contrast ratios (WCAG AA: 4.5:1)</li>
                <li>Avoid hardcoded colors in HTML</li>
              </ul>

              <blockquote>
                "Good dark mode support improves user experience and reduces eye strain."
              </blockquote>

              <h3>Color Palette</h3>

              <div style="display: flex; gap: 8px; flex-wrap: wrap;">
                <div style="width: 60px; height: 60px; background: var(--primary, #6750A4); border-radius: 8px;"></div>
                <div style="width: 60px; height: 60px; background: var(--secondary, #625B71); border-radius: 8px;"></div>
                <div style="width: 60px; height: 60px; background: var(--surface, #FFFBFE); border-radius: 8px;"></div>
              </div>
            </article>
          ''',
          // Apply theme-aware CSS
          customCss: isDark
              ? '''
                  body {
                    color: #E6E1E5;
                    background: #1C1B1F;
                  }
                  h1, h2, h3 { color: #D0BCFF; }
                  a { color: #D0BCFF; }
                  code {
                    background: #2B2930;
                    color: #CCC2DC;
                    padding: 2px 6px;
                    border-radius: 4px;
                  }
                  blockquote {
                    border-left: 4px solid #D0BCFF;
                    padding-left: 16px;
                    color: #CAC4D0;
                  }
                  --card-bg: #2B2930;
                  --primary: #D0BCFF;
                  --secondary: #CCC2DC;
                  --surface: #1C1B1F;
                '''
              : '''
                  body {
                    color: #1C1B1F;
                    background: #FFFBFE;
                  }
                  h1, h2, h3 { color: #6750A4; }
                  a { color: #6750A4; }
                  code {
                    background: #F3EDF7;
                    color: #21005D;
                    padding: 2px 6px;
                    border-radius: 4px;
                  }
                  blockquote {
                    border-left: 4px solid #6750A4;
                    padding-left: 16px;
                    color: #49454F;
                  }
                  --card-bg: #F3EDF7;
                  --primary: #6750A4;
                  --secondary: #625B71;
                  --surface: #FFFBFE;
                ''',
        ),
      ),
    );
  }
}
