import 'package:flutter/material.dart';

import '../exceptions/hyper_render_exceptions.dart';

/// Design tokens for HyperRender
///
/// Based on Material Design 3 principles with 8pt grid system.
/// All measurements follow a consistent scale for visual harmony.
///
/// ## Usage
///
/// ```dart
/// // Typography
/// TextStyle(fontSize: DesignTokens.h1FontSize)
///
/// // Spacing
/// Padding(all: DesignTokens.space3)
///
/// // Colors
/// Text('Link', style: TextStyle(color: DesignTokens.linkColor))
///
/// // Theming
/// final darkTokens = DesignTokens.dark();
/// Text(style: TextStyle(color: darkTokens.textPrimary))
/// ```
class DesignTokens {
  // ============================================================================
  // TYPOGRAPHY SCALE
  // ============================================================================
  // Based on Material Design 3 type scale
  // https://m3.material.io/styles/typography/type-scale-tokens

  /// Display Large - 57px (3.5625rem)
  /// For hero headlines and large display text
  static const double displayLargeFontSize = 57.0;
  static const FontWeight displayLargeFontWeight = FontWeight.w400;
  static const double displayLargeLineHeight = 64.0;

  /// Display Medium - 45px (2.8125rem)
  /// For important headlines
  static const double displayMediumFontSize = 45.0;
  static const FontWeight displayMediumFontWeight = FontWeight.w400;
  static const double displayMediumLineHeight = 52.0;

  /// Display Small - 36px (2.25rem)
  /// For section headlines
  static const double displaySmallFontSize = 36.0;
  static const FontWeight displaySmallFontWeight = FontWeight.w400;
  static const double displaySmallLineHeight = 44.0;

  /// Heading 1 - 32px (2rem)
  /// HTML h1, main page title
  static const double h1FontSize = 32.0;
  static const FontWeight h1FontWeight = FontWeight.bold;
  static const double h1LineHeight = 40.0;
  static const double h1MarginTop = 21.44; // 0.67em
  static const double h1MarginBottom = 21.44;

  /// Heading 2 - 24px (1.5rem)
  /// HTML h2, major section headings
  static const double h2FontSize = 24.0;
  static const FontWeight h2FontWeight = FontWeight.bold;
  static const double h2LineHeight = 32.0;
  static const double h2MarginTop = 19.92; // 0.83em
  static const double h2MarginBottom = 19.92;

  /// Heading 3 - 20px (1.25rem)
  /// HTML h3, subsection headings
  static const double h3FontSize = 20.0;
  static const FontWeight h3FontWeight = FontWeight.bold;
  static const double h3LineHeight = 28.0;
  static const double h3MarginTop = 16.6; // 0.83em
  static const double h3MarginBottom = 16.6;

  /// Heading 4 - 18px (1.125rem)
  /// HTML h4, minor headings
  static const double h4FontSize = 18.0;
  static const FontWeight h4FontWeight = FontWeight.bold;
  static const double h4LineHeight = 24.0;
  static const double h4MarginTop = 14.94; // 0.83em
  static const double h4MarginBottom = 14.94;

  /// Heading 5 - 16px (1rem)
  /// HTML h5, small headings
  static const double h5FontSize = 16.0;
  static const FontWeight h5FontWeight = FontWeight.bold;
  static const double h5LineHeight = 24.0;
  static const double h5MarginTop = 13.28; // 0.83em
  static const double h5MarginBottom = 13.28;

  /// Heading 6 - 14px (0.875rem)
  /// HTML h6, smallest headings
  static const double h6FontSize = 14.0;
  static const FontWeight h6FontWeight = FontWeight.bold;
  static const double h6LineHeight = 20.0;
  static const double h6MarginTop = 11.62; // 0.83em
  static const double h6MarginBottom = 11.62;

  /// Body Large - 16px (1rem)
  /// Default body text size
  static const double bodyLargeFontSize = 16.0;
  static const FontWeight bodyLargeFontWeight = FontWeight.w400;
  static const double bodyLargeLineHeight = 24.0;

  /// Body Medium - 14px (0.875rem)
  /// Smaller body text
  static const double bodyMediumFontSize = 14.0;
  static const FontWeight bodyMediumFontWeight = FontWeight.w400;
  static const double bodyMediumLineHeight = 20.0;

