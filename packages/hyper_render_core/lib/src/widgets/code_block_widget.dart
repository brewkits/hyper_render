import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../interfaces/code_highlighter.dart';

/// A widget that displays code with syntax highlighting
///
/// Supports syntax highlighting via the [CodeHighlighter] interface.
/// Use [language] to specify the language (e.g., 'dart', 'javascript', 'html')
/// If no [codeHighlighter] is provided, [PlainTextHighlighter] is used (no highlighting).
///
/// To enable syntax highlighting, provide a [CodeHighlighter] implementation:
/// - Use `FlutterHighlightHighlighter` from `hyper_render_highlight` package
/// - Or implement your own highlighter
class CodeBlockWidget extends StatelessWidget {
  /// The source code to display
  final String code;

  /// Programming language for syntax highlighting
  /// Common values: 'dart', 'javascript', 'python', 'java', 'html', 'css', 'xml', 'json'
  /// If null, the highlighter may attempt auto-detection or return plain text
  final String? language;

  /// Code highlighter implementation
  /// If null, uses [PlainTextHighlighter] (no syntax highlighting)
  final CodeHighlighter? codeHighlighter;

  /// Background color for the code block
  /// If null, uses a default dark background (#1E1E1E)
  final Color? backgroundColor;

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
    this.codeHighlighter,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.showLineNumbers = false,
    this.showCopyButton = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? const Color(0xFF1E1E1E);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
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
                child: _buildCodeView(),
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

  Widget _buildCodeView() {
    // Prepare code - ensure no trailing whitespace issues
    final cleanCode = code.trimRight();

    if (showLineNumbers) {
      return _buildWithLineNumbers(cleanCode);
    }

    return _buildHighlightedCode(cleanCode);
  }

  Widget _buildHighlightedCode(String cleanCode) {
    final codeStyle = textStyle ??
        const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
        );

    // Use provided highlighter or fall back to plain text
    final highlighter = codeHighlighter ?? const PlainTextHighlighter(
      baseStyle: TextStyle(color: Colors.white),
    );

    final spans = highlighter.highlight(cleanCode, language);

    return RichText(
      text: TextSpan(
        style: codeStyle,
        children: spans,
      ),
    );
  }

  Widget _buildWithLineNumbers(String cleanCode) {
    final lines = cleanCode.split('\n');
    final lineCount = lines.length;
    final lineNumberWidth = lineCount.toString().length * 10.0 + 24;

    final codeStyle = textStyle ??
        const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
        );

    // Use provided highlighter or fall back to plain text
    final highlighter = codeHighlighter ?? const PlainTextHighlighter(
      baseStyle: TextStyle(color: Colors.white),
    );

    final spans = highlighter.highlight(cleanCode, language);

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

        // Divider
        Container(
          width: 1,
          height: lineCount * 19.5, // approximate line height
          color: Colors.white12,
        ),

        const SizedBox(width: 16),

        // Code
        RichText(
          text: TextSpan(
            style: codeStyle,
            children: spans,
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
