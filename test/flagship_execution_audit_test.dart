// FLAGSHIP EXECUTION AUDIT — the differential net for the *features*, not the
// CSS properties.
//
// test/style/css_execution_guard_test.dart pins CSS declarations against the
// "parsed but never rendered" bug class. This file does the same for the
// headline capabilities the README and demos sell: float wrapping, CJK ruby,
// whole-document selection, virtualized/paged rendering, the plugin API, inline
// SVG, sanitization, and canvas-tier animation.
//
// Every case is DIFFERENTIAL: it asserts that turning the feature on produces
// output measurably different from turning it off, measured through real
// rendered geometry or the real widget tree — never through ComputedStyle or a
// string. A feature that silently stops executing flips one of these to "equal"
// and fails loudly, instead of continuing to "render something".

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

/// Rendered height of [html] at a fixed width.
Future<double> _height(
  WidgetTester tester,
  String html, {
  double width = 400,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: SingleChildScrollView(child: HyperViewer(html: html)),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return tester.getSize(find.byType(HyperViewer)).height;
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(400, 600),
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(width: size.width, height: size.height, child: child),
    ),
  ));
  await tester.pump();
}

/// A block-tier plugin for the plugin-API case.
class _BadgePlugin implements HyperNodePlugin {
  const _BadgePlugin();

  @override
  List<String> get tagNames => const ['x-badge'];

  @override
  bool get isInline => false;

  @override
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) =>
      const SizedBox(key: ValueKey('badge'), width: 120, height: 90);
}

