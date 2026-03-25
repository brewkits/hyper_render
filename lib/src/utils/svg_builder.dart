import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

/// Returns a [Widget] for SVG nodes, or `null` for everything else.
///
/// Wire this into [HyperViewer] / [HyperRenderWidget] via `widgetBuilder`.
/// It handles two cases:
///   1. Inline `<svg>…</svg>` — rendered with [SvgPicture.string].
///   2. `<img src="*.svg">` or `<img src="data:image/svg+xml,…">` —
///      rendered with [SvgPicture.network] or [SvgPicture.string].
Widget? buildSvgWidget(UDTNode node) {
  if (node is! AtomicNode) return null;

  final tagName = node.tagName;
  final width = node.intrinsicWidth ?? node.style.width;
  final height = node.intrinsicHeight ?? node.style.height;

  // ── Case 1: inline <svg> element ──────────────────────────────────────────
  if (tagName == 'svg') {
    final svgData = node.svgData;
    if (svgData != null && svgData.isNotEmpty) {
      return SvgPicture.string(
        svgData,
        width: width,
        height: height,
      );
    }

    // <svg src="…"> fallthrough to src handling below
    final src = node.src;
    if (src != null && src.isNotEmpty) {
      return _buildFromSrc(src, width, height);
    }
    return null;
  }

  // ── Case 2: <img src="*.svg"> or data URI ─────────────────────────────────
  if (tagName == 'img') {
    final src = node.src;
    if (src == null || src.isEmpty) return null;
    // Floated images are painted on canvas by RenderHyperBox — skip those.
    if (node.style.float != HyperFloat.none) return null;
    if (_isSvgSrc(src)) {
      return _buildFromSrc(src, width, height);
    }
    return null; // Let core handle non-SVG images
  }

  return null;
}

bool _isSvgSrc(String src) {
  final lower = src.toLowerCase();
  if (lower.endsWith('.svg') || lower.contains('.svg?')) return true;
  if (lower.startsWith('data:image/svg+xml')) return true;
  return false;
}

Widget _buildFromSrc(String src, double? width, double? height) {
  if (src.startsWith('data:image/svg+xml')) {
    final svgString = _decodeSvgDataUri(src);
    if (svgString != null) {
      return SvgPicture.string(svgString, width: width, height: height);
    }
  }
  return SvgPicture.network(
    src,
    width: width,
    height: height,
    placeholderBuilder: (_) =>
        SizedBox(width: width ?? 40, height: height ?? 40),
  );
}

String? _decodeSvgDataUri(String dataUri) {
  // data:image/svg+xml;base64,<b64data>
  // data:image/svg+xml,<url-encoded-svg>
  final comma = dataUri.indexOf(',');
  if (comma < 0) return null;
  final header = dataUri.substring(0, comma);
  final data = dataUri.substring(comma + 1);
  if (header.contains('base64')) {
    try {
      return utf8.decode(base64.decode(data));
    } catch (_) {
      return null;
    }
  }
  return Uri.decodeFull(data);
}
