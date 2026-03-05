/// Production Diagnostic Tools
///
/// Week 3-4: Tools for diagnosing performance issues and validating production readiness
///
/// This module combines:
/// - Performance warnings (from performance_warnings.dart)
/// - Production monitoring (from production_monitor.dart)
/// - Layout engine metrics
///
/// Use this to validate your app before production deployment.
library;

import 'package:flutter/foundation.dart';
import 'production_monitor.dart';
import 'performance_warnings.dart';

/// Complete diagnostic report combining all analysis
class ProductionDiagnosticReport {
  /// Performance warnings from HTML analysis
  final PerformanceAnalysisResult performanceAnalysis;

  /// Production monitoring statistics
  final ProductionStatistics productionStats;

  /// Overall health score (0-100)
  final int healthScore;

  /// Critical issues that must be fixed
  final List<String> criticalIssues;

  /// Warnings that should be addressed
  final List<String> warnings;

  /// Recommendations for improvement
  final List<String> recommendations;

  ProductionDiagnosticReport({
    required this.performanceAnalysis,
    required this.productionStats,
    required this.healthScore,
    required this.criticalIssues,
    required this.warnings,
    required this.recommendations,
  });

  /// Whether the app is ready for production
  bool get isProductionReady => criticalIssues.isEmpty && healthScore >= 80;

  /// Whether there are concerning issues
  bool get hasConcerns => warnings.isNotEmpty || healthScore < 90;
}

/// Production diagnostic tool
class ProductionDiagnostic {
  /// Analyze HTML content and production metrics to generate a comprehensive report
  static ProductionDiagnosticReport analyze(String html) {
    // Get performance warnings
    final performanceAnalysis = PerformanceAnalyzer.analyze(html);

    // Get production monitoring stats
    final productionStats = ProductionMonitor.instance.getStatistics();

    // Analyze issues
    final criticalIssues = <String>[];
    final warnings = <String>[];
    final recommendations = <String>[];

    // Check performance warnings
    for (final warning in performanceAnalysis.warnings) {
      if (warning.severity == PerformanceWarningSeverity.critical) {
        criticalIssues.add('[Performance] ${warning.message}');
      } else if (warning.severity == PerformanceWarningSeverity.warning) {
        warnings.add('[Performance] ${warning.message}');
      }
    }

    // Check production monitoring stats
    if (productionStats.totalLayouts > 0) {
      // High fallback rate is concerning
      if (productionStats.fallbackRate > 0.05) {
        // >5%
        criticalIssues.add(
          '[Layout Engine] High fallback rate: ${(productionStats.fallbackRate * 100).toStringAsFixed(1)}% (target: <1%)',
        );
      } else if (productionStats.fallbackRate > 0.01) {
        // >1%
        warnings.add(
          '[Layout Engine] Elevated fallback rate: ${(productionStats.fallbackRate * 100).toStringAsFixed(1)}% (target: <0.1%)',
        );
      }

      // Slow average layout time
      if (productionStats.averageLayoutTimeMs > 100) {
        criticalIssues.add(
          '[Performance] Very slow layout: ${productionStats.averageLayoutTimeMs.toStringAsFixed(1)}ms average (target: <50ms)',
        );
      } else if (productionStats.averageLayoutTimeMs > 50) {
        warnings.add(
          '[Performance] Slow layout: ${productionStats.averageLayoutTimeMs.toStringAsFixed(1)}ms average (target: <20ms)',
        );
      }

      // Any fallbacks should be reported
      if (productionStats.hasFallbacks) {
        recommendations.add(
          'Review ${productionStats.legacyFallbacks} fallback event(s) - may indicate edge cases',
        );
      }
    }

    // Generate recommendations based on analysis
    if (performanceAnalysis.warnings.isNotEmpty) {
      final docSizeWarnings = performanceAnalysis.warnings
          .where((w) => w.category == 'document_size');
      if (docSizeWarnings.isNotEmpty) {
        recommendations.add(
          'Consider pagination or lazy loading for large documents',
        );
      }

      final imageWarnings = performanceAnalysis.warnings
          .where((w) => w.category == 'image_count');
      if (imageWarnings.isNotEmpty) {
        recommendations.add(
          'Implement image lazy loading with cacheWidth/cacheHeight',
        );
      }

      final tableWarnings = performanceAnalysis.warnings
          .where((w) => w.category == 'table_complexity');
      if (tableWarnings.isNotEmpty) {
        recommendations.add(
          'Split large tables into smaller chunks or use pagination',
        );
      }
    }

    if (productionStats.averageLayoutTimeMs > 20 &&
        productionStats.averageLayoutTimeMs < 50) {
      recommendations.add(
        'Layout performance is acceptable but could be optimized for better UX',
      );
    }

    // Calculate health score
    int healthScore = 100;

    // Deduct points for critical issues
    healthScore -= criticalIssues.length * 20;

    // Deduct points for warnings
    healthScore -= warnings.length * 5;

    // Deduct points for high fallback rate
    if (productionStats.totalLayouts > 0) {
      healthScore -= (productionStats.fallbackRate * 100).round();
    }

    // Deduct points for slow layout
    if (productionStats.averageLayoutTimeMs > 50) {
      healthScore -= 10;
    } else if (productionStats.averageLayoutTimeMs > 20) {
      healthScore -= 5;
    }

    // Ensure score is in valid range
    healthScore = healthScore.clamp(0, 100);

    return ProductionDiagnosticReport(
      performanceAnalysis: performanceAnalysis,
      productionStats: productionStats,
      healthScore: healthScore,
      criticalIssues: criticalIssues,
      warnings: warnings,
      recommendations: recommendations,
    );
  }

