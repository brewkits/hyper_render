// ignore_for_file: unused_import

/// HyperRender example.
///
/// For a full interactive demo, see [example/lib/main.dart].
///
/// Quick usage:
/// ```dart
/// import 'package:hyper_render/hyper_render.dart';
///
/// HyperViewer(
///   html: '<h1>Hello</h1><p>World</p>',
///   onLinkTap: (url) => print(url),
/// )
/// ```
library hyper_render_example;

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  runApp(const HyperRenderExampleApp());
}

class HyperRenderExampleApp extends StatelessWidget {
  const HyperRenderExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'HyperRender Example',
      home: HyperRenderDemo(),
    );
  }
}

class HyperRenderDemo extends StatelessWidget {
  const HyperRenderDemo({super.key});

  static const _html = '''
<article>
  <h1>HyperRender Demo</h1>

  <p>A <strong>single RenderObject</strong> renders this entire document —
  no widget tree explosion, 60 FPS scroll performance.</p>

  <h2>CSS Float (unique to HyperRender)</h2>
  <p>
    <img src="https://picsum.photos/120/90"
         style="float: left; margin: 0 12px 8px 0; border-radius: 6px;" />
    Text wraps around the floated image exactly like a browser.
    No other Flutter HTML library supports this — it requires a unified
    coordinate system that only a single RenderObject can provide.
  </p>
  <p style="clear: both;"></p>

  <h2>Ruby / Furigana</h2>
  <p style="font-size: 20px; line-height: 2.2;">
    <ruby>東京<rt>とうきょう</rt></ruby>の
    <ruby>桜<rt>さくら</rt></ruby>は
    <ruby>美<rt>うつく</rt></ruby>しい。
  </p>

  <h2>CSS Grid</h2>
  <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px;">
    <div style="background: #E3F2FD; padding: 12px; border-radius: 6px;">Column 1</div>
    <div style="background: #F3E5F5; padding: 12px; border-radius: 6px;">Column 2</div>
    <div style="background: #E8F5E9; padding: 12px; border-radius: 6px;">Column 3</div>
  </div>

  <h2>Syntax Highlighting</h2>
  <pre><code class="language-dart">HyperViewer(
  html: articleHtml,
  selectable: true,
  onLinkTap: (url) =&gt; launchUrl(Uri.parse(url)),
)</code></pre>
</article>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HyperRender')),
      body: HyperViewer(
        html: _html,
        selectable: true,
      ),
    );
  }
}
