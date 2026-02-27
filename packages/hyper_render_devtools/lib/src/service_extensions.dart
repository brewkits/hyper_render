import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'udt_serializer.dart';

// Import hyper_render_core model types
import 'package:hyper_render_core/hyper_render_core.dart';

/// Registry for [RenderHyperBox] instances for DevTools inspection.
///
/// Each [RenderHyperBox] can register itself here so the DevTools panel
/// can find and inspect any active renderer on screen.
class _HyperRenderRegistry {
  static final _HyperRenderRegistry instance = _HyperRenderRegistry._();
  _HyperRenderRegistry._();

  final Map<String, _RendererInfo> _renderers = {};

  void register(String id, DocumentNode Function() getDocument) {
    _renderers[id] = _RendererInfo(id: id, getDocument: getDocument);
  }

  void unregister(String id) {
    _renderers.remove(id);
  }

  List<String> get registeredIds => _renderers.keys.toList();

  DocumentNode? getDocument(String id) {
    return _renderers[id]?.getDocument();
  }
}

class _RendererInfo {
  final String id;
  final DocumentNode Function() getDocument;

  _RendererInfo({required this.id, required this.getDocument});
}

/// DevTools integration for HyperRender.
///
/// Registers VM service extensions that the DevTools panel uses to inspect
/// UDT trees, computed styles, and performance data.
class HyperRenderDevtools {
  static bool _registered = false;

  /// Register VM service extensions for DevTools.
  ///
  /// Call this once at app startup, in debug mode only:
  /// ```dart
  /// assert(() {
  ///   HyperRenderDevtools.register();
  ///   return true;
  /// }());
  /// ```
  static void register() {
    if (_registered || !kDebugMode) return;
    _registered = true;

    // Extension: list all active renderers
    developer.registerExtension(
      'ext.hyperRender.listRenderers',
      (method, parameters) async {
        return developer.ServiceExtensionResponse.result(
          '{"renderers": ${_HyperRenderRegistry.instance.registeredIds}}',
        );
      },
    );

    // Extension: get UDT tree for a renderer
    developer.registerExtension(
      'ext.hyperRender.getUdt',
      (method, parameters) async {
        final id = parameters['id'] ?? _HyperRenderRegistry.instance.registeredIds.firstOrNull ?? '';
        final document = _HyperRenderRegistry.instance.getDocument(id);
        if (document == null) {
          return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.extensionError,
            'No renderer found with id: $id',
          );
        }
        final tree = UdtSerializer.serializeTree(document);
        return developer.ServiceExtensionResponse.result(
          '{"id": "$id", "tree": ${_encodeJson(tree)}}',
        );
      },
    );

    // Extension: get computed style for a specific node
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
          '{"nodeId": "$nodeId", "style": ${_encodeJson(style)}}',
        );
      },
    );

    debugPrint('[HyperRender DevTools] Service extensions registered: '
        'ext.hyperRender.{listRenderers, getUdt, getNodeStyle}');
  }

  /// Register a [RenderHyperBox]-like renderer for inspection.
  ///
  /// Call this from [RenderHyperBox] in its attach/detach lifecycle.
  static void registerRenderer(String id, DocumentNode Function() getDocument) {
    if (!kDebugMode) return;
    _HyperRenderRegistry.instance.register(id, getDocument);
  }

  /// Unregister a renderer (call on detach).
  static void unregisterRenderer(String id) {
    if (!kDebugMode) return;
    _HyperRenderRegistry.instance.unregister(id);
  }

  /// Encode a JSON-compatible object to string.
  static String _encodeJson(Object? value) {
    if (value == null) return 'null';
    if (value is String) return '"${value.replaceAll('"', '\\"')}"';
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      return '[${value.map(_encodeJson).join(',')}]';
    }
    if (value is Map) {
      final pairs = value.entries.map((e) {
        return '"${e.key}": ${_encodeJson(e.value)}';
      }).join(',');
      return '{$pairs}';
    }
    return '"${value.toString().replaceAll('"', '\\"')}"';
  }
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
