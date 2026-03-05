/// Fragment Measurement Engine
///
/// Delegates to TextLayoutEngine for actual measurement.
/// Provides clean interface for measuring fragments.
library;

import 'package:flutter/painting.dart';

import '../model/fragment.dart';
import '../model/computed_style.dart';
import '../core/text_layout_engine.dart';

/// Measures fragments (text, atomic elements)
///
/// This class provides abstraction over measurement logic,
/// making it easier to test and modify independently.
class FragmentMeasurer {
  const FragmentMeasurer();

  /// Measure a fragment and update its measuredSize
  void measure(Fragment fragment) {
    switch (fragment.type) {
      case FragmentType.text:
        _measureText(fragment);
        break;
      case FragmentType.atomic:
        _measureAtomic(fragment);
        break;
      case FragmentType.ruby:
        _measureRuby(fragment);
        break;
      default:
        // Other types don't need measurement or are handled elsewhere
        break;
    }
  }

  /// Measure text width for given content and style
  ///
  /// This is useful for calculating split points.
  double measureTextWidth(String text, ComputedStyle style) {
    final painter = TextLayoutEngine.createPainter(
      text: TextSpan(text: text, style: _buildTextStyle(style)),
      textDirection: TextDirection.ltr,
    );

    final size = TextLayoutEngine.measureText(
      painter: painter,
      maxWidth: double.infinity,
    );

    return size.width;
  }

  /// Measure text and get detailed metrics
  TextMetrics measureTextMetrics(String text, ComputedStyle style) {
    final textStyle = _buildTextStyle(style);
    final painter = TextLayoutEngine.createPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );

    TextLayoutEngine.measureText(painter: painter, maxWidth: double.infinity);

    return TextMetrics.fromPainter(painter);
  }

  void _measureText(Fragment fragment) {
    if (fragment.text == null) return;

    final painter = TextLayoutEngine.createPainter(
      text: TextSpan(text: fragment.text!, style: _buildTextStyle(fragment.style)),
      textDirection: TextDirection.ltr,
    );

    final size = TextLayoutEngine.measureText(
      painter: painter,
      maxWidth: double.infinity, // Text fragments are pre-split by line-breaker
    );

    fragment.measuredSize = size;
  }

  void _measureAtomic(Fragment fragment) {
    // Atomic elements (images, widgets) have intrinsic size
    // If already measured, keep it; otherwise use default or style-specified size
    if (fragment.measuredSize != null) {
      return; // Already measured
    }

    final style = fragment.style;
    final width = (style.width != null && style.width! > 0) ? style.width! : 100.0;
    final height = (style.height != null && style.height! > 0) ? style.height! : 100.0;

    fragment.measuredSize = Size(width, height);
  }

  void _measureRuby(Fragment fragment) {
    // Ruby text has base + annotation
    // For now, use simple measurement
    // TODO: Implement proper Ruby measurement with base + rt
    fragment.measuredSize = const Size(50, 30);
  }

  TextStyle _buildTextStyle(ComputedStyle style) {
    return TextStyle(
      fontSize: style.fontSize,
      fontWeight: _parseFontWeight(style.fontWeight),
      fontStyle: style.fontStyle,
      color: style.color,
      decoration: style.textDecoration ?? TextDecoration.none,
      decorationColor: style.textDecorationColor,
      fontFamily: style.fontFamily,
      height: (style.lineHeight != null && style.lineHeight! > 0) ? style.lineHeight! / style.fontSize : null,
      letterSpacing: style.letterSpacing,
      wordSpacing: style.wordSpacing,
      backgroundColor: style.backgroundColor,
    );
  }

  FontWeight _parseFontWeight(dynamic fontWeight) {
    if (fontWeight is FontWeight) return fontWeight;
    if (fontWeight is int) {
      switch (fontWeight) {
        case 100: return FontWeight.w100;
        case 200: return FontWeight.w200;
        case 300: return FontWeight.w300;
        case 400: return FontWeight.w400;
        case 500: return FontWeight.w500;
        case 600: return FontWeight.w600;
        case 700: return FontWeight.w700;
        case 800: return FontWeight.w800;
        case 900: return FontWeight.w900;
        default: return FontWeight.w400;
      }
    }
    return FontWeight.w400;
  }
}

/// Measurement result with metrics
class MeasurementResult {
  final Size size;
  final TextMetrics? metrics;

  const MeasurementResult({
    required this.size,
    this.metrics,
  });

  double get width => size.width;
  double get height => size.height;
}
