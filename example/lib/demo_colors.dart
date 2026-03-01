import 'package:flutter/material.dart';

/// Harmonious color palette for demo cards
///
/// Reduces visual chaos by using only 5 carefully chosen colors
/// that work well together and convey semantic meaning
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
  static const accent = Color(0xFF26A69A); // Teal 400

  /// Warning - Media & Performance (Amber/Orange family)
  /// Used for: Video, Zoom, Stress Test
  static const warning = Color(0xFFFF9800); // Orange 500

  /// Success - Quality & Accessibility (Green family)
  /// Used for: Accessibility, Library Comparison, FWFH Tests
  static const success = Color(0xFF66BB6A); // Green 400

  /// Error - Security & Critical (Red family)
  /// Used for: Security Demo, Critical warnings
  static const error = Color(0xFFEF5350); // Red 400

  // ============================================
  // NEUTRAL PALETTE
  // ============================================

  /// Neutral for less important items
  static const neutral = Color(0xFF78909C); // Blue Grey 400

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
}

/// Semantic categories for demo cards
enum DemoCategory {
  coreRendering,      // Float, Flexbox, CSS, Tables
  advancedFeatures,   // Widget Injection, Selection, Ruby
  contentFormats,     // Quill, Markdown, Code
  media,              // Video, Images, Zoom
  quality,            // A11y, Comparison, Tests
  security,           // Security, XSS Prevention
  other,              // Miscellaneous
}
