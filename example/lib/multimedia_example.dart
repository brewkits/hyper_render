import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';
// Uncomment these when adding video_player and webview_flutter to pubspec.yaml:
// import 'package:video_player/video_player.dart';
// import 'package:webview_flutter/webview_flutter.dart';

/// Comprehensive multimedia integration example for HyperRender v2.0
///
/// This example demonstrates:
/// 1. Video player integration using video_player package
/// 2. WebView/IFrame integration using webview_flutter
/// 3. Float layout with video (unique advantage over FWFH)
/// 4. Both approaches: mediaBuilder and widgetBuilder
///
/// To run this example, add to pubspec.yaml:
/// ```yaml
/// dependencies:
///   video_player: ^2.8.0
///   webview_flutter: ^4.4.0
/// ```

// ============================================================================
// Error Handling Helpers
// ============================================================================

/// Validates if a URL is safe and well-formed
// ignore: unused_element
bool _isValidUrl(String? url) {
  if (url == null || url.isEmpty) return false;

  final uri = Uri.tryParse(url);
  if (uri == null) return false;

  // Must have a scheme (http, https, etc.)
  if (!uri.hasScheme) return false;

  // Must have a host
  if (uri.host.isEmpty) return false;

  return true;
}

/// Creates a beautiful error widget for failed media loading
Widget _buildMediaErrorWidget(String message, {String? details}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      border: Border.all(color: Colors.red.shade200),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            color: Colors.red.shade900,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        if (details != null) ...[
          const SizedBox(height: 4),
          Text(
            details,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    ),
  );
}

/// Safe widget builder wrapper with error handling
Widget? _safeWidgetBuilder(
  Widget? Function() builder, {
  required String context,
}) {
  try {
    return builder();
  } catch (e, stackTrace) {
    // Log error in debug mode
    assert(() {
      print('Error in $context: $e');
      print(stackTrace);
      return true;
    }());

    // Return error widget
    return _buildMediaErrorWidget(
      'Widget failed to load',
      details: 'Error in $context: ${e.toString()}',
    );
  }
}

void main() {
  runApp(const MultimediaExampleApp());
}

class MultimediaExampleApp extends StatelessWidget {
  const MultimediaExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperRender Multimedia Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MultimediaExamplesPage(),
    );
  }
}

class MultimediaExamplesPage extends StatefulWidget {
  const MultimediaExamplesPage({super.key});

  @override
  State<MultimediaExamplesPage> createState() => _MultimediaExamplesPageState();
}

class _MultimediaExamplesPageState extends State<MultimediaExamplesPage> {
  int _selectedExample = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HyperRender Multimedia Examples'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Row(
        children: [
          // Sidebar navigation
          NavigationRail(
            selectedIndex: _selectedExample,
            onDestinationSelected: (index) {
              setState(() => _selectedExample = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.play_circle_outline),
                label: Text('Default Placeholder'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.video_library),
                label: Text('Video Player'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.web),
                label: Text('WebView/IFrame'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.view_quilt),
                label: Text('Float Layout'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.widgets),
                label: Text('Custom Widgets'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Content area
          Expanded(
            child: _buildExample(_selectedExample),
          ),
        ],
      ),
    );
  }

  Widget _buildExample(int index) {
    switch (index) {
      case 0:
        return const DefaultPlaceholderExample();
      case 1:
        return const VideoPlayerExample();
      case 2:
        return const WebViewExample();
      case 3:
        return const FloatLayoutExample();
      case 4:
        return const CustomWidgetExample();
      default:
        return const SizedBox.shrink();
    }
  }
}

// ============================================================================
// Example 1: Default Placeholder (No custom implementation)
// ============================================================================

class DefaultPlaceholderExample extends StatelessWidget {
  const DefaultPlaceholderExample({super.key});

