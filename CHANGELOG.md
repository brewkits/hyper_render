# Changelog

## [1.3.2] - 2026-05-18

### Bug Fixes (Critical)

- **[DEADLOCK] LazyImageQueue no longer deadlocks on a synchronously-throwing loader** — if a user-supplied `HyperImageLoader` threw before invoking its onLoad/onError callback, `_active` was never decremented; after `maxConcurrent` such throws the queue stopped processing every subsequent image until app restart. `_startLoad` now wraps the loader call in try/catch and routes any synchronous exception through the same idempotent error path used by the async callback.
- **[SECURITY] Sanitizer now validates ALL URL-bearing attributes** — previously only `href` and `src` were checked, leaving `poster`, `data`, `cite`, `background`, `longdesc`, `usemap`, `manifest`, `xlink:href`, `formaction`, `action`, `icon`, and `srcset` as XSS bypass vectors (e.g. `<video poster="javascript:...">`). Added `urlBearingAttributes` constant and routes every match through `isSafeUrl`. `srcset` is split into candidates and each candidate's URL is validated independently.
- **[SECURITY] `isTap` no longer fires when the pointer never went down inside the widget** — `handleEvent` previously treated `downPosition == null` as a valid tap, so a finger swiping into the widget from outside and lifting up would trigger `onLinkTap` on whatever fragment was under the lift point. Now requires BOTH a recorded down position AND a movement within `tapSlop`.
- **[BUG-1] Images no longer permanently disappear after a Low Memory Warning** — `clearMemoryCaches()` disposed the image cache but never re-triggered `_loadImages()`. Visible images were stuck in the empty-placeholder state until the user scrolled the section out of view and back to force a detach+attach cycle. The cache-clear path now re-enqueues image loads via `LazyImageQueue` so visible images reload through the normal priority pipeline.
- **[BUG-2] `_hashSection` now invalidates on attribute changes** — the previous fingerprint only hashed text content + child count, so changing only `<img src="a.jpg">` → `<img src="b.jpg">` (or class/id/style) produced the same hash. `_mergeSections` would silently reuse the stale `DocumentNode`, freezing dynamic UI at the first rendered version. The new recursive hash walks the subtree and includes tagName, type, text, atomic src/alt, all attributes (keys sorted), and per-depth child counts.
- **[BUG-3] Eliminated 1-frame layout flash with dangling floats** — `_onFloatCarryover` previously deferred the cross-section update via `addPostFrameCallback + setState`, so section N+1 always laid out once with empty initialFloats before the corrected pass. Added `onRenderBoxReady` callback on `HyperRenderWidget` and `VirtualizedChunk`; `_HyperViewerState` keeps a `Map<int, RenderHyperBox>` registry and pushes new floats directly onto section N+1's RenderObject during section N's layout, so the pipeline owner picks up the change in the same frame.
- **[C-1] HyperSelectionOverlay now forwards `config`, `pluginRegistry`, `enableComplexFilters`** — plugins, custom link schemes, keyframe animations and filter settings were silently ignored in sync+selectable and paged+selectable modes. All three params are now accepted by `HyperSelectionOverlay` and forwarded to the inner `HyperRenderWidget`.
- **[C-2] Fixed GPU memory leak in image cache** — `_imageCache` was missing an `onEvict` callback, so `ui.Image` GPU textures were never disposed when entries were evicted from the LRU. Added `onEvict: (ci) => ci.image?.dispose()` to free GPU memory promptly on eviction.
- **[C-3] Removed dead `_parseIsolate` / `_parseReceivePort` code** — these fields were declared but never assigned, making `_cancelParsing()` a no-op. Cleaned up unused `dart:isolate` import and fields; `_parseId` counter remains the mechanism for discarding stale parse results.
- **[C-4] TextPainter global cache now respects `HyperRenderConfig.textPainterCacheSize`** — was hardcoded to 500 regardless of config (default 5000). Added `RenderHyperBox.setGlobalTextCacheSize()` static method; `HyperViewer` calls it in `initState` and `didUpdateWidget`.

### Bug Fixes (High)

