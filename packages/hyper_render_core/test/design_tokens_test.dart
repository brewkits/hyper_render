import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('DesignTokens', () {
    group('Typography Scale', () {
      test('heading font sizes follow Material Design 3', () {
        expect(DesignTokens.h1FontSize, equals(32.0));
        expect(DesignTokens.h2FontSize, equals(24.0));
        expect(DesignTokens.h3FontSize, equals(20.0));
        expect(DesignTokens.h4FontSize, equals(18.0));
        expect(DesignTokens.h5FontSize, equals(16.0));
        expect(DesignTokens.h6FontSize, equals(14.0));
      });

      test('display sizes are larger than headings', () {
        expect(DesignTokens.displayLargeFontSize, greaterThan(DesignTokens.h1FontSize));
        expect(DesignTokens.displayMediumFontSize, greaterThan(DesignTokens.h1FontSize));
        expect(DesignTokens.displaySmallFontSize, greaterThan(DesignTokens.h1FontSize));
      });

      test('body text sizes are reasonable', () {
        expect(DesignTokens.bodyLargeFontSize, equals(16.0));
        expect(DesignTokens.bodyMediumFontSize, equals(14.0));
        expect(DesignTokens.bodySmallFontSize, equals(12.0));
      });

      test('label sizes are smaller', () {
        expect(DesignTokens.labelLargeFontSize, lessThanOrEqualTo(14.0));
        expect(DesignTokens.labelMediumFontSize, lessThanOrEqualTo(12.0));
        expect(DesignTokens.labelSmallFontSize, lessThanOrEqualTo(11.0));
      });

      test('heading font weights are bold', () {
        expect(DesignTokens.h1FontWeight, equals(FontWeight.bold));
        expect(DesignTokens.h2FontWeight, equals(FontWeight.bold));
        expect(DesignTokens.h3FontWeight, equals(FontWeight.bold));
      });

      test('body font weights are regular', () {
        expect(DesignTokens.bodyLargeFontWeight, equals(FontWeight.w400));
        expect(DesignTokens.bodyMediumFontWeight, equals(FontWeight.w400));
        expect(DesignTokens.bodySmallFontWeight, equals(FontWeight.w400));
      });

      test('line heights are proportional to font size', () {
        expect(DesignTokens.h1LineHeight, greaterThan(DesignTokens.h1FontSize));
        expect(DesignTokens.h2LineHeight, greaterThan(DesignTokens.h2FontSize));
        expect(DesignTokens.bodyLargeLineHeight, greaterThan(DesignTokens.bodyLargeFontSize));
      });

      test('heading margins follow 0.67-0.83em rhythm', () {
        // H1 margin should be around 0.67em
        final h1EmMargin = DesignTokens.h1MarginTop / DesignTokens.h1FontSize;
        expect(h1EmMargin, closeTo(0.67, 0.01));

        // H2-H6 margins should be around 0.83em
        final h2EmMargin = DesignTokens.h2MarginTop / DesignTokens.h2FontSize;
        expect(h2EmMargin, closeTo(0.83, 0.01));
      });

      test('code font uses monospace family', () {
        expect(DesignTokens.codeFontFamily, equals('monospace'));
      });
    });

    group('Spacing Scale (8pt Grid)', () {
      test('spacing follows 8pt baseline grid', () {
        expect(DesignTokens.space0_5, equals(4.0)); // 0.5x
        expect(DesignTokens.space1, equals(8.0)); // 1x
        expect(DesignTokens.space1_5, equals(12.0)); // 1.5x
        expect(DesignTokens.space2, equals(16.0)); // 2x
        expect(DesignTokens.space3, equals(24.0)); // 3x
        expect(DesignTokens.space4, equals(32.0)); // 4x
        expect(DesignTokens.space5, equals(40.0)); // 5x
        expect(DesignTokens.space6, equals(48.0)); // 6x
        expect(DesignTokens.space7, equals(56.0)); // 7x
        expect(DesignTokens.space8, equals(64.0)); // 8x
      });

      test('spacing values are multiples of 8', () {
        expect(DesignTokens.space1 % 8, equals(0));
        expect(DesignTokens.space2 % 8, equals(0));
        expect(DesignTokens.space3 % 8, equals(0));
        expect(DesignTokens.space4 % 8, equals(0));
      });

      test('spacing increases linearly', () {
        expect(DesignTokens.space2, greaterThan(DesignTokens.space1));
        expect(DesignTokens.space3, greaterThan(DesignTokens.space2));
        expect(DesignTokens.space4, greaterThan(DesignTokens.space3));
      });
    });

    group('Border Radius', () {
      test('radius values are progressive', () {
        expect(DesignTokens.radiusNone, equals(0.0));
        expect(DesignTokens.radiusXs, equals(4.0));
        expect(DesignTokens.radiusSmall, equals(8.0));
        expect(DesignTokens.radiusMedium, equals(12.0));
        expect(DesignTokens.radiusLarge, equals(16.0));
        expect(DesignTokens.radiusXl, equals(20.0));
        expect(DesignTokens.radiusXxl, equals(28.0));
        expect(DesignTokens.radiusFull, equals(9999.0));
      });

      test('radius increases progressively', () {
        expect(DesignTokens.radiusSmall, greaterThan(DesignTokens.radiusXs));
        expect(DesignTokens.radiusMedium, greaterThan(DesignTokens.radiusSmall));
        expect(DesignTokens.radiusLarge, greaterThan(DesignTokens.radiusMedium));
      });
    });

    group('Elevation', () {
      test('elevation levels are defined', () {
        expect(DesignTokens.elevation0, equals(0.0));
        expect(DesignTokens.elevation1, equals(1.0));
        expect(DesignTokens.elevation2, equals(2.0));
        expect(DesignTokens.elevation3, equals(3.0));
        expect(DesignTokens.elevation4, equals(4.0));
        expect(DesignTokens.elevation5, equals(8.0));
      });

      test('elevation increases with level', () {
        expect(DesignTokens.elevation1, greaterThan(DesignTokens.elevation0));
        expect(DesignTokens.elevation2, greaterThan(DesignTokens.elevation1));
        expect(DesignTokens.elevation3, greaterThan(DesignTokens.elevation2));
      });
    });

    group('Light Theme Colors', () {
      test('text colors have proper contrast hierarchy', () {
        // Primary is Material Gray 900 (softer than pure black)
        expect(DesignTokens.textPrimary.toARGB32(), equals(0xFF212121));

        // Secondary is lighter (higher luminance)
        expect(
          DesignTokens.textSecondary.computeLuminance(),
          greaterThan(DesignTokens.textPrimary.computeLuminance()),
        );

        // Tertiary is even lighter
        expect(
          DesignTokens.textTertiary.computeLuminance(),
          greaterThan(DesignTokens.textSecondary.computeLuminance()),
        );
      });

      test('link colors are blue-based', () {
        expect(DesignTokens.linkColor.toARGB32(), equals(0xFF1976D2));
        expect(DesignTokens.linkColorHover.toARGB32(), equals(0xFF0D47A1));
        expect(DesignTokens.linkColorVisited.toARGB32(), equals(0xFF7B1FA2));
      });

      test('semantic colors are defined', () {
        expect(DesignTokens.errorColor, isNotNull);
        expect(DesignTokens.successColor, isNotNull);
        expect(DesignTokens.warningColor, isNotNull);
        expect(DesignTokens.infoColor, isNotNull);
      });

      test('semantic background colors are lighter than foreground', () {
        // Error background should be lighter than error color
        expect(
          DesignTokens.errorBackground.computeLuminance(),
          greaterThan(DesignTokens.errorColor.computeLuminance()),
        );

        // Success background should be lighter than success color
        expect(
          DesignTokens.successBackground.computeLuminance(),
          greaterThan(DesignTokens.successColor.computeLuminance()),
        );
      });

      test('code colors are distinctive', () {
        expect(DesignTokens.codeBackground, isNotNull);
        expect(DesignTokens.codeText, isNotNull);
        expect(DesignTokens.codeBlockBackground, isNotNull);
        expect(DesignTokens.codeBlockText, isNotNull);
      });

      test('table colors provide visual structure', () {
        expect(DesignTokens.tableBorder, isNotNull);
        expect(DesignTokens.tableHeaderBackground, isNotNull);
        expect(DesignTokens.tableRowAltBackground, isNotNull);
      });
    });

    group('Dark Theme Colors', () {
      test('dark text colors have proper contrast', () {
        // Primary is lightest
        expect(DesignTokens.darkTextPrimary.toARGB32(), equals(0xFFFFFFFF));

        // Secondary is darker (lower luminance)
        expect(
          DesignTokens.darkTextSecondary.computeLuminance(),
          lessThan(DesignTokens.darkTextPrimary.computeLuminance()),
        );

        // Tertiary is even darker
        expect(
          DesignTokens.darkTextTertiary.computeLuminance(),
          lessThan(DesignTokens.darkTextSecondary.computeLuminance()),
        );
      });

      test('dark link colors are lighter than light theme', () {
        // Dark theme links should be lighter for visibility on dark background
        expect(
          DesignTokens.darkLinkColor.computeLuminance(),
          greaterThan(DesignTokens.linkColor.computeLuminance()),
        );
      });

      test('dark semantic colors are defined', () {
        expect(DesignTokens.darkErrorColor, isNotNull);
        expect(DesignTokens.darkSuccessColor, isNotNull);
        expect(DesignTokens.darkWarningColor, isNotNull);
        expect(DesignTokens.darkInfoColor, isNotNull);
      });

      test('dark backgrounds are darker than light theme', () {
        expect(
          DesignTokens.darkCodeBackground.computeLuminance(),
          lessThan(DesignTokens.codeBackground.computeLuminance()),
        );
      });
    });

    group('Opacity Values', () {
      test('opacity values are between 0 and 1', () {
        expect(DesignTokens.opacity0, equals(0.0));
        expect(DesignTokens.opacity10, equals(0.1));
        expect(DesignTokens.opacity20, equals(0.2));
        expect(DesignTokens.opacity50, equals(0.5));
        expect(DesignTokens.opacity80, equals(0.8));
        expect(DesignTokens.opacity90, equals(0.9));
        expect(DesignTokens.opacity100, equals(1.0));
      });

      test('opacity increases progressively', () {
        expect(DesignTokens.opacity10, greaterThan(DesignTokens.opacity0));
        expect(DesignTokens.opacity20, greaterThan(DesignTokens.opacity10));
        expect(DesignTokens.opacity50, greaterThan(DesignTokens.opacity20));
      });
    });

    group('Animation Durations', () {
      test('durations are defined', () {
        expect(DesignTokens.durationXs, equals(const Duration(milliseconds: 100)));
        expect(DesignTokens.durationShort, equals(const Duration(milliseconds: 200)));
        expect(DesignTokens.durationMedium, equals(const Duration(milliseconds: 300)));
        expect(DesignTokens.durationLong, equals(const Duration(milliseconds: 500)));
        expect(DesignTokens.durationXl, equals(const Duration(milliseconds: 800)));
      });

      test('durations increase progressively', () {
        expect(DesignTokens.durationShort, greaterThan(DesignTokens.durationXs));
        expect(DesignTokens.durationMedium, greaterThan(DesignTokens.durationShort));
        expect(DesignTokens.durationLong, greaterThan(DesignTokens.durationMedium));
      });
    });

    group('Animation Curves', () {
      test('curves are defined', () {
        expect(DesignTokens.curveStandard, isNotNull);
        expect(DesignTokens.curveEmphasized, isNotNull);
        expect(DesignTokens.curveDecelerate, isNotNull);
        expect(DesignTokens.curveAccelerate, isNotNull);
      });

      test('standard curve is ease in out', () {
        expect(DesignTokens.curveStandard, equals(Curves.easeInOut));
      });
    });

    group('Helper Methods', () {
      test('headingStyle creates correct TextStyle for each level', () {
        for (var level = 1; level <= 6; level++) {
          final style = DesignTokens.headingStyle(level);

          expect(style.fontSize, isNotNull);
          expect(style.fontWeight, isNotNull);
          expect(style.height, isNotNull);
        }
      });

      test('headingStyle h1 matches h1FontSize', () {
        final style = DesignTokens.headingStyle(1);

        expect(style.fontSize, equals(DesignTokens.h1FontSize));
        expect(style.fontWeight, equals(DesignTokens.h1FontWeight));
      });

      test('headingStyle h2 matches h2FontSize', () {
        final style = DesignTokens.headingStyle(2);

        expect(style.fontSize, equals(DesignTokens.h2FontSize));
        expect(style.fontWeight, equals(DesignTokens.h2FontWeight));
      });

      test('headingStyle accepts custom color', () {
        final style = DesignTokens.headingStyle(1, color: Colors.red);

        expect(style.color, equals(Colors.red));
      });

      test('headingStyle throws for invalid level', () {
        expect(() => DesignTokens.headingStyle(0), throwsAssertionError);
        expect(() => DesignTokens.headingStyle(7), throwsAssertionError);
      });

      test('spacing with all parameter', () {
        final padding = DesignTokens.spacing(all: DesignTokens.space2);

        expect(padding.left, equals(DesignTokens.space2));
        expect(padding.top, equals(DesignTokens.space2));
        expect(padding.right, equals(DesignTokens.space2));
        expect(padding.bottom, equals(DesignTokens.space2));
      });

      test('spacing with horizontal and vertical', () {
        final padding = DesignTokens.spacing(
          horizontal: DesignTokens.space2,
          vertical: DesignTokens.space3,
        );

        expect(padding.left, equals(DesignTokens.space2));
        expect(padding.right, equals(DesignTokens.space2));
        expect(padding.top, equals(DesignTokens.space3));
        expect(padding.bottom, equals(DesignTokens.space3));
      });

      test('spacing with individual sides', () {
        final padding = DesignTokens.spacing(
          left: DesignTokens.space1,
          top: DesignTokens.space2,
          right: DesignTokens.space3,
          bottom: DesignTokens.space4,
        );

        expect(padding.left, equals(DesignTokens.space1));
        expect(padding.top, equals(DesignTokens.space2));
        expect(padding.right, equals(DesignTokens.space3));
        expect(padding.bottom, equals(DesignTokens.space4));
      });

      test('radius creates BorderRadius', () {
        final borderRadius = DesignTokens.radius(DesignTokens.radiusMedium);

        expect(borderRadius, isA<BorderRadius>());
        expect(borderRadius.topLeft.x, equals(DesignTokens.radiusMedium));
      });

      test('shadow with zero elevation returns empty list', () {
        final shadows = DesignTokens.shadow(0);

        expect(shadows, isEmpty);
      });

      test('shadow with positive elevation returns shadows', () {
        final shadows = DesignTokens.shadow(DesignTokens.elevation2);

        expect(shadows, isNotEmpty);
        expect(shadows.first, isA<BoxShadow>());
      });

      test('shadow blur increases with elevation', () {
        final shadows1 = DesignTokens.shadow(DesignTokens.elevation1);
        final shadows3 = DesignTokens.shadow(DesignTokens.elevation3);

        expect(shadows3.first.blurRadius, greaterThan(shadows1.first.blurRadius));
      });
    });

    group('Consistency', () {
      test('small values are always smaller than large values', () {
        expect(DesignTokens.radiusSmall, lessThan(DesignTokens.radiusLarge));
        expect(DesignTokens.bodySmallFontSize, lessThan(DesignTokens.bodyLargeFontSize));
        expect(DesignTokens.space1, lessThan(DesignTokens.space4));
      });

      test('heading sizes decrease from h1 to h6', () {
        expect(DesignTokens.h1FontSize, greaterThan(DesignTokens.h2FontSize));
        expect(DesignTokens.h2FontSize, greaterThan(DesignTokens.h3FontSize));
        expect(DesignTokens.h3FontSize, greaterThan(DesignTokens.h4FontSize));
        expect(DesignTokens.h4FontSize, greaterThan(DesignTokens.h5FontSize));
        expect(DesignTokens.h5FontSize, greaterThan(DesignTokens.h6FontSize));
      });

      test('all colors are opaque', () {
        expect((DesignTokens.textPrimary.a * 255).round(), equals(255));
        expect((DesignTokens.linkColor.a * 255).round(), equals(255));
        expect((DesignTokens.errorColor.a * 255).round(), equals(255));
      });
    });

    group('Material Design 3 Compliance', () {
      test('follows 8pt baseline grid', () {
        final spacingValues = [
          DesignTokens.space1,
          DesignTokens.space2,
          DesignTokens.space3,
          DesignTokens.space4,
          DesignTokens.space5,
          DesignTokens.space6,
        ];

        for (final value in spacingValues) {
          expect(value % 8, equals(0), reason: '$value should be multiple of 8');
        }
      });

      test('type scale is harmonious', () {
        // Check that font sizes follow a reasonable scale ratio
        final ratio1 = DesignTokens.h2FontSize / DesignTokens.h3FontSize;
        final ratio2 = DesignTokens.h3FontSize / DesignTokens.h4FontSize;

        // Ratios should be similar (within 20%)
        expect((ratio1 - ratio2).abs() / ratio1, lessThan(0.2));
      });

      test('elevation shadows exist for standard levels', () {
        expect(DesignTokens.shadow(DesignTokens.elevation1).length, equals(1));
        expect(DesignTokens.shadow(DesignTokens.elevation2).length, equals(1));
        expect(DesignTokens.shadow(DesignTokens.elevation3).length, equals(1));
      });
    });
  });
}
