import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

/// Comprehensive CSS Properties Demo
/// Shows all CSS properties supported by HyperRender
class CssPropertiesDemo extends StatelessWidget {
  const CssPropertiesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSS Properties Demo'),
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

          // NEW PROPERTIES
          _buildSection('🎉 NEW CSS Properties'),
          _buildPropertyCard(
            title: 'text-shadow',
            description: 'Drop shadow on text (multiple shadows supported)',
            html: '''
              <h2 style="text-shadow: 2px 2px 4px rgba(0,0,0,0.3);">
                Single Shadow
              </h2>
              <h2 style="text-shadow: 1px 1px 2px blue, -1px -1px 2px red;">
                Multiple Shadows
              </h2>
              <p style="text-shadow: 0 0 10px rgba(255,255,0,0.8), 0 0 20px rgba(255,255,0,0.5);">
                Glowing text effect
              </p>
              <h3 style="color: white; text-shadow: 2px 2px 0 #000, -2px -2px 0 #000, 2px -2px 0 #000, -2px 2px 0 #000;">
                Stroke effect with white text
              </h3>
            ''',
          ),
          _buildPropertyCard(
            title: 'text-overflow',
            description: 'Truncate text with ellipsis (requires width + nowrap + hidden)',
            html: '''
              <div style="width: 200px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; border: 1px solid #ddd; padding: 8px;">
                This is a very long text that will be truncated with ellipsis
              </div>
              <div style="width: 200px; white-space: nowrap; overflow: hidden; text-overflow: clip; border: 1px solid #ddd; padding: 8px; margin-top: 8px;">
                This text will be clipped without ellipsis
              </div>
            ''',
          ),
          _buildPropertyCard(
            title: 'border-style',
            description: 'Different border styles: solid, dashed, dotted, double',
            html: '''
              <div style="border: 2px solid red; padding: 8px; margin: 4px 0;">
                Solid border (default)
              </div>
              <div style="border: 2px dashed blue; padding: 8px; margin: 4px 0;">
                Dashed border
              </div>
              <div style="border: 2px dotted green; padding: 8px; margin: 4px 0;">
                Dotted border
              </div>
              <div style="border: 4px double purple; padding: 8px; margin: 4px 0;">
                Double border
              </div>
              <div style="border-top: 3px dashed red; border-right: 3px dotted blue; border-bottom: 3px solid green; border-left: 3px double purple; padding: 8px; margin: 4px 0;">
                Mixed border styles
              </div>
            ''',
          ),
          _buildPropertyCard(
            title: 'direction (RTL/LTR)',
            description: 'Text direction for internationalization',
            html: '''
              <p style="direction: ltr; border: 1px solid #ddd; padding: 8px;">
                <strong>LTR:</strong> This text flows from left to right (English, French, etc.)
              </p>
              <p style="direction: rtl; border: 1px solid #ddd; padding: 8px; margin-top: 8px;">
                <strong>RTL:</strong> هذا النص يتدفق من اليمين إلى اليسار (Arabic, Hebrew, Persian)
              </p>
              <p style="direction: rtl; text-align: right; border: 1px solid #ddd; padding: 8px; margin-top: 8px;">
                <strong>RTL + Right Align:</strong> مرحبا بك في HyperRender
              </p>
            ''',
          ),

          const SizedBox(height: 24),
          _buildSection('📦 Box Model Properties'),
          _buildPropertyCard(
            title: 'Margin & Padding',
            description: 'Spacing around and inside elements',
            html: '''
              <div style="background: #e3f2fd; padding: 16px; margin: 16px 0;">
                <div style="background: #fff; padding: 12px; margin: 8px;">
                  Nested box with margin and padding
                </div>
              </div>
            ''',
          ),
          _buildPropertyCard(
            title: 'Border & Border-Radius',
            description: 'Borders with rounded corners',
            html: '''
              <div style="border: 2px solid #2196F3; border-radius: 8px; padding: 12px;">
                Rounded corners (8px)
              </div>
              <div style="border: 3px solid #4CAF50; border-radius: 20px; padding: 12px; margin-top: 8px;">
                More rounded (20px)
              </div>
            ''',
          ),
          _buildPropertyCard(
            title: 'Width & Height',
            description: 'Fixed and constrained sizing',
            html: '''
              <div style="width: 200px; height: 100px; background: #ffebee; border: 1px solid #f44336; padding: 8px;">
                Fixed size: 200x100
              </div>
              <div style="max-width: 300px; background: #e8f5e9; border: 1px solid #4caf50; padding: 8px; margin-top: 8px;">
                Max width: 300px (responsive)
              </div>
            ''',
          ),

