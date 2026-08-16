# HyperRender - Detailed Comparison Matrix

**Feature-by-feature comparison with other libraries**

Last Updated: July 2026 (v1.5.x + unreleased `fix/bugfix-refactor`)

---

## How to Use This Matrix

- ✅ **Excellent**: Feature works perfectly, production-ready
- ⚠️ **Acceptable**: Feature works with limitations or trade-offs
- ❌ **Poor/Missing**: Feature doesn't work or has major issues
- 🔜 **Planned**: Feature on roadmap (see version)
- N/A: Not applicable for this solution

---

## Performance Metrics

> **Read this before quoting any number below.** We publish only measurements
> that anyone can reproduce with a command in this repo, on the environment we
> actually measured. We do **not** publish performance numbers for other
> libraries: we have no reproducible harness for them, and an unverified
> competitor benchmark is marketing, not data. If you need a comparison,
> measure both on *your* content and *your* target devices — that is the only
> number that should drive your decision.

### HyperRender parse throughput — reproducible

`flutter test benchmark/parse_benchmark.dart --reporter expanded`

| Document size | Median | Avg | P95 |
|---|---|---|---|
| 1 KB | 18 ms | 16.8 ms | 24 ms |
| 10 KB | 19 ms | 19.6 ms | 25 ms |
| 50 KB | 33 ms | 33.2 ms | 42 ms |
| 100 KB | 45 ms | 46.8 ms | 54 ms |
| Complex (tables, lists, styles) | 42 ms | 42.8 ms | 52 ms |

**Environment for the numbers above:** macOS (Apple Silicon), Flutter 3.41.9,
headless `flutter test` (debug/JIT). Measured 2026-07-21.

### Known caveat — these are debug-mode numbers

Flutter debug/JIT is substantially slower than release/AOT on device. Treat the
table above as a **relative regression signal**, not as the performance your
users will see. It is neither an upper nor a lower bound for release builds.

### Layout budget status — currently not met in our own harness

`flutter test benchmark/layout_regression.dart --reporter expanded`

The layout fixtures assert a 16 ms/frame (60 FPS) budget. In the environment
above, 3 of 6 fixtures currently exceed their budget (`simple_paragraph`,
`table_20_rows`, `large_article` — the last two are the heaviest fixtures).
We publish this rather than hide it. Two things are true and neither is proven:
debug-mode overhead may account for it, or there is real headroom to reclaim in
`_performLineLayout`. Until it is measured in release mode on device, **we do
not claim a verified 60 FPS figure.**

### What we do claim, and why

Text selection remains stable on large documents because the whole document is
one `RenderObject` with a single hit-test tree, rather than one widget per
element. That is an architectural property you can inspect in the source — it
does not depend on a benchmark number.

---

## HTML Support

| Feature | FWFH | WebView | HyperRender |
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
| Vertical text | ❌ | ✅ | 🔜 Planned |
| **Interactive** | | | |
| `<details>`, `<summary>` | ❌ | ✅ | **✅ Full** |
| `<button>` | ⚠️ | ✅ | 🔜 Planned |
| `<input>` | ⚠️ | ✅ | 🔜 Planned |
| `<form>` | ⚠️ | ✅ | ❌ Not planned |

---

## CSS Support

### Verified against competitor source (2026-07-21)

The numbers here come from reading the competitors' own parsers, not from our
impressions — they are reproducible by anyone.

| Measure | HyperRender | flutter_html v3.0.0 |
|---|---|---|
| CSS declarations handled by the parser | **189** | **51** |
| `float` / `clear` | Supported for images and sized boxes (not text-sized blocks — see LIMITATIONS.md) | Not present in `css_parser.dart` |
| Flexbox (`display:flex` + children) | Supported | Not present |
| CSS Grid | Supported | Not present |
| `@keyframes` / `animation` / `transition` | Supported | Not present |
| `transform`, `opacity`, `filter`, `box-shadow` | Supported | Not present |
| `background-image` / gradients | Supported | Not present |

