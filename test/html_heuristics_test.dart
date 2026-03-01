import "package:hyper_render/hyper_render.dart";
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HtmlHeuristics', () {
    // -----------------------------------------------------------------------
    // hasComplexTables
    // -----------------------------------------------------------------------
    group('hasComplexTables', () {
      test('returns false for simple table without spans', () {
        const html = '<table><tr><td>A</td><td>B</td></tr></table>';
        expect(HtmlHeuristics.hasComplexTables(html), isFalse);
      });

      test('returns false for colspan="2"', () {
        const html = '<td colspan="2">A</td>';
        expect(HtmlHeuristics.hasComplexTables(html), isFalse);
      });

      test('returns false for rowspan="2"', () {
        const html = '<td rowspan="2">A</td>';
        expect(HtmlHeuristics.hasComplexTables(html), isFalse);
      });

      test('returns true for colspan="3"', () {
        const html = '<td colspan="3">Wide</td>';
        expect(HtmlHeuristics.hasComplexTables(html), isTrue);
      });

      test('returns true for rowspan="5"', () {
        const html = '<td rowspan="5">Tall</td>';
        expect(HtmlHeuristics.hasComplexTables(html), isTrue);
      });

      test('returns true for colspan="10"', () {
        const html = '<td colspan="10">Very wide</td>';
        expect(HtmlHeuristics.hasComplexTables(html), isTrue);
      });

      test('is case insensitive', () {
        const html = '<td COLSPAN="4">A</td>';
        expect(HtmlHeuristics.hasComplexTables(html), isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // hasUnsupportedCss
    // -----------------------------------------------------------------------
    group('hasUnsupportedCss', () {
      test('returns false for safe CSS', () {
        const html = '<p style="color: red; font-size: 16px;">Text</p>';
        expect(HtmlHeuristics.hasUnsupportedCss(html), isFalse);
      });

      test('returns true for position: absolute', () {
        const html = '<div style="position: absolute; top: 0;">x</div>';
        expect(HtmlHeuristics.hasUnsupportedCss(html), isTrue);
      });

      test('returns true for position: fixed', () {
        const html = '<div style="position:fixed;">x</div>';
        expect(HtmlHeuristics.hasUnsupportedCss(html), isTrue);
      });

      test('returns true for z-index', () {
        const html = '<div style="z-index: 99;">x</div>';
        expect(HtmlHeuristics.hasUnsupportedCss(html), isTrue);
      });

      test('returns true for clip-path', () {
        const html = '<div style="clip-path: circle(50%);">x</div>';
        expect(HtmlHeuristics.hasUnsupportedCss(html), isTrue);
      });

      test('returns true for column-count', () {
        const html = '<div style="column-count: 3;">x</div>';
        expect(HtmlHeuristics.hasUnsupportedCss(html), isTrue);
      });

      test('returns true for grid-template-areas in <style> block', () {
        const html = '<style>.g { grid-template-areas: "a b"; }</style>';
        expect(HtmlHeuristics.hasUnsupportedCss(html), isTrue);
      });

      test('returns false for position: relative (supported)', () {
        const html = '<div style="position: relative;">x</div>';
        expect(HtmlHeuristics.hasUnsupportedCss(html), isFalse);
      });

      test('returns false for position: static (supported)', () {
        const html = '<div style="position: static;">x</div>';
        expect(HtmlHeuristics.hasUnsupportedCss(html), isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // hasUnsupportedElements
    // -----------------------------------------------------------------------
    group('hasUnsupportedElements', () {
      test('returns false for standard text HTML', () {
        const html = '<p>Hello <strong>world</strong></p>';
        expect(HtmlHeuristics.hasUnsupportedElements(html), isFalse);
      });

      test('returns true for <canvas>', () {
        const html = '<canvas id="c" width="200"></canvas>';
        expect(HtmlHeuristics.hasUnsupportedElements(html), isTrue);
      });

      test('returns true for <form>', () {
        const html = '<form action="/submit"><input type="text"></form>';
        expect(HtmlHeuristics.hasUnsupportedElements(html), isTrue);
      });

      test('returns true for <input>', () {
        const html = '<input type="text" name="q">';
        expect(HtmlHeuristics.hasUnsupportedElements(html), isTrue);
      });

      test('returns true for <select>', () {
        const html = '<select><option>A</option></select>';
        expect(HtmlHeuristics.hasUnsupportedElements(html), isTrue);
      });

      test('returns true for <textarea>', () {
        const html = '<textarea rows="4">text</textarea>';
        expect(HtmlHeuristics.hasUnsupportedElements(html), isTrue);
      });

      test('returns true for <script>', () {
        const html = '<script>alert(1)</script>';
        expect(HtmlHeuristics.hasUnsupportedElements(html), isTrue);
      });

      test('returns true for HLS streaming media (.m3u8)', () {
        const html =
            '<video src="https://cdn.example.com/stream.m3u8"></video>';
        expect(HtmlHeuristics.hasUnsupportedElements(html), isTrue);
      });

      test('returns true for RTSP streaming media', () {
        const html = '<video src="rtsp://camera.example.com/live"></video>';
        expect(HtmlHeuristics.hasUnsupportedElements(html), isTrue);
      });

      test('returns false for normal <video> with static src', () {
        const html = '<video src="movie.mp4" controls></video>';
        expect(HtmlHeuristics.hasUnsupportedElements(html), isFalse);
      });

      test('returns false for normal <img>', () {
        const html = '<img src="photo.jpg" alt="photo">';
        expect(HtmlHeuristics.hasUnsupportedElements(html), isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // isComplex (aggregate)
    // -----------------------------------------------------------------------
    group('isComplex', () {
      test('returns false for simple article HTML', () {
        const html = '''
<article>
  <h1>Title</h1>
  <p>First paragraph.</p>
  <ul><li>Item 1</li><li>Item 2</li></ul>
  <img src="photo.jpg" alt="photo">
</article>
''';
        expect(HtmlHeuristics.isComplex(html), isFalse);
      });

      test('returns true when table has large colspan', () {
        const html = '<table><tr><td colspan="4">A</td></tr></table>';
        expect(HtmlHeuristics.isComplex(html), isTrue);
      });

      test('returns true when CSS uses z-index', () {
        const html = '<div style="z-index: 10;">x</div>';
        expect(HtmlHeuristics.isComplex(html), isTrue);
      });

      test('returns true for <canvas>', () {
        const html = '<canvas></canvas>';
        expect(HtmlHeuristics.isComplex(html), isTrue);
      });

      test('returns true for a mix of complex indicators', () {
        const html = '''
<div style="position:fixed; z-index:999;">
  <form><input type="text"></form>
  <table><tr><td colspan="5">Header</td></tr></table>
</div>
''';
        expect(HtmlHeuristics.isComplex(html), isTrue);
      });

      test('returns false for empty string', () {
        expect(HtmlHeuristics.isComplex(''), isFalse);
      });
    });
  });
}
