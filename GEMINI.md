# HyperRender Project Instructions

HyperRender is a high-performance HTML/Markdown rendering engine for Flutter, designed to handle complex layouts like CSS floats, crash-free text selection, and CJK typography using a single custom `RenderObject` architecture.

## Project Overview

- **Main Technologies**: Flutter (>=3.10.0), Dart (>=3.5.0), `csslib`, `html`, `markdown`.
- **Architecture**: Modular monorepo.
  - `lib/`: Main package (`hyper_render`) - a convenience wrapper.
  - `packages/hyper_render_core/`: The core engine (UDT model, CSS resolver, custom `RenderObject`).
  - `packages/hyper_render_html/`: HTML + CSS parser.
  - `packages/hyper_render_markdown/`: Markdown adapter (GitHub Flavored Markdown).
  - `packages/hyper_render_highlight/`: Syntax highlighting.
  - `packages/hyper_render_clipboard/`: Image copy/share support.
  - `packages/hyper_render_devtools/`: DevTools extension for UDT inspection.
- **Key Concepts**:
  - **Unified Document Tree (UDT)**: An intermediate model between parser and renderer.
  - **Single RenderObject**: Unlike other libraries, HyperRender uses one `RenderObject` to manage the entire document layout, enabling float support and efficient selection.
  - **Render Modes**: `sync` (small docs), `virtualized` (large docs via `ListView.builder`), `paged` (reader UI), and `auto`.

## Building and Running

### Prerequisites
- Flutter SDK and Dart SDK (versions specified in `pubspec.yaml`).
- [FVM](https://fvm.app/) (recommended, as seen in existing workflows).

### Commands
- **Install Dependencies**: `flutter pub get` (run at root and in sub-packages if needed).
- **Run Tests**:
  - All tests: `flutter test`
  - Exclude golden tests: `flutter test --exclude-tags golden`
  - Specific file: `flutter test test/system_test.dart`
- **Static Analysis**: `flutter analyze --no-pub --fatal-warnings --fatal-infos`
- **Code Formatting**: `dart format .`
- **Run Example App**: `cd example && flutter run`
- **Update Goldens**: `flutter test test/golden/ --update-goldens` (Requires specific Noto fonts installed).

## Development Conventions

### Coding Style
- **Effective Dart**: Follow official [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines.
- **Linter**: Strictly enforced via `flutter_lints` and custom rules in `analysis_options.yaml`.
- **Naming**: `PascalCase` for classes, `camelCase` for members/variables/functions, `camelCase` or `SCREAMING_SNAKE_CASE` for constants.
- **Documentation**: Use `///` for all public APIs.

### Testing Practices
- **Mandatory Coverage**: All new features and bug fixes must include tests.
- **AAA Pattern**: Use Arrange-Act-Assert.
- **Golden Tests**: Tagged with `golden`. Used for visual regression.
- **Performance**: Always profile with Flutter DevTools in `--profile` mode before and after optimization.

### Git & Commit Guidelines
- **Commit Message Format**: `<type>(<scope>): <subject>` (e.g., `feat(html): add support for CSS Grid`).
- **Branching**: Feature work should happen on `feat/*` or `bugfix/*` branches.
- **Pull Requests**: CI must pass (Analyze, Format, Test, Visual Regression) before merging.

## Security Mandates
- **Sanitization**: XSS sanitization must be enabled by default (`sanitize: true`).
- **External Input**: Treat all HTML content as untrusted unless explicitly from a secure internal source.
- **URL Validation**: Always validate URLs in `onLinkTap` callbacks to block `javascript:` or malicious domains.

## Performance Mandates
- **TextPainter Management**: Rely on the internal LRU cache; do not create excessive `TextPainter` objects manually.
- **Virtualized Mode**: Use `HyperRenderMode.virtualized` for documents exceeding 10,000 characters.
- **Const Constructors**: Use `const` wherever possible to reduce widget rebuilds.
