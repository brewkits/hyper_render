import 'package:hyper_render_core/hyper_render_core.dart';
import 'dart:collection';
import 'dart:ui' as ui;

/// A singleton priority queue for image loading.
///
/// Images are loaded in ascending priority order (lower number = closer to
/// viewport = loaded first). At most [maxConcurrent] loads run in parallel.
///
/// Each [enqueue] call returns a subscription token. Pass that token to
/// [cancel] when the requesting widget is disposed so its callback is removed
/// before the image arrives. This prevents:
///   - Callbacks firing on detached RenderObjects.
///   - GPU memory leaks from abandoned [ui.Image] instances.
///   - One viewer's disposal cancelling another viewer's pending load.
///
/// Usage:
/// ```dart
/// final token = LazyImageQueue.instance.enqueue(
///   url: 'https://example.com/image.png',
///   priority: 0,        // 0 = in viewport, higher = further away
///   loader: myLoader,
///   onLoad: (img) { ... },
///   onError: (e) { ... },
/// );
/// // On dispose:
/// LazyImageQueue.instance.cancel(token);
/// ```
class LazyImageQueue {
  LazyImageQueue._();

  static final LazyImageQueue instance = LazyImageQueue._();

  /// Maximum number of concurrent image loads.
  int maxConcurrent = 3;

  final _queue = SplayTreeMap<_QueueKey, _PendingLoad>();

  /// Loads currently in-flight (loader called, result not yet received).
  final Set<_PendingLoad> _inFlight = {};

  int _active = 0;
  int _sequenceCounter = 0;
  int _subscriptionCounter = 0;

  /// Maps subscription token → url for O(1) cancel lookup.
  final Map<int, String> _tokenToUrl = {};

  /// Enqueue an image load request.
  ///
  /// Returns a subscription [token] that must be passed to [cancel] when the
  /// requesting widget is disposed.
  ///
  /// [priority] — lower means higher urgency (0 = viewport-visible).
  ///
  /// If the same [url] is already queued or in-flight, the new callback is
  /// merged into the existing load; priority is lowered if the new value is
  /// smaller. No duplicate network request is made.
  int enqueue({
    required String url,
    required int priority,
    required HyperImageLoader loader,
    required void Function(ui.Image) onLoad,
    required void Function(Object) onError,
  }) {
    final token = _subscriptionCounter++;
    _tokenToUrl[token] = url;

    // Check in-flight first — deduplicates requests for URLs already loading.
    for (final load in _inFlight) {
      if (load.url == url) {
        load.onLoadCallbacks[token] = onLoad;
        load.onErrorCallbacks[token] = onError;
        return token;
      }
    }

    // Check queued — merge or re-prioritise.
    final existing = _findQueued(url);
    if (existing != null) {
      if (priority < existing.priority) {
        // Re-prioritise: remove and re-insert with new priority.
        _queue.remove(existing.key);
        final updated = existing.copyWithPriority(priority, _sequenceCounter++);
        updated.onLoadCallbacks[token] = onLoad;
        updated.onErrorCallbacks[token] = onError;
        _queue[updated.key] = updated;
      } else {
        existing.onLoadCallbacks[token] = onLoad;
        existing.onErrorCallbacks[token] = onError;
      }
      return token;
    }

    final key = _QueueKey(priority, _sequenceCounter++);
    _queue[key] = _PendingLoad(
      key: key,
      url: url,
      priority: priority,
      loader: loader,
      onLoadCallbacks: {token: onLoad},
      onErrorCallbacks: {token: onError},
    );

    _pump();
    return token;
  }

  /// Remove this widget's subscription. Safe to call after completion (no-op).
  ///
  /// - If the load is still queued and this was the last subscriber, the queue
  ///   entry is removed entirely (avoids a wasted network request).
  /// - If the load is in-flight, the callback is removed; when the image
  ///   arrives and no subscribers remain, the [ui.Image] is disposed so GPU
  ///   memory is not leaked.
  void cancel(int token) {
    final url = _tokenToUrl.remove(token);
    if (url == null) return; // already completed or invalid token

    // Search queued loads.
    for (final entry in _queue.entries) {
      if (entry.value.url == url) {
        final load = entry.value;
        load.onLoadCallbacks.remove(token);
        load.onErrorCallbacks.remove(token);
        // Remove the queue entry if no subscribers remain — no point loading.
        if (load.onLoadCallbacks.isEmpty) {
          _queue.remove(entry.key);
        }
        return;
      }
    }

    // Search in-flight loads.
    for (final load in _inFlight) {
      if (load.url == url) {
        load.onLoadCallbacks.remove(token);
        load.onErrorCallbacks.remove(token);
        // Do not remove from _inFlight; the loader will still complete and
        // _startLoad will dispose the image if no callbacks remain.
        return;
      }
    }
  }

  /// Resets all internal state for testing purposes.
  ///
  /// Clears the pending queue and resets the in-flight counter so that each
  /// test starts with a clean singleton. Only available in debug/test builds.
  void resetForTesting() {
    for (final load in _inFlight) {
      load.onLoadCallbacks.clear();
      load.onErrorCallbacks.clear();
    }
    _inFlight.clear();
    _queue.clear();
    _tokenToUrl.clear();
    _active = 0;
    _sequenceCounter = 0;
    _subscriptionCounter = 0;
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
    _inFlight.add(load);

    load.loader(
      load.url,
      (ui.Image image) {
        _active--;
        _inFlight.remove(load);

        // Remove token mappings for all remaining subscribers (load complete).
        for (final token in load.onLoadCallbacks.keys) {
          _tokenToUrl.remove(token);
        }

        if (load.onLoadCallbacks.isEmpty) {
          // All subscribers cancelled before image arrived.
          // Dispose to prevent GPU memory leak — Dart GC cannot free ui.Image.
          image.dispose();
        } else {
          // Distribute independent clones so each subscriber owns its resource.
          // Disposing a clone does not affect other clones or the original.
          for (final cb in load.onLoadCallbacks.values) {
            cb(image.clone());
          }
          image.dispose(); // release the source after cloning
        }

        _pump();
      },
      (Object error) {
        _active--;
        _inFlight.remove(load);

        for (final token in load.onErrorCallbacks.keys) {
          _tokenToUrl.remove(token);
        }
        for (final cb in load.onErrorCallbacks.values) {
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

  /// Keyed by subscription token so individual subscribers can be cancelled.
  final Map<int, void Function(ui.Image)> onLoadCallbacks;
  final Map<int, void Function(Object)> onErrorCallbacks;

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
        onLoadCallbacks: Map.of(onLoadCallbacks),
        onErrorCallbacks: Map.of(onErrorCallbacks),
      );
}
