/// Edge Case Detection System
///
/// Week 3-4: Detect and analyze patterns in layout engine fallbacks
///
/// This system helps identify:
/// - Common edge cases that trigger fallbacks
/// - Content patterns that cause issues
/// - Root causes of fallback events
///
/// Use this during production validation to improve the new layout engines.
library;

import 'package:flutter/foundation.dart';
import 'production_monitor.dart';

/// Category of edge case
enum EdgeCaseCategory {
  /// Complex float layouts
  floatLayout,

  /// Deep nesting
  deepNesting,

  /// CJK/Kinsoku text handling
  cjkText,

  /// Very long lines
  longLines,

  /// Mixed RTL/LTR content
  bidiText,

  /// Large documents
  largeDocument,

  /// Complex tables
  complexTable,

  /// Ruby text
  rubyText,

  /// Unknown/other
  unknown,
}

/// Detected edge case with analysis
class EdgeCase {
  /// When the edge case was detected
  final DateTime timestamp;

  /// Category of edge case
  final EdgeCaseCategory category;

  /// Error message that triggered fallback
  final String errorMessage;

  /// Stack trace if available
  final StackTrace? stackTrace;

  /// Number of fragments being processed
  final int fragmentCount;

  /// Layout time before failure (microseconds)
  final int layoutTimeUs;

  /// Confidence level (0.0-1.0) that category is correct
  final double confidence;

  /// Additional context
  final Map<String, dynamic> context;

  EdgeCase({
    DateTime? timestamp,
    required this.category,
    required this.errorMessage,
    this.stackTrace,
    required this.fragmentCount,
    required this.layoutTimeUs,
    this.confidence = 0.5,
    this.context = const {},
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return '[${category.name}] $errorMessage (${layoutTimeUs ~/ 1000}ms, $fragmentCount fragments)';
  }
}

/// Edge case detection and analysis
class EdgeCaseDetector {
  static EdgeCaseDetector? _instance;
  static EdgeCaseDetector get instance {
    _instance ??= EdgeCaseDetector._();
    return _instance!;
  }

  EdgeCaseDetector._();

  /// History of detected edge cases
  final List<EdgeCase> _edgeCases = [];

  /// Maximum number of edge cases to keep in memory
  int maxHistorySize = 100;

  /// Analyze a fallback event and detect edge case
  EdgeCase detectFromFallback(LayoutMetrics metrics) {
    if (!metrics.wasFallback) {
      throw ArgumentError('Metrics must be from a fallback event');
    }

    final errorMessage = metrics.fallbackReason ?? 'Unknown error';
    final category = _categorizeError(errorMessage, metrics);
    final confidence = _calculateConfidence(errorMessage, category);
    final context = _extractContext(metrics);

    final edgeCase = EdgeCase(
      category: category,
      errorMessage: errorMessage,
      stackTrace: metrics.fallbackStackTrace,
      fragmentCount: metrics.fragmentCount,
      layoutTimeUs: metrics.layoutTimeUs,
      confidence: confidence,
      context: context,
    );

    // Add to history
    _edgeCases.add(edgeCase);
    while (_edgeCases.length > maxHistorySize) {
      _edgeCases.removeAt(0);
    }

    return edgeCase;
  }

