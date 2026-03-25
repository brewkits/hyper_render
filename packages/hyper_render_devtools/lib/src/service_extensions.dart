import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'udt_serializer.dart';

// Import hyper_render_core model types
import 'package:hyper_render_core/hyper_render_core.dart';

/// Registry for [RenderHyperBox] instances for DevTools inspection.
///
/// Each [RenderHyperBox] registers itself automatically via
/// [HyperRenderDebugHooks] when [HyperRenderDevtools.register] has been called.
class _HyperRenderRegistry {
  static final _HyperRenderRegistry instance = _HyperRenderRegistry._();
  _HyperRenderRegistry._();

  final Map<String, _RendererInfo> _renderers = {};

  void register(String id, DocumentNode? Function() getDocument) {
    _renderers[id] = _RendererInfo(id: id, getDocument: getDocument);
  }

  void unregister(String id) {
    _renderers.remove(id);
  }

  void updateLayout(
    String id,
    List<Map<String, dynamic>> fragments,
    List<Map<String, dynamic>> lines,
  ) {
    final info = _renderers[id];
    if (info == null) return;
    info.lastFragments = fragments;
    info.lastLines = lines;
  }

  List<String> get registeredIds => _renderers.keys.toList();

  DocumentNode? getDocument(String id) => _renderers[id]?.getDocument();

  List<Map<String, dynamic>>? getFragments(String id) =>
      _renderers[id]?.lastFragments;

  List<Map<String, dynamic>>? getLines(String id) => _renderers[id]?.lastLines;
}

class _RendererInfo {
  final String id;
  final DocumentNode? Function() getDocument;
  List<Map<String, dynamic>>? lastFragments;
  List<Map<String, dynamic>>? lastLines;

  _RendererInfo({required this.id, required this.getDocument});
}

/// DevTools integration for HyperRender.
///
/// Registers VM service extensions that the DevTools panel uses to inspect
/// UDT trees, computed styles, fragments, and performance data.
///
/// ## Setup (once at app startup, debug mode only)
/// ```dart
/// void main() {
///   assert(() {
///     HyperRenderDevtools.register();
///     return true;
///   }());
///   runApp(const MyApp());
/// }
/// ```
///
/// After calling [register], all [HyperViewer] / [HyperRenderWidget] instances
/// are tracked automatically — no per-widget setup required.
class HyperRenderDevtools {
  static bool _registered = false;

  /// Register VM service extensions and wire up the auto-registration hooks.
  ///
  /// Safe to call multiple times — only registers once.
  static void register() {
    if (_registered || !kDebugMode) return;
    _registered = true;

    // ── Hook into RenderHyperBox lifecycle ──────────────────────────────────
    // HyperRenderDebugHooks are static callbacks in hyper_render_core that
    // RenderHyperBox calls in attach/detach/performLayout.  By injecting here
    // we avoid any circular package dependency.

    HyperRenderDebugHooks.onRendererAttached = (id, getDocument) {
      _HyperRenderRegistry.instance.register(id, getDocument);
    };

    HyperRenderDebugHooks.onRendererDetached = (id) {
      _HyperRenderRegistry.instance.unregister(id);
    };

    HyperRenderDebugHooks.onLayoutComplete = (id, getFragments, getLines) {
      _HyperRenderRegistry.instance.updateLayout(
        id,
        getFragments(),
        getLines(),
      );
    };

    // ── Service extension: list all active renderers ─────────────────────────
    developer.registerExtension(
      'ext.hyperRender.listRenderers',
      (method, parameters) async {
        final ids = _HyperRenderRegistry.instance.registeredIds;
        return developer.ServiceExtensionResponse.result(
          jsonEncode({'renderers': ids}),
        );
      },
    );

    // ── Service extension: get UDT tree for a renderer ───────────────────────
    developer.registerExtension(
      'ext.hyperRender.getUdt',
      (method, parameters) async {
        final id = parameters['id'] ??
            _HyperRenderRegistry.instance.registeredIds.firstOrNull ??
            '';
        final document = _HyperRenderRegistry.instance.getDocument(id);
        if (document == null) {
          return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.extensionError,
            'No renderer found with id: $id',
          );
        }
        final tree = UdtSerializer.serializeTree(document);
        return developer.ServiceExtensionResponse.result(
          jsonEncode({'id': id, 'tree': tree}),
        );
      },
    );

