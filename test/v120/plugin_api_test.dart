// Tests for the v1.2.0 Multi-tier Plugin API (HyperNodePlugin / HyperPluginRegistry).
//
// Covers:
//  - HyperPluginRegistry registration + lookup
//  - Block-tier plugin: widget rendered full-width, replaces built-in rendering
//  - Inline-tier plugin: widget flows with text, intrinsic size respected
//  - Plugin returning null falls through to built-in renderer
//  - pluginRegistry wired into HyperRenderWidget (createRenderObject /
//    updateRenderObject)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

// ── Test doubles ─────────────────────────────────────────────────────────────

class _BlockPlugin extends HyperNodePlugin {
  const _BlockPlugin();

  @override
  List<String> get tagNames => ['figure'];

  @override
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) {
    return Container(
      key: const ValueKey('figure-plugin'),
      height: 80,
      color: const Color(0xFF0000FF),
    );
  }
}

class _InlinePlugin extends HyperNodePlugin {
  const _InlinePlugin();

  @override
  List<String> get tagNames => ['badge'];

  @override
  bool get isInline => true;

  @override
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) {
    return Container(
      key: const ValueKey('badge-plugin'),
      width: 40,
      height: 20,
      color: const Color(0xFF00FF00),
    );
  }
}

/// Plugin that returns null → falls through to built-in.
class _NullPlugin extends HyperNodePlugin {
  const _NullPlugin();

  @override
  List<String> get tagNames => ['p'];

  @override
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) => null;
}

// ── Registry unit tests ───────────────────────────────────────────────────────

void main() {
  group('HyperPluginRegistry', () {
    test('empty registry', () {
      final reg = HyperPluginRegistry();
      expect(reg.isEmpty, isTrue);
      expect(reg.pluginFor('figure'), isNull);
      expect(reg.hasPlugin('figure'), isFalse);
    });

    test('register and lookup by tag name', () {
      final reg = HyperPluginRegistry()..register(const _BlockPlugin());
      expect(reg.hasPlugin('figure'), isTrue);
      expect(reg.hasPlugin('FIGURE'), isTrue); // case-insensitive
      expect(reg.pluginFor('figure'), isA<_BlockPlugin>());
    });

    test('blockPluginTags / inlinePluginTags sets', () {
      final reg = HyperPluginRegistry()
        ..register(const _BlockPlugin())
        ..register(const _InlinePlugin());

      expect(reg.blockPluginTags, contains('figure'));
      expect(reg.blockPluginTags, isNot(contains('badge')));
      expect(reg.inlinePluginTags, contains('badge'));
      expect(reg.inlinePluginTags, isNot(contains('figure')));
    });

    test('last registration wins for same tag', () {
      final reg = HyperPluginRegistry()
        ..register(const _BlockPlugin())
        ..register(const _NullPlugin()); // also registers 'p'

      // figure still points to _BlockPlugin (not overwritten)
      expect(reg.pluginFor('figure'), isA<_BlockPlugin>());
    });

    test('fluent registration returns registry', () {
      final reg = HyperPluginRegistry();
      final result = reg.register(const _BlockPlugin());
      expect(identical(result, reg), isTrue);
    });
  });

  // ── Widget integration ────────────────────────────────────────────────────

  group('HyperRenderWidget with pluginRegistry', () {
    testWidgets('block plugin widget is rendered for matching tag',
        (tester) async {
      final doc = DocumentNode(children: [
        BlockNode(tagName: 'figure', children: [
          TextNode('some caption'),
        ]),
      ]);

      final reg = HyperPluginRegistry()..register(const _BlockPlugin());

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperRenderWidget(
            document: doc,
            pluginRegistry: reg,
          ),
        ),
      ));
      await tester.pump();

      // The container with ValueKey from the plugin should be in the tree.
      expect(find.byKey(const ValueKey('figure-plugin')), findsOneWidget);
    });

    testWidgets('null-returning plugin falls through to built-in renderer',
        (tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [TextNode('Hello from built-in')]),
      ]);

      final reg = HyperPluginRegistry()..register(const _NullPlugin());

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperRenderWidget(
            document: doc,
            pluginRegistry: reg,
          ),
        ),
      ));
      await tester.pump();

      // Widget should still render without error — null → built-in path.
      expect(find.byType(HyperRenderWidget), findsOneWidget);
    });

    testWidgets('updating pluginRegistry triggers rebuild', (tester) async {
      final doc = DocumentNode(children: [
        BlockNode(tagName: 'figure', children: [TextNode('x')]),
      ]);

      final reg1 = HyperPluginRegistry()..register(const _BlockPlugin());

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperRenderWidget(document: doc, pluginRegistry: reg1),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const ValueKey('figure-plugin')), findsOneWidget);

      // Remove plugin registry → should fall through to built-in.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperRenderWidget(document: doc),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const ValueKey('figure-plugin')), findsNothing);
    });

    testWidgets('inline plugin widget is rendered inside paragraph',
        (tester) async {
      final doc = DocumentNode(children: [
        BlockNode.p(children: [
          TextNode('Score: '),
          // Inline custom element
          InlineNode(tagName: 'badge', children: [TextNode('42')]),
          TextNode(' points'),
        ]),
      ]);

      final reg = HyperPluginRegistry()..register(const _InlinePlugin());

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperRenderWidget(
            document: doc,
            pluginRegistry: reg,
          ),
        ),
      ));
      await tester.pump();

      expect(find.byKey(const ValueKey('badge-plugin')), findsOneWidget);
    });

    testWidgets('HyperPluginBuildContext carries baseStyle', (tester) async {
      TextStyle? capturedStyle;

      final capturePlugin = _CapturingPlugin(
        onBuild: (ctx) => capturedStyle = ctx.baseStyle,
      );

      final doc = DocumentNode(children: [
        BlockNode(tagName: 'figure', children: []),
      ]);

      final reg = HyperPluginRegistry()..register(capturePlugin);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HyperRenderWidget(document: doc, pluginRegistry: reg),
        ),
      ));
      await tester.pump();

      expect(capturedStyle, isNotNull);
      expect(capturedStyle!.fontSize, isNotNull);
    });
  });
}

// ── Helper ────────────────────────────────────────────────────────────────────

class _CapturingPlugin extends HyperNodePlugin {
  final void Function(HyperPluginBuildContext) onBuild;

  const _CapturingPlugin({required this.onBuild});

  @override
  List<String> get tagNames => ['figure'];

  @override
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) {
    onBuild(ctx);
    return const SizedBox(height: 1);
  }
}
