import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../model/node.dart';
import '../style/design_tokens.dart';

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
/// Reference: doc3.md - "Requirement 2: Table Horizontal Scroll & Auto Scale"
class SmartTableWrapper extends StatelessWidget {
  /// The table node to render
  final TableNode tableNode;

  /// Strategy for handling wide tables
  final TableStrategy strategy;

  /// Minimum scale factor before switching to scroll
  final double minScaleFactor;

  /// Base text style for table content
  final TextStyle? baseStyle;

  /// Callback when a link in the table is tapped
  final void Function(String url)? onLinkTap;

  /// Whether text in table cells can be selected
  final bool selectable;

  /// Custom builder for cell content (recursive rendering)
  final Widget Function(TableCellNode)? cellContentBuilder;

  const SmartTableWrapper({
    super.key,
    required this.tableNode,
    this.strategy = TableStrategy.horizontalScroll,
    this.minScaleFactor = 0.6,
    this.baseStyle,
    this.onLinkTap,
    this.selectable = true,
    this.cellContentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Build the table widget
    final table = _buildTable(context);

    // Apply strategy based on configuration
    switch (strategy) {
      case TableStrategy.fitWidth:
        // Just render table as-is, it will fit to constraints
        return table;

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
  final Color? borderColor;

  /// Border width
  final double borderWidth;

  /// Default cell padding
  final EdgeInsets? cellPadding;

  /// Whether text in cells can be selected
  /// When true, wraps table with SelectionArea for cross-cell selection
  final bool selectable;

  /// Custom builder for cell content
  final Widget Function(TableCellNode)? cellContentBuilder;

  const HyperTable({
    super.key,
    required this.tableNode,
    this.baseStyle,
    this.onLinkTap,
    this.borderColor,
    this.borderWidth = 1.0,
    this.cellPadding,
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

    // Use theme colors and design tokens as defaults
    final effectiveBorderColor = borderColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignTokens.darkTableBorder
            : DesignTokens.tableBorder);

    final effectiveCellPadding =
        cellPadding ?? EdgeInsets.symmetric(
          horizontal: DesignTokens.space2,
          vertical: DesignTokens.space1_5,
        );

    final tableWidget = _TableLayout(
      grid: grid,
      borderColor: effectiveBorderColor,
      borderWidth: borderWidth,
      cellPadding: effectiveCellPadding,
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
    if (cellContentBuilder != null) {
      return cellContentBuilder!(cellNode);
    }

    // Build text spans from children
    final spans = <InlineSpan>[];

    for (final child in cellNode.children) {
      final span = _buildSpan(child);
      if (span != null) {
        spans.add(span);
      }
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
      // Explicit text wrapping behavior for consistent cell rendering
      softWrap: true,
      overflow: TextOverflow.clip,
      textWidthBasis: TextWidthBasis.parent,
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

  /// Number of header rows (from thead section)
  final int headerRowCount;

  _TableGrid({
    required this.cells,
    required this.columnCount,
    required this.rowCount,
    this.headerRowCount = 0,
  });

  bool get isEmpty => rowCount == 0 || columnCount == 0;

  /// Build grid from TableNode
  factory _TableGrid.fromTableNode(TableNode tableNode) {
    // First pass: collect all rows and track header rows
    final rows = <TableRowNode>[];
    int headerRowCount = 0;

    for (final child in tableNode.children) {
      if (child is TableRowNode) {
        rows.add(child);
      } else if (child.type == NodeType.block) {
        // Check if this is thead section
        final isTheadSection = child.tagName?.toLowerCase() == 'thead';

        // Handle thead, tbody, tfoot
        for (final grandChild in child.children) {
          if (grandChild is TableRowNode) {
            rows.add(grandChild);
            // Count header rows from thead section
            if (isTheadSection) {
              headerRowCount++;
            }
          }
        }
      }
    }

    if (rows.isEmpty) {
      return _TableGrid(cells: [], columnCount: 0, rowCount: 0, headerRowCount: 0);
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
      headerRowCount: headerRowCount,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Wrap in LayoutBuilder to handle unbounded constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        // For unbounded width, calculate table width based on content
        // This avoids nested IntrinsicWidth+IntrinsicHeight which causes layout thrashing
        double? tableWidth;
        if (constraints.maxWidth == double.infinity) {
          tableWidth = _calculateTableWidth();
        }

        final child = Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: borderWidth),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildRows(isDark),
          ),
        );

        // If we calculated a specific width, constrain to it
        if (tableWidth != null) {
          return SizedBox(
            width: tableWidth,
            child: child,
          );
        }

        return child;
      },
    );
  }

  /// Calculate table width based on content without using IntrinsicWidth
  /// This avoids layout thrashing from nested Intrinsic widgets
  double _calculateTableWidth() {
    // Calculate width by finding the widest content in each column
    final columnWidths = List<double>.filled(grid.columnCount, 0.0);

    // Measure each cell and distribute width to columns
    for (int rowIdx = 0; rowIdx < grid.rowCount; rowIdx++) {
      for (int colIdx = 0; colIdx < grid.columnCount; colIdx++) {
        final cell = grid.cells[rowIdx][colIdx];
        if (cell == null || !cell.isPrimary) continue;

        // Estimate cell content width (rough estimate to avoid expensive measurement)
        // Use character count as proxy for width
        final textLength = _estimateCellTextLength(cell.cellNode);
        final estimatedCellWidth = textLength * 8.0; // ~8px per character

        // Distribute width across spanned columns
        final widthPerColumn = estimatedCellWidth / cell.colspan;
        for (int i = 0; i < cell.colspan && (colIdx + i) < grid.columnCount; i++) {
          if (widthPerColumn > columnWidths[colIdx + i]) {
            columnWidths[colIdx + i] = widthPerColumn;
          }
        }
      }
    }

    // Apply minimum column width
    const double minColumnWidth = 80.0;
    for (int i = 0; i < columnWidths.length; i++) {
      if (columnWidths[i] < minColumnWidth) {
        columnWidths[i] = minColumnWidth;
      }
    }

    // Sum column widths + borders + padding
    final contentWidth = columnWidths.reduce((a, b) => a + b);
    final borderCount = grid.columnCount + 1;
    final totalPadding = grid.columnCount * (cellPadding.horizontal);

    return contentWidth + (borderCount * borderWidth) + totalPadding;
  }

  /// Estimate text length in a cell for width calculation
  int _estimateCellTextLength(TableCellNode cellNode) {
    int length = 0;
    void countText(UDTNode node) {
      if (node is TextNode) {
        length += node.text.length;
      }
      for (final child in node.children) {
        countText(child);
      }
    }
    countText(cellNode);
    return length;
  }

  List<Widget> _buildRows(bool isDark) {
    final rows = <Widget>[];
    int visibleRowIdx = 0; // Track actual visible row index for zebra striping

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

      // Determine if this is a header row (first row in thread section)
      final isHeaderRow = grid.headerRowCount > 0 && rowIdx < grid.headerRowCount;

      // Calculate background color for zebra striping
      Color? rowBackground;
      if (isHeaderRow) {
        // Header rows get special background
        rowBackground = isDark
            ? DesignTokens.darkTableHeaderBackground
            : DesignTokens.tableHeaderBackground;
      } else if (visibleRowIdx % 2 == 1) {
        // Odd rows (excluding header) get alternate background
        rowBackground = isDark
            ? DesignTokens.darkTableRowAltBackground
            : DesignTokens.tableRowAltBackground;
      }

      rows.add(Container(
        color: rowBackground,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildRowCells(rowIdx, isHeaderRow),
          ),
        ),
      ));

      visibleRowIdx++;
    }

