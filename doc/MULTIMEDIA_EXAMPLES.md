# HyperRender Multimedia Integration Examples

This guide demonstrates how to integrate video, audio, iframes, and custom widgets into HyperRender v1.0.

## 🎯 What's Unique About HyperRender?

**HyperRender has a unique advantage over flutter_widget_from_html**: Perfect support for **CSS float with video/iframe elements**!

While FWFH struggles with floated media elements, HyperRender's architecture handles them naturally through the RenderHyperBox mechanism.

## 📋 Table of Contents

1. [Default Placeholders](#1-default-placeholders) - No code needed
2. [Video Player Integration](#2-video-player-integration) - Using `video_player` package
3. [WebView/IFrame Integration](#3-webviewiframe-integration) - Using `webview_flutter`
4. [Float Layout with Video](#4-float-layout-with-video) - Unique advantage!
5. [Custom Widget Integration](#5-custom-widget-integration) - Extend HTML with Flutter widgets

## Running the Examples

```bash
cd example
flutter run lib/multimedia_example.dart
```

## 1. Default Placeholders

**No custom implementation needed!** HyperRender provides beautiful default placeholders.

```dart
HyperViewer(
  html: '''
    <video src="sample.mp4" poster="poster.jpg" width="640" height="360"></video>
    <audio src="sample.mp3" title="My Audio Track"></audio>
  ''',
  // No mediaBuilder needed - default placeholders shown
)
```

**Features:**
- ✅ Hover effects
- ✅ Poster image support
- ✅ Play button overlay
- ✅ Title display
- ✅ Tap to open URL externally

## 2. Video Player Integration

Use `mediaBuilder` to plug in the `video_player` package.

### Setup

Add to `pubspec.yaml`:

```yaml
dependencies:
  video_player: ^2.8.0
```

### Implementation

```dart
HyperViewer(
  html: '''
    <video
      src="https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4"
      width="640"
      height="360"
      controls
      autoplay
      loop>
    </video>
  ''',
  mediaBuilder: (context, mediaInfo) {
    if (mediaInfo.isVideo) {
      return VideoPlayerWidget(
        mediaInfo: mediaInfo,
      );
    }
    // Fall back to default for audio
    return DefaultMediaWidget(mediaInfo: mediaInfo);
  },
)
```

### MediaInfo Properties

The `MediaInfo` object provides:

```dart
class MediaInfo {
  final MediaType type;        // audio or video
  final String src;             // Source URL
  final String? poster;         // Poster image
  final bool autoplay;          // Auto-play flag
  final bool loop;              // Loop flag
  final bool muted;             // Muted flag
  final bool controls;          // Show controls
  final double? width;          // Explicit width
  final double? height;         // Explicit height
  final String? title;          // Accessibility title
  final AtomicNode? node;       // Original node
}
```

## 3. WebView/IFrame Integration

Use `widgetBuilder` to detect `<iframe>` tags and render with `webview_flutter`.

### Setup

Add to `pubspec.yaml`:

```yaml
dependencies:
  webview_flutter: ^4.4.0
```

### Implementation

```dart
HyperViewer(
  html: '''
    <h2>YouTube Video</h2>
    <iframe
      src="https://www.youtube.com/embed/VIDEO_ID"
      width="640"
      height="360"
      frameborder="0"
      allowfullscreen>
    </iframe>

    <h2>Google Maps</h2>
    <iframe
      src="https://www.google.com/maps/embed?pb=..."
      width="640"
      height="400">
    </iframe>
  ''',
  widgetBuilder: (node) {
    if (node is AtomicNode && node.tagName == 'iframe') {
      final src = node.attributes['src'];
      if (src != null) {
        return IFrameWidget(
          src: src,
          width: node.intrinsicWidth ?? 640,
          height: node.intrinsicHeight ?? 400,
        );
      }
    }
    return null; // Let HyperRender handle other nodes
  },
)
```

### IFrameWidget Implementation

```dart
class IFrameWidget extends StatefulWidget {
  final String src;
  final double width;
  final double height;

  const IFrameWidget({
    super.key,
    required this.src,
    this.width = 640,
    this.height = 400,
  });

  @override
  State<IFrameWidget> createState() => _IFrameWidgetState();
}

class _IFrameWidgetState extends State<IFrameWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.src));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: WebViewWidget(controller: _controller),
    );
  }
}
```

## 4. Float Layout with Video

**🌟 UNIQUE ADVANTAGE: HyperRender supports CSS float for video/iframe!**

This is something flutter_widget_from_html struggles with.

```dart
HyperViewer(
  html: '''
    <h1>Article with Floated Video</h1>

    <video
      src="video.mp4"
      width="320"
      height="180"
      style="float: left; margin-right: 16px; margin-bottom: 8px;"
      controls>
    </video>

    <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit.
    Text wraps naturally around the floated video, just like in
    a web browser!</p>

    <p>More paragraphs continue flowing around the video...</p>

    <div style="clear: both;"></div>

    <h2>Float Right Example</h2>

    <iframe
      src="https://www.youtube.com/embed/VIDEO_ID"
      width="320"
      height="180"
      style="float: right; margin-left: 16px; margin-bottom: 8px;">
    </iframe>

    <p>This iframe is floated right. Text wraps on the left side.</p>
  ''',
  selectable: true,
)
```

**Why this works:**

HyperRender's architecture treats video/iframe as `AtomicNode` → `Widget` → `RenderBox` child, which integrates perfectly with the float layout algorithm in `RenderHyperBox`.

## 5. Custom Widget Integration

Extend HTML with your own interactive Flutter widgets!

```dart
HyperViewer(
  html: '''
    <h1>Interactive Content</h1>

    <p>Vote in our poll:</p>
    <vote-widget
      question="Is HyperRender awesome?"
      option1="Yes!"
      option2="Absolutely!">
    </vote-widget>

    <p>Check out this chart:</p>
    <chart-widget type="bar" data="10,20,30,40,50"></chart-widget>
  ''',
  widgetBuilder: (node) {
    // Custom vote widget
    if (node is AtomicNode && node.tagName == 'vote-widget') {
      return VoteWidget(
        question: node.attributes['question'] ?? 'Vote',
        option1: node.attributes['option1'] ?? 'Yes',
        option2: node.attributes['option2'] ?? 'No',
      );
    }

    // Custom chart widget
    if (node is AtomicNode && node.tagName == 'chart-widget') {
      final dataStr = node.attributes['data'] ?? '0';
      final data = dataStr.split(',')
        .map((e) => double.tryParse(e.trim()) ?? 0)
        .toList();
      return ChartWidget(data: data);
    }

    return null; // Let HyperRender handle other nodes
  },
)
```

## Architecture Overview

### Two Approaches for Multimedia

| Approach | Use Case | Callback |
|----------|----------|----------|
| **mediaBuilder** | Specifically for `<video>` and `<audio>` tags | `MediaWidgetBuilder` |
| **widgetBuilder** | Generic - any tag (`<iframe>`, custom elements) | `HyperWidgetBuilder` |

### Type Signatures

```dart
// For media elements (video/audio)
typedef MediaWidgetBuilder = Widget Function(
  BuildContext context,
  MediaInfo mediaInfo,
);

// For any UDT node
typedef HyperWidgetBuilder = Widget? Function(UDTNode node);
```

### How It Works

```
HTML
  ↓
HTML Parser
  ↓
UDTNode (AtomicNode for video/iframe)
  ↓
widgetBuilder/mediaBuilder callback
  ↓
Flutter Widget
  ↓
RenderHyperBox (MultiChildRenderObjectWidget)
  ↓
Widget is a RenderBox child → Full Flutter capabilities!
```

## Comparison with FWFH

| Feature | FWFH | HyperRender |
|---------|------|-------------|
| Default placeholders | ❌ Basic | ✅ Beautiful with hover |
| Video player integration | ⚠️ Possible but complex | ✅ Clean callback API |
| IFrame support | ⚠️ Limited | ✅ Full webview support |
| **Float layout with video** | ❌ **Broken/buggy** | ✅ **Perfect!** |
| Custom widgets | ⚠️ Via CustomWidgetBuilder | ✅ Via widgetBuilder |
| Interactive widgets | ⚠️ Limited | ✅ Full Flutter capabilities |

## Best Practices

### 1. Performance

```dart
// ✅ GOOD: Lazy load video players
widgetBuilder: (node) {
  if (node is AtomicNode && node.tagName == 'iframe') {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: 100)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return DefaultMediaWidget(mediaInfo: MediaInfo.fromNode(node));
        }
        return IFrameWidget(src: node.attributes['src']!);
      },
    );
  }
  return null;
}
```

### 2. Error Handling

```dart
// ✅ GOOD: Fall back to default on error
mediaBuilder: (context, mediaInfo) {
  try {
    return VideoPlayerWidget(mediaInfo: mediaInfo);
  } catch (e) {
    return DefaultMediaWidget(mediaInfo: mediaInfo);
  }
}
```

### 3. Memory Management

```dart
// ✅ GOOD: Dispose controllers in StatefulWidget
class VideoPlayerWidget extends StatefulWidget {
  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void dispose() {
    _controller.dispose(); // ← Important!
    super.dispose();
  }
}
```

## Future: hyper_render_media Plugin

We're planning a dedicated plugin:

```yaml
dependencies:
  hyper_render_media: ^1.0.0
```

```dart
import 'package:hyper_render_media/hyper_render_media.dart';

HyperViewer(
  html: htmlWithVideo,
  // One-line integration with sensible defaults:
  mediaBuilder: HyperMediaBuilder.videoPlayer(),
  // Or customize:
  mediaBuilder: HyperMediaBuilder.videoPlayer(
    autoplayPolicy: AutoplayPolicy.allowOnWiFi,
    cachingStrategy: CachingStrategy.aggressive,
  ),
)
```

## Contributing

Have a multimedia integration example to share? Submit a PR!

- Add your example to `multimedia_example.dart`
- Update this README
- Include screenshots/GIFs if possible

## License

MIT License - see [LICENSE](../LICENSE) for details.

---

**Questions?** Open an issue at https://github.com/vietnguyentuan/hyper_render/issues
