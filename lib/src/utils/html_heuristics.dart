/// Fast heuristics for detecting HTML complexity beyond hyper_render's
/// supported subset.
///
/// These checks use regex-based scanning (no full DOM parse) and are intended
/// to be called before rendering to decide whether to use a fallback renderer
/// (e.g., a WebView) for content that hyper_render may not handle correctly.
///
/// ## Usage
/// ```dart
/// HyperViewer(
///   html: content,
///   fallbackBuilder: HtmlHeuristics.isComplex(content)
///       ? (ctx) => WebViewWidget(...)
///       : null,
/// )
/// ```
library;

/// Heuristics for detecting HTML complexity beyond hyper_render's supported
/// subset.
class HtmlHeuristics {
  // Private constructor — static API only.
  HtmlHeuristics._();

  /// Returns `true` if the HTML contains elements or CSS that hyper_render
  /// may not render correctly.
  ///
  /// Equivalent to `hasComplexTables(html) || hasUnsupportedCss(html) ||
  /// hasUnsupportedElements(html)`.
  static bool isComplex(String html) =>
      hasComplexTables(html) ||
      hasUnsupportedCss(html) ||
      hasUnsupportedElements(html);

  // ---------------------------------------------------------------------------
  // Individual heuristic checks
  // ---------------------------------------------------------------------------

  /// Returns `true` if the HTML contains tables with `colspan` or `rowspan`
  /// values greater than 2, which may trigger W3C auto-layout edge-cases
  /// not fully implemented in hyper_render.
  ///
  /// Simple `colspan="2"` / `rowspan="2"` are handled fine; spans of 3+
  /// columns or rows across complex structures are the concern.
  static bool hasComplexTables(String html) {
    // Match colspan="N" or rowspan="N" where N >= 3.
    // \W? matches the optional surrounding quote without needing quote chars
    // in the character class (which trips up single-quoted raw strings).
    final spanPattern = RegExp(
      r'(?:colspan|rowspan)\s*=\s*\W?([3-9]|\d{2,})',
      caseSensitive: false,
    );
    return spanPattern.hasMatch(html);
  }

  /// Returns `true` if the HTML references CSS properties that hyper_render
  /// does not support:
  ///
  /// - `position: absolute` / `position: fixed`
  /// - `z-index`
  /// - `clip-path`
  /// - `columns` / `column-count` (multi-column layout)
  /// - `grid-template-areas` (complex named areas)
  static bool hasUnsupportedCss(String html) {
    final lower = html.toLowerCase();

    // position: absolute or fixed
    if (_containsPositionAbsoluteOrFixed(lower)) return true;

    // z-index
    if (lower.contains('z-index')) return true;

    // clip-path
    if (lower.contains('clip-path')) return true;

    // Multi-column layout
    if (lower.contains('column-count') || lower.contains('columns:')) {
      return true;
    }

    // Complex grid template areas
    if (lower.contains('grid-template-areas')) return true;

    return false;
  }

  /// Returns `true` if the HTML contains interactive or scripted elements
  /// that hyper_render does not render:
  ///
  /// - `<canvas>` — requires JavaScript 2D/WebGL context
  /// - `<form>` — hyper_render is read-only
  /// - `<input>` / `<select>` / `<textarea>` — form controls
  /// - `<script>` — JavaScript execution not supported
  /// - `<video>` or `<audio>` with `src=` pointing to streaming sources
  ///   (HLS, RTSP, etc.) that the platform media player cannot open
  static bool hasUnsupportedElements(String html) {
    final lower = html.toLowerCase();

    // Canvas
    if (_tagPresent(lower, 'canvas')) return true;

    // Form elements
    if (_tagPresent(lower, 'form')) return true;
    if (_tagPresent(lower, 'input')) return true;
    if (_tagPresent(lower, 'select')) return true;
    if (_tagPresent(lower, 'textarea')) return true;

    // Script tags (should have been sanitised, but check anyway)
    if (_tagPresent(lower, 'script')) return true;

    // Streaming media (m3u8, rtsp:, rtmp:)
    if (_hasStreamingMedia(lower)) return true;

    return false;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static bool _tagPresent(String lower, String tag) =>
      lower.contains('<$tag') || lower.contains('<$tag>');

  static bool _containsPositionAbsoluteOrFixed(String lower) {
    // Match "position" followed (loosely) by "absolute" or "fixed".
    // Handles inline styles and <style> blocks.
    return RegExp(r'position\s*:\s*(absolute|fixed)', caseSensitive: false)
        .hasMatch(lower);
  }

  static bool _hasStreamingMedia(String lower) {
    return lower.contains('.m3u8') ||
        lower.contains('rtsp:') ||
        lower.contains('rtmp:') ||
        lower.contains('application/x-mpegurl') ||
        lower.contains('application/vnd.apple.mpegurl');
  }
}
