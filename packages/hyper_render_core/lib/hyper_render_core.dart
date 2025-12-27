/// HyperRender Core - Zero-dependency rendering engine
///
/// This is the core package with NO external dependencies (except Flutter).
/// It provides:
/// - Plugin interfaces for content parsing, CSS parsing, and code highlighting
/// - Core models (DocumentNode, ComputedStyle, etc.)
/// - Base rendering logic
///
/// To use HyperRender, you need to add a content parser plugin:
///
/// ```yaml
/// dependencies:
///   hyper_render_core: ^2.0.0
///   hyper_render_html: ^2.0.0  # For HTML parsing
///   # OR
///   hyper_render_markdown: ^2.0.0  # For Markdown parsing
/// ```
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:hyper_render_core/hyper_render_core.dart';
/// import 'package:hyper_render_html/hyper_render_html.dart';
///
/// HyperViewer(
///   html: '<p>Hello <strong>World</strong></p>',
///   contentParser: HtmlContentParser(),
/// )
/// ```
library;

// NOTE: This is a STUB package showing the intended structure.
// In a full implementation, the following would be exported:

// Plugin Interfaces
// export 'src/interfaces/content_parser.dart';
// export 'src/interfaces/css_parser.dart';
// export 'src/interfaces/code_highlighter.dart';

// Models
// export 'src/model/node.dart';
// export 'src/model/computed_style.dart';
// export 'src/model/fragment.dart';

// Core Widgets (without default implementations)
// export 'src/widgets/hyper_viewer.dart';
// export 'src/widgets/hyper_render_widget.dart';

// Core Rendering
// export 'src/core/render_hyper_box.dart';
// export 'src/core/image_provider.dart';
