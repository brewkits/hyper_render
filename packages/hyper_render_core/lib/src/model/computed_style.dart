import 'dart:ui' as ui;
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

/// Border style for CSS border-style property
enum HyperBorderStyle {
  /// No border
  none,

  /// Solid border (default)
  solid,

  /// Dashed border
  dashed,

  /// Dotted border
  dotted,

  /// Double border
  double,

  /// 3D grooved border
  groove,

  /// 3D ridged border
  ridge,

  /// 3D inset border
  inset,

  /// 3D outset border
  outset,
}

/// Text direction for CSS direction property
enum HyperTextDirection {
  /// Left-to-right (default)
  ltr,

  /// Right-to-left (Arabic, Hebrew, etc.)
  rtl,
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

/// CSS list-style-type values
enum ListStyleType {
  /// Decimal numbers (1, 2, 3...) - default for <ol>
  decimal,

  /// Lowercase roman numerals (i, ii, iii, iv...)
  lowerRoman,

  /// Uppercase roman numerals (I, II, III, IV...)
  upperRoman,

  /// Lowercase letters (a, b, c...)
  lowerAlpha,

  /// Uppercase letters (A, B, C...)
  upperAlpha,

  /// Filled circle • - default for <ul>
  disc,

  /// Hollow circle ○
  circle,

  /// Filled square ▪
  square,

  /// No marker
  none,
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

  /// CSS border-style
  HyperBorderStyle borderStyle;

  /// Individual border styles (if different from borderStyle)
  HyperBorderStyle? borderTopStyle;
  HyperBorderStyle? borderRightStyle;
  HyperBorderStyle? borderBottomStyle;
  HyperBorderStyle? borderLeftStyle;

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

  /// CSS text-overflow
  TextOverflow? textOverflow;

  /// CSS word-break
  String? wordBreak;

  /// CSS overflow-wrap
  String? overflowWrap;

  /// CSS list-style-type - INHERITABLE
  /// Controls the marker style for list items (ul/ol)
  ListStyleType? listStyleType;

  /// CSS text-shadow
  List<Shadow>? textShadow;

  /// CSS box-shadow
  List<BoxShadow>? boxShadow;

  /// CSS filter (blur, brightness, etc.)
  ui.ImageFilter? filter;

  /// CSS backdrop-filter
  ui.ImageFilter? backdropFilter;

  // ============================================
  // Background Properties
  // ============================================

  /// CSS background-color
  Color? backgroundColor;

  /// CSS background-gradient
  Gradient? backgroundGradient;

  /// CSS background-image URL (simplified)
  String? backgroundImage;

  /// CSS background-size
  String? backgroundSize;

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

  /// CSS direction (text direction)
  HyperTextDirection? hyperDirection;

  /// Whether the text direction is right-to-left
  bool get isRtl => hyperDirection == HyperTextDirection.rtl;

  // ============================================
  // Transform Properties
  // ============================================

  /// CSS transform matrix (computed from transform property)
  /// Using Flutter's Matrix4 from dart:ui via painting.dart
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
  // CSS Custom Properties (variables)
  // ============================================

  /// CSS custom properties defined on this element (--name: value)
  /// Also contains inherited custom properties from parent elements.
  Map<String, String> customProperties = {};

  // ============================================
  // Grid Layout Properties
  // ============================================

  /// CSS grid-template-columns (e.g. "1fr 2fr auto")
  String? gridTemplateColumns;

  /// CSS grid-template-rows
  String? gridTemplateRows;

  /// CSS grid-auto-flow ("row" | "column" | "dense")
  String? gridAutoFlow;

  /// CSS grid-column-start for grid items
  int gridColumnStart = 0;

  /// CSS grid-column-end for grid items
  int gridColumnEnd = 0;

  /// CSS grid-row-start for grid items
  int gridRowStart = 0;

  /// CSS grid-row-end for grid items
  int gridRowEnd = 0;

  /// CSS grid-column span shorthand
  int gridColumnSpan = 1;

  /// CSS grid-row span shorthand
  int gridRowSpan = 1;

  // ============================================
  // Table-specific Properties
  // ============================================

  /// colspan attribute
  int colspan;