  /// Body Small - 12px (0.75rem)
  /// Captions and fine print
  static const double bodySmallFontSize = 12.0;
  static const FontWeight bodySmallFontWeight = FontWeight.w400;
  static const double bodySmallLineHeight = 16.0;

  /// Label Large - 14px (0.875rem)
  /// Button text, emphasized labels
  static const double labelLargeFontSize = 14.0;
  static const FontWeight labelLargeFontWeight = FontWeight.w500;
  static const double labelLargeLineHeight = 20.0;

  /// Label Medium - 12px (0.75rem)
  /// Standard labels
  static const double labelMediumFontSize = 12.0;
  static const FontWeight labelMediumFontWeight = FontWeight.w500;
  static const double labelMediumLineHeight = 16.0;

  /// Label Small - 11px
  /// Tiny labels and tags
  static const double labelSmallFontSize = 11.0;
  static const FontWeight labelSmallFontWeight = FontWeight.w500;
  static const double labelSmallLineHeight = 16.0;

  /// Code/Monospace - 14px (0.875rem)
  /// Code blocks and inline code
  static const double codeFontSize = 14.0;
  static const FontWeight codeFontWeight = FontWeight.w400;
  static const double codeLineHeight = 20.0;
  static const String codeFontFamily = 'monospace';

  // ============================================================================
  // SPACING SCALE (8pt Grid System)
  // ============================================================================
  // Material Design uses 8dp baseline grid for consistent spacing

  /// 4px - Extra small spacing
  static const double space0_5 = 4.0;

  /// 8px - Small spacing (1 unit)
  static const double space1 = 8.0;

  /// 12px - Small-medium spacing
  static const double space1_5 = 12.0;

  /// 16px - Medium spacing (2 units)
  static const double space2 = 16.0;

  /// 24px - Medium-large spacing (3 units)
  static const double space3 = 24.0;

  /// 32px - Large spacing (4 units)
  static const double space4 = 32.0;

  /// 40px - Extra large spacing (5 units)
  static const double space5 = 40.0;

  /// 48px - Double extra large spacing (6 units)
  static const double space6 = 48.0;

  /// 56px - Triple extra large spacing (7 units)
  static const double space7 = 56.0;

  /// 64px - Huge spacing (8 units)
  static const double space8 = 64.0;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================
  // Material Design 3 corner radiuses

  /// 0px - No radius (square corners)
  static const double radiusNone = 0.0;

  /// 4px - Extra small radius
  static const double radiusXs = 4.0;

  /// 8px - Small radius
  static const double radiusSmall = 8.0;

  /// 12px - Medium radius
  static const double radiusMedium = 12.0;

  /// 16px - Large radius
  static const double radiusLarge = 16.0;

  /// 20px - Extra large radius
  static const double radiusXl = 20.0;

  /// 28px - Double extra large radius
  static const double radiusXxl = 28.0;

  /// 9999px - Full radius (pill shape)
  static const double radiusFull = 9999.0;

  // ============================================================================
  // ELEVATION (Shadow depths)
  // ============================================================================

  /// Level 0 - No elevation
  static const double elevation0 = 0.0;

  /// Level 1 - Subtle elevation (cards, chips)
  static const double elevation1 = 1.0;

  /// Level 2 - Low elevation (raised buttons)
  static const double elevation2 = 2.0;

  /// Level 3 - Medium elevation (FABs at rest)
  static const double elevation3 = 3.0;

  /// Level 4 - High elevation (navigation drawer)
  static const double elevation4 = 4.0;

  /// Level 5 - Very high elevation (modal bottom sheets)
  static const double elevation5 = 8.0;

  // ============================================================================
  // LIGHT THEME COLORS
  // ============================================================================

  /// Primary text color (Material Gray 900 - softer than pure black)
  /// Pure black (#000) is too harsh on screens, #212121 is easier on eyes
  static const Color textPrimary = Color(0xFF212121);

  /// Secondary text color (medium gray)
  static const Color textSecondary = Color(0xFF666666);

  /// Tertiary text color (light gray)
  static const Color textTertiary = Color(0xFF999999);

  /// Disabled text color
  static const Color textDisabled = Color(0xFFBDBDBD);

  /// Link color (Material Blue 700)
  static const Color linkColor = Color(0xFF1976D2);

  /// Link hover color (Material Blue 900)
  static const Color linkColorHover = Color(0xFF0D47A1);

