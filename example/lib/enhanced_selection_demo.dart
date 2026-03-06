import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

/// Enhanced Selection Menu Demo
///
/// Demonstrates advanced selection menu with additional actions:
/// - Copy (default)
/// - Select All (default)
/// - Share - Share selected text to other apps
/// - Search - Search selected text on Google
/// - Look Up - Dictionary lookup (iOS/macOS)
/// - Custom actions
class EnhancedSelectionDemo extends StatefulWidget {
  const EnhancedSelectionDemo({super.key});

  @override
  State<EnhancedSelectionDemo> createState() => _EnhancedSelectionDemoState();
}

class _EnhancedSelectionDemoState extends State<EnhancedSelectionDemo> {
  String _lastAction = 'None';
  String _selectedText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Enhanced Selection Menu'),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // Status card
          _buildStatusCard(),
          const SizedBox(height: 24),

          // Demo 1: Basic Enhanced Menu
          _buildSection(
            title: '1. Enhanced Menu (Share + Search)',
            description: 'Copy, Select All, Share, Search on Google',
            child: HyperViewer(
              html: '''
                <div style="background: #F3E5F5; padding: 24px; border-radius: 12px; border: 2px solid #9C27B0;">
                  <h2 style="color: #4A148C; margin: 0 0 16px 0; line-height: 1.3;">Try Selecting Text Here!</h2>
                  <p style="color: #6A1B9A; font-size: 16px; line-height: 2.0; margin: 0 0 16px 0;">
                    HyperRender is a powerful Flutter package for rendering HTML content
                    with advanced features like text selection, float layout, and more.
                  </p>
                  <p style="color: #6A1B9A; font-size: 16px; line-height: 2.0; margin: 0 0 16px 0;">
                    <strong style="color: #4A148C;">Long press or drag</strong> to select text and see the enhanced menu.
                  </p>
                  <blockquote style="background: rgba(156, 39, 176, 0.1); border-left: 4px solid #9C27B0; padding: 16px; margin: 0; color: #4A148C; font-style: italic; line-height: 1.8;">
                    "The best way to predict the future is to invent it." - Alan Kay
                  </blockquote>
                </div>
              ''',
              selectable: true,
              selectionMenuActionsBuilder: (overlayState) {
                return [
                  // Default actions
                  SelectionMenuAction(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onPressed: () => _handleCopy(overlayState),
                  ),
                  SelectionMenuAction(
                    icon: Icons.select_all_rounded,
                    label: 'All',
                    onPressed: overlayState.selectAll,
                  ),
                  // NEW: Share action
                  SelectionMenuAction(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onPressed: () => _handleShare(overlayState),
                  ),
                  // NEW: Search action
                  SelectionMenuAction(
                    icon: Icons.search_rounded,
                    label: 'Search',
                    onPressed: () => _handleSearch(overlayState),
                  ),
                ];
              },
            ),
          ),

          const SizedBox(height: 24),

