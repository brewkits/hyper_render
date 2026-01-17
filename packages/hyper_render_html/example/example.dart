import 'package:flutter/material.dart';
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_html/hyper_render_html.dart';

/// Example demonstrating HTML parsing with hyper_render_html
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperRender HTML Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HtmlExamplePage(),
    );
  }
}

class HtmlExamplePage extends StatelessWidget {
  const HtmlExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Parse HTML to UDT
    final parser = DefaultHtmlParser();
    final document = parser.parse(_sampleHtml);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HyperRender HTML Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: HyperRenderWidget(document: document),
      ),
    );
  }
}

/// Sample HTML content
const _sampleHtml = '''
<article>
  <h1>Welcome to HyperRender HTML</h1>

  <p>This example demonstrates <strong>HTML parsing</strong> with full
  <em>CSS support</em> using the <code>hyper_render_html</code> plugin.</p>

  <h2>Text Formatting</h2>

  <p>You can use various text styles:</p>
  <ul>
    <li><strong>Bold text</strong> with &lt;strong&gt; or &lt;b&gt;</li>
    <li><em>Italic text</em> with &lt;em&gt; or &lt;i&gt;</li>
    <li><u>Underlined text</u> with &lt;u&gt;</li>
    <li><s>Strikethrough</s> with &lt;s&gt; or &lt;del&gt;</li>
    <li><code>Inline code</code> with &lt;code&gt;</li>
  </ul>

  <h2>Links and Images</h2>

  <p>Links work seamlessly: <a href="https://flutter.dev">Visit Flutter</a></p>

  <h2>Blockquotes</h2>

  <blockquote>
    <p>HyperRender provides a high-performance rendering engine for Flutter
    with perfect text selection and advanced CSS support.</p>
  </blockquote>

  <h2>Code Blocks</h2>

  <pre><code class="language-dart">void main() {
  final parser = HtmlContentParser();
  final document = parser.parse('&lt;p&gt;Hello World&lt;/p&gt;');

  runApp(MaterialApp(
    home: HyperRenderWidget(document: document),
  ));
}</code></pre>

  <h2>Tables</h2>

  <table>
    <thead>
      <tr>
        <th>Feature</th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>HTML Parsing</td>
        <td>✓ Supported</td>
      </tr>
      <tr>
        <td>CSS Cascade</td>
        <td>✓ Supported</td>
      </tr>
      <tr>
        <td>Inline Styles</td>
        <td>✓ Supported</td>
      </tr>
    </tbody>
  </table>

  <h2>Inline Styles</h2>

  <p style="color: #e74c3c; font-size: 18px;">
    This paragraph has inline styles applied.
  </p>

  <div style="background-color: #f0f0f0; padding: 16px; border-radius: 8px;">
    <p style="margin: 0;">A styled container with background and padding.</p>
  </div>
</article>
''';

/// Example: Using CSS parser standalone
void cssParserExample() {
  const cssParser = DefaultCssParser();

  // Parse stylesheet
  final rules = cssParser.parseStylesheet('''
    body {
      font-size: 16px;
      line-height: 1.5;
    }

    .highlight {
      background-color: yellow;
      padding: 2px 4px;
    }

    #header {
      font-weight: bold;
      font-size: 24px;
    }
  ''');

  // ignore: avoid_print
  print('Parsed ${rules.length} CSS rules');

  // Parse inline style
  final props = cssParser.parseInlineStyle(
    'color: red; margin: 10px 20px; font-weight: bold',
  );

  // ignore: avoid_print
  print('Inline properties: $props');
}

/// Example: Parsing with custom CSS
void customCssExample() {
  final parser = DefaultHtmlParser();

  final document = parser.parseWithOptions(
    '''
    <div class="card">
      <h2 class="card-title">Custom Styled Card</h2>
      <p class="card-content">This card has custom CSS applied.</p>
    </div>
    ''',
    customCss: '''
      .card {
        background-color: #ffffff;
        border: 1px solid #e0e0e0;
        border-radius: 12px;
        padding: 20px;
        margin: 16px 0;
      }

      .card-title {
        color: #1a73e8;
        font-size: 20px;
        margin-bottom: 8px;
      }

      .card-content {
        color: #5f6368;
        font-size: 14px;
        line-height: 1.6;
      }
    ''',
  );

  // ignore: avoid_print
  print('Document has ${document.children.length} children');
}

/// Example: Parsing with base URL for relative links
void baseUrlExample() {
  final parser = DefaultHtmlParser();

  // ignore: unused_local_variable
  final document = parser.parseWithOptions(
    '''
    <img src="/images/logo.png" alt="Logo">
    <a href="/about">About Us</a>
    ''',
    baseUrl: 'https://example.com',
  );

  // Images and links will resolve to:
  // - https://example.com/images/logo.png
  // - https://example.com/about

  // ignore: avoid_print
  print('Document parsed with base URL');
}
