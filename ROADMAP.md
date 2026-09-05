# HyperRender Strategic Product Roadmap

This document outlines the architectural roadmap for **HyperRender** to become the undisputed, de facto content rendering engine for Flutter.

---

## 🗺️ Milestone Overview

| Version | Target Date | Strategic Focus | Key Differentiators |
| :--- | :--- | :--- | :--- |
| **v1.7.0** | Current | **Production Hardening & Drop-in Migration** | Single RenderObject, 100% WASM support, 160/160 pub score, 30s `flutter_html` drop-in layer. |
| **v1.8.0** | Q3 2026 | **AI & LLM Token-Streaming Engine** | Frame-throttled token updates with adaptive backoff, transient syntax auto-repair, auto-scroll locking. Tail-only layout invalidation remains a separate, unscheduled epic — see below. |
| **v1.9.0** | Q4 2026 | **Native Vector Diagramming & Headless Export** | Pure Canvas/Vector Mermaid.js & GraphViz (Zero-WebView), Headless Image & PDF byte stream generator. |
| **v2.0.0** | Q1 2027 | **Interactive Editorial & Magazine Typography** | Medium-style Text Annotation/Highlighting layer, Multi-column layout (`column-count`), Z-Index Stacking Context, Vertical Text (`writing-mode: vertical-rl`). |

---

## 🚀 v1.8.0: AI / LLM Streaming Engine

**Shipped** (`HyperStreamingController`, `HyperViewer.streaming(...)`, `StreamSyntaxNormalizer`, `HyperTypingCaret` — see CHANGELOG 1.8.0): frame-throttled token append with **adaptive backoff** (the notification interval widens as the accumulated buffer grows past 10,000 / 50,000 chars, up to `maxThrottleDuration`), transient syntax auto-repair for Markdown/HTML, stick-to-bottom auto-scroll, typing caret. This bounds the total cost of re-parsing over the life of a long stream and is what "Zero-Jank" in this doc's earlier drafts actually refers to.

**Not shipped — the paragraph below was aspirational and did not match what got built; corrected after a production-readiness review found the mismatch:**

### 1. Incremental Delta-Append Engine (tail-only layout) — still unimplemented, own epic
- **Problem**: re-parsing and re-laying-out the *entire* accumulated document on every streaming tick, rather than only the appended tail, means total work over a stream's lifetime scales with the square of its final length. The adaptive-backoff mitigation above bounds *how often* this happens as the buffer grows, but each tick still does a full document reparse + full `RenderHyperBox` layout pass — it does not make any single tick cheaper.
- **Why it's not a small patch**: a feasibility review of `packages/hyper_render_core/lib/src/core/render_hyper_box*.dart` found this needs four largely independent subsystems, most of them outside the renderer: (a) a parser able to resume from a character offset instead of re-tokenizing from scratch, (b) a UDT model change — `TextNode.text` is currently immutable and nodes have no identity that survives across two parses, so there is no way to "find and extend the last text node" today, (c) a fragment list that supports appending instead of the current full-rebuild-every-layout design, (d) a persisted line-layout checkpoint (cursor position, in-progress float lists) that `_performLineLayout` can resume from instead of always resetting to empty. `RenderHyperBox`'s 7-file `part` architecture (shared private state across files, no interface boundary — see the Architecture section above) makes this riskier than in a normally-composed class, since nothing stops a part file from silently assuming layout is always complete and freshly computed. Some CSS behavior (`text-align: justify`, float carryover, `text-overflow: ellipsis`) is also not strictly tail-local, so "only touch the appended tail" needs a correctness argument per feature, not just an engine change.
- **Status**: deliberately deferred as a separate, scoped effort (own design + plan, own risk review) rather than folded into a bug-fix/hardening pass on a renderer every consumer of this library depends on — not just streaming users.

