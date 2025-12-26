import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

/// Display type for CSS display property
/// Reference: doc1.txt - ComputedStyle class
enum DisplayType {
  /// Block-level element (div, p, h1-h6)
  block,

  /// Inline element (span, a, strong)
  inline,

  /// Inline-block element
  inlineBlock,

  /// Flex container
  flex,

  /// Grid container (future)
  grid,

  /// Table element
  table,

  /// Table row
  tableRow,

  /// Table cell
  tableCell,

  /// Hidden element
  none,
}

/// Text alignment for CSS text-align property
enum HyperTextAlign {
  left,
  center,
  right,
  justify,
}

/// Vertical alignment for CSS vertical-align property
enum HyperVerticalAlign {
  baseline,
  top,
  middle,
  bottom,
  textTop,
  textBottom,
}

/// Overflow behavior for CSS overflow property
enum HyperOverflow {
  visible,
  hidden,
  scroll,
  auto,
}

/// Float behavior for CSS float property
enum HyperFloat {
  /// No floating (default)
  none,

  /// Float to the left, content flows around on the right
  left,

  /// Float to the right, content flows around on the left
  right,
}

/// Clear behavior for CSS clear property
enum HyperClear {
  /// No clearing (default)
  none,

  /// Clear left floats
  left,

  /// Clear right floats
  right,

  /// Clear both left and right floats
  both,
}

/// CSS timing function for animations and transitions
enum HyperTimingFunction {
  /// Linear timing
  linear,

  /// Ease timing (default)
  ease,

  /// Ease-in timing
  easeIn,

  /// Ease-out timing
  easeOut,

  /// Ease-in-out timing
  easeInOut,
}

/// CSS animation direction
enum HyperAnimationDirection {
  /// Normal direction
  normal,

  /// Reverse direction
  reverse,

  /// Alternate direction
  alternate,

  /// Alternate reverse direction
  alternateReverse,
}

/// CSS animation fill mode
enum HyperAnimationFillMode {
  /// No fill
  none,

  /// Forwards fill
  forwards,

  /// Backwards fill
  backwards,

  /// Both fill
  both,
}

/// CSS transition definition
class HyperTransition {
  /// Property to transition (null means 'all')
  final String? property;

  /// Duration in milliseconds
  final int duration;

  /// Timing function
  final HyperTimingFunction timingFunction;

  /// Delay in milliseconds
  final int delay;

  const HyperTransition({
    this.property,
    this.duration = 0,
    this.timingFunction = HyperTimingFunction.ease,
    this.delay = 0,
  });

  /// Check if transition is defined
  bool get isDefined => duration > 0;

  @override
  String toString() =>
      'HyperTransition($property, ${duration}ms, $timingFunction, ${delay}ms)';
}

/// Computed style for a UDT node
/// All CSS properties are resolved to final values here
///
/// Reference: doc1.txt - "1.1. Cấu trúc Dữ liệu Style (The Style Node)"
/// Each Node in UDT will have a ComputedStyle object
class ComputedStyle {
  /// Track which properties have been explicitly set (not inherited)
  /// This is crucial for proper CSS inheritance
  final Set<String> _explicitlySet = {};

  /// Check if a property was explicitly set
  bool isExplicitlySet(String property) => _explicitlySet.contains(property);

  /// Mark a property as explicitly set
  void markExplicitlySet(String property) => _explicitlySet.add(property);

  /// Mark multiple properties as explicitly set
  void markAllExplicitlySet(Iterable<String> properties) =>
      _explicitlySet.addAll(properties);
  // ============================================
  // Box Model Properties
  // ============================================

  /// CSS width (null means auto)
  double? width;

  /// CSS height (null means auto)
  double? height;

  /// CSS min-width
  double? minWidth;

  /// CSS max-width
  double? maxWidth;

  /// CSS min-height
  double? minHeight;

  /// CSS max-height
  double? maxHeight;

  /// CSS margin (collapsed margins handled in layout)
  EdgeInsets margin;

  /// CSS padding
  EdgeInsets padding;

  /// CSS border-width (simplified - same for all sides)
  EdgeInsets borderWidth;

  /// CSS border-color
  Color? borderColor;

  /// CSS border-radius
  BorderRadius? borderRadius;

  // ============================================
  // Text Properties
  // ============================================

  /// CSS color - INHERITABLE
  Color color;

  /// CSS font-size - INHERITABLE
  double fontSize;

  /// CSS font-weight - INHERITABLE
  FontWeight fontWeight;

  /// CSS font-style - INHERITABLE
  FontStyle fontStyle;

  /// CSS font-family - INHERITABLE
  String? fontFamily;

  /// CSS text-decoration
  TextDecoration? textDecoration;

  /// CSS text-decoration-color
  Color? textDecorationColor;

  /// CSS line-height (as multiplier) - INHERITABLE
  double? lineHeight;

  /// CSS letter-spacing
  double? letterSpacing;

  /// CSS word-spacing
  double? wordSpacing;

  /// CSS text-align - INHERITABLE for block
  HyperTextAlign textAlign;

  /// CSS vertical-align (for inline elements)
  HyperVerticalAlign verticalAlign;

  /// CSS text-transform
  String? textTransform;

  /// CSS white-space
  String? whiteSpace;

