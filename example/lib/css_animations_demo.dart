import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

/// Demo showcase for CSS Keyframes and Animations in HyperRender.
///
/// Demonstrates:
/// - CSS @keyframes definition
/// - Animation shorthand property
/// - Multi-state animations (fade, slide, rotate)
/// - v1.5.0: cubic-bezier()/steps() timing and color/background-color keyframes
class CssAnimationsDemo extends StatelessWidget {
  const CssAnimationsDemo({super.key});

  final String _htmlContent = '''
    <style>
      @keyframes fade {
        from { opacity: 0; }
        to { opacity: 1; }
      }
      @keyframes slide {
        from { transform: translateX(-50px); }
        to { transform: translateX(0); }
      }
      @keyframes rotate {
        from { transform: rotate(0deg); }
        to { transform: rotate(360deg); }
      }
      @keyframes glow {
        from { background-color: #6366f1; }
        to { background-color: #ec4899; }
      }
      .box {
        width: 100px;
        height: 100px;
        background: #6366f1;
        margin: 20px;
        display: inline-block;
      }
    </style>
    <h1>CSS Animations Demo</h1>
    <p>HyperRender supports standard CSS keyframes with <code>animation</code> property.</p>

    <h3>Fade Animation</h3>
    <div class="box" style="animation: fade 2s infinite alternate;"></div>

    <h3>Slide Animation (cubic-bezier)</h3>
    <div class="box" style="animation: slide 1s cubic-bezier(0.68, -0.55, 0.27, 1.55) infinite alternate;"></div>

    <h3>Rotate Animation (steps)</h3>
    <div class="box" style="animation: rotate 3s steps(8, end) infinite;"></div>

    <h3>Color Animation (v1.5.0)</h3>
    <div class="box" style="animation: glow 1.5s ease-in-out infinite alternate;"></div>
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CSS Animations Demo')),
      body: HyperViewer(
        html: _htmlContent,
        enableComplexFilters: true,
      ),
    );
  }
}
