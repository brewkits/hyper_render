import 'dart:ui';

import '../model/node.dart';

/// Layout cache for storing computed layout information separately from the tree
///
/// This separation provides several benefits:
/// - Keeps the UDT immutable and focused on document structure
/// - Allows efficient layout invalidation without rebuilding the tree
/// - Reduces memory overhead when layout is not needed
/// - Enables multiple layout passes without mutating the tree
///
/// ## Usage
///
/// ```dart
/// final cache = LayoutCache();
///
/// // Store layout results
/// cache.setPosition(node, Rect.fromLTWH(0, 0, 100, 50));
/// cache.setSize(node, Size(100, 50));
///
/// // Retrieve layout
/// final position = cache.getPosition(node);
/// final size = cache.getSize(node);
///
/// // Clear when layout changes
/// cache.clear();
/// ```
///
/// ## Performance
///
/// - O(1) lookups and updates using node.id as key
/// - Efficient memory usage - only stores what's needed
/// - Fast invalidation with clear()
class LayoutCache {
  /// Cached positions indexed by node ID
  final Map<String, Rect> _positions = {};

  /// Cached sizes indexed by node ID
  final Map<String, Size> _sizes = {};

  /// Cached baselines indexed by node ID
  /// Baseline is the distance from top to the text baseline
  final Map<String, double> _baselines = {};

  /// Cached content bounds (excluding margins) indexed by node ID
  final Map<String, Rect> _contentBounds = {};

  /// Get the cached position for a node
  ///
  /// Returns null if no position has been cached for this node.
  Rect? getPosition(UDTNode node) => _positions[node.id];

  /// Set the position for a node
  ///
  /// The position is relative to the node's parent.
  void setPosition(UDTNode node, Rect rect) {
    _positions[node.id] = rect;
  }

  /// Get the cached size for a node
  ///
  /// Returns null if no size has been cached for this node.
  Size? getSize(UDTNode node) => _sizes[node.id];

  /// Set the size for a node
  void setSize(UDTNode node, Size size) {
    _sizes[node.id] = size;
  }

  /// Get the cached baseline for a node
  ///
  /// The baseline is the distance from the top of the node to its text baseline.
  /// Returns null if no baseline has been cached for this node.
  double? getBaseline(UDTNode node) => _baselines[node.id];

  /// Set the baseline for a node
  void setBaseline(UDTNode node, double baseline) {
    _baselines[node.id] = baseline;
  }

  /// Get the cached content bounds for a node
  ///
  /// Content bounds exclude margins but include padding and border.
  /// Returns null if no content bounds have been cached for this node.
  Rect? getContentBounds(UDTNode node) => _contentBounds[node.id];

  /// Set the content bounds for a node
  void setContentBounds(UDTNode node, Rect bounds) {
    _contentBounds[node.id] = bounds;
  }

  /// Check if a node has cached layout information
  bool hasLayout(UDTNode node) => _positions.containsKey(node.id);

  /// Check if a node has cached size
  bool hasSize(UDTNode node) => _sizes.containsKey(node.id);

  /// Remove cached layout for a specific node
  ///
  /// This is useful for partial layout invalidation.
  void invalidate(UDTNode node) {
    _positions.remove(node.id);
    _sizes.remove(node.id);
    _baselines.remove(node.id);
    _contentBounds.remove(node.id);
  }

  /// Remove cached layout for a node and all its descendants
  ///
  /// This is useful when a subtree needs to be re-laid out.
  void invalidateSubtree(UDTNode node) {
    invalidate(node);
    for (final child in node.children) {
      invalidateSubtree(child);
    }
  }

  /// Clear all cached layout information
  ///
  /// Call this when the entire layout needs to be recalculated,
  /// for example when the viewport size changes.
  void clear() {
    _positions.clear();
    _sizes.clear();
    _baselines.clear();
    _contentBounds.clear();
  }

  /// Get the total number of cached nodes
  int get cachedNodeCount => _positions.length;

  /// Get statistics about the cache
  LayoutCacheStats getStats() {
    return LayoutCacheStats(
      positionsCached: _positions.length,
      sizesCached: _sizes.length,
      baselinesCached: _baselines.length,
      contentBoundsCached: _contentBounds.length,
      totalMemoryBytes: _estimateMemoryUsage(),
    );
  }

  /// Estimate memory usage in bytes
  int _estimateMemoryUsage() {
    // Rough estimates:
    // - String key (node ID): ~50 bytes average
    // - Rect: 32 bytes (4 doubles)
    // - Size: 16 bytes (2 doubles)
    // - double: 8 bytes
    // - Map overhead: ~24 bytes per entry

    var bytes = 0;

    // Positions map
    bytes += _positions.length * (50 + 32 + 24);

    // Sizes map
    bytes += _sizes.length * (50 + 16 + 24);

    // Baselines map
    bytes += _baselines.length * (50 + 8 + 24);

    // Content bounds map
    bytes += _contentBounds.length * (50 + 32 + 24);

    return bytes;
  }