  /// Link visited color (Material Purple 700)
  static const Color linkColorVisited = Color(0xFF7B1FA2);

  /// Selection background (Material Blue 100)
  static const Color selectionBackground = Color(0xFFBBDEFB);

  /// Selection text color
  static const Color selectionText = Color(0xFF000000);

  /// Mark/highlight background (Material Yellow 200)
  static const Color markBackground = Color(0xFFFFF59D);

  /// Mark text color
  static const Color markText = Color(0xFF000000);

  /// Code inline background (light gray)
  static const Color codeBackground = Color(0xFFF5F5F5);

  /// Code inline text color
  static const Color codeText = Color(0xFFE91E63);

  /// Code block background (slightly darker gray)
  static const Color codeBlockBackground = Color(0xFFEEEEEE);

  /// Code block text color
  static const Color codeBlockText = Color(0xFF000000);

  /// Quote border color (Material Gray 400)
  static const Color quoteBorder = Color(0xFFBDBDBD);

  /// Quote background (Material Gray 50)
  static const Color quoteBackground = Color(0xFFFAFAFA);

  /// Table border color (Material Gray 300)
  static const Color tableBorder = Color(0xFFE0E0E0);

  /// Table header background (Material Gray 100)
  static const Color tableHeaderBackground = Color(0xFFF5F5F5);

  /// Table row alternate background (Material Gray 50)
  static const Color tableRowAltBackground = Color(0xFFFAFAFA);

  /// Divider color (Material Gray 300)
  static const Color dividerColor = Color(0xFFE0E0E0);

  /// Error color (Material Red 700)
  static const Color errorColor = Color(0xFFD32F2F);

  /// Error background (Material Red 50)
  static const Color errorBackground = Color(0xFFFFEBEE);

  /// Success color (Material Green 700)
  static const Color successColor = Color(0xFF388E3C);

  /// Success background (Material Green 50)
  static const Color successBackground = Color(0xFFE8F5E9);

  /// Warning color (Material Orange 700)
  static const Color warningColor = Color(0xFFF57C00);

  /// Warning background (Material Orange 50)
  static const Color warningBackground = Color(0xFFFFF3E0);

  /// Info color (Material Blue 700)
  static const Color infoColor = Color(0xFF1976D2);

  /// Info background (Material Blue 50)
  static const Color infoBackground = Color(0xFFE3F2FD);

  // ============================================================================
  // DARK THEME COLORS
  // ============================================================================

  /// Dark theme primary text color
  static const Color darkTextPrimary = Color(0xFFFFFFFF);

  /// Dark theme secondary text color
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  /// Dark theme tertiary text color
  static const Color darkTextTertiary = Color(0xFF808080);

  /// Dark theme disabled text color
  static const Color darkTextDisabled = Color(0xFF606060);

  /// Dark theme link color (Material Blue 300)
  static const Color darkLinkColor = Color(0xFF64B5F6);

  /// Dark theme link hover color (Material Blue 200)
  static const Color darkLinkColorHover = Color(0xFF90CAF9);

  /// Dark theme link visited color (Material Purple 300)
  static const Color darkLinkColorVisited = Color(0xFFBA68C8);

  /// Dark theme selection background
  static const Color darkSelectionBackground = Color(0xFF1565C0);

  /// Dark theme selection text color
  static const Color darkSelectionText = Color(0xFFFFFFFF);

  /// Dark theme mark background (darker yellow)
  static const Color darkMarkBackground = Color(0xFFFBC02D);

  /// Dark theme mark text color
  static const Color darkMarkText = Color(0xFF000000);

  /// Dark theme code background
  static const Color darkCodeBackground = Color(0xFF2D2D2D);

  /// Dark theme code text color
  static const Color darkCodeText = Color(0xFFF48FB1);

  /// Dark theme code block background
  static const Color darkCodeBlockBackground = Color(0xFF1E1E1E);

  /// Dark theme code block text color
  static const Color darkCodeBlockText = Color(0xFFE0E0E0);

  /// Dark theme quote border color
  static const Color darkQuoteBorder = Color(0xFF616161);

  /// Dark theme quote background
  static const Color darkQuoteBackground = Color(0xFF2D2D2D);

  /// Dark theme table border color
  static const Color darkTableBorder = Color(0xFF424242);

