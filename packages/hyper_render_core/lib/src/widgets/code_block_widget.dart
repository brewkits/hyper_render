import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../interfaces/code_highlighter.dart';

/// Available syntax highlighting themes.
///
/// Passed as a hint to the [CodeHighlighter] plugin.  When no plugin is
/// configured, the renderer falls back to plain monospace text and uses the
/// theme only to pick a background colour.
enum CodeTheme {
  vs2015,
  atomOneDark,
  atomOneLight,
  github,
  monokaiSublime,
  dracula,
}

/// A widget that displays code with optional syntax highlighting.
///
/// Syntax highlighting requires a [CodeHighlighter] plugin (e.g. the
/// `HyperHighlighter` from `hyper_render_highlight`).  Without a plugin the
/// code is rendered as plain monospace text, which keeps the core package
/// free of heavy highlight.js dependencies.
class CodeBlockWidget extends StatelessWidget {
  /// The source code to display.
  final String code;

  /// Programming language hint (e.g. 'dart', 'javascript').
  final String? language;

  /// Visual theme — used to pick background colour and passed to [highlighter].
  final CodeTheme theme;

  /// Padding inside the code block.
  final EdgeInsets padding;

  /// Border radius of the code block container.
  final BorderRadius borderRadius;

  /// Whether to show line numbers in the gutter.
  final bool showLineNumbers;

  /// Whether to show a copy-to-clipboard button.
  final bool showCopyButton;

  /// Text style override applied to the code text.
  final TextStyle? textStyle;

  /// Syntax-highlighting plugin.
  ///
  /// When `null` the code is rendered as plain text.  Inject a plugin via
  /// [HyperRenderConfig.codeHighlighter].
  final CodeHighlighter? highlighter;

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
    this.highlighter,
  });

  /// Background colour for each theme variant.
  Color get _backgroundColor {
    switch (theme) {
      case CodeTheme.atomOneLight:
      case CodeTheme.github:
        return const Color(0xFFFAFAFA);
      case CodeTheme.vs2015:
      case CodeTheme.atomOneDark:
      case CodeTheme.monokaiSublime:
      case CodeTheme.dracula:
        return const Color(0xFF1E1E1E);
    }
  }

  /// Default text colour when no plugin is present.
  Color get _defaultTextColor {
    switch (theme) {
      case CodeTheme.atomOneLight:
      case CodeTheme.github:
        return const Color(0xFF383A42);
      case CodeTheme.vs2015:
      case CodeTheme.atomOneDark:
      case CodeTheme.monokaiSublime:
      case CodeTheme.dracula:
        return const Color(0xFFABB2BF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _backgroundColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: borderRadius,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: padding,
                child: _buildContent(),
              ),
            ),
          ),
          if (showCopyButton)
            Positioned(
              top: 8,
              right: 8,
              child: _CopyButton(code: code),
            ),
          if (language != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildContent() {
    final codeStyle = textStyle ??
        TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
          color: _defaultTextColor,
        );

    final cleanCode = code.trimRight();

    // Highlighted spans from plugin, or plain text fallback.
    final List<TextSpan> spans;
    if (highlighter != null &&
        (language == null ||
            language!.isEmpty ||
            highlighter!.isLanguageSupported(language!))) {
      spans = highlighter!.highlight(cleanCode, language);
    } else {
      spans = [TextSpan(text: cleanCode, style: codeStyle)];
    }

    final richText = Text.rich(
      TextSpan(children: spans, style: codeStyle),
      softWrap: false,
    );

    if (!showLineNumbers) return richText;

    final lines = cleanCode.split('\n');
    final lineCount = lines.length;
    final gutterWidth = lineCount.toString().length * 10.0 + 24;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: gutterWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(lineCount, (i) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
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
        Container(
          width: 1,
          height: lineCount * 19.5,
          color: Colors.white12,
        ),
        const SizedBox(width: 16),
        richText,
      ],
    );
  }
}

/// Copy-to-clipboard button with confirmation feedback.
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
    if (mounted) setState(() => _copied = false);
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

/// Detect programming language from a CSS class attribute value.
///
/// Recognises common patterns: `language-dart`, `lang-python`, `hljs-js`.
String? detectLanguageFromClass(String? classAttr) {
  if (classAttr == null || classAttr.isEmpty) return null;

  for (final cls in classAttr.split(' ')) {
    if (cls.startsWith('language-')) return cls.substring(9);
    if (cls.startsWith('lang-')) return cls.substring(5);
    if (cls.startsWith('hljs-')) return cls.substring(5);

    const knownLanguages = {
      'dart', 'javascript', 'typescript', 'python', 'java', 'kotlin',
      'swift', 'go', 'rust', 'c', 'cpp', 'csharp', 'php', 'ruby',
      'html', 'css', 'xml', 'json', 'yaml', 'sql', 'bash', 'shell',
      'markdown',
    };
    if (knownLanguages.contains(cls.toLowerCase())) return cls.toLowerCase();
  }

  return null;
}
