# Integration Tests

This directory contains integration tests for HyperRender that test real-world scenarios, performance, and cross-cutting concerns.

## Test Categories

### 1. Real-World Content Tests
- `real_world_html_test.dart` - News articles, blog posts, documentation
- `markdown_integration_test.dart` - Complete Markdown documents
- `delta_integration_test.dart` - Quill Delta documents

### 2. Performance Tests
- `performance_regression_test.dart` - Ensure performance doesn't degrade
- `large_document_test.dart` - 100K+ character documents
- `memory_test.dart` - Memory leak detection

### 3. Error Recovery Tests
- `error_recovery_test.dart` - Malformed HTML, missing resources, edge cases
- `security_test.dart` - XSS attack vectors, sanitization

### 4. Feature Integration Tests
- `selection_integration_test.dart` - Complex selection scenarios
- `float_integration_test.dart` - Float layout with real content
- `table_integration_test.dart` - Complex table rendering

## Running Tests

```bash
# Run all integration tests
flutter test test/integration/

# Run specific test file
flutter test test/integration/real_world_html_test.dart

# Run with coverage
flutter test --coverage test/integration/

# Run in profile mode (for performance tests)
flutter test --profile test/integration/performance_regression_test.dart
```

## Test Data

Real-world HTML samples are stored in `test/fixtures/integration/`:
- `news_article.html` - News article with images
- `blog_post.html` - Blog post with code blocks
- `documentation.html` - Technical documentation
- `large_document.html` - 100KB+ document

## CI/CD Integration

These tests can be run:
- On every PR (fast tests only)
- On merge to main (all tests)
- Nightly (performance + memory tests)

## Performance Testing

These tests help track performance over time:
- Parse time for various document sizes
- Memory usage during rendering
- Scroll performance for virtualized mode
- Selection latency
