# CSS Properties Support Matrix

Last Updated: March 30, 2026
Version: 1.2.0

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
| `box-sizing` | ✅ | border-box, content-box | Full support |

---

## Display & Layout

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `display` | ✅ | block, inline, inline-block, flex, grid, table, none | |
| `visibility` | ❌ | - | Use `display: none` instead |
| `opacity` | ✅ | 0-1 | |
| `overflow` | ⚠️ | hidden, visible | No scroll support |
| `position: static` | ✅ | static | Default |
| `position: relative` | ✅ | relative | Supported |
| `position: absolute` | ❌ | — | Use `pluginRegistry` for overlay widgets |
| `position: fixed` | ❌ | — | Use `pluginRegistry` for overlay widgets |
| `top` / `right` / `bottom` / `left` | ❌ | — | Requires absolute/fixed; not supported |
| `z-index` | ❌ | — | Stacking contexts not implemented |

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

## Grid Layout

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `display: grid` | ✅ | grid | Supported in v1.2.0 |
| `grid-template-columns` | ✅ | px, fr, auto, repeat(N, size) | Fractional units resolved via LayoutBuilder |
| `grid-template-rows` | ✅ | px, fr, auto | Supported in v1.2.0 |
| `grid-column` | ✅ | span N, start / end | Auto-placement with span support |
| `grid-row` | ✅ | span N, start / end | |
| `gap` / `row-gap` / `column-gap` | ✅ | px | Full support |
| `grid-auto-flow` | ⚠️ | row | Column/dense not yet implemented |
| `justify-items` | ✅ | flex-start, center, flex-end, stretch | |
| `align-content` | ✅ | flex-start, center, flex-end, stretch | |

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
| `text-shadow` | ✅ | x y blur color | Multiple shadows supported in v1.2.0 |

---

## Float & Clear

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `float` | ✅ | left, right, none | Proper float wrapping around text |
| `clear` | ✅ | left, right, both, none | Proper float clearing |

---

## Background & Effects

| Property | Status | Supported Values | Notes |
|----------|--------|------------------|-------|
| `background-color` | ✅ | All CSS colors | |
| `background-image` | ✅ | url(), linear-gradient() | Network/asset images + linear gradients |
| `background-size` | ✅ | cover, contain, fill | |
| `background-position` | ❌ | — | Not supported |
| `background-repeat` | ❌ | — | Not supported |
| `box-shadow` | ✅ | x y blur spread color | Full box-shadow support in v1.2.0 |
| `filter` | ✅ | blur, brightness, contrast | Native image processing effects |
| `backdrop-filter` | ✅ | blur | Glassmorphism support |

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
| `transform` | ❌ | — | Use Flutter's `Transform` widget via `pluginRegistry` |
| `transform-origin` | ❌ | — | Not supported |
| `transition` | ❌ | — | Planned v4.0 |
| `animation` | ✅ | name duration timing | Requires `@keyframes` in style tags |
| `@keyframes` | ✅ | from/to, % | Parsed from `<style>` tags automatically |

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

---

## Measurement Units

| Unit | Status | Notes |
|------|--------|-------|
| `px` | ✅ | Pixels |
| `%` | ✅ | Percentage of parent |
| `em` | ✅ | Relative to font-size |
| `rem` | ✅ | Relative to root font-size |
| `vh` / `vw` | ❌ | Not supported |
| `calc()` | ✅ | Arithmetic expressions |
| `var()` | ✅ | CSS custom properties |

---

## Notes

### Unique Features
- CSS Float Layout: Proper float/clear support around text
- Kinsoku Line-Breaking: Professional CJK typography rules
- Ruby Annotations: Furigana rendering for Japanese
- CSS Grid: fr-unit layout with repeat() support
- CSS Variables: `--custom-property` / `var()` with full inheritance chain
- CSS calc(): arithmetic expressions with correct operator precedence
- RTL/BiDi: per-fragment text direction support
- Screenshot export: `GlobalKey.toPngBytes()` support
- DevTools extension: UDT tree inspector
- Plugin API (v1.2.0): Extend tags via custom Flutter widgets

### Roadmap
- **v3.x**: Better pseudo-element support (::before/::after)
- **v4.0**: Transitions, Transform support, `vh`/`vw` units

---

*Last updated: March 30, 2026 — HyperRender v1.2.0*
