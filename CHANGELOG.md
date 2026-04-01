# Changelog

## [1.2.2] - 2026-04-01

### 🐛 Bug Fixes

- **Android build failure with modern compileSdk** (`example/android/build.gradle.kts`): `irondash_engine_context 0.5.5` was compiled against android-31 but its transitive `androidx.fragment:1.7.1` dependency has `minCompileSdk=34`, causing AGP 8's `checkAarMetadata` to block the build. Added a `subprojects { afterEvaluate { compileSdk = 35 } }` override in the example's root Gradle file. README now documents the same one-line workaround for app-level projects. ([#5](https://github.com/brewkits/hyper_render/issues/5))

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