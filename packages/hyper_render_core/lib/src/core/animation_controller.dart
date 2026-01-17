import 'package:flutter/material.dart';

import '../model/computed_style.dart';

/// Predefined CSS keyframe animations
///
/// These correspond to common CSS animation names like 'fadeIn', 'slideUp', etc.
class HyperAnimations {
  HyperAnimations._();

  /// Fade in animation
  static const fadeIn = HyperKeyframes(
    name: 'fadeIn',
    keyframes: [
      HyperKeyframe(offset: 0.0, opacity: 0.0),
      HyperKeyframe(offset: 1.0, opacity: 1.0),
    ],
  );

  /// Fade out animation
  static const fadeOut = HyperKeyframes(
    name: 'fadeOut',
    keyframes: [
      HyperKeyframe(offset: 0.0, opacity: 1.0),
      HyperKeyframe(offset: 1.0, opacity: 0.0),
    ],
  );

  /// Slide in from left
  static const slideInLeft = HyperKeyframes(
    name: 'slideInLeft',
    keyframes: [
      HyperKeyframe(offset: 0.0, translateX: -100.0, opacity: 0.0),
      HyperKeyframe(offset: 1.0, translateX: 0.0, opacity: 1.0),
    ],
  );

  /// Slide in from right
  static const slideInRight = HyperKeyframes(
    name: 'slideInRight',
    keyframes: [
      HyperKeyframe(offset: 0.0, translateX: 100.0, opacity: 0.0),
      HyperKeyframe(offset: 1.0, translateX: 0.0, opacity: 1.0),
    ],
  );

  /// Slide in from top
  static const slideInUp = HyperKeyframes(
    name: 'slideInUp',
    keyframes: [
      HyperKeyframe(offset: 0.0, translateY: -50.0, opacity: 0.0),
      HyperKeyframe(offset: 1.0, translateY: 0.0, opacity: 1.0),
    ],
  );

  /// Slide in from bottom
  static const slideInDown = HyperKeyframes(
    name: 'slideInDown',
    keyframes: [
      HyperKeyframe(offset: 0.0, translateY: 50.0, opacity: 0.0),
      HyperKeyframe(offset: 1.0, translateY: 0.0, opacity: 1.0),
    ],
  );

  /// Bounce animation
  static const bounce = HyperKeyframes(
    name: 'bounce',
    keyframes: [
      HyperKeyframe(offset: 0.0, translateY: 0.0),
      HyperKeyframe(offset: 0.2, translateY: 0.0),
      HyperKeyframe(offset: 0.4, translateY: -30.0),
      HyperKeyframe(offset: 0.5, translateY: 0.0),
      HyperKeyframe(offset: 0.6, translateY: -15.0),
      HyperKeyframe(offset: 0.8, translateY: 0.0),
      HyperKeyframe(offset: 1.0, translateY: 0.0),
    ],
  );

  /// Pulse animation (scale)
  static const pulse = HyperKeyframes(
    name: 'pulse',
    keyframes: [
      HyperKeyframe(offset: 0.0, scale: 1.0),
      HyperKeyframe(offset: 0.5, scale: 1.05),
      HyperKeyframe(offset: 1.0, scale: 1.0),
    ],
  );

  /// Shake animation
  static const shake = HyperKeyframes(
    name: 'shake',
    keyframes: [
      HyperKeyframe(offset: 0.0, translateX: 0.0),
      HyperKeyframe(offset: 0.1, translateX: -10.0),
      HyperKeyframe(offset: 0.2, translateX: 10.0),
      HyperKeyframe(offset: 0.3, translateX: -10.0),
      HyperKeyframe(offset: 0.4, translateX: 10.0),
      HyperKeyframe(offset: 0.5, translateX: -10.0),
      HyperKeyframe(offset: 0.6, translateX: 10.0),
      HyperKeyframe(offset: 0.7, translateX: -10.0),
      HyperKeyframe(offset: 0.8, translateX: 10.0),
      HyperKeyframe(offset: 0.9, translateX: -10.0),
      HyperKeyframe(offset: 1.0, translateX: 0.0),
    ],
  );

  /// Spin animation (360 rotation)
  static const spin = HyperKeyframes(
    name: 'spin',
    keyframes: [
      HyperKeyframe(offset: 0.0, rotation: 0.0),
      HyperKeyframe(offset: 1.0, rotation: 360.0),
    ],
  );

