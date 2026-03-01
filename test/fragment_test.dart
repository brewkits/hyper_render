import "package:hyper_render/hyper_render.dart";
import 'dart:ui' show Rect, Size, Offset;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fragment', () {
    group('Factory constructors', () {
      test('creates text fragment', () {
        final node = TextNode('Hello World');
        final fragment = Fragment.text(
          text: 'Hello World',
          sourceNode: node,
          style: ComputedStyle(),
        );

        expect(fragment.type, equals(FragmentType.text));
        expect(fragment.text, equals('Hello World'));
        expect(fragment.sourceNode, equals(node));
        expect(fragment.characterOffset, equals(0));
      });

      test('creates text fragment with character offset', () {
        final node = TextNode('Hello');
        final fragment = Fragment.text(
          text: 'Hello',
          sourceNode: node,
          style: ComputedStyle(),
          characterOffset: 100,
        );

        expect(fragment.characterOffset, equals(100));
      });

      test('creates atomic fragment with size', () {
        final node = AtomicNode(
          tagName: 'img',
          src: 'test.png',
          intrinsicWidth: 200,
          intrinsicHeight: 150,
        );
        final fragment = Fragment.atomic(
          sourceNode: node,
          style: ComputedStyle(),
          size: const Size(200, 150),
        );

        expect(fragment.type, equals(FragmentType.atomic));
        expect(fragment.measuredSize, equals(const Size(200, 150)));
        expect(fragment.width, equals(200));
        expect(fragment.height, equals(150));
      });

      test('creates line break fragment with zero size', () {
        final node = LineBreakNode();
        final fragment = Fragment.lineBreak(
          sourceNode: node,
          style: ComputedStyle(),
        );

        expect(fragment.type, equals(FragmentType.lineBreak));
        expect(fragment.measuredSize, equals(Size.zero));
        expect(fragment.width, equals(0));
        expect(fragment.height, equals(0));
      });

      test('creates ruby fragment', () {
        final node = RubyNode(baseText: '漢字', rubyText: 'かんじ');
        final fragment = Fragment.ruby(
          baseText: '漢字',
          rubyText: 'かんじ',
          sourceNode: node,
          style: ComputedStyle(),
        );

        expect(fragment.type, equals(FragmentType.ruby));
        expect(fragment.text, equals('漢字'));
        expect(fragment.rubyText, equals('かんじ'));
      });
    });

    group('Properties', () {
      test('width returns 0 when not measured', () {
        final fragment = Fragment.text(
          text: 'Test',
          sourceNode: TextNode('Test'),
          style: ComputedStyle(),
        );

        expect(fragment.width, equals(0));
      });

      test('height returns 0 when not measured', () {
        final fragment = Fragment.text(
          text: 'Test',
          sourceNode: TextNode('Test'),
          style: ComputedStyle(),
        );

        expect(fragment.height, equals(0));
      });

      test('rect returns null when offset or size is null', () {
        final fragment = Fragment.text(
          text: 'Test',
          sourceNode: TextNode('Test'),
          style: ComputedStyle(),
        );

        expect(fragment.rect, isNull);
      });

      test('rect returns correct value when offset and size are set', () {
        final fragment = Fragment.text(
          text: 'Test',
          sourceNode: TextNode('Test'),
          style: ComputedStyle(),
        );
        fragment.measuredSize = const Size(100, 20);
        fragment.offset = const Offset(10, 50);

        expect(fragment.rect, equals(const Rect.fromLTWH(10, 50, 100, 20)));
      });

      test('canBreak returns true for text with spaces', () {
        final fragment = Fragment.text(
          text: 'Hello World',
          sourceNode: TextNode('Hello World'),
          style: ComputedStyle(),
        );

        expect(fragment.canBreak, isTrue);
      });

      test('canBreak returns false for text without spaces', () {
        final fragment = Fragment.text(
          text: 'HelloWorld',
          sourceNode: TextNode('HelloWorld'),
          style: ComputedStyle(),
        );

        expect(fragment.canBreak, isFalse);
      });

      test('canBreak returns false for non-text fragments', () {
        final fragment = Fragment.atomic(
          sourceNode: AtomicNode(tagName: 'img', src: 'test.png'),
          style: ComputedStyle(),
          size: const Size(100, 100),
        );

        expect(fragment.canBreak, isFalse);
      });

      test('isWhitespace returns true for whitespace-only text', () {
        final fragment = Fragment.text(
          text: '   ',
          sourceNode: TextNode('   '),
          style: ComputedStyle(),
        );

        expect(fragment.isWhitespace, isTrue);
      });

      test('isWhitespace returns false for non-whitespace text', () {
        final fragment = Fragment.text(
          text: 'Hello',
          sourceNode: TextNode('Hello'),
          style: ComputedStyle(),
        );

        expect(fragment.isWhitespace, isFalse);
      });

      test('isWhitespace returns false for non-text fragments', () {
        final fragment = Fragment.atomic(
          sourceNode: AtomicNode(tagName: 'img', src: 'test.png'),
          style: ComputedStyle(),
          size: const Size(100, 100),
        );

        expect(fragment.isWhitespace, isFalse);
      });
    });

    group('toString', () {
      test('text fragment toString shows text', () {
        final fragment = Fragment.text(
          text: 'Hello',
          sourceNode: TextNode('Hello'),
          style: ComputedStyle(),
        );

        expect(fragment.toString(), contains('Fragment.text'));
        expect(fragment.toString(), contains('Hello'));
      });

      test('text fragment toString truncates long text', () {
        final longText = 'A' * 50;
        final fragment = Fragment.text(
          text: longText,
          sourceNode: TextNode(longText),
          style: ComputedStyle(),
        );

        expect(fragment.toString(), contains('...'));
      });

      test('atomic fragment toString shows tag name', () {
        final fragment = Fragment.atomic(
          sourceNode: AtomicNode(tagName: 'img', src: 'test.png'),
          style: ComputedStyle(),
          size: const Size(100, 100),
        );

        expect(fragment.toString(), contains('Fragment.atomic'));
        expect(fragment.toString(), contains('img'));
      });

      test('lineBreak fragment toString', () {
        final fragment = Fragment.lineBreak(
          sourceNode: LineBreakNode(),
          style: ComputedStyle(),
        );

        expect(fragment.toString(), equals('Fragment.lineBreak'));
      });

      test('ruby fragment toString shows text and ruby', () {
        final fragment = Fragment.ruby(
          baseText: '漢字',
          rubyText: 'かんじ',
          sourceNode: RubyNode(baseText: '漢字', rubyText: 'かんじ'),
          style: ComputedStyle(),
        );

        expect(fragment.toString(), contains('Fragment.ruby'));
        expect(fragment.toString(), contains('漢字'));
        expect(fragment.toString(), contains('かんじ'));
      });
    });
  });

  group('LineInfo', () {
    group('Constructor and defaults', () {
      test('creates with default values', () {
        final line = LineInfo();

        expect(line.fragments, isEmpty);
        expect(line.top, equals(0));
        expect(line.baseline, equals(0));
        expect(line.leftInset, equals(0));
        expect(line.rightInset, equals(0));
        expect(line.bounds, isNull);
      });

      test('creates with custom values', () {
        final line = LineInfo(
          top: 100,
          baseline: 15,
          leftInset: 20,
          rightInset: 30,
        );

        expect(line.top, equals(100));
        expect(line.baseline, equals(15));
        expect(line.leftInset, equals(20));
        expect(line.rightInset, equals(30));
      });
    });

    group('add and fragments', () {
      test('adds fragments to the list', () {
        final line = LineInfo();
        final fragment1 = Fragment.text(
          text: 'Hello',
          sourceNode: TextNode('Hello'),
          style: ComputedStyle(),
        );
        final fragment2 = Fragment.text(
          text: 'World',
          sourceNode: TextNode('World'),
          style: ComputedStyle(),
        );

        line.add(fragment1);
        line.add(fragment2);

        expect(line.fragments.length, equals(2));
        expect(line.fragments[0], equals(fragment1));
        expect(line.fragments[1], equals(fragment2));
      });
    });

    group('width calculation', () {
      test('returns 0 for empty line', () {
        final line = LineInfo();
        expect(line.width, equals(0));
      });

      test('calculates total width of fragments', () {
        final line = LineInfo();
        final fragment1 = Fragment.text(
          text: 'Hello',
          sourceNode: TextNode('Hello'),
          style: ComputedStyle(),
        )..measuredSize = const Size(50, 20);
        final fragment2 = Fragment.text(
          text: 'World',
          sourceNode: TextNode('World'),
          style: ComputedStyle(),
        )..measuredSize = const Size(60, 20);

        line.add(fragment1);
        line.add(fragment2);

        expect(line.width, equals(110));
      });
    });

    group('height calculation', () {
      test('returns 0 for empty line', () {
        final line = LineInfo();
        expect(line.height, equals(0));
      });

      test('returns maximum height of fragments', () {
        final line = LineInfo();
        final fragment1 = Fragment.text(
          text: 'Hello',
          sourceNode: TextNode('Hello'),
          style: ComputedStyle(),
        )..measuredSize = const Size(50, 20);
        final fragment2 = Fragment.text(
          text: 'World',
          sourceNode: TextNode('World'),
          style: ComputedStyle(),
        )..measuredSize = const Size(60, 30);

        line.add(fragment1);
        line.add(fragment2);

        expect(line.height, equals(30));
      });
    });

    group('characterCount', () {
      test('returns 0 for empty line', () {
        final line = LineInfo();
        expect(line.characterCount, equals(0));
      });

      test('counts characters in text fragments', () {
        final line = LineInfo();
        final fragment1 = Fragment.text(
          text: 'Hello',
          sourceNode: TextNode('Hello'),
          style: ComputedStyle(),
        );
        final fragment2 = Fragment.text(
          text: 'World',
          sourceNode: TextNode('World'),
          style: ComputedStyle(),
        );

        line.add(fragment1);
        line.add(fragment2);

        expect(line.characterCount, equals(10)); // "Hello" + "World"
      });

      test('counts line break as 1 character', () {
        final line = LineInfo();
        final textFragment = Fragment.text(
          text: 'Hello',
          sourceNode: TextNode('Hello'),
          style: ComputedStyle(),
        );
        final breakFragment = Fragment.lineBreak(
          sourceNode: LineBreakNode(),
          style: ComputedStyle(),
        );

        line.add(textFragment);
        line.add(breakFragment);

        expect(line.characterCount, equals(6)); // "Hello" + 1 for line break
      });

      test('does not count atomic fragments', () {
        final line = LineInfo();
        final textFragment = Fragment.text(
          text: 'Hello',
          sourceNode: TextNode('Hello'),
          style: ComputedStyle(),
        );
        final atomicFragment = Fragment.atomic(
          sourceNode: AtomicNode(tagName: 'img', src: 'test.png'),
          style: ComputedStyle(),
          size: const Size(100, 100),
        );

        line.add(textFragment);
        line.add(atomicFragment);

        expect(line.characterCount, equals(5)); // Only "Hello"
      });
    });

    group('isEmpty and isNotEmpty', () {
      test('isEmpty returns true for empty line', () {
        final line = LineInfo();
        expect(line.isEmpty, isTrue);
        expect(line.isNotEmpty, isFalse);
      });

      test('isEmpty returns false for non-empty line', () {
        final line = LineInfo();
        line.add(Fragment.text(
          text: 'Hello',
          sourceNode: TextNode('Hello'),
          style: ComputedStyle(),
        ));

        expect(line.isEmpty, isFalse);
        expect(line.isNotEmpty, isTrue);
      });
    });

    group('toString', () {
      test('toString shows fragment count and dimensions', () {
        final line = LineInfo();
        final fragment = Fragment.text(
          text: 'Hello',
          sourceNode: TextNode('Hello'),
          style: ComputedStyle(),
        )..measuredSize = const Size(50, 20);
        line.add(fragment);

        final str = line.toString();
        expect(str, contains('LineInfo'));
        expect(str, contains('fragments=1'));
        expect(str, contains('width=50'));
        expect(str, contains('height=20'));
      });
    });
  });

  group('FragmentType', () {
    test('has all expected values', () {
      expect(FragmentType.values.length, equals(4));
      expect(FragmentType.text, isNotNull);
      expect(FragmentType.atomic, isNotNull);
      expect(FragmentType.lineBreak, isNotNull);
      expect(FragmentType.ruby, isNotNull);
    });
  });
}
