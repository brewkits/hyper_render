/// Table Layout Performance Fix
///
/// CRITICAL ISSUE: Intrinsic Sizing Performance Problem
///
/// Problem identified by Senior Dev review:
/// - Current table layout uses getMinIntrinsicWidth / getMaxIntrinsicWidth
/// - 2-pass algorithm calls intrinsic methods for EVERY cell
/// - Nested tables cause recursive intrinsic calls → O(N²) or O(N³)
/// - Blocks main thread → Jank and frame drops
///
/// Flutter's layout philosophy: "Constraints go down, sizes go up" - ONE PASS
/// Intrinsic measurements violate this principle and are EXTREMELY EXPENSIVE.
///
/// This file contains immediate fixes for Week 3-4:
/// 1. Hard limit on nested table depth
/// 2. Performance warnings for large tables
/// 3. Intrinsic measurement caching
/// 4. Documentation of limitations
///
/// TODO (v1.1.0 - Week 5-6): Implement 1-pass table layout algorithm
/// - No intrinsic calls
/// - SubcomposeLayout-like approach
/// - Actual measurements in layout pass
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Maximum allowed nested table depth
///
/// Prevents exponential complexity from recursive intrinsic calls.
/// Example:
/// - Depth 1: Table with cells
/// - Depth 2: Table with cells containing tables
/// - Depth 3: Table with cells containing tables with cells containing tables
/// - Depth 4+: BLOCKED - would cause O(N³) or worse
const int maxTableNestingDepth = 3;

/// Maximum table cells before performance warning
///
/// Tables with more cells may experience layout jank due to intrinsic calls.
const int maxTableCellsWarning = 100;

/// Maximum table cells before critical warning
///
/// Tables with this many cells will likely cause significant jank.
const int maxTableCellsCritical = 500;

/// Table performance configuration
class TablePerformanceConfig {
  /// Whether to enforce max nesting depth
  final bool enforceMaxNestingDepth;

  /// Whether to show performance warnings
  final bool showPerformanceWarnings;

  /// Whether to cache intrinsic measurements
  final bool cacheIntrinsicMeasurements;

  /// Maximum nesting depth
  final int maxNestingDepth;

  const TablePerformanceConfig({
    this.enforceMaxNestingDepth = true,
    this.showPerformanceWarnings = kDebugMode,
    this.cacheIntrinsicMeasurements = true,
    this.maxNestingDepth = maxTableNestingDepth,
  });

  /// Production configuration (enforces limits, no warnings)
  static const TablePerformanceConfig production = TablePerformanceConfig(
    enforceMaxNestingDepth: true,
    showPerformanceWarnings: false,
    cacheIntrinsicMeasurements: true,
  );

  /// Development configuration (enforces limits, shows warnings)
  static const TablePerformanceConfig development = TablePerformanceConfig(
    enforceMaxNestingDepth: true,
    showPerformanceWarnings: true,
    cacheIntrinsicMeasurements: true,
  );

  /// Disabled (no enforcement - DANGEROUS for production)
  static const TablePerformanceConfig disabled = TablePerformanceConfig(
    enforceMaxNestingDepth: false,
    showPerformanceWarnings: false,
    cacheIntrinsicMeasurements: false,
  );
}

/// Table nesting depth tracker
class TableNestingTracker {
  static final Map<Object, int> _nestingDepth = {};

  /// Get current nesting depth for a table
  static int getDepth(Object tableKey) {
    return _nestingDepth[tableKey] ?? 0;
  }

  /// Set nesting depth for a table
  static void setDepth(Object tableKey, int depth) {
    _nestingDepth[tableKey] = depth;
  }

  /// Increment nesting depth (when entering nested table)
  static int incrementDepth(Object parentKey) {
    final parentDepth = getDepth(parentKey);
    return parentDepth + 1;
  }

  /// Clear all tracking (useful for testing)
  static void clear() {
    _nestingDepth.clear();
  }
}

/// Intrinsic measurement cache to avoid redundant calculations
///
/// CRITICAL: This is a band-aid fix. The real solution is to eliminate
/// intrinsic measurements entirely with a 1-pass layout algorithm.
class IntrinsicMeasurementCache {
  static final Map<RenderBox, _CachedIntrinsics> _cache = {};

  /// Get or calculate min intrinsic width
  static double getMinIntrinsicWidth(RenderBox child, double height) {
    final cached = _cache[child];
    if (cached != null && cached.minWidthHeight == height) {
      return cached.minWidth;
    }

    // Cache miss - calculate and store
    final minWidth = child.getMinIntrinsicWidth(height);
    _cache[child] = _CachedIntrinsics(
      minWidth: minWidth,
      minWidthHeight: height,
      maxWidth: cached?.maxWidth ?? 0,
      maxWidthHeight: cached?.maxWidthHeight ?? 0,
    );

    return minWidth;
  }

  /// Get or calculate max intrinsic width
  static double getMaxIntrinsicWidth(RenderBox child, double height) {
    final cached = _cache[child];
    if (cached != null && cached.maxWidthHeight == height) {
      return cached.maxWidth;
    }

    // Cache miss - calculate and store
    final maxWidth = child.getMaxIntrinsicWidth(height);
    _cache[child] = _CachedIntrinsics(
      minWidth: cached?.minWidth ?? 0,
      minWidthHeight: cached?.minWidthHeight ?? 0,
      maxWidth: maxWidth,
      maxWidthHeight: height,
    );

    return maxWidth;
  }

  /// Clear cache (call when child layout changes)
  static void invalidate(RenderBox child) {
    _cache.remove(child);
  }

  /// Clear all cache
  static void clearAll() {
    _cache.clear();
  }

  /// Get cache size (for monitoring)
  static int get cacheSize => _cache.length;
}

