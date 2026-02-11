# API Reference

## SuperClipboardHandler

`SuperClipboardHandler` implements the `ImageClipboardHandler` interface from `hyper_render_core`, providing full image clipboard functionality using the `super_clipboard` package.

### Constructor

```dart
SuperClipboardHandler({http.Client? httpClient})
```

Creates a new instance of SuperClipboardHandler.

**Parameters:**
- `httpClient` (optional): Custom HTTP client for downloading images. Useful for testing or custom network configuration.

**Example:**
```dart
// Default HTTP client
final handler = SuperClipboardHandler();

// Custom HTTP client
final customClient = http.Client();
final handler = SuperClipboardHandler(httpClient: customClient);
```

---

## Methods

### copyImageFromUrl

```dart
Future<bool> copyImageFromUrl(String imageUrl) async
```

Downloads an image from a URL and copies it to the system clipboard.

**Parameters:**
- `imageUrl`: The URL of the image to copy

**Returns:**
- `Future<bool>`: `true` if successful, `false` otherwise

**Example:**
```dart
final handler = SuperClipboardHandler();
final success = await handler.copyImageFromUrl(
  'https://example.com/image.png'
);

if (success) {
  print('Image copied to clipboard');
} else {
  print('Failed to copy image');
}
```

**Supported formats:**
- PNG
- JPEG/JPG
- GIF
- WebP
- TIFF

**Error handling:**
- Returns `false` if download fails (network error, 404, etc.)
- Returns `false` if clipboard is not available
- Prints debug message on error

---

### copyImageBytes

```dart
Future<bool> copyImageBytes(Uint8List bytes, {String? mimeType}) async
```

Copies image bytes to the system clipboard.

**Parameters:**
- `bytes`: The image data as bytes
- `mimeType` (optional): The MIME type of the image (e.g., 'image/png', 'image/jpeg')

**Returns:**
- `Future<bool>`: `true` if successful, `false` otherwise

**Example:**
```dart
import 'dart:typed_data';

final Uint8List imageBytes = ...; // Your image bytes

final handler = SuperClipboardHandler();
final success = await handler.copyImageBytes(
  imageBytes,
  mimeType: 'image/png',
);
```

**Supported MIME types:**
- `image/png` (default if not specified)
- `image/jpeg` or `image/jpg`
- `image/gif`
- `image/webp`
- `image/tiff`

**Notes:**
- If no `mimeType` is provided, defaults to PNG
- The method automatically selects the correct format handler based on MIME type

---

### saveImageFromUrl

```dart
Future<String?> saveImageFromUrl(String imageUrl, {String? filename}) async
```

Downloads an image from a URL and saves it to device storage.

**Parameters:**
- `imageUrl`: The URL of the image to save
- `filename` (optional): Custom filename for the saved image

**Returns:**
- `Future<String?>`: The absolute path to the saved file, or `null` if failed

**Example:**
```dart
final handler = SuperClipboardHandler();

// Save with auto-generated filename
final path = await handler.saveImageFromUrl(
  'https://example.com/image.png'
);

// Save with custom filename
final path = await handler.saveImageFromUrl(
  'https://example.com/image.png',
  filename: 'my_custom_image.png',
);

if (path != null) {
  print('Image saved to: $path');
}
```

**Save locations by platform:**
- **Android**: External storage directory or app documents directory
- **iOS**: App documents directory
- **macOS/Windows/Linux**: Downloads directory or app documents directory

**Filename generation:**
- If `filename` is provided, uses that name
- If not provided, extracts from URL if possible
- Falls back to `image_<timestamp>.png`

---

### saveImageBytes

```dart
Future<String?> saveImageBytes(Uint8List bytes, {String? filename}) async
```

Saves image bytes to device storage.

**Parameters:**
- `bytes`: The image data as bytes
- `filename` (optional): Custom filename for the saved image

**Returns:**
- `Future<String?>`: The absolute path to the saved file, or `null` if failed

**Example:**
```dart
import 'dart:typed_data';

final Uint8List imageBytes = ...; // Your image bytes
final handler = SuperClipboardHandler();

final path = await handler.saveImageBytes(
  imageBytes,
  filename: 'screenshot.png',
);

if (path != null) {
  print('Image saved to: $path');
}
```

---

### shareImageFromUrl

```dart
Future<bool> shareImageFromUrl(String imageUrl, {String? text}) async
```

Downloads an image from a URL and shares it using the system share dialog.

**Parameters:**
- `imageUrl`: The URL of the image to share
- `text` (optional): Additional text to share with the image

**Returns:**
- `Future<bool>`: `true` if successful, `false` otherwise

