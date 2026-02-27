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
enum BorderStyle {
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
enum TextDirection {
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

/// Flex direction for CSS flex-direction property
enum FlexDirection {
  /// Row (left to right) - default
  row,

  /// Row reverse (right to left)
  rowReverse,

  /// Column (top to bottom)
  column,

  /// Column reverse (bottom to top)
  columnReverse,
}

/// Justify content for CSS justify-content property (main axis alignment)
enum JustifyContent {
  /// Items packed at start (default)
  flexStart,

  /// Items packed at end
  flexEnd,

  /// Items centered
  center,

  /// Items evenly distributed, first at start, last at end
  spaceBetween,

  /// Items evenly distributed with equal space around them
  spaceAround,

  /// Items evenly distributed with equal space between them
  spaceEvenly,
}

/// Align items for CSS align-items property (cross axis alignment)
enum AlignItems {
  /// Items aligned at start
  flexStart,

  /// Items aligned at end
  flexEnd,

  /// Items centered
  center,

  /// Items aligned along baseline
  baseline,

  /// Items stretched to fill container (default)
  stretch,
}

/// Flex wrap for CSS flex-wrap property
enum FlexWrap {
  /// No wrapping (default)
  nowrap,

  /// Wrap onto multiple lines
  wrap,

  /// Wrap onto multiple lines in reverse
  wrapReverse,
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
  BorderStyle borderStyle;

  /// Individual border styles (if different from borderStyle)
  BorderStyle? borderTopStyle;
  BorderStyle? borderRightStyle;
  BorderStyle? borderBottomStyle;
  BorderStyle? borderLeftStyle;

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

  /// CSS text-shadow
  List<Shadow>? textShadow;

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

  /// CSS direction (text direction)
  TextDirection? direction;

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

  /// CSS justify-items (for grid containers)
  JustifyContent justifyItems = JustifyContent.flexStart;

  /// CSS align-content (for grid/flex containers)
  JustifyContent alignContent = JustifyContent.flexStart;

  // ============================================
  // Flexbox Properties
  // ============================================

  /// CSS flex-direction - defines main axis direction
  FlexDirection flexDirection;

  /// CSS justify-content - alignment along main axis
  JustifyContent justifyContent;

  /// CSS align-items - alignment along cross axis
  AlignItems alignItems;

  /// CSS flex-wrap - whether flex items wrap
  FlexWrap flexWrap;

  /// CSS gap - shorthand for row-gap and column-gap
  double? gap;

  /// CSS row-gap - gap between rows in flex/grid
  double? rowGap;

  /// CSS column-gap - gap between columns in flex/grid
  double? columnGap;

  /// CSS flex-grow - how much a flex item should grow
  double? flexGrow;

  /// CSS flex-shrink - how much a flex item should shrink
  double? flexShrink;

  /// CSS flex-basis - initial size of flex item
  double? flexBasis;

  /// CSS align-self - override align-items for specific item
  AlignItems? alignSelf;

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
    this.borderStyle = BorderStyle.solid,
    this.borderTopStyle,
    this.borderRightStyle,
    this.borderBottomStyle,
    this.borderLeftStyle,
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
    this.textOverflow,
    this.textShadow,
    this.backgroundColor,
    this.backgroundImage,
    this.display = DisplayType.inline,
    this.overflowX = HyperOverflow.visible,
    this.overflowY = HyperOverflow.visible,
    this.position = 'static',
    this.float = HyperFloat.none,
    this.clear = HyperClear.none,
    this.zIndex,
    this.direction,
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
    this.flexDirection = FlexDirection.row,
    this.justifyContent = JustifyContent.flexStart,
    this.alignItems = AlignItems.stretch,
    this.flexWrap = FlexWrap.nowrap,
    this.gap,
    this.rowGap,
    this.columnGap,
    this.flexGrow,
    this.flexShrink,
    this.flexBasis,
    this.alignSelf,
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

    // CSS direction is inheritable
    direction ??= parent.direction;

    // CSS custom properties are inherited — merge parent's into this element's map
    // (child-defined properties take priority over parent's)
    final merged = Map<String, String>.from(parent.customProperties);
    merged.addAll(customProperties);
    customProperties = merged;

    // Note: margin, padding, border DO NOT inherit
  }

