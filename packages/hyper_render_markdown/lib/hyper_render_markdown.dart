/// HyperRender Markdown Plugin
///
/// Provides Markdown parsing support for HyperRender.
/// Converts Markdown content into the Unified Document Tree (UDT).
///
/// ## Features
/// - GitHub Flavored Markdown (GFM) support
/// - Tables, strikethrough, task lists
/// - Code blocks with language hints
/// - Images and links
/// - Blockquotes and lists
///
/// ## Usage
///
/// ```dart
/// import 'package:hyper_render_core/hyper_render_core.dart';
/// import 'package:hyper_render_markdown/hyper_render_markdown.dart';
///
/// // Parse Markdown to UDT
/// final document = parseMarkdown('# Hello World');
///
/// // Or use with HyperViewer
/// HyperViewer.markdown(
///   markdown: '# Title\n\nContent...',
///   contentParser: MarkdownContentParser(),
/// )
/// ```
library;

export 'src/markdown_adapter.dart';
export 'src/markdown_parser.dart';
