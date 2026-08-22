import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

/// Callback type for link taps in flutter_html compatibility mode.
typedef OnLinkTap = void Function(
  String? url,
  Map<String, String> attributes,
  dynamic element,
);

/// Drop-in replacement for `flutter_html`'s `Html` widget.
///
/// This widget provides high-performance rendering via HyperRender's
/// custom RenderObject engine while exposing a familiar API surface for
/// applications migrating from `flutter_html`.
///
/// ## Migration (Single Line Change)
/// ```dart
/// // Before:
/// // import 'package:flutter_html/flutter_html.dart';
///
/// // After:
/// import 'package:hyper_render/compat/flutter_html.dart';
///
/// Html(
///   data: '<h1>Hello World</h1>',
///   onLinkTap: (url, attributes, element) => print(url),
/// )
/// ```
class Html extends StatelessWidget {
  /// The raw HTML string to render.
  final String? data;

  /// Callback when an `<a>` link is tapped.
  final OnLinkTap? onLinkTap;

  /// Custom inline CSS stylesheet map: selector -> Style or CSS string.
  final Map<String, dynamic>? style;

  /// Whether the rendered document should be selectable.
  final bool? shrinkWrap;

  /// Custom tag builders / widget interceptors.
  final HyperWidgetBuilder? customWidgetBuilder;

  /// Error builder callback.
  final Widget Function(BuildContext context, Object error)? onError;

  /// Selection support toggle.
  final bool selectable;

  const Html({
    super.key,
    this.data,
    this.onLinkTap,
    this.style,
    this.shrinkWrap,
    this.customWidgetBuilder,
    this.onError,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    final htmlContent = data ?? '';
    if (htmlContent.isEmpty) {
      return const SizedBox.shrink();
    }

    // Convert flutter_html custom style map to CSS string if provided
    String? additionalCss;
    if (style != null && style!.isNotEmpty) {
      final buffer = StringBuffer();
      style!.forEach((selector, value) {
        if (value is String) {
          buffer.writeln('$selector { $value }');
        } else if (value is Map) {
          buffer.write('$selector { ');
          value.forEach((k, v) => buffer.write('$k: $v; '));
          buffer.writeln('}');
        }
      });
      additionalCss = buffer.toString();
    }

    return HyperViewer(
      html: htmlContent,
      customCss: additionalCss,
      selectable: selectable,
      widgetBuilder: customWidgetBuilder,
      shrinkWrap: shrinkWrap ?? false,
      onLinkTap:
          onLinkTap != null ? (url) => onLinkTap!(url, const {}, null) : null,
      fallbackBuilder: onError != null
          ? (context) => onError!(context, 'An error occurred during rendering')
          : null,
    );
  }
}
