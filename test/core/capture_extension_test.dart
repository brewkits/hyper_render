import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/src/core/capture_extension.dart';

void main() {
  group('HyperCaptureExtension', () {
    testWidgets('toImage throws error if key not attached', (WidgetTester tester) async {
      final key = GlobalKey();
      expect(() => key.toImage(), throwsStateError);
    });

    testWidgets('toImage captures image when attached to RepaintBoundary', (WidgetTester tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: const SizedBox(width: 10, height: 10, child: Text('A')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      final image = await key.toImage(pixelRatio: 1.0);
      expect(image, isNotNull);
      image.dispose();
    });
  });
}
