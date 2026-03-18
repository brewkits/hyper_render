import 'package:flutter/material.dart';
import '../model/node.dart';
import '../model/computed_style.dart' hide TextDirection, BorderStyle;

/// Widget that renders a flex container (display: flex)
///
/// Leverages Flutter's Row/Column/Flex/Wrap widgets for the flex algorithm.
/// Similar to how tables use Row/Column for layout.
class FlexContainerWidget extends StatelessWidget {
  final UDTNode node;
  final List<Widget> children;

  const FlexContainerWidget({
    super.key,
    required this.node,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final style = node.style;

    // Determine axis from flex-direction
    final Axis axis = _getAxis(style.flexDirection);
    final bool isReverse = _isReverse(style.flexDirection);

    // Map CSS properties to Flutter properties
    final MainAxisAlignment mainAxisAlignment =
        _mapJustifyContent(style.justifyContent, isReverse);
    final CrossAxisAlignment crossAxisAlignment =
        _mapAlignItems(style.alignItems);
    final WrapAlignment wrapAlignment =
        _mapJustifyContentToWrap(style.justifyContent);
    final WrapCrossAlignment wrapCrossAlignment =
        _mapAlignItemsToWrap(style.alignItems);

    // Handle gap spacing
    final double mainAxisSpacing = (axis == Axis.horizontal
            ? (style.columnGap ?? style.gap ?? 0)
            : (style.rowGap ?? style.gap ?? 0));
    final double crossAxisSpacing = (axis == Axis.horizontal
            ? (style.rowGap ?? style.gap ?? 0)
            : (style.columnGap ?? style.gap ?? 0));

    Widget flexWidget;

    if (style.flexWrap == FlexWrap.nowrap) {
      // Use Row/Column for no-wrap flex
      // Wrap children that are NOT FlexItemWidget to prevent overflow
      final processedChildren = _buildChildrenWithGap(children, mainAxisSpacing, axis)
          .map((child) {
            // FlexItemWidget handles its own Flexible wrapping
            if (child is FlexItemWidget) {
              return child;
            }
            // Wrap other widgets in Flexible to prevent overflow
            return Flexible(fit: FlexFit.loose, child: child);
          }).toList();

      if (axis == Axis.horizontal) {
        flexWidget = Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: MainAxisSize.max,
          textDirection: isReverse ? TextDirection.rtl : TextDirection.ltr,
          children: processedChildren,
        );
      } else {
        flexWidget = Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: MainAxisSize.max,
          verticalDirection:
              isReverse ? VerticalDirection.up : VerticalDirection.down,
          children: processedChildren,
        );
      }
    } else {
      // Use Wrap for wrapping flex
      final bool reverseWrap = style.flexWrap == FlexWrap.wrapReverse;
      flexWidget = Wrap(
        direction: axis,
        alignment: wrapAlignment,
        crossAxisAlignment: wrapCrossAlignment,
        spacing: mainAxisSpacing,
        runSpacing: crossAxisSpacing,
        verticalDirection:
            reverseWrap ? VerticalDirection.up : VerticalDirection.down,
        children: children,
      );
    }

