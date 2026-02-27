import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

// =============================================================================
// SmartTableWrapper + TableStrategy Demo
//
// Demonstrates the programmatic table API:
//   • HyperTable           — raw W3C 2-pass layout widget
//   • SmartTableWrapper    — adaptive wrapper with 3 strategies
//   • TableStrategy.fitWidth        — flex-shrink all columns to fit
//   • TableStrategy.horizontalScroll — scrollable when table overflows
//   • TableStrategy.autoScale       — scale the entire table down
// =============================================================================

class SmartTableDemo extends StatefulWidget {
  const SmartTableDemo({super.key});

  @override
  State<SmartTableDemo> createState() => _SmartTableDemoState();
}

class _SmartTableDemoState extends State<SmartTableDemo>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartTableWrapper & TableStrategy'),
        backgroundColor: DemoColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.grid_on, size: 16), text: 'HyperTable'),
            Tab(icon: Icon(Icons.fit_screen, size: 16), text: 'fitWidth'),
            Tab(icon: Icon(Icons.swap_horiz, size: 16), text: 'horizontalScroll'),
            Tab(icon: Icon(Icons.zoom_out, size: 16), text: 'autoScale'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _HyperTableTab(),
          _StrategyTab(
            strategy: TableStrategy.fitWidth,
            description:
                'Columns are shrunk proportionally until the table fits '
                'the available width. Good for tables with short text.',
            color: Colors.blue,
          ),
          _StrategyTab(
            strategy: TableStrategy.horizontalScroll,
            description:
                'Table keeps natural column widths and becomes horizontally '
                'scrollable. Best for wide tables with many columns.',
            color: Colors.orange,
          ),
          _StrategyTab(
            strategy: TableStrategy.autoScale,
            description:
                'The entire table is scaled down uniformly (FittedBox). '
                'Preserves proportions but may make text small.',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — HyperTable (raw W3C 2-pass layout, no strategy wrapper)
// ─────────────────────────────────────────────────────────────────────────────

class _HyperTableTab extends StatelessWidget {
  // Builds a TableNode programmatically to show the Dart API
  TableNode _buildTable() {
    final table = TableNode();

    // Header row
    final headerRow = TableRowNode();
    for (final label in ['Library', 'Language', 'Platform', 'Performance']) {
      final cell = TableCellNode(isHeader: true);
      cell.appendChild(TextNode(label));
      headerRow.appendChild(cell);
    }
    table.appendChild(headerRow);

    // Data rows
    final data = [
      ['HyperRender', 'Dart', 'Flutter (all)', 'Excellent — 60fps'],
      ['flutter_html', 'Dart', 'Flutter (all)', 'Acceptable'],
      ['FWFH', 'Dart', 'Flutter (all)', 'Good'],
      ['WKWebView', 'Swift/ObjC', 'iOS only', 'System native'],
    ];

    for (final row in data) {
      final tableRow = TableRowNode();
      for (final cell in row) {
        final tableCell = TableCellNode();
        tableCell.appendChild(TextNode(cell));
        tableRow.appendChild(tableCell);
      }
      table.appendChild(tableRow);
    }

    return table;
  }

  // Colspan example
  TableNode _buildColspanTable() {
    final table = TableNode();

    final row1 = TableRowNode();
    final mergedHeader = TableCellNode(
      isHeader: true,
      attributes: {'colspan': '2'},
    );
    mergedHeader.appendChild(TextNode('Merged: Column A + B'));
    final header3 = TableCellNode(isHeader: true);
    header3.appendChild(TextNode('Column C'));
    row1.appendChild(mergedHeader);
    row1.appendChild(header3);
    table.appendChild(row1);

    for (int i = 1; i <= 3; i++) {
      final row = TableRowNode();
      for (final text in ['A$i', 'B$i', 'C$i']) {
        final cell = TableCellNode();
        cell.appendChild(TextNode(text));
        row.appendChild(cell);
      }
      table.appendChild(row);
    }

    return table;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'HyperTable — W3C 2-pass Layout',
            color: Colors.teal,
          ),
          const Text(
            'Built from a programmatic TableNode tree. Column widths are '
            'determined by content (min/max intrinsic widths), then surplus '
            'space is distributed proportionally.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          HyperTable(tableNode: _buildTable()),
          const SizedBox(height: 24),
          _SectionHeader(title: 'colspan / rowspan Support', color: Colors.teal),
          const Text(
            'Cells can span multiple columns (colspan) or rows (rowspan).',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          HyperTable(tableNode: _buildColspanTable()),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Dart API', color: Colors.teal),
          _CodeSnippet(code: '''final table = TableNode();

final row = TableRowNode();
final cell = TableCellNode(isHeader: true);
cell.appendChild(TextNode('Header'));
row.appendChild(cell);
table.appendChild(row);

// Render
HyperTable(tableNode: table)'''),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2-4 — SmartTableWrapper with explicit strategy
// ─────────────────────────────────────────────────────────────────────────────

class _StrategyTab extends StatelessWidget {
  final TableStrategy strategy;
  final String description;
  final Color color;

  const _StrategyTab({
    required this.strategy,
    required this.description,
    required this.color,
  });

  TableNode _buildWideTable() {
    final table = TableNode();

    // 7 columns — deliberately wide to trigger overflow
    const headers = [
      'ID', 'Name', 'Email', 'Phone', 'City', 'Country', 'Status'
    ];
    final headerRow = TableRowNode();
    for (final h in headers) {
      final cell = TableCellNode(isHeader: true);
      cell.appendChild(TextNode(h));
      headerRow.appendChild(cell);
    }
    table.appendChild(headerRow);

    final data = [
      ['001', 'Alice Nguyen', 'alice@example.com', '+84 909 123 456',
        'Ho Chi Minh', 'Vietnam', 'Active'],
      ['002', 'Bob Smith', 'bob.smith@company.org', '+1 415 555 0100',
        'San Francisco', 'USA', 'Inactive'],
      ['003', 'Clara Rossi', 'c.rossi@mail.it', '+39 06 1234567',
        'Rome', 'Italy', 'Active'],
    ];

    for (final row in data) {
      final tableRow = TableRowNode();
      for (final cell in row) {
        final tableCell = TableCellNode();
        tableCell.appendChild(TextNode(cell));
        tableRow.appendChild(tableCell);
      }
      table.appendChild(tableRow);
    }
    return table;
  }

  String get _strategyName {
    switch (strategy) {
      case TableStrategy.fitWidth:
        return 'TableStrategy.fitWidth';
      case TableStrategy.horizontalScroll:
        return 'TableStrategy.horizontalScroll';
      case TableStrategy.autoScale:
        return 'TableStrategy.autoScale';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'SmartTableWrapper — $_strategyName',
            color: color,
          ),
          const Text(
            'Same 7-column table, same data — only the strategy changes:',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          // Constrained to 320px to clearly show overflow handling
          SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '← 320px container →',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 4),
                SmartTableWrapper(
                  tableNode: _buildWideTable(),
                  strategy: strategy,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Dart API', color: color),
          _CodeSnippet(code: '''SmartTableWrapper(
  tableNode: myTableNode,       // TableNode built programmatically
  strategy: $_strategyName,
)

// Or let SmartTableWrapper auto-detect via HyperViewer:
HyperViewer(html: htmlWithTable)
// → internally uses SmartTableWrapper.horizontalScroll for wide tables'''),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Strategy Comparison', color: color),
          _strategyComparisonTable(),
        ],
      ),
    );
  }

  Widget _strategyComparisonTable() {
    const rows = [
      ['fitWidth', 'Shrinks columns', 'Short labels', 'May crush text'],
      ['horizontalScroll', 'Preserves widths', 'Many columns', 'Requires scroll'],
      ['autoScale', 'Scale whole table', 'Dense data', 'Small text'],
    ];
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: ['Strategy', 'Behaviour', 'Best for', 'Trade-off']
              .map((h) => Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(h,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ))
              .toList(),
        ),
        ...rows.map((r) => TableRow(
              decoration: BoxDecoration(
                color: r[0] == _strategyName.split('.').last
                    ? color.withValues(alpha: 0.08)
                    : null,
              ),
              children: r
                  .map((cell) => Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(cell,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  r[0] == _strategyName.split('.').last
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            )),
                      ))
                  .toList(),
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
              width: 3,
              height: 18,
              color: color,
              margin: const EdgeInsets.only(right: 8)),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeSnippet extends StatelessWidget {
  final String code;
  const _CodeSnippet({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Color(0xFFCDD6F4),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
