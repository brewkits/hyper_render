/// Performance Warnings System
///
/// Analyzes HTML content and provides warnings about potential performance issues.
/// Helps developers identify and fix performance problems before they affect users.
library;

import 'package:flutter/foundation.dart';

/// Performance warning severity levels
enum PerformanceWarningSeverity {
  /// Informational - no action needed
  info,

  /// Warning - may cause performance issues
  warning,

  /// Critical - will likely cause performance issues
  critical,
}

/// A performance warning with details and suggestions
class PerformanceWarning {
  /// Warning severity level
  final PerformanceWarningSeverity severity;

  /// Warning category (e.g., "document_size", "image_count")
  final String category;

  /// Human-readable warning message
  final String message;

  /// Measured value that triggered the warning
  final num measuredValue;

  /// Recommended threshold
  final num recommendedThreshold;

  /// Suggested actions to fix the issue
  final List<String> suggestions;

  const PerformanceWarning({
    required this.severity,
    required this.category,
    required this.message,
    required this.measuredValue,
    required this.recommendedThreshold,
    required this.suggestions,
  });

  @override
  String toString() {
    final icon = severity == PerformanceWarningSeverity.critical
        ? '🔴'
        : severity == PerformanceWarningSeverity.warning
            ? '⚠️'
            : 'ℹ️';

    final buffer = StringBuffer();
    buffer.writeln('$icon Performance ${severity.name.toUpperCase()}: $message');
    buffer.writeln('   Category: $category');
    buffer.writeln('   Measured: $measuredValue (recommended: ≤ $recommendedThreshold)');

    if (suggestions.isNotEmpty) {
      buffer.writeln('   Suggestions:');
      for (final suggestion in suggestions) {
        buffer.writeln('   • $suggestion');
      }
    }

    return buffer.toString();
  }
}

/// Result of performance analysis
class PerformanceAnalysisResult {
  /// All warnings found
  final List<PerformanceWarning> warnings;

  /// Warnings by severity
  Map<PerformanceWarningSeverity, List<PerformanceWarning>> get bySeverity {
    final map = <PerformanceWarningSeverity, List<PerformanceWarning>>{
      PerformanceWarningSeverity.info: [],
      PerformanceWarningSeverity.warning: [],
      PerformanceWarningSeverity.critical: [],
    };

    for (final warning in warnings) {
      map[warning.severity]!.add(warning);
    }

    return map;
  }

  /// Whether there are any critical warnings
  bool get hasCriticalWarnings =>
      warnings.any((w) => w.severity == PerformanceWarningSeverity.critical);

  /// Whether there are any warnings (warning or critical)
  bool get hasWarnings => warnings.any(
        (w) =>
            w.severity == PerformanceWarningSeverity.warning ||
            w.severity == PerformanceWarningSeverity.critical,
      );

  /// Total warning count
  int get count => warnings.length;

  const PerformanceAnalysisResult(this.warnings);

  /// Print all warnings to debug console
  void printWarnings() {
    if (warnings.isEmpty) {
      debugPrint('✅ No performance warnings');
      return;
    }

    debugPrint('═══════════════════════════════════════════════');
    debugPrint('HyperRender Performance Analysis');
    debugPrint('═══════════════════════════════════════════════');

    for (final warning in warnings) {
      debugPrint(warning.toString());
    }

    debugPrint('═══════════════════════════════════════════════');
    debugPrint('Total: ${warnings.length} warning(s)');
    debugPrint('═══════════════════════════════════════════════');
  }
}

/// Analyzes HTML content for potential performance issues
class PerformanceAnalyzer {
  // Thresholds for warnings
  static const int _documentSizeWarningKB = 100; // 100KB
  static const int _documentSizeCriticalKB = 500; // 500KB
  static const int _imageCountWarning = 20;
  static const int _imageCountCritical = 50;
  static const int _nestingDepthWarning = 15;
  static const int _nestingDepthCritical = 25;
  static const int _totalNodesWarning = 1000;
  static const int _totalNodesCritical = 5000;
  static const int _tableCellsWarning = 100;
  static const int _tableCellsCritical = 500;

