import 'dart:math' show max;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// RubySpan - A WidgetSpan that renders Ruby/Furigana text
///
/// Ruby annotations are used in Japanese to show pronunciation (Furigana)
/// above Kanji characters.
///
/// Example HTML:
/// ```html
/// <ruby>漢字<rt>かんじ</rt></ruby>
/// ```
///
class RubySpan extends WidgetSpan {
  RubySpan({
    required String baseText,
    required String rubyText,
    required TextStyle baseStyle,
    super.alignment = PlaceholderAlignment.middle,
  }) : super(
          child: RubyTextWidget(
            baseText: baseText,
            rubyText: rubyText,
            baseStyle: baseStyle,
          ),
        );
}

/// Widget wrapper for RenderRubyText
///
/// This widget creates a LeafRenderObjectWidget that renders Ruby text
/// using custom painting for perfect baseline alignment.
class RubyTextWidget extends LeafRenderObjectWidget {
  final String baseText;
  final String rubyText;
  final TextStyle baseStyle;

  /// Overrides system text scaling (WCAG 1.4.4). `null` → read from
  /// `MediaQuery.textScalerOf(context)`, matching [HyperRenderWidget].
  final TextScaler? textScaler;

  const RubyTextWidget({
    super.key,
    required this.baseText,
    required this.rubyText,
    required this.baseStyle,
    this.textScaler,
  });

  @override
  RenderRubyText createRenderObject(BuildContext context) {
    return RenderRubyText(
      baseText: baseText,
      rubyText: rubyText,
      baseStyle: baseStyle,
      textScaler: textScaler ?? MediaQuery.textScalerOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderRubyText renderObject) {
    renderObject
      ..baseText = baseText
      ..rubyText = rubyText
      ..baseStyle = baseStyle
      ..textScaler = textScaler ?? MediaQuery.textScalerOf(context);
  }
}

/// Custom RenderObject for Ruby/Furigana text
///
/// This renders base text with smaller ruby text above it,
/// maintaining consistent line height and proper baseline alignment.
///
class RenderRubyText extends RenderBox {
  String _baseText;
  String _rubyText;
  TextStyle _baseStyle;
  TextScaler _textScaler;

  late TextPainter _basePainter;
  late TextPainter _rubyPainter;

  /// Ruby text size ratio compared to base text (W3C standard: 50%)
  static const double rubyTextRatio = 0.5;

  /// Spacing between ruby text and base text
  static const double rubySpacing = 1.0;

  RenderRubyText({
    required String baseText,
    required String rubyText,
    required TextStyle baseStyle,
    TextScaler textScaler = TextScaler.noScaling,
  })  : _baseText = baseText,
        _rubyText = rubyText,
        _baseStyle = baseStyle,
        _textScaler = textScaler {
    _initPainters();
  }

  TextScaler get textScaler => _textScaler;
  set textScaler(TextScaler value) {
    if (_textScaler != value) {
      _textScaler = value;
      _initPainters();
      markNeedsLayout();
    }
  }

  String get baseText => _baseText;
  set baseText(String value) {
    if (_baseText != value) {
      _baseText = value;
      _initPainters();
      markNeedsLayout();
    }
  }

  String get rubyText => _rubyText;
  set rubyText(String value) {
    if (_rubyText != value) {
      _rubyText = value;
      _initPainters();
      markNeedsLayout();
    }
  }

  TextStyle get baseStyle => _baseStyle;
  set baseStyle(TextStyle value) {
    if (_baseStyle != value) {
      _baseStyle = value;
      _initPainters();
      markNeedsLayout();
    }
  }

  void _initPainters() {
    // Base text painter
    _basePainter = TextPainter(
      text: TextSpan(text: _baseText, style: _baseStyle),
      textDirection: TextDirection.ltr,
      textScaler: _textScaler,
    );

    // Ruby text painter (smaller font)
    final rubyFontSize = (_baseStyle.fontSize ?? 16.0) * rubyTextRatio;
    _rubyPainter = TextPainter(
      text: TextSpan(
        text: _rubyText,
        style: _baseStyle.copyWith(fontSize: rubyFontSize),
      ),
      textDirection: TextDirection.ltr,
      textScaler: _textScaler,
    );
  }

  @override
  void performLayout() {
    // Layout both painters
    _basePainter.layout();
    _rubyPainter.layout();

    // Total width = max(base width, ruby width)
    final width = max(_basePainter.width, _rubyPainter.width);

    // Total height = ruby height + spacing + base height
    final height = _rubyPainter.height + rubySpacing + _basePainter.height;

    size = constraints.constrain(Size(width, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    // Paint ruby text on top (centered horizontally)
    final rubyOffset = Offset(
      offset.dx + (size.width - _rubyPainter.width) / 2,
      offset.dy,
    );
    _rubyPainter.paint(canvas, rubyOffset);

    // Paint base text below (centered horizontally)
    final baseOffset = Offset(
      offset.dx + (size.width - _basePainter.width) / 2,
      offset.dy + _rubyPainter.height + rubySpacing,
    );
    _basePainter.paint(canvas, baseOffset);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _basePainter.layout();
    _rubyPainter.layout();
    return max(_basePainter.minIntrinsicWidth, _rubyPainter.minIntrinsicWidth);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _basePainter.layout();
    _rubyPainter.layout();
    return max(_basePainter.maxIntrinsicWidth, _rubyPainter.maxIntrinsicWidth);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _basePainter.layout();
    _rubyPainter.layout();
    return _rubyPainter.height + rubySpacing + _basePainter.height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return computeMinIntrinsicHeight(width);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    // Return baseline of base text to ensure consistent line-height
    // Ruby text height + spacing + base text baseline
    _basePainter.layout();
    _rubyPainter.layout();

    final baseBaseline = _basePainter.computeDistanceToActualBaseline(baseline);
    return _rubyPainter.height + rubySpacing + baseBaseline;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isReadOnly = true
      ..label = '$_baseText ($_rubyText)'
      ..textDirection = TextDirection.ltr;
  }

  @override
  bool hitTestSelf(Offset position) => true;
}

/// Extension to easily create RubySpan from a node
extension RubySpanBuilder on RubySpan {
  /// Create a RubySpan from base and ruby text with default styling
  static RubySpan create({
    required String baseText,
    required String rubyText,
    TextStyle? baseStyle,
    double? fontSize,
    Color? color,
  }) {
    final style = baseStyle ??
        TextStyle(
          fontSize: fontSize ?? 16.0,
          color: color ?? const Color(0xFF000000),
        );

    return RubySpan(
      baseText: baseText,
      rubyText: rubyText,
      baseStyle: style,
    );
  }
}
