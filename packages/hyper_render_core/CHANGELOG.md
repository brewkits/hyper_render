# Changelog — hyper_render_core

## 1.14.0

- **`box-sizing`:** new `ComputedStyle.boxSizing` / `HyperBoxSizing`. `border-box` applies to `width` / `min-width` / `max-width`, including `%`, on in-flow blocks.
- **`position: relative`:** `top` / `right` / `bottom` / `left` (lengths) move blocks, inline spans and flex/grid items without affecting layout. New `ComputedStyle.insetTop` / `insetRight` / `insetBottom` / `insetLeft` and `relativeOffset()`. Hit-testing and selection follow; moved content paints above normal content, clipped to the render box.
- **Horizontal block margins:** `margin-left`, `margin-right` and `margin: 0 auto` now apply to in-flow blocks. New `ComputedStyle.marginLeftAuto` / `marginRightAuto`.
- **Behavior changes:** a block's background and border follow its `width`; `min-width: %` applies on blocks; a first block styled only with a background or border paints it; canvas gradients paint; a `<details>` toggle no longer leaves an old background behind. Floats sit inside their containing block, `<pre>` fits its parent's padding, RTL blocks with a `width` anchor right, `margin` `em` uses the element's font size, and inline `!important` no longer invalidates a value.

## 1.13.0