- **[H-1] `HyperRenderConfig.operator==` and `hashCode` now include `useMicrotaskParsing`** — changing only this field no longer fails to trigger a re-parse.
- **[H-2] `ComputedStyle.copyWith()` now copies `_explicitlySet`** — previously the result had an empty explicit-set, causing `inheritFrom()` to overwrite all copyWith'd properties with parent styles, breaking the CSS cascade.
- **[H-3] `_containsFloatChild` detects `float:left` (no space) and Bootstrap/Tailwind class names** — `float:left`, `float-left`, `float-right`, `float-start`, `float-end`, `pull-left`, `pull-right` are now detected, preventing incorrect section splits in virtualized mode.
- **[H-4] `isSafeUrl()` blocks `file:`, `mhtml:`, and `about:` schemes** — these can access local filesystem, trigger MHTML exploits, or enable sandbox-escape via `about:blank` on Android/iOS.

### Bug Fixes (Medium)

- **[M-1] `_effectiveConfig` is now cached** — was allocating a new `HyperRenderConfig` on every `build()` call (every scroll frame). Cache is invalidated when `renderConfig`, `allowedCustomSchemes`, or document keyframes change.
- **[M-2] `HyperViewer.fromNode` now accepts `pluginRegistry` and `onError`** — previously hardcoded to `null`, making plugins and error handling unavailable for pre-parsed AST consumers.
- **[M-3] `_buildPagedContent` no longer allocates a discarded `HyperRenderWidget`** — restructured to if/else so only one widget is built per page in selectable mode.
- **[M-4] `_TextPainterKey` now includes `wordSpacing`** — two fragments with identical text but different `word-spacing` no longer share the same `TextPainter`, preventing incorrect layout widths.

### Performance (Low)

- **[L-1] `LazyImageQueue._findQueued` is now O(1)** — added `_urlToQueued` secondary index; previously O(N) causing O(N²) batch behavior with many simultaneous image loads.
- **[L-2] `_hasDetailFragments` flag replaces O(N) scan** — `performLayout` no longer scans all fragments to check for `<details>` elements; flag is set during tokenization.

### Fixes (Low)

- **[L-3] `_splitIntoSections` no longer overwrites existing node parents** — changed `child.parent = current` to `if (child.parent == null) child.parent = current` to avoid corrupting ancestor-chain traversal on reused section nodes.
- **[L-4] Removed dead `_draggingHandle` field** from `HyperSelectionOverlayState`.

### Correctness & Robustness

- **Hash collision resilience on Web** — `_accumulateHashParts` now also mixes in `text.length` for every `TextNode`, significantly reducing the chance that two long-but-distinct strings hash to the same slot on the JS target (where `Object.hashAll` has weaker dispersion than the Dart VM).
- **`computeMinIntrinsicWidth` handles icon fonts, emoji, and dingbats** — the previous "longest-by-char-count word" heuristic miscalculated when a single PUA glyph (Material Icons, Font Awesome) or emoji renders far wider than a Latin letter. When the fragment contains any code point in U+E000–U+F8FF, U+2600–U+27BF, or U+1F000+, the entire fragment is measured instead of just the longest word.
- **`RenderHyperBox.detach()` now cancels shimmer state** — a `ListView` item that detached mid-shimmer (scrolled out of cache) and later re-attached kept a stale `_shimmerEpoch`, producing a 1-frame phase jump on re-mount. The frame callback is now cancelled and `_shimmerEpoch` reset.

### New

- **`HyperRenderConfig.useRepaintBoundary`** (default `true`) — opt out of the outer-section `RepaintBoundary` wrapper. `RenderHyperBox` is already an internal repaint boundary, so this is mostly an escape hatch for very low-RAM Android devices (≤ 1.5 GB) rendering image-heavy long documents with a custom small `virtualizationChunkSize`, where many concurrent GPU layers could exhaust VRAM before the texture cache evicts.

---

## [1.3.1] - 2026-05-14

### ⚠️ Migration from 1.3.0

`hyper_render_clipboard` and `hyper_render_math` are no longer transitive dependencies of `hyper_render`. If you use either, add them explicitly:

```yaml
dependencies:
  hyper_render: ^1.3.1
  hyper_render_clipboard: ^1.3.1   # only if you use SuperClipboardHandler
  hyper_render_math: ^1.3.1        # only if you use MathNodePlugin / LatexNodePlugin
```

### ✨ New CSS Properties

- **`list-style-type`**: All 11 marker types — `disc`, `circle`, `square`, `decimal`, `decimal-leading-zero`, `lower-alpha`, `upper-alpha`, `lower-latin`, `upper-latin`, `lower-roman`, `upper-roman`, `none`
- **`list-style-position`**: `inside` / `outside`
- **`list-style` shorthand**: parses type and position in any order
- **`background-repeat`**: `repeat`, `repeat-x`, `repeat-y`, `no-repeat`, `space`, `round`
- **`background-position`**: keyword (`center`, `top left`, etc.) and percentage values

