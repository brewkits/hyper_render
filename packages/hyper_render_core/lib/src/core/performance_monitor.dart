import 'dart:async';

/// Performance metrics for HyperRender operations
///
/// Tracks timing and resource usage for rendering pipeline:
/// - Parse time: Document parsing and UDT construction
/// - Style resolution: CSS matching and cascade
/// - Layout time: Size calculation and positioning
/// - Paint time: Widget tree construction
/// - Memory usage: Approximate memory footprint
class PerformanceReport {
  /// Time spent parsing content into UDT
  final Duration parseTime;

  /// Time spent resolving CSS styles
  final Duration styleTime;

  /// Time spent calculating layout
  final Duration layoutTime;

  /// Time spent painting/rendering
  final Duration paintTime;

  /// Total time from start to finish
  final Duration totalTime;

  /// Number of nodes in the document tree
  final int nodeCount;

  /// Number of CSS rules processed
  final int cssRuleCount;

  /// Number of CSS rules actually matched
  final int cssRulesMatched;

  /// Approximate memory usage in bytes
  final int memoryUsageBytes;

  /// Timestamp when measurement started
  final DateTime timestamp;

  /// Optional label for identifying the report
  final String? label;

  PerformanceReport({
    required this.parseTime,
    required this.styleTime,
    required this.layoutTime,
    required this.paintTime,
    required this.totalTime,
    required this.nodeCount,
    required this.cssRuleCount,
    required this.cssRulesMatched,
    required this.memoryUsageBytes,
    required this.timestamp,
    this.label,
  });

  /// Parse time in milliseconds
  int get parseTimeMs => parseTime.inMilliseconds;

  /// Style resolution time in milliseconds
  int get styleTimeMs => styleTime.inMilliseconds;

  /// Layout time in milliseconds
  int get layoutTimeMs => layoutTime.inMilliseconds;

  /// Paint time in milliseconds
  int get paintTimeMs => paintTime.inMilliseconds;

  /// Total time in milliseconds
  int get totalTimeMs => totalTime.inMilliseconds;

  /// Memory usage in kilobytes
  double get memoryUsageKb => memoryUsageBytes / 1024;

  /// Memory usage in megabytes
  double get memoryUsageMb => memoryUsageBytes / (1024 * 1024);

  /// CSS matching efficiency (percentage of rules actually matched)
  double get cssMatchingEfficiency =>
      cssRuleCount > 0 ? (cssRulesMatched / cssRuleCount) * 100 : 0;

  /// Check if performance is acceptable
  /// Returns true if total time is under 100ms
  bool get isAcceptable => totalTimeMs < 100;

  /// Check if performance is good
  /// Returns true if total time is under 50ms
  bool get isGood => totalTimeMs < 50;

  /// Check if performance is excellent
  /// Returns true if total time is under 16ms (60fps)
  bool get isExcellent => totalTimeMs < 16;

  /// Get performance rating (0-100)
  int get performanceScore {
    if (isExcellent) return 100;
    if (isGood) return 80;
    if (isAcceptable) return 60;
    if (totalTimeMs < 200) return 40;
    if (totalTimeMs < 500) return 20;
    return 0;
  }

  /// Get human-readable performance rating
  String get rating {
    if (isExcellent) return 'Excellent';
    if (isGood) return 'Good';
    if (isAcceptable) return 'Acceptable';
    if (totalTimeMs < 200) return 'Slow';
    return 'Poor';
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Performance Report${label != null ? " ($label)" : ""}:');
    buffer.writeln('  Total: ${totalTimeMs}ms [$rating]');
    buffer.writeln('  Parse: ${parseTimeMs}ms');
    buffer.writeln('  Style: ${styleTimeMs}ms');
    buffer.writeln('  Layout: ${layoutTimeMs}ms');
    buffer.writeln('  Paint: ${paintTimeMs}ms');
    buffer.writeln('  Nodes: $nodeCount');
    buffer.writeln('  CSS Rules: $cssRuleCount ($cssRulesMatched matched)');
    buffer.writeln('  Memory: ${memoryUsageKb.toStringAsFixed(1)}KB');
    return buffer.toString();
  }

  /// Convert to JSON map for logging/analytics
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'label': label,
      'totalTimeMs': totalTimeMs,
      'parseTimeMs': parseTimeMs,
      'styleTimeMs': styleTimeMs,
      'layoutTimeMs': layoutTimeMs,
      'paintTimeMs': paintTimeMs,
      'nodeCount': nodeCount,
      'cssRuleCount': cssRuleCount,
      'cssRulesMatched': cssRulesMatched,
      'memoryUsageBytes': memoryUsageBytes,
      'performanceScore': performanceScore,
      'rating': rating,
    };
  }
}

