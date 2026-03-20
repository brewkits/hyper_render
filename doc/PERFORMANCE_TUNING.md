# Performance Tuning Guide

Last Updated: February 2026
Version: 1.0.0

This guide helps you optimize HyperRender performance for different use cases.

## Table of Contents

1. Quick Performance Checklist
2. Render Modes Explained
3. Choosing the Right Mode
4. Image Loading & Caching
5. CSS Optimization
6. Memory Management
7. Profiling with DevTools
8. Common Performance Issues

## Quick Performance Checklist

DO:
- Use HyperRenderMode.sync for small content
- Use HyperRenderMode.virtualized for large content
- Use HyperRenderMode.auto when content size varies
- Cache parsed DocumentNodes when content doesn't change
- Minimize inline styles (use CSS classes instead)
- Use selectable: false if selection not needed
- Optimize images (compress, resize before rendering)

DON'T:
- Parse the same HTML repeatedly
- Use virtualized mode for short content (overhead not worth it)
- Load huge images without constraints
- Use complex CSS selectors unnecessarily
- Enable zoom on virtualized content (conflicts with scrolling)

---

## Render Modes Explained

HyperRender offers 3 render modes optimized for different scenarios:

### 1. HyperRenderMode.sync (Default for small content)

How it works:
- Parses HTML on main thread (synchronous)
- Renders entire content as single widget
- Scrollable via SingleChildScrollView

Performance:
- Parse time: Fast for small content
- First frame: Very fast (single layout pass)
- Memory: Low (single RenderObject)

Best for:
```dart
HyperViewer(
  html: shortArticle,
  mode: HyperRenderMode.sync,
)
```

Use cases:
- Comments/posts
- Email previews
- Chat messages with formatting
- Product descriptions

### 2. HyperRenderMode.virtualized (For large content)

How it works:
- Parses HTML in background isolate (async)
- Splits content into chunks
- Renders via ListView.builder (virtualizes viewport)
- Only visible sections are in memory

Performance:
- Parse time: Longer but doesn't block UI
- First frame: Fast (renders above-fold content first)
- Memory: Efficient (only viewport + cache rendered)
- Scroll: Smooth even with large HTML

Best for:
```dart
HyperViewer(
  html: longDocument,
  mode: HyperRenderMode.virtualized,
)
```

Use cases:
- Long articles/blog posts
- Documentation pages
- Books/novels
- News feeds

### 3. HyperRenderMode.auto (Smart auto-detection)

How it works:
- Checks content length
- Uses sync for smaller content
- Uses virtualized for larger content

Best for:
```dart
HyperViewer(
  html: variableLengthContent,
  mode: HyperRenderMode.auto,
)
```

Use cases:
- User-generated content (variable length)
- API responses (unknown size)
- Mixed content (comments + articles)

## Choosing the Right Mode

### Decision Tree

```
Content Length?
  ├─ Small content
  │   └─ Use: sync (fastest first render)
  │
  ├─ Medium content
  │   └─ Use: auto (will choose sync)
  │
  ├─ Large content
  │   └─ Use: virtualized (smooth scrolling)
  │
  └─ Very large content
      └─ Use: virtualized (only viable option)
```

### Performance Comparison

| Mode | Parse Time | Memory Usage | Scroll Performance |
|------|------------|--------------|-------------------|
| sync | Fast (blocking) | Higher (all rendered) | Good |
| virtualized | Slower (non-blocking) | Lower (viewport only) | Smooth |
| auto | Adaptive | Adaptive | Good |

## Image Loading & Caching

### Default Image Caching

HyperRender uses Flutter's built-in image cache:

```dart
// Default cache settings use Flutter's defaults
// - Eviction: LRU (Least Recently Used)
```

### Custom Image Cache Configuration

```dart
// In main.dart, before runApp()
void main() {
  // Adjust cache size for image-heavy content if needed
  PaintingBinding.instance.imageCache.maximumSize = 2000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 * 1024 * 1024;

  runApp(MyApp());
}
```

### Optimizing Image Loading

