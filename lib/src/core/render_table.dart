import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../model/node.dart';

/// Table display strategy
///
/// Determines how tables that are wider than screen are handled
enum TableStrategy {
  /// Fit table to screen width (may truncate content)
  fitWidth,

  /// Scale down table to fit (preserves proportions)
  autoScale,

  /// Enable horizontal scrolling
  horizontalScroll,
}

/// SmartTableWrapper - Intelligent table rendering
///
/// Handles tables that are wider than the screen by:
/// 1. Fitting to screen width if small enough
/// 2. Auto-scaling to fit while preserving proportions
/// 3. Enabling horizontal scroll for very wide tables
///
/// The wrapper automatically detects when a table would be too compressed
/// (columns narrower than [minColumnWidth]) and switches to horizontal scroll
/// to prevent unreadable text.
///
/// Reference: doc3.md - "Requirement 2: Table Horizontal Scroll & Auto Scale"
class SmartTableWrapper extends StatelessWidget {
  /// The table node to render
  final TableNode tableNode;

  /// Strategy for handling wide tables
  final TableStrategy strategy;

  /// Minimum scale factor before switching to scroll (for autoScale strategy)
  final double minScaleFactor;

  /// Minimum column width in pixels before auto-switching to horizontal scroll
  ///
  /// If the table's columns would be compressed below this width,
  /// the wrapper automatically switches to [TableStrategy.horizontalScroll]
  /// to prevent unreadable text. Default is 60.0 pixels.
  final double minColumnWidth;

  /// Base text style for table content
  final TextStyle? baseStyle;

  /// Callback when a link in the table is tapped
  final void Function(String url)? onLinkTap;

  /// Whether text in table cells can be selected
  final bool selectable;

  /// Optional builder for cells that contain block-level content (nested
  /// tables, paragraphs, images, etc.) that cannot be represented as inline
  /// spans. When null, such content is silently dropped.
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Build the table widget
        final table = _buildTable(context);

        // Calculate effective strategy based on constraints
        final effectiveStrategy = _calculateEffectiveStrategy(constraints);

        // Apply strategy based on configuration
        switch (effectiveStrategy) {
          case TableStrategy.fitWidth:
            // Render table with width constraints
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: table,
            );

          case TableStrategy.autoScale:
            // Use FittedBox to scale down if needed
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: table,
            );

          case TableStrategy.horizontalScroll:
            // Enable horizontal scrolling
            return _buildScrollableTable(table);
        }
      },
    );
  }

  /// Calculate the effective strategy based on table size and constraints
  ///
  /// If the requested strategy would result in columns that are too narrow,
  /// automatically switch to horizontal scroll to prevent unreadable text.
  TableStrategy _calculateEffectiveStrategy(BoxConstraints constraints) {
    if (strategy == TableStrategy.horizontalScroll) {
      return strategy; // Already using scroll, no change needed
    }

    // Estimate table width based on column count
    final columnCount = _estimateColumnCount();
    if (columnCount == 0) return strategy;

    final availableWidth = constraints.maxWidth;
    final estimatedColumnWidth = availableWidth / columnCount;

    // If columns would be too narrow, switch to horizontal scroll
    if (estimatedColumnWidth < minColumnWidth) {
      return TableStrategy.horizontalScroll;
    }

    // For autoScale, also check if scale factor would be too small
    if (strategy == TableStrategy.autoScale) {
      // Estimate natural table width (rough estimate based on column count and min width)
      final naturalWidth = columnCount * minColumnWidth * 2; // Assume 2x min as natural
      final scaleFactor = availableWidth / naturalWidth;

      if (scaleFactor < minScaleFactor) {
        return TableStrategy.horizontalScroll;
      }
    }

    return strategy;
  }

  /// Estimate the number of columns in the table
  int _estimateColumnCount() {
    // TableNode stores rows as children
    final rows = tableNode.children.whereType<TableRowNode>();
    if (rows.isEmpty) return 0;

    // Find the maximum number of cells in any row (accounting for colspan)
    int maxColumns = 0;
    for (final row in rows) {
      int rowColumns = 0;
      // TableRowNode stores cells as children
      final cells = row.children.whereType<TableCellNode>();
      for (final cell in cells) {
        rowColumns += cell.colspan;
      }
      if (rowColumns > maxColumns) {
        maxColumns = rowColumns;
      }
    }
    return maxColumns;
  }

  Widget _buildScrollableTable(Widget table) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: table,
    );
  }

  Widget _buildTable(BuildContext context) {
    return HyperTable(
      tableNode: tableNode,
      baseStyle: baseStyle,
      onLinkTap: onLinkTap,
      selectable: selectable,
      cellContentBuilder: cellContentBuilder,
    );
  }
}


