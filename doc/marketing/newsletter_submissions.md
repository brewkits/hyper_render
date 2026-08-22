# Newsletter & Community Submission Templates

Use these pre-formatted snippets to submit HyperRender to weekly newsletters, showcase portals, and developer aggregators.

---

## 1. Flutter Weekly (Submit via: https://flutterweekly.net/submit)

**Title:** HyperRender: High-Performance HTML/Markdown Engine with CSS Float & Crash-Free Selection
**URL:** https://github.com/brewkits/hyper_render
**Category:** Packages / Tools
**Description:**
HyperRender is a high-performance content rendering engine for Flutter built on a single custom `RenderObject` architecture. Unlike widget-mapping HTML renderers, HyperRender natively supports CSS float layouts (`float: left/right`), crash-free multi-block text selection, CJK Ruby/Furigana with Kinsoku line-breaking, CSS `@keyframes` animations, and 60 FPS virtualization on 100K+ character documents. Includes a 30-second drop-in compatibility layer for `flutter_html`.

---

## 2. Flutter Awesome (Submit via: https://flutterawesome.com/submit/)

**Title:** HyperRender — Universal Content Engine with CSS Float & Single RenderObject Architecture
**GitHub URL:** https://github.com/brewkits/hyper_render
**Tags:** `render-engine`, `html`, `markdown`, `rich-text`, `css`, `float-layout`
**Short Summary:**
A next-generation HTML, Markdown, and Delta rendering engine for Flutter. Delivers magazine-quality CSS float layouts, 70% lower RAM consumption, and crash-free text selection across 100,000-character documents.

---

## 3. Hacker News (Show HN)

**Post Title:** Show HN: HyperRender – A custom RenderObject HTML & Markdown engine for Flutter
**URL / Link:** https://github.com/brewkits/hyper_render
**First Comment / Description:**
Hi HN,
We built HyperRender because existing HTML renderers in Flutter map every HTML tag into nested Flutter widgets, which makes CSS float (`float: left | right`) mathematically impossible and leads to memory bloat and selection crashes on long articles.

HyperRender uses an intermediate Unified Document Tree (UDT) and renders everything within a single custom `RenderObject`. This enables true CSS float wrapping, CJK Ruby typography, W3C 2-pass table algorithms, and instant binary-search text selection.

You can try the live interactive web demo here: https://brewkits.github.io/hyper_render/
Looking forward to your feedback and technical critiques!

---

## 4. Twitter / X Thread (1-Click Post)

**Tweet 1:**
🚀 Introducing HyperRender 1.7.0 for #Flutter!
The only Flutter renderer with real CSS float layout (text wraps around images like a browser) + crash-free text selection on 100k+ chars.

⚡ 5x faster parse time
📉 70% less RAM
✨ CJK Ruby & Furigana

Try the Live Web Demo 👇
https://brewkits.github.io/hyper_render/

**Tweet 2:**
Why switch?
Standard packages turn a 3,000-word article into 500+ nested Flutter widgets. HyperRender renders the whole document in ONE custom RenderObject.

Got an existing project? Migration from `flutter_html` takes 1 line of code:
`import 'package:hyper_render/compat/flutter_html.dart';`
