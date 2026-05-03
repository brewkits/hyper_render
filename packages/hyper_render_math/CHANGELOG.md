# Changelog — hyper_render_math

## [1.3.0] - 2026-05-03

- Initial release: skeleton plugin for `<math>` and `<latex>` tag rendering.
- `MathNodePlugin` and `LatexNodePlugin` ship a visible placeholder widget — wire up `flutter_math_fork` or another backend to complete the implementation (see README).
- Supports both block tier (full-width) and inline tier (flows with text) via `isInline` override.
