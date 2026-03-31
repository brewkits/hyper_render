# Changelog — hyper_render_core

## [1.2.0] - 2026-03-29

### ✨ New Features

- **`HyperNodePlugin` / `HyperPluginRegistry`** (`src/interfaces/node_plugin.dart`): Plugin API for custom widget rendering of arbitrary HTML tag names. Block tier (full-width, CSS margins) and inline tier (flows with text, intrinsic-measured) supported.
- **Plugin layout wiring** (`render_hyper_box.dart`, `render_hyper_box_layout.dart`): `blockPluginTags` / `inlinePluginTags` sets added to `RenderHyperBox` with layout-invalidating setters. `_tokenizeNode` intercepts plugin tags; Step 1.7 `_measureInlinePluginFragments()` queries child intrinsic dimensions before line layout runs.
- **Plugin widget wiring** (`hyper_render_widget.dart`): `pluginRegistry` field added; `_collectAtomicChildren` checks plugin registry first; `createRenderObject` / `updateRenderObject` sync tag sets to the render object.

### ♿ Accessibility (WCAG 2.1 AA)

- **`<img alt>` → discrete `SemanticsNode`** (`render_hyper_box_accessibility.dart`): Images with non-empty `alt` text now generate an individual `SemanticsNode` at the image's layout rect. VoiceOver/TalkBack users can navigate to images element-by-element. Previously `alt` only appeared in the flat document-level label (WCAG 1.1.1).
- **`aria-label` honored on `<a>` elements** (`render_hyper_box_accessibility.dart`): Anchor elements with `aria-label` now use that attribute as the link's accessible label instead of accumulated text content (WCAG 4.1.2).

### 🐛 Bug Fixes

- **Scroll vs. text-selection conflict** (`render_hyper_box.dart`): Removed `PointerMoveEvent` selection tracking from `handleEvent` — raw pointer events bypass the gesture arena and caused accidental selection during scrolling. Selection is now initiated via `startSelectionAt(Offset)` / `extendSelectionTo(Offset)` public methods, called from a `LongPressGestureRecognizer` at the widget layer.

- **Context menu outside hit-testable bounds** (`hyper_selection_overlay.dart`): `Positioned(top: menuY - 56)` went negative when a selection was near the top of the widget. Clamped to `0.0` so the Copy button is always reachable.

- **`prefer_const_constructors`** (`hyper_render_widget.dart`): `HyperPluginBuildContext` construction changed to `const`.

---

## [1.1.4] - 2026-03-28

### 🐛 Bug Fixes
- **`display:none` not respected**: Added guard in `_tokenizeNode` — elements with `display:none` produce no layout fragments.
- **`_TextPainterKey` hash collision**: Replaced `Object.hash()` int key with full value-equality struct — eliminates subtle layout glitches on large documents with many distinct text styles.

- **Inline images not loaded after async parse**: `document` setter now calls `_loadImages()` when the render box is attached, ensuring images are queued even when the document arrives after the initial `attach()`.
- **Image loading spinner invisible**: `frameBuilder` no longer wraps the `loadingBuilder` placeholder in `AnimatedOpacity(opacity:0)` — loading indicator is now visible, and a `TweenAnimationBuilder` fade-in is applied on the first decoded frame instead.

### 🏗️ Code Quality
- `dart fix` applied to test files: 73 `prefer_const` issues resolved — 0 analyzer issues.

## [1.1.3] - 2026-03-25

- Remove `publish_to: none` from pubspec.yaml so pub.dev can verify the repository URL (fixes 10-point deduction).


## [1.1.2] - 2026-03-25

### 🐛 Bug Fixes
- **Ruby selection — 5 bugs fixed**: `FragmentType.ruby` was silently skipped in every selection pipeline step, causing character offset desynchronisation for all content after a ruby fragment.
  - `_buildCharacterMapping()`: ruby fragments now included in `_fragmentRanges` and `_totalCharacterCount`
  - `_paintSelection()`: selection highlight is now drawn over ruby fragments; offset correctly advanced
  - `getSelectedText()`: ruby base text is now included in copied text
  - `getSelectionRects()`: ruby fragment rects are now returned for handle positioning
  - `_getCharacterPositionAtOffset()` skip-lines section: ruby chars now counted when advancing past earlier lines
- **`LineInfo.characterCount`**: now counts ruby base-text characters (was 0 for ruby fragments)

### 🔬 Tests
- **+17 tests** — `ruby_layout_test.dart`: `LineInfo.characterCount` with ruby, selection offset accumulation across text + ruby + text, character position mapping

