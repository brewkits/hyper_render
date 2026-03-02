part of 'render_hyper_box.dart';

/// Parent data for children of RenderHyperBox
class HyperBoxParentData extends ContainerBoxParentData<RenderBox> {
  /// The source UDT node this child corresponds to
  UDTNode? sourceNode;

  /// The fragment this child corresponds to (for atomic elements)
  Fragment? fragment;

  /// Whether this child is a float element
  bool isFloat = false;

  /// Float direction (left or right)
  HyperFloat floatDirection = HyperFloat.none;

  /// The computed rect after float layout
  Rect? floatRect;
}

/// Float area that text must flow around
class _FloatArea {
  final Rect rect;
  final HyperFloat direction;

  _FloatArea({required this.rect, required this.direction});
}

/// Inline decoration info for painting background/border across line breaks
class _InlineDecoration {
  final UDTNode node;
  final List<Rect> rects;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;

  _InlineDecoration({
    required this.node,
    required this.rects,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.borderRadius,
  });
}

/// Block decoration info for painting border-left, background on block elements
class _BlockDecoration {
  final UDTNode node;
  final Rect rect;
  final Color? backgroundColor;
  final Color? borderLeftColor;
  final double borderLeftWidth;
  final BorderRadius? borderRadius;

  _BlockDecoration({
    required this.node,
    required this.rect,
    this.backgroundColor,
    this.borderLeftColor,
    this.borderLeftWidth = 0,
    this.borderRadius,
  });
}

/// LRU Cache for TextPainter to prevent memory leak
///
/// Uses LinkedHashMap with access-order to automatically track LRU entries.
/// When capacity is exceeded, the least recently used entry is evicted.
class _LruCache<K, V> {
  final int _maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();
  final void Function(V)? _onEvict;

  _LruCache({required int maxSize, void Function(V)? onEvict})
      : _maxSize = maxSize,
        _onEvict = onEvict;

  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      // Re-insert to move to end (most recently used)
      _cache[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    // Guard: a zero/negative maxSize means caching is disabled — evict and discard.
    if (_maxSize <= 0) {
      _onEvict?.call(value);
      return;
    }

    // Remove existing to update access order
    final existing = _cache.remove(key);
    if (existing != null) {
      _onEvict?.call(existing);
    }

    // Evict if at capacity
    while (_cache.length >= _maxSize) {
      final eldest = _cache.keys.first;
      final evicted = _cache.remove(eldest);
      if (evicted != null) {
        _onEvict?.call(evicted);
      }
    }

    _cache[key] = value;
  }

  bool containsKey(K key) => _cache.containsKey(key);

  void clear() {
    final onEvict = _onEvict;
    if (onEvict != null) {
      for (final value in _cache.values) {
        onEvict(value);
      }
    }
    _cache.clear();
  }

  int get length => _cache.length;

  Iterable<V> get values => _cache.values;
}

/// Selection range for text
class HyperTextSelection {
  final int start;
  final int end;

  const HyperTextSelection({required this.start, required this.end});

  bool get isCollapsed => start == end;
  bool get isValid => start >= 0 && end >= start;

  HyperTextSelection copyWith({int? start, int? end}) {
    return HyperTextSelection(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}
