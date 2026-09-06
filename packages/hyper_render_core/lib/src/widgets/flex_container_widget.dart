import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../model/computed_style.dart';
import '../model/node.dart';
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
      // Flutter's `Wrap` provides `WrapParentData`, so an `Expanded`/`Flexible`
      // emitted by [FlexItemWidget] underneath it trips
      // "Incorrect use of ParentDataWidget" and cascades into a broken frame
      // (issue #15).  Two strategies, both of which guarantee that no flex
      // parent data is ever attached to a `Wrap` child:
      //
      //  1. `_buildFlexLines` — a real CSS wrapping-flex layout (line packing +
      //     free-space distribution) emitted as a Column of Rows.  Rows are
      //     `Flex`es, and widths are resolved arithmetically, so no
      //     `Expanded`/`Flexible` is needed at all.
      //  2. `_buildStrippedWrap` — fallback for shapes strategy 1 cannot size at
      //     build time (column wrap, unknown-size items, unbounded width): a
      //     plain `Wrap` whose `FlexItemWidget` children are replaced by
      //     `flex-basis`/`min-width`/`max-width` sizing widgets.
      flexWidget = LayoutBuilder(
        builder: (context, constraints) {
          final lines = _buildFlexLines(
            constraints: constraints,
            axis: axis,
            isReverse: isReverse,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            containerStyle: style,
          );
          if (lines != null) return lines;

          final bool reverseWrap = style.flexWrap == FlexWrap.wrapReverse;
          return Wrap(
            direction: axis,
            alignment: wrapAlignment,
            crossAxisAlignment: wrapCrossAlignment,
            spacing: mainAxisSpacing,
            runSpacing: crossAxisSpacing,
            verticalDirection:
                reverseWrap ? VerticalDirection.up : VerticalDirection.down,
            children: _buildStrippedWrapChildren(axis, constraints),
          );
        },
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

  /// Builds a wrapping flex container as a `Column` of `Row`s, resolving CSS
  /// `flex-basis` / `flex-grow` / `flex-shrink` / `min-width` / `max-width`
  /// arithmetically.
  ///
  /// Returns `null` when the container's shape cannot be resolved at build
  /// time, in which case the caller falls back to a plain (flex-parent-data
  /// free) `Wrap`.  Bailing out covers:
  ///   * `flex-direction: column*` — the cross axis is height, which is
  ///     unbounded here, so lines cannot be packed;
  ///   * `row-reverse` / `wrap-reverse` — ordering is left to `Wrap`;
  ///   * an unbounded/degenerate main-axis extent;
  ///   * a child that is not a [FlexItemWidget], or one whose base size is not
  ///     knowable at build time (no `flex-basis`/`width`/`min-width` and no
  ///     `flex-grow` to size it from free space).
  Widget? _buildFlexLines({
    required BoxConstraints constraints,
    required Axis axis,
    required bool isReverse,
    required double mainAxisSpacing,
    required double crossAxisSpacing,
    required MainAxisAlignment mainAxisAlignment,
    required CrossAxisAlignment crossAxisAlignment,
    required ComputedStyle containerStyle,
  }) {
    if (axis != Axis.horizontal || isReverse) return null;
    if (containerStyle.flexWrap == FlexWrap.wrapReverse) return null;
    if (children.isEmpty) return null;

    final double available = constraints.maxWidth;
    if (!available.isFinite || available <= 0) return null;

    final items = <_ResolvedFlexItem>[];
    for (final child in children) {
      if (child is! FlexItemWidget) return null;
      final ComputedStyle s = child.style;
      final double grow = s.flexGrow ?? 0;
      final double shrink = s.flexShrink ?? 1;
      // CSS `flex-basis: auto` falls back to `width`; an unparsed basis
      // (`0%`, `auto`) resolves to null and is treated as 0 for growable items.
      final double? explicitBase = s.flexBasis ?? s.width ?? s.minWidth;
      if (explicitBase == null && grow <= 0) return null;

      final double minWidth = s.minWidth ?? 0;
      final double maxWidth = s.maxWidth ?? double.infinity;
      double base = explicitBase ?? 0;
      base = base.clamp(minWidth, math.max(minWidth, maxWidth));
      base = base.clamp(0.0, available);

      items.add(_ResolvedFlexItem(
        item: child,
        base: base,
        grow: grow,
        shrink: shrink,
        minWidth: math.min(minWidth, available),
        maxWidth: maxWidth,
      ));
    }

    // Pack items into lines: an item starts a new line when it no longer fits
    // in the remaining main-axis extent (gaps included).
    final lines = <List<_ResolvedFlexItem>>[];
    var current = <_ResolvedFlexItem>[];
    double currentExtent = 0;
    for (final item in items) {
      final double candidate = current.isEmpty
          ? item.base
          : currentExtent + mainAxisSpacing + item.base;
      if (current.isNotEmpty && candidate > available + _epsilon) {
        lines.add(current);
        current = <_ResolvedFlexItem>[];
        currentExtent = 0;
      }
      currentExtent = current.isEmpty
          ? item.base
          : currentExtent + mainAxisSpacing + item.base;
      current.add(item);
    }
    if (current.isNotEmpty) lines.add(current);

    final hasStretch = crossAxisAlignment == CrossAxisAlignment.stretch ||
        items.any((i) => i.item.style.alignSelf == AlignItems.stretch);

    final rows = <Widget>[];
    for (var l = 0; l < lines.length; l++) {
      if (l > 0 && crossAxisSpacing > 0) {
        rows.add(SizedBox(height: crossAxisSpacing));
      }
      rows.add(_buildFlexLine(
        line: lines[l],
        available: available,
        mainAxisSpacing: mainAxisSpacing,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        useIntrinsicHeight: hasStretch,
      ));
    }

    if (rows.length == 1) return rows.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  /// Resolves one flex line's item widths and emits it as a [Row].
  ///
  /// Widths are computed here rather than delegated to `Expanded`/`Flexible`,
  /// because CSS distributes *free space* in proportion to `flex-grow` on top
  /// of each item's base size, whereas `Expanded` divides the whole line.
  Widget _buildFlexLine({
    required List<_ResolvedFlexItem> line,
    required double available,
    required double mainAxisSpacing,
    required MainAxisAlignment mainAxisAlignment,
    required CrossAxisAlignment crossAxisAlignment,
    required bool useIntrinsicHeight,
  }) {
    final double gaps = mainAxisSpacing * (line.length - 1);
    double totalBase = 0;
    for (final i in line) {
      totalBase += i.base;
    }
    final double free = available - gaps - totalBase;

    final widths = <double>[];
    if (free > _epsilon) {
      double totalGrow = 0;
      for (final i in line) {
        totalGrow += i.grow;
      }
      for (final i in line) {
        widths
            .add(totalGrow > 0 ? i.base + free * (i.grow / totalGrow) : i.base);
      }
    } else if (free < -_epsilon) {
      // Defensive only: line packing never emits a line wider than `available`
      // (each base is clamped to it, and an item that would overflow starts a
      // new line), so this branch is currently unreachable. It is kept so a
      // future packing change degrades into CSS shrink rather than overflow.
      double totalScaled = 0;
      for (final i in line) {
        totalScaled += i.shrink * i.base;
      }
      for (final i in line) {
        widths.add(totalScaled > 0
            ? i.base + free * ((i.shrink * i.base) / totalScaled)
            : i.base);
      }
    } else {
      for (final i in line) {
        widths.add(i.base);
      }
    }

    final rowChildren = <Widget>[];
    for (var i = 0; i < line.length; i++) {
      if (i > 0 && mainAxisSpacing > 0) {
        rowChildren.add(SizedBox(width: mainAxisSpacing));
      }
      final resolved = line[i];
      final double width = widths[i]
          .clamp(
              resolved.minWidth, math.max(resolved.minWidth, resolved.maxWidth))
          .clamp(0.0, available)
          .toDouble();
      rowChildren.add(SizedBox(
        width: width,
        child: resolved.item.buildUnflexed(parentAxis: Axis.horizontal),
      ));
    }

    Widget row = Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.max,
      textBaseline: crossAxisAlignment == CrossAxisAlignment.baseline
          ? TextBaseline.alphabetic
          : null,
      children: rowChildren,
    );
    // No Expanded/Flexible is emitted above, so IntrinsicHeight is safe and is
    // what bounds `align-self: stretch`'s SizedBox(height: infinity).
    if (useIntrinsicHeight) row = IntrinsicHeight(child: row);
    return row;
  }

  /// Fallback path: the children a plain `Wrap` may legally receive.
  ///
  /// Every [FlexItemWidget] is replaced by its unflexed child plus explicit
  /// sizing from `flex-basis` / `min-width` / `max-width`, so no `Expanded` or
  /// `Flexible` is ever attached to `WrapParentData` (issue #15).
  List<Widget> _buildStrippedWrapChildren(
      Axis axis, BoxConstraints constraints) {
    return children.map<Widget>((child) {
      if (child is! FlexItemWidget) return child;
      final ComputedStyle s = child.style;
      // `align-self: stretch` builds SizedBox(height: infinity), which needs a
      // bounded cross axis; a Wrap row does not provide one, so drop it here.
      final Widget inner = child.buildUnflexed(
        parentAxis: axis,
        allowStretch: axis != Axis.horizontal,
      );

      if (axis != Axis.horizontal) {
        final basis = s.flexBasis;
        return basis != null ? SizedBox(height: basis, child: inner) : inner;
      }

      final double bound = constraints.maxWidth;
      final double limit =
          bound.isFinite && bound > 0 ? bound : double.infinity;
      final double minWidth = math.min(s.minWidth ?? 0, limit);
      final double maxWidth =
          math.max(minWidth, math.min(s.maxWidth ?? double.infinity, limit));

      final basis = s.flexBasis;
      if (basis != null) {
        return SizedBox(
          width: basis.clamp(minWidth, maxWidth),
          child: inner,
        );
      }
      if (minWidth > 0 || maxWidth.isFinite) {
        return ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
          child: inner,
        );
      }
      return inner;
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

/// Tolerance for main-axis extent comparisons, so that a line whose items sum
/// to exactly the available width does not wrap because of float error.
const double _epsilon = 0.01;

/// One flex item with its CSS sizing inputs resolved to pixels.
class _ResolvedFlexItem {
  final FlexItemWidget item;

  /// Base (pre-growth) main-axis size: `flex-basis`, else `width`, else
  /// `min-width`, else 0 for growable items.
  final double base;
  final double grow;
  final double shrink;
  final double minWidth;
  final double maxWidth;

  const _ResolvedFlexItem({
    required this.item,
    required this.base,
    required this.grow,
    required this.shrink,
    required this.minWidth,
    required this.maxWidth,
  });
}
