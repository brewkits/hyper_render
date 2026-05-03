# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Running tests

```bash
# Full suite (root + packages, golden tests excluded)
flutter test test/ packages/hyper_render_core/test/ packages/hyper_render_html/test/ --exclude-tags golden

# Root package only
flutter test test/ --exclude-tags golden

# Single test file
flutter test test/accessibility_test.dart

# Single test by name
flutter test test/html_adapter_test.dart --plain-name 'parses links'

# A sub-package
flutter test packages/hyper_render_core/test/

# Golden tests (need --update-goldens first to generate baselines)
flutter test test/golden/ --update-goldens
flutter test test/golden/

# Coverage
./scripts/generate_coverage.sh
```

### Analysis and linting

```bash
flutter analyze
dart format --set-exit-if-changed .
```

### Publishing

```bash
# Swap path: deps → version deps, dry-run, then publish
./scripts/prepare_publish.sh
dart pub publish --dry-run
./scripts/publish.sh
```

## Architecture

HyperRender is a **single-RenderObject renderer** — all content is drawn on a single `Canvas` by `RenderHyperBox` rather than building a widget subtree. This is what enables CSS `float` layouts, crash-free selection on 100K-char documents, and sub-millisecond hit-testing.

### Parse pipeline

```
HTML / Markdown / Quill Delta
         ↓
   Adapter (html_adapter, markdown_parser, delta_parser)
         ↓
   Unified Document Tree (UDT) — DocumentNode / BlockNode / InlineNode / TextNode / AtomicNode
         ↓
   CSS resolver (DefaultCssParser, computed_style.dart)
         ↓
   Fragment tokeniser  →  Fragment list (text runs, atoms, line-breaks)
         ↓
   RenderHyperBox  →  layout (float-aware) → paint (Canvas) → semantics
```

### Key packages

| Package | Role |
|---|---|
| `hyper_render_core` | Zero-dep engine: UDT model, `RenderHyperBox`, plugin interface, CSS model |
| `hyper_render_html` | html5lib-based HTML + CSS parser → UDT |
| `hyper_render_markdown` | markdown package → UDT |
| `hyper_render_highlight` | Syntax highlighting via `flutter_highlight` |
| `hyper_render_clipboard` | Image copy/share (`hyper_render_clipboard`) |
| `hyper_render_devtools` | Flutter DevTools extension |
| `hyper_render_math` | Skeleton plugin for `<math>`/`<latex>` — wire up `flutter_math_fork` to complete |

The root `hyper_render` package depends on all of them via `path:` deps and re-exports everything from `lib/hyper_render.dart`.

### Core model (`packages/hyper_render_core/lib/src/model/node.dart`)

`UDTNode` is the abstract base. The node tree always starts with a `DocumentNode` containing `BlockNode` children. Text content lives in `TextNode` leaves; replaced content (images, video, plugins) lives in `AtomicNode`.

### RenderHyperBox (`packages/hyper_render_core/lib/src/core/`)

Implemented as one primary file plus six `part` files:
- `render_hyper_box.dart` — entry, layout orchestration, image loading
- `render_hyper_box_layout.dart` — float-aware line/block layout
- `render_hyper_box_fragments.dart` — fragment tokenisation
- `render_hyper_box_paint.dart` — Canvas painting
- `render_hyper_box_selection.dart` — text selection handles
- `render_hyper_box_accessibility.dart` — WCAG 2.1 AA semantics (headings, links, images)

Do **not** break `part` usage across these files — they share private state via the same library scope.

### Plugin API

```dart
// implement HyperNodePlugin in hyper_render_core
class MyPlugin implements HyperNodePlugin {
  @override List<String> get tagNames => ['my-tag'];
  @override bool get isInline => false;           // block by default
  @override Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) { ... }
}

// register and pass to HyperViewer
final registry = HyperPluginRegistry()..register(const MyPlugin());
HyperViewer(html: html, pluginRegistry: registry)
```

Block-tier plugins take full width; inline-tier plugins are measured via `getMaxIntrinsicWidth` and flow inside text lines.

### Rendering modes

- `auto` — sync if < 10,000 chars, otherwise async + virtualized
- `sync` — single `HyperRenderWidget` on main thread
- `virtualized` — `ListView.builder`, async parse via `Future.microtask` (not `compute()` — isolates break `FakeAsync` in widget tests)
- `paged` — `PageView.builder`, controlled by `HyperPageController`

### Test layout

- `test/` — root-package tests (widget, integration, parser, fuzz, accessibility)
- `test/golden/` — golden pixel tests, tagged `@Tags(['golden'])`, always excluded from normal runs
- `test/fuzz/` — 43 fuzz cases for HTML/Markdown/Sanitizer parsers
- `packages/hyper_render_core/test/` and `packages/hyper_render_html/test/` — package-level unit tests

Current count: **1,645 passing, 0 failing** (golden tests excluded).
