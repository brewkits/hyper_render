/// Golden tests for critical HyperRender layouts.
///
/// Run once to generate reference images:
///   flutter test test/golden/critical_layouts_test.dart --update-goldens
///
/// Then run normally to compare:
///   flutter test test/golden/critical_layouts_test.dart
///
/// Excluded from normal CI runs via: --exclude-tags golden
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Parse HTML → DocumentNode with styles resolved.
DocumentNode _parse(String html) {
  final doc = HtmlAdapter().parse(html);
  StyleResolver().resolveStyles(doc);
  return doc;
}

/// Pump a fixed-width widget for pixel-stable golden comparison.
///
/// - 400 px wide — wide enough for most layouts, narrow enough for lists.
/// - White background so transparency artefacts are visible.
/// - textScaler 1.0 and no system font scaling.
/// Key used to locate the golden capture target.
final _goldenKey = GlobalKey();

Future<void> _pump(WidgetTester tester, String html) async {
  final doc = _parse(html);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        fontFamily: 'Roboto',
      ),
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          devicePixelRatio: 1.0,
          textScaler: TextScaler.noScaling,
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                key: _goldenKey,
                width: 368, // 400 - 2*16 padding
                child: HyperRenderWidget(
                  document: doc,
                  baseStyle: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  // Multiple pumps: layout pass → child widget positioning → paint.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 100));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Golden — Headings', () {
    testWidgets('h1 through h6', (tester) async {
      await _pump(tester, '''
        <h1>Heading 1</h1>
        <h2>Heading 2</h2>
        <h3>Heading 3</h3>
        <h4>Heading 4</h4>
        <h5>Heading 5</h5>
        <h6>Heading 6</h6>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/headings.png'),
      );
    });
  });

  group('Golden — Text formatting', () {
    testWidgets('bold italic underline strikethrough code', (tester) async {
      await _pump(tester, '''
        <p>Plain text baseline.</p>
        <p><strong>Bold text</strong> and <em>italic text</em> in one paragraph.</p>
        <p><u>Underlined</u> and <s>strikethrough</s> and <del>deleted</del>.</p>
        <p>Inline <code>code snippet</code> inside paragraph.</p>
        <p><strong><em>Bold italic combined</em></strong> and
           <strong><em><u>all three</u></em></strong>.</p>
        <p><mark>Highlighted text</mark> and <small>small text</small>.</p>
        <p>Superscript: x<sup>2</sup> + y<sup>2</sup>. Subscript: H<sub>2</sub>O.</p>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/text_formatting.png'),
      );
    });
  });

  group('Golden — Lists', () {
    testWidgets('unordered list with nesting', (tester) async {
      await _pump(tester, '''
        <ul>
          <li>Apples</li>
          <li>Bananas
            <ul>
              <li>Cavendish</li>
              <li>Plantain</li>
            </ul>
          </li>
          <li>Cherries
            <ul>
              <li>Sweet cherry
                <ul>
                  <li>Bing</li>
                  <li>Rainier</li>
                </ul>
              </li>
              <li>Sour cherry</li>
            </ul>
          </li>
        </ul>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/unordered_list.png'),
      );
    });

    testWidgets('ordered list with nesting', (tester) async {
      await _pump(tester, '''
        <ol>
          <li>First item</li>
          <li>Second item
            <ol>
              <li>Sub-item A</li>
              <li>Sub-item B</li>
              <li>Sub-item C</li>
            </ol>
          </li>
          <li>Third item</li>
          <li>Fourth item</li>
        </ol>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/ordered_list.png'),
      );
    });

    testWidgets('mixed list types', (tester) async {
      await _pump(tester, '''
        <p>Shopping list:</p>
        <ul>
          <li>Groceries
            <ol>
              <li>Milk</li>
              <li>Bread</li>
            </ol>
          </li>
          <li>Electronics
            <ul>
              <li>USB cable</li>
              <li>Charger</li>
            </ul>
          </li>
        </ul>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/mixed_lists.png'),
      );
    });
  });

  group('Golden — Blockquote', () {
    testWidgets('single and nested blockquote', (tester) async {
      await _pump(tester, '''
        <blockquote>
          <p>The only way to do great work is to love what you do.</p>
          <p>— Steve Jobs</p>
        </blockquote>
        <p>Normal paragraph after quote.</p>
        <blockquote>
          <p>Outer quote text.</p>
          <blockquote>
            <p>Nested inner quote.</p>
          </blockquote>
        </blockquote>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/blockquote.png'),
      );
    });
  });

  group('Golden — Code', () {
    testWidgets('inline code and code block', (tester) async {
      await _pump(tester, '''
        <p>Use <code>print()</code> to debug.</p>
        <pre><code>void main() {
  print('Hello, World!');
  final x = 42;
  return;
}</code></pre>
        <p>Multi-language example:</p>
        <pre><code class="language-dart">class Foo {
  final String name;
  Foo(this.name);
}</code></pre>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/code_block.png'),
      );
    });
  });

  group('Golden — Table', () {
    testWidgets('table with header row', (tester) async {
      await _pump(tester, '''
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Role</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Alice</td>
              <td>Engineer</td>
              <td>Active</td>
            </tr>
            <tr>
              <td>Bob</td>
              <td>Designer</td>
              <td>Active</td>
            </tr>
            <tr>
              <td>Carol</td>
              <td>Manager</td>
              <td>On leave</td>
            </tr>
          </tbody>
        </table>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/table.png'),
      );
    });

    testWidgets('table with colspan and rowspan', (tester) async {
      await _pump(tester, '''
        <table>
          <thead>
            <tr>
              <th colspan="2">Combined header</th>
              <th>Single</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td rowspan="2">Merged</td>
              <td>A</td>
              <td>B</td>
            </tr>
            <tr>
              <td>C</td>
              <td>D</td>
            </tr>
          </tbody>
        </table>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/table_spans.png'),
      );
    });
  });

  group('Golden — Links', () {
    testWidgets('anchor tags', (tester) async {
      await _pump(tester, '''
        <p>Visit <a href="https://flutter.dev">Flutter website</a> for docs.</p>
        <p>Email us at <a href="mailto:hello@example.com">hello@example.com</a>.</p>
        <p>
          <a href="https://dart.dev">Dart</a> ·
          <a href="https://pub.dev">Pub</a> ·
          <a href="https://github.com">GitHub</a>
        </p>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/links.png'),
      );
    });
  });

  group('Golden — Mixed inline styles', () {
    testWidgets('complex paragraph with many inline elements', (tester) async {
      await _pump(tester, '''
        <p>
          This paragraph contains <strong>bold</strong>,
          <em>italic</em>, <code>inline code</code>,
          <a href="#">a link</a>, <mark>highlighted text</mark>,
          <u>underline</u>, and <s>strikethrough</s> all together.
        </p>
        <p>
          <strong>Bold with <em>nested italic</em> inside</strong> and
          back to <em>italic with <strong>bold</strong> nested</em>.
        </p>
        <p>
          Text wraps naturally across multiple lines when the content is
          long enough to require it — this tests the line-breaking and
          inline-fragment layout logic at the core of the renderer.
        </p>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/mixed_inline.png'),
      );
    });
  });

  group('Golden — Image placeholder', () {
    testWidgets('image with broken URL shows placeholder', (tester) async {
      await _pump(tester, '''
        <p>Image below (will show placeholder in test environment):</p>
        <img src="https://invalid.example.test/image.png"
             alt="A test image"
             width="200" height="120">
        <p>Text after the image.</p>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/image_placeholder.png'),
      );
    });
  });

  group('Golden — Definition list', () {
    testWidgets('dl dt dd elements', (tester) async {
      await _pump(tester, '''
        <dl>
          <dt>Flutter</dt>
          <dd>UI toolkit for building natively compiled apps.</dd>
          <dt>Dart</dt>
          <dd>Client-optimised language for fast apps on any platform.</dd>
          <dt>HyperRender</dt>
          <dd>High-performance HTML renderer for Flutter.</dd>
        </dl>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/definition_list.png'),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Float + RTL + CJK — the "fragile triangle" that must stay green
  // ─────────────────────────────────────────────────────────────────────────

  group('Golden — Float layout', () {
    testWidgets('left float with text wrap', (tester) async {
      await _pump(tester, '''
        <div style="overflow:hidden">
          <img src="https://invalid.example.test/cover.jpg"
               style="float:left; width:100px; height:120px; margin-right:12px"
               alt="float left">
          <p>Text wraps around a left-floated image. The inline layout engine
          must reserve the float inset for each line that overlaps the image
          vertically, then resume full-width once the float is cleared.</p>
        </div>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/float_left.png'),
      );
    });

    testWidgets('right float with text wrap', (tester) async {
      await _pump(tester, '''
        <div style="overflow:hidden">
          <img src="https://invalid.example.test/cover.jpg"
               style="float:right; width:100px; height:80px; margin-left:12px"
               alt="float right">
          <p>Text wraps around a right-floated image. Lines must be inset from
          the right edge while the float occupies vertical space, then use the
          full available width below it.</p>
        </div>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/float_right.png'),
      );
    });

    testWidgets('float with clear', (tester) async {
      await _pump(tester, '''
        <div style="overflow:hidden">
          <img src="https://invalid.example.test/a.jpg"
               style="float:left; width:80px; height:60px; margin-right:8px"
               alt="float">
          <p>Short text beside float.</p>
          <p style="clear:both">This paragraph has clear:both so it starts
          below the floated element, not beside it.</p>
        </div>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/float_clear.png'),
      );
    });
  });

  group('Golden — RTL / BiDi', () {
    testWidgets('Arabic paragraph (direction:rtl)', (tester) async {
      await _pump(tester, '''
        <p dir="rtl" style="text-align:right">
          هذا نص عربي يُكتب من اليمين إلى اليسار.
          يجب أن يتدفق النص بشكل صحيح.
        </p>
        <p dir="rtl" style="text-align:right">
          <strong>نص عريض</strong> و<em>نص مائل</em> في فقرة واحدة.
        </p>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/rtl_arabic.png'),
      );
    });

    testWidgets('Hebrew paragraph (direction:rtl)', (tester) async {
      await _pump(tester, '''
        <p dir="rtl" style="text-align:right">
          זהו טקסט עברי הנכתב מימין לשמאל.
          המעבד חייב לטפל בו כהלכה.
        </p>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/rtl_hebrew.png'),
      );
    });

    testWidgets('mixed LTR + RTL in same document', (tester) async {
      await _pump(tester, '''
        <p>English LTR paragraph at the top.</p>
        <p dir="rtl" style="text-align:right">
          فقرة عربية في المنتصف.
        </p>
        <p>Another English paragraph below.</p>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/rtl_mixed.png'),
      );
    });
  });

  group('Golden — CJK + Ruby typography', () {
    testWidgets('Japanese ruby (furigana) annotation', (tester) async {
      await _pump(tester, '''
        <p>
          <ruby>東京<rt>とうきょう</rt></ruby>は日本の首都です。
        </p>
        <p>
          <ruby>漢字<rt>かんじ</rt></ruby>の上に
          <ruby>振り仮名<rt>ふりがな</rt></ruby>が付きます。
        </p>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/cjk_ruby.png'),
      );
    });

    testWidgets('CJK line-breaking (kinsoku shori)', (tester) async {
      await _pump(tester, '''
        <p style="font-size:16px">
          日本語のテキストは行末で適切に折り返される必要があります。
          句読点（。、）は行頭に来てはならず、
          括弧の開き（「）は行末に来てはなりません。
        </p>
        <p>
          中文文本也应该在正确的位置换行，标点符号不应该出现在行首。
        </p>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/cjk_kinsoku.png'),
      );
    });

    testWidgets('float + CJK mixed layout', (tester) async {
      await _pump(tester, '''
        <div style="overflow:hidden">
          <img src="https://invalid.example.test/jp.jpg"
               style="float:left; width:80px; height:80px; margin-right:10px"
               alt="float">
          <p>
            <ruby>日本語<rt>にほんご</rt></ruby>のテキストが
            フロートの横に流れます。行分割は正しく処理される必要があります。
          </p>
        </div>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/float_cjk.png'),
      );
    });
  });

  group('Golden — Full article layout', () {
    testWidgets('realistic article with mixed elements', (tester) async {
      await _pump(tester, '''
        <h1>Getting Started</h1>
        <p>
          Welcome to <strong>HyperRender</strong>, a high-performance
          HTML renderer for Flutter applications.
        </p>
        <h2>Installation</h2>
        <p>Add to your <code>pubspec.yaml</code>:</p>
        <pre><code>dependencies:
  hyper_render: ^2.0.0</code></pre>
        <h2>Quick Start</h2>
        <p>Then use it in your widget tree:</p>
        <pre><code>HyperViewer(
  html: '&lt;p&gt;Hello World&lt;/p&gt;',
)</code></pre>
        <h2>Features</h2>
        <ul>
          <li><strong>Fast</strong> — native Flutter rendering</li>
          <li><strong>Safe</strong> — built-in XSS sanitization</li>
          <li><strong>Full CSS</strong> — flexbox, tables, media</li>
        </ul>
        <blockquote>
          <p>Built for production-grade HTML rendering.</p>
        </blockquote>
      ''');
      await expectLater(
        find.byKey(_goldenKey),
        matchesGoldenFile('goldens/full_article.png'),
      );
    });
  });
}