*Method: `grep -oE "case '[a-z-]+':"` over each project's CSS parser
(`packages/hyper_render_core/lib/src/style/resolver.dart` vs
flutter_html's `lib/src/css_parser.dart` @ master), de-duplicated, with CSS
*values* filtered out so only property names are counted.*

### The "CSS float" claim, checked

We claim to be the only Flutter HTML renderer with CSS float layout. Evidence:

- **flutter_html** — no `float` handling anywhere in `css_parser.dart`.
- **flutter_widget_from_html** — a GitHub code search for `float` across the
  repository returns exactly one Dart hit, and it is *input HTML inside a test
  fixture*, not an implementation.

We consider the claim supported for these two libraries, which together account
for the overwhelming majority of the category. We have **not** audited every
package on pub.dev, so read it as "no other mainstream Flutter HTML renderer
implements float", not as a proof of universal uniqueness.

### What neither library supports

These are frequently assumed to be HyperRender-specific gaps. They are not —
they are category-wide limitations of native (non-WebView) HTML rendering:

| Property | HyperRender | flutter_html |
|---|---|---|
| `position: absolute/fixed` | No (architectural) | No — open feature request [#1366](https://github.com/Sub6Resources/flutter_html/issues/1366) |
| `z-index` | No (architectural) | No — open feature request [#1482](https://github.com/Sub6Resources/flutter_html/issues/1482) |
| `@media` queries | No (ignored safely) | No — open bug [#1060](https://github.com/Sub6Resources/flutter_html/issues/1060): *crashes the UI* |
| `columns` / `column-width` | No | No — open feature request [#508](https://github.com/Sub6Resources/flutter_html/issues/508) |

If your content genuinely depends on absolute positioning or stacking contexts,
a `WebView` is the honest answer — not this library, and not flutter_html.

---

### Full property matrix (FWFH column not independently verified)

> The `FWFH` and `WebView` columns below were compiled from documentation and
> hands-on impressions, not from a reproducible harness. Verify anything you
> intend to rely on. The HyperRender column is authoritative and kept in sync
> with `CSS_PROPERTIES_MATRIX.md`.

| Property | FWFH | WebView | HyperRender |
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
| `text-align` | ✅ | ✅ | ✅ (incl. `justify` + RTL override) |
| `text-indent` | ⚠️ | ✅ | ✅ px + % |
| `text-decoration` | ✅ | ✅ | ✅ |
| `text-transform` | ⚠️ | ✅ | ✅ |
| `white-space` | ⚠️ | ✅ | ✅ |
| **Box Model** | | | |
| `width`, `height` | ✅ | ✅ | ✅ `width`; `height` on replaced elements only |
| `min-width`, `max-width` | ⚠️ | ✅ | ✅ px + % |
| `margin` | ✅ | ✅ | ✅ |
| `padding` | ✅ | ✅ | ✅ |
| `border` | ✅ | ✅ | ✅ |
| `border-radius` | ⚠️ | ✅ | ✅ |
| `border-collapse` / `border-spacing` | ? (not verified) | ✅ | ✅ (separate + spacing) |
| **Layout** | | | |
| `display` (block/inline) | ✅ | ✅ | ✅ |
| `display: none` | ✅ | ✅ | ✅ |
| `display: flex` | ⚠️ Partial | ✅ | ✅ |
| `display: grid` | ❌ | ✅ | ✅ |
| `float` | ⚠️ Basic | ✅ | ⚠️ images + sized boxes |
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
| `transition` | ❌ | ✅ | ✅ (widget-tier; v1.4) |
| `animation` / `@keyframes` | ❌ | ✅ | ✅ (incl. cubic-bezier/steps timing; v1.5) |
| `transform` | ❌ | ✅ | ✅ (translate/scale/rotate) |

**CSS Coverage Summary** (declaration handlers counted from each project's own
CSS parser — see the "Verified against competitor source" section above):
- FWFH: ~50 properties
- flutter_html v3.0.0: 51 properties
- WebView: ~300 properties (full spec)
- HyperRender: **189 properties**

---

## Accessibility

| Aspect | FWFH | WebView | HyperRender |
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

| Platform | FWFH | WebView | super_editor | HyperRender |
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

| Aspect | FWFH | WebView | super_editor | HyperRender |
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

| Use Case | FWFH | WebView | super_editor | HyperRender |
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

| Aspect | FWFH | WebView | HyperRender |
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

| Factor | FWFH | WebView | HyperRender |
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
| **Performance Gain** | Not independently benchmarked — measure on your own content/devices (see Performance Metrics note above) | Not independently benchmarked | N/A |
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

### Choose HyperRender if:
- ✅ **Large documents (5K+ chars)** — single-RenderObject selection stays stable
- ✅ **CJK content (Japanese, Korean, Chinese)** — Ruby + Kinsoku shori
- ✅ **CSS `float` layouts** — text wraps around floated images; the only native Flutter renderer that does
- ✅ **Web/WASM target** — builds with `--wasm` (FWFH does not, see #1528)
- ✅ **Flutter 3.41+** — unaffected by the crash that hits flutter_html
- ✅ **Native feel + bundle size matter**
- ✅ **Read-only or light editing**

---

## Version Comparison (HyperRender Roadmap)

| Feature | v1.0 | v1.1 | v1.2 | v1.3 (Stable) | v2.0 (Planned) |
|---------|-----------|--------------|--------------|--------------|--------------|
| Single-RenderObject paradigm | ✅ | ✅ | ✅ | ✅ | ✅ |
| Stable selection on large docs | ✅ | ✅ | ✅ | ✅ | ✅ |
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
Measured environment (the parse-throughput table above):
  - macOS (Apple Silicon), headless `flutter test` (debug/JIT)
  - Flutter 3.41.9

Test Documents:
  - Small: 1,000 characters
  - Medium: 5,000 characters
  - Large: 10,000 characters
  - XLarge: 25,000 characters
```

> Release-mode / on-device numbers are not yet published — the figures above are
> debug/JIT and should be read as a relative regression signal only.

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
| **HyperRender** | **Large docs, CJK, performance** | Need JavaScript, full CSS |

**Recommendation**:
- **Migrate to HyperRender** if you have performance issues with FWFH or bundle size issues with WebView
- **Stay with current solution** if it meets your needs and performance is acceptable
- **Use WebView** if you absolutely need JavaScript or pixel-perfect CSS

---

## Appendix: Detailed Feature Matrix (CSV Format)

For import into spreadsheet:

```csv
Category,Feature,FWFH,WebView,HyperRender
HTML,<p>,Yes,Yes,Yes
HTML,<table>,Yes,Yes,Yes
HTML,<ruby>,No,Yes,Yes
CSS,color,Yes,Yes,Yes
CSS,font-size,Yes,Yes,Yes
CSS,float,No,Yes,Yes
Platform,iOS,Yes,Yes,Yes
Platform,Web,Yes,No,Yes
Platform,Web (WASM),No,No,Yes
```

> Performance columns are intentionally omitted here — we do not publish
> unverified competitor numbers. See the Performance Metrics section for the
> reproducible HyperRender figures and how to benchmark the alternatives
> yourself.

Full CSV available at: `COMPARISON_MATRIX.csv` (if needed)

---

*This comparison matrix is maintained by the HyperRender team and updated with each release.*

*Last Updated: 2026-07-22*
*Next Review: 2026-10-01*