/// HyperTable - Custom table widget with advanced features
///
/// Features:
/// - Supports colspan and rowspan
/// - Border customization
/// - Header/body styling
/// - Proper intrinsic width calculation
/// - Text selection across cells (when selectable = true)
///
/// Note: Uses custom layout instead of Flutter's Table widget
/// because Table doesn't support colspan/rowspan.
class HyperTable extends StatelessWidget {
  final TableNode tableNode;
  final TextStyle? baseStyle;
  final void Function(String url)? onLinkTap;

  /// Border color
  final Color borderColor;

  /// Border width
  final double borderWidth;

  /// Default cell padding
  final EdgeInsets cellPadding;

  /// Whether text in cells can be selected
  /// When true, wraps table with SelectionArea for cross-cell selection
  final bool selectable;

  /// Optional builder for cells that contain block-level content (nested
  /// tables, paragraphs, images) that cannot be represented as inline spans.
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
    // Build grid model from table node
    final grid = _TableGrid.fromTableNode(tableNode);

    if (grid.isEmpty) {
      return const SizedBox.shrink();
    }

    final tableWidget = _TableLayout(
      grid: grid,
      borderColor: borderColor,
      borderWidth: borderWidth,
      cellPadding: cellPadding,
      cellBuilder: _buildCellContent,
    );

    // Wrap with SelectionArea for cross-cell text selection
    if (selectable) {
      return SelectionArea(
        child: tableWidget,
      );
    }

