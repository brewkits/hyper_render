# Security Policy

## Supported Versions

We currently support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Security Features

HyperRender includes built-in security features to protect against common web vulnerabilities:

### HTML Sanitization

- **XSS Protection**: Automatic removal of dangerous tags (`<script>`, `<iframe>`, etc.)
- **Event Handler Removal**: Strips all `on*` event attributes (`onclick`, `onerror`, etc.)
- **Protocol Filtering**: Blocks dangerous URL protocols (`javascript:`, `data:`, etc.)
- **Customizable Whitelist**: Configure allowed tags and attributes

**Enable sanitization for all user-generated content**:

```dart
HyperViewer(
  html: userGeneratedContent,
  sanitize: true, // Always enable for untrusted content
)
```

### Best Practices

1. **Always sanitize user input**:
   ```dart
   // ✅ GOOD
   HyperViewer(html: userInput, sanitize: true)

   // ❌ BAD
   HyperViewer(html: userInput) // sanitize defaults to false!
   ```

2. **Use strict whitelists for sensitive contexts**:
   ```dart
   HyperViewer(
     html: userComment,
     sanitize: true,
     allowedTags: ['p', 'br', 'strong', 'em'], // Only allow basic formatting
   )
   ```

3. **Validate URLs before rendering**:
   ```dart
   HyperViewer(
     html: content,
     onLinkTap: (url) {
       if (url.startsWith('https://')) {
         // Safe to open
       }
     },
   )
   ```

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please follow these steps:

### Reporting Process

1. **DO NOT** open a public issue for security vulnerabilities
2. **Email** security details to the maintainers at: [Open an issue with `[SECURITY]` prefix]
3. **Include** the following information:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment**: We'll acknowledge receipt within 48 hours
- **Assessment**: We'll assess the vulnerability within 7 days
- **Updates**: We'll keep you informed of our progress
- **Fix Timeline**: Critical issues will be addressed within 30 days
- **Credit**: We'll credit you in the security advisory (unless you prefer to remain anonymous)

### Disclosure Policy

- **Coordinated Disclosure**: We follow a coordinated disclosure process
- **Public Advisory**: After a fix is released, we'll publish a security advisory
- **CVE Assignment**: For significant vulnerabilities, we'll request a CVE identifier

## Security Considerations

### Content Rendering

- **Untrusted HTML**: Always use `sanitize: true` for user-generated content
- **Image Sources**: Validate image URLs to prevent SSRF attacks
- **Link Destinations**: Verify link URLs before navigation

### Performance & DoS

- **Large Documents**: Use `HyperRenderMode.virtualized` for very large content to prevent memory exhaustion
- **Nested Elements**: Parser has built-in depth limits to prevent stack overflow
- **CSS Complexity**: Complex CSS is sanitized to prevent ReDoS attacks

### Data Handling

- **Clipboard Operations**: Clipboard access requires user interaction
- **Local Storage**: No automatic data persistence
- **Network Requests**: No automatic external resource loading

## Known Limitations

1. **CSS Sanitization**: Basic CSS sanitization is implemented, but complex CSS expressions are not fully validated
2. **SVG Content**: SVG sanitization is limited; avoid rendering untrusted SVG
3. **Data URLs**: Data URLs in images are allowed by default; disable with custom sanitization if needed

## Security Updates

Security updates will be:
- Released as patch versions (e.g., 1.0.1)
- Documented in CHANGELOG.md with `[SECURITY]` prefix
- Announced in GitHub releases

## Contact

For security-related questions or concerns:
- Open an issue with `[SECURITY]` prefix
- Check existing [security advisories](https://github.com/brewkits/hyper_render/security/advisories)

---

**Remember**: Security is a shared responsibility. Always validate and sanitize untrusted content!
