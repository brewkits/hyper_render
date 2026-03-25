import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

/// Tests for Aesthetic Features (Phase 2 & 3):
///   - CSS Box Shadows
///   - CSS Linear Gradients
///   - CSS Filters (Blur, Brightness, Contrast)
///   - CSS Backdrop Filter
///   - CSS Word Breaking
void main() {
  group('Aesthetic Features - Parsing & Layout', () {
    testWidgets('Parses box-shadow property', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html:
                  '<div style="box-shadow: 0 4px 8px rgba(0,0,0,0.5)">Content with shadow</div>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Parses linear-gradient background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html:
                  '<div style="background: linear-gradient(to right, #ff0000, #0000ff)">Gradient</div>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Parses CSS filter blur', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<div style="filter: blur(5px)">Blurred content</div>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Parses backdrop-filter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html:
                  '<div style="backdrop-filter: blur(10px); background: rgba(255,255,255,0.5)">Glassmorphism</div>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Parses word-break and overflow-wrap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html:
                  '<p style="word-break: break-all; overflow-wrap: break-word">LongURLThatNeedsBreaking...</p>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Parses text-shadow property', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html:
                  '<h1 style="text-shadow: 2px 2px 4px rgba(0,0,0,0.5)">Heading with shadow</h1>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Parses text-overflow: ellipsis', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html:
                  '<div style="width: 100px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">Truncated text that is very long</div>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Parses advanced border styles (dashed, dotted, double)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="border: 2px dashed red">Dashed</div>
                <div style="border: 3px dotted blue">Dotted</div>
                <div style="border: 6px double green">Double</div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
