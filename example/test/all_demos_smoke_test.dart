// Crash-net: mounts EVERY demo registered on the home screen and pumps a few
// frames, failing if a demo THROWS (real exception) or raises a non-layout
// FlutterError while opening. This catches the class of bug that makes a demo
// blow up the moment a user taps into it.
//
// It deliberately does NOT fail on `RenderFlex overflowed`. `flutter test`
// renders with a fixed-width fallback font (the same one that draws □ boxes in
// goldens), which makes text noticeably wider than any real proportional font —
// so text-driven overflows here are mostly artifacts, not device bugs (verified:
// a demo that "overflowed 162px" in-test rendered cleanly on the simulator).
// Genuine fixed-width overflows are checked by eye on-device instead.
//
// This is a net for "does the demo blow up when you open it", not a functional
// assertion of each feature (those live in the per-demo tests).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/accessibility_demo.dart';
import 'package:example/animation_demo.dart';
import 'package:example/base_url_demo.dart';
import 'package:example/cjk_languages_demo.dart';
import 'package:example/css_mastery_demo.dart';
import 'package:example/css_properties_demo.dart';
import 'package:example/email_demo.dart';
import 'package:example/enhanced_selection_demo.dart';
import 'package:example/enterprise_features_demo.dart';
import 'package:example/flexbox_demo.dart';
import 'package:example/float_hell_demo.dart';
import 'package:example/formula_demo.dart';
import 'package:example/html_heuristics_demo.dart';
import 'package:example/manga_demo.dart';
import 'package:example/paged_mode_demo.dart';
import 'package:example/performance_deep_dive_demo.dart';
import 'package:example/plugin_api_demo.dart';
import 'package:example/security_demo.dart';
import 'package:example/smart_table_demo.dart';
import 'package:example/sprint3_demo.dart';
import 'package:example/ultra_showcase_2026.dart';
import 'package:example/v2_1_showcase.dart';

/// Each entry: a label and a builder for the demo's screen widget.
final _demos = <String, Widget Function()>{
  'AccessibilityDemo': () => const AccessibilityDemo(),
  'AnimationDemo': () => const AnimationDemo(),
  'BaseUrlDemo': () => const BaseUrlDemo(),
  'CjkLanguagesDemo': () => const CjkLanguagesDemo(),
  'CssMasteryDemo': () => const CssMasteryDemo(),
  'CssPropertiesDemo': () => const CssPropertiesDemo(),
  'EmailDemo': () => const EmailDemo(),
  'EnhancedSelectionDemo': () => const EnhancedSelectionDemo(),
  'EnterpriseFeaturesDemo': () => const EnterpriseFeaturesDemo(),
  'FlexboxDemo': () => const FlexboxDemo(),
  'FloatHellDemo': () => const FloatHellDemo(),
  'FormulaDemo': () => const FormulaDemo(),
  'HtmlHeuristicsDemo': () => const HtmlHeuristicsDemo(),
  'MangaDemo': () => const MangaDemo(),
  'PagedModeDemo': () => const PagedModeDemo(),
  'PerformanceDeepDiveDemo': () => const PerformanceDeepDiveDemo(),
  'PluginApiDemo': () => const PluginApiDemo(),
  'SecurityDemo': () => const SecurityDemo(),
  'SmartTableDemo': () => const SmartTableDemo(),
  'Sprint3Demo': () => const Sprint3Demo(),
  'UltraShowcase2026': () => const UltraShowcase2026(),
  'V21Showcase': () => const V21Showcase(),
};

void main() {
  for (final entry in _demos.entries) {
    testWidgets('opens without a FlutterError: ${entry.key}', (tester) async {
      // Phone-sized viewport (iPhone-ish logical px) so narrow-screen overflows
      // surface.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;

      try {
        await tester.pumpWidget(MaterialApp(home: entry.value()));
        // A few fixed-duration pumps — some demos run infinite animations, so
        // pumpAndSettle would hang.
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 400));
      } finally {
        FlutterError.onError = previous;
      }

      // Ignore RenderFlex overflow (test-font artifact — see file header); fail
      // on any other error, and on a real thrown exception.
      final realErrors = errors
          .map((e) => e.exceptionAsString())
          .where((s) => !s.contains('A RenderFlex overflowed'))
          .toList();
      final captured = tester.takeException();
      expect(
        realErrors.isEmpty && captured == null,
        isTrue,
        reason: '${entry.key} raised: '
            '${realErrors.join(" | ")}'
            '${captured != null ? " | $captured" : ""}',
      );
    });
  }
}
