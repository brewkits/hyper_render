import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

class Sprint2Demo extends StatefulWidget {
  const Sprint2Demo({super.key});

  @override
  State<Sprint2Demo> createState() => _Sprint2DemoState();
}

class _Sprint2DemoState extends State<Sprint2Demo> {
  late final String _html = '''
  <div style="font-family: sans-serif; padding: 20px; font-size: 18px; line-height: 1.8;">
  <h1 style="color: #2c3e50;">Sprint 2: Text Selection & CJK Chaos</h1>
  <p>This document combines Bi-directional text (Arabic), Japanese Kinsoku (line breaking), and Furigana (Ruby) to test the robustness of the Custom RenderBox selection bounds and highlight painting.</p>

  <h2 style="color: #c0392b;">1. Japanese Ruby (Furigana)</h2>
  <p style="font-size: 24px;">
    <ruby>漢<rt>かん</rt></ruby>
    <ruby>字<rt>じ</rt></ruby>
    の
    <ruby>読<rt>よ</rt></ruby>み
    <ruby>方<rt>かた</rt></ruby>
    をテストしています。
  </p>
  <p>Try selecting across the Ruby characters. The blue highlight box should properly cover the base characters and extend upwards to cover the annotation (rt) without clipping.</p>

  <h2 style="color: #c0392b;">2. Kinsoku Shori (Line Breaking)</h2>
  <p style="width: 250px; background: #f0f0f0; padding: 10px; border: 1px solid #ccc;">
    これは非常に長い日本語の文章です。行の終わりに句読点が来る場合、それを次の行の先頭に配置することは禁止されています（禁則処理）。「たと えば、このような括弧の開始」が、行の最後に単独で配置されることもありません。
  </p>
  <p>Select text wrapping around the edge of the grey box. The highlight should wrap perfectly without drawing outside the text boundaries.</p>

  <h2 style="color: #c0392b;">3. Bi-Directional (BiDi) LTR & RTL</h2>
  <p style="font-size: 22px;">
    Here is an English sentence containing Arabic text: 
    <span style="color: #2980b9;">مرحبا بك في اختبار التحديد المعقد</span>
    which means "Welcome to the complex selection test".
  </p>
  <p>Try dragging the selection handle across the Arabic text. Notice how the visual handle might jump due to logical vs visual ordering of BiDi text. Ensure it doesn't crash.</p>

  <h2 style="color: #c0392b;">4. Cross-Chunk Selection</h2>
  <p>The following blocks repeat to force Virtualization. Start selecting here, and scroll down to select text multiple paragraphs below.</p>
  \${List.generate(
          50,
          (i) => \'\'\'
  <div style="margin-top: 20px; padding: 10px; border-left: 4px solid #3498db; background: #eaf2f8;">
    <b>Block \$i:</b> 
    Mixed content: <ruby>東<rt>とう</rt></ruby><ruby>京<rt>きょう</rt></ruby> Tower is tall.
    اختبار التحديد. Select me and keep going!
  </div>
  \'\'\').join('\\n')}
  </div>
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sprint 2: Selection & CJK'),
      ),
      body: HyperViewer(
        html: _html,
        mode: HyperRenderMode.virtualized,
        selectable: true,
        selectionHandleColor: Colors.red, // Making the handles very visible
      ),
    );
  }
}
