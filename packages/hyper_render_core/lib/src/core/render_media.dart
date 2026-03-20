import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../model/node.dart';

/// Callback for building custom media widgets
///
/// This allows users to plug in their own video/audio player implementations
/// (video_player, chewie, just_audio, etc.)
typedef MediaWidgetBuilder = Widget Function(
  BuildContext context,
  MediaInfo mediaInfo,
);

/// Information about a media element
class MediaInfo {
  /// Media type (audio or video)
  final MediaType type;

  /// Source URL
  final String src;

  /// Poster image for video (optional)
  final String? poster;

  /// Whether to autoplay
  final bool autoplay;

  /// Whether to loop
  final bool loop;

  /// Whether to mute
  final bool muted;

  /// Whether to show controls
  final bool controls;

  /// Explicit width (from attributes or CSS)
  final double? width;

  /// Explicit height (from attributes or CSS)
  final double? height;

  /// Alt text / title for accessibility
  final String? title;

  /// Original node for access to all attributes
  final AtomicNode? node;

  const MediaInfo({
    required this.type,
    required this.src,
    this.poster,
    this.autoplay = false,
    this.loop = false,
    this.muted = false,
    this.controls = true,
    this.width,
    this.height,
    this.title,
    this.node,
  });

  /// Create MediaInfo from an AtomicNode
  factory MediaInfo.fromNode(AtomicNode node) {
    final attrs = node.attributes;

    return MediaInfo(
      type: node.tagName == 'audio' ? MediaType.audio : MediaType.video,
      src: node.src ?? attrs['src'] ?? '',
      poster: attrs['poster'],
      autoplay: attrs.containsKey('autoplay'),
      loop: attrs.containsKey('loop'),
      muted: attrs.containsKey('muted'),
      controls: !attrs.containsKey('controls') || attrs['controls'] != 'false',
      width: node.intrinsicWidth,
      height: node.intrinsicHeight,
      title: attrs['title'],
      node: node,
    );
  }

  /// Check if this is an audio element
  bool get isAudio => type == MediaType.audio;

  /// Check if this is a video element
  bool get isVideo => type == MediaType.video;
}

/// Type of media element
enum MediaType {
  audio,
  video,
}

/// Convenience extension on [AtomicNode] for media-related helpers.
///
/// Defined here (not in node.dart) to avoid a circular import:
/// render_media.dart imports node.dart, not the other way around.
extension AtomicNodeMediaExtension on AtomicNode {
  /// Returns a [MediaInfo] built from this node's attributes.
  MediaInfo get mediaInfo => MediaInfo.fromNode(this);
}

/// Default media widget - shows a placeholder with play button
///
/// This is used when no custom MediaWidgetBuilder is provided.
/// For actual video/audio playback, users should provide their own
/// implementation using video_player, chewie, just_audio, etc.
class DefaultMediaWidget extends StatefulWidget {
  final MediaInfo mediaInfo;
  final VoidCallback? onTap;

  const DefaultMediaWidget({
    super.key,
    required this.mediaInfo,
    this.onTap,
  });

  @override
  State<DefaultMediaWidget> createState() => _DefaultMediaWidgetState();
}

class _DefaultMediaWidgetState extends State<DefaultMediaWidget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: widget.mediaInfo.isVideo
            ? _buildVideoPlaceholder()
            : _buildAudioPlaceholder(),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) => _buildVideoContainer(constraints),
    );
  }

  Widget _buildVideoContainer(BoxConstraints constraints) {
    final maxW =
        constraints.maxWidth == double.infinity ? 320.0 : constraints.maxWidth;
    final intrinsicW = widget.mediaInfo.width;
    final intrinsicH = widget.mediaInfo.height;

    double width, height;
    if (intrinsicW != null && intrinsicH != null) {
      final scale = intrinsicW > maxW ? maxW / intrinsicW : 1.0;
      width = intrinsicW * scale;
      height = intrinsicH * scale;
    } else if (intrinsicW != null) {
      width = math.min(intrinsicW, maxW);
      height = width * 9.0 / 16.0;
    } else {
      width = maxW;
      height = maxW * 9.0 / 16.0;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        image: widget.mediaInfo.poster != null
            ? DecorationImage(
                image: NetworkImage(widget.mediaInfo.poster!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Gradient overlay
          if (widget.mediaInfo.poster != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

          // Play button
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isHovering
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                size: _isHovering ? 52 : 48,
                color: Colors.white,
              ),
            ),
          ),

          // Video icon badge
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'VIDEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Title if available
          if (widget.mediaInfo.title != null)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                widget.mediaInfo.title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioPlaceholder() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final maxW = constraints.maxWidth == double.infinity
          ? 300.0
          : constraints.maxWidth;
      final width = widget.mediaInfo.width != null
          ? math.min(widget.mediaInfo.width!, maxW)
          : maxW;
      return _buildAudioContainer(ctx, width);
    });
  }

  Widget _buildAudioContainer(BuildContext context, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play button
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovering
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColor.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),

          // Audio info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.audiotrack, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'AUDIO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (widget.mediaInfo.title != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.mediaInfo.title!,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                // Fake progress bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper widget that wraps media with a link to open externally
class MediaExternalLinkWrapper extends StatelessWidget {
  final MediaInfo mediaInfo;
  final Widget child;
  final VoidCallback? onTap;

  const MediaExternalLinkWrapper({
    super.key,
    required this.mediaInfo,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Tap to play: ${mediaInfo.src}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }
}

/// Extension to add media factory to AtomicNode
extension MediaNodeExtension on AtomicNode {
  /// Check if this node is a media element (audio or video)
  bool get isMedia => tagName == 'audio' || tagName == 'video';

  /// Check if this is an audio element
  bool get isAudio => tagName == 'audio';

  /// Check if this is a video element
  bool get isVideo => tagName == 'video';

  /// Get media info for this node
  MediaInfo get mediaInfo => MediaInfo.fromNode(this);
}

/// Factory for creating AtomicNode for audio elements
extension AtomicNodeAudioFactory on AtomicNode {
  /// Factory for audio element
  static AtomicNode audio({
    required String src,
    bool autoplay = false,
    bool loop = false,
    bool controls = true,
    String? title,
  }) {
    return AtomicNode(
      tagName: 'audio',
      src: src,
      attributes: {
        'src': src,
        if (autoplay) 'autoplay': '',
        if (loop) 'loop': '',
        if (controls) 'controls': '',
        if (title != null) 'title': title,
      },
    );
  }
}
