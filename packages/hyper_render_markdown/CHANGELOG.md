# Changelog — hyper_render_markdown

## [1.3.0] - 2026-05-03

### ✨ New Features
- **Section splitting**: `parseToSections()` now splits at `h1`/`h2`/`h3` boundaries for virtualized rendering — previously ignored `chunkSize` parameter
- **Link safety**: `javascript:` and `data:` href values are sanitized and blocked

### 🐛 Bug Fixes
- **Inline bold/italic**: Nested inline markers (`**bold _italic_**`) now resolve correctly
- **Fenced code blocks**: Language hint passed through to `hyper_render_highlight` for syntax coloring

## [1.2.0] - 2026-03-30

- Initial release: CommonMark Markdown → UDT adapter (headings, bold, italic, links, code blocks, lists, blockquotes)
