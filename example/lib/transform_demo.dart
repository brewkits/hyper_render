/// CSS Transform Demo
///
/// Demonstrates CSS transform property with Matrix4:
/// - translate (move elements)
/// - rotate (spin elements)
/// - scale (resize elements)
/// - Combined transforms
///
/// HyperRender implements transforms via Flutter's Matrix4,
/// providing native performance.
library;

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

class TransformDemo extends StatelessWidget {
  const TransformDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSS Transform Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.transform, color: Colors.purple.shade700, size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CSS Transform',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Move, rotate, and scale elements with CSS',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Transform property powered by Flutter Matrix4 for native performance',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Example 1: Translate
          _SectionTitle('1. Translate (Move)'),
          HyperViewer(
            html: _translateExample,
          ),

          const SizedBox(height: 24),

          // Example 2: Rotate
          _SectionTitle('2. Rotate'),
          HyperViewer(
            html: _rotateExample,
          ),

          const SizedBox(height: 24),

          // Example 3: Scale
          _SectionTitle('3. Scale (Resize)'),
          HyperViewer(
            html: _scaleExample,
          ),

          const SizedBox(height: 24),

          // Example 4: Combined
          _SectionTitle('4. Combined Transforms'),
          HyperViewer(
            html: _combinedExample,
          ),

          const SizedBox(height: 24),

          // Example 5: Transform Origin
          _SectionTitle('5. Transform Origin'),
          HyperViewer(
            html: _originExample,
          ),

          const SizedBox(height: 24),

          // Example 6: 3D Perspective
          _SectionTitle('6. 3D Effects (Advanced)'),
          HyperViewer(
            html: _perspectiveExample,
          ),

          const SizedBox(height: 24),

          // Example 7: Practical use cases
          _SectionTitle('7. Practical Use Cases'),
          HyperViewer(
            html: _practicalExample,
          ),

          const SizedBox(height: 24),

