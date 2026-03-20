# Migration Guide

> **Note**: HyperRender is currently at **v1.0.0**, the initial stable release. This migration guide is preserved for future reference when breaking changes occur in v2.0.

## Current Version: 1.0.0

**No migration needed!** If you're starting fresh with HyperRender v1.0.0:

```yaml
dependencies:
  hyper_render_core: ^1.0.0
  hyper_render_clipboard: ^1.0.0  # Optional: for image clipboard features
```

```dart
import 'package:hyper_render_core/hyper_render_core.dart';

HyperViewer(
  html: '<p>Hello World</p>',
)
```

---

## Future: Migration from v1.x to v2.x

> **This section is for planning purposes only and describes potential breaking changes in a future v2.0 release.**

When v2.0 is released (planned features):
- Modular plugin architecture with separate parser packages
- Zero-dependency core package
- Improved tree-shaking for smaller bundle sizes
- Enhanced plugin system

### Potential Changes in v2.0 (Not Yet Released)

**Current v1.0:**
```yaml
dependencies:
  hyper_render_core: ^1.0.0
```

**Future v2.0 (example structure):**
```yaml
dependencies:
  hyper_render_core: ^2.0.0       # Core engine
  hyper_render_html: ^2.0.0       # HTML parser plugin
  hyper_render_markdown: ^2.0.0   # Markdown parser plugin (optional)
```

### What Won't Change

These APIs are stable and will remain backward-compatible in v2.0:

- Core widget: `HyperViewer`
- Plugin interfaces: `ImageClipboardHandler`, `CodeHighlighter`
- Design tokens system
- CSS support
- Float layout

---

## Version History

### v1.0.0 (Current - February 2026)
- Initial stable release
- Full HTML rendering support
- CSS styling with design tokens
- Plugin architecture with clipboard support
- Cross-platform (iOS, Android, Web, Desktop)

### v2.0.0 (Future - Planned)
- Modular parser system
- Enhanced performance optimizations
- Additional plugin ecosystem
- Breaking API improvements based on community feedback

---

## Getting Help

For the current v1.0.0 release:
- See [README](../README.md) for usage
- Check [CHANGELOG](../CHANGELOG.md) for version history
- Review [Plugin Development Guide](PLUGIN_DEVELOPMENT.md) for extending
- File issues at [GitHub Issues](https://github.com/your-repo/issues)

---

*Last Updated: February 2026 for v1.0.0*
