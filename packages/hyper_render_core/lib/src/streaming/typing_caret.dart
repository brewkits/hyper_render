import 'package:flutter/material.dart';

/// Visual style of the streaming [HyperTypingCaret].
enum HyperTypingCaretStyle {
  /// Vertical cursor bar (ChatGPT / Claude default).
  bar,

  /// Full rectangular block (`█`).
  block,

  /// Bottom horizontal underscore (`_`).
  underscore,

  /// Pulsing dot indicator (`●`).
  dot,

  /// Custom widget builder.
  custom,
}

/// Animated typing caret widget attached to active streaming LLM text in HyperRender.
///
/// Features smooth continuous opacity pulsing (500ms cycle) to mimic native AI interfaces.
class HyperTypingCaret extends StatefulWidget {
  /// Caret display style.
  final HyperTypingCaretStyle style;

  /// Caret color (defaults to theme primary color).
  final Color? color;

  /// Caret width.
  final double width;

  /// Caret height.
  final double height;

  /// Duration of one blink / pulse cycle.
  final Duration blinkDuration;

  /// Optional custom widget builder for [HyperTypingCaretStyle.custom].
  final Widget Function(BuildContext context, double opacity)? customBuilder;

  /// Creates an animated typing caret.
  const HyperTypingCaret({
    super.key,
    this.style = HyperTypingCaretStyle.bar,
    this.color,
    this.width = 3.0,
    this.height = 18.0,
    this.blinkDuration = const Duration(milliseconds: 500),
    this.customBuilder,
  });

  @override
  State<HyperTypingCaret> createState() => _HyperTypingCaretState();
}

class _HyperTypingCaretState extends State<HyperTypingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.blinkDuration,
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(HyperTypingCaret oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blinkDuration != widget.blinkDuration) {
      _controller.duration = widget.blinkDuration;
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        final opacity = _opacityAnimation.value;

        if (widget.customBuilder != null) {
          return widget.customBuilder!(context, opacity);
        }

        switch (widget.style) {
          case HyperTypingCaretStyle.block:
            return Opacity(
              opacity: opacity,
              child: Container(
                width: widget.height * 0.55,
                height: widget.height,
                margin: const EdgeInsets.only(left: 3.0),
                decoration: BoxDecoration(
                  color: effectiveColor,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            );

          case HyperTypingCaretStyle.underscore:
            return Opacity(
              opacity: opacity,
              child: Container(
                width: widget.height * 0.6,
                height: widget.width + 1.0,
                margin: const EdgeInsets.only(left: 2.0),
                color: effectiveColor,
              ),
            );

          case HyperTypingCaretStyle.dot:
            return Opacity(
              opacity: opacity,
              child: Container(
                width: widget.height * 0.45,
                height: widget.height * 0.45,
                margin: const EdgeInsets.only(left: 4.0),
                decoration: BoxDecoration(
                  color: effectiveColor,
                  shape: BoxShape.circle,
                ),
              ),
            );

          case HyperTypingCaretStyle.bar:
          case HyperTypingCaretStyle.custom:
            return Opacity(
              opacity: opacity,
              child: Container(
                width: widget.width,
                height: widget.height,
                margin: const EdgeInsets.only(left: 2.5),
                decoration: BoxDecoration(
                  color: effectiveColor,
                  borderRadius: BorderRadius.circular(widget.width / 2),
                ),
              ),
            );
        }
      },
    );
  }
}