          // Technical notes
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Technical Implementation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '✅ Powered by Flutter Matrix4 (native performance)\n'
                    '✅ Hardware-accelerated rendering\n'
                    '✅ Supports translate, rotate, scale\n'
                    '✅ Multiple transforms can be combined\n'
                    '✅ Transform-origin supported\n'
                    '✅ Coordinate system: CSS standard (not Flutter)',
                    style: TextStyle(fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Browser compatibility note
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Syntax Support',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Supported:\n'
                    '• translate(x, y) - Move element\n'
                    '• translateX(x) / translateY(y) - Move on one axis\n'
                    '• rotate(angle) - Rotate element (deg or rad)\n'
                    '• scale(x, y) - Resize element\n'
                    '• scaleX(x) / scaleY(y) - Scale on one axis\n'
                    '• Multiple: transform: rotate(45deg) scale(1.5)\n'
                    '\n'
                    'Future support:\n'
                    '• skew() - Planned for v1.1\n'
                    '• matrix() - Planned for v1.1\n'
                    '• 3D transforms - Planned for v1.2',
                    style: TextStyle(fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  static const _translateExample = '''
<style>
  .box {
    display: inline-block;
    width: 80px;
    height: 80px;
    background: #2196F3;
    color: white;
    text-align: center;
    line-height: 80px;
    font-weight: bold;
    margin: 20px;
    border-radius: 8px;
  }
  .translate-x {
    transform: translateX(50px);
    background: #4CAF50;
  }
  .translate-y {
    transform: translateY(30px);
    background: #FF9800;
  }
  .translate-both {
    transform: translate(40px, 40px);
    background: #E91E63;
  }
</style>

<div style="border: 2px dashed #ccc; padding: 20px; min-height: 200px;">
  <div class="box">Original</div>
  <div class="box translate-x">→ X</div>
  <div class="box translate-y">↓ Y</div>
  <div class="box translate-both">↘ Both</div>
</div>

<p style="font-size: 13px; color: #666; margin-top: 12px;">
  <code>translateX()</code>, <code>translateY()</code>, and
  <code>translate(x, y)</code> move elements without affecting layout flow.
</p>
''';

  static const _rotateExample = '''
<style>
  .rotate-box {
    display: inline-block;
    width: 100px;
    height: 100px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    text-align: center;
    line-height: 100px;
    font-weight: bold;
    margin: 30px;
    border-radius: 12px;
  }
  .rotate-15 {
    transform: rotate(15deg);
  }
  .rotate-45 {
    transform: rotate(45deg);
  }
  .rotate-90 {
    transform: rotate(90deg);
  }
  .rotate-neg {
    transform: rotate(-30deg);
  }
</style>

<div style="border: 2px dashed #ccc; padding: 40px; text-align: center; min-height: 220px;">
  <div class="rotate-box">0°</div>
  <div class="rotate-box rotate-15">15°</div>
  <div class="rotate-box rotate-45">45°</div>
  <div class="rotate-box rotate-90">90°</div>
  <div class="rotate-box rotate-neg">-30°</div>
</div>

<p style="font-size: 13px; color: #666; margin-top: 12px;">
  <code>rotate(angle)</code> spins elements around their center.
  Angle can be in <code>deg</code> or <code>rad</code>.
</p>
''';

  static const _scaleExample = '''
<style>
  .scale-box {
    display: inline-block;
    width: 60px;
    height: 60px;
    background: #FF5722;
    color: white;
    text-align: center;
    line-height: 60px;
    font-weight: bold;
    margin: 25px;
    border-radius: 8px;
  }
  .scale-up {
    transform: scale(1.5);
    background: #F44336;
  }
  .scale-down {
    transform: scale(0.7);
    background: #FF9800;
  }
  .scale-x {
    transform: scaleX(2);
    background: #4CAF50;
  }
  .scale-y {
    transform: scaleY(2);
    background: #2196F3;
  }
</style>

<div style="border: 2px dashed #ccc; padding: 40px; text-align: center; min-height: 200px;">
  <div class="scale-box">1.0x</div>
  <div class="scale-box scale-up">1.5x</div>
  <div class="scale-box scale-down">0.7x</div>
  <div class="scale-box scale-x">X→</div>
  <div class="scale-box scale-y">Y↕</div>
</div>

<p style="font-size: 13px; color: #666; margin-top: 12px;">
  <code>scale()</code> resizes elements. <code>scaleX()</code> and
  <code>scaleY()</code> scale only one axis.
</p>
''';

  static const _combinedExample = '''
<style>
  .card {
    width: 140px;
    height: 100px;
    background: white;
    border: 2px solid #6750A4;
    border-radius: 12px;
    padding: 16px;
    margin: 30px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    display: inline-block;
  }
  .card h4 {
    margin: 0 0 8px 0;
    color: #6750A4;
    font-size: 14px;
  }
  .card p {
    margin: 0;
    font-size: 11px;
    color: #666;
  }

  .combo-1 {
    transform: rotate(10deg) scale(1.1);
  }
  .combo-2 {
    transform: translate(20px, -10px) rotate(-5deg);
  }
  .combo-3 {
    transform: scale(1.2) rotate(15deg) translateY(10px);
  }
</style>

<div style="border: 2px dashed #ccc; padding: 50px; text-align: center; min-height: 250px;">
  <div class="card">
    <h4>Original</h4>
    <p>No transform</p>
  </div>

  <div class="card combo-1">
    <h4>Combo 1</h4>
    <p>rotate + scale</p>
  </div>

  <div class="card combo-2">
    <h4>Combo 2</h4>
    <p>translate + rotate</p>
  </div>

  <div class="card combo-3">
    <h4>Combo 3</h4>
    <p>All three!</p>
  </div>
</div>

<p style="font-size: 13px; color: #666; margin-top: 12px;">
  Multiple transforms are applied in order: rotate first, then scale, etc.
</p>
''';

  static const _originExample = '''
<style>
  .origin-demo {
    width: 100px;
    height: 100px;
    background: linear-gradient(45deg, #f093fb 0%, #f5576c 100%);
    margin: 50px;
    display: inline-block;
    border-radius: 8px;
    position: relative;
  }
  .origin-demo::after {
    content: "•";
    position: absolute;
    font-size: 20px;
    color: white;
  }
  .origin-center {
    transform: rotate(45deg);
    transform-origin: center center;
  }
  .origin-center::after {
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
  }
  .origin-topleft {
    transform: rotate(45deg);
    transform-origin: top left;
  }
  .origin-topleft::after {
    top: 0;
    left: 0;
  }
  .origin-bottomright {
    transform: rotate(45deg);
    transform-origin: bottom right;
  }
  .origin-bottomright::after {
    bottom: 0;
    right: 0;
  }
</style>

<div style="border: 2px dashed #ccc; padding: 60px; text-align: center; min-height: 250px;">
  <div class="origin-demo origin-center"></div>
  <div class="origin-demo origin-topleft"></div>
  <div class="origin-demo origin-bottomright"></div>
</div>

<p style="font-size: 13px; color: #666; margin-top: 12px;">
  <code>transform-origin</code> changes the pivot point. White dot shows origin.
  Default is <code>center center</code>.
</p>
''';

  static const _perspectiveExample = '''
<style>
  .perspective-box {
    width: 120px;
    height: 120px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    text-align: center;
    line-height: 120px;
    font-weight: bold;
    margin: 40px;
    display: inline-block;
    border-radius: 12px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.3);
  }
  .tilt-up {
    transform: perspective(500px) rotateX(30deg);
  }
  .tilt-right {
    transform: perspective(500px) rotateY(30deg);
  }
  .tilt-combo {
    transform: perspective(500px) rotateX(20deg) rotateY(20deg);
  }
</style>

<div style="border: 2px dashed #ccc; padding: 60px; text-align: center; min-height: 280px; background: linear-gradient(to bottom, #f5f5f5, #e0e0e0);">
  <div class="perspective-box">Flat</div>
  <div class="perspective-box tilt-up">Tilt X</div>
  <div class="perspective-box tilt-right">Tilt Y</div>
  <div class="perspective-box tilt-combo">3D!</div>
</div>

<p style="font-size: 13px; color: #666; margin-top: 12px;">
  <strong>Note:</strong> 3D transforms (rotateX, rotateY, perspective) have
  limited support in v1.0. Full 3D support planned for v1.2.
</p>
''';

  static const _practicalExample = '''
<style>
  /* Hover card effect (simulated with static transform) */
  .hover-card {
    width: 180px;
    height: 120px;
    background: white;
    border-radius: 12px;
    padding: 20px;
    margin: 20px;
    display: inline-block;
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    transform: translateY(0);
  }
  .hover-card-lifted {
    transform: translateY(-8px);
    box-shadow: 0 12px 24px rgba(0,0,0,0.2);
  }

  /* Tilted badges */
  .badge {
    display: inline-block;
    background: #E91E63;
    color: white;
    padding: 8px 16px;
    border-radius: 20px;
    font-weight: bold;
    font-size: 14px;
    margin: 0 8px;
  }
  .badge-tilt {
    transform: rotate(-3deg);
  }

  /* Scaled emphasis */
  .emphasis {
    display: inline-block;
    transform: scale(1.3);
    color: #F44336;
    font-weight: bold;
    margin: 0 8px;
  }
</style>

<h3 style="color: #1976D2; margin: 16px 0;">Practical Applications</h3>

<div style="border: 2px dashed #ccc; padding: 30px; min-height: 200px;">
  <p style="margin-bottom: 20px;"><strong>1. Elevated cards:</strong></p>
  <div class="hover-card">
    <h4 style="margin: 0 0 8px 0; color: #6750A4;">Normal</h4>
    <p style="margin: 0; font-size: 13px; color: #666;">Regular card</p>
  </div>
  <div class="hover-card hover-card-lifted">
    <h4 style="margin: 0 0 8px 0; color: #6750A4;">Lifted</h4>
    <p style="margin: 0; font-size: 13px; color: #666;">Simulated hover</p>
  </div>

  <p style="margin: 30px 0 12px 0;"><strong>2. Tilted badges:</strong></p>
  <span class="badge badge-tilt">NEW</span>
  <span class="badge" style="transform: rotate(2deg);">SALE</span>
  <span class="badge" style="transform: rotate(-5deg);">HOT</span>

  <p style="margin: 30px 0 12px 0;"><strong>3. Emphasis via scale:</strong></p>
  <p>This is <span class="emphasis">VERY</span> important!</p>
</div>
''';
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6750A4),
        ),
      ),
    );
  }
}