### 2. Live KaTeX & Syntax Highlighting in Streaming Mode — verified non-issue, not scheduled
- **Original concern**: incomplete code fences / math delimiters mid-stream could flash unstyled or broken content, or crash the highlighter/KaTeX renderer.
- **Investigated and closed**: `HyperViewer.streaming()` already exposes both `codeHighlighter` and `pluginRegistry`, so both are reachable during live streaming. `flutter_highlight`'s lexer is best-effort (not a strict parser) and doesn't throw on incomplete/malformed code — covered by `code_highlighter_edge_cases_test.dart`. `flutter_math_fork`'s `Math.tex(..., onErrorFallback: ...)` wraps both its parse and build stages in a catch-all, so a delimiter-balanced-but-internally-malformed LaTeX fragment (which `StreamSyntaxNormalizer` intentionally does not try to brace-balance) safely falls through to the red-text fallback instead of crashing. No incremental tokenizer state is needed; regression tests were added to lock this behavior in (see CHANGELOG).

---

## 📊 v1.9.0: Native Vector Diagramming & Headless Export (WebView Replacement)

### 1. Native Mermaid.js & GraphViz Vector Engine (Zero-WebView)
- **Problem**: Technical docs, GitHub clients, and EdTech apps embed WebViews solely for Mermaid diagrams, adding 50MB+ RAM overhead per instance with poor gesture response.
- **Solution**:
  - Direct translation of Mermaid syntax (`flowchart`, `sequenceDiagram`, `classDiagram`, `stateDiagram`) into native Flutter `Path`, `Canvas`, and `TextPainter` draw calls.
  - Zero JavaScript engine, Zero WebView, Zero network latency.
  - Built-in interactive Canvas: smooth 120 FPS pan, pinch-to-zoom, and tap-to-inspect nodes.

### 2. Headless Offline Canvas & PDF Generator
- **Problem**: Generating social share quote cards, receipt images, or exporting articles to PDF previously required hacky off-screen widget tree mounting (`RepaintBoundary`).
- **Solution**:
  - Headless document layout directly in memory without mounting widgets.
  - Export directly to `ui.Image`, PNG byte arrays, or standard PDF document streams.
  ```dart
  final Uint8List pngBytes = await HyperRender.renderToImage(
    html: articleHtml,
    width: 1080,
    pixelRatio: 2.0,
  );
  ```

---

## ✍️ v2.0.0: Interactive Editorial & Enterprise Suite

### 1. Medium-Style Text Annotation & Highlighting Layer
- **Goal**: Enable full e-reading, document study, and collaboration workflows.
- **Implementation**:
  - Expose exact character-range bounding boxes from `render_hyper_box_selection.dart`.
  - Draw custom highlight colors, squiggles, underlines, and anchored comment badges.
  - Import/Export annotations as standardized JSON schemas.
  ```dart
  HyperViewer(
    html: content,
    annotations: [
      TextAnnotation(range: CharRange(120, 250), color: Colors.amberAccent, note: "Key takeaway"),
    ],
    onAnnotationTap: (annotation) => openCommentSheet(annotation),
  )
  ```

### 2. Multi-Column Magazine Layout (`column-count`, `column-gap`)
- Automatic multi-column flow for tablets, foldables, and desktop screens.
- Balancing column heights using binary-search break heights.

### 3. Z-Index & Out-of-Order Stacking Contexts
- Rewrite `paint()` in `RenderHyperBox` with stacking context buckets to support `position: absolute / fixed` and `z-index` overlays.

### 4. Advanced CJK & Traditional Typography
- **Vertical Writing Mode**: Support `writing-mode: vertical-rl` (Tate-chu-yoko) for Japanese, Chinese, and Korean literature.
- **CJK Letter-Spacing Justification**: Free space distribution across individual ideographic glyphs without disrupting Kinsoku line-breaking.

---

## 📈 Quality & Performance Guardrails
- **Test Coverage**: Maintain >= 70% branch coverage and 100% pass rate on all CI suites (>1,200 tests).
- **Pub Score**: Guarantee 160/160 points on every release.
- **Zero Allocations in Paint Loop**: Strict enforcement of pre-allocated static/cached `Paint` objects and reusable path buffers.
