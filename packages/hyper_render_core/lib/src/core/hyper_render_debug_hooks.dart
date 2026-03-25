import 'package:flutter/foundation.dart' show kDebugMode;

import '../model/node.dart';

/// Zero-overhead hook points for DevTools integration.
///
/// `hyper_render_devtools` injects callbacks here at startup so it can
/// observe renderer lifecycle and layout results WITHOUT creating a circular
/// package dependency (core ← devtools would be circular).
///
/// All fields are `null` in release builds and the call sites are guarded by
/// `kDebugMode`, so there is no production overhead.
///
/// ## Usage (by hyper_render_devtools)
/// ```dart
/// HyperRenderDebugHooks.onRendererAttached = (id, getDoc) { ... };
/// HyperRenderDebugHooks.onRendererDetached = (id) { ... };
/// HyperRenderDebugHooks.onLayoutComplete   = (id, getFrags, getLines) { ... };
/// ```
abstract final class HyperRenderDebugHooks {
  /// Called when a [RenderHyperBox] is attached to the pipeline.
  ///
  /// [id] is stable for the lifetime of this renderer instance.
  /// [getDocument] returns the current [DocumentNode] (may be null if no
  /// content has been set yet).
  static void Function(
    String id,
    DocumentNode? Function() getDocument,
  )? onRendererAttached;

  /// Called when a [RenderHyperBox] is detached from the pipeline.
  static void Function(String id)? onRendererDetached;

  /// Called at the end of each successful [performLayout] pass.
  ///
  /// [getFragments] / [getLines] are lazy getters — call them only if you
  /// actually need the data to avoid unnecessary serialization work.
  static void Function(
    String id,
    List<Map<String, dynamic>> Function() getFragments,
    List<Map<String, dynamic>> Function() getLines,
  )? onLayoutComplete;

  /// Optional getter injected by devtools to retrieve the latest
  /// [PerformanceReport]-like map for a renderer by id.
  ///
  /// Returns null if no performance data is available for [id].
  static Map<String, dynamic>? Function(String id)? getPerformanceData;

  /// Returns true only when at least one hook is registered.
  /// Used as a fast-path guard in hot paths.
  static bool get isActive =>
      kDebugMode &&
      (onRendererAttached != null ||
          onRendererDetached != null ||
          onLayoutComplete != null);
}
