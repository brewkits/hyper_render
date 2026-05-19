# Changelog — hyper_render_devtools

## [1.3.2] - 2026-05-19

### 🧪 First Test Coverage

- **`dev_dependencies` block added** (`flutter_test`, `flutter_lints`) — the package shipped previous releases with zero tests; a senior review flagged this as a release blocker for VM-service-extension code.
- **`udt_serializer_test`** — UDT → JSON round-trip for `BlockNode`, `TextNode`, `AtomicNode`; tree-depth cap at 20 levels enforced; text payload truncation at 200 chars; style key shape stable across calls.
- **`service_extensions_test`** — `HyperRenderDevtools.register()` is exception-free on first call and idempotent on subsequent calls (the `kDebugMode` guard short-circuits in the test runner, but the contract is now pinned).

No behavioural changes to the DevTools surface — this release is purely test-coverage hardening.

## [1.3.2] - 2026-05-14

### 🏗️ Maintenance
- Updated `hyper_render_core` dependency to `^1.3.2`

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
