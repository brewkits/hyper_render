/// HyperRender Clipboard Plugin Example
///
/// This example shows how to enable full image clipboard support.
library;

import 'package:flutter/material.dart';
// In a real app:
// import 'package:hyper_render/hyper_render.dart';
// import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperRender Clipboard Example',
      home: const ClipboardExamplePage(),
    );
  }
}

class ClipboardExamplePage extends StatelessWidget {
  const ClipboardExamplePage({super.key});

  static const String htmlWithImages = '''
<html>
<body>
  <h1>Image Clipboard Demo</h1>

  <p>Long-press on any image to see the context menu with these options:</p>
  <ul>
    <li><strong>Copy Image</strong> - Copies the actual image to clipboard</li>
    <li><strong>Save Image</strong> - Saves to device storage</li>
    <li><strong>Share Image</strong> - Opens system share dialog</li>
  </ul>

  <h2>Sample Images</h2>

  <img src="https://picsum.photos/400/300" alt="Random image 1">
  <p><em>A random landscape image</em></p>

  <img src="https://picsum.photos/300/400" alt="Random image 2">
  <p><em>A random portrait image</em></p>

</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Clipboard')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Image Clipboard Plugin',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'This plugin enables full image clipboard support using super_clipboard:\n\n'
              '- Copy actual image data (not just URLs)\n'
              '- Save images to device storage\n'
              '- Share images via system dialog\n\n'
              'Platform Support:\n'
              '- macOS: Full support\n'
              '- Windows: Full support\n'
              '- Linux: Full support (requires xclip)\n'
              '- iOS: Copy/Share support\n'
              '- Android: Copy/Share support\n'
              '- Web: Limited support',
            ),
          ],
        ),
      ),
      // In a real app:
      // body: HyperViewer(
      //   content: htmlWithImages,
      //   imageClipboardHandler: SuperClipboardHandler(),
      //   onImageLongPress: (imageUrl, handler) {
      //     showModalBottomSheet(
      //       context: context,
      //       builder: (context) => ImageActionSheet(
      //         imageUrl: imageUrl,
      //         handler: handler,
      //       ),
      //     );
      //   },
      // ),
    );
  }
}

/// Usage example:
///
/// ```dart
/// import 'package:hyper_render/hyper_render.dart';
/// import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';
///
/// class MyPage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return HyperViewer(
///       html: '<img src="https://example.com/image.png">',
///       imageClipboardHandler: SuperClipboardHandler(),
///     );
///   }
/// }
/// ```
///
/// Manual usage:
///
/// ```dart
/// final handler = SuperClipboardHandler();
///
/// // Copy image from URL
/// await handler.copyImageFromUrl('https://example.com/image.png');
///
/// // Save image
/// final path = await handler.saveImageFromUrl(
///   'https://example.com/image.png',
///   filename: 'my_image.png',
/// );
/// print('Saved to: $path');
///
/// // Share image
/// await handler.shareImageFromUrl(
///   'https://example.com/image.png',
///   text: 'Check out this image!',
/// );
/// ```
