import 'package:flutter/material.dart';
import '../style/design_tokens.dart';

/// Shape of the skeleton loader
enum SkeletonShape {
  /// Rectangle with rounded corners
  rectangle,

  /// Circle
  circle,

  /// Text line (thin rectangle)
  text,
}

/// Beautiful loading skeleton with shimmer animation
///
/// Displays an animated placeholder while content is loading.
/// Follows Material Design 3 principles with smooth shimmer effect.
///
/// ## Usage
///
/// ```dart
/// // Image placeholder
/// LoadingSkeleton(
///   width: 200,
///   height: 150,
/// )
///
/// // Text line placeholder
/// LoadingSkeleton.text(width: 100)
///
/// // Circle avatar placeholder
/// LoadingSkeleton.circle(size: 48)
///
/// // Multiple lines
/// Column(
///   children: [
///     LoadingSkeleton.text(width: 200),
///     SizedBox(height: 8),
///     LoadingSkeleton.text(width: 150),
///   ],
/// )
/// ```
class LoadingSkeleton extends StatefulWidget {
  /// Width of the skeleton
  final double? width;

  /// Height of the skeleton
  final double? height;

  /// Shape of the skeleton
  final SkeletonShape shape;

  /// Border radius (only for rectangle shape)
  final double? borderRadius;

  /// Whether animation is enabled
  final bool animate;

  /// Animation duration
  final Duration duration;

  const LoadingSkeleton({
    super.key,
    this.width,
    this.height,
    this.shape = SkeletonShape.rectangle,
    this.borderRadius,
    this.animate = true,
    this.duration = const Duration(milliseconds: 1500),
  });

  /// Create a text line skeleton
  const LoadingSkeleton.text({
    Key? key,
    double? width,
    double height = 16.0,
    bool animate = true,
    Duration duration = const Duration(milliseconds: 1500),
  }) : this(
          key: key,
          width: width,
          height: height,
          shape: SkeletonShape.text,
          animate: animate,
          duration: duration,
        );

  /// Create a circle skeleton
  const LoadingSkeleton.circle({
    Key? key,
    required double size,
    bool animate = true,
    Duration duration = const Duration(milliseconds: 1500),
  }) : this(
          key: key,
          width: size,
          height: size,
          shape: SkeletonShape.circle,
          animate: animate,
          duration: duration,
        );

  /// Create a rectangle skeleton with specific border radius
  const LoadingSkeleton.rectangle({
    Key? key,
    double? width,
    double? height,
    double borderRadius = 12.0,
    bool animate = true,
    Duration duration = const Duration(milliseconds: 1500),
  }) : this(
          key: key,
          width: width,
          height: height,
          shape: SkeletonShape.rectangle,
          borderRadius: borderRadius,
          animate: animate,
          duration: duration,
        );

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear, // Linear for smooth constant-speed shimmer
    ));

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(LoadingSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }

    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _getColors(isDark);

    Widget skeleton = AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: _buildDecoration(colors),
        );
      },
    );

    // Add default size if not specified
    if (widget.width == null || widget.height == null) {
      skeleton = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.width ?? 100.0,
          minHeight: widget.height ?? 100.0,
          maxWidth: widget.width ?? double.infinity,
          maxHeight: widget.height ?? double.infinity,
        ),
        child: skeleton,
      );
    }

    return skeleton;
  }

  BoxDecoration _buildDecoration(_SkeletonColors colors) {
    BorderRadius? borderRadius;

    switch (widget.shape) {
      case SkeletonShape.rectangle:
        borderRadius = BorderRadius.circular(
          widget.borderRadius ?? DesignTokens.radiusMedium,
        );
        break;

      case SkeletonShape.circle:
        borderRadius = BorderRadius.circular(9999);
        break;

      case SkeletonShape.text:
        borderRadius = BorderRadius.circular(DesignTokens.radiusSmall);
        break;
    }

    return BoxDecoration(
      borderRadius: borderRadius,
      gradient: widget.animate
          ? LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.5, 1.0],
              colors: [
                colors.baseColor,
                colors.highlightColor,
                colors.baseColor,
              ],
              transform: _SlideGradientTransform(_animation.value),
            )
          : null,
      color: widget.animate ? null : colors.baseColor,
    );
  }

  _SkeletonColors _getColors(bool isDark) {
    if (isDark) {
      return _SkeletonColors(
        baseColor: const Color(0xFF2D2D2D),
        highlightColor: const Color(0xFF4F4F4F), // Better contrast for dark mode
      );
    } else {
      return _SkeletonColors(
        baseColor: const Color(0xFFE0E0E0),
        highlightColor: const Color(0xFFF5F5F5),
      );
    }
  }
}

