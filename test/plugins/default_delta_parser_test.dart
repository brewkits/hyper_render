import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/src/plugins/default_delta_parser.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('DefaultDeltaParser', () {
    const parser = DefaultDeltaParser();

    test('contentType returns ContentType.delta', () {
      expect(parser.contentType, ContentType.delta);
    });

    test('parse simple delta', () {
      const deltaJson = '{"ops":[{"insert":"Hello World\\n"}]}';
      final doc = parser.parse(deltaJson);

      expect(doc, isA<DocumentNode>());
      expect(doc.children, isNotEmpty);
    });

    test('parse delta with attributes', () {
      const deltaJson =
          '{"ops":[{"insert":"Bold","attributes":{"bold":true}},{"insert":"\\n"}]}';
      final doc = parser.parse(deltaJson);

      expect(doc.children, isNotEmpty);
    });

    test('parseWithOptions delegates to parse', () {
      const deltaJson = '{"ops":[{"insert":"Hello\\n"}]}';
      final doc =
          parser.parseWithOptions(deltaJson, baseUrl: 'https://example.com');

      expect(doc.children, isNotEmpty);
    });

    test('parseToSections returns a single section', () {
      const deltaJson = '{"ops":[{"insert":"Hello\\n"}]}';
      final sections = parser.parseToSections(deltaJson);

      expect(sections, hasLength(1));
    });

    test('parseExtended returns ParseResult', () {
      const deltaJson = '{"ops":[{"insert":"Hello\\n"}]}';
      final result = parser.parseExtended(deltaJson);

      expect(result, isA<ParseResult>());
      expect(result.document.children, isNotEmpty);
    });

    test('DeltaParserExtension allows easy parsing', () {
      const deltaJson = '{"ops":[{"insert":"Extension\\n"}]}';
      final doc = deltaJson.parseDelta();

      expect(doc.children, isNotEmpty);
    });
  });
}