/// Performance monitor for tracking render pipeline timing
///
/// Usage:
/// ```dart
/// final monitor = PerformanceMonitor();
///
/// monitor.startPhase('parse');
/// // ... parse content ...
/// monitor.endPhase('parse');
///
/// monitor.startPhase('layout');
/// // ... calculate layout ...
/// monitor.endPhase('layout');
///
/// final report = monitor.buildReport(nodeCount: 100);
/// print(report);
/// ```
class PerformanceMonitor {
  final Map<String, Stopwatch> _stopwatches = {};
  final Map<String, Duration> _durations = {};
  final Stopwatch _totalStopwatch = Stopwatch();

  int _nodeCount = 0;
  int _cssRuleCount = 0;
  int _cssRulesMatched = 0;
  int _memoryUsageBytes = 0;
  DateTime? _startTimestamp;
  String? _label;

  /// Whether monitoring is enabled
  bool enabled;

  PerformanceMonitor({this.enabled = true});

  /// Start monitoring (called at beginning of render)
  void start({String? label}) {
    if (!enabled) return;

    _label = label;
    _startTimestamp = DateTime.now();
    _totalStopwatch.reset();
    _totalStopwatch.start();
    _stopwatches.clear();
    _durations.clear();
    _nodeCount = 0;
    _cssRuleCount = 0;
    _cssRulesMatched = 0;
    _memoryUsageBytes = 0;
  }

  /// Start a specific phase
  void startPhase(String phase) {
    if (!enabled) return;

    _stopwatches[phase] = Stopwatch()..start();
  }

  /// End a specific phase
  void endPhase(String phase) {
    if (!enabled) return;

    final stopwatch = _stopwatches[phase];
    if (stopwatch != null) {
      stopwatch.stop();
      _durations[phase] = stopwatch.elapsed;
    }
  }

  /// Measure a synchronous operation
  T measure<T>(String phase, T Function() operation) {
    if (!enabled) {
      return operation();
    }

    startPhase(phase);
    try {
      return operation();
    } finally {
      endPhase(phase);
    }
  }

  /// Measure an asynchronous operation
  Future<T> measureAsync<T>(String phase, Future<T> Function() operation) async {
    if (!enabled) {
      return await operation();
    }

    startPhase(phase);
    try {
      return await operation();
    } finally {
      endPhase(phase);
    }
  }

  /// Record node count
  void recordNodeCount(int count) {
    if (!enabled) return;
    _nodeCount = count;
  }

  /// Record CSS rule statistics
  void recordCssStats({required int ruleCount, required int rulesMatched}) {
    if (!enabled) return;
    _cssRuleCount = ruleCount;
    _cssRulesMatched = rulesMatched;
  }

  /// Estimate memory usage
  void recordMemoryUsage(int bytes) {
    if (!enabled) return;
    _memoryUsageBytes = bytes;
  }

  /// Build the final performance report
  PerformanceReport buildReport() {
    _totalStopwatch.stop();

    return PerformanceReport(
      parseTime: _durations['parse'] ?? Duration.zero,
      styleTime: _durations['style'] ?? Duration.zero,
      layoutTime: _durations['layout'] ?? Duration.zero,
      paintTime: _durations['paint'] ?? Duration.zero,
      totalTime: _totalStopwatch.elapsed,
      nodeCount: _nodeCount,
      cssRuleCount: _cssRuleCount,
      cssRulesMatched: _cssRulesMatched,
      memoryUsageBytes: _memoryUsageBytes,
      timestamp: _startTimestamp ?? DateTime.now(),
      label: _label,
    );
  }

  /// Reset the monitor for reuse
  void reset() {
    _stopwatches.clear();
    _durations.clear();
    _totalStopwatch.reset();
    _nodeCount = 0;
    _cssRuleCount = 0;
    _cssRulesMatched = 0;
    _memoryUsageBytes = 0;
    _startTimestamp = null;
    _label = null;
  }
}

/// Callback for performance reports
typedef PerformanceReportCallback = void Function(PerformanceReport report);

/// Performance statistics aggregator
///
/// Collects multiple reports and provides aggregate statistics
class PerformanceStats {
  final List<PerformanceReport> _reports = [];
  final int maxReports;

  PerformanceStats({this.maxReports = 100});

  /// Add a performance report
  void addReport(PerformanceReport report) {
    _reports.add(report);

    // Keep only the most recent reports
    while (_reports.length > maxReports) {
      _reports.removeAt(0);
    }
  }

  /// Get the number of reports collected
  int get reportCount => _reports.length;

  /// Get all reports
  List<PerformanceReport> get reports => List.unmodifiable(_reports);

