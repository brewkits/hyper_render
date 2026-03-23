import 'dart:convert';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const HyperRenderInspectorApp());
}

class HyperRenderInspectorApp extends StatelessWidget {
  const HyperRenderInspectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DevToolsExtension(
      child: MaterialApp(
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shell
// ─────────────────────────────────────────────────────────────────────────────

class InspectorShell extends StatefulWidget {
  const InspectorShell({super.key});

  @override
  State<InspectorShell> createState() => _InspectorShellState();
}

class _InspectorShellState extends State<InspectorShell>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // ── State ────────────────────────────────────────────────────────────────
  List<String> _rendererIds = [];
  String? _selectedRendererId;

  Map<String, dynamic>? _udtTree;
  Map<String, dynamic>? _selectedNodeStyle;
  String? _selectedNodeId;

  List<dynamic> _fragments = [];
  List<dynamic> _lines = [];

  Map<String, dynamic>? _perfData;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Service extension helpers ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> _call(
    String method, [
    Map<String, Object> args = const {},
  ]) async {
    try {
      final result =
          await serviceManager.callServiceExtensionOnMainIsolate(
        method,
        args: args,
      );
      final raw = result.json;
      if (raw == null) return null;
      // The response is encoded as a JSON string inside result['result']
      final resultStr = raw['result'] as String?;
      if (resultStr == null) return null;
      return jsonDecode(resultStr) as Map<String, dynamic>;
    } catch (e) {
      return {'_error': e.toString()};
    }
  }

  // ── Refresh flow ─────────────────────────────────────────────────────────

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. List renderers
      final listResult = await _call('ext.hyperRender.listRenderers');
      if (listResult == null || listResult.containsKey('_error')) {
        setState(() {
          _loading = false;
          _error = listResult?['_error'] as String? ??
              'Could not connect to app. '
                  'Ensure HyperRenderDevtools.register() is called at startup.';
        });
        return;
      }
      final ids =
          (listResult['renderers'] as List?)?.cast<String>() ?? <String>[];

      // 2. Select first renderer if none selected yet
      final selectedId =
          (_selectedRendererId != null && ids.contains(_selectedRendererId))
              ? _selectedRendererId
              : ids.firstOrNull;

      setState(() {
        _rendererIds = ids;
        _selectedRendererId = selectedId;
      });

      if (selectedId != null) {
        await Future.wait([
          _loadUdt(selectedId),
          _loadFragments(selectedId),
          _loadPerformance(selectedId),
        ]);
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadUdt(String id) async {
    final result = await _call('ext.hyperRender.getUdt', {'id': id});
    if (result != null && !result.containsKey('_error')) {
      final treeList = result['tree'] as List?;
      setState(() {
        _udtTree = treeList?.isNotEmpty == true
            ? treeList!.first as Map<String, dynamic>
            : null;
        _selectedNodeStyle = null;
        _selectedNodeId = null;
      });
    }
  }

  Future<void> _loadFragments(String id) async {
    final result =
        await _call('ext.hyperRender.getFragments', {'id': id});
    if (result != null && !result.containsKey('_error')) {
      setState(() {
        _fragments = result['fragments'] as List? ?? [];
        _lines = result['lines'] as List? ?? [];
      });
    }
  }

  Future<void> _loadPerformance(String id) async {
    final result =
        await _call('ext.hyperRender.getPerformance', {'id': id});
    if (result != null && !result.containsKey('_error')) {
      setState(() => _perfData = result);
    }
  }

  Future<void> _loadNodeStyle(String rendererId, String nodeId) async {
    final result = await _call(
      'ext.hyperRender.getNodeStyle',
      {'rendererId': rendererId, 'nodeId': nodeId},
    );
    if (result != null && !result.containsKey('_error')) {
      setState(() {
        _selectedNodeStyle = result['style'] as Map<String, dynamic>?;
        _selectedNodeId = nodeId;
        _tabs.animateTo(1);
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.account_tree, size: 20),
            const SizedBox(width: 8),
            const Text('HyperRender Inspector'),
            const SizedBox(width: 16),
            if (_rendererIds.isNotEmpty)
              _RendererDropdown(
                ids: _rendererIds,
                selectedId: _selectedRendererId,
                onChanged: (id) {
                  setState(() => _selectedRendererId = id);
                  if (id != null) {
                    Future.wait([
                      _loadUdt(id),
                      _loadFragments(id),
                      _loadPerformance(id),
                    ]);
                  }
                },
              ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _refresh,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.account_tree, size: 16), text: 'UDT Tree'),
            Tab(icon: Icon(Icons.style, size: 16), text: 'Style'),
            Tab(icon: Icon(Icons.view_list, size: 16), text: 'Layout'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _rendererIds.isEmpty
                  ? _buildNoRenderers()
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

  Widget _buildNoRenderers() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No active HyperRender renderers found.\n\n'
            'Make sure your app calls:\n'
            'HyperRenderDevtools.register()\n'
            'at startup in debug mode.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontFamily: 'monospace'),
          ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ── UDT Tree tab ──────────────────────────────────────────────────────────

  Widget _buildTreeView() {
    if (_udtTree == null) {
      return const Center(
        child: Text(
          'No document loaded.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.blue.shade50,
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.blue),
              SizedBox(width: 6),
              Text(
                'Click a node to inspect its computed style.',
                style: TextStyle(fontSize: 12, color: Colors.blue),
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
              onSelected: (nodeId) {
                if (_selectedRendererId != null) {
                  _loadNodeStyle(_selectedRendererId!, nodeId);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Style tab ─────────────────────────────────────────────────────────────

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
            .map((e) => _PropertyRow(name: e.key, value: e.value)),
      ],
    );
  }

  // ── Layout tab ────────────────────────────────────────────────────────────

  Widget _buildLayoutView() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // Performance summary
        if (_perfData != null) ...[
          _SectionHeader('Renderer'),
          _PropertyRow(name: 'id', value: _perfData!['id']),
          _PropertyRow(
              name: 'fragments', value: _perfData!['fragmentCount']),
          _PropertyRow(name: 'lines', value: _perfData!['lineCount']),
          if (_perfData!['note'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                _perfData!['note'] as String,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
        ],

        // Fragment list
        _SectionHeader(
            'Fragments (${_fragments.length}) — last layout pass'),
        if (_fragments.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('No fragments yet.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        else
          ..._fragments
              .cast<Map<String, dynamic>>()
              .take(200) // cap at 200 rows to keep UI snappy
              .map((f) => _FragmentRow(fragment: f)),

        // Line list
        const SizedBox(height: 8),
        _SectionHeader('Lines (${_lines.length})'),
        if (_lines.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('No lines yet.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        else
          ..._lines
              .cast<Map<String, dynamic>>()
              .map((l) => _LineRow(line: l)),

        const SizedBox(height: 16),
        const _InfoCard(
          title: 'Visual debug bounds',
          description:
              'HyperViewer(html: ..., debugShowHyperRenderBounds: true)\n'
              'Blue = line rows  •  Orange = inline fragments',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Renderer dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _RendererDropdown extends StatelessWidget {
  final List<String> ids;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _RendererDropdown({
    required this.ids,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedId,
      isDense: true,
      underline: const SizedBox(),
      hint: const Text('Select renderer', style: TextStyle(fontSize: 12)),
      items: ids
          .map((id) => DropdownMenuItem<String>(
                value: id,
                child: Text(id,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UDT node tree widget
// ─────────────────────────────────────────────────────────────────────────────

class _UdtNodeWidget extends StatefulWidget {
  final Map<String, dynamic> node;
  final String? selectedId;
  final ValueChanged<String> onSelected;

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
    final isSelected = widget.selectedId == nodeId;
    final text = widget.node['text'] as String?;
    final truncated = widget.node['childrenTruncated'] as bool? ?? false;

    final hasChildren = children.isNotEmpty;
    final color = _nodeTypeColor(nodeType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => widget.onSelected(nodeId),
          borderRadius: BorderRadius.circular(4),
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
                    onTap: () =>
                        setState(() => _expanded = !_expanded),
                    child: Icon(
                      _expanded
                          ? Icons.expand_more
                          : Icons.chevron_right,
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
              children: [
                ...children.cast<Map<String, dynamic>>().map((child) =>
                    _UdtNodeWidget(
                      node: child,
                      selectedId: widget.selectedId,
                      onSelected: widget.onSelected,
                    )),
                if (truncated)
                  const Padding(
                    padding: EdgeInsets.only(left: 4, top: 2),
                    child: Text(
                      '… (depth limit reached)',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Color _nodeTypeColor(String type) {
    return switch (type) {
      'document' => Colors.purple,
      'block' => Colors.blue,
      'inline' => Colors.green,
      'text' => Colors.grey,
      'atomic' => Colors.orange,
      'table' || 'tableRow' || 'tableCell' => Colors.teal,
      'ruby' => Colors.pink,
      _ => Colors.grey,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fragment / Line rows
// ─────────────────────────────────────────────────────────────────────────────

class _FragmentRow extends StatelessWidget {
  final Map<String, dynamic> fragment;
  const _FragmentRow({required this.fragment});

  @override
  Widget build(BuildContext context) {
    final type = fragment['type'] as String? ?? '?';
    final text = fragment['text'] as String?;
    final w = (fragment['width'] as num?)?.toStringAsFixed(1) ?? '—';
    final h = (fragment['height'] as num?)?.toStringAsFixed(1) ?? '—';
    final x = (fragment['offsetX'] as num?)?.toStringAsFixed(1) ?? '—';
    final y = (fragment['offsetY'] as num?)?.toStringAsFixed(1) ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          _TypeBadge(type),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text != null
                  ? '"${text.length > 30 ? '${text.substring(0, 30)}…' : text}"'
                  : type,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${w}×$h @ ($x,$y)',
            style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final Map<String, dynamic> line;
  const _LineRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final frags = line['fragmentCount'] ?? '?';
    final top = (line['top'] as num?)?.toStringAsFixed(1) ?? '—';
    final h = (line['height'] as num?)?.toStringAsFixed(1) ?? '—';
    final baseline =
        (line['baseline'] as num?)?.toStringAsFixed(1) ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          const _TypeBadge('line'),
          const SizedBox(width: 6),
          Text(
            '$frags fragments',
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
          const Spacer(),
          Text(
            'top=$top  h=$h  base=$baseline',
            style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  const _TypeBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 10, fontFamily: 'monospace', color: Colors.blueGrey),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PropertyRow extends StatelessWidget {
  final String name;
  final dynamic value;

  const _PropertyRow({required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    final displayValue = value is Map || value is List
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
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
      padding: const EdgeInsets.only(bottom: 6, top: 12),
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
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(description,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