          const SizedBox(height: 24),
          _buildSection('✍️ Typography Properties'),
          _buildPropertyCard(
            title: 'Font Properties',
            description: 'Font family, size, weight, and style',
            html: '''
              <p style="font-family: serif; font-size: 18px;">
                Serif font, 18px
              </p>
              <p style="font-weight: bold; font-size: 16px;">
                Bold text
              </p>
              <p style="font-style: italic; font-size: 16px;">
                Italic text
              </p>
              <p style="font-weight: 300; font-size: 14px;">
                Light weight (300)
              </p>
            ''',
          ),
          _buildPropertyCard(
            title: 'Text Decoration',
            description: 'Underline, overline, line-through',
            html: '''
              <p style="text-decoration: underline;">
                Underlined text
              </p>
              <p style="text-decoration: line-through;">
                Strikethrough text
              </p>
              <p style="text-decoration: overline;">
                Overline text
              </p>
              <p style="text-decoration: underline; text-decoration-color: red;">
                Red underline
              </p>
            ''',
          ),
          _buildPropertyCard(
            title: 'Text Alignment',
            description: 'left, center, right, justify',
            html: '''
              <p style="text-align: left; border: 1px solid #ddd; padding: 4px;">
                Left aligned (default)
              </p>
              <p style="text-align: center; border: 1px solid #ddd; padding: 4px;">
                Center aligned
              </p>
              <p style="text-align: right; border: 1px solid #ddd; padding: 4px;">
                Right aligned
              </p>
              <p style="text-align: justify; border: 1px solid #ddd; padding: 4px;">
                Justified text spreads out to fill the entire width of the container, creating even edges on both sides.
              </p>
            ''',
          ),
          _buildPropertyCard(
            title: 'Line Height & Letter Spacing',
            description: 'Control spacing for readability',
            html: '''
              <p style="line-height: 1.0; background: #f5f5f5; padding: 4px;">
                Tight line height (1.0)
              </p>
              <p style="line-height: 2.0; background: #f5f5f5; padding: 4px;">
                Loose line height (2.0)
              </p>
              <p style="letter-spacing: 3px; background: #f5f5f5; padding: 4px;">
                Wide letter spacing
              </p>
            ''',
          ),

          const SizedBox(height: 24),
          _buildSection('🎨 Background & Colors'),
          _buildPropertyCard(
            title: 'Background Color',
            description: 'Solid background colors',
            html: '''
              <div style="background-color: #ffebee; padding: 12px; margin: 4px 0;">
                Light red background
              </div>
              <div style="background-color: rgba(33, 150, 243, 0.2); padding: 12px; margin: 4px 0;">
                Semi-transparent blue (rgba)
              </div>
              <div style="background-color: #4caf50; color: white; padding: 12px; margin: 4px 0;">
                Green background with white text
              </div>
            ''',
          ),
          _buildPropertyCard(
            title: 'Text Color',
            description: 'Foreground color for text',
            html: '''
              <p style="color: #f44336;">Red text (hex)</p>
              <p style="color: rgb(33, 150, 243);">Blue text (rgb)</p>
              <p style="color: rgba(76, 175, 80, 0.7);">Semi-transparent green (rgba)</p>
            ''',
          ),

          const SizedBox(height: 24),
          _buildSection('📐 Layout Properties'),
          _buildPropertyCard(
            title: 'Display',
            description: 'block, inline, inline-block, none',
            html: '''
              <div style="background: #e3f2fd; padding: 8px;">
                <span style="display: block; background: #fff; padding: 4px; margin: 2px 0;">
                  Block span (full width)
                </span>
                <span style="display: inline; background: #ffebee; padding: 4px;">
                  Inline span
                </span>
                <span style="display: inline; background: #e8f5e9; padding: 4px;">
                  Another inline
                </span>
                <span style="display: inline-block; width: 100px; background: #fff3e0; padding: 4px; margin: 4px;">
                  Inline-block with width
                </span>
              </div>
            ''',
          ),
          _buildPropertyCard(
            title: 'Float ⭐ (HyperRender Advantage!)',
            description: 'Text wraps around floated elements',
            html: '''
              <div>
                <div style="float: left; width: 80px; height: 80px; background: #2196F3; margin: 0 12px 8px 0; color: white; display: flex; align-items: center; justify-content: center; text-align: center; padding: 8px;">
                  Float Left
                </div>
                <p>This text wraps around the floated blue box on the left.
                Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
                This is a unique advantage of HyperRender over flutter_widget_from_html!</p>
                <div style="clear: both;"></div>

                <div style="float: right; width: 80px; height: 80px; background: #4CAF50; margin: 0 0 8px 12px; color: white; display: flex; align-items: center; justify-content: center; text-align: center; padding: 8px;">
                  Float Right
                </div>
                <p>This text wraps around the floated green box on the right.
                Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                Perfect CSS float support is what makes HyperRender special!</p>
              </div>
            ''',
          ),
          _buildPropertyCard(
            title: 'Opacity',
            description: 'Transparency control',
            html: '''
              <div style="background: #2196F3; color: white; padding: 12px; opacity: 1.0;">
                Fully opaque (1.0)
              </div>
              <div style="background: #2196F3; color: white; padding: 12px; opacity: 0.7; margin-top: 4px;">
                70% opacity (0.7)
              </div>
              <div style="background: #2196F3; color: white; padding: 12px; opacity: 0.3; margin-top: 4px;">
                30% opacity (0.3)
              </div>
            ''',
          ),

