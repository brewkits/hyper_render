import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/dracula.dart';

/// Available syntax highlighting themes
enum CodeTheme {
  vs2015,
  atomOneDark,
  atomOneLight,
  github,
  monokaiSublime,
  dracula,
}

/// A widget that displays code with syntax highlighting
///
/// Supports 180+ programming languages via highlight.js
/// Use [language] to specify the language (e.g., 'dart', 'javascript', 'html')
/// If language is not specified, auto-detection will be attempted
class CodeBlockWidget extends StatelessWidget {
  /// The source code to display
  final String code;

  /// Programming language for syntax highlighting
  /// Common values: 'dart', 'javascript', 'python', 'java', 'html', 'css', 'xml', 'json'
  /// If null, highlight.js will attempt auto-detection
  final String? language;

  /// Theme for syntax highlighting
  final CodeTheme theme;

  /// Padding inside the code block
  final EdgeInsets padding;

  /// Border radius of the code block
  final BorderRadius borderRadius;

  /// Whether to show line numbers
  final bool showLineNumbers;

  /// Whether to show copy button
  final bool showCopyButton;

  /// Text style override (fontSize, fontFamily will be applied)
  final TextStyle? textStyle;

  const CodeBlockWidget({
    super.key,
    required this.code,
    this.language,
    this.theme = CodeTheme.vs2015,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.showLineNumbers = false,
    this.showCopyButton = true,
    this.textStyle,
  });

  Map<String, TextStyle> _getThemeMap() {
    switch (theme) {
      case CodeTheme.vs2015:
        return vs2015Theme;
      case CodeTheme.atomOneDark:
        return atomOneDarkTheme;
      case CodeTheme.atomOneLight:
        return atomOneLightTheme;
      case CodeTheme.github:
        return githubTheme;
      case CodeTheme.monokaiSublime:
        return monokaiSublimeTheme;
      case CodeTheme.dracula:
        return draculaTheme;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMap = _getThemeMap();
    final backgroundColor =
        themeMap['root']?.backgroundColor ?? const Color(0xFF1E1E1E);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: Stack(
        children: [
          // Code content
          ClipRRect(
            borderRadius: borderRadius,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: padding,
                child: _buildHighlightView(themeMap),
              ),
            ),
          ),

          // Copy button
          if (showCopyButton)
            Positioned(
              top: 8,
              right: 8,
              child: _CopyButton(code: code),
            ),

          // Language badge
          if (language != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  language!.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHighlightView(Map<String, TextStyle> themeMap) {
    // Prepare code - ensure no trailing whitespace issues
    final cleanCode = code.trimRight();

    if (showLineNumbers) {
      return _buildWithLineNumbers(cleanCode, themeMap);
    }

    return HighlightView(
      cleanCode,
      language: language,
      theme: themeMap,
      textStyle: textStyle ??
          const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.5,
          ),
    );
  }

  Widget _buildWithLineNumbers(
      String cleanCode, Map<String, TextStyle> themeMap) {
    final lines = cleanCode.split('\n');
    final lineCount = lines.length;
    final lineNumberWidth = lineCount.toString().length * 10.0 + 24;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line numbers
        SizedBox(
          width: lineNumberWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(lineCount, (i) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.white38,
                  ),
                ),
              );
            }),
          ),
        ),

        // Divider
        Container(
          width: 1,
          height: lineCount * 19.5, // approximate line height
          color: Colors.white12,
        ),

        const SizedBox(width: 16),

        // Code
        HighlightView(
          cleanCode,
          language: language,
          theme: themeMap,
          textStyle: textStyle ??
              const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
        ),
      ],
    );
  }
}

/// Copy button with feedback
class _CopyButton extends StatefulWidget {
  final String code;

  const _CopyButton({required this.code});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _copyToClipboard,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            _copied ? Icons.check : Icons.copy,
            size: 16,
            color: _copied ? Colors.greenAccent : Colors.white60,
          ),
        ),
      ),
    );
  }
}

/// Helper to detect language from class attribute
/// e.g., "language-dart", "lang-javascript", "hljs-python"
String? detectLanguageFromClass(String? classAttr) {
  if (classAttr == null || classAttr.isEmpty) return null;

  final classes = classAttr.split(' ');
  for (final cls in classes) {
    // Common patterns: language-xxx, lang-xxx, hljs-xxx
    if (cls.startsWith('language-')) {
      return cls.substring(9);
    }
    if (cls.startsWith('lang-')) {
      return cls.substring(5);
    }
    if (cls.startsWith('hljs-')) {
      return cls.substring(5);
    }

    // Direct language names
    final knownLanguages = [
      'dart',
      'javascript',
      'typescript',
      'python',
      'java',
      'kotlin',
      'swift',
      'go',
      'rust',
      'c',
      'cpp',
      'csharp',
      'php',
      'ruby',
      'html',
      'css',
      'xml',
      'json',
      'yaml',
      'sql',
      'bash',
      'shell',
      'markdown',
    ];
    if (knownLanguages.contains(cls.toLowerCase())) {
      return cls.toLowerCase();
    }
  }

  return null;
}