  @override
  Widget build(BuildContext context) {
    const html = '''
      <h1>Default Media Placeholders</h1>
      <p>HyperRender provides beautiful default placeholders for video and audio elements when no custom mediaBuilder is provided.</p>

      <h2>Video Placeholder</h2>
      <video
        src="https://example.com/sample.mp4"
        poster="https://picsum.photos/640/360"
        width="640"
        height="360"
        title="Sample Video Title">
      </video>

      <h2>Audio Placeholder</h2>
      <audio
        src="https://example.com/sample.mp3"
        title="Sample Audio Track"
        controls>
      </audio>

      <p>Tap the placeholders to open the media URL externally.</p>
    ''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ExampleHeader(
            title: 'Default Placeholder',
            description: 'No custom implementation needed. HyperRender shows beautiful placeholders with hover effects.',
          ),
          const SizedBox(height: 24),
          HyperViewer(
            html: html,
            selectable: true,
            // No mediaBuilder = default placeholder
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Example 2: Video Player Integration
// ============================================================================

class VideoPlayerExample extends StatelessWidget {
  const VideoPlayerExample({super.key});

  @override
  Widget build(BuildContext context) {
    const html = '''
      <h1>Video Player Integration</h1>
      <p>Integrate <code>video_player</code> package using <code>mediaBuilder</code> callback.</p>

      <h2>Sample Video</h2>
      <video
        src="https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4"
        poster="https://picsum.photos/640/360"
        width="640"
        height="360"
        controls
        autoplay
        loop>
      </video>

      <p>The video player is fully functional with controls.</p>
    ''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ExampleHeader(
            title: 'Video Player Integration',
            description: 'Use mediaBuilder to plug in video_player package for real video playback.',
          ),
          const SizedBox(height: 24),
          HyperViewer(
            html: html,
            selectable: true,
            // Uncomment when video_player is added to dependencies:
            /*
            mediaBuilder: (context, mediaInfo) {
              if (mediaInfo.isVideo) {
                return VideoPlayerWidget(
                  mediaInfo: mediaInfo,
                );
              }
              // Fall back to default for audio
              return DefaultMediaWidget(mediaInfo: mediaInfo);
            },
            */
          ),
          const SizedBox(height: 24),
          const _CodeExample(
            title: 'Implementation',
            code: '''
// Add to pubspec.yaml:
// dependencies:
//   video_player: ^2.8.0

HyperViewer(
  html: htmlWithVideo,
  mediaBuilder: (context, mediaInfo) {
    if (mediaInfo.isVideo) {
      return VideoPlayerWidget(
        src: mediaInfo.src,
        autoplay: mediaInfo.autoplay,
        loop: mediaInfo.loop,
        controls: mediaInfo.controls,
      );
    }
    return DefaultMediaWidget(mediaInfo: mediaInfo);
  },
)
''',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Example 3: WebView/IFrame Integration
// ============================================================================

class WebViewExample extends StatelessWidget {
  const WebViewExample({super.key});

  @override
  Widget build(BuildContext context) {
    const html = '''
      <h1>WebView & IFrame Integration</h1>
      <p>Embed YouTube videos, Google Maps, or any iframe content using <code>widgetBuilder</code>.</p>

      <h2>YouTube Embed</h2>
      <iframe
        src="https://www.youtube.com/embed/dQw4w9WgXcQ"
        width="640"
        height="360"
        frameborder="0"
        allowfullscreen>
      </iframe>

      <h2>Google Maps</h2>
      <iframe
        src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3919.954!2d106.6297!3d10.7629!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zMTDCsDQ1JzQ2LjQiTiAxMDbCsDM3JzQ2LjkiRQ!5e0!3m2!1sen!2s!4v1234567890"
        width="640"
        height="400"
        frameborder="0">
      </iframe>
    ''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ExampleHeader(
            title: 'WebView/IFrame Integration',
            description: 'Use widgetBuilder to detect iframe tags and render them using webview_flutter.',
          ),
          const SizedBox(height: 24),
          HyperViewer(
            html: html,
            selectable: true,
            // Uncomment when webview_flutter is added:
            /*
            widgetBuilder: (node) {
              if (node is AtomicNode && node.tagName == 'iframe') {
                return _safeWidgetBuilder(
                  () {
                    final src = node.attributes['src'];

                    // Validate URL
                    if (!_isValidUrl(src)) {
                      return _buildMediaErrorWidget(
                        'Invalid IFrame URL',
                        details: src == null || src.isEmpty
                            ? 'No src attribute provided'
                            : 'Invalid URL: $src',
                      );
                    }

                    return IFrameWidget(
                      src: src!,
                      width: node.intrinsicWidth ?? 640,
                      height: node.intrinsicHeight ?? 400,
                    );
                  },
                  context: 'IFrame widget',
                );
              }
              return null; // Let HyperRender handle other nodes
            },
            */
          ),
          const SizedBox(height: 24),
          const _CodeExample(
            title: 'Implementation with Error Handling',
            code: '''
// Add to pubspec.yaml:
// dependencies:
//   webview_flutter: ^4.4.0

HyperViewer(
  html: htmlWithIframes,
  widgetBuilder: (node) {
    if (node is AtomicNode && node.tagName == 'iframe') {
      // Safe widget building with error handling
      return _safeWidgetBuilder(
        () {
          final src = node.attributes['src'];

          // ✅ Validate URL before using
          if (!_isValidUrl(src)) {
            return _buildErrorWidget(
              'Invalid IFrame URL',
              details: src ?? 'No src provided',
            );
          }

          return IFrameWidget(
            src: src!,
            width: node.intrinsicWidth ?? 640,
            height: node.intrinsicHeight ?? 400,
          );
        },
        context: 'IFrame widget',
      );
    }
    return null;
  },
)
''',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Example 4: Float Layout with Video (Unique Advantage!)
// ============================================================================

class FloatLayoutExample extends StatelessWidget {
  const FloatLayoutExample({super.key});

  @override
  Widget build(BuildContext context) {
    const html = '''
      <h1>Float Layout with Video</h1>
      <p><strong>Unique Advantage:</strong> HyperRender supports CSS float for video and iframe elements!</p>

      <video
        src="https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4"
        width="320"
        height="180"
        style="float: left; margin-right: 16px; margin-bottom: 8px;"
        controls>
      </video>

      <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.</p>

      <p>Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>

      <p>Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>

      <div style="clear: both;"></div>

      <h2>Float Right Example</h2>

      <iframe
        src="https://www.youtube.com/embed/dQw4w9WgXcQ"
        width="320"
        height="180"
        style="float: right; margin-left: 16px; margin-bottom: 8px;">
      </iframe>

      <p>This is a floated iframe on the right. Text wraps around it naturally, just like in a web browser! This is a unique capability that flutter_widget_from_html doesn't support well.</p>

      <p>Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.</p>

      <p>Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.</p>
    ''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ExampleHeader(
            title: 'Float Layout with Video',
            description: 'HyperRender\'s unique advantage: CSS float works perfectly with video and iframe!',
            highlight: true,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border.all(color: Colors.amber.shade700),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'UNIQUE ADVANTAGE: FWFH struggles with floated media. HyperRender handles it perfectly!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          HyperViewer(
            html: html,
            selectable: true,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Example 5: Custom Widget Integration
// ============================================================================

class CustomWidgetExample extends StatelessWidget {
  const CustomWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    const html = '''
      <h1>Custom Interactive Widgets</h1>
      <p>Use <code>widgetBuilder</code> to inject any custom Flutter widget into your HTML content.</p>

      <h2>Custom Vote Widget</h2>
      <vote-widget question="Is HyperRender awesome?" option1="Yes!" option2="Absolutely!"></vote-widget>

      <h2>Custom Chart Widget</h2>
      <chart-widget type="bar" data="10,20,30,40,50"></chart-widget>

      <p>These custom elements are rendered as interactive Flutter widgets, not static placeholders!</p>
    ''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ExampleHeader(
            title: 'Custom Widget Integration',
            description: 'Extend HTML with your own custom interactive widgets using widgetBuilder.',
          ),
          const SizedBox(height: 24),
          HyperViewer(
            html: html,
            selectable: true,
            widgetBuilder: (node) {
              // Handle custom vote widget
              if (node is AtomicNode && node.tagName == 'vote-widget') {
                return _safeWidgetBuilder(
                  () {
                    return VoteWidget(
                      question: node.attributes['question'] ?? 'Vote',
                      option1: node.attributes['option1'] ?? 'Yes',
                      option2: node.attributes['option2'] ?? 'No',
                    );
                  },
                  context: 'Vote widget',
                );
              }

              // Handle custom chart widget
              if (node is AtomicNode && node.tagName == 'chart-widget') {
                return _safeWidgetBuilder(
                  () {
                    final dataStr = node.attributes['data'];

                    // Validate data attribute
                    if (dataStr == null || dataStr.isEmpty) {
                      return _buildMediaErrorWidget(
                        'Chart Data Missing',
                        details: 'No data attribute provided for chart',
                      );
                    }

                    // Parse data safely
                    final data = dataStr
                        .split(',')
                        .map((e) => double.tryParse(e.trim()) ?? 0)
                        .toList();

                    // Validate parsed data
                    if (data.isEmpty) {
                      return _buildMediaErrorWidget(
                        'Invalid Chart Data',
                        details: 'Could not parse data: $dataStr',
                      );
                    }

                    return ChartWidget(data: data);
                  },
                  context: 'Chart widget',
                );
              }

              return null; // Let HyperRender handle other nodes
            },
          ),
          const SizedBox(height: 24),
          const _CodeExample(
            title: 'Implementation with Error Handling',
            code: '''
HyperViewer(
  html: htmlWithCustomElements,
  widgetBuilder: (node) {
    if (node is AtomicNode && node.tagName == 'vote-widget') {
      // ✅ Wrap in safe builder for error handling
      return _safeWidgetBuilder(
        () => VoteWidget(
          question: node.attributes['question'] ?? 'Vote',
          option1: node.attributes['option1'] ?? 'Yes',
          option2: node.attributes['option2'] ?? 'No',
        ),
        context: 'Vote widget',
      );
    }

    if (node is AtomicNode && node.tagName == 'chart-widget') {
      return _safeWidgetBuilder(
        () {
          final dataStr = node.attributes['data'];

          // ✅ Validate data exists
          if (dataStr == null || dataStr.isEmpty) {
            return _buildErrorWidget(
              'Chart Data Missing',
              details: 'No data attribute',
            );
          }

          // ✅ Parse and validate
          final data = dataStr
              .split(',')
              .map((e) => double.tryParse(e.trim()) ?? 0)
              .toList();

          if (data.isEmpty) {
            return _buildErrorWidget(
              'Invalid Chart Data',
              details: dataStr,
            );
          }

          return ChartWidget(data: data);
        },
        context: 'Chart widget',
      );
    }

    return null; // Let HyperRender handle other nodes
  },
)
''',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Helper Widgets
// ============================================================================

class _ExampleHeader extends StatelessWidget {
  final String title;
  final String description;
  final bool highlight;

  const _ExampleHeader({
    required this.title,
    required this.description,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? Colors.deepPurple.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: highlight ? Colors.deepPurple.shade700 : null,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CodeExample extends StatelessWidget {
  final String title;
  final String code;

  const _CodeExample({
    required this.title,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.greenAccent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Custom Widget Implementations
// ============================================================================

class VoteWidget extends StatefulWidget {
  final String question;
  final String option1;
  final String option2;

  const VoteWidget({
    super.key,
    required this.question,
    required this.option1,
    required this.option2,
  });

  @override
  State<VoteWidget> createState() => _VoteWidgetState();
}

class _VoteWidgetState extends State<VoteWidget> {
  int _votes1 = 42;
  int _votes2 = 28;
  bool _hasVoted = false;

  void _vote(int option) {
    if (_hasVoted) return;
    setState(() {
      if (option == 1) {
        _votes1++;
      } else {
        _votes2++;
      }
      _hasVoted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _votes1 + _votes2;
    final percent1 = (total > 0 ? (_votes1 / total * 100) : 0).toStringAsFixed(0);
    final percent2 = (total > 0 ? (_votes2 / total * 100) : 0).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.deepPurple.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildOption(1, widget.option1, _votes1, percent1),
          const SizedBox(height: 8),
          _buildOption(2, widget.option2, _votes2, percent2),
          if (_hasVoted) ...[
            const SizedBox(height: 12),
            Text(
              'Thanks for voting! Total votes: $total',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOption(int option, String label, int votes, String percent) {
    final isSelected = _hasVoted;

    return InkWell(
      onTap: () => _vote(option),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                '$votes ($percent%)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ChartWidget extends StatelessWidget {
  final List<double> data;

  const ChartWidget({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: data.map((value) {
          final barHeight = maxValue > 0 ? (value / maxValue * 150) : 0.0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: barHeight,
                decoration: BoxDecoration(
                  color: Colors.blue.shade400,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// Video Player Widget (Stub - requires video_player package)
// ============================================================================

/* Uncomment when video_player is added to pubspec.yaml:

class VideoPlayerWidget extends StatefulWidget {
  final MediaInfo mediaInfo;

  const VideoPlayerWidget({
    super.key,
    required this.mediaInfo,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.mediaInfo.src),
      );

      await _controller.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);
      }

      if (widget.mediaInfo.autoplay) {
        _controller.play();
      }

      if (widget.mediaInfo.loop) {
        _controller.setLooping(true);
      }

      if (widget.mediaInfo.muted) {
        _controller.setVolume(0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return DefaultMediaWidget(mediaInfo: widget.mediaInfo);
    }

    if (!_isInitialized) {
      return SizedBox(
        width: widget.mediaInfo.width ?? 640,
        height: widget.mediaInfo.height ?? 360,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      width: widget.mediaInfo.width ?? 640,
      height: widget.mediaInfo.height ?? 360,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          if (widget.mediaInfo.controls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _VideoControls(controller: _controller),
            ),
        ],
      ),
    );
  }
}

class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoControls({required this.controller});

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.controller.value.position;
    final duration = widget.controller.value.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (widget.controller.value.isPlaying) {
                  widget.controller.pause();
                } else {
                  widget.controller.play();
                }
              });
            },
          ),
          Expanded(
            child: Slider(
              value: progress,
              onChanged: (value) {
                final position = duration * value;
                widget.controller.seekTo(position);
              },
              activeColor: Colors.white,
              inactiveColor: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${_formatDuration(position)} / ${_formatDuration(duration)}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
*/

// ============================================================================
// IFrame Widget (Stub - requires webview_flutter package)
// ============================================================================

/* Uncomment when webview_flutter is added to pubspec.yaml:

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
*/