    // Apply container styling (padding, margin, background, border)
    return Container(
      margin: style.margin,
      padding: style.padding,
      width: style.width,
      height: style.height,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        border: style.borderWidth != EdgeInsets.zero
            ? Border(
                top: BorderSide(
                  color: style.borderColor ?? Colors.transparent,
                  width: style.borderWidth.top,
                ),
                right: BorderSide(
                  color: style.borderColor ?? Colors.transparent,
                  width: style.borderWidth.right,
                ),
                bottom: BorderSide(
                  color: style.borderColor ?? Colors.transparent,
                  width: style.borderWidth.bottom,
                ),
                left: BorderSide(
                  color: style.borderColor ?? Colors.transparent,
                  width: style.borderWidth.left,
                ),
              )
            : null,
        borderRadius: style.borderRadius,
      ),
      child: flexWidget,
    );
  }

  Axis _getAxis(FlexDirection direction) {
    switch (direction) {
      case FlexDirection.row:
      case FlexDirection.rowReverse:
        return Axis.horizontal;
      case FlexDirection.column:
      case FlexDirection.columnReverse:
        return Axis.vertical;
    }
  }

  bool _isReverse(FlexDirection direction) {
    return direction == FlexDirection.rowReverse ||
        direction == FlexDirection.columnReverse;
  }

  MainAxisAlignment _mapJustifyContent(
      JustifyContent justify, bool isReverse) {
    // Note: Reverse is handled via textDirection/verticalDirection
    switch (justify) {
      case JustifyContent.flexStart:
        return MainAxisAlignment.start;
      case JustifyContent.flexEnd:
        return MainAxisAlignment.end;
      case JustifyContent.center:
        return MainAxisAlignment.center;
      case JustifyContent.spaceBetween:
        return MainAxisAlignment.spaceBetween;
      case JustifyContent.spaceAround:
        return MainAxisAlignment.spaceAround;
      case JustifyContent.spaceEvenly:
        return MainAxisAlignment.spaceEvenly;
    }
  }

  CrossAxisAlignment _mapAlignItems(AlignItems align) {
    switch (align) {
      case AlignItems.flexStart:
        return CrossAxisAlignment.start;
      case AlignItems.flexEnd:
        return CrossAxisAlignment.end;
      case AlignItems.center:
        return CrossAxisAlignment.center;
      case AlignItems.baseline:
        return CrossAxisAlignment.baseline;
      case AlignItems.stretch:
        return CrossAxisAlignment.stretch;
    }
  }

  WrapAlignment _mapJustifyContentToWrap(JustifyContent justify) {
    switch (justify) {
      case JustifyContent.flexStart:
        return WrapAlignment.start;
      case JustifyContent.flexEnd:
        return WrapAlignment.end;
      case JustifyContent.center:
        return WrapAlignment.center;
      case JustifyContent.spaceBetween:
        return WrapAlignment.spaceBetween;
      case JustifyContent.spaceAround:
        return WrapAlignment.spaceAround;
      case JustifyContent.spaceEvenly:
        return WrapAlignment.spaceEvenly;
    }
  }

  WrapCrossAlignment _mapAlignItemsToWrap(AlignItems align) {
    switch (align) {
      case AlignItems.flexStart:
        return WrapCrossAlignment.start;
      case AlignItems.flexEnd:
        return WrapCrossAlignment.end;
      case AlignItems.center:
        return WrapCrossAlignment.center;
      default:
        return WrapCrossAlignment.start;
    }
  }

  List<Widget> _buildChildrenWithGap(
      List<Widget> children, double gap, Axis axis) {
    if (gap <= 0 || children.isEmpty) return children;

    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(SizedBox(
          width: axis == Axis.horizontal ? gap : 0,
          height: axis == Axis.vertical ? gap : 0,
        ));
      }
    }
    return result;
  }
}

/// Wrapper for flex items with flex properties (flex-grow, flex-shrink)
class FlexItemWidget extends StatelessWidget {
  final Widget child;
  final ComputedStyle style;

  const FlexItemWidget({
    super.key,
    required this.child,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final int flex = (style.flexGrow ?? 0).toInt();
    final bool canShrink = (style.flexShrink ?? 1) > 0;

    // Use Expanded for flex-grow (simpler than Flexible with tight fit)
    if (flex > 0) {
      return Expanded(
        flex: flex,
        child: _wrapWithAlignSelf(child, style.alignSelf),
      );
    }

    // If item is not shrinkable, it's rigid. No need for Flexible.
    if (!canShrink) {
      return _wrapWithAlignSelf(child, style.alignSelf);
    }

    // For shrinkable items that don't grow, use Flexible with loose fit.
    // This allows them to shrink if needed, but not grow.
    return Flexible(
      fit: FlexFit.loose,
      child: _wrapWithAlignSelf(child, style.alignSelf),
    );
  }

  Widget _wrapWithAlignSelf(Widget child, AlignItems? alignSelf) {
    // align-self overrides the container's align-items for a specific item
    // This is tricky in Flutter because CrossAxisAlignment is per-container
    // We can use Align widget to override for a specific child
    if (alignSelf != null) {
      Alignment? alignment;
      switch (alignSelf) {
        case AlignItems.flexStart:
          alignment = Alignment.topLeft;
          break;
        case AlignItems.flexEnd:
          alignment = Alignment.bottomRight;
          break;
        case AlignItems.center:
          alignment = Alignment.center;
          break;
        case AlignItems.baseline:
        case AlignItems.stretch:
          // Baseline and stretch are harder to implement with Align
          // Just return the child as-is for now
          return child;
      }
      return Align(alignment: alignment, child: child);
    }
    return child;
  }
}
