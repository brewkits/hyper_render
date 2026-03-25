import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  group('buildSvgWidget', () {
    // ── inline <svg> ────────────────────────────────────────────────────────

    test('returns SvgPicture.string for inline svg node with svgData', () {
      final node = AtomicNode(
        tagName: 'svg',
        svgData: '<svg><circle cx="10" cy="10" r="10"/></svg>',
      );
      final widget = buildSvgWidget(node);
      expect(widget, isA<SvgPicture>());
    });

    test('returns null for svg node with no svgData and no src', () {
      final node = AtomicNode(tagName: 'svg');
      final widget = buildSvgWidget(node);
      expect(widget, isNull);
    });

    // ── <img src="*.svg"> ───────────────────────────────────────────────────

    test('returns SvgPicture for img with .svg src', () {
      final node = AtomicNode(tagName: 'img', src: 'https://example.com/icon.svg');
      final widget = buildSvgWidget(node);
      expect(widget, isA<SvgPicture>());
    });

    test('returns SvgPicture for img with .svg?query src', () {
      final node = AtomicNode(
          tagName: 'img', src: 'https://cdn.example.com/logo.svg?v=2');
      final widget = buildSvgWidget(node);
      expect(widget, isA<SvgPicture>());
    });

    test('returns null for img with non-svg src', () {
      final node = AtomicNode(tagName: 'img', src: 'https://example.com/photo.png');
      final widget = buildSvgWidget(node);
      expect(widget, isNull);
    });

    test('returns null for non-svg, non-img node', () {
      final node = AtomicNode(tagName: 'video', src: 'https://example.com/v.mp4');
      final widget = buildSvgWidget(node);
      expect(widget, isNull);
    });

    test('returns null for floated svg img (handled by canvas)', () {
      final style = ComputedStyle()..float = HyperFloat.left;
      final node = AtomicNode(
        tagName: 'img',
        src: 'https://example.com/float.svg',
        style: style,
      );
      final widget = buildSvgWidget(node);
      expect(widget, isNull);
    });

    // ── data URI ────────────────────────────────────────────────────────────

    test('returns SvgPicture.string for base64 SVG data URI', () {
      // <svg><rect width="10" height="10"/></svg> base64-encoded
      const b64 =
          'PHN2Zz48cmVjdCB3aWR0aD0iMTAiIGhlaWdodD0iMTAiLz48L3N2Zz4=';
      final node = AtomicNode(
        tagName: 'img',
        src: 'data:image/svg+xml;base64,$b64',
      );
      final widget = buildSvgWidget(node);
      expect(widget, isA<SvgPicture>());
    });

    test('returns SvgPicture.string for url-encoded SVG data URI', () {
      const encoded =
          'data:image/svg+xml,%3Csvg%3E%3Ccircle%20r%3D%2210%22%2F%3E%3C%2Fsvg%3E';
      final node = AtomicNode(tagName: 'img', src: encoded);
      final widget = buildSvgWidget(node);
      expect(widget, isA<SvgPicture>());
    });

    // ── non-AtomicNode ──────────────────────────────────────────────────────

    test('returns null for non-atomic nodes', () {
      final block = BlockNode.p(children: [TextNode('hello')]);
      expect(buildSvgWidget(block), isNull);

      final inline = InlineNode.span(children: [TextNode('hi')]);
      expect(buildSvgWidget(inline), isNull);
    });
  });
}
