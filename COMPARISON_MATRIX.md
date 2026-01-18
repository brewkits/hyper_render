# HyperRender v2.0 - Detailed Comparison Matrix

**Comprehensive feature-by-feature comparison with competitors**

Last Updated: January 2026

---

## How to Use This Matrix

- ✅ **Excellent**: Feature works perfectly, production-ready
- ⚠️ **Acceptable**: Feature works with limitations or trade-offs
- ❌ **Poor/Missing**: Feature doesn't work or has major issues
- 🔜 **Planned**: Feature on roadmap (see version)
- N/A: Not applicable for this solution

---

## Performance Metrics

| Metric | FWFH | WebView | super_editor | HyperRender v2.0 |
|--------|------|---------|--------------|------------------|
| **Parse Time (10K chars)** | 250ms ⚠️ | 400ms ⚠️ | N/A | **60ms ✅** |
| **Parse Time (25K chars)** | 420ms ❌ | 800ms ❌ | N/A | **95ms ✅** |
| **Memory Usage (10K)** | 15MB ⚠️ | 30MB ❌ | N/A | **5MB ✅** |
| **Memory Usage (25K)** | 28MB ❌ | 45MB ❌ | N/A | **8MB ✅** |
| **Scroll FPS (25K)** | 35fps ❌ | 55fps ⚠️ | 60fps ✅ | **60fps ✅** |
| **Text Selection (25K)** | Breaks ❌ | Perfect ✅ | Perfect ✅ | **Smooth ✅** |
| **Startup Time** | Fast ✅ | Slow ❌ | Fast ✅ | **Fast ✅** |
| **Bundle Size Impact** | +500KB ✅ | +20MB ❌ | +800KB ✅ | **+600KB ✅** |

**Notes**:
- Benchmarks run on iPhone 13 (iOS 17) and Pixel 6 (Android 13)
- Parse time measured from HTML string to rendered widget
- Memory usage measured at peak during rendering

---

## HTML Support

| Feature | FWFH | WebView | HyperRender v2.0 |
|---------|------|---------|------------------|
| **Basic Tags** | | | |
| `<p>`, `<div>`, `<span>` | ✅ | ✅ | ✅ |
| `<h1>`-`<h6>` | ✅ | ✅ | ✅ |
| `<ul>`, `<ol>`, `<li>` | ✅ | ✅ | ✅ |
| `<a>` | ✅ | ✅ | ✅ |
| `<img>` | ✅ | ✅ | ✅ |
| `<br>`, `<hr>` | ✅ | ✅ | ✅ |
| **Text Formatting** | | | |
| `<strong>`, `<b>` | ✅ | ✅ | ✅ |
| `<em>`, `<i>` | ✅ | ✅ | ✅ |
| `<u>`, `<s>`, `<del>` | ✅ | ✅ | ✅ |
| `<mark>` | ✅ | ✅ | ✅ |
| `<code>`, `<pre>` | ✅ | ✅ | ✅ |
| `<sub>`, `<sup>` | ⚠️ | ✅ | ⚠️ Basic |
| **Semantic** | | | |
| `<article>`, `<section>` | ✅ | ✅ | ✅ |
| `<header>`, `<footer>` | ✅ | ✅ | ✅ |
| `<nav>`, `<aside>` | ✅ | ✅ | ✅ |
| `<blockquote>` | ✅ | ✅ | ✅ |
| **Tables** | | | |
| `<table>`, `<tr>`, `<td>` | ✅ | ✅ | ✅ |
| `<th>`, `<thead>`, `<tbody>` | ✅ | ✅ | ✅ |
| `colspan`, `rowspan` | ⚠️ Basic | ✅ | ✅ Full |
| Content-based width | ❌ | ✅ | **✅ Smart** |
| Horizontal scroll | ⚠️ | ✅ | ✅ |
| Auto-scale | ❌ | ✅ | ✅ |
| **Media** | | | |
| `<img>` with dimensions | ✅ | ✅ | ✅ |
| `<video>` | ⚠️ | ✅ | ⚠️ Placeholder |
| `<audio>` | ⚠️ | ✅ | ⚠️ Placeholder |
| `<iframe>` | ❌ | ✅ | ❌ |
| **CJK Specific** | | | |
| `<ruby>`, `<rt>` | ❌ | ✅ | **✅ Full** |
| Kinsoku shori | ❌ | ✅ | **✅ Full** |
| Vertical text | ❌ | ✅ | 🔜 v2.1 |
| **Interactive (v2.0)** | | | |
| `<details>`, `<summary>` | ❌ | ✅ | **✅ Full** |
| `<button>` | ⚠️ | ✅ | 🔜 v2.3 |
| `<input>` | ⚠️ | ✅ | 🔜 v2.3 |
| `<form>` | ⚠️ | ✅ | ❌ Not planned |

