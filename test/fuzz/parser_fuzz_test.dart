// Fuzz-style robustness tests for the HTML adapter, Markdown adapter, and
// HtmlSanitizer: feed structurally-mutated, malformed input and assert none
// of them throws an uncaught exception. A fixed seed keeps failures
// reproducible — if a mutant breaks a parser, print it and pin it as its own
// regression test rather than relying on the fuzzer to find it again.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

const _seedHtmlDocuments = [
  '<h1>Title</h1><p>Hello <b>world</b>, <a href="https://example.com">link</a>.</p>',
  '<table><tr><td colspan="2">A</td></tr><tr><td>B</td><td>C</td></tr></table>',
  '<ul><li>One</li><li>Two <span style="color:red">red</span></li></ul>',
  '<div class="card" style="padding:8px;border:1px solid #ccc"><img src="a.png" alt="x"></div>',
  '<pre><code class="language-dart">void main() { print(1); }</code></pre>',
  '<blockquote>Quoted &amp; escaped &lt;text&gt;</blockquote>',
  '<p>Mixed <em>emphasis <strong>and bold</strong></em> text with &nbsp; entity.</p>',
  '<svg><circle cx="5" cy="5" r="4"/></svg><video src="a.mp4" poster="p.jpg"></video>',
];

const _seedMarkdownDocuments = [
  '# Title\n\nHello **world**, [link](https://example.com).\n',
  '| A | B |\n|---|---|\n| 1 | 2 |\n',
  '- One\n- Two *italic*\n',
  '```dart\nvoid main() {}\n```\n',
  '> Quoted text with `inline code`.\n',
  r'Formula: $x^2 + y^2$ and $$\frac{a}{b}$$' '\n',
];

/// Structural mutation operators. Each returns a new string; none assume the
/// input is well-formed, since that's the whole point.
typedef _Mutator = String Function(String input, Random rng);

String _deleteRandomChar(String s, Random rng) {
  if (s.isEmpty) return s;
  final i = rng.nextInt(s.length);
  return s.replaceRange(i, i + 1, '');
}

String _insertRandomChar(String s, Random rng) {
  const chars = '<>"\'&/\\{}\$`*_|~';
  final i = rng.nextInt(s.length + 1);
  final c = chars[rng.nextInt(chars.length)];
  return s.replaceRange(i, i, c);
}

String _truncateRandomly(String s, Random rng) {
  if (s.isEmpty) return s;
  final cut = rng.nextInt(s.length);
  return s.substring(0, cut);
}

String _duplicateRandomSlice(String s, Random rng) {
  if (s.length < 2) return s;
  final start = rng.nextInt(s.length - 1);
  final end = start + 1 + rng.nextInt(s.length - start - 1).clamp(0, s.length);
  final slice = s.substring(start, end.clamp(start, s.length));
  return s.replaceRange(start, start, slice);
}

String _stripRandomQuote(String s, Random rng) {
  final quoteIndices = <int>[
    for (var i = 0; i < s.length; i++)
      if (s[i] == '"' || s[i] == "'") i,
  ];
  if (quoteIndices.isEmpty) return s;
  final i = quoteIndices[rng.nextInt(quoteIndices.length)];
  return s.replaceRange(i, i + 1, '');
}

const _mutators = <_Mutator>[
  _deleteRandomChar,
  _insertRandomChar,
  _truncateRandomly,
  _duplicateRandomSlice,
  _stripRandomQuote,
];

String _mutate(String seed, Random rng, {int passes = 3}) {
  var result = seed;
  for (var i = 0; i < passes; i++) {
    if (result.isEmpty) break;
    result = _mutators[rng.nextInt(_mutators.length)](result, rng);
  }
  return result;
}

void main() {
  // Fixed seed: any failure is reproducible by re-running with the same seed.
  final rng = Random(20260906);

  const iterationsPerSeed = 15;

  group('Parser fuzz — HTML adapter never throws on mutated input', () {
    for (var s = 0; s < _seedHtmlDocuments.length; s++) {
      for (var i = 0; i < iterationsPerSeed; i++) {
        final mutant = _mutate(_seedHtmlDocuments[s], rng);
        test('html seed $s, mutant $i', () {
          try {
            DefaultHtmlParser().parse(mutant);
          } catch (e, st) {
            fail('HTML adapter threw on mutated input:\n'
                '  input: ${mutant.runtimeType} ${mutant.length} chars: '
                '${mutant.replaceAll('\n', '\\n')}\n'
                '  error: $e\n$st');
          }
        });
      }
    }
  });

  group('Parser fuzz — Markdown adapter never throws on mutated input', () {
    for (var s = 0; s < _seedMarkdownDocuments.length; s++) {
      for (var i = 0; i < iterationsPerSeed; i++) {
        final mutant = _mutate(_seedMarkdownDocuments[s], rng);
        test('markdown seed $s, mutant $i', () {
          try {
            DefaultMarkdownParser().parse(mutant);
          } catch (e, st) {
            fail('Markdown adapter threw on mutated input:\n'
                '  input: ${mutant.length} chars: '
                '${mutant.replaceAll('\n', '\\n')}\n'
                '  error: $e\n$st');
          }
        });
      }
    }
  });

  group('Parser fuzz — HtmlSanitizer never throws on mutated input', () {
    for (var s = 0; s < _seedHtmlDocuments.length; s++) {
      for (var i = 0; i < iterationsPerSeed; i++) {
        final mutant = _mutate(_seedHtmlDocuments[s], rng);
        test('sanitizer seed $s, mutant $i', () {
          try {
            HtmlSanitizer.sanitize(mutant);
          } catch (e, st) {
            fail('HtmlSanitizer threw on mutated input:\n'
                '  input: ${mutant.length} chars: '
                '${mutant.replaceAll('\n', '\\n')}\n'
                '  error: $e\n$st');
          }
        });
      }
    }
  });

  // A handful of hand-picked adversarial shapes on top of the random mutants
  // above — these are patterns that have historically caused real parser
  // crashes across this class of library (dangling attribute quotes, deeply
  // unbalanced tags, null-byte tag-name smuggling, mismatched entity refs).
  group('Parser fuzz — known adversarial shapes', () {
    final adversarial = [
      '<div class="a<b>c">text</div>',
      '<<<<<p>>>>>text</p>',
      '<a href=>no quotes at all</a>',
      '<img src="a.png"alt="b">',
      '<p>&amp;&amp;&amp;&notarealentity;</p>',
      '<div>' * 30 + 'unclosed',
      '```\n```\n```\n',
      '[[[[[[[[[[text]]]]]]]]]]',
      '***___***text***___***',
    ];

    for (var i = 0; i < adversarial.length; i++) {
      test('adversarial shape $i — html+sanitizer+markdown all survive', () {
        final input = adversarial[i];
        expect(() => DefaultHtmlParser().parse(input), returnsNormally);
        expect(() => HtmlSanitizer.sanitize(input), returnsNormally);
        expect(() => DefaultMarkdownParser().parse(input), returnsNormally);
      });
    }
  });
}
