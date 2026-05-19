import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

// Flexbox Demo
// Design principle: every example shows ONE property change, all other
// properties are held constant so the visual difference is unambiguous.
// Items are small + fixed-width so the "empty space" distribution is clearly
// visible. Container has a dashed border to show full available width.

class FlexboxDemo extends StatelessWidget {
  const FlexboxDemo({super.key});

  // Shared item style: dark text, light pastel fill, visible border.
  // No nested display:flex inside items — just text-align + line-height.
  static const _itemBase =
      'width:64px;height:44px;line-height:44px;text-align:center;'
      'font-weight:bold;font-size:14px;color:#1e293b;border-radius:6px;';

  static const _itemBlue =
      '${_itemBase}background:#bfdbfe;border:2px solid #3b82f6;';
  static const _itemRed =
      '${_itemBase}background:#fecaca;border:2px solid #ef4444;';

  // Container: full width, dotted border so you can see where the edges are.
  static const _ctr = 'display:flex;width:100%;box-sizing:border-box;'
      'border:2px dashed #94a3b8;border-radius:8px;padding:10px;background:#f8fafc;';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildDemoAppBar(
        context,
        title: 'Flexbox Layout',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _intro(),
          const SizedBox(height: 20),

          // ── flex-direction ────────────────────────────────────────────────
          _section('flex-direction',
              'Axis items flow along — row (→) or column (↓).'),
          _ex(
              'row',
              'Items placed left → right',
              '<div style="${_ctr}flex-direction:row;gap:8px;">'
                  '<div style="$_itemBlue">1</div>'
                  '<div style="$_itemBlue">2</div>'
                  '<div style="$_itemBlue">3</div>'
                  '</div>'),
          _ex(
              'column',
              'Items placed top ↓ bottom',
              '<div style="${_ctr}flex-direction:column;gap:8px;">'
                  '<div style="${_itemBase}background:#bfdbfe;border:2px solid #3b82f6;width:100%;text-align:center;">1</div>'
                  '<div style="${_itemBase}background:#bfdbfe;border:2px solid #3b82f6;width:100%;text-align:center;">2</div>'
                  '<div style="${_itemBase}background:#bfdbfe;border:2px solid #3b82f6;width:100%;text-align:center;">3</div>'
                  '</div>'),
          _ex(
              'row-reverse',
              'Items placed right → left (order reversed)',
              '<div style="${_ctr}flex-direction:row-reverse;gap:8px;">'
                  '<div style="$_itemBlue">1</div>'
                  '<div style="$_itemBlue">2</div>'
                  '<div style="$_itemBlue">3</div>'
                  '</div>'),

          const SizedBox(height: 20),

          // ── justify-content ───────────────────────────────────────────────
          _section(
              'justify-content',
              'How leftover space on the main axis is distributed. '
                  'Items are 64 px wide — watch where the empty space goes.'),
          _ex(
              'flex-start',
              'All items pushed to the start (left)',
              '<div style="${_ctr}justify-content:flex-start;gap:8px;">'
                  '<div style="$_itemRed">A</div>'
                  '<div style="$_itemRed">B</div>'
                  '<div style="$_itemRed">C</div>'
                  '</div>'),
          _ex(
              'flex-end',
              'All items pushed to the end (right)',
              '<div style="${_ctr}justify-content:flex-end;gap:8px;">'
                  '<div style="$_itemRed">A</div>'
                  '<div style="$_itemRed">B</div>'
                  '<div style="$_itemRed">C</div>'
                  '</div>'),
          _ex(
              'center',
              'Items centered — equal empty space on both sides',
              '<div style="${_ctr}justify-content:center;gap:8px;">'
                  '<div style="$_itemRed">A</div>'
                  '<div style="$_itemRed">B</div>'
                  '<div style="$_itemRed">C</div>'
                  '</div>'),
          _ex(
              'space-between',
              'First item at start, last at end — remaining space split between',
              '<div style="${_ctr}justify-content:space-between;">'
                  '<div style="$_itemRed">A</div>'
                  '<div style="$_itemRed">B</div>'
                  '<div style="$_itemRed">C</div>'
                  '</div>'),
          _ex(
              'space-evenly',
              'Equal gap before every item, between every item, and after the last',
              '<div style="${_ctr}justify-content:space-evenly;">'
                  '<div style="$_itemRed">A</div>'
                  '<div style="$_itemRed">B</div>'
                  '<div style="$_itemRed">C</div>'
                  '</div>'),

          const SizedBox(height: 20),

          // ── align-items ───────────────────────────────────────────────────
          _section(
              'align-items',
              'Cross-axis (vertical) alignment. '
                  'Container is 110 px tall; items have different heights.'),
          _ex(
              'flex-start',
              'Items stick to the top edge',
              '<div style="${_ctr}align-items:flex-start;gap:8px;height:110px;">'
                  '<div style="${_itemBase}background:#bbf7d0;border:2px solid #16a34a;width:64px;height:30px;line-height:26px;font-size:12px;">Short</div>'
                  '<div style="${_itemBase}background:#86efac;border:2px solid #16a34a;width:64px;height:80px;line-height:76px;font-size:12px;">Tall</div>'
                  '<div style="${_itemBase}background:#bbf7d0;border:2px solid #16a34a;width:64px;height:52px;line-height:48px;font-size:12px;">Mid</div>'
                  '</div>'),
          _ex(
              'flex-end',
              'Items stick to the bottom edge',
              '<div style="${_ctr}align-items:flex-end;gap:8px;height:110px;">'
                  '<div style="${_itemBase}background:#bbf7d0;border:2px solid #16a34a;width:64px;height:30px;line-height:26px;font-size:12px;">Short</div>'
                  '<div style="${_itemBase}background:#86efac;border:2px solid #16a34a;width:64px;height:80px;line-height:76px;font-size:12px;">Tall</div>'
                  '<div style="${_itemBase}background:#bbf7d0;border:2px solid #16a34a;width:64px;height:52px;line-height:48px;font-size:12px;">Mid</div>'
                  '</div>'),
          _ex(
              'center',
              'Items centered between top and bottom',
              '<div style="${_ctr}align-items:center;gap:8px;height:110px;">'
                  '<div style="${_itemBase}background:#bbf7d0;border:2px solid #16a34a;width:64px;height:30px;line-height:26px;font-size:12px;">Short</div>'
                  '<div style="${_itemBase}background:#86efac;border:2px solid #16a34a;width:64px;height:80px;line-height:76px;font-size:12px;">Tall</div>'
                  '<div style="${_itemBase}background:#bbf7d0;border:2px solid #16a34a;width:64px;height:52px;line-height:48px;font-size:12px;">Mid</div>'
                  '</div>'),
          _ex(
              'stretch',
              'Items stretch to fill the container height',
              '<div style="${_ctr}align-items:stretch;gap:8px;height:80px;">'
                  '<div style="${_itemBase}background:#bbf7d0;border:2px solid #16a34a;width:64px;height:auto;line-height:56px;">A</div>'
                  '<div style="${_itemBase}background:#86efac;border:2px solid #16a34a;width:64px;height:auto;line-height:56px;">B</div>'
                  '<div style="${_itemBase}background:#bbf7d0;border:2px solid #16a34a;width:64px;height:auto;line-height:56px;">C</div>'
                  '</div>'),

          const SizedBox(height: 20),

          // ── flex-grow ─────────────────────────────────────────────────────
          _section(
              'flex (grow)',
              'Proportion of the remaining space each item gets. '
                  'flex:2 gets twice the extra width of flex:1.'),
          _ex(
              'flex:1 on all — equal columns',
              'Each item gets an equal share of the full width',
              '<div style="${_ctr}gap:8px;">'
                  '<div style="flex:1;height:44px;line-height:44px;text-align:center;font-weight:bold;font-size:13px;color:#1e293b;background:#fed7aa;border:2px solid #ea580c;border-radius:6px;">flex:1</div>'
                  '<div style="flex:1;height:44px;line-height:44px;text-align:center;font-weight:bold;font-size:13px;color:#1e293b;background:#fed7aa;border:2px solid #ea580c;border-radius:6px;">flex:1</div>'
                  '<div style="flex:1;height:44px;line-height:44px;text-align:center;font-weight:bold;font-size:13px;color:#1e293b;background:#fed7aa;border:2px solid #ea580c;border-radius:6px;">flex:1</div>'
                  '</div>'),
          _ex(
              'middle is flex:2 — gets double the width',
              'Side items are flex:1, middle is flex:2 → middle is noticeably wider',
              '<div style="${_ctr}gap:8px;">'
                  '<div style="flex:1;height:44px;line-height:44px;text-align:center;font-weight:bold;font-size:13px;color:#1e293b;background:#fed7aa;border:2px solid #ea580c;border-radius:6px;">flex:1</div>'
                  '<div style="flex:2;height:44px;line-height:44px;text-align:center;font-weight:bold;font-size:13px;color:#1e293b;background:#fdba74;border:2px solid #c2410c;border-radius:6px;">flex:2</div>'
                  '<div style="flex:1;height:44px;line-height:44px;text-align:center;font-weight:bold;font-size:13px;color:#1e293b;background:#fed7aa;border:2px solid #ea580c;border-radius:6px;">flex:1</div>'
                  '</div>'),

          const SizedBox(height: 20),

          // ── flex-wrap ─────────────────────────────────────────────────────
          _section('flex-wrap',
              'What happens when items are too wide to fit on one line.'),
          _ex(
              'nowrap',
              'Items stay on one line — they may overflow the container',
              '<div style="${_ctr}flex-wrap:nowrap;gap:8px;overflow:hidden;">'
                  '<div style="$_itemBlue min-width:90px;">1</div>'
                  '<div style="$_itemBlue min-width:90px;">2</div>'
                  '<div style="$_itemBlue min-width:90px;">3</div>'
                  '<div style="$_itemBlue min-width:90px;">4</div>'
                  '<div style="$_itemBlue min-width:90px;">5</div>'
                  '</div>'),
          _ex(
              'wrap',
              'Items that don\'t fit move to the next line',
              '<div style="${_ctr}flex-wrap:wrap;gap:8px;">'
                  '<div style="$_itemBlue width:90px;">1</div>'
                  '<div style="$_itemBlue width:90px;">2</div>'
                  '<div style="$_itemBlue width:90px;">3</div>'
                  '<div style="$_itemBlue width:90px;">4</div>'
                  '<div style="$_itemBlue width:90px;">5</div>'
                  '</div>'),

          const SizedBox(height: 20),

          // ── Practical examples ────────────────────────────────────────────
          _section('Practical Patterns',
              'Real UI layouts you can build with flexbox.'),

          _ex(
              'Navigation bar',
              'Logo left + links right using justify-content:space-between',
              '<div style="display:flex;justify-content:space-between;align-items:center;'
                  'background:#1e40af;padding:12px 16px;border-radius:8px;">'
                  '<div style="font-weight:bold;font-size:17px;color:#fff;letter-spacing:-0.5px;">MyApp</div>'
                  '<div style="display:flex;gap:18px;">'
                  '<div style="color:#bfdbfe;font-size:14px;">Home</div>'
                  '<div style="color:#bfdbfe;font-size:14px;">Docs</div>'
                  '<div style="background:#3b82f6;color:white;padding:5px 14px;'
                  'border-radius:20px;font-size:13px;font-weight:bold;">Sign in</div>'
                  '</div>'
                  '</div>'),

          _ex(
              'List item',
              'Icon (flex-shrink:0) · text (flex:1 fills remaining space) · time (flex-shrink:0)',
              '<div style="display:flex;gap:12px;align-items:center;'
                  'border:1px solid #e2e8f0;padding:14px;border-radius:10px;background:#fff;">'
                  '<div style="width:44px;height:44px;background:#6366f1;border-radius:10px;flex-shrink:0;"></div>'
                  '<div style="flex:1;">'
                  '<div style="font-weight:600;color:#1e293b;font-size:15px;margin-bottom:3px;">design_v3.fig uploaded</div>'
                  '<div style="font-size:13px;color:#64748b;">by Alice · 4.2 MB</div>'
                  '</div>'
                  '<div style="font-size:12px;color:#94a3b8;flex-shrink:0;white-space:nowrap;">2m ago</div>'
                  '</div>'),

          _ex(
              'Stat cards',
              'Three flex:1 siblings share the full width equally',
              '<div style="display:flex;gap:8px;">'
                  '<div style="flex:1;background:#eff6ff;border:1px solid #bfdbfe;border-radius:10px;padding:14px 8px;text-align:center;">'
                  '<div style="font-size:22px;font-weight:bold;color:#1d4ed8;">128</div>'
                  '<div style="font-size:12px;color:#64748b;margin-top:3px;">Commits</div>'
                  '</div>'
                  '<div style="flex:1;background:#f0fdf4;border:1px solid #bbf7d0;border-radius:10px;padding:14px 8px;text-align:center;">'
                  '<div style="font-size:22px;font-weight:bold;color:#15803d;">4.9</div>'
                  '<div style="font-size:12px;color:#64748b;margin-top:3px;">Rating</div>'
                  '</div>'
                  '<div style="flex:1;background:#faf5ff;border:1px solid #e9d5ff;border-radius:10px;padding:14px 8px;text-align:center;">'
                  '<div style="font-size:22px;font-weight:bold;color:#7e22ce;">2.4k</div>'
                  '<div style="font-size:12px;color:#64748b;margin-top:3px;">Downloads</div>'
                  '</div>'
                  '</div>'),

          _ex(
              'Tag list',
              'Tags with flex-wrap:wrap — overflow to next line automatically',
              '<div style="display:flex;flex-wrap:wrap;gap:8px;">'
                  '<div style="background:#dbeafe;border:1px solid #93c5fd;color:#1e40af;padding:6px 14px;border-radius:16px;font-size:13px;font-weight:500;">Flutter</div>'
                  '<div style="background:#dcfce7;border:1px solid #86efac;color:#166534;padding:6px 14px;border-radius:16px;font-size:13px;font-weight:500;">Dart</div>'
                  '<div style="background:#fce7f3;border:1px solid #f9a8d4;color:#9d174d;padding:6px 14px;border-radius:16px;font-size:13px;font-weight:500;">HyperRender</div>'
                  '<div style="background:#ffedd5;border:1px solid #fdba74;color:#9a3412;padding:6px 14px;border-radius:16px;font-size:13px;font-weight:500;">CSS Flexbox</div>'
                  '<div style="background:#ede9fe;border:1px solid #c4b5fd;color:#5b21b6;padding:6px 14px;border-radius:16px;font-size:13px;font-weight:500;">Layout</div>'
                  '<div style="background:#e0f2fe;border:1px solid #7dd3fc;color:#075985;padding:6px 14px;border-radius:16px;font-size:13px;font-weight:500;">Responsive</div>'
                  '</div>'),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _intro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CSS Flexbox',
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3730A3))),
          SizedBox(height: 8),
          Text(
            'Each example below changes exactly ONE property so the effect is '
            'immediately visible. The dotted border marks the full width of '
            'the flex container so you can see where the empty space goes.',
            style:
                TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF1e1b4b)),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4338CA))),
          const SizedBox(height: 3),
          Text(description,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
        ],
      ),
    );
  }

  Widget _ex(String value, String effect, String html) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Text(value,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4338CA))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(effect,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF475569))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: HyperViewer(html: html),
            ),
          ],
        ),
      ),
    );
  }
}
