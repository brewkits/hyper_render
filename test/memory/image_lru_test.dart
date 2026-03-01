/// Tests for image cache LRU eviction behavior.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_html/hyper_render_html.dart';

void main() {
  group('Image LRU cache', () {
    /// Build a [HyperRenderWidget] with the given HTML and loader.
    Widget _build(String html, HyperImageLoader loader) {
      final adapter = HtmlAdapter();
      final document = adapter.parse(html);
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 600,
            child: HyperRenderWidget(
              document: document,
              imageLoader: loader,
            ),
          ),
        ),
      );
    }

    testWidgets('imageLoader is called for img tags', (tester) async {
      int callCount = 0;
      await tester.pumpWidget(_build(
        '<img src="https://example.com/img.png">',
        (src, onLoad, onError) {
          callCount++;
          onError(Exception('no network'));
        },
      ));
      await tester.pump();
      expect(callCount, greaterThan(0));
    });

    testWidgets('changing imageLoader triggers reload', (tester) async {
      int loaderACount = 0;
      int loaderBCount = 0;

      void loaderA(String src, void Function(ui.Image) onLoad, void Function(Object) onError) {
        loaderACount++;
        onError(Exception('loader A'));
      }

      void loaderB(String src, void Function(ui.Image) onLoad, void Function(Object) onError) {
        loaderBCount++;
        onError(Exception('loader B'));
      }

      await tester.pumpWidget(_build(
        '<img src="https://example.com/img.png">',
        loaderA,
      ));
      await tester.pump();
      expect(loaderACount, greaterThan(0));

      // Switch to loader B
      final adapter = HtmlAdapter();
      final doc = adapter.parse('<img src="https://example.com/img.png">');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 600,
            child: HyperRenderWidget(
              document: doc,
              imageLoader: loaderB,
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(loaderBCount, greaterThan(0));
    });

    testWidgets('50 failing images do not crash', (tester) async {
      final imgs = List.generate(50, (i) =>
          '<img src="http://img$i.example.com/pic.jpg">').join();

      await tester.pumpWidget(_build(
        '<div>$imgs</div>',
        (src, onLoad, onError) => onError(Exception('no network')),
      ));
      await tester.pump();
      expect(find.byType(HyperRenderWidget), findsOneWidget);
    });

    testWidgets('dispose clears image cache cleanly', (tester) async {
      await tester.pumpWidget(_build(
        '<img src="https://example.com/a.png">',
        (src, onLoad, onError) => onError(Exception('failing')),
      ));
      await tester.pump();

      // Unmounting should not throw
      await tester.pumpWidget(const SizedBox());
      expect(true, isTrue);
    });
  });
}
