# Security & Accessibility Guide

## 🔒 Security Features

### HTML Sanitization (XSS Protection)

HyperRender v1.0+ includes built-in HTML sanitization to protect against Cross-Site Scripting (XSS) attacks.

#### Quick Start

```dart
// ❌ UNSAFE - Never render untrusted HTML directly
HyperViewer(html: userGeneratedContent)

// ✅ SAFE - Enable sanitization
HyperViewer(
  html: userGeneratedContent,
  sanitize: true,  // Removes dangerous tags and attributes
)
```

#### What Gets Removed?

The sanitizer removes:

1. **Dangerous Tags**
   - `<script>` - JavaScript execution
   - `<iframe>` - Embedding external content
   - `<object>`, `<embed>` - Plugin content
   - `<form>`, `<input>`, `<button>` - Form elements
   - `<link>`, `<meta>`, `<base>` - Document metadata

2. **Event Handlers**
   - `onclick`, `ondblclick`, `onmousedown`, etc.
   - `onload`, `onerror`, `onabort`
   - `onkeydown`, `onkeypress`, `onkeyup`
   - All JavaScript event handlers

3. **Dangerous Protocols**
   - `javascript:` URLs
   - `vbscript:` URLs
   - `data:` URLs (except for images)

#### Custom Whitelists

For stricter filtering, provide a custom whitelist:

```dart
HyperViewer(
  html: userContent,
  sanitize: true,
  allowedTags: [
    'p', 'br', 'strong', 'em', 'a', 'img',  // Only allow these
  ],
)
```

#### Data Attributes

By default, `data-*` attributes are removed. To allow them:

```dart
HyperViewer(
  html: content,
  sanitize: true,
  allowDataAttributes: true,  // Permit data-* attributes
)
```

### Security Best Practices

#### 1. Always Sanitize User Input

```dart
// User-generated content (comments, posts, etc.)
HyperViewer(
  html: userComment,
  sanitize: true,  // REQUIRED
)

// Trusted content from your backend
HyperViewer(
  html: cmsContent,
  sanitize: true,  // Recommended as defense-in-depth
)
```

#### 2. Detect Dangerous Content

Check if content contains attacks before rendering:

```dart
if (HtmlSanitizer.containsDangerousContent(html)) {
  // Show warning to user
  print('⚠️ Dangerous content detected - sanitizing');
}

HyperViewer(
  html: html,
  sanitize: true,
)
```

#### 3. Use Strict Whitelists for High-Security Apps

```dart
// Banking app example
HyperViewer(
  html: transactionDetails,
  sanitize: true,
  allowedTags: ['p', 'strong', 'em'],  // Very restrictive
)
```

#### 4. Validate URLs in Links and Images

```dart
HyperViewer(
  html: content,
  sanitize: true,
  onLinkTap: (url) {
    final uri = Uri.tryParse(url);

    // Validate before opening
    if (uri == null || !uri.hasScheme ||
        !['http', 'https'].contains(uri.scheme)) {
      print('❌ Invalid URL: $url');
      return;
    }

    launchUrl(uri);
  },
)
```

### Attack Examples (Demo App)

Run the Security Demo to see how sanitization blocks real attacks:

```dart
import 'package:example/security_demo.dart';

// In your app
SecurityDemo()
```

Examples include:
- XSS via `<script>` injection
- Event handler attacks (`onerror`, `onclick`)
- JavaScript URL attacks
- IFrame injection
- Form injection
- Mixed attacks

---

## ♿ Accessibility Features

### Semantic Labels for Screen Readers

HyperRender provides full WCAG 2.1 compliant accessibility support.

#### Quick Start

```dart
// Default semantic label
HyperViewer(
  html: articleHtml,
  // Uses "Article content" by default
)

// Custom semantic label
HyperViewer(
  html: newsArticle,
  semanticLabel: 'Breaking news: Flutter 4.0 released',
)
```

#### Best Practices

##### 1. Provide Descriptive Labels

```dart
// ❌ BAD - Not descriptive
HyperViewer(
  html: article,
  semanticLabel: 'Article',
)

// ✅ GOOD - Descriptive and contextual
HyperViewer(
  html: article,
  semanticLabel: 'News article: Flutter 4.0 brings major improvements',
)
```

##### 2. Include Content Type and Context

```dart
// Email
HyperViewer(
  html: emailBody,
  semanticLabel: 'Email from John Smith: Meeting reminder for tomorrow',
)

// Product
HyperViewer(
  html: productDetails,
  semanticLabel: 'Product details: Premium wireless headphones',
)

// Recipe
HyperViewer(
  html: recipe,
  semanticLabel: 'Recipe: Chocolate chip cookies, 30 minutes total time',
)
```

