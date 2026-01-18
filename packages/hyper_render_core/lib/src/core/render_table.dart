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

  const SmartTableWrapper({
    super.key,
    required this.tableNode,
    this.strategy = TableStrategy.horizontalScroll,
    this.minScaleFactor = 0.6,
    this.baseStyle,
    this.onLinkTap,
    this.selectable = true,
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

  const HyperTable({
    super.key,
    required this.tableNode,
    this.baseStyle,
    this.onLinkTap,
    this.borderColor = const Color(0xFFE0E0E0),
    this.borderWidth = 1.0,
    this.cellPadding = const EdgeInsets.all(8.0),
    this.selectable = true,
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

  List<double> _calculateColumnWidths(double maxWidth) {
    // Content-based width calculation
    // This implements a simplified version of W3C table layout algorithm
    // that distributes width based on content intrinsic sizes

    // 1. Initialize array to store max intrinsic width of each column
    final List<double> colMaxContentWidths = List.filled(columnCount, 0.0);

    // 2. Measure intrinsic width of each cell to find max for each column
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as TableParentData;
      final int colIndex = parentData.column;
      final int colspan = parentData.colspan;

      // Get max content width of the cell
      final double contentWidth = child.getMaxIntrinsicWidth(double.infinity);

      // If cell spans multiple columns, distribute width evenly across them
      // (Simplified approach - full W3C algorithm is more complex)
      final double widthPerCol = contentWidth / colspan;

      for (int i = 0; i < colspan; i++) {
        if (colIndex + i < columnCount) {
          if (widthPerCol > colMaxContentWidths[colIndex + i]) {
            colMaxContentWidths[colIndex + i] = widthPerCol;
          }
        }
      }

      child = childAfter(child);
    }

    // 3. Calculate total desired width
    double totalDesiredWidth = colMaxContentWidths.reduce((a, b) => a + b);

    // Ensure we don't divide by zero
    if (totalDesiredWidth == 0) totalDesiredWidth = 1;

    // 4. Distribute actual width proportionally
    final List<double> finalWidths = List.filled(columnCount, 0.0);

    // Scale factor (if total content < maxWidth, expand; if > maxWidth, shrink)
    double scale = maxWidth / totalDesiredWidth;

    for (int i = 0; i < columnCount; i++) {
      // Apply minimum width of 20px to prevent columns from becoming too narrow
      double w = colMaxContentWidths[i] * scale;
      if (w < 20.0) w = 20.0;
      finalWidths[i] = w;
    }

    // 5. Re-normalize if minimum width constraints caused overflow
    double currentTotal = finalWidths.reduce((a, b) => a + b);
    if (currentTotal > maxWidth) {
      // Shrink proportionally to fit maxWidth
      double shrinkFactor = maxWidth / currentTotal;
      for (int i = 0; i < columnCount; i++) {
        finalWidths[i] *= shrinkFactor;
      }
    }

    return finalWidths;
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