          // Demo 2: Full-Featured Menu
          _buildSection(
            title: '2. Full-Featured Menu (7 Actions)',
            description: 'Copy, All, Share, Search, Translate, Define, Highlight',
            child: HyperViewer(
              html: '''
                <article style="background: #E3F2FD; padding: 24px; border-radius: 12px; border: 2px solid #1976D2;">
                  <h2 style="color: #0D47A1; margin: 0 0 16px 0; line-height: 1.3;">Advanced Selection Features</h2>
                  <p style="color: #1565C0; font-size: 16px; line-height: 2.0; margin: 0 0 20px 0;">
                    Flutter is Google's UI toolkit for building beautiful, natively
                    compiled applications for mobile, web, and desktop from a single codebase.
                  </p>

                  <h3 style="color: #1976D2; margin: 0 0 12px 0; line-height: 1.3;">Key Features:</h3>
                  <ul style="color: #1565C0; font-size: 15px; line-height: 2.0; margin: 0 0 20px 0; padding-left: 24px;">
                    <li style="margin-bottom: 8px;">Fast Development with Hot Reload</li>
                    <li style="margin-bottom: 8px;">Expressive and Flexible UI</li>
                    <li style="margin-bottom: 8px;">Native Performance</li>
                  </ul>

                  <p style="color: #0D47A1; font-size: 16px; line-height: 2.0; margin: 0;">
                    Select any text to see <em style="font-weight: bold;">7 different actions</em> in the context menu!
                  </p>
                </article>
              ''',
              selectable: true,
              selectionMenuActionsBuilder: (overlayState) {
                return [
                  SelectionMenuAction(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onPressed: () => _handleCopy(overlayState),
                  ),
                  SelectionMenuAction(
                    icon: Icons.select_all_rounded,
                    label: 'All',
                    onPressed: overlayState.selectAll,
                  ),
                  SelectionMenuAction(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onPressed: () => _handleShare(overlayState),
                  ),
                  SelectionMenuAction(
                    icon: Icons.search_rounded,
                    label: 'Search',
                    onPressed: () => _handleSearch(overlayState),
                  ),
                  SelectionMenuAction(
                    icon: Icons.translate_rounded,
                    label: 'Trans',
                    onPressed: () => _handleTranslate(overlayState),
                  ),
                  SelectionMenuAction(
                    icon: Icons.book_rounded,
                    label: 'Define',
                    onPressed: () => _handleDefine(overlayState),
                  ),
                  SelectionMenuAction(
                    icon: Icons.highlight_rounded,
                    label: 'Note',
                    onPressed: () => _handleHighlight(overlayState),
                  ),
                ];
              },
            ),
          ),

          const SizedBox(height: 24),

          // Demo 3: Custom Styled Menu
          _buildSection(
            title: '3. Custom Colors & Icons',
            description: 'Themed selection with custom handle color',
            child: HyperViewer(
              html: '''
                <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                            padding: 28px; border-radius: 12px; border: 3px solid #5E35B1; box-shadow: 0 4px 12px rgba(0,0,0,0.2);">
                  <h2 style="color: white; margin: 0 0 16px 0; font-size: 22px; font-weight: bold; line-height: 1.3;">Gradient Theme</h2>
                  <p style="color: rgba(255,255,255,0.95); font-size: 16px; line-height: 2.0; margin: 0;">
                    This example shows custom selection handle colors.
                    Try selecting this text to see <strong style="color: #FFD54F;">purple handles</strong> and a custom menu!
                  </p>
                </div>
              ''',
              selectable: true,
              selectionHandleColor: Colors.purple,
              selectionMenuActionsBuilder: (overlayState) {
                return [
                  SelectionMenuAction(
                    icon: Icons.content_copy,
                    label: 'Copy',
                    onPressed: () => _handleCopy(overlayState),
                  ),
                  SelectionMenuAction(
                    icon: Icons.select_all,
                    label: 'All',
                    onPressed: overlayState.selectAll,
                  ),
                  SelectionMenuAction(
                    icon: Icons.ios_share,
                    label: 'Share',
                    onPressed: () => _handleShare(overlayState),
                  ),
                ];
              },
            ),
          ),

          const SizedBox(height: 24),

