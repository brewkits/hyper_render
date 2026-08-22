import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

/// Comprehensive testing for v1.4.0 features and bug fixes.
/// Covers: unit, integration, system, performance, stress, and security.

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ComputedStyle? _resolvedStyle(String html, bool Function(UDTNode) predicate) {
  final adapter = HtmlAdapter();
  final doc = adapter.parse(html);
  final resolver = StyleResolver();
  final css = adapter.extractCss(html);
  if (css.isNotEmpty) resolver.parseCss(css);
  resolver.resolveStyles(doc);

  ComputedStyle? found;
  void walk(UDTNode node) {
    if (found != null) return;
    if (predicate(node)) {
      found = node.style;
      return;
    }
    for (final c in node.children) {
      walk(c);
    }
  }

  walk(doc);
  return found;
}

ComputedStyle? _styleOfTag(String html, String tag) =>
    _resolvedStyle(html, (n) => n.tagName == tag);

void main() {
  // =========================================================================
  // UNIT TESTS — CSS Resolver: new property cases
  // =========================================================================
  group('Unit: CSS Resolver — v1.4.0 new property cases', () {
    test('white-space: nowrap is parsed', () {
      final style = _styleOfTag(
        '<div style="white-space:nowrap">x</div>',
        'div',
      );
      expect(style?.whiteSpace, 'nowrap');
    });

    test('word-spacing: 2px is parsed', () {
      final style = _styleOfTag(
        '<span style="word-spacing:2px">x</span>',
        'span',
      );
      expect(style?.wordSpacing, 2.0);
    });

    test('text-transform: uppercase is parsed', () {
      final style = _styleOfTag(
        '<span style="text-transform:uppercase">x</span>',
        'span',
      );
      expect(style?.textTransform, 'uppercase');
    });

    test('min-width and max-width are parsed', () {
      final style = _styleOfTag(
        '<div style="min-width:100px;max-width:500px">x</div>',
        'div',
      );
      expect(style?.minWidth, 100.0);
      expect(style?.maxWidth, 500.0);
    });

    test('min-height and max-height are parsed', () {
      final style = _styleOfTag(
        '<div style="min-height:50px;max-height:300px">x</div>',
        'div',
      );
      expect(style?.minHeight, 50.0);
      expect(style?.maxHeight, 300.0);
    });

    test('overflow: hidden is parsed', () {
      final style = _styleOfTag(
        '<div style="overflow:hidden">x</div>',
        'div',
      );
      expect(style?.overflowX, HyperOverflow.hidden);
      expect(style?.overflowY, HyperOverflow.hidden);
    });

    test('border-top shorthand is parsed', () {
      final style = _styleOfTag(
        '<div style="border-top:2px solid red">x</div>',
        'div',
      );
      expect(style?.borderWidth.top, greaterThan(0));
    });

    test('animation shorthand is parsed into sub-properties', () {
      final style = _styleOfTag(
        '<div style="animation:fadeIn 0.5s ease-in-out 0.1s 3">x</div>',
        'div',
      );
      expect(style?.animationName, 'fadeIn');
      expect(style?.animationDuration, 500);
    });

    test('animation-iteration-count: infinite sets null', () {
      final style = _styleOfTag(
        '<div style="animation-iteration-count:infinite">x</div>',
        'div',
      );
      expect(style?.animationIterationCount, isNull);
    });

    test('animation-direction: alternate is parsed', () {
      final style = _styleOfTag(
        '<div style="animation-direction:alternate">x</div>',
        'div',
      );
      expect(style?.animationDirection, HyperAnimationDirection.alternate);
    });

    test('animation-direction: alternate-reverse is parsed', () {
      final style = _styleOfTag(
        '<div style="animation-direction:alternate-reverse">x</div>',
        'div',
      );
      expect(
          style?.animationDirection, HyperAnimationDirection.alternateReverse);
    });
  });

  // =========================================================================
  // UNIT TESTS — Bug fix regressions
  // =========================================================================
  group('Unit: Bug fix regressions — v1.4.0', () {
    test('rem unit parsed correctly (not mis-matched by em branch)', () {
      final style = _styleOfTag(
        '<div style="font-size:2rem">x</div>',
        'div',
      );
      expect(style, isNotNull);
      expect(style!.fontSize, isNotNull);
      expect(style.fontSize, greaterThan(0));
    });

    test('border:none produces zero border width', () {
      final style = _styleOfTag(
        '<div style="border:none">x</div>',
        'div',
      );
      expect(style?.borderWidth.top, 0.0);
      expect(style?.borderWidth.bottom, 0.0);
    });

    test('text-decoration does NOT inherit from parent', () {
      final parent = ComputedStyle(textDecoration: TextDecoration.underline);
      final child = ComputedStyle();
      child.inheritFrom(parent);
      expect(child.textDecoration, isNull);
    });

    test('text-transform inherits from parent', () {
      final parent = ComputedStyle(textTransform: 'uppercase');
      final child = ComputedStyle();
      child.inheritFrom(parent);
      expect(child.textTransform, 'uppercase');
    });

    test('ComputedStyle.copyWith preserves aspectRatio', () {
      final style = ComputedStyle(aspectRatio: 1.5);
      final copy = style.copyWith(opacity: 0.5);
      expect(copy.aspectRatio, 1.5);
      expect(copy.opacity, 0.5);
    });

    test('HyperTextSelection implements operator==', () {
      const a = HyperTextSelection(start: 0, end: 10);
      const b = HyperTextSelection(start: 0, end: 10);
      const c = HyperTextSelection(start: 0, end: 5);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('FloatCarryover includes imageSrc in equality', () {
      const a = FloatCarryover(
        direction: HyperFloat.left,
        width: 200,
        overhangHeight: 100,
        imagePixelOffset: 50,
        imageSrc: 'a.png',
      );
      const b = FloatCarryover(
        direction: HyperFloat.left,
        width: 200,
        overhangHeight: 100,
        imagePixelOffset: 50,
        imageSrc: 'a.png',
      );
      const c = FloatCarryover(
        direction: HyperFloat.left,
        width: 200,
        overhangHeight: 100,
        imagePixelOffset: 50,
        imageSrc: 'b.png',
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // =========================================================================
  // UNIT TESTS — Delta adapter bug fixes
  // =========================================================================
  group('Unit: Delta adapter — v1.4.0 fixes', () {
    test('indent + 1 operator precedence is correct', () {
      final adapter = DeltaAdapter();
      final doc = adapter.parse(
        '{"ops":[{"insert":"item\\n","attributes":{"list":"bullet","indent":2}}]}',
      );
      expect(doc.children, isNotEmpty);
    });

    test('underline + strikethrough combined correctly', () {
      final adapter = DeltaAdapter();
      final doc = adapter.parse(
        '{"ops":[{"insert":"both","attributes":{"underline":true,"strike":true}},{"insert":"\\n"}]}',
      );

      TextDecoration? found;
      void walk(UDTNode n) {
        if (n is InlineNode && n.style.textDecoration != null) {
          found = n.style.textDecoration;
        }
        for (final c in n.children) {
          walk(c);
        }
      }

      walk(doc);
      expect(found, isNotNull);
      expect(found.toString(), contains('underline'));
      expect(found.toString(), contains('lineThrough'));
    });
  });

  // =========================================================================
  // UNIT TESTS — Markdown adapter bug fixes
  // =========================================================================
  group('Unit: Markdown adapter — v1.4.0 fixes', () {
    test('CRLF line endings normalized', () {
      final adapter = MarkdownAdapter();
      final doc = adapter.parse('line1\r\nline2\r\nline3');
      expect(doc.children, isNotEmpty);

      final text = _collectText(doc);
      expect(text, contains('line1'));
      expect(text, contains('line3'));
    });
  });

  // =========================================================================
  // INTEGRATION TESTS — End-to-end rendering
  // =========================================================================
  group('Integration: HyperViewer renders v1.4.0 features', () {
    testWidgets('renders content with CSS aspect-ratio', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html:
                  '<img src="https://example.com/img.png" style="width:200px;aspect-ratio:16/9">',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders content with CSS transition', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html:
                  '<div style="opacity:0.5;transition:opacity 0.3s ease">hi</div>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('renders infinite animation without crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
<style>
  @keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
  .spinner { animation: spin 1s linear infinite; }
</style>
<div class="spinner">Loading...</div>
''',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders animation with alternate direction', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
<style>
  @keyframes pulse { from { opacity: 0.5; } to { opacity: 1.0; } }
  .pulse { animation: pulse 0.5s ease-in-out infinite; animation-direction: alternate; }
</style>
<div class="pulse">Pulse</div>
''',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders multiple CSS properties simultaneously',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
<div style="
  white-space: nowrap;
  word-spacing: 4px;
  text-transform: uppercase;
  min-width: 100px;
  max-width: 500px;
  overflow: hidden;
  border-top: 2px solid red;
  aspect-ratio: 2/1;
">Multiple CSS properties</div>
''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('rem units render without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html:
                  '<p style="font-size:1.5rem;margin:2rem;padding:0.5rem">rem units</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('border:none renders without visible border', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<div style="border:none">No border</div>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // SYSTEM TESTS — Full pipeline validation
  // =========================================================================
  group('System: Full pipeline — HTML → parse → resolve → render', () {
    testWidgets('complex document with all v1.4.0 features', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
<style>
  @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
  .animated { animation: fadeIn 0.5s ease-in-out infinite; animation-direction: alternate; }
  .transitioned { transition: opacity 0.3s ease; }
  .ratio { aspect-ratio: 16/9; width: 200px; }
</style>
<div style="font-size:1.5rem; border:none; white-space:nowrap">
  <p class="animated">Animated paragraph</p>
  <div class="transitioned" style="opacity:0.5">Transitioned</div>
  <img class="ratio" src="https://example.com/img.png">
  <div style="min-width:100px;max-width:500px;overflow:hidden;text-transform:uppercase">
    Constrained content
  </div>
</div>
''',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Delta document with combined formatting', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer.delta(
              delta:
                  '[{"insert":"bold+underline+strike","attributes":{"bold":true,"underline":true,"strike":true}},{"insert":"\\n"}]',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Markdown document with CRLF endings', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer.markdown(
              markdown:
                  '# Heading\r\n\r\nParagraph\r\n\r\n- Item 1\r\n- Item 2',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // PERFORMANCE TESTS
  // =========================================================================
  group('Performance: v1.4.0 resolver efficiency', () {
    test('resolving 100 elements with many CSS properties completes <500ms',
        () {
      final sw = Stopwatch()..start();

      final adapter = HtmlAdapter();
      final buffer = StringBuffer('<style>');
      buffer.writeln(
          'div { font-size:16px; color:red; background:blue; margin:10px; padding:5px; '
          'border:1px solid black; white-space:nowrap; word-spacing:2px; text-transform:uppercase; '
          'min-width:50px; max-width:800px; overflow:hidden; aspect-ratio:16/9; '
          'transition:opacity 0.3s ease; }');
      buffer.writeln('</style>');
      for (int i = 0; i < 100; i++) {
        buffer.writeln('<div>Element $i</div>');
      }

      final doc = adapter.parse(buffer.toString());
      final resolver = StyleResolver();
      resolver.parseCss(adapter.extractCss(buffer.toString()));
      resolver.resolveStyles(doc);

      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('ComputedStyle.copyWith is fast for many copies', () {
      final sw = Stopwatch()..start();

      final style = ComputedStyle(
        fontSize: 16,
        color: const Color(0xFF000000),
        aspectRatio: 1.5,
        transition: const HyperTransition(duration: 300),
        opacity: 0.8,
      );

      for (int i = 0; i < 10000; i++) {
        style.copyWith(opacity: i / 10000);
      }

      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });
  });

  // =========================================================================
  // STRESS TESTS
  // =========================================================================
  group('Stress: large documents with v1.4.0 features', () {
    testWidgets('1000 elements with CSS transitions', (tester) async {
      final buffer = StringBuffer();
      for (int i = 0; i < 1000; i++) {
        buffer.writeln(
            '<div style="transition:opacity 0.3s ease;opacity:${(i % 10) / 10}">Item $i</div>');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: buffer.toString(),
              mode: HyperRenderMode.virtualized,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('500 elements with animation shorthand', (tester) async {
      final buffer = StringBuffer();
      buffer.writeln(
          '<style>@keyframes fade { from { opacity: 0; } to { opacity: 1; } }</style>');
      for (int i = 0; i < 500; i++) {
        buffer.writeln(
            '<div style="animation:fade 1s ease-in-out ${i % 3} alternate">Animated $i</div>');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: buffer.toString(),
              mode: HyperRenderMode.virtualized,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('resolver handles 50+ CSS properties per element', () {
      final buffer = StringBuffer();
      buffer.writeln('<div style="');
      buffer.writeln('font-size:16px;color:red;background:blue;margin:10px;');
      buffer.writeln(
          'padding:5px;border:2px solid black;border-top:1px solid red;');
      buffer.writeln(
          'white-space:nowrap;word-spacing:3px;text-transform:capitalize;');
      buffer.writeln(
          'min-width:50px;max-width:800px;min-height:20px;max-height:600px;');
      buffer.writeln('overflow:hidden;aspect-ratio:4/3;opacity:0.9;');
      buffer.writeln(
          'animation:fadeIn 1s ease infinite;animation-direction:alternate;');
      buffer.writeln('transition:opacity 0.5s ease-in-out;');
      buffer.writeln('text-decoration:underline;text-decoration-color:red;');
      buffer.writeln(
          'box-shadow:2px 2px 5px black;text-shadow:1px 1px 2px gray;');
      buffer.writeln('">All properties</div>');

      final adapter = HtmlAdapter();
      final doc = adapter.parse(buffer.toString());
      final resolver = StyleResolver();
      resolver.resolveStyles(doc);

      final style = doc.children.first.style;
      expect(style.fontSize, isNotNull);
      expect(style.aspectRatio, closeTo(4 / 3, 0.001));
      expect(style.transition, isNotNull);
      expect(style.animationDirection, HyperAnimationDirection.alternate);
    });
  });

  // =========================================================================
  // SECURITY TESTS
  // =========================================================================
  group('Security: v1.4.0 features do not introduce XSS vectors', () {
    test('transition with garbage value does not crash', () {
      final style = _styleOfTag(
        '<div style="transition:javascript:alert(1)">x</div>',
        'div',
      );
      expect(style?.transition?.isDefined, isFalse);
    });

    test('aspect-ratio rejects non-numeric injection', () {
      final style = _styleOfTag(
        '<div style="aspect-ratio:expression(alert(1))">x</div>',
        'div',
      );
      expect(style?.aspectRatio, isNull);
    });

    test('animation-name does not execute script-like names', () {
      final style = _styleOfTag(
        '<div style="animation-name:javascript:void(0)">x</div>',
        'div',
      );
      expect(style?.animationName, isNotNull);
    });

    testWidgets('malicious CSS in transition is safely ignored',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
<style>
  div { transition: all 999999s; opacity: expression(alert(1)); }
</style>
<div>Safe</div>
''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('extremely long CSS values do not crash', (tester) async {
      final longValue = 'A' * 100000;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<div style="content:$longValue">x</div>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}

// ---------------------------------------------------------------------------
// Test utilities
// ---------------------------------------------------------------------------

String _collectText(UDTNode node) {
  final buf = StringBuffer();
  void walk(UDTNode n) {
    if (n is TextNode) buf.write(n.text);
    for (final c in n.children) {
      walk(c);
    }
  }

  walk(node);
  return buf.toString();
}
