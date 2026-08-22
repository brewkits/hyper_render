# Dev.to & Medium Technical Story

**Title:** How We Built a Custom RenderObject HTML & Markdown Engine for Flutter (And Why Widget Trees Fail at Scale)

**Tags:** `#flutter`, `#dart`, `#mobiledev`, `#performance`

---

## The Illusion of the Widget Tree

Flutter's declarative widget tree is the reason why millions of developers fell in love with it. Composing simple bricks into complex UIs is effortless.

Until you try to render rich text from the web.

When a backend returns an article with nested `<div>`, `<blockquote>`, `<table>`, `<img>`, and `<p>` tags, traditional Flutter rendering libraries map every single DOM element into a Flutter widget:
- A simple Wikipedia article easily generates **500 to 1,000 Flutter widgets**.
- Selecting text across multiple paragraphs requires complex synchronisation between disjointed `SelectableText` controllers.
- CSS properties like `float: left` or `shape-outside` become mathematically impossible because children cannot negotiate line-by-line bounding geometry with siblings across widget boundaries.

In this article, we'll dive into the internals of **HyperRender** — how building a custom `RenderObject` from scratch solved CSS float, reduced RAM consumption by 70%, and enabled crash-free text selection across 100,000+ character documents.

---

## Core Architectural Pillars

### 1. The Unified Document Tree (UDT)
Instead of converting HTML directly into Flutter widgets, HyperRender first parses input (HTML, CommonMark, or Quill Delta) into an intermediate **UDT**. 

This abstraction separates document semantics from layout calculation, allowing CSS rules to cascade with full specificity calculation (tags, classes, IDs, inline styles, CSS variables `var()`).

### 2. Fragment-Based Line Breaking & Float Carryover
In standard Flutter rendering, `TextPainter` computes lines with a fixed width constraint.

In `HyperRender`:
1. When a floated replaced element (like `<img style="float:left">`) is encountered, its bounding box is recorded into a active float registry.
2. Subsequent text lines calculate available horizontal width by subtracting the active float rectangle at the current Y-offset.
3. If an image spans multiple lines, the float carryover state seamlessly propagates until the float clears.

### 3. Zero-Allocation Paint Loops
In mobile rendering at 60 FPS (16.6ms per frame) or 120 FPS (8.3ms per frame), garbage collection pauses are the #1 cause of jank.

`HyperRender` eliminates per-frame allocations in the render loop:
- Reusable library-level `Paint` instances for background, borders, skeletons, and error frames.
- Pre-compiled CSS whitespace regexes avoiding dynamic DFA re-allocations.
- LRU TextPainter cache that dynamically bounds memory footprint and purges on system low-memory signals.

---

## Benchmarks & Results

| Metric | Traditional Widget-Based Libraries | HyperRender (Custom RenderObject) |
| :--- | :---: | :---: |
| **Widget Allocations** | ~600 widgets | **3–5 chunk widgets** |
| **Initial Layout Time** | 420 ms | **95 ms** |
| **Peak Memory (RAM)** | 28 MB | **8 MB** |
| **Text Selection Stability** | Prone to Boundary Crashes | **Crash-Free up to 100K+ chars** |
| **CSS Float Support** | ❌ None | **✅ Full Float Left / Right** |

---

## Live Playground & Getting Started

You can test HyperRender live in your browser without setting up any Flutter project:
- 🌐 **Live Web Playground:** [https://brewkits.github.io/hyper_render/](https://brewkits.github.io/hyper_render/)
- 📦 **Pub.dev Package:** [https://pub.dev/packages/hyper_render](https://pub.dev/packages/hyper_render)
- 💻 **GitHub Repository:** [https://github.com/brewkits/hyper_render](https://github.com/brewkits/hyper_render)
