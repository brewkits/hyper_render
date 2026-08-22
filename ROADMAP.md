# HyperRender Strategic Product Roadmap

This document outlines the architectural roadmap for **HyperRender** to become the undisputed, de facto content rendering engine for Flutter.

---

## 🗺️ Milestone Overview

| Version | Target Date | Strategic Focus | Key Differentiators |
| :--- | :--- | :--- | :--- |
| **v1.7.0** | Current | **Production Hardening & Drop-in Migration** | Single RenderObject, 100% WASM support, 160/160 pub score, 30s `flutter_html` drop-in layer. |
| **v1.8.0** | Q3 2026 | **AI & LLM Token-Streaming Engine** | Incremental Delta-Streaming, Zero-Jank token updates, auto-scroll locking, tail-only layout invalidation. |
| **v1.9.0** | Q4 2026 | **Native Vector Diagramming & Headless Export** | Pure Canvas/Vector Mermaid.js & GraphViz (Zero-WebView), Headless Image & PDF byte stream generator. |
| **v2.0.0** | Q1 2027 | **Interactive Editorial & Magazine Typography** | Medium-style Text Annotation/Highlighting layer, Multi-column layout (`column-count`), Z-Index Stacking Context, Vertical Text (`writing-mode: vertical-rl`). |

---

## 🚀 v1.8.0: AI / LLM Streaming Engine (Token-by-Token Zero-Jank)

### 1. Incremental Delta-Append Engine
- **Problem**: Modern LLM chat apps (ChatGPT, Claude, Notion AI) stream Markdown/HTML token-by-token. Re-parsing the full document string every 50ms causes 100% CPU spikes, severe frame drops (jank), memory thrashing, and scroll jump.
- **Solution**: 
  - Token-level append directly to the active UDT leaf node.
  - Partial layout invalidation: only measure and lay out the trailing line fragment (`tailLineLayout`), preserving 100% of cached layout geometry for preceding paragraphs, tables, and code blocks.
  - Smooth Auto-Scroll Anchor: lock viewport to stream tail without jittering scroll physics.
- **API Surface**:
  ```dart
  final streamController = HyperDocumentStreamController();
  
  HyperViewer.stream(
    controller: streamController,
    mode: HyperRenderMode.sync,
  );
  
  // As chunks arrive from LLM:
  streamController.appendToken(" **instant** rendering");
  ```

### 2. Live KaTeX & Syntax Highlighting in Streaming Mode
- Incremental tokenizer state tracking: maintain code-fence (` ``` `) and math-delimiter (`$$`) states across partial chunks to prevent flashing unstyled syntax during streaming.

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
