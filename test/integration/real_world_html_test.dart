import "package:hyper_render/hyper_render.dart";
// Real-world HTML integration tests.
//
// HyperRender paints text via Canvas, not Flutter Text widgets, so
// find.text() / find.textContaining() don't work on rendered output.
// Strategy:
//   • Widget tests  → no-crash + structural widget presence
//   • Content tests → parse the HTML with HtmlAdapter and inspect textContent

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared sample HTML strings (defined once, used in both widget & unit tests)
// ─────────────────────────────────────────────────────────────────────────────

const _newsArticle = '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>Breaking News</title></head>
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
    <blockquote style="border-left:4px solid #1976D2;padding-left:16px;margin:20px 0;">
      "This changes everything we thought we knew about quantum systems."
      <footer>— Dr. Sarah Chen, Lead Researcher</footer>
    </blockquote>
    <h2>Implications</h2>
    <p>The breakthrough could have far-reaching implications for:</p>
    <ol>
      <li><strong>Cryptography</strong>: New encryption methods</li>
      <li><strong>Medicine</strong>: Drug discovery acceleration</li>
      <li><strong>AI</strong>: More powerful machine learning models</li>
    </ol>
    <footer style="border-top:1px solid #ddd;padding-top:16px;margin-top:40px;">
      <p><small>© 2026 Tech News. All rights reserved.</small></p>
    </footer>
  </article>
</body>
</html>
''';

const _blogPost = '''
<article>
  <h1>Getting Started with Flutter</h1>
  <p>Flutter is Google's UI toolkit for building beautiful, natively compiled
     applications from a single codebase.</p>
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
  <h2>Tips and Tricks</h2>
  <ul>
    <li>Use <code>hot reload</code> for fast iteration</li>
    <li>Leverage <code>const</code> constructors for performance</li>
    <li>Follow the <a href="#">Flutter style guide</a></li>
  </ul>
</article>
''';

const _documentation = '''
<article>
  <h1>API Reference</h1>
  <h2>HyperViewer Widget</h2>
  <p>The main widget for rendering HTML content.</p>
  <h3>Constructor Parameters</h3>
  <table border="1" style="width:100%;border-collapse:collapse;">
    <thead>
      <tr>
        <th>Parameter</th><th>Type</th><th>Required</th><th>Description</th>
      </tr>
    </thead>
    <tbody>
      <tr><td>html</td><td>String</td><td>Yes</td><td>HTML content to render</td></tr>
      <tr><td>mode</td><td>HyperRenderMode</td><td>No</td><td>Render mode</td></tr>
      <tr><td>selectable</td><td>bool</td><td>No</td><td>Enable text selection</td></tr>
      <tr><td>sanitize</td><td>bool</td><td>No</td><td>Sanitize HTML (default: true)</td></tr>
    </tbody>
  </table>
  <h3>Render Modes</h3>
  <table border="1" style="width:100%;border-collapse:collapse;">
    <thead><tr><th>Mode</th><th>Use Case</th><th>Performance</th></tr></thead>
    <tbody>
      <tr><td>auto</td><td>Unknown content size</td><td>Smart</td></tr>
      <tr><td>sync</td><td>Small documents</td><td>Very Fast</td></tr>
      <tr><td>virtualized</td><td>Large documents</td><td>Efficient</td></tr>
    </tbody>
  </table>
</article>
''';

const _complexLayout = '''
<article style="max-width:600px;">
  <h1>The Future of Mobile Development</h1>
  <img src="https://picsum.photos/200/200"
       style="float:left;width:150px;height:150px;margin:0 16px 16px 0;border-radius:8px;">
  <p>Mobile development has come a long way since the first smartphones.
     Today, developers have powerful frameworks like Flutter that enable
     building beautiful, fast applications for multiple platforms from a
     single codebase.</p>
  <div style="clear:both;"></div>
  <h2>Key Technologies</h2>
  <ul>
    <li>Declarative UI with reactive updates</li>
    <li>Rich widget libraries</li>
    <li>Native performance</li>
    <li>Hot reload for fast iteration</li>
  </ul>
</article>
''';

const _htmlEntities = '''
<div>
  <h2>Special Characters &amp; Entities</h2>
  <ul>
    <li>Ampersand: &amp;</li>
    <li>Less than: &lt;</li>
    <li>Greater than: &gt;</li>
    <li>Non-breaking space: Hello&nbsp;World</li>
    <li>Copyright: &copy; 2026</li>
  </ul>
  <h3>Unicode Characters</h3>
  <p>Emoji: 🚀 🎉 ✅<br>Arrows: → ← ↑ ↓</p>
  <h3>CJK Characters</h3>
  <p>日本語: こんにちは<br>中文: 你好世界<br>한국어: 안녕하세요</p>
