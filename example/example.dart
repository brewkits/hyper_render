// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperRender Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('HyperRender')),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _HtmlExample(),
              SizedBox(height: 32),
              _MarkdownExample(),
              SizedBox(height: 32),
              _FloatExample(),
              SizedBox(height: 32),
              _SelectionExample(),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Basic HTML rendering
// ---------------------------------------------------------------------------

class _HtmlExample extends StatelessWidget {
  const _HtmlExample();

  @override
  Widget build(BuildContext context) {
    return HyperViewer(
      html: '''
        <h2>Basic HTML</h2>
        <p>HyperRender renders HTML on a single <code>RenderObject</code>,
           not a widget tree. This enables features that are architecturally
           impossible in widget-based renderers.</p>
        <ul>
          <li>CSS float layout</li>
          <li>Continuous text selection</li>
          <li>Ruby / Furigana annotations</li>
          <li>Kinsoku line-breaking for CJK text</li>
        </ul>
      ''',
      onLinkTap: (url) => print('Tapped: $url'),
    );
  }
}

// ---------------------------------------------------------------------------
// Markdown rendering
// ---------------------------------------------------------------------------

class _MarkdownExample extends StatelessWidget {
  const _MarkdownExample();

  @override
  Widget build(BuildContext context) {
    return HyperViewer.markdown(
      markdown: '''
## Markdown support

**Bold**, _italic_, and `inline code` work out of the box.

```dart
HyperViewer.markdown(markdown: '# Hello');
```
      ''',
    );
  }
}

// ---------------------------------------------------------------------------
// CSS Float layout
// ---------------------------------------------------------------------------

class _FloatExample extends StatelessWidget {
  const _FloatExample();

  @override
  Widget build(BuildContext context) {
    return HyperViewer(
      html: '''
        <h2>CSS Float</h2>
        <img src="https://picsum.photos/seed/hyper/120/90"
             style="float: left; margin: 0 12px 8px 0; border-radius: 8px;" />
        <p>Text wraps around the floated image, just like in a browser.
           This is only possible with a unified coordinate system —
           widget-tree renderers cannot implement this.</p>
        <p style="clear: both;"></p>
      ''',
    );
  }
}

// ---------------------------------------------------------------------------
// Text selection with custom menu
// ---------------------------------------------------------------------------

class _SelectionExample extends StatelessWidget {
  const _SelectionExample();

  @override
  Widget build(BuildContext context) {
    return HyperViewer(
      html: '''
        <h2>Text Selection</h2>
        <p>Long-press to start a selection. The selection spans across
           all block elements continuously — no widget-boundary breaks.</p>
        <blockquote>
          <p>Select across this blockquote and the paragraph above
             in a single gesture.</p>
        </blockquote>
      ''',
      selectable: true,
      selectionMenuActionsBuilder: (ctrl) => [
        SelectionMenuAction(
          label: 'Copy',
          onTap: () {
            ctrl.copySelection();
            ctrl.hideMenu();
          },
        ),
      ],
    );
  }
}
