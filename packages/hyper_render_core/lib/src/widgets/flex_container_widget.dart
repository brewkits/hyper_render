import 'package:flutter/material.dart';

import '../model/computed_style.dart';
import '../model/node.dart';

/// Widget that renders a flex container (display: flex)
///
/// Leverages Flutter's Row/Column/Flex/Wrap widgets for the flex algorithm.
/// Similar to how tables use Row/Column for layout.
class FlexContainerWidget extends StatelessWidget {
  final UDTNode node;
  final List<Widget> children;
  final bool selectable;

  const FlexContainerWidget({
    super.key,
    required this.node,
    required this.children,
    this.selectable = false,
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
      final gappedChildren =
          _buildChildrenWithGap(children, mainAxisSpacing, axis);

      // Re-wrap any FlexItemWidget with the correct parentAxis so that
      // align-self can compute axis-relative Alignment and stretch dimensions.
      final axisAwareChildren = gappedChildren.map((child) {
        if (child is FlexItemWidget && child.parentAxis != axis) {
          return FlexItemWidget(
            style: child.style,
            parentAxis: axis,
            child: child.child,
          );
        }
        return child;
      }).toList();

      if (axis == Axis.horizontal) {
        // Wrap horizontal children in Flexible to prevent overflow.
        final processedChildren = axisAwareChildren.map((child) {
          if (child is FlexItemWidget) return child;
          return Flexible(fit: FlexFit.loose, child: child);
        }).toList();

        // IntrinsicHeight is incompatible with Expanded children (FlexItemWidget
        // with flexGrow > 0 builds Expanded). If any child has flex growth,
        // skip IntrinsicHeight to avoid the Flutter assertion error:
        // "RenderFlex children have non-zero flex but incoming height constraints
        // are unbounded."
        final hasFlexGrow = axisAwareChildren
            .any((c) => c is FlexItemWidget && (c.style.flexGrow ?? 0) > 0);

        final effectiveCrossAxis = (crossAxisAlignment ==
                    CrossAxisAlignment.stretch &&
                hasFlexGrow)
            ? CrossAxisAlignment.start
            : crossAxisAlignment;

        // Also need IntrinsicHeight when any child uses align-self:stretch,
        // so that SizedBox(height:infinity) in _wrapWithAlignSelf is bounded.
        final hasAlignSelfStretch = axisAwareChildren.any((c) =>
            c is FlexItemWidget && c.style.alignSelf == AlignItems.stretch);

        Widget row = Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: effectiveCrossAxis,
          mainAxisSize: MainAxisSize.max,
          textDirection: isReverse ? TextDirection.rtl : TextDirection.ltr,
          children: processedChildren,
        );
        // CSS align-items:stretch or any child's align-self:stretch needs bounded
        // height.  Wrap with IntrinsicHeight so the cross-axis is finite.
        // Only safe when no Expanded children exist (already excluded above for
        // align-items:stretch; align-self:stretch children use SizedBox not Expanded).
        if (effectiveCrossAxis == CrossAxisAlignment.stretch ||
            (hasAlignSelfStretch && !hasFlexGrow)) {
          row = IntrinsicHeight(child: row);
        }
        flexWidget = row;
      } else {
        // For vertical flex (column), avoid Flexible children when height may be
        // unbounded (e.g. inside a grid cell or scroll view). Flexible with
        // non-zero flex inside an unbounded-height Column throws a Flutter error.
        // Use MainAxisSize.min unless an explicit height is set.
        final hasExplicitHeight = style.height != null;
        flexWidget = Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: hasExplicitHeight ? MainAxisSize.max : MainAxisSize.min,
          verticalDirection:
              isReverse ? VerticalDirection.up : VerticalDirection.down,
          children: axisAwareChildren.map((child) {
            if (child is FlexItemWidget) {
              // FlexItemWidget with flex-grow > 0 produces Expanded(flex: N).
              // Expanded inside a Column with unbounded height throws:
              // "RenderFlex children have non-zero flex but incoming height
              // constraints are unbounded." Fall back to natural sizing.
              if (!hasExplicitHeight) return child.child;
              return child;
            }
            // Only use Flexible for columns with a known height — otherwise
            // Flexible(flex>0) + unbounded height = assertion error.
            if (hasExplicitHeight) {
              return Flexible(fit: FlexFit.loose, child: child);
            }
            return child;
          }).toList(),
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
    final container = Container(
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
    if (selectable) return SelectionArea(child: container);
    return container;
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

  MainAxisAlignment _mapJustifyContent(JustifyContent justify, bool isReverse) {
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

  /// The main axis of the parent flex container.
  ///
  /// Required for `align-self` to apply the correct cross-axis alignment:
  /// - In a [Row] (horizontal), the cross-axis is vertical → stretch changes height.
  /// - In a [Column] (vertical), the cross-axis is horizontal → stretch changes width.
  final Axis parentAxis;

  const FlexItemWidget({
    super.key,
    required this.child,
    required this.style,
    this.parentAxis = Axis.horizontal,
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
    // align-self overrides the container's align-items for a specific item.
    // CrossAxisAlignment is per-container in Flutter, so we use Align/SizedBox
    // per-child as an approximation.
    //
    // Alignment is axis-relative:
    //   Row  (horizontal, cross = vertical):   start=top,   end=bottom
    //   Column (vertical,   cross = horizontal): start=left,  end=right
    if (alignSelf == null) return child;

    switch (alignSelf) {
      case AlignItems.flexStart:
        final alignment = parentAxis == Axis.horizontal
            ? Alignment.topCenter    // row: align to top
            : Alignment.centerLeft;  // column: align to left
        return Align(alignment: alignment, child: child);

      case AlignItems.flexEnd:
        final alignment = parentAxis == Axis.horizontal
            ? Alignment.bottomCenter  // row: align to bottom
            : Alignment.centerRight;  // column: align to right
        return Align(alignment: alignment, child: child);

      case AlignItems.center:
        return Align(alignment: Alignment.center, child: child);

      case AlignItems.stretch:
        // Fill the cross-axis dimension.
        //
        // For Row (horizontal): stretch height.
        //   FlexContainerWidget wraps the Row with IntrinsicHeight when any
        //   child has align-self:stretch, so maxHeight is always bounded here.
        //   SizedBox(height: infinity) is then safely clamped to that bound.
        //
        // For Column (vertical): stretch width.
        //   Column children always receive a bounded maxWidth (screen width),
        //   so SizedBox(width: infinity) is safe without an explicit guard.
        if (parentAxis == Axis.horizontal) {
          return SizedBox(height: double.infinity, child: child);
        } else {
          return SizedBox(width: double.infinity, child: child);
        }

      case AlignItems.baseline:
        // Baseline alignment requires TextBaseline knowledge at layout time.
        // Approximating as flex-start is safer than being a no-op for stretch.
        final alignment = parentAxis == Axis.horizontal
            ? Alignment.topCenter
            : Alignment.centerLeft;
        return Align(alignment: alignment, child: child);
    }
  }
}
