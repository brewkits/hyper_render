# Changelog — hyper_render_clipboard

## [1.1.0] - 2026-03-20

### ✨ New Features
- **`share_plus: ^10.0.0`**: Upgraded from `^7.2.0` — resolves `mime` version conflict with newer Flutter projects
- **Image copy**: `SuperClipboardHandler.copyImage()` supports PNG byte data via `super_clipboard`
- **Image share**: `SuperClipboardHandler.shareImage()` via `share_plus`

### 🐛 Bug Fixes
- **Race condition**: Copy operation now guards against concurrent calls with a lock flag — prevents duplicate clipboard writes

## [1.0.0] - 2026-01-15

- Initial release: image clipboard and share support for HyperRender selections
