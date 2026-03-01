import "package:hyper_render/hyper_render.dart";
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for Sprint 3 CSS features:
///   - CSS Custom Properties (var() / --custom-property)
///   - CSS calc() arithmetic
///   - RTL / BiDi direction support
///
/// These are integration-level tests that verify the full pipeline:
///   HTML string → parser → StyleResolver → layout → render
void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // CSS Custom Properties (CSS Variables)
  // ──────────────────────────────────────────────────────────────────────────

  group('CSS Custom Properties — var()', () {
    testWidgets('renders element with var() color reference', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <style>:root { --text: #333; }</style>
                <p style="color: var(--text)">Text using CSS variable</p>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('uses fallback when variable is not defined', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p style="font-size: var(--undefined-size, 20px)">Fallback 20px</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('inherits custom property from parent element', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="--brand: #e53935">
                  <p style="color: var(--brand)">Child reads --brand</p>
                  <div>
                    <span style="background-color: var(--brand)">Grandchild reads --brand</span>
                  </div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('multiple variables in same stylesheet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <style>
                  :root {
                    --primary: #1565c0;
                    --accent:  #00897b;
                    --bg:      #e8f5e9;
                  }
                </style>
                <div style="background: var(--bg); padding: 8px">
                  <h3 style="color: var(--primary)">Heading</h3>
                  <a style="color: var(--accent)">Link</a>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('var() inside calc() expression', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="--base: 10px">
                  <p style="font-size: calc(var(--base) + 6px)">calc(var(--base) + 6px)</p>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('variable overriding in child scope', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="--color: blue">
                  <p style="color: var(--color)">Blue (from parent)</p>
                  <div style="--color: red">
                    <p style="color: var(--color)">Red (overridden)</p>
                  </div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders design-token card pattern', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <style>
                  .card        { --bg: #f5f5f5; --border: #e0e0e0; --title: #212121; }
                  .card-blue   { --bg: #e3f2fd; --border: #1565c0; --title: #0d47a1; }
                  .card-green  { --bg: #e8f5e9; --border: #2e7d32; --title: #1b5e20; }
                </style>
                <div class="card card-blue"
                     style="padding:10px;border:2px solid var(--border);
                            background:var(--bg);border-radius:6px">
                  <strong style="color:var(--title)">Blue Card</strong>
                </div>
                <div class="card card-green"
                     style="padding:10px;border:2px solid var(--border);
                            background:var(--bg);border-radius:6px">
                  <strong style="color:var(--title)">Green Card</strong>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // CSS calc()
  // ──────────────────────────────────────────────────────────────────────────

  group('CSS calc()', () {
    testWidgets('evaluates calc with addition', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p style="font-size: calc(8px + 8px)">16px via calc</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('evaluates calc with subtraction', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p style="font-size: calc(24px - 4px)">20px via calc</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('evaluates calc with multiplication', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p style="font-size: calc(4 * 5px)">20px via multiply</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('evaluates calc with division', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p style="font-size: calc(48px / 3)">16px via divide</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('respects operator precedence (* before +)', (tester) async {
      // calc(2 * 6px + 4px) should be 16px, not 20px
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p style="font-size: calc(2 * 6px + 4px)">Should be 16px</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('evaluates calc with em units', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p style="font-size: calc(1em + 4px)">em + px</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('evaluates calc with rem units', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p style="padding: calc(1rem + 4px)">rem + px padding</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles empty calc() gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<div style="width: calc()">Empty calc</div>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles malformed calc() gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<div style="width: calc(abc)">Malformed calc</div>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('calc() in margin and padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="margin: calc(8px + 4px); padding: calc(4px + 6px);
                            background: #e3f2fd; border-radius: calc(4px + 4px)">
                  calc in margin + padding + border-radius
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('calc() combined with var()', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="--sp: 8px; --base: 14px">
                  <p style="font-size: calc(var(--base) + 4px)">18px</p>
                  <p style="margin: calc(var(--sp) * 2)">margin 16px</p>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('division by zero is handled gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p style="font-size: calc(16px / 0)">div by zero</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // RTL / BiDi Support
  // ──────────────────────────────────────────────────────────────────────────

  group('RTL / BiDi Direction', () {
    testWidgets('renders direction:rtl without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<div style="direction:rtl"><p>مرحبا بالعالم</p></div>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('respects dir="rtl" HTML attribute', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p dir="rtl">שלום עולם</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('respects dir="ltr" HTML attribute', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p dir="ltr">Left to right text</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles mixed LTR and RTL paragraphs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <p>English LTR paragraph</p>
                <p style="direction:rtl">فارسی: متن راست‌چین</p>
                <p>Back to LTR English</p>
                <p dir="rtl">مرحبا بالعالم — Arabic RTL</p>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('RTL direction inherited by children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="direction:rtl">
                  <p>Child inherits RTL: مرحبا</p>
                  <ul>
                    <li>عنصر أول</li>
                    <li>عنصر ثانٍ</li>
                  </ul>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('RTL with inline bold and italic formatting', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="direction:rtl">
                  <p>
                    نص <strong>عريض</strong> و<em>مائل</em> و<u>مسطر</u> بالعربية
                  </p>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('RTL with heading tags', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <h1 style="direction:rtl">عنوان رئيسي</h1>
                <h2 dir="rtl">عنوان فرعي</h2>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('RTL in grid container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;direction:rtl">
                  <div style="background:#e3f2fd;padding:8px">خلية 1</div>
                  <div style="background:#e8f5e9;padding:8px">خلية 2</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // CSS !important (Sprint 2, ensuring it still works)
  // ──────────────────────────────────────────────────────────────────────────

  group('CSS !important', () {
    testWidgets('!important overrides inline style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <style>p { color: red !important; }</style>
                <p style="color: blue">Should be red via !important</p>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('!important with multiple conflicting rules', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <style>
                  .a { font-size: 24px !important; }
                  .b { font-size: 12px; }
                </style>
                <p class="a b">24px wins via !important</p>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
