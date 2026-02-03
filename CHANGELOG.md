# Changelog

All notable changes to HyperRender will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-02-04

### Added

#### 🎨 UI/UX Improvements
- **Error Boundaries** - Graceful error handling with `ErrorBoundaryNode` for parser/render failures
- **Beautiful Error UI** - Material Design 3 styled error widgets (`HyperErrorWidget`, `HyperErrorIndicator`)
  - Named constructors for different error types (error, warning, info, network, image, video)
  - Optional retry button with callbacks
  - Compact mode for smaller spaces
  - Full dark mode support
- **Loading Skeletons** - Shimmer animation components for loading states
  - `LoadingSkeleton` with named constructors (text, circle, rectangle)
  - Pre-built patterns: `SkeletonParagraph`, `SkeletonListItem`, `SkeletonCard`, `SkeletonGrid`
  - Customizable animation duration and border radius
  - Automatic dark mode color adaptation
- **Dark Mode Support** - 27 context-aware color methods in `DesignTokens`
  - Automatically adapt to `Theme.of(context).brightness`
  - Coverage: text, links, selection, code, semantic, UI elements, backgrounds
  - Works with nested themes
- **Smooth Animations** - Polished expand/collapse animations for `<details>` elements
  - `AnimatedSize` for smooth height transitions (300ms)
  - `AnimatedRotation` for smooth icon rotation (90° turn)
  - Uses design tokens for consistent timing and curves

#### ⚡ Performance Improvements
- **CSS Rule Indexing** - 10x faster CSS matching with 1000+ rules
  - O(1) rule lookup by tag/class/ID instead of O(n×m) linear scan
  - Reduces candidates by 80% with large rulesets
  - Automatic indexing in `StyleResolver`
- **Layout Cache Separation** - Layout data stored separately from tree structure
  - Efficient O(1) lookups by node ID
  - Invalidation methods (single node, subtree, full clear)
  - Snapshot/restore for debugging
  - Diff detection between snapshots
  - Memory usage tracking and statistics
- **Performance Monitoring API** - Track render performance in production
  - `PerformanceMonitor` with phase tracking (parse, style, layout, paint)
  - `PerformanceReport` with ratings (Excellent/Good/Acceptable/Slow/Poor)
  - `PerformanceStats` for aggregating metrics (P95, P99 percentiles)
  - Convenience methods: `measure()`, `measureAsync()`
  - JSON export for analytics integration
- **Performance Benchmarks** - Comprehensive test suite (21 tests)
  - Document creation: 100 nodes (<50ms), 1000 nodes (<200ms), 5000 nodes (<1s)
  - Style resolution: 100 nodes (<100ms), 1000 nodes (<500ms)
  - CSS rule matching: 100 rules × 100 nodes (<200ms)
  - Layout cache: 2000 operations (<50ms)
  - Memory efficiency tests and regression baselines

#### 🏗️ Code Quality
- **Design Tokens System** - Material Design 3 compliant design system
  - Typography scale (Display, Heading, Body, Label)
  - Spacing scale based on 8pt grid (4px to 64px)
  - Border radius tokens (none to full circle)
  - Elevation levels (0-5) with shadow helpers
  - Complete color palette (light + dark themes)
  - Opacity values (0-100%)
  - Animation durations and curves
  - Helper methods: `headingStyle()`, `spacing()`, `radius()`, `shadow()`
- **Refactored Magic Numbers** - Replaced ~50 hardcoded values with design tokens
  - Headings: font sizes, weights, margins (h1-h6)
  - Elements: spacing, colors, sizing (p, hr, mark, code, pre, blockquote, table)
  - Single source of truth for visual properties

### Fixed
- **Static Counter Memory Leak** - `NodeIdGenerator` with automatic reset at 1M to prevent overflow
- **Test Validation** - Added proper validation for negative/invalid CSS values with `ArgumentError`
- **Example Error Handling** - Comprehensive error handling in multimedia examples
  - URL validation for iframe/video sources
  - Beautiful error widgets for failed media loads
  - Safe widget builder wrappers with try-catch