- **`RenderHyperBox.getBoxesForCharRange(charStart, charEnd)`** — bounding boxes for a character range, for app-drawn highlights (search hits, annotations, read-aloud). Offsets are the selection/IME character space, local to this `RenderHyperBox`: in virtualized / `auto` mode (>10k chars) each chunk has its own box and offsets restart at 0. Glyph x-bounds come from `TextPainter` (so they follow `textScaler` and justified spacing); y-bounds span the full line. Rects of adjacent words on a line merge, except across an inline atom such as an image. Spaces inside `white-space: pre` / `pre-wrap` / `break-spaces` are kept. By [@DrkXo](https://github.com/DrkXo) ([#26](https://github.com/brewkits/hyper_render/pull/26), follow-up to [#17](https://github.com/brewkits/hyper_render/pull/17)).
- **`RenderHyperBox.debugLineFragments()`** — the fragments as laid out on lines, with the position actually painted, `charStart` / `charEnd`, line index / top / height, ruby text and `ellipsisVisibleLength`. `debugFragments()` reports pre-layout fragments and misses wrapped and truncated pieces.
- **`text-overflow: ellipsis`: the truncated fragment now records how many source characters it shows.** The `ellipsisVisibleLength` was only set on the original fragment, which never reaches a line, so the `…` glyph counted as a source character.
- **Behavior changes:** a selection highlight on truncated text no longer covers the `…` glyph, matching `getSelectedText`; and when not even one character fits before the ellipsis on an empty line, the line now shows `…` instead of nothing.

- **Line-breaking fixes** (rendering changes, found while reviewing [#29](https://github.com/brewkits/hyper_render/pull/29)):
  - **Lines no longer run past the box.** A wrap point was taken from the nearest caret rather than the last one that fits, so a line could overflow by up to half a glyph; every full CJK line did.
  - **RTL paragraphs wrap.** The line breaker read an RTL paragraph from its logical end, putting most of it on line one and then one glyph per line.
  - **`word-break` and `overflow-wrap` are inherited**, as in CSS. Set on a `<p>`, they never reached its text, so `word-break: break-all` had no effect.
  - **A word wider than the line breaks after as many characters as fit** (like Flutter's `Text`), instead of after its first letter, which left a column of one-letter lines.
  - **A word that doesn't fit beside a float moves below it** instead of being split after its first letter.
  - **Spaces at the start and end of a line collapse**, as in CSS. A line after `<p>` + newline, after `<br>`, or after an indented `<dt>` started one space in, and trailing spaces counted toward the width that `text-align: center/right` positions.
- **Line-breaking performance on massive unspaced text blocks** ([#28](https://github.com/brewkits/hyper_render/issues/28), [#29](https://github.com/brewkits/hyper_render/pull/29)):
  - Single-pass native multi-line layout fast path via ICU `computeLineMetrics()` when lines are uniform and free of floats, eliminating UI freezes on long unspaced text.
  - Bounded candidate prefix search in the fallback line breaker loop to prevent quadratic `O(N^2)` HarfBuzz text shaping overhead.
  - Robust loop termination on zero or negative line widths and trailing whitespace margin parity.
  - **Behavior change from the native layout:** CJK text now fills the line after a space between two sentences or runs (as a browser does), where it used to start the next run on a new line, and a first-in-document block with `text-overflow: ellipsis` now truncates instead of wrapping (it emitted no block-start fragment, so the ellipsis state was never entered).
- **`HyperRenderDebugHooks.onTextPainterLayout` / `onLineLayoutTextPainter`** — hook callbacks for counting text shaping and line layout operations in tests and DevTools. By [@DrkXo](https://github.com/DrkXo) ([#29](https://github.com/brewkits/hyper_render/pull/29)).

## 1.12.0

- **`StyleResolver.darkSurface`** (default `false`) — switches the built-in link, `<h6>`, `<code>`, `<pre><code>` and `<mark>` colors to dark-surface variants with at least 4.5:1 contrast on `#121212` ([#23](https://github.com/brewkits/hyper_render/issues/23)). `HyperViewer` sets it whenever its effective default text color is light. Author CSS still wins; an `<a>` without `href` is untouched.

## 1.11.0

- **`StyleResolver.rootColorOverride`** — a host-supplied root color, applied to the document root after the content's own `html` / `:root` / `body` color so an app can override a publisher stylesheet. Element-level colors still win. `HyperViewer(textColor:)` sets it.
- **`StyleResolver.ensureReadableOnOwnBackground`** (default off) — an element with its own opaque background and no color of its own never inherits text under 3:1 contrast against that background; it falls back to dark gray or white. `HyperViewer` enables it whenever it supplies a default text color.
- **Deprecated `HyperRenderTheme` / `HyperRenderThemeData`** — nothing reads them, so they never had any effect. Use `HyperViewer(textColor:)` or the ambient `Theme`.
- **`body { color }` / `html { color }` are honoured** (they never matched before — no node is tagged `body` or `html`). Applied to the document root with browser layering `html` < `:root` < `body`; only `color`, because other body properties would change the root's own box. Behavior change for content that declares one.
- **`:root` matches the document root only** (`node is DocumentNode`). The 1.10.0 check, `parent == null`, also matched every top-level block, so `:root { color }` beat `p { color }` and `:root { font-size: 62.5% }` compounded once more on top-level blocks.
- **Block-tier plugins on custom tags now render.** `<info-box>`, `<x-badge>` and any other tag without a UA display style are built by the HTML adapters as inline nodes, so a registered **block** plugin on them never took the block path: its widget was built, linked to no fragment, laid out at 0×0 and never painted, with "Layout Warning: More child widgets than fragments" in debug. Only tags that are already block (`figure`, `div`) worked. A registered block tag is now treated as a block whatever its node type. Existing tests passed because they hand-built `BlockNode`s or only asserted `findsOneWidget`, which a 0×0 widget satisfies.

## 1.10.0

### 🆕 New

- **`HyperRenderDebugHooks.onFrameTiming`** — reports each `RenderHyperBox` layout and paint duration in microseconds. Paint is canvas recording time, not raster. It only runs in debug mode and only while the hook is set.
- **`HyperRenderDebugHooks.onSelectionChanged`** — reports a renderer's selection range when it changes.
- `RenderHyperBox.debugFragments()` now also includes `globalOffset`, `charLength`, `rubyText` and `rubyHeight`.
- **`StyleResolver.customPropertyOverrides`** and **`HyperRenderDebugHooks.cssVariableOverrides`** — replace a `--custom-property` value wherever it is declared. Powers DevTools live CSS-variable editing.

### 🐛 Fixes

- **`:root` matched every element.** The pseudo-class matcher had no case for it, so it fell through to "unknown → match". `:root { font-size: 125% }` compounded at every nesting level, `:root { --c: … }` reset any descendant override of `--c`, and every element re-applied the whole `:root` block. It now matches only the document root.
- **`url()` and `calc()` in stylesheet rules never resolved** (inline `style=""` worked). csslib drops the function name from `UriTerm` / `CalcTerm` spans, the same quirk as `var()` below. This affects `background-image: url(…)` and `width: calc(…)` in `<style>` / `customCss`.
- **Stylesheet `background` / `background-image` URLs now follow the `<img src>` scheme policy** (`UrlSafety.isSafe`). `<style>` blocks are extracted before HTML sanitization, so `javascript:`, `vbscript:`, `file:`, `data:image/svg` and non-image `data:` URLs are dropped.
- **`var()` substitution is bounded.** A value that expands past 16 KB (e.g. a `--l1: var(--l0) var(--l0) …` chain in untrusted `<style>`) is treated as invalid instead of allocating gigabytes. A declaration that resolves to nothing is ignored rather than applied empty.
- **`HtmlToSpanConverter` collapsed `&nbsp;`.** Its whitespace normalization used Dart's `\s`, which includes U+00A0. It now uses the CSS whitespace set, like the rest of the engine.
- **`FormulaWidget` rendered `x^{2}` as `x^2`.** The braced super/subscript form (the usual LaTeX spelling) now converts to `x²` / `aᵢ`.
- **Custom-property inheritance no longer copies the full map per element.** With 300 `:root` variables, 2000 elements resolved in ~37 ms instead of ~457 ms.
- **`var()` in stylesheet rules never resolved.** `<style>` and `customCss` declarations such as `p { color: var(--brand) }` produced nothing, fallback included, because csslib's `VarUsage` span lacks the `var(` prefix. Only inline `style=""` worked. Documents that relied on `var()` in a stylesheet will now render with those values.
- **Custom properties are now cascaded before `var()` is substituted.** `var()` used to be substituted while declarations were applied, so a `--name` defined by a later, higher-specificity, inline or `!important` declaration on the same element was missed. For example, `p { color: var(--c) } .x { --c: blue }` read the parent's `--c`. The element's final custom properties are now computed first, as in CSS.

## 1.9.0

### 🆕 New

- **`RenderFlexWrap`** — a render object for CSS `display:flex; flex-wrap:wrap` on a horizontal main axis, with `FlexWrapLayout` (the widget) and `FlexWrapItem` (the per-item style carrier). It packs items into lines by base size, distributes each line's free space in proportion to `flex-grow`, clamps to `min-width`/`max-width`, and implements intrinsics, dry layout, painting and hit-testing.
- **`ComputedStyle.minWidthPercent` and `ComputedStyle.flexBasisPercent`** — percentage forms resolved at layout, following the existing `widthPercent`/`maxWidthPercent` pattern.
- **`FlexItemWidget.buildUnflexed()`** — builds an item with `align-self` applied but no `Expanded`/`Flexible` wrapper, for parents that cannot accept flex parent data.

### 🐛 Fixes

- **`flex-wrap: wrap` containers emitted `Expanded`/`Flexible` under Flutter's `Wrap`**, which provides `WrapParentData` — Flutter threw *"Incorrect use of ParentDataWidget"* and cascaded into `RenderBox was not laid out`. Horizontal wrapping flex no longer goes through `Wrap` at all; `flex-direction: column` + wrap still does, with all flex parent data stripped.
- **Wrapping flex could not be nested inside another flex container.** CSS's `align-items` default is `stretch`, which puts an `IntrinsicHeight` above every nested flex container — and the previous `LayoutBuilder`-based implementation could not answer intrinsic queries, so those shapes died with `LayoutBuilder does not support returning intrinsic dimensions` plus ~34 cascading errors. `RenderFlexWrap` answers them, and introduces no `IntrinsicHeight` of its own.
- **`flex-basis`, `min-width` and `max-width` were parsed but never applied to flex items.** In a 500px container, `flex: 0 0 50%` produced 32.5px instead of 250px and a bare `min-width: 300px` produced 32.5px instead of 300px. `min-width` now accepts `%`, `flex-basis` accepts `%` and `auto`, and the `flex: 1` / `flex: 1 1` shorthands correctly imply CSS's `0%` basis rather than leaving it unset.
- **`align-items: baseline` asserted on every flex container** — `CrossAxisAlignment.baseline` was passed without a `textBaseline`. Both the wrap and nowrap paths now pass `TextBaseline.alphabetic`.
- **An `&nbsp;`-only flex item was dropped entirely.** `_buildFlexChild` used `String.trim().isEmpty`, but Dart follows Unicode (U+00A0 is whitespace) while CSS Text Level 3 excludes it. It now uses `isCssWhitespaceOnly` and trims only CSS whitespace, so an edge `&nbsp;` survives.

## 1.8.0

- **AI & LLM Streaming Architecture Primitives**:
  - `HyperStreamingController`: High-performance streaming controller for real-time token batching with frame-aligned throttling and lifecycle management (`idle`, `streaming`, `completed`, `error`).
  - `StreamSyntaxNormalizer`: Transient auto-repair engine for unclosed code fences (```), inline code (`), asterisks (**, *), strikethroughs (~~), tables (|), and HTML tags (<tag).
  - `HyperTypingCaret`: Pulsing typing cursor widget supporting `bar`, `block`, `underscore`, `dot`, and `custom` builders.

## 1.7.0

### ✨ New

- **`HyperSelectionOverlay.imageLoader`**: the overlay now forwards an optional
  `HyperImageLoader` to the `HyperRenderWidget` it wraps. `HyperRenderWidget`
  and `RenderHyperBox` already accepted one; the overlay did not, and it is the
  *default* path for a selectable viewer — so a custom loader set upstream was
  silently dropped for every selectable render mode. Additive: omitting it keeps
  the built-in `NetworkImage`-based loader.

- **`HyperPluginRegistry.registeredTags`**: the set of every tag any registered
  plugin handles. A sanitizing host needs it to avoid stripping the very tags a
  plugin was registered for — `hyper_render` 1.7.0 uses it for exactly that.

These are the only changes since 1.6.0. They exist so `hyper_render` 1.7.0 can
expose `HyperViewer.imageLoader` across all render modes, and stop the default
sanitizer from erasing registered plugin tags.

## 1.6.0

### ⚠️ Behavior Change — text scaling (WCAG 1.4.4)
- `RenderHyperBox` and `RenderRubyText` now accept a `TextScaler` and apply it to every `TextPainter` (measurement + paint), so rendered text honours the device's accessibility text-scaling setting. Previously all text was measured at `TextScaler.noScaling`. `HyperRenderWidget` gained an optional `textScaler` param (null → `MediaQuery.textScalerOf(context)`); `_TextPainterKey` now includes the scaler so the process-global painter cache doesn't collide across scales. The `RenderHyperBox.textScaler` setter routes through `_invalidateLayout()` (not a bare `markNeedsLayout()`) so a scaler-only change actually re-measures rather than being skipped by the fragment-version fast-path. **Existing content re-renders larger when the user's system font size is increased** — pass `TextScaler.noScaling` to opt out.

### ✨ New CSS Features
- **`text-align` executes on the canvas path**: `_positionFragments` now shifts each line by the free space according to the block's inherited `text-align` (LTR center/right). Because selection/hit-testing read `fragment.offset` directly, they stay correct with no extra work. Previously text-align only reached widget-tier `Text` widgets. RTL unchanged (right-packed).
- **RTL `text-align` override**: a box-level RTL tree (`textDirection: rtl`) now honours an EXPLICIT `text-align` (left/center) instead of always right-packing; an unset RTL paragraph still right-packs (`start`). The explicit flag is read from the block ancestor via `_lineTextAlignIsExplicit` (the line's text fragment only inherited the value, so its own flag is false).
- **`text-align: justify`**: distributes free space across a line's internal word gaps via a per-fragment `Fragment.justifyWordSpacing` (folded into the effective style by `_effectiveFragmentStyle`, used by paint, selection and the position pass so glyphs, hit boxes and offsets agree). Skipped on the last line of a block and any line ending in `<br>` (CSS). The trailing wrap-space is excluded from the gap count and its width added back, so the final glyph reaches the edge exactly. Recomputed from scratch each layout pass (reset to 0) so it never compounds.
- **`text-indent`**: new `ComputedStyle.textIndent` (+ resolver case + inheritance in `_applyInheritance`), applied to the first line of each block in `_positionFragments` via a nearest-block-ancestor lookup.
- **Block width constraints — `width`, `max-width`, `min-width`, incl. `%`**: all resolved at block-start in `_performLineLayout` via the per-block padding stack (a single unified block that picks a target content width then inflates the right inset). `min-width` wins over `max-width` per CSS. Percentages resolve against the containing block's content width (`_maxWidth − parentLeftInset − parentRightInset`), so nested `%` nests correctly. New `ComputedStyle.widthPercent`/`maxWidthPercent`/`textIndentPercent` fields (threaded through constructor/copyWith/inheritance; `textIndentPercent` inherits, width ones don't). The block-start-fragment emission guard now fires for ANY width constraint, not just absolute `max-width`. `%` height remains unsupported.
- **`animation-play-state`**: `running` / `paused` parsed (longhand + `animation` shorthand) and executed. New `HyperAnimationPlayState` enum, `ComputedStyle.animationPlayState` field, and `HyperAnimatedWidget.paused` flag. Paused animations hold their current frame and resume from it; pausing before the initial delay restarts the delay countdown on resume.
- **Canvas-tier block animation**: `RenderHyperBox` now executes `animation-name` for content it paints directly on its own `Canvas` (plain block-level paragraphs/divs), not just widget-tier content. New `render_hyper_box_animation.dart`: `_BlockAnimationState` tracks per-node elapsed time (`accumulated` + `epoch`, frozen/resumed across pause instead of mirroring `AnimationController`), driven by a `SchedulerBinding.scheduleFrameCallback` loop (same pattern as the existing image-loading shimmer — no `TickerProvider`) that self-terminates once no block is both `running` and unfinished. `paint()` gained a `_paintAnimatedBlocks` pass that composites each animated block's own decoration + owned text/ruby fragments inside a single `saveLayer` before the normal decoration/text passes (which skip anything already painted this way) — a single alpha layer avoids double-blending a block's background through its own text when animating `opacity`. The layer's `saveLayer` bounds are `null` (current clip), not the block's static rect — passing the pre-transform rect as bounds clipped a translated/scaled block to its original position whenever `opacity` and `transform` combined (caught by a new golden test before release, not shipped broken). Rects/fragment groupings are precomputed once per `performLayout`, not per paint frame.

### 🐛 Bug Fixes
- **Non-finite CSS values crashed layout**: `_parseLength`/`_parseLengthWithContext`/`_parseFontSize` in `resolver.dart` used bare `double.tryParse`, which returns `Infinity` for `1e999` and `NaN` for `nan`. These reached box constraints and threw `debugAssertDoesMeetConstraints`. New `_tryParseFinite`/`_scaleFinite` helpers (single choke point) reject non-finite values — including overflow after unit multiplication — so the declaration is ignored.
- **`display: none` not executed on the canvas path**: `_tokenizeNode` now returns early for `DisplayType.none` (covers block/inline/text/atomic uniformly and stops recursion), and `_TableGrid.fromTableNode` filters `display:none` rows and cells from the grid. Previously hidden content was measured, painted and selectable.
- **First no-margin block lost its padding**: `_handleBlockNode`'s block-start-fragment emission guard now also fires on non-zero padding, not just margin or a width constraint. Previously a first `<div style="padding:…">` (no default margin) had its padding dropped. Surfaced by the new `test/style/css_execution_guard_test.dart`.
- **`<a>` without `href` styled as a link**: the UA stylesheet in `resolver.dart` applied the anchor colour/underline to every `<a>`. It now skips anchors with no (or empty) `href`, matching browsers' `a[href]` targeting.
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