```dart
HyperViewer(
  html: content,
  widgetBuilder: (context, node) {
    if (node is AtomicNode && node.tagName == 'img') {
      final src = node.src;
      if (src == null) return null;

      // Use CachedNetworkImage for better performance
      return CachedNetworkImage(
        imageUrl: src,
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(Icons.error),
        // Add memory cache
        memCacheWidth: 800,
        maxWidthDiskCache: 1200,
      );
    }
    return null;
  },
)
```

### Image Size Constraints

```dart
// Good - Constrain image sizes
HyperViewer(
  html: '''
    <img src="huge-image.jpg" style="max-width: 100%; height: auto;">
  ''',
)

// Bad - Unconstrained images may cause memory issues
HyperViewer(
  html: '''
    <img src="huge-image.jpg">
  ''',
)
```

## CSS Optimization

### CSS Rule Matching Performance

HyperRender uses indexed lookup for CSS rules:

```dart
// Internal implementation:
// - Class rules indexed by class name
// - ID rules indexed by ID
// - Tag rules indexed by tag name
// Result: Fast lookup performance
```

### Optimization Tips

Prefer classes over complex selectors:
```html
<!-- Fast: Direct class lookup -->
<div class="card">Content</div>

<!-- Slower: Must traverse tree -->
<div>
  <div>
    <div class="deep-nested">Content</div>
  </div>
</div>
```

Minimize inline styles:
```html
<!-- Better: Reuses computed style -->
<p class="text">Paragraph 1</p>
<p class="text">Paragraph 2</p>
<p class="text">Paragraph 3</p>

<!-- Worse: Computes style multiple times -->
<p style="color: red; font-size: 16px;">Paragraph 1</p>
<p style="color: red; font-size: 16px;">Paragraph 2</p>
<p style="color: red; font-size: 16px;">Paragraph 3</p>
```

Use CSS shorthand:
```css
/* Better: Single property parse */
.box {
  margin: 16px 8px;
  padding: 12px;
}

/* Worse: Multiple property parses */
.box {
  margin-top: 16px;
  margin-right: 8px;
  margin-bottom: 16px;
  margin-left: 8px;
}
```

## Memory Management

### TextPainter Caching

HyperRender uses LRU cache for TextPainters:

```dart
// Uses LRU cache with automatic eviction
// Eviction: Least Recently Used (LRU)
// Each evicted painter is properly disposed

// No configuration needed - handled automatically
```

### GestureRecognizer Lifecycle

```dart
// Automatic disposal
// All TapGestureRecognizers are disposed when widget is removed
// Implemented in RenderHyperBox.dispose()

// No manual cleanup needed
```

### Memory Profiling

Check memory usage with DevTools:

```bash
# Run app in profile mode
flutter run --profile

# Open DevTools
# Memory tab → Take snapshot
# Look for:
# - Image cache size
# - TextPainter count
# - GestureRecognizer count
```

---

## Profiling with DevTools

### 1. Performance Profiling

**Measure render time**:
```dart
final stopwatch = Stopwatch()..start();

HyperViewer(
  html: content,
  placeholderBuilder: (context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Parsing... ${stopwatch.elapsedMilliseconds}ms'),
        ],
      ),
    );
  },
)
```

### 2. Frame Rendering

```bash
# Run in profile mode
flutter run --profile

# Open DevTools → Performance tab
# Look for:
# - Frame rendering time (should be < 16ms for 60fps)
# - Jank (red bars indicate dropped frames)
# - Build/Layout/Paint times
```

### 3. CPU Profiling

**Identify bottlenecks**:
1. Open DevTools → CPU Profiler
2. Click "Record"
3. Scroll through content
4. Click "Stop"
5. Analyze flame graph:
   - Look for wide bars (time-consuming operations)
   - Common culprits: image decoding, layout, paint

### 4. Memory Profiling

**Detect memory leaks**:
```bash
# Steps:
1. Open DevTools → Memory tab
2. Take baseline snapshot
3. Navigate to HyperViewer screen
4. Take snapshot #2
5. Navigate away
6. Take snapshot #3
7. Compare snapshots:
   - Memory should return to baseline after navigation
   - If not, investigate retained objects
```


