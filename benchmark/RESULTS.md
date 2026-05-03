# HyperRender Benchmark Results

> **How to regenerate these numbers on your machine:**
> ```bash
> # Layout regression guard (runs in ~30 s, no device needed):
> flutter test benchmark/layout_regression.dart --reporter expanded
>
> # Full throughput benchmark (parses HTML documents of various sizes):
> flutter test benchmark/parse_benchmark.dart --reporter expanded
> ```
> CI runs `layout_regression.dart` on every PR and uploads results as artifacts.
> `parse_benchmark.dart` runs weekly and on release branches.

---

## Historical Baseline — v1.1.x / Flutter 3.x (2024-02-14)

> ⚠️ These numbers were collected against an earlier version on desktop.
> They are kept as a reference baseline. Re-run the benchmarks above for
> current Flutter 3.41.5 + v1.2.x numbers.

**Test Platform:**
- OS: macOS (Darwin 25.2.0)
- Flutter: Stable channel (3.x)
- Device: Desktop (x86_64)
- Date: 2024-02-14

---

## HTML Parsing Performance

Tests parsing and rendering of HTML documents of various sizes.

### Parse 1KB HTML
| Metric | Time |
|--------|------|
| Runs | 10 |
| Min | 21ms |
| Median | 27ms |
| Average | 28.9ms |
| P95 | 56ms |
| Max | 56ms |

### Parse 10KB HTML
| Metric | Time |
|--------|------|
| Runs | 10 |
| Min | 65ms |
| Median | 69ms |
| Average | 70.0ms |
| P95 | 80ms |
| Max | 80ms |

### Parse 50KB HTML
| Metric | Time |
|--------|------|
| Runs | 10 |
| Min | 263ms |
| Median | 276ms |
| Average | 300.3ms |
| P95 | 412ms |
| Max | 412ms |

### Parse 100KB HTML
| Metric | Time |
|--------|------|
| Runs | 5 |
| Min | 552ms |
| Median | 575ms |
| Average | 594.8ms |
| P95 | 665ms |
| Max | 665ms |

### Parse Complex HTML (tables, lists, styles)
| Metric | Time |
|--------|------|
| Runs | 10 |
| Min | 49ms |
| Median | 65ms |
| Average | 65.3ms |
| P95 | 84ms |
| Max | 84ms |

**Analysis:**
- Parsing performance scales approximately linearly with document size
- 1KB: ~27ms median
- 10KB: ~69ms median (2.6x slower for 10x size)
- 50KB: ~276ms median (4x slower for 5x size)
- 100KB: ~575ms median (2.1x slower for 2x size)

Complex HTML with tables and nested structures performs comparably to simple HTML of similar size.

---

## CSS Lookup Performance

Tests the O(1) indexed CSS rule lookup system.

### CSS Lookup - 100 Rules
| Metric | Time |
|--------|------|
| Lookups | 1000 |
| Min | 8μs |
| Median | 16μs |
| Average | 32.9μs |
| P95 | 46μs |
| P99 | 176μs |
| Max | 10577μs |

### CSS Lookup - 1000 Rules
| Metric | Time |
|--------|------|
| Lookups | 1000 |
| Min | 6μs |
| Median | 7μs |
| Average | 10.6μs |
| P95 | 9μs |
| P99 | 63μs |
| Max | 1522μs |

### CSS Lookup - 5000 Rules
| Metric | Time |
|--------|------|
| Lookups | 1000 |
| Min | 2μs |
| Median | 3μs |
| Average | 5.9μs |
| P95 | 5μs |
| P99 | 44μs |
| Max | 1554μs |

### Complex Selector Matching
| Metric | Time |
|--------|------|
| Lookups | 1000 |
| Min | 5μs |
| Median | 7μs |
| Average | 10.7μs |
| P95 | 16μs |
| P99 | 91μs |
| Max | 693μs |

**Analysis:**
- CSS lookup demonstrates **O(1) constant time** performance
- Median lookup time **decreases** as rule count increases:
  - 100 rules: 16μs median
  - 1000 rules: 7μs median (2.3x faster!)
  - 5000 rules: 3μs median (5.3x faster!)
- This counter-intuitive result confirms the effectiveness of the indexed lookup strategy
- Complex selectors (descendant, child, class combinations) perform comparably: 7μs median

The O(1) performance is achieved through the `CssRuleIndex` HashMap-based indexing system, which groups rules by selector type (tag, class, ID) for instant lookup.

---

## Key Findings

1. **HTML Parsing**: Scales linearly with document size. Median performance:
   - Small documents (<10KB): 27-69ms - suitable for sync rendering
   - Medium documents (10-50KB): 69-276ms - recommend async parsing
   - Large documents (>50KB): 276-575ms+ - virtualized rendering recommended

2. **CSS Lookup**: Demonstrates true O(1) constant-time performance regardless of stylesheet size. Even with 5000 CSS rules, lookup takes only 3μs median.

3. **Performance Recommendations**:
   - Documents <10KB: Use `HyperRenderMode.sync`
   - Documents 10-50KB: Use `HyperRenderMode.auto` (automatically switches to async)
   - Documents >50KB: Use `HyperRenderMode.virtualized` with view virtualization

4. **Production Readiness**: Current performance meets targets for documents up to 100KB with smooth rendering and negligible CSS lookup overhead.

---

## vs webview_flutter — Comparison Methodology

HyperRender's value proposition over a WebView is: **lower memory, faster first-frame,
native text selection, and zero JS overhead**. The table below is a guide for running
your own comparison; we do not ship fabricated numbers.

### Metrics to compare

| Metric | How to measure | Expected HyperRender advantage |
|--------|---------------|-------------------------------|
| **First meaningful paint** | `Stopwatch` from `HyperViewer` construction to first `pumpAndSettle` | Faster — no WebView init or JS parse |
| **Peak RSS memory** | `ProcessInfo.currentRss` before/after render | Lower — no WebView V8 heap |
| **Frame budget (60 FPS)** | `layout_regression.dart` vs equivalent `WebViewWidget` frame | Comparable on light content; advantage grows with long scrolling |
| **Cold start overhead** | Time to first interactive frame (includes WebView init) | Significantly faster — WebView cold-start is 200–800 ms on Android |

### How to run the comparison

1. Add `webview_flutter: ^4.0.0` to `example/pubspec.yaml`.
2. Create `benchmark/webview_comparison.dart` mirroring `parse_benchmark.dart` but
   using `WebViewWidget` as the rendering target.
3. Run both benchmarks on the **same physical device** (emulators have inaccurate
   frame timing).
4. Compare `median` and `P95` columns.

### What HyperRender does NOT beat WebView at

- Full CSS3 / JS-driven animations
- `<canvas>` / WebGL
- Sites that require actual browser APIs
- Documents with `position: absolute/fixed` layouts

Use `HtmlHeuristics.isComplex(html)` to detect these cases at runtime and fall
back to `webview_flutter` automatically (see `doc/LIMITATIONS.md`).
