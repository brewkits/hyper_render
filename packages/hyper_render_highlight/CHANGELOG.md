# Changelog — hyper_render_highlight

## [1.3.0] - 2026-05-03

- Version bump to stay in sync with `hyper_render` 1.2.0.
- No API changes in this package.

## [1.3.0] - 2026-05-03

- Version bump to stay in sync with `hyper_render` 1.1.4.

## [1.3.0] - 2026-05-03

- Remove `publish_to: none` from pubspec.yaml so pub.dev can verify the repository URL (fixes 10-point deduction).


## [1.3.0] - 2026-05-03

- Version bump to stay in sync with `hyper_render_core` 1.1.2 (Ruby selection fixes, CSS @keyframes support).
- No API changes in this package.

## [1.3.0] - 2026-05-03

- Maintenance release: no code changes — republish to sync repository verification with current git HEAD

## [1.3.0] - 2026-05-03

### ✨ New Features
- **Theme API**: `SyntaxTheme.fromHighlightTheme()` factory for using any `flutter_highlight` theme directly
- **180+ languages**: Inherits full language support from `flutter_highlight` / `highlight` packages

### 🐛 Bug Fixes
- **Null language**: Graceful fallback when no language hint is provided — renders as plain monospace text

## [1.3.0] - 2026-05-03

- Initial release: syntax highlighting plugin for HyperRender `<code>` and `<pre>` blocks
