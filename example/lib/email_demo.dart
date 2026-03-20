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
        title: const Text('HTML Email Renderer'),
        backgroundColor: DemoColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.waving_hand, size: 16), text: 'Welcome'),
            Tab(icon: Icon(Icons.newspaper, size: 16), text: 'Newsletter'),
            Tab(icon: Icon(Icons.receipt_long, size: 16), text: 'Order'),
            Tab(icon: Icon(Icons.code, size: 16), text: 'Why?'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EmailTab(html: _welcomeEmail, label: 'Welcome Email'),
          _EmailTab(html: _newsletterEmail, label: 'Newsletter'),
          _EmailTab(html: _orderEmail, label: 'Order Confirmation'),
          const _WhyTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared email wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _EmailTab extends StatelessWidget {
  final String html;
  final String label;

  const _EmailTab({required this.html, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Email client toolbar chrome
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFF5F5F5),
          child: Row(
            children: [
              const Icon(Icons.email_outlined, size: 16, color: Color(0xFF757575)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF424242),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 11, color: Colors.green.shade700),
                    const SizedBox(width: 3),
                    Text(
                      'Rendered natively',
                      style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: HyperViewer(
            html: html,
            selectable: true,
            onLinkTap: (url) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Link tapped: $url'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Welcome Email
// ─────────────────────────────────────────────────────────────────────────────

const _welcomeEmail = '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"/></head>
<body style="margin:0; padding:0; background:#F4F6F9; font-family: -apple-system, 'Segoe UI', Roboto, sans-serif;">

<!-- Outer wrapper -->
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F4F6F9; padding: 24px 0;">
<tr><td align="center">

  <!-- Email container -->
  <table width="560" cellpadding="0" cellspacing="0" style="max-width:560px; width:100%;">

    <!-- Header -->
    <tr>
      <td style="background: linear-gradient(135deg, #3F51B5, #7C4DFF); border-radius:12px 12px 0 0; padding: 32px 36px; text-align:center;">
        <div style="font-size:32px; margin-bottom:8px;">⚡</div>
        <div style="font-size:26px; font-weight:800; color:white; letter-spacing:-0.5px;">
          Welcome to HyperShop
        </div>
        <div style="font-size:14px; color:rgba(255,255,255,0.8); margin-top:6px;">
          Your account is ready
        </div>
      </td>
    </tr>

    <!-- Body -->
    <tr>
      <td style="background:white; padding: 32px 36px;">
        <p style="font-size:16px; color:#212121; margin:0 0 12px;">
          Hi <strong>Alex</strong>, 👋
        </p>
        <p style="font-size:15px; color:#424242; line-height:1.7; margin:0 0 20px;">
          Thanks for joining HyperShop! We're thrilled to have you on board.
          Your account is set up and ready to go.
        </p>

        <!-- CTA Button -->
        <table width="100%" cellpadding="0" cellspacing="0" style="margin: 24px 0;">
          <tr>
            <td align="center">
              <a href="https://hypershop.example.com/start"
                 style="display:inline-block; background:#3F51B5; color:white;
                        font-size:15px; font-weight:700; padding:14px 36px;
                        border-radius:8px; text-decoration:none; letter-spacing:0.3px;">
                Start Shopping →
              </a>
            </td>
          </tr>
        </table>

        <!-- Divider -->
        <hr style="border:none; border-top:1px solid #F0F0F0; margin:24px 0;"/>

        <!-- Feature highlights -->
        <p style="font-size:13px; font-weight:700; color:#757575; letter-spacing:0.8px; margin:0 0 16px;">
          WHAT YOU GET
        </p>
        <table width="100%" cellpadding="0" cellspacing="0">
          <tr>
            <td style="padding:10px 14px; background:#F8F9FF; border-radius:8px; margin-bottom:8px;">
              <table width="100%">
                <tr>
                  <td width="36" style="font-size:22px;">🚀</td>
                  <td>
                    <div style="font-size:14px; font-weight:700; color:#212121;">Free shipping on all orders</div>
                    <div style="font-size:13px; color:#757575;">On orders over \$50</div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr><td style="height:8px;"></td></tr>
          <tr>
            <td style="padding:10px 14px; background:#F8F9FF; border-radius:8px;">
              <table width="100%">
                <tr>
                  <td width="36" style="font-size:22px;">🎁</td>
                  <td>
                    <div style="font-size:14px; font-weight:700; color:#212121;">20% off your first order</div>
                    <div style="font-size:13px; color:#757575;">Use code <strong style="color:#3F51B5;">WELCOME20</strong></div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr><td style="height:8px;"></td></tr>
          <tr>
            <td style="padding:10px 14px; background:#F8F9FF; border-radius:8px;">
              <table width="100%">
                <tr>
                  <td width="36" style="font-size:22px;">💬</td>
                  <td>
                    <div style="font-size:14px; font-weight:700; color:#212121;">24/7 customer support</div>
                    <div style="font-size:13px; color:#757575;">Chat, email or phone</div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </td>
    </tr>

    <!-- Footer -->
    <tr>
      <td style="background:#F8F8F8; border-radius:0 0 12px 12px; padding:20px 36px; text-align:center; border-top:1px solid #EEEEEE;">
        <p style="font-size:12px; color:#9E9E9E; margin:0 0 6px;">
          HyperShop · 123 Commerce St · San Francisco, CA
        </p>
        <p style="font-size:12px; color:#9E9E9E; margin:0;">
          <a href="#" style="color:#3F51B5;">Unsubscribe</a> ·
          <a href="#" style="color:#3F51B5;">Privacy Policy</a> ·
          <a href="#" style="color:#3F51B5;">Terms</a>
        </p>
      </td>
    </tr>

  </table>
</td></tr>
</table>

</body>
</html>
''';

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Newsletter
// ─────────────────────────────────────────────────────────────────────────────

const _newsletterEmail = '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"/></head>
<body style="margin:0; padding:0; background:#F4F4F4; font-family: Georgia, 'Times New Roman', serif;">

<table width="100%" cellpadding="0" cellspacing="0" style="background:#F4F4F4; padding:20px 0;">
<tr><td align="center">
<table width="560" cellpadding="0" cellspacing="0" style="max-width:560px; width:100%;">

  <!-- Masthead -->
  <tr>
    <td style="background:#1A1A2E; padding:20px 28px; border-radius:12px 12px 0 0;">
      <table width="100%">
        <tr>
          <td>
            <div style="font-size:11px; font-weight:700; color:#7C83FF; letter-spacing:2px;">THE WEEKLY</div>
            <div style="font-size:24px; font-weight:900; color:white; font-family:-apple-system,sans-serif;">
              Tech Dispatch
            </div>
          </td>
          <td align="right" style="font-size:11px; color:#666; font-family:-apple-system,sans-serif;">
            Issue #47<br/>Feb 28, 2026
          </td>
        </tr>
      </table>
    </td>
  </tr>

  <!-- Hero story -->
  <tr>
    <td style="background:white; padding:28px;">
      <div style="background:#E8EAF6; border-radius:8px; padding:20px; margin-bottom:24px;">
        <div style="font-size:10px; font-weight:800; color:#3F51B5; letter-spacing:1.5px; margin-bottom:8px;">
          COVER STORY
        </div>
        <h2 style="font-size:20px; line-height:1.3; color:#1A1A2E; margin:0 0 10px; font-family:-apple-system,sans-serif; font-weight:800;">
          Flutter's custom rendering revolution: how single-RenderObject engines are beating WebView
        </h2>
        <p style="font-size:14px; color:#616161; line-height:1.7; margin:0 0 14px;">
          A new generation of Flutter libraries is proving that native canvas painting
          outperforms embedded WebView in every metric that matters: startup time,
          RAM usage, scroll smoothness, and bundle size.
        </p>
        <a href="#" style="color:#3F51B5; font-size:13px; font-weight:700; font-family:-apple-system,sans-serif;">
          Read the full analysis →
        </a>
      </div>

      <!-- Stories grid (two column using table) -->
      <table width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td width="48%" style="vertical-align:top; padding-right:12px;">
            <div style="font-size:18px; margin-bottom:6px;">📱</div>
            <div style="font-size:13px; font-weight:700; color:#212121; margin-bottom:5px; font-family:-apple-system,sans-serif; line-height:1.3;">
              iOS 20 brings new text rendering APIs
            </div>
            <div style="font-size:12px; color:#757575; line-height:1.6;">
              Apple's new CoreText extensions give Flutter access
              to system-level font hinting and subpixel rendering.
            </div>
          </td>
          <td width="4%"></td>
          <td width="48%" style="vertical-align:top; border-left:1px solid #F0F0F0; padding-left:12px;">
            <div style="font-size:18px; margin-bottom:6px;">🤖</div>
            <div style="font-size:13px; font-weight:700; color:#212121; margin-bottom:5px; font-family:-apple-system,sans-serif; line-height:1.3;">
              Dart 4.0 ships with pattern matching in switch
            </div>
            <div style="font-size:12px; color:#757575; line-height:1.6;">
              The latest Dart release makes sealed classes and
              exhaustive switches the default coding pattern.
            </div>
          </td>
        </tr>
      </table>

      <hr style="border:none; border-top:1px solid #F0F0F0; margin:20px 0;"/>

      <!-- Sponsored -->
      <div style="background:#FFFDE7; border:1px solid #FFF59D; border-radius:6px; padding:12px 14px;">
        <div style="font-size:10px; color:#F9A825; font-weight:700; letter-spacing:1px; margin-bottom:5px; font-family:-apple-system,sans-serif;">
          SPONSORED
        </div>
        <div style="font-size:13px; color:#424242; line-height:1.6;">
          <strong>ScreenshotKit Pro</strong> — Export any Flutter widget to PDF in one line of code.
          Used by 12,000+ developers.
          <a href="#" style="color:#3F51B5;">Try free →</a>
        </div>
      </div>

      <hr style="border:none; border-top:1px solid #F0F0F0; margin:20px 0;"/>

      <!-- Quick links -->
      <div style="font-size:11px; font-weight:700; color:#9E9E9E; letter-spacing:1px; margin-bottom:12px; font-family:-apple-system,sans-serif;">
        QUICK LINKS
      </div>
      <table width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td style="padding:7px 0; border-bottom:1px solid #F5F5F5;">
            <a href="#" style="color:#212121; text-decoration:none; font-size:13px;">
              📦 pub.dev packages of the week
            </a>
            <span style="float:right; font-size:11px; color:#BDBDBD;">3 min</span>
          </td>
        </tr>
        <tr>
          <td style="padding:7px 0; border-bottom:1px solid #F5F5F5;">
            <a href="#" style="color:#212121; text-decoration:none; font-size:13px;">
              🐛 Widget tree debugging: 5 hidden DevTools tips
            </a>
            <span style="float:right; font-size:11px; color:#BDBDBD;">5 min</span>
          </td>
        </tr>
        <tr>
          <td style="padding:7px 0;">
            <a href="#" style="color:#212121; text-decoration:none; font-size:13px;">
              🎯 Riverpod vs BLoC in 2026: a real-world comparison
            </a>
            <span style="float:right; font-size:11px; color:#BDBDBD;">8 min</span>
          </td>
        </tr>
      </table>
    </td>
  </tr>

  <!-- Footer -->
  <tr>
    <td style="background:#1A1A2E; padding:18px 28px; border-radius:0 0 12px 12px; text-align:center;">
      <p style="font-size:11px; color:#666; margin:0 0 6px; font-family:-apple-system,sans-serif;">
        You're receiving this because you subscribed to Tech Dispatch.
      </p>
      <p style="font-size:11px; margin:0; font-family:-apple-system,sans-serif;">
        <a href="#" style="color:#7C83FF;">Unsubscribe</a>
        <span style="color:#444;"> · </span>
        <a href="#" style="color:#7C83FF;">Manage preferences</a>
        <span style="color:#444;"> · </span>
        <a href="#" style="color:#7C83FF;">View in browser</a>
      </p>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>
''';

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Order Confirmation
// ─────────────────────────────────────────────────────────────────────────────

const _orderEmail = '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"/></head>
<body style="margin:0; padding:0; background:#F5F5F5; font-family:-apple-system,'Segoe UI',Roboto,sans-serif;">

<table width="100%" cellpadding="0" cellspacing="0" style="background:#F5F5F5; padding:20px 0;">
<tr><td align="center">
<table width="560" cellpadding="0" cellspacing="0" style="max-width:560px; width:100%;">

  <!-- Header -->
  <tr>
    <td style="background:#00897B; border-radius:12px 12px 0 0; padding:24px 28px; text-align:center;">
      <div style="font-size:36px; margin-bottom:6px;">✅</div>
      <div style="font-size:22px; font-weight:800; color:white;">Order Confirmed!</div>
      <div style="font-size:13px; color:rgba(255,255,255,0.8); margin-top:4px;">
        Order #HR-2026-78412 · Feb 28, 2026
      </div>
    </td>
  </tr>

  <!-- Body -->
  <tr>
    <td style="background:white; padding:24px 28px;">
      <p style="font-size:14px; color:#424242; line-height:1.7; margin:0 0 20px;">
        Hi <strong>Alex</strong>, your order has been confirmed and will be
        shipped within <strong style="color:#00897B;">1–2 business days</strong>.
      </p>

      <!-- Order items table -->
      <table width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #E0E0E0; border-radius:8px; overflow:hidden; margin-bottom:20px;">
        <!-- Table header -->
        <tr style="background:#F5F5F5;">
          <td style="padding:10px 14px; font-size:11px; font-weight:700; color:#757575; letter-spacing:0.8px;">ITEM</td>
          <td style="padding:10px 14px; font-size:11px; font-weight:700; color:#757575; letter-spacing:0.8px; text-align:center;">QTY</td>
          <td style="padding:10px 14px; font-size:11px; font-weight:700; color:#757575; letter-spacing:0.8px; text-align:right;">PRICE</td>
        </tr>
        <!-- Items -->
        <tr style="border-top:1px solid #F0F0F0;">
          <td style="padding:12px 14px;">
            <div style="font-size:14px; font-weight:600; color:#212121;">Flutter Pro Bundle</div>
            <div style="font-size:12px; color:#9E9E9E;">Digital download · License: 1 dev</div>
          </td>
          <td style="padding:12px 14px; text-align:center; font-size:14px; color:#424242;">1</td>
          <td style="padding:12px 14px; text-align:right; font-size:14px; font-weight:600; color:#212121;">\$79.00</td>
        </tr>
        <tr style="border-top:1px solid #F0F0F0; background:#FAFAFA;">
          <td style="padding:12px 14px;">
            <div style="font-size:14px; font-weight:600; color:#212121;">HyperRender Pro License</div>
            <div style="font-size:12px; color:#9E9E9E;">12 months · Unlimited apps</div>
          </td>
          <td style="padding:12px 14px; text-align:center; font-size:14px; color:#424242;">1</td>
          <td style="padding:12px 14px; text-align:right; font-size:14px; font-weight:600; color:#212121;">\$49.00</td>
        </tr>
        <tr style="border-top:1px solid #F0F0F0;">
          <td style="padding:12px 14px;">
            <div style="font-size:14px; font-weight:600; color:#212121;">Design System Starter Kit</div>
            <div style="font-size:12px; color:#9E9E9E;">Figma + Flutter components</div>
          </td>
          <td style="padding:12px 14px; text-align:center; font-size:14px; color:#424242;">2</td>
          <td style="padding:12px 14px; text-align:right; font-size:14px; font-weight:600; color:#212121;">\$38.00</td>
        </tr>
        <!-- Totals -->
        <tr style="border-top:1px solid #E0E0E0; background:#F5F5F5;">
          <td colspan="2" style="padding:10px 14px; font-size:13px; color:#757575;">Subtotal</td>
          <td style="padding:10px 14px; text-align:right; font-size:13px; color:#424242;">\$166.00</td>
        </tr>
        <tr style="background:#F5F5F5;">
          <td colspan="2" style="padding:6px 14px; font-size:13px; color:#757575;">Discount (WELCOME20)</td>
          <td style="padding:6px 14px; text-align:right; font-size:13px; color:#00897B;">−\$33.20</td>
        </tr>
        <tr style="background:#F5F5F5;">
          <td colspan="2" style="padding:6px 14px; font-size:13px; color:#757575;">Tax (8.5%)</td>
          <td style="padding:6px 14px; text-align:right; font-size:13px; color:#424242;">\$11.28</td>
        </tr>
        <tr style="border-top:2px solid #E0E0E0; background:white;">
          <td colspan="2" style="padding:14px 14px; font-size:16px; font-weight:800; color:#212121;">
            Total
          </td>
          <td style="padding:14px 14px; text-align:right; font-size:16px; font-weight:800; color:#00897B;">
            \$144.08
          </td>
        </tr>
      </table>

      <!-- Shipping info -->
      <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:20px;">
        <tr>
          <td width="48%" style="background:#E8F5E9; border-radius:8px; padding:14px; vertical-align:top;">
            <div style="font-size:11px; font-weight:700; color:#2E7D32; letter-spacing:0.8px; margin-bottom:6px;">
              SHIPPING TO
            </div>
            <div style="font-size:13px; color:#424242; line-height:1.6;">
              Alex Johnson<br/>
              456 Developer Lane<br/>
              Austin, TX 78701
            </div>
          </td>
          <td width="4%"></td>
          <td width="48%" style="background:#E3F2FD; border-radius:8px; padding:14px; vertical-align:top;">
            <div style="font-size:11px; font-weight:700; color:#1565C0; letter-spacing:0.8px; margin-bottom:6px;">
              PAYMENT
            </div>
            <div style="font-size:13px; color:#424242; line-height:1.6;">
              Visa ···· 4242<br/>
              <span style="font-size:12px; color:#00897B;">✓ Charged \$144.08</span>
            </div>
          </td>
        </tr>
      </table>

      <!-- Track CTA -->
      <table width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td align="center">
            <a href="#"
               style="display:inline-block; background:#00897B; color:white;
                      font-size:14px; font-weight:700; padding:12px 32px;
                      border-radius:8px; text-decoration:none;">
              Track Your Order
            </a>
          </td>
        </tr>
      </table>
    </td>
  </tr>

  <!-- Footer -->
  <tr>
    <td style="background:#F5F5F5; border-radius:0 0 12px 12px; border-top:1px solid #E0E0E0; padding:16px 28px; text-align:center;">
      <p style="font-size:12px; color:#9E9E9E; margin:0;">
        Questions? Reply to this email or contact
        <a href="#" style="color:#00897B;">support@hypershop.example.com</a>
      </p>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>
''';

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4 — Why use HyperRender for emails?
// ─────────────────────────────────────────────────────────────────────────────

class _WhyTab extends StatelessWidget {
  const _WhyTab();

  static const _snippets = {
    'WebView (old way)': '''// Add to pubspec.yaml: webview_flutter (~20MB)
// Initialize WebViewWidget, create WebViewController...
// Load HTML via loadHtmlString()
// → Slow cold start, can't select text natively,
//   breaks scroll physics, ~20MB bundle impact''',
    'HyperRender (new way)': '''// Add to pubspec.yaml: hyper_render (~600KB)
HyperViewer(
  html: emailHtml,          // Your HTML email string
  selectable: true,         // Native text selection
  onLinkTap: (url) { ... }, // Handle link taps
)
// → Instant render, native scroll, native selection,
//   ~600KB bundle impact, works offline''',
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
          _SectionTitle("What's supported in HTML emails", color: DemoColors.primary),
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
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color)),
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
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: const BorderRadius.only(
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
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
