import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../model/node.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PUBLIC API
// ═══════════════════════════════════════════════════════════════════════════════

/// Strategy for tables wider than the available viewport.
enum TableStrategy {
  /// Constrain to available width (content may wrap aggressively).
  fitWidth,

  /// Scale the table down with FittedBox.scaleDown.
  autoScale,

  /// Wrap in a horizontal SingleChildScrollView.
  horizontalScroll,
}

/// Wraps [HyperTable] with a strategy for handling wide tables.
///
/// All three strategies avoid [LayoutBuilder] entirely.  [LayoutBuilder]
/// blocks intrinsic-dimension queries that outer [IntrinsicHeight] widgets
/// (used in parent table rows) propagate down the tree.  Instead the
/// strategy is resolved statically at build time.
class SmartTableWrapper extends StatelessWidget {
  final TableNode tableNode;
  final TableStrategy strategy;

  /// No longer used for auto-switching logic (kept for API compat).
  final double minScaleFactor;

  /// No longer used for auto-switching logic (kept for API compat).
  final double minColumnWidth;

  final TextStyle? baseStyle;
  final void Function(String url)? onLinkTap;
  final bool selectable;
  final Widget Function(TableCellNode)? cellContentBuilder;

  const SmartTableWrapper({
    super.key,
    required this.tableNode,
    this.strategy = TableStrategy.horizontalScroll,
    this.minScaleFactor = 0.6,
    this.minColumnWidth = 60.0,
    this.baseStyle,
    this.onLinkTap,
    this.selectable = true,
    this.cellContentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final table = HyperTable(
      tableNode: tableNode,
      baseStyle: baseStyle,
      onLinkTap: onLinkTap,
      selectable: selectable,
      cellContentBuilder: cellContentBuilder,
    );

    switch (strategy) {
      case TableStrategy.horizontalScroll:
        // _RenderHyperTable handles double.infinity width correctly — no
        // IntrinsicWidth wrapper needed (no Expanded children that could crash).
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: table,
        );

      case TableStrategy.fitWidth:
        // Parent constraints propagate directly into _RenderHyperTable.
        return table;

      case TableStrategy.autoScale:
        // FittedBox gives the child unconstrained width.  _RenderHyperTable
        // detects double.infinity and uses natural (max-intrinsic) column
        // widths.  FittedBox then scales the result down if needed.
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: table,
        );
    }
  }
}

/// Custom HTML table widget.
///
/// Renders a [TableNode] using [_RenderHyperTable] — a custom [RenderBox]
/// that performs W3C-inspired table layout without [IntrinsicHeight] or
/// [LayoutBuilder].  This makes it compatible with nested tables (where an
/// outer [IntrinsicHeight] must query intrinsic dimensions of this widget).
class HyperTable extends StatelessWidget {
  final TableNode tableNode;
  final TextStyle? baseStyle;
  final void Function(String url)? onLinkTap;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets cellPadding;
  final bool selectable;
  final Widget Function(TableCellNode)? cellContentBuilder;

