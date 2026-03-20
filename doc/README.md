# HyperRender Documentation

Welcome to the documentation for **HyperRender v1.1.0** — the high-performance HTML/Markdown renderer for Flutter.

## Documentation Index

### Getting Started

- **[Main README](../README.md)** — Project overview, quick start, and features
- **[CHANGELOG](../CHANGELOG.md)** — Version history and release notes

### User Guides

| Document | Description |
|----------|-------------|
| **[Supported HTML Elements](SUPPORTED_HTML.md)** | Tags and attributes supported by the engine |
| **[Known Limitations](LIMITATIONS.md)** | Honest list of what is not yet supported |
| **[Performance Tuning](PERFORMANCE_TUNING.md)** | Cache configuration, virtualization, benchmarks |
| **[Migration Guide](MIGRATION_GUIDE.md)** | Upgrade instructions between versions |
| **[Security & Accessibility](SECURITY_AND_ACCESSIBILITY.md)** | Security best practices and a11y features |
| **[Security Best Practices](SECURITY_BEST_PRACTICES.md)** | Hardening guide for production deployments |

### Developer Resources

| Document | Description |
|----------|-------------|
| **[Plugin Development](PLUGIN_DEVELOPMENT.md)** | Create custom plugins and adapters |
| **[Comparison Matrix](COMPARISON_MATRIX.md)** | Feature comparison with FWFH and WebView |
| **[CSS Properties Matrix](CSS_PROPERTIES_MATRIX.md)** | Full CSS property support status |
| **[Roadmap](ROADMAP.md)** | Planned features and versioning strategy |
| **[Contributing Guide](CONTRIBUTING.md)** | How to contribute code, docs, and issues |
| **[Code of Conduct](CODE_OF_CONDUCT.md)** | Community standards |

### Architecture Decision Records

Design decisions that shaped the engine, useful for contributors:

| ADR | Decision |
|-----|----------|
| [0001 — UDT Model](adr/0001-udt-model.md) | Unified Document Tree over widget composition |
| [0002 — Single RenderObject](adr/0002-single-renderobject.md) | One RenderObject vs one-per-node |
| [0003 — CSS Float Support](adr/0003-css-float-support.md) | Float layout algorithm design |
| [0004 — Kinsoku Processor](adr/0004-kinsoku-processor.md) | CJK line-breaking rules |
| [0005 — Inline Span Paradigm](adr/0005-inline-span-paradigm.md) | Continuous InlineSpan tree |

### Package-Specific Documentation

- **[hyper_render_clipboard](../packages/hyper_render_clipboard/docs/)** — Clipboard & image copy
  - [API Reference](../packages/hyper_render_clipboard/docs/api_reference.md)
  - [Usage Guide](../packages/hyper_render_clipboard/docs/usage_guide.md)
  - [Platform Setup](../packages/hyper_render_clipboard/docs/platform_setup.md)
  - [Troubleshooting](../packages/hyper_render_clipboard/docs/troubleshooting.md)

---

## Quick Links by Role

### For App Developers

1. [Main README](../README.md) — architecture and quick start
2. [Supported HTML Elements](SUPPORTED_HTML.md) — what renders out of the box
3. [Performance Tuning](PERFORMANCE_TUNING.md) — cache and virtualization settings
4. [Known Limitations](LIMITATIONS.md) — set expectations

### For Contributors

1. [Contributing Guide](CONTRIBUTING.md) — workflow and code standards
2. [Plugin Development](PLUGIN_DEVELOPMENT.md) — extending the engine
3. [Architecture Decision Records](adr/) — why the engine works this way
4. [Roadmap](ROADMAP.md) — what's planned and when

### For Evaluators

1. [Comparison Matrix](COMPARISON_MATRIX.md) — vs FWFH and WebView
2. [CSS Properties Matrix](CSS_PROPERTIES_MATRIX.md) — CSS coverage
3. [Main README](../README.md) — performance benchmarks

---

*Current stable: v1.1.0 — Last updated: March 2026*
