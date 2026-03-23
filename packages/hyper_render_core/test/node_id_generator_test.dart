import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

/// Tests for UDTNode ID generation.
///
/// The codebase does not expose a `NodeIdGenerator` class.  Node IDs are
/// assigned automatically inside [UDTNode]'s constructor using a static
/// counter, or can be provided explicitly via the `id` parameter.
void main() {
  group('UDTNode ID generation', () {
    test('generates unique IDs for distinct nodes', () {
      final node1 = TextNode('Hello');
      final node2 = TextNode('World');
      final node3 = TextNode('!');

      expect(node1.id, isNot(equals(node2.id)));
      expect(node2.id, isNot(equals(node3.id)));
      expect(node1.id, isNot(equals(node3.id)));
    });

    test('ID starts with node_ prefix', () {
      final node = TextNode('Test');
      expect(node.id, startsWith('node_'));
    });

    test('auto-generated ID has node_ prefix', () {
      // TextNode does not expose an `id` constructor parameter, but all
      // auto-generated IDs start with "node_".
      final node = TextNode('Test');
      expect(node.id, startsWith('node_'));
    });

    test('auto-generated IDs are non-empty', () {
      final node = BlockNode(tagName: 'div');
      expect(node.id, isNotEmpty);
    });

    test('different node types get unique IDs', () {
      final block = BlockNode(tagName: 'div');
      final inline = InlineNode(tagName: 'span');
      final text = TextNode('hello');

      final ids = {block.id, inline.id, text.id};
      // All three should be distinct
      expect(ids.length, equals(3));
    });

    test('IDs are strings', () {
      final node = TextNode('Test');
      expect(node.id, isA<String>());
    });

    test('BlockNode gets a unique auto-generated ID', () {
      final node1 = BlockNode(tagName: 'div');
      final node2 = BlockNode(tagName: 'div');
      expect(node1.id, isNot(equals(node2.id)));
    });

    test('stress test — 1000 nodes have unique IDs', () {
      final ids = <String>{};
      for (var i = 0; i < 1000; i++) {
        ids.add(TextNode('Node $i').id);
      }
      expect(ids.length, equals(1000));
    });

    test('findById locates node by auto-generated ID', () {
      final child = TextNode('child');
      final root = DocumentNode(children: [child]);

      final found = root.findById(child.id);
      expect(found, equals(child));
    });

    test('findById returns null for non-existent ID', () {
      final root = DocumentNode(children: [TextNode('hello')]);
      expect(root.findById('nonexistent-id'), isNull);
    });
  });
}