  const HyperTable({
    super.key,
    required this.tableNode,
    this.baseStyle,
    this.onLinkTap,
    this.borderColor = const Color(0xFFE0E0E0),
    this.borderWidth = 1.0,
    this.cellPadding = const EdgeInsets.all(8.0),
    this.selectable = true,
    this.cellContentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final grid = _TableGrid.fromTableNode(tableNode);
    if (grid.isEmpty) return const SizedBox.shrink();

    // Only primary cells become children of _HyperTableWidget.
    // Non-primary cells (covered by colspan/rowspan) are tracked entirely
    // inside _RenderHyperTable using the grid metadata.
    final children = <Widget>[];
    for (int row = 0; row < grid.rowCount; row++) {
      for (int col = 0; col < grid.columnCount; col++) {
        final cell = grid.cells[row][col];
        if (cell != null && cell.isPrimary) {
          children.add(_TableCellSlot(
            row: row,
            col: col,
            colspan: cell.colspan,
            rowspan: cell.rowspan,
            child: Container(
              padding: cellPadding,
              color: cell.cellNode.style.backgroundColor,
              child: _buildCellContent(cell.cellNode),
            ),
          ));
        }
      }
    }

    final tableWidget = _HyperTableWidget(
      columnCount: grid.columnCount,
      rowCount: grid.rowCount,
      borderColor: borderColor,
      borderWidth: borderWidth,
      children: children,
    );

    if (selectable) {
      return SelectionArea(child: tableWidget);
    }
    return tableWidget;
  }

  Widget _buildCellContent(TableCellNode cellNode) {
    final spans = <InlineSpan>[];
    bool hasNonInline = false;

    for (final child in cellNode.children) {
      final span = _buildSpan(child);
      if (span != null) {
        spans.add(span);
      } else {
        hasNonInline = true;
      }
    }

    if (hasNonInline && cellContentBuilder != null) {
      return cellContentBuilder!(cellNode);
    }

    if (spans.isEmpty) return const SizedBox.shrink();

    return Text.rich(
      TextSpan(
        children: spans,
        style: TextStyle(
          fontWeight: cellNode.isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  InlineSpan? _buildSpan(UDTNode node) {
    if (node is TextNode) {
      return TextSpan(text: node.text, style: node.style.toTextStyle());
    }
    if (node.type == NodeType.inline) {
      final children = <InlineSpan>[];
      for (final child in node.children) {
        final span = _buildSpan(child);
        if (span != null) children.add(span);
      }
      return TextSpan(children: children, style: node.style.toTextStyle());
    }
    if (node.type == NodeType.lineBreak) return const TextSpan(text: '\n');
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRID MODEL  (unchanged from before)
// ═══════════════════════════════════════════════════════════════════════════════

class _TableGrid {
  final List<List<_GridCell?>> cells;
  final int columnCount;
  final int rowCount;

  _TableGrid({
    required this.cells,
    required this.columnCount,
    required this.rowCount,
  });

  bool get isEmpty => rowCount == 0 || columnCount == 0;

  factory _TableGrid.fromTableNode(TableNode tableNode) {
    final rows = <TableRowNode>[];
    for (final child in tableNode.children) {
      if (child is TableRowNode) {
        rows.add(child);
      } else if (child.type == NodeType.block) {
        for (final grandChild in child.children) {
          if (grandChild is TableRowNode) rows.add(grandChild);
        }
      }
    }
    if (rows.isEmpty) {
      return _TableGrid(cells: [], columnCount: 0, rowCount: 0);
    }

    int maxCols = 0;
    for (final row in rows) {
      int colCount = 0;
      for (final cell in row.children) {
        if (cell is TableCellNode) colCount += cell.colspan;
      }
      if (colCount > maxCols) maxCols = colCount;
    }

    final rowCount = rows.length;
    final grid = List.generate(
      rowCount,
      (_) => List<_GridCell?>.filled(maxCols, null),
    );

    for (int rowIdx = 0; rowIdx < rows.length; rowIdx++) {
      int colIdx = 0;
      for (final child in rows[rowIdx].children) {
        if (child is TableCellNode) {
          while (colIdx < maxCols && grid[rowIdx][colIdx] != null) {
            colIdx++;
          }
          if (colIdx >= maxCols) break;

          final colspan = child.colspan;
          final rowspan = child.rowspan;
          final primary = _GridCell(
            cellNode: child,
            row: rowIdx,
            col: colIdx,
            colspan: colspan,
            rowspan: rowspan,
            isPrimary: true,
          );

          for (int r = rowIdx; r < rowIdx + rowspan && r < rowCount; r++) {
            for (int c = colIdx; c < colIdx + colspan && c < maxCols; c++) {
              grid[r][c] = (r == rowIdx && c == colIdx)
                  ? primary
                  : _GridCell(
                      cellNode: child,
                      row: rowIdx,
                      col: colIdx,
                      colspan: colspan,
                      rowspan: rowspan,
                      isPrimary: false,
                    );
            }
          }
          colIdx += colspan;
        }
      }
    }

    return _TableGrid(cells: grid, columnCount: maxCols, rowCount: rowCount);
  }
}

class _GridCell {
  final TableCellNode cellNode;
  final int row;
  final int col;
  final int colspan;
  final int rowspan;
  final bool isPrimary;

  _GridCell({
    required this.cellNode,
    required this.row,
    required this.col,
    required this.colspan,
    required this.rowspan,
    required this.isPrimary,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// RENDER LAYER
// ═══════════════════════════════════════════════════════════════════════════════

/// Parent data carried by every primary table cell.
class _TableCellParentData extends ContainerBoxParentData<RenderBox> {
  int row = 0;
  int col = 0;
  int colspan = 1;
  int rowspan = 1;
}

/// [ParentDataWidget] that injects row/col/colspan/rowspan into each cell's
/// [_TableCellParentData] so [_RenderHyperTable] can read it during layout.
class _TableCellSlot extends ParentDataWidget<_TableCellParentData> {
  final int row;
  final int col;
  final int colspan;
  final int rowspan;

  const _TableCellSlot({
    required this.row,
    required this.col,
    required this.colspan,
    required this.rowspan,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    final pd = renderObject.parentData! as _TableCellParentData;
    bool changed = false;
    if (pd.row != row) {
      pd.row = row;
      changed = true;
    }
    if (pd.col != col) {
      pd.col = col;
      changed = true;
    }
    if (pd.colspan != colspan) {
      pd.colspan = colspan;
      changed = true;
    }
    if (pd.rowspan != rowspan) {
      pd.rowspan = rowspan;
      changed = true;
    }
    if (changed) {
      final parent = renderObject.parent;
      if (parent is RenderObject) {
        parent.markNeedsLayout();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _HyperTableWidget;
}

/// [MultiChildRenderObjectWidget] backed by [_RenderHyperTable].
class _HyperTableWidget extends MultiChildRenderObjectWidget {
  final int columnCount;
  final int rowCount;
  final Color borderColor;
  final double borderWidth;

  const _HyperTableWidget({
    required this.columnCount,
    required this.rowCount,
    required this.borderColor,
    required this.borderWidth,
    required super.children,
  });

  @override
  _RenderHyperTable createRenderObject(BuildContext context) {
    return _RenderHyperTable(
      columnCount: columnCount,
      rowCount: rowCount,
      borderColor: borderColor,
      borderWidth: borderWidth,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderHyperTable renderObject) {
    renderObject
      ..columnCount = columnCount
      ..rowCount = rowCount
      ..borderColor = borderColor
      ..borderWidth = borderWidth;
  }
}

/// Custom table [RenderBox] — the heart of the new architecture.
///
/// ## Why a custom RenderObject?
///
/// Flutter's widget-composition approach to tables (Column → IntrinsicHeight →
/// Row → Expanded) requires [IntrinsicHeight] to equalize row heights.
/// [IntrinsicHeight] calls [getMaxIntrinsicHeight] on every descendant.  Any
/// descendant wrapped in [LayoutBuilder] (or [SingleChildScrollView] in the
/// wrong axis) will throw "LayoutBuilder does not support returning intrinsic
/// dimensions" and crash the entire layout.
///
/// A custom [RenderBox] sidesteps this entirely: row-height equalization is
/// done inside [performLayout] by calling [layout] on children directly — no
/// [IntrinsicHeight] widget is needed.  The render object itself implements
/// [computeMaxIntrinsicHeight] so that if THIS table is nested inside an outer
/// table cell that uses [IntrinsicHeight], the query propagates correctly.
///
/// ## Layout algorithm (W3C-inspired, 2-pass)
///
/// **Column widths** ([_distributeColumnWidths]):
///   1. Collect min/max intrinsic widths from each primary cell (split across
///      spanned columns for colspan > 1).
///   2. If total-min >= available width → use min widths (table may overflow;
///      caller wraps in horizontal scroll).
///   3. Otherwise distribute the surplus proportionally to max widths.
///
/// **Row heights** ([_computeRowHeights]):
///   1. Layout every cell with its allocated cell width.
///   2. For rowspan = 1 cells: contribute height to that row.
///   3. For rowspan > 1 cells: if their height overflows the spanned rows,
///      distribute the excess equally across those rows.
///   4. Re-layout rowspan > 1 cells with tight height so they visually fill
///      their allocated space (cell background covers the full span).
///
/// **Borders** are painted as filled rectangles after children.
class _RenderHyperTable extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TableCellParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TableCellParentData> {
  // ── mutable properties ───────────────────────────────────────────────────

  int _columnCount;
  int _rowCount;
  Color _borderColor;
  double _borderWidth;

  // ── layout cache ─────────────────────────────────────────────────────────

  List<double>? _colWidths;
  List<double>? _rowHeights;

  _RenderHyperTable({
    required int columnCount,
    required int rowCount,
    required Color borderColor,
    required double borderWidth,
  })  : _columnCount = columnCount,
        _rowCount = rowCount,
        _borderColor = borderColor,
        _borderWidth = borderWidth;

  set columnCount(int v) {
    if (_columnCount != v) {
      _columnCount = v;
      markNeedsLayout();
    }
  }

  set rowCount(int v) {
    if (_rowCount != v) {
      _rowCount = v;
      markNeedsLayout();
    }
  }

  set borderColor(Color v) {
    if (_borderColor != v) {
      _borderColor = v;
      markNeedsPaint();
    }
  }

  set borderWidth(double v) {
    if (_borderWidth != v) {
      _borderWidth = v;
      markNeedsLayout();
    }
  }

  // ── parentData setup ─────────────────────────────────────────────────────

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TableCellParentData) {
      child.parentData = _TableCellParentData();
    }
  }

  // ── intrinsic dimensions ─────────────────────────────────────────────────

  @override
  double computeMinIntrinsicWidth(double height) {
    if (_columnCount == 0) return 0;
    final minW = List<double>.filled(_columnCount, 0.0);
    _walkChildren((child, pd) {
      final span = pd.colspan.clamp(1, _columnCount - pd.col);
      final childMin = child.getMinIntrinsicWidth(double.infinity);
      final perCol = childMin / span;
      for (int c = pd.col; c < pd.col + span && c < _columnCount; c++) {
        if (perCol > minW[c]) minW[c] = perCol;
      }
    });
    return minW.fold(0.0, (s, v) => s + v) + _borderWidth * (_columnCount + 1);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (_columnCount == 0) return 0;
    final maxW = List<double>.filled(_columnCount, 0.0);
    _walkChildren((child, pd) {
      final span = pd.colspan.clamp(1, _columnCount - pd.col);
      final childMax = child.getMaxIntrinsicWidth(double.infinity);
      final perCol = childMax / span;
      for (int c = pd.col; c < pd.col + span && c < _columnCount; c++) {
        if (perCol > maxW[c]) maxW[c] = perCol;
      }
    });
    return maxW.fold(0.0, (s, v) => s + v) + _borderWidth * (_columnCount + 1);
  }

  /// Called when THIS table is a child of [IntrinsicHeight] (i.e. it is nested
  /// inside a cell of an outer table).  Must NOT call [layout] — uses
  /// [getMaxIntrinsicHeight] on children instead.
  @override
  double computeMaxIntrinsicHeight(double width) {
    if (_columnCount == 0 || _rowCount == 0) return 0;
    final colW = _distributeColumnWidths(width);
    final rowH = List<double>.filled(_rowCount, 0.0);

    // Only rowspan = 1 cells contribute reliably without a layout pass.
    _walkChildren((child, pd) {
      if (pd.rowspan == 1) {
        final cellW = _cellWidth(pd.col, pd.colspan, colW);
        final h = child.getMaxIntrinsicHeight(cellW);
        if (h > rowH[pd.row]) rowH[pd.row] = h;
      }
    });

    // rowspan > 1 cells: use their intrinsic height and distribute if needed.
    _walkChildren((child, pd) {
      if (pd.rowspan > 1) {
        final cellW = _cellWidth(pd.col, pd.colspan, colW);
        final h = child.getMaxIntrinsicHeight(cellW);
        final endRow = math.min(pd.row + pd.rowspan, _rowCount);
        double spanned = _borderWidth * (endRow - pd.row - 1);
        for (int r = pd.row; r < endRow; r++) {
          spanned += rowH[r];
        }
        final overflow = h - spanned;
        if (overflow > 0) {
          final extra = overflow / (endRow - pd.row);
          for (int r = pd.row; r < endRow; r++) {
            rowH[r] += extra;
          }
        }
      }
    });

    return rowH.fold(0.0, (s, v) => s + v) + _borderWidth * (_rowCount + 1);
  }

  // ── layout ───────────────────────────────────────────────────────────────

  @override
  void performLayout() {
    if (_columnCount == 0 || _rowCount == 0) {
      size = constraints.constrain(Size.zero);
      return;
    }

    // Step 1 — column widths
    _colWidths = _distributeColumnWidths(constraints.maxWidth);

    // Step 2 — row heights (lays out all cells as a side-effect)
    _rowHeights = _computeRowHeights(_colWidths!);

    // Step 3 — position every cell
    _positionCells(_colWidths!, _rowHeights!);

    // Step 4 — own size
    final totalW = _colWidths!.fold(0.0, (s, v) => s + v)
        + _borderWidth * (_columnCount + 1);
    final totalH = _rowHeights!.fold(0.0, (s, v) => s + v)
        + _borderWidth * (_rowCount + 1);
    size = constraints.constrain(Size(totalW, totalH));
  }

  // ── column-width distribution ─────────────────────────────────────────────

  /// W3C-inspired two-pass column-width distribution.
  ///
  /// When [availW] is [double.infinity] (inside [FittedBox] / horizontal
  /// [SingleChildScrollView]) the table uses its natural (max-intrinsic) widths.
  List<double> _distributeColumnWidths(double availW) {
    if (_columnCount == 0) return [];

    // Unconstrained — return natural column widths.
    if (availW.isInfinite) {
      final maxW = List<double>.filled(_columnCount, 0.0);
      _walkChildren((child, pd) {
        final span = pd.colspan.clamp(1, _columnCount - pd.col);
        final childMax = child.getMaxIntrinsicWidth(double.infinity);
        final perCol = childMax / span;
        for (int c = pd.col; c < pd.col + span && c < _columnCount; c++) {
          if (perCol > maxW[c]) maxW[c] = perCol;
        }
      });
      return maxW;
    }

    // Content width after reserving space for borders.
    final contentW =
        (availW - _borderWidth * (_columnCount + 1)).clamp(0.0, double.infinity);

    final minW = List<double>.filled(_columnCount, 0.0);
    final maxW = List<double>.filled(_columnCount, 0.0);

    _walkChildren((child, pd) {
      final span = pd.colspan.clamp(1, _columnCount - pd.col);
      final childMin = child.getMinIntrinsicWidth(double.infinity);
      final childMax = child.getMaxIntrinsicWidth(double.infinity);
      final perColMin = childMin / span;
      final perColMax = childMax / span;
      for (int c = pd.col; c < pd.col + span && c < _columnCount; c++) {
        if (perColMin > minW[c]) minW[c] = perColMin;
        if (perColMax > maxW[c]) maxW[c] = perColMax;
      }
    });

    final totalMin = minW.fold(0.0, (s, v) => s + v);

    // Not enough room — clamp to min widths (table may overflow / scroll).
    if (totalMin >= contentW) return List<double>.from(minW);

    final surplus = contentW - totalMin;
    final totalMax = maxW.fold(0.0, (s, v) => s + v);

    // No max-width info → equal distribution.
    if (totalMax <= 0) {
      return List<double>.filled(_columnCount, contentW / _columnCount);
    }

    // Proportional distribution of surplus to wider-content columns.
    return List<double>.generate(
      _columnCount,
      (c) => minW[c] + surplus * (maxW[c] / totalMax),
    );
  }

  // ── row-height computation ────────────────────────────────────────────────

  /// Lays out every primary cell and computes the final row heights.
  ///
  /// Three sub-passes:
  ///   1. Initial layout → rowspan=1 cells set their row's height.
  ///   2. rowspan>1 overflow → excess distributed across spanned rows.
  ///   3. Re-layout rowspan>1 cells with tight height so they fill the span.
  List<double> _computeRowHeights(List<double> colWidths) {
    final rowH = List<double>.filled(_rowCount, 0.0);

    // — Pass 1: layout every cell; rowspan=1 cells determine row heights ——
    _walkChildren((child, pd) {
      final cellW = _cellWidth(pd.col, pd.colspan, colWidths);
      child.layout(BoxConstraints(maxWidth: cellW), parentUsesSize: true);
      if (pd.rowspan == 1) {
        if (child.size.height > rowH[pd.row]) rowH[pd.row] = child.size.height;
      }
    });

    // — Pass 2: distribute overflow from rowspan>1 cells ———————————————————
    _walkChildren((child, pd) {
      if (pd.rowspan > 1) {
        final endRow = math.min(pd.row + pd.rowspan, _rowCount);
        double spanned = _borderWidth * (endRow - pd.row - 1);
        for (int r = pd.row; r < endRow; r++) {
          spanned += rowH[r];
        }
        final overflow = child.size.height - spanned;
        if (overflow > 0) {
          final extra = overflow / (endRow - pd.row);
          for (int r = pd.row; r < endRow; r++) {
            rowH[r] += extra;
          }
        }
      }
    });

    // — Pass 3: re-layout rowspan>1 cells with tight height so their
    //           background fills the full visual span ————————————————————————
    _walkChildren((child, pd) {
      if (pd.rowspan > 1) {
        final endRow = math.min(pd.row + pd.rowspan, _rowCount);
        double totalH = _borderWidth * (endRow - pd.row - 1);
        for (int r = pd.row; r < endRow; r++) {
          totalH += rowH[r];
        }
        final cellW = _cellWidth(pd.col, pd.colspan, colWidths);
        child.layout(
          BoxConstraints(
            minWidth: cellW,
            maxWidth: cellW,
            minHeight: totalH,
            maxHeight: totalH,
          ),
          parentUsesSize: true,
        );
      }
    });

    return rowH;
  }

  // ── cell-width helper ─────────────────────────────────────────────────────

  /// Width allocated to a cell spanning [colspan] columns starting at [col],
  /// including the internal border segments between those columns.
  double _cellWidth(int col, int colspan, List<double> colWidths) {
    final end = math.min(col + colspan, _columnCount);
    double w = 0;
    for (int c = col; c < end; c++) {
      w += colWidths[c];
    }
    // Add the internal borders between spanned columns (but not the outer ones).
    w += _borderWidth * (end - col - 1).clamp(0, _columnCount);
    return w.clamp(0.0, double.infinity);
  }

  // ── cell positioning ──────────────────────────────────────────────────────

  void _positionCells(List<double> colWidths, List<double> rowHeights) {
    // Precompute the left edge of each column (including leading border).
    final colX = List<double>.filled(_columnCount + 1, 0.0);
    colX[0] = _borderWidth;
    for (int c = 0; c < _columnCount; c++) {
      colX[c + 1] = colX[c] + colWidths[c] + _borderWidth;
    }

    // Precompute the top edge of each row (including leading border).
    final rowY = List<double>.filled(_rowCount + 1, 0.0);
    rowY[0] = _borderWidth;
    for (int r = 0; r < _rowCount; r++) {
      rowY[r + 1] = rowY[r] + rowHeights[r] + _borderWidth;
    }

    _walkChildren((child, pd) {
      pd.offset = Offset(colX[pd.col], rowY[pd.row]);
    });
  }

  // ── paint ─────────────────────────────────────────────────────────────────

  @override
  void paint(PaintingContext context, Offset offset) {
    // Paint cell contents first.
    defaultPaint(context, offset);

    // Paint grid borders on top so they are always visible.
    if (_colWidths == null || _rowHeights == null) return;
    _paintBorders(context.canvas, offset);
  }

  void _paintBorders(Canvas canvas, Offset offset) {
    final paint = Paint()
      ..color = _borderColor
      ..style = PaintingStyle.fill;

    final totalW = _colWidths!.fold(0.0, (s, v) => s + v)
        + _borderWidth * (_columnCount + 1);
    final totalH = _rowHeights!.fold(0.0, (s, v) => s + v)
        + _borderWidth * (_rowCount + 1);

    // Horizontal lines (one per row boundary, plus top and bottom).
    double y = offset.dy;
    for (int r = 0; r <= _rowCount; r++) {
      canvas.drawRect(
        Rect.fromLTWH(offset.dx, y, totalW, _borderWidth),
        paint,
      );
      if (r < _rowCount) y += _borderWidth + _rowHeights![r];
    }

    // Vertical lines (one per column boundary, plus left and right).
    double x = offset.dx;
    for (int c = 0; c <= _columnCount; c++) {
      canvas.drawRect(
        Rect.fromLTWH(x, offset.dy, _borderWidth, totalH),
        paint,
      );
      if (c < _columnCount) x += _borderWidth + _colWidths![c];
    }
  }

  // ── hit testing ───────────────────────────────────────────────────────────

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  // ── utility ───────────────────────────────────────────────────────────────

  void _walkChildren(void Function(RenderBox child, _TableCellParentData pd) fn) {
    RenderBox? child = firstChild;
    while (child != null) {
      fn(child, child.parentData! as _TableCellParentData);
      child = childAfter(child);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy public symbol — kept so external code that references TableParentData
// by name does not break at compile time.
// ─────────────────────────────────────────────────────────────────────────────

/// @deprecated  Use the internal [_TableCellParentData] instead.
/// Kept only for backwards API compatibility.
class TableParentData extends ContainerBoxParentData<RenderBox> {
  int column = 0;
  int row = 0;
  int colspan = 1;
  int rowspan = 1;
}
