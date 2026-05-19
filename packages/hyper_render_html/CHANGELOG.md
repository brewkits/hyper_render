# Changelog — hyper_render_html

## [1.3.2] - 2026-05-19

### 🔒 Security

- **`HtmlAdapter` URL scheme gate (defence-in-depth)** — `<img src>` and `<a href>` are now routed through `UrlSafety.isSafe` (from `hyper_render_core`) **after** `_resolveUrl` runs. Even when callers bypass `HtmlSanitizer` (calling `HtmlAdapter().parse(...)` directly, or rendering with `sanitize: false`), `javascript:`, `vbscript:`, `file:`, `mhtml:`, `about:`, `data:image/svg`, and control-character smuggling variants now collapse to inert `#` (links) or `''` (images). Mirrors the same gate the Markdown and Delta adapters already applied.

### 🚀 Performance

- **`HtmlAdapter.extractCss` regex fast-path** — for inputs ≥ 32 KB or with no `<style` tag at all (the common Markdown/Delta case), `extractCss` skips the full html5lib parse on the UI thread and uses a focused regex. Saves 50–300 ms on a 200 KB document on a mid-range Android, eliminating the synchronous parse stall that occurred on every initial render. Small inputs continue to use the full DOM parser for fidelity.

### 🧪 Tests

- **+29 tests added** across `html_url_safety_test`, `css_parser_test`, `extract_css_perf_test`. Covers scheme blocklist, smuggling, multiple `<style>` blocks, case-insensitive matching, fast-path threshold behaviour, comma/class/id selectors, keyframes round-trip.

## [1.3.2] - 2026-05-14

### 🏗️ Maintenance
- Updated `hyper_render_core` dependency to `^1.3.2`

## [1.3.0] - 2026-05-03

### ✨ New Features
- **HTML tag coverage**: Full support for `h4`–`h6`, `section`, `article`, `main`, `aside`, `header`, `footer`, `nav`, `figure`, `figcaption`, `dl`/`dt`/`dd`, `summary`, `u`, `s`, `del`, `ins`, `small`, `q`, `cite`, `abbr`, `time`, `sup`, `sub`, `var`, `kbd`, `samp`, `bdi`, `bdo`, `dfn`, `wbr`
- **`display: none`**: Elements with `display: none` are now correctly skipped — no more `[edit]` links leaking from Wikipedia-style HTML
- **`<pre>` / code blocks**: Inline code and code blocks now render via `CodeBlockWidget`
- **`<hr>`**: Renders as a styled `BlockNode` with a border instead of a `LineBreakNode`
- **CSS Grid**: `display: grid` with row/column track sizing, `gap`, and span support
- **RTL/BiDi**: `direction: rtl` for Arabic, Hebrew, and Persian content

### 🐛 Bug Fixes
- **Whitespace preservation**: Whitespace-only text nodes between inline elements no longer dropped — fixes missing spaces between `<span>` siblings
- **`appendChild` for top-level nodes**: Fixed parent reference not being set for top-level nodes added to the document root
- **Shared `ComputedStyle` mutation**: `_defaultStyles` map now returns `.copyWith()` copies — prevents cross-node style bleed
- **Link XSS**: `javascript:`, `vbscript:`, and `data:` hrefs are sanitized and blocked
- **`<details>`/`<summary>`**: Fixed double-render issue on expanded details elements
- **`@override` analyzer warning**: `parseKeyframes()` no longer carries `@override` annotation — `flutter analyze` reports 0 issues
- **CSS float class detection**: `_containsFloatChild` now detects Bootstrap/Tailwind float class patterns

### 🔬 Tests
- Added regression tests for `display:none`, `<pre>`, whitespace handling

## [1.2.0] - 2026-03-30

- Initial release: HTML → UDT adapter with CSS float, Flexbox, table colspan/rowspan, ruby, XSS sanitization
