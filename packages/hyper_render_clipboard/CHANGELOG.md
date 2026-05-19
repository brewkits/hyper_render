# Changelog — hyper_render_clipboard

## [1.3.2] - 2026-05-19

### 🔒 Security — Path Traversal

- **`saveImageBytes(filename:)` and `shareImageBytes(filename:)` now sanitise the caller-supplied filename.** `_getFilenameFromUrl` already stripped URL-decoded path separators (`%2F` → `/`), but a malicious app dev who passed `filename: '../../etc/passwd.png'` through to the public API would still escape the storage directory. Every code path that lands in `File('${dir.path}/$name')` now runs through a single `_sanitiseFilename` helper that replaces `/` and `\` with `_`. Self-supplied filenames remain untouched in spirit (extensions, dots, dashes preserved).

### 🧪 Tests

- **+8 tests added** in `filename_safety_test`: URL-encoded slash, URL-encoded backslash, plain filename pass-through, extensionless URL fallback, caller-supplied traversal payloads (`../../etc/passwd.png`, Windows backslash variants), safe filename round-trip, mixed separator handling.

## [1.3.2] - 2026-05-14

### 🏗️ Packaging
- **Opt-in add-on**: `hyper_render_clipboard` is no longer bundled with the root `hyper_render` package. Add it explicitly to your `pubspec.yaml` if you use `SuperClipboardHandler`. This removes the `compileSdk = 34` requirement from default `hyper_render` users.

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
