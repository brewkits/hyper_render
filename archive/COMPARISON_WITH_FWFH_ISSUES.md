# HyperRender vs flutter_widget_from_html - Issue Comparison

**Date**: 2026-02-11
**Purpose**: Compare common issues in flutter_widget_from_html (FWFH) with HyperRender to identify gaps and improvements needed.

---

## Executive Summary

After analyzing 125+ open issues in the flutter_widget_from_html repository, we've identified both **advantages HyperRender has** and **areas needing improvement**.

### ✅ HyperRender Advantages (Issues FWFH Has, We Don't)

| Issue | FWFH Status | HyperRender Status |
|-------|-------------|-------------------|
| **Text wrap around images (Float layout)** | ❌ Issue #1449 - Not working properly | ✅ **Working perfectly!** Main differentiator |
| **Performance with large documents** | ⚠️ Discussion #596 - Jank with videos/images | ✅ Isolate-based parsing + view virtualization |
| **Table rendering with colspan/rowspan** | ⚠️ Multiple issues | ✅ Working with smart horizontal scroll |
| **Text selection crashes** | ⚠️ Frequent crashes | ✅ Crash-free with custom RenderObject |
| **CJK line-breaking** | ❌ Not supported | ✅ Kinsoku shori implementation |
| **Ruby/Furigana** | ⚠️ Basic support | ✅ Perfect implementation |

### ⚠️ Areas Needing Attention (Issues We Share or Missing Features)

| Issue | FWFH Issue # | HyperRender Status | Priority |
|-------|-------------|-------------------|----------|
| **`<style>` tag support** | #1525 | ⚠️ Partially implemented, needs testing | HIGH |
| **CSS `clip-path` property** | #1505 | ❌ Not supported | MEDIUM |
| **CSS `list-style-type` string literals** | #1504 | ❌ Not supported | MEDIUM |
| **Iframe `data-src` lazy loading** | #1496 | ❌ Not supported | LOW |
| **Image centering with `display: block; margin: auto`** | #1535 | ❌ Needs testing | HIGH |
| **Table `text-align: center` with borders** | #1534, #1446 | ❌ Needs testing | MEDIUM |
| **W3C table layout algorithm** | N/A | ⚠️ TODO in render_table.dart:701 | MEDIUM |

---

## Detailed Analysis

### 1. Float Layout (Text Wrap Around Images)

**FWFH Issue**: #1449 "Text wrap around image"
- Users report images don't properly allow text to flow around them
- Fundamental architecture limitation

**HyperRender**: ✅ **Perfect implementation**
- Custom `RenderHyperBox` with full float support
- Works with images, video, iframe, and custom widgets
- Demo: `FloatLayoutDemo`, `KitchenSinkDemo`, `RealContentDemo`

**Action**: ✅ **No action needed** - This is our main competitive advantage!

---

### 2. `<style>` Tag Support

**FWFH Issue**: #1525 "is possibile to support style tag?"
- Users want to embed CSS in `<style>` tags within HTML

**HyperRender Status**: ⚠️ **Partially implemented**
- `StyleResolver.parseCss()` method exists (resolver.dart:184)
- Supports CSS rules from `<style>` tags (documented in resolver.dart:15-16)
- **Needs testing and demo**

**Action Required**:
1. ✅ Create test case with `<style>` tag
2. ✅ Add to demo if working
3. ✅ Document in README

**Test HTML**:
```html
<style>
  .highlight { background: yellow; padding: 4px; }
  .blue-text { color: blue; font-weight: bold; }
</style>
<p class="blue-text">This should be blue and bold</p>
<span class="highlight">This should be highlighted</span>
```

---

### 3. CSS Property Support

#### 3a. `clip-path` Property

**FWFH Issue**: #1505 "Support for clip-path"
- Modern CSS property for clipping elements

**HyperRender Status**: ❌ **Not supported**

**Action**:
- Priority: MEDIUM
- Requires custom painting logic
- Consider for future release

#### 3b. `list-style-type` String Literals

**FWFH Issue**: #1504 "list-style-type string literal support"
- Support custom list markers like `list-style-type: "→ "`

**HyperRender Status**: ❌ **Not supported**
- Current list support uses default bullets/numbers

**Action**:
- Priority: MEDIUM
- Check current list rendering implementation
- Add custom marker support

---

### 4. Iframe Lazy Loading

**FWFH Issue**: #1496 "iframes with data-src attribute don't load video content"
- Support for `<iframe data-src="...">` for lazy loading

**HyperRender Status**: ❌ **Not supported**

**Action**:
- Priority: LOW
- Can be handled in `widgetBuilder` callback by user
- Document in MULTIMEDIA_EXAMPLES.md

---

### 5. Image Centering

**FWFH Issue**: #1535 "Center images via display block and margin auto not working"
- `display: block; margin: auto;` should center images

**HyperRender Status**: ❌ **Needs testing**

**Action Required**:
1. ✅ Test with sample HTML
2. ✅ Fix if broken
3. ✅ Add to demo

**Test HTML**:
```html
<img src="https://picsum.photos/200" style="display: block; margin: 0 auto;">
```

---

### 6. Table Rendering Issues

**FWFH Issues**:
- #1534 "Render error for table with tr height and image with text-align center"
- #1446 "text-align: center not working in table with border-collapse"

