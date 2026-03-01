import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Extension to capture a widget as an image via its GlobalKey
extension CaptureExtension on GlobalKey {
  /// Captures the widget as a ui.Image
  Future<ui.Image?> toImage({double pixelRatio = 1.0}) async {
    final RenderRepaintBoundary? boundary =
        currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    return await boundary.toImage(pixelRatio: pixelRatio);
  }

  /// Captures the widget as PNG bytes
  Future<Uint8List?> toPngBytes({double pixelRatio = 1.0}) async {
    final ui.Image? image = await toImage(pixelRatio: pixelRatio);
    if (image == null) return null;
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}
