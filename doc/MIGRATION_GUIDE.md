# Migration Guide

> **Current version: v1.3.2**

## Upgrading to 1.3.2

### ⚠️ Breaking change — clipboard and math are now opt-in

`hyper_render_clipboard` and `hyper_render_math` are no longer transitive dependencies of the root `hyper_render` package. If you use either, add them explicitly:

```yaml
dependencies:
  hyper_render: ^1.3.2
  hyper_render_clipboard: ^1.3.2   # only if you use SuperClipboardHandler
  hyper_render_math: ^1.3.2        # only if you use MathNodePlugin / LatexNodePlugin
```

If you don't use either feature, **no changes are needed** — just bump the version and your Android build will no longer require a `compileSdk = 35` workaround.

### New in 1.3.2

- `list-style-type`, `list-style-position`, `list-style` shorthand CSS support
- `background-repeat`, `background-position` CSS support
- Edge-to-edge images: `width: 100%` now truly fills the container
- Selection drag performance improved (rects cached, auto-scroll proportional)

---

## Starting fresh with 1.3.2

**No migration needed!** If you're starting fresh:

```yaml
dependencies:
  hyper_render: ^1.3.2
  # opt-in extras:
  hyper_render_clipboard: ^1.3.2   # image copy/save/share
  hyper_render_math: ^1.3.2        # LaTeX/MathML
```

```dart
import 'package:hyper_render/hyper_render.dart';

HyperViewer(html: '<p>Hello World</p>')
HyperViewer.markdown(markdown: '# Hello')
HyperViewer(html: '...', mode: HyperRenderMode.paged, pageController: HyperPageController())
```

---

## v1.2.0 — What's New (March 2026)

### ✨ Plugin API, Paged Mode, Incremental Layout, A11y

#### New: Multi-tier Plugin API

Register custom HTML tag renderers at startup:

```dart
final registry = HyperPluginRegistry()
  ..register(MyBlockPlugin())   // isInline == false (full-width)
  ..register(MyInlinePlugin()); // isInline == true (flows with text)

HyperViewer(html: html, pluginRegistry: registry)
```

#### New: Paged Mode

```dart
final ctrl = HyperPageController();

HyperViewer(
  html: longHtml,
  mode: HyperRenderMode.paged,
  pageController: ctrl,
)

// Navigate programmatically:
ctrl.nextPage();
ctrl.animateToPage(3, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);

// Reactive page indicator:
ValueListenableBuilder<int>(
  valueListenable: ctrl.currentPage,
  builder: (_, page, __) => Text('Page ${page + 1} of ${ctrl.pageCount}'),
)
```

#### New: Incremental Layout

Sections whose content hasn't changed are automatically reused — no API changes required.
Flutter skips re-layout and repaint for unchanged `RepaintBoundary` sections.
Approximately 90% layout rebuild reduction for live-updating feeds.

#### New: Accessibility (WCAG 2.1 AA)

- `<img alt="…">` now produces a discrete `SemanticsNode` at the image's layout rect (WCAG 1.1.1).
- `<a aria-label="…">` uses the `aria-label` value as the semantic label (WCAG 4.1.2).

### 🏗️ Internal Refactor — Dead-code elimination

- **No API changes.** Internal cleanup for better performance.
- Root `lib/src/` had 31 stale duplicate files shadowing `hyper_render_core`. All deleted.
- `LazyImageQueue` singleton is now the single shared instance from `hyper_render_core`.
- All v1.2.0 symbols (`HyperRenderConfig`, `LazyImageQueue`, `HyperNodePlugin`, `HyperPluginRegistry`,
  `HyperPluginBuildContext`, `LoadingSkeleton`, `HyperErrorWidget`, `FloatCarryover`) are now
  accessible from `package:hyper_render` directly.

---

## Future: Migration from v1.x to v2.x

> **This section is for planning purposes only and describes potential breaking changes in a future v2.0 release.**

When v2.0 is released (planned features):
- Modular plugin architecture with separate parser packages
- Zero-dependency core package
- Improved tree-shaking for smaller bundle sizes
- Enhanced plugin system

### Potential Changes in v2.0 (Not Yet Released)

**Current v1.0:**
```yaml
dependencies:
  hyper_render_core: ^1.0.0
```

**Future v2.0 (example structure):**
```yaml
dependencies:
  hyper_render_core: ^2.0.0       # Core engine
  hyper_render_html: ^2.0.0       # HTML parser plugin
  hyper_render_markdown: ^2.0.0   # Markdown parser plugin (optional)
```

### What Won't Change

These APIs are stable and will remain backward-compatible in v2.0:

- Core widget: `HyperViewer`
- Plugin interfaces: `ImageClipboardHandler`, `CodeHighlighter`
- Design tokens system
- CSS support
- Float layout

---

## Version History

### v1.3.0 (April 2026)
- High Coverage Milestone: >80% total line coverage (900+ tests)
- Fixed missing `foundation` import for `compute` function
- Virtualized selection logic refinements for off-screen chunks
- Flexible Markdown tag parsing (<b> vs <strong> compatibility)

### v1.2.0 (March 2026)
- Multi-tier Plugin API (`HyperNodePlugin` / `HyperPluginRegistry`)
- `HyperRenderMode.paged` + `HyperPageController`
- Dirty-flag incremental layout (~90% rebuild reduction)
- WCAG 2.1 AA: img alt SemanticsNode + aria-label on links
- Dead-code elimination — 31 duplicate root files removed
- `LazyImageQueue` singleton unified (single shared instance)
- All v1.2.0 symbols now accessible from `package:hyper_render`

### v1.1.x (March 2026)
- CSS @keyframes / animation support
- Ruby/furigana selection fixes
- Wikipedia / rich HTML display fixes (`display:none`, `<pre>`, `<hr>`)
- Over 800 automated tests for production reliability

### v1.0.0 (February 2026)
- Initial stable release
- Full HTML rendering support
- CSS styling with design tokens
- Plugin architecture with clipboard support
- Cross-platform (iOS, Android, Web, Desktop)

---

## Getting Help

For the current v1.3.2 release:
- See [README](../README.md) for usage
- Check [CHANGELOG](../CHANGELOG.md) for version history
- Review [Plugin Development Guide](PLUGIN_DEVELOPMENT.md) for extending
- File issues at [GitHub Issues](https://github.com/brewkits/hyper_render/issues)

---

*Last Updated: May 14, 2026 for v1.3.2*
