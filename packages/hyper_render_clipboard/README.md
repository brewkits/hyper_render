<div align="center">

# 📋 HyperRender Clipboard

**Full-featured image clipboard operations for Flutter**

[![pub package](https://img.shields.io/pub/v/hyper_render_clipboard.svg)](https://pub.dev/packages/hyper_render_clipboard)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-blue.svg)](https://flutter.dev/)

*Copy, save, and share images with just one line of code*

[Features](#-features) • [Quick Start](#-quick-start) • [Platform Support](#-platform-support) • [Documentation](#-documentation) • [Examples](#-examples)

---

</div>

## 🎯 What is HyperRender Clipboard?

A powerful, easy-to-use Flutter package that enables **real image clipboard operations** (not just URLs!) across all platforms. Built on top of [`super_clipboard`](https://pub.dev/packages/super_clipboard), it integrates seamlessly with [HyperRender](https://pub.dev/packages/hyper_render) and can be used standalone in any Flutter app.

### Why Choose HyperRender Clipboard?

| ❌ Without | ✅ With HyperRender Clipboard |
|-----------|-------------------------------|
| Only copy image URLs | **Copy actual image data** to clipboard |
| Manual file operations | **One-line save** to device storage |
| Custom share dialogs | **Native system share** on all platforms |
| Platform-specific code | **Write once, works everywhere** |

<br>

## ✨ Features

<table>
<tr>
<td width="33%" valign="top">

### 📋 **Real Clipboard**
Copy actual **image data** to clipboard, not just URLs. Works across all platforms with proper image format support.

- PNG, JPEG, GIF, WebP, BMP, TIFF
- URL or raw bytes
- Platform-native behavior

</td>
<td width="33%" valign="top">

### 💾 **Smart Saving**
Save images to **device-appropriate locations** automatically. No manual path handling needed.

- Auto location detection
- Custom filenames
- Format auto-detection
- Scoped storage support

</td>
<td width="33%" valign="top">

### 🔗 **Native Sharing**
Open system share dialogs with **zero configuration**. Works with all platform share targets.

- Native UI/UX
- Custom captions
- All share targets
- Platform-optimized

</td>
</tr>
</table>

### 🎨 Additional Capabilities

- **🚀 Zero Config** - Works with HyperViewer out of the box
- **🔧 Flexible** - Use standalone or integrated
- **⚡ Fast** - Optimized for performance
- **🧪 Type-Safe** - Full Dart type safety
- **📱 Cross-Platform** - Desktop, mobile, and web
- **🛡️ Production Ready** - Battle-tested in production apps

<br>

## 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  hyper_render_clipboard: ^1.0.0
```

Run:

```bash
flutter pub get
```

### Usage (3 Lines!)

```dart
import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';

// That's it! 🎉
HyperViewer(
  html: '<img src="https://example.com/image.png">',
  imageClipboardHandler: SuperClipboardHandler(),
)
```

Users can now **long-press any image** to:
- 📋 Copy to clipboard
- 💾 Save to device
- 🔗 Share via system dialog

### Standalone Usage

```dart
final handler = SuperClipboardHandler();

// Copy image 📋
await handler.copyImageFromUrl('https://example.com/photo.jpg');

// Save image 💾
final path = await handler.saveImageFromUrl(
  'https://example.com/photo.jpg',
  filename: 'my_photo.jpg',
);

// Share image 🔗
await handler.shareImageFromUrl(
  'https://example.com/photo.jpg',
  text: 'Check this out!',
);
```

<br>

## 🎨 Platform Support

<div align="center">

| Platform | Copy | Save | Share | Setup Required |
|:--------:|:----:|:----:|:-----:|:-------------:|
| 🍎 **macOS** | ✅ | ✅ | ✅ | Network entitlement |
| 🪟 **Windows** | ✅ | ✅ | ✅ | None ⭐ |
| 🐧 **Linux** | ✅ | ✅ | ✅ | Install xclip |
| 📱 **iOS** | ✅ | ✅ | ✅ | ATS config |
| 🤖 **Android** | ✅ | ✅ | ✅ | Internet permission |
| 🌐 **Web** | ⚠️ | ❌ | ✅ | HTTPS + CORS |

</div>

**Legend:** ✅ Full Support • ⚠️ Limited • ❌ Not Available

<details>
<summary>📖 Platform Setup Details</summary>

### macOS
```xml
<!-- Add to both DebugProfile.entitlements and Release.entitlements -->
<key>com.apple.security.network.client</key>
<true/>
```

### iOS
```xml
<!-- Add to Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### Android
```xml
<!-- Add to AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET"/>
```

### Linux
```bash
# Install xclip
sudo apt-get install xclip  # Ubuntu/Debian
sudo dnf install xclip      # Fedora
sudo pacman -S xclip        # Arch
```

### Windows
No setup required! 🎉

### Web
Ensure HTTPS and proper CORS headers.

**[📚 Complete Platform Setup Guide →](docs/platform_setup.md)**

</details>

<br>

## 💡 Examples

### Work with Image Bytes

Perfect for screenshots, generated images, or canvas exports:

```dart
import 'dart:typed_data';

final Uint8List imageBytes = ...; // Your image data

// Copy screenshot to clipboard
await handler.copyImageBytes(imageBytes, mimeType: 'image/png');

// Save generated image
final path = await handler.saveImageBytes(
  imageBytes,
  filename: 'artwork_${DateTime.now()}.png',
);

// Share canvas export
await handler.shareImageBytes(
  imageBytes,
  text: 'Created with MyApp!',
  filename: 'drawing.png',
);
```

### Custom Context Menu

```dart
HyperViewer(
  html: content,
  imageClipboardHandler: SuperClipboardHandler(),
  onImageLongPress: (imageUrl, handler) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.copy),
            title: Text('Copy Image'),
            onTap: () => handler.copyImageFromUrl(imageUrl),
          ),
          ListTile(
            leading: Icon(Icons.save),
            title: Text('Save Image'),
            onTap: () => handler.saveImageFromUrl(imageUrl),
          ),
          ListTile(
            leading: Icon(Icons.share),
            title: Text('Share Image'),
            onTap: () => handler.shareImageFromUrl(imageUrl),
          ),
        ],
      ),
    );
  },
)
```

### Platform Detection

```dart
final handler = SuperClipboardHandler();

// Check what's supported
if (handler.isImageCopySupported) {
  await handler.copyImageFromUrl(imageUrl);
} else if (handler.isShareSupported) {
  // Fallback to share on platforms with limited clipboard
  await handler.shareImageFromUrl(imageUrl);
}

// Check supported formats
print(handler.supportedFormats);
// [image/png, image/jpeg, image/gif, image/webp, image/bmp]
```

### Error Handling

```dart
final success = await handler.copyImageFromUrl(imageUrl);

if (success) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('✅ Image copied!')),
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('❌ Failed to copy. Check your network.')),
  );
}
```

**[🎯 More Examples →](docs/usage_guide.md)**

<br>

## 📚 Documentation

<table>
<tr>
<td width="50%">

### 📘 For Developers

- **[📖 API Reference](docs/api_reference.md)**
  Complete API with examples

- **[🎯 Usage Guide](docs/usage_guide.md)**
  Patterns and best practices

- **[🔧 Platform Setup](docs/platform_setup.md)**
  Configuration for each platform

</td>
<td width="50%">

### 🆘 Getting Help

- **[🐛 Troubleshooting](docs/troubleshooting.md)**
  Common issues and solutions

- **[📋 Documentation Index](docs/README.md)**
  Complete documentation overview

- **[💬 GitHub Issues](https://github.com/your-repo/issues)**
  Report bugs or request features

</td>
</tr>
</table>

<br>

## 🎨 Supported Image Formats

| Format | MIME Type | Copy | Save | Share |
|--------|-----------|:----:|:----:|:-----:|
| PNG | `image/png` | ✅ | ✅ | ✅ |
| JPEG | `image/jpeg` | ✅ | ✅ | ✅ |
| GIF | `image/gif` | ✅ | ✅ | ✅ |
| WebP | `image/webp` | ✅ | ✅ | ✅ |
| BMP | `image/bmp` | ✅ | ✅ | ✅ |
| TIFF | `image/tiff` | ✅ | ✅ | ✅ |

<br>

## 🏗️ Architecture

This package implements the `ImageClipboardHandler` interface from `hyper_render_core`:

```dart
abstract class ImageClipboardHandler {
  // Operations
  Future<bool> copyImageFromUrl(String imageUrl);
  Future<bool> copyImageBytes(Uint8List bytes, {String? mimeType});
  Future<String?> saveImageFromUrl(String imageUrl, {String? filename});
  Future<String?> saveImageBytes(Uint8List bytes, {String? filename});
  Future<bool> shareImageFromUrl(String imageUrl, {String? text});
  Future<bool> shareImageBytes(Uint8List bytes, {String? text, String? filename});

  // Platform capabilities
  bool get isImageCopySupported;
  bool get isSaveSupported;
  bool get isShareSupported;
  List<String> get supportedFormats;
}
```

### Default vs SuperClipboard

| Feature | `DefaultImageClipboardHandler` | `SuperClipboardHandler` ⭐ |
|---------|-------------------------------|---------------------------|
| Copy Method | URL only | Actual image data |
| Formats | Any URL | PNG, JPEG, GIF, WebP, BMP, TIFF |
| Platforms | All | Desktop, Mobile, Web (limited) |
| Setup Required | None | Minimal platform config |

<br>

## 🔗 Dependencies

Built on top of these excellent packages:

- [`super_clipboard`](https://pub.dev/packages/super_clipboard) ^0.8.0 - Cross-platform clipboard
- [`http`](https://pub.dev/packages/http) ^1.2.0 - Image downloading
- [`path_provider`](https://pub.dev/packages/path_provider) ^2.1.0 - Platform paths
- [`share_plus`](https://pub.dev/packages/share_plus) ^7.2.0 - Native sharing

<br>

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. 🐛 **Report bugs** - Found an issue? [Open an issue](https://github.com/your-repo/issues)
2. 💡 **Suggest features** - Have an idea? We'd love to hear it!
3. 🔧 **Submit PRs** - Read our [contributing guidelines](../../CONTRIBUTING.md)
4. 📖 **Improve docs** - Help others understand better
5. ⭐ **Star the repo** - Show your support!

<br>

## 📦 Related Packages

Part of the **HyperRender** ecosystem:

- **[hyper_render](https://pub.dev/packages/hyper_render)** - Main package for HTML/Markdown rendering
- **[hyper_render_core](https://pub.dev/packages/hyper_render_core)** - Core interfaces and widgets
- **[hyper_render_clipboard](https://pub.dev/packages/hyper_render_clipboard)** - This package (Image operations)

<br>

## 📄 License

MIT License - see [LICENSE](../../LICENSE) file for details.

<br>

---

<div align="center">

**Made with ❤️ for the Flutter community**

[⬆ Back to Top](#-hyperrender-clipboard)

</div>
