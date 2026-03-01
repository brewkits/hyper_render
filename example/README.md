# HyperRender Demo App

Interactive demo application showcasing all features of HyperRender - The Universal Content Engine for Flutter.

## Features Demonstrated

### 🎨 Core Demos

1. **Kitchen Sink** - All-in-one showcase
   - Float Layout with images
   - Widget Injection (subscribe button)
   - Ruby Annotation (Japanese furigana)
   - Text Selection

2. **Float Layout** - CSS float: left/right
   - Left-floated rectangular images
   - Right-floated circular images
   - Multiple floats side-by-side
   - Clear property

3. **Text Selection** - Crash-free selection on large documents
   - Multi-paragraph content
   - Cross-element selection
   - Vietnamese text support
   - Copy/paste functionality

4. **Ruby Annotation** - CJK typography excellence
   - Japanese furigana (振り仮名)
   - Literature examples (夏目漱石)
   - Place names
   - Chinese pinyin

5. **Widget Injection** - Embed Flutter widgets in HTML
   - Stateful subscribe button
   - Like button with counter
   - Star rating widget
   - Share buttons

6. **Inline Decoration** - Background/border across line breaks
   - Multi-line background wrap
   - Border-radius support
   - Code inline styling
   - Multiple colored highlights

7. **Real Content** - Blog post example
   - Float images in articles
   - Blockquotes
   - Lists (ul, ol)
   - Japanese ruby text
   - Professional typography

8. **Table Demo** - Comprehensive table support
   - Simple tables with headers
   - Wide tables (horizontal scroll)
   - Complex tables (colspan, rowspan)
   - Nested tables

9. **Code Blocks** - Syntax highlighting showcase
   - Dart code (VS Code theme)
   - HTML (dark theme)
   - JavaScript (GitHub theme)
   - Python (Material theme)
   - Terminal commands (Matrix green)
   - Inline code examples

10. **Image Handling** - Automatic error/loading states
    - Successfully loaded images
    - Error placeholders (404 images)
    - Loading state explanation
    - Mixed content with floats
    - Responsive images

11. **Zoom & Pan** - Interactive zoom functionality
    - Pinch-to-zoom gestures
    - Pan while zoomed
    - Configurable min/max scale
    - Works with text selection
    - Compatible with float layouts

### 🚀 Advanced Demos

12. **Library Comparison** - HyperRender vs Competitors
   - Side-by-side comparison with flutter_html, FWFH
   - 9 interactive test cases covering:
     • Float Layout (HyperRender exclusive)
     • Table colspan/rowspan with width: 100% (fits screen)
     • Ruby Annotation (HyperRender most accurate)
     • Multiple floats (left + right in same paragraph)
     • Inline background wrapping (HyperRender exclusive)
     • CSS cascade and specificity
     • Selection stress test (crash-free validation)
     • Wide table with horizontal scroll (auto-scale)
     • Nested lists
   - Feature support matrix with 8 features
   - Real-time expected behavior indicators
   - Build time measurement

13. **Stress Test** - Performance testing
    - Configurable page count (10 - 1,000 pages)
    - Library selector for comparison
    - View virtualization demo
    - Generated content with:
      - Multiple chapters
      - Float images
      - Highlighted notes
      - Mixed languages (Latin, Japanese, Vietnamese)
    - Statistics display

## Running the Demo

```bash
cd example
flutter run
```

## Demo Organization

- **Home Screen**: Beautiful gradient header with feature chips and navigation cards
- **Demo Screens**: Each demo is self-contained with clear examples
- **Navigation**: Easy back navigation to explore all features

## Key Features Showcased

- ✅ Perfect Text Selection (crash-free on large documents)
- ✅ Advanced CSS Support (30+ properties)
- ✅ Float Layout (left, right, clear)
- ✅ Table Support (colspan, rowspan, horizontal scroll)
- ✅ CJK Typography (Kinsoku line-breaking, Ruby annotation)
- ✅ Widget Injection (embed interactive Flutter widgets)
- ✅ Inline Decorations (backgrounds/borders across line breaks)
- ✅ View Virtualization (smooth scrolling for large documents)
- ✅ Isolate-based Parsing (60fps performance)

## Screenshots

Run the app to see:
- Material 3 design with beautiful gradients
- Professional typography
- Smooth animations
- Interactive comparisons

## 🎬 Multimedia Integration Examples

**NEW!** Comprehensive guide for integrating video, audio, iframes, and custom widgets.

See [MULTIMEDIA_EXAMPLES.md](MULTIMEDIA_EXAMPLES.md) for detailed examples covering:

- **Video Player Integration** - Using `video_player` package via `mediaBuilder`
- **WebView/IFrame Integration** - Embedding YouTube, Google Maps, etc. via `widgetBuilder`
- **Float Layout with Video** - 🌟 **Unique advantage over FWFH!** Perfect CSS float support for media
- **Custom Widget Integration** - Extend HTML with your own interactive Flutter widgets

**Run multimedia examples:**

```bash
flutter run lib/multimedia_example.dart
```

## Learn More

- [HyperRender Package](https://pub.dev/packages/hyper_render)
- [Main Documentation](../README.md)
- [API Reference](https://pub.dev/documentation/hyper_render/latest/)
- [Multimedia Integration Guide](MULTIMEDIA_EXAMPLES.md)
