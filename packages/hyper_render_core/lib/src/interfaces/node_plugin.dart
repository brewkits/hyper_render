import 'package:flutter/widgets.dart';

import '../model/node.dart';

/// Context provided to [HyperNodePlugin.buildWidget].
///
/// Contains the ambient rendering properties so plugins can match the
/// document's base typography and handle link taps consistently.
class HyperPluginBuildContext {
  /// The resolved base [TextStyle] for the enclosing [HyperRenderWidget].
  final TextStyle baseStyle;

  /// Called when the user taps a hyperlink. Forward to your `url_launcher`
  /// or router as appropriate.
  final void Function(String url)? onLinkTap;

  const HyperPluginBuildContext({
    required this.baseStyle,
    this.onLinkTap,
  });
}

/// Abstract base for a HyperRender node plugin.
///
/// A plugin intercepts one or more HTML tag names and returns a Flutter
/// [Widget] in place of the default canvas-based rendering.  There are two
/// rendering tiers:
///
/// * **Block tier** (`isInline == false`, the default): The widget takes the
///   full available width, just like a `<div>` or `<figure>`.  Margins from
///   the node's CSS `margin` property are still applied.
///
/// * **Inline tier** (`isInline == true`): The widget flows inside the text
///   line like an image.  Set `style="width:…; height:…"` on the element so
///   the layout engine knows how much space to reserve; if omitted, a 50×24
///   logical-pixel placeholder is used.
///
/// ## Example — block plugin for `<figure>`
/// ```dart
/// class FigurePlugin extends HyperNodePlugin {
///   @override
///   List<String> get tagNames => ['figure'];
///
///   @override
///   Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) {
///     final caption = node.children
///         .whereType<BlockNode>()
///         .firstWhere((n) => n.tagName == 'figcaption', orElse: () => null)
///         ?.textContent ?? '';
///     return Column(
///       crossAxisAlignment: CrossAxisAlignment.start,
///       children: [
///         // render image children via widgetBuilder or default
///         Text(caption, style: ctx.baseStyle.copyWith(fontStyle: FontStyle.italic)),
///       ],
///     );
///   }
/// }
/// ```
///
/// ## Example — inline plugin for `<badge>`
/// ```dart
/// class BadgePlugin extends HyperNodePlugin {
///   @override
///   List<String> get tagNames => ['badge'];
///
///   @override
///   bool get isInline => true;
///
///   @override
///   Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) {
///     return Container(
///       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
///       decoration: BoxDecoration(
///         color: Colors.blue,
///         borderRadius: BorderRadius.circular(8),
///       ),
///       child: Text(node.textContent,
///           style: ctx.baseStyle.copyWith(color: Colors.white, fontSize: 11)),
///     );
///   }
/// }
/// ```
abstract class HyperNodePlugin {
  const HyperNodePlugin();

  /// The HTML tag names this plugin handles, e.g. `['math', 'figure']`.
  ///
  /// Tag names are compared **case-insensitively**.
  List<String> get tagNames;

  /// Whether this plugin renders an **inline** widget (flows with text) or a
  /// **block** widget (full width, with CSS margins).
  ///
  /// Defaults to `false` (block).
  bool get isInline => false;

  /// Build the widget for [node].
  ///
  /// Return `null` to fall through to the built-in renderer for this node.
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx);
}

/// Registry for [HyperNodePlugin] instances.
///
/// Register plugins once (typically in `main()` or at app startup) and pass
/// the registry to [HyperViewer] or [HyperRenderWidget]:
///
/// ```dart
/// final plugins = HyperPluginRegistry()
///   ..register(MathPlugin())
///   ..register(FigurePlugin())
///   ..register(BadgePlugin());  // isInline = true
///
/// HyperViewer(
///   html: content,
///   pluginRegistry: plugins,
/// )
/// ```
class HyperPluginRegistry {
  final Map<String, HyperNodePlugin> _map = {};

  /// Register a plugin.  The last registration wins for a given tag name.
  HyperPluginRegistry register(HyperNodePlugin plugin) {
    for (final tag in plugin.tagNames) {
      _map[tag.toLowerCase()] = plugin;
    }
    return this; // fluent
  }

  /// Return the plugin registered for [tagName], or `null` if none.
  HyperNodePlugin? pluginFor(String? tagName) =>
      tagName == null ? null : _map[tagName.toLowerCase()];

  /// Whether any plugin is registered for [tagName].
  bool hasPlugin(String? tagName) =>
      tagName != null && _map.containsKey(tagName.toLowerCase());

  /// Tag names handled by block-tier plugins.
  Set<String> get blockPluginTags => {
        for (final e in _map.entries)
          if (!e.value.isInline) e.key,
      };

  /// Tag names handled by inline-tier plugins.
  Set<String> get inlinePluginTags => {
        for (final e in _map.entries)
          if (e.value.isInline) e.key,
      };

  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
}
