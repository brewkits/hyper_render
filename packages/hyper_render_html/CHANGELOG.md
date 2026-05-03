# Changelog — hyper_render_html

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
