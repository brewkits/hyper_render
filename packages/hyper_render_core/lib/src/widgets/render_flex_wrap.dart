import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../model/computed_style.dart';

/// Parent data carrying a wrapping-flex item's CSS box sizing inputs.
class FlexWrapParentData extends ContainerBoxParentData<RenderBox> {
  /// The item's resolved CSS. Null for a child that was not declared as a flex
  /// item (it is then sized `auto`, i.e. from its max-content width).
  ComputedStyle? style;
}

/// Attaches a flex item's [ComputedStyle] to its slot in a [FlexWrapLayout].
///
/// The analogue of [Flexible] for [RenderFlexWrap] — but unlike `Flexible` it
/// carries no `FlexParentData`, so it is safe under any parent that accepts
/// [FlexWrapParentData].
class FlexWrapItem extends ParentDataWidget<FlexWrapParentData> {
  const FlexWrapItem({super.key, required this.style, required super.child});

  final ComputedStyle style;

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData! as FlexWrapParentData;
    if (identical(parentData.style, style)) return;
    parentData.style = style;
    final parent = renderObject.parent;
    if (parent is RenderObject) parent.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => FlexWrapLayout;
}

/// A CSS wrapping-flex container (`display: flex; flex-wrap: wrap`) on a
/// horizontal main axis.
///
/// Exists because neither of Flutter's built-ins can express it:
///   * `Wrap` has no notion of `flex-grow`, and rejects `Expanded`/`Flexible`
///     children outright (`WrapParentData` vs `FlexParentData`);
///   * a `LayoutBuilder`-driven `Column` of `Row`s cannot answer intrinsic or
///     dry-layout queries, so it explodes the moment an ancestor asks for one
///     (`IntrinsicHeight`, which CSS's default `align-items: stretch` puts
///     above every nested flex container).
class FlexWrapLayout extends MultiChildRenderObjectWidget {
  const FlexWrapLayout({
    super.key,
    required super.children,
    required this.spacing,
    required this.runSpacing,
    required this.justifyContent,
    required this.alignItems,
    this.reverseItems = false,
    this.reverseRuns = false,
  });

  /// Main-axis gap between items on a line (`column-gap` / `gap`).
  final double spacing;

  /// Cross-axis gap between lines (`row-gap` / `gap`).
  final double runSpacing;

  final JustifyContent justifyContent;
  final AlignItems alignItems;

  /// `flex-direction: row-reverse`.
  final bool reverseItems;

  /// `flex-wrap: wrap-reverse`.
  final bool reverseRuns;

  @override
  RenderFlexWrap createRenderObject(BuildContext context) => RenderFlexWrap(
        spacing: spacing,
        runSpacing: runSpacing,
        justifyContent: justifyContent,
        alignItems: alignItems,
        reverseItems: reverseItems,
        reverseRuns: reverseRuns,
      );

  @override
  void updateRenderObject(BuildContext context, RenderFlexWrap renderObject) {
    renderObject
      ..spacing = spacing
      ..runSpacing = runSpacing
      ..justifyContent = justifyContent
      ..alignItems = alignItems
      ..reverseItems = reverseItems
      ..reverseRuns = reverseRuns;
  }
}

/// One item with its CSS sizing inputs resolved against a known container width.
class _Item {
  _Item({
    required this.child,
    required this.base,
    required this.min,
    required this.max,
    required this.grow,
    required this.shrink,
    required this.alignSelf,
  });

  final RenderBox child;

  /// Base (pre-growth) main-axis size, already clamped to [min]/[max].
  final double base;
  final double min;
  final double max;
  final double grow;
  final double shrink;
  final AlignItems? alignSelf;

  /// Filled in by `_distribute`.
  double width = 0;
}

