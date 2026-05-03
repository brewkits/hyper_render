# Changelog — hyper_render_devtools

## [1.3.0] - 2026-05-03

### ✨ New Features
- **Demo Mode**: Loads sample UDT/style/fragment data when no live app is connected — explore the inspector UI without a running HyperRender app
- "Try Demo" button shown in the error state when the app is unreachable
- DEMO chip in the AppBar clearly signals when sample data is active

### 🔧 Improvements
- `README.md` added with full usage guide, service extension table, and architecture overview
- DevTools panel UI (`devtools_ui`) upgraded to `devtools_extensions: 0.2.2`
- Updated `hyper_render_core` dependency to `^1.3.0`
- Removed invalid `flutter.plugin.platforms` declaration — no native code, package correctly supports all Flutter platforms
- `_HyperRenderRegistry` debounces rapid `updateLayout` calls to avoid flooding the DevTools panel during fast scroll

### 🐛 Bug Fixes
- `UdtSerializer.serializeStyle` no longer throws on packages compiled with older `hyper_render_core` that lack newer `ComputedStyle` fields — unresolved dynamic fields fall back gracefully

## [1.2.0] - 2026-03-30

- Initial public release of `hyper_render_devtools`
- Five VM service extensions: `listRenderers`, `getUdt`, `getNodeStyle`, `getFragments`, `getPerformance`
- Auto-registration via `HyperRenderDebugHooks` — no per-widget setup needed
- Flutter DevTools panel (Flutter Web) with three tabs: UDT Tree, Style, Layout
- `UdtSerializer` — serializes `DocumentNode` trees and `ComputedStyle` to JSON for the panel
- Manual registration API (`registerRenderer` / `unregisterRenderer`) for custom document sources
