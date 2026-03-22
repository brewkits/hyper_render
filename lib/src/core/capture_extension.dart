import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Extension on [GlobalKey] to capture a widget as an image.
///
/// Attach the key to a [RepaintBoundary] widget (or use [HyperViewer.captureKey])
/// and call these methods to export the rendered content as an image.
///
/// ## Usage
/// ```dart
/// final captureKey = GlobalKey();
///
/// HyperViewer(
///   html: '<h1>Hello World</h1>',
///   captureKey: captureKey,
/// )
///
/// // Capture PNG bytes:
/// final bytes = await captureKey.toPngBytes();
///
/// // Capture as ui.Image:
/// final image = await captureKey.toImage(pixelRatio: 2.0);
/// ```
extension HyperCaptureExtension on GlobalKey {
  /// Capture the widget as a [ui.Image].
  ///
  /// [pixelRatio] controls resolution: 1.0 = logical pixels, 2.0 = 2× physical.
  /// Default is the device's pixel ratio for retina-quality output.
  Future<ui.Image> toImage({double? pixelRatio}) async {
    final context = currentContext;
    if (context == null) {
      throw StateError(
        'HyperCaptureExtension.toImage: GlobalKey has no context. '
        'Make sure the widget is mounted.',
      );
    }

    // Use the already-null-checked `context` local — not `currentContext!`.
    final renderObject = context.findRenderObject();
    if (renderObject == null) {
      throw StateError(
        'HyperCaptureExtension.toImage: No RenderObject found. '
        'Ensure the key is attached to a RepaintBoundary widget.',
      );
    }
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError(
        'HyperCaptureExtension.toImage: RenderObject is not a '
        'RenderRepaintBoundary (got ${renderObject.runtimeType}). '
        'Ensure the key is attached to a RepaintBoundary widget.',
      );
    }

    final boundary = renderObject;
    final ratio = pixelRatio ??
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    return boundary.toImage(pixelRatio: ratio);
  }

  /// Capture the widget and encode as PNG bytes.
  ///
  /// [pixelRatio] controls resolution. Defaults to device pixel ratio.
  Future<Uint8List> toPngBytes({double? pixelRatio}) async {
    final image = await toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError(
          'HyperCaptureExtension.toPngBytes: Failed to encode PNG.');
    }
    image.dispose();
    return byteData.buffer.asUint8List();
  }
}
