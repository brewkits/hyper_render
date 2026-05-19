# Changelog — hyper_render_markdown

## [1.3.2] - 2026-05-19

### 🔒 Security

- **URL scheme gate consolidated with the rest of the ecosystem** — the per-package `_isSafeUrl` helper had drifted out of sync with the root `HtmlSanitizer.isSafeUrl`: `file:`, `mhtml:`, and `about:` were *not* blocked, leaving a Markdown link like `[click](file:///data/data/com.app/secret.db)` as a working local-file exfiltration vector. The check now delegates to the shared `UrlSafety.isSafe` in `hyper_render_core`, so any future scheme added in one place is added everywhere.

### 📛 API Naming

- **`MarkdownContentParser` → `DefaultMarkdownParser`** — the new name aligns with `DefaultHtmlParser` / `DefaultCssParser` in the sibling HTML sub-package. The old name continues to compile via a `@Deprecated typedef`; remove the typedef in v2.0.

### 🧪 Tests

- **+19 tests added** across `markdown_url_safety_test` (per-scheme link/image neutralisation, scheme casing) and `markdown_gfm_test` (pipe tables, task lists, autolinks, fenced code blocks, `enableGfm:false` opt-out behaviour, heading + blockquote shapes).

## [1.3.1] - 2026-05-14

### 🏗️ Maintenance
- Updated `hyper_render_core` dependency to `^1.3.1`

## [1.3.0] - 2026-05-03

### ✨ New Features
- **Section splitting**: `parseToSections()` now splits at `h1`/`h2`/`h3` boundaries for virtualized rendering — previously ignored `chunkSize` parameter
- **Link safety**: `javascript:` and `data:` href values are sanitized and blocked

### 🐛 Bug Fixes
- **Inline bold/italic**: Nested inline markers (`**bold _italic_**`) now resolve correctly
- **Fenced code blocks**: Language hint passed through to `hyper_render_highlight` for syntax coloring

## [1.2.0] - 2026-03-30

- Initial release: CommonMark Markdown → UDT adapter (headings, bold, italic, links, code blocks, lists, blockquotes)
