# Supported HTML Elements and CSS Properties

This document lists the HTML elements and CSS properties that hyper_render
renders correctly. Anything not listed here is either silently unwrapped
(unknown tags) or ignored (unknown CSS properties).

For content that falls outside this subset, use the **Plugin API (v1.2.0)**
or the `fallbackBuilder` parameter to delegate to a WebView or other renderer.

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
| `em>`, `<i>` | Italic |
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
| `<video>` | Placeholder widget with poster image |
| `<audio>` | Placeholder audio bar |
| `<source>` | Parsed for media attributes |
| `<picture>` | First `<img>` child used |

---

## CSS Properties

### Text

| Property | Support |
|----------|---------|
| `color` | Full color support including alpha |
| `font-size` | px, em, rem, %, named |
| `font-weight` | 100–900 and named |
| `font-style` | normal, italic, oblique |
| `font-family` | System font lookup |
| `line-height` | Unitless, px, em, % |
| `letter-spacing` | px, em |
| `word-spacing` | px, em |
| `text-align` | left, right, center, justify |
| `text-decoration` | underline, line-through, overline, none |
| `text-transform` | uppercase, lowercase, capitalize |
| `white-space` | normal, pre, pre-wrap, nowrap |
| `text-overflow` | clip, ellipsis |
| `text-shadow` | Full support for multiple shadows (v1.2.0) |
| `direction` / `dir` attr | ltr, rtl |

### Box Model

| Property | Support |
|----------|---------|
| `width`, `height` | px, %, em, rem; `auto` |
| `min-width`, `max-width` | px, %, em |
| `margin` | All shorthand forms; `auto` support |
| `padding` | All shorthand forms |
| `border` | width, style, color |
| `border-style` | solid, dashed, dotted, double, none |
| `border-radius` | px, % |
| `box-sizing` | border-box, content-box |
| `overflow` | visible, hidden |

### Layout

| Property | Support |
|----------|---------|
| `display` | block, inline, inline-block, none, flex, grid, table |
| `float` | left, right, none (Full wrapping support) |
| `clear` | left, right, both, none |
| `position` | **relative only** |
| Flexbox | Full support for flex containers and items |
| CSS Grid | Full support including fr-units and gap (v1.2.0) |

### Background

| Property | Support |
|----------|---------|
| `background-color` | Full color support |
| `background-image` | `url()`, `linear-gradient()` (v1.2.0) |
| `background-size` | cover, contain, fill |

### Effects

| Property | Support |
|----------|---------|
| `opacity` | Full (0.0–1.0) |
| `box-shadow` | Full support for multiple shadows (v1.2.0) |
| `filter` | blur, brightness, contrast |
| `backdrop-filter` | blur (Glassmorphism) |

### Advanced

| Property | Support |
|----------|---------|
| CSS Variables (`--prop: value`) | Full inheritance and resolution |
| `calc()` | Arithmetic expressions |
| `!important` | Respected in cascade |
| `@keyframes` | Parsed from `<style>` tags automatically (v1.2.0) |

---

## HTML Attributes

| Attribute | Elements | Notes |
|-----------|----------|-------|
| `id`, `class` | All | Used for CSS selectors |
| `style` | All | Inline CSS |
| `href` | `<a>` | Absolute or relative |
| `src`, `alt`, `width`, `height` | `<img>` | Media attributes |
| `colspan`, `rowspan` | `<td>`, `<th>` | Table spanning |
| `aria-label` | All | Accessibility label (v1.2.0) |

---

## Unsupported

- `position: absolute` / `position: fixed`
- `z-index`
- `clip-path`
- `<form>`, `<input>`, `<select>`, `<textarea>` (Use Plugin API for these)
- `<script>` — JavaScript execution

---

*Last updated: April 29, 2026 — HyperRender v1.3.0*
