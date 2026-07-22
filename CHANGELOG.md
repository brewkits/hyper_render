# Changelog

## [Unreleased]

### ⚠️ Behavior Change — text now scales with system accessibility settings

- **Rendered text now honours the device's accessibility text-scaling setting** (WCAG 2.1 AA §1.4.4, "Resize Text"). Previously HyperRender ignored `MediaQuery.textScaler` entirely — a paragraph rendered at the same pixel size regardless of the user's "large text" OS setting, unlike every Flutter `Text` widget. It now reads `MediaQuery.textScalerOf(context)` and applies it to every measured/painted text fragment. **This means existing content will re-render larger for users who have increased their system font size** — the correct, accessible behavior, and consistent with Flutter's `Text`/`RichText`. To opt a specific viewer out (fixed-size rendering), pass `HyperRenderWidget(textScaler: TextScaler.noScaling)` or wrap it in a `MediaQuery` with `TextScaler.noScaling`. Found by cross-referencing flutter_html issue #308.

### ✨ New CSS Features

- **`text-align` now executes for paragraph text** (center / right / justify). Previously `text-align` only applied to widget-tier content (table cells, flex) — plain `<p>`/`<div>` text painted on the canvas ignored it and always left-aligned, despite the docs claiming support. Selection and hit-testing follow the aligned position correctly. **`justify`** distributes free space across each line's inter-word gaps (widening spaces via word-spacing) so every line but the last reaches the right edge; the trailing wrap-space is excluded so the final glyph lands exactly at the edge. A box-level RTL tree (`textDirection: rtl`) now honours an explicit `text-align` (an unset RTL paragraph still right-packs); `justify` in RTL keeps the start edge for now.
- **`text-indent` now executes** — indents the first line of a block (px/em/rem/pt; inherits). It previously had no effect at all despite being listed as supported.
- **`max-width` now constrains a block's content width** — text wraps inside the `max-width` rather than the full container width.
- **`min-width` now executes** — raises a block's content width, and wins over `max-width` per CSS. Previously parsed but ignored.
- **Percentage `width` / `max-width` / `text-indent`** now resolve against the containing block's content width at layout time (e.g. `width: 50%`, `max-width: 25%`, `text-indent: 10%`). Nested percentages resolve against the parent, not the viewport. `%` height is still unsupported (needs a deferred-height model — see LIMITATIONS.md).
- **`border-collapse: separate` + `border-spacing` now execute on tables.** Previously the table renderer conflated the inter-cell gap and the border line thickness into a single value and never read `border-collapse`/`border-spacing` from CSS. The gap is now a distinct quantity: `separate` mode reserves a `border-spacing` gap (UA-default 2px) between cells and around the table edge, and paints a per-cell outline instead of merged grid bars. The default remains `collapse` (deviating from the CSS initial value `separate`) to preserve the existing grid rendering byte-for-byte; `border-spacing` has no effect without `border-collapse: separate`. Single spacing value and one shared border width (per-cell differing widths not applied) — see LIMITATIONS.md. **Minor visible change**: a table that explicitly set `border-collapse: separate` previously fell back to grid bars (the property wasn't parsed); it now renders separated cells. This affects only content that opted into `separate` — the default and all `collapse` tables are unchanged.
- **Docs correction**: `CSS_PROPERTIES_MATRIX.md` previously over-claimed several properties as supported (`text-align`/`text-indent` didn't execute, `min-width` wasn't implemented) and under-claimed others (`border-spacing` marked "Not implemented" after it shipped). The matrix now reflects what actually executes, and a new `docs_matrix_sync_test.dart` fails CI if an execution-verified property is downgraded or a structurally-unsupported one is marked fully supported.
- **`animation-play-state`**: `running` / `paused` now parsed (longhand and inside the `animation` shorthand) and executed. A paused animation holds its current frame; flipping back to `running` resumes from that frame — mid-flight for finite and infinite (`repeat()`) animations alike. When paused before the initial `animation-delay` elapses, the delay countdown restarts on resume. Exposed as `ComputedStyle.animationPlayState` (`HyperAnimationPlayState`) and `HyperAnimatedWidget.paused`.
- **Canvas-tier block animation**: `animation-name` now executes on plain paragraphs/divs painted directly by `RenderHyperBox`'s canvas, not just widget-tier content (flex/grid containers, plugins, atomic elements). A `<div style="animation: fade 1s ease infinite">` now actually animates regardless of which render tier its content uses. Driven by a `SchedulerBinding` frame loop (no `TickerProvider`, matching the existing image-loading shimmer's architecture) that stops scheduling once nothing is running. Respects `animation-play-state` — a paused block holds its frame on the canvas exactly like the widget tier. `opacity` composites a block's decoration and text together in one `saveLayer` (fading the result once) instead of fading each independently, which would otherwise double-blend a block's own background showing through its own text; that layer's clip bounds float with the block's transform rather than being pinned to its pre-transform rect, so `opacity` and `transform` combine correctly instead of clipping a translated/scaled block to its original position. Scope: a block's own decoration + its own text/ruby fragments only; see LIMITATIONS.md for what does not yet compose (nested animated blocks, list markers, floats, inline decorations).

