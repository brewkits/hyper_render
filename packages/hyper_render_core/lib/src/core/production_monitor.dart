/// Production Monitoring System
///
/// Tracks layout engine usage, performance metrics, and fallback events
/// for production validation and edge case detection.
///
/// Week 3-4: Production Validation and Monitoring
library;

import 'package:flutter/foundation.dart';

/// Layout engine result type
enum LayoutEngineType {
  /// New refactored engines (LineBreakingEngine, FloatLayoutCalculator)
  newEngines,

  /// Legacy layout code (original God Object implementation)
  legacyFallback,
}

/// Result of a layout operation with metrics
class LayoutMetrics {
  /// Which engine was used
  final LayoutEngineType engineType;

  /// Layout computation time in microseconds
  final int layoutTimeUs;

  /// Number of fragments processed
  final int fragmentCount;

  /// Number of lines created
  final int lineCount;

  /// Max width used for layout
  final double maxWidth;

  /// Error message if fallback occurred
  final String? fallbackReason;

  /// Stack trace if fallback occurred
  final StackTrace? fallbackStackTrace;

  /// Timestamp when layout occurred
  final DateTime timestamp;

  LayoutMetrics({
    required this.engineType,
    required this.layoutTimeUs,
    required this.fragmentCount,
    required this.lineCount,
    required this.maxWidth,
    this.fallbackReason,
    this.fallbackStackTrace,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Whether this was a fallback to legacy code
  bool get wasFallback => engineType == LayoutEngineType.legacyFallback;

  /// Layout time in milliseconds
  double get layoutTimeMs => layoutTimeUs / 1000.0;

  @override
  String toString() {
    final engine = engineType == LayoutEngineType.newEngines ? 'NEW' : 'LEGACY';
    final buffer = StringBuffer();
    buffer.write('Layout[$engine]: ');
    buffer.write('${layoutTimeMs.toStringAsFixed(2)}ms, ');
    buffer.write('$fragmentCount fragments → $lineCount lines');

    if (wasFallback && fallbackReason != null) {
      buffer.write('\n  Fallback reason: $fallbackReason');
    }

    return buffer.toString();
  }
}

/// Callback for layout events
typedef LayoutEventCallback = void Function(LayoutMetrics metrics);

/// Production monitoring configuration
class ProductionMonitorConfig {
  /// Enable detailed logging
  final bool enableLogging;

  /// Enable performance tracking
  final bool enablePerformanceTracking;

  /// Enable fallback detection
  final bool enableFallbackDetection;

  /// Callback for all layout events
  final LayoutEventCallback? onLayoutEvent;

  /// Callback specifically for fallback events
  final LayoutEventCallback? onFallbackEvent;

  /// Maximum number of metrics to keep in memory
  final int maxHistorySize;

  const ProductionMonitorConfig({
    this.enableLogging = kDebugMode,
    this.enablePerformanceTracking = true,
    this.enableFallbackDetection = true,
    this.onLayoutEvent,
    this.onFallbackEvent,
    this.maxHistorySize = 1000,
  });

  /// Default production configuration
  static const ProductionMonitorConfig production = ProductionMonitorConfig(
    enableLogging: false,
    enablePerformanceTracking: true,
    enableFallbackDetection: true,
    maxHistorySize: 100,
  );

  /// Development configuration with verbose logging
  static const ProductionMonitorConfig development = ProductionMonitorConfig(
    enableLogging: true,
    enablePerformanceTracking: true,
    enableFallbackDetection: true,
    maxHistorySize: 1000,
  );

  /// Disabled monitoring (for testing)
  static const ProductionMonitorConfig disabled = ProductionMonitorConfig(
    enableLogging: false,
    enablePerformanceTracking: false,
    enableFallbackDetection: false,
    maxHistorySize: 0,
  );
}

/// Singleton production monitor for tracking layout engine performance
class ProductionMonitor {
  static ProductionMonitor? _instance;
  static ProductionMonitor get instance {
    _instance ??= ProductionMonitor._();
    return _instance!;
  }

  ProductionMonitor._();

  /// Current configuration
  ProductionMonitorConfig _config = kDebugMode
      ? ProductionMonitorConfig.development
      : ProductionMonitorConfig.production;

  /// History of layout metrics
  final List<LayoutMetrics> _history = [];

  /// Statistics aggregation
  int _totalLayouts = 0;
  int _newEngineLayouts = 0;
  int _legacyFallbacks = 0;
  int _totalLayoutTimeUs = 0;

  /// Configure the monitor
  void configure(ProductionMonitorConfig config) {
    _config = config;
  }

  /// Record a layout event
  void recordLayout(LayoutMetrics metrics) {
    if (!_config.enablePerformanceTracking) return;

    // Update statistics
    _totalLayouts++;
    _totalLayoutTimeUs += metrics.layoutTimeUs;

    if (metrics.engineType == LayoutEngineType.newEngines) {
      _newEngineLayouts++;
    } else {
      _legacyFallbacks++;

      // Call fallback callback if configured
      if (_config.enableFallbackDetection && _config.onFallbackEvent != null) {
        _config.onFallbackEvent!(metrics);
      }
    }

    // Add to history (limited size)
    if (_config.maxHistorySize > 0) {
      _history.add(metrics);
      while (_history.length > _config.maxHistorySize) {
        _history.removeAt(0);
      }
    }

    // Call general callback if configured
    _config.onLayoutEvent?.call(metrics);

    // Log if enabled
    if (_config.enableLogging) {
      debugPrint('📊 $metrics');

      // Extra logging for fallbacks
      if (metrics.wasFallback && metrics.fallbackStackTrace != null) {
        debugPrint('Stack trace:\n${metrics.fallbackStackTrace}');
      }
    }
  }

  /// Get current statistics
  ProductionStatistics getStatistics() {
    return ProductionStatistics(
      totalLayouts: _totalLayouts,
      newEngineLayouts: _newEngineLayouts,
      legacyFallbacks: _legacyFallbacks,
      averageLayoutTimeUs: _totalLayouts > 0 ? _totalLayoutTimeUs ~/ _totalLayouts : 0,
      newEngineSuccessRate:
          _totalLayouts > 0 ? _newEngineLayouts / _totalLayouts : 0.0,
      recentMetrics: List.unmodifiable(_history),
    );
  }

  /// Reset all statistics (useful for testing)
  void reset() {
    _history.clear();
    _totalLayouts = 0;
    _newEngineLayouts = 0;
    _legacyFallbacks = 0;
    _totalLayoutTimeUs = 0;
  }

  /// Print summary of statistics
  void printSummary() {
    final stats = getStatistics();
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('HyperRender Production Monitoring Summary');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('Total layouts: ${stats.totalLayouts}');
    debugPrint('New engines: ${stats.newEngineLayouts} (${(stats.newEngineSuccessRate * 100).toStringAsFixed(1)}%)');
    debugPrint('Legacy fallbacks: ${stats.legacyFallbacks} (${((1 - stats.newEngineSuccessRate) * 100).toStringAsFixed(1)}%)');
    debugPrint('Average layout time: ${(stats.averageLayoutTimeUs / 1000).toStringAsFixed(2)}ms');
    debugPrint('═══════════════════════════════════════════════');

    if (stats.legacyFallbacks > 0) {
      debugPrint('\n⚠️  Fallback events detected:');
      for (final metric in stats.recentMetrics) {
        if (metric.wasFallback) {
          debugPrint('  - ${metric.timestamp}: ${metric.fallbackReason}');
        }
      }
    }
  }
}

/// Statistics snapshot
class ProductionStatistics {
  /// Total number of layouts performed
  final int totalLayouts;

  /// Number of layouts using new engines
  final int newEngineLayouts;

  /// Number of fallbacks to legacy code
  final int legacyFallbacks;

  /// Average layout time in microseconds
  final int averageLayoutTimeUs;

  /// Success rate of new engines (0.0 to 1.0)
  final double newEngineSuccessRate;

  /// Recent layout metrics
  final List<LayoutMetrics> recentMetrics;

  const ProductionStatistics({
    required this.totalLayouts,
    required this.newEngineLayouts,
    required this.legacyFallbacks,
    required this.averageLayoutTimeUs,
    required this.newEngineSuccessRate,
    required this.recentMetrics,
  });

  /// Average layout time in milliseconds
  double get averageLayoutTimeMs => averageLayoutTimeUs / 1000.0;

  /// Whether any fallbacks have occurred
  bool get hasFallbacks => legacyFallbacks > 0;

  /// Fallback rate (0.0 to 1.0)
  double get fallbackRate => 1.0 - newEngineSuccessRate;
}

/// Helper for timing layout operations
class LayoutTimer {
  final Stopwatch _stopwatch = Stopwatch();

  /// Start timing
  void start() {
    _stopwatch.reset();
    _stopwatch.start();
  }

  /// Stop timing and return elapsed microseconds
  int stop() {
    _stopwatch.stop();
    return _stopwatch.elapsedMicroseconds;
  }

  /// Get elapsed microseconds without stopping
  int get elapsedUs => _stopwatch.elapsedMicroseconds;
}
