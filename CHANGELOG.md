# Changelog

All notable changes to HyperRender will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),

## [1.1.1] - 2026-03-23

### 🐛 Bug Fixes
- **Static analysis**: Fixed all `dart analyze` warnings in `lib/` — 0 issues
  - Wrapped `<details>`/`<summary>` angle brackets in backticks in doc comments
  - Fixed invalid regexp syntax and unnecessary escapes in `resolver.dart`
  - Added curly braces to single-statement `if` branches (`curly_braces_in_flow_control_structures`)
  - Replaced trivial `onLinkTap` getter/setter with a direct public field (`unnecessary_getters_setters`)
- **Layout**: Removed stale `docs/` directory (plural) — pub.dev convention requires `doc/` (singular)

and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-03-20

### 🏗️ Architecture
- **Code consolidation**: Eliminated 26 duplicate source files between `lib/src/` and `packages/hyper_render_core/lib/src/`. `hyper_render` is now a true thin wrapper — core engine lives exclusively in `hyper_render_core`.
- **Single source of truth**: All fixes and features now only need to be applied in one place.

### ✨ New Features
- **CSS Box Shadow**: Full support for box-shadow with multiple shadows, blur, and spread.
- **CSS Gradients**: `linear-gradient` in `background` and `background-image`.
- **Typography**: Font features (ligatures, proportional figures) enabled by default.
- **Consistent Text Rendering**: `TextHeightBehavior` for predictable vertical rhythm across platforms.
- **Retina-Ready Images**: `FilterQuality.medium` for all images — crisp on high-DPI displays.
- **Anti-Aliasing**: Anti-aliasing explicitly enabled on all paint operations.
- **Crisp Borders**: `StrokeCap.square` for professional-looking corners.
- **Adaptive Selection**: Text selection colors adapt to platform (iOS Blue vs Material Blue).
- **Theme-Aware Selection**: Added `selectionColor` property to `HyperViewer` and `HyperRenderWidget`.

### 🐛 Bug Fixes
- **Copy/paste newlines**: Text selection spanning block elements (`<li>`, `<h3>`, `<p>`) now correctly inserts `\n` between blocks when copied to clipboard.
- **Stability**: Comprehensive error boundaries in layout and paint cycles prevent crashes from malformed content.
- **Security**: Reinforced JSON parsing error handling in Delta adapters.
- **Layout — characterOffset**: Second fragment after forced split no longer adds trimmed leading spaces to `characterOffset` — selection mapping is now accurate.
- **Layout — link boundary**: `_sameLinkContext()` guard prevents merging text nodes from different `<a>` ancestors — fixes incorrect link tap targets.
- **Layout — float crash**: Early-return guard in `_layoutFloat()` for unconstrained (`Infinite`) parent width.
- **Layout — float double-layout**: Float intrinsic size uses `getMaxIntrinsicWidth/Height` instead of `child.layout()`.
- **Layout — null fragment text**: `_measureFragments` guards against null `text` on atomic/ruby fragments.
- **Memory — recognizer leak**: `_disposeLinkRecognizers()` called when `document` is replaced — prevents `TapGestureRecognizer` leak.
- **Performance — `enableComplexFilters`**: New flag on `HyperViewer` / `HyperRenderWidget` gates all `canvas.saveLayer` calls for `backdrop-filter`/`filter` effects — eliminates unnecessary GPU compositing layers when effects are unused.
- **Performance — O(1) child lookup**: `_fragmentChildMap` replaces O(N) linear scan in paint cycle.
- **Performance — O(1) accessibility**: `_nodeRectCache` built during layout (Step 8) replaces O(N²) VoiceOver/TalkBack rect computation.
- **Nested Decorations**: `nodeToDecorated` changed to `Map<UDTNode, List<UDTNode>>` — inner spans no longer overwrite outer spans in text decoration maps.

### 🔬 Tests (hyper_render_core)
- **+238 new tests** across 6 new test files covering previously-untested areas:
  - `ruby_layout_test.dart` — RubyNode model + Fragment.ruby lifecycle (27 tests)
  - `float_layout_test.dart` — HyperFloat/HyperClear enums, LineInfo insets (30 tests)
  - `text_breaking_test.dart` — canBreak, isWhitespace, Kinsoku CJK (44 tests)
  - `layout_algorithm_test.dart` — Bug 1–4 regression tests, link context, rect cache (52 tests)
  - `details_element_test.dart` — `<details>/<summary>` model + widget (32 tests)
  - `rtl_bidi_test.dart` — HyperTextDirection, Arabic/Hebrew, RTL widget integration (53 tests)

---

## [1.0.3] - 2026-03-10
- Fix root .pubignore — remove packages/ blanket exclusion that breaks sub-package publishing.
- Restore hyper_render_clipboard path dep post-publish.

## [1.0.2] - 2026-03-08
- Fix .pubignore to exclude packages/, test/, IDE files — reduces upload size.
- Bump hyper_render_clipboard to ^1.0.2 (share_plus 12.x + super_clipboard 0.9.x support).

## [1.0.1] - 2026-03-08
- Add example/example.dart for pub.dev example scoring.
- Fix .pubignore to correctly exclude build artifacts while keeping example.

## [1.0.0] - 2026-03-01
First stable release. Core features, plugin architecture, and cross-platform support are production-ready.
