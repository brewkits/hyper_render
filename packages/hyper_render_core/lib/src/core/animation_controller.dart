import 'dart:async';

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

  /// All predefined animations as a name → keyframes map.
  ///
  /// Use this as the base for [HyperRenderConfig.keyframeRegistry] when you
  /// want all built-in CSS animation names to work out of the box:
  ///
  /// ```dart
  /// HyperRenderConfig(
  ///   keyframeRegistry: {
  ///     ...HyperAnimations.all,
  ///     'mySlide': HyperKeyframes(name: 'mySlide', keyframes: [...]),
  ///   },
  /// )
  /// ```
  static Map<String, HyperKeyframes> get all => const {
        'fadeIn': fadeIn,
        'fadeOut': fadeOut,
        'slideInLeft': slideInLeft,
        'slideInRight': slideInRight,
        'slideInUp': slideInUp,
        'slideInDown': slideInDown,
        'bounce': bounce,
        'pulse': pulse,
        'shake': shake,
        'spin': spin,
        'zoomIn': zoomIn,
        'zoomOut': zoomOut,
      };
}

/// Maps a resolved [HyperTimingFunction] (+ optional parameters) to the
/// equivalent Flutter [Curve].
///
/// Shared between the widget-tier ([HyperAnimatedWidget], [HyperTransitionWidget])
/// and the RenderHyperBox canvas animation path so both interpret
/// `animation-timing-function` / `transition-timing-function` identically.
Curve curveFromHyperTiming(HyperTimingFunction fn,
    [HyperTimingParams? params]) {
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
    case HyperTimingFunction.cubicBezier:
      if (params is HyperCubicBezierParams) {
        return Cubic(params.x1, params.y1, params.x2, params.y2);
      }
      return Curves.ease;
    case HyperTimingFunction.steps:
      if (params is HyperStepsParams) {
        return HyperStepsCurve(params.count, jumpStart: params.jumpStart);
      }
      return Curves.linear;
  }
}

/// Resolves an `animation-name` to its [HyperKeyframes] definition: a custom
/// [keyframesLookup] entry (from `@keyframes` parsed out of the document)
/// takes priority over the built-in [HyperAnimations] presets.
///
/// Shared between the widget-tier animation path and the RenderHyperBox
/// canvas animation path so both resolve names identically.
HyperKeyframes? resolveHyperKeyframes(
  String? animationName,
  Map<String, HyperKeyframes>? keyframesLookup,
) {
  if (animationName == null || animationName.isEmpty) return null;
  return keyframesLookup?[animationName] ??
      HyperAnimations.byName(animationName);
}

/// Builds the same translate → scale → rotate composition [HyperAnimatedWidget]
/// applies via [Transform], from a single interpolated [HyperKeyframe].
///
/// Shared with the RenderHyperBox canvas animation path so a block animated
/// on the canvas transforms identically to one animated via the widget tree.
Matrix4 matrix4FromHyperKeyframe(HyperKeyframe keyframe) {
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

  return transform;
}

/// CSS `steps(n, start|end)` timing function as a Flutter [Curve].
///
/// `steps(n, end)` (the default) holds each value until the end of its
/// interval; `steps(n, start)` jumps at the beginning of each interval.
class HyperStepsCurve extends Curve {
  /// Number of steps (must be > 0).
  final int count;

  /// `true` for `steps(n, start)` / `step-start` semantics.
  final bool jumpStart;

  const HyperStepsCurve(this.count, {this.jumpStart = false})
      : assert(count > 0, 'steps() requires a positive step count');

  @override
  double transformInternal(double t) {
    final scaled = t * count;
    final step = jumpStart ? scaled.ceilToDouble() : scaled.floorToDouble();
    return (step / count).clamp(0.0, 1.0);
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

  /// Text color (CSS `color`) at this keyframe
  final Color? color;

  /// Background color (CSS `background-color`) at this keyframe
  final Color? backgroundColor;

  const HyperKeyframe({
    required this.offset,
    this.opacity,
    this.translateX,
    this.translateY,
    this.scale,
    this.rotation,
    this.color,
    this.backgroundColor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HyperKeyframe &&
          offset == other.offset &&
          opacity == other.opacity &&
          translateX == other.translateX &&
          translateY == other.translateY &&
          scale == other.scale &&
          rotation == other.rotation &&
          color == other.color &&
          backgroundColor == other.backgroundColor);

  @override
  int get hashCode => Object.hash(offset, opacity, translateX, translateY,
      scale, rotation, color, backgroundColor);
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
      color: _lerpColor(before.color, after.color, t),
      backgroundColor:
          _lerpColor(before.backgroundColor, after.backgroundColor, t),
    );
  }

  Color? _lerpColor(Color? a, Color? b, double t) {
    if (a == null && b == null) return null;
    // A one-sided color holds its value (same convention as _lerpNullable).
    if (a == null) return b;
    if (b == null) return a;
    return Color.lerp(a, b, t);
  }

