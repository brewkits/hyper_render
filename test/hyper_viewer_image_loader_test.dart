// Regression tests for HyperViewer.imageLoader passthrough.
//
// `imageLoader` is threaded through five internal widgets before it reaches
// RenderHyperBox, and each one is a distinct default-vs-fallback branch:
//   - sync,        selectable (default)      -> HyperSelectionOverlay
//   - sync,        selectable: false          -> HyperRenderWidget (direct)
//   - paged,       selectable (default)      -> HyperSelectionOverlay
//   - virtualized, selectable (default)      -> VirtualizedChunk
// A change that wires only the "direct HyperRenderWidget" call sites and
// misses HyperSelectionOverlay/VirtualizedChunk would still pass a sync-mode
// smoke test while leaving the *default* configuration of every other mode
// silently on the built-in NetworkImage loader.
//
// Markdown content is used throughout (not HTML) because the HTML path
// parses via an async isolate that doesn't complete inside FakeAsync's test
// environment — see test/v120/paged_mode_test.dart for the same convention.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

/// Produces a tiny valid [ui.Image] a custom loader can hand back via
/// `onLoad` without hitting the network.
Future<ui.Image> _fakeImage() {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    Uint8List.fromList(List.filled(4 * 2 * 2, 255)), // 2x2 opaque white RGBA
    2,
    2,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

/// Records every `src` the loader was asked to resolve and immediately
/// completes it with a fake image, so painting can proceed without a real
/// network fetch.
class _RecordingLoader {
  final List<String> requestedSrcs = [];

  void call(
    String src,
    void Function(ui.Image image) onLoad,
    void Function(Object error) onError,
  ) {
    requestedSrcs.add(src);
    _fakeImage().then(onLoad);
  }
}

void main() {
  const markdownWithImage = '# Chapter\n\n![alt text](test.png)\n\nBody.';

  // LazyImageQueue is a process-wide singleton that dedupes in-flight loads
  // by URL. Every test below requests the same 'test.png', and a load left
  // "in-flight" from a prior test (its onLoad future never awaited to
  // completion, only pumped once) would silently swallow the next test's
  // loader registration instead of invoking it. Reset between tests so each
  // one observes its own loader call.
  setUp(() => LazyImageQueue.instance.resetForTesting());
  tearDown(() => LazyImageQueue.instance.resetForTesting());

  testWidgets(
      'sync mode, default selectable: custom imageLoader fires '
      '(HyperSelectionOverlay path)', (tester) async {
    final loader = _RecordingLoader();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HyperViewer.markdown(
          markdown: markdownWithImage,
          imageLoader: loader.call,
        ),
      ),
    ));
    // A single pump is enough: the loader is invoked synchronously
    // during layout/attach (LazyImageQueue.enqueue), independent of when the
    // fake image finishes decoding. pumpAndSettle() cannot be used here — an
    // image in "loading" state drives a self-perpetuating shimmer frame
    // callback (render_hyper_box.dart _startShimmerLoop) that never lets the
    // frame stream go idle until the image resolves.
    await tester.pump();

    expect(loader.requestedSrcs, isNotEmpty);
    expect(loader.requestedSrcs.first, contains('test.png'));
  });

  testWidgets(
      'sync mode, selectable: false: custom imageLoader fires '
      '(direct HyperRenderWidget path)', (tester) async {
    final loader = _RecordingLoader();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HyperViewer.markdown(
          markdown: markdownWithImage,
          selectable: false,
          imageLoader: loader.call,
        ),
      ),
    ));
    // A single pump is enough: the loader is invoked synchronously
    // during layout/attach (LazyImageQueue.enqueue), independent of when the
    // fake image finishes decoding. pumpAndSettle() cannot be used here — an
    // image in "loading" state drives a self-perpetuating shimmer frame
    // callback (render_hyper_box.dart _startShimmerLoop) that never lets the
    // frame stream go idle until the image resolves.
    await tester.pump();

    expect(loader.requestedSrcs, isNotEmpty);
    expect(loader.requestedSrcs.first, contains('test.png'));
  });

  testWidgets(
      'paged mode, default selectable: custom imageLoader fires '
      '(HyperSelectionOverlay path)', (tester) async {
    final loader = _RecordingLoader();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HyperViewer.markdown(
          markdown: markdownWithImage,
          mode: HyperRenderMode.paged,
          imageLoader: loader.call,
        ),
      ),
    ));
    // A single pump is enough: the loader is invoked synchronously
    // during layout/attach (LazyImageQueue.enqueue), independent of when the
    // fake image finishes decoding. pumpAndSettle() cannot be used here — an
    // image in "loading" state drives a self-perpetuating shimmer frame
    // callback (render_hyper_box.dart _startShimmerLoop) that never lets the
    // frame stream go idle until the image resolves.
    await tester.pump();

    expect(loader.requestedSrcs, isNotEmpty);
    expect(loader.requestedSrcs.first, contains('test.png'));
  });

  testWidgets(
      'virtualized mode, default selectable: custom imageLoader fires '
      '(VirtualizedChunk path)', (tester) async {
    final loader = _RecordingLoader();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HyperViewer.markdown(
          markdown: markdownWithImage,
          mode: HyperRenderMode.virtualized,
          imageLoader: loader.call,
        ),
      ),
    ));
    // A single pump is enough: the loader is invoked synchronously
    // during layout/attach (LazyImageQueue.enqueue), independent of when the
    // fake image finishes decoding. pumpAndSettle() cannot be used here — an
    // image in "loading" state drives a self-perpetuating shimmer frame
    // callback (render_hyper_box.dart _startShimmerLoop) that never lets the
    // frame stream go idle until the image resolves.
    await tester.pump();

    expect(loader.requestedSrcs, isNotEmpty);
    expect(loader.requestedSrcs.first, contains('test.png'));
  });

  test(
      'HyperImageLoader / defaultImageLoader are exported from the root '
      'barrel (lib/hyper_render.dart uses an explicit show-list — a type '
      'used only via structural match, as loader.call is above, would not '
      'catch a regression here)', () {
    final HyperImageLoader typed = _RecordingLoader().call;
    expect(typed, isNotNull);
    expect(defaultImageLoader, isNotNull);
  });

  testWidgets('no imageLoader supplied: renders without error (default path)',
      (tester) async {
    // Regression guard: the new optional param must not break the default
    // (NetworkImage-based) behavior when omitted.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: HyperViewer.markdown(markdown: markdownWithImage),
      ),
    ));
    await tester.pump();
    expect(find.byType(HyperViewer), findsOneWidget);
  });
}