/// Renders a wrapping flex line box: packs items into lines by their base size,
/// then distributes each line's free space per `flex-grow` (or removes overflow
/// per `flex-shrink`).
class RenderFlexWrap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FlexWrapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, FlexWrapParentData> {
  RenderFlexWrap({
    double spacing = 0,
    double runSpacing = 0,
    JustifyContent justifyContent = JustifyContent.flexStart,
    AlignItems alignItems = AlignItems.stretch,
    bool reverseItems = false,
    bool reverseRuns = false,
  })  : _spacing = spacing,
        _runSpacing = runSpacing,
        _justifyContent = justifyContent,
        _alignItems = alignItems,
        _reverseItems = reverseItems,
        _reverseRuns = reverseRuns;

  double _spacing;
  double get spacing => _spacing;
  set spacing(double v) {
    if (_spacing == v) return;
    _spacing = v;
    markNeedsLayout();
  }

  double _runSpacing;
  double get runSpacing => _runSpacing;
  set runSpacing(double v) {
    if (_runSpacing == v) return;
    _runSpacing = v;
    markNeedsLayout();
  }

  JustifyContent _justifyContent;
  JustifyContent get justifyContent => _justifyContent;
  set justifyContent(JustifyContent v) {
    if (_justifyContent == v) return;
    _justifyContent = v;
    markNeedsLayout();
  }

  AlignItems _alignItems;
  AlignItems get alignItems => _alignItems;
  set alignItems(AlignItems v) {
    if (_alignItems == v) return;
    _alignItems = v;
    markNeedsLayout();
  }

  bool _reverseItems;
  bool get reverseItems => _reverseItems;
  set reverseItems(bool v) {
    if (_reverseItems == v) return;
    _reverseItems = v;
    markNeedsLayout();
  }

