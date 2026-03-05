/// Example 01: Basic HTML Rendering
///
/// This example demonstrates the simplest possible usage of HyperRender.
/// Perfect for getting started and understanding the core API.
library;

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

class BasicHtmlExample extends StatelessWidget {
  const BasicHtmlExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('01: Basic HTML'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: HyperViewer(
          html: '''
            <article>
              <h1>Welcome to HyperRender!</h1>

              <p>
                HyperRender is a <strong>high-performance</strong> HTML rendering
                library for Flutter that supports advanced features like
                <em>CSS float layout</em> and <mark>CJK typography</mark>.
              </p>

              <h2>Key Features</h2>

              <ul>
                <li>CSS float layout (text wrapping around images)</li>
                <li>60fps scrolling on large documents</li>
                <li>Full text selection support</li>
                <li>CJK typography (Ruby, Kinsoku)</li>
                <li>Built-in XSS protection</li>
              </ul>

              <h3>Why Use HyperRender?</h3>

              <ol>
                <li><strong>Performance:</strong> 2.6× faster than flutter_widget_from_html</li>
                <li><strong>Features:</strong> CSS float support (impossible in widget-tree renderers)</li>
                <li><strong>Security:</strong> Built-in HTML sanitization</li>
                <li><strong>Typography:</strong> Best CJK support in Flutter</li>
              </ol>

              <blockquote>
                "HyperRender changes everything for Flutter developers building content apps."
                <br><em>— Senior Developer</em>
              </blockquote>

              <h2>Supported HTML Tags</h2>

              <p>
                <code>&lt;p&gt;</code>, <code>&lt;div&gt;</code>, <code>&lt;span&gt;</code>,
                <code>&lt;h1-h6&gt;</code>, <code>&lt;ul&gt;</code>, <code>&lt;ol&gt;</code>,
                <code>&lt;li&gt;</code>, <code>&lt;a&gt;</code>, <code>&lt;img&gt;</code>,
                <code>&lt;table&gt;</code>, <code>&lt;strong&gt;</code>, <code>&lt;em&gt;</code>,
                and many more!
              </p>

              <hr>

              <p style="text-align: center; color: #666;">
                <small>
                  Made with ❤️ by the HyperRender team<br>
                  Open source • MIT License
                </small>
              </p>
            </article>
          ''',
          // Optional: Handle link taps
          onLinkTap: (url) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Link tapped: $url')),
            );
          },
        ),
      ),
    );
  }
}