  /// Analyze HTML string for performance issues
  ///
  /// Returns a list of warnings with severity levels and suggestions.
  /// Use this before rendering large or complex HTML to identify potential issues.
  ///
  /// Example:
  /// ```dart
  /// final result = PerformanceAnalyzer.analyze(htmlContent);
  /// if (result.hasCriticalWarnings) {
  ///   // Show warning to user or use alternative rendering
  /// }
  /// result.printWarnings();  // Print to debug console
  /// ```
  static PerformanceAnalysisResult analyze(String html) {
    final warnings = <PerformanceWarning>[];

    // 1. Document Size Analysis
    final sizeKB = html.length / 1024;
    if (sizeKB > _documentSizeCriticalKB) {
      warnings.add(PerformanceWarning(
        severity: PerformanceWarningSeverity.critical,
        category: 'document_size',
        message: 'HTML document is very large',
        measuredValue: sizeKB.round(),
        recommendedThreshold: _documentSizeWarningKB,
        suggestions: [
          'Split content into multiple pages with pagination',
          'Load content incrementally as user scrolls',
          'Remove unnecessary HTML comments and whitespace',
          'Consider using a WebView for documents > 500KB',
        ],
      ));
    } else if (sizeKB > _documentSizeWarningKB) {
      warnings.add(PerformanceWarning(
        severity: PerformanceWarningSeverity.warning,
        category: 'document_size',
        message: 'HTML document is large',
        measuredValue: sizeKB.round(),
        recommendedThreshold: _documentSizeWarningKB,
        suggestions: [
          'Consider pagination for better performance',
          'Lazy load images with loading="lazy" attribute',
          'Test scrolling performance on low-end devices',
        ],
      ));
    }

    // 2. Image Count Analysis
    final imageCount = _countOccurrences(html, '<img');
    if (imageCount > _imageCountCritical) {
      warnings.add(PerformanceWarning(
        severity: PerformanceWarningSeverity.critical,
        category: 'image_count',
        message: 'Too many images in document',
        measuredValue: imageCount,
        recommendedThreshold: _imageCountWarning,
        suggestions: [
          'Implement pagination to show fewer images per page',
          'Use lazy loading with ListView.builder for image galleries',
          'Load thumbnails first, full-size on demand',
          'Consider image sprites for icons',
        ],
      ));
    } else if (imageCount > _imageCountWarning) {
      warnings.add(PerformanceWarning(
        severity: PerformanceWarningSeverity.warning,
        category: 'image_count',
        message: 'Many images in document',
        measuredValue: imageCount,
        recommendedThreshold: _imageCountWarning,
        suggestions: [
          'Consider lazy loading images',
          'Use appropriate image sizes (cacheWidth/cacheHeight)',
          'Compress images to reduce download time',
        ],
      ));
    }

    // 3. Nesting Depth Analysis (approximate)
    final nestingDepth = _estimateMaxNestingDepth(html);
    if (nestingDepth > _nestingDepthCritical) {
      warnings.add(PerformanceWarning(
        severity: PerformanceWarningSeverity.critical,
        category: 'nesting_depth',
        message: 'Extremely deep HTML nesting',
        measuredValue: nestingDepth,
        recommendedThreshold: _nestingDepthWarning,
        suggestions: [
          'Simplify HTML structure to reduce nesting',
          'Remove unnecessary wrapper divs',
          'Flatten nested lists if possible',
          'Deep nesting can cause layout performance issues',
        ],
      ));
    } else if (nestingDepth > _nestingDepthWarning) {
      warnings.add(PerformanceWarning(
        severity: PerformanceWarningSeverity.warning,
        category: 'nesting_depth',
        message: 'Deep HTML nesting detected',
        measuredValue: nestingDepth,
        recommendedThreshold: _nestingDepthWarning,
        suggestions: [
          'Consider flattening HTML structure',
          'Deep nesting can impact layout performance',
        ],
      ));
    }

    // 4. Total Elements Analysis (approximate)
    final totalNodes = _estimateTotalNodes(html);
    if (totalNodes > _totalNodesCritical) {
      warnings.add(PerformanceWarning(
        severity: PerformanceWarningSeverity.critical,
        category: 'node_count',
        message: 'Very high number of HTML elements',
        measuredValue: totalNodes,
        recommendedThreshold: _totalNodesWarning,
        suggestions: [
          'Break document into smaller chunks',
          'Use pagination or virtual scrolling',
          'Simplify HTML structure where possible',
          'Consider WebView for extremely complex documents',
        ],
      ));
    } else if (totalNodes > _totalNodesWarning) {
      warnings.add(PerformanceWarning(
        severity: PerformanceWarningSeverity.warning,
        category: 'node_count',
        message: 'High number of HTML elements',
        measuredValue: totalNodes,
        recommendedThreshold: _totalNodesWarning,
        suggestions: [
          'Test performance on low-end devices',
          'Consider simplifying structure',
        ],
      ));
    }

    // 5. Table Complexity Analysis
    final tableCells = _estimateTableCells(html);
    if (tableCells > _tableCellsCritical) {
      warnings.add(PerformanceWarning(
        severity: PerformanceWarningSeverity.critical,
        category: 'table_complexity',
        message: 'Very large tables detected',
        measuredValue: tableCells,
        recommendedThreshold: _tableCellsWarning,
        suggestions: [
          'Split large tables into smaller tables with pagination',
          'Use scrollable containers for wide tables',
          'Consider alternative data visualization (charts, cards)',
          'Large tables can cause significant layout overhead',
        ],
      ));
    } else if (tableCells > _tableCellsWarning) {
      warnings.add(PerformanceWarning(
        severity: PerformanceWarningSeverity.warning,
        category: 'table_complexity',
        message: 'Large tables detected',
        measuredValue: tableCells,
        recommendedThreshold: _tableCellsWarning,
        suggestions: [
          'Consider pagination for large tables',
          'Test scrolling performance with table content',
        ],
      ));
    }

    // 6. Inline Styles Analysis
    final inlineStyleCount = _countOccurrences(html, 'style="');
    if (inlineStyleCount > 100) {
      warnings.add(PerformanceWarning(
        severity: PerformanceWarningSeverity.warning,
        category: 'inline_styles',
        message: 'Many inline styles detected',
        measuredValue: inlineStyleCount,
        recommendedThreshold: 50,
        suggestions: [
          'Use customCss parameter instead of inline styles',
          'CSS classes are more efficient than inline styles',
          'Consider using CSS custom properties (variables)',
        ],
      ));
    }

    // 7. Script Tags (security warning)
    final scriptCount = _countOccurrences(html, '<script');
    if (scriptCount > 0) {
      warnings.add(PerformanceWarning(
        severity: PerformanceWarningSeverity.critical,
        category: 'security',
        message: '<script> tags detected (potential XSS)',
        measuredValue: scriptCount,
        recommendedThreshold: 0,
        suggestions: [
          'CRITICAL: Script tags are security risks!',
          'Use HtmlSanitizer.sanitize() to remove scripts',
          'Never render untrusted HTML without sanitization',
          'HyperRender does not execute JavaScript',
        ],
      ));
    }

    // 8. Event Handlers (security warning)
    final eventHandlers = _countEventHandlers(html);
    if (eventHandlers > 0) {
      warnings.add(PerformanceWarning(
        severity: PerformanceWarningSeverity.warning,
        category: 'security',
        message: 'Event handler attributes detected (onclick, etc.)',
        measuredValue: eventHandlers,
        recommendedThreshold: 0,
        suggestions: [
          'Event handlers are potential XSS vectors',
          'Use HtmlSanitizer.sanitize() to remove event handlers',
          'Sanitization is automatic for untrusted content',
        ],
      ));
    }

    return PerformanceAnalysisResult(warnings);
  }

