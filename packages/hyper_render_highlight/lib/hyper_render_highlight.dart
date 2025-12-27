/// HyperRender Highlight Plugin (PAID)
///
/// Provides syntax highlighting for code blocks with support for 180+ languages.
///
/// This is a PAID plugin. Contact sales@hyperrender.dev for licensing.
///
/// ## Installation
///
/// ```yaml
/// dependencies:
///   hyper_render_core: ^2.0.0
///   hyper_render_html: ^2.0.0
///   hyper_render_highlight: ^2.0.0  # Requires license
/// ```
///
/// ## Usage
///
/// ```dart
/// import 'package:hyper_render_core/hyper_render_core.dart';
/// import 'package:hyper_render_html/hyper_render_html.dart';
/// import 'package:hyper_render_highlight/hyper_render_highlight.dart';
///
/// HyperViewer(
///   html: '<pre><code class="language-dart">void main() {}</code></pre>',
///   contentParser: HtmlContentParser(),
///   codeHighlighter: FlutterCodeHighlighter(
///     theme: HighlightTheme.vs2015,
///   ),
/// )
/// ```
///
/// ## Features
///
/// - 180+ programming languages supported
/// - 6 color themes (VS2015, Atom One Dark, GitHub, Monokai, etc.)
/// - Automatic language detection
/// - Line numbers and copy button
library;

// NOTE: This is a STUB package showing the intended structure.
// In a full implementation:

// export 'src/flutter_code_highlighter.dart';
// export 'src/highlight_theme.dart';