**Example:**
```dart
final handler = SuperClipboardHandler();

final success = await handler.shareImageFromUrl(
  'https://example.com/image.png',
  text: 'Check out this image!',
);
```

**Notes:**
- Opens the system native share dialog
- Supported on all platforms (iOS, Android, macOS, Windows, Linux, Web)
- The behavior depends on the platform's share capabilities

---

### shareImageBytes

```dart
Future<bool> shareImageBytes(
  Uint8List bytes, {
  String? text,
  String? filename,
}) async
```

Shares image bytes using the system share dialog.

**Parameters:**
- `bytes`: The image data as bytes
- `text` (optional): Additional text to share with the image
- `filename` (optional): Filename to use when sharing

**Returns:**
- `Future<bool>`: `true` if successful, `false` otherwise

**Example:**
```dart
import 'dart:typed_data';

final Uint8List imageBytes = ...; // Your image bytes
final handler = SuperClipboardHandler();

final success = await handler.shareImageBytes(
  imageBytes,
  text: 'My screenshot',
  filename: 'screenshot.png',
);
```

**Notes:**
- Creates a temporary file for sharing
- Filename defaults to `share_<timestamp>.png` if not provided

---

## Properties

### isImageCopySupported

```dart
bool get isImageCopySupported
```

Indicates whether image copying to clipboard is supported on the current platform.

**Returns:**
- `true` on all platforms except Web
- `false` on Web (due to browser limitations)

**Example:**
```dart
final handler = SuperClipboardHandler();

if (handler.isImageCopySupported) {
  await handler.copyImageFromUrl('https://example.com/image.png');
} else {
  print('Image copying not supported on this platform');
}
```

---

### isSaveSupported

```dart
bool get isSaveSupported
```

Indicates whether saving images to device storage is supported on the current platform.

**Returns:**
- `true` on all platforms except Web
- `false` on Web (due to browser limitations)

---

### isShareSupported

```dart
bool get isShareSupported
```

Indicates whether sharing images is supported on the current platform.

**Returns:**
- `true` on all platforms (uses `share_plus` package)

---

### supportedFormats

```dart
List<String> get supportedFormats
```

Returns a list of supported image MIME types.

**Returns:**
```dart
[
  'image/png',
  'image/jpeg',
  'image/gif',
  'image/webp',
  'image/bmp',
]
```

**Example:**
```dart
final handler = SuperClipboardHandler();
print('Supported formats: ${handler.supportedFormats}');
```

---

## Platform Compatibility Matrix

| Method | macOS | Windows | Linux | iOS | Android | Web |
|--------|-------|---------|-------|-----|---------|-----|
| `copyImageFromUrl` | ✅ | ✅ | ✅* | ✅ | ✅ | ⚠️ |
| `copyImageBytes` | ✅ | ✅ | ✅* | ✅ | ✅ | ⚠️ |
| `saveImageFromUrl` | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| `saveImageBytes` | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| `shareImageFromUrl` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `shareImageBytes` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

**Legend:**
- ✅ Fully supported
- ⚠️ Limited support (browser restrictions)
- ❌ Not supported
- \* Requires `xclip` installed on Linux

---

## Error Handling

All methods handle errors gracefully and return failure indicators instead of throwing exceptions:

```dart
// Example: Handle copy failure
final success = await handler.copyImageFromUrl('https://invalid-url.com/image.png');
if (!success) {
  print('Failed to copy image. Check your network connection and URL.');
}

// Example: Handle save failure
final path = await handler.saveImageFromUrl('https://example.com/image.png');
if (path == null) {
  print('Failed to save image. Check storage permissions.');
}
```

All errors are also logged using Flutter's `debugPrint` for debugging purposes.

---

## Type Definitions

### ImageClipboardHandler (Interface)

`SuperClipboardHandler` implements this interface from `hyper_render_core`:

```dart
abstract class ImageClipboardHandler {
  Future<bool> copyImageFromUrl(String imageUrl);
  Future<bool> copyImageBytes(Uint8List bytes, {String? mimeType});
  Future<String?> saveImageFromUrl(String imageUrl, {String? filename});
  Future<String?> saveImageBytes(Uint8List bytes, {String? filename});
  Future<bool> shareImageFromUrl(String imageUrl, {String? text});
  Future<bool> shareImageBytes(Uint8List bytes, {String? text, String? filename});
  bool get isImageCopySupported;
  bool get isSaveSupported;
  bool get isShareSupported;
  List<String> get supportedFormats;
}
```

---

## See Also

- [Usage Guide](usage_guide.md) - Detailed usage examples and patterns
- [Platform Setup Guide](platform_setup.md) - Platform-specific configuration
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
