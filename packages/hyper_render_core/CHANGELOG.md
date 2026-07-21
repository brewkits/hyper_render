# Changelog — hyper_render_core

## [Unreleased]

### ⚠️ Behavior Change — text scaling (WCAG 1.4.4)
- `RenderHyperBox` and `RenderRubyText` now accept a `TextScaler` and apply it to every `TextPainter` (measurement + paint), so rendered text honours the device's accessibility text-scaling setting. Previously all text was measured at `TextScaler.noScaling`. `HyperRenderWidget` gained an optional `textScaler` param (null → `MediaQuery.textScalerOf(context)`); `_TextPainterKey` now includes the scaler so the process-global painter cache doesn't collide across scales. The `RenderHyperBox.textScaler` setter routes through `_invalidateLayout()` (not a bare `markNeedsLayout()`) so a scaler-only change actually re-measures rather than being skipped by the fragment-version fast-path. **Existing content re-renders larger when the user's system font size is increased** — pass `TextScaler.noScaling` to opt out.

### ✨ New CSS Features
- **`animation-play-state`**: `running` / `paused` parsed (longhand + `animation` shorthand) and executed. New `HyperAnimationPlayState` enum, `ComputedStyle.animationPlayState` field, and `HyperAnimatedWidget.paused` flag. Paused animations hold their current frame and resume from it; pausing before the initial delay restarts the delay countdown on resume.
- **Canvas-tier block animation**: `RenderHyperBox` now executes `animation-name` for content it paints directly on its own `Canvas` (plain block-level paragraphs/divs), not just widget-tier content. New `render_hyper_box_animation.dart`: `_BlockAnimationState` tracks per-node elapsed time (`accumulated` + `epoch`, frozen/resumed across pause instead of mirroring `AnimationController`), driven by a `SchedulerBinding.scheduleFrameCallback` loop (same pattern as the existing image-loading shimmer — no `TickerProvider`) that self-terminates once no block is both `running` and unfinished. `paint()` gained a `_paintAnimatedBlocks` pass that composites each animated block's own decoration + owned text/ruby fragments inside a single `saveLayer` before the normal decoration/text passes (which skip anything already painted this way) — a single alpha layer avoids double-blending a block's background through its own text when animating `opacity`. The layer's `saveLayer` bounds are `null` (current clip), not the block's static rect — passing the pre-transform rect as bounds clipped a translated/scaled block to its original position whenever `opacity` and `transform` combined (caught by a new golden test before release, not shipped broken). Rects/fragment groupings are precomputed once per `performLayout`, not per paint frame.

