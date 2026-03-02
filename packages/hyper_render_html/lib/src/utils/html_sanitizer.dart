/// HTML Sanitizer to prevent XSS attacks
///
/// Uses a DOM-based approach (via the `html` package) for correct handling of
/// nested tags, malformed markup, and edge-cases that trip up regex sanitizers.
library;

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

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
    'a', 'img', 'video', 'audio', 'source', 'track', 'picture', 'figure', 'figcaption',

    // Ruby annotations (CJK)
    'ruby', 'rt', 'rp',

    // Details/Summary
    'details', 'summary',
  ];

  /// Tags whose entire subtree is dropped (content not preserved)
  static const List<String> dangerousTags = [
    'script', 'style', 'iframe', 'frame', 'frameset', 'object', 'embed',
    'applet', 'link', 'meta', 'base', 'form', 'input', 'button', 'select',
    'textarea', 'option', 'optgroup', 'fieldset', 'legend', 'label',
  ];

  /// Attribute names that are always stripped
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
    'formaction', 'action', 'dynsrc', 'lowsrc',
  ];

  /// Default allowed attributes (safe subset)
  static const List<String> defaultAllowedAttributes = [
    'id', 'class', 'title', 'lang', 'dir',
    'style',
    'href', 'target', 'rel',
    'src', 'alt', 'width', 'height',
    'colspan', 'rowspan', 'headers', 'scope',
    'open',
    'datetime', 'cite',
    // ARIA / accessibility — role + aria-* are semantic-only (no executable content)
    'role',
    // Media attributes
    'controls', 'autoplay', 'loop', 'muted', 'poster', 'preload',
    'type', 'media', 'kind', 'srclang', 'label', 'default',
  ];

  /// Sanitize [html] by walking the parsed DOM tree.
  ///
  /// - Dangerous tags (script, iframe, …) are removed **with** their children.
  /// - Unknown/disallowed tags are *unwrapped* — their text content is kept.
  /// - Attributes are filtered to [allowedAttributes] (default:
  ///   [defaultAllowedAttributes]). `javascript:` / non-image `data:` URLs in
  ///   `href`/`src` are stripped.
  /// - Set [allowDataAttributes] to `true` to also permit `data-*` attributes.
  static String sanitize(
    String html, {
    List<String>? allowedTags,
    List<String>? allowedAttributes,
    bool allowDataAttributes = false,
  }) {
    final allowed = allowedTags ?? defaultAllowedTags;
    final allowedAttrs = allowedAttributes ?? defaultAllowedAttributes;

    // Strip null bytes — browsers interpret <script\x00> as NOT a <script> tag,
    // letting the content through a tag-name check.  Remove them first.
    // ignore: parameter_assignments
    html = html.replaceAll('\x00', '');

    // parseFragment avoids wrapping in <html><body> — gives us back only the
    // supplied markup as a DocumentFragment.
    final fragment = html_parser.parseFragment(html);

    _sanitizeFragment(fragment, allowed, allowedAttrs, allowDataAttributes);

    return fragment.outerHtml;
  }

  // ---------------------------------------------------------------------------
  // Internal DOM walk
  // ---------------------------------------------------------------------------

  static void _sanitizeFragment(
    dom.Node node,
    List<String> allowed,
    List<String> allowedAttrs,
    bool allowDataAttributes,
  ) {
    // Iterate in reverse so index stays valid after removals/replacements.
    for (int i = node.nodes.length - 1; i >= 0; i--) {
      final child = node.nodes[i];

      if (child is dom.Element) {
        final tag = child.localName?.toLowerCase() ?? '';

        if (dangerousTags.contains(tag)) {
          // Drop the element AND all its children.
          child.remove();
        } else if (!allowed.contains(tag)) {
          // Unwrap: replace element with its own (already-processed) children.
          // First recurse into children, then lift them up.
          _sanitizeFragment(child, allowed, allowedAttrs, allowDataAttributes);
          final parent = child.parentNode;
          if (parent != null) {
            final idx = parent.nodes.indexOf(child);
            child.remove();
            // reparentChildren would append — insert at idx manually.
            final children = List<dom.Node>.from(child.nodes);
            child.nodes.clear();
            for (int j = 0; j < children.length; j++) {
              parent.nodes.insert(idx + j, children[j]);
            }
          } else {
            child.remove();
          }
        } else {
          // Allowed element — sanitize its attributes then recurse.
          _sanitizeAttributes(child, allowedAttrs, allowDataAttributes);
          _sanitizeFragment(child, allowed, allowedAttrs, allowDataAttributes);
        }
      }
      // Text / Comment nodes are left untouched.
    }
  }

  static void _sanitizeAttributes(
    dom.Element element,
    List<String> allowedAttrs,
    bool allowDataAttributes,
  ) {
    final toRemove = <Object>[];

    for (final entry in element.attributes.entries) {
      final name = (entry.key is String)
          ? (entry.key as String).toLowerCase()
          : entry.key.toString().toLowerCase();

      // Always strip dangerous attribute names.
      if (dangerousAttributes.contains(name)) {
        toRemove.add(entry.key);
        continue;
      }

      // Strip on* event handlers not in the explicit list.
      if (name.startsWith('on')) {
        toRemove.add(entry.key);
        continue;
      }

      // Allow data-* if requested.
      if (allowDataAttributes && name.startsWith('data-')) continue;

      // Always allow aria-* — purely semantic labels, no executable content.
      if (name.startsWith('aria-')) continue;

      if (!allowedAttrs.contains(name)) {
        toRemove.add(entry.key);
        continue;
      }

      // Validate URL-bearing attributes.
      if (name == 'href' || name == 'src') {
        if (!_isSafeUrl(entry.value)) {
          toRemove.add(entry.key);
        }
      }

      // Strip style attributes containing CSS expression() or javascript:.
      // expression() is an IE-era attack; javascript: can appear in url().
      // @import is blocked to prevent external stylesheet loading.
      if (name == 'style') {
        final styleVal = entry.value.toLowerCase();
        if (styleVal.contains('expression(') ||
            styleVal.contains('javascript:') ||
            styleVal.contains('@import')) {
          toRemove.add(entry.key);
          continue;
        }
      }
    }

    for (final key in toRemove) {
      element.attributes.remove(key);
    }
  }

  /// Returns `false` for dangerous URL schemes.
  ///
  /// Blocked: `javascript:`, `vbscript:`, `data:image/svg` (SVG can embed
  /// `<script>`), and any non-image `data:` URL.
  static bool _isSafeUrl(String url) {
    final trimmed = url.trim().toLowerCase();
    if (trimmed.startsWith('javascript:')) return false;
    if (trimmed.startsWith('vbscript:')) return false;
    // Block SVG data URLs — inline SVG can contain <script> elements.
    if (trimmed.startsWith('data:image/svg')) return false;
    if (trimmed.startsWith('data:') && !trimmed.startsWith('data:image/')) {
      return false;
    }
    return true;
  }

  /// Quick check — returns `true` if [html] likely contains dangerous content.
  ///
  /// This is a fast heuristic; use [sanitize] for actual cleaning.
  static bool containsDangerousContent(String html) {
    final lower = html.toLowerCase();
    for (final tag in dangerousTags) {
      if (lower.contains('<$tag')) return true;
    }
    if (lower.contains('javascript:')) return true;
    if (lower.contains('vbscript:')) return true;
    if (lower.contains('expression(')) return true;
    if (lower.contains('@import')) return true;
    for (final attr in dangerousAttributes) {
      if (lower.contains('$attr=')) return true;
    }
    return false;
  }
}