  /// Zoom in animation
  static const zoomIn = HyperKeyframes(
    name: 'zoomIn',
    keyframes: [
      HyperKeyframe(offset: 0.0, scale: 0.0, opacity: 0.0),
      HyperKeyframe(offset: 1.0, scale: 1.0, opacity: 1.0),
    ],
  );

  /// Zoom out animation
  static const zoomOut = HyperKeyframes(
    name: 'zoomOut',
    keyframes: [
      HyperKeyframe(offset: 0.0, scale: 1.0, opacity: 1.0),
      HyperKeyframe(offset: 1.0, scale: 0.0, opacity: 0.0),
    ],
  );

  /// Get animation by name
  static HyperKeyframes? byName(String name) {
    switch (name.toLowerCase()) {
      case 'fadein':
        return fadeIn;
      case 'fadeout':
        return fadeOut;
      case 'slideinleft':
        return slideInLeft;
      case 'slideinright':
        return slideInRight;
      case 'slideinup':
        return slideInUp;
      case 'slideindown':
        return slideInDown;
      case 'bounce':
        return bounce;
      case 'pulse':
        return pulse;
      case 'shake':
        return shake;
      case 'spin':
        return spin;
      case 'zoomin':
        return zoomIn;
      case 'zoomout':
        return zoomOut;
      default:
        return null;
    }
  }
}

/// A single keyframe in an animation
class HyperKeyframe {
  /// Position in animation (0.0 - 1.0)
  final double offset;

  /// Opacity at this keyframe
  final double? opacity;

  /// X translation
  final double? translateX;

  /// Y translation
  final double? translateY;

  /// Scale factor
  final double? scale;

  /// Rotation in degrees
  final double? rotation;

  const HyperKeyframe({
    required this.offset,
    this.opacity,
    this.translateX,
    this.translateY,
    this.scale,
    this.rotation,
  });
}

/// A collection of keyframes that define an animation
class HyperKeyframes {
  final String name;
  final List<HyperKeyframe> keyframes;

  const HyperKeyframes({
    required this.name,
    required this.keyframes,
  });

  /// Interpolate values at a given progress (0.0 - 1.0)
  HyperKeyframe interpolate(double progress) {
    if (keyframes.isEmpty) {
      return const HyperKeyframe(offset: 0);
    }

    if (keyframes.length == 1) {
      return keyframes.first;
    }

    // Find surrounding keyframes
    HyperKeyframe? before;
    HyperKeyframe? after;

    for (int i = 0; i < keyframes.length; i++) {
      if (keyframes[i].offset <= progress) {
        before = keyframes[i];
      }
      if (keyframes[i].offset >= progress && after == null) {
        after = keyframes[i];
      }
    }

    before ??= keyframes.first;
    after ??= keyframes.last;

    if (before == after || before.offset == after.offset) {
      return before;
    }

    // Calculate interpolation factor
    final t = (progress - before.offset) / (after.offset - before.offset);

    return HyperKeyframe(
      offset: progress,
      opacity: _lerpNullable(before.opacity, after.opacity, t),
      translateX: _lerpNullable(before.translateX, after.translateX, t),
      translateY: _lerpNullable(before.translateY, after.translateY, t),
      scale: _lerpNullable(before.scale, after.scale, t),
      rotation: _lerpNullable(before.rotation, after.rotation, t),
    );
  }

  double? _lerpNullable(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return a + (b - a) * t;
  }
}

/// Widget that applies CSS-like animations to its child
class HyperAnimatedWidget extends StatefulWidget {
  final Widget child;
  final String? animationName;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final int? iterationCount;
  final bool reverse;
  final bool autoPlay;

  const HyperAnimatedWidget({
    super.key,
    required this.child,
    this.animationName,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.ease,
    this.iterationCount,
    this.reverse = false,
    this.autoPlay = true,
  });

  /// Create from ComputedStyle
  factory HyperAnimatedWidget.fromStyle({
    Key? key,
    required Widget child,
    required ComputedStyle style,
  }) {
    return HyperAnimatedWidget(
      key: key,
      animationName: style.animationName,
      duration: Duration(milliseconds: style.animationDuration ?? 300),
      delay: Duration(milliseconds: style.animationDelay ?? 0),
      curve: _curveFromTimingFunction(style.animationTimingFunction),
      iterationCount: style.animationIterationCount,
      reverse: style.animationDirection == HyperAnimationDirection.reverse ||
          style.animationDirection == HyperAnimationDirection.alternateReverse,
      child: child,
    );
  }