/// Internal class for skeleton colors
class _SkeletonColors {
  final Color baseColor;
  final Color highlightColor;

  _SkeletonColors({
    required this.baseColor,
    required this.highlightColor,
  });
}

/// Gradient transform for shimmer effect
class _SlideGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlideGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Container with multiple skeleton lines
///
/// Useful for displaying paragraph placeholders.
///
/// ```dart
/// SkeletonParagraph(
///   lines: 3,
///   lineHeight: 16,
///   spacing: 8,
/// )
/// ```
class SkeletonParagraph extends StatelessWidget {
  /// Number of lines to display
  final int lines;

  /// Height of each line
  final double lineHeight;

  /// Spacing between lines
  final double spacing;

  /// Width percentages for each line (for variety)
  /// If not provided, uses default widths
  final List<double>? lineWidths;

  /// Whether animation is enabled
  final bool animate;

  const SkeletonParagraph({
    super.key,
    this.lines = 3,
    this.lineHeight = 16.0,
    this.spacing = 8.0,
    this.lineWidths,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        final width = _getLineWidth(index);

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
          child: FractionallySizedBox(
            widthFactor: width,
            child: LoadingSkeleton.text(
              height: lineHeight,
              animate: animate,
            ),
          ),
        );
      }),
    );
  }

  double _getLineWidth(int index) {
    if (lineWidths != null && index < lineWidths!.length) {
      return lineWidths![index].clamp(0.0, 1.0);
    }

    // Default widths for natural paragraph look
    if (index == lines - 1) {
      return 0.6; // Last line is shorter
    }
    if (index % 3 == 1) {
      return 0.85; // Some variation
    }
    return 1.0; // Full width
  }
}

/// List item skeleton with avatar and text
///
/// Common pattern for list items with avatar and description.
///
/// ```dart
/// SkeletonListItem()
/// ```
class SkeletonListItem extends StatelessWidget {
  /// Size of the leading avatar
  final double avatarSize;

  /// Number of text lines
  final int lines;

  /// Whether to show trailing element
  final bool showTrailing;

  /// Whether animation is enabled
  final bool animate;

  const SkeletonListItem({
    super.key,
    this.avatarSize = 48.0,
    this.lines = 2,
    this.showTrailing = false,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LoadingSkeleton.circle(
          size: avatarSize,
          animate: animate,
        ),
        SizedBox(width: DesignTokens.space2),
        Expanded(
          child: SkeletonParagraph(
            lines: lines,
            lineHeight: 14.0,
            spacing: DesignTokens.space1,
            animate: animate,
          ),
        ),
        if (showTrailing) ...[
          SizedBox(width: DesignTokens.space2),
          LoadingSkeleton(
            width: 24,
            height: 24,
            animate: animate,
          ),
        ],
      ],
    );
  }
}

/// Card skeleton with image and text
///
/// Common pattern for cards with image header and text content.
///
/// ```dart
/// SkeletonCard(
///   imageHeight: 200,
/// )
/// ```
class SkeletonCard extends StatelessWidget {
  /// Height of the image area
  final double imageHeight;

  /// Number of text lines
  final int lines;

  /// Whether to show action buttons
  final bool showActions;

  /// Whether animation is enabled
  final bool animate;

  /// Card border radius
  final double borderRadius;

  const SkeletonCard({
    super.key,
    this.imageHeight = 200.0,
    this.lines = 3,
    this.showActions = true,
    this.animate = true,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: DesignTokens.shadow(DesignTokens.elevation1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          LoadingSkeleton(
            height: imageHeight,
            borderRadius: borderRadius,
            animate: animate,
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(DesignTokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonParagraph(
                  lines: lines,
                  lineHeight: 14.0,
                  spacing: DesignTokens.space1,
                  animate: animate,
                ),
                if (showActions) ...[
                  SizedBox(height: DesignTokens.space2),
                  Row(
                    children: [
                      LoadingSkeleton(
                        width: 80,
                        height: 32,
                        animate: animate,
                      ),
                      SizedBox(width: DesignTokens.space1),
                      LoadingSkeleton(
                        width: 80,
                        height: 32,
                        animate: animate,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of skeleton items
///
/// Useful for displaying grid placeholders.
///
/// ```dart
/// SkeletonGrid(
///   itemCount: 6,
///   crossAxisCount: 3,
/// )
/// ```
class SkeletonGrid extends StatelessWidget {
  /// Number of items to display
  final int itemCount;

  /// Number of items per row
  final int crossAxisCount;

  /// Aspect ratio of items
  final double childAspectRatio;

  /// Spacing between items
  final double spacing;

  /// Whether animation is enabled
  final bool animate;

  const SkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.0,
    this.spacing = 8.0,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return LoadingSkeleton(
          animate: animate,
        );
      },
    );
  }
}