  /// Quick check if HTML is likely to have performance issues
  ///
  /// Returns true if any critical warnings would be generated.
  /// Use this for fast checks before full analysis.
  static bool hasPerformanceIssues(String html) {
    // Quick checks only
    final sizeKB = html.length / 1024;
    if (sizeKB > _documentSizeCriticalKB) return true;

    final imageCount = _countOccurrences(html, '<img');
    if (imageCount > _imageCountCritical) return true;

    final scriptCount = _countOccurrences(html, '<script');
    if (scriptCount > 0) return true;

    return false;
  }

  // Helper methods

  static int _countOccurrences(String text, String pattern) {
    if (pattern.isEmpty) return 0;
    int count = 0;
    int index = 0;

    while ((index = text.indexOf(pattern, index)) != -1) {
      count++;
      index += pattern.length;
    }

    return count;
  }

  static int _estimateMaxNestingDepth(String html) {
    int maxDepth = 0;
    int currentDepth = 0;

    final tagPattern = RegExp(r'<(/?)(\w+)');
    final matches = tagPattern.allMatches(html);

    for (final match in matches) {
      final isClosing = match.group(1) == '/';
      final tagName = match.group(2) ?? '';

      // Skip self-closing tags
      if (['img', 'br', 'hr', 'input', 'meta', 'link'].contains(tagName)) {
        continue;
      }

      if (isClosing) {
        currentDepth--;
      } else {
        currentDepth++;
        if (currentDepth > maxDepth) {
          maxDepth = currentDepth;
        }
      }
    }

    return maxDepth;
  }

  static int _estimateTotalNodes(String html) {
    // Rough estimate: count opening tags
    final openingTags = RegExp(r'<\w+').allMatches(html).length;
    return openingTags;
  }

  static int _estimateTableCells(String html) {
    return _countOccurrences(html, '<td') + _countOccurrences(html, '<th');
  }

  static int _countEventHandlers(String html) {
    int count = 0;
    final eventHandlers = [
      'onclick',
      'ondblclick',
      'onmousedown',
      'onmouseup',
      'onmouseover',
      'onmouseout',
      'onkeydown',
      'onkeyup',
      'onload',
      'onerror',
      'onsubmit',
      'onchange',
      'onfocus',
      'onblur',
    ];

    for (final handler in eventHandlers) {
      count += _countOccurrences(html.toLowerCase(), handler);
    }

    return count;
  }
}
