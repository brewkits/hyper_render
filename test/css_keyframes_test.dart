import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/src/plugins/default_css_parser.dart';

void main() {
  const parser = DefaultCssParser();

  group('DefaultCssParser.parseKeyframes', () {
    test('returns empty map for empty CSS', () {
      expect(parser.parseKeyframes(''), isEmpty);
    });

    test('returns empty map when no @keyframes present', () {
      expect(parser.parseKeyframes('body { color: red; }'), isEmpty);
    });

    test('parses basic fadeIn with from/to selectors', () {
      const css = '''
@keyframes fadeIn {
  from { opacity: 0; }
  to   { opacity: 1; }
}
''';
      final result = parser.parseKeyframes(css);
      expect(result, hasLength(1));
      expect(result, contains('fadeIn'));

      final kf = result['fadeIn']!;
      expect(kf.name, 'fadeIn');
      expect(kf.keyframes, hasLength(2));
      expect(kf.keyframes[0].offset, 0.0);
      expect(kf.keyframes[0].opacity, 0.0);
      expect(kf.keyframes[1].offset, 1.0);
      expect(kf.keyframes[1].opacity, 1.0);
    });

    test('parses percentage selectors', () {
      const css = '''
@keyframes bounce {
  0%   { transform: translateY(0px); }
  50%  { transform: translateY(-30px); }
  100% { transform: translateY(0px); }
}
''';
      final result = parser.parseKeyframes(css);
      final kf = result['bounce']!;
      expect(kf.keyframes, hasLength(3));
      expect(kf.keyframes[0].offset, 0.0);
      expect(kf.keyframes[1].offset, 0.5);
      expect(kf.keyframes[1].translateY, -30.0);
      expect(kf.keyframes[2].offset, 1.0);
    });

    test('parses comma-separated selectors', () {
      const css = '''
@keyframes ping {
  75%, 100% { transform: scale(2); opacity: 0; }
}
''';
      final result = parser.parseKeyframes(css);
      final kf = result['ping']!;
      expect(kf.keyframes, hasLength(2));
      expect(kf.keyframes[0].offset, closeTo(0.75, 0.001));
      expect(kf.keyframes[1].offset, 1.0);
      expect(kf.keyframes[0].scale, 2.0);
      expect(kf.keyframes[0].opacity, 0.0);
    });

    test('parses translateX/Y transforms', () {
      const css = '''
@keyframes slideInLeft {
  from { transform: translateX(-100px); opacity: 0; }
  to   { transform: translateX(0px); opacity: 1; }
}
''';
      final result = parser.parseKeyframes(css);
      final kf = result['slideInLeft']!;
      expect(kf.keyframes[0].translateX, -100.0);
      expect(kf.keyframes[0].opacity, 0.0);
      expect(kf.keyframes[1].translateX, 0.0);
    });

    test('parses rotate transform', () {
      const css = '''
@keyframes spin {
  from { transform: rotate(0deg); }
  to   { transform: rotate(360deg); }
}
''';
      final result = parser.parseKeyframes(css);
      final kf = result['spin']!;
      expect(kf.keyframes[0].rotation, 0.0);
      expect(kf.keyframes[1].rotation, 360.0);
    });

    test('parses scale transform', () {
      const css = '''
@keyframes zoomIn {
  from { transform: scale(0); opacity: 0; }
  to   { transform: scale(1); opacity: 1; }
}
''';
      final result = parser.parseKeyframes(css);
      final kf = result['zoomIn']!;
      expect(kf.keyframes[0].scale, 0.0);
      expect(kf.keyframes[1].scale, 1.0);
    });

    test('parses vendor-prefixed @-webkit-keyframes', () {
      const css = '''
@-webkit-keyframes fadeOut {
  from { opacity: 1; }
  to   { opacity: 0; }
}
''';
      final result = parser.parseKeyframes(css);
      expect(result, contains('fadeOut'));
    });

    test('parses multiple @keyframes blocks', () {
      const css = '''
@keyframes fadeIn  { from { opacity: 0; } to { opacity: 1; } }
@keyframes fadeOut { from { opacity: 1; } to { opacity: 0; } }
''';
      final result = parser.parseKeyframes(css);
      expect(result, hasLength(2));
      expect(result, contains('fadeIn'));
      expect(result, contains('fadeOut'));
    });

    test('keyframes are sorted by offset', () {
      const css = '''
@keyframes test {
  100% { opacity: 1; }
  0%   { opacity: 0; }
  50%  { opacity: 0.5; }
}
''';
      final result = parser.parseKeyframes(css);
      final offsets = result['test']!.keyframes.map((k) => k.offset).toList();
      expect(offsets, [0.0, 0.5, 1.0]);
    });

    test('interpolate works between keyframes', () {
      const css = '''
@keyframes fade {
  from { opacity: 0; }
  to   { opacity: 1; }
}
''';
      final result = parser.parseKeyframes(css);
      final kf = result['fade']!;
      final mid = kf.interpolate(0.5);
      expect(mid.opacity, closeTo(0.5, 0.01));
    });

    test('ignores CSS without @keyframes gracefully', () {
      const css = '''
.box { animation-name: fadeIn; animation-duration: 0.3s; }
''';
      expect(parser.parseKeyframes(css), isEmpty);
    });
  });
}