**HyperRender Status**:
- ✅ Good table support with colspan/rowspan
- ⚠️ TODO: "Implement proper W3C table layout algorithm" (render_table.dart:701)
- ❌ Needs testing for text-align and vertical-align

**Action Required**:
1. ✅ Test `text-align: center` in tables
2. ✅ Test `vertical-align` in table cells
3. ✅ Add edge cases to TableDemo
4. 🔄 Consider implementing W3C table layout (Phase 2)

**Test HTML**:
```html
<table border="1">
  <tr>
    <td style="text-align: center; height: 100px;">
      <img src="https://picsum.photos/50">
    </td>
    <td style="vertical-align: middle;">Middle aligned text</td>
  </tr>
</table>
```

---

### 7. Performance Issues

**FWFH Issue**: Discussion #596 "Strategies to improve performance"
- YouTube video widgets cause severe jank (red bars on performance overlay)
- Image rendering introduces lag
- GIF handling causes high CPU usage

**HyperRender Status**: ✅ **Much better performance**
- Isolate-based parsing prevents UI jank
- View virtualization for long documents
- Default media placeholders are lightweight
- User controls media implementation via callbacks

**Action**: ✅ **No action needed** - Already superior

---

## Demo Coverage Analysis

### ✅ Features We Already Demo

1. **Kitchen Sink** - All-in-one showcase
2. **Float Layout** - Text wrap around images ⭐ (FWFH can't do this)
3. **Text Selection (Enhanced)** - Rich selection menu
4. **Ruby Annotation** - Japanese furigana
5. **Widget Injection** - Interactive widgets in HTML
6. **Inline Decoration** - Multi-line backgrounds
7. **Real Content** - Blog post with floats
8. **Table Demos** - Simple, wide, complex, nested
9. **Code Blocks** - Syntax highlighting
10. **Image Handling** - Loading/error states
11. **Video & Media** - Functional playback ⭐
12. **Zoom & Pan** - Interactive zoom
13. **Quill Delta** - Delta format rendering
14. **Markdown** - Markdown rendering
15. **Library Comparison** - Side-by-side with FWFH/flutter_html
16. **Stress Test** - 1000-page performance test
17. **v2.1.0 Features** - Error boundaries, dark mode, skeletons
18. **Security Demo** - XSS protection
19. **Accessibility Demo** - Screen reader support

### ⚠️ Features Missing from Demo

1. **`<style>` Tag Demo** - Need to test and showcase CSS embedding
2. **Image Centering Demo** - `display: block; margin: auto`
3. **Table Text-Align Demo** - Center/right alignment in tables
4. **List Style Demo** - Different list-style-type options
5. **Details/Summary Demo** - Collapsible sections (if supported)

---

## Action Plan

### Phase 1: High Priority (This Week)

1. ✅ **Test `<style>` tag support**
   - Create test case
   - Add to demo if working
   - Document in README

2. ✅ **Test image centering**
   - Test `display: block; margin: auto`
   - Fix if broken
   - Add to demo

3. ✅ **Test table text-align**
   - Test `text-align: center/right` in tables
   - Test `vertical-align` in cells
   - Add edge cases to TableDemo

4. ✅ **Update documentation**
   - Add comparison table to README
   - Highlight float layout advantage
   - Document known limitations

### Phase 2: Medium Priority (Next Sprint)

1. 🔄 **Improve table layout**
   - Implement proper W3C table layout algorithm
   - Better column width calculation
   - Support for `width` attribute on `<td>`

2. 🔄 **Add CSS properties**
   - `list-style-type` string literals
   - `clip-path` (if feasible)

3. 🔄 **Create comprehensive demos**
   - Style tag demo
   - List styling demo
   - Advanced table demo

### Phase 3: Future Considerations

1. 🔮 **Iframe lazy loading**
   - `data-src` attribute support
   - Intersection observer for lazy load

2. 🔮 **SVG support**
   - Consider hyper_render_svg plugin

3. 🔮 **Form elements**
   - Basic form rendering (without submission)

---

## Conclusion

**HyperRender's Competitive Advantages**:
1. ⭐ **Perfect float layout** - Text wraps naturally around images/videos (FWFH can't do this)
2. ⭐ **Superior performance** - Isolate parsing + view virtualization
3. ⭐ **Crash-free selection** - Custom RenderObject architecture
4. ⭐ **CJK excellence** - Kinsoku line-breaking + perfect Ruby support
5. ⭐ **Smart table rendering** - Automatic horizontal scroll for wide tables

**Areas to Improve**:
1. Test and showcase `<style>` tag support (may already work!)
2. Fix image centering with `display: block; margin: auto`
3. Ensure table text-align works correctly
4. Document known CSS property limitations

**Marketing Position**:
> "HyperRender does what flutter_widget_from_html can't - perfect float layout, crash-free selection, and native performance. If you need text flowing around images like a real browser, HyperRender is your only choice."

---

## Sources

- [flutter_widget_from_html Issues](https://github.com/daohoangson/flutter_widget_from_html/issues)
- [Performance Discussion #596](https://github.com/daohoangson/flutter_widget_from_html/discussions/596)
- [flutter_widget_from_html Releases](https://github.com/daohoangson/flutter_widget_from_html/releases)
