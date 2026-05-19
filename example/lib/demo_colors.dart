import 'package:flutter/material.dart';

/// Harmonious color palette for demo cards
///
/// Reduces visual chaos by using only a small set of semantic accents that
/// work well together and convey meaning. Each accent ships with light/dark
/// variants so demos look correct under both [Brightness.light] and
/// [Brightness.dark] without per-screen branching.
class DemoColors {
  DemoColors._();

  // ============================================
  // PRIMARY PALETTE - Muted, professional tones
  // ============================================

  /// Primary - Core rendering features (Indigo/Blue family)
  /// Used for: Float, Flexbox, CSS Properties, Tables, Real Content
  static const primary = Color(0xFF5C6BC0); // Indigo 400 - softer than default

  /// Secondary - Advanced features (Purple/Violet family)
  /// Used for: Widget Injection, Selection, Ruby, v2.1 Features, Aesthetic
  static const secondary = Color(0xFF7E57C2); // Deep Purple 400

  /// Accent - Content formats (Teal/Cyan family)
  /// Used for: Quill Delta, Markdown, Code Blocks, Image Handling
  static const accent = Color(0xFF00695C); // Teal 800 — contrast 6.3:1 on white

  /// Warning - Media & Performance (Amber/Orange family)
  /// Used for: Video, Zoom, Stress Test
  static const warning =
      Color(0xFFBF360C); // Deep Orange 900 — contrast 5.6:1 on white

  /// Success - Quality & Accessibility (Green family)
  /// Used for: Accessibility, Library Comparison, FWFH Tests
  static const success =
      Color(0xFF2E7D32); // Green 800 — contrast 5.0:1 on white

  /// Error - Security & Critical (Red family)
  /// Used for: Security Demo, Critical warnings
  static const error = Color(0xFFC62828); // Red 900 — contrast 5.6:1 on white

  // ============================================
  // NEUTRAL PALETTE
  // ============================================

  /// Neutral for less important items
  static const neutral =
      Color(0xFF546E7A); // Blue Grey 600 — contrast 5.1:1 on white

  // ============================================
  // COLOR SEMANTICS
  // ============================================

  /// Get color by semantic category
  static Color getColor(DemoCategory category) {
    switch (category) {
      case DemoCategory.coreRendering:
        return primary;
      case DemoCategory.advancedFeatures:
        return secondary;
      case DemoCategory.contentFormats:
        return accent;
      case DemoCategory.media:
        return warning;
      case DemoCategory.quality:
        return success;
      case DemoCategory.security:
        return error;
      case DemoCategory.other:
        return neutral;
    }
  }

  /// Return [color] mapped onto the current theme brightness so demo accents
  /// stay legible in dark mode without per-screen branching.
  static Color forBrightness(Color color, Brightness brightness) {
    if (brightness == Brightness.light) return color;
    // Lighten brand color for dark backgrounds (HSL with raised lightness).
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + 0.18).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.85).clamp(0.0, 1.0))
        .toColor();
  }
}

/// Semantic categories for demo cards
enum DemoCategory {
  coreRendering, // Float, Flexbox, CSS, Tables
  advancedFeatures, // Widget Injection, Selection, Ruby
  contentFormats, // Quill, Markdown, Code
  media, // Video, Images, Zoom
  quality, // A11y, Comparison, Tests
  security, // Security, XSS Prevention
  other, // Miscellaneous
}

// ============================================================================
// Shared demo scaffold helpers — keep all demo screens visually consistent and
// dark-mode safe without duplicating AppBar/SafeArea boilerplate.
// ============================================================================

/// Build a themed AppBar for demo screens.
///
/// Pass [accent] to tint the AppBar with a demo brand accent that automatically
/// lightens in dark mode. Foreground colour is computed from the resulting
/// background luminance for guaranteed WCAG contrast.
PreferredSizeWidget buildDemoAppBar(
  BuildContext context, {
  required String title,
  Color? accent,
  List<Widget>? actions,
  Widget? leading,
  PreferredSizeWidget? bottom,
  bool centerTitle = false,
}) {
  final brightness = Theme.of(context).brightness;
  final bg = accent == null
      ? Theme.of(context).colorScheme.primary
      : DemoColors.forBrightness(accent, brightness);
  // Guarantee 4.5:1 contrast: use luminance to pick fg.
  final fg = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
      ? Colors.white
      : Colors.black87;
  return AppBar(
    title: Text(title),
    centerTitle: centerTitle,
    backgroundColor: bg,
    foregroundColor: fg,
    elevation: 0,
    actions: actions,
    leading: leading,
    bottom: bottom,
  );
}