  /// rowspan attribute
  int rowspan;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComputedStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          fontSize == other.fontSize &&
          fontWeight == other.fontWeight &&
          fontStyle == other.fontStyle &&
          fontFamily == other.fontFamily &&
          lineHeight == other.lineHeight &&
          textAlign == other.textAlign &&
          display == other.display &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode => Object.hash(
        color,
        fontSize,
        fontWeight,
        fontStyle,
        fontFamily,
        lineHeight,
        textAlign,
        display,
        backgroundColor,
      );


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
    this.borderStyle = HyperBorderStyle.solid,
    this.borderTopStyle,
    this.borderRightStyle,
    this.borderBottomStyle,
    this.borderLeftStyle,
    this.color = const Color(0xFF000000),
    this.fontSize = 14.0, // Reduced from 16px for better mobile readability
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
    this.listStyleType,
    this.textShadow,
    this.boxShadow,
    this.filter,
    this.backdropFilter,
    this.backgroundColor,
    this.backgroundGradient,
    this.backgroundImage,
    this.backgroundSize,
    this.display = DisplayType.inline,
    this.overflowX = HyperOverflow.visible,
    this.overflowY = HyperOverflow.visible,
    this.position = 'static',
    this.float = HyperFloat.none,
    this.clear = HyperClear.none,
    this.zIndex,
    this.hyperDirection,
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
  }) {
    // Validate CSS values
    if (fontSize < 0) {
      throw ArgumentError.value(
        fontSize,
        'fontSize',
        'Font size must be non-negative',
      );
    }

    if (width != null && width! < 0) {
      throw ArgumentError.value(width, 'width', 'Width must be non-negative');
    }

    if (height != null && height! < 0) {
      throw ArgumentError.value(height, 'height', 'Height must be non-negative');
    }

    if (opacity < 0 || opacity > 1) {
      throw ArgumentError.value(
        opacity,
        'opacity',
        'Opacity must be between 0 and 1',
      );
    }

    if (minWidth != null && minWidth! < 0) {
      throw ArgumentError.value(
        minWidth,
        'minWidth',
        'Min width must be non-negative',
      );
    }

    if (minHeight != null && minHeight! < 0) {
      throw ArgumentError.value(
        minHeight,
        'minHeight',
        'Min height must be non-negative',
      );
    }

    if (maxWidth != null && maxWidth! < 0) {
      throw ArgumentError.value(
        maxWidth,
        'maxWidth',
        'Max width must be non-negative',
      );
    }

    if (maxHeight != null && maxHeight! < 0) {
      throw ArgumentError.value(
        maxHeight,
        'maxHeight',
        'Max height must be non-negative',
      );
    }
  }

  /// Inherit inheritable properties from parent
  ///
  /// Reference: doc1.txt - "1.2. Quy trình Resolve"
  /// Properties like color, font-family are inherited from parent Node
  /// margin, padding are NOT inherited
  ///
  /// Only inherit properties that are not explicitly set (null) in child
  void inheritFrom(ComputedStyle parent) {
    // Text properties that inherit (only if not already set)
    color = parent.color;
    fontSize = parent.fontSize;
    fontWeight = parent.fontWeight;
    fontStyle = parent.fontStyle;
    fontFamily ??= parent.fontFamily;
    lineHeight ??= parent.lineHeight;
    letterSpacing ??= parent.letterSpacing;
    wordSpacing ??= parent.wordSpacing;
    textAlign = parent.textAlign;
    whiteSpace ??= parent.whiteSpace;
    listStyleType ??= parent.listStyleType;
    hyperDirection ??= parent.hyperDirection;

    // CSS custom properties are inherited — merge parent's into this element's map
    final merged = Map<String, String>.from(parent.customProperties);
    merged.addAll(customProperties);
    customProperties = merged;

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
      overflow: textOverflow,
      shadows: textShadow, // 🆕 ADDED
      fontFeatures: const [
        ui.FontFeature.proportionalFigures(), // Better number spacing
        ui.FontFeature.enable('liga'), // Ligatures (fi, fl, etc.)
      ],
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
    HyperBorderStyle? borderStyle,
    HyperBorderStyle? borderTopStyle,
    HyperBorderStyle? borderRightStyle,
    HyperBorderStyle? borderBottomStyle,
    HyperBorderStyle? borderLeftStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    String? fontFamily,
    TextDecoration? textDecoration,
    double? lineHeight,
    HyperTextAlign? textAlign,
    List<Shadow>? textShadow,
    List<BoxShadow>? boxShadow,
    ui.ImageFilter? filter,
    ui.ImageFilter? backdropFilter,
    Color? backgroundColor,
    Gradient? backgroundGradient,
    String? backgroundImage,
    String? backgroundSize,
    DisplayType? display,
    double? opacity,
    HyperFloat? float,
    HyperClear? clear,
    HyperTextDirection? hyperDirection,
  }) {
    return ComputedStyle(
      width: width ?? this.width,
      height: height ?? this.height,
      margin: margin ?? this.margin,
      padding: padding ?? this.padding,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      borderStyle: borderStyle ?? this.borderStyle,
      borderTopStyle: borderTopStyle ?? this.borderTopStyle,
      borderRightStyle: borderRightStyle ?? this.borderRightStyle,
      borderBottomStyle: borderBottomStyle ?? this.borderBottomStyle,
      borderLeftStyle: borderLeftStyle ?? this.borderLeftStyle,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      fontFamily: fontFamily ?? this.fontFamily,
      textDecoration: textDecoration ?? this.textDecoration,
      lineHeight: lineHeight ?? this.lineHeight,
      textAlign: textAlign ?? this.textAlign,
      textShadow: textShadow ?? this.textShadow,
      boxShadow: boxShadow ?? this.boxShadow,
      filter: filter ?? this.filter,
      backdropFilter: backdropFilter ?? this.backdropFilter,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      backgroundSize: backgroundSize ?? this.backgroundSize,
      display: display ?? this.display,
      opacity: opacity ?? this.opacity,
      float: float ?? this.float,
      clear: clear ?? this.clear,
      hyperDirection: hyperDirection ?? this.hyperDirection,
    );
  }

  /// Default style matching browser defaults with improved readability.
  ///
  /// Declared as `static final` (not a getter) so it is constructed exactly
  /// once. The resolver compares against this instance 5 times per element;
  /// a getter would silently allocate a fresh object on every comparison,
  /// creating thousands of short-lived ComputedStyle instances for large docs.
  static final ComputedStyle defaultStyle = ComputedStyle(
    fontSize: 14.0, // Default body text size
    lineHeight: 1.7, // Generous line height for comfortable reading
  );
}
