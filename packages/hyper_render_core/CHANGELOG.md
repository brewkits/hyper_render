# Changelog — hyper_render_core

## [1.3.2] - 2026-05-19

### 🔒 Security

- **`UrlSafety.isSafe` added** (`lib/src/util/url_safety.dart`) — canonical scheme blocklist (`javascript:`, `vbscript:`, `data:image/svg`, non-image `data:`, `file:`, `mhtml:`, `about:`) with control-character smuggling defence. The root `HtmlSanitizer.isSafeUrl` and the markdown sub-package's URL gate now both delegate here so no scheme can drift between adapters.
- **`HyperViewer.markdown(sanitize:true)`** pre-sanitises markdown content via `HtmlSanitizer` so raw `<script>`/`<style>`/`<iframe>` blocks can no longer survive `enableInlineHtml`.

### 🐛 Critical Layout Fix

- **Unbounded-width crash eliminated** — `RenderHyperBox.performLayout` and `_computeHeightForWidth` now clamp `_maxWidth` to `_kUnboundedWidthFallback = 800.0` when constraints are `double.infinity` (Row without Expanded, horizontal `SingleChildScrollView`, intrinsic queries from unbounded parents). Previously `_FlexFragment.layout` propagated infinity into `BoxConstraints(minWidth: ∞)` and tripped Flutter's `minWidth < double.infinity` assertion.

### 🐛 Selection & Ellipsis

- **`text-overflow: ellipsis` no longer leaks hidden text via copy** — `Fragment.ellipsisVisibleLength` records how many leading characters survive each truncation pass; `getSelectedText` clamps the visible range against it and skips fully-suppressed fragments. State is reset at the top of every `_performLineLayout` so a wider re-layout un-hides text that was previously truncated.
- **Selection drag is now lenient on edge overshoot** — `_lineIndexAt(dy, clampOutOfBounds: true)` is used during handle drag, so a finger that drifts past the first/last line by a pixel snaps to the nearest line instead of freezing. Tap hit-testing (`_findFragmentAtPosition`) keeps the strict semantics.
- **Dead `_characterToFragment` / `_fragmentRanges` fields removed** — they were populated in `_buildCharacterMapping` each layout but never read. Layout micro-saving and one less GC pressure point.

### 🐛 Table

- **Cell BlockNode content no longer disappears** — when `cellContentBuilder` is `null` and a cell contains `<div>`/`<p>` children, `_buildCellContent` now renders the inline run plus each block child via a default `Column`/`Text` fallback. Previously only callers that went through `HyperRenderWidget` (which auto-supplies a builder) were safe.
- **Total-cell cap `_kMaxTotalCells = 100 000`** — a pathological `<table>` whose `rowCount × columnCount` exceeds the cap now renders a visible "Table too large to render" placeholder instead of allocating an 8 MB `null` grid on the UI thread.

### 🐛 Animations

- **`HyperAnimatedWidget` controller lifecycle hardened** — switched from `SingleTickerProviderStateMixin` to `TickerProviderStateMixin`; the previous mixin asserted on the second `createTicker()` when `didUpdateWidget` recreated the controller. The start delay now uses a retained `Timer` that is cancelled on `didUpdateWidget` / `dispose`, eliminating duplicate `forward()` calls in fast-rebuild scenarios.

### 🧪 Tests

- **+27 tests added** across `url_safety_test`, `animation_controller_race_test`, `table_review_fixes_test`. Full sub-package suite green.

## [1.3.2] - 2026-05-14

### ✨ New CSS Properties
- **`list-style-type`**: All 11 values — `disc`, `circle`, `square`, `decimal`, `decimal-leading-zero`, `lower-alpha`, `upper-alpha`, `lower-latin`, `upper-latin`, `lower-roman`, `upper-roman`, `none`
- **`list-style-position`**: `inside` / `outside` (default)
- **`list-style` shorthand**: parses `<type> <position>` in any order
- **`background-repeat`**: `repeat`, `repeat-x`, `repeat-y`, `no-repeat`, `space`, `round`
- **`background-position`**: keyword (`center`, `top left`, etc.) and percentage values

### 🚀 Performance
- **Selection rects cached**: `getSelectionRects()` called once per drag event (was 3×); stored in `_selectionRects` field — eliminates redundant layout walks during selection drag
- **Auto-scroll proportional speed**: `_autoScrollIfNearEdge` now scales 0–20 px/frame based on finger distance from edge (was fixed 15 px/frame)
- **`HyperTeardropHandlePainter` deduplicated**: renamed to `HyperTeardropHandlePainter`, made public, and exported from core; duplicate in the virtualized overlay deleted

### 🐛 Bug Fixes
- **Edge-to-edge images**: `_kImageMargin` set to `0.0` — `width: 100%` images now truly fill their container with no internal margin offset

## [1.3.0] - 2026-05-03

