# CSS Properties Support Matrix

Last Updated: February 2026
Version: 1.0.0

This document lists CSS property support in HyperRender.

## Legend

- Full Support: Property is fully implemented and tested
- Partial Support: Some values or edge cases not supported
- Not Supported: Property is not implemented
- Planned: Scheduled for future release

## Known Limitations

| Feature | Status | Notes |
|---------|--------|-------|
| `!important` | ✅ Full Support | Declarations marked `!important` override inline styles per CSS cascade spec. Important rules are collected separately and applied after all other declarations. |

---

## Box Model Properties

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `width` | ✅ | px, %, auto | Full support including constraints |
| `height` | ✅ | px, %, auto | Full support including constraints |
| `min-width` | ✅ | px, % | |
| `max-width` | ✅ | px, % | |
| `min-height` | ✅ | px, % | |
| `max-height` | ✅ | px, % | |
| `margin` | ✅ | px, %, auto | All 4 directions + shorthand |
| `margin-top` | ✅ | px, %, auto | |
| `margin-right` | ✅ | px, %, auto | |
| `margin-bottom` | ✅ | px, %, auto | |
| `margin-left` | ✅ | px, %, auto | |
| `padding` | ✅ | px, % | All 4 directions + shorthand |
| `padding-top` | ✅ | px, % | |
| `padding-right` | ✅ | px, % | |
| `padding-bottom` | ✅ | px, % | |
| `padding-left` | ✅ | px, % | |
| `border` | ✅ | width style color | Full border support |
| `border-width` | ✅ | px | All 4 sides supported |
| `border-style` | ✅ | solid, dashed, dotted, double, none | Custom styles beyond Flutter defaults |
| `border-color` | ✅ | All color formats | |
| `border-radius` | ✅ | px, % | All 4 corners + shorthand |
| `box-sizing` | ⚠️ | border-box | content-box assumed by default |

---

## Display & Layout

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `display` | ✅ | block, inline, inline-block, flex, grid, table, none | |
| `visibility` | ❌ | - | Use `display: none` instead |
| `opacity` | ✅ | 0-1 | |
| `overflow` | ⚠️ | hidden, visible | No scroll support |
| `position` | ⚠️ | static, relative, absolute | Fixed not supported |
| `top` | ⚠️ | px, % | For absolute positioning |
| `right` | ⚠️ | px, % | For absolute positioning |
| `bottom` | ⚠️ | px, % | For absolute positioning |
| `left` | ⚠️ | px, % | For absolute positioning |
| `z-index` | ⚠️ | integer | Basic stacking context |

---

## Flexbox Properties

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `flex-direction` | ✅ | row, column, row-reverse, column-reverse | |
| `flex-wrap` | ✅ | nowrap, wrap, wrap-reverse | |
| `flex` | ✅ | \<grow\> \<shrink\> \<basis\> | Shorthand |
| `flex-grow` | ✅ | number | |
| `flex-shrink` | ✅ | number | |
| `flex-basis` | ✅ | px, %, auto | |
| `justify-content` | ✅ | flex-start, center, flex-end, space-between, space-around | |
| `align-items` | ✅ | flex-start, center, flex-end, stretch, baseline | |
| `align-content` | ✅ | flex-start, center, flex-end, space-between, space-around | |
| `align-self` | ✅ | auto, flex-start, center, flex-end, stretch | |
| `gap` | ✅ | px | Row and column gap |
| `row-gap` | ✅ | px | |
| `column-gap` | ✅ | px | |
| `order` | ⚠️ | integer | Basic support |

---

## Typography

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `color` | ✅ | All CSS colors | hex, rgb, rgba, named colors |
| `font-size` | ✅ | px, em, rem, % | |
| `font-family` | ✅ | Any font name | Falls back to system fonts |
| `font-weight` | ✅ | 100-900, normal, bold | |
| `font-style` | ✅ | normal, italic, oblique | |
| `font-variant` | ⚠️ | small-caps | Limited support |
| `font-variant-numeric` | ✅ | tabular-nums, etc. | |
| `line-height` | ✅ | px, number, % | |
| `letter-spacing` | ✅ | px | |
| `word-spacing` | ✅ | px | |
| `text-align` | ✅ | left, right, center, justify | |
| `text-decoration` | ✅ | none, underline, overline, line-through | |
| `text-decoration-color` | ✅ | All CSS colors | |
| `text-decoration-style` | ✅ | solid, dashed, dotted, double | |
| `text-transform` | ✅ | none, uppercase, lowercase, capitalize | |
| `text-indent` | ✅ | px, % | |
| `text-overflow` | ✅ | clip, ellipsis | |
| `white-space` | ✅ | normal, nowrap, pre, pre-wrap | |
| `word-break` | ✅ | normal, break-all, keep-all | |
| `vertical-align` | ⚠️ | baseline, sub, super | Limited support |
| `text-shadow` | ✅ | Full shadow syntax | Multiple shadows supported |

