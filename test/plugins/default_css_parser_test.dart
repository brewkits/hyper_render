import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/src/plugins/default_css_parser.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

void main() {
  group('DefaultCssParser', () {
    const parser = DefaultCssParser();

    test('parseStylesheet returns list of rules', () {
      const css = 'div { color: red; } .btn { font-size: 16px; } #main { padding: 10px; }';
      final rules = parser.parseStylesheet(css);
      
      expect(rules, hasLength(3));
      // Sorted by specificity
      expect(rules[0].selector, contains('div')); // Lowest specificity
      expect(rules[2].selector, contains('#main')); // Highest specificity
    });

    test('parseStylesheet handles empty CSS', () {
      expect(parser.parseStylesheet(''), isEmpty);
    });

    test('parseStylesheet handles invalid CSS gracefully', () {
      expect(parser.parseStylesheet('invalid-css'), isEmpty);
    });

    test('specificity calculation', () {
      final stylesheet = parser.parseStylesheet('div { color: red; } .class { color: blue; } #id { color: green; }');
      
      // We know #id has highest specificity
      final idRule = stylesheet.firstWhere((r) => r.selector == '#id');
      final classRule = stylesheet.firstWhere((r) => r.selector == '.class');
      final elementRule = stylesheet.firstWhere((r) => r.selector == 'div');
      
      expect(idRule.specificity, greaterThan(classRule.specificity));
      expect(classRule.specificity, greaterThan(elementRule.specificity));
    });

    test('parseInlineStyle parses multiple declarations', () {
      const style = 'color: red; font-size: 16px; margin: 10px 5px;';
      final result = parser.parseInlineStyle(style);
      
      expect(result['color'], 'red');
      expect(result['font-size'], '16px');
      expect(result['margin'], '10px 5px');
    });

    test('parseKeyframes parses basic keyframes', () {
      const css = '''
        @keyframes slideIn {
          from { opacity: 0; transform: translateX(-100px); }
          to { opacity: 1; transform: translateX(0); }
        }
      ''';
      final keyframes = parser.parseKeyframes(css);
      
      expect(keyframes, contains('slideIn'));
      final anim = keyframes['slideIn']!;
      expect(anim.keyframes, hasLength(2));
      expect(anim.keyframes[0].offset, 0.0);
      expect(anim.keyframes[1].offset, 1.0);
    });

    test('parseKeyframes parses percentage keyframes', () {
      const css = '''
        @keyframes fadeInOut {
          0% { opacity: 0; }
          50% { opacity: 1; scale(1.2); }
          100% { opacity: 0; }
        }
      ''';
      final keyframes = parser.parseKeyframes(css);
      
      expect(keyframes, contains('fadeInOut'));
      final anim = keyframes['fadeInOut']!;
      expect(anim.keyframes, hasLength(3));
      expect(anim.keyframes[0].offset, 0.0);
      expect(anim.keyframes[1].offset, 0.5);
      expect(anim.keyframes[2].offset, 1.0);
    });

    test('parseKeyframes handles various transform functions', () {
      const css = '''
        @keyframes complex {
          from { transform: translate(10px, 20px) scale(1.5) rotate(45deg); }
          to { transform: translateX(50%) translateY(100px); }
        }
      ''';
      final keyframes = parser.parseKeyframes(css);
      final anim = keyframes['complex']!;
      
      final kf1 = anim.keyframes[0];
      expect(kf1.translateX, 10.0);
      expect(kf1.translateY, 20.0);
      expect(kf1.scale, 1.5);
      expect(kf1.rotation, 45.0);
      
      final kf2 = anim.keyframes[1];
      expect(kf2.translateX, 50.0);
      expect(kf2.translateY, 100.0);
    });
  });
}