### ✨ New Features
- **`HyperNodePlugin` / `HyperPluginRegistry`** (`src/interfaces/node_plugin.dart`): Plugin API for custom widget rendering of arbitrary HTML tag names. Block tier (full-width, CSS margins) and inline tier (flows with text, intrinsic-measured) supported.
- **Plugin layout wiring** (`render_hyper_box.dart`, `render_hyper_box_layout.dart`): `blockPluginTags` / `inlinePluginTags` sets added to `RenderHyperBox` with layout-invalidating setters. `_tokenizeNode` intercepts plugin tags; Step 1.7 `_measureInlinePluginFragments()` queries child intrinsic dimensions before line layout runs.
- **Plugin widget wiring** (`hyper_render_widget.dart`): `pluginRegistry` field added; `_collectAtomicChildren` checks plugin registry first; `createRenderObject` / `updateRenderObject` sync tag sets to the render object.
- **CSS**: Box shadow, linear-gradient, advanced border styles (dashed/dotted)
- **CSS**: Full Flexbox support (direction, wrap, gap, align-self, grow/shrink/basis)
- **CSS**: CSS Variables `var()`, `transition`, `animation-*` parsing
- **CSS**: `computed_style` expanded with 120+ additional properties
- **CSS Grid**: `display: grid` with `grid-template-columns`, `span`, `gap`
- **Style**: `resolver.dart` expanded — specificity engine, cascade improvements
- **Widgets**: `HyperRenderWidget` — adaptive selection colors, theme-aware; new `enableComplexFilters` flag to gate `saveLayer` calls for backdrop-filter/filter effects
- **Widgets**: `HyperSelectionOverlay` — improved handle rendering with tight bounding boxes
- **Rendering**: `render_hyper_box_layout.dart` — float algorithm improvements; O(1) `_fragmentChildMap` child lookup; O(1) `_nodeRectCache` accessibility rect lookup
- **Rendering**: `render_hyper_box_paint.dart` — retina-ready images, anti-aliasing
- **Performance**: `_buildNodeRectCache()` builds O(1) accessibility rects during layout (Step 8), depth-capped at 32 levels

### ♿ Accessibility (WCAG 2.1 AA)
- **`<img alt>` → discrete `SemanticsNode`**: Images with non-empty `alt` text now generate an individual `SemanticsNode` at the image's layout rect — VoiceOver/TalkBack users can navigate to images element-by-element (WCAG 1.1.1)
- **`aria-label` honored on `<a>` elements**: Anchor elements with `aria-label` now use that attribute as the link's accessible label instead of accumulated text content (WCAG 4.1.2)

### 🐛 Bug Fixes
- **`HyperRenderWidget` compilation error**: Resolved a signature mismatch in recursive widget construction where `codeHighlighter` was passed outside of `config` and `pluginRegistry` was missing
- **Float layout**: Explicit CSS `width` and `height` properties are now correctly respected for non-image float elements
- **Plugin propagation**: `pluginRegistry` is correctly passed to nested renderers, allowing custom tags to work inside floated containers
- **Scroll vs. text-selection conflict**: Removed `PointerMoveEvent` selection tracking from `handleEvent` — selection now initiated via `LongPressGestureRecognizer` at the widget layer
- **Context menu outside hit-testable bounds**: `Positioned(top: menuY - 56)` clamped to `0.0` — Copy button is always reachable near the top of the widget
- **`display:none` not respected**: Guard in `_tokenizeNode` — elements with `display:none` produce no layout fragments
- **`_TextPainterKey` hash collision**: Replaced `Object.hash()` int key with full value-equality struct — eliminates subtle layout glitches on large documents
- **Inline images not loaded after async parse**: `document` setter now calls `_loadImages()` when the render box is attached
- **Image loading spinner invisible**: `frameBuilder` no longer wraps the `loadingBuilder` placeholder in `AnimatedOpacity(opacity:0)` — `TweenAnimationBuilder` fade-in applied on first decoded frame instead
- **Ruby selection — 5 bugs fixed**: `FragmentType.ruby` was silently skipped in every selection pipeline step, causing character offset desynchronisation for all content after a ruby fragment
- **`LineInfo.characterCount`**: now counts ruby base-text characters (was 0 for ruby fragments)
- **`details_widget.dart`**: Fixed undefined `DetailsNode` class — field type changed to `UDTNode` with `attributes.containsKey('open')` for HTML-spec-compliant initial state
- **Selection**: `getSelectedText()` now inserts `\n` at block element boundaries so copied text respects paragraph/list structure
- **Layout Bug 1**: `characterOffset` no longer adds `trimmedLeading` to second fragment — selection mapping was off by the number of trimmed leading spaces
- **Layout Bug 2**: `_sameLinkContext()` guard prevents merging text nodes from different `<a>` ancestors — fixes incorrect link tap targets
- **Layout Bug 3**: `_layoutFloat()` early-returns when `_maxWidth.isInfinite` — prevents crash in unconstrained layouts; uses `getMaxIntrinsicWidth/Height` instead of `child.layout()` to eliminate double-layout
- **Layout Bug 4**: Null/empty guard in `_measureFragments` for `fragment.text` — no longer crashes on atomic/ruby fragments
- **Memory**: `_disposeLinkRecognizers()` called in `document` setter — fixes recognizer leak when document is replaced
- **Nested decorations**: `nodeToDecorated` changed from `Map<UDTNode, UDTNode>` to `Map<UDTNode, List<UDTNode>>` — inner spans no longer overwrite outer spans
- **`prefer_const_constructors`**: `HyperPluginBuildContext` construction changed to `const`

### 🔬 Tests
- **+17 tests** — `ruby_layout_test.dart`: `LineInfo.characterCount` with ruby, selection offset accumulation
- **+27 tests** — `ruby_layout_test.dart`: RubyNode model, Fragment.ruby lifecycle, document tree traversal
- **+30 tests** — `float_layout_test.dart`: HyperFloat/HyperClear enums, node construction, LineInfo insets
- **+44 tests** — `text_breaking_test.dart`: canBreak, isWhitespace, ComputedStyle overflow, CJK/Kinsoku
- **+52 tests** — `layout_algorithm_test.dart`: characterOffset regression, rect computation, link context
- **+32 tests** — `details_element_test.dart`: `<details>/<summary>` model and widget open/close behavior
- **+53 tests** — `rtl_bidi_test.dart`: HyperTextDirection, hyperDirection inheritance, Arabic/Hebrew text, RTL widget integration
- `dart fix` applied to test files: 73 `prefer_const` issues resolved — 0 analyzer issues

## [1.2.0] - 2026-03-30

- First stable release. Core UDT model, RenderObject engine, plugin interfaces.