---

## CSS Support

| Property | FWFH | WebView | HyperRender v2.0 |
|----------|------|---------|------------------|
| **Text Properties** | | | |
| `color` | ✅ | ✅ | ✅ |
| `font-size` | ✅ | ✅ | ✅ |
| `font-weight` | ✅ | ✅ | ✅ |
| `font-style` | ✅ | ✅ | ✅ |
| `font-family` | ✅ | ✅ | ✅ |
| `line-height` | ⚠️ | ✅ | ✅ |
| `letter-spacing` | ⚠️ | ✅ | ✅ |
| `word-spacing` | ❌ | ✅ | ✅ |
| `text-align` | ✅ | ✅ | ✅ |
| `text-decoration` | ✅ | ✅ | ✅ |
| `text-transform` | ⚠️ | ✅ | ✅ |
| `white-space` | ⚠️ | ✅ | ✅ |
| **Box Model** | | | |
| `width`, `height` | ✅ | ✅ | ✅ |
| `min-width`, `max-width` | ⚠️ | ✅ | ✅ |
| `margin` | ✅ | ✅ | ✅ |
| `padding` | ✅ | ✅ | ✅ |
| `border` | ✅ | ✅ | ✅ |
| `border-radius` | ⚠️ | ✅ | ✅ |
| **Layout** | | | |
| `display` (block/inline) | ✅ | ✅ | ✅ |
| `display: none` | ✅ | ✅ | ✅ |
| `display: flex` | ❌ | ✅ | ❌ |
| `display: grid` | ❌ | ✅ | ❌ |
| `float` | ⚠️ Basic | ✅ | ✅ |
| `clear` | ⚠️ | ✅ | ✅ |
| `position` | ❌ | ✅ | ❌ Not planned |
| **List** | | | |
| `list-style-type` | ⚠️ Basic | ✅ | **✅ 9 types** |
| `list-style-position` | ❌ | ✅ | ⚠️ Outside only |
| **Background** | | | |
| `background-color` | ✅ | ✅ | ✅ |
| `background-image` | ⚠️ | ✅ | ⚠️ Basic |
| `background-size` | ❌ | ✅ | ❌ |
| **Effects** | | | |
| `opacity` | ⚠️ | ✅ | ⚠️ |
| `box-shadow` | ❌ | ✅ | ❌ |
| `text-shadow` | ❌ | ✅ | ❌ |
| **Animations** | | | |
| `transition` | ❌ | ✅ | 🔜 v2.1 |
| `animation` | ❌ | ✅ | 🔜 v2.1 |
| `transform` | ❌ | ✅ | ❌ Not planned |

**CSS Coverage Summary**:
- FWFH: ~50 properties
- WebView: ~300 properties (full spec)
- HyperRender v2.0: ~40 essential properties

---

## Platform Support

| Platform | FWFH | WebView | super_editor | HyperRender v2.0 |
|----------|------|---------|--------------|------------------|
| **Mobile** | | | | |
| iOS | ✅ | ✅ | ✅ | ✅ |
| Android | ✅ | ✅ | ✅ | ✅ |
| **Desktop** | | | | |
| macOS | ✅ | ⚠️ Limited | ✅ | ✅ |
| Windows | ✅ | ⚠️ Limited | ✅ | ✅ |
| Linux | ✅ | ⚠️ Limited | ✅ | ✅ |
| **Web** | | | | |
| Web (CanvasKit) | ✅ | ❌ | ✅ | ✅ |
| Web (HTML renderer) | ⚠️ | ❌ | ⚠️ | ✅ |

---

## Developer Experience

