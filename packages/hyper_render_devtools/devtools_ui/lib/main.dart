import 'dart:convert';

import 'package:flutter/material.dart';

void main() {
  runApp(const HyperRenderInspectorApp());
}

class HyperRenderInspectorApp extends StatelessWidget {
  const HyperRenderInspectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperRender Inspector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const InspectorShell(),
    );
  }
}

/// Shell widget with tab navigation for the DevTools panel.
class InspectorShell extends StatefulWidget {
  const InspectorShell({super.key});

  @override
  State<InspectorShell> createState() => _InspectorShellState();
}

class _InspectorShellState extends State<InspectorShell>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic>? _udtTree;
  Map<String, dynamic>? _selectedNodeStyle;
  String? _selectedNodeId;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadUdtTree();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadUdtTree() async {
    setState(() { _loading = true; _error = null; });
    // In a real devtools extension, this would call:
    // final result = await serviceManager.callServiceExtensionOnMainIsolate(
    //   'ext.hyperRender.getUdt', args: {},
    // );
    // For now, show placeholder UI.
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _loading = false;
      _udtTree = {
        'id': 'root',
        'type': 'document',
        'tagName': '(document)',
        'childCount': 0,
        'children': <dynamic>[],
        'attributes': <String, String>{},
        'style': <String, dynamic>{},
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.account_tree, size: 20),
            const SizedBox(width: 8),
            const Text('HyperRender Inspector'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _loadUdtTree,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.account_tree, size: 16), text: 'UDT Tree'),
            Tab(icon: Icon(Icons.style, size: 16), text: 'Style'),
            Tab(icon: Icon(Icons.speed, size: 16), text: 'Layout'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _buildTreeView(),
                    _buildStyleView(),
                    _buildLayoutView(),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUdtTree,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeView() {
    if (_udtTree == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_tree, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No UDT data.\nConnect to a running HyperRender app\nwith HyperRenderDevtools.register() called.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Click a node to inspect its computed style.',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: _UdtNodeWidget(
              node: _udtTree!,
              selectedId: _selectedNodeId,
              onSelected: (id, style) {
                setState(() {
                  _selectedNodeId = id;
                  _selectedNodeStyle = style;
                  _tabs.animateTo(1);
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyleView() {
    if (_selectedNodeStyle == null) {
      return const Center(
        child: Text(
          'Select a node in the UDT Tree tab\nto inspect its computed style.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _SectionHeader('Computed Style — Node: $_selectedNodeId'),
        ..._selectedNodeStyle!.entries
            .where((e) => e.value != null && e.value.toString() != 'null')
            .map((e) => _StylePropertyRow(name: e.key, value: e.value)),
      ],
    );
  }

  Widget _buildLayoutView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SectionHeader('Layout Info'),
        _InfoCard(
          title: 'Fragment Layout',
          description:
              'Fragment bounds are available via debugShowBounds=true on HyperViewer.',
        ),
        SizedBox(height: 8),
        _InfoCard(
          title: 'Enable Debug Bounds',
          description: 'HyperViewer(html: ..., debugShowHyperRenderBounds: true)\n'
              'Shows blue (lines) and orange (fragments) outlines.',
        ),
        SizedBox(height: 8),
        _InfoCard(
          title: 'Performance Data',
          description:
              'Use PerformanceMonitor from hyper_render_core for detailed timing.\n'
              'Access via ext.hyperRender.getPerformance (coming soon).',
        ),
      ],
    );
  }
}

class _UdtNodeWidget extends StatefulWidget {
  final Map<String, dynamic> node;
  final String? selectedId;
  final void Function(String id, Map<String, dynamic>? style) onSelected;

  const _UdtNodeWidget({
    required this.node,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  State<_UdtNodeWidget> createState() => _UdtNodeWidgetState();
}

class _UdtNodeWidgetState extends State<_UdtNodeWidget> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final nodeId = widget.node['id'] as String? ?? '';
    final tagName = widget.node['tagName'] as String? ?? '';
    final nodeType = widget.node['type'] as String? ?? '';
    final children = widget.node['children'] as List? ?? [];
    final style = widget.node['style'] as Map<String, dynamic>?;
    final isSelected = widget.selectedId == nodeId;
    final text = widget.node['text'] as String?;

    final hasChildren = children.isNotEmpty;
    final color = _nodeTypeColor(nodeType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => widget.onSelected(nodeId, style),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade100 : null,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                if (hasChildren)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Icon(
                      _expanded ? Icons.expand_more : Icons.chevron_right,
                      size: 16,
                      color: Colors.grey,
                    ),
                  )
                else
                  const SizedBox(width: 16),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  '<$tagName>',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: color,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (text != null) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '"${text.length > 40 ? '${text.substring(0, 40)}…' : text}"',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_expanded && hasChildren)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children.cast<Map<String, dynamic>>().map((child) {
                return _UdtNodeWidget(
                  node: child,
                  selectedId: widget.selectedId,
                  onSelected: widget.onSelected,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Color _nodeTypeColor(String type) {
    switch (type) {
      case 'document': return Colors.purple;
      case 'block': return Colors.blue;
      case 'inline': return Colors.green;
      case 'text': return Colors.grey;
      case 'atomic': return Colors.orange;
      case 'table': case 'tableRow': case 'tableCell': return Colors.teal;
      case 'ruby': return Colors.pink;
      default: return Colors.grey;
    }
  }
}

class _StylePropertyRow extends StatelessWidget {
  final String name;
  final dynamic value;

  const _StylePropertyRow({required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    final displayValue = value is Map
        ? const JsonEncoder.withIndent('  ').convert(value)
        : value.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.blue.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String description;
  const _InfoCard({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(description,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
