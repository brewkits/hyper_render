# Reddit /r/FlutterDev Ready-to-Post Post

**Title:** Why Flutter’s Widget Tree Breaks CSS Float — And How We Built a Custom Single RenderObject Engine to Fix It

**Flair:** Package / Showcase / Architecture

---

### The Problem Nobody Talks About in Flutter HTML Rendering

If you’ve ever tried rendering real-world HTML or Markdown in Flutter using popular packages like `flutter_html` or `flutter_widget_from_html`, you’ve likely hit a wall:

1. **CSS Float is impossible:** You want an image floated to the left with text wrapping naturally around it (standard magazine layout). Traditional packages either stack them vertically (`Column`) or put them side-by-side (`Row`).
2. **Text selection crashes on long documents:** Selecting text across multiple headings, paragraphs, and table cells frequently triggers `AssertionError` or breaks selection boundaries when each paragraph is its own `SelectableText` widget.
3. **RAM explosion & 30 FPS jank:** A 3,000-word blog post or Wikipedia article turns into **500+ nested Flutter widgets** (`Padding`, `Container`, `RichText`, `Column`), putting massive pressure on the Element and RenderObject trees.

---

### The Architectural Root Cause

In Flutter's standard widget hierarchy, layout occurs in a single top-down pass (`performLayout()` passing `BoxConstraints` down and receiving `Size` back).

To wrap text around a floated image:
- The renderer must know the exact geometry and bounding box of the float fragment *before* line-breaking adjacent inline text fragments.
- When paragraphs and images are isolated into separate `Widget` nodes, they live in disconnected layout contexts. **A parent `Column` cannot negotiate per-line available width with a child `RichText`.**

---

### Our Solution: `HyperRender` (Single Custom RenderObject)

Instead of generating a massive widget tree, **HyperRender parses HTML, Markdown, or Quill Delta into an intermediate Unified Document Tree (UDT)** and feeds it directly into **one single `RenderHyperBox` custom RenderObject**.

```
HTML / Markdown / Delta
          │
          ▼
Unified Document Tree (UDT) ─── CSS Cascade & Style Resolver
          │
          ▼
    RenderHyperBox (Single Custom RenderObject)
    ├── Fragment-based inline line breaking
    ├── CSS Float wrapping (FloatCarryover)
    ├── W3C 2-pass Table Layout Engine
    ├── Kinsoku Shori (CJK line-breaking) & Ruby / Furigana
    ├── Zero-allocation Paint Pass (Reused Paint cache)
    └── Continuous O(log N) Binary-Search Text Selection
```

---

### Benchmark Comparison (25,000-character article on iPhone 13 / Pixel 6)

| Metric | `flutter_html` | `flutter_widget_from_html` | **HyperRender** |
| :--- | :---: | :---: | :---: |
| **Widgets Created** | ~600 | ~500 | **3–5 chunks** |
| **First Parse Time** | 420 ms | 250 ms | **95 ms** |
| **Peak RAM** | 28 MB | 15 MB | **8 MB** |
| **Scroll FPS** | ~35 FPS | ~45 FPS | **60 / 120 FPS** |
| **CSS Float (`float: left/right`)** | ❌ | ❌ | **✅ Full browser support** |
| **Crash-Free Selection** | ❌ Crashes | ❌ Crashes | **✅ Tested to 100K chars** |

---

### 30-Second Drop-in Migration

If you are already using `flutter_html`, you don't need to rewrite anything. Just update your import:

```dart
// Replace: import 'package:flutter_html/flutter_html.dart';
import 'package:hyper_render/compat/flutter_html.dart';

Html(
  data: '<article><img src="cover.jpg" style="float:left; width:150px;"/><p>Wraps smoothly!</p></article>',
  onLinkTap: (url, attributes, element) => launchUrl(Uri.parse(url!)),
)
```

---

### Try the Live Web Demo

You don't need to clone the repo to test your own HTML/Markdown:
👉 **Live Web Playground:** [https://brewkits.github.io/hyper_render/](https://brewkits.github.io/hyper_render/)
📦 **Pub.dev:** [https://pub.dev/packages/hyper_render](https://pub.dev/packages/hyper_render)
⭐ **GitHub:** [https://github.com/brewkits/hyper_render](https://github.com/brewkits/hyper_render)

We would love your honest feedback, edge-case HTML snippets that break other renderers, and feature requests!