  /// Categorize error based on error message and metrics
  EdgeCaseCategory _categorizeError(String errorMessage, LayoutMetrics metrics) {
    final lowerError = errorMessage.toLowerCase();

    // Float layout issues
    if (lowerError.contains('float') ||
        lowerError.contains('floatarea') ||
        lowerError.contains('left float') ||
        lowerError.contains('right float')) {
      return EdgeCaseCategory.floatLayout;
    }

    // CJK/Kinsoku issues
    if (lowerError.contains('kinsoku') ||
        lowerError.contains('cjk') ||
        lowerError.contains('line break') ||
        lowerError.contains('word boundary')) {
      return EdgeCaseCategory.cjkText;
    }

    // Nesting issues
    if (lowerError.contains('stack') ||
        lowerError.contains('depth') ||
        lowerError.contains('recursion') ||
        lowerError.contains('nested')) {
      return EdgeCaseCategory.deepNesting;
    }

    // Index/range errors often indicate edge cases
    if (lowerError.contains('index') ||
        lowerError.contains('range') ||
        lowerError.contains('bounds')) {
      // High fragment count might indicate large document
      if (metrics.fragmentCount > 1000) {
        return EdgeCaseCategory.largeDocument;
      }
      return EdgeCaseCategory.unknown;
    }

    // Table issues
    if (lowerError.contains('table') ||
        lowerError.contains('cell') ||
        lowerError.contains('row') ||
        lowerError.contains('column')) {
      return EdgeCaseCategory.complexTable;
    }

    // Ruby text
    if (lowerError.contains('ruby')) {
      return EdgeCaseCategory.rubyText;
    }

    // RTL/BiDi
    if (lowerError.contains('rtl') ||
        lowerError.contains('ltr') ||
        lowerError.contains('bidi') ||
        lowerError.contains('direction')) {
      return EdgeCaseCategory.bidiText;
    }

    // Default to unknown
    return EdgeCaseCategory.unknown;
  }

  /// Calculate confidence level for categorization
  double _calculateConfidence(String errorMessage, EdgeCaseCategory category) {
    final lowerError = errorMessage.toLowerCase();

    // High confidence if error message explicitly mentions the category
    final highConfidenceKeywords = {
      EdgeCaseCategory.floatLayout: ['float', 'floatarea'],
      EdgeCaseCategory.cjkText: ['kinsoku', 'cjk'],
      EdgeCaseCategory.deepNesting: ['recursion', 'stack overflow'],
      EdgeCaseCategory.complexTable: ['table'],
      EdgeCaseCategory.rubyText: ['ruby'],
      EdgeCaseCategory.bidiText: ['rtl', 'ltr', 'bidi'],
    };

    final keywords = highConfidenceKeywords[category] ?? [];
    if (keywords.any((keyword) => lowerError.contains(keyword))) {
      return 0.9;
    }

    // Medium confidence for pattern matching
    if (category != EdgeCaseCategory.unknown) {
      return 0.6;
    }

    // Low confidence for unknown
    return 0.3;
  }

  /// Extract context from metrics
  Map<String, dynamic> _extractContext(LayoutMetrics metrics) {
    return {
      'fragmentCount': metrics.fragmentCount,
      'lineCount': metrics.lineCount,
      'maxWidth': metrics.maxWidth,
      'layoutTimeUs': metrics.layoutTimeUs,
    };
  }

  /// Get statistics about edge cases
  EdgeCaseStatistics getStatistics() {
    final categoryCounts = <EdgeCaseCategory, int>{};
    int totalCases = _edgeCases.length;

    for (final edgeCase in _edgeCases) {
      categoryCounts[edgeCase.category] =
          (categoryCounts[edgeCase.category] ?? 0) + 1;
    }

    return EdgeCaseStatistics(
      totalCases: totalCases,
      categoryCounts: categoryCounts,
      recentCases: List.unmodifiable(_edgeCases),
    );
  }

  /// Print summary of edge cases
  void printSummary() {
    final stats = getStatistics();

    debugPrint('\n═══════════════════════════════════════════════');
    debugPrint('Edge Case Detection Summary');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('Total Edge Cases: ${stats.totalCases}');
    debugPrint('═══════════════════════════════════════════════');

    if (stats.totalCases == 0) {
      debugPrint('✅ No edge cases detected!');
      debugPrint('═══════════════════════════════════════════════\n');
      return;
    }

    debugPrint('\nBy Category:');
    final sortedCategories = stats.categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCategories) {
      final percentage = (entry.value / stats.totalCases * 100).toStringAsFixed(1);
      debugPrint('  ${entry.key.name}: ${entry.value} ($percentage%)');
    }