  /// Compact the cache by removing entries for nodes that no longer exist
  ///
  /// Pass the root of the current document tree to keep only valid entries.
  /// This is useful for cleaning up after nodes have been removed from the tree.
  void compact(UDTNode root) {
    final validIds = <String>{};

    void collectIds(UDTNode node) {
      validIds.add(node.id);
      for (final child in node.children) {
        collectIds(child);
      }
    }

    collectIds(root);

    // Remove entries for nodes that no longer exist
    _positions.removeWhere((id, _) => !validIds.contains(id));
    _sizes.removeWhere((id, _) => !validIds.contains(id));
    _baselines.removeWhere((id, _) => !validIds.contains(id));
    _contentBounds.removeWhere((id, _) => !validIds.contains(id));
  }

  /// Create a snapshot of the current cache
  ///
  /// Useful for debugging or comparing layout before/after changes.
  LayoutCacheSnapshot snapshot() {
    return LayoutCacheSnapshot(
      positions: Map.from(_positions),
      sizes: Map.from(_sizes),
      baselines: Map.from(_baselines),
      contentBounds: Map.from(_contentBounds),
    );
  }

  /// Restore from a snapshot
  ///
  /// This replaces the current cache with the snapshot's data.
  void restoreSnapshot(LayoutCacheSnapshot snapshot) {
    clear();
    _positions.addAll(snapshot.positions);
    _sizes.addAll(snapshot.sizes);
    _baselines.addAll(snapshot.baselines);
    _contentBounds.addAll(snapshot.contentBounds);
  }

  @override
  String toString() {
    final stats = getStats();
    return 'LayoutCache(${stats.positionsCached} nodes, '
        '${(stats.totalMemoryBytes / 1024).toStringAsFixed(1)}KB)';
  }
}

/// Statistics about layout cache usage
class LayoutCacheStats {
  final int positionsCached;
  final int sizesCached;
  final int baselinesCached;
  final int contentBoundsCached;
  final int totalMemoryBytes;

  LayoutCacheStats({
    required this.positionsCached,
    required this.sizesCached,
    required this.baselinesCached,
    required this.contentBoundsCached,
    required this.totalMemoryBytes,
  });

  double get memoryKb => totalMemoryBytes / 1024;
  double get memoryMb => totalMemoryBytes / (1024 * 1024);

  @override
  String toString() {
    return '''
Layout Cache Statistics:
  Positions cached: $positionsCached
  Sizes cached: $sizesCached
  Baselines cached: $baselinesCached
  Content bounds cached: $contentBoundsCached
  Memory usage: ${memoryKb.toStringAsFixed(1)}KB
''';
  }

  Map<String, dynamic> toJson() {
    return {
      'positionsCached': positionsCached,
      'sizesCached': sizesCached,
      'baselinesCached': baselinesCached,
      'contentBoundsCached': contentBoundsCached,
      'totalMemoryBytes': totalMemoryBytes,
      'memoryKb': memoryKb,
    };
  }
}

/// Immutable snapshot of layout cache state
class LayoutCacheSnapshot {
  final Map<String, Rect> positions;
  final Map<String, Size> sizes;
  final Map<String, double> baselines;
  final Map<String, Rect> contentBounds;

  LayoutCacheSnapshot({
    required this.positions,
    required this.sizes,
    required this.baselines,
    required this.contentBounds,
  });

  /// Compare two snapshots and return the differences
  LayoutCacheDiff diff(LayoutCacheSnapshot other) {
    final changedPositions = <String, LayoutChange<Rect>>{};
    final changedSizes = <String, LayoutChange<Size>>{};
    final changedBaselines = <String, LayoutChange<double>>{};

    // Check position changes
    for (final entry in positions.entries) {
      final oldValue = entry.value;
      final newValue = other.positions[entry.key];
      if (newValue != null && oldValue != newValue) {
        changedPositions[entry.key] = LayoutChange(oldValue, newValue);
      }
    }

    // Check size changes
    for (final entry in sizes.entries) {
      final oldValue = entry.value;
      final newValue = other.sizes[entry.key];
      if (newValue != null && oldValue != newValue) {
        changedSizes[entry.key] = LayoutChange(oldValue, newValue);
      }
    }

    // Check baseline changes
    for (final entry in baselines.entries) {
      final oldValue = entry.value;
      final newValue = other.baselines[entry.key];
      if (newValue != null && oldValue != newValue) {
        changedBaselines[entry.key] = LayoutChange(oldValue, newValue);
      }
    }

    return LayoutCacheDiff(
      changedPositions: changedPositions,
      changedSizes: changedSizes,
      changedBaselines: changedBaselines,
    );
  }
}

/// Difference between two layout cache snapshots
class LayoutCacheDiff {
  final Map<String, LayoutChange<Rect>> changedPositions;
  final Map<String, LayoutChange<Size>> changedSizes;
  final Map<String, LayoutChange<double>> changedBaselines;

  LayoutCacheDiff({
    required this.changedPositions,
    required this.changedSizes,
    required this.changedBaselines,
  });

  bool get hasChanges =>
      changedPositions.isNotEmpty ||
      changedSizes.isNotEmpty ||
      changedBaselines.isNotEmpty;

  int get totalChanges =>
      changedPositions.length + changedSizes.length + changedBaselines.length;

  @override
  String toString() {
    return 'LayoutCacheDiff($totalChanges changes: '
        '${changedPositions.length} positions, '
        '${changedSizes.length} sizes, '
        '${changedBaselines.length} baselines)';
  }
}

class LayoutChange<T> {
  final T oldValue;
  final T newValue;

  LayoutChange(this.oldValue, this.newValue);
}
