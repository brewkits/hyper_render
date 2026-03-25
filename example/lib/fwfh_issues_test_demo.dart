import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

/// Real-world HTML rendering showcase.
/// Each card shows a realistic HTML use case and highlights where
/// flutter_widget_from_html struggles but HyperRender handles correctly.
class FWFHIssuesTestDemo extends StatelessWidget {
  const FWFHIssuesTestDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTML Rendering Showcase'),
        backgroundColor: Colors.deepOrange.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),

          // 1 — CSS class styles (travel blog)
          _card(
            icon: Icons.style,
            badgeColor: Colors.blue,
            title: 'CSS Class Styling',
            subtitle: 'Travel blog post with <style> tag rules',
            fwfhIssue: 'FWFH #1525 — <style> tag ignored',
            html: '''
<style>
  .hero-label {
    background: #1565C0;
    color: white;
    padding: 3px 10px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: bold;
    letter-spacing: 1px;
    text-transform: uppercase;
  }
  .pull-quote {
    border-left: 4px solid #FF6F00;
    background: #FFF8E1;
    padding: 12px 16px;
    margin: 12px 0;
    border-radius: 0 8px 8px 0;
    font-style: italic;
    color: #4E342E;
    font-size: 15px;
  }
  .tag {
    display: inline-block;
    background: #E3F2FD;
    color: #1565C0;
    padding: 2px 8px;
    border-radius: 10px;
    font-size: 11px;
    margin: 2px;
  }
  .highlight { background: #FFF176; padding: 1px 3px; border-radius: 2px; }
</style>

<p><span class="hero-label">✈ Destination</span></p>
<h3 style="margin:8px 0 4px 0;color:#1A237E;">Hội An Ancient Town</h3>
<p style="color:#555;font-size:13px;margin:0 0 10px 0;">Vietnam · UNESCO World Heritage Site</p>

<p>Walking through <span class="highlight">Hội An's lantern-lit streets</span> at dusk feels
like stepping back five centuries. The ancient trading port retains its remarkably intact
historic architecture — a living museum of merchant houses, temples, and assembly halls.</p>

<div class="pull-quote">
  "Every alley holds a story. Every doorway, a dynasty."
</div>

<p>The town's famous <strong>Thu Bồn River</strong> glows amber at sunset as silk lanterns
are released from wooden boats. The culinary scene alone — <em>Cao Lầu, White Rose dumplings,
Bánh Mì</em> — is worth the journey.</p>

<p>
  <span class="tag">🏮 Lanterns</span>
  <span class="tag">🍜 Street Food</span>
  <span class="tag">🛶 River Cruise</span>
  <span class="tag">🎨 Tailoring</span>
</p>
''',
          ),

          const SizedBox(height: 16),

          // 2 — Image alignment (photography showcase)
          _card(
            icon: Icons.photo_camera,
            badgeColor: Colors.indigo,
            title: 'Image Alignment',
            subtitle: 'Photography showcase — center, left, right',
            fwfhIssue: 'FWFH #1535 — margin:auto ignored',
            html: '''
<h4 style="color:#283593;margin:0 0 12px 0;">🌄 Landscape Gallery</h4>

<p style="font-size:13px;color:#555;margin:0 0 8px 0;">Centered — <code>display:block; margin:0 auto</code></p>
<img src="https://picsum.photos/280/140?random=81"
  style="display:block;margin:0 auto;border-radius:8px;border:3px solid #3F51B5;"
  alt="Mountain lake at dawn"/>
<p style="text-align:center;font-size:11px;color:#9E9E9E;margin:4px 0 14px 0;">Mountain lake at dawn</p>

<p style="font-size:13px;color:#555;margin:0 0 8px 0;">Left — <code>margin:0 auto 0 0</code></p>
<img src="https://picsum.photos/180/100?random=82"
  style="display:block;margin:0 auto 0 0;border-radius:8px;border:3px solid #4CAF50;"
  alt="Forest path"/>
<p style="font-size:11px;color:#9E9E9E;margin:4px 0 14px 0;">Forest path, morning mist</p>

<p style="font-size:13px;color:#555;margin:0 0 8px 0;">Right — <code>margin:0 0 0 auto</code></p>
<img src="https://picsum.photos/180/100?random=83"
  style="display:block;margin:0 0 0 auto;border-radius:8px;border:3px solid #FF5722;"
  alt="Coastal sunset"/>
<p style="text-align:right;font-size:11px;color:#9E9E9E;margin:4px 0 0 0;">Coastal sunset, golden hour</p>
''',
          ),

          const SizedBox(height: 16),

          // 3 — Table (phone comparison)
          _card(
            icon: Icons.table_chart,
            badgeColor: Colors.teal,
            title: 'Table Alignment & Styling',
            subtitle: 'Smartphone comparison table',
            fwfhIssue: 'FWFH #1534, #1446 — text-align in cells broken',
            html: '''
<h4 style="color:#00695C;margin:0 0 10px 0;">📱 Flagship Comparison 2024</h4>
<table style="width:100%;border-collapse:collapse;font-size:13px;">
  <thead>
    <tr style="background:#004D40;color:white;">
      <th style="padding:10px 8px;text-align:left;border-radius:6px 0 0 0;">Spec</th>
      <th style="padding:10px 8px;text-align:center;">Pixel 9 Pro</th>
      <th style="padding:10px 8px;text-align:center;">iPhone 16 Pro</th>
      <th style="padding:10px 8px;text-align:right;border-radius:0 6px 0 0;">Galaxy S25</th>
    </tr>
  </thead>
  <tbody>
    <tr style="background:#E0F2F1;">
      <td style="padding:9px 8px;text-align:left;font-weight:bold;color:#004D40;">Display</td>
      <td style="padding:9px 8px;text-align:center;">6.3" LTPO OLED</td>
      <td style="padding:9px 8px;text-align:center;">6.3" Super Retina</td>
      <td style="padding:9px 8px;text-align:right;">6.2" Dynamic AMOLED</td>
    </tr>
    <tr>
      <td style="padding:9px 8px;text-align:left;font-weight:bold;color:#004D40;">Camera</td>
      <td style="padding:9px 8px;text-align:center;">50 + 48 + 48 MP</td>
      <td style="padding:9px 8px;text-align:center;">48 + 12 + 12 MP</td>
      <td style="padding:9px 8px;text-align:right;">200 + 10 + 50 MP</td>
    </tr>
    <tr style="background:#E0F2F1;">
      <td style="padding:9px 8px;text-align:left;font-weight:bold;color:#004D40;">Battery</td>
      <td style="padding:9px 8px;text-align:center;">4,700 mAh</td>
      <td style="padding:9px 8px;text-align:center;">3,274 mAh</td>
      <td style="padding:9px 8px;text-align:right;">4,900 mAh</td>
    </tr>
    <tr>
      <td style="padding:9px 8px;text-align:left;font-weight:bold;color:#004D40;">Price</td>
      <td style="padding:9px 8px;text-align:center;color:#2E7D32;font-weight:bold;">\$999</td>
      <td style="padding:9px 8px;text-align:center;color:#1565C0;font-weight:bold;">\$1,199</td>
      <td style="padding:9px 8px;text-align:right;color:#6A1B9A;font-weight:bold;">\$1,099</td>
    </tr>
    <tr style="background:#E0F2F1;">
      <td style="padding:9px 8px;text-align:left;font-weight:bold;color:#004D40;">Rating</td>
      <td style="padding:9px 8px;text-align:center;">⭐⭐⭐⭐⭐</td>
      <td style="padding:9px 8px;text-align:center;">⭐⭐⭐⭐⭐</td>
      <td style="padding:9px 8px;text-align:right;">⭐⭐⭐⭐½</td>
    </tr>
  </tbody>
</table>
''',
          ),

          const SizedBox(height: 16),

          // 4 — Float layout (news article)
          _card(
            icon: Icons.article,
            badgeColor: Colors.red.shade700,
            title: 'Float Layout — Text Wraps Images',
            subtitle: 'Magazine-style article. FWFH can\'t do this.',
            fwfhIssue: 'FWFH #1449 — float layout not supported',
            html: '''
<article style="font-family:Georgia,serif;line-height:1.7;">
  <p style="font-size:11px;color:#999;margin:0 0 6px 0;letter-spacing:1px;text-transform:uppercase;">
    🚀 Space Exploration · June 2025
  </p>
  <h3 style="color:#B71C1C;margin:0 0 12px 0;font-size:17px;">
    NASA's Artemis III: Humanity Returns to the Moon
  </h3>

  <img src="https://picsum.photos/130/130?random=91"
    style="float:left;width:120px;height:120px;margin:2px 14px 8px 0;border-radius:8px;border:2px solid #FFCDD2;"
    alt="Astronaut on lunar surface"/>

  <p style="margin:0 0 10px 0;font-size:14px;">
    For the first time since Apollo 17 in 1972, human footprints mark the lunar regolith.
    Mission commander <strong>Anne McClain</strong> stepped onto the South Pole crater rim
    at 03:47 UTC, greeted by a sky full of stars undimmed by any atmosphere.
  </p>
  <p style="font-size:14px;margin:0 0 10px 0;">
    The crew deployed a <em>portable science station</em> and collected 12 kg of ice core
    samples from permanently shadowed craters — the first direct evidence of accessible
    water ice that could sustain a permanent lunar base.
  </p>

  <div style="clear:both;"></div>

  <img src="https://picsum.photos/130/90?random=92"
    style="float:right;width:140px;margin:2px 0 8px 14px;border-radius:8px;border:2px solid #BBDEFB;"
    alt="Lunar gateway station"/>

  <p style="font-size:14px;margin:0 0 10px 0;">
    The <strong>Lunar Gateway</strong> — orbiting the Moon at a near-rectilinear halo orbit —
    served as a staging point. Unlike the Apollo missions, Artemis III used fully
    <em>reusable hardware</em>, cutting mission cost by an estimated 60%.
  </p>
  <p style="font-size:14px;margin:0;">
    Ground controllers at Johnson Space Center watched the 9-hour surface EVA in real time,
    relayed via a new Ka-band communications satellite in lunar orbit.
    The next mission, Artemis IV, will carry a six-person crew and begin constructing
    the first permanent lunar outpost.
  </p>
  <div style="clear:both;"></div>
</article>
''',
          ),

          const SizedBox(height: 16),

          // 5 — Lists (recipe card)
          _card(
            icon: Icons.restaurant_menu,
            badgeColor: Colors.orange.shade700,
            title: 'List Styles',
            subtitle: 'Recipe card — ingredients + numbered steps',
            fwfhIssue: 'list-style-type variants (circle, square, roman)',
            html: '''
<div style="font-family:sans-serif;">
  <h3 style="color:#E65100;margin:0 0 4px 0;">🍜 Phở Bò — Beef Noodle Soup</h3>
  <p style="color:#888;font-size:12px;margin:0 0 14px 0;">Prep 30 min · Cook 4 hrs · Serves 4</p>

  <h4 style="color:#BF360C;margin:0 0 6px 0;font-size:14px;">Broth Ingredients</h4>
  <ul style="list-style-type:disc;padding-left:18px;margin:0 0 10px 0;font-size:14px;">
    <li>1.5 kg beef marrow bones, blanched</li>
    <li>500 g beef brisket</li>
    <li>1 large onion, charred</li>
    <li>5 cm fresh ginger, charred</li>
  </ul>

  <h4 style="color:#BF360C;margin:0 0 6px 0;font-size:14px;">Aromatics</h4>
  <ul style="list-style-type:circle;padding-left:18px;margin:0 0 10px 0;font-size:14px;">
    <li>3 star anise · 4 cloves</li>
    <li>1 cinnamon stick · 1 tsp coriander seeds</li>
    <li>2 tbsp fish sauce · rock sugar to taste</li>
  </ul>

  <h4 style="color:#BF360C;margin:0 0 6px 0;font-size:14px;">Toppings</h4>
  <ul style="list-style-type:square;padding-left:18px;margin:0 0 14px 0;font-size:14px;">
    <li>Bean sprouts · Thai basil · lime wedges</li>
    <li>Thinly sliced beef eye round (raw, to cook in broth)</li>
    <li>Hoisin sauce · Sriracha</li>
  </ul>

  <h4 style="color:#1B5E20;margin:0 0 6px 0;font-size:14px;">Steps</h4>
  <ol style="list-style-type:decimal;padding-left:18px;margin:0 0 10px 0;font-size:14px;">
    <li>Blanch bones in boiling water 10 min, rinse.</li>
    <li>Char onion and ginger directly over open flame until blackened.</li>
    <li>Simmer bones in 4 L water for 3 hours, skimming scum.</li>
    <li>Toast aromatics in a dry pan; add to broth with fish sauce.</li>
    <li>Strain broth; season to taste with salt and sugar.</li>
    <li>Cook rice noodles; arrange toppings; ladle hot broth over.</li>
  </ol>

  <p style="background:#FFF8E1;border-left:3px solid #FFC107;padding:8px 12px;
     margin:0;border-radius:0 6px 6px 0;font-size:13px;color:#5D4037;">
    💡 <strong>Tip:</strong> The longer you simmer the bones, the richer the broth.
    Overnight in a slow cooker gives the best results.
  </p>
</div>
''',
          ),

          const SizedBox(height: 16),

          // 6 — Complex nesting (product page)
          _card(
            icon: Icons.shopping_bag,
            badgeColor: Colors.purple.shade700,
            title: 'Complex Layout — Float + Table + Lists',
            subtitle: 'E-commerce product page layout',
            fwfhIssue: 'nested float + table inside float',
            html: '''
<div style="font-family:sans-serif;font-size:14px;">
  <!-- Product image floated left -->
  <div style="float:left;width:42%;margin-right:14px;background:#F3E5F5;
              border-radius:12px;padding:12px;text-align:center;">
    <img src="https://picsum.photos/160/160?random=77"
      style="width:100%;border-radius:8px;display:block;margin-bottom:8px;"
      alt="Product"/>
    <span style="background:#7B1FA2;color:white;padding:3px 10px;border-radius:10px;
                 font-size:11px;font-weight:bold;">NEW ARRIVAL</span>
  </div>

  <!-- Product details on the right -->
  <div>
    <h3 style="margin:0 0 4px 0;color:#4A148C;">Sony WH-1000XM6</h3>
    <p style="color:#AB47BC;font-size:18px;font-weight:bold;margin:0 0 8px 0;">\$349</p>

    <ul style="list-style-type:none;padding:0;margin:0 0 10px 0;">
      <li style="padding:3px 0;color:#555;">✅ Industry-best ANC</li>
      <li style="padding:3px 0;color:#555;">✅ 40-hour battery life</li>
      <li style="padding:3px 0;color:#555;">✅ LDAC Hi-Res Audio</li>
      <li style="padding:3px 0;color:#555;">✅ Multipoint Bluetooth 5.3</li>
    </ul>

    <!-- Specs mini-table -->
    <table style="width:100%;border-collapse:collapse;font-size:12px;">
      <tr style="background:#EDE7F6;">
        <td style="padding:5px 7px;color:#4A148C;font-weight:bold;">Driver</td>
        <td style="padding:5px 7px;text-align:right;">30 mm</td>
      </tr>
      <tr>
        <td style="padding:5px 7px;color:#4A148C;font-weight:bold;">Weight</td>
        <td style="padding:5px 7px;text-align:right;">250 g</td>
      </tr>
      <tr style="background:#EDE7F6;">
        <td style="padding:5px 7px;color:#4A148C;font-weight:bold;">Codec</td>
        <td style="padding:5px 7px;text-align:right;">LDAC / AAC / SBC</td>
      </tr>
    </table>
  </div>

  <div style="clear:both;"></div>
  <p style="margin:12px 0 0 0;color:#666;font-size:13px;">
    Rated <strong>#1</strong> in over-ear noise-cancelling headphones by
    <em>RTINGS.com</em>, <em>The Verge</em>, and <em>What Hi-Fi?</em> for 2024.
  </p>
</div>
''',
          ),

          const SizedBox(height: 24),
          _buildSummary(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepOrange.shade700, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rocket_launch, color: Colors.white, size: 36),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HTML Rendering Showcase',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Real-world content — blog, recipe, shop, news',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _badge('CSS classes'),
              _badge('Float layout'),
              _badge('Tables'),
              _badge('Image align'),
              _badge('Nesting'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required String fwfhIssue,
    required String html,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                  bottom:
                      BorderSide(color: badgeColor.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: badgeColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // FWFH comparison note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.compare_arrows,
                    size: 13, color: Colors.orange),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    fwfhIssue,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade800,
                        fontStyle: FontStyle.italic),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('✓ HyperRender',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // Rendered HTML
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: HyperViewer(
              html: html,
              mode: HyperRenderMode.sync,
              selectable: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Why HyperRender?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _advantage(Icons.view_quilt, 'Float layout',
              'Text wraps around images — like a real browser'),
          _advantage(Icons.speed, 'Performance',
              'Custom RenderObject — no extra widget overhead'),
          _advantage(Icons.select_all, 'Text selection',
              'Cross-element selection with copy/share menu'),
          _advantage(Icons.translate, 'CJK + Ruby',
              'Furigana, kinsoku, vertical text out of the box'),
          _advantage(Icons.table_chart, 'Tables',
              'Horizontal scroll + colspan/rowspan auto-layout'),
          _advantage(Icons.code, 'CSS classes',
              '<style> tag parsing with cascade & inheritance'),
        ],
      ),
    );
  }

  Widget _advantage(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(desc,
                    style: const TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
