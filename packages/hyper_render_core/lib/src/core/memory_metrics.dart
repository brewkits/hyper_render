import 'package:flutter/foundation.dart';

/// Snapshot of what a single memory-pressure cycle released.
///
/// Produced by `HyperViewer.didHaveMemoryPressure` and published to
/// [HyperMemoryDebug] in debug builds so tools (DevTools, tests) can observe
/// how much memory each pressure event actually reclaimed.
@immutable
class HyperMemoryMetrics {
  /// Bytes freed from Flutter's decoded-image cache
  /// (`PaintingBinding.imageCache`) by this pressure cycle.
  final int imageCacheBytesFreed;

  /// Number of decoded images evicted from Flutter's image cache.
  final int imageCacheImagesEvicted;

  /// Number of live [RenderHyperBox] instances whose TextPainter/image caches
  /// were cleared.
  final int renderBoxesCleared;

  /// Number of pending (not-yet-started) image loads dropped from the
  /// `LazyImageQueue`.
  final int pendingImageLoadsDropped;

  /// When this pressure cycle was handled.
  final DateTime timestamp;

  const HyperMemoryMetrics({
    required this.imageCacheBytesFreed,
    required this.imageCacheImagesEvicted,
    required this.renderBoxesCleared,
    required this.pendingImageLoadsDropped,
    required this.timestamp,
  });

  @override
  String toString() => 'HyperMemoryMetrics(bytesFreed: $imageCacheBytesFreed, '
      'imagesEvicted: $imageCacheImagesEvicted, '
      'boxesCleared: $renderBoxesCleared, '
      'pendingDropped: $pendingImageLoadsDropped, at: $timestamp)';
}

/// Debug-only sink for [HyperMemoryMetrics].
///
/// In release builds [record] is a no-op and [lastMetrics] stays null, so
/// metrics collection carries zero cost in production. Subscribe to
/// [notifier] to observe pressure events live (e.g. from a DevTools panel).
class HyperMemoryDebug {
  HyperMemoryDebug._();

  static final ValueNotifier<HyperMemoryMetrics?> notifier =
      ValueNotifier<HyperMemoryMetrics?>(null);

  /// Most recent metrics recorded, or null if none (always null in release).
  static HyperMemoryMetrics? get lastMetrics => notifier.value;

  /// Records [metrics] for observers. No-op outside debug builds.
  static void record(HyperMemoryMetrics metrics) {
    if (!kDebugMode) return;
    notifier.value = metrics;
  }

  /// Clears the recorded metrics (primarily for tests).
  static void reset() => notifier.value = null;
}
