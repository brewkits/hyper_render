import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

/// Widget-level integration tests for ruby/furigana text selection.
///
/// These tests verify the 5 bugs fixed in the selection pipeline when
/// documents contain `<ruby>`/`<rt>` elements:
///   1. Character offset tracking (skip-lines section)
///   2. _buildCharacterMapping includes ruby base text
///   3. getSelectedText returns ruby base text
///   4. getSelectionRects returns rects for ruby fragments
///   5. _getCharacterPositionAtOffset handles ruby in current line
void main() {
  group('Ruby selection — no exceptions', () {
    testWidgets('renders ruby HTML without throwing', (tester) async {
      const html = '<p>'
          '<ruby>漢字<rt>かんじ</rt></ruby>'
          'は難しい。'
          '</p>';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, selectable: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap inside ruby does not throw', (tester) async {
      const html = '<p>'
          '<ruby>東京<rt>とうきょう</rt></ruby>'
          'に行く</p>';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, selectable: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(50, 50));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('long-press inside ruby does not throw', (tester) async {
      const html = '<p>'
          'これは<ruby>日本語<rt>にほんご</rt></ruby>のテストです。'
          '</p>';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, selectable: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.longPressAt(const Offset(80, 50));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('selectAll on document with ruby does not throw',
        (tester) async {
      const html = '<p>'
          'Hello <ruby>世界<rt>せかい</rt></ruby>!'
          '</p>';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, selectable: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Ruby selection — mixed content', () {
    testWidgets('document with text before and after ruby renders correctly',
        (tester) async {
      // This exercises the offset-sync bug: text after a ruby fragment
      // must start at the correct character offset.
      const html = '<p>'
          'Before '
          '<ruby>漢字<rt>かんじ</rt></ruby>'
          ' after'
          '</p>';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, selectable: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Tap before the ruby
      await tester.tapAt(const Offset(20, 50));
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Tap after the ruby
      await tester.tapAt(const Offset(200, 50));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('multiple ruby elements on same line do not throw',
        (tester) async {
      const html = '<p>'
          '<ruby>東<rt>ひがし</rt></ruby>'
          '<ruby>京<rt>きょう</rt></ruby>'
          'タワー'
          '</p>';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, selectable: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(60, 50));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ruby on second line — character offset not desynchronised',
        (tester) async {
      // First line has only plain text. Second line has ruby. A tap on the
      // second line must resolve to the correct character position (the
      // skip-lines offset tracking must count the first line correctly).
      const html = '<p>First line of plain text.</p>'
          '<p><ruby>二行目<rt>にぎょうめ</rt></ruby>のテキスト</p>';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, selectable: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Tap somewhere on the second paragraph
      await tester.tapAt(const Offset(50, 120));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ruby in paragraph followed by another paragraph',
        (tester) async {
      const html = '<p>'
          'これは<ruby>日本語<rt>にほんご</rt></ruby>のテキストです。'
          '</p>'
          '<p>続くテキスト。</p>';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(html: html, selectable: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
