import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_math/hyper_render_math.dart';

void main() {
  group('MathNodePlugin', () {
    test('returns correct tag names', () {
      const plugin = MathNodePlugin();
      expect(plugin.tagNames, equals(['math']));
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
  });

  group('LatexNodePlugin', () {
    test('returns correct tag names', () {
      const plugin = LatexNodePlugin();
      expect(plugin.tagNames, equals(['latex']));
    });
  });
}
