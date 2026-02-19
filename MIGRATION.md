# Migration Guide

## v1.x → v2.0

### Breaking API changes

#### `HyperViewer` constructor

`html:` is now `content:` (with `contentType` selecting the format).
The old named constructor form still works via a deprecated alias:

```dart
// v1.x
HyperViewer(html: '<p>Hello</p>')

// v2.0 — preferred
HyperViewer(html: '<p>Hello</p>')          // still works (html: alias)
HyperViewer.delta(delta: jsonString)       // new
HyperViewer.markdown(markdown: mdString)   // new
```

#### Sanitization now defaults to `true`

In v1.x, `sanitize` defaulted to `false`. In v2.0 it defaults to `true`.

```dart
// v1.x — user HTML was rendered as-is (XSS risk)
HyperViewer(html: userContent)

// v2.0 — sanitized by default
HyperViewer(html: userContent)              // ✅ safe
HyperViewer(html: trustedHtml, sanitize: false)  // bypass for known-safe HTML
```

#### `HtmlSanitizer` — DOM-based (behaviour change)

The sanitizer was rewritten from regex to a DOM parser. Results are more
correct for nested/malformed markup, but output serialisation may differ
slightly (attribute order, self-closing tags). If you rely on the exact
sanitized string for equality checks, update your tests.

#### `RenderHyperBox` — public extension methods

Selection methods (`getSelectedText`, `clearSelection`, `selectAll`,
`getSelectionRects`, `getStartHandleRect`, `getEndHandleRect`,
`updateSelectionFromHandle`) moved to a public extension `RenderHyperBoxSelection`.
Import `package:hyper_render/hyper_render.dart` as usual — no import change needed.

---

## v2.0 → v2.1

### New features (non-breaking)

| Feature | API |
|---------|-----|
| `baseUrl` — resolve relative URLs | `HyperViewer(html: ..., baseUrl: 'https://example.com')` |
| `customCss` — inject styles | `HyperViewer(html: ..., customCss: 'p { color: red; }')` |
| `debugShowHyperRenderBounds` | `HyperViewer(html: ..., debugShowHyperRenderBounds: true)` |
| CSS `!important` | Now honoured in both `lib/` and `packages/` resolvers |
| DOM-based HTML sanitizer | Automatic — no API change |
| `Object.hash` TextPainter cache | Automatic — no API change |

### `CssRule` / `ParsedCssRule` — new field

`importantDeclarations` field added to both classes. Existing code that
constructs `CssRule`/`ParsedCssRule` directly will still compile because the
field is optional (defaults to `const {}`).

```dart
// v2.0 — works unchanged
ParsedCssRule(selector: 'p', declarations: {'color': 'red'}, specificity: 1)

// v2.1 — new optional field
ParsedCssRule(
  selector: 'p',
  declarations: {'color': 'red'},
  importantDeclarations: {'font-weight': 'bold'},  // !important declarations
  specificity: 1,
)
```

### Removed deprecated aliases

- `HyperViewer.html` getter (was `@Deprecated('Use content instead')`) — still
  present in v2.1 for compatibility, targeted for removal in v3.0.

---

## Upcoming in v3.0

- Remove `HyperViewer.html` deprecated getter
- Remove `HyperContentType.html` (use `HyperViewer(html:)` constructor directly)
- `sanitize` default will stay `true`
