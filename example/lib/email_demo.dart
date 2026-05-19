import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

// =============================================================================
// HTML Email Renderer Demo
//
// Pain point: HTML emails in Flutter apps have always required WebView,
// which is ~20MB overhead, slow startup, and breaks native scroll/selection.
//
// HyperRender renders HTML emails natively:
//   • Table-based layouts (old-school email HTML uses nested <table>)
//   • Inline CSS (all email clients require inline styles)
//   • Images with fallback alt text
//   • Native scroll, selection, and dark mode support
//   • <1MB bundle impact vs ~20MB for WebView
// =============================================================================

class EmailDemo extends StatefulWidget {
  const EmailDemo({super.key});

  @override
  State<EmailDemo> createState() => _EmailDemoState();
}

class _EmailDemoState extends State<EmailDemo>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = DemoColors.forBrightness(
        DemoColors.primary, Theme.of(context).brightness);
    final fg = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTML Email Renderer'),
        backgroundColor: bg,
        foregroundColor: fg,
        bottom: TabBar(
          controller: _tabController,
          labelColor: fg,
          unselectedLabelColor: fg.withValues(alpha: 0.72),
          indicatorColor: fg,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.waving_hand, size: 16), text: 'Welcome'),
            Tab(icon: Icon(Icons.newspaper, size: 16), text: 'Wallpaper'),
            Tab(icon: Icon(Icons.translate, size: 16), text: '日本語'),
            Tab(icon: Icon(Icons.receipt_long, size: 16), text: 'Order'),
            Tab(icon: Icon(Icons.podcasts, size: 16), text: 'Podcast'),
            Tab(icon: Icon(Icons.code, size: 16), text: 'Why?'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EmailTab(html: _welcomeEmail, bgColor: const Color(0xFFF4F6F9)),
          _EmailTab(
              html: _wallpaperNewsletter, bgColor: const Color(0xFFF7F5F0)),
          _EmailTab(
              html: _japaneseNewsletter, bgColor: const Color(0xFFF0F4FF)),
          _EmailTab(html: _orderEmail, bgColor: const Color(0xFFF5F5F5)),
          _EmailTab(
              html: _podcastEmail,
              bgColor: const Color(0xFF0F0F1A),
              darkBg: true),
          const _WhyTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared email wrapper — renders inside a colored background like a real inbox
// ─────────────────────────────────────────────────────────────────────────────

class _EmailTab extends StatelessWidget {
  final String html;
  final Color bgColor;
  final bool darkBg;

  const _EmailTab({
    required this.html,
    required this.bgColor,
    this.darkBg = false,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: bgColor,
      child: Column(
        children: [
          // Inbox chrome bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: darkBg ? const Color(0xFF1A1A2E) : const Color(0xFFEEEEEE),
            child: Row(
              children: [
                Icon(Icons.inbox_outlined,
                    size: 14,
                    color: darkBg ? Colors.white54 : Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Inbox · Rendered natively by HyperRender',
                    style: TextStyle(
                      fontSize: 11,
                      color: darkBg ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Native · No WebView',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          // Email body — scrollable, padded like a real email client viewport
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: HyperViewer(
                html: html,
                selectable: true,
                shrinkWrap: true,
                onLinkTap: (url) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link: $url'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Welcome Email
// ─────────────────────────────────────────────────────────────────────────────

const _welcomeEmail = '''
<div style="font-family:-apple-system,'Segoe UI',Roboto,sans-serif; max-width:560px; margin:0 auto;">

  <!-- Header -->
  <div style="background:#3F51B5;
              border-radius:14px 14px 0 0; padding:32px 28px; text-align:center;">
    <div style="width:64px; height:64px; background:rgba(255,255,255,0.2);
                border-radius:16px; margin:0 auto 12px; display:flex;
                align-items:center; justify-content:center; font-size:32px;">⚡</div>
    <div style="font-size:26px; font-weight:800; color:white; letter-spacing:-0.5px;">
      Welcome to HyperShop
    </div>
    <div style="font-size:13px; color:rgba(255,255,255,0.75); margin-top:6px;">
      Your account is ready · 3 perks waiting for you
    </div>
  </div>

  <!-- Body -->
  <div style="background:white; padding:28px 28px 20px;">
    <p style="font-size:16px; color:#212121; margin:0 0 10px;">
      Hi <strong>Alex</strong>, 👋
    </p>
    <p style="font-size:14px; color:#424242; line-height:1.75; margin:0 0 20px;">
      Thanks for joining HyperShop — we're thrilled to have you on board.
      Your account is fully set up. Here's everything you unlock today:
    </p>

    <!-- 3 perk cards -->
    <div style="background:#F8F9FF; border-radius:10px; padding:14px 16px; margin-bottom:10px;">
      <div style="display:flex; align-items:center;">
        <span style="font-size:24px; padding-right:14px;">🚀</span>
        <div>
          <div style="font-size:14px; font-weight:700; color:#212121;">Free shipping on all orders</div>
          <div style="font-size:12px; color:#757575; margin-top:2px;">No minimum order, worldwide delivery</div>
        </div>
      </div>
    </div>
    <div style="background:#F8F9FF; border-radius:10px; padding:14px 16px; margin-bottom:10px;">
      <div style="display:flex; align-items:center;">
        <span style="font-size:24px; padding-right:14px;">🎁</span>
        <div>
          <div style="font-size:14px; font-weight:700; color:#212121;">20% off your first order</div>
          <div style="font-size:12px; color:#757575; margin-top:2px;">
            Use code <strong style="color:#3F51B5; background:#EEF2FF; padding:1px 6px; border-radius:4px;">WELCOME20</strong>
          </div>
        </div>
      </div>
    </div>
    <div style="background:#F8F9FF; border-radius:10px; padding:14px 16px; margin-bottom:22px;">
      <div style="display:flex; align-items:center;">
        <span style="font-size:24px; padding-right:14px;">💬</span>
        <div>
          <div style="font-size:14px; font-weight:700; color:#212121;">24/7 live chat support</div>
          <div style="font-size:12px; color:#757575; margin-top:2px;">Average response time under 2 minutes</div>
        </div>
      </div>
    </div>

    <!-- CTA -->
    <div style="text-align:center; margin-bottom:24px;">
      <a href="https://hypershop.example.com/start"
         style="display:inline-block; background:#3F51B5;
                color:white; font-size:15px; font-weight:700; padding:14px 40px;
                border-radius:10px; text-decoration:none; letter-spacing:0.2px;">
        Start Shopping →
      </a>
    </div>

    <hr style="border:none; border-top:1px solid #F0F0F0; margin:0 0 16px;"/>

    <!-- Social proof -->
    <div style="text-align:center;">
      <div style="font-size:22px; font-weight:800; color:#212121;">4.9 ★</div>
      <div style="font-size:12px; color:#9E9E9E; margin-top:2px;">
        Rated by 28,000+ customers on the App Store
      </div>
    </div>
  </div>

  <!-- Footer -->
  <div style="background:#F8F8F8; border-radius:0 0 14px 14px; padding:16px 28px;
              text-align:center; border-top:1px solid #EEEEEE;">
    <p style="font-size:11px; color:#BDBDBD; margin:0 0 6px;">
      HyperShop Inc. · 123 Commerce St · San Francisco, CA 94103
    </p>
    <p style="font-size:11px; margin:0;">
      <a href="#" style="color:#3F51B5; text-decoration:none;">Unsubscribe</a>
      <span style="color:#E0E0E0;"> · </span>
      <a href="#" style="color:#3F51B5; text-decoration:none;">Privacy Policy</a>
      <span style="color:#E0E0E0;"> · </span>
      <a href="#" style="color:#3F51B5; text-decoration:none;">View in browser</a>
    </p>
  </div>

</div>
''';

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Wallpaper-style Design & Architecture Newsletter (English)
// ─────────────────────────────────────────────────────────────────────────────

const _wallpaperNewsletter = '''
<div style="font-family:'Georgia','Times New Roman',serif; max-width:560px; margin:0 auto;
            color:#1A1A1A; background:#FFFDF8;">

  <!-- Masthead -->
  <div style="padding:24px 24px 0; border-bottom:3px solid #1A1A1A;">
    <div style="font-family:-apple-system,sans-serif; font-size:10px; font-weight:700;
                letter-spacing:3px; color:#888; margin-bottom:10px;">
      DESIGN · ARCHITECTURE · CULTURE
    </div>
    <div style="font-size:36px; font-weight:900; letter-spacing:-1.5px; line-height:1;
                font-family:-apple-system,sans-serif; color:#1A1A1A;">
      SURFACES
    </div>
    <div style="display:flex; justify-content:space-between; margin-top:10px;
                padding-bottom:14px; font-size:11px; color:#888;
                font-family:-apple-system,sans-serif;">
      <span>No. 024 · March 2026</span>
      <span>Free · Monthly</span>
    </div>
  </div>

  <!-- Hero story -->
  <div style="padding:24px 24px 0;">
    <div style="font-size:10px; font-weight:700; letter-spacing:2px; color:#888;
                font-family:-apple-system,sans-serif; margin-bottom:10px;">
      COVER STORY
    </div>
    <h1 style="font-size:28px; font-weight:700; line-height:1.25; margin:0 0 14px;
               letter-spacing:-0.5px; color:#1A1A1A;">
      The Quiet Revolution: How Brutalist UI Is Making Its Comeback
    </h1>
    <img src="https://picsum.photos/seed/brutalism/520/260"
         style="width:100%; border-radius:4px; display:block; margin-bottom:14px;" />
    <p style="font-size:15px; line-height:1.8; color:#333; margin:0 0 12px;">
      A new wave of digital designers is rejecting the soft gradients and rounded corners
      of the 2010s in favour of something rawer — heavy borders, monochrome palettes,
      and layouts that feel <em>deliberately unpolished</em>. The aesthetic has a name:
      <strong>Neo-Brutalism</strong>, and it is appearing everywhere from banking apps
      to editorial websites.
    </p>
    <p style="font-size:15px; line-height:1.8; color:#333; margin:0 0 16px;">
      "We were drowning in frosted glass," says Berlin-based creative director
      Lena Hoffmann. "At some point the sameness became its own kind of ugliness.
      Brutalism forces the designer to find beauty in structure, not decoration."
    </p>
    <a href="#" style="font-family:-apple-system,sans-serif; font-size:12px;
                       font-weight:700; color:#1A1A1A; letter-spacing:1px;
                       text-decoration:none; border-bottom:2px solid #1A1A1A;">
      READ FULL STORY →
    </a>
  </div>

  <!-- Divider rule -->
  <div style="margin:24px; border-top:1px solid #E0DDD6;"></div>

  <!-- Two-column features -->
  <div style="padding:0 24px;">
    <div style="font-size:10px; font-weight:700; letter-spacing:2px; color:#888;
                font-family:-apple-system,sans-serif; margin-bottom:16px;">
      THIS MONTH
    </div>
    <table width="100%" cellpadding="0" cellspacing="0">
      <tr>
        <td width="48%" style="vertical-align:top; padding-right:14px;
                               border-right:1px solid #E0DDD6;">
          <div style="font-size:10px; font-weight:700; letter-spacing:1.5px;
                      color:#888; margin-bottom:8px; font-family:-apple-system,sans-serif;">
            OBJECT
          </div>
          <img src="https://picsum.photos/seed/lamp/220/160"
               style="width:100%; border-radius:3px; margin-bottom:10px;" />
          <div style="font-size:13px; font-weight:700; line-height:1.4;
                      margin-bottom:6px; color:#1A1A1A;">
            The Flos IC Floor Lamp at 60: Still the Benchmark
          </div>
          <div style="font-size:12px; color:#666; line-height:1.6;">
            Achille Castiglioni's 1962 ball-joint floor lamp turns sixty
            this year. We revisit why it has never been bettered.
          </div>
        </td>
        <td width="4%"></td>
        <td width="48%" style="vertical-align:top; padding-left:14px;">
          <div style="font-size:10px; font-weight:700; letter-spacing:1.5px;
                      color:#888; margin-bottom:8px; font-family:-apple-system,sans-serif;">
            ARCHITECTURE
          </div>
          <img src="https://picsum.photos/seed/arch2026/220/160"
               style="width:100%; border-radius:3px; margin-bottom:10px;" />
          <div style="font-size:13px; font-weight:700; line-height:1.4;
                      margin-bottom:6px; color:#1A1A1A;">
            Kengo Kuma's Woven Pavilion Opens in Kyoto
          </div>
          <div style="font-size:12px; color:#666; line-height:1.6;">
            The Japanese architect's latest work dissolves the boundary
            between roof and forest canopy using cedar lattice.
          </div>
        </td>
      </tr>
    </table>
  </div>

  <!-- Divider -->
  <div style="margin:24px; border-top:1px solid #E0DDD6;"></div>

  <!-- What we're reading -->
  <div style="padding:0 24px 24px;">
    <div style="font-size:10px; font-weight:700; letter-spacing:2px; color:#888;
                font-family:-apple-system,sans-serif; margin-bottom:14px;">
      ON THE SHELF
    </div>
    <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:12px;">
      <tr>
        <td width="52" style="vertical-align:top; padding-right:12px;">
          <div style="width:44px; height:60px; background:#1A1A1A; border-radius:3px;
                      display:flex; align-items:center; justify-content:center;
                      font-size:8px; color:white; text-align:center; font-family:-apple-system,sans-serif;
                      font-weight:700; letter-spacing:0.5px; padding:4px;">
            ATLAS
          </div>
        </td>
        <td style="vertical-align:top;">
          <div style="font-size:13px; font-weight:700; color:#1A1A1A; margin-bottom:3px;">
            Atlas of Brutalist Architecture
          </div>
          <div style="font-size:11px; color:#888; font-family:-apple-system,sans-serif;
                      margin-bottom:5px;">
            Phaidon Press · 640 pages
          </div>
          <div style="font-size:12px; color:#555; line-height:1.6;">
            The definitive survey of 879 Brutalist buildings across 102 countries.
            Essential for anyone serious about concrete aesthetics.
          </div>
        </td>
      </tr>
    </table>
    <table width="100%" cellpadding="0" cellspacing="0">
      <tr>
        <td width="52" style="vertical-align:top; padding-right:12px;">
          <div style="width:44px; height:60px; background:#B71C1C; border-radius:3px;
                      display:flex; align-items:center; justify-content:center;
                      font-size:8px; color:white; text-align:center; font-family:-apple-system,sans-serif;
                      font-weight:700; letter-spacing:0.5px; padding:4px;">
            TYPE
          </div>
        </td>
        <td style="vertical-align:top;">
          <div style="font-size:13px; font-weight:700; color:#1A1A1A; margin-bottom:3px;">
            Thinking with Type
          </div>
          <div style="font-size:11px; color:#888; font-family:-apple-system,sans-serif;
                      margin-bottom:5px;">
            Ellen Lupton · Princeton Architectural Press
          </div>
          <div style="font-size:12px; color:#555; line-height:1.6;">
            Now in its third edition, Lupton's guide to typography remains
            the clearest introduction to type as a design medium.
          </div>
        </td>
      </tr>
    </table>
  </div>

  <!-- Footer -->
  <div style="background:#1A1A1A; padding:20px 24px; border-radius:0 0 4px 4px; text-align:center;">
    <div style="font-family:-apple-system,sans-serif; font-size:9px; font-weight:700;
                letter-spacing:3px; color:#555; margin-bottom:8px;">
      SURFACES NEWSLETTER
    </div>
    <p style="font-size:11px; color:#666; margin:0 0 8px; font-family:-apple-system,sans-serif;">
      You are receiving this because you subscribed at surfaces.design
    </p>
    <p style="font-size:11px; margin:0; font-family:-apple-system,sans-serif;">
      <a href="#" style="color:#AAA; text-decoration:none;">Unsubscribe</a>
      <span style="color:#444;"> · </span>
      <a href="#" style="color:#AAA; text-decoration:none;">Web version</a>
      <span style="color:#444;"> · </span>
      <a href="#" style="color:#AAA; text-decoration:none;">Archive</a>
    </p>
  </div>

</div>
''';

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Japanese Tech Newsletter (日本語)
// ─────────────────────────────────────────────────────────────────────────────

const _japaneseNewsletter = '''
<div style="font-family:-apple-system,'Hiragino Sans','Yu Gothic',sans-serif;
            max-width:560px; margin:0 auto; color:#1A1A1A;">

  <!-- Masthead -->
  <div style="background:#0D47A1; padding:20px 24px 16px; border-radius:10px 10px 0 0;">
    <div style="font-size:10px; font-weight:700; letter-spacing:3px; color:rgba(255,255,255,0.6);
                margin-bottom:8px;">
      テクノロジー · デザイン · プロダクト
    </div>
    <div style="font-size:28px; font-weight:900; color:white; letter-spacing:-0.5px;
                line-height:1.1;">
      テックノート
    </div>
    <div style="font-size:11px; color:rgba(255,255,255,0.6); margin-top:6px;
                display:flex; justify-content:space-between;">
      <span>Vol. 38 · 2026年3月号</span>
      <span>読者数 12,400人</span>
    </div>
  </div>

  <!-- Editor note -->
  <div style="background:#E3F2FD; padding:14px 20px; border-left:4px solid #1565C0;
              font-size:13px; color:#0D47A1; line-height:1.8;">
    <strong>編集後記：</strong>今号では AI 開発ツールの最前線と、Flutter を使ったリッチコンテンツレンダリングの革新について深掘りします。
    AI がコーディングを変え、Flutter がアプリ内 HTML 表示を変えようとしています。
  </div>

  <!-- Hero story -->
  <div style="background:white; padding:22px 24px;">
    <div style="font-size:10px; font-weight:700; letter-spacing:2px; color:#1565C0;
                margin-bottom:10px;">
      特集記事
    </div>
    <h1 style="font-size:22px; font-weight:800; line-height:1.4; margin:0 0 12px;
               color:#1A1A1A; letter-spacing:-0.3px;">
      Flutter × ネイティブレンダリング：<br/>WebView なしで HTML を美しく表示する方法
    </h1>
    <img src="https://picsum.photos/seed/flutter-jp/520/220"
         style="width:100%; border-radius:8px; margin-bottom:14px;" />
    <p style="font-size:14px; line-height:1.9; color:#333; margin:0 0 12px;">
      Flutter アプリ内で HTML コンテンツ（メール、ニュース記事、マニュアルなど）を表示する際、
      従来の選択肢は <code style="background:#EEF2FF; color:#3F51B5; padding:1px 5px;
      border-radius:3px; font-size:12px;">webview_flutter</code> 一択でした。
      しかし WebView は起動が遅く、バンドルサイズが約 20MB 増加し、
      ネイティブスクロールの物理演算が失われるという問題があります。
    </p>
    <p style="font-size:14px; line-height:1.9; color:#333; margin:0 0 16px;">
      新世代のライブラリ <strong>HyperRender</strong> は、Flutter の <code style="background:#EEF2FF;
      color:#3F51B5; padding:1px 5px; border-radius:3px; font-size:12px;">RenderObject</code>
      レイヤーに直接書き込むことで、WebView なしで CSS フォートレイアウト・テーブル・
      ルビアノテーション・テキスト選択を完全実現しました。
    </p>

    <!-- Key metrics -->
    <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:16px;">
      <tr>
        <td style="background:#E3F2FD; border-radius:8px; padding:12px 14px;
                   text-align:center; width:30%;">
          <div style="font-size:22px; font-weight:900; color:#0D47A1;">600KB</div>
          <div style="font-size:11px; color:#1565C0; margin-top:2px;">バンドルサイズ</div>
        </td>
        <td width="3%"></td>
        <td style="background:#E8F5E9; border-radius:8px; padding:12px 14px;
                   text-align:center; width:30%;">
          <div style="font-size:22px; font-weight:900; color:#1B5E20;">60fps</div>
          <div style="font-size:11px; color:#2E7D32; margin-top:2px;">スクロール</div>
        </td>
        <td width="3%"></td>
        <td style="background:#FFF3E0; border-radius:8px; padding:12px 14px;
                   text-align:center; width:30%;">
          <div style="font-size:22px; font-weight:900; color:#E65100;">&lt;16ms</div>
          <div style="font-size:11px; color:#BF360C; margin-top:2px;">初回描画</div>
        </td>
      </tr>
    </table>

    <a href="#" style="display:inline-block; background:#0D47A1; color:white;
                       font-size:13px; font-weight:700; padding:10px 22px;
                       border-radius:8px; text-decoration:none;">
      詳細を読む →
    </a>
  </div>

  <div style="height:1px; background:#E8EDF4; margin:0 24px;"></div>

  <!-- Short reads -->
  <div style="background:white; padding:20px 24px;">
    <div style="font-size:10px; font-weight:700; letter-spacing:2px; color:#888;
                margin-bottom:14px;">
      ショートリード
    </div>
    <table width="100%" cellpadding="0" cellspacing="0">
      <tr>
        <td style="padding:12px 0; border-bottom:1px solid #F0F0F0; vertical-align:top;">
          <div style="display:flex; align-items:flex-start;">
            <span style="font-size:20px; padding-right:12px; margin-top:1px;">🤖</span>
            <div>
              <div style="font-size:13px; font-weight:700; color:#1A1A1A; line-height:1.4;
                          margin-bottom:4px;">
                GitHub Copilot が Dart / Flutter に完全対応
              </div>
              <div style="font-size:12px; color:#666; line-height:1.6;">
                ウィジェットツリーの補完精度が大幅向上。State 管理パターンも自動提案。
              </div>
              <a href="#" style="font-size:11px; color:#1565C0; font-weight:600;
                                 text-decoration:none; margin-top:4px; display:inline-block;">
                3分で読む →
              </a>
            </div>
          </div>
        </td>
      </tr>
      <tr>
        <td style="padding:12px 0; border-bottom:1px solid #F0F0F0; vertical-align:top;">
          <div style="display:flex; align-items:flex-start;">
            <span style="font-size:20px; padding-right:12px; margin-top:1px;">📱</span>
            <div>
              <div style="font-size:13px; font-weight:700; color:#1A1A1A; line-height:1.4;
                          margin-bottom:4px;">
                Impeller が iOS・Android 両対応に — Skia は完全引退へ
              </div>
              <div style="font-size:12px; color:#666; line-height:1.6;">
                Flutter 3.20 で Impeller がデフォルトエンジンとなり、
                シェーダーコンパイルジャンクが解消される見込みです。
              </div>
              <a href="#" style="font-size:11px; color:#1565C0; font-weight:600;
                                 text-decoration:none; margin-top:4px; display:inline-block;">
                5分で読む →
              </a>
            </div>
          </div>
        </td>
      </tr>
      <tr>
        <td style="padding:12px 0; vertical-align:top;">
          <div style="display:flex; align-items:flex-start;">
            <span style="font-size:20px; padding-right:12px; margin-top:1px;">🎯</span>
            <div>
              <div style="font-size:13px; font-weight:700; color:#1A1A1A; line-height:1.4;
                          margin-bottom:4px;">
                Riverpod 3.0 正式リリース — Provider は完全移行推奨
              </div>
              <div style="font-size:12px; color:#666; line-height:1.6;">
                コード生成ベースの新 API、IDE 補完の強化、
                テスト時の依存注入が大幅に簡素化されました。
              </div>
              <a href="#" style="font-size:11px; color:#1565C0; font-weight:600;
                                 text-decoration:none; margin-top:4px; display:inline-block;">
                7分で読む →
              </a>
            </div>
          </div>
        </td>
      </tr>
    </table>
  </div>

  <!-- Job board -->
  <div style="background:#F8F9FF; padding:18px 24px; margin-top:1px;">
    <div style="font-size:10px; font-weight:700; letter-spacing:2px; color:#888;
                margin-bottom:12px;">
      求人情報
    </div>
    <div style="background:white; border:1px solid #E0E7FF; border-radius:8px;
                padding:14px 16px; margin-bottom:8px;">
      <div style="font-size:13px; font-weight:700; color:#1A1A1A;">
        シニア Flutter エンジニア — サイバーエージェント
      </div>
      <div style="font-size:11px; color:#888; margin:4px 0;">
        東京（ハイブリッド）· 年収 900万〜1,400万円
      </div>
      <a href="#" style="font-size:11px; color:#1565C0; font-weight:600;
                         text-decoration:none;">応募する →</a>
    </div>
    <div style="background:white; border:1px solid #E0E7FF; border-radius:8px;
                padding:14px 16px;">
      <div style="font-size:13px; font-weight:700; color:#1A1A1A;">
        Flutter / Dart テックリード — LINE Corporation
      </div>
      <div style="font-size:11px; color:#888; margin:4px 0;">
        東京・大阪（フルリモート可）· 年収 1,000万〜1,600万円
      </div>
      <a href="#" style="font-size:11px; color:#1565C0; font-weight:600;
                         text-decoration:none;">応募する →</a>
    </div>
  </div>

  <!-- Footer -->
  <div style="background:#0D47A1; padding:18px 24px; border-radius:0 0 10px 10px;
              text-align:center;">
    <p style="font-size:11px; color:rgba(255,255,255,0.5); margin:0 0 8px;
              font-family:-apple-system,sans-serif;">
      テックノートは毎月第一月曜日に配信されます
    </p>
    <p style="font-size:11px; margin:0; font-family:-apple-system,sans-serif;">
      <a href="#" style="color:rgba(255,255,255,0.6); text-decoration:none;">配信停止</a>
      <span style="color:rgba(255,255,255,0.25);"> · </span>
      <a href="#" style="color:rgba(255,255,255,0.6); text-decoration:none;">設定変更</a>
      <span style="color:rgba(255,255,255,0.25);"> · </span>
      <a href="#" style="color:rgba(255,255,255,0.6); text-decoration:none;">ブラウザで見る</a>
    </p>
  </div>

</div>
''';

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4 — Order Confirmation
// ─────────────────────────────────────────────────────────────────────────────

const _orderEmail = '''
<div style="font-family:-apple-system,'Segoe UI',Roboto,sans-serif;
            max-width:560px; margin:0 auto; color:#1A1A1A;">

  <!-- Header -->
  <div style="background:#00695C;
              border-radius:14px 14px 0 0; padding:28px 28px 24px; text-align:center;">
    <div style="width:60px; height:60px; background:rgba(255,255,255,0.2);
                border-radius:50%; margin:0 auto 12px; font-size:30px;
                display:flex; align-items:center; justify-content:center;">✅</div>
    <div style="font-size:22px; font-weight:800; color:white;">Order Confirmed!</div>
    <div style="font-size:13px; color:rgba(255,255,255,0.75); margin-top:4px;">
      #HR-2026-78412 · Feb 28, 2026 · 14:32 UTC
    </div>
  </div>

  <!-- Body -->
  <div style="background:white; padding:24px 24px 20px;">
    <p style="font-size:14px; color:#424242; line-height:1.75; margin:0 0 20px;">
      Hi <strong>Alex</strong> 👋 — your order has been confirmed and will
      be ready for download within <strong style="color:#00897B;">5 minutes</strong>.
      A receipt has also been sent to <strong>alex@example.com</strong>.
    </p>

    <!-- Order items -->
    <div style="border:1px solid #E8F5E9; border-radius:10px; overflow:hidden; margin-bottom:20px;">
      <div style="background:#E8F5E9; padding:10px 16px; font-size:11px; font-weight:700;
                  color:#1B5E20; letter-spacing:1px;">
        ORDER SUMMARY
      </div>
      <!-- Item 1 -->
      <div style="padding:14px 16px; border-bottom:1px solid #F5F5F5;">
        <div style="display:flex; justify-content:space-between; align-items:flex-start;">
          <div>
            <div style="font-size:14px; font-weight:600; color:#212121;">Flutter Pro Bundle</div>
            <div style="font-size:11px; color:#9E9E9E; margin-top:2px;">Digital download · Single dev licence</div>
          </div>
          <div style="font-size:14px; font-weight:600; color:#212121; margin-left:12px; white-space:nowrap;">
            \$79.00
          </div>
        </div>
      </div>
      <!-- Item 2 -->
      <div style="padding:14px 16px; border-bottom:1px solid #F5F5F5; background:#FAFAFA;">
        <div style="display:flex; justify-content:space-between; align-items:flex-start;">
          <div>
            <div style="font-size:14px; font-weight:600; color:#212121;">HyperRender Pro Licence</div>
            <div style="font-size:11px; color:#9E9E9E; margin-top:2px;">12 months · Unlimited apps</div>
          </div>
          <div style="font-size:14px; font-weight:600; color:#212121; margin-left:12px; white-space:nowrap;">
            \$49.00
          </div>
        </div>
      </div>
      <!-- Item 3 -->
      <div style="padding:14px 16px; border-bottom:1px solid #EEEEEE; background:#E8F5E9;">
        <div style="display:flex; justify-content:space-between;">
          <span style="font-size:13px; color:#555;">Discount (WELCOME20)</span>
          <span style="font-size:13px; color:#00897B; font-weight:600;">−\$25.60</span>
        </div>
      </div>
      <div style="padding:14px 16px; border-bottom:1px solid #EEEEEE; background:#E8F5E9;">
        <div style="display:flex; justify-content:space-between;">
          <span style="font-size:13px; color:#555;">Tax (8.5%)</span>
          <span style="font-size:13px; color:#555;">\$8.69</span>
        </div>
      </div>
      <!-- Total -->
      <div style="padding:14px 16px; background:#E8F5E9;">
        <div style="display:flex; justify-content:space-between; align-items:center;">
          <span style="font-size:16px; font-weight:800; color:#1B5E20;">Total Charged</span>
          <span style="font-size:18px; font-weight:800; color:#00897B;">\$111.09</span>
        </div>
        <div style="font-size:11px; color:#555; margin-top:3px;">Visa ···· 4242 · Charged successfully</div>
      </div>
    </div>

    <!-- Shipping + Payment row -->
    <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:22px;">
      <tr>
        <td width="48%" style="vertical-align:top; background:#E8F5E9;
                               border-radius:8px; padding:14px;">
          <div style="font-size:10px; font-weight:700; color:#2E7D32;
                      letter-spacing:1px; margin-bottom:6px;">BILLING TO</div>
          <div style="font-size:13px; color:#333; line-height:1.7;">
            Alex Johnson<br/>
            456 Developer Lane<br/>
            Austin, TX 78701<br/>
            United States
          </div>
        </td>
        <td width="4%"></td>
        <td width="48%" style="vertical-align:top; background:#E3F2FD;
                               border-radius:8px; padding:14px;">
          <div style="font-size:10px; font-weight:700; color:#1565C0;
                      letter-spacing:1px; margin-bottom:6px;">DELIVERY</div>
          <div style="font-size:13px; color:#333; line-height:1.7;">
            Digital licence keys<br/>
            Sent to <strong>alex@example.com</strong><br/>
            <span style="color:#00897B;">✓ Delivered instantly</span>
          </div>
        </td>
      </tr>
    </table>

    <!-- CTA -->
    <div style="text-align:center;">
      <a href="#" style="display:inline-block; background:#00695C;
                         color:white; font-size:14px; font-weight:700; padding:13px 36px;
                         border-radius:10px; text-decoration:none;">
        Download Your Licences →
      </a>
    </div>
  </div>

  <!-- Footer -->
  <div style="background:#F5F5F5; border-radius:0 0 14px 14px; border-top:1px solid #E0E0E0;
              padding:14px 28px; text-align:center;">
    <p style="font-size:11px; color:#BDBDBD; margin:0;">
      Questions? <a href="#" style="color:#00897B;">support@hypershop.example.com</a>
    </p>
  </div>

</div>
''';

// ─────────────────────────────────────────────────────────────────────────────
// Tab 5 — Podcast Episode Digest
// ─────────────────────────────────────────────────────────────────────────────

const _podcastEmail = '''
<div style="font-family:-apple-system,'Segoe UI',Roboto,sans-serif;
            max-width:560px; margin:0 auto; background:#0F0F1A; color:#E8E8F0;">

  <!-- Top bar -->
  <div style="padding:14px 20px; display:flex; align-items:center;
              border-bottom:1px solid rgba(255,255,255,0.08);">
    <div style="width:8px; height:8px; background:#1DB954; border-radius:50%;
                margin-right:8px;"></div>
    <span style="font-size:11px; color:rgba(255,255,255,0.4); letter-spacing:1.5px;
                 font-weight:700;">NEW EPISODE</span>
    <span style="margin-left:auto; font-size:11px; color:rgba(255,255,255,0.3);">
      Friday Drop · Mar 14, 2026
    </span>
  </div>

  <!-- Show header -->
  <div style="padding:28px 20px 20px;">
    <div style="display:flex; align-items:flex-start; margin-bottom:20px;">
      <!-- Artwork -->
      <div style="width:88px; height:88px; border-radius:14px; overflow:hidden;
                  flex-shrink:0; margin-right:16px; background:#1DB954;">
        <img src="https://picsum.photos/seed/podcast-art/88/88"
             style="width:88px; height:88px; display:block;" />
      </div>
      <div>
        <div style="font-size:11px; font-weight:700; letter-spacing:2px;
                    color:#1DB954; margin-bottom:6px;">
          FLUTTER UNCENSORED
        </div>
        <h1 style="font-size:20px; font-weight:800; line-height:1.3; margin:0 0 6px;
                   color:white; letter-spacing:-0.3px;">
          Ep. 112 — Native HTML Rendering: Is the WebView Era Finally Over?
        </h1>
        <div style="font-size:12px; color:rgba(255,255,255,0.45);">
          with Kenji Tanaka &amp; Sarah Okonkwo · 1hr 04min
        </div>
      </div>
    </div>

    <!-- Play button -->
    <a href="#" style="display:flex; align-items:center; justify-content:center;
                       background:#1DB954; color:white; font-size:14px; font-weight:700;
                       padding:13px 0; border-radius:10px; text-decoration:none;
                       letter-spacing:0.3px; margin-bottom:28px;">
      ▶  Play Episode
    </a>

    <!-- Chapter list -->
    <div style="font-size:10px; font-weight:700; letter-spacing:2px;
                color:rgba(255,255,255,0.35); margin-bottom:12px;">
      CHAPTERS
    </div>
    <table width="100%" cellpadding="0" cellspacing="0">
      <tr>
        <td style="padding:12px 0; border-bottom:1px solid rgba(255,255,255,0.07);">
          <div style="display:flex; align-items:center;">
            <span style="font-size:12px; color:#1DB954; font-weight:700;
                         min-width:44px;">00:00</span>
            <span style="font-size:13px; color:rgba(255,255,255,0.85);">
              Intro — The WebView problem in production apps
            </span>
          </div>
        </td>
      </tr>
      <tr>
        <td style="padding:12px 0; border-bottom:1px solid rgba(255,255,255,0.07);">
          <div style="display:flex; align-items:center;">
            <span style="font-size:12px; color:#1DB954; font-weight:700;
                         min-width:44px;">08:22</span>
            <span style="font-size:13px; color:rgba(255,255,255,0.85);">
              How RenderObject custom engines work
            </span>
          </div>
        </td>
      </tr>
      <tr>
        <td style="padding:12px 0; border-bottom:1px solid rgba(255,255,255,0.07);">
          <div style="display:flex; align-items:center;">
            <span style="font-size:12px; color:#1DB954; font-weight:700;
                         min-width:44px;">22:45</span>
            <span style="font-size:13px; color:rgba(255,255,255,0.85);">
              Live demo: HyperRender vs flutter_html vs WebView
            </span>
          </div>
        </td>
      </tr>
      <tr>
        <td style="padding:12px 0; border-bottom:1px solid rgba(255,255,255,0.07);">
          <div style="display:flex; align-items:center;">
            <span style="font-size:12px; color:#1DB954; font-weight:700;
                         min-width:44px;">41:10</span>
            <span style="font-size:13px; color:rgba(255,255,255,0.85);">
              Float layout deep-dive — the IFC algorithm in Flutter
            </span>
          </div>
        </td>
      </tr>
      <tr>
        <td style="padding:12px 0; border-bottom:1px solid rgba(255,255,255,0.07);">
          <div style="display:flex; align-items:center;">
            <span style="font-size:12px; color:#1DB954; font-weight:700;
                         min-width:44px;">53:30</span>
            <span style="font-size:13px; color:rgba(255,255,255,0.85);">
              Q&A — listener questions from Discord
            </span>
          </div>
        </td>
      </tr>
      <tr>
        <td style="padding:12px 0;">
          <div style="display:flex; align-items:center;">
            <span style="font-size:12px; color:#1DB954; font-weight:700;
                         min-width:44px;">01:00</span>
            <span style="font-size:13px; color:rgba(255,255,255,0.85);">
              Outro &amp; next week's teaser
            </span>
          </div>
        </td>
      </tr>
    </table>
  </div>

  <!-- Show notes divider -->
  <div style="height:1px; background:rgba(255,255,255,0.07); margin:0 20px;"></div>

  <!-- Show notes -->
  <div style="padding:20px;">
    <div style="font-size:10px; font-weight:700; letter-spacing:2px;
                color:rgba(255,255,255,0.35); margin-bottom:12px;">
      SHOW NOTES
    </div>
    <p style="font-size:13px; color:rgba(255,255,255,0.65); line-height:1.8; margin:0 0 12px;">
      This week Kenji and Sarah dig into the new generation of Flutter HTML renderers
      that are finally making <code style="background:rgba(255,255,255,0.1); color:#82CFFF;
      padding:1px 5px; border-radius:3px;">webview_flutter</code> look like a legacy choice.
      They benchmark startup time, RAM usage, and scroll jank across three libraries —
      and the results may surprise you.
    </p>
    <p style="font-size:13px; color:rgba(255,255,255,0.65); line-height:1.8; margin:0 0 18px;">
      Key takeaway: if your Flutter app renders any HTML — emails, articles, CMSs,
      or user-generated content — you owe it to your users to switch from WebView.
    </p>

    <!-- Links -->
    <div style="font-size:10px; font-weight:700; letter-spacing:2px;
                color:rgba(255,255,255,0.35); margin-bottom:12px;">
      LINKS FROM THIS EPISODE
    </div>
    <table width="100%" cellpadding="0" cellspacing="0">
      <tr>
        <td style="padding:9px 0; border-bottom:1px solid rgba(255,255,255,0.06);">
          <a href="#" style="font-size:13px; color:#82CFFF; text-decoration:none;">
            → HyperRender on pub.dev
          </a>
        </td>
      </tr>
      <tr>
        <td style="padding:9px 0; border-bottom:1px solid rgba(255,255,255,0.06);">
          <a href="#" style="font-size:13px; color:#82CFFF; text-decoration:none;">
            → Flutter RenderObject deep-dive (official docs)
          </a>
        </td>
      </tr>
      <tr>
        <td style="padding:9px 0; border-bottom:1px solid rgba(255,255,255,0.06);">
          <a href="#" style="font-size:13px; color:#82CFFF; text-decoration:none;">
            → CSS IFC specification — W3C
          </a>
        </td>
      </tr>
      <tr>
        <td style="padding:9px 0;">
          <a href="#" style="font-size:13px; color:#82CFFF; text-decoration:none;">
            → GitHub: benchmark repo used in this episode
          </a>
        </td>
      </tr>
    </table>
  </div>

  <!-- Rating + Subscribe -->
  <div style="padding:0 20px 20px;">
    <div style="background:rgba(255,255,255,0.05); border-radius:10px; padding:16px;
                text-align:center;">
      <div style="font-size:13px; color:rgba(255,255,255,0.6); margin-bottom:10px;">
        Enjoying the show? Leave us a review ⭐
      </div>
      <div style="display:flex; justify-content:center; gap:8px;">
        <a href="#" style="background:#1DB954; color:white; font-size:12px;
                           font-weight:700; padding:8px 16px; border-radius:8px;
                           text-decoration:none; margin-right:8px;">
          Apple Podcasts
        </a>
        <a href="#" style="background:#1A1A1A; border:1px solid rgba(255,255,255,0.2);
                           color:white; font-size:12px; font-weight:700; padding:8px 16px;
                           border-radius:8px; text-decoration:none;">
          Spotify
        </a>
      </div>
    </div>
  </div>

  <!-- Footer -->
  <div style="padding:16px 20px; border-top:1px solid rgba(255,255,255,0.07);
              text-align:center;">
    <p style="font-size:11px; color:rgba(255,255,255,0.25); margin:0 0 6px;">
      Flutter Uncensored · Produced independently · Released every Friday
    </p>
    <p style="font-size:11px; margin:0;">
      <a href="#" style="color:rgba(255,255,255,0.35); text-decoration:none;">Unsubscribe</a>
      <span style="color:rgba(255,255,255,0.15);"> · </span>
      <a href="#" style="color:rgba(255,255,255,0.35); text-decoration:none;">Manage alerts</a>
    </p>
  </div>

</div>
''';

// ─────────────────────────────────────────────────────────────────────────────
// Tab 6 — Why use HyperRender for emails?
// ─────────────────────────────────────────────────────────────────────────────

class _WhyTab extends StatelessWidget {
  const _WhyTab();

  static const _snippets = {
    'WebView (old way)': '''// pubspec.yaml: webview_flutter (~20MB overhead)
// - Slow cold start (~800ms on mid-range Android)
// - Breaks native scroll physics
// - Text selection works differently per platform
// - Cannot mix WebView with Flutter widgets
// - ~20MB bundle size increase''',
    'HyperRender (new way)': '''// pubspec.yaml: hyper_render (~600KB)
HyperViewer(
  html: emailHtml,          // Any HTML email string
  selectable: true,         // Native Flutter text selection
  onLinkTap: (url) { ... }, // Handle link taps natively
)
// - First frame in <16ms
// - Native scroll physics, rubber-band, overscroll
// - Mix HyperViewer with any Flutter widget
// - ~600KB bundle impact''',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            icon: Icons.help_outline,
            color: DemoColors.primary,
            title: 'Why not just use WebView?',
            body:
                'Flutter apps commonly display HTML emails (transactional, newsletters, '
                'receipts). The default approach is webview_flutter — but that adds ~20MB '
                'to your app, requires a platform-specific WebViewController per email, '
                'breaks native scroll physics, and makes text selection janky.',
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.bolt,
            color: Colors.green,
            title: 'HyperRender handles real-world email HTML',
            body:
                'HTML emails use inline CSS and table-based layouts — legacy patterns that '
                'most Flutter renderers choke on. HyperRender\'s CSS cascade supports '
                'inline styles, and its table renderer handles the nested <table> layouts '
                'that every marketing platform generates.',
          ),
          const SizedBox(height: 16),
          _SectionTitle('Code Comparison', color: DemoColors.primary),
          const SizedBox(height: 8),
          ..._snippets.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CodeBlock(label: e.key, code: e.value),
              )),
          const SizedBox(height: 8),
          _SectionTitle("What's supported in HTML emails",
              color: DemoColors.primary),
          const SizedBox(height: 8),
          _FeatureGrid(features: const [
            ('✅', 'Nested <table> layouts'),
            ('✅', 'Inline CSS (style="...")'),
            ('✅', 'Images with alt text'),
            ('✅', 'Links with onLinkTap'),
            ('✅', 'Colored sections'),
            ('✅', 'Buttons (styled <a>)'),
            ('✅', 'Native text selection'),
            ('✅', 'Native scroll physics'),
            ('✅', 'Works offline'),
            ('⚠️', '<video> (placeholder)'),
            ('❌', 'JavaScript (by design)'),
            ('❌', '<form> inputs'),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 4),
                Text(body,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionTitle(this.title, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: color),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String label;
  final String code;
  const _CodeBlock({required this.label, required this.code});

  @override
  Widget build(BuildContext context) {
    final isGood = label.contains('HyperRender');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isGood ? Colors.green.shade600 : Colors.grey.shade600,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2E),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(6),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
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
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final List<(String, String)> features;
  const _FeatureGrid({required this.features});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features.map((f) {
        final (icon, label) = f;
        final color = icon == '✅'
            ? Colors.green.shade700
            : icon == '⚠️'
                ? Colors.orange.shade700
                : Colors.red.shade700;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(20),
            color: color.withValues(alpha: 0.06),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
