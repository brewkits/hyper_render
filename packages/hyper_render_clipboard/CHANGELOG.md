## 1.0.3

- Fix `share_plus` lower bound constraint: `>=10.0.0` → `>=11.0.0` to match `SharePlus`/`ShareParams` API availability
- Add unit tests for `SuperClipboardHandler` and `DefaultImageClipboardHandler`

## 1.0.2

- Migrate `share_plus` API: `Share.shareXFiles()` → `SharePlus.instance.share(ShareParams(...))` (compatible with share_plus 11+ / 12.x)
- Verified compatibility with `super_clipboard` 0.9.x — no API changes required

## 1.0.1

- Widen `share_plus` constraint to `>=10.0.0 <13.0.0` (covers 12.x)
- Widen `super_clipboard` constraint to `>=0.8.0 <1.0.0` (covers 0.9.x)

## 1.0.0

Initial public release. See the [root CHANGELOG](https://github.com/brewkits/hyper_render/blob/main/CHANGELOG.md) for full release notes.
