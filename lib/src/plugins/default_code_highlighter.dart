import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:highlight/highlight.dart' show Highlight;

/// Global highlight instance
final _highlight = Highlight();

/// Available syntax highlighting themes for DefaultCodeHighlighter
enum HighlightTheme {
  vs2015,
  atomOneDark,
  atomOneLight,
  github,
  monokaiSublime,
  dracula,
}

/// Default code highlighter using flutter_highlight package
///
/// Supports 180+ programming languages via highlight.js
/// This is the default implementation provided by HyperRender.
class DefaultCodeHighlighter implements CodeHighlighter {
  /// The theme to use for highlighting
  final HighlightTheme theme;

  /// Base text style to apply
  final TextStyle? baseStyle;

  const DefaultCodeHighlighter({
    this.theme = HighlightTheme.vs2015,
    this.baseStyle,
  });

  Map<String, TextStyle> _getThemeMap() {
    switch (theme) {
      case HighlightTheme.vs2015:
        return vs2015Theme;
      case HighlightTheme.atomOneDark:
        return atomOneDarkTheme;
      case HighlightTheme.atomOneLight:
        return atomOneLightTheme;
      case HighlightTheme.github:
        return githubTheme;
      case HighlightTheme.monokaiSublime:
        return monokaiSublimeTheme;
      case HighlightTheme.dracula:
        return draculaTheme;
    }
  }

  @override
  List<TextSpan> highlight(String code, String? language) {
    final themeMap = _getThemeMap();

    // Parse and highlight the code
    final result = language != null
        ? _highlight.parse(code, language: language)
        : _highlight.parse(code, autoDetection: true);

    // Convert highlight result to TextSpans
    return _buildSpans(result.nodes ?? [], themeMap);
  }

  @override
  bool isLanguageSupported(String language) =>
      supportedLanguages.contains(language.toLowerCase());

  List<TextSpan> _buildSpans(
    List<dynamic> nodes,
    Map<String, TextStyle> themeMap,
  ) {
    final spans = <TextSpan>[];
    final rootStyle = themeMap['root'] ?? const TextStyle();
    final mergedBaseStyle = baseStyle?.merge(rootStyle) ?? rootStyle;

    for (final node in nodes) {
      if (node is String) {
        spans.add(TextSpan(text: node, style: mergedBaseStyle));
      } else if (node.className != null) {
        final className = node.className as String;
        final classStyle = themeMap[className];
        final style = classStyle != null
            ? mergedBaseStyle.merge(classStyle)
            : mergedBaseStyle;

        if (node.children != null && (node.children as List).isNotEmpty) {
          spans.addAll(_buildSpans(node.children as List, themeMap));
        } else if (node.value != null) {
          spans.add(TextSpan(text: node.value as String, style: style));
        }
      } else if (node.value != null) {
        spans.add(TextSpan(text: node.value as String, style: mergedBaseStyle));
      } else if (node.children != null) {
        spans.addAll(_buildSpans(node.children as List, themeMap));
      }
    }

    return spans;
  }

  @override
  Set<String> get supportedLanguages => _supportedLanguages;

  @override
  String get themeName => theme.name;

  /// All languages supported by highlight.js
  static const Set<String> _supportedLanguages = {
    'dart',
    'javascript',
    'typescript',
    'python',
    'java',
    'kotlin',
    'swift',
    'objectivec',
    'c',
    'cpp',
    'csharp',
    'go',
    'rust',
    'ruby',
    'php',
    'html',
    'css',
    'scss',
    'less',
    'xml',
    'json',
    'yaml',
    'markdown',
    'sql',
    'bash',
    'shell',
    'powershell',
    'dockerfile',
    'makefile',
    'cmake',
    'gradle',
    'groovy',
    'scala',
    'r',
    'matlab',
    'julia',
    'lua',
    'perl',
    'haskell',
    'clojure',
    'erlang',
    'elixir',
    'fsharp',
    'ocaml',
    'lisp',
    'scheme',
    'assembly',
    'x86asm',
    'arm',
    'wasm',
    'glsl',
    'hlsl',
    'latex',
    'ini',
    'toml',
    'properties',
    'nginx',
    'apache',
    'vim',
    'diff',
    'plaintext',
  };
}
