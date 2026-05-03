import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  final String testHtml = '''
<div style="font-family: sans-serif; padding: 20px; font-size: 18px; line-height: 1.0;">
  <h1 id="title">Title</h1>
  <p id="ruby">
    <ruby>漢<rt>かん</rt></ruby><ruby>字<rt>じ</rt></ruby>
  </p>
  <p id="kinsoku" style="width: 100px;">
    あいうえおかきくけこさしすせそ
  </p>
  <p id="bidi">
    English مرحبا English
  </p>
</div>
''';

  testWidgets('Sprint 2 Auto-QA (Refined)', (tester) async {
    tester.view.physicalSize = const Size(400 * 3.0, 800 * 3.0);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HyperViewer(
          html: testHtml,
          mode: HyperRenderMode.sync, // Use sync to make it easier
          selectable: true,
        ),
      ),
    ));

    await tester.pumpAndSettle();

    final box =
        tester.renderObject<RenderHyperBox>(find.byType(HyperRenderWidget));

    debugPrint('\n======================================================');
    debugPrint('=== [QA LOG] REFINED TYPOGRAPHY TEST ===');

    // 1. Test Ruby Height
    // "Title" is ~5 chars. "Title" + newline + spacing...
    // Let's just select a huge range to be sure we hit the Ruby.
    box.selection = const HyperTextSelection(start: 0, end: 100);
    final selectedText = box.getSelectedText();
    debugPrint('Selected Text: $selectedText');

    final rects = box.getSelectionRects();
    debugPrint('Selection Rects Count: ${rects.length}');
    for (var r in rects) {
      debugPrint(
          '  Rect: h=${r.height.toStringAsFixed(1)}, top=${r.top.toStringAsFixed(1)}, bottom=${r.bottom.toStringAsFixed(1)}');
    }

    // 2. Kinsoku Shori Right-Edge
    // Check if any rect exceeds chunk width
    double maxR = 0;
    for (var r in rects) {
      if (r.right > maxR) {
        maxR = r.right;
      }
    }
    debugPrint('Max Right Edge: $maxR (Constraint: ${box.size.width})');

    debugPrint('======================================================\n');

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
