/// HTML Sanitizer to prevent XSS attacks
///
/// This sanitizer uses a whitelist approach to allow only safe HTML tags
/// and attributes. It removes dangerous elements like <script>, <iframe>,
/// and event handlers like onclick, onerror, etc.
library;

/// HTML Sanitizer for preventing XSS attacks
class HtmlSanitizer {
  /// Default allowed HTML tags (safe subset)
  static const List<String> defaultAllowedTags = [
    // Block elements
    'p', 'div', 'section', 'article', 'header', 'footer', 'nav', 'aside',
    'blockquote', 'pre', 'hr', 'br',

    // Headings
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6',

    // Lists
    'ul', 'ol', 'li', 'dl', 'dt', 'dd',

    // Tables
    'table', 'thead', 'tbody', 'tfoot', 'tr', 'th', 'td', 'caption',

    // Inline elements
    'span', 'strong', 'em', 'b', 'i', 'u', 's', 'del', 'ins', 'mark',
    'code', 'kbd', 'samp', 'var', 'sub', 'sup', 'small', 'q', 'cite',
    'abbr', 'time',

    // Links and media
    'a', 'img',

    // Ruby annotations (CJK)
    'ruby', 'rt', 'rp',

    // Details/Summary
    'details', 'summary',
  ];

  /// Dangerous tags that should always be removed
  static const List<String> dangerousTags = [
    'script', 'style', 'iframe', 'frame', 'frameset', 'object', 'embed',
    'applet', 'link', 'meta', 'base', 'form', 'input', 'button', 'select',
    'textarea', 'option', 'optgroup', 'fieldset', 'legend', 'label',
  ];

  /// Dangerous attributes that should always be removed
  static const List<String> dangerousAttributes = [
    // Event handlers
    'onclick', 'ondblclick', 'onmousedown', 'onmouseup', 'onmouseover',
    'onmousemove', 'onmouseout', 'onmouseenter', 'onmouseleave',
    'onload', 'onerror', 'onabort', 'onblur', 'onchange', 'onfocus',
    'oninput', 'oninvalid', 'onreset', 'onselect', 'onsubmit',
    'onkeydown', 'onkeypress', 'onkeyup',
    'ontouchstart', 'ontouchmove', 'ontouchend', 'ontouchcancel',
    'onscroll', 'onwheel', 'oncopy', 'oncut', 'onpaste',

    // Other dangerous attributes
    'formaction', 'action', 'data', 'dynsrc', 'lowsrc',
  ];

  /// Sanitize HTML string by removing dangerous tags and attributes
  ///
  /// Parameters:
  /// - [html]: The HTML string to sanitize
  /// - [allowedTags]: Optional custom list of allowed tags (overrides default)
  /// - [allowedAttributes]: Optional list of allowed attributes (default: safe subset)
  /// - [allowDataAttributes]: Whether to allow data-* attributes (default: false)
  ///
  /// Returns sanitized HTML string
  static String sanitize(
    String html, {
    List<String>? allowedTags,
    List<String>? allowedAttributes,
    bool allowDataAttributes = false,
  }) {
    final allowed = allowedTags ?? defaultAllowedTags;
    final allowedAttrs = allowedAttributes ?? _defaultAllowedAttributes;

    // Simple regex-based sanitization
    // For production, consider using a proper HTML parser

    String result = html;

    // 1. Remove dangerous tags
    for (final tag in dangerousTags) {
      // Remove opening and closing tags
      result = result.replaceAll(
        RegExp('<$tag[^>]*>.*?</$tag>', caseSensitive: false, dotAll: true),
        '',
      );
      // Remove self-closing tags
      result = result.replaceAll(
        RegExp('<$tag[^>]*/?>', caseSensitive: false),
        '',
      );
    }

    // 2. Remove tags not in whitelist
    result = result.replaceAllMapped(
      RegExp(r'<(/?)(\w+)([^>]*)>', caseSensitive: false),
      (match) {
        final isClosing = match.group(1) == '/';
        final tagName = match.group(2)?.toLowerCase() ?? '';
        final attributes = match.group(3) ?? '';

        // Check if tag is allowed
        if (!allowed.contains(tagName)) {
          return ''; // Remove tag
        }

        // For closing tags, just return as-is
        if (isClosing) {
          return '</$tagName>';
        }

        // Sanitize attributes
        final sanitizedAttrs = _sanitizeAttributes(
          attributes,
          allowedAttrs,
          allowDataAttributes,
        );

        return '<$tagName$sanitizedAttrs>';
      },
    );

    // 3. Remove javascript: and data: URLs
    result = _sanitizeUrls(result);

    return result;
  }

  /// Default allowed attributes (safe subset)
  static const List<String> _defaultAllowedAttributes = [
    // Universal attributes
    'id', 'class', 'title', 'lang', 'dir',

    // Styling (will be handled by CSS parser)
    'style',

    // Links
    'href', 'target', 'rel',

    // Images
    'src', 'alt', 'width', 'height',

    // Tables
    'colspan', 'rowspan', 'headers', 'scope',

    // Ruby
    'ruby',

    // Details
    'open',

    // Semantic
    'datetime', 'cite',
  ];

  /// Sanitize HTML attributes
  static String _sanitizeAttributes(
    String attributes,
    List<String> allowedAttrs,
    bool allowDataAttributes,
  ) {
    // Parse attributes
    final attrPattern = RegExp(
      r'''(\w+(?:-\w+)*)(?:\s*=\s*["']([^"']*)["'])?''',
      caseSensitive: false,
    );

    final sanitized = <String>[];

    for (final match in attrPattern.allMatches(attributes)) {
      final name = match.group(1)?.toLowerCase() ?? '';
      final value = match.group(2) ?? '';

      // Skip dangerous attributes
      if (dangerousAttributes.contains(name)) {
        continue;
      }

      // Check if attribute is allowed
      if (allowedAttrs.contains(name) ||
          (allowDataAttributes && name.startsWith('data-'))) {
        sanitized.add('$name="${_escapeAttribute(value)}"');
      }
    }

    return sanitized.isEmpty ? '' : ' ${sanitized.join(' ')}';
  }

  /// Sanitize URLs to prevent javascript: and data: schemes
  static String _sanitizeUrls(String html) {
    // Remove javascript: URLs
    html = html.replaceAllMapped(
      RegExp(r'''(href|src)\s*=\s*["']javascript:[^"']*["']''',
          caseSensitive: false),
      (match) => '',
    );

    // Remove data: URLs (except for images with image/* MIME types)
    html = html.replaceAllMapped(
      RegExp(r'''(href|src)\s*=\s*["']data:(?!image/)[^"']*["']''',
          caseSensitive: false),
      (match) => '',
    );

    return html;
  }

  /// Escape HTML attribute value
  static String _escapeAttribute(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  /// Check if HTML contains potentially dangerous content
  static bool containsDangerousContent(String html) {
    // Check for dangerous tags
    for (final tag in dangerousTags) {
      if (RegExp('<$tag[^>]*>', caseSensitive: false).hasMatch(html)) {
        return true;
      }
    }

    // Check for javascript: URLs
    if (RegExp(r'javascript:', caseSensitive: false).hasMatch(html)) {
      return true;
    }

    // Check for event handlers
    for (final attr in dangerousAttributes) {
      if (RegExp('$attr\\s*=', caseSensitive: false).hasMatch(html)) {
        return true;
      }
    }

    return false;
  }
}
