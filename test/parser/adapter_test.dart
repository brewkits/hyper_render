import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/src/parser/adapter.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

class MockAdapter extends DocumentAdapter {
  @override
  InputType get inputType => InputType.html;

  @override
  DocumentNode parse(String content) => DocumentNode();
}

void main() {
  group('DocumentAdapter', () {
    test('parseWithOptions defaults to parse', () {
      final adapter = MockAdapter();
      expect(adapter.parseWithOptions('content'), isA<DocumentNode>());
    });

    test('AdapterResult properties', () {
      final doc = DocumentNode();
      final result = AdapterResult(
        document: doc,
        extractedCss: 'div {}',
        warnings: ['warn'],
        parseDuration: const Duration(milliseconds: 10),
      );

      expect(result.document, doc);
      expect(result.extractedCss, 'div {}');
      expect(result.warnings, ['warn']);
      expect(result.parseDuration.inMilliseconds, 10);
    });
  });
}
