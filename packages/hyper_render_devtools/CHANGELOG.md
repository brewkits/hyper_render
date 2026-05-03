# Changelog — hyper_render_devtools

## [1.3.0] - 2026-05-03

- Version bump to stay in sync with `hyper_render` 1.2.0.
- Updated `hyper_render_core` dependency to `^1.2.0`.
- No UI changes in this version.

## [1.3.0] - 2026-05-03

### 🔧 Improvements
- Remove invalid `flutter.plugin.platforms` declaration (no native code exists); package now correctly reports support for all Flutter platforms.
- Update `hyper_render_core` dependency to `^1.1.3`.

## [1.3.0] - 2026-05-03

- Fix pub.dev repository verification.

## [1.3.0] - 2026-05-03

- Remove `publish_to: none` from pubspec.yaml so pub.dev can verify the repository URL (fixes 10-point deduction).


## [1.3.0] - 2026-05-03

### ✨ New
- **Demo Mode** in the DevTools panel — loads sample UDT/style/fragment data when no live app is connected, so you can explore the inspector UI without a running HyperRender app.
- "Try Demo" button shown in the error state when the app is not reachable.
- DEMO chip in the AppBar clearly signals when sample data is active.

### 🔧 Improvements
- Added `README.md` with full usage guide, service extension table, and architecture overview.
- DevTools panel UI (`devtools_ui`) upgraded to `devtools_extensions: 0.2.2`.

## [1.3.0] - 2026-05-03

### 🐛 Bug Fixes
- `UdtSerializer.serializeStyle` — no longer throws on packages compiled with older `hyper_render_core` that lack newer `ComputedStyle` fields; unresolved dynamic fields fall back gracefully.

### 🔧 Improvements
- `_HyperRenderRegistry` debounces rapid `updateLayout` calls to avoid flooding the DevTools panel during fast scroll.

## [1.3.0] - 2026-05-03

### ✨ New
- Initial public release of `hyper_render_devtools`.
- Five VM service extensions: `listRenderers`, `getUdt`, `getNodeStyle`, `getFragments`, `getPerformance`.
- Auto-registration via `HyperRenderDebugHooks` — no per-widget setup needed.
- Flutter DevTools panel (Flutter Web) with three tabs: UDT Tree, Style, Layout.
- `UdtSerializer` — serializes `DocumentNode` trees and `ComputedStyle` to JSON for the panel.
- Manual registration API (`registerRenderer` / `unregisterRenderer`) for custom document sources.