## Common Performance Issues

### Issue 1: Jank During Scroll

Symptom: Stuttering/dropped frames while scrolling

Causes:
- Large inline images not constrained
- Too many TextPainters being created
- Complex CSS selectors

Solutions:
```dart
// Constrain image sizes
<img src="image.jpg" style="max-width: 100%; height: auto;">

// Use virtualized mode for large content
HyperViewer(
  html: largeContent,
  mode: HyperRenderMode.virtualized,
)
```

### Issue 2: Slow Initial Load

Symptom: Long delay before content appears

Causes:
- Parsing large HTML on main thread
- Loading many images synchronously

Solutions:
```dart
// Use virtualized mode for async parsing
HyperViewer(
  html: largeContent,
  mode: HyperRenderMode.virtualized,
)

// Show loading indicator
HyperViewer(
  html: content,
  placeholderBuilder: (context) => CircularProgressIndicator(),
)

// Lazy-load images
widgetBuilder: (context, node) {
  if (node is AtomicNode && node.isImage) {
    return CachedNetworkImage(
      imageUrl: node.src!,
      placeholder: (context, url) => Shimmer(...),
    );
  }
  return null;
}
```

### Issue 3: High Memory Usage

Symptom: App using excessive RAM

Causes:
- Large uncompressed images
- Too many cached images
- Not using virtualized mode for large content

Solutions:
```dart
// Reduce image cache size if needed
PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;

// Use virtualized mode
HyperViewer(
  html: largeContent,
  mode: HyperRenderMode.virtualized,
)

// Compress images server-side
// - Use WebP format
// - Resize to display size
```

### Issue 4: Slow CSS Resolution

Symptom: Long layout times in DevTools

Causes:
- Too many CSS rules
- Complex descendant selectors

Solutions:
```dart
// Use specific classes
<style>
  .article-text { color: #333; }
</style>
<p class="article-text">Content</p>

// Avoid complex selectors
<style>
  div > section > article > p { color: #333; }
</style>
```

## Performance Best Practices Summary

### For Small Content
```dart
HyperViewer(
  html: shortContent,
  mode: HyperRenderMode.sync,
  selectable: true,
)
```

### For Medium Content
```dart
HyperViewer(
  html: mediumContent,
  mode: HyperRenderMode.auto,
  placeholderBuilder: (context) => CircularProgressIndicator(),
)
```

### For Large Content
```dart
HyperViewer(
  html: largeContent,
  mode: HyperRenderMode.virtualized,
  selectable: false,
  placeholderBuilder: (context) => LoadingShimmer(),
)
```

### For Image-Heavy Content
```dart
HyperViewer(
  html: content,
  widgetBuilder: (context, node) {
    if (node is AtomicNode && node.isImage) {
      return CachedNetworkImage(
        imageUrl: node.src!,
        memCacheWidth: 800,
        placeholder: (context, url) => Shimmer(...),
      );
    }
    return null;
  },
)
```

---

## Monitoring Performance in Production

### Add Performance Metrics

```dart
class PerformanceMonitor {
  static void trackRenderTime(String contentId, Duration duration) {
    // Send to analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'hyper_render_performance',
      parameters: {
        'content_id': contentId,
        'render_time_ms': duration.inMilliseconds,
        'content_length': html.length,
      },
    );
  }
}

// Usage:
final stopwatch = Stopwatch()..start();
HyperViewer(
  html: content,
  // ... after rendering
);
PerformanceMonitor.trackRenderTime('article_123', stopwatch.elapsed);
```

## Further Resources

- Flutter Performance Best Practices: https://docs.flutter.dev/perf/best-practices
- DevTools User Guide: https://docs.flutter.dev/tools/devtools
- Image Optimization: https://docs.flutter.dev/perf/rendering-performance#images
- HyperRender Benchmarks: benchmark/ folder

Remember: Profile first, optimize second. Use DevTools to identify actual bottlenecks before making changes.