          // Instructions
          _buildInstructionsCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.touch_app, color: Colors.purple.shade700, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enhanced Selection Menu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rich context menu like native apps',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildFeatureItem('✅ 7+ menu actions (vs default 2)'),
            _buildFeatureItem('✅ Share to other apps'),
            _buildFeatureItem('✅ Web search integration'),
            _buildFeatureItem('✅ Translation services'),
            _buildFeatureItem('✅ Dictionary lookup'),
            _buildFeatureItem('✅ Custom actions & theming'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Last Action Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 16),
            _buildStatusRow('Action:', _lastAction),
            if (_selectedText.isNotEmpty)
              _buildStatusRow('Text:', '"${_selectedText.length > 50 ? '${_selectedText.substring(0, 50)}...' : _selectedText}"'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'How to Use',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInstruction('1. Long press or drag to select text'),
            _buildInstruction('2. Menu appears above selection'),
            _buildInstruction('3. Tap an action (Copy, Share, Search, etc.)'),
            _buildInstruction('4. Check status card for results'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '''selectionMenuActionsBuilder: (state) {
  return [
    SelectionMenuAction(
      icon: Icons.copy_rounded,
      label: 'Copy',
      onPressed: () => handleCopy(state),
    ),
    SelectionMenuAction(
      icon: Icons.share_rounded,
      label: 'Share',
      onPressed: () => handleShare(state),
    ),
    // Add more actions...
  ];
}''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Action Handlers
  // ============================================================================

  void _handleCopy(SelectionOverlayController state) {
    final text = state.selectedText;
    if (text != null && text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      setState(() {
        _lastAction = 'Copy';
        _selectedText = text;
      });
      _showSnackBar('✅ Copied to clipboard', Colors.green);
      state.clearSelection();
    }
  }

  void _handleShare(SelectionOverlayController state) async {
    final text = state.selectedText;
    if (text != null && text.isNotEmpty) {
      setState(() {
        _lastAction = 'Share';
        _selectedText = text;
      });

      try {
        // Share using share_plus package
        final result = await Share.share(
          text,
          subject: 'Shared from HyperRender',
        );

        if (result.status == ShareResultStatus.success) {
          _showSnackBar('✅ Shared successfully', Colors.green);
        } else if (result.status == ShareResultStatus.dismissed) {
          _showSnackBar('ℹ️ Share cancelled', Colors.orange);
        } else {
          _showSnackBar('📤 Share dialog opened', Colors.blue);
        }
      } catch (e) {
        print('Share error: $e');
        _showSnackBar('❌ Share not available: ${e.toString()}', Colors.red);
      }

      state.clearSelection();
    }
  }

  void _handleSearch(SelectionOverlayController state) async {
    final text = state.selectedText;
    if (text != null && text.isNotEmpty) {
      setState(() {
        _lastAction = 'Search on Google';
        _selectedText = text;
      });

      // Open Google search
      final query = Uri.encodeComponent(text);
      final url = Uri.parse('https://www.google.com/search?q=$query');

      try {
        print('Attempting to launch: $url');
        if (await canLaunchUrl(url)) {
          final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
          if (launched) {
            _showSnackBar('🔍 Opened Google search', Colors.green);
          } else {
            _showSnackBar('⚠️ Browser opened but URL may not load', Colors.orange);
          }
        } else {
          _showSnackBar('❌ Cannot open browser - URL not supported', Colors.red);
        }
      } catch (e) {
        print('Search error: $e');
        _showSnackBar('❌ Failed to open browser: ${e.toString()}', Colors.red);
      }

      state.clearSelection();
    }
  }

  void _handleTranslate(SelectionOverlayController state) async {
    final text = state.selectedText;
    if (text != null && text.isNotEmpty) {
      setState(() {
        _lastAction = 'Translate';
        _selectedText = text;
      });

      // Open Google Translate
      final query = Uri.encodeComponent(text);
      final url = Uri.parse('https://translate.google.com/?text=$query&sl=auto&tl=en');

      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          _showSnackBar('🌐 Opened Google Translate', Colors.blue);
        }
      } catch (e) {
        _showSnackBar('❌ Failed to open translator', Colors.red);
      }

      state.clearSelection();
    }
  }

  void _handleDefine(SelectionOverlayController state) async {
    final text = state.selectedText;
    if (text != null && text.isNotEmpty) {
      setState(() {
        _lastAction = 'Dictionary Lookup';
        _selectedText = text;
      });

      // Open dictionary (using DuckDuckGo define)
      final query = Uri.encodeComponent(text);
      final url = Uri.parse('https://duckduckgo.com/?q=define+$query');

      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          _showSnackBar('📚 Opened dictionary', Colors.blue);
        }
      } catch (e) {
        _showSnackBar('❌ Failed to open dictionary', Colors.red);
      }

      state.clearSelection();
    }
  }

  void _handleHighlight(SelectionOverlayController state) {
    final text = state.selectedText;
    if (text != null && text.isNotEmpty) {
      setState(() {
        _lastAction = 'Highlight / Note';
        _selectedText = text;
      });

      // Show dialog for note
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.highlight, color: Colors.amber),
              SizedBox(width: 8),
              Text('Create Note'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selected text:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  border: Border.all(color: Colors.yellow.shade700),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  text,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'In a real app, this would save the highlight with your notes.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Note'),
              onPressed: () {
                Navigator.pop(context);
                _showSnackBar('💾 Note saved!', Colors.green);
              },
            ),
          ],
        ),
      );

      state.clearSelection();
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
