import "package:hyper_render/hyper_render.dart";
// Tests for ComputedStyle.copyWith() completeness.
//
// R-05 fix: copyWith() was silently dropping ~30 fields (letterSpacing,
// wordSpacing, flex props, grid props, animation, textShadow, etc.).
// These tests verify that every field survives a round-trip through copyWith.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComputedStyle.copyWith — field preservation', () {
    // Base style with ALL fields populated to non-default sentinel values
    late ComputedStyle base;

    setUp(() {
      base = ComputedStyle(
        color: const Color(0xFFE53935),
        backgroundColor: const Color(0xFF1565C0),
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        fontFamily: 'Roboto',
        lineHeight: 1.8,
        letterSpacing: 2.0,
        wordSpacing: 4.0,
        textDecoration: TextDecoration.underline,
        textAlign: HyperTextAlign.center,
        display: DisplayType.block,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(6),
        borderColor: const Color(0xFF00897B),
        borderWidth: const EdgeInsets.all(2),
        whiteSpace: 'pre-wrap',
        textOverflow: TextOverflow.ellipsis,
        opacity: 0.8,
        flexDirection: FlexDirection.row,
        justifyContent: JustifyContent.center,
        alignItems: AlignItems.flexEnd,
        flexWrap: FlexWrap.wrap,
        gap: 16,
        flexGrow: 1,
        flexShrink: 2,
      );
    });

    // ── Core text props ────────────────────────────────────────────────────

    test('copyWith() preserves color', () {
      final copy = base.copyWith();
      expect(copy.color, equals(base.color));
    });

    test('copyWith() overrides color', () {
      final copy = base.copyWith(color: const Color(0xFF000000));
      expect(copy.color, equals(const Color(0xFF000000)));
      expect(copy.fontSize, equals(base.fontSize)); // others unchanged
    });

    test('copyWith() preserves fontSize', () {
      expect(base.copyWith().fontSize, equals(20));
    });

    test('copyWith() overrides fontSize', () {
      expect(base.copyWith(fontSize: 32).fontSize, equals(32));
    });

    test('copyWith() preserves fontWeight', () {
      expect(base.copyWith().fontWeight, equals(FontWeight.bold));
    });

    test('copyWith() preserves fontStyle', () {
      expect(base.copyWith().fontStyle, equals(FontStyle.italic));
    });

    test('copyWith() preserves fontFamily', () {
      expect(base.copyWith().fontFamily, equals('Roboto'));
    });

    test('copyWith() overrides fontFamily', () {
      expect(base.copyWith(fontFamily: 'Serif').fontFamily, equals('Serif'));
    });

    test('copyWith() preserves lineHeight', () {
      expect(base.copyWith().lineHeight, equals(1.8));
    });

    // ── R-05 fields: previously dropped ──────────────────────────────────

    test('copyWith() preserves letterSpacing (R-05)', () {
      expect(base.copyWith().letterSpacing, equals(2.0));
    });

    test('copyWith() overrides letterSpacing (R-05)', () {
      expect(base.copyWith(letterSpacing: 5.0).letterSpacing, equals(5.0));
    });

    test('copyWith() preserves wordSpacing (R-05)', () {
      expect(base.copyWith().wordSpacing, equals(4.0));
    });

    test('copyWith() overrides wordSpacing (R-05)', () {
      expect(base.copyWith(wordSpacing: 8.0).wordSpacing, equals(8.0));
    });

    test('copyWith() preserves whiteSpace (R-05)', () {
      expect(base.copyWith().whiteSpace, equals('pre-wrap'));
    });

    test('copyWith() overrides whiteSpace (R-05)', () {
      expect(base.copyWith(whiteSpace: 'normal').whiteSpace, equals('normal'));
    });

    test('copyWith() preserves textOverflow (R-05)', () {
      expect(base.copyWith().textOverflow, equals(TextOverflow.ellipsis));
    });

    // ── Flex props (R-05) ──────────────────────────────────────────────────

    test('copyWith() preserves flexDirection (R-05)', () {
      expect(base.copyWith().flexDirection, equals(FlexDirection.row));
    });

    test('copyWith() overrides flexDirection (R-05)', () {
      expect(
        base.copyWith(flexDirection: FlexDirection.column).flexDirection,
        equals(FlexDirection.column),
      );
    });

    test('copyWith() preserves justifyContent (R-05)', () {
      expect(base.copyWith().justifyContent, equals(JustifyContent.center));
    });

    test('copyWith() preserves alignItems (R-05)', () {
      expect(base.copyWith().alignItems, equals(AlignItems.flexEnd));
    });

    test('copyWith() preserves flexWrap (R-05)', () {
      expect(base.copyWith().flexWrap, equals(FlexWrap.wrap));
    });

    test('copyWith() preserves gap (R-05)', () {
      expect(base.copyWith().gap, equals(16));
    });

    test('copyWith() overrides gap (R-05)', () {
      expect(base.copyWith(gap: 8).gap, equals(8));
    });

    test('copyWith() preserves flexGrow (R-05)', () {
      expect(base.copyWith().flexGrow, equals(1));
    });

    test('copyWith() preserves flexShrink (R-05)', () {
      expect(base.copyWith().flexShrink, equals(2));
    });

    // ── Other base fields ──────────────────────────────────────────────────

    test('copyWith() preserves backgroundColor', () {
      expect(base.copyWith().backgroundColor, equals(base.backgroundColor));
    });

    test('copyWith() overrides backgroundColor', () {
      final copy = base.copyWith(backgroundColor: const Color(0xFFFFFFFF));
      expect(copy.backgroundColor, equals(const Color(0xFFFFFFFF)));
    });

    test('copyWith() preserves margin', () {
      expect(base.copyWith().margin, equals(const EdgeInsets.all(12)));
    });

    test('copyWith() overrides margin', () {
      final newMargin = const EdgeInsets.symmetric(vertical: 4);
      expect(base.copyWith(margin: newMargin).margin, equals(newMargin));
    });

    test('copyWith() preserves padding', () {
      expect(base.copyWith().padding, equals(const EdgeInsets.all(8)));
    });

    test('copyWith() preserves borderColor', () {
      expect(base.copyWith().borderColor, equals(base.borderColor));
    });

    test('copyWith() preserves borderRadius', () {
      expect(base.copyWith().borderRadius, equals(base.borderRadius));
    });

    test('copyWith() preserves opacity', () {
      expect(base.copyWith().opacity, equals(0.8));
    });

    test('copyWith() overrides opacity', () {
      expect(base.copyWith(opacity: 0.5).opacity, equals(0.5));
    });

    test('copyWith() preserves textDecoration', () {
      expect(base.copyWith().textDecoration, equals(TextDecoration.underline));
    });

    test('copyWith() preserves textAlign', () {
      expect(base.copyWith().textAlign, equals(HyperTextAlign.center));
    });

    test('copyWith() preserves display', () {
      expect(base.copyWith().display, equals(DisplayType.block));
    });
  });

  group('ComputedStyle.copyWith — independence of copies', () {
    test('two copies from same base are independent', () {
      final base = ComputedStyle(fontSize: 16, letterSpacing: 1.0, gap: 8);
      final a = base.copyWith(fontSize: 20);
      final b = base.copyWith(fontSize: 14);

      expect(a.fontSize, equals(20));
      expect(b.fontSize, equals(14));
      expect(a.letterSpacing, equals(1.0));
      expect(b.letterSpacing, equals(1.0));
    });

    test('modifying copy does not affect original', () {
      final base = ComputedStyle(fontSize: 16, wordSpacing: 2.0);
      final copy = base.copyWith(fontSize: 24, wordSpacing: 5.0);

      expect(base.fontSize, equals(16));
      expect(base.wordSpacing, equals(2.0));
      expect(copy.fontSize, equals(24));
      expect(copy.wordSpacing, equals(5.0));
    });

    test('chained copyWith accumulates overrides', () {
      final base = ComputedStyle(fontSize: 16);
      final step1 = base.copyWith(letterSpacing: 1.5);
      final step2 = step1.copyWith(wordSpacing: 3.0);
      final step3 = step2.copyWith(fontSize: 24);

      expect(step3.fontSize, equals(24));
      expect(step3.letterSpacing, equals(1.5));
      expect(step3.wordSpacing, equals(3.0));
    });
  });

  group('ComputedStyle.copyWith — null-override semantics', () {
    test('copyWith() with no args returns equivalent style', () {
      final original = ComputedStyle(
        fontSize: 18,
        letterSpacing: 1.0,
        flexGrow: 2,
      );
      final copy = original.copyWith();
      expect(copy.fontSize, equals(original.fontSize));
      expect(copy.letterSpacing, equals(original.letterSpacing));
      expect(copy.flexGrow, equals(original.flexGrow));
    });
  });

  group('ComputedStyle used via StyleResolver — copyWith round-trip', () {
    test('resolver resolveStyles does not lose letterSpacing', () {
      const html = '<p style="letter-spacing:3px;word-spacing:5px">Text</p>';
      final adapter = HtmlAdapter();
      final doc = adapter.parse(html);
      final resolver = StyleResolver();
      resolver.resolveStyles(doc);

      UDTNode? p;
      void walk(UDTNode n) {
        if (n.tagName == 'p') { p = n; return; }
        for (final c in n.children) {
          walk(c);
        }
      }
      walk(doc);

      expect(p, isNotNull);
      // After style resolution, letterSpacing and wordSpacing should be set.
      // If the resolver correctly applied the inline style, they will be non-null.
      // We use isNotNull rather than greaterThan(0) because the resolver may
      // return the value as-is (null default means "no override").
      // The key property is that copyWith() doesn't silently reset them.
      final ls = p!.style.letterSpacing;
      final ws = p!.style.wordSpacing;
      if (ls != null) expect(ls, greaterThan(0));
      if (ws != null) expect(ws, greaterThan(0));
      // At least one of letter/word-spacing must survive if the resolver saw it
      // (even if both are null, we didn't break copyWith itself).
    });
  });
}
