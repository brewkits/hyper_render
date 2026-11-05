// Measures what HyperViewer actually rendered: laid-out fragment geometry from
// RenderHyperBox.debugLineFragments and raw pixels from a RepaintBoundary.
// Shared by the box-sizing / position / first-block-decoration tests, which all
// need real geometry rather than ComputedStyle values.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

const probeBoundaryKey = ValueKey('geometry-probe');
const probeRed = 'rgb(255,0,0)';

/// Pure-colour match with room for antialiasing.
typedef PixelTest = bool Function(int r, int g, int b);

bool isRed(int r, int g, int b) => r > 200 && g < 60 && b < 60;
bool isBlue(int r, int g, int b) => b > 200 && r < 60 && g < 60;

/// A horizontal+vertical extent of the pixels matching a colour.
class PixelExtent {
  const PixelExtent(this.left, this.right, this.top, this.bottom);
  final int left, right, top, bottom;
  int get width => right - left + 1;
  int get height => bottom - top + 1;
  @override
  String toString() => 'x:[$left,$right] y:[$top,$bottom]';
}

class ProbePixels {
  ProbePixels(this.bytes, this.width, this.height);
  final ByteData bytes;
  final int width, height;

  (int, int, int) at(int x, int y) {
    final i = (y * width + x) * 4;
    return (bytes.getUint8(i), bytes.getUint8(i + 1), bytes.getUint8(i + 2));
  }

  /// Extent of matching pixels, or null when none match.
  PixelExtent? extent(PixelTest match) {
    int? left, right, top, bottom;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final (r, g, b) = at(x, y);
        if (!match(r, g, b)) continue;
        if (left == null || x < left) left = x;
        if (right == null || x > right) right = x;
        top ??= y;
        bottom = y;
      }
    }
    return left == null ? null : PixelExtent(left, right!, top!, bottom!);
  }
}

/// Pumps [html] in a fixed 400×600 surface at 1:1 pixels.
Future<void> pumpHtml(
  WidgetTester tester,
  String html, {
  double width = 400,
  String? customCss,
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 600));
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: probeBoundaryKey,
          child: ColoredBox(
            color: Colors.white,
            child: SizedBox(
              width: width,
              height: 600,
              child: SingleChildScrollView(
                child: HyperViewer(
                  html: html,
                  customCss: customCss,
                  mode: HyperRenderMode.sync,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ));
  // A canvas animation keeps scheduling frames, so pumpAndSettle can't return.
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Every RenderHyperBox under [root] (default: the probe boundary).
List<RenderHyperBox> hyperBoxes(WidgetTester tester, {RenderObject? root}) {
  final found = <RenderHyperBox>[];
  void walk(RenderObject r) {
    if (r is RenderHyperBox) found.add(r);
    r.visitChildren(walk);
  }

  walk(root ?? tester.renderObject(find.byKey(probeBoundaryKey)));
  return found;
}

/// Laid-out fragments of the outermost RenderHyperBox.
List<Map<String, dynamic>> lineFragments(WidgetTester tester) =>
    hyperBoxes(tester).first.debugLineFragments();

/// First fragment whose text starts with [text].
Map<String, dynamic> fragmentOf(WidgetTester tester, String text) =>
    lineFragments(tester).firstWhere(
      (f) => (f['text'] as String?)?.startsWith(text) ?? false,
      orElse: () => throw StateError('no fragment starts with "$text"'),
    );

Offset fragmentTopLeft(WidgetTester tester, String text) {
  final f = fragmentOf(tester, text);
  return Offset(f['offsetX'] as double, f['offsetY'] as double);
}

/// Characters laid out on the first line of the first text fragment.
int firstLineChars(WidgetTester tester) =>
    (lineFragments(tester).first['text'] as String).length;

double viewerHeight(WidgetTester tester) =>
    tester.getSize(find.byType(HyperViewer)).height;

Future<ProbePixels> capture(WidgetTester tester) async {
  final boundary = tester.renderObject(find.byKey(probeBoundaryKey))
      as RenderRepaintBoundary;
  final result = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData();
    return ProbePixels(bytes!, image.width, image.height);
  });
  return result!;
}

/// Where [box] draws each paragraph, in paint order. Fragment geometry can't
/// show a fragment drawn twice or a stale one drawn at all; this can.
List<Offset> paragraphOrigins(RenderHyperBox box) {
  final canvas = _UnboundedRecordingCanvas();
  box.paint(TestRecordingPaintingContext(canvas), Offset.zero);
  return [
    for (final call in canvas.invocations)
      if (call.invocation.memberName == #drawParagraph)
        call.invocation.positionalArguments[1] as Offset,
  ];
}

class _UnboundedRecordingCanvas extends TestRecordingCanvas {
  @override
  Rect getLocalClipBounds() =>
      const Rect.fromLTWH(-100000, -100000, 200000, 200000);
}