### 🔒 Security

- **Root `HtmlAdapter` gained the URL-safety gate it was missing** — the adapter `HyperViewer` actually uses (`lib/src/parser/html/html_adapter.dart`) previously resolved `<a href>`/`<img src>` without checking the scheme, unlike the `hyper_render_html`, Markdown, and Delta adapters. A caller using `HtmlAdapter` directly, or with `sanitize:false`, could let `javascript:`/`file:`/`data:` reach link-tap and image-loading. Now routed through `UrlSafety.isSafe` (unsafe hrefs → `#`, unsafe img src → empty), matching the other adapters as defense-in-depth.

### 🐛 Bug Fixes

- **Animation iteration counter leaked across rebuilds**: when `HyperAnimatedWidget` rebuilt its controller (animation name, duration, curve, or keyframes changed), the internal iteration counter kept its old value, so the new animation could stop after fewer iterations than its `animation-iteration-count`. The counter now resets on every controller rebuild.
- **`line-height` in absolute units used the wrong reference font-size**: `h2 { font-size: 20px; line-height: 3px }` divided the 3px by the *parent's* font-size (e.g. the default 16px) instead of the element's own 20px, producing a visibly wrong line-height whenever `font-size` and a length-based `line-height` were set on the same element — a very common CSS pattern. Found while auditing flutter_html's issue tracker for bugs (#1367) also worth checking against HyperRender's independent implementation.
- **`<p>&nbsp;</p>` collapsed to zero height**: a text run made up solely of `&nbsp;` (U+00A0) was misclassified as insignificant/collapsible whitespace and dropped, because `String.trim()` and RegExp's `\s` both also match U+00A0 — unlike CSS, which explicitly does not. A paragraph holding only a non-breaking space now renders with the same height as any other text paragraph. New shared `isCssWhitespaceOnly`/`cssWhitespaceRun` helpers in `hyper_render_core` replace the ad-hoc `.trim().isEmpty`/`\s+` checks in both `HtmlAdapter` implementations and the layout tokenizer. Also found via flutter_html's issue tracker (#1439).
- **Flutter Web crash parsing CSS `transform` keyframes**: `@keyframes` with a `translate()`/`scale()` step used a negative-lookbehind regex (`(?<![XY])translate\(…`) that throws `Invalid regular expression` on Flutter Web and older Safari, crashing the whole widget. The lookbehind was redundant (`translate\(` already excludes `translateX(`/`translateY(`) and has been removed — transform animations now parse identically but without the web-incompatible construct. Found via flutter_html #1504/#1314.
- **`<ol start="N">` ignored**: ordered lists always numbered from 1, disregarding the HTML `start` attribute. `<ol start="5">` now numbers 5, 6, 7…; a missing or malformed value still defaults to 1, and sibling lists keep independent counters. Found via flutter_html #1480.
- **Malformed CSS with non-finite values crashed layout**: an overflowing length literal such as `1e999px` parses to `Infinity` (Dart's `double.tryParse` accepts it), which propagated into margins/font-sizes/box constraints and threw a `BoxConstraints` assertion during layout — malformed or hostile CSS (common in email HTML) could crash the app. Length/size/font-size parsing now rejects non-finite results (including overflow after unit scaling), so the declaration is ignored as CSS requires. Found via flutter_widget_from_html #34.
- **`display: none` was parsed but not executed on the canvas path**: hidden elements — and hidden `<tr>`/`<td>` in tables — still rendered, took up space, and were selectable. Content commonly hidden with `display:none` (email pre-headers, conditional CMS blocks, tracking wrappers) leaked into the visible/selectable output. Now removed from the box tree at tokenization and from the table grid. Found via flutter_widget_from_html #488.
- **First block with padding but no top margin lost its padding**: the block-start fragment that carries a block's padding was elided for a first no-margin block (only width constraints re-triggered it). A first `<div style="padding:…">` silently rendered flush; `<p>` was unaffected only because it has a default top margin. Caught by the new CSS-execution guard test. The emission guard now also fires on non-zero padding.
- **`<a>` without `href` was styled as a link**: a placeholder anchor like `<a name="x">Text</a>` got the blue link colour and underline. Browsers only style `a[href]`; HyperRender now matches, leaving href-less anchors as plain text. Found via flutter_widget_from_html #676.
- **Bootstrap 4/5 logical float classes split away from their content in large documents**: the root `HtmlAdapter` (the one `HyperViewer` runs) recognised `float-left`/`float-right` but not `float-start`/`float-end`, so a block floated with the Bootstrap 4/5 utilities could be chunked into a different virtualized section than the text meant to wrap around it. Both adapters now share one superset heuristic (Bootstrap `pull-*`/`float-*`/`float-start`/`float-end`, Tailwind, WordPress `align*`, legacy `float` attribute + inline `float:` style).

### ⚠️ Potentially breaking — three transitive dependencies removed

- **`hyper_render` no longer depends on `hyper_render_html`, `hyper_render_markdown` or `hyper_render_highlight`.** These were declared but never imported: the root package implements its own HTML/Markdown/highlight parsing directly on `html`/`csslib`/`markdown`/`flutter_highlight`, so the three packages were pure install weight for every consumer.

  **Rendering behaviour is completely unchanged** — `HyperViewer` never used those packages. Nothing breaks if you only import `package:hyper_render/hyper_render.dart`.

  **What can break:** code that imports `package:hyper_render_html/...` (or `_markdown` / `_highlight`) while declaring only `hyper_render` in its pubspec. That used to resolve transitively and will now fail to resolve. Fix by depending on the package explicitly — which is what pub expects for any package you import directly:

  ```yaml
  dependencies:
    hyper_render: ^1.6.0
    hyper_render_html: ^1.5.1   # add this if you import it directly
  ```

  All three remain separately published and fully supported for standalone use.

### ♻️ Internal

- **Deprecation annotations that actually warn**: `TableParentData` carried only a `/// @deprecated` doc comment, which the analyzer ignores — callers got no warning for a class the renderer never uses. It now has a real `@Deprecated(...)` annotation, as do the ignored `SmartTableWrapper.minScaleFactor` / `minColumnWidth` parameters. All three are slated for removal in v2.0; nothing is removed in this release.
- **Removed a stale tracked `pubspec.yaml.backup`** (pinned at v1.4.0 while the real pubspec was v1.5.0) and fixed the publish script's restore instruction, which told you to `cp` from that file — following it would have silently downgraded the version. It now says `git checkout pubspec.yaml`.
- **Documented the root ↔ sub-package parser duplication** in LIMITATIONS.md, including which copy `HyperViewer` actually runs, so a parser fix isn't applied to only one of them (this has already caused two bugs).
- **CI: the weekly benchmark job now alerts on failure** — a scheduled-run failure opens (or comments on) a tracking issue instead of sitting as an unwatched red X, so a silent breakage like the month-long `mkdir` typo surfaces immediately.

- Timing-curve resolution, keyframe-name lookup, and the translate/scale/rotate transform matrix used to build a CSS animation frame are now shared top-level helpers (`curveFromHyperTiming`, `resolveHyperKeyframes`, `matrix4FromHyperKeyframe` in `animation_controller.dart`) instead of being duplicated between the widget-tier and canvas-tier animation code.

## [1.5.0] - 2026-07-05

### ✨ New CSS Features

- **`cubic-bezier()` and `steps()` timing functions**: `transition` and `animation`/`animation-timing-function` now accept `cubic-bezier(x1, y1, x2, y2)` (mapped to Flutter's `Cubic`), `steps(n, start|end)`, and the `step-start`/`step-end` keywords (via the new `HyperStepsCurve`). Parameters are carried on `HyperTimingParams` (`HyperCubicBezierParams` / `HyperStepsParams`) so the existing enum-based API stays source-compatible. Shorthand parsing is now paren-aware, so `cubic-bezier(0.4, 0, 0.2, 1)` is no longer split on its inner commas. `x` control points are clamped to `[0, 1]` per spec.
- **Animatable `color` / `background-color`**: `@keyframes` and `transition` can now animate text and background colors. `HyperKeyframe` gained `color`/`backgroundColor` fields interpolated with `Color.lerp`; `HyperAnimatedWidget` applies them via `DefaultTextStyle.merge` + `ColoredBox`, and `HyperTransitionWidget` animates them via `AnimatedDefaultTextStyle` + `AnimatedContainer`. Colors are parsed through the shared `StyleResolver.parseCssColor` so keyframe colors use the exact same grammar (`#hex`, `rgb()`, `rgba()`, named) as the rest of the engine.

### 🩺 Diagnostics

- **Debug-mode memory-pressure metrics**: on `didHaveMemoryPressure`, HyperViewer now records a `HyperMemoryMetrics` snapshot (bytes freed from the image cache, images evicted, `RenderHyperBox` instances cleared, pending image loads dropped) to `HyperMemoryDebug` in debug builds. Zero cost in release (guarded by `kDebugMode`; the notifier stays null). Added `LazyImageQueue.pendingCount`.

### 🐛 Bug Fixes

- **Issue #12 — zero-width `BorderSide` + `border-radius` assertion**: a CSS element with `border-radius` and an uneven border (e.g. `border-left: 5px solid` with the other sides `0px`) produced `BorderSide(width: 0, style: solid)`, which Flutter's `BoxDecoration` rejects as a hairline border when the radius is non-zero. Zero-width sides now map to `BorderSide.none` via a shared `cssBorderFromStyle` helper, fixing both the flex-child path (`hyper_render_widget.dart`) and the flex-container path (`flex_container_widget.dart`); the latter also now honours `border-style: none`.
- **Color parsing hardened**: `StyleResolver.parseCssColor` now returns `null` instead of throwing `FormatException` on malformed hex (`#zzz`) or out-of-`int64` `rgb()`/`rgba()` channel values. This matters because color parsing now runs on arbitrary `@keyframes` values, where a hostile or typo'd color could otherwise crash a render.

## [1.4.0] - 2026-06-24

### ✨ New CSS Features

- **`aspect-ratio`**: `W/H` ratio syntax (`16/9`) and bare-number syntax (`2.5`) parsed and applied to `<img>`/`<video>` sizing — overrides the image's intrinsic ratio when only one dimension (or neither) is specified in CSS/HTML.
- **`transition` execution**: CSS `transition` is now actually animated, not just parsed. New `HyperTransitionWidget` detects `opacity`/`transform` changes across rebuilds and animates them over the declared duration and timing function via `AnimatedOpacity`/`AnimatedContainer`. Wired into the render pipeline through `_maybeAnimate` in `hyper_render_widget.dart`.
- **`animation-iteration-count: infinite`**: now loops via `AnimationController.repeat()` instead of a one-shot `forward()`. Added a dedicated `alternate` flag to `HyperAnimatedWidget` so `animation-direction: alternate` / `alternate-reverse` no longer gets conflated with plain `reverse`.
- **Cross-Chunk Float Carryover — paint completion**: the previously-unused `imagePixelOffset` on `FloatCarryover` is now consumed at paint time. A tall floated image that overhangs a virtualized section boundary continues painting from the correct offset in the next chunk instead of the gap being left blank.
- **~25 previously-silent CSS properties now resolved**: `white-space`, `word-spacing`, `text-transform`, `text-decoration-color`, `min/max-width/height`, `overflow`/`overflow-x`/`overflow-y`, `border-top`/`border-right`/`border-bottom`/`border-color`/`border-width`, `animation` shorthand and all `animation-*` sub-properties, `transition`, `aspect-ratio`. These had `ComputedStyle` fields but no resolver case, so values were silently dropped.

### 🐛 Bug Fixes

- **`rem` units silently failed** — `_parseLength` had no `rem` branch; `'2rem'.endsWith('em')` matched the `em` branch instead, producing an unparseable `'2r'`. Added the missing `rem` case ahead of `em`.
- **`text-decoration` incorrectly marked as inherited** — not an inheritable CSS property per spec; child elements were wrongly picking up a parent's underline/strikethrough. Removed from `inheritFrom()`; added correct inheritance of `text-transform` instead.
- **Linear-gradient diagonal corners wrong** — for `to top right` / `to bottom right` / `to top left` / `to bottom left`, only `begin` was corrected, leaving `end` on the wrong single axis.
- **`filter` only composed the first two entries** — multiple chained filters (e.g. `blur() brightness() contrast()`) silently dropped everything past the second; now folds over the full list.
- **`border: none` left a 1px border** — shorthand parsing didn't zero the width when style was `none`.
- **Division-by-zero in `line-height`** — unitless line-height against a zero/null parent font size could divide by zero.
- **Float layout list-spread bug** — `performLayout` iterated `[..._leftFloats, ..._rightFloats]`, allocating a new list every line; replaced with two direct loops.
- **`HyperTextSelection` missing `operator==`** — every selection update looked "changed" even when identical, causing redundant repaints.
- **`setGlobalTextCacheSize` leaked old `TextPainter`s** on resize — old cache was dropped without disposal.
- **Delta adapter `indent` operator-precedence bug** — `((attributes['indent'] as int?) ?? 0 + 1)` added 1 to the default before the null-check applied; also hardened the `int` cast to `num.toInt()` against JSON-decoded doubles.
- **Delta underline+strikethrough mutually exclusive** — applying both attributes silently dropped underline; now combined via `TextDecoration.combine`.
- **HTML adapter shared mutable default styles** — `_defaultStyles[tagName]` returned a shared `ComputedStyle` instance reused (and mutated) across unrelated nodes; now `.copyWith()`'d per node.
- **Markdown adapter didn't normalize `\r\n`/`\r`** line endings before splitting, breaking line-based heuristics on Windows-authored content.
- **Markdown adapter double-applied syntaxes** when both `extensionSet` and explicit `blockSyntaxes`/`inlineSyntaxes` were supplied.
- **`_prebuiltDocument` fast-path left stale cached state** (`_docKeyframes`, `_cachedEffectiveConfig`, `_sectionHashes`, page count, section boxes) when switching to a pre-parsed AST document.
- **pub.dev pana INFO**: suppressed the `cacheExtent` deprecation hint (`scrollCacheExtent` isn't available on the SDK floor this package supports) with `// ignore: deprecated_member_use`, consistent with the existing SDK-version-gap pattern.

### 📝 Documentation

- `doc/LIMITATIONS.md`: removed stale "not parsed" entries for `background-position`/`background-repeat`/`list-style-*` (shipped in v1.3.1); added v1.4.0 entries; corrected the async-parsing description (`Future.microtask`, not `compute()` isolate).
- `doc/ROADMAP.md`: marked Cross-Chunk Float Carryover paint offset, CSS `transition` execution, `animation-iteration-count: infinite`, and `aspect-ratio` as completed.

## [1.3.4] - 2026-06-04

### 🔧 Fixes & Optimizations
- **Static Analysis Compliance**: Suppressed deprecated `SizeTransition.axisAlignment` lints with `// ignore: deprecated_member_use` to maintain backwards compatibility with older Flutter SDKs (>=3.10) while securing 160/160 points on pub.dev.
- **Dependency Widening**: Widened `share_plus` dependency constraint to `^12.0.2 || ^13.0.0` in `hyper_render_clipboard` and root packages to allow compatibility with latest stable release.

## [1.3.3] - 2026-06-04

### 🚀 Production Readiness
- **Publishing Candidate**: Comprehensive code cleanup, removal of unnecessary TODOs, and linting fixes.
- **Test Coverage Verified**: Passed 973 test cases covering unit, integration, system, performance, stress, and security testing.
- **Dependency Resolution**: Ensured all internal sub-packages (`hyper_render_math`, etc.) are fully resolved and analyzed.

### ✨ New CSS Properties

- **`object-fit`**: `cover`, `contain`, `fill`, `none`, `scale-down` — applies to `<img>` elements. Controls how the image content is resized to fit its layout box. Previously, images incorrectly fell through to the `background-size` mapping; `object-fit` now takes priority as the semantically correct property for replaced elements.

### ✨ New Features

- **`onMemoryPressure` callback**: `HyperViewer` now exposes an optional `VoidCallback? onMemoryPressure` parameter (available on all constructors: default, `.delta`, `.markdown`, `.fromNode`). Invoked after HyperRender clears its internal TextPainter, image, and painting caches in response to `didHaveMemoryPressure`. Enables host apps to release their own resources (video players, download queues, custom caches) in the same memory-pressure cycle.

### 🔧 Improvements

- **Float carryover `imagePixelOffset`**: `FloatCarryover` now carries an `imagePixelOffset` field computed from the originating section's layout. When a tall float image overhangs a virtualized section boundary, the offset records how many pixels of the image were already painted — enabling future visual rendering of the remaining portion in the next section without repeating the top. The `_onFloatCarryover` comparison in `HyperViewer` now includes `imagePixelOffset` to avoid missing updates.

### 📝 Documentation

- **ROADMAP corrected**: `list-style-type` and `list-style-position` were marked as incomplete (`[ ]`) despite being fully shipped in v1.3.1. Now correctly marked as `[x]`. `object-fit` moved from Backlog to Completed.

---

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

### Second-Pass Senior Review (2026-05-18 → 2026-05-19)

A second multi-disciplinary review (PM/BA/SA/principal mobile) surfaced a further batch of issues addressed in this same release. Highlights:

#### Security

- **`UrlSafety` consolidated in `hyper_render_core/util/url_safety.dart`** — root `HtmlSanitizer.isSafeUrl` and the `hyper_render_markdown` sub-package's URL gate previously had independent copies that drifted: the sub-package missed `file:`/`mhtml:`/`about:`. Both now delegate to the shared helper; no future drift is possible.
- **`HtmlAdapter` defence-in-depth URL gate** — `<img src>` and `<a href>` are now routed through `UrlSafety.isSafe` even when the upstream `HtmlSanitizer` is bypassed (callers that invoke `HtmlAdapter().parse()` directly or render with `sanitize: false`). Blocked `href` collapses to `#`; blocked `src` collapses to `''`.
- **`hyper_render_clipboard` filename hardening (path traversal)** — `_getFilenameFromUrl` already stripped path separators from URL-decoded filenames, but `saveImageBytes(filename:)` and `shareImageBytes(filename:)` concatenated caller-supplied strings raw. Every save/share path now runs through a single `_sanitiseFilename` helper.
- **Markdown inline HTML pre-sanitised** — when `HyperViewer.markdown(sanitize: true)` (default) is used with `enableInlineHtml: true` (default), raw `<script>`/`<style>`/`<iframe>` blocks are now stripped via `HtmlSanitizer` before reaching the markdown parser, so they can no longer flash as visible text or become a self-rendering plugin's XSS surface.

#### Layout & Selection

- **Unbounded-width crash fixed** — `RenderHyperBox.performLayout` and `_computeHeightForWidth` clamp `_maxWidth` to a finite fallback when the constraint is `double.infinity` (Row without Expanded, horizontal `SingleChildScrollView`). Before this, `_FlexFragment.layout` propagated infinity into a `BoxConstraints(minWidth: ∞)` and tripped Flutter's `minWidth < double.infinity` assertion.
- **`text-overflow: ellipsis` no longer leaks hidden text via copy** — `Fragment.ellipsisVisibleLength` tracks how many leading characters survive each truncation pass; `getSelectedText` clamps the visible range against it and skips fully-suppressed fragments. State is reset at the top of every `_performLineLayout` so a wider re-layout un-hides previously truncated text.
- **Selection-drag hit-test made lenient** — `_lineIndexAt` accepts a `clampOutOfBounds` flag (`true` for drag, `false` for tap). When a selection handle drags past the first/last line by a pixel, the index now snaps to the nearest line instead of returning `-1` and freezing.
- **Dead-code removal** — `_characterToFragment` / `_fragmentRanges` fields in `RenderHyperBox` were populated each layout but never read; deleted along with their `clear()` and populate loops.
- **Table cell block-content fallback** — when `cellContentBuilder` is `null` and a cell contains `<div>`/`<p>` children, `_buildCellContent` now renders the inline run plus each block child via a default `Column`/`Text` fallback instead of dropping the content. (Previously only `HyperRenderWidget` callers were safe.)
- **Table grid total-cell cap** — added `_kMaxTotalCells = 100 000`. A pathological `<table>` whose `rowCount × columnCount` exceeds the cap now renders a visible "Table too large to render" placeholder instead of allocating an 8 MB `null` grid on the UI thread.
- **`HyperAnimatedWidget` controller lifecycle hardened** — switched from `SingleTickerProviderStateMixin` to `TickerProviderStateMixin` (the previous mixin asserted on the second `createTicker()` when `didUpdateWidget` recreated the controller after a prop change). Start delay now uses a retained `Timer` that is cancelled on `didUpdateWidget` / `dispose`, eliminating duplicate `forward()` calls in fast-rebuild scenarios (live editor typing).

#### Performance

- **`HtmlAdapter.extractCss` regex fast-path** — for inputs ≥ 32 KB or with no `<style` tag at all (the common Markdown/Delta case), `extractCss` now skips the full html5lib parse on the UI thread and uses a focused regex. Saves 50–300 ms on a 200 KB document on a mid-range Android.

#### Cross-package Polish

- **`MarkdownContentParser` renamed to `DefaultMarkdownParser`** — aligns with `DefaultHtmlParser` / `DefaultCssParser`. The old name remains as a `@Deprecated` typedef so existing callers compile; new code should use the new name.
- **`hyper_render_devtools` now has tests + `dev_dependencies` block** — `UdtSerializer` round-trip + truncation cap + `register()` idempotency. Previously the package shipped zero tests.
- **`hyper_render_math` pubspec description normalised** — replaced the YAML folded-scalar (`>`) form with a plain string for consistency with the other six packages.
- **`pubspec_publish_ready.yaml` and `scripts/prepare_publish.sh` version sync** — both now pin `^1.3.2`, eliminating the previous 1.3.1/1.3.2 mismatch that would have failed `dart pub publish --dry-run`.

#### Tests

71 new tests added across 11 files covering every fix above: URL safety scheme blocklist (core), HTML adapter URL gate, CSS parser edge cases, markdown GFM (tables/task-lists/autolinks/code-fence/heading), highlight edge cases (malformed source, 5 KB load, every theme), clipboard filename sanitisation, UDT serializer shape + truncation, animation controller race / dispose, table cell fallback + total-cell cap, extractCss perf, ellipsis copy + selection clamp regressions. Full suite: 1764 passing, 0 failing.

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