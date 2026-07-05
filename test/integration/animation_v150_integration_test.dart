// Integration + system tests for v1.5.0 animation features.
//
// Exercises cubic-bezier()/steps() timing functions and animated
// color/background-color end-to-end through HyperViewer, pumping real frames
// to ensure the animation pipeline drives without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

Future<void> _pumpHtml(WidgetTester tester, String html) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: HyperViewer(html: html, mode: HyperRenderMode.sync),
        ),
      ),
    ),
  );
}

void main() {
  group('v1.5.0 animation — integration', () {
    testWidgets('cubic-bezier keyframe animation drives frames',
        (tester) async {
      const html = '''
<style>
  @keyframes slide { from { transform: translateX(-40px); } to { transform: translateX(0); } }
  .b { width: 80px; height: 40px; background: #6366f1; }
</style>
<div class="b" style="animation: slide 1s cubic-bezier(0.4, 0, 0.2, 1) infinite;"></div>
''';
      await _pumpHtml(tester, html);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);
    });

    testWidgets('steps() keyframe animation drives frames', (tester) async {
      const html = '''
<style>
  @keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
  .b { width: 80px; height: 40px; background: #10b981; }
</style>
<div class="b" style="animation: spin 2s steps(8, end) infinite;"></div>
''';
      await _pumpHtml(tester, html);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 750));
      expect(tester.takeException(), isNull);
    });

    testWidgets('color/background-color keyframes animate without throwing',
        (tester) async {
      const html = '''
<style>
  @keyframes glow { from { background-color: #6366f1; color: #ffffff; }
                    to   { background-color: #ec4899; color: #000000; } }
  .b { width: 120px; height: 40px; }
</style>
<div class="b" style="animation: glow 1s ease-in-out infinite alternate;">Hi</div>
''';
      await _pumpHtml(tester, html);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 750));
      expect(tester.takeException(), isNull);
    });

    testWidgets('transition with cubic-bezier renders', (tester) async {
      const html =
          '<div style="opacity:0.4; background-color:#fee; transition: all 0.3s cubic-bezier(0.4,0,0.2,1)">fade</div>';
      await _pumpHtml(tester, html);
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);
    });
  });

  group('v1.5.0 animation — system (mixed document)', () {
    testWidgets('document mixing all timing functions + colors renders clean',
        (tester) async {
      const html = '''
<style>
  @keyframes fade  { from { opacity: 0; } to { opacity: 1; } }
  @keyframes glow  { from { background-color: #fffbdd; } to { background-color: #ffffff; } }
  @keyframes spin  { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
  .box { width: 60px; height: 60px; background: #333; display: inline-block; margin: 8px; }
</style>
<h1>Animation Gallery</h1>
<p>Every timing function in one document.</p>
<div class="box" style="animation: fade 1s linear infinite alternate;"></div>
<div class="box" style="animation: fade 1s ease-in-out infinite alternate;"></div>
<div class="box" style="animation: spin 2s cubic-bezier(0.68,-0.55,0.27,1.55) infinite;"></div>
<div class="box" style="animation: spin 2s steps(6, start) infinite;"></div>
<div class="box" style="animation: glow 1.5s step-end infinite alternate;"></div>
<p style="transition: color 0.4s ease; color: #6366f1;">Transitioned text.</p>
''';
      await _pumpHtml(tester, html);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });
}