/// Cached intrinsic measurements
class _CachedIntrinsics {
  final double minWidth;
  final double minWidthHeight;
  final double maxWidth;
  final double maxWidthHeight;

  _CachedIntrinsics({
    required this.minWidth,
    required this.minWidthHeight,
    required this.maxWidth,
    required this.maxWidthHeight,
  });
}

/// Table performance analyzer
class TablePerformanceAnalyzer {
  /// Analyze table and warn about performance issues
  static void analyzeTable({
    required int rowCount,
    required int columnCount,
    required int nestingDepth,
    required TablePerformanceConfig config,
  }) {
    if (!config.showPerformanceWarnings) return;

    final totalCells = rowCount * columnCount;

    // Check nesting depth
    if (nestingDepth > config.maxNestingDepth) {
      debugPrint('');
      debugPrint('🔴 TABLE PERFORMANCE CRITICAL:');
      debugPrint('   Nesting depth: $nestingDepth (max: ${config.maxNestingDepth})');
      debugPrint('   This will cause O(N³) complexity from recursive intrinsic calls!');
      debugPrint('   Solution: Flatten table structure or use alternative layout.');
      debugPrint('');
    }

    // Check cell count
    if (totalCells > maxTableCellsCritical) {
      debugPrint('');
      debugPrint('🔴 TABLE PERFORMANCE CRITICAL:');
      debugPrint('   Total cells: $totalCells (critical threshold: $maxTableCellsCritical)');
      debugPrint('   Intrinsic measurements will block main thread!');
      debugPrint('   Expected jank: ${_estimateJankMs(totalCells)}ms per layout');
      debugPrint('   Solution: Paginate table or use server-side rendering.');
      debugPrint('');
    } else if (totalCells > maxTableCellsWarning) {
      debugPrint('');
      debugPrint('⚠️  TABLE PERFORMANCE WARNING:');
      debugPrint('   Total cells: $totalCells (warning threshold: $maxTableCellsWarning)');
      debugPrint('   May experience layout jank on low-end devices.');
      debugPrint('   Expected jank: ${_estimateJankMs(totalCells)}ms per layout');
      debugPrint('');
    }

    // Educational message about intrinsic sizing
    if (totalCells > maxTableCellsWarning || nestingDepth > 1) {
      debugPrint('💡 WHY THIS IS SLOW:');
      debugPrint('   Current algorithm calls getMaxIntrinsicWidth() for each cell.');
      debugPrint('   With $totalCells cells, that\'s $totalCells intrinsic measurements per layout!');
      debugPrint('   Nested tables multiply this: Depth $nestingDepth = ${totalCells * nestingDepth}+ measurements.');
      debugPrint('   Flutter\'s "one-pass" layout philosophy is violated by intrinsic calls.');
      debugPrint('');
      debugPrint('🔧 FUTURE FIX (v1.1.0):');
      debugPrint('   Implement 1-pass table layout algorithm (no intrinsic calls).');
      debugPrint('   Use SubcomposeLayout-like approach for on-demand measurements.');
      debugPrint('   See: lib/src/core/table_layout_performance_fix.dart');
      debugPrint('');
    }
  }

  /// Estimate jank in milliseconds based on cell count
  ///
  /// Very rough estimate based on:
  /// - Each intrinsic call: ~0.1-0.5ms (depending on cell complexity)
  /// - 2-pass algorithm: 2x measurements
  /// - Overhead: Additional 20%
  static int _estimateJankMs(int totalCells) {
    const avgIntrinsicCallMs = 0.3; // ms per intrinsic call
    const passFactor = 2; // 2-pass algorithm
    const overheadFactor = 1.2; // 20% overhead

    final estimate = totalCells * avgIntrinsicCallMs * passFactor * overheadFactor;
    return estimate.round();
  }
}

/// Table layout complexity metrics
class TableLayoutMetrics {
  /// Number of rows
  final int rowCount;

  /// Number of columns
  final int columnCount;

  /// Total cells
  int get totalCells => rowCount * columnCount;

  /// Nesting depth
  final int nestingDepth;

  /// Number of intrinsic calls
  ///
  /// In 2-pass algorithm:
  /// - Pass 1: All cells (non-spanning)
  /// - Pass 2: Spanning cells
  /// Worst case: 2x total cells
  int get intrinsicCallCount => totalCells * 2;

  /// Complexity factor (1 = O(N), 2 = O(N²), 3 = O(N³))
  int get complexityFactor => 1 + nestingDepth;

  /// Estimated time complexity
  String get timeComplexity {
    if (complexityFactor == 1) return 'O(N)';
    if (complexityFactor == 2) return 'O(N²)';
    if (complexityFactor == 3) return 'O(N³)';
    return 'O(N^$complexityFactor)';
  }

  TableLayoutMetrics({
    required this.rowCount,
    required this.columnCount,
    required this.nestingDepth,
  });

  @override
  String toString() {
    return 'TableLayoutMetrics('
        'rows: $rowCount, '
        'cols: $columnCount, '
        'cells: $totalCells, '
        'depth: $nestingDepth, '
        'complexity: $timeComplexity)';
  }
}

/// Exception thrown when table nesting depth is exceeded
class TableNestingDepthExceededException implements Exception {
  final int currentDepth;
  final int maxDepth;

  TableNestingDepthExceededException(this.currentDepth, this.maxDepth);

  @override
  String toString() {
    return 'TableNestingDepthExceededException: '
        'Table nesting depth $currentDepth exceeds maximum $maxDepth. '
        'Nested tables cause O(N³) complexity from recursive intrinsic calls. '
        'Solution: Flatten table structure or increase maxNestingDepth in TablePerformanceConfig.';
  }
}
