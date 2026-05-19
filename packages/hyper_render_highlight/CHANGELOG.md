# Changelog — hyper_render_highlight

## [1.3.2] - 2026-05-19

### 🧪 Tests

- **+9 edge-case tests added** in `code_highlighter_edge_cases_test`: empty / whitespace-only input round-trips, unknown-language fallback to auto-detect, malformed source (unterminated string) doesn't throw, 5 KB block highlights in linear time, every popular language identifier resolves, every `HighlightTheme` enum value produces a non-empty `themeName`. No behavioural changes to the highlighter itself.

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
