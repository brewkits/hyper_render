import 'package:flutter/material.dart';

import '../model/computed_style.dart';
import '../model/node.dart';
import 'render_flex_wrap.dart';
import 'css_border.dart';

/// Widget that renders a flex container (display: flex)
///
/// Uses Flutter's Row/Column/Flex/Wrap widgets for the flex algorithm.
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

        final effectiveCrossAxis =
            (crossAxisAlignment == CrossAxisAlignment.stretch && hasFlexGrow)
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
          // Row asserts when crossAxisAlignment is baseline and textBaseline is
          // null. CSS `align-items: baseline` maps to the alphabetic baseline.
          textBaseline: effectiveCrossAxis == CrossAxisAlignment.baseline
              ? TextBaseline.alphabetic
              : null,
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
          textBaseline: crossAxisAlignment == CrossAxisAlignment.baseline
              ? TextBaseline.alphabetic
              : null,
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
      // Wrapping flex (`flex-wrap: wrap` / `wrap-reverse`).
      //
      // Horizontal wrap goes to [FlexWrapLayout], a real render object. Neither
      // Flutter built-in can express CSS here: `Wrap` has no `flex-grow` and
      // rejects `Expanded`/`Flexible` children (`WrapParentData` vs
      // `FlexParentData`, issue #15), while a `LayoutBuilder`-driven Column of
      // Rows cannot answer intrinsic or dry-layout queries — and CSS's default
      // `align-items: stretch` puts an `IntrinsicHeight` above every nested
      // flex container, so that shape crashed on contact.
      //
      // Vertical wrap keeps `Wrap`: packing lines along an unbounded cross axis
      // (width) is well defined, but the main axis (height) is not.
      if (axis == Axis.horizontal) {
        flexWidget = FlexWrapLayout(
          spacing: mainAxisSpacing,
          runSpacing: crossAxisSpacing,
          justifyContent: style.justifyContent,
          alignItems: style.alignItems,
          reverseItems: isReverse,
          reverseRuns: style.flexWrap == FlexWrap.wrapReverse,
          children: _asFlexWrapItems(),
        );
      } else {
        final bool reverseWrap = style.flexWrap == FlexWrap.wrapReverse;
        flexWidget = Wrap(
          direction: axis,
          alignment: wrapAlignment,
          crossAxisAlignment: wrapCrossAlignment,
          spacing: mainAxisSpacing,
          runSpacing: crossAxisSpacing,
          verticalDirection:
              reverseWrap ? VerticalDirection.up : VerticalDirection.down,
          children: _buildVerticalWrapChildren(),
        );
      }
    }

    // Apply container styling (padding, margin, background, border)
    final container = Container(
      margin: style.margin,
      padding: style.padding,
      width: style.width,
      height: style.height,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        border: style.borderWidth != EdgeInsets.zero &&
                style.borderStyle != HyperBorderStyle.none
            ? cssBorderFromStyle(style)
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

  /// Wraps each child in a [FlexWrapItem] so [RenderFlexWrap] can read its CSS.
  ///
  /// A child that never went through [FlexItemWidget] (no `flex-*` and no
  /// `align-self`) still carries `min-width` / `max-width` / `width` that CSS
  /// says must be honoured, so it is given its own style rather than dropped
  /// through as an opaque box.
  List<Widget> _asFlexWrapItems() {
    final nodeChildren = node.children;
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      if (child is FlexItemWidget) {
        // Unflexed: RenderFlexWrap owns sizing, and `align-self` is applied by
        // the render object's cross-axis placement rather than by an Align box.
        items.add(FlexWrapItem(
          style: child.style,
          child: child.child,
        ));
        continue;
      }
      // Fall back to the source node's style when the widget carries none.
      final style =
          i < nodeChildren.length ? nodeChildren[i].style : ComputedStyle();
      items.add(FlexWrapItem(style: style, child: child));
    }
    return items;
  }

  /// Children a vertical `Wrap` may legally receive.
  ///
  /// Strips the `Expanded`/`Flexible` that [FlexItemWidget] would emit — `Wrap`
  /// provides `WrapParentData` and asserts on flex parent data (issue #15) —
  /// and replaces it with explicit `flex-basis` sizing on the main (vertical)
  /// axis.
  List<Widget> _buildVerticalWrapChildren() {
    return children.map<Widget>((child) {
      if (child is! FlexItemWidget) return child;
      final inner = child.buildUnflexed(parentAxis: Axis.vertical);
      final basis = child.style.flexBasis;
      return basis != null ? SizedBox(height: basis, child: inner) : inner;
    }).toList();
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

  /// Builds this item's child with `align-self` applied but **without** any
  /// `Expanded`/`Flexible` wrapper.
  ///
  /// Used by containers that cannot accept flex parent data — notably `Wrap`,
  /// which provides `WrapParentData` and asserts when handed `FlexParentData`
  /// (issue #15) — and by the arithmetic wrapping-flex layout, which sizes
  /// items itself.
  ///
  /// Set [allowStretch] to false when the cross axis is unbounded, so that
  /// `align-self: stretch` does not emit an infinite-height box.
  Widget buildUnflexed({
    required Axis parentAxis,
    bool allowStretch = true,
  }) {
    var effective = style.alignSelf;
    if (!allowStretch && effective == AlignItems.stretch) effective = null;
    return _alignSelf(child, effective, parentAxis);
  }

  Widget _wrapWithAlignSelf(Widget child, AlignItems? alignSelf) =>
      _alignSelf(child, alignSelf, parentAxis);

  static Widget _alignSelf(
      Widget child, AlignItems? alignSelf, Axis parentAxis) {
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
            ? Alignment.topCenter // row: align to top
            : Alignment.centerLeft; // column: align to left
        return Align(alignment: alignment, child: child);

      case AlignItems.flexEnd:
        final alignment = parentAxis == Axis.horizontal
            ? Alignment.bottomCenter // row: align to bottom
            : Alignment.centerRight; // column: align to right
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