  static Curve _curveFromTimingFunction(HyperTimingFunction fn) {
    switch (fn) {
      case HyperTimingFunction.linear:
        return Curves.linear;
      case HyperTimingFunction.ease:
        return Curves.ease;
      case HyperTimingFunction.easeIn:
        return Curves.easeIn;
      case HyperTimingFunction.easeOut:
        return Curves.easeOut;
      case HyperTimingFunction.easeInOut:
        return Curves.easeInOut;
    }
  }

  @override
  State<HyperAnimatedWidget> createState() => _HyperAnimatedWidgetState();
}

class _HyperAnimatedWidgetState extends State<HyperAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  HyperKeyframes? _keyframes;
  int _currentIteration = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    // Get keyframes
    if (widget.animationName != null) {
      _keyframes = HyperAnimations.byName(widget.animationName!);
    }

    // Setup iteration listener
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentIteration++;
        final maxIterations = widget.iterationCount;

        if (maxIterations == null || _currentIteration < maxIterations) {
          if (widget.reverse) {
            _controller.reverse();
          } else {
            _controller.reset();
            _controller.forward();
          }
        }
      } else if (status == AnimationStatus.dismissed && widget.reverse) {
        _currentIteration++;
        final maxIterations = widget.iterationCount;

        if (maxIterations == null || _currentIteration < maxIterations) {
          _controller.forward();
        }
      }
    });

    // Start animation after delay
    if (widget.autoPlay && _keyframes != null) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(HyperAnimatedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationName != widget.animationName ||
        oldWidget.duration != widget.duration ||
        oldWidget.curve != widget.curve) {
      _controller.dispose();
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_keyframes == null) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final keyframe = _keyframes!.interpolate(_animation.value);

        // Build transform matrix
        Matrix4 transform = Matrix4.identity();

        if (keyframe.translateX != null || keyframe.translateY != null) {
          transform = transform.multiplied(Matrix4.translationValues(
            keyframe.translateX ?? 0.0,
            keyframe.translateY ?? 0.0,
            0.0,
          ));
        }

        if (keyframe.scale != null) {
          transform = transform.multiplied(Matrix4.diagonal3Values(
            keyframe.scale!,
            keyframe.scale!,
            1.0,
          ));
        }

        if (keyframe.rotation != null) {
          final rotationMatrix = Matrix4.identity()
            ..rotateZ(keyframe.rotation! * 3.14159 / 180.0);
          transform = transform.multiplied(rotationMatrix);
        }

        Widget result = child!;

        // Apply transform
        if (keyframe.translateX != null ||
            keyframe.translateY != null ||
            keyframe.scale != null ||
            keyframe.rotation != null) {
          result = Transform(
            transform: transform,
            alignment: Alignment.center,
            child: result,
          );
        }

        // Apply opacity
        if (keyframe.opacity != null) {
          result = Opacity(
            opacity: keyframe.opacity!.clamp(0.0, 1.0),
            child: result,
          );
        }

        return result;
      },
      child: widget.child,
    );
  }
}

/// Extension to easily animate widgets
extension HyperAnimationExtension on Widget {
  /// Apply a fade in animation
  Widget fadeIn({
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    return HyperAnimatedWidget(
      animationName: 'fadeIn',
      duration: duration,
      delay: delay,
      curve: curve,
      child: this,
    );
  }

  /// Apply a slide in from left animation
  Widget slideInLeft({
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    return HyperAnimatedWidget(
      animationName: 'slideInLeft',
      duration: duration,
      delay: delay,
      curve: curve,
      child: this,
    );
  }

  /// Apply a bounce animation
  Widget bounce({
    Duration duration = const Duration(milliseconds: 1000),
    int? iterationCount,
  }) {
    return HyperAnimatedWidget(
      animationName: 'bounce',
      duration: duration,
      iterationCount: iterationCount,
      child: this,
    );
  }

  /// Apply a pulse animation
  Widget pulse({
    Duration duration = const Duration(milliseconds: 1000),
    int? iterationCount,
  }) {
    return HyperAnimatedWidget(
      animationName: 'pulse',
      duration: duration,
      iterationCount: iterationCount,
      child: this,
    );
  }

  /// Apply a spin animation
  Widget spin({
    Duration duration = const Duration(milliseconds: 1000),
    int? iterationCount,
  }) {
    return HyperAnimatedWidget(
      animationName: 'spin',
      duration: duration,
      iterationCount: iterationCount,
      child: this,
    );
  }
}
