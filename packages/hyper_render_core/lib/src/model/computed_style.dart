import 'package:flutter/material.dart';

/// Display type for CSS display property
enum DisplayType {
  block,
  inline,
  inlineBlock,
  flex,
  grid,
  table,
  tableRow,
  tableCell,
  none,
}

/// Flex direction property
enum FlexDirection {
  row,
  column,
  rowReverse,
  columnReverse,
}

/// Flex wrap property
enum FlexWrap {
  nowrap,
  wrap,
  wrapReverse,
}

/// Justify content property
enum JustifyContent {
  flexStart,
  flexEnd,
  center,
  spaceBetween,
  spaceAround,
  spaceEvenly,
}

/// Align items property
enum AlignItems {
  flexStart,
  flexEnd,
  center,
  baseline,
  stretch,
}

/// Align content property
enum AlignContent {
  flexStart,
  flexEnd,
  center,
  spaceBetween,
  spaceAround,
  stretch,
}

/// Align self property
enum AlignSelf {
  auto,
  flexStart,
  flexEnd,
  center,
  baseline,
  stretch,
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
  none,
  left,
  right,
}

/// Clear behavior for CSS clear property
enum HyperClear {
  none,
  left,
  right,
  both,
}

/// CSS timing function
enum HyperTimingFunction {
  linear,
  ease,
  easeIn,
  easeOut,
  easeInOut,
}

/// CSS animation direction
enum HyperAnimationDirection {
  normal,
  reverse,
  alternate,
  alternateReverse,
}

/// CSS animation fill mode
enum HyperAnimationFillMode {
  none,
  forwards,
  backwards,
  both,
}

/// CSS list-style-type values
enum ListStyleType {
  decimal,
  lowerRoman,
  upperRoman,
  lowerAlpha,
  upperAlpha,
  disc,
  circle,
  square,
  none,
}

/// CSS transition definition
class HyperTransition {
  final String? property;
  final int duration;
  final HyperTimingFunction timingFunction;
  final int delay;

  const HyperTransition({
    this.property,
    this.duration = 0,
    this.timingFunction = HyperTimingFunction.ease,
    this.delay = 0,
  });

  bool get isDefined => duration > 0;
}

/// The resolved CSS style for a single node in the Unified Document Tree.
///
/// `ComputedStyle` is produced by the style resolver after applying the CSS
/// cascade (UA defaults → author rules → inline styles → inheritance). It
/// covers the full CSS2/CSS3 box model, typography, flexbox, grid, animation,
/// and transform properties.
///
/// **Inheritance** — call [inheritFrom] to copy inheritable text properties
/// (color, fontSize, fontFamily, etc.) from a parent node's style.
///
/// **Serialisation** — call [toTextStyle] to obtain a Flutter [TextStyle]
/// suitable for painting text fragments.
///
/// **Immutable snapshots** — call [copyWith] to produce a new `ComputedStyle`
/// with selected fields overridden while preserving all others.
///
/// ```dart
/// final style = ComputedStyle(
///   fontSize: 18,
///   fontWeight: FontWeight.bold,
///   color: Colors.black87,
/// );
///
/// final larger = style.copyWith(fontSize: 24);
/// ```
class ComputedStyle {
  final Set<String> _explicitlySet = {};

  bool isExplicitlySet(String property) => _explicitlySet.contains(property);
  void markExplicitlySet(String property) => _explicitlySet.add(property);
  void markAllExplicitlySet(Iterable<String> properties) => _explicitlySet.addAll(properties);

  // Box Model
  double? width;
  double? height;
  double? minWidth;
  double? maxWidth;
  double? minHeight;
  double? maxHeight;
  EdgeInsets margin;
  EdgeInsets padding;
  EdgeInsets borderWidth;
  Color? borderColor;
  BorderRadius? borderRadius;

  // Text
  Color color;
  double fontSize;
  FontWeight fontWeight;
  FontStyle fontStyle;
  String? fontFamily;
  TextDecoration? textDecoration;
  Color? textDecorationColor;
  double? lineHeight;
  double? letterSpacing;
  double? wordSpacing;
  HyperTextAlign textAlign;
  HyperVerticalAlign verticalAlign;
  String? textTransform;
  String? whiteSpace;
  TextOverflow? textOverflow;
  ListStyleType? listStyleType;

  // Background
  Color? backgroundColor;
  String? backgroundImage;

  // Layout
  DisplayType display;
  Map<String, String> customProperties = {};
  HyperOverflow overflowX;
  HyperOverflow overflowY;
  String position;
  HyperFloat float;
  HyperClear clear;
  int? zIndex;

  // Flexbox Properties
  FlexDirection flexDirection;
  FlexWrap flexWrap;
  JustifyContent justifyContent;
  AlignItems alignItems;
  AlignContent alignContent;
  AlignSelf alignSelf;
  double flexGrow;
  double flexShrink;
  double? flexBasis;
  double? gap;
  int order;

  // Transform
  Matrix4? transform;
  double opacity;

  // Animation
  HyperTransition? transition;
  String? animationName;
  int? animationDuration;
  HyperTimingFunction animationTimingFunction;
  int? animationDelay;
  int? animationIterationCount;
  HyperAnimationDirection animationDirection;
  HyperAnimationFillMode animationFillMode;

