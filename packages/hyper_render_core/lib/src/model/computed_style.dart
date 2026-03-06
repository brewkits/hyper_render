import 'package:flutter/material.dart';

import '../exceptions/hyper_render_exceptions.dart';

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
  final String property;
  final Duration duration;
  final HyperTimingFunction timingFunction;
  final Duration delay;

  const HyperTransition({
    required this.property,
    required this.duration,
    this.timingFunction = HyperTimingFunction.ease,
    this.delay = Duration.zero,
  });
}

/// Computed style for a UDT node
///
/// Contains resolved style properties after CSS cascade and inheritance.
/// Optimized for fast access during layout and painting.
///
/// Reference: doc1.txt - "Style System"
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
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    this.textDecoration,
    this.textDecorationColor,
    this.fontFamily,
    this.lineHeight,
    this.letterSpacing,
    this.wordSpacing,
    HyperTextAlign? textAlign,
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
    this.gridTemplateColumns,
    this.gridTemplateRows,
    this.gridAutoFlow,
    this.gridColumnStart = 0,
    this.gridColumnEnd = 0,
    this.gridRowStart = 0,
    this.gridRowEnd = 0,
    this.gridColumnSpan = 1,
    this.gridRowSpan = 1,
    this.colspan = 1,
    this.rowspan = 1,
  })  : color = color ?? const Color(0xFF000000),
        fontSize = fontSize ?? 14.0,
        fontWeight = fontWeight ?? FontWeight.normal,
        fontStyle = fontStyle ?? FontStyle.normal,
        textAlign = textAlign ?? HyperTextAlign.left {
    if (color != null) markExplicitlySet('color');
    if (fontSize != null) markExplicitlySet('font-size');
    if (fontWeight != null) markExplicitlySet('font-weight');
    if (fontStyle != null) markExplicitlySet('font-style');
    if (textAlign != null) markExplicitlySet('text-align');
    if (textDecoration != null) markExplicitlySet('text-decoration');

    if (this.fontSize < 0) {
      throw ArgumentError.value(this.fontSize, 'fontSize', 'fontSize cannot be negative');
    }
    if (width != null && width! < 0) {
      throw ArgumentError.value(width, 'width', 'width cannot be negative');
    }
    if (height != null && height! < 0) {
      throw ArgumentError.value(height, 'height', 'height cannot be negative');
    }
    if (minWidth != null && minWidth! < 0) {
      throw ArgumentError.value(minWidth, 'minWidth', 'minWidth cannot be negative');
    }
    if (maxWidth != null && maxWidth! < 0) {
      throw ArgumentError.value(maxWidth, 'maxWidth', 'maxWidth cannot be negative');
    }
    if (minHeight != null && minHeight! < 0) {
      throw ArgumentError.value(minHeight, 'minHeight', 'minHeight cannot be negative');
    }
    if (maxHeight != null && maxHeight! < 0) {
      throw ArgumentError.value(maxHeight, 'maxHeight', 'maxHeight cannot be negative');
    }
    if (opacity < 0.0 || opacity > 1.0) {
      throw ArgumentError.value(opacity, 'opacity', 'opacity must be between 0.0 and 1.0');
    }
  }

  void inheritFrom(ComputedStyle parent) {
    if (!isExplicitlySet('color')) color = parent.color;
    if (!isExplicitlySet('font-size')) fontSize = parent.fontSize;
    if (!isExplicitlySet('font-weight')) fontWeight = parent.fontWeight;
    if (!isExplicitlySet('font-style')) fontStyle = parent.fontStyle;
    if (!isExplicitlySet('font-family')) fontFamily ??= parent.fontFamily;
    if (!isExplicitlySet('line-height')) lineHeight ??= parent.lineHeight;
    if (!isExplicitlySet('letter-spacing')) letterSpacing ??= parent.letterSpacing;
    if (!isExplicitlySet('word-spacing')) wordSpacing ??= parent.wordSpacing;
    if (!isExplicitlySet('text-align')) textAlign = parent.textAlign;
    if (!isExplicitlySet('white-space')) whiteSpace ??= parent.whiteSpace;
    if (!isExplicitlySet('list-style-type')) listStyleType ??= parent.listStyleType;
    if (!isExplicitlySet('text-decoration')) textDecoration ??= parent.textDecoration;
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
    // Transform/Animation
    Matrix4? transform,
    double? opacity,
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
      gridTemplateColumns: gridTemplateColumns ?? this.gridTemplateColumns,
      gridTemplateRows: gridTemplateRows ?? this.gridTemplateRows,
      gridAutoFlow: gridAutoFlow ?? this.gridAutoFlow,
      gridColumnStart: gridColumnStart ?? this.gridColumnStart,
      gridColumnEnd: gridColumnEnd ?? this.gridColumnEnd,
      gridRowStart: gridRowStart ?? this.gridRowStart,
      gridRowEnd: gridRowEnd ?? this.gridRowEnd,
      gridColumnSpan: gridColumnSpan ?? this.gridColumnSpan,
      gridRowSpan: gridRowSpan ?? this.gridRowSpan,
      colspan: colspan ?? this.colspan,
      rowspan: rowspan ?? this.rowspan,
    );

    // Copy explicit flags
    result.markAllExplicitlySet(_explicitlySet);
    if (width != null) result.markExplicitlySet('width');
    if (height != null) result.markExplicitlySet('height');
    if (color != null) result.markExplicitlySet('color');
    if (fontSize != null) result.markExplicitlySet('font-size');
    if (fontWeight != null) result.markExplicitlySet('font-weight');
    if (fontStyle != null) result.markExplicitlySet('font-style');
    if (textAlign != null) result.markExplicitlySet('text-align');
    if (lineHeight != null) result.markExplicitlySet('line-height');
    if (letterSpacing != null) result.markExplicitlySet('letter-spacing');
    if (wordSpacing != null) result.markExplicitlySet('word-spacing');
    if (whiteSpace != null) result.markExplicitlySet('white-space');
    if (textDecoration != null) result.markExplicitlySet('text-decoration');

    return result;
  }

  static final ComputedStyle defaultStyle = ComputedStyle();
}