  /// Dark theme table header background
  static const Color darkTableHeaderBackground = Color(0xFF2D2D2D);

  /// Dark theme table row alternate background
  static const Color darkTableRowAltBackground = Color(0xFF252525);

  /// Dark theme divider color
  static const Color darkDividerColor = Color(0xFF424242);

  /// Dark theme error color (Material Red 400)
  static const Color darkErrorColor = Color(0xFFEF5350);

  /// Dark theme error background
  static const Color darkErrorBackground = Color(0xFF5D2121);

  /// Dark theme success color (Material Green 400)
  static const Color darkSuccessColor = Color(0xFF66BB6A);

  /// Dark theme success background
  static const Color darkSuccessBackground = Color(0xFF1B5E20);

  /// Dark theme warning color (Material Orange 400)
  static const Color darkWarningColor = Color(0xFFFF9800);

  /// Dark theme warning background
  static const Color darkWarningBackground = Color(0xFF663C00);

  /// Dark theme info color (Material Blue 400)
  static const Color darkInfoColor = Color(0xFF42A5F5);

  /// Dark theme info background
  static const Color darkInfoBackground = Color(0xFF0D47A1);

  // ============================================================================
  // OPACITY VALUES
  // ============================================================================

  /// Fully transparent
  static const double opacity0 = 0.0;

  /// Subtle transparency
  static const double opacity10 = 0.1;

  /// Light transparency
  static const double opacity20 = 0.2;

  /// Medium transparency
  static const double opacity50 = 0.5;

  /// Heavy transparency
  static const double opacity80 = 0.8;

  /// Nearly opaque
  static const double opacity90 = 0.9;

  /// Fully opaque
  static const double opacity100 = 1.0;

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  /// Extra fast animation (100ms)
  static const Duration durationXs = Duration(milliseconds: 100);

  /// Fast animation (200ms)
  static const Duration durationShort = Duration(milliseconds: 200);

  /// Standard animation (300ms)
  static const Duration durationMedium = Duration(milliseconds: 300);

  /// Slow animation (500ms)
  static const Duration durationLong = Duration(milliseconds: 500);

  /// Very slow animation (800ms)
  static const Duration durationXl = Duration(milliseconds: 800);

  // ============================================================================
  // ANIMATION CURVES
  // ============================================================================

  /// Standard easing - most common
  static const Curve curveStandard = Curves.easeInOut;

  /// Emphasized easing - for important transitions
  static const Curve curveEmphasized = Curves.easeOutCubic;

  /// Decelerated easing - for entering elements
  static const Curve curveDecelerate = Curves.easeOut;

  /// Accelerated easing - for exiting elements
  static const Curve curveAccelerate = Curves.easeIn;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get TextStyle for heading level (1-6)
  static TextStyle headingStyle(int level, {Color? color}) {
    assert(level >= 1 && level <= 6, 'Heading level must be 1-6');

    switch (level) {
      case 1:
        return TextStyle(
          fontSize: h1FontSize,
          fontWeight: h1FontWeight,
          height: h1LineHeight / h1FontSize,
          color: color,
        );
      case 2:
        return TextStyle(
          fontSize: h2FontSize,
          fontWeight: h2FontWeight,
          height: h2LineHeight / h2FontSize,
          color: color,
        );
      case 3:
        return TextStyle(
          fontSize: h3FontSize,
          fontWeight: h3FontWeight,
          height: h3LineHeight / h3FontSize,
          color: color,
        );
      case 4:
        return TextStyle(
          fontSize: h4FontSize,
          fontWeight: h4FontWeight,
          height: h4LineHeight / h4FontSize,
          color: color,
        );
      case 5:
        return TextStyle(
          fontSize: h5FontSize,
          fontWeight: h5FontWeight,
          height: h5LineHeight / h5FontSize,
          color: color,
        );
      case 6:
        return TextStyle(
          fontSize: h6FontSize,
          fontWeight: h6FontWeight,
          height: h6LineHeight / h6FontSize,
          color: color,
        );
      default:
        throw ConfigurationException.invalidParameter(
          parameter: 'level',
          reason: 'Heading level must be between 1 and 6',
          validValues: '1, 2, 3, 4, 5, 6',
        );
    }
  }

