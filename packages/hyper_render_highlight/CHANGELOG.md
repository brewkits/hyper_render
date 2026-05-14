# Changelog — hyper_render_highlight

## [1.3.1] - 2026-05-14

### 🏗️ Maintenance
- Updated `hyper_render_core` dependency to `^1.3.1`

## [1.3.0] - 2026-05-03

### ✨ New Features
- **Theme API**: `SyntaxTheme.fromHighlightTheme()` factory for using any `flutter_highlight` theme directly
- **180+ languages**: Inherits full language support from `flutter_highlight` / `highlight` packages

### 🐛 Bug Fixes
- **Null language**: Graceful fallback when no language hint is provided — renders as plain monospace text

## [1.2.0] - 2026-03-30

- Initial release: syntax highlighting plugin for HyperRender `<code>` and `<pre>` blocks
