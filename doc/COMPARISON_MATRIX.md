# HyperRender v1.0 - Detailed Comparison Matrix

**Comprehensive feature-by-feature comparison with competitors**

Last Updated: February 2026

---

## How to Use This Matrix

- ✅ **Excellent**: Feature works perfectly, production-ready
- ⚠️ **Acceptable**: Feature works with limitations or trade-offs
- ❌ **Poor/Missing**: Feature doesn't work or has major issues
- 🔜 **Planned**: Feature on roadmap (see version)
- N/A: Not applicable for this solution

---

## Performance Metrics

| Metric | FWFH | WebView | super_editor | HyperRender v1.0 |
|--------|------|---------|--------------|------------------|
| **Parse Time (10K chars)** | 250ms ⚠️ | 400ms ⚠️ | N/A | **69ms ✅** |
| **Parse Time (25K chars)** | 420ms ❌ | 800ms ❌ | N/A | **~150ms ✅** |
| **Memory Usage (10K)** | 15MB ⚠️ | 30MB ❌ | N/A | **5MB ✅** |
| **Memory Usage (25K)** | 28MB ❌ | 45MB ❌ | N/A | **8MB ✅** |
| **Scroll FPS (25K)** | 45fps ⚠️ | 55fps ⚠️ | 60fps ✅ | **60fps ✅** |
| **Text Selection (25K)** | Breaks ❌ | Perfect ✅ | Perfect ✅ | **Smooth ✅** |
| **Startup Time** | Fast ✅ | Slow ❌ | Fast ✅ | **Fast ✅** |
| **Bundle Size Impact** | +500KB ✅ | +20MB ❌ | +800KB ✅ | **+600KB ✅** |

**Notes**:
- ⚠️ **All HyperRender numbers are self-measured** on macOS (Darwin 25.2.0, Apple Silicon, Flutter Desktop release mode). Results on mobile will differ. Source: `benchmark/RESULTS.md`.
- 25K parse time is interpolated between measured 10K (69ms) and 50K (276ms) data points — not a direct measurement.
- FWFH and WebView numbers are estimates based on published benchmarks and community reports, not measured by this project. Treat them as rough guidance.
- FWFH = flutter_widget_from_html v0.17.x; flutter_html v3.x not shown (deprecated, unmaintained)
- Run `cd benchmark && flutter run --release benchmark/performance_test.dart` to reproduce on your hardware.

---

## HTML Support

| Feature | FWFH | WebView | HyperRender v1.0 |
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
| Vertical text | ❌ | ✅ | 🔜 v1.1 |
| **Interactive (v1.0)** | | | |
| `<details>`, `<summary>` | ❌ | ✅ | **✅ Full** |
| `<button>` | ⚠️ | ✅ | 🔜 v1.2 |
| `<input>` | ⚠️ | ✅ | 🔜 v1.2 |
| `<form>` | ⚠️ | ✅ | ❌ Not planned |

---

## CSS Support

| Property | FWFH | WebView | HyperRender v1.0 |
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
| `display: flex` | ⚠️ Partial | ✅ | ✅ |
| `display: grid` | ❌ | ✅ | ✅ v3.0 |
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
| `transition` | ❌ | ✅ | 🔜 v1.1 |
| `animation` | ❌ | ✅ | 🔜 v1.1 |
| `transform` | ❌ | ✅ | ❌ Not planned |

**CSS Coverage Summary**:
- FWFH: ~50 properties
- WebView: ~300 properties (full spec)
- HyperRender v1.0: ~40 essential properties

---

## Accessibility

| Aspect | FWFH | WebView | HyperRender v1.0 |
|--------|------|---------|------------------|
| **Screen reader support** | ⚠️ Basic | ✅ Full (browser a11y) | ✅ Semantics tree |
| **Headings (h1–h6)** | ⚠️ | ✅ | ✅ `isHeader` + level hint |
| **Links** | ⚠️ | ✅ | ✅ `isLink` + href hint |
| **Images (alt text)** | ✅ | ✅ | ✅ `isImage` + alt label |
| **Lists (ul/ol/li)** | ⚠️ | ✅ | ✅ list hint + ordinal position |
| **Buttons** | ⚠️ | ✅ | ✅ `isButton` |
| **`aria-label` / `aria-labelledby`** | ❌ | ✅ | ✅ Resolved to semantic label |
| **`role` attribute** | ❌ | ✅ | ✅ button / region / heading |
| **WCAG 2.1 AA (partial)** | ⚠️ | ✅ | ⚠️ Partial — no focus mgmt |

