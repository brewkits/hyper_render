# hyper_render_clipboard

Image clipboard operations for [HyperRender](https://pub.dev/packages/hyper_render). Copy actual image data (not just URLs), save to device storage, and share via the system share sheet — built on [`super_clipboard`](https://pub.dev/packages/super_clipboard).

---

## Installation

```yaml
dependencies:
  hyper_render_clipboard: ^1.3.1
```

---

## Usage

### With HyperViewer

```dart
import 'package:hyper_render/hyper_render.dart';
import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';

HyperViewer(
  html: '<img src="https://example.com/photo.jpg">',
  imageClipboardHandler: SuperClipboardHandler(),
)
```

Long-pressing an image shows Copy / Save / Share options automatically.

### Standalone

```dart
final handler = SuperClipboardHandler();

await handler.copyImageFromUrl('https://example.com/photo.jpg');

final path = await handler.saveImageFromUrl(
  'https://example.com/photo.jpg',
  filename: 'my_photo.jpg',
);

await handler.shareImageFromUrl(
  'https://example.com/photo.jpg',
  text: 'Check this out!',
);
```

### From bytes

```dart
final Uint8List imageBytes = ...;

await handler.copyImageBytes(imageBytes, mimeType: 'image/png');
await handler.saveImageBytes(imageBytes, filename: 'screenshot.png');
await handler.shareImageBytes(imageBytes, text: 'Created with MyApp!');
```

---

## Platform support

| Platform | Copy | Save | Share | Setup |
|:--------:|:----:|:----:|:-----:|:------|
| macOS | ✅ | ✅ | ✅ | Add `com.apple.security.network.client` entitlement |
| Windows | ✅ | ✅ | ✅ | None |
| Linux | ✅ | ✅ | ✅ | Install `xclip` |
| iOS | ✅ | ✅ | ✅ | Add `NSAllowsArbitraryLoads` to Info.plist |
| Android | ✅ | ✅ | ✅ | Add `INTERNET` permission to AndroidManifest.xml |
| Web | ⚠️ | ❌ | ✅ | HTTPS + CORS required |

---

## Supported formats

PNG, JPEG, GIF, WebP, BMP, TIFF

---

## HyperRender Ecosystem

| Package | Description |
|---------|-------------|
| [hyper_render](https://pub.dev/packages/hyper_render) | Main package — `HyperViewer` widget, HTML + Markdown rendering |
| [hyper_render_core](https://pub.dev/packages/hyper_render_core) | Core engine: UDT model, `RenderHyperBox`, plugin API |
| [hyper_render_html](https://pub.dev/packages/hyper_render_html) | HTML + CSS → UDT parser |
| [hyper_render_markdown](https://pub.dev/packages/hyper_render_markdown) | Markdown (GFM) → UDT parser |
| [hyper_render_highlight](https://pub.dev/packages/hyper_render_highlight) | Syntax highlighting for `<code>` / `<pre>` blocks |
| **[hyper_render_clipboard](https://pub.dev/packages/hyper_render_clipboard)** | **Image copy / save / share** ← you are here |
| [hyper_render_math](https://pub.dev/packages/hyper_render_math) | LaTeX / MathML rendering *(opt-in)* |
| [hyper_render_devtools](https://pub.dev/packages/hyper_render_devtools) | Flutter DevTools inspector |

[Source](https://github.com/brewkits/hyper_render/tree/main/packages/hyper_render_clipboard) · [Issues](https://github.com/brewkits/hyper_render/issues) · [Changelog](CHANGELOG.md)

---

## License

MIT — see [LICENSE](LICENSE).