  /// Print a comprehensive diagnostic report
  static void printReport(ProductionDiagnosticReport report) {
    debugPrint('\n');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('HyperRender Production Diagnostic Report');
    debugPrint('═══════════════════════════════════════════════');

    // Health Score
    final scoreIcon = report.healthScore >= 90
        ? '✅'
        : report.healthScore >= 70
            ? '⚠️'
            : '❌';
    debugPrint('$scoreIcon Health Score: ${report.healthScore}/100');

    // Production Readiness
    if (report.isProductionReady) {
      debugPrint('✅ Production Ready: YES');
    } else {
      debugPrint('❌ Production Ready: NO');
    }

    debugPrint('═══════════════════════════════════════════════');

    // Critical Issues
    if (report.criticalIssues.isNotEmpty) {
      debugPrint('\n🔴 CRITICAL ISSUES (Must Fix):');
      for (final issue in report.criticalIssues) {
        debugPrint('  • $issue');
      }
    }

    // Warnings
    if (report.warnings.isNotEmpty) {
      debugPrint('\n⚠️  WARNINGS (Should Fix):');
      for (final warning in report.warnings) {
        debugPrint('  • $warning');
      }
    }

    // Recommendations
    if (report.recommendations.isNotEmpty) {
      debugPrint('\n💡 RECOMMENDATIONS:');
      for (final rec in report.recommendations) {
        debugPrint('  • $rec');
      }
    }

    // Performance Analysis Details
    if (report.performanceAnalysis.warnings.isNotEmpty) {
      debugPrint('\n📊 Performance Analysis:');
      for (final warning in report.performanceAnalysis.warnings) {
        final icon = warning.severity == PerformanceWarningSeverity.critical
            ? '🔴'
            : '⚠️';
        debugPrint('  $icon ${warning.message}');
        debugPrint('     ${warning.measuredValue} (recommended: ≤ ${warning.recommendedThreshold})');
      }
    }

    // Production Monitoring Stats
    if (report.productionStats.totalLayouts > 0) {
      debugPrint('\n📈 Layout Engine Statistics:');
      debugPrint('  Total Layouts: ${report.productionStats.totalLayouts}');
      debugPrint(
        '  New Engine Success: ${(report.productionStats.newEngineSuccessRate * 100).toStringAsFixed(1)}%',
      );
      debugPrint(
        '  Fallback Rate: ${(report.productionStats.fallbackRate * 100).toStringAsFixed(2)}%',
      );
      debugPrint(
        '  Avg Layout Time: ${report.productionStats.averageLayoutTimeMs.toStringAsFixed(2)}ms',
      );
    }

    debugPrint('═══════════════════════════════════════════════');

    // Summary
    if (report.isProductionReady) {
      debugPrint('✅ Your app is ready for production!');
    } else {
      debugPrint('❌ Please address critical issues before production deployment');
    }

    debugPrint('═══════════════════════════════════════════════\n');
  }

  /// Quick health check - returns true if production ready
  static bool quickCheck(String html) {
    final report = analyze(html);
    return report.isProductionReady;
  }

  /// Pre-deployment validation
  ///
  /// Run this before deploying to production to catch issues:
  ///
  /// ```dart
  /// if (!ProductionDiagnostic.validateForProduction(myHtml)) {
  ///   print('⚠️ Production validation failed!');
  ///   // Don't deploy
  /// }
  /// ```
  static bool validateForProduction(String html) {
    final report = analyze(html);
    printReport(report);
    return report.isProductionReady;
  }

  /// Analyze and get actionable advice
  static List<String> getActionableAdvice(String html) {
    final report = analyze(html);
    final advice = <String>[];

    // Critical issues first
    if (report.criticalIssues.isNotEmpty) {
      advice.add('CRITICAL: Fix these issues immediately:');
      advice.addAll(report.criticalIssues.map((i) => '  - $i'));
    }

    // Then warnings
    if (report.warnings.isNotEmpty) {
      advice.add('WARNINGS: Address these issues:');
      advice.addAll(report.warnings.map((w) => '  - $w'));
    }

    // Then recommendations
    if (report.recommendations.isNotEmpty) {
      advice.add('RECOMMENDATIONS: Consider these improvements:');
      advice.addAll(report.recommendations.map((r) => '  - $r'));
    }

    return advice;
  }
}

/// Diagnostic helper for continuous monitoring
class DiagnosticMonitor {
  final Duration checkInterval;
  final void Function(ProductionDiagnosticReport) onReport;

  DiagnosticMonitor({
    this.checkInterval = const Duration(minutes: 5),
    required this.onReport,
  });

  /// Start continuous monitoring (useful for long-running apps)
  void start() {
    // This is a placeholder - in real implementation you'd need to
    // hook into the render pipeline to get HTML periodically
    debugPrint('DiagnosticMonitor started (check interval: $checkInterval)');
  }

  /// Stop monitoring
  void stop() {
    debugPrint('DiagnosticMonitor stopped');
  }
}
