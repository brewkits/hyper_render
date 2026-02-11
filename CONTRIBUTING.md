# Contributing to HyperRender

Thank you for your interest in contributing to HyperRender! We welcome contributions from the community and appreciate your help in making this project better.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)
- [Testing](#testing)

## Code of Conduct

This project adheres to a Code of Conduct that all contributors are expected to follow. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/hyper_render.git
   cd hyper_render
   ```
3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/brewkits/hyper_render.git
   ```

## Development Setup

### Prerequisites

- Flutter SDK >=3.10.0
- Dart SDK >=3.5.0
- Git

### Installation

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run tests to verify setup:
   ```bash
   flutter test
   ```

3. Run the example app:
   ```bash
   cd example
   flutter run
   ```

### Project Structure

```
hyper_render/
├── lib/                    # Main package (convenience wrapper)
├── packages/
│   ├── hyper_render_core/      # Core rendering engine (zero dependencies)
│   ├── hyper_render_html/      # HTML parsing plugin
│   ├── hyper_render_markdown/  # Markdown parsing plugin
│   ├── hyper_render_highlight/ # Syntax highlighting plugin
│   └── hyper_render_clipboard/ # Clipboard operations plugin
├── example/                # Example Flutter app
├── test/                   # Integration and system tests
└── docs/                   # Documentation
```

## How to Contribute

### Types of Contributions

We welcome:

- **Bug fixes**
- **New features**
- **Documentation improvements**
- **Performance optimizations**
- **Test coverage improvements**
- **Examples and tutorials**

### Before You Start

1. **Check existing issues** to see if your idea/bug is already being discussed
2. **Create an issue** for significant changes to discuss the approach
3. **For small fixes**, feel free to submit a PR directly

## Coding Standards

### Dart Style Guide

- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter_lints` for code analysis
- Run `dart format .` before committing
- Run `flutter analyze` to check for issues

### Code Conventions

1. **Naming**:
   - Classes: `PascalCase`
   - Variables/functions: `camelCase`
   - Constants: `camelCase` or `SCREAMING_SNAKE_CASE` for compile-time constants
   - Private members: prefix with `_`

2. **Documentation**:
   - Add dartdoc comments (`///`) for all public APIs
   - Include usage examples for complex APIs
   - Document parameters, return values, and exceptions

3. **Code Organization**:
   - Keep files under 500 lines when possible
   - Group related functionality together
   - Extract complex logic into separate functions/classes

4. **Performance**:
   - Avoid unnecessary rebuilds
   - Use `const` constructors where possible
   - Profile before optimizing

5. **No Debug Code**:
   - Remove all `print()` statements from production code
   - Use `debugPrint()` or logging packages for development

### Testing Standards

- Write tests for all new features
- Maintain or improve test coverage
- Include unit tests, widget tests, and integration tests as appropriate
- Test edge cases and error conditions

## Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `perf`: Performance improvements
- `chore`: Maintenance tasks

**Examples**:
```
feat(html): add support for CSS Grid layout

Implement CSS Grid layout parsing and rendering with proper
alignment and gap support.

Closes #123
```

```
fix(core): resolve text selection crash on empty nodes

Add null checks in selection logic to prevent crashes when
selecting empty text nodes.

Fixes #456
```

## Pull Request Process

### Before Submitting

1. **Update your branch** with the latest upstream changes:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run tests**:
   ```bash
   flutter test
   ```

3. **Run analysis**:
   ```bash
   flutter analyze
   ```

4. **Format code**:
   ```bash
   dart format .
   ```

5. **Update documentation** if needed

### Submitting a PR

1. **Push to your fork**:
   ```bash
   git push origin your-branch-name
   ```

2. **Create a Pull Request** on GitHub

3. **Fill out the PR template** completely:
   - Description of changes
   - Related issue numbers
   - Testing performed
   - Screenshots/videos (for UI changes)
   - Breaking changes (if any)

4. **Respond to review feedback** promptly

### PR Requirements

- ✅ All tests pass
- ✅ Code follows style guidelines
- ✅ Documentation updated
- ✅ Commit messages follow conventions
- ✅ No merge conflicts
- ✅ Signed commits (optional but recommended)

### Review Process

- Maintainers will review your PR within 1-2 weeks
- Address feedback by pushing new commits
- Once approved, a maintainer will merge your PR
- PRs may be closed if inactive for 30+ days

## Reporting Issues

### Bug Reports

When reporting bugs, include:

1. **Description**: Clear description of the issue
2. **Steps to Reproduce**: Minimal reproducible example
3. **Expected Behavior**: What should happen
4. **Actual Behavior**: What actually happens
5. **Environment**:
   - Flutter version: `flutter --version`
   - Dart version: `dart --version`
   - Platform: iOS/Android/Web/Desktop
   - Device/Emulator details
6. **Code Sample**: Minimal code that reproduces the issue
7. **Logs/Screenshots**: Any relevant error messages or screenshots

### Feature Requests

When requesting features:

1. **Use Case**: Describe the problem you're trying to solve
2. **Proposed Solution**: Your suggested implementation
3. **Alternatives**: Other approaches you've considered
4. **Additional Context**: Any other relevant information

## Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/system_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Writing Tests

- Place unit tests in `test/` directory
- Use descriptive test names
- Follow AAA pattern: Arrange, Act, Assert
- Use `group()` to organize related tests
- Mock external dependencies

**Example**:

```dart
test('parses simple HTML paragraph', () {
  // Arrange
  const html = '<p>Hello World</p>';

  // Act
  final document = HtmlParser().parse(html);

  // Assert
  expect(document.children, hasLength(1));
  expect(document.children[0].textContent, equals('Hello World'));
});
```

## Additional Resources

- [Documentation](https://github.com/brewkits/hyper_render/tree/main/docs)
- [Examples](https://github.com/brewkits/hyper_render/tree/main/example)
- [Issue Tracker](https://github.com/brewkits/hyper_render/issues)
- [Discussions](https://github.com/brewkits/hyper_render/discussions)

## Questions?

If you have questions about contributing:

1. Check the [documentation](https://github.com/brewkits/hyper_render/tree/main/docs)
2. Search [existing issues](https://github.com/brewkits/hyper_render/issues)
3. Ask in [GitHub Discussions](https://github.com/brewkits/hyper_render/discussions)
4. Open a new issue with the `question` label

---

Thank you for contributing to HyperRender! 🚀
