/// HyperRender Core - Zero External Dependencies
///
/// This is the core rendering engine for HyperRender.
/// It provides the Unified Document Tree (UDT) model, rendering primitives,
/// and interfaces for plugins.
///
/// ## Features
/// - Universal Document Tree (UDT) model
/// - Custom RenderObject-based layout engine
/// - Fragment-based inline layout with float support
/// - CJK line-breaking (Kinsoku)
/// - Ruby/Furigana support for Japanese
/// - Text selection with handles
/// - CSS cascade style resolution
///
/// ## Zero External Dependencies
/// This package only depends on Flutter SDK.
/// Parsing (HTML, Markdown, CSS) and syntax highlighting are provided
/// by separate plugin packages.
///
/// ## Plugin Interfaces
/// - [ContentParser] - For content parsing (HTML, Markdown, Delta)
/// - [CssParserInterface] - For CSS stylesheet parsing
/// - [CodeHighlighter] - For code syntax highlighting
/// - [ImageClipboardHandler] - For image clipboard operations
///
/// ## Example
/// ```dart
/// import 'package:hyper_render_core/hyper_render_core.dart';
///
/// // Create document manually
/// final document = DocumentNode(children: [
///   BlockNode.h1(children: [TextNode('Hello World')]),
///   BlockNode.p(children: [TextNode('Welcome to HyperRender!')]),
/// ]);
///
/// // Render with HyperRenderWidget
/// HyperRenderWidget(document: document)
/// ```
library;

// Model
export 'src/model/computed_style.dart';
export 'src/model/node.dart';
export 'src/model/fragment.dart';

// Layout
export 'src/layout/layout_cache.dart';

// Interfaces (Plugin system)
export 'src/interfaces/content_parser.dart';
export 'src/interfaces/css_parser.dart';
export 'src/interfaces/code_highlighter.dart';
export 'src/interfaces/image_clipboard.dart';
export 'src/interfaces/node_plugin.dart';

// Style
export 'src/style/resolver.dart';
export 'src/style/css_rule_index.dart';
export 'src/style/design_tokens.dart';

// Util
export 'src/util/url_safety.dart';

// Core rendering
export 'src/core/hyper_render_debug_hooks.dart';
export 'src/core/hyper_render_config.dart';
export 'src/core/hyper_render_theme.dart';
export 'src/core/render_hyper_box.dart';
export 'src/core/hyper_selection_controller.dart';
export 'src/core/span_converter.dart';
export 'src/core/kinsoku_processor.dart';
export 'src/core/image_provider.dart';
export 'src/core/lazy_image_queue.dart';
export 'src/core/render_ruby.dart';
export 'src/core/render_media.dart';
export 'src/core/render_table.dart';
export 'src/core/render_formula.dart';
export 'src/core/animation_controller.dart';
export 'src/core/performance_monitor.dart';

// Widgets
export 'src/widgets/hyper_render_widget.dart';
export 'src/widgets/hyper_selection_overlay.dart';
export 'src/widgets/code_block_widget.dart';
export 'src/widgets/error_boundary_widget.dart';
export 'src/widgets/hyper_error_widget.dart';
export 'src/widgets/loading_skeleton.dart';
export 'src/widgets/flex_container_widget.dart';
export 'src/widgets/grid_container_widget.dart';
export 'src/widgets/hyper_details_widget.dart';