    debugPrint('\nRecent Cases:');
    final recentCases = stats.recentCases.take(5).toList();
    for (final edgeCase in recentCases) {
      debugPrint('  - $edgeCase');
    }

    if (stats.recentCases.length > 5) {
      debugPrint('  ... and ${stats.recentCases.length - 5} more');
    }

    debugPrint('═══════════════════════════════════════════════');

    // Recommendations
    if (stats.categoryCounts.isNotEmpty) {
      debugPrint('\n💡 Top Issues to Address:');
      final topCategories = sortedCategories.take(3);
      for (final entry in topCategories) {
        final recommendation = _getRecommendation(entry.key);
        debugPrint('  • ${entry.key.name}: $recommendation');
      }
    }

    debugPrint('═══════════════════════════════════════════════\n');
  }

  /// Get recommendation for a category
  String _getRecommendation(EdgeCaseCategory category) {
    switch (category) {
      case EdgeCaseCategory.floatLayout:
        return 'Review float layout calculator logic';
      case EdgeCaseCategory.cjkText:
        return 'Verify Kinsoku rules and CJK text handling';
      case EdgeCaseCategory.deepNesting:
        return 'Check for infinite recursion or stack overflow';
      case EdgeCaseCategory.longLines:
        return 'Test with very long unbreakable strings';
      case EdgeCaseCategory.bidiText:
        return 'Verify RTL/LTR text direction handling';
      case EdgeCaseCategory.largeDocument:
        return 'Test with documents > 1000 fragments';
      case EdgeCaseCategory.complexTable:
        return 'Review table layout algorithm';
      case EdgeCaseCategory.rubyText:
        return 'Verify ruby text rendering logic';
      case EdgeCaseCategory.unknown:
        return 'Investigate error messages for patterns';
    }
  }

  /// Reset edge case history
  void reset() {
    _edgeCases.clear();
  }
}

/// Edge case statistics
class EdgeCaseStatistics {
  /// Total number of edge cases detected
  final int totalCases;

  /// Count of cases by category
  final Map<EdgeCaseCategory, int> categoryCounts;

  /// Recent edge cases
  final List<EdgeCase> recentCases;

  EdgeCaseStatistics({
    required this.totalCases,
    required this.categoryCounts,
    required this.recentCases,
  });

  /// Most common edge case category
  EdgeCaseCategory? get mostCommonCategory {
    if (categoryCounts.isEmpty) return null;

    return categoryCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Percentage of edge cases in a category
  double percentageFor(EdgeCaseCategory category) {
    if (totalCases == 0) return 0.0;
    final count = categoryCounts[category] ?? 0;
    return count / totalCases * 100;
  }
}

/// Integration helper to automatically detect edge cases from production monitor
class EdgeCaseMonitoringIntegration {
  /// Set up automatic edge case detection from production monitor
  static void setup() {
    ProductionMonitor.instance.configure(
      ProductionMonitorConfig(
        enableFallbackDetection: true,
        onFallbackEvent: (metrics) {
          // Detect and categorize edge case
          final edgeCase = EdgeCaseDetector.instance.detectFromFallback(metrics);

          // Log the edge case
          debugPrint('📍 Edge Case Detected: $edgeCase');

          // If high confidence, log additional details
          if (edgeCase.confidence > 0.7) {
            debugPrint('   Confidence: ${(edgeCase.confidence * 100).toStringAsFixed(0)}%');
            debugPrint('   Category: ${edgeCase.category.name}');
          }
        },
      ),
    );
  }

  /// Print comprehensive report combining production stats and edge cases
  static void printComprehensiveReport() {
    debugPrint('\n');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('COMPREHENSIVE PRODUCTION REPORT');
    debugPrint('═══════════════════════════════════════════════\n');

    // Production monitoring summary
    ProductionMonitor.instance.printSummary();

    debugPrint('');

    // Edge case summary
    EdgeCaseDetector.instance.printSummary();
  }
}
