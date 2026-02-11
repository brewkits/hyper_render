# Usage Guide

This guide provides comprehensive examples of using the `hyper_render_clipboard` package in various scenarios.

## Table of Contents

- [Installation](#installation)
- [Basic Setup](#basic-setup)
- [Integration with HyperViewer](#integration-with-hyperviewer)
- [Standalone Usage](#standalone-usage)
- [Working with Image Bytes](#working-with-image-bytes)
- [Custom HTTP Client](#custom-http-client)
- [Error Handling](#error-handling)
- [Platform Detection](#platform-detection)
- [Advanced Usage](#advanced-usage)

---

## Installation

### 1. Add Dependencies

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  hyper_render: ^1.0.0
  hyper_render_clipboard: ^1.0.0
```

### 2. Install Packages

```bash
flutter pub get
```

### 3. Platform Setup

See [Platform Setup Guide](platform_setup.md) for platform-specific configuration.

---

## Basic Setup

Import the package in your Dart file:

```dart
import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';
```

Create an instance of `SuperClipboardHandler`:

```dart
final clipboardHandler = SuperClipboardHandler();
```

---

## Integration with HyperViewer

### Simple Integration

The most common use case is integrating with `HyperViewer` to enable image clipboard operations on rendered HTML content:

```dart
import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';

class MyContentPage extends StatelessWidget {
  const MyContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Content Viewer')),
      body: HyperViewer(
        html: '''
          <h1>My Document</h1>
          <p>Long-press images to copy, save, or share:</p>
          <img src="https://example.com/image.png" alt="Example">
        ''',
        imageClipboardHandler: SuperClipboardHandler(),
      ),
    );
  }
}
```

### With Custom Context Menu

Handle image long-press events to show a custom context menu:

```dart
HyperViewer(
  html: htmlContent,
  imageClipboardHandler: SuperClipboardHandler(),
  onImageLongPress: (imageUrl, handler) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ImageActionSheet(
        imageUrl: imageUrl,
        handler: handler,
      ),
    );
  },
)
```

### Custom Action Sheet Widget

```dart
class _ImageActionSheet extends StatelessWidget {
  final String imageUrl;
  final ImageClipboardHandler handler;

  const _ImageActionSheet({
    required this.imageUrl,
    required this.handler,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (handler.isImageCopySupported)
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Image'),
              onTap: () async {
                Navigator.pop(context);
                final success = await handler.copyImageFromUrl(imageUrl);
                if (context.mounted) {
                  _showSnackBar(
                    context,
                    success ? 'Image copied!' : 'Failed to copy',
                  );
                }
              },
            ),
          if (handler.isSaveSupported)
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('Save Image'),
              onTap: () async {
                Navigator.pop(context);
                final path = await handler.saveImageFromUrl(imageUrl);
                if (context.mounted) {
                  _showSnackBar(
                    context,
                    path != null ? 'Saved to: $path' : 'Failed to save',
                  );
                }
              },
            ),
          if (handler.isShareSupported)
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Image'),
              onTap: () async {
                Navigator.pop(context);
                final success = await handler.shareImageFromUrl(imageUrl);
                if (context.mounted && !success) {
                  _showSnackBar(context, 'Failed to share');
                }
              },
            ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
```

---

## Standalone Usage

### Copy Image from URL

```dart
import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';

Future<void> copyImageExample() async {
  final handler = SuperClipboardHandler();

  final success = await handler.copyImageFromUrl(
    'https://example.com/image.png'
  );

  if (success) {
    print('Image copied to clipboard');
  } else {
    print('Failed to copy image');
  }
}
```

### Save Image to Device

```dart
Future<void> saveImageExample() async {
  final handler = SuperClipboardHandler();

  // Save with auto-generated filename
  final path = await handler.saveImageFromUrl(
    'https://example.com/nature.jpg'
  );

  if (path != null) {
    print('Image saved to: $path');
  } else {
    print('Failed to save image');
  }
}
```

### Save with Custom Filename

```dart
Future<void> saveWithCustomName() async {
  final handler = SuperClipboardHandler();

  final path = await handler.saveImageFromUrl(
    'https://example.com/photo.jpg',
    filename: 'my_vacation_photo.jpg',
  );

  if (path != null) {
    print('Image saved as: $path');
  }
}
```

### Share Image

```dart
Future<void> shareImageExample() async {
  final handler = SuperClipboardHandler();

  final success = await handler.shareImageFromUrl(
    'https://example.com/image.png',
    text: 'Check out this amazing image!',
  );

  if (success) {
    print('Share dialog opened');
  }
}
```

---

## Working with Image Bytes

### Copy Bytes to Clipboard

Useful for copying screenshots or generated images:

```dart
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';

Future<void> copyScreenshot(RenderRepaintBoundary boundary) async {
  // Capture widget as image
  final image = await boundary.toImage(pixelRatio: 3.0);
  final byteData = await image.toByteData(format: ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  // Copy to clipboard
  final handler = SuperClipboardHandler();
  final success = await handler.copyImageBytes(
    bytes,
    mimeType: 'image/png',
  );

  if (success) {
    print('Screenshot copied to clipboard');
  }
}
```

### Save Generated Image

```dart
Future<void> saveGeneratedImage(Uint8List imageBytes) async {
  final handler = SuperClipboardHandler();

  final path = await handler.saveImageBytes(
    imageBytes,
    filename: 'generated_${DateTime.now().millisecondsSinceEpoch}.png',
  );

  if (path != null) {
    print('Image saved to: $path');
  }
}
```

### Share Image Bytes

```dart
Future<void> shareImageBytes(Uint8List imageBytes) async {
  final handler = SuperClipboardHandler();

  await handler.shareImageBytes(
    imageBytes,
    text: 'Created with my app!',
    filename: 'artwork.png',
  );
}
```

### Complete Screenshot Example

```dart
class ScreenshotWidget extends StatefulWidget {
  const ScreenshotWidget({super.key});

  @override
  State<ScreenshotWidget> createState() => _ScreenshotWidgetState();
}

class _ScreenshotWidgetState extends State<ScreenshotWidget> {
  final GlobalKey _boundaryKey = GlobalKey();
  final _handler = SuperClipboardHandler();

  Future<void> _captureAndCopy() async {
    try {
      // Find the RenderRepaintBoundary
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;

      // Capture as image
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Copy to clipboard
      final success = await _handler.copyImageBytes(bytes, mimeType: 'image/png');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Copied to clipboard!' : 'Copy failed'),
          ),
        );
      }
    } catch (e) {
      print('Error capturing screenshot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(
          key: _boundaryKey,
          child: Container(
            width: 300,
            height: 300,
            color: Colors.blue,
            child: const Center(
              child: Text('Capture me!', style: TextStyle(fontSize: 24)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _captureAndCopy,
          child: const Text('Capture & Copy'),
        ),
      ],
    );
  }
}
```

---

## Custom HTTP Client

Use a custom HTTP client for advanced network configuration:

```dart
import 'package:http/http.dart' as http;

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late final ImageClipboardHandler _handler;
  late final http.Client _httpClient;

  @override
  void initState() {
    super.initState();
    // Create custom HTTP client with timeout
    _httpClient = http.Client();
    _handler = SuperClipboardHandler(httpClient: _httpClient);
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HyperViewer(
      html: htmlContent,
      imageClipboardHandler: _handler,
    );
  }
}
```

### Custom HTTP Client with Headers

```dart
import 'package:http/http.dart' as http;

class AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final String authToken;

  AuthenticatedHttpClient(this.authToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $authToken';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

// Usage
final authClient = AuthenticatedHttpClient('your-token');
final handler = SuperClipboardHandler(httpClient: authClient);
```

---

## Error Handling

### Basic Error Handling

```dart
Future<void> handleImageOperation() async {
  final handler = SuperClipboardHandler();

  final success = await handler.copyImageFromUrl(
    'https://example.com/image.png'
  );

  if (!success) {
    // Handle error
    print('Failed to copy image. Possible reasons:');
    print('- Network error');
    print('- Invalid URL');
    print('- Clipboard not available');
    print('- Unsupported platform');
  }
}
```

### With User Feedback

```dart
Future<void> copyWithFeedback(BuildContext context) async {
  final handler = SuperClipboardHandler();

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final success = await handler.copyImageFromUrl(
      'https://example.com/large-image.jpg'
    );

    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Image copied to clipboard!'
                : 'Failed to copy image. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### Retry Logic

```dart
Future<bool> copyImageWithRetry(
  String imageUrl, {
  int maxRetries = 3,
}) async {
  final handler = SuperClipboardHandler();

  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    print('Attempt $attempt of $maxRetries');

    final success = await handler.copyImageFromUrl(imageUrl);
    if (success) {
      return true;
    }

    if (attempt < maxRetries) {
      await Future.delayed(Duration(seconds: attempt));
    }
  }

  return false;
}
```

---

## Platform Detection

Check platform capabilities before performing operations:

```dart
import 'package:flutter/foundation.dart';
import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';

class ImageToolbar extends StatelessWidget {
  final String imageUrl;
  final ImageClipboardHandler handler;

  const ImageToolbar({
    super.key,
    required this.imageUrl,
    required this.handler,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Show copy button only if supported
        if (handler.isImageCopySupported)
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyImage(context),
            tooltip: 'Copy Image',
          ),

        // Show save button only if supported
        if (handler.isSaveSupported)
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveImage(context),
            tooltip: 'Save Image',
          ),

        // Share is available on all platforms
        if (handler.isShareSupported)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareImage(context),
            tooltip: 'Share Image',
          ),
      ],
    );
  }

  Future<void> _copyImage(BuildContext context) async {
    final success = await handler.copyImageFromUrl(imageUrl);
    if (context.mounted) {
      _showMessage(context, success ? 'Copied!' : 'Copy failed');
    }
  }

  Future<void> _saveImage(BuildContext context) async {
    final path = await handler.saveImageFromUrl(imageUrl);
    if (context.mounted) {
      _showMessage(
        context,
        path != null ? 'Saved to $path' : 'Save failed',
      );
    }
  }

  Future<void> _shareImage(BuildContext context) async {
    await handler.shareImageFromUrl(imageUrl);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
```

### Platform-Specific Logic

```dart
Future<void> handleImage(String imageUrl) async {
  final handler = SuperClipboardHandler();

  if (kIsWeb) {
    // Web has limited clipboard support, prefer share
    await handler.shareImageFromUrl(imageUrl);
  } else if (defaultTargetPlatform == TargetPlatform.iOS ||
             defaultTargetPlatform == TargetPlatform.android) {
    // Mobile: offer both copy and share
    // Show action sheet with both options
  } else {
    // Desktop: prefer copy
    await handler.copyImageFromUrl(imageUrl);
  }
}
```

---

## Advanced Usage

### Batch Operations

Process multiple images:

```dart
Future<void> copyMultipleImages(List<String> imageUrls) async {
  final handler = SuperClipboardHandler();
  final results = <String, bool>{};

  for (final url in imageUrls) {
    print('Processing: $url');
    final success = await handler.copyImageFromUrl(url);
    results[url] = success;
  }

  final successCount = results.values.where((v) => v).length;
  print('Successfully copied $successCount of ${imageUrls.length} images');
}
```

### Progress Tracking

```dart
class ImageDownloader extends StatefulWidget {
  final List<String> imageUrls;

  const ImageDownloader({super.key, required this.imageUrls});

  @override
  State<ImageDownloader> createState() => _ImageDownloaderState();
}

class _ImageDownloaderState extends State<ImageDownloader> {
  final _handler = SuperClipboardHandler();
  double _progress = 0.0;
  String _status = '';

  Future<void> _downloadAll() async {
    for (int i = 0; i < widget.imageUrls.length; i++) {
      setState(() {
        _status = 'Saving image ${i + 1} of ${widget.imageUrls.length}...';
        _progress = (i + 1) / widget.imageUrls.length;
      });

      await _handler.saveImageFromUrl(widget.imageUrls[i]);
    }

    setState(() {
      _status = 'Complete!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(value: _progress),
        Text(_status),
        ElevatedButton(
          onPressed: _downloadAll,
          child: const Text('Download All'),
        ),
      ],
    );
  }
}
```

### Format Detection

```dart
Future<void> copyImageWithFormatDetection(String imageUrl) async {
  final handler = SuperClipboardHandler();

  // Detect format from URL
  final extension = imageUrl.split('.').last.toLowerCase();
  final mimeType = _getMimeType(extension);

  print('Detected format: $mimeType');

  if (handler.supportedFormats.contains(mimeType)) {
    await handler.copyImageFromUrl(imageUrl);
  } else {
    print('Unsupported format: $mimeType');
  }
}

String _getMimeType(String extension) {
  switch (extension) {
    case 'png': return 'image/png';
    case 'jpg':
    case 'jpeg': return 'image/jpeg';
    case 'gif': return 'image/gif';
    case 'webp': return 'image/webp';
    case 'bmp': return 'image/bmp';
    default: return 'image/unknown';
  }
}
```

---

## Best Practices

### 1. Reuse Handler Instances

```dart
// Good: Reuse the same handler instance
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _handler = SuperClipboardHandler(); // Reuse

  @override
  Widget build(BuildContext context) {
    return HyperViewer(
      html: content,
      imageClipboardHandler: _handler,
    );
  }
}
```

### 2. Always Check Platform Support

```dart
// Good: Check before using
if (handler.isImageCopySupported) {
  await handler.copyImageFromUrl(url);
}

// Bad: Assume support
await handler.copyImageFromUrl(url); // May fail on Web
```

### 3. Provide User Feedback

```dart
// Good: Show feedback
final success = await handler.copyImageFromUrl(url);
if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(success ? 'Copied!' : 'Failed')),
  );
}

// Bad: Silent operation
await handler.copyImageFromUrl(url); // User doesn't know what happened
```

### 4. Handle Async Properly

```dart
// Good: Await and handle
Future<void> copyImage() async {
  final success = await handler.copyImageFromUrl(url);
  if (!success) {
    // Handle error
  }
}

// Bad: Fire and forget
handler.copyImageFromUrl(url); // Don't ignore the Future
```

---

## Next Steps

- Review the [API Reference](api_reference.md) for detailed method documentation
- Check [Platform Setup Guide](platform_setup.md) for platform-specific configuration
- See [Troubleshooting](troubleshooting.md) for common issues
