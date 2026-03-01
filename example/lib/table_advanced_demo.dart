import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

class TableAdvancedDemo extends StatefulWidget {
  const TableAdvancedDemo({super.key});

  @override
  State<TableAdvancedDemo> createState() => _TableAdvancedDemoState();
}

class _TableAdvancedDemoState extends State<TableAdvancedDemo>
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
        title: const Text('Advanced Table Layouts'),
        backgroundColor: DemoColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.account_tree, size: 15), text: 'Nested'),
            Tab(icon: Icon(Icons.bar_chart, size: 15), text: 'Financial'),
            Tab(icon: Icon(Icons.schedule, size: 15), text: 'Schedule'),
            Tab(icon: Icon(Icons.compare, size: 15), text: 'Comparison'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _HtmlTab(html: _nestedHtml),
          _HtmlTab(html: _financialHtml),
          _HtmlTab(html: _scheduleHtml),
          _HtmlTab(html: _comparisonHtml),
        ],
      ),
    );
  }
}

class _HtmlTab extends StatelessWidget {
  final String html;
  const _HtmlTab({required this.html});

  @override
  Widget build(BuildContext context) {
    return HyperViewer(html: html, selectable: true);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Nested tables (3 levels deep, real-world invoice pattern)
// ─────────────────────────────────────────────────────────────────────────────

const _nestedHtml = '''
<div style="font-family:-apple-system,Roboto,sans-serif;padding:16px;background:#F8F9FA;">

<h2 style="color:#1A237E;margin:0 0 4px;">Nested Table Layouts</h2>
<p style="color:#757575;font-size:13px;margin:0 0 20px;">Three levels of nesting — mimicking real HTML email / invoice patterns.</p>

<!-- LEVEL 1: outer card -->
<table width="100%" cellpadding="0" cellspacing="0"
  style="background:white;border-radius:12px;border:1px solid #E0E0E0;margin-bottom:20px;">
  <tr>
    <td style="background:#1A237E;padding:16px 20px;border-radius:12px 12px 0 0;">
      <span style="font-size:16px;font-weight:800;color:white;">📄 Invoice #INV-2026-001</span>
    </td>
  </tr>
  <tr>
    <td style="padding:20px;">

      <!-- LEVEL 2: two-column layout -->
      <table width="100%" cellpadding="0" cellspacing="8">
        <tr>
          <!-- From block -->
          <td width="48%" style="background:#F5F5F5;border-radius:8px;padding:14px;vertical-align:top;">
            <div style="font-size:10px;font-weight:700;color:#9E9E9E;letter-spacing:1px;margin-bottom:8px;">FROM</div>
            <div style="font-size:14px;font-weight:700;color:#212121;">HyperRender Studio</div>
            <div style="font-size:12px;color:#616161;line-height:1.7;">
              123 Flutter Ave<br/>
              San Francisco, CA 94105<br/>
              billing@hyperrender.dev
            </div>
          </td>
          <td width="4%"></td>
          <!-- To block -->
          <td width="48%" style="background:#E8EAF6;border-radius:8px;padding:14px;vertical-align:top;">
            <div style="font-size:10px;font-weight:700;color:#5C6BC0;letter-spacing:1px;margin-bottom:8px;">BILL TO</div>
            <div style="font-size:14px;font-weight:700;color:#212121;">Acme Corp</div>
            <div style="font-size:12px;color:#616161;line-height:1.7;">
              456 Widget Blvd<br/>
              Austin, TX 78701<br/>
              accounts@acme.example
            </div>
          </td>
        </tr>
        <tr><td colspan="3" style="height:16px;"></td></tr>
        <tr>
          <!-- Line items -->
          <td colspan="3">
            <table width="100%" cellpadding="0" cellspacing="0"
              style="border:1px solid #E0E0E0;border-radius:8px;overflow:hidden;">
              <thead>
                <tr style="background:#FAFAFA;">
                  <th style="padding:10px 14px;text-align:left;font-size:11px;font-weight:700;color:#757575;letter-spacing:0.8px;">DESCRIPTION</th>
                  <th style="padding:10px 14px;text-align:center;font-size:11px;font-weight:700;color:#757575;letter-spacing:0.8px;">QTY</th>
                  <th style="padding:10px 14px;text-align:right;font-size:11px;font-weight:700;color:#757575;letter-spacing:0.8px;">UNIT</th>
                  <th style="padding:10px 14px;text-align:right;font-size:11px;font-weight:700;color:#757575;letter-spacing:0.8px;">TOTAL</th>
                </tr>
              </thead>
              <tbody>
                <tr style="border-top:1px solid #F0F0F0;">
                  <td style="padding:12px 14px;">
                    <!-- LEVEL 3: detail cell with inner layout table -->
                    <table cellpadding="0" cellspacing="0">
                      <tr>
                        <td style="font-size:14px;font-weight:600;color:#212121;">HyperRender Pro License</td>
                      </tr>
                      <tr>
                        <td style="font-size:11px;color:#9E9E9E;padding-top:2px;">12 months · Unlimited apps · Priority support</td>
                      </tr>
                    </table>
                  </td>
                  <td style="padding:12px 14px;text-align:center;color:#424242;">1</td>
                  <td style="padding:12px 14px;text-align:right;color:#424242;">\$499</td>
                  <td style="padding:12px 14px;text-align:right;font-weight:600;color:#212121;">\$499.00</td>
                </tr>
                <tr style="border-top:1px solid #F0F0F0;background:#FAFAFA;">
                  <td style="padding:12px 14px;">
                    <table cellpadding="0" cellspacing="0">
                      <tr><td style="font-size:14px;font-weight:600;color:#212121;">Onboarding &amp; Setup</td></tr>
                      <tr><td style="font-size:11px;color:#9E9E9E;padding-top:2px;">3 hours · Remote session</td></tr>
                    </table>
                  </td>
                  <td style="padding:12px 14px;text-align:center;color:#424242;">3</td>
                  <td style="padding:12px 14px;text-align:right;color:#424242;">\$150</td>
                  <td style="padding:12px 14px;text-align:right;font-weight:600;color:#212121;">\$450.00</td>
                </tr>
                <tr style="border-top:1px solid #F0F0F0;">
                  <td style="padding:12px 14px;">
                    <table cellpadding="0" cellspacing="0">
                      <tr><td style="font-size:14px;font-weight:600;color:#212121;">Custom Widget Integration</td></tr>
                      <tr><td style="font-size:11px;color:#9E9E9E;padding-top:2px;">2 widgets · Source included</td></tr>
                    </table>
                  </td>
                  <td style="padding:12px 14px;text-align:center;color:#424242;">2</td>
                  <td style="padding:12px 14px;text-align:right;color:#424242;">\$200</td>
                  <td style="padding:12px 14px;text-align:right;font-weight:600;color:#212121;">\$400.00</td>
                </tr>
              </tbody>
              <tfoot>
                <tr style="border-top:1px solid #E0E0E0;background:#F5F5F5;">
                  <td colspan="3" style="padding:10px 14px;font-size:13px;color:#757575;">Subtotal</td>
                  <td style="padding:10px 14px;text-align:right;font-size:13px;">\$1,349.00</td>
                </tr>
                <tr style="background:#F5F5F5;">
                  <td colspan="3" style="padding:6px 14px;font-size:13px;color:#757575;">Tax (10%)</td>
                  <td style="padding:6px 14px;text-align:right;font-size:13px;">\$134.90</td>
                </tr>
                <tr style="border-top:2px solid #1A237E;background:white;">
                  <td colspan="3" style="padding:14px;font-size:16px;font-weight:800;color:#1A237E;">TOTAL DUE</td>
                  <td style="padding:14px;text-align:right;font-size:18px;font-weight:900;color:#1A237E;">\$1,483.90</td>
                </tr>
              </tfoot>
            </table>
          </td>
        </tr>
      </table>

    </td>
  </tr>
  <tr>
    <td style="background:#F5F5F5;padding:14px 20px;border-radius:0 0 12px 12px;text-align:center;">
      <span style="font-size:12px;color:#9E9E9E;">Due: March 31, 2026 · Payment: Wire transfer or card</span>
    </td>
  </tr>
</table>

<p style="font-size:11px;color:#BDBDBD;text-align:center;margin:0;">
  This layout uses 3 levels of nested &lt;table&gt; — outer card → two-column → line items → detail cells.
</p>

</div>
''';

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Financial report: colspan, rowspan, thead/tbody/tfoot
// ─────────────────────────────────────────────────────────────────────────────

const _financialHtml = '''
<div style="font-family:-apple-system,Roboto,sans-serif;padding:16px;">

<h2 style="color:#1B5E20;margin:0 0 4px;">Q1 2026 Financial Report</h2>
<p style="color:#757575;font-size:13px;margin:0 0 20px;">Multi-level grouping with colspan, rowspan, thead/tbody/tfoot.</p>

<!-- P&L table -->
<table width="100%" cellpadding="0" cellspacing="0"
  style="border-collapse:collapse;margin-bottom:28px;font-size:13px;">
  <thead>
    <tr style="background:#1B5E20;">
      <th colspan="4" style="padding:12px 16px;text-align:left;color:white;font-size:14px;font-weight:800;">
        Profit &amp; Loss Statement
      </th>
    </tr>
    <tr style="background:#E8F5E9;border-bottom:2px solid #A5D6A7;">
      <th style="padding:10px 16px;text-align:left;color:#2E7D32;font-size:11px;letter-spacing:0.8px;">CATEGORY</th>
      <th style="padding:10px 16px;text-align:right;color:#2E7D32;font-size:11px;letter-spacing:0.8px;">JAN</th>
      <th style="padding:10px 16px;text-align:right;color:#2E7D32;font-size:11px;letter-spacing:0.8px;">FEB</th>
      <th style="padding:10px 16px;text-align:right;color:#2E7D32;font-size:11px;letter-spacing:0.8px;">MAR</th>
    </tr>
  </thead>
  <tbody>
    <!-- Revenue group header -->
    <tr style="background:#F9FBE7;">
      <td colspan="4" style="padding:8px 16px;font-size:11px;font-weight:700;color:#558B2F;letter-spacing:1px;">
        REVENUE
      </td>
    </tr>
    <tr style="border-bottom:1px solid #F0F0F0;">
      <td style="padding:9px 16px 9px 28px;color:#424242;">License Sales</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$42,000</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$51,200</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$63,800</td>
    </tr>
    <tr style="border-bottom:1px solid #F0F0F0;background:#FAFAFA;">
      <td style="padding:9px 16px 9px 28px;color:#424242;">Support Contracts</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$8,500</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$9,100</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$9,800</td>
    </tr>
    <tr style="border-bottom:1px solid #F0F0F0;">
      <td style="padding:9px 16px 9px 28px;color:#424242;">Professional Services</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$12,000</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$14,500</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$18,200</td>
    </tr>
    <tr style="background:#E8F5E9;border-bottom:2px solid #A5D6A7;">
      <td style="padding:10px 16px;font-weight:700;color:#2E7D32;">Total Revenue</td>
      <td style="padding:10px 16px;text-align:right;font-weight:700;color:#2E7D32;">\$62,500</td>
      <td style="padding:10px 16px;text-align:right;font-weight:700;color:#2E7D32;">\$74,800</td>
      <td style="padding:10px 16px;text-align:right;font-weight:700;color:#2E7D32;">\$91,800</td>
    </tr>
    <!-- Expenses group -->
    <tr style="background:#FFF3E0;">
      <td colspan="4" style="padding:8px 16px;font-size:11px;font-weight:700;color:#E65100;letter-spacing:1px;">
        EXPENSES
      </td>
    </tr>
    <tr style="border-bottom:1px solid #F0F0F0;">
      <td style="padding:9px 16px 9px 28px;color:#424242;">Salaries &amp; Benefits</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$28,000</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$28,000</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$31,500</td>
    </tr>
    <tr style="border-bottom:1px solid #F0F0F0;background:#FAFAFA;">
      <td style="padding:9px 16px 9px 28px;color:#424242;">Infrastructure &amp; Cloud</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$4,200</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$4,400</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$5,100</td>
    </tr>
    <tr style="border-bottom:1px solid #F0F0F0;">
      <td style="padding:9px 16px 9px 28px;color:#424242;">Marketing</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$6,000</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$7,500</td>
      <td style="padding:9px 16px;text-align:right;color:#212121;">\$8,000</td>
    </tr>
    <tr style="background:#FBE9E7;border-bottom:2px solid #FFAB91;">
      <td style="padding:10px 16px;font-weight:700;color:#BF360C;">Total Expenses</td>
      <td style="padding:10px 16px;text-align:right;font-weight:700;color:#BF360C;">\$38,200</td>
      <td style="padding:10px 16px;text-align:right;font-weight:700;color:#BF360C;">\$39,900</td>
      <td style="padding:10px 16px;text-align:right;font-weight:700;color:#BF360C;">\$44,600</td>
    </tr>
  </tbody>
  <tfoot>
    <tr style="background:#1B5E20;">
      <td style="padding:14px 16px;font-size:15px;font-weight:800;color:white;">NET PROFIT</td>
      <td style="padding:14px 16px;text-align:right;font-size:15px;font-weight:800;color:#A5D6A7;">\$24,300</td>
      <td style="padding:14px 16px;text-align:right;font-size:15px;font-weight:800;color:#A5D6A7;">\$34,900</td>
      <td style="padding:14px 16px;text-align:right;font-size:15px;font-weight:800;color:#A5D6A7;">\$47,200</td>
    </tr>
    <tr style="background:#2E7D32;">
      <td colspan="4" style="padding:8px 16px;text-align:right;font-size:12px;color:#C8E6C9;">
        Q1 Total Net: <strong style="color:white;">\$106,400</strong> · Growth: <strong style="color:#69F0AE;">+38% YoY</strong>
      </td>
    </tr>
  </tfoot>
</table>

<!-- Balance sheet with rowspan -->
<h3 style="color:#1565C0;margin:0 0 12px;">Balance Sheet Snapshot — colspan &amp; rowspan</h3>
<table width="100%" cellpadding="0" cellspacing="0"
  style="border-collapse:collapse;font-size:13px;border:1px solid #BBDEFB;border-radius:8px;overflow:hidden;">
  <tr style="background:#1565C0;">
    <th colspan="2" style="padding:10px 14px;text-align:left;color:white;">ASSETS</th>
    <th colspan="2" style="padding:10px 14px;text-align:left;color:white;border-left:1px solid rgba(255,255,255,0.2);">LIABILITIES &amp; EQUITY</th>
  </tr>
  <tr style="background:#E3F2FD;border-bottom:1px solid #BBDEFB;">
    <td style="padding:8px 14px;color:#424242;">Current Assets</td>
    <td style="padding:8px 14px;text-align:right;font-weight:600;">\$284,000</td>
    <td style="padding:8px 14px;color:#424242;border-left:1px solid #BBDEFB;">Current Liabilities</td>
    <td style="padding:8px 14px;text-align:right;font-weight:600;">\$91,000</td>
  </tr>
  <tr style="border-bottom:1px solid #E3F2FD;">
    <td style="padding:8px 14px;color:#424242;">Fixed Assets</td>
    <td style="padding:8px 14px;text-align:right;font-weight:600;">\$156,000</td>
    <td style="padding:8px 14px;color:#424242;border-left:1px solid #BBDEFB;">Long-term Debt</td>
    <td style="padding:8px 14px;text-align:right;font-weight:600;">\$120,000</td>
  </tr>
  <tr style="border-bottom:1px solid #E3F2FD;background:#FAFAFA;">
    <td style="padding:8px 14px;color:#424242;">Intangibles</td>
    <td style="padding:8px 14px;text-align:right;font-weight:600;">\$48,000</td>
    <td style="padding:8px 14px;color:#424242;border-left:1px solid #BBDEFB;">Shareholders Equity</td>
    <td style="padding:8px 14px;text-align:right;font-weight:600;">\$277,000</td>
  </tr>
  <tr style="background:#1565C0;">
    <td style="padding:10px 14px;font-weight:800;color:white;">Total Assets</td>
    <td style="padding:10px 14px;text-align:right;font-weight:800;color:white;">\$488,000</td>
    <td style="padding:10px 14px;font-weight:800;color:white;border-left:1px solid rgba(255,255,255,0.2);">Total L &amp; E</td>
    <td style="padding:10px 14px;text-align:right;font-weight:800;color:white;">\$488,000</td>
  </tr>
</table>

</div>
''';

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Weekly schedule: complex rowspan for multi-slot events
// ─────────────────────────────────────────────────────────────────────────────

const _scheduleHtml = '''
<div style="font-family:-apple-system,Roboto,sans-serif;padding:16px;">

<h2 style="color:#4A148C;margin:0 0 4px;">Weekly Dev Schedule</h2>
<p style="color:#757575;font-size:13px;margin:0 0 16px;">rowspan for multi-hour blocks, colspan for full-day events.</p>

<table width="100%" cellpadding="0" cellspacing="0"
  style="border-collapse:collapse;font-size:12px;border:1px solid #E0E0E0;border-radius:8px;overflow:hidden;">
  <thead>
    <tr style="background:#4A148C;">
      <th style="padding:10px 8px;color:rgba(255,255,255,0.7);width:52px;font-weight:600;">TIME</th>
      <th style="padding:10px 8px;color:white;font-weight:700;">MON</th>
      <th style="padding:10px 8px;color:white;font-weight:700;">TUE</th>
      <th style="padding:10px 8px;color:white;font-weight:700;">WED</th>
      <th style="padding:10px 8px;color:white;font-weight:700;">THU</th>
      <th style="padding:10px 8px;color:white;font-weight:700;">FRI</th>
    </tr>
  </thead>
  <tbody>
    <!-- 9:00 -->
    <tr style="border-bottom:1px solid #F0F0F0;">
      <td style="padding:6px 8px;color:#9E9E9E;font-size:11px;background:#FAFAFA;text-align:center;vertical-align:top;">9:00</td>
      <td colspan="5" style="padding:6px 10px;background:#E8EAF6;color:#3949AB;font-weight:700;text-align:center;">
        🗓 All-hands standup (30 min)
      </td>
    </tr>
    <!-- 9:30 -->
    <tr style="border-bottom:1px solid #F0F0F0;">
      <td style="padding:6px 8px;color:#9E9E9E;font-size:11px;background:#FAFAFA;text-align:center;vertical-align:top;">9:30</td>
      <!-- Mon: 2-hour deep work block (rowspan=4) -->
      <td rowspan="4" style="padding:10px 8px;background:#E3F2FD;color:#0D47A1;font-weight:600;vertical-align:middle;text-align:center;border-right:1px solid #BBDEFB;">
        💻 Deep Work<br/><span style="font-size:10px;font-weight:400;">HyperRender core</span>
      </td>
      <td style="padding:6px 8px;color:#424242;">Sprint planning</td>
      <!-- Wed: 1.5h design review (rowspan=3) -->
      <td rowspan="3" style="padding:10px 8px;background:#F3E5F5;color:#6A1B9A;font-weight:600;vertical-align:middle;text-align:center;border-right:1px solid #E1BEE7;">
        🎨 Design Review<br/><span style="font-size:10px;font-weight:400;">UI/UX session</span>
      </td>
      <td style="padding:6px 8px;color:#424242;">Code review</td>
      <td style="padding:6px 8px;color:#424242;">Docs writing</td>
    </tr>
    <!-- 10:00 -->
    <tr style="border-bottom:1px solid #F0F0F0;">
      <td style="padding:6px 8px;color:#9E9E9E;font-size:11px;background:#FAFAFA;text-align:center;vertical-align:top;">10:00</td>
      <!-- Mon rowspan continues -->
      <td rowspan="2" style="padding:10px 8px;background:#E8F5E9;color:#1B5E20;font-weight:600;vertical-align:middle;text-align:center;border-right:1px solid #C8E6C9;">
        🧪 Testing<br/><span style="font-size:10px;font-weight:400;">Integration suite</span>
      </td>
      <!-- Wed rowspan continues -->
      <td style="padding:6px 8px;color:#424242;">Bug triage</td>
      <td style="padding:6px 8px;color:#424242;">Feature dev</td>
    </tr>
    <!-- 10:30 -->
    <tr style="border-bottom:1px solid #F0F0F0;">
      <td style="padding:6px 8px;color:#9E9E9E;font-size:11px;background:#FAFAFA;text-align:center;vertical-align:top;">10:30</td>
      <!-- Mon rowspan, Tue rowspan continues -->
      <!-- Wed rowspan continues -->
      <td style="padding:6px 8px;color:#424242;">Performance</td>
      <td style="padding:6px 8px;color:#424242;">Feature dev</td>
    </tr>
    <!-- 11:00 -->
    <tr style="border-bottom:1px solid #F0F0F0;">
      <td style="padding:6px 8px;color:#9E9E9E;font-size:11px;background:#FAFAFA;text-align:center;vertical-align:top;">11:00</td>
      <!-- Mon rowspan continues (last) -->
      <td style="padding:6px 8px;color:#424242;">Backlog grooming</td>
      <td style="padding:6px 8px;color:#424242;">Retro prep</td>
      <td style="padding:6px 8px;color:#424242;">PR reviews</td>
      <td style="padding:6px 8px;color:#424242;">Team 1:1</td>
    </tr>
    <!-- Lunch -->
    <tr style="border-bottom:1px solid #F0F0F0;">
      <td style="padding:6px 8px;color:#9E9E9E;font-size:11px;background:#FAFAFA;text-align:center;">12:00</td>
      <td colspan="5" style="padding:6px 10px;color:#9E9E9E;text-align:center;background:#FAFAFA;font-style:italic;">
        🍜 Lunch break
      </td>
    </tr>
    <!-- 13:00 -->
    <tr style="border-bottom:1px solid #F0F0F0;">
      <td style="padding:6px 8px;color:#9E9E9E;font-size:11px;background:#FAFAFA;text-align:center;vertical-align:top;">13:00</td>
      <td style="padding:6px 8px;color:#424242;">Client call</td>
      <!-- Tue: 2h workshop (rowspan=4) -->
      <td rowspan="4" style="padding:10px 8px;background:#FFF8E1;color:#E65100;font-weight:600;vertical-align:middle;text-align:center;border-right:1px solid #FFE082;">
        🎓 Flutter Workshop<br/><span style="font-size:10px;font-weight:400;">Live coding</span>
      </td>
      <td style="padding:6px 8px;color:#424242;">Release prep</td>
      <!-- Thu: 1h arch review (rowspan=2) -->
      <td rowspan="2" style="padding:10px 8px;background:#FCE4EC;color:#880E4F;font-weight:600;vertical-align:middle;text-align:center;border-right:1px solid #F48FB1;">
        🏛 Arch Review
      </td>
      <td style="padding:6px 8px;color:#424242;">Deploy &amp; monitor</td>
    </tr>
    <!-- 13:30 -->
    <tr style="border-bottom:1px solid #F0F0F0;">
      <td style="padding:6px 8px;color:#9E9E9E;font-size:11px;background:#FAFAFA;text-align:center;vertical-align:top;">13:30</td>
      <td style="padding:6px 8px;color:#424242;">API design</td>
      <td style="padding:6px 8px;color:#424242;">Changelog write</td>
      <!-- Thu rowspan continues -->
      <td style="padding:6px 8px;color:#424242;">Incident review</td>
    </tr>
    <!-- 14:00 -->
    <tr style="border-bottom:1px solid #F0F0F0;">
      <td style="padding:6px 8px;color:#9E9E9E;font-size:11px;background:#FAFAFA;text-align:center;vertical-align:top;">14:00</td>
      <td style="padding:6px 8px;color:#424242;">Deep work</td>
      <!-- Tue rowspan continues -->
      <td style="padding:6px 8px;color:#424242;">Deep work</td>
      <td style="padding:6px 8px;color:#424242;">Deep work</td>
      <td style="padding:6px 8px;color:#424242;">EOW wrap-up</td>
    </tr>
    <!-- 14:30 -->
    <tr>
      <td style="padding:6px 8px;color:#9E9E9E;font-size:11px;background:#FAFAFA;text-align:center;vertical-align:top;">14:30</td>
      <td style="padding:6px 8px;color:#424242;">Deep work</td>
      <!-- Tue rowspan continues (last) -->
      <td style="padding:6px 8px;color:#424242;">Deep work</td>
      <td style="padding:6px 8px;color:#424242;">Deep work</td>
      <td style="padding:6px 8px;color:#757575;font-style:italic;">🏖 Early finish</td>
    </tr>
  </tbody>
</table>

<p style="font-size:11px;color:#BDBDBD;margin:12px 0 0;text-align:center;">
  Uses rowspan for multi-hour blocks and colspan for full-team events
</p>

</div>
''';

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4 — Feature comparison matrix: multi-table + header groups
// ─────────────────────────────────────────────────────────────────────────────

const _comparisonHtml = '''
<div style="font-family:-apple-system,Roboto,sans-serif;padding:16px;">

<h2 style="color:#37474F;margin:0 0 4px;">Flutter HTML Renderer Comparison</h2>
<p style="color:#757575;font-size:13px;margin:0 0 20px;">Multi-table layout — each section is a separate table with grouped headers.</p>

<!-- Section 1: Performance -->
<div style="margin-bottom:8px;">
  <div style="background:#37474F;padding:10px 14px;border-radius:8px 8px 0 0;">
    <span style="color:white;font-weight:700;font-size:13px;">⚡ Performance</span>
  </div>
  <table width="100%" cellpadding="0" cellspacing="0"
    style="border-collapse:collapse;border:1px solid #CFD8DC;border-top:none;font-size:12px;">
    <thead>
      <tr style="background:#ECEFF1;">
        <th style="padding:8px 12px;text-align:left;color:#546E7A;font-weight:700;width:40%;">Metric</th>
        <th style="padding:8px 12px;text-align:center;color:#546E7A;font-weight:700;">flutter_html</th>
        <th style="padding:8px 12px;text-align:center;color:#546E7A;font-weight:700;">FWFH</th>
        <th style="padding:8px 12px;text-align:center;color:#546E7A;font-weight:700;">HyperRender</th>
      </tr>
    </thead>
    <tbody>
      <tr style="border-top:1px solid #ECEFF1;">
        <td style="padding:9px 12px;color:#424242;">Widget count (3K article)</td>
        <td style="padding:9px 12px;text-align:center;color:#C62828;">~600</td>
        <td style="padding:9px 12px;text-align:center;color:#EF6C00;">~500</td>
        <td style="padding:9px 12px;text-align:center;color:#2E7D32;font-weight:700;">~3–5 chunks</td>
      </tr>
      <tr style="border-top:1px solid #ECEFF1;background:#FAFAFA;">
        <td style="padding:9px 12px;color:#424242;">Parse 25K article</td>
        <td style="padding:9px 12px;text-align:center;color:#C62828;">~420ms</td>
        <td style="padding:9px 12px;text-align:center;color:#EF6C00;">~250ms</td>
        <td style="padding:9px 12px;text-align:center;color:#2E7D32;font-weight:700;">~95ms</td>
      </tr>
      <tr style="border-top:1px solid #ECEFF1;">
        <td style="padding:9px 12px;color:#424242;">RAM (same article)</td>
        <td style="padding:9px 12px;text-align:center;color:#C62828;">~28 MB</td>
        <td style="padding:9px 12px;text-align:center;color:#EF6C00;">~15 MB</td>
        <td style="padding:9px 12px;text-align:center;color:#2E7D32;font-weight:700;">~8 MB</td>
      </tr>
      <tr style="border-top:1px solid #ECEFF1;background:#FAFAFA;">
        <td style="padding:9px 12px;color:#424242;">Scroll FPS (large doc)</td>
        <td style="padding:9px 12px;text-align:center;color:#C62828;">~35 fps</td>
        <td style="padding:9px 12px;text-align:center;color:#EF6C00;">~45 fps</td>
        <td style="padding:9px 12px;text-align:center;color:#2E7D32;font-weight:700;">60 fps</td>
      </tr>
    </tbody>
  </table>
</div>

<!-- Section 2: CSS Support -->
<div style="margin-bottom:8px;">
  <div style="background:#1565C0;padding:10px 14px;border-radius:8px 8px 0 0;">
    <span style="color:white;font-weight:700;font-size:13px;">🎨 CSS Features</span>
  </div>
  <table width="100%" cellpadding="0" cellspacing="0"
    style="border-collapse:collapse;border:1px solid #BBDEFB;border-top:none;font-size:12px;">
    <thead>
      <tr style="background:#E3F2FD;">
        <th style="padding:8px 12px;text-align:left;color:#1565C0;font-weight:700;width:40%;">Feature</th>
        <th style="padding:8px 12px;text-align:center;color:#1565C0;font-weight:700;">flutter_html</th>
        <th style="padding:8px 12px;text-align:center;color:#1565C0;font-weight:700;">FWFH</th>
        <th style="padding:8px 12px;text-align:center;color:#1565C0;font-weight:700;">HyperRender</th>
      </tr>
    </thead>
    <tbody>
      <tr style="border-top:1px solid #E3F2FD;">
        <td style="padding:9px 12px;color:#424242;">float: left/right</td>
        <td style="padding:9px 12px;text-align:center;">❌</td>
        <td style="padding:9px 12px;text-align:center;">❌</td>
        <td style="padding:9px 12px;text-align:center;">✅</td>
      </tr>
      <tr style="border-top:1px solid #E3F2FD;background:#FAFAFA;">
        <td style="padding:9px 12px;color:#424242;">CSS Variables (--var)</td>
        <td style="padding:9px 12px;text-align:center;">❌</td>
        <td style="padding:9px 12px;text-align:center;">❌</td>
        <td style="padding:9px 12px;text-align:center;">✅</td>
      </tr>
      <tr style="border-top:1px solid #E3F2FD;">
        <td style="padding:9px 12px;color:#424242;">CSS calc()</td>
        <td style="padding:9px 12px;text-align:center;">❌</td>
        <td style="padding:9px 12px;text-align:center;">❌</td>
        <td style="padding:9px 12px;text-align:center;">✅</td>
      </tr>
      <tr style="border-top:1px solid #E3F2FD;background:#FAFAFA;">
        <td style="padding:9px 12px;color:#424242;">display: grid</td>
        <td style="padding:9px 12px;text-align:center;">❌</td>
        <td style="padding:9px 12px;text-align:center;">❌</td>
        <td style="padding:9px 12px;text-align:center;">⚠️ Basic</td>
      </tr>
      <tr style="border-top:1px solid #E3F2FD;">
        <td style="padding:9px 12px;color:#424242;">Flexbox</td>
        <td style="padding:9px 12px;text-align:center;">❌</td>
        <td style="padding:9px 12px;text-align:center;">⚠️ Partial</td>
        <td style="padding:9px 12px;text-align:center;">✅</td>
      </tr>
    </tbody>
  </table>
</div>

<!-- Section 3: Typography -->
<div style="margin-bottom:8px;">
  <div style="background:#6A1B9A;padding:10px 14px;border-radius:8px 8px 0 0;">
    <span style="color:white;font-weight:700;font-size:13px;">🈳 Typography &amp; Languages</span>
  </div>
  <table width="100%" cellpadding="0" cellspacing="0"
    style="border-collapse:collapse;border:1px solid #E1BEE7;border-top:none;font-size:12px;">
    <thead>
      <tr style="background:#F3E5F5;">
        <th style="padding:8px 12px;text-align:left;color:#6A1B9A;font-weight:700;width:40%;">Feature</th>
        <th style="padding:8px 12px;text-align:center;color:#6A1B9A;font-weight:700;">flutter_html</th>
        <th style="padding:8px 12px;text-align:center;color:#6A1B9A;font-weight:700;">FWFH</th>
        <th style="padding:8px 12px;text-align:center;color:#6A1B9A;font-weight:700;">HyperRender</th>
      </tr>
    </thead>
    <tbody>
      <tr style="border-top:1px solid #F3E5F5;">
        <td style="padding:9px 12px;color:#424242;">&lt;ruby&gt; / Furigana</td>
        <td style="padding:9px 12px;text-align:center;">❌ Raw text</td>
        <td style="padding:9px 12px;text-align:center;">❌</td>
        <td style="padding:9px 12px;text-align:center;">✅</td>
      </tr>
      <tr style="border-top:1px solid #F3E5F5;background:#FAFAFA;">
        <td style="padding:9px 12px;color:#424242;">RTL / BiDi text</td>
        <td style="padding:9px 12px;text-align:center;">⚠️ Partial</td>
        <td style="padding:9px 12px;text-align:center;">⚠️ Partial</td>
        <td style="padding:9px 12px;text-align:center;">✅</td>
      </tr>
      <tr style="border-top:1px solid #F3E5F5;">
        <td style="padding:9px 12px;color:#424242;">&lt;details&gt; / &lt;summary&gt;</td>
        <td style="padding:9px 12px;text-align:center;">❌</td>
        <td style="padding:9px 12px;text-align:center;">❌</td>
        <td style="padding:9px 12px;text-align:center;">✅ Interactive</td>
      </tr>
    </tbody>
  </table>
</div>

<!-- Section 4: Bundle size summary -->
<div>
  <div style="background:#004D40;padding:10px 14px;border-radius:8px 8px 0 0;">
    <span style="color:white;font-weight:700;font-size:13px;">📦 Bundle &amp; Security</span>
  </div>
  <table width="100%" cellpadding="0" cellspacing="0"
    style="border-collapse:collapse;border:1px solid #B2DFDB;border-top:none;font-size:12px;">
    <thead>
      <tr style="background:#E0F2F1;">
        <th style="padding:8px 12px;text-align:left;color:#004D40;font-weight:700;width:40%;">Property</th>
        <th style="padding:8px 12px;text-align:center;color:#004D40;font-weight:700;">flutter_html</th>
        <th style="padding:8px 12px;text-align:center;color:#004D40;font-weight:700;">FWFH</th>
        <th style="padding:8px 12px;text-align:center;color:#004D40;font-weight:700;">HyperRender</th>
      </tr>
    </thead>
    <tbody>
      <tr style="border-top:1px solid #E0F2F1;">
        <td style="padding:9px 12px;color:#424242;">Bundle size (approx)</td>
        <td style="padding:9px 12px;text-align:center;color:#424242;">~1.8 MB</td>
        <td style="padding:9px 12px;text-align:center;color:#424242;">~1.2 MB</td>
        <td style="padding:9px 12px;text-align:center;font-weight:700;color:#00695C;">~600 KB</td>
      </tr>
      <tr style="border-top:1px solid #E0F2F1;background:#FAFAFA;">
        <td style="padding:9px 12px;color:#424242;">Built-in XSS sanitizer</td>
        <td style="padding:9px 12px;text-align:center;">❌</td>
        <td style="padding:9px 12px;text-align:center;">❌</td>
        <td style="padding:9px 12px;text-align:center;">✅ Default on</td>
      </tr>
      <tr style="border-top:1px solid #E0F2F1;">
        <td style="padding:9px 12px;color:#424242;">Text selection</td>
        <td style="padding:9px 12px;text-align:center;">⚠️ Limited</td>
        <td style="padding:9px 12px;text-align:center;">❌ Crashes</td>
        <td style="padding:9px 12px;text-align:center;">✅ Crash-free</td>
      </tr>
    </tbody>
  </table>
</div>

<p style="font-size:11px;color:#BDBDBD;margin:12px 0 0;text-align:center;">
  ⚠️ Numbers are self-measured — run benchmark/performance_test.dart to reproduce
</p>

</div>
''';