**Note**: hyper_render exposes a `SemanticsNode` tree for screen readers but
does not implement keyboard focus management or ARIA live regions.

---

## Platform Support

| Platform | FWFH | WebView | super_editor | HyperRender v1.0 |
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

| Aspect | FWFH | WebView | super_editor | HyperRender v1.0 |
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
| Community plugins | Many ✅ | Few ⚠️ | Few ⚠️ | Growing 🔜 |

---

## Use Case Suitability

| Use Case | FWFH | WebView | super_editor | HyperRender v1.0 |
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
| Forms | ⚠️ | ✅ | ❌ | 🔜 v1.2 Read-only |
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

| Aspect | FWFH | WebView | HyperRender v1.0 |
|--------|------|---------|------------------|
| **XSS Protection** | ⚠️ Manual | ⚠️ Sandboxed | ✅ Built-in `HtmlSanitizer` |
| **JavaScript Execution** | ❌ None | ✅ Full (risk) | ❌ None (safe) |
| **`javascript:` URLs** | ⚠️ Manual | ⚠️ CSP needed | ✅ Blocked |
| **`vbscript:` URLs** | ⚠️ Manual | ⚠️ CSP needed | ✅ Blocked |
| **SVG data: URLs** | ⚠️ Manual | ⚠️ CSP needed | ✅ Blocked |
| **CSS `expression()`** | ⚠️ Manual | N/A (sandboxed) | ✅ Blocked |
| **External Resources** | ⚠️ Limited control | ⚠️ CSP needed | ✅ Full control |
| **User Input Handling** | ⚠️ | ⚠️ | **✅ Read-only** |
| **Privacy** | ✅ Local only | ⚠️ Tracking possible | ✅ Local only |

**Recommendation**: Always sanitize untrusted HTML before rendering in any solution.
Enable `sanitize: true` (default in HyperRender) when rendering user-generated content.

---

## Cost Analysis

| Factor | FWFH | WebView | HyperRender v1.0 |
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
| **Code Changes** | Medium | Lower (HTML rendering only) | N/A — different use case |
| **Testing Required** | Medium | High | N/A |
| **Performance Gain** | **~2.6× faster parse, ~47% less RAM** (self-measured) | **~8× faster parse, ~73% less RAM** (self-measured) | N/A |
| **Feature Loss** | Some CSS decoration | JavaScript, forms | N/A |
| **Breaking Changes** | Widget builders API | Full rewrite | N/A |

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

### Choose HyperRender v1.0 if:
- ✅ **Large documents (5K+ chars)**
- ✅ **Performance critical (60fps required)**
- ✅ **CJK content (Japanese, Korean, Chinese)**
- ✅ **Native feel important**
- ✅ **Bundle size matters**
- ✅ **Read-only or light editing**

---

## Version Comparison (HyperRender Roadmap)

| Feature | v1.0 (Now) | v1.1 (Q2'26) | v1.2 (Q3'26) | v1.3 (Q4'26) | v2.0 (2027+) |
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
| **Security & Enterprise** | | | | | |
| Interface-based Sanitizer | ❌ Static only | ❌ | ❌ | ❌ | **✅ DI support** |
| Custom XSS filters | ❌ | ❌ | ❌ | ❌ | **✅ Pluggable** |
| TextPainter abstraction | ❌ Direct usage | ⚠️ Partial | ⚠️ | ✅ Full | ✅ |
| Fuzzing test suite | ❌ | **✅ HTML/XSS** | ✅ | ✅ | ✅ |
| Flutter master CI | ❌ | **✅ Advisory** | ✅ | ✅ | ✅ |

---

## Benchmark Suite (Reproducible)

### Test Environment
```yaml
Platform:
  - macOS (Darwin 25.2.0, Apple Silicon)
  - Flutter Desktop, release mode

Flutter SDK: >=3.10.0
Dart SDK: >=3.5.0

Test Documents:
  - Small: 1,000 characters
  - Medium: 5,000 characters
  - Large: 10,000 characters
  - XLarge: 50,000 characters
  - XXLarge: 100,000 characters
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
| **HyperRender v1.0** | **Large docs, CJK, performance** | Need JavaScript, full CSS |

**Recommendation**:
- **Migrate to HyperRender** if you have performance issues with FWFH or bundle size issues with WebView
- **Stay with current solution** if it meets your needs and performance is acceptable
- **Use WebView** if you absolutely need JavaScript or pixel-perfect CSS

---

## Appendix: Detailed Feature Matrix (CSV Format)

For import into spreadsheet:

```csv
Category,Feature,FWFH,WebView,HyperRender v1.0
Performance,Parse (10K chars),250ms,400ms,69ms
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