  /// Get EdgeInsets for consistent spacing
  static EdgeInsets spacing({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (all != null) {
      return EdgeInsets.all(all);
    }
    if (horizontal != null || vertical != null) {
      return EdgeInsets.symmetric(
        horizontal: horizontal ?? 0,
        vertical: vertical ?? 0,
      );
    }
    return EdgeInsets.only(
      left: left ?? 0,
      top: top ?? 0,
      right: right ?? 0,
      bottom: bottom ?? 0,
    );
  }

  /// Get BorderRadius for consistent corners
  static BorderRadius radius(double value) {
    return BorderRadius.circular(value);
  }

  /// Get BoxShadow for elevation
  static List<BoxShadow> shadow(double elevation) {
    if (elevation <= 0) return [];

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: elevation * 2,
        offset: Offset(0, elevation),
      ),
    ];
  }

  // ============================================================================
  // CONTEXT-AWARE THEME COLORS
  // ============================================================================
  // These methods automatically pick the right color based on theme brightness

  /// Get primary text color based on theme
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : textPrimary;
  }

  /// Get secondary text color based on theme
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : textSecondary;
  }

  /// Get tertiary text color based on theme
  static Color getTextTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextTertiary
        : textTertiary;
  }

  /// Get disabled text color based on theme
  static Color getTextDisabled(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextDisabled
        : textDisabled;
  }

  /// Get link color based on theme
  static Color getLinkColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkLinkColor
        : linkColor;
  }

  /// Get link hover color based on theme
  static Color getLinkColorHover(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkLinkColorHover
        : linkColorHover;
  }

  /// Get link visited color based on theme
  static Color getLinkColorVisited(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkLinkColorVisited
        : linkColorVisited;
  }

  /// Get selection background color based on theme
  static Color getSelectionBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSelectionBackground
        : selectionBackground;
  }

  /// Get selection text color based on theme
  static Color getSelectionText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSelectionText
        : selectionText;
  }

  /// Get mark/highlight background color based on theme
  static Color getMarkBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkMarkBackground
        : markBackground;
  }

  /// Get mark text color based on theme
  static Color getMarkText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkMarkText
        : markText;
  }

  /// Get code inline background color based on theme
  static Color getCodeBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCodeBackground
        : codeBackground;
  }

  /// Get code inline text color based on theme
  static Color getCodeText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCodeText
        : codeText;
  }

  /// Get code block background color based on theme
  static Color getCodeBlockBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCodeBlockBackground
        : codeBlockBackground;
  }

  /// Get code block text color based on theme
  static Color getCodeBlockText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCodeBlockText
        : codeBlockText;
  }

  /// Get quote border color based on theme
  static Color getQuoteBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkQuoteBorder
        : quoteBorder;
  }

  /// Get quote background color based on theme
  static Color getQuoteBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkQuoteBackground
        : quoteBackground;
  }

  /// Get table border color based on theme
  static Color getTableBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTableBorder
        : tableBorder;
  }

  /// Get table header background color based on theme
  static Color getTableHeaderBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTableHeaderBackground
        : tableHeaderBackground;
  }

  /// Get table row alternate background color based on theme
  static Color getTableRowAltBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTableRowAltBackground
        : tableRowAltBackground;
  }

  /// Get divider color based on theme
  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkDividerColor
        : dividerColor;
  }

  /// Get error color based on theme
  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkErrorColor
        : errorColor;
  }

  /// Get error background color based on theme
  static Color getErrorBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkErrorBackground
        : errorBackground;
  }

  /// Get success color based on theme
  static Color getSuccessColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSuccessColor
        : successColor;
  }

  /// Get success background color based on theme
  static Color getSuccessBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSuccessBackground
        : successBackground;
  }

  /// Get warning color based on theme
  static Color getWarningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkWarningColor
        : warningColor;
  }

  /// Get warning background color based on theme
  static Color getWarningBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkWarningBackground
        : warningBackground;
  }

  /// Get info color based on theme
  static Color getInfoColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkInfoColor
        : infoColor;
  }

  /// Get info background color based on theme
  static Color getInfoBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkInfoBackground
        : infoBackground;
  }

  /// Get background color based on theme
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212) // Material dark background
        : const Color(0xFFFFFFFF); // White
  }

  /// Get surface color based on theme
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E) // Material dark surface
        : const Color(0xFFFFFFFF); // White
  }

  /// Get card color based on theme
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2D2D2D) // Material dark card
        : const Color(0xFFFFFFFF); // White
  }
}
