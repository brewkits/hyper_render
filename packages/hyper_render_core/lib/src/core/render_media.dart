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
        behavior: HitTestBehavior.opaque, // CRITICAL: Catch taps on entire area including transparent regions
        onTap: widget.onTap,
        child: widget.mediaInfo.isVideo
            ? _buildVideoPlaceholder()
            : _buildAudioPlaceholder(),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    final width = widget.mediaInfo.width ?? 640;
    final height = widget.mediaInfo.height ?? 360;

    // Use LayoutBuilder to make video responsive
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine available width - always constrain to parent
        final availableWidth = constraints.maxWidth != double.infinity
            ? constraints.maxWidth
            : 480.0; // Reasonable default max width for unconstrained layouts

        // Calculate responsive dimensions maintaining aspect ratio
        // ALWAYS constrain to available width to prevent overlap
        final constrainedWidth = width > availableWidth ? availableWidth : width.toDouble();
        final scale = constrainedWidth / width;
        final responsiveWidth = constrainedWidth;
        final responsiveHeight = height * scale;

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: availableWidth,
            maxHeight: responsiveHeight,
          ),
          child: Container(
            width: responsiveWidth,
            height: responsiveHeight,
          decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF000000),
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

          // Play button with smooth animation
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isHovering
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                boxShadow: _isHovering
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Transform.scale(
                scale: _isHovering ? 1.08 : 1.0,
                child: const Icon(
                  Icons.play_arrow,
                  size: 48,
                  color: Colors.white,
                ),
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
          ),
        );
      },
    );
  }

  Widget _buildAudioPlaceholder() {
    final width = widget.mediaInfo.width ?? 320;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine available width - always constrain to parent
        final availableWidth = constraints.maxWidth != double.infinity
            ? constraints.maxWidth
            : 360.0; // Reasonable default max width for unconstrained layouts

        // ALWAYS constrain to available width to prevent overlap
        final responsiveWidth = width > availableWidth ? availableWidth : width.toDouble();

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: availableWidth,
          ),
          child: Container(
            width: responsiveWidth,
            padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
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
          ),
        );
      },
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