  // ============================================
  // Background Properties
  // ============================================

  /// CSS background-color
  Color? backgroundColor;

  /// CSS background-image URL (simplified)
  String? backgroundImage;

  // ============================================
  // Layout Properties
  // ============================================

  /// CSS display
  DisplayType display;

  /// CSS overflow-x
  HyperOverflow overflowX;

  /// CSS overflow-y
  HyperOverflow overflowY;

  /// CSS position (simplified)
  String position;

  /// CSS float (left, right, none)
  HyperFloat float;

  /// CSS clear (left, right, both, none)
  HyperClear clear;

  /// CSS z-index
  int? zIndex;

  // ============================================
  // Transform Properties
  // ============================================

  /// CSS transform matrix (computed from transform property)
  Matrix4? transform;

  /// CSS opacity
  double opacity;

  // ============================================
  // Animation Properties
  // ============================================

  /// CSS transition property
  HyperTransition? transition;

  /// CSS animation name
  String? animationName;

  /// CSS animation duration (in milliseconds)
  int? animationDuration;

  /// CSS animation timing function
  HyperTimingFunction animationTimingFunction;

  /// CSS animation delay (in milliseconds)
  int? animationDelay;

  /// CSS animation iteration count (null means infinite)
  int? animationIterationCount;

  /// CSS animation direction
  HyperAnimationDirection animationDirection;

  /// CSS animation fill mode
  HyperAnimationFillMode animationFillMode;

  // ============================================
  // Table-specific Properties
  // ============================================

  /// colspan attribute
  int colspan;

  /// rowspan attribute
  int rowspan;

  // ============================================
  // Constructor
  // ============================================

  ComputedStyle({
    this.width,
    this.height,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.borderWidth = EdgeInsets.zero,
    this.borderColor,
    this.borderRadius,
    this.color = const Color(0xFF000000),
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
    this.fontFamily,
    this.textDecoration,
    this.textDecorationColor,
    this.lineHeight,
    this.letterSpacing,
    this.wordSpacing,
    this.textAlign = HyperTextAlign.left,
    this.verticalAlign = HyperVerticalAlign.baseline,
    this.textTransform,
    this.whiteSpace,
    this.backgroundColor,
    this.backgroundImage,
    this.display = DisplayType.inline,
    this.overflowX = HyperOverflow.visible,
    this.overflowY = HyperOverflow.visible,
    this.position = 'static',
    this.float = HyperFloat.none,
    this.clear = HyperClear.none,
    this.zIndex,
    this.transform,
    this.opacity = 1.0,
    this.transition,
    this.animationName,
    this.animationDuration,
    this.animationTimingFunction = HyperTimingFunction.ease,
    this.animationDelay,
    this.animationIterationCount,
    this.animationDirection = HyperAnimationDirection.normal,
    this.animationFillMode = HyperAnimationFillMode.none,
    this.colspan = 1,
    this.rowspan = 1,
  });

  /// Inherit inheritable properties from parent
  ///
  /// Reference: doc1.txt - "1.2. Quy trình Resolve"
  /// Properties like color, font-family are inherited from parent Node
  /// margin, padding are NOT inherited
  void inheritFrom(ComputedStyle parent) {
    // Text properties that inherit
    color = parent.color;
    fontSize = parent.fontSize;
    fontWeight = parent.fontWeight;
    fontStyle = parent.fontStyle;
    fontFamily = parent.fontFamily;
    lineHeight = parent.lineHeight;
    letterSpacing = parent.letterSpacing;
    wordSpacing = parent.wordSpacing;
    textAlign = parent.textAlign;
    whiteSpace = parent.whiteSpace;

    // Note: margin, padding, border DO NOT inherit
  }

  /// Convert to Flutter TextStyle
  TextStyle toTextStyle() {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      fontFamily: fontFamily,
      decoration: textDecoration,
      decorationColor: textDecorationColor,
      height: lineHeight ?? 1.4,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
    );
  }

  /// Create a copy with modifications
  ComputedStyle copyWith({
    double? width,
    double? height,
    EdgeInsets? margin,
    EdgeInsets? padding,
    EdgeInsets? borderWidth,
    Color? borderColor,
    BorderRadius? borderRadius,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    String? fontFamily,
    TextDecoration? textDecoration,
    double? lineHeight,
    HyperTextAlign? textAlign,
    Color? backgroundColor,
    DisplayType? display,
    double? opacity,
    HyperFloat? float,
    HyperClear? clear,
  }) {
    return ComputedStyle(
      width: width ?? this.width,
      height: height ?? this.height,
      margin: margin ?? this.margin,
      padding: padding ?? this.padding,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      fontFamily: fontFamily ?? this.fontFamily,
      textDecoration: textDecoration ?? this.textDecoration,
      lineHeight: lineHeight ?? this.lineHeight,
      textAlign: textAlign ?? this.textAlign,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      display: display ?? this.display,
      opacity: opacity ?? this.opacity,
      float: float ?? this.float,
      clear: clear ?? this.clear,
    );
  }

  /// Default style matching browser defaults with improved readability
  /// lineHeight: 1.5 is recommended for better readability
  static ComputedStyle get defaultStyle => ComputedStyle(
        lineHeight: 1.5, // Better readability than browser default 1.0
      );
}
