import 'package:hyper_render_core/hyper_render_core.dart';
import 'dart:collection';
import 'dart:ui' as ui;

/// A singleton priority queue for image loading.
///
/// Images are loaded in ascending priority order (lower number = closer to
/// viewport = loaded first). At most [maxConcurrent] loads run in parallel.
///
/// Usage:
/// ```dart
/// LazyImageQueue.instance.enqueue(
///   url: 'https://example.com/image.png',
///   priority: 0,        // 0 = in viewport, higher = further away
///   loader: myLoader,
///   onLoad: (img) { ... },
///   onError: (e) { ... },
/// );
/// ```
class LazyImageQueue {
  LazyImageQueue._();

  static final LazyImageQueue instance = LazyImageQueue._();

  /// Maximum number of concurrent image loads.
  int maxConcurrent = 3;

  final _queue = SplayTreeMap<_QueueKey, _PendingLoad>();
  int _active = 0;
  int _sequenceCounter = 0;

  /// Enqueue an image load request.
  ///
  /// [priority] — lower means higher urgency (0 = viewport-visible).
  /// If the same [url] is already loading or queued, the new request is
  /// merged: callbacks are appended and priority is updated if lower.
  void enqueue({
    required String url,
    required int priority,
    required HyperImageLoader loader,
    required void Function(ui.Image) onLoad,
    required void Function(Object) onError,
  }) {
    // Already loading → just add callback.
    final existing = _findQueued(url);
    if (existing != null) {
      if (priority < existing.priority) {
        // Re-prioritise: remove and re-insert with new priority.
        _queue.remove(existing.key);
        final updated = existing.copyWithPriority(priority, _sequenceCounter++);
        updated.onLoadCallbacks.add(onLoad);
        updated.onErrorCallbacks.add(onError);
        _queue[updated.key] = updated;
      } else {
        existing.onLoadCallbacks.add(onLoad);
        existing.onErrorCallbacks.add(onError);
      }
      return;
    }

    final key = _QueueKey(priority, _sequenceCounter++);
    _queue[key] = _PendingLoad(
      key: key,
      url: url,
      priority: priority,
      loader: loader,
      onLoadCallbacks: [onLoad],
      onErrorCallbacks: [onError],
    );

    _pump();
  }

  /// Remove all pending requests (e.g., when the widget is disposed).
  void cancelAll(String url) {
    _queue.removeWhere((_, load) => load.url == url);
  }

  void _pump() {
    while (_active < maxConcurrent && _queue.isNotEmpty) {
      final entry = _queue.entries.first;
      _queue.remove(entry.key);
      _startLoad(entry.value);
    }
  }

  void _startLoad(_PendingLoad load) {
    _active++;

    load.loader(
      load.url,
      (ui.Image image) {
        _active--;
        for (final cb in load.onLoadCallbacks) {
          cb(image);
        }
        _pump();
      },
      (Object error) {
        _active--;
        for (final cb in load.onErrorCallbacks) {
          cb(error);
        }
        _pump();
      },
    );
  }

  _PendingLoad? _findQueued(String url) {
    for (final load in _queue.values) {
      if (load.url == url) return load;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Internal types
// ---------------------------------------------------------------------------

class _QueueKey implements Comparable<_QueueKey> {
  final int priority;
  final int sequence; // tie-breaker: earlier = lower sequence

  const _QueueKey(this.priority, this.sequence);

  @override
  int compareTo(_QueueKey other) {
    final p = priority.compareTo(other.priority);
    return p != 0 ? p : sequence.compareTo(other.sequence);
  }

  @override
  bool operator ==(Object other) =>
      other is _QueueKey &&
      priority == other.priority &&
      sequence == other.sequence;

  @override
  int get hashCode => Object.hash(priority, sequence);
}

class _PendingLoad {
  final _QueueKey key;
  final String url;
  int priority;
  final HyperImageLoader loader;
  final List<void Function(ui.Image)> onLoadCallbacks;
  final List<void Function(Object)> onErrorCallbacks;

  _PendingLoad({
    required this.key,
    required this.url,
    required this.priority,
    required this.loader,
    required this.onLoadCallbacks,
    required this.onErrorCallbacks,
  });

  _PendingLoad copyWithPriority(int newPriority, int newSequence) =>
      _PendingLoad(
        key: _QueueKey(newPriority, newSequence),
        url: url,
        priority: newPriority,
        loader: loader,
        onLoadCallbacks: List.of(onLoadCallbacks),
        onErrorCallbacks: List.of(onErrorCallbacks),
      );
}