          const SizedBox(height: 24),
          _buildSection('🎯 Advanced Combinations'),
          _buildPropertyCard(
            title: 'Card Design',
            description: 'Combining multiple properties',
            html: '''
              <div style="
                border: 1px solid #e0e0e0;
                border-radius: 12px;
                padding: 16px;
                background: #ffffff;
                margin: 8px 0;
              ">
                <h3 style="margin: 0 0 8px 0; color: #1976d2;">
                  Card Title
                </h3>
                <p style="margin: 0; color: #666; line-height: 1.6;">
                  This demonstrates a card design using border, border-radius,
                  padding, background, and proper spacing.
                </p>
              </div>
            ''',
          ),
          _buildPropertyCard(
            title: 'Button Styles',
            description: 'CSS-styled buttons',
            html: '''
              <div style="
                display: inline-block;
                background: #2196F3;
                color: white;
                padding: 12px 24px;
                border-radius: 6px;
                font-weight: bold;
                margin: 4px;
              ">
                Primary Button
              </div>
              <div style="
                display: inline-block;
                background: transparent;
                color: #2196F3;
                padding: 12px 24px;
                border: 2px solid #2196F3;
                border-radius: 6px;
                font-weight: bold;
                margin: 4px;
              ">
                Outline Button
              </div>
              <div style="
                display: inline-block;
                background: #4CAF50;
                color: white;
                padding: 12px 24px;
                border-radius: 20px;
                font-weight: bold;
                margin: 4px;
                text-shadow: 1px 1px 2px rgba(0,0,0,0.2);
              ">
                Pill Button with Shadow
              </div>
            ''',
          ),

          const SizedBox(height: 24),
          _buildSection('🌟 Additional Properties'),
          _buildPropertyCard(
            title: 'opacity (4 levels)',
            description: 'Transparency at 100%, 75%, 50%, and 25% — clearly visible difference',
            html: '''
              <div style="background: #3F51B5; color: white; padding: 12px; margin: 4px 0; opacity: 1.0;">
                Fully opaque — opacity: 1.0 (100%)
              </div>
              <div style="background: #3F51B5; color: white; padding: 12px; margin: 4px 0; opacity: 0.75;">
                Slightly transparent — opacity: 0.75 (75%)
              </div>
              <div style="background: #3F51B5; color: white; padding: 12px; margin: 4px 0; opacity: 0.5;">
                Half transparent — opacity: 0.5 (50%)
              </div>
              <div style="background: #3F51B5; color: white; padding: 12px; margin: 4px 0; opacity: 0.25;">
                Very transparent — opacity: 0.25 (25%)
              </div>
            ''',
          ),
          _buildPropertyCard(
            title: 'position: relative (top / left offset)',
            description: 'Relative positioning shifts element from its normal flow position',
            html: '''
              <div style="background: #f5f5f5; padding: 20px; border: 1px solid #ddd;">
                <div style="background: #E8F5E9; padding: 8px; border: 1px solid #4CAF50;">
                  Normal flow element
                </div>
                <div style="background: #E3F2FD; padding: 8px; border: 1px solid #2196F3; position: relative; top: 8px; left: 16px;">
                  position: relative; top: 8px; left: 16px
                </div>
                <div style="background: #FFF3E0; padding: 8px; border: 1px solid #FF9800;">
                  Normal flow (after offset element)
                </div>
              </div>
            ''',
          ),

          const SizedBox(height: 24),
          _buildSummary(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade700, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.style, color: Colors.white, size: 40),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CSS Properties',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Comprehensive CSS support showcase',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '✅ text-shadow • text-overflow • border-style • direction (RTL/LTR)',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildPropertyCard({
    required String title,
    required String description,
    required String html,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: HyperViewer(
                html: html,
                selectable: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue.shade700, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'CSS Coverage Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCoverageBullet('✅ Box Model: margin, padding, border, width, height', '100%'),
          _buildCoverageBullet('✅ Typography: fonts, text-decoration, alignment, spacing', '95%'),
          _buildCoverageBullet('✅ NEW: text-shadow, text-overflow', '90%'),
          _buildCoverageBullet('✅ NEW: border-style (solid, dashed, dotted, double)', '90%'),
          _buildCoverageBullet('✅ NEW: direction (RTL/LTR) for i18n', '100%'),
          _buildCoverageBullet('✅ Colors: hex, rgb, rgba, named colors', '100%'),
          _buildCoverageBullet('✅ Layout: display, float ⭐, clear, opacity', '100%'),
          _buildCoverageBullet('⏳ Coming: Flexbox, Grid, box-shadow', '0% → 90%'),
          const SizedBox(height: 12),
          Text(
            'HyperRender now supports 60+ CSS properties!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageBullet(String text, String percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              percentage,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