void main() {
  group('Float layout', () {
    testWidgets('a floated box shares its vertical band with following text',
        (tester) async {
      // Sized box, no content of its own — the case float is built for.
      const box =
          '<div style="width:150px;height:120px;background:#ccc"></div>';
      const text = '<p>One two three four five six seven eight nine ten '
          'eleven twelve thirteen.</p>';

      final floated = await _height(
        tester,
        '${box.replaceFirst('style="', 'style="float:left;')}$text',
      );
      final stacked = await _height(tester, '$box$text');

      // Unfloated, the empty box collapses to zero and only the paragraph has
      // height; floated, it reserves its 120px band beside the text. Equal
      // heights would mean float stopped executing.
      expect(floated, greaterThan(stacked));
      expect(floated, greaterThanOrEqualTo(120));
    });

    testWidgets('clear cancels the wrap', (tester) async {
      const box =
          '<div style="float:left;width:160px;height:100px;background:#ccc"></div>';
      const text = 'Short paragraph beside the float.';
      final wrapped = await _height(tester, '$box<p>$text</p>');
      final cleared =
          await _height(tester, '$box<p style="clear:both">$text</p>');

      expect(cleared, greaterThan(wrapped));
    });

    testWidgets(
        'KNOWN GAP — a floated block sized by its own text is not floated',
        (tester) async {
      // A float fragment reserves a box from `width`/`height`; it does not lay
      // the floated element's own content out inside that box. So a floated
      // <div> that would get its height from its text renders that text in
      // normal flow instead, and floating changes nothing.
      //
      // Documented in doc/LIMITATIONS.md. This asserts the CURRENT behaviour so
      // the gap cannot widen unnoticed — when floated block content is
      // implemented, this expectation is the one to flip to `lessThan`.
      const text = 'One two three four five six seven eight nine ten eleven '
          'twelve thirteen.';
      const floatedDiv = '<div style="float:left;width:150px">$text</div>';
      const para = '<p>$text</p>';

      final floated = await _height(tester, '$floatedDiv$para');
      final stacked = await _height(
        tester,
        '${floatedDiv.replaceFirst("float:left;", "")}$para',
      );

      expect(floated, stacked,
          reason: 'if this now differs, floated block content works — update '
              'the matrix, LIMITATIONS.md and this test together');
    });
  });

  group('Float — inline', () {
    testWidgets('KNOWN GAP — float on an inline span (drop cap) does nothing',
        (tester) async {
      // The classic drop-cap idiom. Two demo screens use it; neither actually
      // wraps. Same root cause as the block case: the float box is sized from
      // the element's own box properties, and a span has none.
      const drop = '<p><span style="font-size:48px;line-height:1;FLOAT'
          'margin:8px 12px 0 0">A</span>The rest of the paragraph would wrap '
          'around the drop cap for two or three lines of body text.</p>';

      final floated =
          await _height(tester, drop.replaceFirst('FLOAT', 'float:left;'));
      final plain = await _height(tester, drop.replaceFirst('FLOAT', ''));

      expect(floated, plain,
          reason: 'flip this to lessThan when inline floats are implemented');
    });
  });

  group('CJK ruby typography', () {
    testWidgets('rt annotations occupy space above the base text',
        (tester) async {
      // Ruby text is positioned above its base, so the line box is taller than
      // the same base characters alone. An implementation that dropped <rt> to
      // an inline run would render the SAME height (or wider), not taller.
      final withRuby = await _height(
        tester,
        '<p><ruby>漢<rt>かん</rt>字<rt>じ</rt></ruby></p>',
      );
      final withoutRuby = await _height(tester, '<p>漢字</p>');

      expect(withRuby, greaterThan(withoutRuby));
    });
  });

  group('Render modes', () {
    // Markdown, not HTML: the HTML path parses through an async chain that
    // FakeAsync does not drive to completion, so an HTML document would still
    // be "loading" here. (Verified separately with tester.runAsync: HTML in
    // virtualized mode does build its ListView once real async runs — this is
    // a test-environment constraint, not a rendering gap. Same convention as
    // test/v120/paged_mode_test.dart and hyper_viewer_image_loader_test.dart.)
    final longMarkdown = List.generate(
      400,
      (i) => 'Paragraph $i with enough text to take a full line or two.\n\n',
    ).join();

    testWidgets('virtualized mode builds a ListView, sync mode does not',
        (tester) async {
      await _pump(
        tester,
        HyperViewer.markdown(
          markdown: longMarkdown,
          mode: HyperRenderMode.virtualized,
        ),
      );
      expect(find.byType(ListView), findsWidgets,
          reason: 'virtualized mode renders through ListView.builder');

      await _pump(
        tester,
        const HyperViewer(html: '<p>Short</p>', mode: HyperRenderMode.sync),
      );
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('paged mode builds a PageView with more than one page',
        (tester) async {
      final controller = HyperPageController();
      addTearDown(controller.dispose);

      await _pump(
        tester,
        HyperViewer.markdown(
          markdown: longMarkdown,
          mode: HyperRenderMode.paged,
          pageController: controller,
        ),
      );

      expect(find.byType(PageView), findsOneWidget);
      expect(controller.pageCount, greaterThan(1),
          reason: 'the document must be split across pages, not shown whole');
    });

    testWidgets('auto mode switches on document size', (tester) async {
      await _pump(tester, const HyperViewer.markdown(markdown: 'Tiny'));
      final smallUsesList = find.byType(ListView).evaluate().isNotEmpty;

      await _pump(tester, HyperViewer.markdown(markdown: longMarkdown));
      final largeUsesList = find.byType(ListView).evaluate().isNotEmpty;

      expect(smallUsesList, isFalse,
          reason: 'a short document must render in one pass');
      expect(largeUsesList, isTrue,
          reason: 'past the 10,000-char threshold auto must virtualize');
    });
  });

  group('Selection', () {
    testWidgets(
        'the selection overlay is the default path and can be opted out',
        (tester) async {
      await _pump(tester, const HyperViewer(html: '<p>Selectable text</p>'));
      expect(find.byType(HyperSelectionOverlay), findsOneWidget);

      await _pump(
        tester,
        const HyperViewer(html: '<p>Selectable text</p>', selectable: false),
      );
      expect(find.byType(HyperSelectionOverlay), findsNothing);
    });

    testWidgets('long-press + drag selects across canvas-painted text',
        (tester) async {
      await _pump(
          tester, const HyperViewer(html: '<p>Hello selectable world</p>'));
      await tester.pump();

      final overlay = tester.state<HyperSelectionOverlayState>(
        find.byType(HyperSelectionOverlay),
      );
      expect(overlay.hasSelection, isFalse);

      final gesture = await tester.startGesture(
          tester.getTopLeft(find.byType(HyperRenderWidget)) +
              const Offset(20, 10));
      await tester.pump(const Duration(milliseconds: 600)); // long-press wins

      // NOTE — deliberate assertion of CURRENT behaviour, not of the platform
      // convention: a long-press with no drag only drops a collapsed anchor
      // (RenderHyperBox.startSelectionAt sets start == end), so nothing is
      // selected yet. iOS/Android and Flutter's own SelectableText select the
      // word under the finger at this point. If word-granularity long-press is
      // ever implemented, THIS expectation is the one to flip.
      expect(overlay.hasSelection, isFalse);

      await gesture.moveBy(const Offset(120, 0));
      await tester.pump();
      expect(overlay.hasSelection, isTrue,
          reason: 'dragging after the long-press must extend the selection');
      expect(overlay.selectedText, isNotEmpty);

      await gesture.up();
      await tester.pump();
      // Selection survives the pointer release — it lives on the single
      // RenderObject, not on a transient gesture.
      expect(overlay.hasSelection, isTrue);
    });

    testWidgets('selectAll covers the whole document in one RenderObject',
        (tester) async {
      await _pump(tester,
          const HyperViewer(html: '<p>First para</p><p>Second para</p>'));
      await tester.pump();

      final overlay = tester.state<HyperSelectionOverlayState>(
        find.byType(HyperSelectionOverlay),
      );
      overlay.selectAll();
      await tester.pump();

      // Whole-document selection across block boundaries is the architectural
      // claim; a widget-tree renderer selects per-widget.
      expect(overlay.selectedText, contains('First para'));
      expect(overlay.selectedText, contains('Second para'));
    });
  });

  group('Plugin API', () {
    testWidgets('a registered tag renders the plugin widget', (tester) async {
      // Default `sanitize: true` on purpose. A custom tag is in no default
      // allow-list, so before HyperViewer merged the registry's tags into the
      // sanitizer's list, the documented three-line plugin setup rendered
      // NOTHING — no error, just a blank space where the widget should be.
      final registry = HyperPluginRegistry()..register(const _BadgePlugin());

      await _pump(
        tester,
        HyperViewer(
          html: '<p>Before</p><x-badge></x-badge><p>After</p>',
          pluginRegistry: registry,
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('badge')), findsOneWidget);
    });

    testWidgets('an unregistered tag does not produce the widget',
        (tester) async {
      await _pump(
        tester,
        const HyperViewer(html: '<p>Before</p><x-badge></x-badge>'),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('badge')), findsNothing);
    });
  });

  group('Inline SVG', () {
    testWidgets('renders from markup, not through a network loader',
        (tester) async {
      await _pump(
        tester,
        const HyperViewer(
          html: '<p>Art</p><svg xmlns="http://www.w3.org/2000/svg" '
              'viewBox="0 0 10 10"><rect width="10" height="10"/></svg>',
        ),
      );
      await tester.pump();

      final svg = find.byType(SvgPicture);
      expect(svg, findsOneWidget);
      // SvgNetworkLoader here would mean the markup was thrown away and a URL
      // fetched instead — the failure mode that looks identical in a
      // findsOneWidget assertion.
      expect(
          tester.widget<SvgPicture>(svg).bytesLoader, isA<SvgStringLoader>());
    });
  });

  group('Sanitization', () {
    testWidgets('script content is dropped while surrounding text survives',
        (tester) async {
      final clean = await _height(tester, '<p>Safe paragraph</p>');
      final withScript = await _height(
        tester,
        '<p>Safe paragraph</p><script>alert("xss")</script>',
      );

      expect(withScript, clean,
          reason: 'a stripped <script> must contribute no rendered content');
    });

    testWidgets('an unsafe img src is neutralised', (tester) async {
      // UrlSafety blocks javascript:/data:非-image/file: — the adapter blanks
      // the src rather than handing it to the image loader.
      final loaded = <String>[];
      await _pump(
        tester,
        HyperViewer(
          html: '<img src="javascript:alert(1)"/>',
          imageLoader: (src, onLoad, onError) => loaded.add(src),
        ),
      );
      await tester.pump();

      expect(loaded, isEmpty);
    });
  });

  group('Canvas-tier animation', () {
    testWidgets('an animated block schedules frames; a static one does not',
        (tester) async {
      const css = '@keyframes fade { from { opacity: 1 } to { opacity: 0 } }';

      await _pump(
        tester,
        const HyperViewer(
          html: '<style>$css</style>'
              '<div style="animation: fade 2s linear infinite">Animated</div>',
        ),
      );
      // pump(1ms) fires the zero-delay start timer AND delivers a first tick;
      // a bare pump() does neither.
      await tester.pump(const Duration(milliseconds: 1));
      final animatedCallbacks =
          SchedulerBinding.instance.transientCallbackCount;

      await _pump(tester, const HyperViewer(html: '<div>Static</div>'));
      await tester.pump(const Duration(milliseconds: 1));
      final staticCallbacks = SchedulerBinding.instance.transientCallbackCount;

      expect(animatedCallbacks, greaterThan(staticCallbacks),
          reason: 'a running animation must keep scheduling frames');
    });
  });

  group('Block sizing', () {
    testWidgets('KNOWN GAP — min-height / max-height never reach layout',
        (tester) async {
      // Both parse into ComputedStyle (resolver.dart) and both are read by
      // nothing in the render path — verified by grep as well as by these
      // measurements. doc/CSS_PROPERTIES_MATRIX.md marked them fully supported
      // until this audit; it now says otherwise.
      final plain = await _height(tester, '<div>x</div>');
      final minned =
          await _height(tester, '<div style="min-height:120px">x</div>');
      expect(minned, plain, reason: 'min-height does not execute');

      const fiveLines = 'one<br/>two<br/>three<br/>four<br/>five';
      final tall = await _height(tester, '<div>$fiveLines</div>');
      final capped = await _height(
          tester, '<div style="max-height:40px">$fiveLines</div>');
      expect(capped, tall, reason: 'max-height does not execute');
    });

    testWidgets('height applies to replaced elements, not to plain blocks',
        (tester) async {
      // This asymmetry IS what the matrix documents ("Absolute px on replaced
      // elements"); pinned here so the documented scope stays true.
      final divPlain = await _height(tester, '<div>x</div>');
      final divTall =
          await _height(tester, '<div style="height:200px">x</div>');
      expect(divTall, divPlain);
    });
  });

  group('Tables', () {
    testWidgets('each row adds height', (tester) async {
      const cell = '<tr><td>Cell A</td><td>Cell B</td></tr>';
      final twoRows = await _height(tester, '<table>$cell$cell</table>');
      final fourRows =
          await _height(tester, '<table>$cell$cell$cell$cell</table>');

      expect(fourRows, greaterThan(twoRows));
    });
  });
}