  bool _reverseRuns;
  bool get reverseRuns => _reverseRuns;
  set reverseRuns(bool v) {
    if (_reverseRuns == v) return;
    _reverseRuns = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FlexWrapParentData) {
      child.parentData = FlexWrapParentData();
    }
  }

  // ---------------------------------------------------------------- sizing --

  static double _pct(double? fraction, double available) =>
      (fraction == null || !available.isFinite)
          ? double.nan
          : available * fraction;

  double _minOf(ComputedStyle? s, double available) {
    if (s == null) return 0;
    if (s.minWidth != null) return s.minWidth!;
    final p = _pct(s.minWidthPercent, available);
    return p.isNaN ? 0 : p;
  }

  double _maxOf(ComputedStyle? s, double available) {
    if (s == null) return double.infinity;
    if (s.maxWidth != null) return s.maxWidth!;
    final p = _pct(s.maxWidthPercent, available);
    return p.isNaN ? double.infinity : p;
  }

  /// CSS base size: `flex-basis`, else `width`, else `auto` (max-content).
  double _baseOf(RenderBox child, ComputedStyle? s, double available) {
    if (s != null) {
      if (s.flexBasis != null) return s.flexBasis!;
      final bp = _pct(s.flexBasisPercent, available);
      if (!bp.isNaN) return bp;
      if (s.width != null) return s.width!;
      final wp = _pct(s.widthPercent, available);
      if (!wp.isNaN) return wp;
    }
    return child.getMaxIntrinsicWidth(double.infinity);
  }

  /// Resolves every child's sizing inputs against [available].
  List<_Item> _resolveItems(double available) {
    final items = <_Item>[];
    var child = firstChild;
    while (child != null) {
      final pd = child.parentData! as FlexWrapParentData;
      final s = pd.style;
      final min = math.max(0.0, _minOf(s, available));
      final max = math.max(min, _maxOf(s, available));
      var base = _baseOf(child, s, available).clamp(min, max);
      if (available.isFinite) base = base.clamp(0.0, available);
      items.add(_Item(
        child: child,
        base: base.toDouble(),
        min: available.isFinite ? math.min(min, available) : min,
        max: max,
        grow: s?.flexGrow ?? 0,
        shrink: s?.flexShrink ?? 1,
        alignSelf: s?.alignSelf,
      ));
      child = pd.nextSibling;
    }
    if (_reverseItems) return items.reversed.toList();
    return items;
  }

  /// Packs items into lines that fit within [available].
  List<List<_Item>> _packLines(List<_Item> items, double available) {
    if (items.isEmpty) return const [];
    if (!available.isFinite) return [items];

    final lines = <List<_Item>>[];
    var current = <_Item>[];
    var extent = 0.0;
    for (final item in items) {
      final candidate =
          current.isEmpty ? item.base : extent + _spacing + item.base;
      if (current.isNotEmpty && candidate > available + _epsilon) {
        lines.add(current);
        current = <_Item>[];
        extent = 0;
      }
      extent = current.isEmpty ? item.base : extent + _spacing + item.base;
      current.add(item);
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  /// Resolves each item's final main-axis size on one line, writing [_Item.width].
  void _distribute(List<_Item> line, double available) {
    final gaps = _spacing * (line.length - 1);
    var totalBase = 0.0;
    for (final i in line) {
      totalBase += i.base;
    }

    if (!available.isFinite) {
      for (final i in line) {
        i.width = i.base;
      }
      return;
    }

    final free = available - gaps - totalBase;
    if (free > _epsilon) {
      var totalGrow = 0.0;
      for (final i in line) {
        totalGrow += i.grow;
      }
      for (final i in line) {
        i.width = totalGrow > 0 ? i.base + free * (i.grow / totalGrow) : i.base;
      }
    } else if (free < -_epsilon) {
      // Only reachable when a single item's own minimum overflows the line.
      var totalScaled = 0.0;
      for (final i in line) {
        totalScaled += i.shrink * i.base;
      }
      for (final i in line) {
        i.width = totalScaled > 0
            ? i.base + free * ((i.shrink * i.base) / totalScaled)
            : i.base;
      }
    } else {
      for (final i in line) {
        i.width = i.base;
      }
    }

    for (final i in line) {
      i.width = i.width.clamp(i.min, math.max(i.min, i.max)).toDouble();
      if (i.width < 0) i.width = 0;
    }
  }

  AlignItems _crossAlignFor(_Item item) => item.alignSelf ?? _alignItems;

  /// Leading offset and inter-item gap for `justify-content` on one line.
  ({double leading, double between}) _justify(double free, int count) {
    if (free <= _epsilon || count == 0) {
      return (leading: 0, between: _spacing);
    }
    switch (_justifyContent) {
      case JustifyContent.flexStart:
        return (leading: 0, between: _spacing);
      case JustifyContent.flexEnd:
        return (leading: free, between: _spacing);
      case JustifyContent.center:
        return (leading: free / 2, between: _spacing);
      case JustifyContent.spaceBetween:
        return count < 2
            ? (leading: 0, between: _spacing)
            : (leading: 0, between: _spacing + free / (count - 1));
      case JustifyContent.spaceAround:
        return (leading: free / (2 * count), between: _spacing + free / count);
      case JustifyContent.spaceEvenly:
        return (
          leading: free / (count + 1),
          between: _spacing + free / (count + 1)
        );
    }
  }

  // ---------------------------------------------------------------- layout --

  @override
  void performLayout() {
    final available = constraints.maxWidth;
    final items = _resolveItems(available);
    final lines = _packLines(items, available);

    if (lines.isEmpty) {
      size = constraints.constrain(Size.zero);
      return;
    }

    final lineHeights = <double>[];
    var widest = 0.0;

    for (final line in lines) {
      _distribute(line, available);

      var lineHeight = 0.0;
      var lineWidth = _spacing * (line.length - 1);
      for (final item in line) {
        item.child.layout(
          BoxConstraints(minWidth: item.width, maxWidth: item.width),
          parentUsesSize: true,
        );
        lineHeight = math.max(lineHeight, item.child.size.height);
        lineWidth += item.width;
      }

      // Second pass, only for the items that actually stretch.
      for (final item in line) {
        if (_crossAlignFor(item) != AlignItems.stretch) continue;
        if ((item.child.size.height - lineHeight).abs() < _epsilon) continue;
        item.child.layout(
          BoxConstraints.tightFor(width: item.width, height: lineHeight),
          parentUsesSize: true,
        );
      }

      lineHeights.add(lineHeight);
      widest = math.max(widest, lineWidth);
    }

    var totalHeight = _runSpacing * (lines.length - 1);
    for (final h in lineHeights) {
      totalHeight += h;
    }

    size = constraints.constrain(
      Size(available.isFinite ? available : widest, totalHeight),
    );

    // Position.
    var y = 0.0;
    final order = _reverseRuns
        ? List<int>.generate(lines.length, (i) => lines.length - 1 - i)
        : List<int>.generate(lines.length, (i) => i);
    for (final li in order) {
      final line = lines[li];
      final lineHeight = lineHeights[li];
      final width = available.isFinite ? available : widest;

      var used = _spacing * (line.length - 1);
      for (final item in line) {
        used += item.width;
      }
      final placement = _justify(width - used, line.length);

      var x = placement.leading;
      for (final item in line) {
        final pd = item.child.parentData! as FlexWrapParentData;
        final h = item.child.size.height;
        final double dy;
        switch (_crossAlignFor(item)) {
          case AlignItems.center:
            dy = y + (lineHeight - h) / 2;
          case AlignItems.flexEnd:
            dy = y + (lineHeight - h);
          case AlignItems.stretch:
          case AlignItems.flexStart:
          // `baseline` needs font metrics the box model does not carry here;
          // flex-start is the documented approximation (see CSS matrix).
          case AlignItems.baseline:
            dy = y;
        }
        pd.offset = Offset(x, dy);
        x += item.width + placement.between;
      }
      y += lineHeight + _runSpacing;
    }
  }

  // ------------------------------------------------------------ dry layout --

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final available = constraints.maxWidth;
    final items = _resolveItems(available);
    final lines = _packLines(items, available);
    if (lines.isEmpty) return constraints.constrain(Size.zero);

    var total = _runSpacing * (lines.length - 1);
    var widest = 0.0;
    for (final line in lines) {
      _distribute(line, available);
      var lineHeight = 0.0;
      var lineWidth = _spacing * (line.length - 1);
      for (final item in line) {
        final s = item.child.getDryLayout(
            BoxConstraints(minWidth: item.width, maxWidth: item.width));
        lineHeight = math.max(lineHeight, s.height);
        lineWidth += item.width;
      }
      total += lineHeight;
      widest = math.max(widest, lineWidth);
    }
    return constraints
        .constrain(Size(available.isFinite ? available : widest, total));
  }

  // ------------------------------------------------------------- intrinsics --

  @override
  double computeMaxIntrinsicWidth(double height) {
    // Max-content: everything on one line at its base size.
    final items = _resolveItems(double.infinity);
    if (items.isEmpty) return 0;
    var total = _spacing * (items.length - 1);
    for (final i in items) {
      total += i.base;
    }
    return total;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    // Min-content: the widest single item, since every item may take its own line.
    var widest = 0.0;
    var child = firstChild;
    while (child != null) {
      final pd = child.parentData! as FlexWrapParentData;
      final s = pd.style;
      final declared = s?.flexBasis ?? s?.width ?? s?.minWidth;
      widest = math.max(
        widest,
        declared ?? child.getMinIntrinsicWidth(double.infinity),
      );
      child = pd.nextSibling;
    }
    return widest;
  }

  double _intrinsicHeightAt(double width) {
    final items = _resolveItems(width);
    final lines = _packLines(items, width);
    if (lines.isEmpty) return 0;
    var total = _runSpacing * (lines.length - 1);
    for (final line in lines) {
      _distribute(line, width);
      var lineHeight = 0.0;
      for (final item in line) {
        lineHeight =
            math.max(lineHeight, item.child.getMaxIntrinsicHeight(item.width));
      }
      total += lineHeight;
    }
    return total;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _intrinsicHeightAt(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _intrinsicHeightAt(width);

  // ------------------------------------------------------------ paint / hit --

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// Tolerance for main-axis extent comparisons, so a line whose items sum to
/// exactly the available width does not wrap because of float error.
const double _epsilon = 0.01;
