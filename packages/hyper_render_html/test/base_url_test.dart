import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_html/hyper_render_html.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('Base URL Resolution - Edge Cases', () {
    late HtmlAdapter adapter;

    setUp(() {
      adapter = HtmlAdapter();
    });

    test('resolves absolute URL unchanged', () {
      const html = '<img src="https://cdn.example.com/image.png">';
      const baseUrl = 'https://example.com';

      final document = adapter.parse(html, baseUrl: baseUrl);
      final img = document.children.first as AtomicNode;

      expect(img.src, equals('https://cdn.example.com/image.png'));
    });

    test('resolves relative path with leading slash', () {
      const html = '<img src="/assets/logo.png">';
      const baseUrl = 'https://example.com/page/subpage';

      final document = adapter.parse(html, baseUrl: baseUrl);
      final img = document.children.first as AtomicNode;

      expect(img.src, equals('https://example.com/assets/logo.png'));
    });

    test('resolves relative path without leading slash', () {
      const html = '<img src="images/photo.jpg">';
      const baseUrl = 'https://example.com/blog/';

      final document = adapter.parse(html, baseUrl: baseUrl);
      final img = document.children.first as AtomicNode;

      expect(img.src, equals('https://example.com/blog/images/photo.jpg'));
    });

    test('resolves parent directory path (..)', () {
      const html = '<img src="../assets/icon.png">';
      const baseUrl = 'https://example.com/blog/post/';

      final document = adapter.parse(html, baseUrl: baseUrl);
      final img = document.children.first as AtomicNode;

      expect(img.src, equals('https://example.com/blog/assets/icon.png'));
    });

    test('resolves protocol-relative URL', () {
      const html = '<img src="//cdn.example.com/image.png">';
      const baseUrl = 'https://example.com';

      final document = adapter.parse(html, baseUrl: baseUrl);
      final img = document.children.first as AtomicNode;

      expect(img.src, equals('https://cdn.example.com/image.png'));
    });

    test('handles empty src gracefully', () {
      const html = '<img src="">';
      const baseUrl = 'https://example.com';

      final document = adapter.parse(html, baseUrl: baseUrl);
      final img = document.children.first as AtomicNode;

      // Empty src should remain empty or return null
      expect(img.src, anyOf(equals(''), isNull));
    });

    test('handles missing src attribute', () {
      const html = '<img alt="No source">';
      const baseUrl = 'https://example.com';

      final document = adapter.parse(html, baseUrl: baseUrl);
      final img = document.children.first as AtomicNode;

      expect(img.src, isNull);
    });

    test('resolves link href with baseUrl', () {
      const html = '<a href="/about">About Us</a>';
      const baseUrl = 'https://example.com';

      final document = adapter.parse(html, baseUrl: baseUrl);
      final link = document.children.first;

      expect(link.attributes['href'], equals('https://example.com/about'));
    });

    test('resolves multiple images with same baseUrl', () {
      const html = '''
        <img src="/logo.png">
        <img src="images/photo.jpg">
        <img src="https://cdn.com/banner.png">
      ''';
      const baseUrl = 'https://example.com/';

      final document = adapter.parse(html, baseUrl: baseUrl);

      final images = document.children.whereType<AtomicNode>().toList();
      expect(images.length, equals(3));

      expect(images[0].src, equals('https://example.com/logo.png'));
      expect(images[1].src, equals('https://example.com/images/photo.jpg'));
      expect(images[2].src, equals('https://cdn.com/banner.png'));
    });

    test('handles invalid baseUrl gracefully', () {
      const html = '<img src="/logo.png">';
      const baseUrl = 'not-a-valid-url';

      // Should not throw, might return original or handle gracefully
      expect(() => adapter.parse(html, baseUrl: baseUrl), returnsNormally);
    });

    test('works without baseUrl parameter', () {
      const html = '<img src="/logo.png">';

      final document = adapter.parse(html);
      final img = document.children.first as AtomicNode;

      // Without baseUrl, relative URLs should remain unchanged
      expect(img.src, equals('/logo.png'));
    });

    test('resolves query parameters correctly', () {
      const html = '<img src="/api/image?id=123&size=large">';
      const baseUrl = 'https://example.com';

      final document = adapter.parse(html, baseUrl: baseUrl);
      final img = document.children.first as AtomicNode;

      expect(img.src, equals('https://example.com/api/image?id=123&size=large'));
    });

    test('resolves fragment identifiers correctly', () {
      const html = '<a href="/page#section">Link</a>';
      const baseUrl = 'https://example.com';

      final document = adapter.parse(html, baseUrl: baseUrl);
      final link = document.children.first;

      expect(link.attributes['href'], equals('https://example.com/page#section'));
    });

    test('handles baseUrl with trailing slash', () {
      const html = '<img src="logo.png">';
      const baseUrl = 'https://example.com/folder/';

      final document = adapter.parse(html, baseUrl: baseUrl);
      final img = document.children.first as AtomicNode;

      expect(img.src, equals('https://example.com/folder/logo.png'));
    });

    test('handles baseUrl without trailing slash', () {
      const html = '<img src="logo.png">';
      const baseUrl = 'https://example.com/folder';

      final document = adapter.parse(html, baseUrl: baseUrl);
      final img = document.children.first as AtomicNode;

      // Should resolve relative to the directory containing 'folder'
      expect(img.src, anyOf(
        equals('https://example.com/logo.png'),
        equals('https://example.com/folder/logo.png'),
      ));
    });

    test('resolves video src with baseUrl', () {
      const html = '<video src="/videos/demo.mp4"></video>';
      const baseUrl = 'https://example.com';

      final document = adapter.parse(html, baseUrl: baseUrl);
      final video = document.children.first as AtomicNode;

      expect(video.src, equals('https://example.com/videos/demo.mp4'));
    });

    test('resolves audio src with baseUrl', () {
      const html = '<audio src="/sounds/beep.mp3"></audio>';
      const baseUrl = 'https://example.com';

      final document = adapter.parse(html, baseUrl: baseUrl);
      final audio = document.children.first as AtomicNode;

      expect(audio.src, equals('https://example.com/sounds/beep.mp3'));
    });

    test('resolves nested links in complex HTML', () {
      const html = '''
        <div>
          <p>Visit <a href="/about">about page</a></p>
          <img src="/logo.png">
        </div>
      ''';
      const baseUrl = 'https://example.com';

      final document = adapter.parse(html, baseUrl: baseUrl);

      // Traverse to find link and image
      UDTNode? link;
      UDTNode? img;

      void traverse(UDTNode node) {
        if (node.tagName == 'a' && link == null) link = node;
        if (node is AtomicNode && node.tagName == 'img' && img == null) img = node;
        for (final child in node.children) {
          traverse(child);
        }
      }

      for (final child in document.children) {
        traverse(child);
      }

      expect(link, isNotNull);
      expect(img, isNotNull);
      expect(link!.attributes['href'], equals('https://example.com/about'));
      expect((img as AtomicNode).src, equals('https://example.com/logo.png'));
    });
  });

  group('Base URL - parseToSections', () {
    late HtmlAdapter adapter;

    setUp(() {
      adapter = HtmlAdapter();
    });

    test('resolves URLs in chunked parsing', () {
      const html = '''
        <p>First paragraph</p>
        <img src="/image1.png">
        <p>Second paragraph</p>
        <img src="/image2.png">
      ''';
      const baseUrl = 'https://example.com';

      final sections = adapter.parseToSections(html, baseUrl: baseUrl);

      // Find all images across sections
      final images = <AtomicNode>[];
      for (final section in sections) {
        void traverse(UDTNode node) {
          if (node is AtomicNode && node.tagName == 'img') {
            images.add(node);
          }
          for (final child in node.children) {
            traverse(child);
          }
        }

        for (final child in section.children) {
          traverse(child);
        }
      }

      expect(images.length, greaterThanOrEqualTo(2));
      for (final img in images) {
        expect(img.src, startsWith('https://example.com/'));
      }
    });
  });
}
