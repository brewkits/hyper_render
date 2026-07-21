// Tests for WCAG 2.1 AA §1.4.4 (Resize Text) — system/host accessibility
// text scaling.
//
// Before this fix HyperRender ignored MediaQuery.textScaler entirely: a
// paragraph rendered at the same pixel height regardless of the device's
// "large text" accessibility setting, unlike every Flutter `Text` widget.
// Found by cross-referencing flutter_html issue #308.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

Future<double> _viewerHeight(WidgetTester tester, Widget viewer) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: viewer)),
  ));
  await tester.pumpAndSettle();
  return tester.getSize(find.byType(HyperViewer)).height;
}

Widget _scaled(TextScaler scaler, Widget child) => MediaQuery(
      data: MediaQueryData(textScaler: scaler),
      child: child,
    );

void main() {
  group('WCAG 1.4.4 — HyperViewer honours MediaQuery textScaler', () {
    testWidgets('text grows monotonically with the scale factor',
        (tester) async {
      const html = '<p style="font-size: 16px;">Resize me</p>';

      double h = 0;
      for (final factor in [1.0, 2.0, 3.0]) {
        final height = await _viewerHeight(
          tester,
          _scaled(TextScaler.linear(factor), const HyperViewer(html: html)),
        );
        expect(height, greaterThan(h),
            reason: 'text must grow as the accessibility scale factor rises '
                '(factor=$factor produced $height, not greater than $h)');
        h = height;
      }
    });

    testWidgets('runtime scale change (updateRenderObject path) re-measures',
        (tester) async {
      // Reuses the same Element/RenderObject across pumps — exercises the
      // textScaler setter's _invalidateLayout(), not a fresh mount. If the
      // setter failed to invalidate, height would stay constant here.
      const html = '<p style="font-size: 16px;">Resize me</p>';

      final h1 = await _viewerHeight(
        tester,
        _scaled(const TextScaler.linear(1.0), const HyperViewer(html: html)),
      );
      final h2 = await _viewerHeight(
        tester,
        _scaled(const TextScaler.linear(2.5), const HyperViewer(html: html)),
      );
      expect(h2, greaterThan(h1));
    });

    testWidgets('no MediaQuery scaling leaves text at its natural size',
        (tester) async {
      // Baseline: without an explicit scaler MediaQuery defaults to 1.0.
      const html = '<p style="font-size: 16px;">Natural</p>';
      final natural = await _viewerHeight(
        tester,
        _scaled(const TextScaler.linear(1.0), const HyperViewer(html: html)),
      );
      expect(natural, greaterThan(0));
    });
  });

  group('HyperRenderWidget.textScaler override', () {
    testWidgets('explicit noScaling opts out of a large MediaQuery scaler',
        (tester) async {
      final doc = HtmlAdapter().parse('<p style="font-size: 16px;">Fixed</p>');
      StyleResolver().resolveStyles(doc);

      Future<double> heightWith(TextScaler? override) async {
        await tester.pumpWidget(MaterialApp(
          home: _scaled(
            const TextScaler.linear(3.0),
            Scaffold(
              body: SingleChildScrollView(
                child: HyperRenderWidget(
                  document: doc,
                  textScaler: override,
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        return tester.getSize(find.byType(HyperRenderWidget)).height;
      }

      final honored = await heightWith(null); // reads the 3.0 MediaQuery scaler
      final overridden = await heightWith(TextScaler.noScaling);
      expect(overridden, lessThan(honored),
          reason: 'an explicit noScaling override must ignore the 3x '
              'MediaQuery scaler and render at natural size');
    });
  });

  group('Global TextPainter cache does not collide across scalers', () {
    testWidgets(
        'same text at two scales renders at two different sizes in one tree',
        (tester) async {
      // Both viewers share the process-global TextPainter LRU cache. If the
      // cache key omitted the scaler, the second viewer would reuse the first
      // viewer's painter and render at the wrong size.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              _scaled(
                const TextScaler.linear(1.0),
                const HyperViewer(
                    html: '<p style="font-size: 16px;">Same text</p>',
                    key: Key('a')),
              ),
              _scaled(
                const TextScaler.linear(3.0),
                const HyperViewer(
                    html: '<p style="font-size: 16px;">Same text</p>',
                    key: Key('b')),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final aHeight = tester.getSize(find.byKey(const Key('a'))).height;
      final bHeight = tester.getSize(find.byKey(const Key('b'))).height;
      expect(bHeight, greaterThan(aHeight),
          reason: 'identical text at 3x must be taller than at 1x — proves '
              'the shared cache key includes the scaler');
    });
  });

  group('RenderRubyText honours textScaler', () {
    testWidgets('ruby widget grows with the scaler', (tester) async {
      Future<double> rubyHeight(TextScaler scaler) async {
        await tester.pumpWidget(MaterialApp(
          home: _scaled(
            scaler,
            const Scaffold(
              body: Center(
                child: RubyTextWidget(
                  baseText: '漢字',
                  rubyText: 'かんじ',
                  baseStyle: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        return tester.getSize(find.byType(RubyTextWidget)).height;
      }

      final h1 = await rubyHeight(const TextScaler.linear(1.0));
      final h2 = await rubyHeight(const TextScaler.linear(2.0));
      expect(h2, greaterThan(h1));
    });
  });
}
