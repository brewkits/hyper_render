import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

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
      appBar: AppBar(
        title: const Text('Aesthetic Quality Demo'),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
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
          _buildBorderQualitySection(),
          const SizedBox(height: 24),
          _buildShadowQualitySection(),
          const SizedBox(height: 24),
          _buildGradientQualitySection(),
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
                Icon(Icons.auto_awesome, color: Colors.deepPurple.shade700, size: 32),
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
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 12)),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: '''
                <div style="text-align: center;">
                  <h3 style="color: #673AB7;">High-Quality Images</h3>
                  <img src="https://picsum.photos/400/300?random=100"
                       style="width: 100%; max-width: 400px; border-radius: 12px; margin: 8px 0;" />
                  <p style="font-size: 14px; color: #666;">
                    Notice the crisp details even when scaled. FilterQuality.medium ensures
                    smooth rendering without the performance cost of .high quality.
                  </p>

                  <div style="display: flex; gap: 8px; justify-content: center; margin-top: 16px;">
                    <img src="https://picsum.photos/150/150?random=101"
                         style="width: 150px; height: 150px; border-radius: 50%; object-fit: cover;" />
                    <img src="https://picsum.photos/150/150?random=102"
                         style="width: 150px; height: 150px; border-radius: 12px; object-fit: cover;" />
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
          'Enhanced with TextHeightBehavior for consistent vertical rhythm',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
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
                    across different font sizes and styles, creating a harmonious reading experience.
                  </p>

                  <div style="background: #FFF3E0; padding: 12px; border-radius: 8px; margin: 12px 0;">
                    <p style="margin: 0; font-size: 14px; color: #E65100;">
                      💡 <strong>Pro Tip:</strong> Notice how the line spacing is perfectly balanced,
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
          'Loading placeholders with anti-aliased gradients',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HyperViewer(
              html: '''
                <div>
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

                  <p style="margin: 16px 0 0 0; font-size: 12px; color: #999; text-align: center;">
                    ⬆️ Loading states with beautiful gradient backgrounds
                  </p>
                </div>
              ''',
            ),
          ),
        ),
      ],
    );
  }
}
