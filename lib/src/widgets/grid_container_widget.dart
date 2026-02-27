import 'package:flutter/material.dart';

import '../model/node.dart';

/// GridContainerWidget — renders a CSS Grid container (`display: grid`).
///
/// Supports:
/// - `grid-template-columns`: px, fr, auto, repeat(N, size)
/// - `grid-column: span N` for items
/// - `gap` / `column-gap` / `row-gap`
/// - `justify-content` along the column axis
///
/// ## Example
/// ```html
/// <div style="display:grid;grid-template-columns:1fr 2fr auto;gap:8px">
///   <div>Cell 1</div>
///   <div>Cell 2</div>
///   <div style="grid-column:span 2">Wide cell</div>
/// </div>
/// ```
class GridContainerWidget extends StatelessWidget {
  /// The UDT node for this grid container
  final UDTNode node;

  /// Pre-built children (one per grid item node)
  final List<GridItem> items;

  const GridContainerWidget({
    super.key,
    required this.node,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final style = node.style;
    final colGap = style.columnGap ?? style.gap ?? 0.0;
    final rowGap = style.rowGap ?? style.gap ?? 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final colTemplate = style.gridTemplateColumns;
        final columns = _parseColumns(colTemplate, maxWidth, colGap);
        final numCols = columns.length;

        if (numCols == 0 || items.isEmpty) {
          return const SizedBox.shrink();
        }

        // Place items into rows, respecting span
        final rows = _placeItems(items, numCols);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int r = 0; r < rows.length; r++) ...[
              if (r > 0) SizedBox(height: rowGap),
              _buildRow(rows[r], columns, colGap),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRow(
    List<_PlacedItem?> row,
    List<double> columns,
    double colGap,
  ) {
    final cells = <Widget>[];
    int col = 0;
    while (col < row.length) {
      final item = row[col];
      if (item == null) {
        // Empty cell
        cells.add(SizedBox(width: columns[col]));
        col++;
        continue;
      }
      // Calculate spanned width
      final span = item.span.clamp(1, columns.length - col);
      double cellWidth = 0;
      for (int s = 0; s < span; s++) {
        cellWidth += columns[col + s];
        if (s < span - 1) cellWidth += colGap;
      }
      cells.add(SizedBox(width: cellWidth, child: item.child));
      col += span;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < cells.length; i++) ...[
          if (i > 0) SizedBox(width: colGap),
          cells[i],
        ],
      ],
    );
  }

  /// Parse grid-template-columns into actual pixel widths.
  /// Handles: px, fr (fractional), auto, repeat(N, size)
  static List<double> _parseColumns(
    String? template,
    double maxWidth,
    double gap,
  ) {
    if (template == null || template.isEmpty) {
      return [maxWidth]; // Single-column grid fallback
    }

    // Expand repeat(N, size) → N copies of size
    template = template.replaceAllMapped(
      RegExp(r'repeat\(\s*(\d+)\s*,\s*([^)]+)\)', caseSensitive: false),
      (m) {
        final count = int.tryParse(m.group(1)!) ?? 1;
        final size = m.group(2)!.trim();
        return List.filled(count, size).join(' ');
      },
    );

    final parts = template.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return [maxWidth];

    // First pass: resolve fixed widths, collect fr fractions
    final widths = <double?>[];
    double totalFixed = 0;
    double totalFr = 0;

    for (final part in parts) {
      if (part.endsWith('px')) {
        final w = double.tryParse(part.replaceAll('px', '')) ?? 0;
        widths.add(w);
        totalFixed += w;
      } else if (part.endsWith('fr')) {
        final fr = double.tryParse(part.replaceAll('fr', '')) ?? 1;
        widths.add(null); // placeholder
        totalFr += fr;
      } else if (part == 'auto') {
        widths.add(null); // treated as 1fr
        totalFr += 1;
      } else {
        // Try plain number as px
        final w = double.tryParse(part);
        if (w != null) {
          widths.add(w);
          totalFixed += w;
        } else {
          widths.add(null); // fallback: 1fr
          totalFr += 1;
        }
      }
    }

    // Available space for fr units
    final numGaps = (widths.length - 1).clamp(0, 1000);
    final totalGap = numGaps * gap;
    final available = (maxWidth - totalFixed - totalGap).clamp(0.0, double.infinity);
    final perFr = totalFr > 0 ? available / totalFr : 0;

    // Second pass: resolve fr
    final result = <double>[];
    for (int i = 0; i < widths.length; i++) {
      final w = widths[i];
      if (w != null) {
        result.add(w);
      } else {
        // fr or auto
        final partStr = (i < parts.length) ? parts[i] : '1fr';
        double fr = 1;
        if (partStr.endsWith('fr')) {
          fr = double.tryParse(partStr.replaceAll('fr', '')) ?? 1;
        }
        result.add(perFr * fr);
      }
    }

    return result;
  }

  /// Place items into row arrays, handling column spans.
  static List<List<_PlacedItem?>> _placeItems(
    List<GridItem> items,
    int numCols,
  ) {
    final rows = <List<_PlacedItem?>>[];
    int currentRow = 0;
    int currentCol = 0;

    void ensureRow(int r) {
      while (rows.length <= r) {
        rows.add(List.filled(numCols, null));
      }
    }

    for (final item in items) {
      final span = item.span.clamp(1, numCols);

      // Find next available position
      while (true) {
        ensureRow(currentRow);
        // Check if span fits in current row
        bool fits = true;
        for (int s = 0; s < span; s++) {
          final c = currentCol + s;
          if (c >= numCols || rows[currentRow][c] != null) {
            fits = false;
            break;
          }
        }
        if (fits) break;

        currentCol++;
        if (currentCol + span > numCols) {
          currentCol = 0;
          currentRow++;
        }
      }

      ensureRow(currentRow);
      final placed = _PlacedItem(child: item.child, span: span);
      rows[currentRow][currentCol] = placed;
      // Mark spanned columns
      for (int s = 1; s < span; s++) {
        rows[currentRow][currentCol + s] = _PlacedItem(child: const SizedBox.shrink(), span: 0);
      }

      currentCol += span;
      if (currentCol >= numCols) {
        currentCol = 0;
        currentRow++;
      }
    }

    return rows;
  }
}

/// A grid item with its column span for [GridContainerWidget].
class GridItem {
  final Widget child;
  final int span;

  const GridItem({required this.child, required this.span});
}

class _PlacedItem {
  final Widget child;
  final int span; // 0 means it's a spanned cell (skip rendering)

  const _PlacedItem({required this.child, required this.span});
}

/// Detect column span from a UDT node's grid-column style.
int gridItemSpan(UDTNode node) {
  final style = node.style;
  if (style.gridColumnSpan > 1) return style.gridColumnSpan;
  if (style.gridColumnEnd > style.gridColumnStart && style.gridColumnStart > 0) {
    return style.gridColumnEnd - style.gridColumnStart;
  }
  return 1;
}