    return rows;
  }

  List<Widget> _buildRowCells(int rowIdx, bool isHeaderRow) {
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
      widgets.add(_buildCell(cell, isHeaderRow));
      colIdx += cell.colspan;
    }

    return widgets;
  }

  Widget _buildCell(_GridCell cell, bool isHeaderRow) {
    // Calculate flex based on colspan
    final flex = cell.colspan;

    Widget content = cellBuilder(cell.cellNode);

    // Apply bold text style for header cells
    if (isHeaderRow) {
      content = DefaultTextStyle.merge(
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
        child: content,
      );
    }

    return Expanded(
      flex: flex,
      child: Container(
        padding: cellPadding,
        decoration: BoxDecoration(
          color: cell.cellNode.style.backgroundColor,
        ),
        child: content,
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
    // If maxWidth is infinity, use intrinsic width to calculate layout
    final double targetWidth = constraints.maxWidth == double.infinity
        ? computeMaxIntrinsicWidth(constraints.maxHeight)
        : constraints.maxWidth;

    _columnWidths = _calculateColumnWidths(targetWidth);
    _rowHeights = _calculateRowHeights(_columnWidths!);
    _positionCells(_columnWidths!, _rowHeights!);

    final totalWidth = _columnWidths!.fold(0.0, (a, b) => a + b);
    final totalHeight = _rowHeights!.fold(0.0, (a, b) => a + b);
    size = constraints.constrain(Size(totalWidth, totalHeight));
  }

  List<double> _calculateColumnWidths(double maxWidth) {
    // 1. Initialize array to store max intrinsic width of each column
    final List<double> colMaxContentWidths = List.filled(columnCount, 0.0);

    // 2. Measure cells to establish column widths (handles colspan)
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as TableParentData;
      final int colIndex = parentData.column;
      final int colspan = parentData.colspan;
      final double contentWidth = child.getMaxIntrinsicWidth(double.infinity);

      if (colspan == 1) {
        if (contentWidth > colMaxContentWidths[colIndex]) {
          colMaxContentWidths[colIndex] = contentWidth;
        }
      } else {
        // Distribute colspan width equally across spanned columns
        final double perCol = contentWidth / colspan;
        for (int i = 0; i < colspan; i++) {
          if (colIndex + i < columnCount) {
            if (perCol > colMaxContentWidths[colIndex + i]) {
              colMaxContentWidths[colIndex + i] = perCol;
            }
          }
        }
      }
      child = childAfter(child);
    }

    // 3. Handle infinite constraint (no expansion possible)
    if (maxWidth == double.infinity) {
      return colMaxContentWidths;
    }

    // 4. Distribute surplus width if table content < maxWidth
    double totalWidth = colMaxContentWidths.fold(0.0, (a, b) => a + b);
    if (totalWidth < maxWidth && totalWidth > 0) {
      final double surplus = maxWidth - totalWidth;
      for (int i = 0; i < columnCount; i++) {
        colMaxContentWidths[i] += surplus / columnCount;
      }
    }
    
    return colMaxContentWidths;
  }

  List<double> _calculateRowHeights(List<double> columnWidths) {
    final heights = <double>[];
    RenderBox? child = firstChild;

    for (int row = 0; row < rowCount; row++) {
      double maxRowHeight = 0;

      for (int col = 0; col < columnCount; col++) {
        if (child != null) {
          // Use tight width constraint to ensure cells fill their column width
          // This ensures consistent text wrapping behavior
          child.layout(
            BoxConstraints.tightFor(width: columnWidths[col]),
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
