import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('Real-World HTML Integration Tests', () {
    testWidgets('renders news article with images', (tester) async {
      const newsArticle = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Breaking News</title>
</head>
<body>
  <article>
    <header>
      <h1>Major Technology Breakthrough Announced</h1>
      <p class="byline">By Jane Doe | February 13, 2026</p>
    </header>

    <img src="https://picsum.photos/800/400"
         alt="Technology illustration"
         style="width: 100%; height: auto; margin: 20px 0;">

    <p class="lead">
      Scientists today announced a groundbreaking discovery that could
      revolutionize the field of quantum computing.
    </p>

    <h2>Key Findings</h2>
    <ul>
      <li>New algorithm improves qubit stability by 300%</li>
      <li>Error correction rates improved to 99.99%</li>
      <li>Room temperature operation now possible</li>
    </ul>

    <blockquote style="border-left: 4px solid #1976D2; padding-left: 16px; margin: 20px 0;">
      "This changes everything we thought we knew about quantum systems."
      <footer>— Dr. Sarah Chen, Lead Researcher</footer>
    </blockquote>

    <h2>Implications</h2>
    <p>
      The breakthrough could have far-reaching implications for:
    </p>
    <ol>
      <li><strong>Cryptography</strong>: New encryption methods</li>
      <li><strong>Medicine</strong>: Drug discovery acceleration</li>
      <li><strong>AI</strong>: More powerful machine learning models</li>
    </ol>

    <aside style="background: #f5f5f5; padding: 16px; border-radius: 8px; margin: 20px 0;">
      <h3>Related Articles</h3>
      <ul>
        <li><a href="#">Quantum Computing 101</a></li>
        <li><a href="#">Previous Breakthroughs in 2025</a></li>
      </ul>
    </aside>

    <footer style="border-top: 1px solid #ddd; padding-top: 16px; margin-top: 40px;">
      <p><small>© 2026 Tech News. All rights reserved.</small></p>
    </footer>
  </article>
</body>
</html>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: newsArticle,
                mode: HyperRenderMode.sync,
                selectable: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify key elements are rendered
      expect(find.text('Major Technology Breakthrough Announced'), findsOneWidget);
      expect(find.text('By Jane Doe | February 13, 2026'), findsOneWidget);
      expect(find.text('Key Findings'), findsOneWidget);
      expect(find.text('New algorithm improves qubit stability by 300%'), findsOneWidget);

      // Verify blockquote
      expect(find.textContaining('This changes everything'), findsOneWidget);

      // Verify ordered list
      expect(find.textContaining('Cryptography'), findsOneWidget);
      expect(find.textContaining('Medicine'), findsOneWidget);
      expect(find.textContaining('AI'), findsOneWidget);
    });

    testWidgets('renders blog post with code blocks', (tester) async {
      const blogPost = '''
<article>
  <h1>Getting Started with Flutter</h1>

  <p>
    Flutter is Google's UI toolkit for building beautiful, natively compiled
    applications from a single codebase.
  </p>

  <h2>Installation</h2>
  <p>First, install Flutter SDK:</p>

  <pre><code>git clone https://github.com/flutter/flutter.git
export PATH="\$PATH:`pwd`/flutter/bin"
flutter doctor</code></pre>

  <h2>Creating Your First App</h2>
  <p>Run the following command:</p>

  <pre><code>flutter create my_app
cd my_app
flutter run</code></pre>

  <h2>Basic Widget Example</h2>
  <p>Here's a simple counter app:</p>

  <pre><code>import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(),
    );
  }
}</code></pre>

  <h2>Tips and Tricks</h2>
  <ul>
    <li>Use <code>hot reload</code> for fast iteration</li>
    <li>Leverage <code>const</code> constructors for performance</li>
    <li>Follow the <a href="#">Flutter style guide</a></li>
  </ul>

  <p>Happy coding! 🚀</p>
</article>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: blogPost,
                selectable: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify headings
      expect(find.text('Getting Started with Flutter'), findsOneWidget);
      expect(find.text('Installation'), findsOneWidget);
      expect(find.text('Creating Your First App'), findsOneWidget);

      // Verify code blocks are rendered (contains code text)
      expect(find.textContaining('flutter create my_app'), findsOneWidget);
      expect(find.textContaining('import \'package:flutter/material.dart\''), findsOneWidget);

      // Verify inline code
      expect(find.textContaining('hot reload'), findsOneWidget);
    });

    testWidgets('renders documentation with tables', (tester) async {
      const documentation = '''
<article>
  <h1>API Reference</h1>

  <h2>HyperViewer Widget</h2>
  <p>The main widget for rendering HTML content.</p>

  <h3>Constructor Parameters</h3>
  <table border="1" style="width: 100%; border-collapse: collapse;">
    <thead>
      <tr style="background-color: #f5f5f5;">
        <th style="padding: 8px; text-align: left;">Parameter</th>
        <th style="padding: 8px; text-align: left;">Type</th>
        <th style="padding: 8px; text-align: left;">Required</th>
        <th style="padding: 8px; text-align: left;">Description</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="padding: 8px;"><code>html</code></td>
        <td style="padding: 8px;">String</td>
        <td style="padding: 8px;">✅ Yes</td>
        <td style="padding: 8px;">HTML content to render</td>
      </tr>
      <tr style="background-color: #fafafa;">
        <td style="padding: 8px;"><code>mode</code></td>
        <td style="padding: 8px;">HyperRenderMode</td>
        <td style="padding: 8px;">❌ No</td>
        <td style="padding: 8px;">Render mode (auto, sync, virtualized)</td>
      </tr>
      <tr>
        <td style="padding: 8px;"><code>selectable</code></td>
        <td style="padding: 8px;">bool</td>
        <td style="padding: 8px;">❌ No</td>
        <td style="padding: 8px;">Enable text selection</td>
      </tr>
      <tr style="background-color: #fafafa;">
        <td style="padding: 8px;"><code>sanitize</code></td>
        <td style="padding: 8px;">bool</td>
        <td style="padding: 8px;">❌ No</td>
        <td style="padding: 8px;">Sanitize HTML (default: true)</td>
      </tr>
    </tbody>
  </table>

  <h3>Render Modes</h3>
  <table border="1" style="width: 100%; border-collapse: collapse; margin-top: 16px;">
    <thead>
      <tr style="background-color: #f5f5f5;">
        <th style="padding: 8px;">Mode</th>
        <th style="padding: 8px;">Use Case</th>
        <th style="padding: 8px;">Performance</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="padding: 8px;"><strong>auto</strong></td>
        <td style="padding: 8px;">Unknown content size</td>
        <td style="padding: 8px;">⚡ Smart</td>
      </tr>
      <tr style="background-color: #fafafa;">
        <td style="padding: 8px;"><strong>sync</strong></td>
        <td style="padding: 8px;">&lt; 10,000 chars</td>
        <td style="padding: 8px;">⚡⚡ Very Fast</td>
      </tr>
      <tr>
        <td style="padding: 8px;"><strong>virtualized</strong></td>
        <td style="padding: 8px;">&gt; 50,000 chars</td>
        <td style="padding: 8px;">⚡⚡⚡ Efficient</td>
      </tr>
    </tbody>
  </table>

  <div style="background: #fff3cd; border: 1px solid #ffc107; padding: 12px; border-radius: 4px; margin-top: 20px;">
    <strong>⚠️ Warning:</strong> Always enable <code>sanitize</code> for user-generated content to prevent XSS attacks.
  </div>
</article>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: documentation,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify headings
      expect(find.text('API Reference'), findsOneWidget);
      expect(find.text('HyperViewer Widget'), findsOneWidget);
      expect(find.text('Constructor Parameters'), findsOneWidget);

      // Verify table content
      expect(find.textContaining('html'), findsAtLeastNWidgets(1));
      expect(find.textContaining('mode'), findsAtLeastNWidgets(1));
      expect(find.textContaining('selectable'), findsAtLeastNWidgets(1));
      expect(find.textContaining('sanitize'), findsAtLeastNWidgets(1));

      // Verify modes table
      expect(find.text('auto'), findsOneWidget);
      expect(find.text('sync'), findsOneWidget);
      expect(find.text('virtualized'), findsOneWidget);

      // Verify warning box
      expect(find.textContaining('Warning'), findsOneWidget);
      expect(find.textContaining('XSS attacks'), findsOneWidget);
    });

    testWidgets('renders complex layout with floats', (tester) async {
      const complexLayout = '''
<article style="max-width: 600px;">
  <h1>The Future of Mobile Development</h1>

  <img src="https://picsum.photos/200/200"
       style="float: left; width: 150px; height: 150px; margin: 0 16px 16px 0; border-radius: 8px;">

  <p>
    Mobile development has come a long way since the first smartphones.
    Today, developers have powerful frameworks like Flutter that enable
    building beautiful, fast applications for multiple platforms from a
    single codebase.
  </p>

  <p>
    The cross-platform approach offers significant advantages in terms of
    development speed and maintenance costs, while still delivering native
    performance and user experience.
  </p>

  <div style="clear: both;"></div>

  <h2>Key Technologies</h2>

  <img src="https://picsum.photos/200/150"
       style="float: right; width: 180px; height: auto; margin: 0 0 16px 16px; border: 2px solid #ddd;">

  <p>
    Modern mobile frameworks leverage advanced rendering engines,
    declarative UI paradigms, and hot reload capabilities to maximize
    developer productivity.
  </p>

  <ul>
    <li>Declarative UI with reactive updates</li>
    <li>Rich widget libraries</li>
    <li>Native performance</li>
    <li>Hot reload for fast iteration</li>
  </ul>

  <p>
    These capabilities allow teams to build world-class applications
    in a fraction of the time it would take with traditional native
    development approaches.
  </p>

  <div style="clear: both; padding-top: 20px;"></div>

  <footer style="border-top: 1px solid #eee; padding-top: 16px; margin-top: 20px; color: #666;">
    <p><small>Published February 2026</small></p>
  </footer>
</article>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: complexLayout,
                selectable: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify content is rendered
      expect(find.text('The Future of Mobile Development'), findsOneWidget);
      expect(find.textContaining('Mobile development has come a long way'), findsOneWidget);
      expect(find.text('Key Technologies'), findsOneWidget);
      expect(find.textContaining('Declarative UI with reactive updates'), findsOneWidget);
    });

    testWidgets('handles HTML entities and special characters', (tester) async {
      const htmlEntities = '''
<div>
  <h2>Special Characters &amp; Entities</h2>

  <p>Common entities:</p>
  <ul>
    <li>Ampersand: &amp;</li>
    <li>Less than: &lt;</li>
    <li>Greater than: &gt;</li>
    <li>Quote: &quot;</li>
    <li>Apostrophe: &apos;</li>
    <li>Non-breaking space: Hello&nbsp;World</li>
    <li>Copyright: &copy; 2026</li>
    <li>Euro: &euro; 100</li>
    <li>Trademark: HyperRender&trade;</li>
  </ul>

  <h3>Unicode Characters</h3>
  <p>
    Emoji: 🚀 🎉 ✅ ❌ ⚠️<br>
    Math: π ≈ 3.14, ∞ > 0<br>
    Arrows: → ← ↑ ↓ ↔<br>
    Symbols: ★ ☆ ♥ ♦ ♣ ♠
  </p>

  <h3>CJK Characters</h3>
  <p>
    日本語: こんにちは<br>
    中文: 你好世界<br>
    한국어: 안녕하세요
  </p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: htmlEntities,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify entities are decoded
      expect(find.textContaining('&'), findsWidgets);
      expect(find.textContaining('<'), findsWidgets);
      expect(find.textContaining('>'), findsWidgets);

      // Verify unicode works
      expect(find.textContaining('🚀'), findsOneWidget);
      expect(find.textContaining('→'), findsOneWidget);

      // Verify CJK
      expect(find.textContaining('こんにちは'), findsOneWidget);
      expect(find.textContaining('你好世界'), findsOneWidget);
      expect(find.textContaining('안녕하세요'), findsOneWidget);
    });
  });
}
