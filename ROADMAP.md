# HyperRender Roadmap

## v2.0 Roadmap (Planned)

### 1. Z-Buffer Rendering (z-index / z-overlay Support)
- **Goal**: Support CSS `z-index` and `position: fixed/absolute`.
- **Implementation**: Rewrite `paint()` of `RenderHyperBox` to support out-of-order painting (Stacking Context Buckets) instead of strict DOM-order traversal.

### 2. WASM / CanvasKit Optimization
- **Goal**: Drastically improve FPS on Flutter Web (WASM).
- **Implementation**: Introduce Line-Level Batching by grouping contiguous text fragments on the same line into a single `dart:ui.ParagraphBuilder` call (`drawParagraph`) instead of calling `TextPainter.paint()` for every individual fragment.
- **Trade-off**: Requires splitting the paint phase into `paintBackgrounds()` followed by `paintBatchedText()`.

### 3. CJK Inter-character Justification
- **Goal**: Perfectly justify Chinese, Japanese, and Korean text.
- **Implementation**: Update `_applyJustify` to detect CJK text and distribute free space via `letterSpacing` (between every character) rather than `word-spacing` (ASCII spaces).
- **Trade-off**: Requires tuning to ensure it does not break Kinsoku line-breaking rules.

### 4. Extended CSS Properties
- **Goal**: Expand CSS Grid and Flexbox property parsing within `hyper_render_core`.
