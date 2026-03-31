// Demo for the v1.2.0 Multi-tier Plugin API (HyperNodePlugin / HyperPluginRegistry).
// Shows both block-level and inline-level custom tag plugins.

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'html_preview_helper.dart';

// ── Plugin implementations ────────────────────────────────────────────────────

/// Block plugin: renders `<info-box type="tip|warning|danger">` as a styled callout.
class InfoBoxPlugin extends HyperNodePlugin {
  const InfoBoxPlugin();

  @override
  List<String> get tagNames => ['info-box'];

  @override
  bool get isInline => false;

  @override
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) {
    final type = node.attributes['type'] ?? 'tip';
    final (color, icon) = switch (type) {
      'warning' => (Colors.orange.shade700, Icons.warning_amber_rounded),
      'danger' => (Colors.red.shade700, Icons.error_outline),
      _ => (Colors.blue.shade700, Icons.lightbulb_outline),
    };
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              node.textContent,
              style: ctx.baseStyle.copyWith(color: color, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Block plugin: renders `<rating value="3" max="5">` as a star row.
class RatingPlugin extends HyperNodePlugin {
  const RatingPlugin();

  @override
  List<String> get tagNames => ['rating'];

  @override
  bool get isInline => false;

  @override
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) {
    final value = int.tryParse(node.attributes['value'] ?? '0') ?? 0;
    final max = int.tryParse(node.attributes['max'] ?? '5') ?? 5;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: List.generate(
          max,
          (i) => Icon(
            i < value ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber.shade700,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Inline plugin: renders `<badge color="#hex">` as a colored pill that flows with text.
class BadgePlugin extends HyperNodePlugin {
  const BadgePlugin();

  @override
  List<String> get tagNames => ['badge'];

  @override
  bool get isInline => true;

  @override
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) {
    final hex = node.attributes['color'] ?? '#2196F3';
    Color color;
    try {
      color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        node.textContent,
        style: ctx.baseStyle.copyWith(
          color: Colors.white,
          fontSize: 11,
          height: 1.3,
        ),
      ),
    );
  }
}

// ── Demo HTML ─────────────────────────────────────────────────────────────────

const _kDemoHtml = '''
<h2>Block Plugins</h2>

<p>Block plugins receive full available width with CSS margins applied.</p>

<info-box type="tip">
  Tip: Use block plugins for standalone components like callouts, cards, or media players.
</info-box>

<info-box type="warning">
  Warning: Always validate node.attributes — HTML attributes can contain arbitrary values.
</info-box>

<info-box type="danger">
  Danger: Never pass unvalidated HTML attributes directly to Uri.parse or network requests.
</info-box>

<h3>Star Rating</h3>
<p>A &lt;rating&gt; tag rendered by a block plugin:</p>
<rating value="4" max="5"></rating>

<h2>Inline Plugins</h2>

<p>Inline plugins flow alongside text. Here are some status badges:
<badge color="#4CAF50">stable</badge>
<badge color="#FF9800">beta</badge>
<badge color="#F44336">deprecated</badge></p>

<p>The inline plugin&#39;s intrinsic size is measured by the layout engine so
text wraps correctly around it at any viewport width.</p>

<h2>Fallthrough</h2>
<p>Unknown tags fall through to the default renderer,
which renders their text content inline.</p>
''';

// ── Demo widget ───────────────────────────────────────────────────────────────

class PluginApiDemo extends StatefulWidget {
  const PluginApiDemo({super.key});

  @override
  State<PluginApiDemo> createState() => _PluginApiDemoState();
}

class _PluginApiDemoState extends State<PluginApiDemo> {
  late final HyperPluginRegistry _registry;

  @override
  void initState() {
    super.initState();
    _registry = HyperPluginRegistry()
      ..register(const InfoBoxPlugin())
      ..register(const RatingPlugin())
      ..register(const BadgePlugin());
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Plugin API (v1.2.0)',
      html: _kDemoHtml,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: HyperViewer(
          html: _kDemoHtml,
          pluginRegistry: _registry,
        ),
      ),
    );
  }
}