  double? _lerpNullable(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return a + (b - a) * t;
  }

  // HIGH-02: Value equality so HyperRenderConfig.hashCode / == can compare
  // keyframeRegistry entries by content rather than object identity.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HyperKeyframes) return false;
    if (name != other.name || keyframes.length != other.keyframes.length) {
      return false;
    }
    for (int i = 0; i < keyframes.length; i++) {
      if (keyframes[i] != other.keyframes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(name, Object.hashAll(keyframes));
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
  final bool alternate;
  final bool autoPlay;

  /// CSS `animation-play-state: paused`. While `true` the animation holds
  /// its current frame; flipping back to `false` resumes from that frame
  /// without restarting. When paused before the initial [delay] elapses,
  /// the delay countdown restarts on resume.
  final bool paused;

  /// Optional registry of custom [HyperKeyframes] keyed by animation name.
  ///
  /// When an [animationName] is set, [HyperAnimatedWidget] first looks it up
  /// in this map, then falls back to the built-in [HyperAnimations] presets.
  /// Typically sourced from [HyperRenderConfig.keyframeRegistry] so that
  /// `@keyframes` declared in the HTML document's `<style>` tags are used.
  final Map<String, HyperKeyframes>? keyframesLookup;

  const HyperAnimatedWidget({
    super.key,
    required this.child,
    this.animationName,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.ease,
    this.iterationCount,
    this.reverse = false,
    this.alternate = false,
    this.autoPlay = true,
    this.paused = false,
    this.keyframesLookup,
  });

  /// Create from ComputedStyle
  factory HyperAnimatedWidget.fromStyle({
    Key? key,
    required Widget child,
    required ComputedStyle style,
    Map<String, HyperKeyframes>? keyframesLookup,
  }) {
    return HyperAnimatedWidget(
      key: key,
      animationName: style.animationName,
      duration: Duration(milliseconds: style.animationDuration ?? 300),
      delay: Duration(milliseconds: style.animationDelay ?? 0),
      curve: curveFromHyperTiming(
          style.animationTimingFunction, style.animationTimingParams),
      iterationCount: style.animationIterationCount,
      reverse: style.animationDirection == HyperAnimationDirection.reverse ||
          style.animationDirection == HyperAnimationDirection.alternateReverse,
      alternate: style.animationDirection ==
              HyperAnimationDirection.alternate ||
          style.animationDirection == HyperAnimationDirection.alternateReverse,
      paused: style.animationPlayState == HyperAnimationPlayState.paused,
      keyframesLookup: keyframesLookup,
      child: child,
    );
  }

  @override
  State<HyperAnimatedWidget> createState() => _HyperAnimatedWidgetState();
}

class _HyperAnimatedWidgetState extends State<HyperAnimatedWidget>
    // TickerProviderStateMixin (not Single...) because didUpdateWidget below
    // disposes the current AnimationController and creates a new one when
    // the animation name / duration / curve / keyframes lookup changes.
    // Single... asserts on the second `createTicker()` call and crashes the
    // app in live-update scenarios (e.g. a markdown editor that swaps the
    // animation prop on every keystroke).
    with
        TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  HyperKeyframes? _keyframes;
  int _currentIteration = 0;

  /// Pending delayed-start timer, retained so [_cancelPendingStart] can
  /// drop the callback when the widget rebuilds or unmounts. Without this
  /// a fast didUpdateWidget cycle (e.g. live editor typing) would let an
  /// older Future.delayed fire forward() on the freshly-installed
  /// AnimationController — harmless under current Flutter semantics but
  /// still an unintended duplicate start.
  Timer? _pendingStart;

  /// Whether the animation has passed its initial delay and started at
  /// least once on the current controller. Distinguishes "paused before
  /// start" (resume must re-run the delay) from "paused mid-flight"
  /// (resume continues from the held frame).
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _currentIteration = 0;
    _hasStarted = false;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    // Resolve keyframes: custom registry takes priority over built-ins.
    _keyframes =
        resolveHyperKeyframes(widget.animationName, widget.keyframesLookup);

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

    // Start animation after delay.
    //
    // A [Timer] (retained in [_pendingStart]) is used instead of a bare
    // [Future.delayed] so that a subsequent [didUpdateWidget] which replaces
    // [_controller] can cancel this pending start — otherwise the new
    // controller would receive a stray forward() once the old delay resolves.
    // The closure reads `this._controller` at call time, so the timer never
    // touches a disposed controller: `mounted` covers the unmount case and
    // [_cancelPendingStart] covers the in-place rebuild case.
    if (widget.autoPlay && _keyframes != null && !widget.paused) {
      _scheduleStart();
    }
  }

  void _scheduleStart() {
    _pendingStart = Timer(widget.delay, () {
      _pendingStart = null;
      if (mounted) {
        _hasStarted = true;
        if (widget.iterationCount == null) {
          _controller.repeat(reverse: widget.alternate);
        } else {
          _controller.forward();
        }
      }
    });
  }

