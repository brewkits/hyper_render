# HyperRender Clipboard Documentation

Complete documentation for the `hyper_render_clipboard` package.

## 📚 Documentation Overview

Welcome to the comprehensive documentation for HyperRender Clipboard! This package provides full-featured image clipboard operations for HyperRender, including copying images to clipboard, saving to device storage, and sharing via system dialogs.

### Quick Links

| Document | Description |
|----------|-------------|
| [API Reference](api_reference.md) | Complete API documentation with method signatures, parameters, and examples |
| [Usage Guide](usage_guide.md) | Detailed usage patterns, integration examples, and best practices |
| [Platform Setup](platform_setup.md) | Platform-specific configuration for macOS, iOS, Android, Windows, Linux, and Web |
| [Troubleshooting](troubleshooting.md) | Common issues, solutions, and debugging tips |

---

## 🚀 Getting Started

### New to HyperRender Clipboard?

1. **Start here:** [Installation & Basic Setup](usage_guide.md#installation)
2. **Configure your platform:** [Platform Setup Guide](platform_setup.md)
3. **Learn the API:** [API Reference](api_reference.md)
4. **Explore examples:** [Usage Guide](usage_guide.md)

### Quick Example

```dart
import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';

final handler = SuperClipboardHandler();

// Copy image to clipboard
await handler.copyImageFromUrl('https://example.com/image.png');

// Save image to device
final path = await handler.saveImageFromUrl(
  'https://example.com/image.png',
  filename: 'my_image.png',
);

// Share image
await handler.shareImageFromUrl(
  'https://example.com/image.png',
  text: 'Check this out!',
);
```

---

## 📖 Documentation Structure

### 1. API Reference

**[Complete API Documentation →](api_reference.md)**

Comprehensive reference covering:
- Constructor and initialization
- All methods with signatures and examples
- Properties and getters
- Platform compatibility matrix
- Type definitions
- Error handling patterns

**When to read:**
- Looking up specific method signatures
- Understanding method parameters and return types
- Checking platform compatibility
- Reference during development

### 2. Usage Guide

**[Detailed Usage Patterns →](usage_guide.md)**

In-depth guide covering:
- Installation and setup
- Integration with HyperViewer
- Standalone usage examples
- Working with image bytes
- Custom HTTP clients
- Error handling strategies
- Platform detection
- Advanced usage patterns
- Best practices

**When to read:**
- Implementing clipboard features for the first time
- Learning advanced usage patterns
- Understanding best practices
- Integrating with existing apps

### 3. Platform Setup Guide

**[Platform Configuration →](platform_setup.md)**

Platform-specific setup instructions:
- macOS entitlements
- iOS Info.plist configuration
- Android permissions and manifest
- Windows setup (minimal)
- Linux xclip installation
- Web CORS and HTTPS requirements
- Verification checklists
- Common setup issues

**When to read:**
- Setting up a new project
- Adding platform support
- Troubleshooting platform-specific issues
- Preparing for deployment

### 4. Troubleshooting Guide

**[Common Issues & Solutions →](troubleshooting.md)**

Problem-solving guide covering:
- Installation issues
- Clipboard operation failures
- Network errors
- Storage/save problems
- Share dialog issues
- Platform-specific problems
- Debugging techniques
- Performance optimization

**When to read:**
- Encountering errors or unexpected behavior
- Operations returning false/null
- Platform-specific issues
- Performance problems
- Before filing a bug report

---

## 🎯 Common Tasks

### Integration Tasks

| Task | Documentation |
|------|---------------|
| Add to HyperViewer | [Usage Guide - Integration](usage_guide.md#integration-with-hyperviewer) |
| Custom context menu | [Usage Guide - Custom Menu](usage_guide.md#with-custom-context-menu) |
| Platform detection | [Usage Guide - Platform Detection](usage_guide.md#platform-detection) |

### Image Operations

| Task | Documentation |
|------|---------------|
| Copy image from URL | [API Reference - copyImageFromUrl](api_reference.md#copyimagefromurl) |
| Copy image bytes | [API Reference - copyImageBytes](api_reference.md#copyimagebytes) |
| Save to device | [API Reference - saveImageFromUrl](api_reference.md#saveimagefromurl) |
| Share image | [API Reference - shareImageFromUrl](api_reference.md#shareimagefromurl) |

### Platform Setup

| Platform | Documentation |
|----------|---------------|
| macOS | [Platform Setup - macOS](platform_setup.md#macos) |
| iOS | [Platform Setup - iOS](platform_setup.md#ios) |
| Android | [Platform Setup - Android](platform_setup.md#android) |
| Windows | [Platform Setup - Windows](platform_setup.md#windows) |
| Linux | [Platform Setup - Linux](platform_setup.md#linux) |
| Web | [Platform Setup - Web](platform_setup.md#web) |

### Troubleshooting

| Issue | Documentation |
|-------|---------------|
| Copy returns false | [Troubleshooting - Clipboard Issues](troubleshooting.md#clipboard-issues) |
| Network errors | [Troubleshooting - Network Issues](troubleshooting.md#network-issues) |
| Save returns null | [Troubleshooting - Storage Issues](troubleshooting.md#savestorage-issues) |
| Platform-specific problems | [Troubleshooting - Platform-Specific](troubleshooting.md#platform-specific-issues) |

---

## 🔍 Find What You Need

### By Role

**App Developers**
1. [Usage Guide](usage_guide.md) - Learn integration patterns
2. [API Reference](api_reference.md) - Look up methods
3. [Platform Setup](platform_setup.md) - Configure your platforms

**Plugin Developers**
1. [API Reference](api_reference.md) - Understand the interface
2. Architecture section in [README](../README.md#architecture)
3. Source code in `lib/src/`

**Troubleshooters**
1. [Troubleshooting Guide](troubleshooting.md) - Find solutions
2. [Platform Setup](platform_setup.md) - Verify configuration
3. GitHub Issues for known problems

### By Experience Level

**Beginners**
1. Start with [Usage Guide - Basic Setup](usage_guide.md#basic-setup)
2. Follow [Platform Setup](platform_setup.md) for your target
3. Try examples from [Usage Guide](usage_guide.md)

**Intermediate**
1. [API Reference](api_reference.md) for detailed methods
2. [Usage Guide - Advanced](usage_guide.md#advanced-usage)
3. [Troubleshooting](troubleshooting.md) for issues

**Advanced**
1. Custom HTTP clients in [Usage Guide](usage_guide.md#custom-http-client)
2. Performance tips in [Troubleshooting](troubleshooting.md#performance-tips)
3. Source code review

---

## 🌟 Features Overview

### Core Features

✅ **Copy to Clipboard**
- Copy actual image data (not just URLs)
- Support for PNG, JPEG, GIF, WebP, BMP, TIFF
- Works with URLs or raw bytes
- Platform-specific optimizations

✅ **Save to Storage**
- Platform-appropriate save locations
- Custom filenames supported
- Automatic format detection
- Handles scoped storage (Android 10+)

✅ **System Share**
- Native share dialogs
- Optional text/captions
- Cross-platform consistency
- Handles large images

### Platform Support Matrix

| Feature | macOS | iOS | Android | Windows | Linux | Web |
|---------|-------|-----|---------|---------|-------|-----|
| Copy to Clipboard | ✅ | ✅ | ✅ | ✅ | ✅* | ⚠️ |
| Save to Storage | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Share | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Byte Operations | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |

\* Requires xclip on Linux
⚠️ Limited browser support

---

## 💡 Tips & Best Practices

### Quick Tips

1. **Reuse Handler Instances**
   ```dart
   // Good: Create once, reuse
   final handler = SuperClipboardHandler();
   ```

2. **Check Platform Support**
   ```dart
   if (handler.isImageCopySupported) {
     await handler.copyImageFromUrl(url);
   }
   ```

3. **Provide User Feedback**
   ```dart
   final success = await handler.copyImageFromUrl(url);
   if (!success) {
     showError('Failed to copy image');
   }
   ```

4. **Handle Async Properly**
   ```dart
   // Always await operations
   await handler.copyImageFromUrl(url);
   ```

See [Usage Guide - Best Practices](usage_guide.md#best-practices) for more.

---

## 🆘 Getting Help

### Documentation Not Enough?

1. **Search** the documentation for keywords
2. **Check** [Troubleshooting Guide](troubleshooting.md)
3. **Review** [GitHub Issues](https://github.com/your-repo/issues)
4. **Ask** on [GitHub Discussions](https://github.com/your-repo/discussions)
5. **File** a detailed bug report with:
   - Platform and version
   - Flutter version
   - Error messages
   - Minimal reproduction code

### Before Asking

- [ ] Read relevant documentation sections
- [ ] Check [Troubleshooting Guide](troubleshooting.md)
- [ ] Search existing GitHub issues
- [ ] Verify platform setup is correct
- [ ] Test with minimal reproduction code

---

## 📝 Contributing to Documentation

Found a typo or want to improve the docs?

1. Fork the repository
2. Edit the documentation files
3. Submit a pull request

See [Contributing Guidelines](../../CONTRIBUTING.md) for details.

---

## 📦 Package Information

- **Package:** hyper_render_clipboard
- **Version:** 1.0.0
- **License:** MIT
- **Repository:** [GitHub](https://github.com/your-repo)
- **Pub.dev:** [hyper_render_clipboard](https://pub.dev/packages/hyper_render_clipboard)

---

## 🔗 Related Documentation

- [HyperRender Documentation](../../docs/)
- [HyperRender Core](../hyper_render_core/README.md)
- [Plugin Development Guide](../../docs/PLUGIN_DEVELOPMENT.md)

---

**Happy Coding! 🚀**

If you find this package useful, please consider giving it a ⭐ on [GitHub](https://github.com/your-repo)!
