import 'dart:math' show max;

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
/// Reference: doc3.md - "Requirement 4: Japanese Ruby/Furigana Support"
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

  const RubyTextWidget({
    super.key,
    required this.baseText,
    required this.rubyText,
    required this.baseStyle,
  });

  @override
  RenderRubyText createRenderObject(BuildContext context) {
    return RenderRubyText(
      baseText: baseText,
      rubyText: rubyText,
      baseStyle: baseStyle,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderRubyText renderObject) {
    renderObject
      ..baseText = baseText
      ..rubyText = rubyText
      ..baseStyle = baseStyle;
  }
}

/// Custom RenderObject for Ruby/Furigana text
///
/// This renders base text with smaller ruby text above it,
/// maintaining consistent line height and proper baseline alignment.
///
/// Reference: doc3.md - "class RenderRubyText extends RenderBox"
class RenderRubyText extends RenderBox {
  String _baseText;
  String _rubyText;
  TextStyle _baseStyle;

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
  })  : _baseText = baseText,
        _rubyText = rubyText,
        _baseStyle = baseStyle {
    _initPainters();
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
    );

    // Ruby text painter (smaller font)
    final rubyFontSize = (_baseStyle.fontSize ?? 16.0) * rubyTextRatio;
    _rubyPainter = TextPainter(
      text: TextSpan(
        text: _rubyText,
        style: _baseStyle.copyWith(fontSize: rubyFontSize),
      ),
      textDirection: TextDirection.ltr,
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

    final baseBaseline =
        _basePainter.computeDistanceToActualBaseline(baseline);
    return _rubyPainter.height + rubySpacing + baseBaseline;
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
