import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('Dark Mode Support', () {
    // Helper to create a widget with specific brightness
    Widget testWidget({
      required Brightness brightness,
      required Widget Function(BuildContext) builder,
    }) {
      return MaterialApp(
        home: Theme(
          data: ThemeData(brightness: brightness),
          child: Builder(builder: builder),
        ),
      );
    }

    group('Text Colors', () {
      testWidgets('getTextPrimary adapts to theme brightness', (tester) async {
        // Test light theme
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              final color = DesignTokens.getTextPrimary(context);
              expect(color, equals(DesignTokens.textPrimary));
              return const SizedBox();
            },
          ),
        );

        // Test dark theme
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              final color = DesignTokens.getTextPrimary(context);
              expect(color, equals(DesignTokens.darkTextPrimary));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getTextSecondary adapts to theme brightness',
          (tester) async {
        // Test light theme
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              final color = DesignTokens.getTextSecondary(context);
              expect(color, equals(DesignTokens.textSecondary));
              return const SizedBox();
            },
          ),
        );

        // Test dark theme
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              final color = DesignTokens.getTextSecondary(context);
              expect(color, equals(DesignTokens.darkTextSecondary));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getTextTertiary adapts to theme brightness', (tester) async {
        // Test light theme
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              final color = DesignTokens.getTextTertiary(context);
              expect(color, equals(DesignTokens.textTertiary));
              return const SizedBox();
            },
          ),
        );

        // Test dark theme
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              final color = DesignTokens.getTextTertiary(context);
              expect(color, equals(DesignTokens.darkTextTertiary));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getTextDisabled adapts to theme brightness', (tester) async {
        // Test light theme
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              final color = DesignTokens.getTextDisabled(context);
              expect(color, equals(DesignTokens.textDisabled));
              return const SizedBox();
            },
          ),
        );

        // Test dark theme
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              final color = DesignTokens.getTextDisabled(context);
              expect(color, equals(DesignTokens.darkTextDisabled));
              return const SizedBox();
            },
          ),
        );
      });
    });

    group('Link Colors', () {
      testWidgets('getLinkColor adapts to theme brightness', (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getLinkColor(context),
                  equals(DesignTokens.linkColor));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getLinkColor(context),
                  equals(DesignTokens.darkLinkColor));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getLinkColorHover adapts to theme brightness',
          (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getLinkColorHover(context),
                  equals(DesignTokens.linkColorHover));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getLinkColorHover(context),
                  equals(DesignTokens.darkLinkColorHover));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getLinkColorVisited adapts to theme brightness',
          (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getLinkColorVisited(context),
                  equals(DesignTokens.linkColorVisited));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getLinkColorVisited(context),
                  equals(DesignTokens.darkLinkColorVisited));
              return const SizedBox();
            },
          ),
        );
      });
    });

    group('Selection Colors', () {
      testWidgets('getSelectionBackground adapts to theme brightness',
          (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getSelectionBackground(context),
                  equals(DesignTokens.selectionBackground));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getSelectionBackground(context),
                  equals(DesignTokens.darkSelectionBackground));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getSelectionText adapts to theme brightness',
          (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getSelectionText(context),
                  equals(DesignTokens.selectionText));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getSelectionText(context),
                  equals(DesignTokens.darkSelectionText));
              return const SizedBox();
            },
          ),
        );
      });
    });

    group('Code Colors', () {
      testWidgets('getCodeBackground adapts to theme brightness',
          (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getCodeBackground(context),
                  equals(DesignTokens.codeBackground));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getCodeBackground(context),
                  equals(DesignTokens.darkCodeBackground));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getCodeText adapts to theme brightness', (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getCodeText(context),
                  equals(DesignTokens.codeText));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getCodeText(context),
                  equals(DesignTokens.darkCodeText));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getCodeBlockBackground adapts to theme brightness',
          (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getCodeBlockBackground(context),
                  equals(DesignTokens.codeBlockBackground));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getCodeBlockBackground(context),
                  equals(DesignTokens.darkCodeBlockBackground));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getCodeBlockText adapts to theme brightness',
          (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getCodeBlockText(context),
                  equals(DesignTokens.codeBlockText));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getCodeBlockText(context),
                  equals(DesignTokens.darkCodeBlockText));
              return const SizedBox();
            },
          ),
        );
      });
    });

    group('Semantic Colors', () {
      testWidgets('getErrorColor adapts to theme brightness', (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getErrorColor(context),
                  equals(DesignTokens.errorColor));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getErrorColor(context),
                  equals(DesignTokens.darkErrorColor));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getSuccessColor adapts to theme brightness', (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getSuccessColor(context),
                  equals(DesignTokens.successColor));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getSuccessColor(context),
                  equals(DesignTokens.darkSuccessColor));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getWarningColor adapts to theme brightness', (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getWarningColor(context),
                  equals(DesignTokens.warningColor));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getWarningColor(context),
                  equals(DesignTokens.darkWarningColor));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getInfoColor adapts to theme brightness', (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getInfoColor(context),
                  equals(DesignTokens.infoColor));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getInfoColor(context),
                  equals(DesignTokens.darkInfoColor));
              return const SizedBox();
            },
          ),
        );
      });
    });

    group('UI Element Colors', () {
      testWidgets('getQuoteBorder adapts to theme brightness', (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getQuoteBorder(context),
                  equals(DesignTokens.quoteBorder));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getQuoteBorder(context),
                  equals(DesignTokens.darkQuoteBorder));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getTableBorder adapts to theme brightness', (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getTableBorder(context),
                  equals(DesignTokens.tableBorder));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getTableBorder(context),
                  equals(DesignTokens.darkTableBorder));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getDividerColor adapts to theme brightness', (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getDividerColor(context),
                  equals(DesignTokens.dividerColor));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getDividerColor(context),
                  equals(DesignTokens.darkDividerColor));
              return const SizedBox();
            },
          ),
        );
      });
    });

    group('Background Colors', () {
      testWidgets('getBackgroundColor adapts to theme brightness',
          (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getBackgroundColor(context),
                  equals(const Color(0xFFFFFFFF)));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getBackgroundColor(context),
                  equals(const Color(0xFF121212)));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getSurfaceColor adapts to theme brightness', (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getSurfaceColor(context),
                  equals(const Color(0xFFFFFFFF)));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getSurfaceColor(context),
                  equals(const Color(0xFF1E1E1E)));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('getCardColor adapts to theme brightness', (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.light,
            builder: (context) {
              expect(DesignTokens.getCardColor(context),
                  equals(const Color(0xFFFFFFFF)));
              return const SizedBox();
            },
          ),
        );

        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              expect(DesignTokens.getCardColor(context),
                  equals(const Color(0xFF2D2D2D)));
              return const SizedBox();
            },
          ),
        );
      });
    });

    group('Integration', () {
      testWidgets('all color getters work together', (tester) async {
        await tester.pumpWidget(
          testWidget(
            brightness: Brightness.dark,
            builder: (context) {
              // Verify multiple getters work in same context
              expect(DesignTokens.getTextPrimary(context),
                  equals(DesignTokens.darkTextPrimary));
              expect(DesignTokens.getLinkColor(context),
                  equals(DesignTokens.darkLinkColor));
              expect(DesignTokens.getErrorColor(context),
                  equals(DesignTokens.darkErrorColor));
              expect(DesignTokens.getBackgroundColor(context),
                  equals(const Color(0xFF121212)));
              return const SizedBox();
            },
          ),
        );
      });

      testWidgets('works with nested themes', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Theme(
              data: ThemeData(brightness: Brightness.light),
              child: Builder(
                builder: (outerContext) {
                  return Theme(
                    data: ThemeData(brightness: Brightness.dark),
                    child: Builder(
                      builder: (innerContext) {
                        // Inner context should use dark theme
                        expect(DesignTokens.getTextPrimary(innerContext),
                            equals(DesignTokens.darkTextPrimary));
                        return const SizedBox();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      });
    });
  });
}