    return tableWidget;
  }

  Widget _buildCellContent(TableCellNode cellNode) {
    // Try to build inline spans for all children.
    // Any child that is not inline (nested table, block, image …) returns null
    // from _buildSpan — track whether that happened.
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

    // If there is block-level content that can't be an inline span, delegate
    // to the external builder (e.g. a HyperRenderWidget closure supplied by
    // hyper_render_widget.dart) so nested tables / paragraphs / images render.
    if (hasNonInline && cellContentBuilder != null) {
      return cellContentBuilder!(cellNode);
    }

    if (spans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: TextStyle(
          fontWeight:
              cellNode.isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  InlineSpan? _buildSpan(UDTNode node) {
    if (node is TextNode) {
      return TextSpan(
        text: node.text,
        style: node.style.toTextStyle(),
      );
    }

    if (node.type == NodeType.inline) {
      final children = <InlineSpan>[];
      for (final child in node.children) {
        final span = _buildSpan(child);
        if (span != null) {
          children.add(span);
        }
      }
      return TextSpan(
        children: children,
        style: node.style.toTextStyle(),
      );
    }

    if (node.type == NodeType.lineBreak) {
      return const TextSpan(text: '\n');
    }

    return null;
  }
}

/// Internal grid model for table layout
///
/// This class analyzes the table structure and creates a 2D grid
/// that properly handles colspan and rowspan.
class _TableGrid {
  /// Grid cells (row, col) -> cell info
  final List<List<_GridCell?>> cells;

  /// Number of columns
  final int columnCount;

  /// Number of rows
  final int rowCount;

  _TableGrid({
    required this.cells,
    required this.columnCount,
    required this.rowCount,
  });

  bool get isEmpty => rowCount == 0 || columnCount == 0;

  /// Build grid from TableNode
  factory _TableGrid.fromTableNode(TableNode tableNode) {
    // First pass: collect all rows
    final rows = <TableRowNode>[];
    for (final child in tableNode.children) {
      if (child is TableRowNode) {
        rows.add(child);
      } else if (child.type == NodeType.block) {
        // Handle thead, tbody, tfoot
        for (final grandChild in child.children) {
          if (grandChild is TableRowNode) {
            rows.add(grandChild);
          }
        }
      }
    }

    if (rows.isEmpty) {
      return _TableGrid(cells: [], columnCount: 0, rowCount: 0);
    }

    // Calculate column count (max cells in any row, considering colspan)
    int maxCols = 0;
    for (final row in rows) {
      int colCount = 0;
      for (final cell in row.children) {
        if (cell is TableCellNode) {
          colCount += cell.colspan;
        }
      }
      if (colCount > maxCols) maxCols = colCount;
    }

    // Initialize grid with nulls
    final rowCount = rows.length;
    final grid = List.generate(
      rowCount,
      (_) => List<_GridCell?>.filled(maxCols, null),
    );

    // Second pass: fill grid with cells
    for (int rowIdx = 0; rowIdx < rows.length; rowIdx++) {
      int colIdx = 0;
      for (final child in rows[rowIdx].children) {
        if (child is TableCellNode) {
          // Find next available column
          while (colIdx < maxCols && grid[rowIdx][colIdx] != null) {
            colIdx++;
          }

          if (colIdx >= maxCols) break;

          final colspan = child.colspan;
          final rowspan = child.rowspan;

          // Create primary cell
          final gridCell = _GridCell(
            cellNode: child,
            row: rowIdx,
            col: colIdx,
            colspan: colspan,
            rowspan: rowspan,
            isPrimary: true,
          );

          // Fill all cells covered by this spanning cell
          for (int r = rowIdx; r < rowIdx + rowspan && r < rowCount; r++) {
            for (int c = colIdx; c < colIdx + colspan && c < maxCols; c++) {
              if (r == rowIdx && c == colIdx) {
                grid[r][c] = gridCell;
              } else {
                // Mark as covered by the primary cell
                grid[r][c] = _GridCell(
                  cellNode: child,
                  row: rowIdx,
                  col: colIdx,
                  colspan: colspan,
                  rowspan: rowspan,
                  isPrimary: false,
                );
              }
            }
          }

          colIdx += colspan;
        }
      }
    }

    return _TableGrid(
      cells: grid,
      columnCount: maxCols,
      rowCount: rowCount,
    );
  }
}

/// A cell in the table grid
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

/// Table layout widget that handles colspan/rowspan
class _TableLayout extends StatelessWidget {
  final _TableGrid grid;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets cellPadding;
  final Widget Function(TableCellNode) cellBuilder;

  const _TableLayout({
    required this.grid,
    required this.borderColor,
    required this.borderWidth,
    required this.cellPadding,
    required this.cellBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap in LayoutBuilder to handle unbounded constraints
    // This fixes "NEEDS-LAYOUT" error when used in horizontal scroll
    return LayoutBuilder(
      builder: (context, constraints) {
        final child = Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildRows(),
          ),
        );

        // If width is unbounded (e.g., in horizontal scroll),
        // wrap in IntrinsicWidth to provide bounded constraints
        if (constraints.maxWidth == double.infinity) {
          return IntrinsicWidth(child: child);
        }

        return child;
      },
    );
  }

  List<Widget> _buildRows() {
    final rows = <Widget>[];

    for (int rowIdx = 0; rowIdx < grid.rowCount; rowIdx++) {
      // Check if this row has any primary cells (not covered by rowspan from above)
      bool hasContent = false;
      for (int colIdx = 0; colIdx < grid.columnCount; colIdx++) {
        final cell = grid.cells[rowIdx][colIdx];
        if (cell != null && (cell.isPrimary || cell.row == rowIdx)) {
          hasContent = true;
          break;
        }
      }

      if (!hasContent) continue;

      if (rows.isNotEmpty) {
        // Add horizontal border between rows
        rows.add(Container(
          height: borderWidth,
          color: borderColor,
        ));
      }

      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildRowCells(rowIdx),
        ),
      ));
    }

    return rows;
  }

  List<Widget> _buildRowCells(int rowIdx) {
    final widgets = <Widget>[];
    int colIdx = 0;

    while (colIdx < grid.columnCount) {
      final cell = grid.cells[rowIdx][colIdx];

      if (cell == null) {
        // Empty cell
        widgets.add(_buildEmptyCell());
        colIdx++;
        continue;
      }

      if (!cell.isPrimary) {
        // This cell is covered by a spanning cell from above (rowspan)
        // We need to add a spacer to maintain column alignment
        // Use the colspan of the primary cell to determine flex
        final primaryColspan = cell.colspan;

        // Add vertical border before spacer (except first)
        if (widgets.isNotEmpty) {
          widgets.add(Container(
            width: borderWidth,
            color: borderColor,
          ));
        }

        // Add invisible spacer with same flex as the primary cell
        widgets.add(Expanded(
          flex: primaryColspan,
          child: const SizedBox.shrink(),
        ));

        colIdx += primaryColspan;
        continue;
      }

      // Add vertical border before cell (except first)
      if (widgets.isNotEmpty) {
        widgets.add(Container(
          width: borderWidth,
          color: borderColor,
        ));
      }

      // Build the cell widget
      widgets.add(_buildCell(cell));
      colIdx += cell.colspan;
    }

    return widgets;
  }

  Widget _buildCell(_GridCell cell) {
    // Calculate flex based on colspan
    final flex = cell.colspan;

    return Expanded(
      flex: flex,
      child: Container(
        padding: cellPadding,
        decoration: BoxDecoration(
          color: cell.cellNode.style.backgroundColor,
        ),
        child: cellBuilder(cell.cellNode),
      ),
    );
  }

  Widget _buildEmptyCell() {
    return Expanded(
      child: Container(
        padding: cellPadding,
      ),
    );
  }
}