  /// Whether this element's text direction is right-to-left.
  /// Use this in rendering code where `TextDirection` is hidden by import.
  bool get isRtl => direction == TextDirection.rtl;

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
      shadows: textShadow,
      overflow: textOverflow,
    );
  }

  /// Create a copy with modifications
  ComputedStyle copyWith({
    // Box model
    double? width,
    double? height,
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
    EdgeInsets? margin,
    EdgeInsets? padding,
    EdgeInsets? borderWidth,
    Color? borderColor,
    BorderRadius? borderRadius,
    BorderStyle? borderStyle,
    BorderStyle? borderTopStyle,
    BorderStyle? borderRightStyle,
    BorderStyle? borderBottomStyle,
    BorderStyle? borderLeftStyle,
    // Text
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    String? fontFamily,
    TextDecoration? textDecoration,
    Color? textDecorationColor,
    double? lineHeight,
    double? letterSpacing,
    double? wordSpacing,
    HyperTextAlign? textAlign,
    HyperVerticalAlign? verticalAlign,
    String? textTransform,
    String? whiteSpace,
    TextOverflow? textOverflow,
    List<Shadow>? textShadow,
    // Background
    Color? backgroundColor,
    String? backgroundImage,
    // Layout
    DisplayType? display,
    HyperOverflow? overflowX,
    HyperOverflow? overflowY,
    String? position,
    HyperFloat? float,
    HyperClear? clear,
    int? zIndex,
    TextDirection? direction,
    // Transform / visual
    Matrix4? transform,
    double? opacity,
    // Animation
    HyperTransition? transition,
    String? animationName,
    int? animationDuration,
    HyperTimingFunction? animationTimingFunction,
    int? animationDelay,
    int? animationIterationCount,
    HyperAnimationDirection? animationDirection,
    HyperAnimationFillMode? animationFillMode,
    // Table
    int? colspan,
    int? rowspan,
    // Flexbox
    FlexDirection? flexDirection,
    JustifyContent? justifyContent,
    AlignItems? alignItems,
    FlexWrap? flexWrap,
    double? gap,
    double? rowGap,
    double? columnGap,
    double? flexGrow,
    double? flexShrink,
    double? flexBasis,
    AlignItems? alignSelf,
    // Grid
    String? gridTemplateColumns,
    String? gridTemplateRows,
    String? gridAutoFlow,
    int? gridColumnStart,
    int? gridColumnEnd,
    int? gridRowStart,
    int? gridRowEnd,
    int? gridColumnSpan,
    int? gridRowSpan,
    JustifyContent? justifyItems,
    JustifyContent? alignContent,
    // Custom properties
    Map<String, String>? customProperties,
  }) {
    final result = ComputedStyle(
      width: width ?? this.width,
      height: height ?? this.height,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
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
      textDecorationColor: textDecorationColor ?? this.textDecorationColor,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      textAlign: textAlign ?? this.textAlign,
      verticalAlign: verticalAlign ?? this.verticalAlign,
      textTransform: textTransform ?? this.textTransform,
      whiteSpace: whiteSpace ?? this.whiteSpace,
      textOverflow: textOverflow ?? this.textOverflow,
      textShadow: textShadow ?? this.textShadow,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      display: display ?? this.display,
      overflowX: overflowX ?? this.overflowX,
      overflowY: overflowY ?? this.overflowY,
      position: position ?? this.position,
      float: float ?? this.float,
      clear: clear ?? this.clear,
      zIndex: zIndex ?? this.zIndex,
      direction: direction ?? this.direction,
      transform: transform ?? this.transform,
      opacity: opacity ?? this.opacity,
      transition: transition ?? this.transition,
      animationName: animationName ?? this.animationName,
      animationDuration: animationDuration ?? this.animationDuration,
      animationTimingFunction:
          animationTimingFunction ?? this.animationTimingFunction,
      animationDelay: animationDelay ?? this.animationDelay,
      animationIterationCount:
          animationIterationCount ?? this.animationIterationCount,
      animationDirection: animationDirection ?? this.animationDirection,
      animationFillMode: animationFillMode ?? this.animationFillMode,
      colspan: colspan ?? this.colspan,
      rowspan: rowspan ?? this.rowspan,
      flexDirection: flexDirection ?? this.flexDirection,
      justifyContent: justifyContent ?? this.justifyContent,
      alignItems: alignItems ?? this.alignItems,
      flexWrap: flexWrap ?? this.flexWrap,
      gap: gap ?? this.gap,
      rowGap: rowGap ?? this.rowGap,
      columnGap: columnGap ?? this.columnGap,
      flexGrow: flexGrow ?? this.flexGrow,
      flexShrink: flexShrink ?? this.flexShrink,
      flexBasis: flexBasis ?? this.flexBasis,
      alignSelf: alignSelf ?? this.alignSelf,
    );
    // Copy non-constructor grid fields and custom properties
    result.gridTemplateColumns =
        gridTemplateColumns ?? this.gridTemplateColumns;
    result.gridTemplateRows = gridTemplateRows ?? this.gridTemplateRows;
    result.gridAutoFlow = gridAutoFlow ?? this.gridAutoFlow;
    result.gridColumnStart = gridColumnStart ?? this.gridColumnStart;
    result.gridColumnEnd = gridColumnEnd ?? this.gridColumnEnd;
    result.gridRowStart = gridRowStart ?? this.gridRowStart;
    result.gridRowEnd = gridRowEnd ?? this.gridRowEnd;
    result.gridColumnSpan = gridColumnSpan ?? this.gridColumnSpan;
    result.gridRowSpan = gridRowSpan ?? this.gridRowSpan;
    result.justifyItems = justifyItems ?? this.justifyItems;
    result.alignContent = alignContent ?? this.alignContent;
    result.customProperties =
        customProperties ?? Map<String, String>.from(this.customProperties);
    return result;
  }

  /// Default style matching browser defaults with improved readability.
  ///
  /// Declared as `static final` (not a getter) so it is constructed exactly
  /// once. The resolver compares against this instance 5 times per element;
  /// a getter would silently allocate a fresh object on every comparison,
  /// creating thousands of short-lived ComputedStyle instances for large docs.
  static final ComputedStyle defaultStyle = ComputedStyle(
    lineHeight: 1.5, // Better readability than browser default 1.0
  );
}