##### 3. Only Exclude Decorative Content

```dart
// ✅ GOOD - Decorative image
HyperViewer(
  html: '<img src="banner.jpg" alt="">',
  excludeSemantics: true,  // No important info
)

// ❌ BAD - Important content
HyperViewer(
  html: '<article>News story...</article>',
  excludeSemantics: true,  // Users can't access this!
)
```

#### Screen Reader Testing

##### iOS (VoiceOver)
1. Settings → Accessibility → VoiceOver → Enable
2. Triple-click home/side button to toggle
3. Swipe to navigate, double-tap to activate

##### Android (TalkBack)
1. Settings → Accessibility → TalkBack → Enable
2. Use volume keys to toggle (if configured)
3. Swipe to navigate, double-tap to activate

### Accessibility Demo

Run the Accessibility Demo to test screen reader support:

```dart
import 'package:example/accessibility_demo.dart';

// In your app
AccessibilityDemo()
```

Examples include:
- News articles
- Blog posts
- Product details
- Recipes
- Emails
- CJK content (Japanese with Ruby)

---

## 🧪 Testing

### Security Tests

```bash
# Run all security tests
flutter test test/html_sanitizer_test.dart
flutter test test/security_edge_cases_test.dart

# Run integration tests
flutter test test/integration/security_accessibility_integration_test.dart
```

**Coverage:**
- ✅ 30 XSS attack vectors
- ✅ 35 edge cases
- ✅ Real-world exploits
- ✅ Performance benchmarks

### Accessibility Tests

```bash
# Run accessibility tests
flutter test test/accessibility_test.dart
```

**Coverage:**
- ✅ Semantic labels
- ✅ Screen reader integration
- ✅ Exclusion from semantics
- ✅ Content type support

---

## 📊 Combined Security + Accessibility

You can (and should!) use both features together:

```dart
HyperViewer(
  html: userGeneratedContent,

  // Security
  sanitize: true,
  allowedTags: ['p', 'strong', 'em', 'a'],

  // Accessibility
  semanticLabel: 'User comment by ${username}',

  // Additional
  selectable: true,
  onLinkTap: (url) => launchUrl(Uri.parse(url)),
)
```

### Real-World Example: Comments Section

```dart
class CommentsSection extends StatelessWidget {
  final List<Comment> comments;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.authorName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                HyperViewer(
                  html: comment.htmlContent,

                  // 🔒 Security: Sanitize user content
                  sanitize: true,
                  allowedTags: ['p', 'br', 'strong', 'em', 'a'],

                  // ♿ Accessibility: Descriptive label
                  semanticLabel: 'Comment by ${comment.authorName}: ${comment.preview}',

                  // Link handling
                  onLinkTap: (url) => _handleLink(url),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && ['http', 'https'].contains(uri.scheme)) {
      launchUrl(uri);
    }
  }
}
```

---

## 🎯 Quick Reference

### Security Checklist

- [ ] Enable `sanitize: true` for all user-generated content
- [ ] Use custom `allowedTags` for strict filtering
- [ ] Validate URLs before opening links
- [ ] Test with real attack vectors
- [ ] Never trust user input

### Accessibility Checklist

- [ ] Provide meaningful `semanticLabel` for all content
- [ ] Include content type and context in labels
- [ ] Only exclude decorative content with `excludeSemantics`
- [ ] Test with VoiceOver (iOS) and TalkBack (Android)
- [ ] Follow WCAG 2.1 guidelines

---

## 📚 Additional Resources

- [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Flutter Accessibility Guide](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [MDN: HTML Sanitization](https://developer.mozilla.org/en-US/docs/Web/API/HTML_Sanitizer_API)

---

## 🐛 Known Limitations

### Security

1. **CSS Injection**: The current implementation doesn't validate CSS content in `style` attributes
   - **Workaround**: Remove `style` from allowed attributes for high-security apps
   - **Future**: v1.1 will add CSS sanitization

2. **HTML Comments**: HTML comments are preserved
   - **Workaround**: Manual comment stripping if needed
   - **Future**: v1.1 will add comment removal option

### Accessibility

1. **Dynamic Content**: Semantic labels don't auto-update when content changes
   - **Workaround**: Set new label when content changes
   - **Future**: v1.1 will add auto-labeling from content

---

**Questions or Issues?**
File an issue at: https://github.com/brewkits/hyper_render/issues
