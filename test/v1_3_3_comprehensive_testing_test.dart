// ignore_for_file: prefer_const_constructors, avoid_print, no_leading_underscores_for_local_identifiers
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';


UDTNode? findNodeByTagName(UDTNode node, String tagName) {
  if (node.tagName == tagName) return node;
  for (final child in node.children) {
    final found = findNodeByTagName(child, tagName);
    if (found != null) return found;
  }
  return null;
}

DocumentNode _parseAndResolve(String html) {
  final doc = HtmlAdapter().parse(html);
  StyleResolver().resolveStyles(doc);
  return doc;
}

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // 1. UNIT TESTING
  // ═══════════════════════════════════════════════════════════════════════════
  group('v1.3.3 Unit Tests', () {
    test('FloatCarryover equality handles imagePixelOffset correctly', () {
      final f1 = FloatCarryover(
        direction: HyperFloat.left,
        width: 150.0,
        overhangHeight: 80.0,
        imagePixelOffset: 30.0,
      );
      final f2 = FloatCarryover(
        direction: HyperFloat.left,
        width: 150.0,
        overhangHeight: 80.0,
        imagePixelOffset: 30.0,
      );
      final f3 = FloatCarryover(
        direction: HyperFloat.left,
        width: 150.0,
        overhangHeight: 80.0,
        imagePixelOffset: 45.0, // different offset
      );

      expect(f1, equals(f2));
      expect(f1, isNot(equals(f3)));
      expect(f1.hashCode, equals(f2.hashCode));
      expect(f1.hashCode, isNot(equals(f3.hashCode)));
    });

    test('ComputedStyle copying retains object-fit value', () {
      final style = ComputedStyle(objectFit: 'contain');
      final copied = style.copyWith(objectFit: 'cover');
      final copiedNoChange = style.copyWith(color: Colors.red);

      expect(copied.objectFit, equals('cover'));
      expect(copiedNoChange.objectFit, equals('contain'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. INTEGRATION TESTING
  // ═══════════════════════════════════════════════════════════════════════════
  group('v1.3.3 Integration Tests', () {
    testWidgets('onMemoryPressure triggers in Sync mode', (tester) async {
      int triggerCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<p>Sync text</p>',
              mode: HyperRenderMode.sync,
              onMemoryPressure: () {
                triggerCount++;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      tester.binding.handleMemoryPressure();
      await tester.pump();

      expect(triggerCount, equals(1));
    });

    testWidgets('onMemoryPressure triggers in Virtualized mode', (tester) async {
      int triggerCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: HyperViewer(
                html: '<p>Line 1</p><p>Line 2</p><p>Line 3</p>',
                mode: HyperRenderMode.virtualized,
                onMemoryPressure: () {
                  triggerCount++;
                },
              ),
            ),
          ),
        ),
      );
      // Wait for async parsing and initial frame rendering using discrete pumps
      await tester.pump(Duration(milliseconds: 100));
      await tester.pump(Duration(milliseconds: 100));

      tester.binding.handleMemoryPressure();
      await tester.pump();

      expect(triggerCount, equals(1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. SYSTEM TESTING
  // ═══════════════════════════════════════════════════════════════════════════
  group('v1.3.3 System Tests', () {
    testWidgets('Renders image with valid object-fit inside HyperViewer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<img src="https://example.com/logo.png" style="object-fit: cover; width: 100px; height: 100px;" />',
              mode: HyperRenderMode.sync,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(HyperViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. PERFORMANCE TESTING
  // ═══════════════════════════════════════════════════════════════════════════
  group('v1.3.3 Performance Benchmarks', () {
    test('Benchmark parsing of object-fit styles', () {
      final html = StringBuffer('<div>');
      for (int i = 0; i < 500; i++) {
        html.write('<img style="object-fit: cover;" />');
      }
      html.write('</div>');

      final adapter = HtmlAdapter();
      final stopwatch = Stopwatch()..start();
      final doc = adapter.parse(html.toString());
      stopwatch.stop();

      print('Parsed 500 image nodes with object-fit: ${stopwatch.elapsedMilliseconds}ms');
      expect(doc.children, isNotEmpty);
      expect(stopwatch.elapsedMilliseconds, lessThan(150),
          reason: 'Parsing 500 image tags must be fast');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. STRESS TESTING
  // ═══════════════════════════════════════════════════════════════════════════
  group('v1.3.3 Stress Tests', () {
    testWidgets('Handles a document containing multiple floated images', (tester) async {
      final buffer = StringBuffer('<div>');
      for (int i = 0; i < 100; i++) {
        buffer.write('<img src="https://example.com/img$i.png" style="float: left; width: 20px; height: 20px;" />');
        buffer.write('<p>Text content wrapper $i</p>');
      }
      buffer.write('</div>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: HyperViewer(
                html: buffer.toString(),
                mode: HyperRenderMode.virtualized,
              ),
            ),
          ),
        ),
      );
      await tester.pump(Duration(milliseconds: 100));
      await tester.pump(Duration(milliseconds: 100));

      expect(find.byType(HyperViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. SECURITY TESTING
  // ═══════════════════════════════════════════════════════════════════════════
  group('v1.3.3 Security Testing', () {
    test('XSS sanitization strips or invalidates malformed object-fit values', () {
      final doc = _parseAndResolve(
        '<img style="object-fit: expression(alert(1));" />',
      );
      final img = findNodeByTagName(doc, 'img');
      expect(img, isNotNull);
      expect(img!.style.objectFit, isNull,
          reason: 'Malformed object-fit value with potential script execution must be filtered');
    });

    test('Valid CSS properties are retained while unknown / malicious are stripped', () {
      final doc = _parseAndResolve(
        '<img style="object-fit: cover; width: url(javascript:alert(1));" />',
      );
      final img = findNodeByTagName(doc, 'img');
      expect(img, isNotNull);
      expect(img!.style.objectFit, equals('cover'),
          reason: 'Valid properties must be kept');
      expect(img.style.width, isNull,
          reason: 'Malicious CSS URL expression must be filtered out');
    });
  });
}