  // Grid
  String? gridTemplateColumns;
  String? gridTemplateRows;
  String? gridAutoFlow;
  int gridColumnStart = 0;
  int gridColumnEnd = 0;
  int gridRowStart = 0;
  int gridRowEnd = 0;
  int gridColumnSpan = 1;
  int gridRowSpan = 1;

  // Table
  int colspan;
  int rowspan;

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
    this.fontSize = 14.0,
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
    this.listStyleType,
    this.backgroundColor,
    this.backgroundImage,
    this.display = DisplayType.inline,
    this.overflowX = HyperOverflow.visible,
    this.overflowY = HyperOverflow.visible,
    this.position = 'static',
    this.float = HyperFloat.none,
    this.clear = HyperClear.none,
    this.zIndex,
    this.flexDirection = FlexDirection.row,
    this.flexWrap = FlexWrap.nowrap,
    this.justifyContent = JustifyContent.flexStart,
    this.alignItems = AlignItems.stretch,
    this.alignContent = AlignContent.stretch,
    this.alignSelf = AlignSelf.auto,
    this.flexGrow = 0.0,
    this.flexShrink = 1.0,
    this.flexBasis,
    this.gap,
    this.order = 0,
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

  void inheritFrom(ComputedStyle parent) {
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
  }

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
    ListStyleType? listStyleType,
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
    // Flexbox
    FlexDirection? flexDirection,
    FlexWrap? flexWrap,
    JustifyContent? justifyContent,
    AlignItems? alignItems,
    AlignContent? alignContent,
    AlignSelf? alignSelf,
    double? flexGrow,
    double? flexShrink,
    double? flexBasis,
    double? gap,
    int? order,
    // Transform / opacity
    Matrix4? transform,
    double? opacity,
    // Transition / animation
    HyperTransition? transition,
    String? animationName,
    int? animationDuration,
    HyperTimingFunction? animationTimingFunction,
    int? animationDelay,
    int? animationIterationCount,
    HyperAnimationDirection? animationDirection,
    HyperAnimationFillMode? animationFillMode,
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
    // Table
    int? colspan,
    int? rowspan,
    // Custom properties (merged with existing, not replaced)
    Map<String, String>? customProperties,
  }) {
    final style = ComputedStyle(
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
      listStyleType: listStyleType ?? this.listStyleType,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      display: display ?? this.display,
      overflowX: overflowX ?? this.overflowX,
      overflowY: overflowY ?? this.overflowY,
      position: position ?? this.position,
      float: float ?? this.float,
      clear: clear ?? this.clear,
      zIndex: zIndex ?? this.zIndex,
      flexDirection: flexDirection ?? this.flexDirection,
      flexWrap: flexWrap ?? this.flexWrap,
      justifyContent: justifyContent ?? this.justifyContent,
      alignItems: alignItems ?? this.alignItems,
      alignContent: alignContent ?? this.alignContent,
      alignSelf: alignSelf ?? this.alignSelf,
      flexGrow: flexGrow ?? this.flexGrow,
      flexShrink: flexShrink ?? this.flexShrink,
      flexBasis: flexBasis ?? this.flexBasis,
      gap: gap ?? this.gap,
      order: order ?? this.order,
      transform: transform ?? this.transform,
      opacity: opacity ?? this.opacity,
      transition: transition ?? this.transition,
      animationName: animationName ?? this.animationName,
      animationDuration: animationDuration ?? this.animationDuration,
      animationTimingFunction: animationTimingFunction ?? this.animationTimingFunction,
      animationDelay: animationDelay ?? this.animationDelay,
      animationIterationCount: animationIterationCount ?? this.animationIterationCount,
      animationDirection: animationDirection ?? this.animationDirection,
      animationFillMode: animationFillMode ?? this.animationFillMode,
      colspan: colspan ?? this.colspan,
      rowspan: rowspan ?? this.rowspan,
    );
    // Grid fields are not constructor params — set post-construction
    style.gridTemplateColumns = gridTemplateColumns ?? this.gridTemplateColumns;
    style.gridTemplateRows = gridTemplateRows ?? this.gridTemplateRows;
    style.gridAutoFlow = gridAutoFlow ?? this.gridAutoFlow;
    style.gridColumnStart = gridColumnStart ?? this.gridColumnStart;
    style.gridColumnEnd = gridColumnEnd ?? this.gridColumnEnd;
    style.gridRowStart = gridRowStart ?? this.gridRowStart;
    style.gridRowEnd = gridRowEnd ?? this.gridRowEnd;
    style.gridColumnSpan = gridColumnSpan ?? this.gridColumnSpan;
    style.gridRowSpan = gridRowSpan ?? this.gridRowSpan;
    // Merge custom properties: caller's values override existing
    style.customProperties = customProperties != null
        ? {...this.customProperties, ...customProperties}
        : Map.of(this.customProperties);
    style._explicitlySet.addAll(_explicitlySet);
    return style;
  }

  static final ComputedStyle defaultStyle = ComputedStyle(
    fontSize: 14.0,
    lineHeight: 1.7,
  );
}