### 🚀 Performance

- **Selection rects cached**: `getSelectionRects()` now called once per drag event (was 3×) — stored in `_selectionRects` field, eliminating redundant layout walks during selection drag
- **Auto-scroll proportional speed**: `_autoScrollIfNearEdge` scales 0–20 px/frame based on finger proximity to edge (was fixed 15 px/frame)
- **`HyperTeardropHandlePainter` deduplicated**: renamed, made public, and exported from `hyper_render_core`; duplicate implementation in the virtualized overlay removed

### 🐛 Bug Fixes

- **Edge-to-edge images**: `width: 100%` images now truly fill their container — no internal margin offset

### 🏗️ Build Fixes

- **Decoupled native dependencies**: `hyper_render_clipboard` and `hyper_render_math` removed from root `hyper_render` default dependencies — eliminates the `compileSdk = 34` Gradle requirement for basic usage
- **Removed outdated `compileSdk` workaround** from example app's Android Gradle config


## [1.3.0] - 2026-05-03

### ✨ New Features

- **New Plugin Package**: `hyper_render_math` (`packages/hyper_render_math`): Added first-party support for mathematical formulas via LaTeX/MathML. It uses a custom `HyperNodePlugin` to render math content using the `flutter_math_fork` package. This milestone release consolidates all recent architectural improvements and bug fixes into a stable minor version.

### 🚀 Performance & Stability

- **Test Coverage Optimization**: Increased global test coverage to >85% with new comprehensive suites for parsers, adapters, and selection logic.
- **Golden Test Alignment**: Updated golden tests for consistent multi-platform rendering validation.
- **Improved Widget Test Robustness**: Updated `find.byType(HyperRenderWidget)` assertions to handle multiple instances in the tree caused by virtualization and float nesting.
- **`Paint()` memory optimization**: Replaced inline `Paint()` allocations in hot paint paths with reusable fields, reducing GC pressure during smooth scrolling.
- **Incremental layout hash collision fix**: Improved the fingerprinting of document sections to prevent cache collisions on duplicate content.

### 🐛 Bug Fixes

- **Markdown CRLF normalisation**: Content is now normalised to LF before splitting, fixing stray carriage-return characters in code blocks on Windows.
- **Virtualized Heading Protection**: Added guards to prevent virtualized sections from orphaning headings (Heading Widow/Orphan protection).
- **Config & Scheme Propagation**: Fixed issues where `useMicrotaskParsing` and `allowedCustomSchemes` were dropped during CSS-driven config rebuilds.
- **Float Layout precision**: Explicit CSS `width` and `height` are now strictly respected for non-image float elements.
- **Selection logic refinement**: Fixed edge cases for text selection across off-screen chunks in virtualized lists.
- **Android & iOS Build compatibility**: Modernized Gradle configuration and iOS project settings for better ARM64 simulator and modern SDK support.
- **SVG Sanitization**: Added an atomic SVG sanitization path to preserve structural elements while stripping dangerous attributes.
- **Plugin Propagation**: Ensured `pluginRegistry` is correctly passed to nested renderers inside floated containers.

## [1.2.2] - 2026-04-02

### 🐛 Bug Fixes

