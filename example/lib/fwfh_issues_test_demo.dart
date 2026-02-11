import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

/// Demo to test features that flutter_widget_from_html (FWFH) has issues with
/// This verifies HyperRender handles these cases correctly
class FWFHIssuesTestDemo extends StatelessWidget {
  const FWFHIssuesTestDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FWFH Issues Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildTestCard(
            title: '1. <style> Tag Support (FWFH #1525)',
            description: 'CSS rules defined in <style> tag should apply',
            html: '''
              <style>
                .highlight {
                  background-color: yellow;
                  padding: 4px 8px;
                  border-radius: 4px;
                }
                .blue-text {
                  color: blue;
                  font-weight: bold;
                }
                .red-box {
                  background-color: #ffebee;
                  border: 2px solid red;
                  padding: 12px;
                  border-radius: 8px;
                  margin: 16px 0;
                }
              </style>
              <p class="blue-text">This text should be blue and bold.</p>
              <p>This has a <span class="highlight">yellow highlighted</span> section.</p>
              <div class="red-box">
                This box should have a red border and pink background.
              </div>
            ''',
            expectedResult: '✅ Text is blue/bold, highlight is yellow, box has red border',
          ),
          const SizedBox(height: 16),
          _buildTestCard(
            title: '2. Image Centering (FWFH #1535)',
            description: 'Images with display:block and margin:auto should center',
            html: '''
              <p>Before image</p>
              <img
                src="https://picsum.photos/200/100"
                style="display: block; margin: 0 auto; border: 2px solid blue;"
                alt="Centered image">
              <p>After image</p>
              <hr>
              <p>Left aligned image:</p>
              <img
                src="https://picsum.photos/150/80"
                style="display: block; margin: 0; border: 2px solid green;"
                alt="Left image">
              <p>Right aligned image:</p>
              <img
                src="https://picsum.photos/150/80"
                style="display: block; margin: 0 0 0 auto; border: 2px solid red;"
                alt="Right image">
            ''',
            expectedResult: '✅ Blue border image centered, green left, red right',
          ),
          const SizedBox(height: 16),
          _buildTestCard(
            title: '3. Table Text-Align (FWFH #1534, #1446)',
            description: 'text-align should work in table cells with borders',
            html: '''
              <table border="1" style="width: 100%; border-collapse: collapse;">
                <tr>
                  <th style="text-align: left; padding: 8px;">Left</th>
                  <th style="text-align: center; padding: 8px;">Center</th>
                  <th style="text-align: right; padding: 8px;">Right</th>
                </tr>
                <tr>
                  <td style="text-align: left; padding: 8px;">Left text</td>
                  <td style="text-align: center; padding: 8px;">Center text</td>
                  <td style="text-align: right; padding: 8px;">Right text</td>
                </tr>
                <tr>
                  <td style="text-align: center; padding: 16px; height: 100px;">
                    <img src="https://picsum.photos/50" alt="Small image">
                  </td>
                  <td style="text-align: center; vertical-align: middle; padding: 8px;">
                    Middle aligned
                  </td>
                  <td style="text-align: center; vertical-align: top; padding: 8px;">
                    Top aligned
                  </td>
                </tr>
              </table>
            ''',
            expectedResult: '✅ Text aligns correctly, image centered in cell',
          ),
          const SizedBox(height: 16),
          _buildTestCard(
            title: '4. Float Layout (FWFH #1449) - HyperRender Advantage!',
            description: 'Text should wrap around floated images (FWFH can\'t do this)',
            html: '''
              <h4>Float Left Example</h4>
              <img
                src="https://picsum.photos/120/120"
                style="float: left; margin-right: 12px; margin-bottom: 8px; border: 2px solid blue;">
              <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit.
              Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
              Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.</p>
              <p>This is another paragraph that should continue wrapping around
              the floated image on the left side. This demonstrates HyperRender's
              unique advantage over flutter_widget_from_html.</p>
              <div style="clear: both;"></div>

              <h4>Float Right Example</h4>
              <img
                src="https://picsum.photos/120/120"
                style="float: right; margin-left: 12px; margin-bottom: 8px; border: 2px solid red;">
              <p>Now the image is floated right, and text wraps around the left side.
              Flutter_widget_from_html struggles with this fundamental CSS feature,
              but HyperRender handles it perfectly.</p>
              <p>Multiple paragraphs continue to flow naturally around the floated element,
              just like in a web browser. This is powered by HyperRender's custom RenderHyperBox.</p>
            ''',
            expectedResult: '✅ Text flows around floated images (LEFT: blue border, RIGHT: red border)',
          ),
          const SizedBox(height: 16),
          _buildTestCard(
            title: '5. List Styles',
            description: 'Different list-style-type values',
            html: '''
              <h4>Unordered Lists</h4>
              <ul style="list-style-type: disc;">
                <li>Disc item 1</li>
                <li>Disc item 2</li>
              </ul>
              <ul style="list-style-type: circle;">
                <li>Circle item 1</li>
                <li>Circle item 2</li>
              </ul>
              <ul style="list-style-type: square;">
                <li>Square item 1</li>
                <li>Square item 2</li>
              </ul>

              <h4>Ordered Lists</h4>
              <ol style="list-style-type: decimal;">
                <li>Decimal item 1</li>
                <li>Decimal item 2</li>
              </ol>
              <ol style="list-style-type: upper-alpha;">
                <li>Upper alpha A</li>
                <li>Upper alpha B</li>
              </ol>
              <ol style="list-style-type: lower-roman;">
                <li>Lower roman i</li>
                <li>Lower roman ii</li>
              </ol>
            ''',
            expectedResult: '⚠️ Check if different list markers render correctly',
          ),
          const SizedBox(height: 16),
          _buildTestCard(
            title: '6. Complex Nesting',
            description: 'Tables inside floated divs, lists in tables, etc.',
            html: '''
              <div style="float: left; width: 45%; margin-right: 10px; border: 1px solid #ddd; padding: 8px;">
                <h4>Floated Table</h4>
                <table border="1" style="width: 100%;">
                  <tr>
                    <th>Header 1</th>
                    <th>Header 2</th>
                  </tr>
                  <tr>
                    <td>Cell 1</td>
                    <td>Cell 2</td>
                  </tr>
                </table>
              </div>

              <div style="float: left; width: 45%; border: 1px solid #ddd; padding: 8px;">
                <h4>Floated List</h4>
                <ul>
                  <li>Item 1</li>
                  <li>Item 2
                    <ul>
                      <li>Nested A</li>
                      <li>Nested B</li>
                    </ul>
                  </li>
                  <li>Item 3</li>
                </ul>
              </div>

              <div style="clear: both;"></div>

              <p style="margin-top: 16px;">Content after floated elements should appear below both floats.</p>
            ''',
            expectedResult: '✅ Two floated boxes side by side, content clears below',
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
          colors: [Colors.deepOrange.shade700, Colors.red.shade600],
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
              Icon(Icons.bug_report, color: Colors.white, size: 40),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FWFH Issues Test',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Testing features that flutter_widget_from_html struggles with',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Compare with FWFH issues: #1525, #1535, #1534, #1449',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard({
    required String title,
    required String description,
    required String html,
    required String expectedResult,
  }) {
    return Card(
      elevation: 2,
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      expectedResult,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
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
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'HyperRender Advantages',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBullet('Float Layout - Text wraps around images/videos (FWFH #1449)'),
          _buildBullet('Performance - No jank with isolate parsing'),
          _buildBullet('Selection - Crash-free on large documents'),
          _buildBullet('CJK Typography - Perfect Kinsoku + Ruby support'),
          _buildBullet('Tables - Smart horizontal scroll + colspan/rowspan'),
          const SizedBox(height: 12),
          Text(
            'If any test above shows issues, report at:\ngithub.com/vietnguyentuan/hyper_render/issues',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
