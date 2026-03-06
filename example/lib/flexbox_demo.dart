import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

class FlexboxDemo extends StatelessWidget {
  const FlexboxDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ensure white background for proper contrast
      appBar: AppBar(
        title: const Text('Flexbox Demo'),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Custom back button from _BackBlockedPage
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntro(),
          const SizedBox(height: 24),
          _buildSection('flex-direction'),
          _buildExample(
            'Row (default)',
            '<div style="display: flex; flex-direction: row; gap: 8px; border: 1px solid #ddd; padding: 8px;">'
            '<div style="background: #f44336; color: white; padding: 12px;">Item 1</div>'
            '<div style="background: #2196F3; color: white; padding: 12px;">Item 2</div>'
            '<div style="background: #4CAF50; color: white; padding: 12px;">Item 3</div>'
            '</div>',
          ),
          _buildExample(
            'Column',
            '<div style="display: flex; flex-direction: column; gap: 8px; border: 1px solid #ddd; padding: 8px;">'
            '<div style="background: #f44336; color: white; padding: 12px;">Item 1</div>'
            '<div style="background: #2196F3; color: white; padding: 12px;">Item 2</div>'
            '<div style="background: #4CAF50; color: white; padding: 12px;">Item 3</div>'
            '</div>',
          ),
          _buildExample(
            'Row Reverse',
            '<div style="display: flex; flex-direction: row-reverse; gap: 8px; border: 1px solid #ddd; padding: 8px;">'
            '<div style="background: #f44336; color: white; padding: 12px;">Item 1</div>'
            '<div style="background: #2196F3; color: white; padding: 12px;">Item 2</div>'
            '<div style="background: #4CAF50; color: white; padding: 12px;">Item 3</div>'
            '</div>',
          ),
          const SizedBox(height: 24),
          _buildSection('justify-content'),
          _buildExample(
            'flex-start (default)',
            '<div style="display: flex; justify-content: flex-start; border: 1px solid #ddd; padding: 8px;">'
            '<div style="background: #f44336; color: white; padding: 12px;">Left</div>'
            '<div style="background: #4CAF50; color: white; padding: 12px;">Items</div>'
            '</div>',
          ),
          _buildExample(
            'flex-end',
            '<div style="display: flex; justify-content: flex-end; border: 1px solid #ddd; padding: 8px;">'
            '<div style="background: #f44336; color: white; padding: 12px;">Right</div>'
            '<div style="background: #4CAF50; color: white; padding: 12px;">Items</div>'
            '</div>',
          ),
          _buildExample(
            'center',
            '<div style="display: flex; justify-content: center; border: 1px solid #ddd; padding: 8px;">'
            '<div style="background: #2196F3; color: white; padding: 12px;">Centered</div>'
            '</div>',
          ),
          _buildExample(
            'space-between',
            '<div style="display: flex; justify-content: space-between; border: 1px solid #ddd; padding: 8px;">'
            '<div style="background: #f44336; color: white; padding: 12px;">Left</div>'
            '<div style="background: #2196F3; color: white; padding: 12px;">Middle</div>'
            '<div style="background: #4CAF50; color: white; padding: 12px;">Right</div>'
            '</div>',
          ),
          _buildExample(
            'space-around',
            '<div style="display: flex; justify-content: space-around; border: 1px solid #ddd; padding: 8px;">'
            '<div style="background: #f44336; color: white; padding: 12px;">1</div>'
            '<div style="background: #2196F3; color: white; padding: 12px;">2</div>'
            '<div style="background: #4CAF50; color: white; padding: 12px;">3</div>'
            '</div>',
          ),
          _buildExample(
            'space-evenly',
            '<div style="display: flex; justify-content: space-evenly; border: 1px solid #ddd; padding: 8px;">'
            '<div style="background: #f44336; color: white; padding: 12px;">1</div>'
            '<div style="background: #2196F3; color: white; padding: 12px;">2</div>'
            '<div style="background: #4CAF50; color: white; padding: 12px;">3</div>'
            '</div>',
          ),
          const SizedBox(height: 24),
          _buildSection('align-items'),
          _buildExample(
            'flex-start',
            '<div style="display: flex; align-items: flex-start; height: 100px; border: 1px solid #ddd; padding: 8px; gap: 8px;">'
            '<div style="background: #f44336; color: white; padding: 8px;">Short</div>'
            '<div style="background: #2196F3; color: white; padding: 24px;">Tall</div>'
            '<div style="background: #4CAF50; color: white; padding: 8px;">Short</div>'
            '</div>',
          ),
          _buildExample(
            'flex-end',
            '<div style="display: flex; align-items: flex-end; height: 100px; border: 1px solid #ddd; padding: 8px; gap: 8px;">'
            '<div style="background: #f44336; color: white; padding: 8px;">Short</div>'
            '<div style="background: #2196F3; color: white; padding: 24px;">Tall</div>'
            '<div style="background: #4CAF50; color: white; padding: 8px;">Short</div>'
            '</div>',
          ),
          _buildExample(
            'center',
            '<div style="display: flex; align-items: center; height: 100px; border: 1px solid #ddd; padding: 8px; gap: 8px;">'
            '<div style="background: #f44336; color: white; padding: 8px;">Short</div>'
            '<div style="background: #2196F3; color: white; padding: 24px;">Tall</div>'
            '<div style="background: #4CAF50; color: white; padding: 8px;">Short</div>'
            '</div>',
          ),
          _buildExample(
            'stretch (default)',
            '<div style="display: flex; align-items: stretch; height: 100px; border: 1px solid #ddd; padding: 8px; gap: 8px;">'
            '<div style="background: #f44336; color: white; padding: 8px;">Stretch</div>'
            '<div style="background: #2196F3; color: white; padding: 8px;">To</div>'
            '<div style="background: #4CAF50; color: white; padding: 8px;">Fill</div>'
            '</div>',
          ),
          const SizedBox(height: 24),
          _buildSection('gap property'),
          _buildExample(
            'gap: 8px',
            '<div style="display: flex; gap: 8px; border: 1px solid #ddd; padding: 8px;">'
            '<div style="background: #f44336; color: white; padding: 12px;">Item 1</div>'
            '<div style="background: #2196F3; color: white; padding: 12px;">Item 2</div>'
            '<div style="background: #4CAF50; color: white; padding: 12px;">Item 3</div>'
            '</div>',
          ),
          _buildExample(
            'gap: 16px',
            '<div style="display: flex; gap: 16px; border: 1px solid #ddd; padding: 8px;">'
            '<div style="background: #f44336; color: white; padding: 12px;">Item 1</div>'
            '<div style="background: #2196F3; color: white; padding: 12px;">Item 2</div>'
            '<div style="background: #4CAF50; color: white; padding: 12px;">Item 3</div>'
            '</div>',
          ),
          _buildExample(
            'row-gap & column-gap',
            '<div style="display: flex; flex-direction: column; row-gap: 16px; border: 1px solid #ddd; padding: 8px;">'
            '<div style="background: #f44336; color: white; padding: 12px;">Row Gap 16px</div>'
            '<div style="background: #2196F3; color: white; padding: 12px;">Between</div>'
            '<div style="background: #4CAF50; color: white; padding: 12px;">Items</div>'
            '</div>',
          ),
          const SizedBox(height: 24),
          _buildSection('flex-wrap'),
          _buildExample(
            'nowrap (default) - items may overflow',
            '<div style="display: flex; flex-wrap: nowrap; gap: 8px; border: 1px solid #ddd; padding: 8px; width: 300px;">'
            '<div style="background: #f44336; color: white; padding: 12px; width: 120px;">Wide 1</div>'
            '<div style="background: #2196F3; color: white; padding: 12px; width: 120px;">Wide 2</div>'
            '<div style="background: #4CAF50; color: white; padding: 12px; width: 120px;">Wide 3</div>'
            '</div>',
          ),
          _buildExample(
            'wrap - items wrap to next line',
            '<div style="display: flex; flex-wrap: wrap; gap: 8px; border: 1px solid #ddd; padding: 8px;">'
            '<div style="background: #f44336; color: white; padding: 12px; width: 100px;">Item 1</div>'
            '<div style="background: #2196F3; color: white; padding: 12px; width: 100px;">Item 2</div>'
            '<div style="background: #4CAF50; color: white; padding: 12px; width: 100px;">Item 3</div>'
            '<div style="background: #ff9800; color: white; padding: 12px; width: 100px;">Item 4</div>'
            '<div style="background: #9c27b0; color: white; padding: 12px; width: 100px;">Item 5</div>'
            '<div style="background: #00bcd4; color: white; padding: 12px; width: 100px;">Item 6</div>'
            '</div>',
          ),
          const SizedBox(height: 24),
          _buildSection('Practical Examples'),
          _buildExample(
            'Navbar Layout',
            '<div style="display: flex; justify-content: space-between; align-items: center; background: #1976D2; color: white; padding: 12px 16px; border-radius: 4px;">'
            '<div style="font-weight: bold; font-size: 18px;">MyApp</div>'
            '<div style="display: flex; gap: 16px;">'
            '<div>Home</div>'
            '<div>About</div>'
            '<div>Contact</div>'
            '</div>'
            '</div>',
          ),
          _buildExample(
            'Card with Icon and Text',
            '<div style="display: flex; gap: 12px; align-items: center; border: 1px solid #ddd; padding: 16px; border-radius: 8px; background: white;">'
            '<div style="background: #2196F3; color: white; padding: 16px; border-radius: 50%; width: 48px; height: 48px; display: flex; align-items: center; justify-content: center; font-size: 24px;">📧</div>'
            '<div style="flex: 1;">'
            '<div style="font-weight: bold; font-size: 16px;">New Message</div>'
            '<div style="color: #666; font-size: 14px;">You have 3 unread messages</div>'
            '</div>'
            '</div>',
          ),
          _buildExample(
            'Centered Content',
            '<div style="display: flex; justify-content: center; align-items: center; height: 150px; border: 1px solid #ddd; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 8px;">'
            '<div style="background: white; padding: 24px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">'
            '<div style="font-size: 20px; font-weight: bold; color: #333;">Welcome!</div>'
            '<div style="color: #666; margin-top: 8px;">Get started with Flexbox</div>'
            '</div>'
            '</div>',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'Flexbox Implementation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This demo showcases HyperRender\'s implementation of CSS Flexbox properties. '
              'Scroll down to see various flex layouts in action.',
              style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade800),
            ),
          ],
        ),
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
          color: Colors.purple.shade900,
        ),
      ),
    );
  }

  Widget _buildExample(String label, String html) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(8),
              child: HyperViewer(html: html),
            ),
          ],
        ),
      ),
    );
  }
}