- **Android build failure with modern compileSdk** (`example/android/build.gradle.kts`): `irondash_engine_context 0.5.5` was compiled against android-31 but its transitive `androidx.fragment:1.7.1` dependency has `minCompileSdk=34`, causing AGP 8's `checkAarMetadata` to block the build. Added a `subprojects { afterEvaluate { compileSdk = 35 } }` override in the example's root Gradle file. README now documents the same one-line workaround for app-level projects. ([#5](https://github.com/brewkits/hyper_render/issues/5))
- **SVG invisible with `sanitize: true`** (`html_sanitizer.dart`): `<svg>` was not in `defaultAllowedTags` so the sanitizer unwrapped it, destroying the SVG structure. Added an atomic SVG sanitization path that strips `<script>` and dangerous attributes while preserving all structural SVG elements (`path`, `circle`, `g`, `use`, etc.).
- **`selectable` toggle ignored after build** (`hyper_viewer.dart`): Toggling `selectable` from `false` → `true` never created `VirtualizedSelectionController`, and `true` → `false` never disposed it. Fixed in `didUpdateWidget`.
- **Deep-link tap silently blocked** (`hyper_viewer.dart`): `_safeOnLinkTap` only checked `widget.allowedCustomSchemes` but ignored `renderConfig.extraLinkSchemes`, causing deep-links registered via `HyperRenderConfig` to be silently dropped. Both sources are now consulted.
- **CSS change didn't invalidate section cache** (`hyper_viewer.dart`): `_hashSection` hashes only text content, so a `customCss` change that alters layout/appearance would incorrectly reuse cached sections. `_sectionHashes` is now reset whenever `customCss` changes in `didUpdateWidget`.
- **Markdown/Delta virtualized/paged mode rendered as single section** (`hyper_viewer.dart`): The sync fallback path wrapped the entire parsed document as one section, defeating virtualization. Added `_splitIntoSections()` to chunk Markdown/Delta documents at block boundaries, matching the HTML isolate path.
- **`renderConfig` change only partially detected** (`hyper_viewer.dart`): `didUpdateWidget` compared only `virtualizationChunkSize` instead of the full `HyperRenderConfig`. Now uses full value equality (available since the `operator==` fix) so any config change triggers a re-parse.
- **CSS float class names not detected** (`html_adapter.dart`): `_containsFloatChild` missed Bootstrap/Tailwind float class names (`float-left`, `pull-right`, `alignleft`, etc.), causing premature section splits after float-containing blocks. Common class patterns are now detected heuristically.

## [1.2.1] - 2026-03-31

### 🏗️ Maintenance

- **Pub.dev compliance**: Fixed internal dependency constraints to use version ranges instead of path dependencies in the published package.
- **Virtualized screenshot description**: Refined screenshot metadata in `pubspec.yaml` for better display on pub.dev.
- **Metadata cleanup**: Removed stale comments and aligned topics for better discovery.


## [1.2.0] - 2026-03-30

### ✨ New Features

- **Multi-tier Plugin API** (`hyper_render_core`): Third-party packages can now render arbitrary HTML tags as custom Flutter widgets via `HyperNodePlugin` / `HyperPluginRegistry`.
  - **Block tier** (`isInline == false`, default): widget takes full available width with CSS margins.
  - **Inline tier** (`isInline == true`): widget flows inside text lines; intrinsic size measured in `performLayout` via `getMaxIntrinsicWidth / getMinIntrinsicHeight`.
  - Register at startup: `HyperPluginRegistry()..register(MyPlugin())` and pass to `HyperViewer(pluginRegistry: ...)`.

- **Dirty-flag incremental layout** (`hyper_viewer.dart`): Only re-layout sections whose content changed. Each `DocumentNode` chunk is fingerprinted with `Object.hashAll` over child `textContent`; unchanged sections are reused on the next parse, and `ValueKey(hash)` on `RepaintBoundary` lets Flutter skip re-layout and repaint entirely. ~90 0x0p+0yout rebuild reduction for live-updating feeds.

- **Paged mode** (`HyperRenderMode.paged`): `PageView.builder`-based rendering, one document chunk per page. Suitable for e-book / epub / reader UIs.
  - Supply a `HyperPageController` for programmatic navigation (`animateToPage`, `nextPage`, `previousPage`, `jumpToPage`) and `ValueNotifier<int> currentPage` for reactive page indicators.

### ♿ Accessibility (WCAG 2.1 AA)

- **Image alt-text semantic nodes** (`render_hyper_box_accessibility.dart`): `<img alt="…">` elements now produce a discrete `SemanticsNode` at the image's layout rect. Screen-reader users can navigate to images element-by-element (WCAG 1.1.1 Non-text Content). Previously alt text only appeared in the flat document-level label.
- **`aria-label` on links honored** (`render_hyper_box_accessibility.dart`): If an `<a>` element carries an `aria-label` attribute, that value is used as the link's semantic label instead of its text content (WCAG 4.1.2 Name, Role, Value).

### 🏗️ Refactor — Dead-code elimination

- **Removed 31 duplicate files from root `lib/src/`** that were identical or outdated copies of the canonical implementations in `packages/hyper_render_core`. Root `lib/src/` now contains only the 17 files that are genuinely unique to the root package (parsers, sanitizer, `HyperViewer`, virtualized selection, `capture_extension`).
- **`LazyImageQueue` singleton deduplication**: `lib/src/core/lazy_image_queue.dart` was a separate implementation that created a second `LazyImageQueue.instance` — meaning `LazyImageQueue.instance.cancel()` called from outside `HyperViewer` hit a different singleton than the one `HyperViewer` used internally. Root now re-exports `LazyImageQueue` directly from `hyper_render_core` (single shared instance).
- **Added missing v1.2.0 symbols to root re-export**: `HyperRenderConfig`, `LazyImageQueue`, `HyperNodePlugin`, `HyperPluginRegistry`, `HyperPluginBuildContext`, `LoadingSkeleton`, `HyperErrorWidget`, `FloatCarryover` are now all accessible from `package:hyper_render`.
- **Consolidated double export**: The redundant second `export 'package:hyper_render_core' show HyperRenderConfig'` line was folded into the main re-export block.

### 🐛 Bug Fixes

- **Copy action produced empty clipboard** (`virtualized_selection_overlay.dart`, `hyper_selection_overlay.dart`): The `Listener.onPointerDown` callback cleared the active selection before the Copy button's `onPressed` could fire, so `Clipboard.setData` received an empty string. Fixed by guarding `clearSelection()` behind a `_showMenu` / `_showContextMenu` check (matching the pattern already used in the non-virtualized overlay).

- **Context menu outside hit-testable bounds** (`hyper_selection_overlay.dart`, `virtualized_selection_overlay.dart`): When a selection was near the top of the widget the computed `top` for the `Positioned` menu went negative. `Stack(clipBehavior: Clip.none)` allows visual overflow but Flutter hit-testing is still bounded by the parent — the Copy button was unreachable. Fixed by clamping the top offset: `.clamp(0.0, double.infinity)`.

- **Scroll vs. text-selection conflict** (`render_hyper_box.dart`): `handleEvent(PointerMoveEvent)` bypassed the gesture arena and fired on every pointer move, creating accidental selections during scrolling. Removed raw-event selection tracking and moved selection initiation to a `LongPressGestureRecognizer` at the widget layer — this correctly competes with the parent scroll view's `VerticalDragGestureRecognizer`, so a quick swipe scrolls while a 500 ms hold begins a text selection (matching iOS/Android native behaviour).

- **Virtualized copy menu never appeared** (`virtualized_selection_overlay.dart`): Per-chunk `RenderHyperBox._selection` was set by the old pointer-event tracking, but `VirtualizedSelectionController` (cross-chunk selection) was never populated, so `hasSelection` remained `false` and the menu was never shown. Fixed by routing the long-press start through `VirtualizedSelectionController.startSelection()`.

- **Selection Escape key fix** (`hyper_selection_overlay.dart`): `Escape` key failed to clear selection because the internal `FocusNode` wasn't reliably focused after selection was established. Fixed by calling `_focusNode.requestFocus()` inside `startSelectionAt`.

- **`const` lint fix** (`hyper_render_widget.dart`): `HyperPluginBuildContext` instantiation changed to `const` to silence `prefer_const_constructors`.

---

## [1.1.4] - 2026-03-28

### 🐛 Bug Fixes

- **`display:none` not respected in renderer** (`render_hyper_box_layout.dart`): Added early-return guard in `_tokenizeNode` — elements with `display:none` no longer produce any layout fragments and are correctly hidden. Previously, elements styled with `display:none` (e.g. Wikipedia `[edit]` section links) were still rendered.

- **`<hr>` rendered as line break** (`html_adapter.dart`): `<hr>` now correctly returns a styled `BlockNode` with a top border (`borderColor: #CCCCCC, borderWidth: 1px`), matching browser behavior. Previously it was incorrectly treated identically to `<br>`.

- **Whitespace-only space nodes dropped between inline elements** (`html_adapter.dart`): Text nodes consisting only of horizontal spaces (e.g. `" "` between `<b>text</b> <i>more</i>`) were being silently dropped by `.trim().isEmpty`, causing missing word-separating spaces. Fixed to only drop nodes that contain newlines (structural indentation whitespace), not pure-space nodes.

- **`TextPainter` cache hash collision** (`render_hyper_box.dart`): The `_LruCache<int, TextPainter>` key was computed with `Object.hash()` which can collide for large documents with many distinct text styles, leading to wrong text metrics and subtle layout glitches. Replaced with a new `_TextPainterKey` class using full value equality over all 9 style fields.

---

## [1.0.0] - 2026-03-01
First stable release. Core features, plugin architecture, and cross-platform support are production-ready.