# Supported HTML Elements and CSS Properties

This document lists the HTML elements and CSS properties that hyper_render
renders correctly.  Anything not listed here is either silently unwrapped
(unknown tags) or ignored (unknown CSS properties).

For content that falls outside this subset, use the `fallbackBuilder`
parameter to delegate to a WebView or other renderer — see
[LIMITATIONS.md](LIMITATIONS.md) for guidance.

---

## Block Elements

| Element | Notes |
|---------|-------|
| `<p>` | Paragraph with margin collapse |
| `<div>`, `<section>`, `<article>` | Generic block containers |
| `<header>`, `<footer>`, `<nav>`, `<aside>` | Semantic sections |
| `<h1>`–`<h6>` | Headings with default sizing |
| `<blockquote>` | Indented quotation |
| `<pre>` | Preserves whitespace (`white-space: pre`) |
| `<hr>` | Horizontal rule |
| `<ul>`, `<ol>` | Unordered and ordered lists |
| `<li>` | List items (9 `list-style-type` values) |
| `<dl>`, `<dt>`, `<dd>` | Description lists |
| `<table>`, `<thead>`, `<tbody>`, `<tfoot>` | Table structure |
| `<tr>` | Table row |
| `<th>`, `<td>` | Table cells; `colspan` and `rowspan` supported |
| `<caption>` | Table caption |
| `<details>`, `<summary>` | Collapsible disclosure widget |
| `<figure>`, `<figcaption>` | Figure with caption |

---

## Inline Elements

| Element | Notes |
|---------|-------|
| `<span>` | Generic inline container |
| `<a>` | Links — `href` resolved against `baseUrl`; `onLinkTap` callback |
| `<strong>`, `<b>` | Bold |
| `<em>`, `<i>` | Italic |
| `<u>` | Underline |
| `<s>`, `<del>` | Strikethrough |
| `<ins>`, `<mark>` | Highlight |
| `<code>`, `<kbd>`, `<samp>`, `<var>` | Monospace |
| `<sub>`, `<sup>` | Subscript / superscript (basic positioning) |
| `<small>`, `<q>`, `<cite>`, `<abbr>` | Semantic inline |
| `<time>` | Date/time |
| `<br>` | Line break |
| `<ruby>`, `<rt>`, `<rp>` | CJK ruby annotations (furigana) |

---

## Replaced / Atomic Elements

| Element | Notes |
|---------|-------|
| `<img>` | Lazy-loaded; `alt`, `width`, `height`, aspect ratio |
| `<video>` | Placeholder widget with poster image; no JS playback |
| `<audio>` | Placeholder audio bar |
| `<source>` | Parsed for media attributes |
| `<picture>` | First `<img>` child used |

---

## CSS Properties

### Text

| Property | Support |
|----------|---------|
| `color` | Full — named, hex (#RGB, #RRGGBB, #RGBA, #RRGGBBAA), rgb(), rgba(), hsl() |
| `font-size` | px, em, rem, %, named (small/medium/large/…) |
| `font-weight` | Numeric (100–900) and named |
| `font-style` | normal, italic, oblique |
| `font-family` | System font lookup |
| `line-height` | Unitless, px, em, % |
| `letter-spacing` | px, em |
| `word-spacing` | px, em |
| `text-align` | left, right, center, justify |
| `text-decoration` | underline, line-through, overline, none |
| `text-transform` | uppercase, lowercase, capitalize |
| `white-space` | normal, pre, pre-wrap, nowrap |
| `direction` / `dir` attr | ltr, rtl |

### Box Model

| Property | Support |
|----------|---------|
| `width`, `height` | px, %, em, rem; `auto` |
| `min-width`, `max-width` | px, %, em |
| `margin` | All shorthand forms; `auto` on block elements |
| `padding` | All shorthand forms |
| `border` | `border`, `border-width`, `border-color`, `border-style` |
| `border-radius` | px, % |
| `box-sizing` | border-box, content-box |
| `overflow` | visible, hidden |

### Layout

| Property | Support |
|----------|---------|
| `display` | block, inline, inline-block, none, flex, grid |
| `float` | left, right, none |
| `clear` | left, right, both, none |
| `position` | **relative only** — absolute/fixed not supported |
| Flexbox | `flex-direction`, `justify-content`, `align-items`, `flex-wrap`, `flex`, `flex-grow`, `flex-shrink`, `flex-basis` |
| CSS Grid | `display: grid`, `grid-template-columns`, `grid-template-rows`, `gap`, `grid-column`, `grid-row` |

### Background

| Property | Support |
|----------|---------|
| `background-color` | Full color support |
| `background-image` | `url()` for network/asset images (basic) |
| `background-size` | Not supported |
| `background-position` | Not supported |

### Effects

| Property | Support |
|----------|---------|
| `opacity` | Full (0.0–1.0) |
| `box-shadow` | Not supported |
| `text-shadow` | Not supported |
| `transform` | Not supported |
| `clip-path` | Not supported |

### Advanced

| Property | Support |
|----------|---------|
| CSS Variables (`--prop: value`) | Full — `var()` with fallback |
| `calc()` | px/em/rem arithmetic |
| `!important` | Respected in cascade |
| CSS specificity | Full — inline > id > class > element |
| `@media` queries | Not supported |
| `@keyframes` | Not directly — use `HyperAnimatedWidget` |

---

## HTML Attributes

| Attribute | Elements | Notes |
|-----------|----------|-------|
| `id`, `class` | All | Used for CSS selectors |
| `style` | All | Inline CSS |
| `lang`, `dir` | All | Language and text direction |
| `href` | `<a>` | Absolute or relative (resolved via `baseUrl`) |
| `src`, `alt`, `width`, `height` | `<img>`, `<video>`, `<audio>` | Media attributes |
| `colspan`, `rowspan` | `<td>`, `<th>` | Table spanning |
| `open` | `<details>` | Default expanded state |
| `controls`, `autoplay`, `loop`, `muted`, `poster` | `<video>`, `<audio>` | Media controls |
| `aria-label`, `aria-labelledby` | All | Accessibility labels |
| `role` | All | ARIA role (`button`, `region`, `heading`) |

---

## Unsupported

The following will **not** render correctly in hyper_render.  Use
`fallbackBuilder` to delegate to a WebView when the content requires these:

- `position: absolute` / `position: fixed` — overlapping layouts
- `z-index` — stacking contexts
- `clip-path` — non-rectangular masks
- `@media` queries — responsive breakpoints
- `@keyframes` / CSS animations (use `HyperAnimatedWidget` instead)
- `<canvas>` — requires JavaScript 2D/WebGL
- `<form>`, `<input>`, `<select>`, `<textarea>` — interactive form controls
- `<script>` — JavaScript execution is not supported
- `<iframe>`, `<embed>`, `<object>`, `<applet>` — embedded content

---

*Last updated: 2026-02-26*
