# Changelog — hyper_render_clipboard

## [1.1.3] - 2026-03-25

- Remove `publish_to: none` from pubspec.yaml so pub.dev can verify the repository URL (fixes 10-point deduction).


## [1.1.2] - 2026-03-25

- Version bump to stay in sync with `hyper_render_core` 1.1.2 (Ruby selection fixes, CSS @keyframes support).
- No API changes in this package.

## [1.1.1] - 2026-03-23

### 🐛 Bug Fixes
- **Static analysis**: Replaced deprecated `Share.shareXFiles()` with `SharePlus.instance.share()` — 0 analyzer issues
- **Conventions**: Renamed `docs/` → `doc/` (pub.dev singular directory convention)

## [1.1.0] - 2026-03-20

### ✨ New Features
- **`share_plus: ^10.0.0`**: Upgraded from `^7.2.0` — resolves `mime` version conflict with newer Flutter projects
- **Image copy**: `SuperClipboardHandler.copyImage()` supports PNG byte data via `super_clipboard`
- **Image share**: `SuperClipboardHandler.shareImage()` via `share_plus`

### 🐛 Bug Fixes
- **Race condition**: Copy operation now guards against concurrent calls with a lock flag — prevents duplicate clipboard writes

## [1.0.0] - 2026-01-15

- Initial release: image clipboard and share support for HyperRender selections
