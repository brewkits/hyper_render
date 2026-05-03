# Changelog — hyper_render_markdown

## [1.3.0] - 2026-05-03

- Version bump to stay in sync with `hyper_render` 1.2.0.
- No API changes in this package.

## [1.3.0] - 2026-05-03

- Version bump to stay in sync with `hyper_render` 1.1.4.

## [1.3.0] - 2026-05-03

- Remove `publish_to: none` from pubspec.yaml so pub.dev can verify the repository URL (fixes 10-point deduction).


## [1.3.0] - 2026-05-03

- Version bump to stay in sync with `hyper_render_core` 1.1.2 (Ruby selection fixes, CSS @keyframes support).
- No API changes in this package.

## [1.3.0] - 2026-05-03

- Maintenance release: no code changes — republish to sync repository verification with current git HEAD

## [1.3.0] - 2026-05-03

### ✨ New Features
- **Section splitting**: `parseToSections()` now splits at `h1`/`h2`/`h3` boundaries for virtualized rendering — previously ignored `chunkSize` parameter
- **Link safety**: `javascript:` and `data:` href values are sanitized and blocked

### 🐛 Bug Fixes
- **Inline bold/italic**: Nested inline markers (`**bold _italic_**`) now resolve correctly
- **Fenced code blocks**: Language hint passed through to `hyper_render_highlight` for syntax coloring

## [1.3.0] - 2026-05-03

- Initial release: CommonMark Markdown → UDT adapter (headings, bold, italic, links, code blocks, lists, blockquotes)
