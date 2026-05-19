import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

/// Demonstrates aesthetic quality improvements in HyperRender
///
/// Phase 1 Improvements:
/// ✅ Image filterQuality: medium (crisp on retina displays)
/// ✅ Explicit isAntiAlias on all Paint objects
/// ✅ TextHeightBehavior for consistent vertical rhythm
/// ✅ Smooth gradients and borders
class AestheticDemo extends StatelessWidget {
  const AestheticDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildDemoAppBar(
        context,
        title: 'Aesthetic Quality Demo',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildImageQualitySection(),
          const SizedBox(height: 24),
          _buildTextQualitySection(),
          const SizedBox(height: 24),
          _buildAdvancedBordersSection(),
          const SizedBox(height: 24),
          _buildBorderQualitySection(),
          const SizedBox(height: 24),
          _buildShadowQualitySection(),
          const SizedBox(height: 24),
          _buildGradientQualitySection(),
          const SizedBox(height: 24),
          _buildAdvancedCssSection(),
          const SizedBox(height: 24),
          _buildFilterSection(),
          const SizedBox(height: 24),
          _buildLayoutQualitySection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: Colors.deepPurple.shade700, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Visual Quality Enhancements',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildFeature('✨ FilterQuality.medium for crisp images'),
            _buildFeature('✨ Explicit anti-aliasing on all shapes'),
            _buildFeature('✨ Enhanced text rendering with height behavior'),
            _buildFeature('✨ Smooth borders and rounded corners'),
            _buildFeature('✨ Beautiful gradients and shadows'),
            _buildFeature('✨ CSS box-shadow and linear-gradients'),
            _buildFeature('✨ CSS filters and backdrop-filter (blur)'),
            _buildFeature(
                '✨ NEW: word-break and background-size (cover/contain)'),
            _buildFeature('✨ NEW: list-style and background (repeat/position)'),
            _buildFeature('✨ NEW: Advanced borders (dashed, dotted, double)'),
            _buildFeature(
                '✨ NEW: Professional truncation (text-overflow: ellipsis)'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text,
          style: const TextStyle(fontSize: 12, color: Colors.deepPurple)),
    );
  }

  Widget _buildImageQualitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. Image Rendering Quality',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Images now use FilterQuality.medium for crisp rendering on retina displays',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: '''
                <div style="text-align: center;">
                  <h3 style="color: #673AB7; margin-bottom: 12px;">High-Quality Images</h3>
                  <img src="https://picsum.photos/400/300?random=100"
                       style="width: 100%; max-width: 400px; border-radius: 12px; margin: 8px 0; box-shadow: 0 4px 12px rgba(0,0,0,0.1);" />
                  <p style="font-size: 14px; color: #666; margin-top: 12px; line-height: 1.5;">
                    Notice the crisp details even when scaled. FilterQuality.medium ensures
                    smooth rendering without the performance cost of .high quality.
                  </p>

                  <div style="display: flex; gap: 12px; justify-content: center; margin-top: 20px;">
                    <img src="https://picsum.photos/150/150?random=101"
                         style="width: 140px; height: 140px; border-radius: 50%; object-fit: cover; border: 3px solid white; box-shadow: 0 4px 10px rgba(0,0,0,0.1);" />
                    <img src="https://picsum.photos/150/150?random=102"
                         style="width: 140px; height: 140px; border-radius: 12px; object-fit: cover; border: 3px solid white; box-shadow: 0 4px 10px rgba(0,0,0,0.1);" />
                  </div>
                </div>
              ''',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextQualitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. Typography & Text Rendering',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enhanced with TextHeightBehavior and ligatures support',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: '''
                <div style="line-height: 1.6; font-size: 16px;">
                  <h3 style="color: #1976D2; margin: 0 0 12px 0;">Beautiful Typography</h3>

                  <p style="margin: 0 0 12px 0;">
                    HyperRender delivers <strong>pixel-perfect text rendering</strong> with
                    optimized line height, letter spacing, and <em>font metrics</em>.
                  </p>

                  <p style="margin: 0 0 12px 0; color: #555;">
                    The TextHeightBehavior enhancement ensures consistent vertical rhythm
                    across different font sizes and styles. Notice the <strong>ligatures (fi, fl, ffi)</strong>
                    enabled by default for superior readability.
                  </p>

                  <div style="background: #FFF3E0; padding: 12px; border-radius: 8px; margin: 12px 0; border-left: 4px solid #FF9800;">
                    <p style="margin: 0; font-size: 14px; color: #E65100;">
                      💡 <strong>Vertical Rhythm:</strong> Notice how the line spacing is perfectly balanced,
                      making long-form content comfortable to read on any screen size.
                    </p>
                  </div>
                </div>
              ''',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedBordersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. Advanced Borders & Truncation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Dashed, dotted, and double borders with professional ellipsis',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: '''
                <div style="display: flex; flex-direction: column; gap: 20px;">
                  <h3 style="color: #E91E63; margin: 0;">Styled Borders</h3>
                  
                  <div style="border: 2px dashed #E91E63; padding: 16px; border-radius: 8px; text-align: center; background: #FCE4EC;">
                    <strong style="color: #AD1457;">dashed border</strong>
                  </div>

                  <div style="border: 2px dotted #3F51B5; padding: 16px; border-radius: 8px; text-align: center; background: #E8EAF6;">
                    <strong style="color: #283593;">dotted border</strong>
                  </div>

                  <div style="border: 6px double #4CAF50; padding: 16px; border-radius: 8px; text-align: center; background: #E8F5E9;">
                    <strong style="color: #2E7D32;">double border</strong>
                  </div>

                  <h3 style="color: #607D8B; margin: 12px 0 0 0;">Professional Truncation</h3>
                  <p style="font-size: 12px; color: #666; margin-bottom: 8px;">text-overflow: ellipsis support</p>
                  
                  <div style="width: 100%; max-width: 300px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; border: 1px solid #CFD8DC; padding: 12px; border-radius: 8px; background: #ECEFF1; color: #374151;">
                    This is a very long heading that will be truncated with ellipsis when it reaches the end of the container width.
                  </div>
                </div>
              ''',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBorderQualitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. Smooth Borders & Rounded Corners',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Explicit anti-aliasing eliminates jagged edges',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: '''
                <div>
                  <h3 style="color: #388E3C; margin: 0 0 16px 0;">Crisp Borders</h3>

                  <div style="display: flex; gap: 16px; flex-wrap: wrap; justify-content: center;">
                    <div style="border: 2px solid #2196F3; padding: 16px; border-radius: 8px; text-align: center;">
                      <strong style="color: #2196F3;">Rounded 8px</strong>
                    </div>

                    <div style="border: 3px solid #9C27B0; padding: 16px; border-radius: 16px; text-align: center;">
                      <strong style="color: #9C27B0;">Rounded 16px</strong>
                    </div>

                    <div style="border: 2px solid #FF5722; padding: 16px; border-radius: 50%; width: 80px; height: 80px; display: flex; align-items: center; justify-content: center;">
                      <strong style="color: #FF5722; font-size: 12px;">Circle</strong>
                    </div>
                  </div>

                  <p style="margin: 16px 0 0 0; font-size: 14px; color: #666; text-align: center;">
                    All borders render with smooth anti-aliasing for professional quality
                  </p>
                </div>
              ''',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShadowQualitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '4. Text Shadows',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'CSS text-shadow with multiple shadows and blur effects',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: '''
                <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 32px; border-radius: 12px; text-align: center;">
                  <h1 style="color: white; font-size: 36px; margin: 0 0 16px 0; text-shadow: 2px 2px 4px rgba(0,0,0,0.3);">
                    Beautiful Shadows
                  </h1>

                  <p style="color: #F3E5F5; font-size: 18px; margin: 0; text-shadow: 1px 1px 2px rgba(0,0,0,0.2);">
                    Text shadows add depth and visual hierarchy
                  </p>
                </div>

                <div style="margin-top: 16px; text-align: center;">
                  <h2 style="color: #FF6B6B; font-size: 28px; text-shadow: 3px 3px 0px #C92A2A, 6px 6px 10px rgba(201,42,42,0.3);">
                    Layered Shadow
                  </h2>

                  <h2 style="color: #51CF66; font-size: 28px; text-shadow: 0 0 10px rgba(81,207,102,0.8), 0 0 20px rgba(81,207,102,0.4);">
                    Glow Effect
                  </h2>
                </div>
              ''',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientQualitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '5. Smooth Gradients',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'CSS linear-gradient and beautiful skeleton placeholders',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: '''
                <div>
                  <div style="background: linear-gradient(to right, #6a11cb 0%, #2575fc 100%); padding: 24px; border-radius: 8px; color: white; text-align: center; margin-bottom: 24px;">
                    <h3 style="margin: 0;">Linear Gradient Background</h3>
                    <p style="margin: 8px 0 0 0; font-size: 12px; opacity: 0.9;">linear-gradient(to right, #6a11cb, #2575fc)</p>
                  </div>

                  <h3 style="color: #00BCD4; margin: 0 0 16px 0;">Skeleton Placeholders</h3>
                  <p style="margin: 0 0 16px 0; font-size: 14px; color: #666;">
                    Image placeholders use smooth gradients with anti-aliasing for a polished look
                  </p>

                  <div style="display: flex; gap: 16px; justify-content: center;">
                    <img src="https://invalid-url-will-show-placeholder.com/150x150"
                         style="width: 150px; height: 150px; border-radius: 8px;" />
                    <img src="https://another-invalid-url.com/150x150"
                         style="width: 150px; height: 150px; border-radius: 50%;" />
                  </div>
                </div>
              ''',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedCssSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '6. Advanced CSS Visuals (Phase 2)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'CSS box-shadow and linear-gradient support for rich, modern UI',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: '''
                <div style="display: flex; flex-direction: column; gap: 24px;">
                  <!-- Box Shadow Examples -->
                  <div style="background: white; padding: 20px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); text-align: center;">
                    <strong style="color: #333;">Standard Drop Shadow</strong>
                    <p style="font-size: 12px; color: #666; margin: 8px 0 0 0;">box-shadow: 0 4px 12px rgba(0,0,0,0.1)</p>
                  </div>

                  <div style="background: white; padding: 20px; border-radius: 12px; box-shadow: 0 10px 20px rgba(33,150,243,0.3); border: 1px solid #2196F3; text-align: center;">
                    <strong style="color: #2196F3;">Colored Shadow</strong>
                    <p style="font-size: 12px; color: #666; margin: 8px 0 0 0;">box-shadow: 0 10px 20px rgba(33,150,243,0.3)</p>
                  </div>

                  <!-- Linear Gradient Examples -->
                  <div style="background: linear-gradient(to right, #FF5F6D, #FFC371); padding: 32px; border-radius: 12px; text-align: center; box-shadow: 0 8px 16px rgba(255,95,109,0.4);">
                    <h2 style="color: white; margin: 0; text-shadow: 1px 1px 2px rgba(0,0,0,0.2);">Sunset Gradient</h2>
                    <p style="color: rgba(255,255,255,0.9); font-size: 14px; margin: 8px 0 0 0;">linear-gradient(to right, #FF5F6D, #FFC371)</p>
                  </div>

                  <div style="background: linear-gradient(135deg, #2193b0 0%, #6dd5ed 100%); padding: 32px; border-radius: 12px; text-align: center; box-shadow: 0 8px 16px rgba(33,147,176,0.4);">
                    <h2 style="color: white; margin: 0; text-shadow: 1px 1px 2px rgba(0,0,0,0.2);">Ocean Blue</h2>
                    <p style="color: rgba(255,255,255,0.9); font-size: 14px; margin: 8px 0 0 0;">linear-gradient(135deg, #2193b0, #6dd5ed)</p>
                  </div>

                  <!-- Combined Effects -->
                  <div style="background: #f8f9fa; padding: 24px; border-radius: 16px; border: 1px solid #dee2e6; box-shadow: 0 2px 4px rgba(0,0,0,0.05), 0 10px 15px -3px rgba(0,0,0,0.1);">
                    <div style="display: flex; align-items: center; gap: 16px;">
                      <div style="width: 48px; height: 48px; border-radius: 12px; background: linear-gradient(45deg, #7b4397, #dc2430); box-shadow: 0 4px 8px rgba(123,67,151,0.4);"></div>
                      <div>
                        <strong style="font-size: 16px;">Glassmorphism Style</strong>
                        <p style="font-size: 12px; color: #666; margin: 4px 0 0 0;">Combining gradients, borders, and shadows</p>
                      </div>
                    </div>
                  </div>
                </div>
              ''',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '7. CSS Filters & Glassmorphism',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Modern blur and backdrop-filter effects for depth and focus',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: '''
                <div style="display: flex; flex-direction: column; gap: 24px;">
                  <!-- CSS Filter Examples -->
                  <div style="display: flex; gap: 16px; justify-content: center;">
                    <div style="text-align: center;">
                      <img src="https://picsum.photos/id/10/100/100" style="width: 100px; height: 100px; border-radius: 12px; filter: blur(4px);" />
                      <p style="font-size: 10px; margin-top: 4px;">filter: blur(4px)</p>
                    </div>
                    <div style="text-align: center;">
                      <img src="https://picsum.photos/id/10/100/100" style="width: 100px; height: 100px; border-radius: 12px; filter: brightness(1.5);" />
                      <p style="font-size: 10px; margin-top: 4px;">brightness(1.5)</p>
                    </div>
                    <div style="text-align: center;">
                      <img src="https://picsum.photos/id/10/100/100" style="width: 100px; height: 100px; border-radius: 12px; filter: contrast(0.5);" />
                      <p style="font-size: 10px; margin-top: 4px;">contrast(0.5)</p>
                    </div>
                  </div>

                  <!-- Backdrop Filter (Glassmorphism) -->
                  <div style="position: relative; height: 180px; border-radius: 16px; overflow: hidden; background: url(https://picsum.photos/id/28/400/200); background-size: cover;">
                    <div style="position: absolute; top: 40px; left: 40px; right: 40px; bottom: 40px; 
                                background: rgba(255, 255, 255, 0.2); 
                                border: 1px solid rgba(255, 255, 255, 0.3);
                                border-radius: 12px;
                                backdrop-filter: blur(10px);
                                display: flex;
                                align-items: center;
                                justify-content: center;
                                box-shadow: 0 8px 32px rgba(0,0,0,0.1);">
                      <div style="text-align: center;">
                        <strong style="color: white; font-size: 18px; text-shadow: 0 2px 4px rgba(0,0,0,0.2);">Glassmorphism</strong>
                        <p style="color: white; font-size: 12px; margin: 4px 0 0 0;">backdrop-filter: blur(10px)</p>
                      </div>
                    </div>
                  </div>

                  <!-- Combined Effects -->
                  <div style="background: linear-gradient(45deg, #f3f4f6, #ffffff); padding: 20px; border-radius: 12px; border: 1px solid #e5e7eb;">
                    <div style="display: flex; align-items: center; gap: 12px;">
                      <div style="width: 40px; height: 40px; background: #3b82f6; border-radius: 50%; filter: blur(8px); opacity: 0.6;"></div>
                      <p style="font-size: 14px; color: #374151;">Blurred decorative elements for modern "soft" UI feel.</p>
                    </div>
                  </div>
                </div>
              ''',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutQualitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '8. Advanced Layout Control',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Precise control over text breaking and background image sizing',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: '''
                <div style="display: flex; flex-direction: column; gap: 20px;">
                  <!-- Word Breaking -->
                  <div>
                    <strong style="font-size: 14px; color: #333;">word-break: break-all</strong>
                    <div style="width: 150px; border: 1px solid #ddd; padding: 8px; margin-top: 4px; word-break: break-all; font-size: 12px; background: #f9f9f9;">
                      ThisIsAVeryLongStringThatShouldBreakAtAnyCharacterToFitTheContainerWidth.
                    </div>
                  </div>

                  <!-- Background Sizing -->
                  <div style="display: flex; gap: 16px; justify-content: center;">
                    <div style="text-align: center;">
                      <div style="width: 100px; height: 100px; border: 1px solid #ddd; border-radius: 8px; background: url(https://picsum.photos/id/64/200/200); background-size: cover;"></div>
                      <p style="font-size: 10px; margin-top: 4px;">size: cover</p>
                    </div>
                    <div style="text-align: center;">
                      <div style="width: 100px; height: 100px; border: 1px solid #ddd; border-radius: 8px; background: url(https://picsum.photos/id/64/200/200); background-size: contain; background-color: #eee;"></div>
                      <p style="font-size: 10px; margin-top: 4px;">size: contain</p>
                    </div>
                  </div>
                </div>
              ''',
            ),
          ),
        ),
      ],
    );
  }
}