| Aspect | FWFH | WebView | super_editor | HyperRender v2.0 |
|--------|------|---------|--------------|------------------|
| **Ease of Use** | | | | |
| Learning curve | Easy ✅ | Medium ⚠️ | Hard ❌ | Medium ⚠️ |
| Basic setup | 5 min ✅ | 10 min ⚠️ | 30 min ❌ | 5 min ✅ |
| Documentation | Good ✅ | Excellent ✅ | Good ✅ | **Excellent ✅** |
| Examples | Many ✅ | Many ✅ | Few ⚠️ | **Many ✅** |
| **Customization** | | | | |
| Widget builders | ✅ Easy | ❌ Hard | N/A | ⚠️ Medium |
| Custom CSS | ⚠️ Limited | ✅ Full | N/A | ⚠️ Essential |
| Styling API | ✅ | ❌ | ✅ | ✅ |
| **Debugging** | | | | |
| Error messages | Good ✅ | Poor ❌ | Good ✅ | **Excellent ✅** |
| Flutter DevTools | ✅ | ⚠️ | ✅ | ✅ |
| Hot reload | ✅ | ⚠️ | ✅ | ✅ |
| **Community** | | | | |
| GitHub stars | 2.1K ✅ | 15K ✅ | 1.5K ✅ | New (targeting 1K) |
| Issues response | Slow ⚠️ | Fast ✅ | Medium ⚠️ | **Fast ✅** |
| Community plugins | Many ✅ | Few ⚠️ | Few ⚠️ | Growing 🔜 |

---

## Use Case Suitability

| Use Case | FWFH | WebView | super_editor | HyperRender v2.0 |
|----------|------|---------|--------------|------------------|
| **Content Display** | | | | |
| News articles (5K+ chars) | ⚠️ Slow | ✅ | N/A | **✅ Fast** |
| Documentation | ⚠️ | ✅ | N/A | **✅ Optimized** |
| E-books | ❌ Slow | ⚠️ Heavy | N/A | **✅ Perfect** |
| RSS feeds | ⚠️ | ✅ | N/A | **✅ Ideal** |
| Email (HTML) | ✅ | ⚠️ Security | N/A | **✅ Safe** |
| **Interactive** | | | | |
| Rich text editor | ❌ | ❌ | **✅ Designed for** | 🔜 v3.0 Light mode |
| WYSIWYG editor | ❌ | ⚠️ | ✅ | ❌ Not planned |
| Forms | ⚠️ | ✅ | ❌ | 🔜 v2.3 Read-only |
| Web scraping display | ⚠️ | ✅ Full | N/A | ⚠️ Essential only |
| **CJK Content** | | | | |
| Japanese articles | ❌ No kinsoku | ✅ | N/A | **✅ Perfect** |
| Korean blogs | ❌ | ✅ | N/A | **✅ Optimized** |
| Chinese docs | ❌ | ✅ | N/A | **✅ Good** |
| Manga/Comics | ❌ | ✅ | N/A | ⚠️ Depends |
| **Technical** | | | | |
| API docs | ⚠️ | ✅ | N/A | **✅ Great** |
| Code snippets | ✅ | ✅ | ✅ | **✅ With syntax** |
| Tables (data) | ⚠️ Basic | ✅ | N/A | **✅ Smart layout** |
| Math formulas | ❌ | ⚠️ MathML | ❌ | 🔜 Plugin |

---

## Security & Safety

| Aspect | FWFH | WebView | HyperRender v2.0 |
|--------|------|---------|------------------|
| **XSS Protection** | ⚠️ Manual | ⚠️ Sandboxed | ⚠️ Manual sanitization |
| **JavaScript Execution** | ❌ None | ✅ Full (risk) | ❌ None (safe) |
| **External Resources** | ⚠️ Limited control | ⚠️ CSP needed | ✅ Full control |
| **User Input Handling** | ⚠️ | ⚠️ | **✅ Read-only** |
| **Privacy** | ✅ Local only | ⚠️ Tracking possible | ✅ Local only |

**Recommendation**: Always sanitize untrusted HTML before rendering in any solution.

---

## Cost Analysis

| Factor | FWFH | WebView | HyperRender v2.0 |
|--------|------|---------|------------------|
| **License** | MIT (Free) | Apache (Free) | MIT (Free) |
| **Development Time** | Low ✅ | Medium ⚠️ | Medium ⚠️ |
| **Maintenance** | Low ✅ | Medium ⚠️ | Low ✅ |
| **Performance Optimization** | High ❌ | Low ✅ | **Low ✅** |
| **Platform Testing** | Medium ⚠️ | High ❌ | Low ✅ |
| **Support** | Community | Community | **Community + Paid** |

---

## Migration Effort

| From → To | FWFH → HyperRender | WebView → HyperRender | super_editor → HyperRender |
|-----------|-------------------|----------------------|---------------------------|
| **Code Changes** | Medium (2-4 hours) | Low (4-6 hours) | High (N/A - different use case) |
| **Testing Required** | Medium | High | N/A |
| **Performance Gain** | **4.4x faster ✅** | **60% less memory ✅** | N/A |
| **Feature Loss** | Custom widgets | JavaScript, forms | N/A |
| **Breaking Changes** | Widget builders | Full rewrite | N/A |

