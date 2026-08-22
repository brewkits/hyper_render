# Changelog — hyper_render_math

## [1.7.0] - 2026-08-22

### 🚀 Update
- Bump `hyper_render_core` dependency to `^1.7.0`.
- Synchronized release with HyperRender 1.7.0 core engine.

## [1.6.0] - 2026-07-26

### 🚀 Update
- Bump `hyper_render_core` dependency to `^1.6.0` to support multi-platform constraints.
## [1.5.1] - 2026-07-05

### 🐛 Packaging Fix
- Republished without the dev-only `dependency_overrides` block that slipped into the 1.5.0 archive and broke pub.dev dependency resolution (`pub get` could not find the local `../hyper_render_core` path). **No code changes** from 1.5.0.

## [1.5.0] - 2026-07-05

### 🏗️ Maintenance
- Updated `hyper_render_core` dependency to `^1.5.0`

## [1.4.0] - 2026-06-24

### 🏗️ Maintenance
- Updated `hyper_render_core` dependency to `^1.4.0`

## [1.3.4] - 2026-06-04

### 🏗️ Maintenance
- Updated `hyper_render_core` dependency to `^1.3.4`

## [1.3.3] - 2026-06-04

### 🏗️ Maintenance
- Updated `hyper_render_core` dependency to `^1.3.3`

## [1.3.2] - 2026-05-19

### 🏗️ Packaging

- **`pubspec.yaml` description format normalised** — replaced the YAML folded-scalar (`>`) form with a plain string, matching the other six sub-packages and removing a pana cosmetic warning.

No code changes — the plugin's tag handlers (`<math>` / `<latex>`) and `flutter_math_fork` integration are unchanged.

## [1.3.1] - 2026-05-14

### 🏗️ Packaging
- **Opt-in add-on**: `hyper_render_math` is no longer bundled with the root `hyper_render` package. Add it explicitly to your `pubspec.yaml` to use `MathNodePlugin` / `LatexNodePlugin`.
- Updated `hyper_render_core` dependency to `^1.3.1`

## [1.3.0] - 2026-05-03

- Initial release: skeleton plugin for `<math>` and `<latex>` tag rendering.
- `MathNodePlugin` and `LatexNodePlugin` ship a visible placeholder widget — wire up `flutter_math_fork` or another backend to complete the implementation (see README).
- Supports both block tier (full-width) and inline tier (flows with text) via `isInline` override.
