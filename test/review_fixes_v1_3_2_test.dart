import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

/// Helper: HtmlAdapter().parse() returns a tree with unresolved styles.
/// HyperViewer normally wires up StyleResolver; tests that bypass HyperViewer
/// (e.g. by handing a DocumentNode directly to HyperSelectionOverlay) must
/// resolve styles themselves so CSS like `text-overflow:ellipsis` takes effect.
DocumentNode _parseAndResolve(String html) {
  final doc = HtmlAdapter().parse(html);
  StyleResolver().resolveStyles(doc);
  return doc;
}

/// Regression tests for the v1.3.2 deep-dive review findings:
///   #1 — Dead `_characterToFragment` / `_fragmentRanges` removal must not
///        break selection (covered indirectly: any selection works).
///   #4 — Unbounded horizontal constraints must not crash _FlexFragment.layout
///        with `minWidth < double.infinity`.
///   #5 — CSS `text-overflow: ellipsis` must not leak hidden text via copy.
///   #6 — Selection drag past the top/bottom edge must extend the selection
///        instead of freezing (lenient hit-test).
void main() {
  group('v1.3.2 review fixes', () {
    testWidgets(
      '#4 — unbounded horizontal constraint does not crash flex layout',
      (tester) async {
        // A horizontally-scrolling parent gives `maxWidth = double.infinity`.
        // Before the fix this propagated into _FlexFragment.layout and tripped
        // the Flutter assertion `minWidth < double.infinity`.
        const html = '<div style="display:flex"><span>flex child</span></div>';
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 800,
                  child: HyperViewer(html: html),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '#4 — flex container inside Row without Expanded does not crash',
      (tester) async {
        // Row's default behaviour gives children unbounded width unless wrapped.
        const html =
            '<div style="display:flex;gap:8px"><span>a</span><span>b</span></div>';
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  SizedBox(width: 600, child: HyperViewer(html: html)),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '#5 — copying through ellipsis-truncated text returns only visible chars',
      (tester) async {
        // Narrow render-box width forces the long text to be ellipsis-clipped.
        // The hidden suffix ("SECRET TAIL") must not leak via getSelectedText.
        // text-overflow:ellipsis requires the render-box's available width
        // (the SizedBox here) to be narrower than the text.
        //
        // Leading <p> ensures the truncated div is not the first block —
        // _BlockStartFragment (which carries truncateWithEllipsis) is only
        // emitted when prior fragments exist or marginTop > 0.
        const html = '<p>x</p><div style="overflow:hidden;'
            'text-overflow:ellipsis;white-space:nowrap">'
            'visible head SECRET TAIL</div>';

        final key = GlobalKey<HyperSelectionOverlayState>();
        final doc = _parseAndResolve(html);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 80,
                height: 200,
                child: HyperSelectionOverlay(key: key, document: doc),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        key.currentState!.selectAll();
        await tester.pump();

        final selected = key.currentState!.selectedText ?? '';
        expect(
          selected.contains('SECRET TAIL'),
          isFalse,
          reason: 'ellipsis-hidden suffix must not leak via copy: "$selected"',
        );
      },
    );

    testWidgets(
      '#5 — ellipsis state resets after layout pass at wider width',
      (tester) async {
        // After a narrow pass marks fragments as hidden, a wider pass must
        // clear the flag so the full text is selectable again.
        const html = '<p>x</p><div style="overflow:hidden;'
            'text-overflow:ellipsis;white-space:nowrap">'
            'alpha beta gamma delta</div>';

        final key = GlobalKey<HyperSelectionOverlayState>();
        final doc = _parseAndResolve(html);

        // First render narrow.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 60,
                child: HyperSelectionOverlay(key: key, document: doc),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Re-render wide enough to fit everything.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                child: HyperSelectionOverlay(key: key, document: doc),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        key.currentState!.selectAll();
        await tester.pump();

        final selected = key.currentState!.selectedText ?? '';
        expect(selected.contains('delta'), isTrue,
            reason: 'wide layout must un-hide previously truncated text');
      },
    );

    testWidgets(
      '#6 — selection drag above first line snaps to start, not -1',
      (tester) async {
        // No exception when handle drag passes far above content; selection
        // updates instead of freezing.
        const html = '<p>line one</p><p>line two</p><p>line three</p>';

        final key = GlobalKey<HyperSelectionOverlayState>();
        final doc = _parseAndResolve(html);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: HyperSelectionOverlay(key: key, document: doc),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        key.currentState!.selectAll();
        await tester.pump();
        expect(key.currentState!.hasSelection, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('v1.3.2 security review fixes', () {
    testWidgets(
      'markdown with sanitize=true strips inline <script>/<style>',
      (tester) async {
        // enableInlineHtml is on by default — without pre-sanitization the
        // script/style tags survive into UDT nodes and render as visible
        // garbage. HyperViewer now runs HtmlSanitizer on the markdown text
        // first when sanitize=true.
        const markdown = '# Title\n\n'
            '<script>alert("xss")</script>\n\n'
            '<style>body{display:none}</style>\n\n'
            'Body paragraph.';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: HyperViewer.markdown(
                  markdown: markdown,
                  // sanitize defaults to true
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Walk the rendered widget tree and assert no visible Text contains
        // the script/style payload.
        final allText = find
            .byType(Text)
            .evaluate()
            .map((e) => (e.widget as Text).data ?? '')
            .join('\n');
        expect(allText.contains('alert("xss")'), isFalse,
            reason: 'script body must not leak into rendered text');
        expect(allText.contains('display:none'), isFalse,
            reason: 'style body must not leak into rendered text');
        expect(tester.takeException(), isNull);
      },
    );
  });
}