</div>
''';

// ─────────────────────────────────────────────────────────────────────────────
// Widget rendering tests — verify no crash + widget tree structure
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Real-World HTML — Rendering (no crash)', () {
    testWidgets('renders news article with images', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: _newsArticle,
                mode: HyperRenderMode.sync,
                selectable: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
      expect(find.byType(HyperRenderWidget), findsAtLeastNWidgets(1));
    });

    testWidgets('renders blog post with code blocks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: _blogPost, selectable: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
      expect(find.byType(HyperRenderWidget), findsAtLeastNWidgets(1));
    });

    testWidgets('renders documentation with tables', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: HyperViewer(html: _documentation)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('renders complex layout with floats', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(html: _complexLayout, selectable: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('handles HTML entities and special characters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: HyperViewer(html: _htmlEntities)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Parser-level content tests — verify HTML is correctly parsed
  // ─────────────────────────────────────────────────────────────────────────

  group('Real-World HTML — Parser content', () {
    late HtmlAdapter adapter;
    setUp(() => adapter = HtmlAdapter());

    test('news article: key headings present in parsed tree', () {
      final doc = adapter.parse(_newsArticle);
      final text = doc.textContent;
      expect(text, contains('Major Technology Breakthrough Announced'));
      expect(text, contains('Key Findings'));
      expect(text, contains('Implications'));
    });

    test('news article: list items parsed', () {
      final doc = adapter.parse(_newsArticle);
      final text = doc.textContent;
      expect(text, contains('qubit stability'));
      expect(text, contains('Error correction'));
      expect(text, contains('Room temperature'));
    });

    test('news article: blockquote content preserved', () {
      final doc = adapter.parse(_newsArticle);
      expect(doc.textContent, contains('This changes everything'));
    });

    test('news article: ordered list items parsed', () {
      final doc = adapter.parse(_newsArticle);
      final text = doc.textContent;
      expect(text, contains('Cryptography'));
      expect(text, contains('Medicine'));
      expect(text, contains('AI'));
    });

    test('blog post: headings parsed correctly', () {
      final doc = adapter.parse(_blogPost);
      final text = doc.textContent;
      expect(text, contains('Getting Started with Flutter'));
      expect(text, contains('Installation'));
      expect(text, contains('Creating Your First App'));
      expect(text, contains('Tips and Tricks'));
    });

    test('blog post: code block content preserved', () {
      final doc = adapter.parse(_blogPost);
      final text = doc.textContent;
      expect(text, contains('flutter create my_app'));
    });

    test('documentation: table rows parsed', () {
      final doc = adapter.parse(_documentation);
      final text = doc.textContent;
      expect(text, contains('html'));
      expect(text, contains('mode'));
      expect(text, contains('selectable'));
      expect(text, contains('sanitize'));
    });

    test('documentation: render modes table rows parsed', () {
      final doc = adapter.parse(_documentation);
      final text = doc.textContent;
      expect(text, contains('auto'));
      expect(text, contains('sync'));
      expect(text, contains('virtualized'));
    });

    test('complex layout: floated image + text present', () {
      final doc = adapter.parse(_complexLayout);
      final text = doc.textContent;
      expect(text, contains('The Future of Mobile Development'));
      expect(text, contains('Declarative UI with reactive updates'));
      expect(text, contains('Key Technologies'));
    });

    test('HTML entities: decoded to their character', () {
      final doc = adapter.parse(_htmlEntities);
      final text = doc.textContent;
      // &amp; → &, &lt; → <, &gt; → >, &copy; → ©
      expect(text, contains('&'));
      expect(text, contains('<'));
      expect(text, contains('>'));
      expect(text, contains('©'));
    });

    test('HTML entities: unicode characters preserved', () {
      final doc = adapter.parse(_htmlEntities);
      final text = doc.textContent;
      expect(text, contains('🚀'));
      expect(text, contains('→'));
    });

    test('HTML entities: CJK characters preserved', () {
      final doc = adapter.parse(_htmlEntities);
      final text = doc.textContent;
      expect(text, contains('こんにちは'));
      expect(text, contains('你好世界'));
      expect(text, contains('안녕하세요'));
    });

    test('img parsed as AtomicNode', () {
      final doc = adapter.parse(_newsArticle);
      bool foundImg = false;
      void walk(UDTNode node) {
        if (node is AtomicNode && node.tagName == 'img') foundImg = true;
        for (final c in node.children) {
          walk(c);
        }
      }
      walk(doc);
      expect(foundImg, isTrue);
    });

    test('table parsed as TableNode', () {
      final doc = adapter.parse(_documentation);
      bool foundTable = false;
      void walk(UDTNode node) {
        if (node is TableNode) foundTable = true;
        for (final c in node.children) {
          walk(c);
        }
      }
      walk(doc);
      expect(foundTable, isTrue);
    });
  });
}
