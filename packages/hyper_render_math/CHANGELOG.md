# Changelog — hyper_render_math

## [1.3.1] - 2026-05-14

### 🏗️ Packaging
- **Opt-in add-on**: `hyper_render_math` is no longer bundled with the root `hyper_render` package. Add it explicitly to your `pubspec.yaml` to use `MathNodePlugin` / `LatexNodePlugin`.
- Updated `hyper_render_core` dependency to `^1.3.1`

## [1.3.0] - 2026-05-03

- Initial release: skeleton plugin for `<math>` and `<latex>` tag rendering.
- `MathNodePlugin` and `LatexNodePlugin` ship a visible placeholder widget — wire up `flutter_math_fork` or another backend to complete the implementation (see README).
- Supports both block tier (full-width) and inline tier (flows with text) via `isInline` override.
