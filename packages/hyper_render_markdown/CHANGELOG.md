# Changelog — hyper_render_markdown

## [1.1.1] - 2026-03-23

- Maintenance release: no code changes — republish to sync repository verification with current git HEAD

## [1.1.0] - 2026-03-20

### ✨ New Features
- **Section splitting**: `parseToSections()` now splits at `h1`/`h2`/`h3` boundaries for virtualized rendering — previously ignored `chunkSize` parameter
- **Link safety**: `javascript:` and `data:` href values are sanitized and blocked

### 🐛 Bug Fixes
- **Inline bold/italic**: Nested inline markers (`**bold _italic_**`) now resolve correctly
- **Fenced code blocks**: Language hint passed through to `hyper_render_highlight` for syntax coloring

## [1.0.0] - 2026-01-15

- Initial release: CommonMark Markdown → UDT adapter (headings, bold, italic, links, code blocks, lists, blockquotes)