/// Custom RenderTable with intrinsic width calculation
///
/// This is an optimized table layout that properly calculates
/// minimum and maximum intrinsic widths for smart resizing.
///
/// Reference: doc3.md - "RenderCustomHtmlTable"
class RenderHyperTable extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TableParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TableParentData> {
  /// Number of columns
  final int columnCount;

  /// Number of rows
  final int rowCount;

  /// Column widths (calculated after layout)
  List<double>? _columnWidths;

  /// Row heights (calculated after layout)
  List<double>? _rowHeights;

  RenderHyperTable({
    required this.columnCount,
    required this.rowCount,
  });

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TableParentData) {
      child.parentData = TableParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    // Sum of minimum column widths
    double totalWidth = 0;
    RenderBox? child = firstChild;

    for (int col = 0; col < columnCount; col++) {
      double maxColWidth = 0;

      for (int row = 0; row < rowCount; row++) {
        if (child != null) {
          final childMinWidth = child.getMinIntrinsicWidth(double.infinity);
          if (childMinWidth > maxColWidth) {
            maxColWidth = childMinWidth;
          }
          child = childAfter(child);
        }
      }

      totalWidth += maxColWidth;
    }

    return totalWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    // Sum of maximum column widths
    double totalWidth = 0;
    RenderBox? child = firstChild;

    for (int col = 0; col < columnCount; col++) {
      double maxColWidth = 0;

      for (int row = 0; row < rowCount; row++) {
        if (child != null) {
          final childMaxWidth = child.getMaxIntrinsicWidth(double.infinity);
          if (childMaxWidth > maxColWidth) {
            maxColWidth = childMaxWidth;
          }
          child = childAfter(child);
        }
      }

      totalWidth += maxColWidth;
    }

    return totalWidth;
  }

  @override
  void performLayout() {
    // Calculate column widths
    _columnWidths = _calculateColumnWidths(constraints.maxWidth);

    // Calculate row heights
    _rowHeights = _calculateRowHeights(_columnWidths!);

    // Position cells
    _positionCells(_columnWidths!, _rowHeights!);

    // Set size
    final totalWidth = _columnWidths!.reduce((a, b) => a + b);
    final totalHeight = _rowHeights!.reduce((a, b) => a + b);
    size = constraints.constrain(Size(totalWidth, totalHeight));
  }

  /// Calculates column widths using a 2-pass W3C-inspired table layout.
  ///
  /// **Pass 1 — Min-content widths** (`minW[col]`):
  ///   For each column, find the widest minimum intrinsic width reported by
  ///   any child cell that starts in that column.  For cells with `colspan > 1`
  ///   the min-width is divided equally among the spanned columns.
  ///
  /// **Pass 2 — Distribute remaining space**:
  ///   If `sum(minW) >= maxWidth` the columns are clamped to their min-widths
  ///   (table may overflow, caller adds horizontal scroll).
  ///   Otherwise the surplus is distributed proportionally to the
  ///   max-intrinsic widths (`maxW[col]`) so wider-content columns receive
  ///   proportionally more space.
  List<double> _calculateColumnWidths(double maxWidth) {
    if (columnCount == 0) return [];
    if (maxWidth == 0 || maxWidth == double.infinity) {
      return List.filled(columnCount, 0.0);
    }

    // --- Pass 1: collect min and max intrinsic widths per column -----------
    // We iterate children in row-major order (same as _calculateRowHeights).
    // Each child corresponds to the cell at (row, col) in the linear scan.
    final minW = List<double>.filled(columnCount, 0.0);
    final maxW = List<double>.filled(columnCount, 0.0);

    // Walk children: columnCount children per row, rowCount rows.
    RenderBox? child = firstChild;
    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < columnCount; col++) {
        if (child == null) break;

        final td = child.parentData as TableParentData;
        final span = td.colspan.clamp(1, columnCount - col);

        final childMin = child.getMinIntrinsicWidth(double.infinity);
        final childMax = child.getMaxIntrinsicWidth(double.infinity);

        // Distribute this cell's contribution equally across spanned columns.
        final perColMin = childMin / span;
        final perColMax = childMax / span;

        for (int c = col; c < col + span && c < columnCount; c++) {
          if (perColMin > minW[c]) minW[c] = perColMin;
          if (perColMax > maxW[c]) maxW[c] = perColMax;
        }

        child = childAfter(child);
      }
    }

    // --- Pass 2: distribute available space --------------------------------
    final totalMin = minW.fold(0.0, (s, v) => s + v);

    if (totalMin >= maxWidth) {
      // Not enough room — use min widths (table will likely overflow/scroll).
      return List<double>.from(minW);
    }

    final surplus = maxWidth - totalMin;
    final totalMax = maxW.fold(0.0, (s, v) => s + v);

    if (totalMax <= 0) {
      // No max-width info — fall back to equal distribution.
      final equal = maxWidth / columnCount;
      return List.filled(columnCount, equal);
    }

    // Proportional distribution of the surplus based on max-content widths.
    final widths = List<double>.filled(columnCount, 0.0);
    for (int c = 0; c < columnCount; c++) {
      widths[c] = minW[c] + surplus * (maxW[c] / totalMax);
    }
    return widths;
  }

  List<double> _calculateRowHeights(List<double> columnWidths) {
    final heights = <double>[];
    RenderBox? child = firstChild;

    for (int row = 0; row < rowCount; row++) {
      double maxRowHeight = 0;

      for (int col = 0; col < columnCount; col++) {
        if (child != null) {
          child.layout(
            BoxConstraints(maxWidth: columnWidths[col]),
            parentUsesSize: true,
          );

          if (child.size.height > maxRowHeight) {
            maxRowHeight = child.size.height;
          }
          child = childAfter(child);
        }
      }

      heights.add(maxRowHeight);
    }

    return heights;
  }

  void _positionCells(List<double> columnWidths, List<double> rowHeights) {
    RenderBox? child = firstChild;
    double y = 0;

    for (int row = 0; row < rowCount; row++) {
      double x = 0;

      for (int col = 0; col < columnCount; col++) {
        if (child != null) {
          final parentData = child.parentData as TableParentData;
          parentData.offset = Offset(x, y);
          x += columnWidths[col];
          child = childAfter(child);
        }
      }

      y += rowHeights[row];
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

/// Parent data for table cells
class TableParentData extends ContainerBoxParentData<RenderBox> {
  /// Column index
  int column = 0;

  /// Row index
  int row = 0;

  /// Colspan
  int colspan = 1;

  /// Rowspan
  int rowspan = 1;
}