    // ── Service extension: get computed style for a specific node ────────────
    developer.registerExtension(
      'ext.hyperRender.getNodeStyle',
      (method, parameters) async {
        final rendererId = parameters['rendererId'] ?? '';
        final nodeId = parameters['nodeId'] ?? '';
        final document = _HyperRenderRegistry.instance.getDocument(rendererId);
        if (document == null) {
          return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.extensionError,
            'Renderer not found: $rendererId',
          );
        }
        final node = document.findById(nodeId);
        if (node == null) {
          return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.extensionError,
            'Node not found: $nodeId',
          );
        }
        final style = UdtSerializer.serializeStyle(node.style);
        return developer.ServiceExtensionResponse.result(
          jsonEncode({'nodeId': nodeId, 'style': style}),
        );
      },
    );

    // ── Service extension: get fragment + line layout data ───────────────────
    developer.registerExtension(
      'ext.hyperRender.getFragments',
      (method, parameters) async {
        final id = parameters['id'] ??
            _HyperRenderRegistry.instance.registeredIds.firstOrNull ??
            '';
        final fragments = _HyperRenderRegistry.instance.getFragments(id);
        final lines = _HyperRenderRegistry.instance.getLines(id);
        if (fragments == null) {
          return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.extensionError,
            'No layout data for renderer: $id. '
            'Ensure HyperRenderDevtools.register() was called before the '
            'first layout pass.',
          );
        }
        return developer.ServiceExtensionResponse.result(
          jsonEncode({
            'id': id,
            'fragmentCount': fragments.length,
            'lineCount': lines?.length ?? 0,
            'fragments': fragments,
            'lines': lines ?? [],
          }),
        );
      },
    );

    // ── Service extension: get performance data ──────────────────────────────
    developer.registerExtension(
      'ext.hyperRender.getPerformance',
      (method, parameters) async {
        final id = parameters['id'] ??
            _HyperRenderRegistry.instance.registeredIds.firstOrNull ??
            '';
        final data = HyperRenderDebugHooks.getPerformanceData?.call(id);
        if (data == null) {
          // Return summary stats derived from fragment/line counts as a
          // lightweight fallback when no PerformanceMonitor is wired.
          final fragments =
              _HyperRenderRegistry.instance.getFragments(id) ?? [];
          final lines = _HyperRenderRegistry.instance.getLines(id) ?? [];
          return developer.ServiceExtensionResponse.result(
            jsonEncode({
              'id': id,
              'fragmentCount': fragments.length,
              'lineCount': lines.length,
              'note': 'Wire HyperRenderDebugHooks.getPerformanceData for '
                  'full timing data.',
            }),
          );
        }
        return developer.ServiceExtensionResponse.result(
          jsonEncode({'id': id, 'performance': data}),
        );
      },
    );

    debugPrint(
      '[HyperRender DevTools] Service extensions registered: '
      'ext.hyperRender.{listRenderers, getUdt, getNodeStyle, '
      'getFragments, getPerformance}',
    );
  }

  // ── Legacy manual API (kept for back-compat) ─────────────────────────────

  /// Manually register a renderer for inspection.
  ///
  /// Not needed when [register] has been called — renderers auto-register
  /// via [HyperRenderDebugHooks].  Only use this if you need to expose a
  /// custom document source that doesn't go through [RenderHyperBox].
  static void registerRenderer(
    String id,
    DocumentNode Function() getDocument,
  ) {
    if (!kDebugMode) return;
    _HyperRenderRegistry.instance.register(id, getDocument);
  }

  /// Manually unregister a renderer.
  static void unregisterRenderer(String id) {
    if (!kDebugMode) return;
    _HyperRenderRegistry.instance.unregister(id);
  }
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
