# Changelog — hyper_render_highlight

## [1.1.0] - 2026-03-20

### ✨ New Features
- **Theme API**: `SyntaxTheme.fromHighlightTheme()` factory for using any `flutter_highlight` theme directly
- **180+ languages**: Inherits full language support from `flutter_highlight` / `highlight` packages

### 🐛 Bug Fixes
- **Null language**: Graceful fallback when no language hint is provided — renders as plain monospace text

## [1.0.0] - 2026-01-15

- Initial release: syntax highlighting plugin for HyperRender `<code>` and `<pre>` blocks
