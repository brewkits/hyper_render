/// Text Layout Engine - Abstraction layer for Flutter's TextPainter
///
/// This abstraction centralizes all TextPainter interactions to:
/// 1. Isolate HyperRender from Flutter Text API changes (Impeller migration, etc.)
/// 2. Provide a single point of maintenance when Flutter updates
/// 3. Enable testing and mocking of text layout operations
/// 4. Add HyperRender-specific optimizations and caching strategies
///
/// When Flutter's TextPainter API changes (e.g., during Impeller migration),
/// only this file needs to be updated, not the entire codebase.
library;

import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

import '../exceptions/hyper_render_exceptions.dart';

/// Abstraction for Flutter's TextPainter
///
/// Provides a stable API for text measurement and painting that isolates
/// HyperRender from Flutter internal changes.
class TextLayoutEngine {
  /// Create a TextPainter with the given configuration
  ///
  /// This factory method centralizes TextPainter creation, making it easier
  /// to update when Flutter's constructor signature changes.
  static TextPainter createPainter({
    required InlineSpan text,
    TextAlign textAlign = TextAlign.start,
    TextDirection textDirection = TextDirection.ltr,
    double textScaleFactor = 1.0,
    int? maxLines,
    String? ellipsis,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    TextHeightBehavior? textHeightBehavior,
  }) {
    return TextPainter(
      text: text,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: TextScaler.linear(textScaleFactor),
      maxLines: maxLines,
      ellipsis: ellipsis,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }

  /// Measure text and return its size
  ///
  /// Handles the layout calculation and returns the measured size.
  /// This method encapsulates the measure-then-read pattern.
  static Size measureText({
    required TextPainter painter,
    required double maxWidth,
    double minWidth = 0.0,
  }) {
    painter.layout(
      minWidth: minWidth,
      maxWidth: maxWidth,
    );
    return painter.size;
  }

  /// Get the intrinsic width of text (minimum width needed)
  ///
  /// This is useful for table column sizing and other auto-width calculations.
  static double getMinIntrinsicWidth({
    required TextPainter painter,
  }) {
    // Layout with infinite width to get natural size
    painter.layout(minWidth: 0, maxWidth: double.infinity);
    return painter.width;
  }

  /// Get the maximum intrinsic width (width without line breaks)
  ///
  /// This represents the "ideal" width if there were no constraints.
  static double getMaxIntrinsicWidth({
    required TextPainter painter,
  }) {
    // For single-line text, this is the same as min intrinsic width
    final currentMaxLines = painter.maxLines;
    painter.maxLines = 1; // Force single line
    painter.layout(minWidth: 0, maxWidth: double.infinity);
    final width = painter.width;
    painter.maxLines = currentMaxLines; // Restore original
    return width;
  }

  /// Paint text onto canvas at the given offset
  ///
  /// Centralizes the painting operation for easier debugging and profiling.
  static void paintText({
    required Canvas canvas,
    required TextPainter painter,
    required Offset offset,
  }) {
    painter.paint(canvas, offset);
  }

  /// Get text position from pixel offset
  ///
  /// Used for text selection - converts a tap position to a character offset.
  static TextPosition getPositionForOffset({
    required TextPainter painter,
    required Offset offset,
  }) {
    return painter.getPositionForOffset(offset);
  }

  /// Get the bounding boxes for a text selection range
  ///
  /// Returns rectangles that can be used to paint selection highlights.
  static List<ui.TextBox> getBoxesForSelection({
    required TextPainter painter,
    required TextSelection selection,
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) {
    return painter.getBoxesForSelection(
      selection,
      boxHeightStyle: boxHeightStyle,
      boxWidthStyle: boxWidthStyle,
    );
  }

  /// Get line metrics for the laid-out text
  ///
  /// Provides detailed information about each line: baseline, ascent, descent.
  /// Useful for precise vertical alignment and selection highlight positioning.
  static List<ui.LineMetrics> getLineMetrics({
    required TextPainter painter,
  }) {
    return painter.computeLineMetrics();
  }

  /// Get the word boundary at a given text position
  ///
  /// Used for double-tap word selection.
  static TextRange getWordBoundary({
    required TextPainter painter,
    required TextPosition position,
  }) {
    return painter.getWordBoundary(position);
  }

  /// Dispose a TextPainter and free its resources
  ///
  /// Centralizes disposal for proper resource cleanup tracking.
  static void disposePainter(TextPainter painter) {
    painter.dispose();
  }

  /// Create a hash key for TextPainter caching
  ///
  /// Generates a cache key based on text style properties.
  /// Used by LRU cache to determine if a TextPainter can be reused.
  static int createCacheKey({
    required TextStyle? style,
    required TextAlign textAlign,
    required TextDirection textDirection,
    required double textScaleFactor,
    required int? maxLines,
  }) {
    return Object.hash(
      style?.fontFamily,
      style?.fontSize,
      style?.fontWeight,
      style?.fontStyle,
      style?.letterSpacing,
      style?.wordSpacing,
      style?.height,
      style?.color,
      style?.decoration,
      textAlign,
      textDirection,
      textScaleFactor,
      maxLines,
    );
  }
}

/// Configuration for text measurement behavior
///
/// Allows customization of how text is measured and laid out.
class TextLayoutConfig {
  /// Whether to use tight bounding boxes for selection highlights
  final bool useTightBoundingBoxes;

  /// Default text scale factor (for accessibility)
  final double defaultTextScaleFactor;

  /// Whether to compute line metrics eagerly
  final bool computeLineMetricsEagerly;

  const TextLayoutConfig({
    this.useTightBoundingBoxes = true,
    this.defaultTextScaleFactor = 1.0,
    this.computeLineMetricsEagerly = false,
  });

  /// Default configuration
  static const TextLayoutConfig defaults = TextLayoutConfig();
}

/// Helper for common text layout patterns
extension TextPainterHelpers on TextPainter {
  /// Measure with the given constraints and return size
  Size measureWithConstraints(BoxConstraints constraints) {
    return TextLayoutEngine.measureText(
      painter: this,
      maxWidth: constraints.maxWidth,
      minWidth: constraints.minWidth,
    );
  }

  /// Check if text overflows the given width
  bool overflows(double maxWidth) {
    layout(maxWidth: maxWidth);
    return didExceedMaxLines;
  }

  /// Get the height of a single line of text
  double get singleLineHeight {
    final currentMaxLines = maxLines;
    maxLines = 1;
    layout(maxWidth: double.infinity);
    final height = size.height;
    maxLines = currentMaxLines;
    return height;
  }
}

/// Metrics for a measured text block
///
/// Provides structured access to text measurement results.
class TextMetrics {
  /// The size of the text
  final Size size;

  /// Line metrics (baseline, ascent, descent per line)
  final List<ui.LineMetrics> lineMetrics;

  /// Whether the text exceeded max lines
  final bool didExceedMaxLines;

  /// Number of lines actually used
  final int lineCount;

  const TextMetrics({
    required this.size,
    required this.lineMetrics,
    required this.didExceedMaxLines,
    required this.lineCount,
  });

  /// Create metrics from a TextPainter
  factory TextMetrics.fromPainter(TextPainter painter) {
    return TextMetrics(
      size: painter.size,
      lineMetrics: painter.computeLineMetrics(),
      didExceedMaxLines: painter.didExceedMaxLines,
      lineCount: painter.computeLineMetrics().length,
    );
  }

  /// Get the baseline offset for the first line
  double get firstBaseline {
    return lineMetrics.isEmpty ? 0.0 : lineMetrics.first.baseline;
  }

  /// Get the total ascent (distance from baseline to top)
  double get totalAscent {
    return lineMetrics.isEmpty ? 0.0 : lineMetrics.first.ascent;
  }

  /// Get the total descent (distance from baseline to bottom)
  double get totalDescent {
    if (lineMetrics.isEmpty) return 0.0;
    final lastLine = lineMetrics.last;
    return lastLine.descent;
  }
}

/// Text layout result with detailed metrics
class TextLayoutResult {
  /// The painter used for this layout
  final TextPainter painter;

  /// Metrics for the laid-out text
  final TextMetrics metrics;

  /// Cache key for this layout configuration
  final int cacheKey;

  const TextLayoutResult({
    required this.painter,
    required this.metrics,
    required this.cacheKey,
  });

  /// Dispose resources
  void dispose() {
    TextLayoutEngine.disposePainter(painter);
  }
}

/// Builder for creating text painters with fluent API
class TextPainterBuilder {
  InlineSpan? _text;
  TextAlign _textAlign = TextAlign.start;
  TextDirection _textDirection = TextDirection.ltr;
  double _textScaleFactor = 1.0;
  int? _maxLines;
  String? _ellipsis;
  TextWidthBasis _textWidthBasis = TextWidthBasis.parent;
  TextHeightBehavior? _textHeightBehavior;

  TextPainterBuilder text(InlineSpan text) {
    _text = text;
    return this;
  }

  TextPainterBuilder align(TextAlign align) {
    _textAlign = align;
    return this;
  }

  TextPainterBuilder direction(TextDirection direction) {
    _textDirection = direction;
    return this;
  }

  TextPainterBuilder scaleFactor(double factor) {
    _textScaleFactor = factor;
    return this;
  }

  TextPainterBuilder maxLines(int? lines) {
    _maxLines = lines;
    return this;
  }

  TextPainterBuilder ellipsis(String? ellipsis) {
    _ellipsis = ellipsis;
    return this;
  }

  TextPainterBuilder widthBasis(TextWidthBasis basis) {
    _textWidthBasis = basis;
    return this;
  }

  TextPainterBuilder heightBehavior(TextHeightBehavior? behavior) {
    _textHeightBehavior = behavior;
    return this;
  }

  /// Build the TextPainter
  TextPainter build() {
    if (_text == null) {
      throw TextLayoutException.missingText();
    }

    return TextLayoutEngine.createPainter(
      text: _text!,
      textAlign: _textAlign,
      textDirection: _textDirection,
      textScaleFactor: _textScaleFactor,
      maxLines: _maxLines,
      ellipsis: _ellipsis,
      textWidthBasis: _textWidthBasis,
      textHeightBehavior: _textHeightBehavior,
    );
  }

  /// Build and measure the text
  TextLayoutResult buildAndMeasure({
    required double maxWidth,
    double minWidth = 0.0,
  }) {
    final painter = build();
    TextLayoutEngine.measureText(
      painter: painter,
      maxWidth: maxWidth,
      minWidth: minWidth,
    );

    final metrics = TextMetrics.fromPainter(painter);
    final cacheKey = TextLayoutEngine.createCacheKey(
      style: (_text as TextSpan?)?.style,
      textAlign: _textAlign,
      textDirection: _textDirection,
      textScaleFactor: _textScaleFactor,
      maxLines: _maxLines,
    );

    return TextLayoutResult(
      painter: painter,
      metrics: metrics,
      cacheKey: cacheKey,
    );
  }
}
