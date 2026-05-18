/// Canonical URL scheme allow-list shared by every parser / sanitizer in the
/// HyperRender ecosystem.
///
/// All adapters that turn user-supplied strings into clickable links — the
/// HTML sanitizer, Markdown adapter, Delta adapter, plugin authors — MUST
/// route URLs through [UrlSafety.isSafe] rather than rolling their own check.
/// Keeping the blocklist in a single place prevents the "drift" failure mode
/// where one adapter forgets to block a scheme another already blocks
/// (e.g. the markdown sub-package previously missed `file:`/`mhtml:`/`about:`).
///
/// The check is intentionally conservative: anything not on a known-safe
/// scheme should still be allowed (apps register their own deep-link schemes
/// via `HyperRenderConfig.extraLinkSchemes`), but a fixed set of known-bad
/// schemes is denied outright.
class UrlSafety {
  /// Returns false when [url] should be treated as untrusted and rejected.
  ///
  /// Blocked schemes:
  /// - `javascript:` — XSS execution.
  /// - `vbscript:` — legacy IE XSS execution.
  /// - `data:image/svg…` — inline SVG can carry `<script>`.
  /// - non-image `data:` — arbitrary payload execution vector.
  /// - `file:` — local filesystem read on Android/iOS (contacts, private
  ///   app storage, sqlite DBs).
  /// - `mhtml:` — MHTML archive parsing has been an Android WebView XSS
  ///   vector.
  /// - `about:` — `about:blank` is a classic sandbox-escape vector.
  ///
  /// Bypass tricks neutralised:
  /// - Leading/trailing whitespace stripped.
  /// - ASCII control chars (U+0000–U+001F + DEL) stripped from the whole
  ///   string per WHATWG URL spec §4.1 — defeats `jav\tascript:` /
  ///   `jav&#x09;ascript:` smuggling.
  /// - Case-insensitive scheme match (`JaVaScRiPt:` is still blocked).
  static bool isSafe(String url) {
    final cleaned =
        url.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim().toLowerCase();
    if (cleaned.startsWith('javascript:')) return false;
    if (cleaned.startsWith('vbscript:')) return false;
    if (cleaned.startsWith('data:image/svg')) return false;
    if (cleaned.startsWith('data:') && !cleaned.startsWith('data:image/')) {
      return false;
    }
    if (cleaned.startsWith('file:')) return false;
    if (cleaned.startsWith('mhtml:')) return false;
    if (cleaned.startsWith('about:')) return false;
    return true;
  }
}
