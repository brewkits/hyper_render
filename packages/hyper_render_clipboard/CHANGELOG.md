# Changelog — hyper_render_clipboard

## [1.3.0] - 2026-05-03

### ✨ New Features
- **`share_plus: ^10.0.0`**: Upgraded from `^7.2.0` — resolves `mime` version conflict with newer Flutter projects
- **Image copy**: `SuperClipboardHandler.copyImage()` supports PNG byte data via `super_clipboard`
- **Image share**: `SuperClipboardHandler.shareImage()` via `share_plus`

### 🐛 Bug Fixes
- **Race condition**: Copy operation now guards against concurrent calls with a lock flag — prevents duplicate clipboard writes
- **Static analysis**: Replaced deprecated `Share.shareXFiles()` with `SharePlus.instance.share()` — 0 analyzer issues
- **Directory convention**: Renamed `docs/` → `doc/` (pub.dev singular directory convention)

## [1.2.0] - 2026-03-30

- Initial release: image clipboard and share support for HyperRender selections
