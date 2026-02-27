import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:url_launcher/url_launcher.dart';

/// Improved Video Demo with Functional Video Playback
///
/// Features:
/// - Proper mediaBuilder integration for video tap handling
/// - Opens videos in external player (browser/video app)
/// - Beautiful placeholder with poster images
/// - Multiple video layouts (single, grid, floated)
/// - Responsive sizing
class ImprovedVideoDemo extends StatelessWidget {
  const ImprovedVideoDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video & Media Demo (Improved)'),
        centerTitle: false,
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // Video with poster
          _buildSection(
            title: '1. Video with Poster Image',
            description: 'Tap video to open in external player (browser/video player)',
            child: HyperViewer(
              html: '''
                <video
                  src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                  poster="https://peach.blender.org/wp-content/uploads/title_anouncement.jpg"
                  width="640"
                  height="360"
                  controls>
                </video>
              ''',
              widgetBuilder: (node) {
                if (node is AtomicNode && (node.tagName == 'video' || node.tagName == 'audio')) {
                  final mediaInfo = MediaInfo.fromNode(node);
                  return _buildInteractiveMedia(context, mediaInfo);
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 24),

          // Video without poster
          _buildSection(
            title: '2. Video without Poster',
            description: 'Shows default placeholder with play button',
            child: HyperViewer(
              html: '''
                <video
                  src="https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4"
                  width="640"
                  height="360"
                  controls>
                </video>
              ''',
              widgetBuilder: (node) {
                if (node is AtomicNode && (node.tagName == 'video' || node.tagName == 'audio')) {
                  final mediaInfo = MediaInfo.fromNode(node);
                  return _buildInteractiveMedia(context, mediaInfo);
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 24),

          // Multiple videos in grid
          _buildSection(
            title: '3. Video Grid Layout',
            description: 'Multiple videos in grid - responsive layout',
            child: HyperViewer(
              html: '''
                <div style="display: flex; gap: 16px; flex-wrap: wrap; justify-content: center;">
                  <video
                    src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
                    poster="https://storage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg"
                    width="300"
                    height="200"
                    controls>
                  </video>

                  <video
                    src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
                    poster="https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg"
                    width="300"
                    height="200"
                    controls>
                  </video>

                  <video
                    src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"
                    poster="https://storage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg"
                    width="300"
                    height="200"
                    controls>
                  </video>
                </div>
              ''',
              widgetBuilder: (node) {
                if (node is AtomicNode && (node.tagName == 'video' || node.tagName == 'audio')) {
                  final mediaInfo = MediaInfo.fromNode(node);
                  return _buildInteractiveMedia(context, mediaInfo);
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 24),

          // Floated video with text wrapping
          _buildSection(
            title: '4. Float Layout with Video (Unique Feature!)',
            description: 'Video float left with text wrapping - unique feature of HyperRender',
            child: HyperViewer(
              html: '''
                <h2>Article with Floated Video</h2>

                <video
                  src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4"
                  poster="https://storage.googleapis.com/gtv-videos-bucket/sample/images/WeAreGoingOnBullrun.jpg"
                  width="320"
                  height="180"
                  style="float: left; margin-right: 16px; margin-bottom: 8px;"
                  controls>
                </video>

                <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                Text wraps naturally around the floated video, just like in a web browser!
                This is a unique advantage of HyperRender over other Flutter HTML rendering libraries.</p>

                <p>Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
                Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.</p>

                <p>Duis aute irure dolor in reprehenderit in voluptate velit esse
                cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat.</p>
              ''',
              widgetBuilder: (node) {
                if (node is AtomicNode && (node.tagName == 'video' || node.tagName == 'audio')) {
                  final mediaInfo = MediaInfo.fromNode(node);
                  return _buildInteractiveMedia(context, mediaInfo);
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 24),

          // Instructions card
          _buildInstructionsCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle_filled, color: Colors.red.shade700, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video & Media Demo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tap video to play in external player',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildFeatureItem('✅ Beautiful video placeholders with poster images'),
            _buildFeatureItem('✅ Hover effects and animations'),
            _buildFeatureItem('✅ Tap to open in external player'),
            _buildFeatureItem('✅ Float layout support (unique feature)'),
            _buildFeatureItem('✅ Responsive sizing'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveMedia(BuildContext context, MediaInfo mediaInfo) {
    return DefaultMediaWidget(
      mediaInfo: mediaInfo,
      onTap: () async {
        // Show a dialog explaining what will happen
        final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.open_in_new, color: Colors.blue),
                SizedBox(width: 8),
                Text('Open Video'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Video will be opened in external player (browser or video player app).'),
                const SizedBox(height: 12),
                Text(
                  'URL: ${mediaInfo.src}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Open Video'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );

        if (shouldOpen == true) {
          try {
            final uri = Uri.parse(mediaInfo.src);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video opened in external player'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cannot open video: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        }
      },
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'How It Works',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInstruction('1. Video placeholders show poster images when available'),
            _buildInstruction('2. Hover over video to see animation effects (desktop)'),
            _buildInstruction('3. Tap/click video to open in external player'),
            _buildInstruction('4. For embedded video playback, use video_player package with mediaBuilder'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Pro Tip:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'For inline video playback, integrate video_player package:',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '''mediaBuilder: (context, mediaInfo) {
  return VideoPlayerWidget(
    url: mediaInfo.src,
    autoPlay: mediaInfo.autoplay,
  );
}''',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