---

## Decision Matrix

### Choose FWFH if:
- ✅ Short documents (<1K chars)
- ✅ Need custom Flutter widgets embedded
- ✅ Performance is acceptable
- ✅ Team familiar with widget builders

### Choose WebView if:
- ✅ Need 100% CSS accuracy
- ✅ JavaScript execution required
- ✅ Full form support needed
- ✅ Existing web content (no modification)

### Choose super_editor if:
- ✅ Building a text editor (not viewer)
- ✅ Need caret, keyboard, selection
- ✅ Rich text composition required

### Choose HyperRender v2.0 if:
- ✅ **Large documents (5K+ chars)**
- ✅ **Performance critical (60fps required)**
- ✅ **CJK content (Japanese, Korean, Chinese)**
- ✅ **Native feel important**
- ✅ **Bundle size matters**
- ✅ **Read-only or light editing**

---

## Version Comparison (HyperRender Roadmap)

| Feature | v2.0 (Now) | v2.1 (Q2'26) | v2.2 (Q3'26) | v2.3 (Q4'26) | v3.0 (2027+) |
|---------|-----------|--------------|--------------|--------------|--------------|
| InlineSpan paradigm | ✅ | ✅ | ✅ | ✅ | ✅ |
| Performance (60fps) | ✅ | ✅ | ✅ | ✅ | ✅ |
| CJK typography | ✅ | ✅ | ✅ | ✅ | ✅ |
| Vertical text | ❌ | ✅ | ✅ | ✅ | ✅ |
| CSS animations | ❌ | ✅ Basic | ✅ | ✅ | ✅ |
| Widget embedding | ⚠️ Manual | ⚠️ | ✅ API | ✅ | ✅ |
| Theme system | ❌ | ❌ | ✅ M3 | ✅ | ✅ |
| Form inputs | ❌ | ❌ | ❌ | ✅ Read-only | ✅ |
| Interactive buttons | ❌ | ❌ | ❌ | ✅ | ✅ |
| Light editing | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## Benchmark Suite (Reproducible)

### Test Environment
```yaml
Devices:
  - iPhone 13 (iOS 17.2)
  - Pixel 6 (Android 13)
  - MacBook Pro M1 (macOS 14)

Flutter Version: 3.19.0
Dart Version: 3.3.0

Test Documents:
  - Small: 1,000 characters
  - Medium: 5,000 characters
  - Large: 10,000 characters
  - XLarge: 25,000 characters
```

### Test Cases
1. **Parse Time**: HTML string → Rendered widget
2. **Memory Usage**: Peak during rendering
3. **Scroll FPS**: During viewport scroll
4. **Selection**: Time to select 1000 chars
5. **Rebuild**: After setState()

### How to Run
```bash
cd benchmark/
flutter run --release benchmark/performance_test.dart
```

Results available in: `benchmark/RESULTS.md`

---

## Conclusion

**Summary Table**:

| Solution | Best For | Avoid If |
|----------|----------|----------|
| **FWFH** | Short docs, custom widgets | Large docs, performance-critical |
| **WebView** | JS required, 100% CSS | Bundle size, native feel matters |
| **super_editor** | Text editing | Read-only content display |
| **HyperRender v2.0** | **Large docs, CJK, performance** | Need JavaScript, full CSS |

**Recommendation**:
- **Migrate to HyperRender** if you have performance issues with FWFH or bundle size issues with WebView
- **Stay with current solution** if it meets your needs and performance is acceptable
- **Use WebView** if you absolutely need JavaScript or pixel-perfect CSS

---

## Appendix: Detailed Feature Matrix (CSV Format)

For import into spreadsheet:

```csv
Category,Feature,FWFH,WebView,HyperRender v2.0
Performance,Parse (10K chars),250ms,400ms,60ms
Performance,Memory (10K),15MB,30MB,5MB
Performance,Scroll FPS,35,55,60
HTML,<p>,Yes,Yes,Yes
HTML,<table>,Yes,Yes,Yes
HTML,<ruby>,No,Yes,Yes
CSS,color,Yes,Yes,Yes
CSS,font-size,Yes,Yes,Yes
Platform,iOS,Yes,Yes,Yes
Platform,Web,Yes,No,Yes
```

Full CSV available at: `COMPARISON_MATRIX.csv` (if needed)

---

*This comparison matrix is maintained by the HyperRender team and updated with each release.*

*Last Updated: 2026-01-18*
*Next Review: 2026-04-01*
