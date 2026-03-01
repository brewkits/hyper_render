import "package:hyper_render/hyper_render.dart";
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Selection Integration Tests', () {
    testWidgets('selection across plain text', (tester) async {
      const html = '<p>This is a test paragraph for selection testing.</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: html,
              selectable: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap to start selection
      await tester.tapAt(const Offset(50, 50));
      await tester.pump();

      // Selection should work (no exceptions)
      expect(tester.takeException(), isNull);
    });

    testWidgets('selection across styled text', (tester) async {
      const html = '''
<p>
  Normal text <strong>bold text</strong> <em>italic text</em>
  <u>underlined text</u> and <a href="#">link text</a>.
</p>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: html,
              selectable: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should be able to select across different styles
      await tester.longPressAt(const Offset(100, 50));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('selection across multiple paragraphs', (tester) async {
      const html = '''
<div>
  <p>First paragraph with some content.</p>
  <p>Second paragraph with more content.</p>
  <p>Third paragraph continues the text.</p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: html,
                selectable: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Long press should initiate selection
      await tester.longPressAt(const Offset(100, 50));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('selection with inline images (WidgetSpan)', (tester) async {
      const html = '''
<p>
  Text before
  <img src="https://picsum.photos/50/50" style="display: inline;">
  text after image.
</p>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: html,
              selectable: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.longPressAt(const Offset(100, 50));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('selection in code blocks', (tester) async {
      const html = '''
<pre><code>function test() {
  console.log('Hello');
  return true;
}</code></pre>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: html,
              selectable: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.longPressAt(const Offset(100, 50));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('selection in lists', (tester) async {
      const html = '''
<ul>
  <li>First item with some text</li>
  <li>Second item with more text</li>
  <li>Third item continues</li>
</ul>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: html,
              selectable: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.longPressAt(const Offset(100, 50));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('selection in tables', (tester) async {
      const html = '''
<table>
  <tr>
    <td>Cell 1</td>
    <td>Cell 2</td>
  </tr>
  <tr>
    <td>Cell 3</td>
    <td>Cell 4</td>
  </tr>
</table>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: html,
              selectable: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.longPressAt(const Offset(50, 50));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('selection with CJK text', (tester) async {
      const html = '''
<div>
  <p>日本語のテキストです。選択できます。</p>
  <p>中文文本也可以选择。</p>
  <p>한국어 텍스트도 선택할 수 있습니다.</p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: html,
              selectable: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.longPressAt(const Offset(100, 50));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('selection with RTL text', (tester) async {
      const html = '''
<div dir="rtl">
  <p>هذا نص عربي للاختبار</p>
  <p>בדיקת טקסט בעברית</p>
</div>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: html,
              selectable: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(100, 100));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('selection with mixed content', (tester) async {
      const html = '''
<article>
  <h1>Article Title</h1>
  <p>Paragraph with <strong>bold</strong>, <em>italic</em>, and <code>code</code>.</p>
  <blockquote>Quoted text here</blockquote>
  <ul>
    <li>List item one</li>
    <li>List item two</li>
  </ul>
</article>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: html,
                selectable: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.longPressAt(const Offset(100, 50));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('selection: disabled when selectable=false', (tester) async {
      const html = '<p>This text should not be selectable.</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: html,
              selectable: false,  // Disable selection
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Long press should not trigger selection
      await tester.longPressAt(const Offset(100, 50));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('selection in long documents', (tester) async {
      // Generate long document
      final buffer = StringBuffer('<article>');
      for (int i = 1; i <= 50; i++) {
        buffer.write('<p>Paragraph $i with selectable content. ');
        buffer.write('This paragraph has enough text to make selection meaningful.</p>');
      }
      buffer.write('</article>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: buffer.toString(),
                selectable: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select in first paragraph
      await tester.longPressAt(const Offset(100, 50));
      await tester.pump();

      expect(tester.takeException(), isNull);

      // Verify HyperViewer rendered the long document
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('selection with emoji', (tester) async {
      const html = '''
<p>
  Text with emoji: 🚀 🎉 ✅ ❌ ⚠️
  Complex emoji: 👨‍👩‍👧‍👦 🏳️‍🌈
</p>
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: html,
              selectable: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.longPressAt(const Offset(100, 50));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('selection: performance with large selection', (tester) async {
      // Document with lots of text
      final largeText = 'Lorem ipsum dolor sit amet ' * 500;
      final html = '<p>$largeText</p>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: html,
                selectable: true,
              ),
            ),
          ),
        ),
      );

      // Use pump() instead of pumpAndSettle() to avoid timeout
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final stopwatch = Stopwatch()..start();

      // Start selection
      await tester.longPressAt(const Offset(100, 100));
      await tester.pump();

      stopwatch.stop();

      // Selection should be fast even on large text (< 50ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: 'Selection on large text should be < 50ms');

      expect(tester.takeException(), isNull);
    });
  });
}