### 🐛 Bug Fixes
- **Animation iteration counter leaked across rebuilds**: `_HyperAnimatedWidgetState` now resets its iteration counter whenever the controller is rebuilt, so a swapped-in animation plays its full `animation-iteration-count` instead of inheriting the previous animation's progress.
- **`line-height` in absolute units used the wrong reference font-size**: `resolver.dart`'s `case 'line-height'` divided a px/em length by `parentFontSize` unconditionally; when the same element also declared its own `font-size`, that's the wrong reference per CSS (should be the element's own resolved font-size). Now uses `style.fontSize` when `font-size` was already processed earlier in the same declaration block, falling back to `parentFontSize` only when this element doesn't override font-size at all.
- **`<p>&nbsp;</p>` collapsed to zero height**: `Fragment.isWhitespace` and the layout tokenizer's whitespace-collapsing regex both used `String.trim()`/`\s+`, which — unlike CSS — also match U+00A0 (`&nbsp;`). A text run consisting only of a non-breaking space was misclassified as droppable/collapsible source whitespace. New `src/util/html_whitespace.dart` (`isCssWhitespaceOnly`, `cssWhitespaceRun`) defines the CSS-precise whitespace set (space/tab/LF/CR/FF only) and is now used by `Fragment.isWhitespace`, `RenderHyperBox`'s `_kWhitespaceSplitter`, and both `HtmlAdapter` implementations (`hyper_render_html` and the root package's).
- **`<ol start="N">` was ignored**: `render_hyper_box_layout.dart`'s list-marker numbering always seeded the first `<li>` at 1. It now reads `parentBlock.attributes['start']` for the first item of each `<ol>` (defaulting to 1 on absent/malformed values), so ordered lists can start at an arbitrary ordinal. Sibling lists keep independent counters via the existing `_listItemIndices` map.

### ♻️ Internal
- `curveFromHyperTiming`, `resolveHyperKeyframes`, `matrix4FromHyperKeyframe` (`animation_controller.dart`) are now shared top-level helpers used by both the widget-tier and canvas-tier animation code, replacing three near-duplicate private implementations.
- New `src/util/html_whitespace.dart`, exported from the package barrel — same pattern as the existing `UrlSafety` shared helper (single source of truth for a rule every adapter must apply identically, instead of each adapter/layout stage rolling its own whitespace check and risking drift).

## [1.5.0] - 2026-07-05

### ✨ New CSS Features
- **`cubic-bezier()` / `steps()` timing functions**: new `HyperTimingFunction.cubicBezier`/`steps` enum values plus `HyperTimingParams` (`HyperCubicBezierParams`, `HyperStepsParams`) carried on `HyperTransition` and `ComputedStyle.animationTimingParams`. `steps()`/`step-start`/`step-end` render through the new `HyperStepsCurve`; `cubic-bezier()` maps to Flutter's `Cubic`. Shorthand parsing is paren-aware so inner commas are preserved; `x` control points are clamped to `[0, 1]`.
- **Animatable `color` / `background-color`**: `HyperKeyframe` gained `color`/`backgroundColor` (interpolated via `Color.lerp`). `HyperAnimatedWidget` applies them with `DefaultTextStyle.merge` + `ColoredBox`; `HyperTransitionWidget` animates them with `AnimatedDefaultTextStyle` + `AnimatedContainer`. `StyleResolver.parseCssColor` is now a public static so adapters reuse the same color grammar.

### 🩺 Diagnostics
- **`HyperMemoryMetrics` / `HyperMemoryDebug`**: debug-only snapshot of what each memory-pressure cycle released. `LazyImageQueue.pendingCount` added.

### 🐛 Bug Fixes
- **Zero-width `BorderSide` + `border-radius` assertion (issue #12)**: new `cssBorderFromStyle` helper maps `0px` sides to `BorderSide.none` in both `hyper_render_widget.dart` and `flex_container_widget.dart`; the flex-container path also now honours `border-style: none`.
- **`StyleResolver.parseCssColor` hardened**: returns `null` (no `FormatException`) on malformed hex or out-of-`int64` `rgb()`/`rgba()` values — required now that color parsing runs on arbitrary `@keyframes` values.

## [1.4.0] - 2026-06-24

### ✨ New CSS Features
- **`aspect-ratio`**: `W/H` and bare-number syntax parsed; applied to `<img>`/`<video>` sizing across all width-only/height-only/neither-specified layout branches.
- **`transition` execution**: new `HyperTransitionWidget` animates `opacity`/`transform` across style changes using the declared duration and timing function; wired into `HyperRenderWidget._maybeAnimate`.
- **`animation-iteration-count: infinite`**: now loops via `AnimationController.repeat()`; added `alternate` flag so `animation-direction: alternate`/`alternate-reverse` is handled distinctly from `reverse`.
- **Float Carryover paint completion**: `imagePixelOffset` is now consumed in `_paintFloatImages` — a tall floated image overhanging a virtualized section boundary continues painting from the correct offset in the next chunk.
- ~25 new resolver cases for previously-silent properties: `white-space`, `word-spacing`, `text-transform`, `text-decoration-color`, `min/max-width/height`, `overflow*`, `border-top/right/bottom/color/width`, `animation` shorthand + sub-properties, `transition`, `aspect-ratio`.

### 🐛 Bug Fixes
- `rem` units now parsed correctly in `_parseLength` (previously misparsed via the `em` branch).
- `text-decoration` no longer incorrectly inherited (not inheritable per CSS spec); `text-transform` inheritance added instead.
- Linear-gradient diagonal corner directions (`to top right`, etc.) now set both `begin` and `end` correctly.
- `filter` now composes all entries in a chain, not just the first two.
- `border: none` now zeroes width instead of leaving the 1px default.
- Division-by-zero guard added to unitless `line-height` resolution.
- Float layout no longer allocates a spread list (`[...left, ...right]`) per line.
- `HyperTextSelection` now implements `operator==`, eliminating redundant repaints on unchanged selections.
- `setGlobalTextCacheSize` now disposes the previous cache instead of leaking `TextPainter`s.

## [1.3.4] - 2026-06-04

### 🔧 Fixes
- **Static Analysis Compliance**: Suppressed deprecated `SizeTransition.axisAlignment` lints with `// ignore: deprecated_member_use` to maintain backwards compatibility with older Flutter SDKs (>=3.10) while securing 160/160 points on pub.dev.

## [1.3.3] - 2026-06-04

### ✨ New CSS & Layout
- **`object-fit` support**: Added `object-fit` property parsing (`cover`, `contain`, `fill`, `none`, `scale-down`) to control image resizing within its block container.
- **Float carryover `imagePixelOffset`**: Enhanced `FloatCarryover` to carry `imagePixelOffset` across sections to allow precise partial painting of tall floated images.

### ✨ New APIs & Configs
- **`onMemoryPressure` callback**: Added `onMemoryPressure` parameter to widgets to allow host applications to coordinate resource disposal with HyperRender's cache invalidation.
- **`imageConcurrency`**: Configured `imageConcurrency` setting in `HyperRenderConfig` and wired it into `LazyImageQueue`.

### 🐛 Bug Fixes & Refinement
- **TextPainter Cache**: Replaced the global `TextPainter` cache with a reference-counted multi-viewer safe cache.
- **Color Parsing**: Fixed rgb/rgba parsing bugs by properly mapping `csslib` function parameters.

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

## [1.3.1] - 2026-05-14

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
