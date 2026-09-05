import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_math/hyper_render_math.dart';

void main() {
  group('MathNodePlugin', () {
    test('returns correct tag names', () {
      const plugin = MathNodePlugin();
      expect(plugin.tagNames, contains('math'));
      expect(plugin.tagNames, contains('latex'));
    });

    test('is not inline by default', () {
      const plugin = MathNodePlugin();
      expect(plugin.isInline, isFalse);
    });

    test('builds widget with text content', () {
      const plugin = MathNodePlugin();
      final node = BlockNode(
        tagName: 'math',
        children: [TextNode('E=mc^2')],
      );
      const ctx = HyperPluginBuildContext(
        baseStyle: TextStyle(),
      );

      final widget = plugin.buildWidget(node, ctx);
      expect(widget, isNotNull);
    });

    test('builds widget with src attribute', () {
      const plugin = MathNodePlugin();
      final node = BlockNode(
        tagName: 'math',
        attributes: {'src': 'E=mc^2'},
      );
      const ctx = HyperPluginBuildContext(
        baseStyle: TextStyle(),
      );

      final widget = plugin.buildWidget(node, ctx);
      expect(widget, isNotNull);
    });

    test('returns null if no content', () {
      const plugin = MathNodePlugin();
      final node = BlockNode(tagName: 'math');
      const ctx = HyperPluginBuildContext(
        baseStyle: TextStyle(),
      );

      final widget = plugin.buildWidget(node, ctx);
      expect(widget, isNull);
    });

    testWidgets(
        'structurally malformed LaTeX (unbalanced braces) falls back to '
        'the red-text error widget instead of throwing', (tester) async {
      const plugin = MathNodePlugin();
      // Missing the closing brace on \frac{a}{b — delimiter-balancing (the
      // streaming StreamSyntaxNormalizer's job) would not catch this: it's
      // an internal LaTeX structure error, not an unclosed $/$$ delimiter.
      final node = BlockNode(
        tagName: 'math',
        attributes: {'src': r'\frac{a}{b'},
      );
      const ctx = HyperPluginBuildContext(baseStyle: TextStyle());

      final widget = plugin.buildWidget(node, ctx);
      expect(widget, isNotNull);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      expect(tester.takeException(), isNull);
    });
  });
}
