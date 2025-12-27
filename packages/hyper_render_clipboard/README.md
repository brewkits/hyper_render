# HyperRender Clipboard

Image clipboard support for HyperRender using `super_clipboard`.

## Installation

```yaml
dependencies:
  hyper_render: ^1.0.0
  hyper_render_clipboard: ^0.1.0
```

## Features

- Copy images to clipboard (actual image data, not just URLs)
- Save images to device storage
- Share images via system dialog
- Cross-platform support

## Platform Support

| Platform | Copy | Save | Share |
|----------|------|------|-------|
| macOS | Yes | Yes | Yes |
| Windows | Yes | Yes | Yes |
| Linux | Yes* | Yes | Yes |
| iOS | Yes | Yes | Yes |
| Android | Yes | Yes | Yes |
| Web | Limited | No | No |

*Requires `xclip` installed

## Usage

### With HyperViewer

```dart
import 'package:hyper_render/hyper_render.dart';
import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';

HyperViewer(
  html: '<img src="https://example.com/image.png">',
  imageClipboardHandler: SuperClipboardHandler(),
)
```

### Standalone Usage

```dart
import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';

final handler = SuperClipboardHandler();

// Copy image from URL
await handler.copyImageFromUrl('https://example.com/image.png');

// Save image to device
final path = await handler.saveImageFromUrl(
  'https://example.com/image.png',
  filename: 'my_image.png',
);
print('Saved to: $path');

// Share image
await handler.shareImageFromUrl(
  'https://example.com/image.png',
  text: 'Check out this image!',
);
```

### With Bytes

```dart
import 'dart:typed_data';

final Uint8List imageBytes = ...;

// Copy bytes to clipboard
await handler.copyImageBytes(imageBytes, mimeType: 'image/png');

// Save bytes to file
final path = await handler.saveImageBytes(
  imageBytes,
  filename: 'screenshot.png',
);

// Share bytes
await handler.shareImageBytes(
  imageBytes,
  text: 'My screenshot',
  filename: 'screenshot.png',
);
```

## Supported Formats

- PNG
- JPEG
- GIF
- WebP
- BMP
- TIFF

## Dependencies

- `super_clipboard: ^0.8.0` - Cross-platform clipboard
- `http: ^1.2.0` - HTTP client
- `path_provider: ^2.1.0` - File system paths
- `share_plus: ^7.2.0` - Share functionality

## Default Behavior

Without this plugin, HyperRender uses `DefaultImageClipboardHandler` which only copies the image URL to clipboard (not the actual image data).

## License

MIT License
