/// HyperRender Highlight - Syntax Highlighting Plugin
///
/// This package provides syntax highlighting for HyperRender using
/// the flutter_highlight package. It supports 180+ programming languages
/// with multiple color themes.
///
/// ## Features
/// - 180+ programming language support via highlight.js
/// - Multiple built-in themes (VS2015, Atom One Dark, GitHub, Dracula, etc.)
/// - Auto-detection of language when not specified
/// - Seamless integration with HyperRender
///
/// ## Usage
/// ```dart
/// import 'package:hyper_render_highlight/hyper_render_highlight.dart';
///
/// // Create a highlighter with your preferred theme
/// final highlighter = FlutterHighlightCodeHighlighter(
///   theme: HighlightTheme.dracula,
/// );
///
/// // Use with HyperRenderWidget
/// HyperRenderWidget(
///   document: document,
///   codeHighlighter: highlighter,
/// )
/// ```
///
/// ## Available Themes
/// - [HighlightTheme.vs2015] - Visual Studio 2015 dark theme (default)
/// - [HighlightTheme.atomOneDark] - Atom One Dark theme
/// - [HighlightTheme.atomOneLight] - Atom One Light theme
/// - [HighlightTheme.github] - GitHub light theme
/// - [HighlightTheme.monokaiSublime] - Monokai Sublime theme
/// - [HighlightTheme.dracula] - Dracula dark theme
library;

// Export the highlighter implementation
export 'src/code_highlighter.dart'
    show FlutterHighlightCodeHighlighter, HighlightTheme;

// Re-export CodeHighlighter interface from core for convenience
export 'package:hyper_render_core/hyper_render_core.dart'
    show CodeHighlighter, PlainTextHighlighter;