  void _cancelPendingStart() {
    _pendingStart?.cancel();
    _pendingStart = null;
  }

  /// Resumes after `animation-play-state` flips from paused to running.
  void _resumeFromPause() {
    if (!widget.autoPlay || _keyframes == null) return;
    if (_pendingStart != null || _controller.isAnimating) return;
    if (!_hasStarted) {
      _scheduleStart();
    } else if (widget.iterationCount == null) {
      // repeat() seeds its simulation with the current value, so an
      // infinite animation continues from the held frame.
      _controller.repeat(reverse: widget.alternate);
    } else if (_currentIteration < widget.iterationCount!) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(HyperAnimatedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationName != widget.animationName ||
        oldWidget.duration != widget.duration ||
        oldWidget.curve != widget.curve ||
        oldWidget.iterationCount != widget.iterationCount ||
        oldWidget.reverse != widget.reverse ||
        oldWidget.alternate != widget.alternate ||
        oldWidget.keyframesLookup != widget.keyframesLookup) {
      _cancelPendingStart();
      _controller.dispose();
      _setupAnimation();
    } else if (oldWidget.paused != widget.paused) {
      if (widget.paused) {
        _cancelPendingStart();
        _controller.stop();
      } else {
        _resumeFromPause();
      }
    }
  }

  @override
  void dispose() {
    _cancelPendingStart();
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
        final transform = matrix4FromHyperKeyframe(keyframe);

        Widget result = child!;

        // Apply animated text color. Affects widget-tier text that doesn't
        // set an explicit color (e.g. plugin widgets); canvas-painted text
        // inside RenderHyperBox is not affected.
        if (keyframe.color != null) {
          result = DefaultTextStyle.merge(
            style: TextStyle(color: keyframe.color),
            child: result,
          );
        }

        // Apply animated background color behind the child's content.
        if (keyframe.backgroundColor != null) {
          result = ColoredBox(
            color: keyframe.backgroundColor!,
            child: result,
          );
        }

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

/// Applies CSS `transition` property to a child widget.
///
/// When the [style] changes across rebuilds, animatable properties (opacity,
/// transform) transition smoothly over the specified duration and timing
/// function. Mirrors browser CSS `transition` behavior for content that
/// updates dynamically (e.g., live feeds, class toggles via API).
class HyperTransitionWidget extends StatefulWidget {
  final Widget child;
  final ComputedStyle style;

  const HyperTransitionWidget({
    super.key,
    required this.child,
    required this.style,
  });

  @override
  State<HyperTransitionWidget> createState() => _HyperTransitionWidgetState();
}

class _HyperTransitionWidgetState extends State<HyperTransitionWidget> {
  late double _opacity;
  late Matrix4 _transform;
  Color? _backgroundColor;
  Color? _textColor;

  @override
  void initState() {
    super.initState();
    _readStyle();
  }

  @override
  void didUpdateWidget(HyperTransitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _readStyle();
  }

  void _readStyle() {
    _opacity = widget.style.opacity;
    _transform = widget.style.transform ?? Matrix4.identity();
    _backgroundColor = widget.style.backgroundColor;
    _textColor = widget.style.color;
  }

  Duration get _duration {
    final t = widget.style.transition;
    if (t == null || !t.isDefined) return Duration.zero;
    return Duration(milliseconds: t.duration);
  }

  Curve get _curve {
    final t = widget.style.transition;
    if (t == null) return Curves.ease;
    return curveFromHyperTiming(t.timingFunction, t.timingParams);
  }

  @override
  Widget build(BuildContext context) {
    final dur = _duration;
    if (dur == Duration.zero) {
      return _applyStaticStyle(widget.child);
    }

    final curve = _curve;

    Widget result = widget.child;

    // Animated text color — affects widget-tier text without an explicit
    // color; canvas-painted text inside RenderHyperBox is not affected.
    if (_textColor != null) {
      result = AnimatedDefaultTextStyle(
        style: DefaultTextStyle.of(context).style.copyWith(color: _textColor),
        duration: dur,
        curve: curve,
        child: result,
      );
    }

    result = AnimatedOpacity(
      opacity: _opacity.clamp(0.0, 1.0),
      duration: dur,
      curve: curve,
      child: result,
    );

    // `color` on AnimatedContainer paints the animated background behind the
    // child's own painting (visible when the child's static background is
    // transparent, e.g. class toggles that only change background-color).
    result = AnimatedContainer(
      duration: dur,
      curve: curve,
      color: _backgroundColor,
      transform: _transform,
      transformAlignment: Alignment.center,
      child: result,
    );

    return result;
  }

  Widget _applyStaticStyle(Widget child) {
    Widget result = child;
    if (_opacity < 1.0) {
      result = Opacity(opacity: _opacity.clamp(0.0, 1.0), child: result);
    }
    if (_transform != Matrix4.identity()) {
      result = Transform(
          transform: _transform, alignment: Alignment.center, child: result);
    }
    return result;
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