## [1.1.1] - 2026-03-23

### 🐛 Bug Fixes
- **`details_widget.dart`**: Fixed undefined `DetailsNode` class — changed field type to `UDTNode` and replaced `.open` property access with `attributes.containsKey('open')` for HTML-spec-compliant initial state

## [1.1.0] - 2026-03-20

### ✨ New Features (synced from hyper_render)
- **CSS**: Box shadow, linear-gradient, advanced border styles (dashed/dotted)
- **CSS**: Full Flexbox support (direction, wrap, gap, align-self, grow/shrink/basis)
- **CSS**: CSS Variables `var()`, `transition`, `animation-*` parsing
- **CSS**: `computed_style` expanded with 120+ additional properties
- **Style**: `resolver.dart` expanded — specificity engine, cascade improvements
- **Widgets**: `HyperRenderWidget` — adaptive selection colors, theme-aware; new `enableComplexFilters` flag to gate `saveLayer` calls for backdrop-filter/filter effects
- **Widgets**: `HyperSelectionOverlay` — improved handle rendering with tight bounding boxes
- **Widgets**: `GridContainerWidget` — CSS Grid layout with `grid-template-columns`, `span`, `gap`
- **Rendering**: `render_hyper_box_layout.dart` — float algorithm improvements; O(1) `_fragmentChildMap` child lookup; O(1) `_nodeRectCache` accessibility rect lookup
- **Rendering**: `render_hyper_box_paint.dart` — retina-ready images, anti-aliasing; `_fragmentChildMap` replaces O(N) linear scan
- **Rendering**: `render_media.dart` — enhanced error boundaries
- **Performance**: `_buildNodeRectCache()` builds O(1) accessibility rects during layout (Step 8), depth-capped at 32 levels

### 🐛 Bug Fixes
- **Selection**: `getSelectedText()` now inserts `\n` at block element boundaries (`_BlockEndFragment`) so copied text respects paragraph/list structure
- **Selection**: `getSelectionRects()` uses `getBoxesForSelection` with tight bounding boxes for accurate highlight rendering
- **Layout** (Bug 1): `characterOffset` no longer adds `trimmedLeading` to second fragment — selection mapping was off by the number of trimmed leading spaces
- **Layout** (Bug 2): `_sameLinkContext()` guard prevents merging text nodes from different `<a>` ancestors during tokenization — fixed incorrect link tap targets
- **Layout** (Bug 3): `_layoutFloat()` now early-returns when `_maxWidth.isInfinite` — prevented crash in unconstrained layouts
- **Layout** (Bug 3): Float intrinsic size uses `getMaxIntrinsicWidth/Height` instead of `child.layout()` — eliminates double-layout
- **Layout** (Bug 4): Null/empty guard in `_measureFragments` for `fragment.text` — no longer crashes on atomic/ruby fragments
- **Memory**: `_disposeLinkRecognizers()` called in `document` setter — fixes recognizer leak when document is replaced
- **Float**: `_layoutFloat()` uses `getMaxIntrinsicWidth/Height` instead of direct `child.layout()` to avoid double-layout violations
- **Nested Decorations** (Issue 4): `nodeToDecorated` changed from `Map<UDTNode, UDTNode>` to `Map<UDTNode, List<UDTNode>>` — inner spans no longer overwrite outer spans in decoration maps
- **Type Safety** (BP5): `decoratedRanges` uses `int?` null sentinel instead of `-1` — eliminates accidental `-1 < 0` false matches

### 🔬 Tests
- **+27 tests** — `ruby_layout_test.dart`: RubyNode model, Fragment.ruby lifecycle, document tree traversal
- **+30 tests** — `float_layout_test.dart`: HyperFloat/HyperClear enums, node construction, LineInfo insets
- **+44 tests** — `text_breaking_test.dart`: canBreak, isWhitespace, ComputedStyle overflow, CJK/Kinsoku
- **+52 tests** — `layout_algorithm_test.dart`: characterOffset regression, rect computation, Bug 1–4 regressions, link context
- **+32 tests** — `details_element_test.dart`: `<details>/<summary>` model and widget open/close behavior
- **+53 tests** — `rtl_bidi_test.dart`: HyperTextDirection, hyperDirection inheritance, Arabic/Hebrew text, RTL widget integration

## [1.0.0] - 2026-03-01
First stable release. Core UDT model, RenderObject engine, plugin interfaces.
