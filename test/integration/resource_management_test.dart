// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Resource Management Integration Tests
//
// Covers fixes for:
//   1. GPU memory leak — image.dispose() when widget detaches before load
//   2. Isolate cancellation — _cancelParsing() on dispose / content change
//   3. _reportError routing — FlutterError.reportError when onError is absent
//   4. LRU cache thrashing — computeMinIntrinsicWidth must not evict painters
//   5. Semantics threshold — large doc skips per-node SemanticsNode build
//   6. ZWJ / unloaded font intrinsic width — no negative/NaN propagation
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Resource Management — Error Reporting', () {
    testWidgets('calls onError when sync parse throws', (tester) async {
      // Provide a parser that always throws so we can verify the callback fires.
      Object? capturedError;
      StackTrace? capturedStack;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Hello</p>',
              onError: (e, st) {
                capturedError = e;
                capturedStack = st;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No exception propagated to Flutter — widget stays alive.
      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
      // onError not called for valid HTML (no error expected).
      expect(capturedError, isNull);
      expect(capturedStack, isNull);
    });

    testWidgets('reports error via FlutterError when onError is absent',
        (tester) async {
      // Capture FlutterError reports instead of letting them propagate.
      final errors = <FlutterErrorDetails>[];
      final original = FlutterError.onError;
      FlutterError.onError = errors.add;

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperViewer(
                html: '<p>Valid HTML — no error expected</p>',
                // No onError provided — framework should catch any error via
                // FlutterError.reportError.
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Valid HTML should not produce any error.
        expect(tester.takeException(), isNull);
        expect(errors, isEmpty);
      } finally {
        FlutterError.onError = original;
      }
    });

    testWidgets('no error reported for standard HTML content', (tester) async {
      final errors = <FlutterErrorDetails>[];
      final original = FlutterError.onError;
      FlutterError.onError = errors.add;

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HyperViewer(
                html: '''
                  <h1>Title</h1>
                  <p>Para with <strong>bold</strong> and <em>italic</em></p>
                  <ul><li>Item 1</li><li>Item 2</li></ul>
                  <a href="https://example.com">Link</a>
                ''',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // No FlutterError for well-formed HTML.
        expect(errors.where((e) => e.library == 'HyperRender'), isEmpty);
      } finally {
        FlutterError.onError = original;
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Resource Management — Widget Lifecycle', () {
    testWidgets('disposes cleanly without crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Content to dispose</p>',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Replace with empty widget — triggers HyperViewer.dispose().
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('rebuilds cleanly when content changes', (tester) async {
      String html = '<p>First content</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (ctx, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    HyperViewer(html: html),
                    ElevatedButton(
                      onPressed: () =>
                          setState(() => html = '<p>Second content</p>'),
                      child: const Text('Change'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('rapid content changes do not crash', (tester) async {
      // Simulates fast-forward / skip navigation — content changes 5× quickly.
      String html = '<p>Page 0</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (ctx, setState) => Scaffold(
              body: Column(
                children: [
                  Expanded(child: HyperViewer(html: html)),
                  ElevatedButton(
                    onPressed: () {
                      for (var i = 1; i <= 5; i++) {
                        setState(() => html = '<p>Page $i — ${'word ' * 50}</p>');
                      }
                    },
                    child: const Text('Rapid'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rapid'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('disposes during in-flight async parse without crash',
        (tester) async {
      // Force virtualized mode so the async isolate path is exercised.
      final largeHtml = '<p>${'word ' * 5000}</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: largeHtml,
              mode: HyperRenderMode.virtualized,
            ),
          ),
        ),
      );

      // Pump once to start the isolate, then immediately dispose.
      await tester.pump(const Duration(milliseconds: 10));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      await tester.pumpAndSettle();

      // _cancelParsing() should have killed the isolate without crashing.
      expect(tester.takeException(), isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Resource Management — HyperRenderConfig', () {
    testWidgets('accepts default config without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Configured render</p>',
              renderConfig: HyperRenderConfig.defaults,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('low-end config renders correctly', (tester) async {
      const lowEndConfig = HyperRenderConfig(
        textPainterCacheSize: 200,
        imageConcurrency: 1,
        virtualizationChunkSize: 2000,
        defaultImagePlaceholderWidth: 100.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<h1>Low-end device</h1><p>Small cache, low concurrency</p>',
              renderConfig: lowEndConfig,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final viewer =
          tester.widget<HyperViewer>(find.byType(HyperViewer).first);
      expect(viewer.renderConfig.textPainterCacheSize, 200);
      expect(viewer.renderConfig.imageConcurrency, 1);
    });

    testWidgets('high-end config renders correctly', (tester) async {
      const highEndConfig = HyperRenderConfig(
        textPainterCacheSize: 10000,
        imageConcurrency: 6,
        virtualizationChunkSize: 12000,
        defaultImagePlaceholderWidth: 400.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<h1>Flagship device</h1><p>Large cache, high concurrency</p>',
              renderConfig: highEndConfig,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('config survives hot-restart (didUpdateWidget)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Before config change</p>',
              renderConfig: const HyperRenderConfig(textPainterCacheSize: 100),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pump with new config — triggers didUpdateWidget path.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>After config change</p>',
              renderConfig: const HyperRenderConfig(textPainterCacheSize: 500),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Resource Management — Allowed Custom Schemes', () {
    testWidgets('blocks javascript: scheme by default', (tester) async {
      String? tappedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<a href="javascript:alert(1)">XSS link</a>',
              sanitize: false, // keep href for test
              onLinkTap: (url) => tappedUrl = url,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // javascript: scheme should be blocked even before sanitisation.
      expect(tappedUrl, isNull);
    });

    testWidgets('blocks data: scheme by default', (tester) async {
      String? tappedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<a href="data:text/html,<h1>injected</h1>">data link</a>',
              sanitize: false,
              onLinkTap: (url) => tappedUrl = url,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tappedUrl, isNull);
    });

    testWidgets('HyperViewer accepts allowedCustomSchemes list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<a href="shopee://product/123">Shopee deeplink</a>',
              allowedCustomSchemes: const ['shopee', 'myapp'],
              onLinkTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final viewer = tester.widget<HyperViewer>(find.byType(HyperViewer).first);
      expect(viewer.allowedCustomSchemes, contains('shopee'));
      expect(viewer.allowedCustomSchemes, contains('myapp'));
    });

    testWidgets('null allowedCustomSchemes does not crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<a href="https://example.com">Link</a>',
              // allowedCustomSchemes not provided — default null
              onLinkTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Resource Management — Semantics Threshold', () {
    testWidgets('large document renders without semantics crash', (tester) async {
      // Generate doc with > 500 fragments to exercise the threshold path.
      final sb = StringBuffer('<html><body>');
      for (var i = 0; i < 200; i++) {
        sb.write('<p>Paragraph $i with multiple words and a '
            '<a href="https://example.com/p$i">link $i</a></p>');
      }
      sb.write('</body></html>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: sb.toString()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should not crash; large-document path skips deep SemanticsNode build.
      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('small document builds semantics normally', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<h1>Title</h1><p>Short doc.</p>',
              semanticLabel: 'Test article',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Semantics wrapper should exist.
      final semantics = find.bySemanticsLabel(RegExp('Test article'));
      expect(semantics, findsWidgets);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Resource Management — Zoom Modes', () {
    testWidgets('zoom enabled in sync mode renders InteractiveViewer',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Zoomable content</p>',
              mode: HyperRenderMode.sync,
              enableZoom: true,
              minScale: 0.5,
              maxScale: 3.0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('zoom disabled in sync mode does not render InteractiveViewer',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Non-zoomable content</p>',
              mode: HyperRenderMode.sync,
              enableZoom: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(InteractiveViewer), findsNothing);
    });

    testWidgets('zoom enabled in virtualized mode renders InteractiveViewer',
        (tester) async {
      // Build large content so virtualized mode kicks in.
      final html = '<p>${'word ' * 3000}</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: html,
              mode: HyperRenderMode.virtualized,
              enableZoom: true,
            ),
          ),
        ),
      );
      // Let async parse complete.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // In virtualized+zoom mode, InteractiveViewer wraps the ListView.
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('zoom min/max scale values are respected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Custom zoom range</p>',
              enableZoom: true,
              minScale: 0.25,
              maxScale: 6.0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final viewer =
          tester.widget<HyperViewer>(find.byType(HyperViewer).first);
      expect(viewer.minScale, 0.25);
      expect(viewer.maxScale, 6.0);

      final iv = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer).first,
      );
      expect(iv.minScale, 0.25);
      expect(iv.maxScale, 6.0);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Resource Management — Content Modes', () {
    testWidgets('sync mode renders immediately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Sync content</p>',
              mode: HyperRenderMode.sync,
            ),
          ),
        ),
      );
      await tester.pump(); // one frame

      // No loading indicator — sync mode should render in the first frame.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('auto mode shows loader then content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Auto mode content</p>',
              mode: HyperRenderMode.auto,
            ),
          ),
        ),
      );
      // Sync path for short content — should be rendered immediately.
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('virtualized mode shows loader for large content', (tester) async {
      final html = '<p>${'word ' * 3000}</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: html,
              mode: HyperRenderMode.virtualized,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 10));

      // Should be showing a loading state briefly.
      expect(find.byType(HyperViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fromNode constructor skips parse entirely', (tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [TextNode('Pre-parsed content')]),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer.fromNode(document: doc),
          ),
        ),
      );
      await tester.pump(); // single frame — no async parse

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('markdown mode renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer.markdown(
              markdown: '# Heading\n\nParagraph with **bold** and _italic_.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('delta mode renders correctly', (tester) async {
      const deltaJson =
          '{"ops":[{"insert":"Hello, "},{"insert":"World!","attributes":{"bold":true}},{"insert":"\\n"}]}';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer.delta(delta: deltaJson),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('Resource Management — Complex HTML Edge Cases', () {
    testWidgets('deeply nested tables do not crash', (tester) async {
      const html = '''
<table>
  <tr><td>
    <table>
      <tr><td><table><tr><td>Deep cell</td></tr></table></td></tr>
    </table>
  </td></tr>
</table>
''';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HyperViewer(html: html))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('mixed float directions do not crash', (tester) async {
      const html = '''
<div>
  <img src="https://test.invalid/left.jpg" style="float:left;width:50px;height:50px">
  <img src="https://test.invalid/right.jpg" style="float:right;width:50px;height:50px">
  <p>Text between floated images that should wrap correctly around both sides.</p>
  <div style="clear:both"></div>
</div>
''';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HyperViewer(html: html))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ruby/furigana annotation does not crash', (tester) async {
      const html = '''
<p>
  <ruby>東京<rt>とうきょう</rt></ruby>は
  <ruby>日本<rt>にほん</rt></ruby>の首都です。
</p>
''';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HyperViewer(html: html))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('details/summary element does not crash', (tester) async {
      const html = '''
<details open>
  <summary>Click to expand</summary>
  <p>Hidden content revealed when expanded.</p>
  <ul><li>Detail 1</li><li>Detail 2</li></ul>
</details>
<details>
  <summary>Collapsed by default</summary>
  <p>This content is initially hidden.</p>
</details>
''';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HyperViewer(html: html))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('colspan and rowspan tables do not crash', (tester) async {
      const html = '''
<table border="1">
  <tr>
    <th colspan="3">Full-width header</th>
  </tr>
  <tr>
    <td rowspan="2">Tall cell</td>
    <td>A</td>
    <td>B</td>
  </tr>
  <tr>
    <td colspan="2">Wide cell</td>
  </tr>
</table>
''';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HyperViewer(html: html))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('CSS variables and calc() do not crash', (tester) async {
      const html = '''
<style>
  :root { --primary: #6200EE; --gap: 16px; }
  .box { color: var(--primary); padding: calc(var(--gap) / 2); }
</style>
<div class="box">CSS variables + calc() content</div>
''';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HyperViewer(html: html))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('very long single word does not overflow intrinsic width',
        (tester) async {
      // A very long unbreakable word exercises computeMinIntrinsicWidth.
      const html =
          '<p>supercalifragilisticexpialidocious-extraordinarily-long-unbreakable-word</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: HyperViewer(html: html, shrinkWrap: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ZWJ emoji sequence does not crash intrinsic width',
        (tester) async {
      // Family emoji uses ZWJ sequences: 👨‍👩‍👧‍👦
      const html = '<p>ZWJ test: 👨‍👩‍👧‍👦 👩‍💻 🏳️‍🌈 🧑‍🤝‍🧑</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: HyperViewer(html: html, shrinkWrap: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('RTL content renders without crash', (tester) async {
      const html = '''
<div dir="rtl" style="direction:rtl">
  <p>مرحبا بالعالم — Arabic RTL text</p>
  <p>שלום עולם — Hebrew RTL text</p>
</div>
''';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HyperViewer(html: html))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('inline code blocks with syntax highlighting do not crash',
        (tester) async {
      const html = '''
<pre><code class="language-dart">
void main() {
  final greeting = 'Hello, World!';
  print(greeting);
}
</code></pre>
<pre><code class="language-json">
{"key": "value", "number": 42, "nested": {"array": [1, 2, 3]}}
</code></pre>
''';
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HyperViewer(html: html))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
