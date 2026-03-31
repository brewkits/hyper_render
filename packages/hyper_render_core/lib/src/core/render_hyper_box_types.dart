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

/// Describes a float element whose visual area extends beyond the bottom of a
/// virtualized section boundary.
///
/// Produced by [RenderHyperBox.danglingFloats] after layout and consumed by the
/// next section's [RenderHyperBox] via [RenderHyperBox.initialFloats], so that
/// text in Chunk N+1 correctly indents alongside a float that began in Chunk N.
///
/// ### Why parse-time dimensions are used
/// The carryover is computed from float-fragment dimensions already resolved
/// during the layout of Chunk N — no additional image-load is required.
/// For lazy-loaded images whose dimensions are not yet known, [width] will be
/// zero and the carryover will have no effect on Chunk N+1 (safe default).
class FloatCarryover {
  /// Whether this float is on the left or right edge.
  final HyperFloat direction;

  /// Width of the float element in logical pixels.
  final double width;

  /// The height of the float that overhangs into the next section (logical px).
  ///
  /// This equals `float.rect.bottom − naturalTextHeight` for the originating
  /// chunk, where `naturalTextHeight` is the content height without the float
  /// extension.
  final double overhangHeight;

  const FloatCarryover({
    required this.direction,
    required this.width,
    required this.overhangHeight,
  });

  @override
  String toString() =>
      'FloatCarryover($direction, w=$width, overhang=$overhangHeight)';
}

/// Inline decoration info for painting background/border across line breaks
class _InlineDecoration {
  final UDTNode node;
  final List<Rect> rects;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final ui.ImageFilter? filter;
  final ui.ImageFilter? backdropFilter;

  _InlineDecoration({
    required this.node,
    required this.rects,
    this.backgroundColor,
    this.backgroundGradient,
    this.borderColor,
    this.borderWidth = 0,
    this.borderRadius,
    this.boxShadow,
    this.filter,
    this.backdropFilter,
  });
}

/// Block decoration info for painting border-left, background on block elements
class _BlockDecoration {
  final UDTNode node;
  final Rect rect;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final Color? borderLeftColor;
  final double borderLeftWidth;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final ui.ImageFilter? filter;
  final ui.ImageFilter? backdropFilter;

  /// Whether to draw all 4 sides (true) or only the left side (false, blockquote-style)
  final bool fullBorder;

  /// The border style for the full-box border (solid, dashed, dotted, double, etc.)
  final HyperBorderStyle borderStyle;

  _BlockDecoration({
    required this.node,
    required this.rect,
    this.backgroundColor,
    this.backgroundGradient,
    this.borderLeftColor,
    this.borderLeftWidth = 0,
    this.borderRadius,
    this.boxShadow,
    this.filter,
    this.backdropFilter,
    this.fullBorder = false,
    this.borderStyle = HyperBorderStyle.solid,
  });
}

/// Cache key for [TextPainter] instances stored in [RenderHyperBox._textPainters].
///
/// Uses full value-equality across all style properties so that two fragments
/// with different visual styles never collide to the same cache slot.
/// Previously the cache used [Object.hash] → `int`, which has birthday-paradox
/// collision risk on documents with many distinct text styles (probability
/// reaches ~1% around √(2^32) ≈ 65K entries).  A struct key eliminates the
/// risk entirely at negligible memory cost (one object per distinct style).
@immutable
class _TextPainterKey {
  final String text;
  final double fontSize;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final Color? color;
  final String? fontFamily;
  final double? lineHeight;
  final double? letterSpacing;
  final ui.TextDirection textDirection;

  const _TextPainterKey({
    required this.text,
    required this.fontSize,
    required this.fontWeight,
    required this.fontStyle,
    required this.color,
    required this.fontFamily,
    required this.lineHeight,
    required this.letterSpacing,
    required this.textDirection,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _TextPainterKey &&
        other.text == text &&
        other.fontSize == fontSize &&
        other.fontWeight == fontWeight &&
        other.fontStyle == fontStyle &&
        other.color == color &&
        other.fontFamily == fontFamily &&
        other.lineHeight == lineHeight &&
        other.letterSpacing == letterSpacing &&
        other.textDirection == textDirection;
  }

  @override
  int get hashCode => Object.hash(
        text,
        fontSize,
        fontWeight,
        fontStyle,
        color,
        fontFamily,
        lineHeight,
        letterSpacing,
        textDirection,
      );
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