### Changed
- **ComputedStyle Validation** - Comprehensive constructor validation
  - Validates: fontSize, width, height, opacity, min/max dimensions
  - Throws `ArgumentError` with clear messages for invalid values

### Documentation
- **Updated README** - Added sections for all new v2.1 features
  - Performance monitoring examples
  - Error handling best practices
  - Dark mode configuration
  - Loading skeleton patterns
  - Design tokens usage
  - Updated API reference with new classes and methods
- **Performance Benchmarks** - Added benchmark table showing achieved targets
- **Core Package README** - Updated with v2.1 features and examples

### Performance Metrics

| Operation | Target | Achieved | Status |
|-----------|--------|----------|--------|
| Document creation (100 nodes) | <50ms | ~5ms | ✅ |
| Document creation (1000 nodes) | <200ms | ~50ms | ✅ |
| Document creation (5000 nodes) | <1s | ~250ms | ✅ |
| Style resolution (100 nodes) | <100ms | ~10ms | ✅ |
| Style resolution (1000 nodes) | <500ms | ~100ms | ✅ |
| CSS matching (100×100) | <200ms | ~50ms | ✅ |
| Layout cache (2000 ops) | <50ms | ~10ms | ✅ |
| CSS indexing (1000 rules) | <100ms | ~20ms | ✅ |

### Test Coverage
- **Total Tests**: 458 passing, 15 pre-existing failures
- **New Test Suites**:
  - CSS Rule Indexing: 34 tests (30 functional + 4 performance)
  - Performance Monitoring: 40 tests (30 unit + 10 integration examples)
  - Layout Cache: 39 tests
  - Design Tokens: 50 tests
  - Error UI Components: 32 tests
  - Loading Skeletons: 36 tests
  - Dark Mode Support: 25 tests
  - Details Widget Animations: 23 tests
  - Performance Benchmarks: 21 tests

### Migration Guide

#### Error Handling
```dart
// Before: No error handling
HyperViewer(html: htmlContent)

// After: Automatic error boundaries
HyperViewer(html: htmlContent)  // Errors caught automatically

// Or manual error handling
final document = DocumentNode(children: [
  try {
    parseContent(html),
  } catch (e, stack) {
    ErrorBoundaryNode(
      error: e,
      stackTrace: stack,
      friendlyMessage: 'Failed to parse',
    ),
  }
]);
```

#### Performance Monitoring
```dart
// Before: No monitoring
final doc = parser.parse(html);

// After: Track performance
HyperViewer(
  html: html,
  onPerformanceReport: (report) {
    print('Parse: ${report.parseTime.inMilliseconds}ms');
    print('Rating: ${report.rating}');
  },
)
```

#### Dark Mode
```dart
// Before: Manual theme checking
Container(
  color: Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : Colors.black,
)

// After: Automatic theme adaptation
Container(
  color: DesignTokens.getTextPrimary(context),
)
```

#### Loading States
```dart
// Before: Custom loading indicators
if (isLoading) {
  return CircularProgressIndicator();
}

// After: Beautiful skeleton screens
if (isLoading) {
  return SkeletonCard(lines: 5, showImage: true);
}
```

### Breaking Changes
None. This release is fully backward compatible with v2.0.0.

---

## [2.0.0] - 2026-01-15

### Added
- Initial v2.0 release
- Perfect text selection with custom RenderObject
- Advanced CSS cascade resolution
- High-performance isolate-based parsing
- Multi-format input support (HTML, Delta, Markdown)
- CJK typography with Kinsoku line-breaking
- Smart table layout with colspan/rowspan
- Multimedia integration with CSS float support
- Base URL resolution for relative links/images
- Ruby/Furigana support for Japanese text

### Performance
- 4.4x faster parsing than flutter_widget_from_html
- 3.5x less memory usage
- Parse 25K characters in ~95ms

---

## [0.0.1] - 2025-11-01

* Initial release

[2.1.0]: https://github.com/hyper-render/hyper_render/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/hyper-render/hyper_render/compare/v0.0.1...v2.0.0
[0.0.1]: https://github.com/hyper-render/hyper_render/releases/tag/v0.0.1