---

## Float & Clear (Unique Feature!)

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `float` | ✅ | left, right, none | **HyperRender exclusive!** |
| `clear` | ✅ | left, right, both, none | Proper float clearing |

---

## Background

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `background-color` | ✅ | All CSS colors | |
| `background-image` | ❌ | - | Planned for v3.x |
| `background-size` | ❌ | - | Planned for v3.x |
| `background-position` | ❌ | - | Planned for v3.x |
| `background-repeat` | ❌ | - | Planned for v3.x |
| `background` | ⚠️ | color only | Shorthand only for color |

---

## List Styling

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `list-style-type` | ✅ | disc, circle, square, decimal, lower-alpha, upper-alpha, lower-roman, upper-roman, none | 9 types supported |
| `list-style-position` | ✅ | inside, outside | |
| `list-style` | ✅ | Shorthand | |

---

## Table Properties

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `border-collapse` | ✅ | collapse, separate | |
| `border-spacing` | ⚠️ | px | Basic support |
| `table-layout` | ⚠️ | auto, fixed | Content-based algorithm |
| `vertical-align` (in cells) | ✅ | top, middle, bottom | |

---

## Transform & Animation

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `transform` | ⚠️ | translate, scale, rotate | Basic support |
| `transform-origin` | ⚠️ | px, % | Basic support |
| `transition` | ✅ | property duration timing | |
| `transition-property` | ✅ | all, specific properties | |
| `transition-duration` | ✅ | ms, s | |
| `transition-timing-function` | ✅ | ease, linear, ease-in, ease-out | |
| `animation` | ⚠️ | Basic keyframes | Limited support |
| `@keyframes` | ⚠️ | - | Basic support, needs expansion |

---

## Grid Layout

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `display: grid` | ✅ | grid | Supported in v1.0.0 |
| `grid-template-columns` | ✅ | px, fr, auto, repeat(N, size) | Fractional units resolved via LayoutBuilder |
| `grid-template-rows` | ⚠️ | Parsed, auto height per row | Explicit row sizing pending |
| `grid-column` | ✅ | span N, start / end | Auto-placement with span support |
| `grid-row` | ⚠️ | start / end | Basic parsing; explicit row placement pending |
| `gap` / `row-gap` / `column-gap` | ✅ | px | Full support |
| `grid-auto-flow` | ⚠️ | row | Column/dense not yet implemented |
| `justify-items` | ⚠️ | Parsed | Layout pending |
| `align-content` | ⚠️ | Parsed | Layout pending |

---

## CSS Variables & calc()

| Feature | Status | Supported Values | Notes |
|---------|--------|------------------|-------|
| `--custom-property` | ✅ | Any value | Custom properties are inherited along parent chain. |
| `var(--name)` | ✅ | — | Resolved at cascade time with parent-chain lookup |
| `var(--name, fallback)` | ✅ | — | Fallback used when variable not defined |
| `calc()` | ✅ | px, em, rem, unitless | Correct operator precedence (`*`/`/` before `+`/`-`) |
| `calc()` with `var()` | ✅ | — | `var()` resolved first, then arithmetic |

---

## Text Direction & BiDi

| Feature | Status | Notes |
|---------|--------|-------|
| `direction: ltr` | ✅ | Default |
| `direction: rtl` | ✅ | Applied per-fragment in TextPainter. |
| `dir=` HTML attribute | ✅ | Parsed on any element, including `<html dir="rtl">` |
| Bi-directional text mixing | ⚠️ | Relies on Flutter's Unicode BiDi algorithm; complex cases may vary |

---

## SVG

| Feature | Status | Notes |
|---------|--------|-------|
| Inline `<svg>` elements | ✅ | Serialized and rendered as placeholder (flutter_svg integration optional) |
| `<img src="*.svg">` | ⚠️ | Treated as network image; SVG-specific rendering requires flutter_svg |
| SVG width / height attributes | ✅ | Used for intrinsic sizing |

---

## Screenshot / Export

| Feature | Status | Notes |
|---------|--------|-------|
| `captureKey` on HyperViewer | ✅ | Pass a `GlobalKey` to enable capture. |
| `captureKey.toImage()` | ✅ | Returns `ui.Image` at given pixel ratio |
| `captureKey.toPngBytes()` | ✅ | Returns `Uint8List` PNG bytes |

