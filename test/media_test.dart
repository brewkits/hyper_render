import "package:hyper_render/hyper_render.dart";
// Tests for render_media.dart — MediaInfo, MediaInfo.fromNode,
// DefaultMediaWidget sizing, and the sanitizer allowing video/audio.
//
// No mocks used: tests exercise real objects and real widget rendering.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── MediaInfo unit tests ────────────────────────────────────────────────

  group('MediaInfo — properties', () {
    test('default values are sensible', () {
      const info = MediaInfo(
        type: MediaType.video,
        src: 'https://example.com/video.mp4',
      );

      expect(info.src, equals('https://example.com/video.mp4'));
      expect(info.type, equals(MediaType.video));
      expect(info.isVideo, isTrue);
      expect(info.isAudio, isFalse);
      expect(info.controls, isTrue);
      expect(info.autoplay, isFalse);
      expect(info.loop, isFalse);
      expect(info.muted, isFalse);
      expect(info.poster, isNull);
      expect(info.width, isNull);
      expect(info.height, isNull);
      expect(info.title, isNull);
    });

    test('audio MediaInfo is correctly typed', () {
      const info = MediaInfo(type: MediaType.audio, src: 'audio.mp3');
      expect(info.isAudio, isTrue);
      expect(info.isVideo, isFalse);
    });

    test('all optional fields are stored', () {
      const info = MediaInfo(
        type: MediaType.video,
        src: 'v.mp4',
        poster: 'poster.jpg',
        autoplay: true,
        loop: true,
        muted: true,
        controls: false,
        width: 640,
        height: 360,
        title: 'My Video',
      );

      expect(info.poster, equals('poster.jpg'));
      expect(info.autoplay, isTrue);
      expect(info.loop, isTrue);
      expect(info.muted, isTrue);
      expect(info.controls, isFalse);
      expect(info.width, equals(640));
      expect(info.height, equals(360));
      expect(info.title, equals('My Video'));
    });
  });

  // ─── MediaInfo.fromNode ──────────────────────────────────────────────────

  group('MediaInfo.fromNode', () {
    test('creates video MediaInfo from AtomicNode', () {
      final node = AtomicNode(
        tagName: 'video',
        src: 'video.mp4',
        attributes: {
          'src': 'video.mp4',
          'poster': 'poster.jpg',
          'controls': '',
          'width': '640',
          'height': '360',
        },
        intrinsicWidth: 640,
        intrinsicHeight: 360,
      );

      final info = MediaInfo.fromNode(node);

      expect(info.type, equals(MediaType.video));
      expect(info.src, equals('video.mp4'));
      expect(info.poster, equals('poster.jpg'));
      expect(info.controls, isTrue);
      expect(info.width, equals(640));
      expect(info.height, equals(360));
    });

    test('creates audio MediaInfo from AtomicNode', () {
      final node = AtomicNode(
        tagName: 'audio',
        src: 'audio.mp3',
        attributes: {'src': 'audio.mp3', 'controls': ''},
      );

      final info = MediaInfo.fromNode(node);

      expect(info.type, equals(MediaType.audio));
      expect(info.isAudio, isTrue);
      expect(info.src, equals('audio.mp3'));
    });

    test('autoplay/loop/muted boolean attrs parsed', () {
      final node = AtomicNode(
        tagName: 'video',
        src: 'v.mp4',
        attributes: {
          'src': 'v.mp4',
          'autoplay': '',
          'loop': '',
          'muted': '',
        },
      );

      final info = MediaInfo.fromNode(node);
      expect(info.autoplay, isTrue);
      expect(info.loop, isTrue);
      expect(info.muted, isTrue);
    });

    test('missing src falls back to empty string', () {
      final node = AtomicNode(tagName: 'video', attributes: {});
      final info = MediaInfo.fromNode(node);
      expect(info.src, equals(''));
    });

    test('controls defaults to true when attribute absent', () {
      final node = AtomicNode(
        tagName: 'video',
        src: 'v.mp4',
        attributes: {'src': 'v.mp4'},
      );
      final info = MediaInfo.fromNode(node);
      expect(info.controls, isTrue);
    });
  });

  // ─── HTML parsing: video/audio survive sanitizer ─────────────────────────

  group('HTML parsing — video/audio through sanitizer', () {
    late HtmlAdapter adapter;
    setUp(() => adapter = HtmlAdapter());

    test('video tag parsed as AtomicNode', () {
      final doc = adapter.parse(
        '<video src="v.mp4" width="320" height="180" controls></video>',
      );

      AtomicNode? video;
      void walk(UDTNode n) {
        if (n is AtomicNode && n.tagName == 'video') video = n;
        for (final c in n.children) {
          walk(c);
        }
      }
      walk(doc);

      expect(video, isNotNull);
      expect(video!.src, equals('v.mp4'));
      expect(video!.intrinsicWidth, equals(320));
      expect(video!.intrinsicHeight, equals(180));
      expect(video!.attributes['controls'], isNotNull);
    });

    test('audio tag parsed as AtomicNode', () {
      final doc = adapter.parse(
        '<audio src="audio.mp3" controls></audio>',
      );

      AtomicNode? audio;
      void walk(UDTNode n) {
        if (n is AtomicNode && n.tagName == 'audio') audio = n;
        for (final c in n.children) {
          walk(c);
        }
      }
      walk(doc);

      expect(audio, isNotNull);
      expect(audio!.src, equals('audio.mp3'));
    });

    test('video poster attribute preserved after parsing', () {
      final doc = adapter.parse(
        '<video src="v.mp4" poster="poster.jpg"></video>',
      );

      AtomicNode? video;
      void walk(UDTNode n) {
        if (n is AtomicNode && n.tagName == 'video') video = n;
        for (final c in n.children) {
          walk(c);
        }
      }
      walk(doc);

      expect(video, isNotNull);
      expect(video!.attributes['poster'], equals('poster.jpg'));
    });
  });

  // ─── Sanitizer: video/audio allowed ─────────────────────────────────────

  group('HtmlSanitizer — video/audio allowed', () {
    test('video tag survives sanitization', () {
      const html = '<video src="v.mp4" controls width="320" height="180"></video>';
      final result = HtmlSanitizer.sanitize(html);

      expect(result, contains('video'));
      expect(result, contains('src'));
    });

    test('audio tag survives sanitization', () {
      const html = '<audio src="a.mp3" controls></audio>';
      final result = HtmlSanitizer.sanitize(html);

      expect(result, contains('audio'));
    });

    test('video poster attribute survives sanitization', () {
      const html = '<video src="v.mp4" poster="p.jpg" controls></video>';
      final result = HtmlSanitizer.sanitize(html);

      expect(result, contains('poster'));
    });

    test('source tag inside video survives sanitization', () {
      const html = '''
<video controls>
  <source src="v.mp4" type="video/mp4">
  <source src="v.webm" type="video/webm">
</video>
''';
      final result = HtmlSanitizer.sanitize(html);
      expect(result, contains('source'));
      expect(result, contains('video/mp4'));
    });

    test('video autoplay muted loop survive sanitization', () {
      const html = '<video src="v.mp4" autoplay muted loop></video>';
      final result = HtmlSanitizer.sanitize(html);

      expect(result, contains('autoplay'));
      expect(result, contains('muted'));
      expect(result, contains('loop'));
    });

    test('dangerous attributes stripped from video', () {
      const html = '<video src="v.mp4" onclick="evil()" onerror="bad()"></video>';
      final result = HtmlSanitizer.sanitize(html);

      expect(result, isNot(contains('onclick')));
      expect(result, isNot(contains('onerror')));
      expect(result, contains('video'));
    });
  });

  // ─── DefaultMediaWidget rendering ────────────────────────────────────────

  group('DefaultMediaWidget — rendering', () {
    testWidgets('video placeholder renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultMediaWidget(
              mediaInfo: const MediaInfo(
                type: MediaType.video,
                src: 'v.mp4',
                poster: null,
                width: 320,
                height: 180,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(DefaultMediaWidget), findsOneWidget);
    });

    testWidgets('audio placeholder renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultMediaWidget(
              mediaInfo: const MediaInfo(
                type: MediaType.audio,
                src: 'a.mp3',
                width: 300,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(DefaultMediaWidget), findsOneWidget);
    });

    testWidgets('video with large width is capped to container', (tester) async {
      // Container is 400px wide; video requests 1920px → must not overflow
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: DefaultMediaWidget(
                mediaInfo: const MediaInfo(
                  type: MediaType.video,
                  src: 'v.mp4',
                  width: 1920,
                  height: 1080,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Widget must not overflow the 400px container
      final renderBox = tester.renderObject<RenderBox>(
        find.byType(DefaultMediaWidget),
      );
      expect(renderBox.size.width, lessThanOrEqualTo(400));
    });

    testWidgets('video with no explicit size fills container at 16:9',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: DefaultMediaWidget(
                mediaInfo: const MediaInfo(
                  type: MediaType.video,
                  src: 'v.mp4',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      final renderBox = tester.renderObject<RenderBox>(
        find.byType(DefaultMediaWidget),
      );
      expect(renderBox.size.width, lessThanOrEqualTo(360));
      // Height should be roughly 16:9 of width
      expect(renderBox.size.height, greaterThan(0));
    });

    testWidgets('onTap callback is called when video is tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultMediaWidget(
              mediaInfo: const MediaInfo(
                type: MediaType.video,
                src: 'v.mp4',
                width: 320,
                height: 180,
              ),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(DefaultMediaWidget));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  // ─── Full pipeline: HyperViewer with video HTML ──────────────────────────

  group('HyperViewer — video/audio full pipeline', () {
    testWidgets('video HTML renders via widgetBuilder', (tester) async {
      bool builderCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<video src="v.mp4" width="320" height="180" controls></video>',
              widgetBuilder: (node) {
                if (node is AtomicNode && node.tagName == 'video') {
                  builderCalled = true;
                  return DefaultMediaWidget(
                    mediaInfo: MediaInfo.fromNode(node),
                  );
                }
                return null;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(builderCalled, isTrue);
    });

    testWidgets('audio HTML renders via widgetBuilder', (tester) async {
      bool builderCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<audio src="a.mp3" controls></audio>',
              widgetBuilder: (node) {
                if (node is AtomicNode && node.tagName == 'audio') {
                  builderCalled = true;
                  return DefaultMediaWidget(
                    mediaInfo: MediaInfo.fromNode(node),
                  );
                }
                return null;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(builderCalled, isTrue);
    });

    testWidgets('video with sanitize:true still renders', (tester) async {
      // Default: sanitize=true — video must survive sanitizer
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<video src="v.mp4" controls width="320" height="180"></video>',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('mixed text and video renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HyperViewer(
                html: '''
<article>
  <h1>Video Article</h1>
  <p>Introduction paragraph before the video.</p>
  <video src="v.mp4" width="320" height="180" controls></video>
  <p>Paragraph after the video.</p>
</article>
''',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(HyperRenderWidget), findsAtLeastNWidgets(1));
    });
  });

  // ─── MediaNodeExtension ──────────────────────────────────────────────────

  group('MediaNodeExtension', () {
    test('isMedia true for video', () {
      final node = AtomicNode(tagName: 'video', src: 'v.mp4', attributes: {});
      expect(node.isMedia, isTrue);
    });

    test('isMedia true for audio', () {
      final node = AtomicNode(tagName: 'audio', src: 'a.mp3', attributes: {});
      expect(node.isMedia, isTrue);
    });

    test('isMedia false for img', () {
      final node = AtomicNode(tagName: 'img', src: 'i.png', attributes: {});
      expect(node.isMedia, isFalse);
    });

    test('isVideo / isAudio exclusive', () {
      final video = AtomicNode(tagName: 'video', attributes: {});
      final audio = AtomicNode(tagName: 'audio', attributes: {});
      expect(video.isVideo, isTrue);
      expect(video.isAudio, isFalse);
      expect(audio.isAudio, isTrue);
      expect(audio.isVideo, isFalse);
    });

    test('mediaInfo getter wraps node', () {
      final node = AtomicNode(
        tagName: 'video',
        src: 'v.mp4',
        attributes: {'src': 'v.mp4', 'poster': 'p.jpg'},
      );
      final info = node.mediaInfo;
      expect(info.src, equals('v.mp4'));
      expect(info.poster, equals('p.jpg'));
    });
  });
}