  /// Get average total time in milliseconds
  double get averageTotalTimeMs {
    if (_reports.isEmpty) return 0;
    return _reports.map((r) => r.totalTimeMs).reduce((a, b) => a + b) / _reports.length;
  }

  /// Get average parse time in milliseconds
  double get averageParseTimeMs {
    if (_reports.isEmpty) return 0;
    return _reports.map((r) => r.parseTimeMs).reduce((a, b) => a + b) / _reports.length;
  }

  /// Get average style time in milliseconds
  double get averageStyleTimeMs {
    if (_reports.isEmpty) return 0;
    return _reports.map((r) => r.styleTimeMs).reduce((a, b) => a + b) / _reports.length;
  }

  /// Get average layout time in milliseconds
  double get averageLayoutTimeMs {
    if (_reports.isEmpty) return 0;
    return _reports.map((r) => r.layoutTimeMs).reduce((a, b) => a + b) / _reports.length;
  }

  /// Get average paint time in milliseconds
  double get averagePaintTimeMs {
    if (_reports.isEmpty) return 0;
    return _reports.map((r) => r.paintTimeMs).reduce((a, b) => a + b) / _reports.length;
  }

  /// Get average node count
  double get averageNodeCount {
    if (_reports.isEmpty) return 0;
    return _reports.map((r) => r.nodeCount).reduce((a, b) => a + b) / _reports.length;
  }

  /// Get average memory usage in KB
  double get averageMemoryKb {
    if (_reports.isEmpty) return 0;
    return _reports.map((r) => r.memoryUsageKb).reduce((a, b) => a + b) / _reports.length;
  }

  /// Get maximum total time
  int get maxTotalTimeMs {
    if (_reports.isEmpty) return 0;
    return _reports.map((r) => r.totalTimeMs).reduce((a, b) => a > b ? a : b);
  }

  /// Get minimum total time
  int get minTotalTimeMs {
    if (_reports.isEmpty) return 0;
    return _reports.map((r) => r.totalTimeMs).reduce((a, b) => a < b ? a : b);
  }

  /// Get 95th percentile total time
  int get p95TotalTimeMs {
    if (_reports.isEmpty) return 0;
    final sorted = _reports.map((r) => r.totalTimeMs).toList()..sort();
    final index = (sorted.length * 0.95).floor();
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  /// Get 99th percentile total time
  int get p99TotalTimeMs {
    if (_reports.isEmpty) return 0;
    final sorted = _reports.map((r) => r.totalTimeMs).toList()..sort();
    final index = (sorted.length * 0.99).floor();
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  /// Clear all reports
  void clear() {
    _reports.clear();
  }

  @override
  String toString() {
    if (_reports.isEmpty) {
      return 'Performance Stats: No data';
    }

    final buffer = StringBuffer();
    buffer.writeln('Performance Statistics ($reportCount reports):');
    buffer.writeln('  Average Total: ${averageTotalTimeMs.toStringAsFixed(1)}ms');
    buffer.writeln('  Min/Max: ${minTotalTimeMs}ms / ${maxTotalTimeMs}ms');
    buffer.writeln('  P95: ${p95TotalTimeMs}ms');
    buffer.writeln('  P99: ${p99TotalTimeMs}ms');
    buffer.writeln('  Avg Parse: ${averageParseTimeMs.toStringAsFixed(1)}ms');
    buffer.writeln('  Avg Style: ${averageStyleTimeMs.toStringAsFixed(1)}ms');
    buffer.writeln('  Avg Layout: ${averageLayoutTimeMs.toStringAsFixed(1)}ms');
    buffer.writeln('  Avg Paint: ${averagePaintTimeMs.toStringAsFixed(1)}ms');
    buffer.writeln('  Avg Nodes: ${averageNodeCount.toStringAsFixed(0)}');
    buffer.writeln('  Avg Memory: ${averageMemoryKb.toStringAsFixed(1)}KB');
    return buffer.toString();
  }

  /// Convert to JSON for analytics
  Map<String, dynamic> toJson() {
    return {
      'reportCount': reportCount,
      'averageTotalTimeMs': averageTotalTimeMs,
      'minTotalTimeMs': minTotalTimeMs,
      'maxTotalTimeMs': maxTotalTimeMs,
      'p95TotalTimeMs': p95TotalTimeMs,
      'p99TotalTimeMs': p99TotalTimeMs,
      'averageParseTimeMs': averageParseTimeMs,
      'averageStyleTimeMs': averageStyleTimeMs,
      'averageLayoutTimeMs': averageLayoutTimeMs,
      'averagePaintTimeMs': averagePaintTimeMs,
      'averageNodeCount': averageNodeCount,
      'averageMemoryKb': averageMemoryKb,
    };
  }
}