---

## Filters & Effects

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `filter` | ❌ | - | Planned for future |
| `backdrop-filter` | ❌ | - | Planned for future |
| `box-shadow` | ✅ | Full shadow syntax | Multiple shadows supported |
| `text-shadow` | ✅ | Full shadow syntax | Multiple shadows supported |

---

## Other Properties

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `cursor` | ❌ | - | Not applicable in Flutter |
| `user-select` | ✅ | Controlled by `selectable` param | |
| `pointer-events` | ❌ | - | Not applicable |
| `content` | ⚠️ | For pseudo-elements | Limited ::before/::after |

---

## Pseudo-Classes & Pseudo-Elements

| Selector | Status | Notes |
|----------|--------|-------|
| `:hover` | ⚠️ | Limited to link hover |
| `:active` | ⚠️ | Limited to link active |
| `:focus` | ❌ | Not supported |
| `:first-child` | ❌ | Not supported |
| `:last-child` | ❌ | Not supported |
| `:nth-child()` | ❌ | Not supported |
| `::before` | ❌ | Not supported |
| `::after` | ❌ | Not supported |

---

## CSS Selectors Support

| Selector Type | Status | Examples |
|---------------|--------|----------|
| Type selector | ✅ | `p`, `div`, `span` |
| Class selector | ✅ | `.classname` |
| ID selector | ✅ | `#idname` |
| Descendant combinator | ✅ | `div p` |
| Child combinator | ✅ | `div > p` |
| Attribute selector | ⚠️ | `[attr]` (basic) |
| Universal selector | ✅ | `*` |
| Multiple selectors | ✅ | `h1, h2, h3` |
| Specificity calculation | ✅ | Proper CSS cascade |

---

## Measurement Units

| Unit | Status | Notes |
|------|--------|-------|
| `px` | ✅ | Pixels |
| `%` | ✅ | Percentage of parent |
| `em` | ✅ | Relative to font-size |
| `rem` | ✅ | Relative to root font-size |
| `vh` | ❌ | Not supported |
| `vw` | ❌ | Not supported |
| `pt` | ⚠️ | Converted to px |
| `calc()` | ✅ | Arithmetic expressions with px/em/rem/unitless |
| `var()` | ✅ | CSS custom properties (--name) |

---

## Color Formats

| Format | Status | Example |
|--------|--------|---------|
| Named colors | ✅ | `red`, `blue`, `transparent` |
| Hex | ✅ | `#FF5733`, `#F57` |
| RGB | ✅ | `rgb(255, 87, 51)` |
| RGBA | ✅ | `rgba(255, 87, 51, 0.5)` |
| HSL | ⚠️ | Converted to RGB |
| HSLA | ⚠️ | Converted to RGBA |

---

## Notes

### Unique Features
- CSS Float Layout: HyperRender is the only Flutter HTML library with proper float/clear support
- Kinsoku Line-Breaking: Professional CJK typography rules
- Ruby Annotations: Furigana rendering for Japanese
- CSS Grid: fr-unit layout with repeat() and column-span support
- CSS Variables: `--custom-property` / `var()` with full inheritance chain
- CSS calc(): arithmetic expressions with correct operator precedence
- RTL/BiDi: per-fragment text direction from `direction` property or `dir=` attribute
- Screenshot export: `GlobalKey.toPngBytes()` via `HyperCaptureExtension`
- DevTools extension: UDT tree inspector at `packages/hyper_render_devtools/`

### Performance Considerations
- CSS rule matching uses indexed lookup for better performance
- Style resolution cached during layout
- Computed styles memoized per node
- TextPainter cache uses 9-tuple composite key (no XOR collisions)
- Image loading uses priority queue (viewport-first)
- Incremental layout with dirty checking

### Roadmap
- **v3.x**: Background images, Gradient backgrounds, CSS filters
- **v4.0**: Pseudo-elements (::before, ::after), More pseudo-classes, `vh`/`vw` units

---

## Testing Your CSS

Use the comparison demo to test CSS properties:

```dart
HyperViewer(
  html: '''
    <div style="
      display: flex;
      flex-direction: row;
      justify-content: space-between;
      padding: 16px;
      background-color: #f5f5f5;
      border-radius: 8px;
    ">
      <span style="color: #1976D2; font-weight: bold;">Test</span>
    </div>
  ''',
)
```

---

## Contributing

Found a CSS property that's not working? Please report:
1. Property name
2. Expected behavior
3. Actual behavior
4. Minimal reproduction HTML

File an issue at: https://github.com/your-repo/hyper_render/issues
