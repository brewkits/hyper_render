// ignore_for_file: deprecated_member_use
// Tests covering P1 + P2 fixes from the recent engineering sessions.
//
// Fixes tested here:
//  • HyperRenderConfig — imageCacheSize, extraLinkSchemes fields
//  • _Re static-final regex patterns (via StyleResolver._parseInlineStyle)
//  • calc() depth cap (_kMaxCalcDepth = 8 in StyleResolver)
//  • Semantics virtualization — headingAnchors population
//  • Semantics tree — heading/link nodes emitted to accessibility tree
//  • Details relayout — expand/collapse works without crashing

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps [child] in a minimal Material app with a 400 × 800 viewport.
Widget _app(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 400, height: 800, child: child),
      ),
    );

/// Resolves an inline CSS style string on [tagName] and returns the
/// resulting [ComputedStyle].  Uses the inline-style path which exercises
/// [_Re] regex patterns in [StyleResolver._parseInlineStyle].
ComputedStyle _resolveInline(String inlineStyle, String tagName) {
  final resolver = StyleResolver();
  final node = BlockNode(
    tagName: tagName,
    attributes: {'style': inlineStyle},
  );
  final doc = DocumentNode(children: [node]);
  resolver.resolveStyles(doc);
  return node.style;
}

// ─────────────────────────────────────────────────────────────────────────────
// Group 1 — HyperRenderConfig new fields
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('HyperRenderConfig', () {
    test('defaults: imageCacheSize=30, extraLinkSchemes={}', () {
      const cfg = HyperRenderConfig();
      expect(cfg.imageCacheSize, 30);
      expect(cfg.extraLinkSchemes, isEmpty);
    });

    test('low-end device profile', () {
      const cfg = HyperRenderConfig(
        imageCacheSize: 10,
        imageConcurrency: 2,
        textPainterCacheSize: 500,
      );
      expect(cfg.imageCacheSize, 10);
      expect(cfg.imageConcurrency, 2);
    });

    test('high-end device profile', () {
      const cfg = HyperRenderConfig(
        imageCacheSize: 60,
        imageConcurrency: 6,
        textPainterCacheSize: 10000,
      );
      expect(cfg.imageCacheSize, 60);
    });

    test('extraLinkSchemes stores custom schemes', () {
      const cfg = HyperRenderConfig(
        extraLinkSchemes: {'myapp', 'shopee', 'fb'},
      );
      expect(cfg.extraLinkSchemes, containsAll(['myapp', 'shopee', 'fb']));
      expect(cfg.extraLinkSchemes.length, 3);
    });

    test('imageCacheSize must be positive', () {
      expect(
        () => HyperRenderConfig(imageCacheSize: 0),
        throwsAssertionError,
      );
      expect(
        () => HyperRenderConfig(imageCacheSize: -1),
        throwsAssertionError,
      );
    });

    test('textPainterCacheSize must be positive', () {
      expect(
        () => HyperRenderConfig(textPainterCacheSize: 0),
        throwsAssertionError,
      );
    });

    test('imageConcurrency must be positive', () {
      expect(
        () => HyperRenderConfig(imageConcurrency: 0),
        throwsAssertionError,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 2 — _Re regex patterns (via inline style parsing)
  //
  // StyleResolver._parseInlineStyle → _applyDeclarations uses the same
  // _Re regex patterns as stylesheet parsing, but the inline-style path is
  // more reliable in tests (avoids csslib span-text edge cases).
  // ─────────────────────────────────────────────────────────────────────────

  group('StyleResolver — CSS value parsing (_Re patterns)', () {
    group('rgb / rgba colors', () {
      test('rgb(r,g,b) parses to correct color', () {
        final style = _resolveInline('color: rgb(255, 0, 128)', 'p');
        expect(style.color, isNotNull);
        expect(style.color.red, 255);
        expect(style.color.green, 0);
        expect(style.color.blue, 128);
      });

      test('rgb with negative values clamped to 0', () {
        final style = _resolveInline('color: rgb(-10, 200, 50)', 'p');
        expect(style.color, isNotNull);
        expect(style.color.red, 0);
        expect(style.color.green, 200);
        expect(style.color.blue, 50);
      });

      test('rgba(r,g,b,a) parses alpha correctly', () {
        final style = _resolveInline('color: rgba(255, 128, 0, 0.5)', 'p');
        expect(style.color, isNotNull);
        expect(style.color.red, 255);
        expect(style.color.green, 128);
        expect(style.color.blue, 0);
        // alpha 0.5 → ~128
        expect(style.color.alpha, closeTo(128, 2));
      });

      test('rgba with alpha=0 is fully transparent', () {
        final style = _resolveInline('color: rgba(0, 0, 0, 0)', 'p');
        expect(style.color, isNotNull);
        expect(style.color.alpha, 0);
      });

      test('rgba with alpha=1 is fully opaque', () {
        final style = _resolveInline('color: rgba(0, 0, 0, 1)', 'p');
        expect(style.color, isNotNull);
        expect(style.color.alpha, 255);
      });
    });

    group('url() function', () {
      test("url() extracts background image URL (quoted)", () {
        final style = _resolveInline("background: url('/images/bg.png')", 'p');
        expect(style.backgroundImage, '/images/bg.png');
      });

      test('url() without quotes', () {
        final style =
            _resolveInline('background: url(https://example.com/img.jpg)', 'p');
        expect(style.backgroundImage, 'https://example.com/img.jpg');
      });

      test('url() with double quotes', () {
        final style = _resolveInline('background: url("sprite.svg")', 'p');
        expect(style.backgroundImage, 'sprite.svg');
      });
    });

    group('CSS custom properties (var() fallback)', () {
      test('var() uses fallback when property missing', () {
        // --missing-prop is not defined → fallback #00FF00 should be used
        final style =
            _resolveInline('color: var(--missing-prop, #00FF00)', 'p');
        expect(style.color, isNotNull);
        expect(style.color.green, 0xFF);
        expect(style.color.red, 0);
        expect(style.color.blue, 0);
      });

      test('var() fallback parses hex correctly', () {
        final style = _resolveInline('color: var(--x, #FF5500)', 'p');
        expect(style.color, isNotNull);
        expect(style.color.red, 0xFF);
        expect(style.color.green, 0x55);
        expect(style.color.blue, 0x00);
      });
    });

    group('grid-column/row span', () {
      test('grid-column: span 3', () {
        final style = _resolveInline('grid-column: span 3', 'div');
        expect(style.gridColumnSpan, 3);
      });

      test('grid-column: span 1 (single)', () {
        final style = _resolveInline('grid-column: span 1', 'div');
        expect(style.gridColumnSpan, 1);
      });
    });

    group('linear-gradient()', () {
      test('linear-gradient(to right, ...) produces a gradient', () {
        final style = _resolveInline(
            'background: linear-gradient(to right, red, blue)', 'div');
        expect(style.backgroundGradient, isNotNull);
      });

      test('linear-gradient with angle produces a gradient', () {
        final style = _resolveInline(
            'background: linear-gradient(90deg, #fff, #000)', 'div');
        expect(style.backgroundGradient, isNotNull);
      });
    });

    group('filter function', () {
      test('filter: blur(5px) produces an ImageFilter', () {
        final style = _resolveInline('filter: blur(5px)', 'div');
        expect(style.filter, isNotNull);
      });

      test('filter: brightness(1.5) produces an ImageFilter', () {
        final style = _resolveInline('filter: brightness(1.5)', 'div');
        expect(style.filter, isNotNull);
      });
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 3 — calc() depth cap
  // ─────────────────────────────────────────────────────────────────────────

  group('CSS calc() depth cap', () {
    StyleResolver makeResolver() => StyleResolver();

    test('simple calc(a + b) resolves', () {
      final resolver = makeResolver();
      final doc = DocumentNode(children: [
        BlockNode(
          tagName: 'div',
          attributes: {'style': 'font-size: calc(10px + 6px)'},
        ),
      ]);
      resolver.resolveStyles(doc);
      final style = doc.children.first.style;
      expect(style.fontSize, closeTo(16.0, 0.1));
    });

    test('nested calc(calc(a+b)+c) resolves', () {
      final resolver = makeResolver();
      final doc = DocumentNode(children: [
        BlockNode(
          tagName: 'div',
          attributes: {'style': 'font-size: calc(calc(10px + 4px) + 2px)'},
        ),
      ]);
      resolver.resolveStyles(doc);
      final style = doc.children.first.style;
      expect(style.fontSize, closeTo(16.0, 0.1));
    });

    test('adversarial 20-deep calc() does not hang', () {
      // Build calc(calc(calc(...calc(1px)...))) 20 levels deep.
      String expr = '1px';
      for (int i = 0; i < 20; i++) {
        expr = 'calc($expr + 0px)';
      }

      final resolver = makeResolver();
      final doc = DocumentNode(children: [
        BlockNode(
          tagName: 'div',
          attributes: {'style': 'font-size: $expr'},
        ),
      ]);

      // Must complete in reasonable time (not loop forever).
      // The _kMaxCalcDepth=8 cap ensures this.
      final stopwatch = Stopwatch()..start();
      resolver.resolveStyles(doc);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason:
              'Deeply nested calc() should resolve quickly due to depth cap');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 4 — headingAnchors population (data source for semantics)
  //
  // Note: _BlockStartFragment is only added when effectiveMarginTop > 0 OR
  // _fragments is non-empty (from _tokenizeBlock). Using BlockNode.h1()
  // / BlockNode.h2() factory constructors ensures marginTop > 0, so the
  // first heading gets a _BlockStartFragment.  Subsequent headings always
  // get one because _fragments.isNotEmpty is true.
  // ─────────────────────────────────────────────────────────────────────────

  group('headingAnchors — populated after layout', () {
    testWidgets('h1, h2 and h3 generate heading anchors', (tester) async {
      // Use BlockNode.h1() factory (has margin 21.44) so h1 gets a
      // _BlockStartFragment even when it is the first fragment in the list.
      final doc = DocumentNode(children: [
        BlockNode.h1(children: [TextNode('Main Title')]),
        BlockNode(tagName: 'p', children: [TextNode('Some text.')]),
        BlockNode.h2(children: [TextNode('Sub Section')]),
        // h3 comes after h1/h2 so _fragments.isNotEmpty → always detected.
        BlockNode(
          tagName: 'h3',
          style:
              ComputedStyle(margin: const EdgeInsets.symmetric(vertical: 10)),
          children: [TextNode('Third Level')],
        ),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(document: doc)));
      await tester.pump();

      final renderBox = tester
          .renderObject(find.byType(HyperRenderWidget).first) as RenderHyperBox;

      expect(renderBox.headingAnchors.length, 3);
      expect(renderBox.headingAnchors[0].level, 1);
      expect(renderBox.headingAnchors[0].text, 'Main Title');
      expect(renderBox.headingAnchors[1].level, 2);
      expect(renderBox.headingAnchors[1].text, 'Sub Section');
      expect(renderBox.headingAnchors[2].level, 3);
      expect(renderBox.headingAnchors[2].text, 'Third Level');
    });

    testWidgets('paragraph text does not generate heading anchors',
        (tester) async {
      final doc = DocumentNode(children: [
        BlockNode(tagName: 'p', children: [TextNode('Plain paragraph.')]),
        BlockNode(tagName: 'blockquote', children: [TextNode('A quote.')]),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(document: doc)));
      await tester.pump();

      final renderBox = tester
          .renderObject(find.byType(HyperRenderWidget).first) as RenderHyperBox;
      expect(renderBox.headingAnchors, isEmpty);
    });

    testWidgets('yOffset increases for headings lower in the document',
        (tester) async {
      final doc = DocumentNode(children: [
        BlockNode.h1(children: [TextNode('First')]),
        BlockNode(tagName: 'p', children: [TextNode('A long paragraph ' * 20)]),
        BlockNode.h2(children: [TextNode('Second')]),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(document: doc)));
      await tester.pump();

      final renderBox = tester
          .renderObject(find.byType(HyperRenderWidget).first) as RenderHyperBox;

      expect(renderBox.headingAnchors.length, 2);
      expect(
        renderBox.headingAnchors[1].yOffset,
        greaterThan(renderBox.headingAnchors[0].yOffset),
      );
    });

    testWidgets('all six heading levels (h1-h6) are recorded', (tester) async {
      final doc = DocumentNode(children: [
        // h1 uses factory (has margin → gets _BlockStartFragment even first).
        // h2-h6 come after h1 so _fragments.isNotEmpty is always true.
        BlockNode.h1(children: [TextNode('Heading 1')]),
        BlockNode.h2(children: [TextNode('Heading 2')]),
        for (int i = 3; i <= 6; i++)
          BlockNode(
            tagName: 'h$i',
            style: ComputedStyle(
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
            children: [TextNode('Heading $i')],
          ),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(document: doc)));
      await tester.pump();

      final renderBox = tester
          .renderObject(find.byType(HyperRenderWidget).first) as RenderHyperBox;
      expect(renderBox.headingAnchors.length, 6);
      for (int i = 0; i < 6; i++) {
        expect(renderBox.headingAnchors[i].level, i + 1);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 5 — Semantics tree: heading and link nodes
  // ─────────────────────────────────────────────────────────────────────────

  group('Semantics — heading and link nodes in accessibility tree', () {
    testWidgets('headings are present in the semantics tree', (tester) async {
      final handle = tester.ensureSemantics();

      final doc = DocumentNode(children: [
        // Use factory constructors to ensure margins → _BlockStartFragment.
        BlockNode.h1(children: [TextNode('Important Heading')]),
        BlockNode(tagName: 'p', children: [TextNode('Body text.')]),
        BlockNode.h2(children: [TextNode('Sub Heading')]),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(document: doc)));
      await tester.pump();

      // headingAnchors must be non-empty — the data source for semantic nodes
      final renderBox = tester
          .renderObject(find.byType(HyperRenderWidget).first) as RenderHyperBox;
      expect(renderBox.headingAnchors.length, 2);

      // The full semantics node for HyperRenderWidget should exist.
      final semanticsNode =
          tester.getSemantics(find.byType(HyperRenderWidget).first);
      expect(semanticsNode, isNotNull);

      // The top-level label includes all text (flat label for linear reading).
      expect(semanticsNode.label, contains('Important Heading'));

      handle.dispose();
    });

    testWidgets('links are present in the semantics tree', (tester) async {
      final handle = tester.ensureSemantics();

      final doc = DocumentNode(children: [
        BlockNode(tagName: 'p', children: [
          InlineNode(
            tagName: 'a',
            attributes: {'href': 'https://example.com'},
            children: [TextNode('Visit Example')],
          ),
        ]),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(document: doc)));
      await tester.pump();

      final semanticsNode =
          tester.getSemantics(find.byType(HyperRenderWidget).first);
      expect(semanticsNode, isNotNull);
      // Flat label covers the link text.
      expect(semanticsNode.label, contains('Visit Example'));

      handle.dispose();
    });

    testWidgets('document with no headings or links has correct flat label',
        (tester) async {
      final handle = tester.ensureSemantics();

      final doc = DocumentNode(children: [
        BlockNode(tagName: 'p', children: [TextNode('Just a paragraph.')]),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(document: doc)));
      await tester.pump();

      final semanticsNode =
          tester.getSemantics(find.byType(HyperRenderWidget).first);
      expect(semanticsNode.label, contains('Just a paragraph.'));

      handle.dispose();
    });

    testWidgets('dispose does not assert when semantics were used',
        (tester) async {
      // Regression: disposing RenderHyperBox after assembleSemanticsNode was
      // called must not throw 'owner!._nodes.containsKey(id)' assertion.
      final handle = tester.ensureSemantics();

      final doc = DocumentNode(children: [
        BlockNode.h1(children: [TextNode('Heading')]),
        BlockNode(tagName: 'p', children: [
          InlineNode(
            tagName: 'a',
            attributes: {'href': 'https://flutter.dev'},
            children: [TextNode('Link')],
          ),
        ]),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(document: doc)));
      await tester.pump();

      // Unmounting the widget should not throw.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      handle.dispose();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 6 — Details expand/collapse (relayout optimization)
  //
  // Note: Summary text is rendered via HyperRenderWidget (custom painter),
  // not a Flutter Text widget, so find.text() cannot find it.
  // Use find.byType(InkWell).first to tap the summary row.
  // ─────────────────────────────────────────────────────────────────────────

  group('Details element — expand/collapse relayout', () {
    testWidgets('details expands without crash', (tester) async {
      final doc = DocumentNode(children: [
        BlockNode(tagName: 'details', children: [
          BlockNode(tagName: 'summary', children: [TextNode('Show more')]),
          BlockNode(tagName: 'p', children: [TextNode('Hidden content here')]),
        ]),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(document: doc)));
      await tester.pump();

      // HyperDetailsWidget should be present
      expect(find.byType(HyperDetailsWidget), findsOneWidget);

      // Tap the InkWell (summary row) to expand
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // No crash — widget still present
      expect(find.byType(HyperDetailsWidget), findsOneWidget);
    });

    testWidgets('details collapses on second tap without crash',
        (tester) async {
      // Start open
      final doc = DocumentNode(children: [
        BlockNode(tagName: 'details', attributes: {
          'open': ''
        }, children: [
          BlockNode(tagName: 'summary', children: [TextNode('Toggle me')]),
          BlockNode(tagName: 'p', children: [TextNode('Collapsible body')]),
        ]),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(document: doc)));
      await tester.pumpAndSettle();

      // Initially open — details widget present
      expect(find.byType(HyperDetailsWidget), findsOneWidget);

      // Tap to collapse
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // No crash
      expect(find.byType(HyperDetailsWidget), findsOneWidget);
    });

    testWidgets('HyperDetailsWidget grows after expand', (tester) async {
      // HyperDetailsWidget is a child of RenderHyperBox and is NOT inside the
      // SizedBox that constrains the outer HyperRenderWidget height.
      // Its height reflects actual content: summary-only when collapsed,
      // summary + body when expanded.
      final doc = DocumentNode(children: [
        BlockNode(tagName: 'details', children: [
          BlockNode(tagName: 'summary', children: [TextNode('Expand')]),
          BlockNode(tagName: 'p', children: [TextNode('Body ' * 10)]),
        ]),
        BlockNode(tagName: 'p', children: [TextNode('Below the details')]),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(document: doc)));
      await tester.pump();

      // Record HyperDetailsWidget height when collapsed (summary only)
      final beforeHeight =
          tester.getSize(find.byType(HyperDetailsWidget)).height;

      // Expand by tapping the InkWell
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // HyperDetailsWidget grows to include the body
      final afterHeight =
          tester.getSize(find.byType(HyperDetailsWidget)).height;
      expect(afterHeight, greaterThan(beforeHeight));
    });

    testWidgets('multiple details elements work independently', (tester) async {
      final doc = DocumentNode(children: [
        BlockNode(tagName: 'details', children: [
          BlockNode(tagName: 'summary', children: [TextNode('First')]),
          BlockNode(tagName: 'p', children: [TextNode('First body')]),
        ]),
        BlockNode(tagName: 'details', children: [
          BlockNode(tagName: 'summary', children: [TextNode('Second')]),
          BlockNode(tagName: 'p', children: [TextNode('Second body')]),
        ]),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(document: doc)));
      await tester.pump();

      // Both HyperDetailsWidgets are present
      expect(find.byType(HyperDetailsWidget), findsNWidgets(2));

      // Expand first
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Still two details widgets (no crash)
      expect(find.byType(HyperDetailsWidget), findsNWidgets(2));

      // Expand second
      await tester.tap(find.byType(InkWell).last);
      await tester.pumpAndSettle();

      // Still two, no crash
      expect(find.byType(HyperDetailsWidget), findsNWidgets(2));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 7 — P1 edge cases: extraLinkSchemes link security
  //
  // Note: Link text is rendered via RenderHyperBox custom painter (not Text
  // widgets), so find.text() cannot locate it.  We tap near the top-left of
  // the HyperRenderWidget where the single-line link text starts.
  // ─────────────────────────────────────────────────────────────────────────

  group('extraLinkSchemes — link tap security', () {
    /// Taps on the link area of the [HyperRenderWidget].
    ///
    /// The link text is the first content rendered at approximately (0, 0)
    /// in the widget's local coordinate space.  The widget may be tall (800px
    /// due to SizedBox constraints) but the text is at the top, so we tap
    /// near the top-left.
    Future<void> tapLink(WidgetTester tester) async {
      final rect = tester.getRect(find.byType(HyperRenderWidget).first);
      // Tap ~40px from the left (within "Flutter"/"Open in app" text width)
      // and 8px from the top (middle of first text line, ~16px tall).
      await tester.tapAt(Offset(rect.left + 40, rect.top + 8));
      await tester.pump();
    }

    testWidgets('standard https links trigger onLinkTap', (tester) async {
      String? tappedUrl;
      final doc = DocumentNode(children: [
        BlockNode(tagName: 'p', children: [
          InlineNode(
            tagName: 'a',
            attributes: {'href': 'https://flutter.dev'},
            children: [TextNode('Flutter')],
          ),
        ]),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(
        document: doc,
        onLinkTap: (url) => tappedUrl = url,
      )));
      await tester.pump();

      await tapLink(tester);

      expect(tappedUrl, 'https://flutter.dev');
    });

    testWidgets('custom scheme blocked without extraLinkSchemes',
        (tester) async {
      String? tappedUrl;
      final doc = DocumentNode(children: [
        BlockNode(tagName: 'p', children: [
          InlineNode(
            tagName: 'a',
            attributes: {'href': 'myapp://open/article/123'},
            children: [TextNode('Open in app')],
          ),
        ]),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(
        document: doc,
        onLinkTap: (url) => tappedUrl = url,
      )));
      await tester.pump();

      await tapLink(tester);

      // 'myapp' scheme not in built-in set → blocked
      expect(tappedUrl, isNull);
    });

    testWidgets('custom scheme allowed with extraLinkSchemes', (tester) async {
      String? tappedUrl;
      final doc = DocumentNode(children: [
        BlockNode(tagName: 'p', children: [
          InlineNode(
            tagName: 'a',
            attributes: {'href': 'myapp://open/article/123'},
            children: [TextNode('Open in app')],
          ),
        ]),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(
        document: doc,
        config: const HyperRenderConfig(extraLinkSchemes: {'myapp'}),
        onLinkTap: (url) => tappedUrl = url,
      )));
      await tester.pump();

      await tapLink(tester);

      expect(tappedUrl, 'myapp://open/article/123');
    });

    testWidgets(
        'https link triggers onLinkTap (standard scheme always allowed)',
        (tester) async {
      String? tappedUrl;
      final doc = DocumentNode(children: [
        BlockNode(tagName: 'p', children: [
          InlineNode(
            attributes: {'href': 'https://safe.example.com'},
            tagName: 'a',
            children: [TextNode('Safe link')],
          ),
        ]),
      ]);

      await tester.pumpWidget(_app(HyperRenderWidget(
        document: doc,
        onLinkTap: (url) => tappedUrl = url,
      )));
      await tester.pump();

      await tapLink(tester);

      expect(tappedUrl, 'https://safe.example.com');
    });
  });
}
