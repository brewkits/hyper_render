# Changelog

All notable changes to HyperRender will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-03-17

### ✨ Aesthetic & Visual Quality Enhancements (Phase 1 & 2)

#### 🎨 Advanced CSS Support
- **CSS Box Shadow**: Full support for box-shadow property with multiple shadows, blur, and spread.
- **CSS Gradients**: Support for linear-gradient in background and background-image properties.
- **Typography Enhancements**: Enabled font features (ligatures, proportional figures) by default for superior readability.
- **Consistent Text Rendering**: Implemented TextHeightBehavior for predictable vertical rhythm across all platforms.

#### 🚀 Rendering Quality
- **Retina-Ready Images**: Explicitly set FilterQuality.medium for all images, ensuring crisp rendering on high-DPI displays.
- **Anti-Aliasing Guarantee**: Explicitly enabled anti-aliasing on all paint operations to eliminate jagged edges on borders and shapes.
- **Crisp Borders**: Improved border rendering with StrokeCap.square for professional-looking corners.

#### 🛠️ Core Improvements
- **Adaptive Selection**: Native-feeling text selection colors that automatically adapt to the platform (iOS Blue vs Material Blue).
- **Theme-Aware Selection**: Added selectionColor property to HyperViewer and HyperRenderWidget for custom branding.
- **Stability**: Added comprehensive error boundaries to layout and paint cycles to prevent app crashes from malformed content.
- **Security**: Reinforced JSON parsing error handling in Delta adapters.

### 📦 Packages Updated
- hyper_render (wrapper)

---

## [1.0.3] - 2026-03-10
- Fix root .pubignore — remove packages/ blanket exclusion that breaks sub-package publishing.
- Restore hyper_render_clipboard path dep post-publish.

## [1.0.2] - 2026-03-08
- Fix .pubignore to exclude packages/, test/, IDE files — reduces upload size.
- Bump hyper_render_clipboard to ^1.0.2 (share_plus 12.x + super_clipboard 0.9.x support).

## [1.0.1] - 2026-03-08
- Add example/example.dart for pub.dev example scoring.
- Fix .pubignore to correctly exclude build artifacts while keeping example.

## [1.0.0] - 2026-03-01
First stable release. Core features, plugin architecture, and cross-platform support are production-ready.
