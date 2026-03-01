import "package:hyper_render/hyper_render.dart";
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for CSS Grid Layout (Sprint 3).
///
/// Tests the full pipeline:
///   HTML `display:grid` → StyleResolver → GridContainerWidget → layout
void main() {
  group('CSS Grid — basic rendering', () {
    testWidgets('renders 3-column equal-width grid (1fr 1fr 1fr)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px">
                  <div style="background:#bbdefb;padding:8px">Col 1</div>
                  <div style="background:#c8e6c9;padding:8px">Col 2</div>
                  <div style="background:#ffe0b2;padding:8px">Col 3</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(HyperViewer), findsOneWidget);
    });

    testWidgets('renders grid with fixed px column', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:100px 1fr;gap:4px">
                  <div style="background:#e3f2fd">Fixed 100px</div>
                  <div style="background:#e8f5e9">Flexible 1fr</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders mixed units: 120px 2fr 1fr', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:120px 2fr 1fr;gap:6px">
                  <div style="background:#e3f2fd">Fixed 120px</div>
                  <div style="background:#e8f5e9">2fr main</div>
                  <div style="background:#fff3e0">1fr aside</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders auto column', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:auto 1fr auto;gap:8px">
                  <div>Left</div>
                  <div>Center</div>
                  <div>Right</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('CSS Grid — repeat()', () {
    testWidgets('repeat(3, 1fr) expands to 3 equal columns', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:4px">
                  <div style="background:#e3f2fd">A</div>
                  <div style="background:#e8f5e9">B</div>
                  <div style="background:#fff3e0">C</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('repeat(4, 1fr) with overflow to next row', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:4px">
                  <div>1</div><div>2</div><div>3</div><div>4</div>
                  <div>5</div><div>6</div><div>7</div><div>8</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('repeat(2, 200px) with fixed px repeats', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:repeat(2,100px);gap:4px">
                  <div style="background:#e3f2fd">100px</div>
                  <div style="background:#e8f5e9">100px</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('CSS Grid — grid-column span', () {
    testWidgets('grid-column: span 2 spans two columns', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:4px">
                  <div style="grid-column:span 2;background:#e3f2fd">Span 2</div>
                  <div style="background:#e8f5e9">Normal</div>
                  <div>A</div><div>B</div><div>C</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('grid-column: span 3 full-width header', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:4px">
                  <div style="grid-column:span 3;background:#1565c0;color:white;padding:8px">
                    Full-width header
                  </div>
                  <div>A</div><div>B</div><div>C</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('span exceeding column count is clamped', (tester) async {
      // span:10 in a 3-col grid should clamp to 3
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:4px">
                  <div style="grid-column:span 10">Clamped span</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('CSS Grid — gap', () {
    testWidgets('gap applies equal row and column gap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px">
                  <div style="background:#e3f2fd;padding:8px">A</div>
                  <div style="background:#e8f5e9;padding:8px">B</div>
                  <div style="background:#fff3e0;padding:8px">C</div>
                  <div style="background:#f3e5f5;padding:8px">D</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('column-gap only', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:1fr 1fr;column-gap:20px">
                  <div>Left</div>
                  <div>Right</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('row-gap only', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:1fr;row-gap:12px">
                  <div>Row 1</div>
                  <div>Row 2</div>
                  <div>Row 3</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('CSS Grid — edge cases', () {
    testWidgets('empty grid container renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<div style="display:grid;grid-template-columns:1fr 1fr"></div>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('grid with single item', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:4px">
                  <div style="background:#e3f2fd;padding:8px">Only one item</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('nested grids render without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px">
                  <div style="display:grid;grid-template-columns:1fr 1fr;gap:4px">
                    <div style="background:#e3f2fd">A1</div>
                    <div style="background:#e8f5e9">A2</div>
                  </div>
                  <div style="background:#fff3e0;padding:8px">Right</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('grid without grid-template-columns falls back gracefully',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid">
                  <div>Item without column definition</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('grid with many items wraps to multiple rows', (tester) async {
      const items = [
        '<div>1</div>', '<div>2</div>', '<div>3</div>',
        '<div>4</div>', '<div>5</div>', '<div>6</div>',
        '<div>7</div>', '<div>8</div>', '<div>9</div>',
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<div style="display:grid;grid-template-columns:repeat(3,1fr);gap:4px">'
                  '${items.join()}</div>',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('CSS Grid — combined with other features', () {
    testWidgets('grid with CSS variables for gap and colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="--g:8px;--c1:#e3f2fd;--c2:#e8f5e9;
                            display:grid;grid-template-columns:1fr 1fr;gap:var(--g)">
                  <div style="background:var(--c1);padding:8px">CSS Vars</div>
                  <div style="background:var(--c2);padding:8px">in Grid</div>
                </div>
              ''',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('grid with calc() in template columns', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '''
                <div style="display:grid;grid-template-columns:calc(50px + 50px) 1fr;gap:8px">
                  <div style="background:#e3f2fd">calc col</div>
                  <div style="background:#e8f5e9">fr col</div>
                </div>
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
