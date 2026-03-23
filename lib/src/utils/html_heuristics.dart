/// Fast heuristics for detecting HTML complexity beyond hyper_render's
/// supported subset.
///
/// These checks use regex-based scanning (no full DOM parse) and are intended
/// to be called before rendering to decide whether to use a fallback renderer
/// (e.g., a WebView) for content that hyper_render may not handle correctly.
///
/// ---
///
/// ## ⚠️ BA / Product gap: HyperRender is read-only
///
/// HyperRender renders HTML as a **display-only** widget — it does not
/// support interactive form elements (`<input>`, `<select>`, `<textarea>`,
/// `<form>`).  When a requirement involves an HTML article with an embedded
/// survey, checkout form, or any user-input field, one of three patterns must
/// be chosen **before development starts**:
///
/// ### Pattern A — WebView fallback (easiest, least control)
/// Use `HtmlHeuristics.hasForms()` or `HtmlHeuristics.isComplex()` to detect
/// form HTML at runtime and render the entire page in a WebView instead.
/// ```dart
/// if (HtmlHeuristics.hasForms(html)) {
///   return WebViewWidget(controller: ..webViewController..);
/// }
/// return HyperViewer(html: html);
/// ```
/// **Trade-off**: loses HyperRender's performance, text selection, and deep
/// linking on those screens.
///
/// ### Pattern B — Native form below the article (recommended)
/// Render the article text with HyperRender and place a native Flutter
/// `Form` / `Column` of `TextFormField`s **below** or in a `Stack`.
/// The backend delivers article HTML and form schema as **separate fields**
/// (e.g., `{ "body": "<p>…</p>", "form": [...] }`).
/// ```dart
/// Column(children: [
///   HyperViewer(html: article.body),
///   NativeSurveyForm(schema: article.form),
/// ])
/// ```
/// **Trade-off**: requires the backend to separate content from form
/// definition.  Strongly preferred for new screens.
///
/// ### Pattern C — Strip form tags, keep read-only body
/// If the form is purely cosmetic (e.g., a "vote" button that submits via
/// a link rather than POST), strip interactive elements with
/// `HtmlSanitizer` and render the cleaned HTML.
/// ```dart
/// final clean = HtmlSanitizer.sanitize(html);  // strips <input> etc.
/// return HyperViewer(html: clean);
/// ```
/// **Trade-off**: any form functionality is silently removed.
///
/// ---
///
/// ## Usage (isComplex gate)
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
  /// - `@keyframes` / `animation:` (CSS animations)
  /// - `filter:` / `backdrop-filter:` with values beyond supported subset
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

    // CSS animations — @keyframes or animation: property
    if (lower.contains('@keyframes')) return true;
    if (RegExp(r'\banimation\s*:', caseSensitive: false).hasMatch(lower)) {
      return true;
    }

    // CSS transitions
    if (RegExp(r'\btransition\s*:', caseSensitive: false).hasMatch(lower)) {
      return true;
    }

    // backdrop-filter (requires saveLayer, not supported on all devices)
    if (lower.contains('backdrop-filter')) return true;

    return false;
  }

  /// Returns `true` if the HTML contains form or user-input elements.
  ///
  /// HyperRender is a **read-only** renderer — it does not support
  /// `<form>`, `<input>`, `<select>`, `<textarea>`, or `<button type="submit">`.
  ///
  /// Use this check when deciding between rendering strategies:
  /// - `true`  → choose Pattern A (WebView), B (native form below), or C (strip)
  /// - `false` → safe to render with HyperRender as-is
  ///
  /// See the library-level doc comment for a full description of each pattern.
  ///
  /// ```dart
  /// if (HtmlHeuristics.hasForms(html)) {
  ///   // Route to WebView or show native form widget
  /// } else {
  ///   return HyperViewer(html: html);
  /// }
  /// ```
  static bool hasForms(String html) {
    final lower = html.toLowerCase();
    return _tagPresent(lower, 'form') ||
        _tagPresent(lower, 'input') ||
        _tagPresent(lower, 'select') ||
        _tagPresent(lower, 'textarea') ||
        // <button type="submit"> without a parent <form> still signals
        // interactive intent — flag it so the team can decide.
        RegExp(r'<button[^>]+type\s*=\s*["\']?submit',
                caseSensitive: false)
            .hasMatch(html);
  }

  /// Returns `true` if the HTML contains interactive or scripted elements
  /// that hyper_render does not render:
  ///
  /// - `<canvas>` — requires JavaScript 2D/WebGL context
  /// - `<form>` / `<input>` / `<select>` / `<textarea>` — hyper_render is
  ///   read-only; use [hasForms] for a targeted form check
  /// - `<script>` — JavaScript execution not supported
  /// - `<video>` or `<audio>` with `src=` pointing to streaming sources
  ///   (HLS, RTSP, etc.) that the platform media player cannot open
  static bool hasUnsupportedElements(String html) {
    final lower = html.toLowerCase();

    // Canvas
    if (_tagPresent(lower, 'canvas')) return true;

    // Form elements (delegates to hasForms for single source of truth)
    if (hasForms(html)) return true;

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
