import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/src/parser/adapter.dart';
import 'package:hyper_render/src/parser/delta/delta_adapter.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('DeltaAdapter', () {
    final adapter = DeltaAdapter();

    test('inputType is delta', () {
      expect(adapter.inputType, InputType.delta);
    });

    test('parse invalid JSON returns empty document with warning', () {
      final result = adapter.parseExtended('invalid-json');
      expect(result.document.children, isEmpty);
      expect(result.warnings, isNotEmpty);
      expect(result.warnings.first, contains('Failed to parse Delta'));
    });

    test('parse non-map JSON returns empty document with warning', () {
      final result = adapter.parseExtended('["not", "a", "map"]');
      expect(result.document.children, isEmpty);
      expect(result.warnings, isNotEmpty);
      expect(result.warnings.first, contains('not a valid JSON object'));
    });

    test('parse missing ops returns empty document with warning', () {
      final result = adapter.parseExtended('{"not_ops": []}');
      expect(result.document.children, isEmpty);
      expect(result.warnings, isNotEmpty);
      expect(result.warnings.first, contains('has no ops array'));
    });

    test('parse simple text', () {
      const delta = '{"ops": [{"insert": "Hello World\\n"}]}';
      final result = adapter.parseExtended(delta);
      expect(result.document.children, hasLength(1));
      final p = result.document.children[0] as BlockNode;
      expect(p.tagName, 'p');
      expect((p.children[0] as TextNode).text, 'Hello World');
    });

    test('parse text with multiple lines', () {
      const delta = '{"ops": [{"insert": "Line 1\\nLine 2\\nLine 3\\n"}]}';
      final result = adapter.parseExtended(delta);
      expect(result.document.children, hasLength(3));
    });

    test('parse text with inline attributes', () {
      const delta =
          '{"ops": [{"insert": "Bold", "attributes": {"bold": true}}, {"insert": " Italic", "attributes": {"italic": true}}, {"insert": "\\n"}]}';
      final result = adapter.parseExtended(delta);
      final p = result.document.children[0] as BlockNode;
      expect(p.children, hasLength(2));
      expect(p.children[0].style.fontWeight, FontWeight.bold);
      expect(p.children[1].style.fontStyle, FontStyle.italic);
    });

    test('parse headings', () {
      for (int i = 1; i <= 6; i++) {
        final delta =
            '{"ops": [{"insert": "Header $i"}, {"insert": "\\n", "attributes": {"header": $i}}]}';
        final result = adapter.parseExtended(delta);
        final h = result.document.children[0] as BlockNode;
        expect(h.tagName, 'h$i');
      }
    });

    test('parse lists', () {
      const delta = '''
      {
        "ops": [
          {"insert": "Item 1"}, {"insert": "\\n", "attributes": {"list": "bullet"}},
          {"insert": "Item 2"}, {"insert": "\\n", "attributes": {"list": "bullet"}},
          {"insert": "Ordered 1"}, {"insert": "\\n", "attributes": {"list": "ordered"}}
        ]
      }
      ''';
      final result = adapter.parseExtended(delta);
      // Blocks should be: [ul with 2 lis, ol with 1 li]
      expect(result.document.children, hasLength(2));
      expect((result.document.children[0] as BlockNode).tagName, 'ul');
      expect((result.document.children[1] as BlockNode).tagName, 'ol');
    });

    test('parse blockquote and code-block', () {
      const delta = '''
      {
        "ops": [
          {"insert": "Quote"}, {"insert": "\\n", "attributes": {"blockquote": true}},
          {"insert": "Code"}, {"insert": "\\n", "attributes": {"code-block": true}}
        ]
      }
      ''';
      final result = adapter.parseExtended(delta);
      expect((result.document.children[0] as BlockNode).tagName, 'blockquote');
      expect((result.document.children[1] as BlockNode).tagName, 'pre');
    });

    test('parse alignment and indent', () {
      const delta =
          '{"ops": [{"insert": "Aligned"}, {"insert": "\\n", "attributes": {"align": "center", "indent": 2}}]}';
      final result = adapter.parseExtended(delta);
      final p = result.document.children[0] as BlockNode;
      expect(p.style.textAlign, HyperTextAlign.center);
      expect(p.style.padding.left, 80.0);
    });

    test('parse links', () {
      const delta =
          '{"ops": [{"insert": "Google", "attributes": {"link": "https://google.com"}}, {"insert": "\\n"}]}';
      final result = adapter.parseExtended(delta);
      final p = result.document.children[0] as BlockNode;
      final a = p.children[0] as InlineNode;
      expect(a.tagName, 'a');
      expect(a.attributes['href'], 'https://google.com');
    });

    test('parse embeds (image, video, formula)', () {
      const delta = '''
      {
        "ops": [
          {"insert": {"image": "img.png"}, "attributes": {"alt": "Alt Text"}},
          {"insert": {"video": "vid.mp4"}},
          {"insert": {"formula": "e=mc^2"}},
          {"insert": "\\n"}
        ]
      }
      ''';
      final result = adapter.parseExtended(delta);
      final p = result.document.children[0] as BlockNode;
      expect(p.children[0], isA<AtomicNode>());
      expect((p.children[0] as AtomicNode).tagName, 'img');
      expect((p.children[1] as AtomicNode).tagName, 'video');
      expect((p.children[2] as AtomicNode).tagName, 'formula');
    });

    test('parse colors and font sizes', () {
      const delta = '''
      {
        "ops": [
          {"insert": "Text", "attributes": {"color": "#FF0000", "background": "blue", "size": "huge"}},
          {"insert": "\\n"}
        ]
      }
      ''';
      final result = adapter.parseExtended(delta);
      final p = result.document.children[0] as BlockNode;
      final style = p.children[0].style;
      expect(style.color, const Color(0xFFFF0000));
      expect(style.backgroundColor, const Color(0xFF0000FF));
      expect(style.fontSize, 32.0);
    });

    test('parse more attributes', () {
      const delta = '''
      {
        "ops": [
          {"insert": "Text", "attributes": {"underline": true, "strike": true, "script": "sub"}},
          {"insert": "More", "attributes": {"script": "super"}},
          {"insert": "\\n"}
        ]
      }
      ''';
      final result = adapter.parseExtended(delta);
      final p = result.document.children[0] as BlockNode;
      expect(p.children[0].style.textDecoration, isNotNull);
    });

    test('parse line attributes', () {
      const delta = '''
      {
        "ops": [
          {"insert": "Line 1"},
          {"insert": "\\n", "attributes": {"direction": "rtl", "header": 1}}
        ]
      }
      ''';
      final result = adapter.parseExtended(delta);
      final h = result.document.children[0] as BlockNode;
      expect(h.tagName, 'h1');
    });

    test('parse unknown attributes does not crash', () {
      const delta =
          '{"ops": [{"insert": "Text", "attributes": {"unknown": "value"}}, {"insert": "\\n"}]}';
      final result = adapter.parseExtended(delta);
      expect(result.document.children, isNotEmpty);
    });

    test('parse numeric font size and px suffix', () {
      const delta = '''
      {
        "ops": [
          {"insert": "Text", "attributes": {"size": 24}},
          {"insert": "More", "attributes": {"size": "15px"}},
          {"insert": "\\n"}
        ]
      }
      ''';
      final result = adapter.parseExtended(delta);
      expect(result.document.children, isNotEmpty);
      final p = result.document.children[0] as BlockNode;
      expect(p.children, isNotEmpty);
      expect(p.children[0].style.fontSize, 24.0);
      expect(p.children[1].style.fontSize, 15.0);
    });
  });
}
